"""End-to-end checks for the CoinVault crypto exchange (Phase 3)."""
from app.db import SessionLocal
from app.models import PanBlacklist
from app.routers.crypto import exchange_account
from helpers import login, open_account
from test_upi import bank_account, link, upi_register

EXCHANGE_VPA = "coinvault@godavari"


def crypto_register(client, mobile, pan, account):
    return client.post("/api/crypto/register", json={
        "mobile": mobile, "pan": pan, "bank_account_no": account["account_no"],
        "ifsc": account["branch"]["ifsc"], "pin": "4444"})


def test_kyc_deposit_trade_withdraw(client):
    sunil = open_account(client, "KAVR", "Sunil Verma", "AKVPV1234S", "9988776655", deposit=50_000_00).json()
    ravi = open_account(client, "GANG", "Ravi Kumar", "BGNPK5678R", "9123456780", deposit=20_000_00).json()
    s_acc = bank_account(client, "KAVR", sunil["cif"])
    r_acc = bank_account(client, "GANG", ravi["cif"])

    # KYC: PAN must match the bank account
    assert crypto_register(client, "9988776655", "BGNPK5678R", s_acc).status_code == 400
    r = crypto_register(client, "9988776655", "AKVPV1234S", s_acc)
    assert r.status_code == 200, r.text
    cv = {"Authorization": f"Bearer {r.json()['token']}"}
    assert r.json()["user"]["name"] == "Sunil Verma" and r.json()["user"]["deposit_vpa"] == EXCHANGE_VPA

    # deposit by UPI from Sunil's own account -> credited
    s = upi_register(client, "9988776655", "Sunil Verma")
    link(client, s, s_acc)
    dep = client.post("/api/upi/pay", headers=s, json={"from_vpa": "sunil6655@kaveri", "to": EXCHANGE_VPA,
                                                      "amount": 10_000_00, "upi_pin": "2580"}).json()
    assert "added to your CoinVault wallet" in dep["note"]
    assert client.get("/api/crypto/me", headers=cv).json()["inr"] == 10_000_00

    # Ravi pays CoinVault but has no CoinVault account with his PAN -> refunded at once
    rv = upi_register(client, "9123456780", "Ravi Kumar")
    link(client, rv, r_acc)
    ref = client.post("/api/upi/pay", headers=rv, json={"from_vpa": "ravi6780@ganga", "to": EXCHANGE_VPA,
                                                       "amount": 5_000_00, "upi_pin": "2580"}).json()
    assert "refunded" in ref["note"]
    ravi_book = client.get(f"/api/accounts/{r_acc['account_no']}/passbook", headers=login(client, "GANG", ravi["cif"])).json()
    assert ravi_book["account"]["balance"] == 20_000_00
    assert "COINVAULT REFUND" in ravi_book["entries"][-1]["narration"]
    assert client.get("/api/upi/history", headers=rv).json()[0]["direction"] == "RECEIVED"

    # trade
    assert client.post("/api/crypto/buy", headers=cv, json={"asset": "BTC", "inr": 5_000_00, "pin": "0000"}).status_code == 401
    me = client.post("/api/crypto/buy", headers=cv, json={"asset": "BTC", "inr": 5_000_00, "pin": "4444"}).json()["user"]
    btc = next(h for h in me["holdings"] if h["asset"] == "BTC")["quantity"]
    assert btc > 0 and me["inr"] == 5_000_00
    assert client.post("/api/crypto/buy", headers=cv, json={"asset": "ETH", "inr": 50_000_00, "pin": "4444"}).status_code == 400
    me = client.post("/api/crypto/sell", headers=cv, json={"asset": "BTC", "quantity": btc // 2, "pin": "4444"}).json()["user"]
    assert me["inr"] > 5_000_00

    # withdraw rupees to own bank by IMPS
    before = client.get("/api/me", headers=login(client, "KAVR", sunil["cif"])).json()["accounts"][0]["balance"]
    w = client.post("/api/crypto/withdraw-inr", headers=cv, json={"amount": 1_000_00, "pin": "4444"})
    assert w.status_code == 200, w.text
    after = client.get("/api/me", headers=login(client, "KAVR", sunil["cif"])).json()["accounts"][0]["balance"]
    assert after - before == 1_000_00

    # send remaining BTC to an outside wallet
    left = next(h for h in client.get("/api/crypto/me", headers=cv).json()["holdings"] if h["asset"] == "BTC")["quantity"]
    out = client.post("/api/crypto/withdraw-crypto", headers=cv, json={
        "asset": "BTC", "quantity": left, "address": "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh", "pin": "4444"})
    assert out.status_code == 200, out.text
    kinds = [e["kind"] for e in client.get("/api/crypto/history", headers=cv).json()]
    assert kinds == ["WITHDRAW_CRYPTO", "WITHDRAW_INR", "SELL", "BUY", "DEPOSIT"]


def test_bank_transfer_deposit_and_pan_blacklist(client):
    sunil = open_account(client, "KAVR", "Sunil Verma", "AKVPV1234S", "9988776655", deposit=50_000_00).json()
    s_acc = bank_account(client, "KAVR", sunil["cif"])
    cv = {"Authorization": f"Bearer {crypto_register(client, '9988776655', 'AKVPV1234S', s_acc).json()['token']}"}

    # IMPS from the bank app into CoinVault's account is credited too
    exch = client.get("/api/upi/resolve", params={"to": EXCHANGE_VPA}, headers=upi_register(client, "9000000009", "Test User"))
    assert exch.json()["name"] == "CoinVault Exchange"
    with SessionLocal() as db:
        ex = exchange_account(db)
        ex_no, ex_ifsc = ex.account_no, ex.branch.ifsc
    t = client.post("/api/transfers", headers=login(client, "KAVR", sunil["cif"]), json={
        "from_account": s_acc["account_no"], "to_account": ex_no, "to_ifsc": ex_ifsc, "amount": 2_000_00, "mpin": "1234"})
    assert "added to your CoinVault wallet" in t.json()["note"]
    assert client.get("/api/crypto/me", headers=cv).json()["inr"] == 2_000_00

    # once the PAN is blacklisted, the exchange freezes the user
    with SessionLocal() as db:
        db.add(PanBlacklist(pan="AKVPV1234S", reason="test"))
        db.commit()
    assert client.post("/api/crypto/buy", headers=cv, json={"asset": "USDT", "inr": 1_000_00, "pin": "4444"}).status_code == 403
    assert client.post("/api/crypto/login", json={"mobile": "9988776655", "pin": "4444"}).status_code == 403
    other = open_account(client, "SAHY", "Asha Rao", "DKRPR7788A", "9876501234").json()
    o_acc = bank_account(client, "SAHY", other["cif"])
    with SessionLocal() as db:
        db.add(PanBlacklist(pan="DKRPR7788A", reason="test"))
        db.commit()
    assert crypto_register(client, "9876501234", "DKRPR7788A", o_acc).status_code == 403
