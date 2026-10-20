"""Phase 6: branch verification of mules and the police decision."""
from helpers import open_account
from test_fraud import Person
from app.routers.officer import DEMO_PASSWORD, KYC_CHECKS, REASONS
from app.routers.police import DEMO_OFFICER


def officer_login(client, bank):
    r = client.post("/api/officer/login", json={"bank_code": bank, "staff_id": f"{bank}001", "password": DEMO_PASSWORD})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['token']}"}


def test_branch_verification_and_police_decisions(client):
    victim = Person(client, "SAHY", "Vani Rao", "VVVPR0001V", "9200000001", deposit=20_000)
    a = Person(client, "KAVR", "Arun Kumar", "AAAPK0001A", "9200000002")  # account was hacked
    b = Person(client, "GANG", "Bhanu Pratap", "BBBPP0001B", "9200000003")  # rented his account
    b2 = Person(client, "SAHY", "Bhanu Pratap", "BBBPP0001B", "9200000013")  # same PAN, other bank
    c = Person(client, "NARM", "Chetan Joshi", "CCCPJ0001C", "9200000004")  # job scam victim turned mule
    shop = Person(client, "GODA", "Shop Owner", "DDDPS0001D", "9200000005",
                  account_type="CURRENT", business_name="Gadget Store")

    t = victim.pay(a, 10_000).json()
    a.pay(b, 6_000)
    a.pay(c, 3_000)  # A keeps 1,000 of the victim's money
    c.pay(shop, 3_000)
    comp = client.post("/api/complaints", headers=victim.headers, json={"utr": t["utr"], "category": "Other"}).json()

    police = {"Authorization": "Bearer " + client.post("/api/police/login", json={
        "badge_id": DEMO_OFFICER["badge_id"], "password": DEMO_OFFICER["password"]}).json()["token"]}
    order = next(o for o in client.get("/api/police/court-orders", headers=police).json() if o["holder"] == "Chetan Joshi")
    client.post(f"/api/police/court-orders/{order['id']}/approve", headers=police)
    assert c.account()["available_balance"] == -3_000_00

    # --- officers only see their own bank's customers
    kav = officer_login(client, "KAVR")
    assert client.post("/api/officer/login", json={"bank_code": "GANG", "staff_id": "KAVR001",
                                                   "password": DEMO_PASSWORD}).status_code == 401
    found = client.get("/api/officer/search", params={"q": "9200000002"}, headers=kav).json()
    assert [f["name"] for f in found] == ["Arun Kumar"] and found[0]["flagged"]
    assert client.get("/api/officer/search", params={"q": "9200000003"}, headers=kav).json() == []
    flagged = client.get("/api/officer/flagged", headers=kav).json()
    assert {f["name"] for f in flagged} == {"Arun Kumar"}
    detail = client.get(f"/api/officer/customers/{found[0]['cif']}", headers=kav).json()
    assert detail["involvement"][0]["complaint"] == comp["ack_no"]
    assert detail["involvement"][0]["held"] == 1_000_00

    # --- verification rules
    base = {"account_no": a.no, "kyc_checks": KYC_CHECKS, "reason_category": REASONS[0],
            "statement": "Someone changed my net banking password last month.", "recommendation": "INNOCENT"}
    assert client.post("/api/officer/verifications", headers=kav, json={**base, "kyc_checks": KYC_CHECKS[:2]}).status_code == 400
    assert client.post("/api/officer/verifications", headers=kav, json={**base, "account_no": b.no}).status_code == 404
    case_a = client.post("/api/officer/verifications", headers=kav, json=base)
    assert case_a.status_code == 200, case_a.text
    assert client.post("/api/officer/verifications", headers=kav, json=base).status_code == 409  # already pending

    gang = officer_login(client, "GANG")
    case_b = client.post("/api/officer/verifications", headers=gang, json={
        **base, "account_no": b.no, "reason_category": REASONS[4],
        "statement": "A man paid me Rs 8000 for my ATM card and SIM.", "recommendation": "INVOLVED"}).json()

    narm = officer_login(client, "NARM")
    tricked = {**base, "account_no": c.no, "reason_category": REASONS[2],
               "statement": "I was promised a work-from-home job and asked to forward payments.",
               "recommendation": "TRICKED"}
    assert client.post("/api/officer/verifications", headers=narm, json=tricked).status_code == 400  # no undertaking
    case_c = client.post("/api/officer/verifications", headers=narm, json={
        **tricked, "undertaking_signed": True, "awareness_done": True}).json()

    # --- police decide
    pending = client.get("/api/police/verifications", headers=police).json()
    assert {p["customer"] for p in pending if p["status"] == "PENDING_POLICE"} == {"Arun Kumar", "Bhanu Pratap", "Chetan Joshi"}

    def decide(case, decision):
        r = client.post(f"/api/police/verifications/{case['id']}/decide", headers=police,
                        json={"decision": decision, "remarks": "Reviewed"})
        assert r.status_code == 200, r.text

    decide(case_a.json(), "INNOCENT")
    decide(case_b, "INVOLVED")
    decide(case_c, "TRICKED")
    assert client.post(f"/api/police/verifications/{case_b['id']}/decide", headers=police,
                       json={"decision": "INNOCENT"}).status_code == 409

    # Innocent: services back, but the victim's 1,000 stays on hold
    acc_a = a.account()
    assert acc_a["status"] == "ACTIVE" and acc_a["lien_amount"] == 1_000_00
    assert open_account(client, "GODA", "Arun Kumar", "AAAPK0001A", "9200000022").status_code == 200  # PAN unblocked

    # Involved: every account with the PAN is confirmed and blocked
    assert b.account()["status"] == "CONFIRMED_MULE" and b2.account()["status"] == "CONFIRMED_MULE"
    assert b.pay(victim, 100, ok=False).status_code == 403
    assert open_account(client, "NARM", "Bhanu Pratap", "BBBPP0001B", "9200000023").status_code == 403

    # Tricked: active again, but still owes the court-ordered 3,000
    acc_c = c.account()
    assert acc_c["status"] == "ACTIVE" and acc_c["available_balance"] == -3_000_00
    assert c.pay(victim, 100, ok=False).status_code == 400  # nothing available to spend
    notices = client.get("/api/notices", headers=c.headers).json()
    assert notices[0]["title"] == "Services restored with conditions"
