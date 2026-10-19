"""Public information: banks, branches, ATMs, cities."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Atm, Bank, Branch
from ..out import atm_out, bank_out, branch_out
from ..seed_data import CITIES

router = APIRouter(prefix="/api", tags=["meta"])


@router.get("/banks")
def list_banks(db: Session = Depends(get_db)):
    return [bank_out(b) for b in db.query(Bank).order_by(Bank.name)]


@router.get("/banks/{code}")
def bank_details(code: str, db: Session = Depends(get_db)):
    bank = db.get(Bank, code.upper())
    if not bank:
        raise HTTPException(404, "Bank not found")
    branches = db.query(Branch).filter_by(bank_code=bank.code).order_by(Branch.name)
    atms = db.query(Atm).filter_by(bank_code=bank.code).order_by(Atm.name)
    return {**bank_out(bank),
            "branches": [branch_out(b) for b in branches],
            "atms": [atm_out(a) for a in atms]}


@router.get("/atms")
def list_atms(db: Session = Depends(get_db)):
    """All ATMs of all banks (any card works at any ATM, like real India)."""
    return [atm_out(a) for a in db.query(Atm).order_by(Atm.city, Atm.name)]


@router.get("/cities")
def list_cities():
    return [{"name": n, "state": s, "lat": lat, "lng": lng} for n, (s, lat, lng) in CITIES.items()]
