"""Password / PIN hashing and login tokens.

PINs and passwords are never stored in plain text, even in this demo.
"""
import hashlib
import hmac
import secrets

from fastapi import Depends, Header, HTTPException
from sqlalchemy.orm import Session as DbSession

from .db import get_db
from .models import Customer, Session

_ITERATIONS = 100_000


def hash_secret(secret: str) -> str:
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", secret.encode(), salt.encode(), _ITERATIONS).hex()
    return f"{salt}${digest}"


def verify_secret(secret: str, stored: str) -> bool:
    salt, digest = stored.split("$", 1)
    check = hashlib.pbkdf2_hmac("sha256", secret.encode(), salt.encode(), _ITERATIONS).hex()
    return hmac.compare_digest(check, digest)


def new_token() -> str:
    return secrets.token_urlsafe(32)


def current_customer(
    authorization: str = Header(default=""),
    db: DbSession = Depends(get_db),
) -> Customer:
    """FastAPI dependency: the logged-in customer, from the Bearer token."""
    token = authorization.removeprefix("Bearer ").strip()
    session = db.get(Session, token) if token else None
    if not session:
        raise HTTPException(401, "Please log in again")
    return db.get(Customer, session.customer_id)
