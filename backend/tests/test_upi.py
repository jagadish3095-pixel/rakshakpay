"""End-to-end checks for the UPI switch (Phase 2)."""
from helpers import login, open_account


def upi_register(client, mobile, name):
    r = client.post("/api/upi/register", json={"mobile": mobile, "name": name, "passcode": "1111"})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['token']}"}


def bank_account(client, bank, cif):
    """Full account details (incl. card) as the bank app sees them."""
    return client.get("/api/me", headers=login(client, bank, cif)).json()["accounts"][0]


def link(client, headers, account, pin="2580"):
    return client.post("/api/upi/link", headers=headers, json={
        "account_no": account["account_no"], "card_last6": account["card_no"][-6:],
        "card_expiry": account["card_expiry"], "upi_pin": pin})


def test_full_upi_flow(client):
    sunil = open_account(client, "KAVR", "Sunil Verma", "AKVPV1234S", "9988776655", deposit=50_000_00).json()
    sunil2 = open_account(client, "SAHY", "Sunil Verma", "AKVPV1234S", "9988776655", deposit=1_000_00).json()
    ravi = open_account(client, "GANG", "Ravi Kumar", "BGNPK5678R", "9123456780").json()
    shop = open_account(client, "NARM", "Lakshmi Devi", "CNRPD4321L", "9001122334",
                        account_type="CURRENT", business_name="Lakshmi Mobiles").json()

    # register + login rules
    s = upi_register(client, "9988776655", "sunil verma")
    assert client.post("/api/upi/register", json={"mobile": "9988776655", "name": "X Y Z",
                                                  "passcode": "1111"}).status_code == 409
    assert client.post("/api/upi/login", json={"mobile": "9988776655", "passcode": "0000"}).status_code == 401

    # the bank finds the account by mobile number
    found = client.get("/api/upi/banks/KAVR/accounts", headers=s).json()["accounts"]
    assert [a["account_no"] for a in found] == [sunil["account_no"]]
    assert client.get("/api/upi/banks/GANG/accounts", headers=s).json()["accounts"] == []

    # card check, then UPI ID
    kav = bank_account(client, "KAVR", sunil["cif"])
    bad = client.post("/api/upi/link", headers=s, json={
        "account_no": kav["account_no"], "card_last6": "000000", "card_expiry": kav["card_expiry"], "upi_pin": "2580"})
    assert bad.status_code == 400
    r = link(client, s, kav)
    assert r.status_code == 200, r.text
    assert r.json()["vpa"]["address"] == "sunil6655@kaveri"
    assert link(client, s, kav).status_code == 409  # already linked
    assert link(client, s, bank_account(client, "SAHY", sunil2["cif"])).json()["vpa"]["address"] == "sunil6655@sahyadri"

    # someone else's account cannot be linked
    assert link(client, s, bank_account(client, "GANG", ravi["cif"])).status_code == 404

    rv = upi_register(client, "9123456780", "Ravi Kumar")
    link(client, rv, bank_account(client, "GANG", ravi["cif"]))
    sh = upi_register(client, "9001122334", "Lakshmi Devi")
    assert link(client, sh, bank_account(client, "NARM", shop["cif"])).json()["vpa"]["address"] == "lakshmimobiles@narmada"

    # resolve by UPI ID and by mobile
    assert client.get("/api/upi/resolve", params={"to": "9123456780"}, headers=s).json()["name"] == "RAVI K****"
    m = client.get("/api/upi/resolve", params={"to": "lakshmimobiles@narmada"}, headers=s).json()
    assert m["is_merchant"] and m["name"] == "Lakshmi Mobiles"
    assert client.get("/api/upi/resolve", params={"to": "nobody@kaveri"}, headers=s).status_code == 404

    pay = {"from_vpa": "sunil6655@kaveri", "to": "9123456780", "amount": 500_00, "upi_pin": "2580",
           "location": {"lat": 12.97, "lng": 77.59, "label": "Bengaluru", "source": "DEMO"}}
    assert client.post("/api/upi/pay", headers=s, json={**pay, "upi_pin": "9999"}).status_code == 401
    assert client.post("/api/upi/pay", headers=s, json={**pay, "to": "sunil6655@kaveri"}).status_code == 400
    assert client.post("/api/upi/pay", headers=s, json={**pay, "amount": 60_000_00}).status_code == 400
    r = client.post("/api/upi/pay", headers=s, json=pay)
    assert r.status_code == 200, r.text
    client.post("/api/upi/pay", headers=s, json={**pay, "to": "lakshmimobiles@narmada", "amount": 15_000_00})

    bal = client.post("/api/upi/balance", headers=s, json={"vpa": "sunil6655@kaveri", "upi_pin": "2580"}).json()
    assert bal["balance"] == 34_500_00

    hist = client.get("/api/upi/history", headers=rv).json()
    assert hist[0]["direction"] == "RECEIVED" and hist[0]["other_name"] == "Sunil Verma"
    assert client.get("/api/upi/history", headers=s).json()[0]["other_name"] == "Lakshmi Mobiles"

    # the bank passbook shows the UPI narration
    book = client.get(f"/api/accounts/{shop['account_no']}/passbook", headers=login(client, "NARM", shop["cif"])).json()
    assert book["entries"][-1]["narration"].startswith("UPI/CR/SUNIL VERMA/sunil6655@kaveri")


def test_upi_app_gets_live_updates(client):
    a = open_account(client, "KAVR", "Sunil Verma", "AKVPV1234S", "9988776655", deposit=5_000_00).json()
    b = open_account(client, "GANG", "Ravi Kumar", "BGNPK5678R", "9123456780").json()
    s = upi_register(client, "9988776655", "Sunil Verma")
    link(client, s, bank_account(client, "KAVR", a["cif"]))
    rv = upi_register(client, "9123456780", "Ravi Kumar")
    link(client, rv, bank_account(client, "GANG", b["cif"]))

    with client.websocket_connect(f"/ws?token={rv['Authorization'].split()[1]}") as ws:
        client.post("/api/upi/pay", headers=s, json={"from_vpa": "sunil6655@kaveri", "to": "ravi6780@ganga",
                                                     "amount": 100_00, "upi_pin": "2580"})
        assert ws.receive_json() == {"type": "account_changed", "account_no": b["account_no"]}
