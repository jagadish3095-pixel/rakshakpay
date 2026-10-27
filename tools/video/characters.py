"""Flat 2D cartoon characters for the RakshakPay story video, drawn with Pillow.

    draw_character(img, name, x, ground_y, height, expression="neutral", mouth=0.0, blink=False,
                   pose="idle", facing=1)

`mouth` 0..1 opens the mouth (driven by the voice volume while a character speaks).
Expressions: neutral, happy, worried, shocked, sly, sad, angry, relieved.
Poses: idle, phone (phone at the ear), wave, laptop (hands forward), point, cheer.
"""

from PIL import Image, ImageDraw

SKIN = {"light": (241, 194, 160), "medium": (214, 160, 120), "tan": (192, 140, 100), "deep": (150, 102, 70)}

CAST = {
    "priya": dict(skin="medium", hair="long", hair_c=(32, 22, 20), top=(232, 76, 120), bottom=(52, 60, 110),
                  female=True, bindi=True),
    "pankaj": dict(skin="tan", hair="short", hair_c=(20, 18, 18), top=(46, 50, 58), bottom=(30, 32, 40),
                   hoodie=True, headset=True, stubble=True),
    "meera": dict(skin="medium", hair="bun", hair_c=(25, 18, 16), top=(176, 150, 96), bottom=(150, 128, 82),
                  female=True, cap=True, badge=True),
    "mahesh": dict(skin="tan", hair="short", hair_c=(60, 56, 54), top=(250, 245, 230), bottom=(120, 100, 80),
                   mustache=True, glasses=True),
    "prem": dict(skin="medium", hair="short", hair_c=(30, 24, 20), top=(64, 160, 120), bottom=(40, 50, 90),
                 cap_back=True),
    "pavan": dict(skin="tan", hair="short", hair_c=(28, 22, 20), top=(90, 90, 200), bottom=(40, 40, 50)),
    "pradeep": dict(skin="deep", hair="short", hair_c=(20, 18, 18), top=(200, 70, 60), bottom=(40, 40, 50),
                    hoodie=True),
    "ravi": dict(skin="light", hair="short", hair_c=(45, 32, 24), top=(70, 150, 220), bottom=(60, 60, 70),
                 glasses=True),
    "lakshmi": dict(skin="medium", hair="bun", hair_c=(25, 18, 16), top=(120, 70, 170), bottom=(70, 50, 110),
                    female=True, bindi=True, badge=True),
    "mule1": dict(skin="deep", hair="short", hair_c=(20, 18, 18), top=(200, 70, 60), bottom=(40, 40, 50),
                  hoodie=True),
    "mule2": dict(skin="light", hair="short", hair_c=(50, 35, 25), top=(90, 90, 200), bottom=(40, 40, 50)),
    "mule3": dict(skin="tan", hair="long_m", hair_c=(25, 20, 18), top=(230, 160, 40), bottom=(40, 40, 50),
                  female=True),
}

OUTLINE = (30, 26, 34)


def _shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c)


def draw_character(img, name, x, ground_y, height, expression="neutral", mouth=0.0, blink=False, pose="idle",
                   facing=1, prop=None):
    """Draws onto `img` (RGBA). The character stands on `ground_y`, centred on `x`, `height` pixels tall."""
    c = CAST[name]
    ss = 2  # supersample for smooth edges
    s = height / 600 * ss
    W, H = int(420 * s), int(640 * s)
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx = W / 2
    gy = 620 * s  # ground inside the layer

    def P(px, py):  # design units (character is ~600 tall, origin at feet centre) -> layer pixels
        return cx + px * s * facing, gy - py * s

    def ell(x0, y0, x1, y1, fill, outline=OUTLINE, w=4):
        (a, b), (e, f) = P(x0, y0), P(x1, y1)
        d.ellipse((min(a, e), min(b, f), max(a, e), max(b, f)), fill=fill, outline=outline, width=int(w * s / ss * ss))

    def rrect(x0, y0, x1, y1, r, fill, outline=OUTLINE, w=4):
        (a, b), (e, f) = P(x0, y0), P(x1, y1)
        d.rounded_rectangle((min(a, e), min(b, f), max(a, e), max(b, f)), int(r * s), fill=fill, outline=outline,
                            width=int(w * s))

    def poly(pts, fill, outline=OUTLINE, w=4):
        d.polygon([P(*p) for p in pts], fill=fill, outline=outline, width=int(w * s))

    def line(pts, fill, w):
        d.line([P(*p) for p in pts], fill=fill, width=int(w * s), joint="curve")
        for p in (pts[0], pts[-1]):
            px, py = P(*p)
            r = w * s / 2
            d.ellipse((px - r, py - r, px + r, py + r), fill=fill)

    skin = SKIN[c["skin"]]
    top, bottom = c["top"], c["bottom"]
    female = c.get("female", False)

    # ---- long hair behind the body
    if c["hair"] == "long":
        rrect(-78, 470, 78, 300, 60, c["hair_c"])
    if c["hair"] == "long_m":
        rrect(-74, 470, 74, 350, 50, c["hair_c"])

    # ---- legs and shoes
    if female and not c.get("cap"):
        poly([(-70, 250), (70, 250), (92, 40), (-92, 40)], bottom)  # long skirt / kurta bottom
        rrect(-60, 40, -14, 0, 14, (60, 40, 40))
        rrect(14, 40, 60, 0, 14, (60, 40, 40))
    else:
        rrect(-52, 250, -8, 20, 14, bottom)
        rrect(8, 250, 52, 20, 14, bottom)
        rrect(-62, 30, -4, 0, 14, (40, 36, 40))
        rrect(4, 30, 62, 0, 14, (40, 36, 40))

    # ---- arms (behind/in front depends on pose; keep it simple: drawn before torso if idle)
    arm_w = 30
    sl, sr = (-68, 395), (68, 395)  # shoulders

    def arm(sh, elbow, hand, front=True):
        line([sh, elbow, hand], _shade(top, 0.92), arm_w)
        hx, hy = hand
        ell(hx - 17, hy + 17, hx + 17, hy - 17, skin, w=3)

    poses = {
        "idle": ((-84, 300), (-80, 215), (84, 300), (80, 215)),
        "phone": ((-84, 300), (-80, 215), (110, 360), (52, 470)),
        "wave": ((-84, 300), (-80, 215), (130, 420), (150, 520)),
        "laptop": ((-90, 320), (-40, 270), (90, 320), (40, 270)),
        "point": ((-84, 300), (-80, 215), (140, 380), (205, 400)),
        "cheer": ((-120, 440), (-140, 540), (120, 440), (140, 540)),
        "shrug": ((-120, 330), (-150, 380), (120, 330), (150, 380)),
        "facepalm": ((-84, 300), (-80, 215), (90, 380), (30, 500)),
    }
    le, lh, re, rh = poses.get(pose, poses["idle"])

    # ---- torso
    if c.get("hoodie"):
        rrect(-80, 420, 80, 230, 40, top)
        poly([(-40, 420), (40, 420), (0, 370)], _shade(top, 0.8))
        line([(-14, 380), (-18, 320)], (220, 220, 220), 4)
        line([(14, 380), (18, 320)], (220, 220, 220), 4)
    elif c.get("cap"):  # police uniform
        rrect(-80, 420, 80, 230, 30, top)
        poly([(-30, 420), (30, 420), (0, 380)], (240, 236, 220))
        rrect(-80, 250, 80, 228, 6, (90, 60, 30))  # belt
        rrect(30, 380, 62, 352, 6, (230, 190, 60))  # badge
        for yy in (360, 320, 280):
            ell(-4, yy + 4, 4, yy - 4, (90, 60, 30), w=1)
    else:
        rrect(-80, 420, 80, 230, 40, top)
        if female:
            poly([(-34, 420), (34, 420), (0, 378)], _shade(top, 0.8))
        else:
            poly([(-26, 420), (26, 420), (0, 392)], _shade(top, 0.85))

    arm(sl, le, lh)
    if pose not in ("phone", "facepalm"):
        arm(sr, re, rh)

    # ---- neck and head
    rrect(-20, 450, 20, 410, 8, skin, w=3)
    hx0, hy0, hx1, hy1 = -70, 590, 70, 440
    ell(hx0, hy0, hx1, hy1, skin)
    ell(-80, 525, -64, 495, skin, w=3)  # ears
    ell(64, 525, 80, 495, skin, w=3)
    if female:  # earrings
        ell(-79, 494, -67, 480, (235, 190, 60), w=2)
        ell(67, 494, 79, 480, (235, 190, 60), w=2)

    # ---- hair on top
    hc = c["hair_c"]
    if c["hair"] in ("long", "long_m"):
        poly([(-74, 540), (-60, 585), (-20, 600), (30, 600), (66, 580), (76, 530), (40, 560), (0, 555), (-40, 545)],
             hc)
    elif c["hair"] == "bun":
        ell(-30, 625, 30, 580, hc)
        poly([(-72, 530), (-60, 585), (0, 598), (60, 585), (72, 530), (30, 560), (-30, 560)], hc)
    else:
        poly([(-72, 525), (-66, 580), (-20, 602), (40, 600), (70, 575), (73, 525), (50, 560), (0, 570),
              (-45, 560)], hc)

    if c.get("cap"):  # police cap
        rrect(-76, 612, 76, 560, 20, (40, 60, 110))
        rrect(-84, 566, 84, 550, 8, (25, 35, 70))
        ell(-12, 600, 12, 576, (230, 190, 60), w=2)
    if c.get("cap_back"):
        rrect(-74, 600, 74, 560, 30, (220, 60, 50))
        rrect(-74, 566, 30, 554, 6, (190, 40, 40))  # brim to the side
    if c.get("headset"):
        d.arc([*P(-82, 610), *P(82, 470)], 180 if facing == 1 else 0, 360 if facing == 1 else 180,
              fill=(20, 20, 20), width=int(10 * s))
        ell(-90, 540, -64, 490, (20, 20, 20), w=2)
        line([(-76, 500), (-40, 470), (-12, 466)], (20, 20, 20), 5)
        ell(-18, 472, -6, 460, (20, 20, 20), w=1)

    # ---- face
    ex = 28
    ey = 515
    brow = {"neutral": (0, 0), "happy": (2, 2), "worried": (8, -6), "shocked": (12, 12), "sly": (-8, 6),
            "sad": (8, -8), "angry": (-10, 8), "relieved": (4, 4)}.get(expression, (0, 0))
    for side in (-1, 1):
        bx = side * ex
        # eyebrow: inner end raised for worried/sad, lowered for angry/sly
        inner, outer = (bx - side * 14, ey + 28 + brow[0]), (bx + side * 14, ey + 28 + brow[1] * 0.4)
        line([inner, outer], hc if c["hair"] != "bun" else (40, 28, 24), 6)
        if blink or (expression == "happy" and mouth < 0.1 and False):
            line([(bx - 11, ey), (bx + 11, ey)], OUTLINE, 5)
        elif expression == "sly":
            ell(bx - 12, ey + 5, bx + 12, ey - 7, (255, 255, 255), w=3)
            ell(bx - 5 + 3, ey + 3, bx + 5 + 3, ey - 6, OUTLINE, w=1)
        else:
            big = 1.35 if expression == "shocked" else 1.0
            ell(bx - 12 * big, ey + 13 * big, bx + 12 * big, ey - 13 * big, (255, 255, 255), w=3)
            ell(bx - 6, ey + 5, bx + 6, ey - 7, OUTLINE, w=1)
            ell(bx - 1, ey + 3, bx + 3, ey - 1, (255, 255, 255), outline=None)
            if female:  # eyelashes
                line([(bx + side * 10, ey + 10), (bx + side * 20, ey + 17)], OUTLINE, 4)
                line([(bx + side * 4, ey + 13), (bx + side * 9, ey + 22)], OUTLINE, 4)
    if c.get("glasses"):
        for side in (-1, 1):
            d.ellipse(_box(P(side * ex - 20, ey + 18), P(side * ex + 20, ey - 18)), outline=(40, 40, 40),
                      width=int(4 * s))
        line([(-8, ey + 2), (8, ey + 2)], (40, 40, 40), 4)

    # nose
    line([(4, 500), (10, 480), (2, 476)], _shade(skin, 0.75), 4)
    if c.get("bindi"):
        ell(-5, 552, 5, 542, (200, 30, 50), outline=None)
    if female and expression in ("happy", "relieved"):
        ell(-56, 480, -36, 466, (240, 140, 140), outline=None)
        ell(36, 480, 56, 466, (240, 140, 140), outline=None)
    if c.get("stubble"):
        d.chord(_box(P(-58, 500), P(58, 438)), 0, 180, fill=_shade(skin, 0.8))
    if c.get("mustache"):
        poly([(-30, 468), (0, 476), (30, 468), (24, 458), (0, 464), (-24, 458)], (60, 56, 54), w=2)

    # mouth
    my = 455
    if mouth > 0.08:
        h = 6 + 22 * mouth
        ell(-16 - 4 * mouth, my + h / 2, 16 + 4 * mouth, my - h / 2, (120, 30, 40), w=3)
        ell(-9, my - h / 2 + 7, 9, my - h / 2, (230, 110, 120), outline=None)
    elif expression in ("happy", "relieved"):
        d.chord(_box(P(-22, my + 12), P(22, my - 16)), 0, 180, fill=(120, 30, 40), outline=OUTLINE,
                width=int(3 * s))
    elif expression == "shocked":
        ell(-11, my + 14, 11, my - 14, (120, 30, 40), w=3)
    elif expression in ("worried", "sad"):
        d.arc(_box(P(-18, my - 2), P(18, my - 22)), 180, 360, fill=OUTLINE, width=int(5 * s))
    elif expression == "sly":
        line([(-18, my), (6, my - 2), (20, my + 8)], OUTLINE, 5)
    elif expression == "angry":
        line([(-16, my - 4), (16, my - 4)], OUTLINE, 6)
    else:
        d.arc(_box(P(-16, my + 10), P(16, my - 8)), 20, 160, fill=OUTLINE, width=int(5 * s))

    if expression == "sad":  # tear
        ell(ex + 2, ey - 14, ex + 12, ey - 30, (120, 190, 255), outline=None)

    # ---- right arm in front for phone / facepalm poses, plus props
    if pose in ("phone", "facepalm"):
        arm(sr, re, rh)
    if pose == "phone":
        px, py = rh
        rrect(px - 14, py + 46, px + 14, py - 8, 6, (20, 20, 24), w=2)
    if prop == "phone_hand":
        px, py = rh
        rrect(px - 16, py + 50, px + 16, py - 4, 6, (20, 20, 24), w=2)

    layer = layer.resize((W // ss, H // ss), Image.LANCZOS)
    img.alpha_composite(layer, (int(x - W / ss / 2), int(ground_y - gy / ss)))


def _box(a, b):
    return (min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))
