"""RakshakPay full video v2 (Hinglish): documentary + cartoon story + real app screens.

    python make_full.py <shots_dir> <work_dir> <out.mp4 | preview>

Script: script_v2_hinglish.md. Voices: Microsoft neural voices (edge-tts). Consecutive lines of the same
speaker are spoken in one go so the voice flows; word timings place each caption at the right moment.
"""

import asyncio
import hashlib
import json
import pathlib
import re
import subprocess
import sys
import wave

import edge_tts
import imageio_ffmpeg
from PIL import Image, ImageDraw

import make_story as ms
import sets
from make_story import Line, N, actor, calendar, card, desk, kaveri_phone, label, paste, pop, sms, stamp
from make_video import (AMBER, CARD, GREEN, NAVY, PURPLE, RED, SAFFRON, SOFT, WHITE, L_eco, L_stack, badge,
                        browser, font, gradient_bg, illus_pan, logo, phone, rounded, shadowed, text_img, wrap)

W, H, FPS = 1920, 1080, 30
LANG = "hi"  # "hi" = Hinglish, "en" = English (see story_en.py)
GAP = 0.30  # pause when the speaker changes
SHOT_PAD = 0.40

ms.VOICES.update({
    "narrator": ("hi-IN-MadhurNeural", "+6%", "+0Hz"),
    "pavan": ("hi-IN-MadhurNeural", "+6%", "+8Hz"),
    "pradeep": ("hi-IN-MadhurNeural", "+8%", "-6Hz"),
    "ravi": ("hi-IN-MadhurNeural", "+8%", "+26Hz"),
    "lakshmi": ("hi-IN-SwaraNeural", "+2%", "-4Hz"),
})
ms.NAMES.update({"pavan": "PAVAN", "pradeep": "PRADEEP", "ravi": "RAVI", "lakshmi": "LAKSHMI (BANK OFFICER)"})
ms.PILL.update({"pavan": (90, 90, 200), "pradeep": (200, 70, 60), "ravi": (40, 120, 200),
                "lakshmi": (120, 70, 170)})


def L(text):
    """On-screen text in the chosen language."""
    if LANG == "en":
        from story_en import EN
        return EN.get(text, text)
    return text


# ---------------------------------------------------------------- speech, one call per run of the same speaker

def _words(text):
    return [t for t in text.split() if re.search(r"\w", t)]


async def _tts(text, voice, rate, pitch, mp3):
    marks = []
    c = edge_tts.Communicate(text, voice, rate=rate, pitch=pitch, boundary="WordBoundary")
    with open(mp3, "wb") as f:
        async for ch in c.stream():
            if ch["type"] == "audio":
                f.write(ch["data"])
            elif ch["type"] == "WordBoundary":
                marks.append(ch["offset"] / 1e7)
    return marks


def speak_group(lines, work):
    """Speaks lines of one speaker together. Returns (pcm, [start seconds of each line])."""
    voice, rate, pitch = ms.VOICES[lines[0].who]
    text = " ".join(l.deva for l in lines)
    key = hashlib.sha1(f"v2{voice}{rate}{pitch}{text}".encode()).hexdigest()[:16]
    wav, meta = work / f"{key}.wav", work / f"{key}.json"
    if not wav.exists():
        mp3 = work / f"{key}.mp3"
        marks = asyncio.run(_tts(text, voice, rate, pitch, mp3))
        subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error", "-i", str(mp3), "-ar", "48000",
                        "-ac", "1", str(wav)], check=True)
        meta.write_text(json.dumps(marks))
    marks = json.loads(meta.read_text())
    with wave.open(str(wav)) as w:
        pcm = w.readframes(w.getnframes())
    starts, k = [], 0
    for l in lines:
        starts.append(marks[min(k, len(marks) - 1)] if marks and k else 0.0)
        k += len(_words(l.deva))
    starts[0] = 0.0
    return pcm, starts


# ---------------------------------------------------------------- helpers for real screens

def shadow_img(im):
    return shadowed(im)[0]


def zoom_pop(frame, img, cx, cy, c, t0=0.0, z=0.03):
    """Fades in at t0, then slowly zooms (the 'documentary' look)."""
    a = max(0.0, min(1.0, (c.t - t0) / 0.45))
    if a <= 0:
        return
    s = 1 + z * max(0.0, c.t - t0) / max(c.dur, 0.1)
    im = img.resize((int(img.width * s), int(img.height * s)), Image.BILINEAR) if s > 1.001 else img
    paste(frame, im, cx - im.width / 2, cy - im.height / 2, a)


def pill(text, color=SAFFRON, fg=NAVY):
    t = text_img(text, 30, "semi", fg)
    c = rounded((t.width + 44, t.height + 14), 26, color + (255,))
    c.alpha_composite(t, (22, 6))
    return c


def map_base(shots):
    src = Image.open(shots / "p2_play00.png").convert("RGB").crop((450, 155, 1450, 975))
    m = src.resize((1317, 1080), Image.LANCZOS).convert("RGBA")
    bg = Image.new("RGBA", (W, H), (14, 22, 44, 255))
    bg.alpha_composite(m, (301, 0))
    return bg


def rule_card(n, title, body, ic, color, w=820):
    im = rounded((w, 140), 24, CARD + (255,), outline=color + (255,), width=3)
    im.alpha_composite(badge(ic, 80, color, NAVY), (22, 30))
    d = ImageDraw.Draw(im)
    tf, bf = font(29, "bold"), font(23)
    tl = wrap(f"{n}. {title}", tf, w - 150)[:2]
    for j, ln in enumerate(tl):
        d.text((122, 14 + j * 35), ln, font=tf, fill=WHITE)
    y = 20 + len(tl) * 35
    for j, ln in enumerate(wrap(body, bf, w - 150)[:2]):
        d.text((124, y + j * 29), ln, font=bf, fill=SOFT)
    return im


# ---------------------------------------------------------------- the shots

def build(shots: pathlib.Path):
    S = lambda n: shots / f"{n}.png"  # noqa: E731
    img = lambda n: Image.open(S(n)).convert("RGB")  # noqa: E731
    home_bg, scam_bg = sets.home(W, H), sets.scam_room(W, H)
    office_bg, shop_bg, hall_bg = sets.police_office(W, H), sets.shop(W, H), ms.bank_hall(W, H)
    atm_bg, branch_bg = sets.atm_booth(W, H), sets.branch(W, H)
    half_home, half_scam = sets.home(956, H), sets.scam_room(956, H)
    mapbg = map_base(shots)
    dark = gradient_bg((6, 12, 32), (14, 26, 62))
    nav = gradient_bg()
    play = [img(f"p2_play{i:02d}") for i in range(14)]
    ph = {}

    def P(n, h=700):
        if (n, h) not in ph:
            ph[(n, h)] = shadow_img(phone(S(n), h))
        return ph[(n, h)]

    br = {}

    def B(n, w=1300):
        if (n, w) not in br:
            br[(n, w)] = shadow_img(browser(S(n), w))
        return br[(n, w)]

    out = []

    def shot(lines, draw, bg):
        out.append((lines, draw, bg))

    def counter(f):
        d = ImageDraw.Draw(f)
        floor = int(H * 0.80)
        cy = int(floor - H * 0.22)
        d.rectangle((int(W * 0.30), cy, int(W * 0.98), floor), fill=(200, 160, 120), outline=(150, 110, 80), width=6)
        d.rectangle((int(W * 0.30), cy, int(W * 0.98), cy + 22), fill=(170, 130, 95))

    # ================= 1. Hook
    def hook1(f, c):
        drop = min(1, max(0, (c.t - 2.6) / 1.2))
        bal = 100000 - int(50000 * drop)
        txt = "₹1,00,000" if bal >= 100000 else f"₹{bal // 1000},{bal % 1000:03d}"
        flash = 1.0 if drop >= 1 and (c.t * 4) % 2 < 1 else (0.5 if drop > 0 else 0)
        p = kaveri_phone(txt, flash, "− ₹50,000" if drop >= 1 else None)
        p = p.resize((int(p.width * 0.8), int(p.height * 0.8)), Image.LANCZOS)
        pop(f, p, W / 2, 470, min(1, c.t / 0.5))
    shot([N("Sirf do minute. Ek phone call. Aur pachaas hazaar rupaye gayab.",
            "सिर्फ़ दो मिनट। एक फ़ोन कॉल। और पचास हज़ार रुपये ग़ायब।")], hook1, dark)

    def hook2(f, c):
        actor(f, "priya", W / 2, H + 760, 1500, c, expr="shocked" if c.t < 2.5 else "sad")
    shot([N("Yeh kahani Priya ki hai — aur kal yeh aapke kisi apne ki bhi ho sakti hai.",
            "यह कहानी प्रिया की है — और कल यह आपके किसी अपने की भी हो सकती है।")], hook2, home_bg)

    # ================= 2. The scam call
    def call(f, c):
        left, right = half_home.copy(), half_scam.copy()
        p_expr = ["neutral", "neutral", "worried", "worried", "worried", "sad", "sad"][c.i]
        k_expr = ["happy", "happy", "neutral", "happy", "happy", "sly", "sly"][c.i]
        actor(left, "priya", 430, 900, 620, c, expr=p_expr, pose="phone")
        actor(right, "pankaj", 330, 900, 640, c, expr=k_expr, pose="phone")
        f.alpha_composite(left, (0, 0))
        f.alpha_composite(right, (964, 0))
        ImageDraw.Draw(f).rectangle((956, 0, 964, H), fill=WHITE)
        paste(f, label("BENGALURU"), 30, 30)
        paste(f, label("JAMTARA"), 994, 30)
        if c.i >= 5:
            pop(f, kaveri_phone("₹50,000", 0, "− ₹50,000").resize((416, 784)), 700, 470, c.appear(5))
    shot([Line("pankaj", "Hello, Priya ji? Main Kaveri Bank ke KYC department se baat kar raha hoon.",
               "हैलो, प्रिया जी? मैं कावेरी बैंक के KYC department से बात कर रहा हूँ।"),
          Line("priya", "Haan ji, boliye?", "हाँ जी, बोलिए?"),
          Line("pankaj", "Aapka KYC expire ho chuka hai. Aaj update nahi hua, toh aapka account block ho jayega.",
               "आपका KYC expire हो चुका है। आज update नहीं हुआ, तो आपका account block हो जाएगा।"),
          Line("priya", "Arre! Toh ab main kya karoon?", "अरे! तो अब मैं क्या करूँ?"),
          Line("pankaj", "Ghabraiye mat. Bas pachaas hazaar ka ek verification payment kijiye. Kaam hote hi poori "
                         "raqam wapas aa jayegi.",
               "घबराइए मत। बस पचास हज़ार का एक verification payment कीजिए। काम होते ही पूरी रक़म वापस आ जाएगी।"),
          Line("priya", "Theek hai… bhej diya.", "ठीक है… भेज दिया।"),
          Line("pankaj", "Bahut shukriya, Priya ji.", "बहुत शुक्रिया, प्रिया जी।")], call, None)

    # ================= 3. The money runs
    def hops(f, c, done=False):
        span = (c.ends[min(2, len(c.ends) - 1)] - 0.6) if not done else 1
        for k, (a, b, amt, col) in enumerate(ms.HOPS):
            prog = 1.0 if done else max(0, min(1, (c.t - 0.4 - k * span / 7) / (span / 7 * 0.85)))
            if prog > 0:
                ms.draw_hop(f, a, b, prog, col, amt)
                if prog >= 1:
                    who = {"Deoghar": "pavan", "Ranchi": "pradeep"}.get(b, ms.MULES_AT[b])
                    x, y = ms.city_xy(b)
                    actor(f, who, x + 70, y + 40, 150, c, expr="sly" if who == "pankaj" else "neutral", bob=False)
        paste(f, label("Bengaluru → 7 mule accounts → 4 banks"), 40, 30)

    def money_map(f, c):
        hops(f, c)
    shot([N("Paisa milte hi Pankaj use turant aage bhej deta hai — ek account se doosre, doosre se teesre.",
            "पैसा मिलते ही पंकज उसे तुरंत आगे भेज देता है — एक account से दूसरे, दूसरे से तीसरे।"),
          N("Inhe kehte hain mule accounts — aise log jo kuch paison ke liye apna bank account dusron ko istemaal "
            "karne dete hain.",
            "इन्हें कहते हैं mule accounts — ऐसे लोग जो कुछ पैसों के लिए अपना bank account दूसरों को इस्तेमाल करने "
            "देते हैं।"),
          N("Kuch hi minuton mein paisa saat accounts aur chaar bankon mein bikhar jaata hai.",
            "कुछ ही मिनटों में पैसा सात accounts और चार bankों में बिखर जाता है।")], money_map, mapbg)

    def atm_cash(f, c):
        actor(f, "pavan", 620, 960, 680, c, expr="sly", pose="point")
        x0 = 1190 + 90
        y = int(H * 0.74) + 20 + int(60 * min(1, c.t / 1.5))
        d = ImageDraw.Draw(f)
        for k in range(5):
            d.rectangle((x0 + k * 8, y + k * 4, x0 + 160 + k * 8, y + 70 + k * 4), fill=(140, 200, 140),
                        outline=(60, 120, 60), width=3)
        pop(f, pill("₹5,000 cash withdrawn", RED, WHITE), 1500, 200, c.appear(0, 0.6))
    shot([N("Deoghar mein Pavan ATM se paanch hazaar nakad nikaal leta hai.",
            "देवघर में पवन ATM से पाँच हज़ार नक़द निकाल लेता है।")], atm_cash, atm_bg)

    def crypto(f, c):
        hops(f, c, done=True)
        prog = max(0, min(1, c.t / 1.6))
        ms.draw_hop(f, "Ranchi", "Hyderabad", prog, PURPLE, "₹10,000")
        if prog >= 1:
            x, y = ms.city_xy("Hyderabad")
            d = ImageDraw.Draw(f)
            d.ellipse((x - 34, y - 34, x + 34, y + 34), fill=PURPLE)
            d.text((x - 14, y - 26), "₿", font=font(40, "bold"), fill=WHITE)
            fly = max(0, min(1, (c.t - 1.8) / 2.0))
            if fly > 0:
                fx = x + (W - 120 - x) * fly
                d.ellipse((fx - 22, y - 22 - 200 * fly, fx + 22, y + 22 - 200 * fly), fill=(200, 160, 255))
    shot([N("Das hazaar crypto mein badle gaye, aur unka ek hissa desh se bahar bhej diya gaya.",
            "दस हज़ार crypto में बदले गए, और उनका एक हिस्सा देश से बाहर भेज दिया गया।")], crypto, mapbg)

    def shop_buy(f, c):
        walk = min(1, c.t / 1.6)
        actor(f, "mahesh", 1200, 900, 600, c, expr="happy", pose="wave" if c.i == 1 else "idle")
        counter(f)
        actor(f, "prem", 1900 - 1500 * (1 - (1 - walk) ** 2) if walk < 1 else 400, 960, 640, c,
              expr="sly" if c.i == 0 else "happy", pose="point" if c.i == 0 else "idle")
        paste(f, label("JAIPUR"), 30, 150)
    shot([Line("prem", "Bhaiya, woh naya phone dikhana. Das hazaar ka hai na? UPI se de deta hoon.",
               "भैया, वो नया फ़ोन दिखाना। दस हज़ार का है ना? UPI से दे देता हूँ।"),
          Line("mahesh", "Yeh lijiye sir. Payment aa gaya — dhanyavaad!",
               "ये लीजिए sir। Payment आ गया — धन्यवाद!")], shop_buy, shop_bg)

    # ================= 4. How it goes today
    def report_1930(f, c):
        pop(f, sms("Rs 50,000.00 debited from A/c XX5235 by UPI to PANKAJ MONDAL. Not you? Call 1930."), 1350, 260,
            min(1, c.t / 0.4))
        actor(f, "priya", 520, 930, 680, c, expr="sad", pose="phone")
    shot([Line("priya", "Hello, 1930? Mere saath fraud ho gaya hai… pachaas hazaar!",
               "हैलो, 1 9 3 0? मेरे साथ fraud हो गया है… पचास हज़ार!"),
          N("Priya turant shikayat karti hai. Lekin aaj ka tareeka bahut dheema hai.",
            "प्रिया तुरंत शिकायत करती है। लेकिन आज का तरीक़ा बहुत धीमा है।")], report_1930, home_bg)

    def manual(f, c):
        d = ImageDraw.Draw(f)
        d.rectangle((300, 760, 1100, 790), fill=(110, 80, 60))
        pile = int(6 + 30 * min(1, c.t / c.dur))
        for k in range(pile):
            d.rectangle((820 + (k % 3) * 4, 755 - k * 9, 1040 + (k % 3) * 4, 762 - k * 9), fill=(250, 250, 245),
                        outline=(180, 180, 180))
        actor(f, "meera", 560, 950, 640, c, expr="worried", pose="laptop")
        day = ["DAY 1", "DAY 3", "DAY 7", "DAY 15"][min(3, int(c.t / max(c.dur / 4, 0.1)))]
        pop(f, calendar(day.split()[1], day.split()[0]), 1550, 330, 1)
        for k in range(4):
            ft = (c.t * 0.6 + k * 0.25) % 1
            x, y = 1130 + 600 * ft, 600 - 260 * ft + k * 40
            d.rectangle((x, y, x + 70, y + 46), fill=WHITE, outline=(120, 120, 120), width=2)
            d.line((x, y, x + 35, y + 26, x + 70, y), fill=(120, 120, 120), width=2)
        if c.i >= 1:
            for k, name in enumerate(["Mule 1", "Mule 2", "ATM cash"]):
                pop(f, card(name, "₹0", "already gone", RED, 330), 1110 + 330 * k, 640, c.appear(1, 0.3 * k))
    shot([N("Shikayat ek ticket ban jaati hai. Phir har bank ko alag-alag letter jaata hai — yeh paisa kahan gaya?",
            "शिकायत एक ticket बन जाती है। फिर हर bank को अलग-अलग letter जाता है — यह पैसा कहाँ गया?"),
          N("Jab tak jawab aata hai, mule accounts khaali ho chuke hote hain. ATM se nikla cash toh hamesha ke liye "
            "gaya.",
            "जब तक जवाब आता है, mule accounts ख़ाली हो चुके होते हैं। ATM से निकला cash तो हमेशा के लिए गया।")],
         manual, office_bg)

    def frozen(f, c):
        expr = ["shocked", "angry", "sad", "sad"][min(c.i, 3)]
        actor(f, "mahesh", 520, 960, 680, c, expr=expr, pose="facepalm" if c.i >= 2 else "idle")
        counter(f)
        pop(f, card("Mahesh's shop account", "FROZEN", "₹10,000 for a phone he really sold", RED, 640), 1350, 420,
            c.appear(0, 0.6))
        if c.appear(0, 1.2) > 0:
            pop(f, stamp("ACCOUNT FROZEN"), 1350, 700, c.appear(0, 1.2))
    shot([N("Aur sabse bada nuksaan hota hai ek imaandaar dukaandaar ka.",
            "और सबसे बड़ा नुक़सान होता है एक ईमानदार दुकानदार का।"),
          Line("mahesh", "Maine toh phone imaandaari se becha tha! Mera poora account kyun band kar diya?",
               "मैंने तो फ़ोन ईमानदारी से बेचा था! मेरा पूरा account क्यों बंद कर दिया?"),
          N("Fraud ka paisa jis bhi account tak pahunchta hai, use aksar poora freeze kar diya jaata hai — dukaandaar "
            "ka bhi.",
            "Fraud का पैसा जिस भी account तक पहुँचता है, उसे अक्सर पूरा freeze कर दिया जाता है — दुकानदार का भी।"),
          N("Mahesh ka phone bhi gaya, aur uski kamaai bhi atak gayi.",
            "महेश का फ़ोन भी गया, और उसकी कमाई भी अटक गई।")], frozen, shop_bg)

    def waiting(f, c):
        actor(f, "priya", 600, 930, 680, c, expr="sad")
        months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN"]
        m = months[min(5, int(c.t / max(c.dur / 6, 0.1)))]
        pop(f, calendar("?", m), 1350, 380, 1)
        paste(f, label(L("Court order ka intezaar… mahinon tak")), 1110, 580)
        pop(f, pill(L("Mule → naya account, doosra bank"), RED, WHITE), 1380, 720, c.appear(0, 0.3))
    shot([N("Mule doosre bank mein naya account khol lete hain. Aur Priya? Court ke order ka mahinon intezaar.",
            "Mule दूसरे bank में नया account खोल लेते हैं। और प्रिया? Court के order का महीनों इंतज़ार।")],
         waiting, home_bg)

    # ================= 5. Enter RakshakPay
    def intro(f, c):
        pop(f, logo(260), W / 2, 380, min(1, c.t / 0.6))
        pop(f, text_img("RakshakPay", 120, "black", align="center"), W / 2, 620, min(1, (c.t - 0.4) / 0.5))
        pop(f, text_img(L("har rupaye ki raksha"), 46, "light", SOFT, align="center"), W / 2, 740,
            min(1, (c.t - 0.9) / 0.5))
    shot([N("Isi samasya ka hal hai — RakshakPay.", "इसी समस्या का हल है — रक्षक पे।")], intro, nav)

    eco = L_eco()

    def eco_draw(f, c):
        for k, e in enumerate(eco):
            paste(f, e.img, e.x, e.y, max(0, min(1, (c.t - (0 if k < 3 else (k - 3) * 0.35)) / 0.4)))
    shot([N("Paanch bank, UPI app, dukaan ka sound box, crypto exchange aur cyber police — sab ek hi system se jude "
            "hue.", "पाँच bank, UPI app, दुकान का sound box, crypto exchange और cyber police — सब एक ही system से "
                    "जुड़े हुए।"),
          N("Ab wahi kahani dobara dekhiye — is baar RakshakPay ke saath.",
            "अब वही कहानी दोबारा देखिए — इस बार रक्षक पे के साथ।")], eco_draw, nav)

    # ================= 6. With RakshakPay
    def complaint(f, c):
        actor(f, "priya", 380, 960, 640, c, expr="worried" if c.i == 0 else "relieved", pose="point")
        pop(f, P("b2_form_filled", 760), 980, 480, c.appear(0, 0.3))
        if c.i >= 1:
            pop(f, P("b2_filed", 760), 1500, 480, c.appear(1, 1.5))
        paste(f, label("Report fraud from the bank app"), 30, 30)
    shot([Line("priya", "Is payment ko main fraud report karti hoon.", "इस payment को मैं fraud report करती हूँ।"),
          N("Priya app mein hi woh payment chunti hai aur shikayat bhejti hai. Use turant ek acknowledgement number "
            "milta hai — jaanch ki baaki jaankari sirf police ke paas rehti hai.",
            "प्रिया app में ही वो payment चुनती है और शिकायत भेजती है। उसे तुरंत एक acknowledgement number मिलता है "
            "— जाँच की बाक़ी जानकारी सिर्फ़ police के पास रहती है।")], complaint, home_bg)

    def trace(f, c):
        if c.i == 0:
            scr = img("p2_dashboard")
        else:
            k = min(13, int(max(0, c.since(1)) / max(c.dur - c.starts[1], 0.1) * 14))
            scr = play[k]
        desk(f, scr)
        actor(f, "meera", 300, 980, 700, c, expr="neutral", pose="point")
    shot([Line("meera", "Shikayat aate hi system ne poora paisa trace kar liya — har account, har bank.",
               "शिकायत आते ही system ने पूरा पैसा trace कर लिया — हर account, हर bank।"),
          N("System fraud ke baad ka har transaction samay ke kram mein dobara chalata hai, aur Priya ke paise ka "
            "peecha karta hai.",
            "System fraud के बाद का हर transaction समय के क्रम में दोबारा चलाता है, और प्रिया के पैसे का पीछा करता "
            "है।")], trace, office_bg)

    def hold(f, c):
        desk(f, img("p2_summary"))
        actor(f, "meera", 300, 980, 700, c, expr="happy" if c.i == 0 else "neutral", pose="point")
        if c.i >= 1:
            pop(f, card("Held (lien)", "₹25,000", "only the victim's money", AMBER, 520), 1560, 600, c.appear(1, 0.5))
    shot([Line("meera", "Pachchees hazaar mule accounts mein hold, aur lagbhag paanch hazaar ka crypto exchange par "
                        "freeze.",
               "पच्चीस हज़ार mule accounts में hold, और लगभग पाँच हज़ार का crypto exchange पर freeze।"),
          N("Poora account band nahi hota — sirf utni raqam roki jaati hai jitni Priya ki us account tak pahunchi.",
            "पूरा account बंद नहीं होता — सिर्फ़ उतनी रक़म रोकी जाती है जितनी प्रिया की उस account तक पहुँची।")],
         hold, office_bg)

    def atm_map(f, c):
        zoom_pop(f, B("p2_map"), W / 2, 500, c)
        paste(f, pill("ATM withdrawal: Godavari Bank ATM, Deoghar"), 560, 40)
        if c.i >= 1:
            zoom_pop(f, B("p2_courts", 1100), W / 2 + 120, 560, c, t0=c.starts[1])
    shot([N("Jo paisa ATM se nikal chuka hai, uska bhi hisaab hai. Har ATM withdrawal ki jagah map par dikhti hai, aur "
            "zyada cash-out wale ilaake hotspot ban jaate hain.",
            "जो पैसा ATM से निकल चुका है, उसका भी हिसाब है। हर ATM withdrawal की जगह map पर दिखती है, और ज़्यादा "
            "cash-out वाले इलाक़े hotspot बन जाते हैं।"),
          N("Pavan ke nikaale paanch hazaar ke liye court application apne aap taiyaar hoti hai.",
            "पवन के निकाले पाँच हज़ार के लिए court application अपने आप तैयार होती है।")], atm_map, dark)

    def atm_blocked(f, c):
        actor(f, "pavan", 420, 960, 680, c, expr="angry" if c.i == 0 else "sad", pose="shrug" if c.i == 0 else "idle")
        pop(f, P("v_atm_blocked", 740), 1000, 470, min(1, c.t / 0.4))
        if c.i >= 1:
            pop(f, P("v_notices", 740), 1520, 470, c.appear(1, 0.3))
    shot([Line("pavan", "Yeh kya? Card hi nahi chal raha!", "ये क्या? Card ही नहीं चल रहा!"),
          N("Mule list mein aate hi Pavan ka ATM card, UPI aur transfer — sab band.",
            "Mule list में आते ही पवन का ATM card, UPI और transfer — सब बंद।")], atm_blocked, atm_bg)

    def upi_block(f, c):
        actor(f, "pradeep", 420, 960, 680, c, expr="sly" if c.i == 0 else "angry", pose="phone")
        pop(f, P("u_home", 740), 1000, 470, min(1, c.t / 0.4))
        pop(f, P("u_blocked", 740), 1520, 470, c.appear(0, 1.6))
        paste(f, label("RANCHI • RakshakPay UPI"), 30, 30)
    shot([Line("pradeep", "UPI se bhej deta hoon… arre, yeh bhi block!", "UPI से भेज देता हूँ… अरे, ये भी block!"),
          N("UPI app par bhi mule ko saaf sandesh milta hai — payment band, branch jaakar verification karaiye.",
            "UPI app पर भी mule को साफ़ संदेश मिलता है — payment बंद, branch जाकर verification कराइए।"),
          N("Haan, account mein aane wala paisa aata rahega, aur victim ka nuksaan bharega.",
            "हाँ, account में आने वाला पैसा आता रहेगा, और victim का नुक़सान भरेगा।")], upi_block, scam_bg)

    def ravi(f, c):
        expr = ["happy", "shocked", "relieved", "relieved"][c.i]
        actor(f, "ravi", 420, 960, 680, c, expr=expr, pose="phone" if c.i == 0 else "idle")
        if c.i >= 1:
            pop(f, P("b_mule_payee", 740), 1000, 470, c.appear(1, 0))
            pop(f, P("b_mule_dialog", 740), 1520, 470, c.appear(1, 1.0))
        paste(f, label("RAVI • an ordinary customer"), 30, 30)
    shot([Line("ravi", "Online ek purana phone dekha tha, saste mein mil raha hai. Bechne wale ko das hazaar bhej deta "
                       "hoon.",
               "Online एक पुराना फ़ोन देखा था, सस्ते में मिल रहा है। बेचने वाले को दस हज़ार भेज देता हूँ।"),
          Line("ravi", "Yeh account mule list mein hai? Nahi bhai, payment cancel!",
               "ये account mule list में है? नहीं भाई, payment cancel!"),
          N("RakshakPay har us vyakti ko pehle hi chetavni deta hai jo mule account mein paisa bhejne ja raha ho. Ravi "
            "ka paisa bach gaya.",
            "रक्षक पे हर उस व्यक्ति को पहले ही चेतावनी देता है जो mule account में पैसा भेजने जा रहा हो। रवि का पैसा "
            "बच गया।"),
          N("Pay anyway sirf us vyakti ke liye hai jo victim ka paisa lautana chahta hai — aisa paisa seedha victim "
            "ki recovery mein jaata hai.",
            "Pay anyway सिर्फ़ उस व्यक्ति के लिए है जो victim का पैसा लौटाना चाहता है — ऐसा पैसा सीधा victim की "
            "recovery में जाता है।")], ravi, home_bg)

    pan = illus_pan()

    def pan_block(f, c):
        actor(f, "pankaj", 420, 960, 680, c, expr="sly" if c.i == 0 else "angry", pose="idle")
        if c.i >= 1:
            for k, e in enumerate(pan):
                paste(f, e.img, e.x - 40, e.y - 60, c.appear(1, 0.4 * k))
    shot([Line("pankaj", "Koi baat nahi, naya account khol leta hoon…", "कोई बात नहीं, नया account खोल लेता हूँ…"),
          N("Ab yeh mumkin nahi. Uska PAN har bank aur crypto exchange mein blacklist ho chuka hai.",
            "अब यह मुमकिन नहीं। उसका PAN हर bank और crypto exchange में blacklist हो चुका है।")], pan_block, hall_bg)

    def safe(f, c):
        actor(f, "mahesh", 480, 960, 680, c, expr="relieved" if c.i == 0 else "happy",
              pose="cheer" if c.i == 0 else "idle")
        counter(f)
        pop(f, card("Mahesh's shop account", "ACTIVE", "keeps the ₹10,000 for the phone", GREEN, 640), 1350, 380,
            c.appear(0, 0.5))
        if c.i >= 2:
            pop(f, card("Prem's account (buyer)", "− ₹10,000", "recovery lien, court approved", RED, 640), 1350,
                720, c.appear(2, 0.5))
    shot([Line("mahesh", "Mera account bilkul theek chal raha hai!", "मेरा account बिल्कुल ठीक चल रहा है!"),
          N("Mahesh ne imaandaari se saamaan becha tha, isliye RakshakPay uske account ko haath bhi nahi lagata.",
            "महेश ने ईमानदारी से सामान बेचा था, इसलिए रक्षक पे उसके account को हाथ भी नहीं लगाता।"),
          N("Woh das hazaar Prem se wasool hote hain — jisne fraud ke paise se phone khareeda tha.",
            "वो दस हज़ार प्रेम से वसूल होते हैं — जिसने fraud के पैसे से फ़ोन ख़रीदा था।"),
          N("Court ki manzoori ke baad uske account par recovery lien lagta hai, chahe balance minus mein kyun na "
            "chala jaaye.",
            "Court की मंज़ूरी के बाद उसके account पर recovery lien लगता है, चाहे balance minus में क्यों न चला जाए।")],
         safe, shop_bg)

    def prem_neg(f, c):
        actor(f, "prem", 520, 960, 680, c, expr="shocked", pose="facepalm")
        pop(f, card("Prem's balance", "− ₹10,000", "every new rupee repays Priya first", RED, 640), 1320, 420,
            min(1, c.t / 0.4))
    shot([Line("prem", "Mera balance minus mein?!", "मेरा balance minus में?!")], prem_neg, nav)

    def court(f, c):
        desk(f, img("p_application"))
        actor(f, "meera", 300, 980, 700, c, expr="happy", pose="point")
    shot([Line("meera", "Court ke liye saari applications bhi system ne khud taiyaar kar di hain — account, raqam aur "
                        "transaction number ke saath.",
               "Court के लिए सारी applications भी system ने ख़ुद तैयार कर दी हैं — account, रक़म और transaction number "
               "के साथ।")], court, office_bg)

    def gps(f, c):
        actor(f, "priya", 520, 930, 680, c, expr="neutral", pose="point")
        pop(f, P("b_location_popup", 760), 1300, 480, min(1, c.t / 0.4))
    shot([N("Har payment ke saath phone ki location darj hoti hai. Location band? Toh payment bhi nahi.",
            "हर payment के साथ फ़ोन की location दर्ज होती है। Location बंद? तो payment भी नहीं।")], gps, home_bg)

    # ---- delisting
    def branch_talk(f, c):
        actor(f, "lakshmi", 1250, 900, 620, c, expr="neutral", pose="point" if c.i == 1 else "idle", facing=-1)
        sets.branch_desk(f)
        actor(f, "pavan", 520, 980, 700, c, expr="worried", pose="idle")
        paste(f, label("Pavan visits his home branch"), 30, 150)
    shot([Line("pavan", "Madam, mujhe ek part-time job ke naam par phasaaya gaya tha. Mujhe nahi pata tha yeh fraud ka "
                        "paisa hai.",
               "मैडम, मुझे एक part-time job के नाम पर फँसाया गया था। मुझे नहीं पता था यह fraud का पैसा है।"),
          Line("lakshmi", "Original PAN, Aadhaar aur photo dikhaiye. Aapke mobile par OTP bhi bhej rahi hoon.",
               "Original PAN, Aadhaar और photo दिखाइए। आपके mobile पर OTP भी भेज रही हूँ।")], branch_talk, branch_bg)

    def branch_screens(f, c):
        pop(f, P("o_verify4", 760), 560, 480, min(1, c.t / 0.4))
        pop(f, P("o_statement", 760), 1000, 480, c.appear(1, 0))
        pop(f, P("o_recommend2", 760), 1440, 480, c.appear(1, 1.2))
        paste(f, pill("Branch desk: re-KYC → statement → recommendation"), 520, 20)
    shot([N("Mule list se bahar aane ka ek hi raasta hai — apni home branch jaakar asli documents ke saath dobara KYC.",
            "Mule list से बाहर आने का एक ही रास्ता है — अपनी home branch जाकर असली documents के साथ दोबारा KYC।"),
          N("Bank officer customer ka bayaan likhta hai aur apni salaah police ko bhejta hai. Aakhri faisla cyber "
            "police ka hota hai.",
            "Bank officer customer का बयान लिखता है और अपनी सलाह police को भेजता है। आख़िरी फ़ैसला cyber police का "
            "होता है।")], branch_screens, dark)

    def decide(f, c):
        desk(f, img("p2_case"))
        actor(f, "meera", 300, 980, 700, c, expr="neutral", pose="point")
    shot([Line("meera", "Pavan ko dhokha diya gaya tha. Services wapas chalu — lekin recovery jaari rahegi.",
               "पवन को धोखा दिया गया था। Services वापस चालू — लेकिन recovery जारी रहेगी।")], decide, office_bg)

    outcomes = [("Begunaah (Innocent)", "Account hack / documents misused → fully off the mule list", GREEN),
                ("Dhokhe ka shikaar (Tricked)", "Services back, but the court recovery must be repaid", AMBER),
                ("Jaan-boojhkar shaamil (Involved)", "Blocked in every bank, police case continues", RED)]
    oc = []
    for title, body, col in outcomes:
        title, body = L(title), L(body)
        im = rounded((540, 260), 26, CARD + (255,), outline=col + (255,), width=4)
        d = ImageDraw.Draw(im)
        for j, ln in enumerate(wrap(title, font(36, "bold"), 490)):
            d.text((28, 24 + j * 44), ln, font=font(36, "bold"), fill=col)
        for j, ln in enumerate(wrap(body, font(28), 490)):
            d.text((28, 130 + j * 36), ln, font=font(28), fill=SOFT)
        oc.append(im)

    def outcome_draw(f, c):
        if c.i == 0:
            paste(f, text_img(L("Police ke teen faisle"), 60, "bold"), 120, 90)
            for k, im in enumerate(oc):
                pop(f, im, 120 + k * 580 + 270, 460, c.appear(0, 0.8 + k * 1.6))
        else:
            actor(f, "pavan", 420, 960, 680, c, expr="sad")
            pop(f, P("v_home_neg", 740), 1000, 470, min(1, c.since(1) / 0.4))
            pop(f, P("v_notices_after", 740), 1520, 470, c.appear(1, 1.0))
    shot([N("Teen faisle ho sakte hain. Begunaah — account hack hua ya documents ka galat istemaal hua: poori tarah "
            "list se bahar. Dhokhe ka shikaar — services wapas, lekin court wali recovery chukaani hogi. Aur "
            "jaan-boojhkar shaamil — account har bank mein band rehta hai, aur police case chalta hai.",
            "तीन फ़ैसले हो सकते हैं। बेगुनाह — account hack हुआ या documents का ग़लत इस्तेमाल हुआ: पूरी तरह list से "
            "बाहर। धोखे का शिकार — services वापस, लेकिन court वाली recovery चुकानी होगी। और जान-बूझकर शामिल — account "
            "हर bank में बंद रहता है, और police case चलता है।"),
          N("Pavan ka account phir se chalu hai — lekin paanch hazaar ki recovery baaki hai, isliye balance minus mein "
            "dikhta hai.",
            "पवन का account फिर से चालू है — लेकिन पाँच हज़ार की recovery बाक़ी है, इसलिए balance minus में दिखता "
            "है।")], outcome_draw, nav)

    def release(f, c):
        desk(f, img("p2_summary"))
        actor(f, "meera", 300, 980, 700, c, expr="happy", pose="point")
    shot([Line("meera", "Court ki manzoori mil gayi hai. Raqam release kar rahi hoon.",
               "Court की मंज़ूरी मिल गई है। रक़म release कर रही हूँ।")], release, office_bg)

    def back(f, c):
        actor(f, "priya", 460, 930, 680, c, expr="happy", pose="cheer" if c.i == 0 else "idle")
        pop(f, P("b2_home_after", 760), 1000, 480, min(1, c.t / 0.4))
        pop(f, P("b2_notices", 760), 1500, 480, c.appear(0, 0.8))
    shot([Line("priya", "Mera paisa wapas aa gaya!", "मेरा पैसा वापस आ गया!"),
          N("Lagbhag tees hazaar rupaye seedhe Priya ke account mein — aur baaki raqam recovery lien se wasool hoti "
            "rahegi.",
            "लगभग तीस हज़ार रुपये सीधे प्रिया के account में — और बाक़ी रक़म recovery lien से वसूल होती रहेगी।")],
         back, home_bg)

    # ================= 7. Stay safe
    safety = [("Bank kabhi phone par KYC nahi maangta", "No bank or police asks for KYC or money on a call", "\U0001F4DE", RED),
              ("OTP, UPI PIN, CVV — kisi ko nahi", "You never enter a PIN to receive money", "\U0001F512", AMBER),
              ("Account, card, SIM kiraye par nahi", "'Ghar baithe paisa ghumao' jobs make you a mule", "\U0001F6AB", RED),
              ("Payment se pehle warning padhiye", "Mule warning? Stop the payment", "⚠", AMBER),
              ("Fraud? Turant 1930", "or cybercrime.gov.in — the sooner, the more is saved", "⏱", GREEN),
              ("Location aur SMS alert ON", "Every payment needs your phone's location", "\U0001F4CD", (90, 160, 255)),
              ("Anjaan logon ka paisa nahi", "'I'll send you money, buy it for me' — recovery is from YOU",
               "\U0001F464", RED),
              ("Online paise ke badle cash nahi", "Never swap UPI money for hard cash with strangers", "\U0001F4B0",
               AMBER)]
    cards = [rule_card(k + 1, L(t), L(b), ic, col) for k, (t, b, ic, col) in enumerate(safety)]

    def safe_draw(f, c):
        paste(f, text_img(L("Aapki suraksha ke 8 niyam"), 56, "bold"), 120, 50)
        for k, im in enumerate(cards):
            pop(f, im, 120 + (k % 2) * 860 + 410, 225 + (k // 2) * 160, c.appear(k + 1))
    shot([N("Aur ab, aapki suraksha ke kuch zaroori niyam.", "और अब, आपकी सुरक्षा के कुछ ज़रूरी नियम।"),
          N("Ek. Koi bhi bank ya police phone par KYC update ya paise nahi maangti.",
            "एक। कोई भी bank या police फ़ोन पर KYC update या पैसे नहीं माँगती।"),
          N("Do. OTP, UPI PIN ya CVV kisi ko mat bataiye. Paisa lene ke liye kabhi PIN daalna nahi padta.",
            "दो। OTP, UPI PIN या CVV किसी को मत बताइए। पैसा लेने के लिए कभी PIN डालना नहीं पड़ता।"),
          N("Teen. Apna bank account, ATM card ya SIM kisi ko kiraye par mat dijiye. Ghar baithe paisa ghumao wali "
            "naukri, mule banne ka jaal hai.",
            "तीन। अपना bank account, ATM card या SIM किसी को किराए पर मत दीजिए। घर बैठे पैसा घुमाओ वाली नौकरी, mule "
            "बनने का जाल है।"),
          N("Chaar. Payment se pehle naam aur chetavni dhyaan se padhiye. Mule warning dikhe toh payment rok dijiye.",
            "चार। Payment से पहले नाम और चेतावनी ध्यान से पढ़िए। Mule warning दिखे तो payment रोक दीजिए।"),
          N("Paanch. Fraud ho jaaye toh turant 1930 par call kijiye ya cybercrime.gov.in par shikayat kijiye — jitni "
            "jaldi, utna zyada paisa bachta hai.",
            "पाँच। Fraud हो जाए तो तुरंत 1 9 3 0 पर call कीजिए या cyber crime dot gov dot in पर शिकायत कीजिए — जितनी "
            "जल्दी, उतना ज़्यादा पैसा बचता है।"),
          N("Chhe. Phone ki location aur bank ke SMS alert hamesha chalu rakhiye.",
            "छह। फ़ोन की location और bank के SMS alert हमेशा चालू रखिए।"),
          N("Saat. Anjaan logon se paisa mat lijiye. Koi kahe main aapke account mein paise bhejta hoon, aap mere liye "
            "kuch khareed do — woh fraud ka paisa hai, aur wasooli aapse hogi, fraudster se nahi.",
            "सात। अनजान लोगों से पैसा मत लीजिए। कोई कहे मैं आपके account में पैसे भेजता हूँ, आप मेरे लिए कुछ ख़रीद दो "
            "— वो fraud का पैसा है, और वसूली आपसे होगी, fraudster से नहीं।"),
          N("Aur aath. Anjaan logon ke saath online paise ko nakad cash mein kabhi mat badliye.",
            "और आठ। अनजान लोगों के साथ online पैसे को नक़द cash में कभी मत बदलिए।")], safe_draw, nav)

    # ================= 8. Nine rules
    rules = [("Turant trace", "\U0001F50D", SAFFRON), ("Sirf victim ka paisa hold", "\U0001F512", AMBER),
             ("Mule accounts par nishaan", "\U0001F6A9", RED), ("Bhejne wale ko chetavni", "⚠", AMBER),
             ("Dukaandaar surakshit", "\U0001F3EA", GREEN), ("PAN blacklist", "\U0001F6AB", RED),
             ("Court se recovery", "⚖", AMBER), ("Crypto freeze", "❄", PURPLE),
             ("Har payment par location", "\U0001F4CD", (90, 160, 255))]
    tiles = []
    for name, ic, col in rules:
        name = L(name)
        im = rounded((540, 150), 24, CARD + (255,), outline=col + (255,), width=3)
        im.alpha_composite(badge(ic, 96, col, NAVY), (24, 27))
        lines = wrap(name, font(36, "bold"), 380)
        for j, ln in enumerate(lines):
            ImageDraw.Draw(im).text((140, 30 + j * 44 + (22 if len(lines) == 1 else 0)), ln, font=font(36, "bold"),
                                    fill=WHITE)
        tiles.append(im)
    heading = text_img(L("RakshakPay ke nau niyam"), 64, "bold")

    def rules_draw(f, c):
        paste(f, heading, 120, 90)
        for k, im in enumerate(tiles):
            pop(f, im, 120 + (k % 3) * 580 + 270, 300 + (k // 3) * 190, min(1, max(0, (c.t - 2.2 - k * 1.05) / 0.4)))
    shot([N("RakshakPay ke nau niyam: turant trace. Sirf victim ka paisa hold. Mule accounts par nishaan. Bhejne wale "
            "ko chetavni. Dukaandaar surakshit. PAN blacklist. Court ki manzoori se recovery. Crypto freeze. Aur har "
            "payment par location.",
            "रक्षक पे के नौ नियम: तुरंत trace। सिर्फ़ victim का पैसा hold। Mule accounts पर निशान। भेजने वाले को "
            "चेतावनी। दुकानदार सुरक्षित। PAN blacklist। Court की मंज़ूरी से recovery। Crypto freeze। और हर payment पर "
            "location।")], rules_draw, nav)

    # ================= 9. Tech and next steps
    stack = L_stack()

    def tech(f, c):
        for k, e in enumerate(stack):
            paste(f, e.img, e.x, e.y, max(0, min(1, (c.t - (0 if k == 0 else 0.3 + k * 0.6)) / 0.4)))
    shot([N("Humne nau Android apps Flutter mein banaye, server Python aur FastAPI par, aur database PostgreSQL par. "
            "Har app English, Hindi aur Kannada mein chalta hai.",
            "हमने नौ Android apps Flutter में बनाए, server Python और Fast A P I पर, और database Postgres पर। हर app "
            "English, Hindi और Kannada में चलता है।"),
          N("Abhi yeh demo bankon par chalta hai. Asli duniya mein ise RBI, NPCI, bankon aur adalaton se jodna hoga.",
            "अभी यह demo bankों पर चलता है। असली दुनिया में इसे RBI, NPCI, bankों और अदालतों से जोड़ना होगा।"),
          N("Aage hum fake shikayaton ko pehchaanne aur mule hotspots ka anumaan lagane par kaam karenge.",
            "आगे हम fake शिकायतों को पहचानने और mule hotspots का अनुमान लगाने पर काम करेंगे।")], tech, nav)

    # ================= 10. Ending
    def ending(f, c):
        actor(f, "meera", 330, 1000, 600, c, expr="happy", pose="wave")
        actor(f, "ravi", 750, 1000, 580, c, expr="happy", pose="wave")
        actor(f, "priya", 1170, 1000, 600, c, expr="happy", pose="cheer")
        actor(f, "mahesh", 1590, 1000, 600, c, expr="happy", pose="wave")
        pop(f, logo(170), W / 2, 130, min(1, c.t / 0.5))
        pop(f, text_img(L("RakshakPay — har rupaye ki raksha"), 54, "black", (40, 30, 90), align="center"), W / 2, 260,
            min(1, (c.t - 0.3) / 0.5))
    shot([N("RakshakPay — har rupaye ki raksha.", "रक्षक पे — हर रुपये की रक्षा।")], ending, home_bg)
    return out


# ---------------------------------------------------------------- render

def main(shots_dir, work_dir, out, lang="hi"):
    global LANG
    LANG = lang
    shots, work = pathlib.Path(shots_dir), pathlib.Path(work_dir)
    work.mkdir(parents=True, exist_ok=True)
    plan = build(shots)
    if LANG == "en":
        from story_en import EN, VOICES_EN, spoken
        ms.VOICES.update(VOICES_EN)
        missing = [l.roman for lines, _, _ in plan for l in lines if l.roman not in EN]
        if missing:
            raise SystemExit("No English for: " + repr(missing))
        for lines, _, _ in plan:
            for l in lines:
                l.roman = EN[l.roman]
                l.deva = spoken(l.roman)
    preview = out.endswith("preview")

    audio, timeline = bytearray(), []
    for lines, draw, bg in plan:
        starts, ends, tracks, t = [], [], [], 0.0
        k = 0
        while k < len(lines):
            j = k
            while j + 1 < len(lines) and lines[j + 1].who == lines[k].who:
                j += 1
            group = lines[k:j + 1]
            pcm, offs = speak_group(group, work)
            gdur = len(pcm) / 2 / 48000
            for n, ln in enumerate(group):
                s0 = offs[n]
                s1 = offs[n + 1] if n + 1 < len(group) else gdur
                starts.append(t + s0)
                ends.append(t + s1)
                tracks.append(ms.mouth_track(pcm[int(s0 * 48000) * 2:int(s1 * 48000) * 2]))
            audio += pcm + b"\x00\x00" * int(48000 * GAP)
            t += gdur + GAP
            k = j + 1
        audio += b"\x00\x00" * int(48000 * SHOT_PAD)
        timeline.append((lines, draw, bg, starts, ends, tracks, t + SHOT_PAD))
    total = sum(x[-1] for x in timeline)
    print(f"total {total / 60:.1f} min, {len(timeline)} shots", flush=True)
    wav_path = work / "full.wav"
    with wave.open(str(wav_path), "wb") as w:
        w.setnchannels(1), w.setsampwidth(2), w.setframerate(48000)
        w.writeframes(bytes(audio))

    if preview:
        (work / "preview").mkdir(exist_ok=True)
        ff = None
    else:
        ff = subprocess.Popen([imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error", "-f", "rawvideo",
                               "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-i", str(wav_path),
                               "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p", "-c:a",
                               "aac", "-b:a", "160k", "-shortest", "-movflags", "+faststart", out],
                              stdin=subprocess.PIPE)
    caps, prev = {}, None
    for si, (lines, draw, bg, starts, ends, tracks, dur) in enumerate(timeline):
        n = round(dur * FPS)
        base = bg if bg is not None else Image.new("RGBA", (W, H), (0, 0, 0, 255))
        for fi in ([int(n * 0.75)] if preview else range(n)):
            t = fi / FPS
            idx = max([k for k, s in enumerate(starts) if s <= t] or [0])
            speaking = starts[idx] <= t < ends[idx]
            mouth = 0.0
            if speaking:
                tr = tracks[idx]
                j = int((t - starts[idx]) * FPS)
                mouth = float(tr[min(j, len(tr) - 1)]) if len(tr) else 0.0
            ctx = ms.Ctx(t, dur, starts, ends, idx, lines[idx].who if speaking else None, mouth)
            frame = base.copy()
            draw(frame, ctx)
            if t < ends[idx] + GAP:
                key = (lines[idx].who, lines[idx].roman)
                if key not in caps:
                    caps[key] = ms.caption(*key)
                cp = caps[key]
                frame.alpha_composite(cp, ((W - cp.width) // 2, H - cp.height - 30))
            rgb = frame.convert("RGB")
            if preview:
                rgb.resize((960, 540)).save(work / "preview" / f"{si:02d}.jpg", quality=85)
                continue
            if prev is not None and fi < 10:
                rgb = Image.blend(prev, rgb, (fi + 1) / 10)
            ff.stdin.write(rgb.tobytes())
            if fi == n - 1:
                prev = rgb
        print(f"shot {si + 1}/{len(timeline)}", flush=True)
    if ff:
        ff.stdin.close()
        ff.wait()
    print("saved", out)


if __name__ == "__main__":
    main(*sys.argv[1:5])
