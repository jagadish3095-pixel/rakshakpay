"""RakshakPay documentary v2 (English, no cartoon characters): real app screens and slides.

    python make_doc_v2.py <shots_dir> <work_dir> <out.mp4 | preview>

Uses the engine of make_video.py (same look as the first documentary) with the updated story:
ATM withdrawal, mule blocking on UPI and ATM, the warning for ordinary payers, branch delisting,
and the citizen safety rules.
"""

import pathlib
import sys

import make_video as mv
from make_video import (AMBER, GREEN, PURPLE, RED, SAFFRON, L_browser, L_browser_phone, L_chips, L_eco, L_flow,
                        L_grid, L_heading, L_phones, L_rows, L_rule, L_sequence, L_stack, L_title, L_tree, browser,
                        illus_browser, illus_crypto, illus_hold, illus_merchant, illus_pan, illus_phone,
                        place_shadowed)

BLUE = (90, 160, 255)


def beats(shots: pathlib.Path):
    S = lambda n: str(shots / f"{n}.png")  # noqa: E731
    play = [S(f"p2_play{i:02d}") for i in range(14)]
    return [
        ("title", "", ["RakshakPay.", "A system that follows stolen money, and stops it, in seconds."],
         L_title("RakshakPay", "A system that follows stolen money, and stops it, in seconds.",
                 "Smart India Hackathon • Cyber fraud money trail")),

        # ---- the problem
        ("problem", "THE PROBLEM",
         ["Every day, people in India lose money to cyber fraud.", "Fake KYC calls.", "Fake jobs.",
          "Investment scams.", "Courier scams."],
         L_chips("Cyber fraud, every day", [("Fake KYC calls", "\U0001F4DE", RED), ("Fake jobs", "\U0001F4C4", AMBER),
                                            ("Investment scams", "\U0001F4B0", PURPLE),
                                            ("Courier scams", "\U0001F4F1", BLUE)])),
        ("problem", "THE PROBLEM",
         ["The victim calls 1930, or complains on the national cybercrime portal.", "And a race against time begins."],
         L_flow("Reporting the fraud", [("Call 1930", "national helpline", "\U0001F4DE", SAFFRON),
                                        ("cybercrime.gov.in", "online complaint", "\U0001F5A5", SAFFRON),
                                        ("Race against time", "money keeps moving", "⏱", RED)], [0, 0, 1])),
        ("today", "HOW IT WORKS TODAY",
         ["Today, much of this is manual.", "A complaint becomes a ticket.",
          "Officers write to banks one by one to find where the money went."],
         L_flow("Today: manual and slow", [("Complaint", "victim reports", "\U0001F464", mv.SOFT),
                                           ("Ticket", "raised by hand", "\U0001F4C4", mv.SOFT),
                                           ("Letters to banks", "one bank at a time", "\U0001F3E6", AMBER)], [0, 1, 2])),
        ("today", "HOW IT WORKS TODAY",
         ["But the fraudster moves faster.",
          "Within minutes, the money is split across mule accounts in different banks, withdrawn at ATMs, spent at "
          "shops, or turned into crypto."],
         L_tree()),
        ("today", "HOW IT WORKS TODAY",
         ["By the time a hold reaches the right account, it is often empty.",
          "Cash taken from an ATM is gone for good.",
          "And returning money to the victim needs a court order, which can take months."],
         L_flow("Too late, too slow", [("Hold arrives", "account already ₹0", "\U0001F512", RED),
                                       ("ATM cash", "gone for good", "\U0001F4B0", RED),
                                       ("Court order", "months of waiting", "⚖", AMBER)], [0, 1, 2])),
        ("today", "HOW IT WORKS TODAY",
         ["And an honest shopkeeper often pays the price.",
          "If he sold a phone to someone using fraud money, his whole account can be frozen.",
          "He has lost the goods, and his earnings are stuck too."],
         L_flow("Honest shopkeepers lose too", [("Phone sold", "₹10,000 received honestly", "\U0001F3EA", GREEN),
                                                ("Account frozen", "the whole account", "\U0001F512", RED),
                                                ("Double loss", "goods gone, money stuck", "✖", RED)], [0, 1, 2])),
        ("problems", "WHAT GOES WRONG",
         ["Six problems keep repeating.", "Fraud moves in minutes, but investigation takes days.",
          "No single bank sees the whole chain.", "Innocent shopkeepers get their whole account frozen.",
          "Crypto and ATM cash take the money out of the system.", "Refunds wait for a slow court process.",
          "And mules simply open new accounts in other banks."],
         L_grid("Six problems", [
             ("Too slow", "Fraud moves in minutes, investigation takes days", "⏱", RED),
             ("No full picture", "Money is split across many banks", "\U0001F3E6", AMBER),
             ("Innocent shops frozen", "Whole merchant accounts get blocked", "\U0001F3EA", GREEN),
             ("Cash and crypto exit", "Money leaves the banking system", "❄", PURPLE),
             ("Slow refunds", "Manual court process", "⚖", AMBER),
             ("Mules come back", "New accounts in other banks", "\U0001F6A9", RED)])),

        # ---- the idea and the rules
        ("idea", "OUR IDEA",
         ["RakshakPay connects the whole chain: five banks, a UPI app, a shop sound box, a crypto exchange and a "
          "cyber police console, all on one server."],
         L_eco()),
        ("idea", "OUR IDEA", ["So a single complaint can trace the money and stop it, automatically."],
         L_flow("One complaint, three seconds", [("Complaint", "from the victim's app", "\U0001F464", SAFFRON),
                                                 ("Trace", "every hop, every bank", "\U0001F50D", SAFFRON),
                                                 ("Hold", "the victim's money", "\U0001F512", GREEN)], [0, 0, 0])),
        ("rules", "THE RULES", ["These are the rules we designed."],
         L_title("Nine rules", "Designed so the money can be stopped, and only the guilty pay.")[1:]),
        ("rules", "THE RULES",
         ["Rule one: trace automatically.",
          "The moment a complaint is filed, every later transaction is replayed in time order, following the "
          "victim's money through every hop."],
         L_rule(1, "Trace automatically", "Every transaction after the fraud is replayed in time order.",
                "\U0001F50D", illus=illus_browser(S("p2_trail")))),
        ("rules", "THE RULES",
         ["Two: hold only the victim's money.", "Each account is held for exactly the traced amount, not frozen."],
         L_rule(2, "Hold only the victim's money", "A lien for exactly the traced amount, not a full freeze.",
                "\U0001F512", AMBER, illus=illus_hold())),
        ("rules", "THE RULES",
         ["Three: mark mule accounts.", "Every bank sees the mark, and so does the holder.",
          "UPI, transfers and ATM stay blocked until the holder is verified at the branch."],
         L_rule(3, "Mark mule accounts", "Visible to every bank and to the holder. UPI, transfers and ATM "
                "blocked until branch verification.", "\U0001F6A9", RED, illus=illus_phone(S("v_notices")))),
        ("rules", "THE RULES",
         ["Four: warn the sender.", "Pay anyway is allowed only to repay a victim."],
         L_rule(4, "Warn the sender", "A red warning before paying a mule. \"Pay anyway\" only to repay.",
                "⚠", AMBER, illus=illus_phone(S("b_mule_payee")))),
        ("rules", "THE RULES",
         ["Five: never touch the merchant.", "The shop keeps its money. Recovery comes from the buyer, the last mule."],
         L_rule(5, "Never touch the merchant", "The shop keeps its money. The buyer, the last mule, repays.",
                "\U0001F3EA", GREEN, illus=illus_merchant())),
        ("rules", "THE RULES",
         ["Six: blacklist the PAN across every bank and crypto exchange.", "No new account, and no crypto."],
         L_rule(6, "Blacklist the PAN", "No new bank account, no crypto account, anywhere.", "\U0001F6AB", RED,
                illus=illus_pan())),
        ("rules", "THE RULES",
         ["Seven: court-approved recovery.", "The system drafts the court application itself.",
          "After approval, a recovery lien collects the money, even into a negative balance."],
         L_rule(7, "Court-approved recovery", "Applications drafted automatically. Recovery lien can go "
                "negative.", "⚖", AMBER, illus=illus_browser(S("p_application")))),
        ("rules", "THE RULES",
         ["Eight: crypto is frozen at the exchange, and released only with a court seizure order."],
         L_rule(8, "Freeze crypto", "Frozen at the exchange; released only with a seizure order.", "❄",
                PURPLE, illus=illus_crypto())),
        ("rules", "THE RULES",
         ["And nine: the phone's GPS is mandatory.", "No location, no payment. ATM withdrawals record the ATM."],
         L_rule(9, "Location on every payment", "GPS is mandatory. ATM withdrawals record the ATM.",
                "\U0001F4CD", BLUE, illus=illus_phone(S("b_location_popup")))),

        # ---- the demo
        ("story", "WATCH IT WORK",
         ["Let us watch it work.",
          "Priya gets a call: her KYC has expired, and she must pay fifty thousand rupees to keep her account."],
         L_phones([S("b_lock"), S("b2_report1")], [0, 1], captions=["Priya's bank app", "₹50,000 paid to the caller"])),
        ("story", "WATCH IT WORK",
         ["She pays by UPI.",
          "Within minutes, the money passes through seven mules in four banks, from Jamtara to Kolkata, Deoghar and "
          "Nuh.",
          "In Deoghar, one mule takes five thousand in cash from an ATM.",
          "Ten thousand buys a phone in Jaipur, and ten thousand goes to a crypto exchange."],
         L_sequence(play)),
        ("story", "WATCH IT WORK",
         ["Priya picks the payment in her app and files the complaint.",
          "She gets only an acknowledgement number; the investigation details stay with the police."],
         L_phones([S("b2_form_filled"), S("b2_filed")], [0, 1], captions=["Report fraud (1930)",
                                                                           "Only the acknowledgement"])),
        ("story", "WATCH IT WORK",
         ["In the police console, the complaint is already traced.",
          "Twenty-five thousand rupees is on hold, and about five thousand in crypto is frozen."],
         L_browser(S("p2_dashboard"), caption="Cyber Police console")),
        ("story", "WATCH IT WORK",
         ["The summary shows everything: amount lost, accounts traced, money held, spent at shops, ATM cash, frozen "
          "crypto, and what escaped."],
         L_browser(S("p2_summary"), caption="Complaint summary")),
        ("story", "WATCH IT WORK", ["The money trail shows the same story as a tree, account by account."],
         L_browser(S("p2_trail"), caption="Money trail")),
        ("story", "WATCH IT WORK",
         ["The ATM withdrawal is on the map too.",
          "Every cash-out is recorded with its location, and areas with many cash-outs become hotspots."],
         L_browser(S("p2_map"), caption="ATM withdrawal: Godavari Bank ATM, Deoghar")),
        ("story", "WATCH IT WORK",
         ["For the ATM cash, the phone and the escaped crypto, court applications are already drafted, ready for the "
          "magistrate.",
          "The shopkeeper is never touched: Prem, the buyer, repays."],
         L_browser(S("p2_courts"), caption="Court applications, drafted automatically")
         + [place_shadowed(browser(S("p_application"), 1000), 560, 250, at=1)]),
        ("story", "WATCH IT WORK",
         ["The mules are marked at once.",
          "Pavan's ATM card is declined, and his notice explains that UPI, transfers and ATM are all blocked until he "
          "is verified at his branch."],
         L_phones([S("v_atm_blocked"), S("v_notices")], [0, 1], captions=["ATM: declined", "Mule-list notice"])),
        ("story", "WATCH IT WORK",
         ["The UPI app blocks the mule too.", "Money coming in is still accepted, and it goes to repay the victim."],
         L_phones([S("u_home"), S("u_blocked")], [0, 1], captions=["Mule's UPI app", "Payment refused"])),
        ("story", "WATCH IT WORK",
         ["And an ordinary person about to pay a mule, say for a cheap phone seen online, sees this warning first.",
          "He can cancel. Pay anyway is only for someone repaying a victim."],
         L_phones([S("b_mule_payee"), S("b_mule_dialog")], [0, 1], captions=["Mule warning", "Pay anyway = repayment"])),
        ("story", "WATCH IT WORK", ["And a payment without location is simply not made."],
         L_phones([S("b_location_popup")], [0], captions=["No GPS, no payment"])),
        ("story", "WATCH IT WORK",
         ["To get off the mule list, the holder visits the home branch.",
          "The officer does a fresh KYC with original documents and an OTP, records the statement, and sends a "
          "recommendation to the police."],
         L_phones([S("o_verify4"), S("o_statement"), S("o_recommend2")], [0, 1, 1],
                  captions=["Re-KYC", "Statement", "Recommendation"], height=720)),
        ("story", "WATCH IT WORK",
         ["The cyber police make the final decision.",
          "Innocent: fully removed from the list. Tricked: services restored, but the court-ordered recovery must be "
          "repaid. Knowingly involved: blocked in every bank, and the police case continues."],
         L_browser(S("p2_case"), caption="Police decision")),
        ("story", "WATCH IT WORK",
         ["Pavan was tricked by a job offer.",
          "His account works again, but five thousand is still to be recovered, so his balance shows minus five "
          "thousand."],
         L_phones([S("v_home_neg"), S("v_notices_after")], [0, 1], captions=["Active again: −₹5,000",
                                                                             "Recovery lien notice"])),
        ("story", "WATCH IT WORK",
         ["When the court approves, one tap releases the money.",
          "Almost thirty thousand rupees is back with Priya, with a notice in her app.",
          "The rest comes in through the recovery liens."],
         L_phones([S("b2_home_after"), S("b2_notices")], [0, 1], captions=["Money back", "Refund notice"])),

        # ---- safety rules for citizens
        ("safety", "STAY SAFE",
         ["And now, eight rules to keep you safe.",
          "One. No bank or police officer will ever ask you on a call to update KYC or send money.",
          "Two. Never share your OTP, UPI PIN or CVV. You never need a PIN to receive money.",
          "Three. Never rent out your bank account, ATM card or SIM. A job that pays you to move money is a mule trap.",
          "Four. Read the name and any warning before you pay. If you see a mule warning, stop.",
          "Five. If you are cheated, call 1930 at once, or complain on cybercrime.gov.in. The sooner you report, the "
          "more is saved.",
          "Six. Keep your phone's location and your bank's SMS alerts on.",
          "Seven. Never accept money from strangers. If someone says, I'll send money to your account, please buy "
          "this for me, that is stolen money, and it will be recovered from you, not from the fraudster.",
          "And eight. Never exchange online money for hard cash with strangers."],
         L_grid("8 rules to keep you safe", [
             ("No KYC on calls", "Banks and police never ask on the phone", "\U0001F4DE", RED),
             ("Never share OTP or PIN", "No PIN is needed to receive money", "\U0001F512", AMBER),
             ("Never rent your account", "Account, card or SIM — never", "\U0001F6AB", RED),
             ("Read the warning", "Mule warning? Stop the payment", "⚠", AMBER),
             ("Report at once: 1930", "or cybercrime.gov.in", "⏱", GREEN),
             ("Location and SMS on", "Every payment needs location", "\U0001F4CD", BLUE),
             ("No money from strangers", "'Buy this for me' = you repay", "\U0001F464", RED),
             ("No cash swaps", "Never trade UPI money for cash", "\U0001F4B0", AMBER)], y0=230, gap=150)),

        # ---- tech, impact, end
        ("tech", "TECHNOLOGY",
         ["We built nine Android apps in Flutter and Dart, sharing one core library.",
          "The server is Python and FastAPI, with a PostgreSQL database on Neon, hosted on Render.",
          "Every app works in English, Hindi and Kannada, with a night mode."],
         L_stack()),
        ("impact", "WHAT IT CHANGES",
         ["With RakshakPay, money is held in seconds, not days.", "Shopkeepers are protected.",
          "Mules cannot just move banks.", "And victims get their money back faster."],
         L_rows("What changes", [
             ("Seconds, not days", "Money is held the moment the complaint is filed", "⏱", GREEN),
             ("Shops protected", "Merchants keep their money; buyers repay", "\U0001F3EA", GREEN),
             ("No escape for mules", "Blocked on UPI, transfers and ATM; PAN blacklisted", "\U0001F6A9", AMBER),
             ("Faster refunds", "Court applications drafted automatically", "₹", GREEN)], y0=300, gap=150)),
        ("impact", "WHAT'S NEXT",
         ["Today it runs on simulated banks.",
          "Next: protection against fake complaints, and forecasting mule hotspots.",
          "A real launch needs RBI, NPCI, the banks and the courts to connect."],
         L_rows("Next steps", [
             ("A working prototype", "Five simulated banks, real apps, real server", "✔", SAFFRON),
             ("Fake-complaint protection", "and forecasting of mule hotspots", "\U0001F50D", SAFFRON),
             ("Real-world launch", "needs RBI, NPCI, banks and courts to connect", "\U0001F3E6", SAFFRON)],
             y0=320, gap=160)),
        ("end", "", ["RakshakPay.", "Protecting every rupee."],
         L_title("RakshakPay", "Protecting every rupee.", "github.com/jagadish3095-pixel/rakshakpay")),
    ]


if __name__ == "__main__":
    mv.beats = beats
    mv.main(*sys.argv[1:4])
