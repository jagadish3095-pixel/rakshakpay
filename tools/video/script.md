# RakshakPay – documentary script (about 6 minutes)

Narration voice: en-IN-PrabhatNeural (Microsoft neural voice). This file is the narration used by
`make_video.py`; edit the sentences there and run it again to rebuild the video.

How to rebuild: take screenshots with `capture.py` (police web, bank web, local test server with the
demo story), then `python make_video.py <shots> <work> out.mp4`.

RakshakPay. A system that follows stolen money, and stops it, in seconds.

## The Problem

Every day, people in India lose money to cyber fraud. Fake KYC calls. Fake jobs. Investment scams. Courier scams.

The victim calls 1930, or complains on the national cybercrime portal. And a race against time begins.

## How It Works Today

Today, much of this is manual. A complaint becomes a ticket. Officers write to banks one by one to find where the money went.

But the fraudster moves faster. Within minutes, the money is split across mule accounts in different banks, withdrawn at ATMs, spent at shops, or turned into crypto.

By the time a hold reaches the right account, it is often empty. And returning money to the victim needs a court order, which can take months.

## What Goes Wrong

Six problems keep repeating. Fraud moves in minutes, but investigation takes days. No single bank sees the whole chain. Innocent shopkeepers get their whole account frozen. Crypto takes the money out of the banking system. Refunds wait for a slow court process. And mules simply open new accounts in other banks.

## Our Idea

RakshakPay connects the whole chain: five banks, a UPI app, a shop sound box, a crypto exchange and a cyber police console, all on one server.

So a single complaint can trace the money and stop it, automatically.

## The Rules

These are the rules we designed.

Rule one: trace automatically. The moment a complaint is filed, every later transaction is replayed in time order, following the victim's money through every hop.

Two: hold only the victim's money. Each account is held for exactly the traced amount, not frozen.

Three: mark mule accounts. Every bank sees the mark, and so does the holder. Payments out stay blocked until the holder is verified at the branch.

Four: warn the sender. Pay anyway is allowed only to repay a victim.

Five: never touch the merchant. The shop keeps its money. Recovery comes from the buyer, the last mule.

Six: blacklist the PAN across every bank and crypto exchange. No new account, and no crypto.

Seven: court-approved recovery. The system drafts the court application itself. After approval, a recovery lien collects the money, even into a negative balance.

Eight: crypto is frozen at the exchange, and released only with a court seizure order.

And nine: the phone's GPS is mandatory. No location, no payment.

## Watch It Work

Let us watch it work. Priya gets a call: her KYC has expired, and she must pay fifty thousand rupees to keep her account.

She pays by UPI. Within minutes, the money passes through seven mules in four banks, from Jamtara to Kolkata, Deoghar and Nuh. Ten thousand buys a phone in Jaipur, and ten thousand goes to a crypto exchange.

Priya reports the payment from her app. She gets only an acknowledgement number; the investigation details stay with the police.

In the police console, the complaint is already traced. Thirty thousand rupees is on hold, and five thousand in crypto is frozen.

The summary shows everything: amount lost, accounts traced, money held, spent at shops, frozen as crypto, and what escaped.

The map shows where every phone was when it moved the money, with an arrow for every hop.

The money trail shows the same story as a tree, account by account.

For the phone and the escaped crypto, court applications are already drafted, ready for the magistrate. The shopkeeper is never touched: Prem, the buyer, repays.

Meanwhile, the mule accounts are marked. If anyone tries to pay one, they see this warning.

And a payment without location is simply not made.

When the court approves, one tap releases the money. Almost thirty-five thousand rupees is back with Priya, with a notice in her app. The rest is collected through the recovery liens.

## Technology

We built nine Android apps in Flutter and Dart, sharing one core library. The server is Python and FastAPI, with a PostgreSQL database on Neon, hosted on Render. Every app works in English, Hindi and Kannada, with a night mode.

## What It Changes

With RakshakPay, money is held in seconds, not days. Shopkeepers are protected. Mules cannot just move banks. And victims get their money back faster.

## What'S Next

Today it runs on simulated banks. Next: protection against fake complaints, and forecasting mule hotspots. A real launch needs RBI, NPCI, the banks and the courts to connect.

RakshakPay. Protecting every rupee.
