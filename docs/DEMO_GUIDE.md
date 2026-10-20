# RakshakPay – demo guide

A live demo of about **10 minutes**: a citizen is scammed, reports it, and the system traces the money,
holds what is left, flags the mules, protects the merchant, and returns money to the victim.

Everything is fake: banks, people, PAN/Aadhaar numbers and money.

---

## 1. Devices and who holds what

| Device | Shows | Person / login |
|---|---|---|
| 💻 **Laptop + projector** | **Cyber Police website** – https://rakshakpay.onrender.com/police | badge `CYB001`, password `police123` |
| 📱 **Phone 1 (Redmi)** | **RakshakPay** + **Kaveri Bank** | **Priya Sharma**, the victim |
| 📱 **Phone 2 (Vivo)** | **RakshakPay Business** (shop soundbox), then **Ganga Bank** | **Jaipur Mobile Hub** (shop), then **Prakash Das** (mule) and the **Ganga Bank officer** |

Both phones have all 9 apps, so either phone can play any role.

## 2. Logins (after "Demo reset")

| Who | Mobile | Bank app | Notes |
|---|---|---|---|
| Priya Sharma – **victim** | 9000000002 | Kaveri Bank | Lost ₹50,000 to a "KYC officer" |
| Pankaj Mondal – scammer (P1) | 9000000001 | Ganga Bank | UPI ID `pankaj0001@ganga` |
| Prakash Das – mule (P3) | 9000000003 | Ganga Bank | ₹10,000 gets held |
| Pooja Meena – mule (P4) | 9000000004 | Narmada Bank | ₹10,000 gets held |
| Pavan Yadav – mule (P5) | 9000000005 | Kaveri Bank | ₹5,000 gets held |
| Parvez Khan – mule (P6) | 9000000006 | Ganga Bank | ₹5,000 gets held |
| Pradeep Soren – mule (P7) | 9000000007 | Godavari Bank | Bought crypto, sent half outside |
| Prem Singh – mule (P8) | 9000000008 | Narmada Bank | Bought a ₹15,000 phone |
| Mahesh Gupta – **Jaipur Mobile Hub** | 9000000009 | Narmada Bank (merchant) | Shop soundbox |

For everyone: bank password `secret123` · MPIN `1234` · ATM PIN `4321` · RakshakPay passcode `1111` ·
UPI PIN `2580` · CoinVault PIN `4444`.
Bank staff: `SAHY001` / `GANG001` / `KAVR001` / `NARM001` / `GODA001`, password `officer123`.

---

## 3. Before the demo

**The day before**
- [ ] Charge both phones and the laptop. Turn on **Do Not Disturb**.
- [ ] Practise the whole script once (section 4).
- [ ] Record a screen video of a full run as a backup.

**15 minutes before**
- [ ] Open **https://rakshakpay.onrender.com/police** on the laptop. The free server sleeps after 15 idle minutes and
      takes up to a minute to wake: do this early.
- [ ] Log in, tap **Demo reset** (top right), type `RESET`, leave *"Also file Priya's complaint"* **off**.
      The dialog shows everyone's logins.
- [ ] **Phone 1:** RakshakPay → log in as Priya (9000000002 / 1111). Kaveri Bank → log in as Priya.
- [ ] **Phone 2:** RakshakPay Business → log in as the shop (9000000009 / 1111). Volume up.
- [ ] Phones: mobile data **on**, screen timeout 10 minutes, brightness high.

---

## 4. The script (≈10 minutes)

### Scene 1 – Normal life (1 min)
*"Five banks, one UPI network. Priya buys something at a shop."*
- **Phone 1:** RakshakPay → **Scan & Pay** → scan Phone 2's QR → ₹200 → UPI PIN `2580`.
- **Phone 2 speaks:** *"Received 200 rupees on RakshakPay"*.

### Scene 2 – The scam (1 min)
*"This morning a caller told Priya her KYC had expired and her account would be blocked. She paid ₹50,000.
Within minutes the money was split across 7 accounts in 4 states: Jharkhand, West Bengal, Rajasthan,
Haryana. One mule bought a phone in Jaipur, another converted it to Bitcoin."*
- **Phone 1:** RakshakPay → **History** → the ₹50,000 to Pankaj Mondal.
- *"Today the bank sends a ticket, waits for a reply, then the next bank… while the cash is withdrawn."*

### Scene 3 – Report fraud (1 min)
- **Phone 1:** **Report fraud (1930)** → the ₹50,000 payment → *Fake KYC / bank call* → tick → **Submit**.
- Point at the result: **acknowledgement number, 9 accounts traced, 7 mules, ₹30,000 on hold – in seconds.**

### Scene 4 – The police see everything (3 min, on the projector)
- **Dashboard** updates by itself: complaint, ₹30,000 held, ≈₹5,000 crypto frozen (it moves with the coin price),
  7 mule accounts, hotspot map.
- **Complaints → the complaint → Map → ▶ Play.** Narrate: Bengaluru → Jamtara → Kolkata / Bharatpur → Deoghar / Nuh →
  Ranchi (crypto) / Jaipur (phone shop).
- **Money trail** tab: *"Hold only the victim's money, never the whole account. The mule's own money stays free."*
- Point out: **the phone shop is green – protected.** *"He sold a real phone. We recover from the buyer instead."*
- Crypto: *"Coins still on the exchange are frozen; coins sent to an outside wallet are lost – so we file in court
  against the person who did it."*

### Scene 5 – The mules feel it (1 min)
- **Phone 2:** open **Ganga Bank** → log in as **Prakash Das** (9000000003 / secret123) → red badge,
  **₹10,000 on hold**, 🔔 notice. Try **Send money** → blocked.
- **Phone 1:** RakshakPay → **Pay** → `pankaj0001@ganga` → **red mule-list warning**. Tap *Cancel payment*.

### Scene 6 – Court and refund (1 min, projector)
- **Court orders** tab → **Prem Singh ₹10,000** → read the auto-drafted BNSS s.107 application → **Approve**.
- **Mule list:** Prem Singh's available balance is now **−₹10,000** – future money goes to the victim.
- Complaint → **Summary → Release to victim** → **Phone 1:** Kaveri Bank passbook shows the refund appear live.

### Scene 7 – A mule visits the branch (1–2 min)
- **Phone 2:** Ganga Bank → log out → **Bank staff login** `GANG001` / `officer123` → **Mule list** → Prakash Das →
  **Start mule verification** → tick re-KYC, OTP → statement *"Tricked by a job offer"* → **Tricked** + undertaking →
  **Send to police**.
- **Projector:** **Verifications** → Prakash → **Tricked: restore with conditions**.
- *"Innocent people get their banking back; real mules stay blocked across every bank by PAN."*

### Closing (30 s)
*"The pieces exist in India today – UPI, CFCFRMS, the Suspect Registry, e-Courts – but they work bank by bank and
wait for humans. RakshakPay connects them: it acts in seconds, recovers instead of giving up, and protects the
merchants and innocent people caught in the middle."*

---

## 5. Questions judges may ask

| Question | Short answer |
|---|---|
| Is instant access to bank data legal? | Not today. We propose **complaint-triggered, time-limited, audited** access – only accounts in that complaint's money trail. It needs an RBI / MHA framework. |
| Can you really make a balance negative? | Only after a **court order** (BNSS s.107 attachment). We auto-draft the application; the officer signs; the magistrate decides. Banks already do this for their own charges. |
| What about fake complaints? | Victim must be the account holder, the payment must exist, and they accept the BNS 217/248 declaration. Next step: a complaint confidence score; low scores hold only the disputed amount. |
| What if the merchant is innocent? | Merchant accounts are never frozen. The buyer (last mule) owes the amount; the goods can be seized. |
| What if a mule was tricked or hacked? | Branch re-KYC + statement → police decide **innocent / tricked / involved**. Innocent and tricked get services back. |
| Why not just freeze the account? | We do – but tracking is always behind the fraudster. Holding fast + flagging the whole network + PAN blocking closes the gaps. |
| Crypto? | Money is stopped at the exchange's KYC (PAN). Coins already sent to private wallets can't be frozen – that is why speed matters. |
| Does it scale to 8,000 complaints a day? | Tracing is a single pass over later transactions per complaint; at national scale it would run on NPCI / bank data with indexes and queues. |
| What does "predict withdrawal location" mean here? | The hotspot map shows where mules operate and cash out, so banks and police can focus on those districts. |

## 6. If something goes wrong

| Problem | Fix |
|---|---|
| App says "Not connected" / spinner for a long time | Free server waking up – wait up to 1 minute. Check mobile data. |
| Laptop Wi-Fi fails | Connect the laptop to a phone's hotspot. |
| A step went wrong / data is messy | Police website → **Demo reset** (≈30 s) → log in again on the phones. |
| Soundbox silent | Volume up; ⋮ → Test sound; language → English. |
| A phone dies | Every app is on both phones – continue on the other one. |
| Nothing works | Play the backup screen recording. |

## 7. Sharing the apps with judges

`tools\build_all_apks.cmd` builds all 9 apps into `dist\` (`Sahyadri-Bank.apk`, …, `Cyber-Police.apk`). Send them by
WhatsApp or Google Drive. On the phone: open the APK → allow *Install unknown apps* → Install. They connect to the cloud
server automatically.
