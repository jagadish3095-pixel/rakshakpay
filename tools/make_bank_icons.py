"""Draws a launcher icon for each of the 5 bank apps.

Run once (needs Pillow):  backend/.venv/Scripts/python tools/make_bank_icons.py
Writes apps/bank_app/android/app/src/<flavor>/res/mipmap-*/ic_launcher.png
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "apps" / "bank_app" / "android" / "app" / "src"
SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
BANKS = {
    "sahyadri": ("S", "#1B8A5A"),
    "ganga": ("G", "#1E5BB8"),
    "kaveri": ("K", "#6B3FA0"),
    "narmada": ("N", "#D9731A"),
    "godavari": ("G", "#C62F3B"),
}


def font(px: int) -> ImageFont.FreeTypeFont:
    for name in ("arialbd.ttf", "DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(name, px)
        except OSError:
            continue
    return ImageFont.load_default(px)


def draw_icon(letter: str, color: str, size: int) -> Image.Image:
    big = size * 4  # draw large, then shrink for smooth edges
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, big - 1, big - 1), radius=big // 5, fill=color)
    pad = big // 7
    d.ellipse((pad, pad, big - pad, big - pad), fill="white")
    # rupee-coin style ring
    ring = big // 5
    d.ellipse((ring, ring, big - ring, big - ring), outline=color, width=big // 40)
    d.text((big / 2, big / 2), letter, fill=color, font=font(int(big * 0.42)), anchor="mm")
    return img.resize((size, size), Image.LANCZOS)


for flavor, (letter, color) in BANKS.items():
    for density, px in SIZES.items():
        out = RES / flavor / "res" / f"mipmap-{density}" / "ic_launcher.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        draw_icon(letter, color, px).save(out)
    print("icons written for", flavor)
