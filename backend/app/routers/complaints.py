"""Victims report fraud (like calling 1930) from the bank app or RakshakPay.

Filing a complaint immediately runs the fraud engine (app/fraud.py).
"""
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from .. import fraud
from ..db import get_db
from ..models import Account, Complaint, Customer, Notice, Transaction, UpiUser, Vpa
from ..realtime import manager
from ..security import current_customer, current_upi_user
from .payments import LocationIn

router = APIRouter(prefix="/api", tags=["complaints"])

CATEGORIES = [
    "UPI / payment fraud", "Fake KYC / bank call", "Investment / trading scam", "Job / task scam",
    "Online shopping fraud", "Sextortion / blackmail", "Other",
]
MAX_AGE = timedelta(days=30)


class ComplaintRequest(BaseModel):
    utr: str
    category: str
    description: str = Field(default="", max_length=1000)
    location: LocationIn = LocationIn()


@router.get("/complaint-categories")
def categories():
    return CATEGORIES


def victim_complaint_out(c: Complaint) -> dict:
    """What the victim sees: acknowledgement and status only. Investigation details
    (accounts traced, mules, holds) are shown to the police, not to the complainant."""
    return {
        "id": c.id, "ack_no": c.ack_no, "date": c.created_at.isoformat(), "amount": c.amount,
        "category": c.category, "description": c.description, "utr": c.victim_txn.utr,
        "status": "REFUNDED" if c.status == "REFUNDED" else "UNDER_INVESTIGATION",
        "recovered": sum(n.released + n.crypto_released for n in c.nodes),
    }


def complaint_out(c: Complaint) -> dict:
    """Full summary for the police."""
    held = sum(n.held for n in c.nodes)
    recovered = sum(n.released + n.crypto_released for n in c.nodes)
    return {
        "id": c.id, "ack_no": c.ack_no, "date": c.created_at.isoformat(), "amount": c.amount,
        "category": c.category, "description": c.description, "status": c.status, "utr": c.victim_txn.utr,
        "accounts_traced": sum(1 for n in c.nodes if n.role != "VICTIM"),
        "mules": sum(1 for n in c.nodes if n.role == "MULE"),
        "held": held, "recovered": recovered,
    }


async def file_complaint(db: Session, *, accounts: list[str], req: ComplaintRequest, channel: str) -> dict:
    txn = db.query(Transaction).filter_by(utr=req.utr.strip()).first()
    if not txn or txn.debit_account not in accounts:
        raise HTTPException(404, "Transaction not found in your account")
    if txn.credit_account is None or txn.channel in ("ATM", "CASH", "REFUND"):
        raise HTTPException(400, "Only payments to another account can be reported here")
    if db.query(Complaint).filter_by(victim_txn_id=txn.id).first():
        raise HTTPException(409, "A complaint for this transaction is already registered")
    if datetime.now() - txn.created_at > MAX_AGE:
        raise HTTPException(400, "This transaction is too old to report here. Please visit the police station.")
    if req.category not in CATEGORIES:
        raise HTTPException(400, "Choose a complaint category")

    loc = req.location.to_location()
    complaint = Complaint(ack_no="PENDING", victim_txn_id=txn.id, victim_account=txn.debit_account, amount=txn.amount,
                          category=req.category, description=req.description.strip(), channel=channel,
                          lat=loc.lat, lng=loc.lng, location_label=loc.label)
    db.add(complaint)
    db.flush()
    complaint.ack_no = f"1930-{datetime.now().year}-{complaint.id:06d}"
    touched = fraud.trace(db, complaint)  # commits
    await manager.account_changed(*touched)
    db.refresh(complaint)
    return victim_complaint_out(complaint)


def _complaints_for(db: Session, accounts: list[str]) -> list[dict]:
    rows = (db.query(Complaint).filter(Complaint.victim_account.in_(accounts))
            .order_by(Complaint.id.desc()).all())
    return [victim_complaint_out(c) for c in rows]


def _notices_for(db: Session, accounts: list[str]) -> list[dict]:
    rows = db.query(Notice).filter(Notice.account_no.in_(accounts)).order_by(Notice.id.desc()).limit(50)
    return [{"id": n.id, "account_no": n.account_no, "kind": n.kind, "title": n.title, "body": n.body,
             "date": n.created_at.isoformat()} for n in rows]


# ---------------------------------------------------------------- bank app


def _bank_accounts(db: Session, customer: Customer) -> list[str]:
    return [a.account_no for a in db.query(Account).filter_by(customer_id=customer.id)]


@router.post("/complaints")
async def complain_from_bank(req: ComplaintRequest, customer: Customer = Depends(current_customer),
                             db: Session = Depends(get_db)):
    return await file_complaint(db, accounts=_bank_accounts(db, customer), req=req, channel="BANK_APP")


@router.get("/complaints")
def my_complaints_bank(customer: Customer = Depends(current_customer), db: Session = Depends(get_db)):
    return _complaints_for(db, _bank_accounts(db, customer))


@router.get("/notices")
def my_notices_bank(customer: Customer = Depends(current_customer), db: Session = Depends(get_db)):
    return _notices_for(db, _bank_accounts(db, customer))


# ---------------------------------------------------------------- UPI app


def _upi_accounts(db: Session, user: UpiUser) -> list[str]:
    return [v.account_no for v in db.query(Vpa).filter_by(upi_user_id=user.id)]


@router.post("/upi/complaints")
async def complain_from_upi(req: ComplaintRequest, user: UpiUser = Depends(current_upi_user),
                            db: Session = Depends(get_db)):
    return await file_complaint(db, accounts=_upi_accounts(db, user), req=req, channel="UPI_APP")


@router.get("/upi/complaints")
def my_complaints_upi(user: UpiUser = Depends(current_upi_user), db: Session = Depends(get_db)):
    return _complaints_for(db, _upi_accounts(db, user))


@router.get("/upi/notices")
def my_notices_upi(user: UpiUser = Depends(current_upi_user), db: Session = Depends(get_db)):
    return _notices_for(db, _upi_accounts(db, user))
