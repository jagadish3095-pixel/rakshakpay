"""Database setup.

All data lives in a single SQLite file (backend/rakshakpay.db).
Delete that file (or call POST /api/demo/reset) to start fresh.
"""
import os
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

DB_PATH = Path(os.environ.get("RAKSHAK_DB", Path(__file__).resolve().parent.parent / "rakshakpay.db"))

engine = create_engine(
    f"sqlite:///{DB_PATH}",
    # FastAPI may use the connection from different threads.
    connect_args={"check_same_thread": False},
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


def get_db():
    """FastAPI dependency: one DB session per request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
