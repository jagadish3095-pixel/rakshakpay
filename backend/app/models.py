"""Database tables.

Money is always stored in PAISE as an integer (₹1 = 100 paise)
so we never get floating-point rounding errors.
"""
from datetime import datetime

from sqlalchemy import BigInteger, Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .db import Base


def now() -> datetime:
    return datetime.now()


class Bank(Base):
    __tablename__ = "banks"

    code: Mapped[str] = mapped_column(String(4), primary_key=True)  # e.g. SAHY
    name: Mapped[str] = mapped_column(String(80))  # e.g. Sahyadri Bank
    ifsc_prefix: Mapped[str] = mapped_column(String(4))  # first 4 letters of IFSC
    account_prefix: Mapped[str] = mapped_column(String(4))  # first 4 digits of account no
    card_bin: Mapped[str] = mapped_column(String(6))  # first 6 digits of debit card
    color: Mapped[str] = mapped_column(String(7))  # brand colour, e.g. #1B8A5A
    tagline: Mapped[str] = mapped_column(String(120), default="")

    branches: Mapped[list["Branch"]] = relationship(back_populates="bank")


class Branch(Base):
    __tablename__ = "branches"

    id: Mapped[int] = mapped_column(primary_key=True)
    bank_code: Mapped[str] = mapped_column(ForeignKey("banks.code"))
    name: Mapped[str] = mapped_column(String(80))
    city: Mapped[str] = mapped_column(String(60))
    state: Mapped[str] = mapped_column(String(60))
    ifsc: Mapped[str] = mapped_column(String(11), unique=True)
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)

    bank: Mapped[Bank] = relationship(back_populates="branches")


class Atm(Base):
    __tablename__ = "atms"

    id: Mapped[str] = mapped_column(String(20), primary_key=True)  # e.g. SAHY-ATM-01
    bank_code: Mapped[str] = mapped_column(ForeignKey("banks.code"))
    name: Mapped[str] = mapped_column(String(80))
    address: Mapped[str] = mapped_column(String(160))
    city: Mapped[str] = mapped_column(String(60))
    state: Mapped[str] = mapped_column(String(60))
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)


class Customer(Base):
    """A person's KYC profile inside ONE bank (each bank has its own customers)."""

    __tablename__ = "customers"

    id: Mapped[int] = mapped_column(primary_key=True)
    bank_code: Mapped[str] = mapped_column(ForeignKey("banks.code"))
    cif: Mapped[str] = mapped_column(String(16), unique=True)  # Customer ID used to log in
    full_name: Mapped[str] = mapped_column(String(100))
    dob: Mapped[str] = mapped_column(String(10))  # YYYY-MM-DD
    gender: Mapped[str] = mapped_column(String(10))
    mobile: Mapped[str] = mapped_column(String(10))
    email: Mapped[str] = mapped_column(String(120), default="")
    pan: Mapped[str] = mapped_column(String(10), index=True)
    aadhaar: Mapped[str] = mapped_column(String(12))
    address: Mapped[str] = mapped_column(String(200))
    city: Mapped[str] = mapped_column(String(60))
    state: Mapped[str] = mapped_column(String(60))
    pincode: Mapped[str] = mapped_column(String(6))
    password_hash: Mapped[str] = mapped_column(String(200))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now)

    accounts: Mapped[list["Account"]] = relationship(back_populates="customer")


class Account(Base):
    __tablename__ = "accounts"

    account_no: Mapped[str] = mapped_column(String(12), primary_key=True)
    bank_code: Mapped[str] = mapped_column(ForeignKey("banks.code"))
    customer_id: Mapped[int] = mapped_column(ForeignKey("customers.id"))
    branch_id: Mapped[int] = mapped_column(ForeignKey("branches.id"))
    account_type: Mapped[str] = mapped_column(String(10))  # SAVINGS | CURRENT (merchant)
    business_name: Mapped[str] = mapped_column(String(100), default="")  # for CURRENT accounts
    balance: Mapped[int] = mapped_column(Integer, default=0)  # paise
    lien_amount: Mapped[int] = mapped_column(Integer, default=0)  # paise on hold
    status: Mapped[str] = mapped_column(String(20), default="ACTIVE")
    mpin_hash: Mapped[str] = mapped_column(String(200))  # 4-digit transaction PIN
    card_no: Mapped[str] = mapped_column(String(16), unique=True)
    card_pin_hash: Mapped[str] = mapped_column(String(200))  # 4-digit ATM PIN
    card_blocked: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now)

    customer: Mapped[Customer] = relationship(back_populates="accounts")
    branch: Mapped[Branch] = relationship()

    @property
    def available_balance(self) -> int:
        """Money the holder can actually use (can be negative under a recovery lien)."""
        return self.balance - self.lien_amount

    @property
    def card_expiry(self) -> str:
        """Debit card 'valid thru' (MM/YY): 5 years after the account was opened."""
        return f"{self.created_at.month:02d}/{(self.created_at.year + 5) % 100:02d}"


class Transaction(Base):
    """One money movement. ATM withdrawals and cash deposits have only one side."""

    __tablename__ = "transactions"

    id: Mapped[int] = mapped_column(primary_key=True)
    utr: Mapped[str] = mapped_column(String(16), unique=True, index=True)
    channel: Mapped[str] = mapped_column(String(10))  # IMPS | NEFT | INTERNAL | UPI | ATM | CASH
    amount: Mapped[int] = mapped_column(Integer)  # paise
    debit_account: Mapped[str | None] = mapped_column(ForeignKey("accounts.account_no"), nullable=True)
    credit_account: Mapped[str | None] = mapped_column(ForeignKey("accounts.account_no"), nullable=True)
    remark: Mapped[str] = mapped_column(String(120), default="")
    status: Mapped[str] = mapped_column(String(10), default="SUCCESS")
    # Where the transaction happened (ATM location for ATM, phone location for app payments).
    lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    location_label: Mapped[str] = mapped_column(String(120), default="")
    location_source: Mapped[str] = mapped_column(String(10), default="")  # GPS | DEMO | ATM | BRANCH
    atm_id: Mapped[str | None] = mapped_column(ForeignKey("atms.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now, index=True)


class LedgerEntry(Base):
    """One line in an account's passbook."""

    __tablename__ = "ledger_entries"

    id: Mapped[int] = mapped_column(primary_key=True)
    account_no: Mapped[str] = mapped_column(ForeignKey("accounts.account_no"), index=True)
    txn_id: Mapped[int] = mapped_column(ForeignKey("transactions.id"))
    entry_type: Mapped[str] = mapped_column(String(2))  # DR | CR
    amount: Mapped[int] = mapped_column(Integer)  # paise
    balance_after: Mapped[int] = mapped_column(Integer)  # paise
    narration: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now)

    txn: Mapped[Transaction] = relationship()


class Session(Base):
    """Login sessions. The token is sent as 'Authorization: Bearer <token>'."""

    __tablename__ = "sessions"

    token: Mapped[str] = mapped_column(String(64), primary_key=True)
    customer_id: Mapped[int] = mapped_column(ForeignKey("customers.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now)


class PanBlacklist(Base):
    """PANs blocked across ALL banks (filled by the fraud engine in Phase 4)."""

    __tablename__ = "pan_blacklist"

    pan: Mapped[str] = mapped_column(String(10), primary_key=True)
    reason: Mapped[str] = mapped_column(String(200))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now)


# ---------------------------------------------------------------- UPI (the "NPCI" side)


class UpiUser(Base):
    """A person registered in the RakshakPay UPI app (identified by mobile, like real UPI)."""

    __tablename__ = "upi_users"

    id: Mapped[int] = mapped_column(primary_key=True)
    mobile: Mapped[str] = mapped_column(String(10), unique=True)
    name: Mapped[str] = mapped_column(String(100))
    passcode_hash: Mapped[str] = mapped_column(String(200))  # 4-digit app passcode
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now)

    # First linked UPI ID first: payments to this person's mobile number go to it.
    vpas: Mapped[list["Vpa"]] = relationship(back_populates="user", order_by="Vpa.created_at")


class Vpa(Base):
    """A UPI ID (e.g. sunil6655@kaveri) linked to one bank account."""

    __tablename__ = "vpas"

    address: Mapped[str] = mapped_column(String(60), primary_key=True)
    upi_user_id: Mapped[int] = mapped_column(ForeignKey("upi_users.id"))
    account_no: Mapped[str] = mapped_column(ForeignKey("accounts.account_no"), unique=True)
    upi_pin_hash: Mapped[str] = mapped_column(String(200))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now)

    user: Mapped[UpiUser] = relationship(back_populates="vpas")
    account: Mapped[Account] = relationship()


class UpiSession(Base):
    __tablename__ = "upi_sessions"

    token: Mapped[str] = mapped_column(String(64), primary_key=True)
    upi_user_id: Mapped[int] = mapped_column(ForeignKey("upi_users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now)


class UpiTransfer(Base):
    """Extra details for a UPI transaction: which UPI IDs paid and received."""

    __tablename__ = "upi_transfers"

    txn_id: Mapped[int] = mapped_column(ForeignKey("transactions.id"), primary_key=True)
    payer_vpa: Mapped[str] = mapped_column(String(60), index=True)
    payee_vpa: Mapped[str] = mapped_column(String(60), index=True)

    txn: Mapped[Transaction] = relationship()


# ---------------------------------------------------------------- CoinVault crypto exchange


class CryptoUser(Base):
    """A KYC-verified CoinVault exchange user. PAN must match their bank account."""

    __tablename__ = "crypto_users"

    id: Mapped[int] = mapped_column(primary_key=True)
    mobile: Mapped[str] = mapped_column(String(10), unique=True)
    name: Mapped[str] = mapped_column(String(100))
    pan: Mapped[str] = mapped_column(String(10), unique=True)
    pin_hash: Mapped[str] = mapped_column(String(200))
    bank_account_no: Mapped[str] = mapped_column(ForeignKey("accounts.account_no"))  # for withdrawals
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now)

    bank_account: Mapped[Account] = relationship()


class CryptoSession(Base):
    __tablename__ = "crypto_sessions"

    token: Mapped[str] = mapped_column(String(64), primary_key=True)
    crypto_user_id: Mapped[int] = mapped_column(ForeignKey("crypto_users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now)


class CryptoBalance(Base):
    """Wallet balance. INR is in paise; coins are in 1/100,000,000 units (like satoshis)."""

    __tablename__ = "crypto_balances"

    crypto_user_id: Mapped[int] = mapped_column(ForeignKey("crypto_users.id"), primary_key=True)
    asset: Mapped[str] = mapped_column(String(6), primary_key=True)  # INR | BTC | ETH | USDT
    amount: Mapped[int] = mapped_column(BigInteger, default=0)


class CryptoEntry(Base):
    """Exchange ledger: every deposit, trade and withdrawal."""

    __tablename__ = "crypto_entries"

    id: Mapped[int] = mapped_column(primary_key=True)
    crypto_user_id: Mapped[int] = mapped_column(ForeignKey("crypto_users.id"), index=True)
    kind: Mapped[str] = mapped_column(String(16))  # DEPOSIT | BUY | SELL | WITHDRAW_INR | WITHDRAW_CRYPTO
    asset: Mapped[str] = mapped_column(String(6))
    quantity: Mapped[int] = mapped_column(BigInteger, default=0)  # coin units (0 for INR-only entries)
    inr_paise: Mapped[int] = mapped_column(BigInteger, default=0)
    price_paise: Mapped[int | None] = mapped_column(BigInteger, nullable=True)  # price per 1 coin
    txn_id: Mapped[int | None] = mapped_column(ForeignKey("transactions.id"), nullable=True)
    address: Mapped[str] = mapped_column(String(100), default="")  # outside wallet for WITHDRAW_CRYPTO
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now)
