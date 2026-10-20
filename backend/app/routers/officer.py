"""Bank branch staff: find a customer, see their fraud involvement, and run the mule
verification (re-KYC + statement + recommendation) that goes to the police for a decision."""
from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import or_
from sqlalchemy.orm import Session

from ..db import get_db
from ..fraud import DECISIONS, MULE
from ..models import (Account, Bank, BankOfficer, Branch, Complaint, CourtOrder, Customer, Notice, OfficerSession,
                      TrailNode, VerificationCase)
from ..out import account_out, mask
from ..realtime import manager
from ..security import hash_secret, new_token, verify_secret

router = APIRouter(prefix="/api/officer", tags=["bank officer"])

# One demo officer per bank (fake). Password for all: officer123
DEMO_OFFICERS = {
    "SAHY": "Anitha Gowda", "GANG": "Rakesh Srivastava", "KAVR": "Lakshmi Narayanan",
    "NARM": "Hitesh Patel", "GODA": "Sravani Reddy",
}
DEMO_PASSWORD = "officer123"
KYC_CHECKS = ["pan_original", "aadhaar_original", "live_photo", "mobile_otp"]
REASONS = [
    "Account hacked / login stolen",
    "Identity documents misused (account opened without my knowledge)",
    "Tricked by a job / part-time task offer",
    "Paid a commission to receive money for someone",
    "Knowingly rented or sold the account",
    "Other",
]


def ensure_officers(db: Session) -> None:
    for code, name in DEMO_OFFICERS.items():
        staff_id = f"{code}001"
        if db.query(BankOfficer).filter_by(staff_id=staff_id).first():
            continue
        branch = db.query(Branch).filter_by(bank_code=code).order_by(Branch.id).first()
        db.add(BankOfficer(staff_id=staff_id, name=name, bank_code=code, branch_id=branch.id,
                           password_hash=hash_secret(DEMO_PASSWORD)))
    db.commit()


def current_officer(authorization: str = Header(default=""), db: Session = Depends(get_db)) -> BankOfficer:
    token = authorization.removeprefix("Bearer ").strip()
    session = db.get(OfficerSession, token) if token else None
    if not session:
        raise HTTPException(401, "Please log in again")
    return db.get(BankOfficer, session.officer_id)


def _officer_out(db: Session, o: BankOfficer) -> dict:
    return {"staff_id": o.staff_id, "name": o.name, "bank_code": o.bank_code,
            "bank": db.get(Bank, o.bank_code).name, "branch": o.branch.name}


class LoginRequest(BaseModel):
    bank_code: str
    staff_id: str
    password: str


@router.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    o = db.query(BankOfficer).filter_by(staff_id=req.staff_id.upper().strip()).first()
    if not o or o.bank_code != req.bank_code.upper() or not verify_secret(req.password, o.password_hash):
        raise HTTPException(401, "Wrong staff ID or password for this bank")
    token = new_token()
    db.add(OfficerSession(token=token, officer_id=o.id))
    db.commit()
    return {"token": token, "officer": _officer_out(db, o)}


@router.get("/me")
def me(o: BankOfficer = Depends(current_officer), db: Session = Depends(get_db)):
    return {**_officer_out(db, o), "kyc_checks": KYC_CHECKS, "reasons": REASONS}


# ---------------------------------------------------------------- customers


def _customer_row(c: Customer) -> dict:
    statuses = [a.status for a in c.accounts]
    return {"cif": c.cif, "name": c.full_name, "mobile": c.mobile, "pan": c.pan, "city": c.city,
            "accounts": [a.account_no for a in c.accounts],
            "flagged": any(s != "ACTIVE" for s in statuses), "statuses": statuses}


@router.get("/search")
def search(q: str, o: BankOfficer = Depends(current_officer), db: Session = Depends(get_db)):
    """Customers of this officer's bank by account no, mobile, PAN, Customer ID or name."""
    q = q.strip()
    if len(q) < 3:
        raise HTTPException(400, "Type at least 3 characters")
    rows = (db.query(Customer).outerjoin(Account, Account.customer_id == Customer.id)
            .filter(Customer.bank_code == o.bank_code)
            .filter(or_(Account.account_no == q, Customer.mobile == q, Customer.pan == q.upper(),
                        Customer.cif == q.upper(), Customer.full_name.ilike(f"%{q}%")))
            .distinct().limit(30).all())
    return [_customer_row(c) for c in rows]


@router.get("/flagged")
def flagged(o: BankOfficer = Depends(current_officer), db: Session = Depends(get_db)):
    """Customers of this bank on the mule list, or with money on hold."""
    accs = (db.query(Account).filter(Account.bank_code == o.bank_code)
            .filter(or_(Account.status != "ACTIVE", Account.lien_amount > 0)).all())
    seen, out = set(), []
    for a in accs:
        if a.customer_id not in seen:
            seen.add(a.customer_id)
            out.append({**_customer_row(a.customer), "lien": sum(x.lien_amount for x in a.customer.accounts)})
    return out


def case_out(db: Session, c: VerificationCase) -> dict:
    a = c.account
    return {
        "id": c.id, "account_no": a.account_no, "customer": a.customer.full_name, "cif": a.customer.cif,
        "pan": a.customer.pan, "mobile": a.customer.mobile, "bank": db.get(Bank, a.bank_code).name,
        "branch": c.officer.branch.name, "officer": c.officer.name, "kyc_checks": c.kyc_checks.split(","),
        "reason_category": c.reason_category, "statement": c.statement, "recommendation": c.recommendation,
        "officer_notes": c.officer_notes, "undertaking_signed": c.undertaking_signed,
        "awareness_done": c.awareness_done, "status": c.status, "decision": c.decision,
        "police_remarks": c.police_remarks, "decided_by": c.decided_by,
        "date": c.created_at.isoformat(), "decided_at": c.decided_at.isoformat() if c.decided_at else None,
        "involvement": _involvement(db, [a.account_no]),
    }


def _involvement(db: Session, account_nos: list[str]) -> list[dict]:
    """Every complaint whose money trail passed through these accounts."""
    out = []
    for n in db.query(TrailNode).filter(TrailNode.account_no.in_(account_nos), TrailNode.role == "MULE"):
        c = db.get(Complaint, n.complaint_id)
        orders = db.query(CourtOrder).filter_by(complaint_id=c.id, account_no=n.account_no).all()
        out.append({
            "complaint": c.ack_no, "category": c.category, "date": c.created_at.isoformat(), "account_no": n.account_no,
            "received": n.received, "forwarded": n.forwarded, "held": n.held, "spent_merchant": n.spent_merchant,
            "cashed_out": n.cashed_out, "to_crypto": n.to_crypto, "returned_to_victim": n.released,
            "court_orders": [{"amount": o.amount, "status": o.status, "reason": o.reason} for o in orders],
        })
    return out


@router.get("/customers/{cif}")
def customer(cif: str, o: BankOfficer = Depends(current_officer), db: Session = Depends(get_db)):
    c = db.query(Customer).filter_by(cif=cif.upper(), bank_code=o.bank_code).first()
    if not c:
        raise HTTPException(404, "Customer not found in your bank")
    nos = [a.account_no for a in c.accounts]
    # Same PAN in other banks (the officer sees only that they exist and their status).
    other = (db.query(Account).join(Customer).filter(Customer.pan == c.pan, Customer.bank_code != o.bank_code).all())
    cases = db.query(VerificationCase).filter(VerificationCase.account_no.in_(nos)).order_by(VerificationCase.id.desc())
    notices = db.query(Notice).filter(Notice.account_no.in_(nos)).order_by(Notice.id.desc()).limit(20)
    return {
        "cif": c.cif, "name": c.full_name, "dob": c.dob, "gender": c.gender, "mobile": c.mobile, "pan": c.pan,
        "aadhaar_masked": mask(c.aadhaar), "address": f"{c.address}, {c.city}, {c.state} - {c.pincode}",
        "accounts": [account_out(a) for a in c.accounts],
        "other_banks": [{"bank": db.get(Bank, a.bank_code).name, "account_no_masked": mask(a.account_no),
                         "status": a.status} for a in other],
        "involvement": _involvement(db, nos),
        "cases": [case_out(db, x) for x in cases],
        "notices": [{"title": n.title, "body": n.body, "date": n.created_at.isoformat()} for n in notices],
    }


# ---------------------------------------------------------------- verification


class VerificationRequest(BaseModel):
    account_no: str
    kyc_checks: list[str]
    reason_category: str
    statement: str = Field(min_length=10, max_length=2000)
    recommendation: str
    officer_notes: str = Field(default="", max_length=1000)
    undertaking_signed: bool = False
    awareness_done: bool = False


@router.post("/verifications")
async def start_verification(req: VerificationRequest, o: BankOfficer = Depends(current_officer),
                             db: Session = Depends(get_db)):
    a = db.get(Account, req.account_no)
    if not a or a.bank_code != o.bank_code:
        raise HTTPException(404, "Account not found in your bank")
    if a.status != MULE:
        raise HTTPException(400, "Only accounts under verification (suspected mule) need this")
    if missing := [k for k in KYC_CHECKS if k not in req.kyc_checks]:
        raise HTTPException(400, f"Complete re-KYC first: {', '.join(missing)}")
    if req.reason_category not in REASONS:
        raise HTTPException(400, "Choose what the customer says happened")
    if req.recommendation not in DECISIONS:
        raise HTTPException(400, "Recommendation must be INNOCENT, TRICKED or INVOLVED")
    if req.recommendation == "TRICKED" and not (req.undertaking_signed and req.awareness_done):
        raise HTTPException(400, "For 'tricked', the customer must sign the undertaking and attend the awareness session")
    if db.query(VerificationCase).filter_by(account_no=a.account_no, status="PENDING_POLICE").first():
        raise HTTPException(409, "A verification for this account is already waiting for the police")

    case = VerificationCase(
        account_no=a.account_no, officer_id=o.id, kyc_checks=",".join(req.kyc_checks),
        reason_category=req.reason_category, statement=req.statement.strip(), recommendation=req.recommendation,
        officer_notes=req.officer_notes.strip(), undertaking_signed=req.undertaking_signed,
        awareness_done=req.awareness_done,
    )
    db.add(case)
    db.add(Notice(account_no=a.account_no, kind="INFO", title="Branch verification submitted",
                  body=f"Your re-KYC and statement were recorded at {o.branch.name} by {o.name} and sent to the "
                       "cyber police for review. You will get a notice when they decide."))
    db.commit()
    await manager.account_changed(a.account_no)
    return case_out(db, case)


@router.get("/verifications")
def my_cases(o: BankOfficer = Depends(current_officer), db: Session = Depends(get_db)):
    rows = (db.query(VerificationCase).join(Account).filter(Account.bank_code == o.bank_code)
            .order_by(VerificationCase.id.desc()))
    return [case_out(db, c) for c in rows]

