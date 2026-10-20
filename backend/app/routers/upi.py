"""UPI: the "NPCI" switch that connects the RakshakPay UPI app to all 5 banks.

Flow (same as real UPI):
  register with mobile -> pick a bank -> the bank finds accounts registered with
  that mobile -> verify debit card (last 6 digits + expiry) -> set UPI PIN -> UPI ID.
"""
import re

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import or_
from sqlalchemy.orm import Session

from ..db import get_db
from ..ledger import move_money, rupees
from ..models import Account, Bank, Customer, Transaction, UpiSession, UpiTransfer, UpiUser, Vpa
from ..out import mask, mask_name
from ..realtime import manager
from ..security import current_upi_user, hash_secret, new_token, verify_secret
from . import crypto
from .payments import LocationIn, ensure_can_debit

router = APIRouter(prefix="/api/upi", tags=["upi"])

MAX_UPI = 1_00_000 * 100  # ₹1 lakh per UPI payment (real NPCI limit for most payments)

# Bank code -> UPI handle (the part after @)
HANDLES = {"SAHY": "sahyadri", "GANG": "ganga", "KAVR": "kaveri", "NARM": "narmada", "GODA": "godavari"}


def _pin_ok(v: str, digits: tuple[int, ...]) -> str:
    if not (v.isdigit() and len(v) in digits):
        raise ValueError(f"PIN must be {' or '.join(map(str, digits))} digits")
    return v


# ---------------------------------------------------------------- account


class RegisterRequest(BaseModel):
    mobile: str
    name: str = Field(min_length=3, max_length=100)
    passcode: str

    @field_validator("mobile")
    @classmethod
    def mobile_ok(cls, v: str) -> str:
        if not re.fullmatch(r"[6-9]\d{9}", v):
            raise ValueError("Enter a valid 10-digit Indian mobile number")
        return v

    @field_validator("passcode")
    @classmethod
    def passcode_ok(cls, v: str) -> str:
        return _pin_ok(v, (4,))


def _vpa_out(v: Vpa) -> dict:
    a = v.account
    return {
        "address": v.address,
        "bank_code": a.bank_code,
        "bank_handle": HANDLES[a.bank_code],
        "account_no_masked": mask(a.account_no),
        "account_type": a.account_type,
        "is_merchant": a.account_type == "CURRENT",
        "display_name": a.business_name or a.customer.full_name,
        "holder_name": a.customer.full_name,
        "status": a.status,
    }


def _user_out(u: UpiUser) -> dict:
    return {"mobile": u.mobile, "name": u.name, "vpas": [_vpa_out(v) for v in u.vpas]}


def _start_session(db: Session, user: UpiUser) -> dict:
    token = new_token()
    db.add(UpiSession(token=token, upi_user_id=user.id))
    db.commit()
    return {"token": token, "user": _user_out(user)}


@router.post("/register")
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(UpiUser).filter_by(mobile=req.mobile).first():
        raise HTTPException(409, "This mobile number is already registered. Please log in.")
    user = UpiUser(mobile=req.mobile, name=" ".join(req.name.split()).title(),
                   passcode_hash=hash_secret(req.passcode))
    db.add(user)
    db.flush()
    return _start_session(db, user)


class LoginRequest(BaseModel):
    mobile: str
    passcode: str


@router.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(UpiUser).filter_by(mobile=req.mobile).first()
    if not user or not verify_secret(req.passcode, user.passcode_hash):
        raise HTTPException(401, "Wrong mobile number or passcode")
    return _start_session(db, user)


@router.get("/me")
def me(user: UpiUser = Depends(current_upi_user)):
    return _user_out(user)


class UnlockRequest(BaseModel):
    passcode: str


@router.post("/unlock")
def unlock(req: UnlockRequest, user: UpiUser = Depends(current_upi_user)):
    """Checks the app passcode each time the app is opened (app lock)."""
    if not verify_secret(req.passcode, user.passcode_hash):
        raise HTTPException(401, "Wrong passcode")
    return {"message": "Unlocked"}


# ---------------------------------------------------------------- linking a bank account


@router.get("/banks/{code}/accounts")
def find_accounts(code: str, user: UpiUser = Depends(current_upi_user), db: Session = Depends(get_db)):
    """Accounts in this bank registered with the user's mobile number (and not yet linked)."""
    bank = db.get(Bank, code.upper())
    if not bank:
        raise HTTPException(404, "Bank not found")
    accounts = (db.query(Account).join(Customer)
                .filter(Account.bank_code == bank.code, Customer.mobile == user.mobile).all())
    linked = {v.account_no for v in db.query(Vpa).filter(Vpa.account_no.in_([a.account_no for a in accounts]))}
    return {
        "bank": bank.name,
        "accounts": [
            {"account_no": a.account_no, "account_no_masked": mask(a.account_no), "account_type": a.account_type,
             "holder_name": a.customer.full_name, "business_name": a.business_name,
             "branch": a.branch.name, "already_linked": a.account_no in linked}
            for a in accounts
        ],
    }


class LinkRequest(BaseModel):
    account_no: str
    card_last6: str
    card_expiry: str  # MM/YY
    upi_pin: str

    @field_validator("upi_pin")
    @classmethod
    def upi_pin_ok(cls, v: str) -> str:
        return _pin_ok(v, (4, 6))


def _new_vpa_address(db: Session, account: Account, mobile: str) -> str:
    if account.account_type == "CURRENT" and account.business_name:
        base = re.sub(r"[^a-z0-9]", "", account.business_name.lower())[:20] or "merchant"
    else:
        base = re.sub(r"[^a-z]", "", account.customer.full_name.split()[0].lower())[:12] + mobile[-4:]
    handle = HANDLES[account.bank_code]
    address, n = f"{base}@{handle}", 1
    while db.get(Vpa, address):
        n += 1
        address = f"{base}{n}@{handle}"
    return address


@router.post("/link")
def link_account(req: LinkRequest, user: UpiUser = Depends(current_upi_user), db: Session = Depends(get_db)):
    account = db.get(Account, req.account_no)
    if not account or account.customer.mobile != user.mobile:
        raise HTTPException(404, "No account with your mobile number found")
    if db.query(Vpa).filter_by(account_no=account.account_no).first():
        raise HTTPException(409, "This account is already linked to UPI")
    if account.card_no[-6:] != req.card_last6 or account.card_expiry != req.card_expiry:
        raise HTTPException(400, "Debit card details do not match")
    if account.card_blocked:
        raise HTTPException(403, "Your debit card is blocked. Unblock it in your bank app first.")
    vpa = Vpa(address=_new_vpa_address(db, account, user.mobile), upi_user_id=user.id,
              account_no=account.account_no, upi_pin_hash=hash_secret(req.upi_pin))
    db.add(vpa)
    db.commit()
    db.refresh(user)
    return {"message": f"UPI ID {vpa.address} is ready", "vpa": _vpa_out(vpa), "user": _user_out(user)}


# ---------------------------------------------------------------- paying


def _resolve(db: Session, to: str) -> Vpa:
    """'to' is a UPI ID or a 10-digit mobile number (pays that person's first UPI ID)."""
    to = to.strip().lower()
    if re.fullmatch(r"[6-9]\d{9}", to):
        payee_user = db.query(UpiUser).filter_by(mobile=to).first()
        if not payee_user or not payee_user.vpas:
            raise HTTPException(404, "This mobile number is not on UPI")
        return payee_user.vpas[0]
    vpa = db.get(Vpa, to)
    if not vpa:
        raise HTTPException(404, "UPI ID not found")
    return vpa


@router.get("/resolve")
def resolve(to: str, _user: UpiUser = Depends(current_upi_user), db: Session = Depends(get_db)):
    """Check who you are paying before you pay (shows the verified name)."""
    vpa = _resolve(db, to)
    a = vpa.account
    bank = db.get(Bank, a.bank_code)
    return {"vpa": vpa.address, "name": a.business_name or mask_name(a.customer.full_name),
            "is_merchant": a.account_type == "CURRENT", "bank": bank.name}


def _own_vpa(user: UpiUser, address: str) -> Vpa:
    vpa = next((v for v in user.vpas if v.address == address.lower()), None)
    if not vpa:
        raise HTTPException(404, "This UPI ID is not linked to your profile")
    return vpa


class PayRequest(BaseModel):
    from_vpa: str
    to: str  # UPI ID or mobile number
    amount: int = Field(gt=0, le=MAX_UPI)  # paise
    upi_pin: str
    remark: str = Field(default="", max_length=60)
    location: LocationIn = LocationIn()


@router.post("/pay")
async def pay(req: PayRequest, user: UpiUser = Depends(current_upi_user), db: Session = Depends(get_db)):
    payer = _own_vpa(user, req.from_vpa)
    if not verify_secret(req.upi_pin, payer.upi_pin_hash):
        raise HTTPException(401, "Incorrect UPI PIN")
    ensure_can_debit(payer.account)
    payee = _resolve(db, req.to)
    if payee.account_no == payer.account_no:
        raise HTTPException(400, "You cannot pay the same account")

    payee_name = payee.account.business_name or payee.account.customer.full_name
    txn = move_money(
        db, amount=req.amount, channel="UPI", debit=payer.account, credit=payee.account, remark=req.remark,
        narration_dr=f"UPI/DR/{payee_name.upper()}/{payee.address}",
        narration_cr=f"UPI/CR/{payer.account.customer.full_name.upper()}/{payer.address}",
        location=req.location.to_location(),
    )
    db.add(UpiTransfer(txn_id=txn.id, payer_vpa=payer.address, payee_vpa=payee.address))
    db.commit()
    await manager.account_changed(payer.account_no, payee.account_no)
    # Paying the crypto exchange: credit the payer's CoinVault wallet, or refund.
    note = ""
    if payee.address == crypto.EXCHANGE["vpa"]:
        note = await crypto.handle_exchange_credit(db, txn, payer.account, payer.address)
    return {"message": f"{rupees(req.amount)} paid to {payee_name}", "utr": txn.utr, "note": note,
            "date": txn.created_at.isoformat(), "payee_vpa": payee.address, "payee_name": payee_name}


class BalanceRequest(BaseModel):
    vpa: str
    upi_pin: str


@router.post("/balance")
def balance(req: BalanceRequest, user: UpiUser = Depends(current_upi_user)):
    vpa = _own_vpa(user, req.vpa)
    if not verify_secret(req.upi_pin, vpa.upi_pin_hash):
        raise HTTPException(401, "Incorrect UPI PIN")
    a = vpa.account
    return {"vpa": vpa.address, "balance": a.balance, "lien_amount": a.lien_amount,
            "available_balance": a.available_balance}


@router.get("/history")
def history(user: UpiUser = Depends(current_upi_user), db: Session = Depends(get_db)):
    """UPI payments sent and received by any of the user's UPI IDs, newest first."""
    mine = [v.address for v in user.vpas]
    if not mine:
        return []
    rows = (db.query(UpiTransfer).join(Transaction)
            .filter(or_(UpiTransfer.payer_vpa.in_(mine), UpiTransfer.payee_vpa.in_(mine)))
            .order_by(Transaction.id.desc()).limit(200).all())
    out = []
    for r in rows:
        sent = r.payer_vpa in mine
        other = db.get(Vpa, r.payee_vpa if sent else r.payer_vpa)
        other_name = (other.account.business_name or other.account.customer.full_name) if other else ""
        out.append({
            "utr": r.txn.utr, "date": r.txn.created_at.isoformat(), "direction": "SENT" if sent else "RECEIVED",
            "amount": r.txn.amount, "my_vpa": r.payer_vpa if sent else r.payee_vpa,
            "other_vpa": r.payee_vpa if sent else r.payer_vpa, "other_name": other_name,
            "remark": r.txn.remark, "status": r.txn.status, "location_label": r.txn.location_label,
        })
    return out
