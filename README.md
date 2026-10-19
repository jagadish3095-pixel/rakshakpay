# RakshakPay

A working demo of a **proactive cyber-fraud response system** for India: five fake banks,
a UPI payment app, a merchant app, a crypto exchange and a Cyber Police app, all running on
fake money and connected through one backend ("the banking network").

> All banks, people, PAN/Aadhaar numbers and money in this project are **fake**.

## Project layout

```
RakshakPay/
â”œâ”€ backend/                 Python FastAPI server = bank core systems + NPCI switch (+ fraud engine later)
â”‚  â”œâ”€ app/main.py           starts the server, live-update WebSocket
â”‚  â”œâ”€ app/models.py         database tables (banks, branches, ATMs, customers, accounts, transactions, passbook)
â”‚  â”œâ”€ app/ledger.py         the ONLY place money moves
â”‚  â”œâ”€ app/seed_data.py      the 5 banks, 30 branches, 20 ATMs, 23 cities
â”‚  â”œâ”€ app/routers/          APIs: meta, accounts (KYC/login/passbook), payments (transfer/ATM), demo
â”‚  â””â”€ tests/                end-to-end tests (python -m pytest)
â”œâ”€ packages/rakshak_core/   Dart code shared by all Flutter apps (API client, models, GPS, live updates)
â”œâ”€ apps/bank_app/           Flutter bank app â†’ 5 apps via flavors (Sahyadri, Ganga, Kaveri, Narmada, Godavari)
â”œâ”€ tools/                   icon generator, test-account creator
â”œâ”€ docs/PLAN.md             system rules, demo story, build phases
â”œâ”€ run_backend.ps1          start the server
â””â”€ build_bank_apks.ps1      build all 5 bank APKs into dist/
```

## Cloud server (main setup)

The backend runs on **Render** (free) at **https://rakshakpay.onrender.com**, with data stored in a
**Neon** PostgreSQL database. Phones connect over any internet connection; no laptop needed.

- Code pushed to GitHub `main` deploys automatically (settings in `render.yaml`).
- `DATABASE_URL` (Neon connection string) and `ADMIN_KEY` are set in Render â†’ Environment. Never commit them.
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

**Connecting a phone:** phone and laptop on the same Wi-Fi (or the phone's hotspot) â†’ in the app tap
âš™ **Settings** â†’ enter `http://<laptop IP>:8000` â†’ **Save & test**. The Android emulator uses
`http://10.0.2.2:8000` (the default).

**Demo location:** in Settings you can pretend the phone is in another city, so the police map shows
transactions spread across India even though all phones are in one room.

Build all five APKs to share by USB or WhatsApp: double-click `build_bank_apks.cmd` â†’ `dist\`.

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

- [x] Phase 0 â€“ project setup, Git
- [x] Phase 1 â€“ 5 bank apps: account opening + KYC, login, transfers (IMPS/NEFT), live passbook + PDF, ATM withdrawal with location, debit card
- [ ] Phase 2 â€“ RakshakPay UPI app
- [ ] Phase 3 â€“ merchant app (QR + voice), crypto exchange app
- [ ] Phase 4 â€“ fraud engine (complaint, auto-trace, hold, mule list, PAN block, recovery lien, court, refund)
- [ ] Phase 5 â€“ Cyber Police app with GPS map and money-flow animation
- [ ] Phase 6 â€“ bank officer mode (mule verification / delisting)
- [ ] Phase 7 â€“ demo polish
