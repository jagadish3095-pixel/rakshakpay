"""RakshakPay backend: the fake banking network.

Run from the backend folder:
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
Then open http://localhost:8000/docs to try every API in the browser.
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from .db import Base, SessionLocal, engine
from .models import Account, UpiSession, Vpa
from .models import Session as LoginSession
from .realtime import manager
from .routers import accounts, demo, meta, payments, upi
from .seed_data import seed


@asynccontextmanager
async def lifespan(_app: FastAPI):
    Base.metadata.create_all(engine)
    with SessionLocal() as db:
        seed(db)
    yield


app = FastAPI(title="RakshakPay Banking Network", version="0.1.0", lifespan=lifespan)

# The Cyber Police web app runs in a browser, so allow cross-origin calls.
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

app.include_router(meta.router)
app.include_router(accounts.router)
app.include_router(payments.router)
app.include_router(upi.router)
app.include_router(demo.router)


@app.get("/")
def health():
    return {"service": "RakshakPay Banking Network", "status": "running"}


def _watched_accounts(token: str) -> list[str] | None:
    """Accounts a bank-app or UPI-app login may watch; None if the token is not valid."""
    with SessionLocal() as db:
        if bank := db.get(LoginSession, token):
            return [a.account_no for a in db.query(Account).filter_by(customer_id=bank.customer_id)]
        if upi := db.get(UpiSession, token):
            return [v.account_no for v in db.query(Vpa).filter_by(upi_user_id=upi.upi_user_id)]
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
