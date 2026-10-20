"""Phase 4: the 8-person fraud story from docs/PLAN.md, end to end.

P2 (victim) --50,000--> P1 (scammer)
P1 --25,000--> P3 (keeps 10,000) --15,000--> P5 (keeps 5,000) --10,000--> P7 (buys crypto, sends half outside)
P1 --25,000--> P4 (keeps 10,000) --15,000--> P6 (keeps 5,000) --10,000--> P8 (+5,000 own money, buys 15,000 phone)
"""
from app.db import SessionLocal
from app.models import Account
from app.routers.police import DEMO_OFFICER
from helpers import login, open_account
from test_crypto import crypto_register
from test_upi import bank_account, link, upi_register

ROUND = 100  # allow ₹1 rounding in crypto prices


class Person:
    def __init__(self, client, bank, name, pan, mobile, deposit=0, **extra):
        r = open_account(client, bank, name, pan, mobile, deposit=deposit * 100, **extra).json()
        self.client, self.bank, self.cif = client, bank, r["cif"]
        self.headers = login(client, bank, r["cif"])
        self.acc = bank_account(client, bank, r["cif"])
        self.no, self.ifsc = self.acc["account_no"], self.acc["branch"]["ifsc"]

    def pay(self, other, rupees, ok=True, **extra):
        r = self.client.post("/api/transfers", headers=self.headers, json={
            "from_account": self.no, "to_account": other.no, "to_ifsc": other.ifsc,
            "amount": rupees * 100, "mpin": "1234", **extra})
        if ok:
            assert r.status_code == 200, r.text
        return r

    def account(self):
        return self.client.get("/api/me", headers=self.headers).json()["accounts"][0]


def test_eight_person_story(client):
    p2 = Person(client, "KAVR", "Priya Sharma", "AAAPS0002A", "9000000002", deposit=100_000)  # victim
    p1 = Person(client, "GANG", "Pankaj One", "BBBPO0001B", "9000000001")  # scammer
    p3 = Person(client, "SAHY", "Prakash Three", "CCCPT0003C", "9000000003")
    p4 = Person(client, "NARM", "Pooja Four", "DDDPF0004D", "9000000004")
    p5 = Person(client, "GODA", "Pavan Five", "EEEPF0005E", "9000000005")
    p6 = Person(client, "GANG", "Pallavi Six", "FFFPS0006F", "9000000006")
    p7 = Person(client, "KAVR", "Pradeep Seven", "GGGPS0007G", "9000000007")
    p8 = Person(client, "SAHY", "Prem Eight", "HHHPE0008H", "9000000008", deposit=5_000)
    shop = Person(client, "NARM", "Lakshmi Devi", "IIIPL0009I", "9000000009",
                  account_type="CURRENT", business_name="Lakshmi Mobiles")
    p8_second = Person(client, "GODA", "Prem Eight", "HHHPE0008H", "9000000018")  # same PAN, other bank

    # P7 has a CoinVault account (same PAN as his bank account)
    cv = {"Authorization": "Bearer " + crypto_register(client, "9000000007", "GGGPS0007G", p7.acc).json()["token"]}

    # --- the fraud: victim pays the scammer by UPI
    v = upi_register(client, "9000000002", "Priya Sharma")
    link(client, v, p2.acc)
    s1 = upi_register(client, "9000000001", "Pankaj One")
    link(client, s1, p1.acc)
    scam = client.post("/api/upi/pay", headers=v, json={
        "from_vpa": "priya0002@kaveri", "to": "pankaj0001@ganga", "amount": 50_000_00, "upi_pin": "2580",
        "location": {"lat": 12.97, "lng": 77.59, "label": "Bengaluru", "source": "DEMO"}}).json()

    # --- the money is spread out
    p1.pay(p3, 25_000)
    p1.pay(p4, 25_000)
    p3.pay(p5, 15_000)
    p4.pay(p6, 15_000)
    p5.pay(p7, 10_000)
    p6.pay(p8, 10_000)
    p8.pay(shop, 15_000)  # buys a phone (10,000 victim money + 5,000 own)
    s7 = upi_register(client, "9000000007", "Pradeep Seven")
    link(client, s7, p7.acc)
    client.post("/api/upi/pay", headers=s7, json={"from_vpa": "pradeep0007@kaveri", "to": "coinvault@godavari",
                                                  "amount": 10_000_00, "upi_pin": "2580"})
    btc = client.post("/api/crypto/buy", headers=cv, json={"asset": "BTC", "inr": 10_000_00, "pin": "4444"}).json()
    qty = next(h for h in btc["user"]["holdings"] if h["asset"] == "BTC")["quantity"]
    client.post("/api/crypto/withdraw-crypto", headers=cv, json={
        "asset": "BTC", "quantity": qty // 2, "address": "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh", "pin": "4444"})

    # --- the victim complains from RakshakPay
    cats = client.get("/api/complaint-categories").json()
    r = client.post("/api/upi/complaints", headers=v, json={"utr": scam["utr"], "category": cats[1],
                                                            "description": "Caller said my KYC expired"})
    assert r.status_code == 200, r.text
    c = r.json()
    assert c["ack_no"].startswith("1930-") and c["status"] == "TRACED"
    assert c["held"] == 30_000_00  # P3 10k + P4 10k + P5 5k + P6 5k
    assert client.post("/api/upi/complaints", headers=v, json={"utr": scam["utr"], "category": cats[1]}).status_code == 409

    # --- holds: only the victim's money, own money untouched
    assert p3.account()["lien_amount"] == 10_000_00 and p4.account()["lien_amount"] == 10_000_00
    assert p5.account()["lien_amount"] == 5_000_00 and p6.account()["lien_amount"] == 5_000_00
    assert p1.account()["lien_amount"] == 0  # forwarded everything

    # --- mules flagged and blocked; merchant and victim untouched
    for p in (p1, p3, p4, p5, p6, p7, p8):
        assert p.account()["status"] == "SUSPECTED_MULE", p.account()["holder_name"]
    assert p8_second.account()["status"] == "SUSPECTED_MULE"  # linked by PAN in another bank
    assert shop.account()["status"] == "ACTIVE" and shop.account()["lien_amount"] == 0
    assert p2.account()["status"] == "ACTIVE"
    assert p3.pay(p5, 100, ok=False).status_code == 403  # debit blocked
    notices = client.get("/api/notices", headers=p3.headers).json()
    assert notices[0]["kind"] == "MULE"
    assert "NOT restricted" in client.get("/api/notices", headers=shop.headers).json()[0]["body"]

    # --- PAN blacklist: no new accounts anywhere, exchange frozen
    assert open_account(client, "KAVR", "Pankaj One", "BBBPO0001B", "9000000099").status_code == 403
    assert client.post("/api/crypto/login", json={"mobile": "9000000007", "pin": "4444"}).status_code == 403

    # --- anyone paying a mule is warned and must acknowledge
    w = p2.pay(p1, 100, ok=False)
    assert w.status_code == 409 and "mule list" in w.json()["detail"]
    look = client.get("/api/lookup", params={"account_no": p1.no, "ifsc": p1.ifsc}, headers=p2.headers).json()
    assert look["warning"]
    # "Pay anyway" works. P1 has no lien, so this stays in P1's blocked account (not captured).
    p2.pay(p1, 100, acknowledge_warning=True)

    # --- police
    pol = client.post("/api/police/login", json={"badge_id": DEMO_OFFICER["badge_id"],
                                                 "password": DEMO_OFFICER["password"]}).json()
    ph = {"Authorization": f"Bearer {pol['token']}"}
    d = client.get(f"/api/police/complaints/{c['id']}", headers=ph).json()
    roles = {n["holder"]: n["role"] for n in d["nodes"]}
    assert roles["Lakshmi Devi"] == "MERCHANT" and roles["Priya Sharma"] == "VICTIM"
    assert d["totals"]["spent_merchant"] == 10_000_00
    assert abs(d["totals"]["crypto_frozen"] - 5_000_00) <= ROUND * 100
    assert abs(d["totals"]["crypto_escaped"] - 5_000_00) <= ROUND * 100
    assert d["report_location"] is None  # this complaint was filed without a location
    assert any(e["location"] and e["location"]["label"] == "Bengaluru" for e in d["edges"])  # victim's GPS
    p8_node = next(n for n in d["nodes"] if n["holder"] == "Prem Eight")
    assert p8_node["spent_merchant"] == 10_000_00

    orders = {o["holder"]: o for o in d["court_orders"]}
    assert set(orders) == {"Prem Eight", "Pradeep Seven"}
    assert orders["Prem Eight"]["amount"] == 10_000_00
    assert "Section 107" in orders["Prem Eight"]["application_text"]

    # court approves -> P8's available balance goes negative
    client.post(f"/api/police/court-orders/{orders['Prem Eight']['id']}/approve", headers=ph)
    assert p8.account()["available_balance"] == -10_000_00

    # money later arriving in P8's account is captured (a relative repays on P8's behalf)
    p2.pay(p8, 3_000, acknowledge_warning=True)

    # release everything to the victim
    before = p2.account()["balance"]
    rel = client.post(f"/api/police/complaints/{c['id']}/release", headers=ph).json()
    got = p2.account()["balance"] - before
    assert got == rel["released"]
    # 30,000 held + 3,000 captured by P8's court-approved lien + ~5,000 crypto seized at the exchange
    assert abs(got - (30_000_00 + 3_000_00 + 5_000_00)) <= ROUND * 100
    assert p3.account()["lien_amount"] == 0
    assert p8.account()["available_balance"] == -7_000_00  # still owes the rest

    mules = client.get("/api/police/mules", headers=ph).json()
    assert {m["holder"] for m in mules} >= {"Pankaj One", "Prem Eight"}
    dash = client.get("/api/police/dashboard", headers=ph).json()
    assert dash["complaints"] == 1 and dash["recovered"] == got


def test_complaint_rules(client):
    a = Person(client, "KAVR", "Asha Rao", "AAAPR1111A", "9100000001", deposit=1_000)
    b = Person(client, "GANG", "Bala Rao", "BBBPR2222B", "9100000002")
    t = a.pay(b, 100).json()
    # someone else cannot report your transaction
    assert client.post("/api/complaints", headers=b.headers, json={"utr": t["utr"], "category": "Other"}).status_code == 404
    assert client.post("/api/complaints", headers=a.headers, json={"utr": t["utr"], "category": "Nope"}).status_code == 400
    r = client.post("/api/complaints", headers=a.headers, json={"utr": t["utr"], "category": "Other"})
    assert r.status_code == 200
    assert client.get("/api/complaints", headers=a.headers).json()[0]["ack_no"] == r.json()["ack_no"]
    with SessionLocal() as db:
        assert db.get(Account, b.no).lien_amount == 100_00
