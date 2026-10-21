"""RakshakPay backend: the fake banking network.

Run from the backend folder:
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
Then open http://localhost:8000/docs to try every API in the browser.
"""
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .db import Base, SessionLocal, add_missing_columns, engine
from .models import Account, CryptoSession, CryptoUser, PoliceSession, UpiSession, Vpa
from .models import Session as LoginSession
from .realtime import ALL, manager
from .routers import accounts, complaints, crypto, demo, meta, officer, payments, police, upi
from .seed_data import seed


@asynccontextmanager
async def lifespan(_app: FastAPI):
    Base.metadata.create_all(engine)
    add_missing_columns()
    with SessionLocal() as db:
        seed(db)
        crypto.ensure_exchange(db)
        police.ensure_police(db)
        officer.ensure_officers(db)
    yield


app = FastAPI(title="RakshakPay Banking Network", version="0.1.0", lifespan=lifespan)

# The Cyber Police web app runs in a browser, so allow cross-origin calls.
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

app.include_router(meta.router)
app.include_router(accounts.router)
app.include_router(payments.router)
app.include_router(upi.router)
app.include_router(crypto.router)
app.include_router(complaints.router)
app.include_router(police.router)
app.include_router(officer.router)
app.include_router(demo.router)


@app.get("/")
def health():
    return {"service": "RakshakPay Banking Network", "status": "running"}


def _watched_accounts(token: str) -> list[str] | None:
    """Accounts a bank, UPI or crypto app login may watch; None if the token is not valid."""
    with SessionLocal() as db:
        if bank := db.get(LoginSession, token):
            return [a.account_no for a in db.query(Account).filter_by(customer_id=bank.customer_id)]
        if upi := db.get(UpiSession, token):
            return [v.account_no for v in db.query(Vpa).filter_by(upi_user_id=upi.upi_user_id)]
        if cs := db.get(CryptoSession, token):
            # Deposits and withdrawals move money in the user's own bank account.
            return [db.get(CryptoUser, cs.crypto_user_id).bank_account_no]
        if db.get(PoliceSession, token):
            return [ALL]  # police dashboards refresh on every change
    return None


@app.websocket("/ws")
async def live_updates(ws: WebSocket, token: str = ""):
    """Apps connect here to hear about changes to their accounts."""
    account_nos = _watched_accounts(token)
    await ws.accept()
    if account_nos is None:
        # Accept first so the app receives the 4401 code and stops retrying.
        await ws.close(code=4401)
        return
    manager.watch(ws, account_nos)
    try:
        while True:
            await ws.receive_text()  # keep-alive pings from the app
    except WebSocketDisconnect:
        manager.forget(ws)


# The Cyber Police app's web version (built by tools/build_police_web.ps1) is served at /police,
# so any laptop can open https://<server>/police without a separate website host.
POLICE_WEB = Path(__file__).resolve().parent.parent / "police_web"
if POLICE_WEB.is_dir():
    app.mount("/police", StaticFiles(directory=POLICE_WEB, html=True), name="police_web")
