# RakshakPay – system plan

## Apps

| App | Platform | Purpose |
|---|---|---|
| 5 bank apps (Sahyadri, Ganga, Kaveri, Narmada, Godavari) | Android | Account opening/KYC, login, transfers, live passbook + PDF, ATM withdrawal, debit card, officer mode |
| RakshakPay UPI app | Android | Link bank, UPI PIN, pay/scan QR, history, sender popup, report fraud (1930), repay victim |
| Merchant app | Android | Merchant QR + speaks amount received (no fraud alerts – mules are only known after a complaint) |
| Crypto exchange app | Android | PAN KYC, deposit from bank, buy/sell, PAN blacklist check |
| Cyber Police app | Android phone/tablet + web (laptop) | Complaints, money-trail graph, GPS map with animated money flow, mule list, court applications, refund |
| Backend | Laptop (FastAPI) | Bank core systems + NPCI switch + fraud engine + e-court simulator |

Every payment must carry the phone's GPS position (no location, no payment). ATM withdrawals store the ATM's location.

## System rules

1. Complaint → the system auto-traces every transaction ID (no waiting for bank-by-bank approval).
2. Every account in the trail goes on the mule list, visible to banks and to the account holder.
3. Money still in an account → hold **only the victim's amount**.
4. A merchant (current) account in the trail is never touched; recover from the buyer (last mule) instead.
5. Money spent or converted (crypto, goods) → auto-generated court application (BNSS s.107) → recovery lien
   (negative available balance) after approval.
6. Mule's PAN blocked → all linked bank, exchange and demat accounts blocked; no new accounts.
7. Mule's payment services blocked (UPI, cards, transfers, ATM, AEPS).
8. Incoming money to a mule is allowed but goes to victim recovery first.
9. Senders paying a mule see a warning popup; "pay anyway" only as repayment.
10. Delisting only at the branch: re-KYC + police review (innocent / tricked / knowingly involved).
11. Businesses must use merchant accounts (proposed rule).

## Demo story (8 people)

```
P2 (victim) ──₹50,000──► P1 (scammer)
                          ├─₹25,000─► P3 keeps ₹10,000 ─₹15,000─► P5 keeps ₹5,000 ─₹10,000─► P7 buys crypto
                          └─₹25,000─► P4 keeps ₹10,000 ─₹15,000─► P6 keeps ₹5,000 ─₹10,000─► P8 buys ₹15,000 phone
                                                                                              (₹5,000 own money)
```

After P2 complains: hold ₹30,000 (P3, P4, P5, P6); merchant untouched; P7 and P8 PAN-blocked with a
court-approved recovery lien of −₹10,000 each → up to 100% recovered.

## Parked for later

- Fake-complaint protection (complaint confidence score, accused uploads proof, penalty for false complaints).
- Hotspot forecasting (ML) on the police map.
