"""Demo helpers: reset everything, add fake cash. Not part of a real bank."""
import hmac
import os

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from ..db import Base, engine, get_db
from ..ledger import Location, move_money, rupees
from ..models import Customer
from ..realtime import manager
from ..security import current_customer
from ..seed_data import seed
from .accounts import own_account

router = APIRouter(prefix="/api/demo", tags=["demo"])

# On the public cloud server, set ADMIN_KEY so strangers cannot wipe the demo.
# On the laptop it is unset and reset works without a key.
ADMIN_KEY = os.environ.get("ADMIN_KEY", "")


@router.post("/reset")
def reset(x_admin_key: str = Header(default=""), db: Session = Depends(get_db)):
    """Wipe all customers and money; re-create the 5 banks."""
    if ADMIN_KEY and not hmac.compare_digest(x_admin_key, ADMIN_KEY):
        raise HTTPException(403, "Admin key required to reset the demo")
    db.close()
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    with Session(engine) as fresh:
        seed(fresh)
    return {"message": "Demo data reset"}


class CashDepositRequest(BaseModel):
    account_no: str
    amount: int = Field(gt=0, le=10_00_000 * 100)  # paise


@router.post("/cash-deposit")
async def cash_deposit(req: CashDepositRequest, customer: Customer = Depends(current_customer),
                       db: Session = Depends(get_db)):
    """Simulates depositing cash at the home branch (to load fake money into your own account)."""
    account = own_account(db, customer, req.account_no)
    br = account.branch
    move_money(db, amount=req.amount, channel="CASH", credit=account, remark="Cash deposit",
               narration_cr=f"CASH DEP/{br.name.upper()}",
               location=Location(br.lat, br.lng, br.name, "BRANCH"))
    db.commit()
    await manager.account_changed(account.account_no)
    return {"message": f"{rupees(req.amount)} deposited", "balance": account.balance}
