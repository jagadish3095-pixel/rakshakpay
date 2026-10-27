"""Builds the RakshakPay documentary video (about 5 minutes, 1920x1080, English narration).

    python make_video.py <shots_dir> <work_dir> <out.mp4>

<shots_dir> holds the app screenshots taken with capture.py (see SHOTS below).
Narration: Microsoft neural voice via edge-tts (needs internet). Video: Pillow frames piped
into ffmpeg (imageio-ffmpeg). Every sentence is spoken separately, so the subtitles and the
on-screen animations start exactly when their sentence starts.
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
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H, FPS = 1920, 1080, 30
VOICE = "en-IN-PrabhatNeural"
GAP = 0.12  # silence after each sentence (s)
BEAT_PAD = 0.45  # extra silence at the end of each beat (s)
FADE = 0.45

# Colours
NAVY, NAVY2 = (9, 20, 52), (21, 40, 96)
CARD = (27, 45, 102)
SAFFRON = (255, 143, 31)
WHITE = (255, 255, 255)
SOFT = (196, 206, 235)
RED = (235, 77, 75)
GREEN = (52, 199, 120)
PURPLE = (176, 120, 255)
AMBER = (255, 190, 60)

FONTS = r"C:\Windows\Fonts"


def font(size, weight="regular"):
    name = {"regular": "segoeui.ttf", "semi": "seguisb.ttf", "bold": "segoeuib.ttf", "light": "segoeuil.ttf",
            "black": "seguibl.ttf", "sym": "seguisym.ttf"}[weight]
    return ImageFont.truetype(f"{FONTS}\\{name}", size)


# ---------------------------------------------------------------- drawing helpers

def wrap(text, f, max_w):
    lines = []
    for para in text.split("\n"):
        words, line = para.split(), ""
        for w_ in words:
            test = (line + " " + w_).strip()
            if f.getlength(test) <= max_w or not line:
                line = test
            else:
                lines.append(line)
                line = w_
        lines.append(line)
    return lines


def text_img(text, size, weight="regular", color=WHITE, max_w=1600, align="left", spacing=1.25):
    f = font(size, weight)
    lines = wrap(text, f, max_w)
    lh = int(size * spacing)
    width = int(max(f.getlength(l) for l in lines)) + 4
    im = Image.new("RGBA", (width, lh * len(lines) + int(size * 0.35)), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for i, l in enumerate(lines):
        x = (width - f.getlength(l)) / 2 if align == "center" else 0
        d.text((x, i * lh), l, font=f, fill=color)
    return im


def rounded(size, radius, fill, outline=None, width=0):
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(im).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius, fill=fill, outline=outline,
                                         width=width)
    return im


def shadowed(im, blur=18, offset=10, alpha=140):
    pad = blur * 2
    out = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2), (0, 0, 0, 0))
    sh = Image.new("RGBA", im.size, (0, 0, 0, alpha))
    sh.putalpha(im.getchannel("A").point(lambda v: v * alpha // 255))
    out.alpha_composite(sh, (pad, pad + offset))
    out = out.filter(ImageFilter.GaussianBlur(blur))
    out.alpha_composite(im, (pad, pad))
    return out, pad


def round_corners(im, r):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.width - 1, im.height - 1), r, fill=255)
    out = im.convert("RGBA")
    out.putalpha(mask)
    return out


def browser(path, width=1400, url="rakshakpay.onrender.com/police"):
    shot = Image.open(path).convert("RGB")
    shot = shot.resize((width, round(shot.height * width / shot.width)), Image.LANCZOS)
    bar = 40
    im = Image.new("RGBA", (width, shot.height + bar), (236, 238, 244, 255))
    d = ImageDraw.Draw(im)
    for i, c in enumerate([(255, 95, 87), (255, 189, 46), (39, 201, 63)]):
        d.ellipse((18 + i * 24, 13, 32 + i * 24, 27), fill=c)
    d.rounded_rectangle((110, 8, width - 110, 32), 12, fill=WHITE)
    d.text((126, 9), url, font=font(17), fill=(90, 96, 110))
    im.paste(shot, (0, bar))
    return round_corners(im, 14)


def phone(path, height=760):
    shot = Image.open(path).convert("RGB")
    sw = round(shot.width * (height - 28) / shot.height)
    shot = round_corners(shot.resize((sw, height - 28), Image.LANCZOS), 34)
    im = rounded((sw + 28, height), 48, (14, 14, 18, 255), outline=(70, 74, 90, 255), width=3)
    im.alpha_composite(shot, (14, 14))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((im.width // 2 - 40, 20, im.width // 2 + 40, 30), 5, fill=(14, 14, 18))
    return im


def icon(char, size, color=WHITE):
    f = font(size, "sym") if char != "₹" else font(size, "bold")
    bbox = f.getbbox(char)
    im = Image.new("RGBA", (bbox[2] + 8, bbox[3] + 8), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((4, 4), char, font=f, fill=color)
    return im.crop(im.getbbox())


def badge(char, d=96, bg=SAFFRON, fg=NAVY):
    im = Image.new("RGBA", (d, d), (0, 0, 0, 0))
    ImageDraw.Draw(im).ellipse((0, 0, d - 1, d - 1), fill=bg)
    ic = icon(char, int(d * 0.5), fg)
    im.alpha_composite(ic, ((d - ic.width) // 2, (d - ic.height) // 2))
    return im


def logo(size=220):
    """The RakshakPay shield with a rupee sign."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    s = size
    pts = [(s * .5, s * .04), (s * .9, s * .18), (s * .86, s * .58), (s * .5, s * .96), (s * .14, s * .58), (s * .1, s * .18)]
    d.polygon(pts, fill=WHITE)
    inner = [(x * .82 + s * .09, y * .82 + s * .09) for x, y in pts]
    d.polygon(inner, fill=(59, 42, 140))
    f = font(int(s * .45), "bold")
    w = f.getlength("₹")
    d.text(((s - w) / 2, s * .16), "₹", font=f, fill=SAFFRON)
    return im


def gradient_bg(top=NAVY, bottom=NAVY2):
    bg = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(bg)
    for y in range(H):
        t = y / H
        d.line([(0, y), (W, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    # soft saffron glow, top right
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((W - 700, -500, W + 300, 400), fill=(255, 143, 31, 38))
    glow = glow.filter(ImageFilter.GaussianBlur(120))
    out = bg.convert("RGBA")
    out.alpha_composite(glow)
    return out


# ---------------------------------------------------------------- elements and layouts

class El:
    """Something on screen that fades and slides in when sentence `at` starts (or at `t` seconds)."""

    def __init__(self, img, x, y, at=0, t=None, slide=28, zoom=0.0, seq=None):
        self.img, self.x, self.y, self.at, self.t, self.slide, self.zoom, self.seq = img, x, y, at, t, slide, zoom, seq


def center_x(img):
    return (W - img.width) // 2


def place_shadowed(img, x, y, **kw):
    s, pad = shadowed(img)
    return El(s, x - pad, y - pad, **kw)


def L_title(title, sub, small=None):
    els = [El(logo(230), center_x(logo(230)), 190, slide=0)]
    t = text_img(title, 120, "black", align="center")
    els.append(El(t, center_x(t), 450))
    s = text_img(sub, 46, "light", SOFT, max_w=1400, align="center")
    els.append(El(s, center_x(s), 610, at=min(1, 0)))
    if small:
        sm = text_img(small, 30, "semi", SAFFRON, align="center")
        els.append(El(sm, center_x(sm), 760, at=0, t=1.2))
    return els


def L_heading(text, sub=None, y=110):
    els = [El(text_img(text, 64, "bold"), 120, y, slide=0)]
    if sub:
        els.append(El(text_img(sub, 34, "regular", SOFT, max_w=1600), 124, y + 92, slide=0))
    return els


def chip(text, ic, color):
    f = font(40, "semi")
    w = int(f.getlength(text)) + 150
    im = rounded((w, 96), 48, CARD + (255,), outline=color + (255,), width=3)
    b = badge(ic, 64, color, NAVY)
    im.alpha_composite(b, (18, 16))
    ImageDraw.Draw(im).text((100, 20), text, font=f, fill=WHITE)
    return im


def L_chips(heading, items, first_at=1, sub=None):
    els = L_heading(heading, sub)
    x, y = 120, 330
    for i, (txt, ic, col) in enumerate(items):
        c = chip(txt, ic, col)
        if x + c.width > W - 120:
            x, y = 120, y + 130
        els.append(El(c, x, y, at=first_at + i))
        x += c.width + 30
    return els


def row_card(num, title, body, color=SAFFRON, w=1680, ic=None):
    im = rounded((w, 128), 22, CARD + (255,))
    d = ImageDraw.Draw(im)
    if ic:
        im.alpha_composite(badge(ic, 84, color, NAVY), (24, 22))
    else:
        d.ellipse((24, 22, 108, 106), fill=color)
        f = font(44, "bold")
        d.text((66 - f.getlength(str(num)) / 2, 30), str(num), font=f, fill=NAVY)
    d.text((136, 16), title, font=font(40, "bold"), fill=WHITE)
    d.text((138, 70), body, font=font(29), fill=SOFT)
    return im


def L_rows(heading, rows, first_at=1, sub=None, y0=300, gap=146):
    els = L_heading(heading, sub)
    for i, (title, body, ic, col) in enumerate(rows):
        els.append(El(row_card(i + 1, title, body, col, ic=ic), 120, y0 + i * gap, at=first_at + i))
    return els


def L_grid(heading, items, first_at=1, cols=2, y0=270, gap=176):
    els = L_heading(heading)
    w = (W - 240 - 60 * (cols - 1)) // cols
    for i, (title, body, ic, col) in enumerate(items):
        els.append(El(row_card(i + 1, title, body, col, w=w, ic=ic), 120 + (i % cols) * (w + 60),
                      y0 + (i // cols) * gap, at=first_at + i))
    return els


def flow_box(title, sub, ic, color):
    im = rounded((420, 300), 26, CARD + (255,), outline=color + (255,), width=3)
    b = badge(ic, 110, color, NAVY)
    im.alpha_composite(b, ((420 - 110) // 2, 34))
    for i, (t, f, c) in enumerate([(title, font(38, "bold"), WHITE), (sub, font(27), SOFT)]):
        for j, line in enumerate(wrap(t, f, 380)):
            ImageDraw.Draw(im).text(((420 - f.getlength(line)) / 2, 166 + i * 52 + j * 34), line, font=f, fill=c)
    return im


def arrow(length=90, color=SAFFRON):
    im = Image.new("RGBA", (length, 60), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.line((4, 30, length - 26, 30), fill=color, width=8)
    d.polygon([(length - 30, 12), (length - 2, 30), (length - 30, 48)], fill=color)
    return im


def L_flow(heading, boxes, ats, sub=None, y=380):
    els = L_heading(heading, sub)
    total = len(boxes) * 420 + (len(boxes) - 1) * 110
    x = (W - total) // 2
    for i, ((t, s, ic, col), at) in enumerate(zip(boxes, ats)):
        if i:
            els.append(El(arrow(), x - 100, y + 120, at=at, slide=0))
        els.append(El(flow_box(t, s, ic, col), x, y, at=at))
        x += 530
    return els


def node(label, sub, color, w=300):
    im = rounded((w, 104), 20, CARD + (255,), outline=color + (255,), width=3)
    d = ImageDraw.Draw(im)
    f, g = font(32, "bold"), font(24)
    d.text(((w - f.getlength(label)) / 2, 12), label, font=f, fill=WHITE)
    d.text(((w - g.getlength(sub)) / 2, 58), sub, font=g, fill=color)
    return im


def L_tree():
    """Victim -> mule layers -> ATM / shop / crypto, appearing sentence by sentence."""
    els = L_heading("How the money disappears")
    canvas = Image.new("RGBA", (W, 640), (0, 0, 0, 0))
    lines = ImageDraw.Draw(canvas)
    cols = [140, 560, 980, 1440]
    pos = {"V": (cols[0], 270), "M1": (cols[1], 270), "M2": (cols[2], 120), "M3": (cols[2], 420),
           "ATM": (cols[3], 20), "SHOP": (cols[3], 250), "CRYPTO": (cols[3], 480)}
    links = [("V", "M1"), ("M1", "M2"), ("M1", "M3"), ("M2", "ATM"), ("M2", "SHOP"), ("M3", "CRYPTO")]
    for a, b in links:
        (x1, y1), (x2, y2) = pos[a], pos[b]
        lines.line((x1 + 300, y1 + 52, x2, y2 + 52), fill=RED + (255,), width=5)
    els.append(El(canvas, 0, 320, at=1, slide=0))
    nodes = {"V": ("Victim", "₹50,000", (90, 160, 255)), "M1": ("Mule 1", "Bank A", RED),
             "M2": ("Mule 2", "Bank B", RED), "M3": ("Mule 3", "Bank C", RED),
             "ATM": ("ATM", "cash withdrawn", (200, 200, 200)), "SHOP": ("Shop", "goods bought", GREEN),
             "CRYPTO": ("Crypto", "sent abroad", PURPLE)}
    for k, (label, sub, col) in nodes.items():
        at = 0 if k == "V" else 1
        els.append(El(node(label, sub, col), pos[k][0], 320 + pos[k][1], at=at))
    return els


def L_browser(path, at=0, zoom=0.03, width=1300, y=132, caption=None):
    b = browser(path, width)
    els = [place_shadowed(b, center_x(b), y, at=at, zoom=zoom)]
    if caption:
        els.append(caption_el(caption, at))
    return els


def caption_el(text, at=0, x=None, y=60):
    t = text_img(text, 30, "semi", NAVY)
    c = rounded((t.width + 44, t.height + 14), 26, SAFFRON + (255,))
    c.alpha_composite(t, (22, 6))
    return El(c, x if x is not None else center_x(c), y, at=at, slide=10)


def L_phones(paths, ats, height=780, captions=None, y=95):
    imgs = [phone(p, height) for p in paths]
    gap = 260 if captions else 90
    total = sum(i.width for i in imgs) + gap * (len(imgs) - 1)
    x = (W - total) // 2
    els = []
    for i, (im, at) in enumerate(zip(imgs, ats)):
        els.append(place_shadowed(im, x, y, at=at))
        if captions and captions[i]:
            c = caption_el(captions[i], at, y=y - 62)
            c.x = x + (im.width - c.img.width) // 2
            els.append(c)
        x += im.width + gap
    return els


def L_browser_phone(bpath, ppath, b_at=0, p_at=1, caption=None):
    b = browser(bpath, 1180)
    p = phone(ppath, 760)
    els = [place_shadowed(b, 90, 160, at=b_at, zoom=0.02), place_shadowed(p, W - p.width - 110, 100, at=p_at)]
    if caption:
        els.append(caption_el(caption, b_at))
    return els


def L_sequence(paths, width=1300, y=110):
    frames = [browser(p, width) for p in paths]
    s, pad = shadowed(frames[0])
    return [El(s, center_x(frames[0]) - pad, y - pad, seq=(frames, pad))]


def L_rule(n, title, body, ic, color=SAFFRON, illus=None):
    els = [El(text_img(f"RULE {n}", 34, "bold", color), 120, 140, slide=0)]
    els.append(El(badge(ic, 150, color, NAVY), 120, 210))
    els.append(El(text_img(title, 60, "black", max_w=760 if illus else 1600), 120, 390))
    els.append(El(text_img(body, 36, "regular", SOFT, max_w=760 if illus else 1500), 124, 560))
    if illus is not None:
        els += illus
    return els


def illus_phone(path, height=800):
    p = phone(path, height)
    return [place_shadowed(p, 1300, 70, at=0)]


def illus_browser(path, width=880):
    b = browser(path, width)
    return [place_shadowed(b, 960, 220, at=0, zoom=0.03)]


def illus_hold():
    im = rounded((820, 420), 26, CARD + (255,))
    d = ImageDraw.Draw(im)
    d.text((40, 30), "Mule account balance", font=font(34, "semi"), fill=SOFT)
    d.text((40, 80), "₹25,000", font=font(72, "bold"), fill=WHITE)
    d.rounded_rectangle((40, 210, 780, 270), 30, fill=(60, 80, 140))
    d.rounded_rectangle((40, 210, 40 + 740 * 0.4, 270), 30, fill=AMBER)
    d.text((40, 290), "■ ₹10,000 held: the victim's money", font=font(30, "semi"), fill=AMBER)
    d.text((40, 340), "■ ₹15,000 untouched: the holder's own money", font=font(30), fill=SOFT)
    return [place_shadowed(im, 980, 300, at=0)]


def illus_merchant():
    a = node("Shop", "keeps its money", GREEN, 380)
    b = node("Buyer (last mule)", "recovery lien", RED, 380)
    return [place_shadowed(a, 1080, 320, at=0), place_shadowed(b, 1080, 520, at=0, t=0.8)]


def illus_pan():
    im = rounded((760, 440), 26, (238, 232, 214, 255))
    d = ImageDraw.Draw(im)
    d.text((40, 30), "INCOME TAX DEPARTMENT", font=font(30, "bold"), fill=(60, 60, 60))
    d.text((40, 90), "Permanent Account Number", font=font(28), fill=(80, 80, 80))
    d.text((40, 140), "PNKPM1001B", font=font(64, "bold"), fill=(30, 30, 30))
    d.text((40, 240), "PANKAJ MONDAL", font=font(36, "semi"), fill=(30, 30, 30))
    stamp = Image.new("RGBA", (700, 140), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stamp)
    sd.rounded_rectangle((4, 4, 696, 136), 16, outline=RED, width=10)
    f = font(80, "black")
    sd.text(((700 - f.getlength("BLACKLISTED")) / 2, 12), "BLACKLISTED", font=f, fill=RED)
    stamp = stamp.rotate(12, expand=True, resample=Image.BICUBIC)
    els = [place_shadowed(im, 1000, 260, at=0)]
    els.append(El(stamp, 1020, 470, at=0, t=0.9, slide=0))
    banks = text_img("All 5 banks  •  CoinVault exchange", 32, "semi", SAFFRON)
    els.append(El(banks, 1010, 760, at=0, t=1.4))
    return els


def illus_crypto():
    im = rounded((760, 380), 26, CARD + (255,), outline=PURPLE + (255,), width=3)
    d = ImageDraw.Draw(im)
    d.text((40, 30), "CoinVault wallet", font=font(34, "semi"), fill=SOFT)
    d.text((40, 90), "0.00058 BTC", font=font(64, "bold"), fill=WHITE)
    d.text((40, 190), "Frozen: bought with a victim's money", font=font(30, "semi"), fill=PURPLE)
    d.text((40, 250), "Released only after the court's", font=font(30), fill=SOFT)
    d.text((40, 295), "seizure order", font=font(30), fill=SOFT)
    return [place_shadowed(im, 1000, 330, at=0)]


def L_eco():
    els = L_heading("One connected system", "Every app talks to one RakshakPay server")
    cx, cy = W // 2, 575
    server = node("RakshakPay server", "trace • hold • court • refund", SAFFRON, 440)
    ring = [("5 Banks", "Sahyadri, Ganga, Kaveri…", (90, 160, 255)), ("RakshakPay", "UPI payments", (120, 140, 255)),
            ("Business", "shop sound box", GREEN), ("CoinVault", "crypto exchange", PURPLE),
            ("Cyber Police", "phone • tab • web", RED), ("Bank branches", "verification desk", AMBER)]
    lines = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lines)
    pts = []
    for i in range(len(ring)):
        a = -math.pi / 2 + i * 2 * math.pi / len(ring)
        pts.append((cx + int(640 * math.cos(a)), cy + int(255 * math.sin(a))))
    for x, y in pts:
        ld.line((cx, cy, x, y), fill=(255, 143, 31, 150), width=4)
    els.append(El(lines, 0, 0, at=1, slide=0))
    els.append(El(server, cx - 220, cy - 52, at=0))
    for (label, sub, col), (x, y) in zip(ring, pts):
        els.append(El(node(label, sub, col, 330), x - 165, y - 52, at=0, t=0.6 + 0.35 * len(els)))
    return els


def L_stack():
    els = L_heading("How we built it")
    tiles = [("Flutter + Dart", "9 Android apps + police web", (90, 160, 255)),
             ("Python + FastAPI", "the server and fraud engine", AMBER),
             ("PostgreSQL on Neon", "the database", (120, 200, 255)),
             ("Render", "cloud hosting, auto deploy", PURPLE),
             ("WebSockets", "live updates", GREEN),
             ("OpenStreetMap", "money-trail maps", (120, 220, 160)),
             ("English • Hindi • Kannada", "every screen, with night mode", SAFFRON),
             ("GitHub + pytest", "version control and tests", SOFT)]
    for i, (t, s, c) in enumerate(tiles):
        im = rounded((800, 130), 22, CARD + (255,), outline=c + (255,), width=3)
        d = ImageDraw.Draw(im)
        d.text((36, 14), t, font=font(42, "bold"), fill=WHITE)
        d.text((38, 74), s, font=font(28), fill=c)
        els.append(El(im, 120 + (i % 2) * 880, 290 + (i // 2) * 160, at=0, t=0.4 + i * 0.9))
    return els


# ---------------------------------------------------------------- the story

def beats(shots: pathlib.Path):
    S = lambda n: str(shots / f"{n}.png")  # noqa: E731
    play = [S(f"p_play{i:02d}") for i in range(12)]
    return [
        # scene, label, sentences, layout
        ("title", "", ["RakshakPay.", "A system that follows stolen money, and stops it, in seconds."],
         L_title("RakshakPay", "A system that follows stolen money, and stops it, in seconds.",
                 "Smart India Hackathon • Cyber fraud money trail")),

        ("problem", "THE PROBLEM",
         ["Every day, people in India lose money to cyber fraud.", "Fake KYC calls.", "Fake jobs.",
          "Investment scams.", "Courier scams."],
         L_chips("Cyber fraud, every day", [("Fake KYC calls", "\U0001F4DE", RED), ("Fake job offers", "\U0001F4C4", AMBER),
                                            ("Investment scams", "\U0001F4B0", PURPLE),
                                            ("Courier scams", "\U0001F4F1", (90, 160, 255))])),
        ("problem", "THE PROBLEM",
         ["The victim calls 1930, or complains on the national cybercrime portal.",
          "And a race against time begins."],
         L_flow("Reporting the fraud", [("Call 1930", "national helpline", "\U0001F4DE", SAFFRON),
                                        ("cybercrime.gov.in", "online complaint", "\U0001F5A5", SAFFRON),
                                        ("Race against time", "money keeps moving", "\u23F1", RED)], [0, 0, 1])),

        ("today", "HOW IT WORKS TODAY",
         ["Today, much of this is manual.", "A complaint becomes a ticket.",
          "Officers write to banks one by one to find where the money went."],
         L_flow("Today: manual and slow", [("Complaint", "victim reports", "\U0001F464", SOFT),
                                           ("Ticket", "raised by hand", "\U0001F4C4", SOFT),
                                           ("Letters to banks", "one bank at a time", "\U0001F3E6", AMBER)], [0, 1, 2])),
        ("today", "HOW IT WORKS TODAY",
         ["But the fraudster moves faster.",
          "Within minutes, the money is split across mule accounts in different banks, withdrawn at ATMs, spent "
          "at shops, or turned into crypto."],
         L_tree()),
        ("today", "HOW IT WORKS TODAY",
         ["By the time a hold reaches the right account, it is often empty.",
          "And returning money to the victim needs a court order, which can take months."],
         L_flow("Too late, too slow", [("Hold arrives", "account already ₹0", "\U0001F512", RED),
                                       ("Court order", "applied for by hand", "\u2696", AMBER),
                                       ("Refund", "after months", "\u23F1", RED)], [0, 1, 1])),

        ("problems", "WHAT GOES WRONG",
         ["Six problems keep repeating.", "Fraud moves in minutes, but investigation takes days.",
          "No single bank sees the whole chain.", "Innocent shopkeepers get their whole account frozen.",
          "Crypto takes the money out of the banking system.", "Refunds wait for a slow court process.",
          "And mules simply open new accounts in other banks."],
         L_grid("Six problems", [
             ("Too slow", "Fraud moves in minutes, investigation takes days", "\u23F1", RED),
             ("No full picture", "Money is split across many banks", "\U0001F3E6", AMBER),
             ("Innocent shops frozen", "Whole merchant accounts get blocked", "\U0001F3EA", GREEN),
             ("Crypto exit", "Money leaves the banking system", "\u2744", PURPLE),
             ("Slow refunds", "Manual court process", "\u2696", AMBER),
             ("Mules come back", "New accounts in other banks", "\U0001F6A9", RED)])),

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
                "\U0001F50D", illus=illus_browser(S("p_trail")))),
        ("rules", "THE RULES",
         ["Two: hold only the victim's money.", "Each account is held for exactly the traced amount, not frozen."],
         L_rule(2, "Hold only the victim's money", "A lien for exactly the traced amount, not a full freeze.",
                "\U0001F512", AMBER, illus=illus_hold())),
        ("rules", "THE RULES",
         ["Three: mark mule accounts.", "Every bank sees the mark, and so does the holder.",
          "Payments out stay blocked until the holder is verified at the branch."],
         L_rule(3, "Mark mule accounts", "Visible to every bank and to the holder. Debits blocked until branch "
                "verification.", "\U0001F6A9", RED, illus=illus_browser(S("p_mules")))),
        ("rules", "THE RULES",
         ["Four: warn the sender.", "Pay anyway is allowed only to repay a victim."],
         L_rule(4, "Warn the sender", "A red warning before paying a mule. \"Pay anyway\" only to repay.",
                "\u26A0", AMBER, illus=illus_phone(S("b_mule_payee")))),
        ("rules", "THE RULES",
         ["Five: never touch the merchant.", "The shop keeps its money. Recovery comes from the buyer, the last mule."],
         L_rule(5, "Never touch the merchant", "The shop keeps its money. The buyer, the last mule, repays.",
                "\U0001F3EA", GREEN, illus=illus_merchant())),
        ("rules", "THE RULES",
         ["Six: blacklist the PAN across every bank and crypto exchange.",
          "No new account, and no crypto."],
         L_rule(6, "Blacklist the PAN", "No new bank account, no crypto account, anywhere.", "\U0001F6AB", RED,
                illus=illus_pan())),
        ("rules", "THE RULES",
         ["Seven: court-approved recovery.", "The system drafts the court application itself.",
          "After approval, a recovery lien collects the money, even into a negative balance."],
         L_rule(7, "Court-approved recovery", "Applications drafted automatically. Recovery lien can go "
                "negative.", "\u2696", AMBER, illus=illus_browser(S("p_application")))),
        ("rules", "THE RULES",
         ["Eight: crypto is frozen at the exchange, and released only with a court seizure order."],
         L_rule(8, "Freeze crypto", "Frozen at the exchange; released only with a seizure order.", "\u2744",
                PURPLE, illus=illus_crypto())),
        ("rules", "THE RULES",
         ["And nine: the phone's GPS is mandatory.", "No location, no payment."],
         L_rule(9, "Location on every payment", "GPS is mandatory. ATM withdrawals record the ATM.",
                "\U0001F4CD", (90, 160, 255), illus=illus_phone(S("b_location_popup")))),

        ("story", "WATCH IT WORK",
         ["Let us watch it work.",
          "Priya gets a call: her KYC has expired, and she must pay fifty thousand rupees to keep her account."],
         L_phones([S("b_lock"), S("b_home")], [0, 1], captions=["Priya's bank app", "₹50,000 paid to the caller"])),
        ("story", "WATCH IT WORK",
         ["She pays by UPI.",
          "Within minutes, the money passes through seven mules in four banks, from Jamtara to Kolkata, Deoghar "
          "and Nuh.",
          "Ten thousand buys a phone in Jaipur, and ten thousand goes to a crypto exchange."],
         L_sequence(play)),
        ("story", "WATCH IT WORK",
         ["Priya reports the payment from her app.",
          "She gets only an acknowledgement number; the investigation details stay with the police."],
         L_phones([S("b_complaints")], [0], captions=["Victim sees only the acknowledgement"])),
        ("story", "WATCH IT WORK",
         ["In the police console, the complaint is already traced.",
          "Thirty thousand rupees is on hold, and five thousand in crypto is frozen."],
         L_browser(S("p_dashboard"), caption="Cyber Police console")),
        ("story", "WATCH IT WORK",
         ["The summary shows everything: amount lost, accounts traced, money held, spent at shops, frozen as "
          "crypto, and what escaped."],
         L_browser(S("p_summary"), caption="Complaint summary")),
        ("story", "WATCH IT WORK",
         ["The map shows where every phone was when it moved the money, with an arrow for every hop."],
         L_browser(S("p_map"), caption="Money-trail map (phone GPS)")),
        ("story", "WATCH IT WORK", ["The money trail shows the same story as a tree, account by account."],
         L_browser(S("p_trail"), caption="Money trail")),
        ("story", "WATCH IT WORK",
         ["For the phone and the escaped crypto, court applications are already drafted, ready for the magistrate.",
          "The shopkeeper is never touched: Prem, the buyer, repays."],
         L_browser(S("p_courts"), caption="Court applications, drafted automatically")
         + [place_shadowed(browser(S("p_application"), 1000), 560, 250, at=1)]),
        ("story", "WATCH IT WORK",
         ["Meanwhile, the mule accounts are marked.", "If anyone tries to pay one, they see this warning."],
         L_phones([S("b_mule_payee"), S("b_mule_dialog")], [0, 1], captions=["Mule warning", "Pay anyway = repayment"])),
        ("story", "WATCH IT WORK", ["And a payment without location is simply not made."],
         L_phones([S("b_location_popup")], [0], captions=["No GPS, no payment"])),
        ("story", "WATCH IT WORK",
         ["When the court approves, one tap releases the money.",
          "Almost thirty-five thousand rupees is back with Priya, with a notice in her app.",
          "The rest is collected through the recovery liens."],
         L_browser_phone(S("p_summary_after"), S("b_notices"), 0, 1, caption="Money returned to Priya")),

        ("tech", "TECHNOLOGY",
         ["We built nine Android apps in Flutter and Dart, sharing one core library.",
          "The server is Python and FastAPI, with a PostgreSQL database on Neon, hosted on Render.",
          "Every app works in English, Hindi and Kannada, with a night mode."],
         L_stack()),

        ("impact", "WHAT IT CHANGES",
         ["With RakshakPay, money is held in seconds, not days.", "Shopkeepers are protected.",
          "Mules cannot just move banks.", "And victims get their money back faster."],
         L_rows("What changes", [
             ("Seconds, not days", "Money is held the moment the complaint is filed", "\u23F1", GREEN),
             ("Shops protected", "Merchants keep their money; buyers repay", "\U0001F3EA", GREEN),
             ("No escape for mules", "Marked across all banks; PAN blacklisted", "\U0001F6A9", AMBER),
             ("Faster refunds", "Court applications drafted automatically", "\u20B9", GREEN)], y0=300, gap=150)),
        ("impact", "WHAT'S NEXT",
         ["Today it runs on simulated banks.",
          "Next: protection against fake complaints, and forecasting mule hotspots.",
          "A real launch needs RBI, NPCI, the banks and the courts to connect."],
         L_rows("Next steps", [
             ("A working prototype", "Five simulated banks, real apps, real server", "\u2714", SAFFRON),
             ("Fake-complaint protection", "and forecasting of mule hotspots", "\U0001F50D", SAFFRON),
             ("Real-world launch", "needs RBI, NPCI, banks and courts to connect", "\U0001F3E6", SAFFRON)],
             y0=320, gap=160)),

        ("end", "", ["RakshakPay.", "Protecting every rupee."],
         L_title("RakshakPay", "Protecting every rupee.", "github.com/jagadish3095-pixel/rakshakpay")),
    ]


def spoken(sentence: str) -> str:
    """Text for the voice: say the names the way people say them."""
    return (sentence.replace("RakshakPay", "Rakshak Pay").replace("1930", "1 9 3 0")
            .replace("CoinVault", "Coin Vault").replace("PostgreSQL", "Postgres").replace("FastAPI", "Fast A.P.I.").replace("cybercrime.gov.in", "cyber crime dot gov dot in"))


# ---------------------------------------------------------------- audio

async def _tts(text, path):
    c = edge_tts.Communicate(text, VOICE, rate="+12%")
    with open(path, "wb") as f:
        async for ch in c.stream():
            if ch["type"] == "audio":
                f.write(ch["data"])


def tts_wav(sentence, work: pathlib.Path):
    key = hashlib.sha1((VOICE + spoken(sentence)).encode()).hexdigest()[:16]
    wav = work / f"{key}.wav"
    if not wav.exists():
        mp3 = work / f"{key}.mp3"
        asyncio.run(_tts(spoken(sentence), mp3))
        subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error", "-i", str(mp3), "-ar", "48000",
                        "-ac", "1", str(wav)], check=True)
    with wave.open(str(wav)) as w:
        return w.readframes(w.getnframes()), w.getnframes() / w.getframerate()


# ---------------------------------------------------------------- render

def subtitle_img(text):
    t = text_img(text, 36, "semi", WHITE, max_w=1560, align="center", spacing=1.2)
    box = rounded((t.width + 60, t.height + 20), 18, (0, 0, 0, 170))
    box.alpha_composite(t, (30, 8))
    return box


def label_img(text):
    return text_img(text, 26, "bold", SAFFRON)


def faded(img, a):
    if a >= 1:
        return img
    out = img.copy()
    out.putalpha(img.getchannel("A").point(lambda v: int(v * a)))
    return out


def main(shots_dir, work_dir, out_mp4):
    shots, work = pathlib.Path(shots_dir), pathlib.Path(work_dir)
    work.mkdir(parents=True, exist_ok=True)
    plan = beats(shots)

    # Narration: one wav per sentence, then the whole soundtrack
    audio, timeline = bytearray(), []  # timeline: (scene, label, layout, [(start, end, text)], duration)
    for scene, label, sentences, layout in plan:
        starts, t = [], 0.0
        for s in sentences:
            pcm, dur = tts_wav(s, work)
            audio += pcm + b"\x00\x00" * int(48000 * GAP)
            starts.append((t, t + dur, s))
            t += dur + GAP
        audio += b"\x00\x00" * int(48000 * BEAT_PAD)
        timeline.append((scene, label, layout, starts, t + BEAT_PAD))
        print(f"{scene:9s} {t + BEAT_PAD:5.1f}s  {sentences[0][:60]}")
    total = sum(b[4] for b in timeline)
    print(f"total {total / 60:.1f} min")
    wav_path = work / "narration.wav"
    with wave.open(str(wav_path), "wb") as w:
        w.setnchannels(1), w.setsampwidth(2), w.setframerate(48000)
        w.writeframes(bytes(audio))

    preview = out_mp4.endswith("preview")  # one still per beat instead of the video
    if preview:
        (work / "preview").mkdir(exist_ok=True)
    ff = None if preview else subprocess.Popen([imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error",
                           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
                           "-i", str(wav_path), "-c:v", "libx264", "-preset", "medium", "-crf", "20",
                           "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k", "-shortest",
                           "-movflags", "+faststart", out_mp4], stdin=subprocess.PIPE)
    bg = gradient_bg()
    dark_bg = gradient_bg((6, 12, 32), (14, 26, 62))
    prev_frame, prev_scene = None, None
    subs_cache = {}
    for bi, (scene, label, layout, sents, dur) in enumerate(timeline):
        base_bg = dark_bg if scene == "story" else bg
        n = round(dur * FPS)
        # when each element appears (seconds into the beat)
        for e in layout:
            e.t0 = e.t if e.t is not None and e.at == 0 else sents[min(e.at, len(sents) - 1)][0] + (
                e.t if e.t is not None else 0)
        static_key, static_img = None, None
        lbl = label_img(label) if label else None
        for fi in ([n - 1] if preview else range(n)):
            t = fi / FPS
            # Only a leading run of finished, still elements is cached, so drawing order is kept.
            settled = []
            for i, e in enumerate(layout):
                if t - e.t0 < FADE or e.zoom or e.seq:
                    break
                settled.append(i)
            settled = tuple(settled)
            if settled != static_key:
                static_img = base_bg.copy()
                if lbl:
                    static_img.alpha_composite(lbl, (120, 54))
                for i in settled:
                    e = layout[i]
                    static_img.paste(e.img, (e.x, e.y), e.img)
                static_key = settled
            frame = static_img.copy()
            for i, e in enumerate(layout):
                if i in settled:
                    continue
                a = (t - e.t0) / FADE
                if a <= 0:
                    continue
                a = min(a, 1.0)
                ease = 1 - (1 - a) ** 3
                img = e.img
                if e.seq:
                    frames, pad = e.seq
                    k = t / dur * (len(frames) - 1)
                    i0 = min(int(k), len(frames) - 2)
                    mix = k - i0
                    cur = Image.blend(frames[i0], frames[i0 + 1], min(1, max(0, (mix - 0.5) * 2.5 + 0.5)))
                    img = e.img.copy()
                    img.alpha_composite(cur, (pad, pad))
                if e.zoom:
                    z = 1 + e.zoom * (t / dur)
                    img = img.resize((int(img.width * z), int(img.height * z)), Image.BILINEAR)
                    x = e.x - (img.width - e.img.width) // 2
                    y = e.y - (img.height - e.img.height) // 2
                else:
                    x, y = e.x, e.y
                y += int(e.slide * (1 - ease))
                img = faded(img, ease)
                frame.paste(img, (x, y), img)
            cur = next((s for s in sents if s[0] <= t < s[1] + GAP), None)
            if cur and scene not in ("title", "end"):
                key = cur[2]
                if key not in subs_cache:
                    subs_cache[key] = subtitle_img(key)
                sub = subs_cache[key]
                frame.alpha_composite(sub, ((W - sub.width) // 2, H - sub.height - 36))
            rgb = frame.convert("RGB")
            if preview:
                # the last sentence's subtitle is gone by the end; show the first one instead
                if sents and scene not in ("title", "end"):
                    sub = subtitle_img(sents[0][2])
                    rgb.paste(sub, ((W - sub.width) // 2, H - sub.height - 36), sub)
                rgb.resize((960, 540)).save(work / "preview" / f"{bi:02d}_{scene}.jpg", quality=85)
                continue
            if prev_frame is not None and scene != prev_scene and fi < 12:
                rgb = Image.blend(prev_frame, rgb, (fi + 1) / 12)
            ff.stdin.write(rgb.tobytes())
            if fi == n - 1:
                prev_frame = rgb
        prev_scene = scene
        print(f"rendered beat {bi + 1}/{len(timeline)}", flush=True)
    if ff:
        ff.stdin.close()
        ff.wait()
    print("saved", out_mp4)


if __name__ == "__main__":
    main(*sys.argv[1:4])
