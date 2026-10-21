# RakshakPay

A working demo of a **proactive cyber-fraud response system** for India: five fake banks,
a UPI payment app, a merchant app, a crypto exchange and a Cyber Police app, all running on
fake money and connected through one backend ("the banking network").

> All banks, people, PAN/Aadhaar numbers and money in this project are **fake**.

## Project layout

```
RakshakPay/
├─ backend/                 Python FastAPI server = bank core systems + NPCI switch (+ fraud engine later)
│  ├─ app/main.py           starts the server, live-update WebSocket
│  ├─ app/models.py         database tables (banks, branches, ATMs, customers, accounts, transactions, passbook)
│  ├─ app/ledger.py         the ONLY place money moves
│  ├─ app/seed_data.py      the 5 banks, 30 branches, 20 ATMs, 23 cities
│  ├─ app/routers/          APIs: meta, accounts (KYC/login/passbook), payments (transfer/ATM), demo
│  └─ tests/                end-to-end tests (python -m pytest)
├─ packages/rakshak_core/   Dart code shared by all Flutter apps (API client, models, GPS, live updates)
├─ apps/upi_app/            Flutter RakshakPay UPI app (works with all 5 banks)
├─ apps/bank_app/           Flutter bank app → 5 apps via flavors (Sahyadri, Ganga, Kaveri, Narmada, Godavari)
├─ tools/                   icon generator, test-account creator
├─ docs/PLAN.md             system rules, demo story, build phases
├─ run_backend.ps1          start the server
└─ tools/build_all_apks.cmd  build release APKs of all 9 apps into dist/
```

## Cloud server (main setup)

The backend runs on **Render** (free) at **https://rakshakpay.onrender.com**, with data stored in a
**Neon** PostgreSQL database. Phones connect over any internet connection; no laptop needed.

- Code pushed to GitHub `main` deploys automatically (settings in `render.yaml`).
- `DATABASE_URL` (Neon connection string) and `ADMIN_KEY` are set in Render → Environment. Never commit them.
- The free server sleeps after ~15 minutes without use; the first request then takes up to a minute.
- Build apps for the cloud:
  `flutter build apk --flavor kaveri --dart-define=SERVER=https://rakshakpay.onrender.com`
- Test customers on the cloud: `backend\.venv\Scripts\python.exe tools\create_test_accounts.py https://rakshakpay.onrender.com`
- Reset the cloud demo: `POST /api/demo/reset` with header `X-Admin-Key: <ADMIN_KEY from Render>`.

## Laptop server (offline development)

### First-time setup (once)

```powershell
cd C:\dev\RakshakPay\backend
& "$env:APPDATA\uv\python\cpython-3.14.7-windows-x86_64-none\python.exe" -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

### Run the backend

Double-click **`run_backend.cmd`**, or in a terminal:

```powershell
cd C:\dev\RakshakPay
.\run_backend.cmd
```

(Windows blocks `.ps1` scripts by default; the `.cmd` file runs it without changing that setting.)

It prints the laptop's IP addresses. Open **http://localhost:8000/docs** to try every API in the browser.
The first time, Windows Firewall asks to allow Python on the network: allow it on **private** networks
so phones can connect.

## Run a bank app

On a connected Android phone or emulator:

```powershell
cd C:\dev\RakshakPay\apps\bank_app
flutter run --flavor kaveri
```

Use `sahyadri`, `ganga`, `kaveri`, `narmada` or `godavari`. Each is a separate app, so all five can be
installed on the same phone.

**Connecting a phone:** phone and laptop on the same Wi-Fi (or the phone's hotspot) → in the app tap
⚙ **Settings** → enter `http://<laptop IP>:8000` → **Save & test**. The Android emulator uses
`http://10.0.2.2:8000` (the default).

**Location is mandatory for payments:** every bank transfer and UPI payment records the phone's GPS
position. If location is off or permission is refused, the app shows a popup and the payment is not made
(the server also refuses payments without a location). The police map places each account where its
phone was when it paid; a shop is placed where the buyer paid it.

**Night mode and languages:** ⚙ **Settings** in every app → Night mode (Auto / Day / Night) and
Language (English / हिन्दी / ಕನ್ನಡ). `python tools/check_translations.py` checks that every text has a
Hindi and Kannada translation.

Build release APKs of all 9 apps to share by WhatsApp or Drive: double-click `tools\build_all_apks.cmd` → `dist\`.

## Test data

With the server running:

```powershell
backend\.venv\Scripts\python.exe tools\create_test_accounts.py
```

creates Sunil (Kaveri), Ravi (Ganga) and Lakshmi Mobiles (Narmada, merchant).
Password `secret123`, MPIN `1234`, ATM PIN `4321`. Log in with the mobile number or Customer ID.

Reset everything: `POST http://localhost:8000/api/demo/reset` (from /docs).

## Tests

```powershell
cd backend;  .\.venv\Scripts\python.exe -m pytest
cd apps\bank_app;  flutter analyze;  flutter test
```

## Progress

- [x] Phase 0 – project setup, Git
- [x] Phase 1 – 5 bank apps: account opening + KYC, login, transfers (IMPS/NEFT), live passbook + PDF, ATM withdrawal with location, debit card
- [x] Phase 2 – RakshakPay UPI app (`apps/upi_app`): register, link bank (card check + UPI PIN), UPI IDs, pay by UPI ID / mobile / QR, my QR, balance, history
- [x] Phase 3 – merchant soundbox app (`apps/merchant_app`), CoinVault crypto exchange (`apps/crypto_app`)
- [x] Phase 4 – fraud engine (`backend/app/fraud.py`): complaint, auto-trace, hold victim money only, mule list,
  PAN block, court applications + recovery lien, refund; report-fraud / complaints / notices screens in the apps
- [x] Phase 5 – Cyber Police app (`apps/police_app`, Android + web at **https://rakshakpay.onrender.com/police**):
  dashboard + hotspot map, complaint map with animated money flow, money-trail tree, court orders, release to victim,
  mule list. Rebuild the web version with `tools\build_police_web.ps1`, then commit `backend/police_web`.
- [x] Phase 6 – bank officer mode: in any bank app tap **Bank staff login** (staff ID `SAHY001`, `GANG001`, `KAVR001`,
  `NARM001` or `GODA001`, password `officer123`) → find a flagged customer → re-KYC → statement → recommendation;
  the police decide in the Cyber Police app's **Verifications** tab (innocent / tricked / involved)
- [x] Phase 7 – demo polish: **Demo reset** button in the Cyber Police app (wipes the server and replays the
  8-person story, optionally with the complaint), release APKs of all 9 apps (`tools\build_all_apks.cmd` → `dist\`),
  and the presentation script **[docs/DEMO_GUIDE.md](docs/DEMO_GUIDE.md)**
- [ ] Later – fake-complaint protection (complaint confidence score), hotspot forecasting (ML)

## Demo

Follow **[docs/DEMO_GUIDE.md](docs/DEMO_GUIDE.md)**. Before each run: open https://rakshakpay.onrender.com/police,
log in (`CYB001` / `police123`) and tap **Demo reset**. The same story can also be loaded from the laptop with
`backend\.venv\Scripts\python.exe tools\demo_story.py <server>` on an empty database; the story itself is in
`backend/app/demo_story.py`.
