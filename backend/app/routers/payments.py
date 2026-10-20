"""Sending money (IMPS / NEFT / within bank) and ATM cash withdrawal."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from ..db import get_db
from ..ledger import Location, move_money, rupees
from ..models import Account, Atm, Bank, Customer
from ..realtime import manager
from ..security import current_customer, verify_secret
from . import crypto
from ..fraud import payee_warning
from .accounts import own_account

router = APIRouter(prefix="/api", tags=["payments"])

MAX_TRANSFER = 5_00_000 * 100  # ₹5 lakh per transaction
MAX_ATM = 20_000 * 100  # ₹20,000 per withdrawal


class LocationIn(BaseModel):
    """Where the phone was when the payment was made."""

    lat: float | None = None
    lng: float | None = None
    label: str = ""
    source: str = "GPS"  # GPS | DEMO

    def to_location(self) -> Location:
        # Trim to the database column sizes (PostgreSQL rejects longer text).
        return Location(self.lat, self.lng, self.label[:120], self.source[:10] if self.lat is not None else "")


def ensure_can_debit(account: Account) -> None:
    """Block outgoing money for accounts that are not active."""
    if account.status != "ACTIVE":
        raise HTTPException(403, "Debit services are blocked on this account. "
                                 "Please visit your home branch for verification.")


class TransferRequest(BaseModel):
    from_account: str
    to_account: str
    to_ifsc: str
    amount: int = Field(gt=0, le=MAX_TRANSFER)  # paise
    mode: str = "IMPS"  # IMPS | NEFT
    mpin: str
    remark: str = Field(default="", max_length=60)
    location: LocationIn = LocationIn()
    # Must be true to send money to an account on the mule list.
    acknowledge_warning: bool = False


@router.post("/transfers")
async def transfer(req: TransferRequest, customer: Customer = Depends(current_customer),
                   db: Session = Depends(get_db)):
    sender = own_account(db, customer, req.from_account)
    if not verify_secret(req.mpin, sender.mpin_hash):
        raise HTTPException(401, "Incorrect transaction PIN")
    ensure_can_debit(sender)

    receiver = db.get(Account, req.to_account)
    if not receiver or receiver.branch.ifsc != req.to_ifsc.upper():
        raise HTTPException(404, "Account number and IFSC do not match any account")
    if receiver.account_no == sender.account_no:
        raise HTTPException(400, "You cannot transfer to the same account")
    if (warning := payee_warning(receiver)) and not req.acknowledge_warning:
        raise HTTPException(409, warning)

    from_bank = db.get(Bank, sender.bank_code)
    to_bank = db.get(Bank, receiver.bank_code)
    channel = "INTERNAL" if from_bank.code == to_bank.code else req.mode.upper()
    if channel not in ("INTERNAL", "IMPS", "NEFT"):
        raise HTTPException(400, "Mode must be IMPS or NEFT")

    to_name = receiver.business_name or receiver.customer.full_name
    txn = move_money(
        db, amount=req.amount, channel=channel, debit=sender, credit=receiver, remark=req.remark,
        narration_dr=f"{channel}/DR/{to_name.upper()}/{to_bank.ifsc_prefix}",
        narration_cr=f"{channel}/CR/{customer.full_name.upper()}/{from_bank.ifsc_prefix}",
        location=req.location.to_location(),
    )
    db.commit()
    await manager.account_changed(sender.account_no, receiver.account_no)
    # Bank transfer to the crypto exchange: credit the sender's CoinVault wallet, or refund.
    note = ""
    if receiver.account_no == crypto.exchange_account(db).account_no:
        note = await crypto.handle_exchange_credit(db, txn, sender)
    return {"message": f"{rupees(req.amount)} sent to {to_name}", "utr": txn.utr, "note": note,
            "channel": channel, "date": txn.created_at.isoformat(),
            "balance": sender.balance, "available_balance": sender.available_balance}


class AtmWithdrawRequest(BaseModel):
    atm_id: str
    card_no: str
    card_pin: str
    amount: int = Field(gt=0, le=MAX_ATM)  # paise


@router.post("/atm/withdraw")
async def atm_withdraw(req: AtmWithdrawRequest, db: Session = Depends(get_db)):
    """Card + PIN withdrawal. Works without logging in, like a real ATM."""
    atm = db.get(Atm, req.atm_id)
    if not atm:
        raise HTTPException(404, "ATM not found")
    account = db.query(Account).filter_by(card_no=req.card_no.replace(" ", "")).first()
    if not account or not verify_secret(req.card_pin, account.card_pin_hash):
        raise HTTPException(401, "Invalid card or PIN")
    if account.card_blocked:
        raise HTTPException(403, "This card is blocked")
    ensure_can_debit(account)
    if req.amount % (100 * 100):
        raise HTTPException(400, "Amount must be in multiples of ₹100")

    txn = move_money(
        db, amount=req.amount, channel="ATM", debit=account, remark="ATM cash withdrawal",
        narration_dr=f"ATM WDL/{atm.name.upper()}/{atm.city.upper()}",
        location=Location(atm.lat, atm.lng, atm.name, "ATM"), atm_id=atm.id,
    )
    db.commit()
    await manager.account_changed(account.account_no)
    return {"message": f"Please collect your cash: {rupees(req.amount)}", "utr": txn.utr,
            "atm": atm.name, "date": txn.created_at.isoformat(),
            "available_balance": account.available_balance}
