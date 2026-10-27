"""RakshakPay story video: cartoon characters act out the fraud, then the same fraud with RakshakPay.

    python make_story.py <shots_dir> <work_dir> <out.mp4 | preview>

Language: Hinglish (captions in Roman letters, speech from Hindi neural voices). The script is in
`script_hinglish.md`; the lines below are the same text, with a Devanagari version for the voice.
"""

import asyncio
import hashlib
import math
import pathlib
import subprocess
import sys
import wave

import edge_tts
import imageio_ffmpeg
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

import characters as chars
import sets
from make_video import (AMBER, CARD, GREEN, NAVY, PURPLE, RED, SAFFRON, SOFT, WHITE, El, L_eco, L_stack, badge, browser,
                        font, gradient_bg, illus_pan, logo, phone, rounded, shadowed, text_img, wrap)

W, H, FPS = 1920, 1080, 30
LINE_GAP = 0.32
SHOT_PAD = 0.45

VOICES = {  # voice, rate, pitch
    "narrator": ("hi-IN-MadhurNeural", "+0%", "+0Hz"),
    "priya": ("hi-IN-SwaraNeural", "+5%", "+6Hz"),
    "pankaj": ("hi-IN-MadhurNeural", "+10%", "-12Hz"),
    "meera": ("hi-IN-SwaraNeural", "-5%", "-14Hz"),
    "mahesh": ("hi-IN-MadhurNeural", "-10%", "-4Hz"),
    "prem": ("hi-IN-MadhurNeural", "+8%", "+18Hz"),
}
NAMES = {"priya": "PRIYA", "pankaj": "PANKAJ", "meera": "INSPECTOR MEERA", "mahesh": "MAHESH", "prem": "PREM"}
PILL = {"priya": (232, 76, 120), "pankaj": (70, 76, 90), "meera": (13, 43, 94), "mahesh": (150, 110, 70),
        "prem": (40, 140, 100)}


class Line:
    def __init__(self, who, roman, deva):
        self.who, self.roman, self.deva = who, roman, deva


N = lambda r, d: Line("narrator", r, d)  # noqa: E731


# ---------------------------------------------------------------- helpers used by the shots

class Ctx:
    """What a shot's draw function needs to know about the current frame."""

    def __init__(self, t, dur, starts, ends, idx, who, mouth):
        self.t, self.dur, self.starts, self.ends, self.i, self.who, self._mouth = t, dur, starts, ends, idx, who, mouth

    def mouth(self, name):
        return self._mouth if self.who == name else 0.0

    def since(self, k):
        """Seconds since line k started (negative before)."""
        k = min(k, len(self.starts) - 1)
        return self.t - self.starts[k]

    def appear(self, k, delay=0.0, fade=0.4):
        """0..1 fade-in that starts with line k (+delay seconds)."""
        return max(0.0, min(1.0, (self.since(k) - delay) / fade))


_char_cache = {}


def actor(frame, name, x, ground, h, ctx, expr="neutral", pose="idle", facing=1, prop=None, bob=True):
    mouth = round(ctx.mouth(name) * 3) / 3
    phase = (hash(name) % 100) / 100 * 5
    blink = ((ctx.t + phase) % 3.7) < 0.13
    key = (name, expr, pose, mouth, blink, h, facing, prop)
    if key not in _char_cache:
        cw, chh = int(h * 0.9) + 60, int(h * 1.12)
        canvas = Image.new("RGBA", (cw, chh), (0, 0, 0, 0))
        chars.draw_character(canvas, name, cw / 2, h * 1.05, h, expression=expr, mouth=mouth, blink=blink, pose=pose,
                             facing=facing, prop=prop)
        if len(_char_cache) > 600:
            _char_cache.clear()
        _char_cache[key] = canvas
    canvas = _char_cache[key]
    dy = int(math.sin(ctx.t * 2.2 + phase) * 3) if bob else 0
    paste(frame, canvas, x - canvas.width / 2, ground - h * 1.05 + dy)


def paste(frame, img, x, y, a=1.0):
    if a <= 0:
        return
    if a < 1:
        img = img.copy()
        img.putalpha(img.getchannel("A").point(lambda v: int(v * a)))
    frame.alpha_composite(img, (int(x), int(y))) if x >= 0 and y >= 0 else frame.paste(img, (int(x), int(y)), img)


def pop(frame, img, cx, cy, a):
    """Pastes `img` centred on (cx, cy), scaling up slightly as it appears."""
    if a <= 0:
        return
    s = 0.85 + 0.15 * (1 - (1 - a) ** 3)
    im = img.resize((max(1, int(img.width * s)), max(1, int(img.height * s))), Image.BILINEAR) if s < 0.999 else img
    paste(frame, im, cx - im.width / 2, cy - im.height / 2, a)


def label(text, color=(0, 0, 0)):
    f = font(30, "bold")
    im = rounded((int(f.getlength(text)) + 44, 52), 26, color + (200,))
    ImageDraw.Draw(im).text((22, 6), text, font=f, fill=(255, 200, 60))
    return im


def card(title, value, sub, color, w=560):
    im = rounded((w, 250), 26, (255, 255, 255, 255), outline=color + (255,), width=6)
    d = ImageDraw.Draw(im)
    d.text((32, 24), title, font=font(30, "semi"), fill=(90, 90, 100))
    d.text((32, 70), value, font=font(70, "bold"), fill=color)
    d.text((32, 176), sub, font=font(28, "semi"), fill=(70, 70, 80))
    return shadowed(im)[0]


def stamp(text, color=RED, size=90, angle=10):
    f = font(size, "black")
    w = int(f.getlength(text)) + 60
    im = Image.new("RGBA", (w, size + 50), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((4, 4, w - 4, size + 46), 18, outline=color, width=10)
    d.text((30, 12), text, font=f, fill=color)
    return im.rotate(angle, expand=True, resample=Image.BICUBIC)


def phone_card(path, h=640):
    return shadowed(phone(path, h))[0]


def calendar(text, sub=""):
    im = rounded((300, 300), 24, (255, 255, 255, 255), outline=(60, 60, 60, 255), width=5)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, 299, 90), 24, fill=RED)
    d.rectangle((0, 50, 299, 90), fill=RED)
    d.text((150 - font(40, "bold").getlength(sub) / 2, 18), sub, font=font(40, "bold"), fill=WHITE)
    f = font(96, "black")
    d.text((150 - f.getlength(text) / 2, 110), text, font=f, fill=(40, 40, 40))
    return im


def kaveri_phone(balance_text, flash=0.0, debit=None):
    """A drawn phone showing Priya's balance (for the hook)."""
    im = rounded((520, 980), 60, (14, 14, 18, 255), outline=(70, 74, 90, 255), width=4)
    scr = rounded((480, 940), 46, (252, 246, 255, 255))
    d = ImageDraw.Draw(scr)
    d.rectangle((0, 0, 480, 120), fill=(103, 58, 160))
    d.text((40, 36), "Kaveri Bank", font=font(40, "bold"), fill=WHITE)
    d.rounded_rectangle((30, 160, 450, 420), 30, fill=(90, 50, 150))
    d.text((60, 190), "Available balance", font=font(30), fill=(220, 210, 240))
    bal_col = (255, int(255 - 155 * flash), int(255 - 155 * flash))
    d.text((60, 250), balance_text, font=font(72, "bold"), fill=bal_col)
    if debit:
        d.rounded_rectangle((30, 470, 450, 600), 24, fill=(255, 235, 235))
        d.text((54, 490), "UPI / DR / PANKAJ MONDAL", font=font(24, "semi"), fill=(80, 40, 40))
        d.text((54, 530), debit, font=font(46, "bold"), fill=RED)
    im.alpha_composite(scr, (20, 20))
    return shadowed(im)[0]


def sms(text):
    im = rounded((620, 170), 26, (255, 255, 255, 255), outline=(200, 200, 210, 255), width=3)
    d = ImageDraw.Draw(im)
    d.text((28, 18), "SMS • KAVERI BANK", font=font(24, "bold"), fill=(103, 58, 160))
    for i, l in enumerate(wrap(text, font(28), 570)):
        d.text((28, 58 + i * 36), l, font=font(28), fill=(40, 40, 40))
    return shadowed(im)[0]


def bank_hall(w, h):
    im = Image.new("RGBA", (w, h), (232, 226, 246, 255))
    d = ImageDraw.Draw(im)
    floor = int(h * 0.8)
    d.rectangle((0, floor, w, h), fill=(160, 150, 180))
    d.rectangle((0, 0, w, int(h * 0.13)), fill=(103, 58, 160))
    d.text((40, int(h * 0.02)), "KAVERI BANK  •  NEW ACCOUNT", font=font(int(h * 0.06), "bold"), fill=WHITE)
    d.rectangle((int(w * 0.45), int(floor - h * 0.24), w, floor), fill=(200, 190, 220), outline=(130, 110, 160),
                width=6)
    return im


def desk(frame, screen_img, a=1.0):
    """Meera's desk with a big monitor showing a real screen."""
    d = ImageDraw.Draw(frame)
    d.rectangle((520, 838, 1880, 866), fill=(110, 80, 60))
    d.rectangle((560, 866, 590, 1080), fill=(90, 64, 48))
    d.rectangle((1810, 866, 1840, 1080), fill=(90, 64, 48))
    d.rectangle((1180, 800, 1240, 838), fill=(50, 50, 56))
    mon = rounded((1120, 650), 22, (24, 24, 30, 255))
    if screen_img is not None:
        scr = screen_img.resize((1084, 610), Image.LANCZOS)
        mon.paste(scr, (18, 20))
    paste(frame, shadowed(mon)[0], 650 - 36, 160 - 36, a)


# ---------------------------------------------------------------- the map

CITIES = {"Bengaluru": (12.9716, 77.5946), "Jamtara": (23.9628, 86.8023), "Kolkata": (22.5726, 88.3639),
          "Bharatpur": (27.2152, 77.4930), "Deoghar": (24.4826, 86.6950), "Nuh": (28.1024, 77.0016),
          "Ranchi": (23.3441, 85.3096), "Jaipur": (26.9124, 75.7873), "Hyderabad": (17.3850, 78.4867)}


def _merc(lat):
    return math.log(math.tan(math.pi / 4 + math.radians(lat) / 2))


def city_xy(name, crop=(450, 155, 1450, 975), out=(1317, 1080), ox=301):
    """Pixel position of a city on the cropped and scaled police-map screenshot."""
    lat, lng = CITIES[name]
    # calibrated on the screenshot: Bengaluru label (790, 927), Kolkata label (1237, 488)
    a = (1237 - 790) / (88.3639 - 77.5946)
    c = (488 - 927) / (_merc(22.5726) - _merc(12.9716))
    x = 790 + (lng - 77.5946) * a
    y = 927 + (_merc(lat) - _merc(12.9716)) * c
    sx = out[0] / (crop[2] - crop[0])
    return ox + (x - crop[0]) * sx, (y - crop[1]) * sx


def map_base(shots):
    src = Image.open(shots / "p_play00.png").convert("RGB").crop((450, 155, 1450, 975))
    m = src.resize((1317, 1080), Image.LANCZOS).convert("RGBA")
    bg = Image.new("RGBA", (W, H), (14, 22, 44, 255))
    bg.alpha_composite(m, (301, 0))
    return bg


HOPS = [("Bengaluru", "Jamtara", "₹50,000", RED), ("Jamtara", "Kolkata", "₹25,000", RED),
        ("Jamtara", "Bharatpur", "₹25,000", RED), ("Kolkata", "Deoghar", "₹15,000", RED),
        ("Bharatpur", "Nuh", "₹15,000", RED), ("Deoghar", "Ranchi", "₹10,000", RED),
        ("Nuh", "Jaipur", "₹10,000", RED)]
MULES_AT = {"Jamtara": "pankaj", "Kolkata": "mule1", "Bharatpur": "mule3", "Deoghar": "mule2", "Nuh": "mule1",
            "Ranchi": "mule2", "Jaipur": "prem"}


def draw_hop(frame, a, b, prog, color, amount):
    (x1, y1), (x2, y2) = city_xy(a), city_xy(b)
    d = ImageDraw.Draw(frame)
    xe, ye = x1 + (x2 - x1) * prog, y1 + (y2 - y1) * prog
    d.line((x1, y1, xe, ye), fill=color, width=7)
    if 0 < prog < 1:
        d.ellipse((xe - 18, ye - 18, xe + 18, ye + 18), fill=(255, 205, 60), outline=(150, 100, 0), width=3)
        d.text((xe - 7, ye - 17), "₹", font=font(24, "bold"), fill=(120, 80, 0))
    if prog >= 1:
        mx, my = (x1 + x2) / 2, (y1 + y2) / 2
        f = font(22, "bold")
        w = f.getlength(amount)
        d.rounded_rectangle((mx - w / 2 - 10, my - 16, mx + w / 2 + 10, my + 16), 10, fill=WHITE, outline=color,
                            width=2)
        d.text((mx - w / 2, my - 14), amount, font=f, fill=color)


# ---------------------------------------------------------------- the shots

def build(shots: pathlib.Path):
    S = lambda n: shots / f"{n}.png"  # noqa: E731
    shot_img = lambda n: Image.open(S(n)).convert("RGB")  # noqa: E731
    home_bg, scam_bg = sets.home(W, H), sets.scam_room(W, H)
    office_bg, shop_bg, hall_bg = sets.police_office(W, H), sets.shop(W, H), bank_hall(W, H)
    half_home, half_scam = sets.home(956, H), sets.scam_room(956, H)
    mapbg = map_base(shots)
    dark = gradient_bg((6, 12, 32), (14, 26, 62))
    play = [shot_img(f"p_play{i:02d}") for i in range(12)]
    screens = {n: shot_img(n) for n in ("p_dashboard", "p_summary", "p_application", "p_summary_after")}
    phones = {n: phone_card(S(n), 700) for n in ("b_home", "b_complaints", "b_mule_payee", "b_mule_dialog",
                                                 "b_location_popup", "b_notices")}

    def shop_counter(frame):
        d = ImageDraw.Draw(frame)
        floor = int(H * 0.80)
        cy = int(floor - H * 0.22)
        d.rectangle((int(W * 0.30), cy, int(W * 0.98), floor), fill=(200, 160, 120), outline=(150, 110, 80), width=6)
        d.rectangle((int(W * 0.30), cy, int(W * 0.98), cy + 22), fill=(170, 130, 95))

    shots_list = []

    def shot(lines, draw, bg=None):
        shots_list.append((lines, draw, bg))

    # ---- 1. Hook
    def hook1(f, c):
        x = c.t / max(c.dur, 0.1)
        drop = min(1, max(0, (c.t - 2.6) / 1.2))
        bal = 100000 - int(50000 * drop)
        txt = "₹" + f"{bal:,}".replace(",", ",")
        if bal >= 100000:
            txt = "₹1,00,000"
        elif bal >= 10000:
            txt = f"₹{bal // 1000},{bal % 1000:03d}"
        flash = 1.0 if drop >= 1 and (c.t * 4) % 2 < 1 else (0.5 if drop > 0 else 0)
        ph = kaveri_phone(txt, flash, "− ₹50,000" if drop >= 1 else None)
        ph = ph.resize((int(ph.width * 0.8), int(ph.height * 0.8)), Image.LANCZOS)
        pop(f, ph, W / 2, 470, min(1, c.t / 0.5))
        _ = x
    shot([N("Sirf do minute. Ek phone call. Aur pachaas hazaar rupaye gayab.",
            "सिर्फ़ दो मिनट। एक फ़ोन कॉल। और पचास हज़ार रुपये ग़ायब।")], hook1, dark)

    def hook2(f, c):
        actor(f, "priya", W / 2, H + 760, 1500, c, expr="shocked" if c.t < 2.5 else "sad")
    shot([N("Yeh kahani Priya ki hai — aur kal yeh aapke kisi apne ki bhi ho sakti hai.",
            "यह कहानी प्रिया की है — और कल यह आपके किसी अपने की भी हो सकती है।")], hook2, home_bg)

    # ---- 2. The scam call (split screen)
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
        if c.i >= 5:  # she pays: her real bank app shows the debit
            pop(f, phones["b_home"], 700, 430, c.appear(5))
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
          Line("pankaj", "Bahut shukriya, Priya ji.", "बहुत शुक्रिया, प्रिया जी।")], call)

    # ---- 3. The money runs (map)
    def money_map(f, c):
        total_hops = len(HOPS)
        span = c.ends[2] - 0.6  # hops spread over the first three lines
        for k, (a, b, amt, col) in enumerate(HOPS):
            t0 = 0.4 + k * span / total_hops
            prog = max(0, min(1, (c.t - t0) / (span / total_hops * 0.85)))
            if prog > 0:
                draw_hop(f, a, b, prog, col, amt)
                if prog >= 1:
                    who = MULES_AT[b]
                    x, y = city_xy(b)
                    actor(f, who, x + 70, y + 40, 150, c, expr="sly" if who == "pankaj" else "neutral", bob=False)
        if c.i >= 3:  # crypto line: Ranchi -> exchange, then off the screen
            prog = max(0, min(1, c.since(3) / 1.6))
            draw_hop(f, "Ranchi", "Hyderabad", prog, PURPLE, "₹10,000")
            if prog >= 1:
                x, y = city_xy("Hyderabad")
                d = ImageDraw.Draw(f)
                d.ellipse((x - 34, y - 34, x + 34, y + 34), fill=PURPLE)
                d.text((x - 14, y - 26), "₿", font=font(40, "bold"), fill=WHITE)
                fly = max(0, min(1, (c.since(3) - 1.8) / 2.0))
                if fly > 0:
                    fx = x + (W - 120 - x) * fly
                    d.ellipse((fx - 22, y - 22 - 200 * fly, fx + 22, y + 22 - 200 * fly), fill=(200, 160, 255))
        paste(f, label("Bengaluru → 7 mule accounts → 4 banks"), 40, 30)
    shot([N("Paisa milte hi Pankaj use turant aage bhej deta hai — ek account se doosre, doosre se teesre.",
            "पैसा मिलते ही पंकज उसे तुरंत आगे भेज देता है — एक account से दूसरे, दूसरे से तीसरे।"),
          N("Inhe kehte hain mule accounts — aise log jo kuch paison ke liye apna bank account dusron ko istemaal "
            "karne dete hain.",
            "इन्हें कहते हैं mule accounts — ऐसे लोग जो कुछ पैसों के लिए अपना bank account दूसरों को इस्तेमाल करने "
            "देते हैं।"),
          N("Kuch hi minuton mein paisa saat accounts aur chaar bankon mein bikhar jaata hai.",
            "कुछ ही मिनटों में पैसा सात accounts और चार bankों में बिखर जाता है।"),
          N("Das hazaar crypto mein badle gaye, aur unka ek hissa desh se bahar bhej diya gaya.",
            "दस हज़ार crypto में बदले गए, और उनका एक हिस्सा देश से बाहर भेज दिया गया।")], money_map, mapbg)

    # ---- 3b. The phone shop
    def shop_buy(f, c):
        walk = min(1, c.t / 1.6)
        actor(f, "mahesh", 1200, 900, 600, c, expr="happy", pose="wave" if c.i == 1 else "idle")
        shop_counter(f)
        actor(f, "prem", 1900 - 1500 * (1 - (1 - walk) ** 2) if walk < 1 else 400, 960, 640, c,
              expr="sly" if c.i == 0 else "happy", pose="point" if c.i == 0 else "idle")
        paste(f, label("JAIPUR"), 30, 150)
    shot([Line("prem", "Bhaiya, woh naya phone dikhana. Das hazaar ka hai na? UPI se de deta hoon.",
               "भैया, वो नया फ़ोन दिखाना। दस हज़ार का है ना? UPI से दे देता हूँ।"),
          Line("mahesh", "Yeh lijiye sir. Payment aa gaya — dhanyavaad!",
               "ये लीजिए sir। Payment आ गया — धन्यवाद!")], shop_buy, shop_bg)

    # ---- 4. How it goes today
    def report_1930(f, c):
        pop(f, sms("Rs 50,000.00 debited from A/c XX8896 by UPI to PANKAJ MONDAL. Not you? Call 1930."), 1350, 260,
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
        for k, bank in enumerate(["Ganga", "Narmada", "Kaveri", "Godavari"]):
            ft = (c.t * 0.6 + k * 0.25) % 1
            x = 1130 + 600 * ft
            y = 600 - 260 * ft + k * 40
            d.rectangle((x, y, x + 70, y + 46), fill=WHITE, outline=(120, 120, 120), width=2)
            d.line((x, y, x + 35, y + 26, x + 70, y), fill=(120, 120, 120), width=2)
        if c.i >= 1:
            for k, name in enumerate(["Mule 1", "Mule 2", "Mule 3"]):
                pop(f, card(name, "₹0", "already withdrawn", RED, 330), 1110 + 330 * k, 640, c.appear(1, 0.3 * k))
    shot([N("Shikayat ek ticket ban jaati hai. Phir har bank ko alag-alag letter jaata hai — yeh paisa kahan gaya?",
            "शिकायत एक ticket बन जाती है। फिर हर bank को अलग-अलग letter जाता है — यह पैसा कहाँ गया?"),
          N("Jab tak jawab aata hai, mule accounts khaali ho chuke hote hain.",
            "जब तक जवाब आता है, mule accounts ख़ाली हो चुके होते हैं।")], manual, office_bg)

    def frozen(f, c):
        expr = ["shocked", "angry", "sad", "sad", "sad"][c.i]
        actor(f, "mahesh", 520, 960, 680, c, expr=expr, pose="facepalm" if c.i >= 2 else "idle")
        shop_counter(f)
        pop(f, card("Mahesh's shop account", "FROZEN", "₹10,000 for a phone he really sold", RED, 640), 1350, 420,
            c.appear(0, 0.6))
        if c.appear(0, 1.2) > 0:
            pop(f, stamp("ACCOUNT FROZEN"), 1350, 700, c.appear(0, 1.2))
    shot([N("Aur is poori kahani mein sabse bada nuksaan hota hai ek imaandaar dukaandaar ka.",
            "और इस पूरी कहानी में सबसे बड़ा नुक़सान होता है एक ईमानदार दुकानदार का।"),
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
        pop(f, calendar("?", m), 1350, 420, 1)
        paste(f, label("Court order ka intezaar… mahinon tak"), 1110, 620)
    shot([N("Aur Priya? Use apna paisa wapas paane ke liye court ke order ka mahinon intezaar karna padta hai.",
            "और प्रिया? उसे अपना पैसा वापस पाने के लिए court के order का महीनों इंतज़ार करना पड़ता है।")],
         waiting, home_bg)

    # ---- 5. Enter RakshakPay
    def intro(f, c):
        a = min(1, c.t / 0.6)
        lg = logo(260)
        pop(f, lg, W / 2, 380, a)
        t = text_img("RakshakPay", 120, "black", align="center")
        pop(f, t, W / 2, 620, min(1, (c.t - 0.4) / 0.5))
        s = text_img("har rupaye ki raksha", 46, "light", SOFT, align="center")
        pop(f, s, W / 2, 740, min(1, (c.t - 0.9) / 0.5))
    shot([N("Isi samasya ka hal hai — RakshakPay.", "इसी समस्या का हल है — रक्षक पे।")], intro, gradient_bg())

    eco = L_eco()

    def eco_draw(f, c):
        for k, e in enumerate(eco):
            delay = 0 if k < 3 else (k - 3) * 0.35
            paste(f, e.img, e.x, e.y, max(0, min(1, (c.t - delay) / 0.4)))
    shot([N("Paanch bank, UPI app, dukaan ka sound box, crypto exchange aur cyber police — sab ek hi system se jude "
            "hue.", "पाँच bank, UPI app, दुकान का sound box, crypto exchange और cyber police — सब एक ही system से "
                    "जुड़े हुए।"),
          N("Ab wahi kahani dobara dekhiye — is baar RakshakPay ke saath.",
            "अब वही कहानी दोबारा देखिए — इस बार रक्षक पे के साथ।")], eco_draw, gradient_bg())

    # ---- 6. The same fraud, with RakshakPay
    def complaint(f, c):
        actor(f, "priya", 520, 930, 680, c, expr="worried" if c.i == 0 else "relieved", pose="point")
        pop(f, phones["b_complaints"], 1300, 470, c.appear(0, 0.8))
        paste(f, label("RakshakPay: complaint from the bank app"), 30, 30)
    shot([Line("priya", "Is payment ko main fraud report karti hoon.", "इस payment को मैं fraud report करती हूँ।"),
          N("Shikayat darj hote hi Priya ko ek acknowledgement number milta hai. Jaanch ki baaki jaankari sirf police "
            "ke paas rehti hai.",
            "शिकायत दर्ज होते ही प्रिया को एक acknowledgement number मिलता है। जाँच की बाक़ी जानकारी सिर्फ़ police "
            "के पास रहती है।")], complaint, home_bg)

    def trace(f, c):
        if c.i == 0:
            scr = screens["p_dashboard"]
        else:
            k = min(11, int(max(0, c.since(1)) / max(c.dur - c.starts[1], 0.1) * 12))
            scr = play[k]
        desk(f, scr)
        actor(f, "meera", 300, 980, 700, c, expr="neutral", pose="point")
    shot([Line("meera", "Shikayat aate hi system ne poora paisa trace kar liya hai — har account, har bank.",
               "शिकायत आते ही system ने पूरा पैसा trace कर लिया है — हर account, हर bank।"),
          N("System fraud ke baad ka har transaction samay ke kram mein dobara chalata hai, aur Priya ke paise ka "
            "peecha karta hai.",
            "System fraud के बाद का हर transaction समय के क्रम में दोबारा चलाता है, और प्रिया के पैसे का पीछा करता "
            "है।")], trace, office_bg)

    def hold(f, c):
        desk(f, screens["p_summary"])
        actor(f, "meera", 300, 980, 700, c, expr="happy" if c.i == 0 else "neutral", pose="point")
        if c.i >= 1:
            pop(f, card("Held (lien)", "₹30,000", "only the victim's money", AMBER, 520), 1560, 600, c.appear(1, 0.5))
    shot([Line("meera", "Tees hazaar mule accounts mein hold ho gaye, aur paanch hazaar ka crypto exchange par freeze.",
               "तीस हज़ार mule accounts में hold हो गए, और पाँच हज़ार का crypto exchange पर freeze।"),
          N("Dhyaan dijiye — poora account band nahi hota. Sirf utni raqam roki jaati hai jitni Priya ki us account "
            "tak pahunchi.",
            "ध्यान दीजिए — पूरा account बंद नहीं होता। सिर्फ़ उतनी रक़म रोकी जाती है जितनी प्रिया की उस account "
            "तक पहुँची।")], hold, office_bg)

    def blocked(f, c):
        actor(f, "pankaj", 520, 930, 680, c, expr="angry", pose="phone")
        pop(f, card("Pankaj's account", "BLOCKED", "on the mule list • branch verification", RED, 620), 1320, 420,
            c.appear(0, 0.8))
    shot([Line("pankaj", "Yeh kya? Mera account toh chal hi nahi raha!", "ये क्या? मेरा account तो चल ही नहीं रहा!"),
          N("Saare mule accounts mule list mein aa jaate hain. Jab tak branch jaakar verification na ho, unse paisa "
            "nahi nikal sakta.",
            "सारे mule accounts mule list में आ जाते हैं। जब तक branch जाकर verification न हो, उनसे पैसा नहीं निकल "
            "सकता।")], blocked, scam_bg)

    def warn(f, c):
        pop(f, phones["b_mule_payee"], 700, 500, min(1, c.t / 0.4))
        pop(f, phones["b_mule_dialog"], 1220, 500, min(1, (c.t - 1.2) / 0.4))
        paste(f, label("Anyone paying a mule sees this first"), 30, 30)
    shot([N("Aur koi in accounts mein paisa bhejne lage, toh use pehle hi chetavni mil jaati hai.",
            "और कोई इन accounts में पैसा भेजने लगे, तो उसे पहले ही चेतावनी मिल जाती है।")], warn, dark)

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
        actor(f, "mahesh", 480, 960, 680, c, expr="relieved" if c.i == 0 else "happy", pose="cheer" if c.i == 0 else "idle")
        shop_counter(f)
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
            "Court की मंज़ूरी के बाद उसके account पर recovery lien लगता है, चाहे balance minus में क्यों न चला जाए।")], safe, shop_bg)

    def prem_neg(f, c):
        actor(f, "prem", 520, 960, 680, c, expr="shocked", pose="facepalm" if c.i == 1 else "idle")
        pop(f, card("Prem's balance", "− ₹10,000", "every new rupee repays Priya first", RED, 640), 1320, 420,
            min(1, c.t / 0.4))
    shot([Line("prem", "Mera balance minus mein?!", "मेरा balance minus में?!"),
          N("Ab Prem ke account mein jo bhi paisa aayega, sabse pehle Priya ka nuksaan bharega.",
            "अब प्रेम के account में जो भी पैसा आएगा, सबसे पहले प्रिया का नुक़सान भरेगा।")], prem_neg, gradient_bg())

    def court(f, c):
        desk(f, screens["p_application"])
        actor(f, "meera", 300, 980, 700, c, expr="happy", pose="point")
    shot([Line("meera", "Court ke liye application bhi system ne khud taiyaar kar di hai — saare account, raqam aur "
                        "transaction number ke saath.",
               "Court के लिए application भी system ने ख़ुद तैयार कर दी है — सारे account, रक़म और transaction number "
               "के साथ।")], court, office_bg)

    def gps(f, c):
        actor(f, "priya", 520, 930, 680, c, expr="neutral", pose="point")
        pop(f, phones["b_location_popup"], 1300, 470, min(1, c.t / 0.4))
    shot([N("Har payment ke saath phone ki location bhi darj hoti hai. Location band? Toh payment bhi nahi.",
            "हर payment के साथ फ़ोन की location भी दर्ज होती है। Location बंद? तो payment भी नहीं।")], gps, home_bg)

    def release(f, c):
        desk(f, screens["p_summary_after"])
        actor(f, "meera", 300, 980, 700, c, expr="happy", pose="point")
    shot([Line("meera", "Court ki manzoori mil gayi hai. Raqam release kar rahi hoon.",
               "Court की मंज़ूरी मिल गई है। रक़म release कर रही हूँ।")], release, office_bg)

    def back(f, c):
        actor(f, "priya", 520, 930, 680, c, expr="happy", pose="cheer" if c.i == 0 else "idle")
        pop(f, phones["b_notices"], 1300, 470, min(1, c.t / 0.4))
    shot([Line("priya", "Mera paisa wapas aa gaya!", "मेरा पैसा वापस आ गया!"),
          N("Lagbhag paintees hazaar rupaye seedhe Priya ke account mein — aur baaki raqam recovery lien se wasool "
            "hoti rahegi.",
            "लगभग पैंतीस हज़ार रुपये सीधे प्रिया के account में — और बाक़ी रक़म recovery lien से वसूल होती रहेगी।")],
         back, home_bg)

    # ---- 7. The nine rules
    rules = [("Turant trace", "\U0001F50D", SAFFRON), ("Sirf victim ka paisa hold", "\U0001F512", AMBER),
             ("Mule accounts par nishaan", "\U0001F6A9", RED), ("Bhejne wale ko chetavni", "⚠", AMBER),
             ("Dukaandaar surakshit", "\U0001F3EA", GREEN), ("PAN blacklist", "\U0001F6AB", RED),
             ("Court se recovery", "⚖", AMBER), ("Crypto freeze", "❄", PURPLE),
             ("Har payment par location", "\U0001F4CD", (90, 160, 255))]
    tiles = []
    for name, ic, col in rules:
        im = rounded((540, 150), 24, CARD + (255,), outline=col + (255,), width=3)
        im.alpha_composite(badge(ic, 96, col, NAVY), (24, 27))
        for j, ln in enumerate(wrap(name, font(36, "bold"), 380)):
            ImageDraw.Draw(im).text((140, 30 + j * 44 + (22 if len(wrap(name, font(36, "bold"), 380)) == 1 else 0)),
                                    ln, font=font(36, "bold"), fill=WHITE)
        tiles.append(im)
    heading = text_img("RakshakPay ke nau niyam", 64, "bold")

    def rules_draw(f, c):
        paste(f, heading, 120, 90)
        for k, im in enumerate(tiles):
            pop(f, im, 120 + (k % 3) * 580 + 270, 300 + (k // 3) * 190, c.appear(k + 1))
    shot([N("RakshakPay ke nau niyam.", "रक्षक पे के नौ नियम।")]
         + [N(r, d) for r, d in [
             ("Turant trace.", "तुरंत trace।"), ("Sirf victim ka paisa hold.", "सिर्फ़ victim का पैसा hold।"),
             ("Mule accounts par nishaan.", "Mule accounts पर निशान।"),
             ("Paisa bhejne wale ko chetavni.", "पैसा भेजने वाले को चेतावनी।"),
             ("Dukaandaar surakshit.", "दुकानदार सुरक्षित।"), ("PAN blacklist.", "PAN blacklist।"),
             ("Court ki manzoori se recovery.", "Court की मंज़ूरी से recovery।"), ("Crypto freeze.", "Crypto freeze।"),
             ("Aur har payment par location.", "और हर payment पर location।")]], rules_draw, gradient_bg())

    # ---- 8. Tech and next steps
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
            "आगे हम fake शिकायतों को पहचानने और mule hotspots का अनुमान लगाने पर काम करेंगे।")], tech, gradient_bg())

    # ---- 9. Ending
    def ending(f, c):
        actor(f, "meera", 420, 1000, 620, c, expr="happy", pose="wave")
        actor(f, "priya", 960, 1000, 600, c, expr="happy", pose="cheer")
        actor(f, "mahesh", 1500, 1000, 620, c, expr="happy", pose="wave")
        pop(f, logo(170), W / 2, 130, min(1, c.t / 0.5))
        t = text_img("RakshakPay — har rupaye ki raksha", 54, "black", (40, 30, 90), align="center")
        pop(f, t, W / 2, 260, min(1, (c.t - 0.3) / 0.5))
    shot([N("RakshakPay — har rupaye ki raksha.", "रक्षक पे — हर रुपये की रक्षा।")], ending, home_bg)

    return shots_list


# ---------------------------------------------------------------- audio

async def _tts(text, voice, rate, pitch, path):
    c = edge_tts.Communicate(text, voice, rate=rate, pitch=pitch)
    with open(path, "wb") as f:
        async for ch in c.stream():
            if ch["type"] == "audio":
                f.write(ch["data"])


def speak(line, work):
    voice, rate, pitch = VOICES[line.who]
    key = hashlib.sha1(f"{voice}{rate}{pitch}{line.deva}".encode()).hexdigest()[:16]
    wav = work / f"{key}.wav"
    if not wav.exists():
        mp3 = work / f"{key}.mp3"
        asyncio.run(_tts(line.deva, voice, rate, pitch, mp3))
        subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error", "-i", str(mp3), "-ar", "48000",
                        "-ac", "1", str(wav)], check=True)
    with wave.open(str(wav)) as w:
        pcm = w.readframes(w.getnframes())
    return pcm


def mouth_track(pcm):
    """Mouth opening (0..1) for each video frame, from the loudness of the voice."""
    a = np.frombuffer(pcm, dtype=np.int16).astype(np.float32)
    step = 48000 // FPS
    n = max(1, len(a) // step)
    rms = np.array([np.sqrt(np.mean(a[i * step:(i + 1) * step] ** 2)) for i in range(n)])
    ref = np.percentile(rms, 90) or 1
    m = np.clip(rms / ref * 1.1, 0, 1)
    m[m < 0.15] = 0
    return m


# ---------------------------------------------------------------- captions

def caption(who, text):
    f = font(42, "bold")
    lines = wrap(text, f, 1500)
    lh = 54
    box_h = len(lines) * lh + 28
    width = int(max(f.getlength(l) for l in lines)) + 70
    im = Image.new("RGBA", (max(width, 300), box_h + 50), (0, 0, 0, 0))
    box = rounded((width, box_h), 22, (0, 0, 0, 175))
    im.alpha_composite(box, ((im.width - width) // 2, 50))
    d = ImageDraw.Draw(im)
    for i, l in enumerate(lines):
        d.text(((im.width - f.getlength(l)) / 2, 62 + i * lh), l, font=f, fill=WHITE)
    if who != "narrator":
        nf = font(28, "bold")
        nm = NAMES[who]
        pw = int(nf.getlength(nm)) + 40
        pill = rounded((pw, 44), 22, PILL[who] + (255,))
        ImageDraw.Draw(pill).text((20, 4), nm, font=nf, fill=WHITE)
        im.alpha_composite(pill, ((im.width - pw) // 2, 0))
    return im


# ---------------------------------------------------------------- render

def main(shots_dir, work_dir, out):
    shots, work = pathlib.Path(shots_dir), pathlib.Path(work_dir)
    work.mkdir(parents=True, exist_ok=True)
    plan = build(shots)
    preview = out.endswith("preview")

    audio, timeline = bytearray(), []
    for lines, draw, bg in plan:
        starts, ends, tracks, t = [], [], [], 0.0
        for ln in lines:
            pcm = speak(ln, work)
            dur = len(pcm) / 2 / 48000
            starts.append(t)
            ends.append(t + dur)
            tracks.append(mouth_track(pcm))
            audio += pcm + b"\x00\x00" * int(48000 * LINE_GAP)
            t += dur + LINE_GAP
        audio += b"\x00\x00" * int(48000 * SHOT_PAD)
        timeline.append((lines, draw, bg, starts, ends, tracks, t + SHOT_PAD))
    total = sum(x[-1] for x in timeline)
    print(f"total {total / 60:.1f} min, {len(timeline)} shots", flush=True)
    wav_path = work / "story.wav"
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
    caps = {}
    prev = None
    for si, (lines, draw, bg, starts, ends, tracks, dur) in enumerate(timeline):
        n = round(dur * FPS)
        base = bg if bg is not None else Image.new("RGBA", (W, H), (0, 0, 0, 255))
        frames = [int(n * 0.7)] if preview else range(n)
        for fi in frames:
            t = fi / FPS
            idx = max([k for k, s in enumerate(starts) if s <= t] or [0])
            speaking = starts[idx] <= t < ends[idx]
            mouth = 0.0
            if speaking:
                tr = tracks[idx]
                j = int((t - starts[idx]) * FPS)
                mouth = float(tr[min(j, len(tr) - 1)])
            ctx = Ctx(t, dur, starts, ends, idx, lines[idx].who if speaking else None, mouth)
            frame = base.copy()
            draw(frame, ctx)
            if t < ends[idx] + LINE_GAP:
                key = (lines[idx].who, lines[idx].roman)
                if key not in caps:
                    caps[key] = caption(*key)
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
    main(*sys.argv[1:4])
