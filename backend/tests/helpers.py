"""Small helpers used by several test files."""


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
