"""End-to-end checks for Phase 1 banking. Run from backend/:  python -m pytest"""
import os
import tempfile

os.environ["RAKSHAK_DB"] = os.path.join(tempfile.mkdtemp(), "test.db")

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402


@pytest.fixture()
def client():
    with TestClient(app) as c:
        c.post("/api/demo/reset")
        yield c


def first_branch(client, bank):
    return client.get(f"/api/banks/{bank}").json()["branches"][0]


def open_account(client, bank, name, pan, mobile, deposit=0, **extra):
    branch = first_branch(client, bank)
    body = {
        "full_name": name, "dob": "1995-04-12", "gender": "Female", "mobile": mobile,
        "pan": pan, "aadhaar": "234567890123", "address": "12 Test Street",
        "city": branch["city"], "state": branch["state"], "pincode": "560001",
        "branch_id": branch["id"], "password": "secret123", "mpin": "1234",
        "card_pin": "4321", "initial_deposit": deposit, **extra,
    }
    return client.post(f"/api/banks/{bank}/open-account", json=body)


def login(client, bank, login_id):
    r = client.post("/api/auth/login", json={"bank_code": bank, "login_id": login_id, "password": "secret123"})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['token']}"}


def test_five_banks_with_branches_and_atms(client):
    banks = client.get("/api/banks").json()
    assert len(banks) == 5
    for b in banks:
        details = client.get(f"/api/banks/{b['code']}").json()
        assert len(details["branches"]) == 6 and len(details["atms"]) == 4


def test_open_account_validates_kyc(client):
    r = open_account(client, "SAHY", "Priya Sharma", "BADPAN", "9876543210")
    assert r.status_code == 422
    r = open_account(client, "SAHY", "Priya Sharma", "ABCPS1234K", "1234567890")
    assert r.status_code == 422


def test_open_login_transfer_passbook_and_atm(client):
    a = open_account(client, "SAHY", "priya  sharma", "ABCPS1234K", "9876543210", deposit=1_00_000_00)
    assert a.status_code == 200, a.text
    b = open_account(client, "GANG", "Ravi Kumar", "ABCPK5678L", "9123456780")
    assert b.status_code == 200
    a, b = a.json(), b.json()
    assert a["account_no"].startswith("3021") and len(a["account_no"]) == 12
    assert a["ifsc"].startswith("SAHY0")

    # duplicate PAN in same bank is refused
    assert open_account(client, "SAHY", "Priya Sharma", "ABCPS1234K", "9000000001").status_code == 409

    priya = login(client, "SAHY", a["cif"])
    me = client.get("/api/me", headers=priya).json()
    assert me["full_name"] == "Priya Sharma"
    assert me["accounts"][0]["balance"] == 1_00_000_00

    # beneficiary check shows a masked name
    look = client.get("/api/lookup", params={"account_no": b["account_no"], "ifsc": b["ifsc"]}, headers=priya)
    assert look.json()["name"] == "RAVI K****"

    transfer = {"from_account": a["account_no"], "to_account": b["account_no"], "to_ifsc": b["ifsc"],
                "amount": 50_000_00, "mode": "IMPS", "mpin": "1234",
                "location": {"lat": 12.97, "lng": 77.59, "label": "Bengaluru", "source": "DEMO"}}
    assert client.post("/api/transfers", json={**transfer, "mpin": "0000"}, headers=priya).status_code == 401
    r = client.post("/api/transfers", json=transfer, headers=priya)
    assert r.status_code == 200, r.text
    assert r.json()["balance"] == 50_000_00 and len(r.json()["utr"]) == 12

    # cannot overspend
    too_much = {**transfer, "amount": 60_000_00}
    assert client.post("/api/transfers", json=too_much, headers=priya).status_code == 400

    # Ravi sees it in his passbook
    ravi = login(client, "GANG", "9123456780")
    book = client.get(f"/api/accounts/{b['account_no']}/passbook", headers=ravi).json()
    assert book["entries"][-1]["type"] == "CR"
    assert book["entries"][-1]["amount"] == 50_000_00
    assert "PRIYA SHARMA" in book["entries"][-1]["narration"]

    # someone else's passbook is hidden
    assert client.get(f"/api/accounts/{b['account_no']}/passbook", headers=priya).status_code == 404

    # ATM withdrawal at a different bank's ATM records the ATM location
    atm = client.get("/api/banks/KAVR").json()["atms"][1]
    w = client.post("/api/atm/withdraw", json={"atm_id": atm["id"], "card_no": b["card_no"],
                                              "card_pin": "4321", "amount": 10_000_00})
    assert w.status_code == 200, w.text
    book = client.get(f"/api/accounts/{b['account_no']}/passbook", headers=ravi).json()
    last = book["entries"][-1]
    assert last["channel"] == "ATM" and last["lat"] == atm["lat"]
    assert book["account"]["balance"] == 40_000_00

    # ATM amount rules
    bad = {"atm_id": atm["id"], "card_no": b["card_no"], "card_pin": "4321", "amount": 150_00}
    assert client.post("/api/atm/withdraw", json=bad).status_code == 400
    assert client.post("/api/atm/withdraw", json={**bad, "card_pin": "9999"}).status_code == 401


def test_demo_deposit_only_into_own_account(client):
    a = open_account(client, "SAHY", "Priya Sharma", "ABCPS1234K", "9876543210").json()
    b = open_account(client, "GANG", "Ravi Kumar", "ABCPK5678L", "9123456780").json()
    deposit = {"account_no": a["account_no"], "amount": 1_000_00}
    assert client.post("/api/demo/cash-deposit", json=deposit).status_code == 401
    ravi = login(client, "GANG", b["cif"])
    assert client.post("/api/demo/cash-deposit", json=deposit, headers=ravi).status_code == 404
    priya = login(client, "SAHY", a["cif"])
    assert client.post("/api/demo/cash-deposit", json=deposit, headers=priya).json()["balance"] == 1_000_00


def test_live_update_reaches_receiver(client):
    a = open_account(client, "SAHY", "Priya Sharma", "ABCPS1234K", "9876543210", deposit=5_000_00).json()
    b = open_account(client, "NARM", "Kumar Stores", "ABCPK5678L", "9123456780",
                     account_type="CURRENT", business_name="Kumar Stores").json()
    priya = login(client, "SAHY", a["cif"])
    kumar_token = login(client, "NARM", b["cif"])["Authorization"].split()[1]

    with client.websocket_connect(f"/ws?token={kumar_token}") as ws:
        client.post("/api/transfers", headers=priya, json={
            "from_account": a["account_no"], "to_account": b["account_no"], "to_ifsc": b["ifsc"],
            "amount": 500_00, "mpin": "1234"})
        assert ws.receive_json() == {"type": "account_changed", "account_no": b["account_no"]}
