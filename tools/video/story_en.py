"""English version of the v2 story video: lines, on-screen labels and voices (used by make_full.py, lang "en")."""

VOICES_EN = {  # voice, rate, pitch (Indian English neural voices)
    "narrator": ("en-IN-PrabhatNeural", "+0%", "+0Hz"),
    "priya": ("en-IN-NeerjaExpressiveNeural", "+0%", "+0Hz"),
    "pankaj": ("en-IN-PrabhatNeural", "+8%", "-10Hz"),
    "meera": ("en-IN-NeerjaNeural", "-2%", "-10Hz"),
    "mahesh": ("en-IN-PrabhatNeural", "-8%", "-4Hz"),
    "prem": ("en-IN-PrabhatNeural", "+6%", "+16Hz"),
    "pavan": ("en-IN-PrabhatNeural", "+4%", "+8Hz"),
    "pradeep": ("en-IN-PrabhatNeural", "+6%", "-6Hz"),
    "ravi": ("en-IN-PrabhatNeural", "+6%", "+24Hz"),
    "lakshmi": ("en-IN-NeerjaNeural", "+0%", "+0Hz"),
}


def spoken(text):
    """Text for the voice: say the names the way people say them."""
    return (text.replace("RakshakPay", "Rakshak Pay").replace("1930", "1 9 3 0")
            .replace("cybercrime.gov.in", "cyber crime dot gov dot in").replace("CoinVault", "Coin Vault"))


EN = {
    # ---- spoken lines (Hinglish caption -> English)
    "Sirf do minute. Ek phone call. Aur pachaas hazaar rupaye gayab.":
        "Two minutes. One phone call. And fifty thousand rupees are gone.",
    "Yeh kahani Priya ki hai — aur kal yeh aapke kisi apne ki bhi ho sakti hai.":
        "This is Priya's story — and tomorrow, it could be the story of someone you love.",
    "Hello, Priya ji? Main Kaveri Bank ke KYC department se baat kar raha hoon.":
        "Hello, am I speaking to Priya? I'm calling from the KYC department of Kaveri Bank.",
    "Haan ji, boliye?": "Yes, tell me?",
    "Aapka KYC expire ho chuka hai. Aaj update nahi hua, toh aapka account block ho jayega.":
        "Your KYC has expired. If it isn't updated today, your account will be blocked.",
    "Arre! Toh ab main kya karoon?": "Oh no! So what do I do now?",
    "Ghabraiye mat. Bas pachaas hazaar ka ek verification payment kijiye. Kaam hote hi poori raqam wapas aa jayegi.":
        "Don't worry. Just make a verification payment of fifty thousand. You'll get it all back as soon as it's done.",
    "Theek hai… bhej diya.": "Okay… I've sent it.",
    "Bahut shukriya, Priya ji.": "Thank you so much, Priya.",
    "Paisa milte hi Pankaj use turant aage bhej deta hai — ek account se doosre, doosre se teesre.":
        "The moment the money arrives, Pankaj passes it on — from one account to another, and then another.",
    "Inhe kehte hain mule accounts — aise log jo kuch paison ke liye apna bank account dusron ko istemaal karne dete "
    "hain.":
        "These are called mule accounts — people who let others use their bank account for a small fee.",
    "Kuch hi minuton mein paisa saat accounts aur chaar bankon mein bikhar jaata hai.":
        "Within minutes, the money is scattered across seven accounts in four banks.",
    "Deoghar mein Pavan ATM se paanch hazaar nakad nikaal leta hai.":
        "In Deoghar, Pavan withdraws five thousand in cash at an ATM.",
    "Das hazaar crypto mein badle gaye, aur unka ek hissa desh se bahar bhej diya gaya.":
        "Ten thousand is turned into crypto, and part of it is sent out of the country.",
    "Bhaiya, woh naya phone dikhana. Das hazaar ka hai na? UPI se de deta hoon.":
        "Brother, show me that new phone. It's ten thousand, right? I'll pay by UPI.",
    "Yeh lijiye sir. Payment aa gaya — dhanyavaad!": "Here you go, sir. Payment received — thank you!",
    "Hello, 1930? Mere saath fraud ho gaya hai… pachaas hazaar!":
        "Hello, 1930? I've been cheated… fifty thousand rupees!",
    "Priya turant shikayat karti hai. Lekin aaj ka tareeka bahut dheema hai.":
        "Priya reports it immediately. But today's process is very slow.",
    "Shikayat ek ticket ban jaati hai. Phir har bank ko alag-alag letter jaata hai — yeh paisa kahan gaya?":
        "The complaint becomes a ticket. Then a separate letter goes to every bank — where did this money go?",
    "Jab tak jawab aata hai, mule accounts khaali ho chuke hote hain. ATM se nikla cash toh hamesha ke liye gaya.":
        "By the time the answers come, the mule accounts are empty. And cash taken from an ATM is gone forever.",
    "Aur sabse bada nuksaan hota hai ek imaandaar dukaandaar ka.":
        "And the biggest loss falls on an honest shopkeeper.",
    "Maine toh phone imaandaari se becha tha! Mera poora account kyun band kar diya?":
        "I sold that phone honestly! Why has my whole account been frozen?",
    "Fraud ka paisa jis bhi account tak pahunchta hai, use aksar poora freeze kar diya jaata hai — dukaandaar ka bhi.":
        "Any account that fraud money reaches is often frozen completely — even a shopkeeper's.",
    "Mahesh ka phone bhi gaya, aur uski kamaai bhi atak gayi.":
        "Mahesh has lost the phone, and his earnings are stuck too.",
    "Mule doosre bank mein naya account khol lete hain. Aur Priya? Court ke order ka mahinon intezaar.":
        "The mules simply open new accounts in other banks. And Priya? She waits months for a court order.",
    "Isi samasya ka hal hai — RakshakPay.": "This is the problem RakshakPay solves.",
    "Paanch bank, UPI app, dukaan ka sound box, crypto exchange aur cyber police — sab ek hi system se jude hue.":
        "Five banks, a UPI app, a shop sound box, a crypto exchange and the cyber police — all connected to one "
        "system.",
    "Ab wahi kahani dobara dekhiye — is baar RakshakPay ke saath.":
        "Now watch the same story again — this time with RakshakPay.",
    "Is payment ko main fraud report karti hoon.": "I'm reporting this payment as fraud.",
    "Priya app mein hi woh payment chunti hai aur shikayat bhejti hai. Use turant ek acknowledgement number milta hai "
    "— jaanch ki baaki jaankari sirf police ke paas rehti hai.":
        "Priya picks the payment right in her app and files the complaint. She gets an acknowledgement number at once "
        "— the investigation details stay with the police.",
    "Shikayat aate hi system ne poora paisa trace kar liya — har account, har bank.":
        "The moment the complaint came in, the system traced all the money — every account, every bank.",
    "System fraud ke baad ka har transaction samay ke kram mein dobara chalata hai, aur Priya ke paise ka peecha "
    "karta hai.":
        "The system replays every transaction after the fraud in time order, and follows Priya's money.",
    "Pachchees hazaar mule accounts mein hold, aur lagbhag paanch hazaar ka crypto exchange par freeze.":
        "Twenty-five thousand is on hold in mule accounts, and about five thousand in crypto is frozen at the "
        "exchange.",
    "Poora account band nahi hota — sirf utni raqam roki jaati hai jitni Priya ki us account tak pahunchi.":
        "No account is frozen completely — only the amount of Priya's money that reached it is held.",
    "Jo paisa ATM se nikal chuka hai, uska bhi hisaab hai. Har ATM withdrawal ki jagah map par dikhti hai, aur zyada "
    "cash-out wale ilaake hotspot ban jaate hain.":
        "Even cash taken from an ATM is accounted for. Every ATM withdrawal appears on the map, and areas with many "
        "cash-outs become hotspots.",
    "Pavan ke nikaale paanch hazaar ke liye court application apne aap taiyaar hoti hai.":
        "For the five thousand Pavan withdrew, a court application is drafted automatically.",
    "Yeh kya? Card hi nahi chal raha!": "What? My card isn't working!",
    "Mule list mein aate hi Pavan ka ATM card, UPI aur transfer — sab band.":
        "Once Pavan is on the mule list, his ATM card, UPI and transfers are all blocked.",
    "UPI se bhej deta hoon… arre, yeh bhi block!": "I'll send it by UPI… what, this is blocked too!",
    "UPI app par bhi mule ko saaf sandesh milta hai — payment band, branch jaakar verification karaiye.":
        "The UPI app tells the mule clearly — payments are blocked; get verified at your branch.",
    "Haan, account mein aane wala paisa aata rahega, aur victim ka nuksaan bharega.":
        "Money coming into the account still arrives — and it goes towards the victim's loss.",
    "Online ek purana phone dekha tha, saste mein mil raha hai. Bechne wale ko das hazaar bhej deta hoon.":
        "I found a second-hand phone online, really cheap. Let me send the seller ten thousand.",
    "Yeh account mule list mein hai? Nahi bhai, payment cancel!":
        "This account is on the mule list? No way — I'm cancelling the payment!",
    "RakshakPay har us vyakti ko pehle hi chetavni deta hai jo mule account mein paisa bhejne ja raha ho. Ravi ka paisa "
    "bach gaya.":
        "RakshakPay warns anyone who is about to send money to a mule account. Ravi's money is safe.",
    "Pay anyway sirf us vyakti ke liye hai jo victim ka paisa lautana chahta hai — aisa paisa seedha victim ki recovery "
    "mein jaata hai.":
        "Pay anyway is only for someone repaying a victim — that money goes straight to the victim's recovery.",
    "Koi baat nahi, naya account khol leta hoon…": "No problem, I'll just open a new account…",
    "Ab yeh mumkin nahi. Uska PAN har bank aur crypto exchange mein blacklist ho chuka hai.":
        "Not any more. His PAN is blacklisted at every bank and crypto exchange.",
    "Mera account bilkul theek chal raha hai!": "My account is working perfectly!",
    "Mahesh ne imaandaari se saamaan becha tha, isliye RakshakPay uske account ko haath bhi nahi lagata.":
        "Mahesh sold his goods honestly, so RakshakPay never touches his account.",
    "Woh das hazaar Prem se wasool hote hain — jisne fraud ke paise se phone khareeda tha.":
        "The ten thousand is recovered from Prem — who bought the phone with the fraud money.",
    "Court ki manzoori ke baad uske account par recovery lien lagta hai, chahe balance minus mein kyun na chala jaaye.":
        "Once the court approves, a recovery lien is placed on his account, even if the balance goes negative.",
    "Mera balance minus mein?!": "My balance is negative?!",
    "Court ke liye saari applications bhi system ne khud taiyaar kar di hain — account, raqam aur transaction number "
    "ke saath.":
        "The system has also drafted every court application itself — with the accounts, amounts and transaction "
        "numbers.",
    "Har payment ke saath phone ki location darj hoti hai. Location band? Toh payment bhi nahi.":
        "Every payment records the phone's location. Location off? Then no payment.",
    "Madam, mujhe ek part-time job ke naam par phasaaya gaya tha. Mujhe nahi pata tha yeh fraud ka paisa hai.":
        "Madam, I was trapped by a part-time job offer. I didn't know it was fraud money.",
    "Original PAN, Aadhaar aur photo dikhaiye. Aapke mobile par OTP bhi bhej rahi hoon.":
        "Please show me your original PAN, Aadhaar and photo. I'm also sending an OTP to your mobile.",
    "Mule list se bahar aane ka ek hi raasta hai — apni home branch jaakar asli documents ke saath dobara KYC.":
        "There is only one way off the mule list — a fresh KYC with original documents at your home branch.",
    "Bank officer customer ka bayaan likhta hai aur apni salaah police ko bhejta hai. Aakhri faisla cyber police ka "
    "hota hai.":
        "The bank officer records the customer's statement and sends a recommendation to the police. The cyber police "
        "make the final decision.",
    "Pavan ko dhokha diya gaya tha. Services wapas chalu — lekin recovery jaari rahegi.":
        "Pavan was tricked. His services are restored — but the recovery continues.",
    "Teen faisle ho sakte hain. Begunaah — account hack hua ya documents ka galat istemaal hua: poori tarah list se "
    "bahar. Dhokhe ka shikaar — services wapas, lekin court wali recovery chukaani hogi. Aur jaan-boojhkar shaamil — "
    "account har bank mein band rehta hai, aur police case chalta hai.":
        "There are three possible decisions. Innocent — the account was hacked or the documents were misused: fully "
        "removed from the list. Tricked — services come back, but the court-ordered recovery must be repaid. And "
        "knowingly involved — the accounts stay blocked in every bank, and the police case continues.",
    "Pavan ka account phir se chalu hai — lekin paanch hazaar ki recovery baaki hai, isliye balance minus mein dikhta "
    "hai.":
        "Pavan's account works again — but five thousand is still to be recovered, so his balance shows negative.",
    "Court ki manzoori mil gayi hai. Raqam release kar rahi hoon.":
        "The court has approved it. I'm releasing the money now.",
    "Mera paisa wapas aa gaya!": "My money is back!",
    "Lagbhag tees hazaar rupaye seedhe Priya ke account mein — aur baaki raqam recovery lien se wasool hoti rahegi.":
        "Almost thirty thousand rupees goes straight back to Priya — and the rest keeps coming in through the "
        "recovery liens.",
    "Aur ab, aapki suraksha ke kuch zaroori niyam.": "And now, a few important rules to keep you safe.",
    "Ek. Koi bhi bank ya police phone par KYC update ya paise nahi maangti.":
        "One. No bank or police officer will ever ask you on a call to update KYC or send money.",
    "Do. OTP, UPI PIN ya CVV kisi ko mat bataiye. Paisa lene ke liye kabhi PIN daalna nahi padta.":
        "Two. Never share your OTP, UPI PIN or CVV. You never need to enter a PIN to receive money.",
    "Teen. Apna bank account, ATM card ya SIM kisi ko kiraye par mat dijiye. Ghar baithe paisa ghumao wali naukri, mule "
    "banne ka jaal hai.":
        "Three. Never rent out your bank account, ATM card or SIM. A job that pays you to move money from home is a "
        "trap that turns you into a mule.",
    "Chaar. Payment se pehle naam aur chetavni dhyaan se padhiye. Mule warning dikhe toh payment rok dijiye.":
        "Four. Read the name and any warning before you pay. If you see a mule warning, stop the payment.",
    "Paanch. Fraud ho jaaye toh turant 1930 par call kijiye ya cybercrime.gov.in par shikayat kijiye — jitni jaldi, "
    "utna zyada paisa bachta hai.":
        "Five. If you are cheated, call 1930 at once or complain on cybercrime.gov.in — the sooner you report, the "
        "more money is saved.",
    "Chhe. Phone ki location aur bank ke SMS alert hamesha chalu rakhiye.":
        "Six. Always keep your phone's location and your bank's SMS alerts on.",
    "Saat. Anjaan logon se paisa mat lijiye. Koi kahe main aapke account mein paise bhejta hoon, aap mere liye kuch "
    "khareed do — woh fraud ka paisa hai, aur wasooli aapse hogi, fraudster se nahi.":
        "Seven. Never accept money from strangers. If someone says, I'll send money to your account, please buy this "
        "for me — that is stolen money, and it will be recovered from you, not from the fraudster.",
    "Aur aath. Anjaan logon ke saath online paise ko nakad cash mein kabhi mat badliye.":
        "And eight. Never exchange online money for hard cash with strangers.",
    "RakshakPay ke nau niyam: turant trace. Sirf victim ka paisa hold. Mule accounts par nishaan. Bhejne wale ko "
    "chetavni. Dukaandaar surakshit. PAN blacklist. Court ki manzoori se recovery. Crypto freeze. Aur har payment par "
    "location.":
        "RakshakPay's nine rules: instant trace. Hold only the victim's money. Mark mule accounts. Warn the sender. "
        "Protect the shopkeeper. Blacklist the PAN. Court-approved recovery. Freeze crypto. And location on every "
        "payment.",
    "Humne nau Android apps Flutter mein banaye, server Python aur FastAPI par, aur database PostgreSQL par. Har app "
    "English, Hindi aur Kannada mein chalta hai.":
        "We built nine Android apps in Flutter, the server in Python with FastAPI, and the database on PostgreSQL. "
        "Every app works in English, Hindi and Kannada.",
    "Abhi yeh demo bankon par chalta hai. Asli duniya mein ise RBI, NPCI, bankon aur adalaton se jodna hoga.":
        "Today it runs on demo banks. In the real world, it would need to connect to the RBI, NPCI, the banks and "
        "the courts.",
    "Aage hum fake shikayaton ko pehchaanne aur mule hotspots ka anumaan lagane par kaam karenge.":
        "Next, we will work on detecting fake complaints and forecasting mule hotspots.",
    "RakshakPay — har rupaye ki raksha.": "RakshakPay — protecting every rupee.",

    # ---- on-screen labels
    "Court order ka intezaar… mahinon tak": "Waiting months for a court order…",
    "Mule → naya account, doosra bank": "Mule → new account, another bank",
    "har rupaye ki raksha": "protecting every rupee",
    "Police ke teen faisle": "The police's three decisions",
    "Begunaah (Innocent)": "Innocent",
    "Dhokhe ka shikaar (Tricked)": "Tricked",
    "Jaan-boojhkar shaamil (Involved)": "Knowingly involved",
    "RakshakPay ke nau niyam": "RakshakPay's nine rules",
    "RakshakPay — har rupaye ki raksha": "RakshakPay — protecting every rupee",
    "Turant trace": "Instant trace",
    "Sirf victim ka paisa hold": "Hold only the victim's money",
    "Mule accounts par nishaan": "Mark mule accounts",
    "Bhejne wale ko chetavni": "Warn the sender",
    "Dukaandaar surakshit": "Protect the shopkeeper",
    "Court se recovery": "Court-approved recovery",
    "Har payment par location": "Location on every payment",
    "Aapki suraksha ke 8 niyam": "8 rules to keep you safe",
    "Bank kabhi phone par KYC nahi maangta": "No bank asks for KYC on a call",
    "OTP, UPI PIN, CVV — kisi ko nahi": "Never share OTP, UPI PIN or CVV",
    "Account, card, SIM kiraye par nahi": "Never rent out your account, card or SIM",
    "'Ghar baithe paisa ghumao' jobs make you a mule": "'Move money from home' jobs make you a mule",
    "Payment se pehle warning padhiye": "Read the warning before you pay",
    "Fraud? Turant 1930": "Cheated? Call 1930 at once",
    "Location aur SMS alert ON": "Keep location and SMS alerts on",
    "Anjaan logon ka paisa nahi": "Never accept money from strangers",
    "Online paise ke badle cash nahi": "Never swap online money for cash",
}
