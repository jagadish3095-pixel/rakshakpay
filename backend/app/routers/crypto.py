"""CoinVault: a fake Indian crypto exchange.

KYC: the user's PAN must match a bank account in their name.
Deposits: UPI/IMPS into CoinVault's own bank account. Only payments from an
account with the same PAN are credited; anything else is refunded at once
(real exchanges reject third-party deposits).
Exits: withdraw rupees to the user's bank account, or send coins to an outside
wallet address (where Indian police lose the trail - the Phase 4 "crypto escape").
"""
import math
import re
import time

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field, field_validator
from sqlalchemy.orm import Session

from ..db import get_db
from ..ledger import Location, move_money, rupees
from ..models import (Account, Bank, Branch, CryptoBalance, CryptoEntry, CryptoSession, CryptoUser, Customer,
                      PanBlacklist, Transaction, UpiTransfer, UpiUser, Vpa)
from ..out import mask
from ..realtime import manager
from ..security import hash_secret, new_token, verify_secret

router = APIRouter(prefix="/api/crypto", tags=["crypto"])

UNITS = 100_000_000  # 1 coin = 100,000,000 units
# Base price in rupees for 1 coin. Prices move a little around these (fake market).
BASE_PRICES = {"BTC": 60_00_000, "ETH": 2_50_000, "USDT": 88}
COINS = list(BASE_PRICES)
MIN_TRADE = 100 * 100  # ₹100

# CoinVault's own company bank account (created at startup).
EXCHANGE = {
    "bank": "GODA", "mobile": "6000000001", "name": "Coinvault Technologies", "pan": "AAACV7777C",
    "business": "CoinVault Exchange", "vpa": "coinvault@godavari",
}


# ---------------------------------------------------------------- the exchange's bank account


def ensure_exchange(db: Session) -> None:
    """Create CoinVault's company account and UPI ID if missing (safe to call every startup)."""
    if db.get(Vpa, EXCHANGE["vpa"]):
        return
    branch = db.query(Branch).filter_by(bank_code=EXCHANGE["bank"]).order_by(Branch.id).first()
    bank = db.get(Bank, EXCHANGE["bank"])
    customer = Customer(
        bank_code=bank.code, cif=f"{bank.code}00000001", full_name=EXCHANGE["name"], dob="2018-04-01",
        gender="Other", mobile=EXCHANGE["mobile"], pan=EXCHANGE["pan"], aadhaar="999999999999",
        address="CoinVault Tower, Ameerpet", city=branch.city, state=branch.state, pincode="500016",
        password_hash=hash_secret(new_token()),  # nobody logs in to this account
    )
    db.add(customer)
    db.flush()
    account = Account(
        account_no=f"{bank.account_prefix}00000001", bank_code=bank.code, customer_id=customer.id,
        branch_id=branch.id, account_type="CURRENT", business_name=EXCHANGE["business"],
        mpin_hash=hash_secret(new_token()), card_no=f"{bank.card_bin}0000000001", card_pin_hash=hash_secret(new_token()),
    )
    db.add(account)
    user = UpiUser(mobile=EXCHANGE["mobile"], name=EXCHANGE["business"], passcode_hash=hash_secret(new_token()))
    db.add(user)
    db.flush()
    db.add(Vpa(address=EXCHANGE["vpa"], upi_user_id=user.id, account_no=account.account_no,
               upi_pin_hash=hash_secret(new_token())))
    # Float so the exchange can pay out withdrawals.
    move_money(db, amount=1_00_00_000 * 100, channel="CASH", credit=account, remark="Exchange float",
               narration_cr="CASH DEP/COINVAULT FLOAT", location=Location(branch.lat, branch.lng, branch.name, "BRANCH"))
    db.commit()


def exchange_account(db: Session) -> Account:
    return db.get(Vpa, EXCHANGE["vpa"]).account


async def handle_exchange_credit(db: Session, txn: Transaction, payer: Account, payer_vpa: str | None = None) -> str:
    """Called after money lands in CoinVault's account. Credits the matching user or refunds.

    Returns a short message for the payer ("credited" / "refunded").
    """
    user = db.query(CryptoUser).filter_by(pan=payer.customer.pan).first()
    if user:
        _add(db, user.id, "INR", txn.amount)
        db.add(CryptoEntry(crypto_user_id=user.id, kind="DEPOSIT", asset="INR", inr_paise=txn.amount, txn_id=txn.id))
        db.commit()
        return f"{rupees(txn.amount)} added to your CoinVault wallet"

    # Not a CoinVault user with this PAN: send it straight back.
    exch = exchange_account(db)
    refund = move_money(
        db, amount=txn.amount, channel=txn.channel, debit=exch, credit=payer,
        remark=f"Refund of {txn.utr}: third-party deposit not allowed",
        narration_dr=f"{txn.channel}/DR/REFUND/{payer.customer.full_name.upper()}",
        narration_cr=f"{txn.channel}/CR/COINVAULT REFUND/THIRD-PARTY DEPOSIT",
    )
    if payer_vpa:
        db.add(UpiTransfer(txn_id=refund.id, payer_vpa=EXCHANGE["vpa"], payee_vpa=payer_vpa))
    db.commit()
    await manager.account_changed(payer.account_no)
    return "CoinVault refunded this payment: deposits are accepted only from your own KYC-verified bank account"


# ---------------------------------------------------------------- prices


def price_paise(asset: str, at: float | None = None) -> int:
    """Fake market: smooth waves of a few percent around the base price."""
    t = time.time() if at is None else at
    seed = {"BTC": 1.0, "ETH": 2.3, "USDT": 4.1}[asset]
    swing = 0.04 if asset != "USDT" else 0.004  # stablecoin barely moves
    factor = 1 + swing * math.sin(t / 900 + seed) + swing / 3 * math.sin(t / 97 + seed * 2)
    return round(BASE_PRICES[asset] * 100 * factor)


def _prices() -> list[dict]:
    now = time.time()
    return [{"asset": a, "price": price_paise(a, now),
             "change_pct": round((price_paise(a, now) / price_paise(a, now - 3600) - 1) * 100, 2)}
            for a in COINS]


@router.get("/prices")
def prices():
    return _prices()


# ---------------------------------------------------------------- users


def _balance(db: Session, user_id: int, asset: str) -> CryptoBalance:
    bal = db.get(CryptoBalance, (user_id, asset))
    if not bal:
        bal = CryptoBalance(crypto_user_id=user_id, asset=asset, amount=0)
        db.add(bal)
        db.flush()
    return bal


def _add(db: Session, user_id: int, asset: str, amount: int) -> None:
    _balance(db, user_id, asset).amount += amount


def _take(db: Session, user_id: int, asset: str, amount: int) -> None:
    bal = _balance(db, user_id, asset)
    if amount <= 0 or bal.amount < amount:
        raise HTTPException(400, f"Not enough {asset} in your wallet")
    bal.amount -= amount


def current_crypto_user(authorization: str = Header(default=""), db: Session = Depends(get_db)) -> CryptoUser:
    token = authorization.removeprefix("Bearer ").strip()
    session = db.get(CryptoSession, token) if token else None
    if not session:
        raise HTTPException(401, "Please log in again")
    return db.get(CryptoUser, session.crypto_user_id)


def _user_out(db: Session, u: CryptoUser) -> dict:
    prices = {p["asset"]: p["price"] for p in _prices()}
    balances = {b.asset: b.amount for b in db.query(CryptoBalance).filter_by(crypto_user_id=u.id)}
    holdings = [{"asset": a, "quantity": balances.get(a, 0), "price": prices[a],
                 "value": balances.get(a, 0) * prices[a] // UNITS} for a in COINS]
    inr = balances.get("INR", 0)
    acc = u.bank_account
    return {
        "mobile": u.mobile, "name": u.name, "pan_masked": u.pan[:2] + "XXXXX" + u.pan[7:],
        "bank": {"name": db.get(Bank, acc.bank_code).name, "account_no_masked": mask(acc.account_no), "ifsc": acc.branch.ifsc},
        "inr": inr, "holdings": holdings, "total_value": inr + sum(h["value"] for h in holdings),
        "deposit_vpa": EXCHANGE["vpa"], "deposit_name": EXCHANGE["business"],
    }


class RegisterRequest(BaseModel):
    mobile: str
    pan: str
    bank_account_no: str
    ifsc: str
    pin: str

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

    @field_validator("pin")
    @classmethod
    def pin_ok(cls, v: str) -> str:
        if not re.fullmatch(r"\d{4}", v):
            raise ValueError("PIN must be 4 digits")
        return v


def _session(db: Session, user: CryptoUser) -> dict:
    token = new_token()
    db.add(CryptoSession(token=token, crypto_user_id=user.id))
    db.commit()
    return {"token": token, "user": _user_out(db, user)}


@router.post("/register")
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    if db.get(PanBlacklist, req.pan):
        raise HTTPException(403, "KYC rejected: this PAN is linked to a cyber fraud case")
    if db.query(CryptoUser).filter_by(pan=req.pan).first():
        raise HTTPException(409, "A CoinVault account already exists for this PAN. Please log in.")
    if db.query(CryptoUser).filter_by(mobile=req.mobile).first():
        raise HTTPException(409, "This mobile number is already registered. Please log in.")
    account = db.get(Account, req.bank_account_no)
    if not account or account.branch.ifsc != req.ifsc.upper():
        raise HTTPException(404, "Bank account not found. Check the account number and IFSC.")
    if account.customer.pan != req.pan:
        raise HTTPException(400, "KYC failed: this bank account does not belong to this PAN")
    user = CryptoUser(mobile=req.mobile, name=account.customer.full_name, pan=req.pan,
                      pin_hash=hash_secret(req.pin), bank_account_no=account.account_no)
    db.add(user)
    db.flush()
    return _session(db, user)


class LoginRequest(BaseModel):
    mobile: str
    pin: str


@router.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(CryptoUser).filter_by(mobile=req.mobile).first()
    if not user or not verify_secret(req.pin, user.pin_hash):
        raise HTTPException(401, "Wrong mobile number or PIN")
    if db.get(PanBlacklist, user.pan):
        raise HTTPException(403, "Account frozen: this PAN is linked to a cyber fraud case")
    return _session(db, user)


class PinRequest(BaseModel):
    pin: str


@router.post("/unlock")
def unlock(req: PinRequest, user: CryptoUser = Depends(current_crypto_user)):
    if not verify_secret(req.pin, user.pin_hash):
        raise HTTPException(401, "Wrong PIN")
    return {"message": "Unlocked"}


@router.get("/me")
def me(user: CryptoUser = Depends(current_crypto_user), db: Session = Depends(get_db)):
    return _user_out(db, user)


def _check_pin_and_freeze(db: Session, user: CryptoUser, pin: str) -> None:
    if not verify_secret(pin, user.pin_hash):
        raise HTTPException(401, "Wrong PIN")
    if db.get(PanBlacklist, user.pan):
        raise HTTPException(403, "Account frozen: this PAN is linked to a cyber fraud case")


# ---------------------------------------------------------------- trading


class BuyRequest(BaseModel):
    asset: str
    inr: int = Field(ge=MIN_TRADE)  # paise to spend
    pin: str


@router.post("/buy")
def buy(req: BuyRequest, user: CryptoUser = Depends(current_crypto_user), db: Session = Depends(get_db)):
    if req.asset not in COINS:
        raise HTTPException(400, "Unknown coin")
    _check_pin_and_freeze(db, user, req.pin)
    price = price_paise(req.asset)
    qty = req.inr * UNITS // price
    _take(db, user.id, "INR", req.inr)
    _add(db, user.id, req.asset, qty)
    db.add(CryptoEntry(crypto_user_id=user.id, kind="BUY", asset=req.asset, quantity=qty,
                       inr_paise=req.inr, price_paise=price))
    db.commit()
    return {"message": f"Bought {qty / UNITS:.8f} {req.asset} for {rupees(req.inr)}", "user": _user_out(db, user)}


class SellRequest(BaseModel):
    asset: str
    quantity: int = Field(gt=0)  # coin units
    pin: str


@router.post("/sell")
def sell(req: SellRequest, user: CryptoUser = Depends(current_crypto_user), db: Session = Depends(get_db)):
    if req.asset not in COINS:
        raise HTTPException(400, "Unknown coin")
    _check_pin_and_freeze(db, user, req.pin)
    price = price_paise(req.asset)
    inr = req.quantity * price // UNITS
    if inr < 1:
        raise HTTPException(400, "Amount too small to sell")
    _take(db, user.id, req.asset, req.quantity)
    _add(db, user.id, "INR", inr)
    db.add(CryptoEntry(crypto_user_id=user.id, kind="SELL", asset=req.asset, quantity=req.quantity,
                       inr_paise=inr, price_paise=price))
    db.commit()
    return {"message": f"Sold {req.quantity / UNITS:.8f} {req.asset} for {rupees(inr)}", "user": _user_out(db, user)}


# ---------------------------------------------------------------- withdrawals


class WithdrawInrRequest(BaseModel):
    amount: int = Field(ge=MIN_TRADE)
    pin: str


@router.post("/withdraw-inr")
async def withdraw_inr(req: WithdrawInrRequest, user: CryptoUser = Depends(current_crypto_user),
                       db: Session = Depends(get_db)):
    """Pays rupees from the CoinVault wallet to the user's own (KYC) bank account by IMPS."""
    _check_pin_and_freeze(db, user, req.pin)
    _take(db, user.id, "INR", req.amount)
    exch, dest = exchange_account(db), user.bank_account
    txn = move_money(db, amount=req.amount, channel="IMPS", debit=exch, credit=dest, remark="CoinVault withdrawal",
                     narration_dr=f"IMPS/DR/{user.name.upper()}/WITHDRAWAL",
                     narration_cr="IMPS/CR/COINVAULT TECHNOLOGIES/WITHDRAWAL")
    db.add(CryptoEntry(crypto_user_id=user.id, kind="WITHDRAW_INR", asset="INR", inr_paise=req.amount, txn_id=txn.id))
    db.commit()
    await manager.account_changed(dest.account_no)
    return {"message": f"{rupees(req.amount)} sent to your bank account", "utr": txn.utr, "user": _user_out(db, user)}


class WithdrawCryptoRequest(BaseModel):
    asset: str
    quantity: int = Field(gt=0)
    address: str = Field(min_length=20, max_length=100)
    pin: str

    @field_validator("address")
    @classmethod
    def address_ok(cls, v: str) -> str:
        v = v.strip()
        if not re.fullmatch(r"[A-Za-z0-9]+", v):
            raise ValueError("Wallet address can contain only letters and numbers")
        return v


@router.post("/withdraw-crypto")
def withdraw_crypto(req: WithdrawCryptoRequest, user: CryptoUser = Depends(current_crypto_user),
                    db: Session = Depends(get_db)):
    """Sends coins to an outside wallet. After this the exchange can no longer freeze them."""
    if req.asset not in COINS:
        raise HTTPException(400, "Unknown coin")
    _check_pin_and_freeze(db, user, req.pin)
    _take(db, user.id, req.asset, req.quantity)
    db.add(CryptoEntry(crypto_user_id=user.id, kind="WITHDRAW_CRYPTO", asset=req.asset, quantity=req.quantity,
                       inr_paise=req.quantity * price_paise(req.asset) // UNITS, address=req.address))
    db.commit()
    return {"message": f"{req.quantity / UNITS:.8f} {req.asset} sent to {req.address[:10]}…",
            "user": _user_out(db, user)}


@router.get("/history")
def history(user: CryptoUser = Depends(current_crypto_user), db: Session = Depends(get_db)):
    rows = (db.query(CryptoEntry).filter_by(crypto_user_id=user.id).order_by(CryptoEntry.id.desc()).limit(200))
    out = []
    for e in rows:
        txn = db.get(Transaction, e.txn_id) if e.txn_id else None
        out.append({"id": e.id, "kind": e.kind, "asset": e.asset, "quantity": e.quantity, "inr": e.inr_paise,
                    "price": e.price_paise, "address": e.address, "utr": txn.utr if txn else "",
                    "date": e.created_at.isoformat()})
    return out
