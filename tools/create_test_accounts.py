"""Creates a few test customers through the API (server must be running).

    backend/.venv/Scripts/python tools/create_test_accounts.py

All test logins use password 'secret123', MPIN '1234', ATM PIN '4321'.
"""
import json
import urllib.error
import urllib.request

SERVER = "http://localhost:8000"

PEOPLE = [
    # bank, branch index, name, PAN, mobile, opening deposit (₹), type, business
    ("KAVR", 1, "Sunil Verma", "AKVPV1234S", "9988776655", 100000, "SAVINGS", ""),
    ("GANG", 4, "Ravi Kumar", "BGNPK5678R", "9123456780", 1000, "SAVINGS", ""),
    ("NARM", 0, "Lakshmi Devi", "CNRPD4321L", "9001122334", 50000, "CURRENT", "Lakshmi Mobiles"),
]


def call(method, path, body=None):
    req = urllib.request.Request(SERVER + path, method=method,
                                 data=json.dumps(body).encode() if body else None,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())


for bank, idx, name, pan, mobile, deposit, acc_type, business in PEOPLE:
    branch = call("GET", f"/api/banks/{bank}")["branches"][idx]
    try:
        res = call("POST", f"/api/banks/{bank}/open-account", {
            "full_name": name, "dob": "1994-06-15", "gender": "Male", "mobile": mobile, "pan": pan,
            "aadhaar": "345678901234", "address": "Demo street", "city": branch["city"],
            "state": branch["state"], "pincode": "560001", "branch_id": branch["id"],
            "account_type": acc_type, "business_name": business, "password": "secret123",
            "mpin": "1234", "card_pin": "4321", "initial_deposit": deposit * 100})
        print(f"{bank}  {name:<14} CIF {res['cif']}  A/c {res['account_no']}  IFSC {res['ifsc']}")
    except urllib.error.HTTPError as e:
        print(f"{bank}  {name:<14} skipped: {json.loads(e.read())['detail']}")
