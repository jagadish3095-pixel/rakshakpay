"""Cyber Police / I4C view: complaints, money trails with GPS, court orders, refunds, mule list."""
import math

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel
from sqlalchemy import func
from sqlalchemy.orm import Session

from .. import fraud
from ..db import get_db
from ..models import (Account, Bank, Complaint, CourtOrder, PoliceOfficer, PoliceSession, Transaction, TrailEdge,
                      TrailNode)
from ..realtime import manager
from ..security import hash_secret, new_token, verify_secret
from ..seed_data import CITIES
from .complaints import complaint_out

router = APIRouter(prefix="/api/police", tags=["police"])

# Demo officer (fake). Change or add officers in production.
DEMO_OFFICER = {"badge_id": "CYB001", "name": "Inspector Meera Nair", "unit": "I4C Cyber Crime Cell",
                "password": "police123"}


def ensure_police(db: Session) -> None:
    if not db.query(PoliceOfficer).filter_by(badge_id=DEMO_OFFICER["badge_id"]).first():
        db.add(PoliceOfficer(badge_id=DEMO_OFFICER["badge_id"], name=DEMO_OFFICER["name"], unit=DEMO_OFFICER["unit"],
                             password_hash=hash_secret(DEMO_OFFICER["password"])))
        db.commit()


def current_officer(authorization: str = Header(default=""), db: Session = Depends(get_db)) -> PoliceOfficer:
    token = authorization.removeprefix("Bearer ").strip()
    session = db.get(PoliceSession, token) if token else None
    if not session:
        raise HTTPException(401, "Please log in again")
    return db.get(PoliceOfficer, session.officer_id)


class LoginRequest(BaseModel):
    badge_id: str
    password: str


@router.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    officer = db.query(PoliceOfficer).filter_by(badge_id=req.badge_id.upper().strip()).first()
    if not officer or not verify_secret(req.password, officer.password_hash):
        raise HTTPException(401, "Wrong badge ID or password")
    token = new_token()
    db.add(PoliceSession(token=token, officer_id=officer.id))
    db.commit()
    return {"token": token, "officer": {"badge_id": officer.badge_id, "name": officer.name, "unit": officer.unit}}


@router.get("/me")
def me(officer: PoliceOfficer = Depends(current_officer)):
    return {"badge_id": officer.badge_id, "name": officer.name, "unit": officer.unit}


# ---------------------------------------------------------------- helpers


def _place(lat, lng, label, date=None):
    return None if lat is None else {"lat": lat, "lng": lng, "label": label, "date": date}


def _last_seen(db: Session, account_no: str) -> dict | None:
    """Latest place this account was used from (phone GPS or ATM)."""
    t = (db.query(Transaction).filter(Transaction.debit_account == account_no, Transaction.lat.isnot(None))
         .order_by(Transaction.id.desc()).first())
    return _place(t.lat, t.lng, t.location_label, t.created_at.isoformat()) if t else None


def _node_out(db: Session, n: TrailNode) -> dict:
    a = n.account
    br = a.branch
    return {
        "account_no": a.account_no, "role": n.role, "level": n.level, "holder": a.customer.full_name,
        "business_name": a.business_name, "pan": a.customer.pan, "mobile": a.customer.mobile,
        "bank_code": a.bank_code, "bank": db.get(Bank, a.bank_code).name, "branch": br.name, "ifsc": br.ifsc,
        "status": a.status, "balance": a.balance, "lien_amount": a.lien_amount,
        "home": _place(br.lat, br.lng, f"{br.name} (home branch)"), "last_seen": _last_seen(db, a.account_no),
        "received": n.received, "forwarded": n.forwarded, "cashed_out": n.cashed_out,
        "spent_merchant": n.spent_merchant, "to_crypto": n.to_crypto, "crypto_frozen": n.crypto_frozen,
        "crypto_escaped": n.crypto_escaped, "held": n.held, "recovery_approved": n.recovery_approved,
        "released": n.released, "crypto_released": n.crypto_released,
    }


def _edge_out(e: TrailEdge) -> dict:
    t = e.txn
    return {"utr": t.utr, "date": t.created_at.isoformat(), "kind": e.kind, "channel": t.channel,
            "from_account": e.from_account, "to_account": e.to_account, "amount": e.amount,
            "txn_amount": e.txn_amount, "location": _place(t.lat, t.lng, t.location_label), "atm_id": t.atm_id}


def _order_out(db: Session, o: CourtOrder) -> dict:
    return {"id": o.id, "complaint_ack": o.complaint.ack_no, "account_no": o.account_no,
            "holder": o.account.customer.full_name, "bank": db.get(Bank, o.account.bank_code).name,
            "amount": o.amount, "reason": o.reason, "status": o.status, "application_text": o.application_text,
            "date": o.created_at.isoformat(), "approved_at": o.approved_at.isoformat() if o.approved_at else None,
            "approved_by": o.approved_by}


def _totals(c: Complaint, orders: list[CourtOrder]) -> dict:
    nodes = c.nodes
    return {
        "held": sum(n.held for n in nodes),
        "crypto_frozen": sum(n.crypto_frozen for n in nodes),
        "cashed_out": sum(n.cashed_out for n in nodes),
        "spent_merchant": sum(n.spent_merchant for n in nodes),
        "crypto_escaped": sum(n.crypto_escaped for n in nodes),
        "court_pending": sum(o.amount for o in orders if o.status == "PENDING"),
        "court_approved": sum(o.amount for o in orders if o.status == "APPROVED"),
        "recovered": sum(n.released + n.crypto_released for n in nodes),
    }


# ---------------------------------------------------------------- endpoints


def _nearest_city(lat: float, lng: float) -> str | None:
    best, best_km = None, 150.0  # ignore points far from every known city
    for name, (_state, clat, clng) in CITIES.items():
        km = 6371 * 2 * math.asin(math.sqrt(
            math.sin(math.radians(clat - lat) / 2) ** 2
            + math.cos(math.radians(lat)) * math.cos(math.radians(clat)) * math.sin(math.radians(clng - lng) / 2) ** 2))
        if km < best_km:
            best, best_km = name, km
    return best


def _hotspots(db: Session, nodes: list[TrailNode], atm_edges: list[TrailEdge]) -> list[dict]:
    """Cities where mules operate (where they forwarded money from) and where cash was withdrawn."""
    spots: dict[str, dict] = {}

    def spot(city: str) -> dict:
        state, lat, lng = CITIES[city]
        return spots.setdefault(city, {"city": city, "state": state, "lat": lat, "lng": lng,
                                       "mules": 0, "amount": 0, "cashouts": 0})

    for n in nodes:
        if n.role != "MULE":
            continue
        first_out = (db.query(TrailEdge).join(TrailEdge.txn)
                     .filter(TrailEdge.complaint_id == n.complaint_id, TrailEdge.from_account == n.account_no,
                             Transaction.lat.isnot(None)).order_by(TrailEdge.id).first())
        lat, lng = (first_out.txn.lat, first_out.txn.lng) if first_out else (n.account.branch.lat, n.account.branch.lng)
        if city := _nearest_city(lat, lng):
            s = spot(city)
            s["mules"] += 1
            s["amount"] += n.received
    for e in atm_edges:
        if e.txn.lat is not None and (city := _nearest_city(e.txn.lat, e.txn.lng)):
            spot(city)["cashouts"] += 1
    return sorted(spots.values(), key=lambda s: (s["mules"] + s["cashouts"], s["amount"]), reverse=True)


@router.get("/dashboard")
def dashboard(_o: PoliceOfficer = Depends(current_officer), db: Session = Depends(get_db)):
    complaints = db.query(Complaint).all()
    nodes = db.query(TrailNode).all()
    atm_edges = db.query(TrailEdge).filter_by(kind="ATM").all()
    return {
        "hotspots": _hotspots(db, nodes, atm_edges),
        "complaints": len(complaints),
        "reported_amount": sum(c.amount for c in complaints),
        "held": sum(n.held for n in nodes),
        "crypto_frozen": sum(n.crypto_frozen for n in nodes),
        "recovered": sum(n.released + n.crypto_released for n in nodes),
        "mule_accounts": db.query(Account).filter(Account.status != "ACTIVE").count(),
        "court_pending": db.query(CourtOrder).filter_by(status="PENDING").count(),
        # Where victims' money was taken out as cash: input for the hotspot map.
        "cashout_points": [
            {**_place(e.txn.lat, e.txn.lng, e.txn.location_label, e.txn.created_at.isoformat()),
             "amount": e.amount, "complaint_id": e.complaint_id}
            for e in atm_edges if e.txn.lat is not None
        ],
        "recent": [complaint_out(c) for c in sorted(complaints, key=lambda c: c.id, reverse=True)[:10]],
    }


@router.get("/complaints")
def complaints(_o: PoliceOfficer = Depends(current_officer), db: Session = Depends(get_db)):
    return [complaint_out(c) for c in db.query(Complaint).order_by(Complaint.id.desc())]


@router.get("/complaints/{complaint_id}")
def complaint_detail(complaint_id: int, _o: PoliceOfficer = Depends(current_officer), db: Session = Depends(get_db)):
    c = db.get(Complaint, complaint_id)
    if not c:
        raise HTTPException(404, "Complaint not found")
    orders = db.query(CourtOrder).filter_by(complaint_id=c.id).all()
    return {
        **complaint_out(c),
        "description": c.description, "channel": c.channel,
        "report_location": _place(c.lat, c.lng, c.location_label),
        "totals": _totals(c, orders),
        "nodes": [_node_out(db, n) for n in c.nodes],
        "edges": [_edge_out(e) for e in c.edges],
        "court_orders": [_order_out(db, o) for o in orders],
    }


@router.get("/court-orders")
def court_orders(_o: PoliceOfficer = Depends(current_officer), db: Session = Depends(get_db)):
    return [_order_out(db, o) for o in db.query(CourtOrder).order_by(CourtOrder.id.desc())]


@router.post("/court-orders/{order_id}/approve")
async def approve(order_id: int, officer: PoliceOfficer = Depends(current_officer), db: Session = Depends(get_db)):
    """Demo stand-in for the magistrate's order (in real life the court decides)."""
    o = db.get(CourtOrder, order_id)
    if not o:
        raise HTTPException(404, "Court application not found")
    if o.status != "PENDING":
        raise HTTPException(409, "Already decided")
    fraud.approve_court_order(db, o, officer.name)
    await manager.account_changed(o.account_no)
    return _order_out(db, o)


@router.post("/complaints/{complaint_id}/release")
async def release(complaint_id: int, _o: PoliceOfficer = Depends(current_officer), db: Session = Depends(get_db)):
    """Return held / recovered money and seized crypto to the victim (after the court's refund order)."""
    c = db.get(Complaint, complaint_id)
    if not c:
        raise HTTPException(404, "Complaint not found")
    amount, touched = fraud.release_to_victim(db, c)
    await manager.account_changed(*touched)
    return {"released": amount, "complaint": complaint_out(c)}


@router.get("/mules")
def mules(_o: PoliceOfficer = Depends(current_officer), db: Session = Depends(get_db)):
    counts = dict(db.query(TrailNode.account_no, func.count(TrailNode.id)).filter_by(role="MULE")
                  .group_by(TrailNode.account_no).all())
    rows = db.query(Account).filter(Account.status != "ACTIVE").order_by(Account.account_no)
    return [{"account_no": a.account_no, "holder": a.customer.full_name, "pan": a.customer.pan,
             "mobile": a.customer.mobile, "bank": db.get(Bank, a.bank_code).name, "status": a.status,
             "balance": a.balance, "lien_amount": a.lien_amount, "available_balance": a.available_balance,
             "complaints": counts.get(a.account_no, 0), "linked_by_pan_only": a.account_no not in counts}
            for a in rows]
