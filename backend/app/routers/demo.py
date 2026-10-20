"""Demo helpers: reset everything, load the demo story, add fake cash. Not part of a real bank."""
import hmac
import os

import httpx
from fastapi import APIRouter, Depends, Header, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from ..db import Base, engine, get_db
from ..demo_story import StoryError, run_story
from ..ledger import Location, move_money, rupees
from ..models import Customer, PoliceOfficer, PoliceSession
from ..realtime import manager
from ..security import current_customer, new_token
from ..seed_data import seed
from . import crypto, officer, police
from .accounts import own_account

router = APIRouter(prefix="/api/demo", tags=["demo"])

# On the public cloud server, set ADMIN_KEY so strangers cannot wipe the demo.
# On the laptop it is unset and reset works without a key.
ADMIN_KEY = os.environ.get("ADMIN_KEY", "")


def _reset_database() -> None:
    """Drop every table and start again with the 5 banks, the exchange, police and bank officers."""
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    with Session(engine) as fresh:
        seed(fresh)
        crypto.ensure_exchange(fresh)
        police.ensure_police(fresh)
        officer.ensure_officers(fresh)


def _allowed(db: Session, x_admin_key: str, authorization: str) -> bool:
    """Admin key (if set), or a logged-in police officer (the demo's operator)."""
    if not ADMIN_KEY or (x_admin_key and hmac.compare_digest(x_admin_key, ADMIN_KEY)):
        return True
    token = authorization.removeprefix("Bearer ").strip()
    return bool(token and db.get(PoliceSession, token))


@router.post("/reset")
def reset(x_admin_key: str = Header(default=""), authorization: str = Header(default=""),
          db: Session = Depends(get_db)):
    """Wipe all customers and money; re-create the 5 banks (no demo story)."""
    if not _allowed(db, x_admin_key, authorization):
        raise HTTPException(403, "Only the police console (or the admin key) can reset the demo")
    db.close()
    _reset_database()
    return {"message": "Demo data reset"}


@router.post("/load-story")
async def load_story(request: Request, file_complaint: bool = False, x_admin_key: str = Header(default=""),
                     authorization: str = Header(default=""), db: Session = Depends(get_db)):
    """Wipes everything and plays the 8-person fraud story (optionally with the victim's complaint).

    Because the wipe also removes all logins, a fresh police login is returned.
    """
    if not _allowed(db, x_admin_key, authorization):
        raise HTTPException(403, "Only the police console (or the admin key) can reset the demo")
    db.close()
    _reset_database()
    # Play the story through this server's own APIs, in-process.
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=request.app), base_url="http://demo") as client:
        try:
            story = await run_story(client, file_complaint=file_complaint, log=lambda _msg: None)
        except StoryError as e:
            raise HTTPException(500, f"Demo story failed: {e}")
    with Session(engine) as fresh:
        o = fresh.query(PoliceOfficer).filter_by(badge_id=police.DEMO_OFFICER["badge_id"]).first()
        token = new_token()
        fresh.add(PoliceSession(token=token, officer_id=o.id))
        fresh.commit()
    return {**story, "police_token": token}


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
