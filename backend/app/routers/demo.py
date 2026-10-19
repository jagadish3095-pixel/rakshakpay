"""Demo helpers: reset everything, add fake cash. Not part of a real bank."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from ..db import Base, engine, get_db
from ..ledger import Location, move_money, rupees
from ..models import Account
from ..realtime import manager
from ..seed_data import seed

router = APIRouter(prefix="/api/demo", tags=["demo"])


@router.post("/reset")
def reset(db: Session = Depends(get_db)):
    """Wipe all customers and money; re-create the 5 banks."""
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
async def cash_deposit(req: CashDepositRequest, db: Session = Depends(get_db)):
    """Simulates depositing cash at the home branch (to load fake money)."""
    account = db.get(Account, req.account_no)
    if not account:
        raise HTTPException(404, "Account not found")
    br = account.branch
    move_money(db, amount=req.amount, channel="CASH", credit=account, remark="Cash deposit",
               narration_cr=f"CASH DEP/{br.name.upper()}",
               location=Location(br.lat, br.lng, br.name, "BRANCH"))
    db.commit()
    await manager.account_changed(account.account_no)
    return {"message": f"{rupees(req.amount)} deposited", "balance": account.balance}
