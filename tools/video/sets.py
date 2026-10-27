"""Cartoon backgrounds ("sets") for the RakshakPay story video, drawn with Pillow."""

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONTS = r"C:\Windows\Fonts"


def _font(size, bold=True):
    return ImageFont.truetype(f"{FONTS}\\{'segoeuib.ttf' if bold else 'segoeui.ttf'}", size)


def home(w, h):
    """Priya's living room in Bengaluru: warm wall, window with a coconut tree, sofa, lamp."""
    im = Image.new("RGBA", (w, h), (247, 226, 196, 255))
    d = ImageDraw.Draw(im)
    floor = int(h * 0.80)
    d.rectangle((0, floor, w, h), fill=(196, 150, 110))
    for x in range(0, w, 120):
        d.line((x, floor, x - 60, h), fill=(180, 134, 96), width=3)
    # window
    wx, wy, ww, wh = int(w * 0.12), int(h * 0.14), int(w * 0.3), int(h * 0.38)
    d.rounded_rectangle((wx, wy, wx + ww, wy + wh), 10, fill=(170, 220, 250), outline=(120, 90, 60), width=10)
    d.ellipse((wx + ww * 0.55, wy + wh * 0.15, wx + ww * 0.75, wy + wh * 0.38), fill=(255, 225, 120))
    d.rectangle((wx + ww * 0.25, wy + wh * 0.45, wx + ww * 0.29, wy + wh), fill=(140, 100, 60))
    for dx in (-60, -30, 0, 30, 60):
        d.ellipse((wx + ww * 0.27 + dx - 50, wy + wh * 0.35, wx + ww * 0.27 + dx + 50, wy + wh * 0.52),
                  fill=(60, 160, 80))
    d.line((wx + ww / 2, wy, wx + ww / 2, wy + wh), fill=(120, 90, 60), width=8)
    # sofa
    sx, sy = int(w * 0.5), int(floor - h * 0.26)
    d.rounded_rectangle((sx, sy, sx + int(w * 0.42), floor - 10), 30, fill=(70, 120, 150))
    d.rounded_rectangle((sx + 20, sy + int(h * 0.1), sx + int(w * 0.42) - 20, floor - 30), 20, fill=(90, 145, 175))
    # lamp
    lx = int(w * 0.94)
    d.line((lx, floor, lx, floor - h * 0.42), fill=(80, 70, 60), width=8)
    d.polygon([(lx - 50, floor - h * 0.42), (lx + 50, floor - h * 0.42), (lx + 30, floor - h * 0.52),
               (lx - 30, floor - h * 0.52)], fill=(250, 200, 120))
    return im


def scam_room(w, h):
    """Pankaj's dim room in Jamtara: dark walls, a desk with a glowing laptop, SIM cards and phones."""
    im = Image.new("RGBA", (w, h), (34, 38, 52, 255))
    d = ImageDraw.Draw(im)
    floor = int(h * 0.80)
    d.rectangle((0, floor, w, h), fill=(26, 28, 36))
    # peeling poster and a bare bulb
    d.line((w * 0.5, 0, w * 0.5, h * 0.16), fill=(20, 20, 20), width=4)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((w * 0.5 - 260, h * 0.16 - 200, w * 0.5 + 260, h * 0.16 + 260),
                                 fill=(255, 210, 120, 70))
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(60)))
    d.ellipse((w * 0.5 - 18, h * 0.16 - 10, w * 0.5 + 18, h * 0.16 + 30), fill=(255, 230, 150))
    # desk with laptop and a pile of phones
    dy = int(floor - h * 0.2)
    d.rectangle((int(w * 0.52), dy, int(w * 0.98), dy + 24), fill=(90, 66, 50))
    d.rectangle((int(w * 0.54), dy + 24, int(w * 0.56), floor), fill=(70, 50, 40))
    d.rectangle((int(w * 0.94), dy + 24, int(w * 0.96), floor), fill=(70, 50, 40))
    lx = int(w * 0.66)
    d.polygon([(lx, dy), (lx + 220, dy), (lx + 250, dy - 150), (lx + 30, dy - 150)], fill=(40, 44, 54))
    d.polygon([(lx + 40, dy - 20), (lx + 210, dy - 20), (lx + 232, dy - 136), (lx + 52, dy - 136)], fill=(90, 200, 255))
    for i in range(5):
        d.rounded_rectangle((int(w * 0.86) + i * 18, dy - 30 - i * 6, int(w * 0.86) + i * 18 + 34, dy - i * 6), 5,
                            fill=(20, 20, 24), outline=(80, 80, 90), width=2)
    d.text((int(w * 0.08), int(h * 0.18)), "KYC", font=_font(int(h * 0.06)), fill=(70, 74, 90))
    return im


def police_office(w, h):
    """Cyber crime cell: blue wall, India map poster, desk with a big monitor (screen drawn by the caller)."""
    im = Image.new("RGBA", (w, h), (214, 226, 240, 255))
    d = ImageDraw.Draw(im)
    floor = int(h * 0.80)
    d.rectangle((0, floor, w, h), fill=(150, 160, 175))
    d.rectangle((0, int(h * 0.08), w, int(h * 0.15)), fill=(13, 43, 94))
    d.text((40, int(h * 0.085)), "CYBER CRIME CELL", font=_font(int(h * 0.045)), fill=(255, 200, 60))
    return im


def atm_booth(w, h, bank="GODAVARI BANK ATM", city="DEOGHAR"):
    """An ATM booth: tiled walls, the machine with a green screen, a cash slot."""
    im = Image.new("RGBA", (w, h), (226, 232, 238, 255))
    d = ImageDraw.Draw(im)
    floor = int(h * 0.80)
    for x in range(0, w, 90):
        d.line((x, 0, x, floor), fill=(210, 216, 224), width=2)
    d.rectangle((0, floor, w, h), fill=(150, 156, 166))
    d.rectangle((0, 0, w, int(h * 0.11)), fill=(0, 105, 92))
    d.text((40, int(h * 0.015)), f"{bank}  •  {city}", font=_font(int(h * 0.06)), fill=(255, 255, 255))
    mx = int(w * 0.62)
    d.rounded_rectangle((mx, int(h * 0.22), mx + 420, floor), 24, fill=(70, 78, 90), outline=(40, 44, 52), width=6)
    d.rounded_rectangle((mx + 50, int(h * 0.27), mx + 370, int(h * 0.47)), 12, fill=(10, 40, 30))
    d.text((mx + 74, int(h * 0.30)), "WELCOME", font=_font(30), fill=(90, 255, 160))
    d.text((mx + 74, int(h * 0.36)), "INSERT CARD", font=_font(26, False), fill=(90, 255, 160))
    d.rectangle((mx + 90, int(h * 0.52), mx + 330, int(h * 0.545)), fill=(20, 20, 24))  # card slot
    for r in range(3):
        for k in range(3):
            d.rounded_rectangle((mx + 140 + k * 52, int(h * 0.58) + r * 44, mx + 180 + k * 52,
                                 int(h * 0.58) + r * 44 + 34), 6, fill=(200, 204, 210))
    d.rectangle((mx + 90, int(h * 0.74), mx + 330, int(h * 0.765)), fill=(20, 20, 24))  # cash slot
    return im


def branch(w, h, bank="KAVERI BANK", place="HOME BRANCH"):
    """A bank branch desk with a nameplate, a computer and a document tray."""
    im = Image.new("RGBA", (w, h), (238, 230, 248, 255))
    d = ImageDraw.Draw(im)
    floor = int(h * 0.80)
    d.rectangle((0, floor, w, h), fill=(170, 160, 190))
    d.rectangle((0, 0, w, int(h * 0.12)), fill=(103, 58, 160))
    d.text((40, int(h * 0.02)), f"{bank}  •  {place}", font=_font(int(h * 0.06)), fill=(255, 255, 255))
    d.rounded_rectangle((int(w * 0.1), int(h * 0.2), int(w * 0.3), int(h * 0.42)), 14, fill=(255, 255, 255),
                        outline=(150, 130, 180), width=5)
    d.text((int(w * 0.12), int(h * 0.24)), "KYC", font=_font(int(h * 0.05)), fill=(103, 58, 160))
    d.text((int(w * 0.12), int(h * 0.32)), "Re-verification", font=_font(int(h * 0.028), False), fill=(90, 80, 110))
    return im


def branch_desk(im):
    """The desk drawn in front of the officer (call after drawing her)."""
    w, h = im.size
    d = ImageDraw.Draw(im)
    floor = int(h * 0.80)
    top = int(floor - h * 0.22)
    d.rectangle((int(w * 0.40), top, int(w * 0.95), floor), fill=(150, 110, 80), outline=(110, 80, 60), width=6)
    d.rectangle((int(w * 0.40), top, int(w * 0.95), top + 24), fill=(120, 86, 62))
    d.rounded_rectangle((int(w * 0.58), top + 50, int(w * 0.77), top + 110), 8, fill=(240, 232, 210))
    d.text((int(w * 0.59), top + 60), "LAKSHMI • OFFICER", font=_font(26), fill=(60, 40, 30))
    d.rectangle((int(w * 0.80), top - 150, int(w * 0.92), top - 10), fill=(40, 44, 52))
    d.rectangle((int(w * 0.81), top - 140, int(w * 0.91), top - 30), fill=(120, 200, 255))


def shop(w, h):
    """Jaipur Mobile Hub: shelves of phones, a counter and a QR stand."""
    im = Image.new("RGBA", (w, h), (255, 240, 214, 255))
    d = ImageDraw.Draw(im)
    floor = int(h * 0.80)
    d.rectangle((0, floor, w, h), fill=(170, 130, 100))
    d.rectangle((0, 0, w, int(h * 0.13)), fill=(220, 60, 50))
    d.text((40, int(h * 0.02)), "JAIPUR MOBILE HUB", font=_font(int(h * 0.07)), fill=(255, 255, 255))
    for row in range(3):
        y = int(h * (0.24 + row * 0.15))
        d.rectangle((int(w * 0.05), y + 70, int(w * 0.95), y + 82), fill=(150, 110, 80))
        for i in range(10):
            x = int(w * 0.07) + i * int(w * 0.088)
            d.rounded_rectangle((x, y, x + 44, y + 70), 8, fill=(30, 30, 36), outline=(120, 120, 130), width=2)
            d.rectangle((x + 6, y + 8, x + 38, y + 58), fill=(80 + i * 15 % 120, 140, 220))
    cy = int(floor - h * 0.22)
    d.rectangle((int(w * 0.30), cy, int(w * 0.98), floor), fill=(200, 160, 120), outline=(150, 110, 80), width=6)
    d.rounded_rectangle((int(w * 0.80), cy - 120, int(w * 0.90), cy), 10, fill=(255, 255, 255),
                        outline=(60, 60, 60), width=4)
    d.text((int(w * 0.81), cy - 115), "UPI", font=_font(28), fill=(40, 40, 120))
    for i in range(4):
        for j in range(4):
            if (i + j) % 2 == 0:
                d.rectangle((int(w * 0.815) + i * 18, cy - 75 + j * 16, int(w * 0.815) + i * 18 + 14,
                             cy - 75 + j * 16 + 12), fill=(20, 20, 20))
    return im
