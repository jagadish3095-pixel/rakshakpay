"""Changing passwords and PINs in every app."""
from test_crypto import crypto_register
from test_fraud import Person
from test_upi import link, upi_register


def test_bank_password_mpin_and_atm_pin(client):
    a = Person(client, "KAVR", "Asha Rao", "AAAPR1111A", "9300000001", deposit=5_000)
    b = Person(client, "GANG", "Bala Rao", "BBBPR2222B", "9300000002")

    assert client.post("/api/security/password", headers=a.headers,
                       json={"current": "wrong", "new": "newpass99"}).status_code == 401
    assert client.post("/api/security/password", headers=a.headers,
                       json={"current": "secret123", "new": "short"}).status_code == 400
    assert client.post("/api/security/password", headers=a.headers,
                       json={"current": "secret123", "new": "newpass99"}).status_code == 200
    login = lambda pw: client.post("/api/auth/login", json={"bank_code": "KAVR", "login_id": "9300000001", "password": pw})
    assert login("secret123").status_code == 401 and login("newpass99").status_code == 200

    # MPIN: used for transfers and the app lock
    mpin = f"/api/accounts/{a.no}/mpin"
    assert client.post(mpin, headers=a.headers, json={"current": "1234", "new": "1234"}).status_code == 400
    assert client.post(mpin, headers=a.headers, json={"current": "1234", "new": "12a4"}).status_code == 400
    assert client.post(mpin, headers=a.headers, json={"current": "1234", "new": "9876"}).status_code == 200
    assert a.pay(b, 10, ok=False).status_code == 401  # old MPIN no longer works
    assert client.post("/api/unlock", headers=a.headers, json={"mpin": "9876"}).status_code == 200
    assert client.post("/api/accounts/" + b.no + "/mpin", headers=a.headers,
                       json={"current": "1234", "new": "5555"}).status_code == 404  # not your account

    # ATM PIN
    assert client.post(f"/api/accounts/{a.no}/card-pin", headers=a.headers,
                       json={"current": "4321", "new": "2468"}).status_code == 200
    atm = client.get("/api/atms").json()[0]["id"]
    w = lambda pin: client.post("/api/atm/withdraw", json={"atm_id": atm, "card_no": a.acc["card_no"],
                                                           "card_pin": pin, "amount": 100_00})
    assert w("4321").status_code == 401 and w("2468").status_code == 200


def test_upi_passcode_upi_pin_and_crypto_pin(client):
    a = Person(client, "KAVR", "Asha Rao", "AAAPR1111A", "9300000001", deposit=5_000)
    s = upi_register(client, "9300000001", "Asha Rao")
    link(client, s, a.acc)
    vpa = "asha0001@kaveri"

    # app passcode
    assert client.post("/api/upi/passcode", headers=s, json={"current": "0000", "new": "2222"}).status_code == 401
    assert client.post("/api/upi/passcode", headers=s, json={"current": "1111", "new": "2222"}).status_code == 200
    assert client.post("/api/upi/unlock", headers=s, json={"passcode": "2222"}).status_code == 200

    # UPI PIN: change with the current PIN
    pin = f"/api/upi/vpas/{vpa}/pin"
    assert client.post(pin, headers=s, json={"current": "0000", "new": "3333"}).status_code == 401
    assert client.post(pin, headers=s, json={"current": "2580", "new": "3333"}).status_code == 200
    bal = lambda p: client.post("/api/upi/balance", headers=s, json={"vpa": vpa, "upi_pin": p})
    assert bal("2580").status_code == 401 and bal("3333").status_code == 200

    # Forgot UPI PIN: reset with the debit card
    assert client.post(pin, headers=s, json={"new": "4444", "card_last6": "000000",
                                             "card_expiry": a.acc["card_expiry"]}).status_code == 400
    assert client.post(pin, headers=s, json={"new": "4444", "card_last6": a.acc["card_no"][-6:],
                                             "card_expiry": a.acc["card_expiry"]}).status_code == 200
    assert bal("4444").status_code == 200

    # CoinVault PIN
    cv = {"Authorization": "Bearer " + crypto_register(client, "9300000001", "AAAPR1111A", a.acc).json()["token"]}
    assert client.post("/api/crypto/pin", headers=cv, json={"current": "4444", "new": "4444"}).status_code == 400
    assert client.post("/api/crypto/pin", headers=cv, json={"current": "4444", "new": "7777"}).status_code == 200
    assert client.post("/api/crypto/login", json={"mobile": "9300000001", "pin": "7777"}).status_code == 200
