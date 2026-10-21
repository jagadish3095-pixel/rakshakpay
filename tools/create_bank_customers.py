"""Creates 5 customers in each of the 5 banks (25 accounts) and saves their details as JSON.

    backend/.venv/Scripts/python tools/create_bank_customers.py https://rakshakpay.onrender.com out.json

All names, PANs, Aadhaar numbers, mobile numbers and money are fake.
Everyone: login password secret123, MPIN 1234, ATM PIN 4321.
"""
import json
import sys
import urllib.error
import urllib.request

SERVER = (sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000").rstrip("/")
OUT = sys.argv[2] if len(sys.argv) > 2 else "customers.json"
PASSWORD, MPIN, CARD_PIN = "secret123", "1234", "4321"

# bank, branch city, full name, gender, DOB, PAN, mobile, Aadhaar, opening deposit (₹), type, business name
CUSTOMERS = [
    ("SAHY", "Bengaluru", "Ananya Hegde", "Female", "1996-03-14", "AHGPH1101A", "9811100101", "281100110011", 85000, "SAVINGS", ""),
    ("SAHY", "Mysuru", "Karthik Gowda", "Male", "1991-07-22", "KGWPG1102B", "9811100102", "281100110022", 120000, "SAVINGS", ""),
    ("SAHY", "Pune", "Sneha Kulkarni", "Female", "1988-11-05", "SKLPK1103C", "9811100103", "281100110033", 64000, "SAVINGS", ""),
    ("SAHY", "Mumbai", "Rohan Deshmukh", "Male", "1993-01-30", "RDSPD1104D", "9811100104", "281100110044", 150000, "SAVINGS", ""),
    ("SAHY", "Mangaluru", "Ibrahim Shaikh", "Male", "1984-09-18", "ISHPS1105E", "9811100105", "281100110055", 40000, "CURRENT", "Coastal Electronics"),
    ("GANG", "Delhi", "Aditi Malhotra", "Female", "1995-05-09", "AMLPM2101F", "9822200201", "382200220011", 95000, "SAVINGS", ""),
    ("GANG", "Lucknow", "Vikas Tiwari", "Male", "1990-12-02", "VTWPT2102G", "9822200202", "382200220022", 72000, "SAVINGS", ""),
    ("GANG", "Patna", "Neha Kumari", "Female", "1997-08-27", "NKMPK2103H", "9822200203", "382200220033", 48000, "SAVINGS", ""),
    ("GANG", "Kolkata", "Arnab Banerjee", "Male", "1986-04-11", "ABNPB2104J", "9822200204", "382200220044", 130000, "SAVINGS", ""),
    ("GANG", "Delhi", "Harpreet Singh", "Male", "1982-10-23", "HSNPS2105K", "9822200205", "382200220055", 60000, "CURRENT", "Singh Mobile Point"),
    ("KAVR", "Chennai", "Lakshmi Priya", "Female", "1994-02-16", "LPRPP3101L", "9833300301", "483300330011", 110000, "SAVINGS", ""),
    ("KAVR", "Bengaluru", "Suresh Reddy", "Male", "1989-06-08", "SRDPR3102M", "9833300302", "483300330022", 88000, "SAVINGS", ""),
    ("KAVR", "Kochi", "Anjali Nair", "Female", "1992-09-29", "ANRPN3103N", "9833300303", "483300330033", 56000, "SAVINGS", ""),
    ("KAVR", "Hyderabad", "Mohammed Faisal", "Male", "1987-03-03", "MFSPF3104P", "9833300304", "483300330044", 140000, "SAVINGS", ""),
    ("KAVR", "Chennai", "Murugan Selvam", "Male", "1980-12-19", "MSLPS3105Q", "9833300305", "483300330055", 45000, "CURRENT", "Murugan Tea Stall"),
    ("NARM", "Ahmedabad", "Krupa Patel", "Female", "1993-07-01", "KPTPP4101R", "9844400401", "584400440011", 99000, "SAVINGS", ""),
    ("NARM", "Bhopal", "Rahul Chouhan", "Male", "1991-11-13", "RCHPC4102S", "9844400402", "584400440022", 67000, "SAVINGS", ""),
    ("NARM", "Nagpur", "Pooja Wankhede", "Female", "1996-01-25", "PWKPW4103T", "9844400403", "584400440033", 52000, "SAVINGS", ""),
    ("NARM", "Jaipur", "Devendra Rathore", "Male", "1985-05-17", "DRTPR4104U", "9844400404", "584400440044", 125000, "SAVINGS", ""),
    ("NARM", "Mumbai", "Farida Ansari", "Female", "1983-08-06", "FANPA4105V", "9844400405", "584400440055", 70000, "CURRENT", "Ansari Fashions"),
    ("GODA", "Hyderabad", "Sai Kiran", "Male", "1995-10-10", "SKRPK5101W", "9855500501", "685500550011", 105000, "SAVINGS", ""),
    ("GODA", "Visakhapatnam", "Divya Raju", "Female", "1992-04-21", "DRJPR5102X", "9855500502", "685500550022", 78000, "SAVINGS", ""),
    ("GODA", "Ranchi", "Sunil Oraon", "Male", "1990-02-28", "SORPO5103Y", "9855500503", "685500550033", 46000, "SAVINGS", ""),
    ("GODA", "Guwahati", "Pallavi Bora", "Female", "1997-12-07", "PBRPB5104Z", "9855500504", "685500550044", 90000, "SAVINGS", ""),
    ("GODA", "Kolkata", "Tapas Ghosh", "Male", "1981-06-15", "TGHPG5105A", "9855500505", "685500550055", 55000, "CURRENT", "Ghosh Sweets"),
]

BANK_NAMES = {"SAHY": "Sahyadri Bank", "GANG": "Ganga Bank", "KAVR": "Kaveri Bank",
              "NARM": "Narmada Bank", "GODA": "Godavari Bank"}


def call(method, path, body=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(SERVER + path, method=method, headers=headers,
                                 data=json.dumps(body).encode() if body is not None else None)
    try:
        with urllib.request.urlopen(req, timeout=90) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {path} failed: {e.code} {e.read().decode()}")


rows = []
branches = {code: call("GET", f"/api/banks/{code}")["branches"] for code in BANK_NAMES}
for bank, city, name, gender, dob, pan, mobile, aadhaar, deposit, acc_type, business in CUSTOMERS:
    branch = next(b for b in branches[bank] if b["city"] == city)
    email = f"{name.split()[0].lower()}.{name.split()[-1].lower()}@example.com"
    r = call("POST", f"/api/banks/{bank}/open-account", {
        "full_name": name, "dob": dob, "gender": gender, "mobile": mobile, "email": email,
        "pan": pan, "aadhaar": aadhaar, "address": f"{10 + len(rows)}, Main Road", "city": branch["city"],
        "state": branch["state"], "pincode": "560001", "branch_id": branch["id"], "account_type": acc_type,
        "business_name": business, "password": PASSWORD, "mpin": MPIN, "card_pin": CARD_PIN,
        "initial_deposit": deposit * 100})
    token = call("POST", "/api/auth/login", {"bank_code": bank, "login_id": mobile, "password": PASSWORD})["token"]
    acc = call("GET", "/api/me", token=token)["accounts"][0]
    rows.append({
        "bank": BANK_NAMES[bank], "bank_code": bank, "name": name, "gender": gender, "dob": dob,
        "account_type": "Current (Merchant)" if acc_type == "CURRENT" else "Savings", "business_name": business,
        "cif": r["cif"], "account_no": r["account_no"], "ifsc": r["ifsc"], "branch": branch["name"],
        "city": branch["city"], "state": branch["state"], "mobile": mobile, "email": email,
        "pan": pan, "aadhaar": aadhaar, "opening_deposit": deposit, "card_no": acc["card_no"],
        "card_expiry": acc["card_expiry"],
    })
    print(f"  {BANK_NAMES[bank]:<14} {name:<18} A/c {r['account_no']}  IFSC {r['ifsc']}  mobile {mobile}")

with open(OUT, "w", encoding="utf-8") as f:
    json.dump(rows, f, indent=2)
print(f"\n{len(rows)} accounts created. Details saved to {OUT}")
