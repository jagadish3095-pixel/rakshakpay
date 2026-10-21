"""The fraud engine: follows a victim's money and acts on every account it reached.

How tracing works
-----------------
Start with the reported payment. Replay every later transaction in time order.
Each account keeps a "pool" of the victim's money it currently holds. When an
account with a pool pays someone, the victim's money is assumed to leave first
(the rule most favourable to the victim), so min(pool, amount) moves on:

  to another person      -> follow it (that person is a suspected mule)
  to a merchant          -> stop; the merchant is NOT touched, the buyer owes it
  to the crypto exchange -> stop; coins still on the exchange are frozen, coins
                            sent to outside wallets are lost
  ATM withdrawal         -> stop; the cash is lost, the ATM location is recorded

Whatever is left in a pool at the end is still in that account: hold exactly
that much (a lien) and no more. Money that was spent, withdrawn or moved out as
crypto gets an auto-drafted court application for a recovery lien.
"""
from collections import defaultdict
from datetime import datetime

from sqlalchemy.orm import Session

from .ledger import move_money, rupees
from .models import (Account, Bank, Complaint, CourtOrder, CryptoBalance, CryptoEntry, CryptoUser, Notice,
                     PanBlacklist, Transaction, TrailEdge, TrailNode, VerificationCase)
from .out import mask
from .routers.crypto import COINS, UNITS, exchange_account, price_paise

MULE = "SUSPECTED_MULE"


def payee_warning(account: Account) -> str | None:
    """Shown before anyone pays an account that is on the mule list."""
    if account.status == "ACTIVE":
        return None
    return ("This account is on the national mule list: it has been used in cyber fraud. "
            "Money you send will be held to repay fraud victims and cannot be reversed. "
            "Pay only if you are repaying a victim on behalf of this person.")


def trace(db: Session, complaint: Complaint) -> set[str]:
    """Trace the complaint, place holds, flag mules, draft court applications.

    Commits. Returns the account numbers whose apps should refresh.
    """
    start = complaint.victim_txn
    victim_no = start.debit_account
    exchange_no = exchange_account(db).account_no
    pool: dict[str, int] = defaultdict(int)
    nodes: dict[str, TrailNode] = {}
    crypto_in: dict[str, int] = defaultdict(int)  # account -> victim's money deposited at the exchange

    def node(account_no: str, role: str, level: int) -> TrailNode:
        if account_no not in nodes:
            # Column defaults only apply when saved, so start every amount at 0 here.
            amounts = dict.fromkeys(["received", "forwarded", "cashed_out", "spent_merchant", "to_crypto",
                                     "crypto_frozen", "crypto_escaped", "held", "recovery_approved",
                                     "released", "crypto_released"], 0)
            n = TrailNode(complaint_id=complaint.id, account_no=account_no, role=role, level=level, **amounts)
            db.add(n)
            nodes[account_no] = n
        return nodes[account_no]

    def route(txn: Transaction, sender: str, amount: int) -> None:
        """Send `amount` of the victim's money from `sender` along `txn`."""
        src = nodes[sender]
        to = txn.credit_account
        edge = TrailEdge(complaint_id=complaint.id, txn_id=txn.id, from_account=sender, to_account=to,
                         amount=amount, txn_amount=txn.amount, kind="TRANSFER")
        db.add(edge)
        if to is None:  # ATM / cash
            edge.kind = "ATM"
            src.cashed_out += amount
        elif to == victim_no:  # came back to the victim
            edge.kind = "RETURN"
            src.forwarded += amount
        elif to == exchange_no:
            edge.kind = "CRYPTO"
            src.to_crypto += amount
            crypto_in[sender] += amount
            node(to, "EXCHANGE", src.level + 1).received += amount
        elif db.get(Account, to).account_type == "CURRENT":
            edge.kind = "MERCHANT"
            src.spent_merchant += amount
            node(to, "MERCHANT", src.level + 1).received += amount
        else:
            src.forwarded += amount
            node(to, "MULE", src.level + 1).received += amount
            pool[to] += amount

    node(victim_no, "VICTIM", 0)
    route(start, victim_no, complaint.amount)

    later = db.query(Transaction).filter(Transaction.id > start.id).order_by(Transaction.id)
    for txn in later:
        sender = txn.debit_account
        if not sender or sender == victim_no or pool.get(sender, 0) <= 0:
            continue
        moved = min(pool[sender], txn.amount)
        pool[sender] -= moved
        route(txn, sender, moved)
        # The exchange refunds deposits that do not match a KYC user: that money came back.
        if txn.credit_account == exchange_no and not _crypto_user(db, sender):
            nodes[sender].to_crypto -= moved
            nodes[exchange_no].received -= moved
            crypto_in[sender] -= moved
            pool[sender] += moved

    touched = set(nodes)
    _settle_crypto(db, nodes, crypto_in)
    _place_holds(db, nodes, pool)
    touched |= _flag_mules(db, complaint, nodes)
    _draft_court_orders(db, complaint, nodes)

    # The victim gets only the acknowledgement; investigation details are for the police.
    db.add(Notice(account_no=victim_no, kind="COMPLAINT", complaint_id=complaint.id,
                  title=f"Complaint {complaint.ack_no} registered",
                  body=f"Your complaint about {rupees(complaint.amount)} has been registered and sent to the "
                       "cyber police. Keep this acknowledgement number. You will get a notice here when "
                       "money is returned to your account."))
    complaint.status = "TRACED"
    complaint.traced_at = datetime.now()
    db.commit()
    return touched


def _crypto_user(db: Session, account_no: str) -> CryptoUser | None:
    return db.query(CryptoUser).filter_by(pan=db.get(Account, account_no).customer.pan).first()


def _wallet_value(db: Session, user: CryptoUser) -> int:
    total = 0
    for b in db.query(CryptoBalance).filter_by(crypto_user_id=user.id):
        total += b.amount if b.asset == "INR" else b.amount * price_paise(b.asset) // UNITS
    return total


def _settle_crypto(db: Session, nodes: dict[str, TrailNode], crypto_in: dict[str, int]) -> None:
    """Money sent to the exchange: whatever is still in the user's wallet is frozen; the rest escaped."""
    for account_no, amount in crypto_in.items():
        if amount <= 0:
            continue
        user = _crypto_user(db, account_no)
        frozen = min(amount, _wallet_value(db, user)) if user else 0
        nodes[account_no].crypto_frozen = frozen
        nodes[account_no].crypto_escaped = amount - frozen


def _place_holds(db: Session, nodes: dict[str, TrailNode], pool: dict[str, int]) -> None:
    """Hold only the victim's money that is still in each account."""
    for account_no, left in pool.items():
        if left <= 0:
            continue
        account = db.get(Account, account_no)
        held = min(left, max(0, account.available_balance))
        nodes[account_no].held = held
        account.lien_amount += held


def _flag_mules(db: Session, complaint: Complaint, nodes: dict[str, TrailNode]) -> set[str]:
    """Every person's account the money passed through goes on the mule list, and so does every
    other account with the same PAN (so the person cannot simply use another bank)."""
    victim_pan = db.get(Account, complaint.victim_account).customer.pan
    touched: set[str] = set()
    for n in nodes.values():
        account = db.get(Account, n.account_no)
        if n.role == "MERCHANT":
            db.add(Notice(account_no=n.account_no, kind="INFO", complaint_id=complaint.id,
                          title="Payment linked to a fraud complaint",
                          body=f"A customer paid you {rupees(n.received)} using money reported in complaint "
                               f"{complaint.ack_no}. Your account is NOT restricted: as a merchant who sold goods "
                               "in good faith, the amount will be recovered from the buyer instead."))
            continue
        if n.role != "MULE":
            continue
        pan = account.customer.pan
        if pan == victim_pan:
            continue
        if not db.get(PanBlacklist, pan):
            db.add(PanBlacklist(pan=pan, reason=f"Money mule in complaint {complaint.ack_no}"))
        linked = db.query(Account).join(Account.customer).filter_by(pan=pan).all()
        for acc in linked:
            if acc.status == "ACTIVE":
                acc.status = MULE
            touched.add(acc.account_no)
            in_trail = acc.account_no == n.account_no
            bank = db.get(Bank, acc.bank_code).name
            db.add(Notice(
                account_no=acc.account_no, kind="MULE", complaint_id=complaint.id,
                title="Your account is on the mule list",
                body=(f"{bank} A/c {mask(acc.account_no)} "
                      + ("received money from cyber fraud complaint " if in_trail else
                         "is linked by PAN to an account used in cyber fraud complaint ")
                      + f"{complaint.ack_no}. Debit services (UPI, transfers, ATM) are blocked"
                      + (f" and {rupees(n.held)} is on hold" if in_trail and n.held else "")
                      + ". If you were tricked, visit your home branch with original KYC documents "
                        "for verification. Incoming money is still accepted and will be used to repay the victim."),
            ))
    return touched


def _draft_court_orders(db: Session, complaint: Complaint, nodes: dict[str, TrailNode]) -> None:
    """Money that left the banking system (spent, cash, outside crypto wallets) -> court application."""
    db.flush()  # save the trail first so its edges can be queried below
    victim = db.get(Account, complaint.victim_account)
    for n in nodes.values():
        if n.role != "MULE":
            continue
        parts = [(n.spent_merchant, "used to buy goods from a merchant"),
                 (n.cashed_out, "withdrawn as cash at ATM"),
                 (n.crypto_escaped, "converted to crypto and sent to outside wallets")]
        amount = sum(a for a, _ in parts)
        if amount <= 0:
            continue
        reason = "; ".join(f"{rupees(a)} {why}" for a, why in parts if a)
        acc = db.get(Account, n.account_no)
        utrs = [e.txn.utr for e in db.query(TrailEdge).filter_by(complaint_id=complaint.id, from_account=acc.account_no)]
        text = (
            "IN THE COURT OF THE JUDICIAL MAGISTRATE FIRST CLASS\n"
            "Application under Section 107 of the Bharatiya Nagarik Suraksha Sanhita, 2023\n"
            "for attachment of proceeds of crime\n\n"
            f"Complaint No.: {complaint.ack_no} ({complaint.category})\n"
            f"Victim: {victim.customer.full_name}, {db.get(Bank, victim.bank_code).name} A/c {mask(victim.account_no)}\n"
            f"Respondent: {acc.customer.full_name}, PAN {acc.customer.pan}\n"
            f"Account: {db.get(Bank, acc.bank_code).name} A/c {acc.account_no} (IFSC {acc.branch.ifsc})\n"
            f"Amount sought: {rupees(amount)}\n\n"
            f"Grounds: the victim's money reached the respondent's account and was {reason}. "
            f"Transactions (UTR): {', '.join(utrs)}.\n\n"
            "Prayer: direct the bank(s) to mark a recovery lien for the above amount on the respondent's "
            "account(s), so that incoming funds are retained and remitted to the victim.\n\n"
            "Auto-drafted by the RakshakPay fraud engine; requires the investigating officer's digital signature."
        )
        db.add(CourtOrder(complaint_id=complaint.id, account_no=acc.account_no, kind="RECOVERY", amount=amount,
                          reason=reason, application_text=text))

    # Crypto still on the exchange is frozen, but seizing and selling it also needs the court.
    for n in nodes.values():
        if n.role != "MULE" or n.crypto_frozen <= 0:
            continue
        acc = db.get(Account, n.account_no)
        reason = f"{rupees(n.crypto_frozen)} of crypto bought with the victim's money is frozen at CoinVault"
        text = (
            "IN THE COURT OF THE JUDICIAL MAGISTRATE FIRST CLASS\n"
            "Application under Section 107 of the Bharatiya Nagarik Suraksha Sanhita, 2023\n"
            "for attachment and restoration of proceeds of crime held as virtual digital assets\n\n"
            f"Complaint No.: {complaint.ack_no} ({complaint.category})\n"
            f"Victim: {victim.customer.full_name}, {db.get(Bank, victim.bank_code).name} A/c {mask(victim.account_no)}\n"
            f"Respondent: {acc.customer.full_name}, PAN {acc.customer.pan}\n"
            "Holder of the assets: CoinVault Exchange (KYC-verified wallet of the respondent)\n"
            f"Value sought: {rupees(n.crypto_frozen)} (at market price when seized)\n\n"
            f"Grounds: {reason}; the respondent's PAN is blacklisted and the wallet is frozen.\n\n"
            "Prayer: direct CoinVault to sell the frozen assets up to the above value and remit the proceeds "
            "to the victim's account.\n\n"
            "Auto-drafted by the RakshakPay fraud engine; requires the investigating officer's digital signature."
        )
        db.add(CourtOrder(complaint_id=complaint.id, account_no=acc.account_no, kind="CRYPTO_SEIZURE",
                          amount=n.crypto_frozen, reason=reason, application_text=text))


def approve_court_order(db: Session, order: CourtOrder, officer_name: str) -> None:
    """Simulates the magistrate's approval.

    RECOVERY: recovery lien on the account (available balance can go negative).
    CRYPTO_SEIZURE: the frozen crypto may now be seized and sold for the victim (on release).
    """
    order.status = "APPROVED"
    order.approved_at = datetime.now()
    order.approved_by = officer_name
    if order.kind == "CRYPTO_SEIZURE":
        title = "Court order: frozen crypto to be seized"
        body = (f"By court order in complaint {order.complaint.ack_no}, crypto worth up to {rupees(order.amount)} "
                "in your CoinVault wallet will be sold and paid to the victim.")
    else:
        order.account.lien_amount += order.amount
        n = db.query(TrailNode).filter_by(complaint_id=order.complaint_id, account_no=order.account_no).first()
        n.recovery_approved += order.amount
        title = "Court-approved recovery lien"
        body = (f"By court order in complaint {order.complaint.ack_no}, a recovery lien of {rupees(order.amount)} "
                f"is placed on your account ({order.reason}). Money coming into this account will be "
                "used to repay the victim until this amount is recovered.")
    db.add(Notice(account_no=order.account_no, kind="RECOVERY", complaint_id=order.complaint_id, title=title, body=body))
    db.commit()


def approved_crypto_seizure(db: Session, complaint_id: int, account_no: str) -> int:
    """How much frozen crypto the court has allowed to be seized for this account in this complaint."""
    return sum(o.amount for o in db.query(CourtOrder).filter_by(
        complaint_id=complaint_id, account_no=account_no, kind="CRYPTO_SEIZURE", status="APPROVED"))


def release_to_victim(db: Session, complaint: Complaint) -> tuple[int, set[str]]:
    """Pays the victim under the court's refund order. Returns (amount, touched accounts).

    Pays only: money held in mule accounts, court-APPROVED recovery liens (as far as the balance
    allows) and court-APPROVED crypto seizures. Anything still waiting for the court is not paid.
    """
    victim = db.get(Account, complaint.victim_account)
    total, touched = 0, {victim.account_no}
    for n in complaint.nodes:
        acc = n.account
        due = n.held + n.recovery_approved - n.released
        amount = min(due, acc.balance)
        if amount > 0:
            acc.lien_amount = max(0, acc.lien_amount - amount)
            move_money(db, amount=amount, channel="REFUND", debit=acc, credit=victim, release_lien=True,
                       remark=f"Court-ordered refund {complaint.ack_no}",
                       narration_dr=f"REFUND/DR/COURT ORDER/{complaint.ack_no}",
                       narration_cr=f"REFUND/CR/COURT ORDER/{complaint.ack_no}")
            n.released += amount
            total += amount
            touched.add(acc.account_no)
        crypto_due = min(n.crypto_frozen, approved_crypto_seizure(db, complaint.id, n.account_no)) - n.crypto_released
        if crypto_due > 0:
            seized = _seize_crypto(db, n.account_no, crypto_due)
            if seized > 0:
                move_money(db, amount=seized, channel="REFUND", debit=exchange_account(db), credit=victim,
                           remark=f"Crypto seized {complaint.ack_no}",
                           narration_dr=f"REFUND/DR/CRYPTO SEIZURE/{complaint.ack_no}",
                           narration_cr=f"REFUND/CR/CRYPTO SEIZED AT COINVAULT/{complaint.ack_no}")
                n.crypto_released += seized
                total += seized
    if total:
        complaint.status = "REFUNDED"
        db.add(Notice(account_no=victim.account_no, kind="REFUND", complaint_id=complaint.id,
                      title="Money returned to you",
                      body=f"{rupees(total)} has been returned to your account by court order in complaint "
                           f"{complaint.ack_no}."))
    db.commit()
    return total, touched


def _seize_crypto(db: Session, account_no: str, amount: int) -> int:
    """Sells the mule's exchange wallet (rupees first, then coins) up to `amount` paise."""
    user = _crypto_user(db, account_no)
    if not user:
        return 0
    seized = 0
    for asset in ["INR", *COINS]:
        bal = db.get(CryptoBalance, (user.id, asset))
        if not bal or bal.amount <= 0 or seized >= amount:
            continue
        need = amount - seized
        if asset == "INR":
            take, value = min(bal.amount, need), min(bal.amount, need)
        else:
            price = price_paise(asset)
            take = min(bal.amount, -(-need * UNITS // price))  # round up so the victim is fully paid
            value = min(take * price // UNITS, need)
        bal.amount -= take
        seized += value
        db.add(CryptoEntry(crypto_user_id=user.id, kind="POLICE_SEIZURE", asset=asset,
                           quantity=0 if asset == "INR" else take, inr_paise=value))
    return seized


# ---------------------------------------------------------------- Phase 6: branch verification decisions

DECISIONS = {"INNOCENT", "TRICKED", "INVOLVED"}


def decide_verification(db: Session, case: VerificationCase, decision: str, remarks: str, officer_name: str) -> set[str]:
    """Applies the police decision to every account with the customer's PAN.

    INNOCENT  - hacked / stolen identity: back to ACTIVE, PAN unblocked.
    TRICKED   - fooled by a job/commission scam, signed an undertaking: back to ACTIVE, PAN unblocked,
                but court-approved recovery liens stay (available balance stays negative until repaid).
    INVOLVED  - knowingly rented or sold the account: CONFIRMED_MULE, stays blocked.
    In every case money held for victims stays held until the court's refund order.
    """
    pan = case.account.customer.pan
    linked = db.query(Account).join(Account.customer).filter_by(pan=pan).all()
    restore = decision in ("INNOCENT", "TRICKED")
    for acc in linked:
        if acc.status in (MULE, "CONFIRMED_MULE"):
            acc.status = "ACTIVE" if restore else "CONFIRMED_MULE"
    blacklisted = db.get(PanBlacklist, pan)
    if restore and blacklisted:
        db.delete(blacklisted)

    case.status = "DECIDED"
    case.decision = decision
    case.police_remarks = remarks.strip()
    case.decided_by = officer_name
    case.decided_at = datetime.now()

    title, body = {
        "INNOCENT": ("Removed from the mule list",
                     "After branch verification the police found that your account was misused without your "
                     "knowledge. All services are restored."),
        "TRICKED": ("Services restored with conditions",
                    "After branch verification the police accepted that you were tricked. Services are restored "
                    "under your signed undertaking. Any court-approved recovery amount must still be repaid: "
                    "money coming into your account goes to the victim first."),
        "INVOLVED": ("Confirmed as a money mule",
                     "After branch verification the police found that you knowingly allowed your account to be used "
                     "for fraud. Your accounts stay blocked across all banks and the police case continues."),
    }[decision]
    held_note = " Money held for fraud victims stays on hold until the court's refund order." if any(
        a.lien_amount for a in linked) else ""
    for acc in linked:
        db.add(Notice(account_no=acc.account_no, kind="VERIFIED" if restore else "MULE", title=title,
                      body=body + (f" Police remarks: {case.police_remarks}" if case.police_remarks else "") + held_note))
    db.commit()
    return {a.account_no for a in linked}