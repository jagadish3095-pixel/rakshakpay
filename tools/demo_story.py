"""Plays the 8-person fraud story on a RakshakPay server (on an empty database).

    backend/.venv/Scripts/python tools/demo_story.py https://rakshakpay.onrender.com

Easier: in the Cyber Police app use "Reset & load demo story", which wipes the server and
does the same thing. The story itself lives in backend/app/demo_story.py.

Then, on a phone, log in to RakshakPay as the victim Priya (mobile 9000000002, passcode 1111)
and report the Rs 50,000 payment to Pankaj as fraud.
"""
import asyncio
import sys
from pathlib import Path

import httpx

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "backend"))
from app.demo_story import run_story  # noqa: E402

SERVER = (sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000").rstrip("/")


async def main() -> None:
    async with httpx.AsyncClient(base_url=SERVER) as client:
        story = await run_story(client)
    print("\nReady. Accounts:")
    for p in story["people"]:
        print(f"  {p['name']:<16} {p['bank']}  A/c {p['account_no']}  IFSC {p['ifsc']}  mobile {p['mobile']}")
    print("\nNow report the fraud: RakshakPay -> 9000000002 / passcode 1111 -> Report fraud")
    print("Police: badge CYB001, password police123")


asyncio.run(main())
