"""Database setup.

On the laptop all data lives in a single SQLite file (backend/rakshakpay.db).
In the cloud, set DATABASE_URL to a PostgreSQL database (e.g. Neon) so data
survives server restarts.
"""
import os
from pathlib import Path

from sqlalchemy import create_engine, event
from sqlalchemy.orm import DeclarativeBase, sessionmaker


def _database_url() -> str:
    url = os.environ.get("DATABASE_URL", "").strip()
    if url:
        # Neon/Render give "postgres://" or "postgresql://"; SQLAlchemy needs the driver name.
        for prefix in ("postgres://", "postgresql://"):
            if url.startswith(prefix):
                return "postgresql+psycopg://" + url[len(prefix):]
        return url
    db_path = Path(os.environ.get("RAKSHAK_DB", Path(__file__).resolve().parent.parent / "rakshakpay.db"))
    return f"sqlite:///{db_path}"


DATABASE_URL = _database_url()

if DATABASE_URL.startswith("sqlite"):
    # FastAPI may use the connection from different threads.
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

    @event.listens_for(engine, "connect")
    def _enforce_foreign_keys(dbapi_conn, _record):
        # SQLite ignores foreign keys unless asked; turn them on so the laptop
        # behaves like the cloud PostgreSQL database and tests catch mistakes.
        dbapi_conn.execute("PRAGMA foreign_keys=ON")
else:
    # Cloud databases drop idle connections; check each one before use.
    engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_recycle=300)
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
