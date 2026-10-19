"""Turn database rows into the JSON the apps receive."""
from .models import Account, Atm, Bank, Branch, Customer, LedgerEntry


def mask(value: str, keep: int = 4) -> str:
    return "X" * (len(value) - keep) + value[-keep:]


def mask_name(name: str) -> str:
    """'Ravi Kumar' -> 'RAVI K****' (shown before you send money, like real banks)."""
    parts = name.upper().split()
    if len(parts) == 1:
        return parts[0]
    return parts[0] + " " + " ".join(p[0] + "*" * (len(p) - 1) for p in parts[1:])


def bank_out(b: Bank) -> dict:
    return {"code": b.code, "name": b.name, "ifsc_prefix": b.ifsc_prefix,
            "color": b.color, "tagline": b.tagline}


def branch_out(br: Branch) -> dict:
    return {"id": br.id, "bank_code": br.bank_code, "name": br.name, "city": br.city,
            "state": br.state, "ifsc": br.ifsc, "lat": br.lat, "lng": br.lng}


def atm_out(a: Atm) -> dict:
    return {"id": a.id, "bank_code": a.bank_code, "name": a.name, "address": a.address,
            "city": a.city, "state": a.state, "lat": a.lat, "lng": a.lng}


def account_out(a: Account) -> dict:
    return {
        "account_no": a.account_no,
        "bank_code": a.bank_code,
        "account_type": a.account_type,
        "business_name": a.business_name,
        "holder_name": a.customer.full_name,
        "branch": branch_out(a.branch),
        "balance": a.balance,
        "lien_amount": a.lien_amount,
        "available_balance": a.available_balance,
        "status": a.status,
        "card_no": a.card_no,
        "card_expiry": a.card_expiry,
        "card_blocked": a.card_blocked,
        "opened_on": a.created_at.isoformat(),
    }


def customer_out(c: Customer) -> dict:
    return {
        "cif": c.cif, "bank_code": c.bank_code, "full_name": c.full_name, "dob": c.dob,
        "gender": c.gender, "mobile": c.mobile, "email": c.email, "pan": c.pan,
        "aadhaar_masked": mask(c.aadhaar), "address": c.address, "city": c.city,
        "state": c.state, "pincode": c.pincode,
        "accounts": [account_out(a) for a in c.accounts],
    }


def entry_out(e: LedgerEntry) -> dict:
    t = e.txn
    return {
        "id": e.id, "date": e.created_at.isoformat(), "type": e.entry_type,
        "amount": e.amount, "balance_after": e.balance_after, "narration": e.narration,
        "utr": t.utr, "channel": t.channel, "remark": t.remark,
        "location_label": t.location_label, "lat": t.lat, "lng": t.lng,
    }
