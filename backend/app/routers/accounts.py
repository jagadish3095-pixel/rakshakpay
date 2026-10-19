"""Account opening (KYC), login, profile, passbook."""
import random
import re
from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field, field_validator
from sqlalchemy.orm import Session

from ..db import get_db
from ..ledger import Location, move_money
from ..models import Account, Bank, Branch, Customer, LedgerEntry, PanBlacklist
from ..models import Session as LoginSession
from ..out import account_out, branch_out, customer_out, entry_out, mask_name
from ..realtime import manager
from ..security import current_customer, hash_secret, new_token, verify_secret

router = APIRouter(prefix="/api", tags=["accounts"])

MAX_OPENING_DEPOSIT = 10_00_000 * 100  # ₹10 lakh, in paise


class OpenAccountRequest(BaseModel):
    full_name: str = Field(min_length=3, max_length=100)
    dob: date
    gender: str
    mobile: str
    email: str = ""
    pan: str
    aadhaar: str
    address: str = Field(min_length=5, max_length=200)
    city: str = Field(min_length=2)
    state: str = Field(min_length=2)
    pincode: str
    account_type: str = "SAVINGS"  # SAVINGS | CURRENT
    business_name: str = ""
    branch_id: int
    password: str = Field(min_length=6)
    mpin: str
    card_pin: str
    initial_deposit: int = Field(default=0, ge=0, le=MAX_OPENING_DEPOSIT)  # paise

    @field_validator("full_name")
    @classmethod
    def clean_name(cls, v: str) -> str:
        v = " ".join(v.split())
        if not re.fullmatch(r"[A-Za-z .]+", v):
            raise ValueError("Name can contain only letters, spaces and dots")
        return v.title()

    @field_validator("dob")
    @classmethod
    def adult(cls, v: date) -> date:
        today = date.today()
        age = today.year - v.year - ((today.month, today.day) < (v.month, v.day))
        if age < 18:
            raise ValueError("Account holder must be at least 18 years old")
        return v

    @field_validator("mobile")
    @classmethod
    def mobile_ok(cls, v: str) -> str:
        if not re.fullmatch(r"[6-9]\d{9}", v):
            raise ValueError("Enter a valid 10-digit Indian mobile number")
        return v

    @field_validator("pan")
    @classmethod
    def pan_ok(cls, v: str) -> str:
        v = v.upper().strip()
        if not re.fullmatch(r"[A-Z]{5}\d{4}[A-Z]", v):
            raise ValueError("PAN must look like ABCDE1234F")
        return v

    @field_validator("aadhaar")
    @classmethod
    def aadhaar_ok(cls, v: str) -> str:
        v = v.replace(" ", "")
        if not re.fullmatch(r"[2-9]\d{11}", v):
            raise ValueError("Aadhaar must be 12 digits and cannot start with 0 or 1")
        return v

    @field_validator("pincode")
    @classmethod
    def pincode_ok(cls, v: str) -> str:
        if not re.fullmatch(r"[1-9]\d{5}", v):
            raise ValueError("Enter a valid 6-digit PIN code")
        return v

    @field_validator("account_type")
    @classmethod
    def type_ok(cls, v: str) -> str:
        v = v.upper()
        if v not in ("SAVINGS", "CURRENT"):
            raise ValueError("Account type must be SAVINGS or CURRENT")
        return v

    @field_validator("mpin", "card_pin")
    @classmethod
    def pin_ok(cls, v: str) -> str:
        if not re.fullmatch(r"\d{4}", v):
            raise ValueError("PIN must be exactly 4 digits")
        return v


def _unique_digits(db: Session, model, column: str, prefix: str, length: int) -> str:
    while True:
        value = prefix + "".join(random.choices("0123456789", k=length - len(prefix)))
        if not db.query(model).filter(getattr(model, column) == value).first():
            return value


@router.post("/banks/{code}/open-account")
async def open_account(code: str, req: OpenAccountRequest, db: Session = Depends(get_db)):
    bank = db.get(Bank, code.upper())
    if not bank:
        raise HTTPException(404, "Bank not found")
    branch = db.get(Branch, req.branch_id)
    if not branch or branch.bank_code != bank.code:
        raise HTTPException(400, f"Choose a {bank.name} branch")
    if req.account_type == "CURRENT" and len(req.business_name.strip()) < 3:
        raise HTTPException(400, "Business / shop name is required for a current (merchant) account")

    # KYC checks
    blocked = db.get(PanBlacklist, req.pan)
    if blocked:
        raise HTTPException(403, "Account opening blocked: this PAN is linked to a cyber fraud case. "
                                 "Visit the branch with original documents.")
    existing = db.query(Customer).filter_by(bank_code=bank.code, pan=req.pan).first()
    if existing:
        raise HTTPException(409, f"You are already a {bank.name} customer (Customer ID {existing.cif}). "
                                 "Please log in.")
    if db.query(Customer).filter_by(bank_code=bank.code, mobile=req.mobile).first():
        raise HTTPException(409, "This mobile number is already registered with another customer")

    customer = Customer(
        bank_code=bank.code,
        cif=_unique_digits(db, Customer, "cif", bank.code, 12),
        full_name=req.full_name, dob=req.dob.isoformat(), gender=req.gender, mobile=req.mobile,
        email=req.email, pan=req.pan, aadhaar=req.aadhaar, address=req.address, city=req.city,
        state=req.state, pincode=req.pincode, password_hash=hash_secret(req.password),
    )
    db.add(customer)
    db.flush()

    account = Account(
        account_no=_unique_digits(db, Account, "account_no", bank.account_prefix, 12),
        bank_code=bank.code, customer_id=customer.id, branch_id=branch.id,
        account_type=req.account_type, business_name=req.business_name.strip(),
        mpin_hash=hash_secret(req.mpin),
        card_no=_unique_digits(db, Account, "card_no", bank.card_bin, 16),
        card_pin_hash=hash_secret(req.card_pin),
    )
    db.add(account)
    db.flush()

    if req.initial_deposit:
        move_money(db, amount=req.initial_deposit, channel="CASH", credit=account,
                   remark="Account opening deposit",
                   narration_cr=f"CASH DEP/ACCOUNT OPENING/{branch.name.upper()}",
                   location=Location(branch.lat, branch.lng, branch.name, "BRANCH"))
    db.commit()

    return {
        "message": f"Welcome to {bank.name}! Your account is ready.",
        "cif": customer.cif,
        "account_no": account.account_no,
        "ifsc": branch.ifsc,
        "branch": branch_out(branch),
        "card_no": account.card_no,
    }


class LoginRequest(BaseModel):
    bank_code: str
    login_id: str  # Customer ID or registered mobile number
    password: str


@router.post("/auth/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    bank_code = req.bank_code.upper()
    q = db.query(Customer).filter_by(bank_code=bank_code)
    customer = q.filter_by(cif=req.login_id.upper()).first() or q.filter_by(mobile=req.login_id).first()
    if not customer or not verify_secret(req.password, customer.password_hash):
        raise HTTPException(401, "Wrong Customer ID / mobile or password")
    token = new_token()
    db.add(LoginSession(token=token, customer_id=customer.id))
    db.commit()
    return {"token": token, "customer": customer_out(customer)}


@router.post("/auth/logout")
def logout(customer: Customer = Depends(current_customer), db: Session = Depends(get_db)):
    db.query(LoginSession).filter_by(customer_id=customer.id).delete()
    db.commit()
    return {"message": "Logged out"}


@router.get("/me")
def me(customer: Customer = Depends(current_customer)):
    return customer_out(customer)


def own_account(db: Session, customer: Customer, account_no: str) -> Account:
    account = db.get(Account, account_no)
    if not account or account.customer_id != customer.id:
        raise HTTPException(404, "Account not found")
    return account


@router.get("/accounts/{account_no}/passbook")
def passbook(account_no: str, customer: Customer = Depends(current_customer), db: Session = Depends(get_db)):
    account = own_account(db, customer, account_no)
    entries = (db.query(LedgerEntry).filter_by(account_no=account_no)
               .order_by(LedgerEntry.id).all())
    return {"account": account_out(account), "customer": customer_out(customer),
            "entries": [entry_out(e) for e in entries]}


class CardRequest(BaseModel):
    blocked: bool


@router.post("/accounts/{account_no}/card")
async def set_card_blocked(account_no: str, req: CardRequest,
                           customer: Customer = Depends(current_customer), db: Session = Depends(get_db)):
    account = own_account(db, customer, account_no)
    account.card_blocked = req.blocked
    db.commit()
    await manager.account_changed(account_no)
    return {"message": "Card blocked" if req.blocked else "Card unblocked", "card_blocked": req.blocked}


@router.get("/lookup")
def lookup_beneficiary(account_no: str, ifsc: str,
                       customer: Customer = Depends(current_customer), db: Session = Depends(get_db)):
    """Check an account before sending money; shows a masked name like real banks."""
    account = db.get(Account, account_no)
    if not account or account.branch.ifsc != ifsc.upper():
        raise HTTPException(404, "No account found with this account number and IFSC")
    bank = db.get(Bank, account.bank_code)
    return {"account_no": account.account_no, "name": mask_name(account.customer.full_name),
            "bank": bank.name, "branch": account.branch.name, "account_type": account.account_type,
            "business_name": account.business_name}
