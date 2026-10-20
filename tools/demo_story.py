"""Sets up the 8-person fraud story on a RakshakPay server, up to (not including) the complaint.

    backend/.venv/Scripts/python tools/demo_story.py https://rakshakpay.onrender.com

Then, on a phone, log in to RakshakPay as the victim Priya (mobile 9000000002, passcode 1111),
open History -> the Rs 50,000 payment to Pankaj -> Report fraud.

Everyone: bank password secret123, MPIN 1234, ATM PIN 4321, RakshakPay passcode 1111, UPI PIN 2580,
CoinVault PIN 4444. All people, PANs and money are fake. Run it only once per fresh database
(the PANs and mobile numbers below must not exist yet).
"""
import json
import sys
import urllib.error
import urllib.request

SERVER = (sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000").rstrip("/")


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


class Person:
    def __init__(self, bank, branch_city, name, pan, mobile, deposit=0, account_type="SAVINGS", business=""):
        bank_info = call("GET", f"/api/banks/{bank}")
        branch = next(b for b in bank_info["branches"] if b["city"] == branch_city)
        r = call("POST", f"/api/banks/{bank}/open-account", {
            "full_name": name, "dob": "1993-08-20", "gender": "Male", "mobile": mobile, "pan": pan,
            "aadhaar": "456789012345", "address": "Demo street", "city": branch["city"], "state": branch["state"],
            "pincode": "560001", "branch_id": branch["id"], "account_type": account_type,
            "business_name": business, "password": "secret123", "mpin": "1234", "card_pin": "4321",
            "initial_deposit": deposit * 100})
        self.name, self.mobile, self.pan = name, mobile, pan
        self.no, self.ifsc = r["account_no"], r["ifsc"]
        self.token = call("POST", "/api/auth/login", {"bank_code": bank, "login_id": mobile, "password": "secret123"})["token"]
        self.city = branch_city
        print(f"  {name:<16} {bank}  A/c {self.no}  IFSC {self.ifsc}  mobile {mobile}  ({branch_city})")

    def pay(self, other, rupees, city):
        lat, lng = CITY[city]
        r = call("POST", "/api/transfers", {"from_account": self.no, "to_account": other.no, "to_ifsc": other.ifsc,
                                            "amount": rupees * 100, "mpin": "1234", "mode": "IMPS",
                                            "location": {"lat": lat, "lng": lng, "label": city, "source": "DEMO"}},
                 self.token)
        print(f"  {self.name} -> {other.name}: Rs {rupees:,} from {city} (UTR {r['utr']})")

    def upi(self):
        """Registers in RakshakPay and links the bank account. Returns (token, UPI ID)."""
        t = call("POST", "/api/upi/register", {"mobile": self.mobile, "name": self.name, "passcode": "1111"})["token"]
        acc = call("GET", "/api/me", token=self.token)["accounts"][0]
        vpa = call("POST", "/api/upi/link", {"account_no": self.no, "card_last6": acc["card_no"][-6:],
                                             "card_expiry": acc["card_expiry"], "upi_pin": "2580"}, t)["vpa"]["address"]
        return t, vpa


CITY = {c["name"]: (c["lat"], c["lng"]) for c in call("GET", "/api/cities")}

print("Opening accounts…")
victim = Person("KAVR", "Bengaluru", "Priya Sharma", "PRYPS2002A", "9000000002", deposit=100_000)
p1 = Person("GANG", "Jamtara", "Pankaj Mondal", "PNKPM1001B", "9000000001")
p3 = Person("GANG", "Kolkata", "Prakash Das", "PRKPD3003C", "9000000003")
p4 = Person("NARM", "Bharatpur", "Pooja Meena", "POJPM4004D", "9000000004")
p5 = Person("KAVR", "Deoghar", "Pavan Yadav", "PVNPY5005E", "9000000005")
p6 = Person("GANG", "Nuh", "Parvez Khan", "PRVPK6006F", "9000000006")
p7 = Person("GODA", "Ranchi", "Pradeep Soren", "PRDPS7007G", "9000000007")
p8 = Person("NARM", "Jaipur", "Prem Singh", "PRMPS8008H", "9000000008", deposit=5_000)
shop = Person("NARM", "Jaipur", "Mahesh Gupta", "MHSPG9009J", "9000000009",
              account_type="CURRENT", business="Jaipur Mobile Hub")

print("RakshakPay sign-ups…")
v_token, v_vpa = victim.upi()
p1_token, p1_vpa = p1.upi()
p7_token, p7_vpa = p7.upi()
shop.upi()
print(f"  victim {v_vpa}, scammer {p1_vpa}, P7 {p7_vpa}")

print("P7 opens a CoinVault account…")
cv = call("POST", "/api/crypto/register", {"mobile": p7.mobile, "pan": p7.pan, "bank_account_no": p7.no,
                                           "ifsc": p7.ifsc, "pin": "4444"})["token"]

print("The scam: Priya pays Rs 50,000 to the 'KYC officer'…")
lat, lng = CITY["Bengaluru"]
scam = call("POST", "/api/upi/pay", {"from_vpa": v_vpa, "to": p1_vpa, "amount": 50_000_00, "upi_pin": "2580",
                                     "remark": "KYC update fee",
                                     "location": {"lat": lat, "lng": lng, "label": "Bengaluru", "source": "DEMO"}}, v_token)
print(f"  UTR {scam['utr']}")

print("The money is spread through mules…")
p1.pay(p3, 25_000, "Jamtara")
p1.pay(p4, 25_000, "Jamtara")
p3.pay(p5, 15_000, "Kolkata")
p4.pay(p6, 15_000, "Bharatpur")
p5.pay(p7, 10_000, "Deoghar")
p6.pay(p8, 10_000, "Nuh")

print("P8 buys a Rs 15,000 phone…")
lat, lng = CITY["Jaipur"]
call("POST", "/api/transfers", {"from_account": p8.no, "to_account": shop.no, "to_ifsc": shop.ifsc,
                                "amount": 15_000_00, "mpin": "1234",
                                "location": {"lat": lat, "lng": lng, "label": "Jaipur", "source": "DEMO"}}, p8.token)

print("P7 converts to crypto and sends half to an outside wallet…")
lat, lng = CITY["Ranchi"]
call("POST", "/api/upi/pay", {"from_vpa": p7_vpa, "to": "coinvault@godavari", "amount": 10_000_00, "upi_pin": "2580",
                              "location": {"lat": lat, "lng": lng, "label": "Ranchi", "source": "DEMO"}}, p7_token)
buy = call("POST", "/api/crypto/buy", {"asset": "BTC", "inr": 10_000_00, "pin": "4444"}, cv)
qty = next(h for h in buy["user"]["holdings"] if h["asset"] == "BTC")["quantity"]
call("POST", "/api/crypto/withdraw-crypto", {"asset": "BTC", "quantity": qty // 2,
                                             "address": "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh", "pin": "4444"}, cv)

print("\nReady. Now report the fraud from a phone:")
print("  RakshakPay -> log in 9000000002 / passcode 1111 -> Report fraud -> the Rs 50,000 payment to Pankaj")
print("Police login (Phase 5): badge CYB001, password police123")
