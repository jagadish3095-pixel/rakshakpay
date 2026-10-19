"""The only place where money moves.

Every rupee that enters or leaves an account goes through move_money(),
which updates balances, writes passbook lines and records the transaction.
"""
import random
from dataclasses import dataclass

from fastapi import HTTPException
from sqlalchemy.orm import Session

from .models import Account, LedgerEntry, Transaction


@dataclass
class Location:
    lat: float | None = None
    lng: float | None = None
    label: str = ""
    source: str = ""  # GPS | DEMO | ATM | BRANCH


def rupees(paise: int) -> str:
    return f"₹{paise / 100:,.2f}"


def new_utr(db: Session) -> str:
    """12-digit unique transaction reference (like a real IMPS/UPI RRN)."""
    while True:
        utr = str(random.randint(10**11, 10**12 - 1))
        if not db.query(Transaction).filter_by(utr=utr).first():
            return utr


def move_money(
    db: Session,
    *,
    amount: int,
    channel: str,
    debit: Account | None = None,
    credit: Account | None = None,
    remark: str = "",
    narration_dr: str = "",
    narration_cr: str = "",
    location: Location | None = None,
    atm_id: str | None = None,
) -> Transaction:
    """Debit one account and/or credit another. Caller must commit."""
    if amount <= 0:
        raise HTTPException(400, "Amount must be more than zero")
    if debit and debit.available_balance < amount:
        raise HTTPException(400, f"Insufficient balance. Available: {rupees(max(debit.available_balance, 0))}")

    loc = location or Location()
    txn = Transaction(
        utr=new_utr(db), channel=channel, amount=amount,
        debit_account=debit.account_no if debit else None,
        credit_account=credit.account_no if credit else None,
        remark=remark, lat=loc.lat, lng=loc.lng,
        location_label=loc.label, location_source=loc.source, atm_id=atm_id,
    )
    db.add(txn)
    db.flush()  # gives txn.id

    if debit:
        debit.balance -= amount
        db.add(LedgerEntry(account_no=debit.account_no, txn_id=txn.id, entry_type="DR",
                           amount=amount, balance_after=debit.balance,
                           narration=f"{narration_dr}/{txn.utr}"))
    if credit:
        credit.balance += amount
        db.add(LedgerEntry(account_no=credit.account_no, txn_id=txn.id, entry_type="CR",
                           amount=amount, balance_after=credit.balance,
                           narration=f"{narration_cr}/{txn.utr}"))
    return txn
