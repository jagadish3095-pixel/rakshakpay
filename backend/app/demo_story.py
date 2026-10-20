"""The 8-person fraud story (docs/PLAN.md), played through the real APIs.

Used by POST /api/demo/load-story (the police app's "Reset & load demo story" button)
and by tools/demo_story.py. Everyone: bank password secret123, MPIN 1234, ATM PIN 4321,
RakshakPay passcode 1111, UPI PIN 2580, CoinVault PIN 4444. All people and money are fake.
"""
import httpx

PASSWORD, MPIN, CARD_PIN, PASSCODE, UPI_PIN, CRYPTO_PIN = "secret123", "1234", "4321", "1111", "2580", "4444"
OUTSIDE_WALLET = "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"

# role, bank, branch city, name, PAN, mobile, opening deposit (₹), type, business
PEOPLE = [
    ("victim", "KAVR", "Bengaluru", "Priya Sharma", "PRYPS2002A", "9000000002", 100_000, "SAVINGS", ""),
    ("p1", "GANG", "Jamtara", "Pankaj Mondal", "PNKPM1001B", "9000000001", 0, "SAVINGS", ""),
    ("p3", "GANG", "Kolkata", "Prakash Das", "PRKPD3003C", "9000000003", 0, "SAVINGS", ""),
    ("p4", "NARM", "Bharatpur", "Pooja Meena", "POJPM4004D", "9000000004", 0, "SAVINGS", ""),
    ("p5", "KAVR", "Deoghar", "Pavan Yadav", "PVNPY5005E", "9000000005", 0, "SAVINGS", ""),
    ("p6", "GANG", "Nuh", "Parvez Khan", "PRVPK6006F", "9000000006", 0, "SAVINGS", ""),
    ("p7", "GODA", "Ranchi", "Pradeep Soren", "PRDPS7007G", "9000000007", 0, "SAVINGS", ""),
    ("p8", "NARM", "Jaipur", "Prem Singh", "PRMPS8008H", "9000000008", 5_000, "SAVINGS", ""),
    ("shop", "NARM", "Jaipur", "Mahesh Gupta", "MHSPG9009J", "9000000009", 0, "CURRENT", "Jaipur Mobile Hub"),
]


class StoryError(Exception):
    pass


async def run_story(client: httpx.AsyncClient, file_complaint: bool = False, log=print) -> dict:
    """Creates the people and moves the money. Returns the logins and (optionally) the complaint."""

    async def call(method: str, path: str, body=None, token: str | None = None):
        headers = {"Authorization": f"Bearer {token}"} if token else {}
        r = await client.request(method, path, json=body, headers=headers, timeout=90)
        if r.status_code >= 400:
            raise StoryError(f"{method} {path} failed: {r.status_code} {r.text}")
        return r.json()

    city = {c["name"]: (c["lat"], c["lng"]) for c in await call("GET", "/api/cities")}

    def here(name: str) -> dict:
        lat, lng = city[name]
        return {"lat": lat, "lng": lng, "label": name, "source": "DEMO"}

    log("Opening accounts…")
    people: dict[str, dict] = {}
    for role, bank, branch_city, name, pan, mobile, deposit, acc_type, business in PEOPLE:
        branches = (await call("GET", f"/api/banks/{bank}"))["branches"]
        branch = next(b for b in branches if b["city"] == branch_city)
        r = await call("POST", f"/api/banks/{bank}/open-account", {
            "full_name": name, "dob": "1993-08-20", "gender": "Male", "mobile": mobile, "pan": pan,
            "aadhaar": "456789012345", "address": "Demo street", "city": branch["city"], "state": branch["state"],
            "pincode": "560001", "branch_id": branch["id"], "account_type": acc_type, "business_name": business,
            "password": PASSWORD, "mpin": MPIN, "card_pin": CARD_PIN, "initial_deposit": deposit * 100})
        token = (await call("POST", "/api/auth/login", {"bank_code": bank, "login_id": mobile, "password": PASSWORD}))["token"]
        people[role] = {"name": name, "bank": bank, "mobile": mobile, "pan": pan, "city": branch_city,
                        "no": r["account_no"], "ifsc": r["ifsc"], "token": token}

    async def transfer(frm: str, to: str, rupees: int, where: str):
        a, b = people[frm], people[to]
        await call("POST", "/api/transfers", {"from_account": a["no"], "to_account": b["no"], "to_ifsc": b["ifsc"],
                                              "amount": rupees * 100, "mpin": MPIN, "mode": "IMPS",
                                              "location": here(where)}, a["token"])
        log(f"  {a['name']} -> {b['name']}: Rs {rupees:,} from {where}")

    async def upi(role: str) -> tuple[str, str]:
        p = people[role]
        t = (await call("POST", "/api/upi/register", {"mobile": p["mobile"], "name": p["name"], "passcode": PASSCODE}))["token"]
        acc = (await call("GET", "/api/me", token=p["token"]))["accounts"][0]
        vpa = (await call("POST", "/api/upi/link", {"account_no": p["no"], "card_last6": acc["card_no"][-6:],
                                                    "card_expiry": acc["card_expiry"], "upi_pin": UPI_PIN}, t))["vpa"]["address"]
        return t, vpa

    log("RakshakPay sign-ups…")
    v_token, v_vpa = await upi("victim")
    _, p1_vpa = await upi("p1")
    p7_token, p7_vpa = await upi("p7")
    await upi("shop")
    p7 = people["p7"]
    cv = (await call("POST", "/api/crypto/register", {"mobile": p7["mobile"], "pan": p7["pan"],
                                                      "bank_account_no": p7["no"], "ifsc": p7["ifsc"],
                                                      "pin": CRYPTO_PIN}))["token"]

    log("The scam: Priya pays Rs 50,000 to the 'KYC officer'…")
    scam = await call("POST", "/api/upi/pay", {"from_vpa": v_vpa, "to": p1_vpa, "amount": 50_000_00, "upi_pin": UPI_PIN,
                                               "remark": "KYC update fee", "location": here("Bengaluru")}, v_token)

    log("The money is spread through mules…")
    await transfer("p1", "p3", 25_000, "Jamtara")
    await transfer("p1", "p4", 25_000, "Jamtara")
    await transfer("p3", "p5", 15_000, "Kolkata")
    await transfer("p4", "p6", 15_000, "Bharatpur")
    await transfer("p5", "p7", 10_000, "Deoghar")
    await transfer("p6", "p8", 10_000, "Nuh")
    log("P8 buys a Rs 15,000 phone in Jaipur…")
    await transfer("p8", "shop", 15_000, "Jaipur")

    log("P7 converts to crypto and sends half to an outside wallet…")
    await call("POST", "/api/upi/pay", {"from_vpa": p7_vpa, "to": "coinvault@godavari", "amount": 10_000_00,
                                        "upi_pin": UPI_PIN, "location": here("Ranchi")}, p7_token)
    buy = await call("POST", "/api/crypto/buy", {"asset": "BTC", "inr": 10_000_00, "pin": CRYPTO_PIN}, cv)
    qty = next(h for h in buy["user"]["holdings"] if h["asset"] == "BTC")["quantity"]
    await call("POST", "/api/crypto/withdraw-crypto", {"asset": "BTC", "quantity": qty // 2,
                                                       "address": OUTSIDE_WALLET, "pin": CRYPTO_PIN}, cv)

    complaint = None
    if file_complaint:
        log("Priya reports the fraud…")
        complaint = await call("POST", "/api/upi/complaints", {
            "utr": scam["utr"], "category": "Fake KYC / bank call",
            "description": "A caller said my KYC had expired and my account would be blocked unless I paid.",
            "location": here("Bengaluru")}, v_token)

    return {
        "scam_utr": scam["utr"],
        "complaint": complaint,
        "people": [{"role": p_role, "name": p["name"], "bank": p["bank"], "mobile": p["mobile"],
                    "account_no": p["no"], "ifsc": p["ifsc"], "city": p["city"]} for p_role, p in people.items()],
        "logins": {"bank_password": PASSWORD, "mpin": MPIN, "atm_pin": CARD_PIN, "rakshakpay_passcode": PASSCODE,
                   "upi_pin": UPI_PIN, "coinvault_pin": CRYPTO_PIN},
    }
