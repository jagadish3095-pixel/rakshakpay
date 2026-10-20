"""Draws the launcher icons for RakshakPay (indigo) and RakshakPay Business (saffron).

Run once (needs Pillow):  backend/.venv/Scripts/python tools/make_upi_icon.py
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
INDIGO, SAFFRON = "#3B2A8C", "#FF8F1F"


def font(px):
    for name in ("arialbd.ttf", "seguisb.ttf", "DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(name, px)
        except OSError:
            continue
    return ImageFont.load_default(px)


def draw(size, background, rupee_color):
    big = size * 4
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, big - 1, big - 1), radius=big // 5, fill=background)
    w = big
    # shield outline: flat top, curved sides to a point at the bottom
    shield = [(w * .22, w * .2), (w * .5, w * .12), (w * .78, w * .2), (w * .76, w * .52),
              (w * .66, w * .72), (w * .5, w * .86), (w * .34, w * .72), (w * .24, w * .52)]
    d.polygon(shield, fill="white")
    d.text((w / 2, w * .47), "₹", fill=rupee_color, font=font(int(w * .42)), anchor="mm")
    return img.resize((size, size), Image.LANCZOS)


def draw_coinvault(size):
    """CoinVault: gold hexagon with a C on a dark background."""
    big = size * 4
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, big - 1, big - 1), radius=big // 5, fill="#0B1418")
    d.regular_polygon((big / 2, big / 2, big * 0.38), n_sides=6, rotation=30, fill="#F5B301")
    d.text((big / 2, big / 2), "C", fill="#0B1418", font=font(int(big * .42)), anchor="mm")
    return img.resize((size, size), Image.LANCZOS)


def draw_police(size):
    """Cyber Police: amber star badge on navy."""
    big = size * 4
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, big - 1, big - 1), radius=big // 5, fill="#0D2B5E")
    d.regular_polygon((big / 2, big / 2, big * 0.36), n_sides=6, rotation=0, fill="#FFB300")
    c, r_out, r_in = big / 2, big * 0.22, big * 0.09
    star = [(c + (r_out if i % 2 == 0 else r_in) * math.cos(math.pi / 2 + i * math.pi / 5),
             c - (r_out if i % 2 == 0 else r_in) * math.sin(math.pi / 2 + i * math.pi / 5)) for i in range(10)]
    d.polygon(star, fill="#0D2B5E")
    return img.resize((size, size), Image.LANCZOS)


APPS = {"upi_app": lambda px: draw(px, INDIGO, SAFFRON),
        "merchant_app": lambda px: draw(px, SAFFRON, INDIGO),
        "crypto_app": draw_coinvault,
        "police_app": draw_police}

for app, painter in APPS.items():
    res = ROOT / "apps" / app / "android" / "app" / "src" / "main" / "res"
    for density, px in SIZES.items():
        painter(px).save(res / f"mipmap-{density}" / "ic_launcher.png")
    print("icon written for", app)
