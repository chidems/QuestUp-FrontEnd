#!/usr/bin/env python3
"""QuestUp avatar concept v4 — unisex chibi base + RPG outfits, 80x120.

One shared base body (chibi proportions, ~2.3 heads tall, matching the
in-app avatar layering: body -> bottoms -> tops -> eyes -> hair) with a
neutral face. Masculine / feminine reads come from hair, brows, mouth
and clothing only. Exports the bare base layer plus two dressed heroes.

Run: python3 gen_avatar_concept_v4.py <outdir>
"""
import sys
import numpy as np
from PIL import Image

W, H = 80, 120
CX = 39

WHITE = (250, 248, 242)
GOLD = (232, 190, 96)
GOLD_DK = (170, 128, 56)

SKIN = dict(
    skin=(246, 205, 164), skin_lt=(252, 226, 194),
    skin_sh=(224, 168, 124), skin_dk=(186, 125, 92), skin_ln=(138, 84, 64),
    blush=(242, 158, 134),
    brief=(96, 98, 112), brief_sh=(70, 72, 84), brief_ln=(48, 50, 60),
)
LEATHER = dict(
    lth=(134, 96, 60), lth_lt=(168, 128, 84),
    lth_sh=(100, 68, 44), lth_dk=(76, 50, 32), lth_ln=(54, 36, 24),
)

MALE = dict(
    SKIN, **LEATHER,
    hair=(88, 60, 46), hair_lt=(120, 86, 64), hair_hi=(156, 118, 86),
    hair_dk=(62, 42, 32), hair_ln=(40, 28, 20),
    iris=(96, 138, 186), iris_lt=(150, 186, 222), iris_dk=(50, 80, 128),
    tunic=(66, 140, 130), tunic_lt=(100, 176, 162),
    tunic_sh=(46, 104, 98), tunic_ln=(28, 68, 64),
    pants=(84, 86, 100), pants_lt=(108, 110, 126),
    pants_sh=(62, 64, 78), pants_ln=(42, 44, 56),
    under=(238, 226, 204),
)

FEMALE = dict(
    SKIN, **LEATHER,
    hair=(214, 168, 86), hair_lt=(236, 198, 122), hair_hi=(248, 224, 162),
    hair_dk=(172, 126, 60), hair_ln=(120, 84, 40),
    iris=(92, 150, 84), iris_lt=(150, 202, 120), iris_dk=(44, 88, 50),
    blouse=(238, 226, 204), blouse_lt=(250, 242, 226),
    blouse_sh=(206, 186, 158), blouse_ln=(150, 130, 104),
    bodice=(160, 60, 66), bodice_lt=(198, 94, 94),
    bodice_sh=(118, 42, 50), bodice_ln=(80, 28, 36),
    skirt=(60, 112, 106), skirt_lt=(90, 144, 134),
    skirt_sh=(42, 82, 80), skirt_ln=(26, 56, 52),
    tights=(84, 86, 100), tights_sh=(62, 64, 78), tights_ln=(42, 44, 56),
)


def canvas():
    img = np.zeros((H, W, 4), np.uint8)

    def px(x, y, c):
        if 0 <= x < W and 0 <= y < H:
            img[y, x] = (*c, 255)

    def hspan(y, x0, x1, c):
        for x in range(x0, x1 + 1):
            px(x, y, c)

    def sym(y, hw, c):
        hspan(y, CX - hw, CX + hw, c)

    def get(x, y):
        if 0 <= x < W and 0 <= y < H and img[y, x, 3] > 0:
            return tuple(img[y, x, :3])
        return None

    def runs_of(y, colors):
        out, start = [], None
        for x in range(W):
            m = get(x, y) in colors
            if m and start is None:
                start = x
            elif not m and start is not None:
                out.append((start, x - 1))
                start = None
        if start is not None:
            out.append((start, W - 1))
        return out

    def shade_right(colors, y0, y1, depth, sc):
        for y in range(y0, y1 + 1):
            for a, b in runs_of(y, colors):
                for x in range(max(a, b - depth + 1), b + 1):
                    px(x, y, sc)

    def light_left(colors, y0, y1, depth, lc):
        for y in range(y0, y1 + 1):
            for a, b in runs_of(y, colors):
                for x in range(a, min(b, a + depth - 1) + 1):
                    px(x, y, lc)

    return dict(img=img, px=px, hspan=hspan, sym=sym, get=get,
                shade_right=shade_right, light_left=light_left)


def outline(img, p, extra=()):
    OUT = {}
    fams = [
        (('skin', 'skin_lt', 'skin_sh', 'skin_dk', 'blush'), 'skin_ln'),
        (('hair', 'hair_lt', 'hair_hi', 'hair_dk'), 'hair_ln'),
        (('lth', 'lth_lt', 'lth_sh', 'lth_dk'), 'lth_ln'),
        (('brief', 'brief_sh'), 'brief_ln'),
    ] + list(extra)
    for keys, ln in fams:
        for k in keys:
            if k in p:
                OUT[p[k]] = p[ln]
    OUT[GOLD] = GOLD_DK
    OUT[GOLD_DK] = GOLD_DK
    mask = img[:, :, 3] > 0
    edge = mask & ~(np.roll(mask, 1, 0) & np.roll(mask, -1, 0)
                    & np.roll(mask, 1, 1) & np.roll(mask, -1, 1))
    ys, xs = np.nonzero(edge)
    for y, x in zip(ys, xs):
        c = tuple(img[y, x, :3])
        img[y, x] = (*OUT.get(c, p['skin_ln']), 255)
    return img


# ================= shared neutral face + chibi base body =================
def draw_face(c, p):
    px, sym, hspan = c['px'], c['sym'], c['hspan']
    FACE = {14: 12, 15: 14, 16: 15, 17: 16, 18: 17, 19: 17, 20: 18}
    for y in range(21, 33):
        FACE[y] = 18
    FACE.update({33: 17, 34: 17, 35: 16, 36: 15, 37: 14, 38: 13, 39: 11,
                 40: 9, 41: 7, 42: 5})
    for y, hw in FACE.items():
        sym(y, hw, p['skin'])
    sym(43, 3, p['skin'])
    c['light_left']([p['skin']], 15, 42, 2, p['skin_lt'])
    c['shade_right']([p['skin']], 15, 42, 3, p['skin_sh'])
    hspan(42, CX, CX + 4, p['skin_sh'])
    hspan(43, CX - 1, CX + 2, p['skin_sh'])


def draw_body(c, p):
    """Unisex chibi body: short neck, stubby torso, arms, legs, feet."""
    px, sym, hspan = c['px'], c['sym'], c['hspan']
    # neck
    for y in range(44, 52):
        sym(y, 5, p['skin'])
    for y in range(44, 48):
        sym(y, 5, p['skin_sh'])
    # torso
    for y in range(52, 78):
        sym(y, 12, p['skin'])
    # arms (separated from torso, paper-doll style)
    for y in range(53, 73):
        hspan(y, CX - 17, CX - 14, p['skin'])
        hspan(y, CX + 14, CX + 17, p['skin'])
    # hands
    for y in range(73, 79):
        hspan(y, CX - 18, CX - 14, p['skin'])
        hspan(y, CX + 14, CX + 18, p['skin'])
    # legs
    for y in range(78, 93):
        hspan(y, CX - 10, CX - 2, p['skin'])
        hspan(y, CX + 2, CX + 10, p['skin'])
    # feet
    for y in range(93, 104):
        hspan(y, CX - 11, CX - 2, p['skin'])
        hspan(y, CX + 2, CX + 11, p['skin'])
    c['shade_right']([p['skin']], 48, 103, 2, p['skin_sh'])
    c['light_left']([p['skin']], 52, 92, 1, p['skin_lt'])


def draw_briefs(c, p):
    px, sym, hspan = c['px'], c['sym'], c['hspan']
    for y in range(75, 80):
        sym(y, 11, p['brief'])
    for y in range(80, 83):
        hspan(y, CX - 10, CX - 2, p['brief'])
        hspan(y, CX + 2, CX + 10, p['brief'])
    sym(75, 11, p['brief_sh'])
    c['shade_right']([p['brief']], 75, 82, 2, p['brief_sh'])


EYE = [
    ".kkkkkkkk.",
    "kWiCCiipWk",
    "kWiCCiipWk",
    "kWiiiiipWk",
    "kWIIIIIIWk",
    "..tttttt..",
]


def draw_eyes(c, p, ey=25):
    px = c['px']
    def one(ox):
        for dy, row in enumerate(EYE):
            for dx, ch in enumerate(row):
                col = {'k': p['skin_ln'], 'W': WHITE, 'C': WHITE,
                       'i': p['iris'], 't': p['skin_dk'],
                       'I': p['iris_lt'], 'p': p['iris_dk']}.get(ch)
                if col:
                    px(ox + dx, ey + dy, col)
    one(CX - 16)
    one(CX + 7)


# ============================================================ MALE
def draw_male(p):
    c = canvas()
    px, hspan, sym, get = c['px'], c['hspan'], c['sym'], c['get']
    shade_right, light_left = c['shade_right'], c['light_left']

    draw_face(c, p)
    draw_body(c, p)

    # ---- tunic ----
    for y in range(52, 74):
        sym(y, 13, p['tunic'])
    for y, hw in [(52, 6), (53, 5), (54, 4), (55, 3), (56, 2), (57, 1)]:
        sym(y, hw, p['under'])                        # V-neck undershirt
    for y, hw in [(52, 7), (53, 6), (54, 5), (55, 4), (56, 3), (57, 2)]:
        px(CX - hw, y, p['tunic_sh'])
        px(CX + hw, y, p['tunic_sh'])
    shade_right([p['tunic']], 52, 73, 3, p['tunic_sh'])
    light_left([p['tunic']], 52, 62, 2, p['tunic_lt'])

    # ---- sleeves ----
    for y in range(53, 64):
        w = 18 if y > 55 else (16 if y == 53 else 17)
        hspan(y, CX - w, CX - 13, p['tunic'])
        hspan(y, CX + 13, CX + w, p['tunic'])
    hspan(63, CX - 18, CX - 13, p['tunic_sh'])
    hspan(63, CX + 13, CX + 18, p['tunic_sh'])
    shade_right([p['tunic']], 53, 63, 2, p['tunic_sh'])

    # ---- leather jerkin ----
    for y in range(58, 74):
        hspan(y, CX - 12, CX - 5, p['lth'])
        hspan(y, CX + 5, CX + 12, p['lth'])
    for y in range(70, 74):
        sym(y, 12, p['lth'])
    for y in range(58, 70):
        px(CX - 5, y, p['lth_dk'])
        px(CX + 5, y, p['lth_dk'])
    for y in (61, 65):                                # lacing bars
        hspan(y, CX - 4, CX + 4, p['lth_dk'])
        px(CX - 4, y - 1, GOLD_DK)
        px(CX + 4, y - 1, GOLD_DK)
    shade_right([p['lth']], 58, 73, 2, p['lth_sh'])
    light_left([p['lth']], 58, 66, 1, p['lth_lt'])

    # ---- pauldrons ----
    for y, (a, b) in {52: (11, 16), 53: (10, 18), 54: (10, 19),
                      55: (10, 19), 56: (11, 19), 57: (12, 18)}.items():
        hspan(y, CX - b, CX - a, p['lth'])
        hspan(y, CX + a, CX + b, p['lth'])
    hspan(53, CX - 17, CX - 11, p['lth_lt'])
    hspan(53, CX + 11, CX + 17, p['lth_lt'])
    hspan(57, CX - 18, CX - 12, p['lth_dk'])
    hspan(57, CX + 12, CX + 18, p['lth_dk'])
    px(CX - 14, 54, GOLD)                             # rivets
    px(CX + 14, 54, GOLD)

    # ---- bracers ----
    for y in range(64, 73):
        hspan(y, CX - 18, CX - 14, p['lth'])
        hspan(y, CX + 14, CX + 18, p['lth'])
    hspan(64, CX - 18, CX - 14, p['lth_lt'])
    hspan(64, CX + 14, CX + 18, p['lth_lt'])
    for sy in (67, 71):                               # straps
        hspan(sy, CX - 18, CX - 14, p['lth_dk'])
        hspan(sy, CX + 14, CX + 18, p['lth_dk'])
    shade_right([p['lth']], 64, 72, 1, p['lth_sh'])

    # ---- belt + buckle + pouch ----
    for y in range(74, 78):
        sym(y, 13, p['lth_dk'])
    hspan(74, CX - 13, CX + 13, p['lth_sh'])
    for x in range(CX - 2, CX + 3):
        px(x, 75, GOLD)
        px(x, 76, GOLD)
    px(CX, 76, GOLD_DK)
    for y in range(77, 85):                           # hip pouch (right)
        hspan(y, CX + 7, CX + 13, p['lth'])
    for y in range(77, 80):
        hspan(y, CX + 7, CX + 13, p['lth_lt'])
    px(CX + 10, 80, GOLD_DK)
    shade_right([p['lth']], 77, 84, 1, p['lth_sh'])

    # ---- pants ----
    for y in range(78, 84):
        sym(y, 12, p['pants'])
    for y in range(84, 94):
        hspan(y, CX - 11, CX - 2, p['pants'])
        hspan(y, CX + 2, CX + 11, p['pants'])
    hspan(88, CX - 9, CX - 6, p['pants_sh'])          # knee folds
    hspan(88, CX + 5, CX + 8, p['pants_sh'])
    px(CX - 5, 89, p['pants_ln'])
    px(CX + 9, 89, p['pants_ln'])
    shade_right([p['pants']], 78, 93, 2, p['pants_sh'])
    light_left([p['pants']], 79, 91, 1, p['pants_lt'])

    # ---- boots ----
    for y in range(93, 100):
        hspan(y, CX - 11, CX - 2, p['lth'])
        hspan(y, CX + 2, CX + 11, p['lth'])
    for y in range(93, 96):                           # folded top band
        hspan(y, CX - 12, CX - 1, p['lth_lt'])
        hspan(y, CX + 1, CX + 12, p['lth_lt'])
    hspan(95, CX - 12, CX - 1, p['lth_dk'])
    hspan(95, CX + 1, CX + 12, p['lth_dk'])
    hspan(98, CX - 11, CX - 2, p['lth_dk'])           # ankle strap
    hspan(98, CX + 2, CX + 11, p['lth_dk'])
    px(CX - 6, 98, GOLD)
    px(CX + 6, 98, GOLD)
    for y in range(100, 104):                         # foot
        hspan(y, CX - 12, CX - 2, p['lth'])
        hspan(y, CX + 2, CX + 12, p['lth'])
    hspan(100, CX - 12, CX - 8, p['lth_lt'])
    hspan(100, CX + 4, CX + 8, p['lth_lt'])
    for y in range(104, 106):                         # sole
        hspan(y, CX - 12, CX - 2, p['lth_dk'])
        hspan(y, CX + 2, CX + 12, p['lth_dk'])
    shade_right([p['lth']], 93, 103, 2, p['lth_sh'])

    # ---- hair: swept spiky crown ----
    TOP = {-19: 9, -18: 7, -17: 5, -16: 4, -15: 3, -14: 2, -13: 3,
           -12: 4, -11: 2, -10: 1, -9: 0, -8: 1, -7: 2, -6: 1, -5: 0,
           -4: 1, -3: 2, -2: 1, -1: 0, 0: 1, 1: 2, 2: 3, 3: 2, 4: 1,
           5: 2, 6: 3, 7: 4, 8: 3, 9: 2, 10: 3, 11: 4, 12: 5, 13: 4,
           14: 5, 15: 6, 16: 7, 17: 8, 18: 9, 19: 11}
    FRDEPTH = {-19: 30, -18: 32, -17: 28, -16: 24, -15: 20, -14: 22,
               -13: 18, -12: 16, -11: 18, -10: 20, -9: 17, -8: 15,
               -7: 17, -6: 19, -5: 16, -4: 15, -3: 17, -2: 19, -1: 16,
               0: 15, 1: 17, 2: 19, 3: 21, 4: 18, 5: 16, 6: 18, 7: 20,
               8: 22, 9: 19, 10: 17, 11: 19, 12: 21, 13: 23, 14: 25,
               15: 22, 16: 24, 17: 27, 18: 30, 19: 33}
    for dx in range(-19, 20):
        for y in range(TOP[dx], FRDEPTH[dx] + 1):
            px(CX + dx, y, p['hair'])
        px(CX + dx, FRDEPTH[dx], p['hair_dk'])
    for y in range(12, 40):                           # side volume
        w = 3 if y < 30 else 2
        hspan(y, CX - 22, CX - 22 + w, p['hair'])
        hspan(y, CX + 22 - w, CX + 22, p['hair'])
    for y in range(36, 42):
        px(CX - 20, y, p['hair'])
        px(CX + 20, y, p['hair_dk'])
    for sx in (-11, -4, 3, 10):                       # strand separators
        for d in range(4):
            px(CX + sx + d // 2, 11 + d, p['hair_dk'])
    for x, y in [(-13, 4), (-12, 4), (-11, 5), (-10, 4), (-9, 4), (-5, 5),
                 (-4, 6), (-3, 5), (-2, 4), (2, 4), (3, 5), (4, 6), (5, 5),
                 (9, 6), (10, 6), (11, 7), (12, 8), (15, 8), (16, 9)]:
        px(CX + x, y, p['hair_hi'])
    for x, y in [(-16, 6), (-15, 6), (-14, 5), (-7, 6), (-6, 7), (0, 6),
                 (1, 7), (7, 7), (8, 8), (13, 9), (14, 10)]:
        px(CX + x, y, p['hair_lt'])
    shade_right([p['hair'], p['hair_dk']], 0, 41, 3, p['hair_dk'])
    light_left([p['hair']], 2, 12, 1, p['hair_lt'])
    for dx in range(-19, 20):                         # fringe shadow
        cc = get(CX + dx, FRDEPTH[dx] + 1)
        if cc in (p['skin'], p['skin_lt'], p['skin_sh']):
            px(CX + dx, FRDEPTH[dx] + 1, p['skin_sh'])

    # ---- face features (masculine) ----
    draw_eyes(c, p)
    hspan(22, CX - 15, CX - 8, p['hair_dk'])          # thick brows
    hspan(23, CX - 15, CX - 8, p['hair_dk'])
    hspan(22, CX + 8, CX + 15, p['hair_dk'])
    hspan(23, CX + 8, CX + 15, p['hair_dk'])
    for y in range(33, 36):                            # nose
        px(CX + 1, y, p['skin_dk'])
    px(CX, 36, p['skin_sh'])
    hspan(39, CX - 3, CX + 3, p['skin_ln'])           # mouth
    px(CX - 4, 38, p['skin_dk'])
    px(CX + 4, 38, p['skin_dk'])
    hspan(40, CX - 2, CX + 2, p['skin_sh'])

    return outline(c['img'], p, extra=[
        (('tunic', 'tunic_lt', 'tunic_sh'), 'tunic_ln'),
        (('pants', 'pants_lt', 'pants_sh'), 'pants_ln'),
        (('under',), 'tunic_ln'),
    ])


# ============================================================ FEMALE
def draw_female(p):
    c = canvas()
    px, hspan, sym, get = c['px'], c['hspan'], c['sym'], c['get']
    shade_right, light_left = c['shade_right'], c['light_left']

    draw_face(c, p)
    draw_body(c, p)

    # ---- blouse (scoop neckline + puff sleeves) ----
    for y in range(50, 64):
        sym(y, 13, p['blouse'])
    for y, hw in [(50, 5), (51, 4)]:                  # neckline scoop
        sym(y, hw, p['skin'])
    px(CX - 6, 50, p['blouse_sh'])
    px(CX + 6, 50, p['blouse_sh'])
    hspan(52, CX - 4, CX + 4, p['blouse_sh'])
    px(CX - 5, 51, p['blouse_sh'])
    px(CX + 5, 51, p['blouse_sh'])
    for y in range(52, 63):                           # puff sleeves
        w = 18 if 54 <= y <= 60 else 17
        hspan(y, CX - w, CX - 13, p['blouse'])
        hspan(y, CX + 13, CX + w, p['blouse'])
    hspan(62, CX - 17, CX - 13, p['blouse_sh'])       # cuff gather
    hspan(62, CX + 13, CX + 17, p['blouse_sh'])
    shade_right([p['blouse']], 50, 62, 2, p['blouse_sh'])
    light_left([p['blouse']], 50, 58, 2, p['blouse_lt'])

    # ---- corset bodice ----
    BOD = {63: 13, 64: 13, 65: 12, 66: 12, 67: 12, 68: 11, 69: 11,
           70: 11, 71: 11, 72: 11, 73: 11}
    for y, hw in BOD.items():
        sym(y, hw, p['bodice'])
    sym(63, 13, p['bodice_lt'])                       # top trim
    for y in range(65, 73, 3):                        # front lacing
        hspan(y, CX - 2, CX + 2, p['bodice_lt'])
        px(CX - 3, y + 1, p['bodice_sh'])
        px(CX + 3, y + 1, p['bodice_sh'])
    for y in range(64, 73):
        px(CX, y, p['bodice_sh'])
    shade_right([p['bodice']], 63, 73, 2, p['bodice_sh'])
    light_left([p['bodice']], 63, 70, 1, p['bodice_lt'])

    # ---- belt + side pouch ----
    for y in range(74, 77):
        sym(y, 12, p['lth_dk'])
    hspan(74, CX - 12, CX + 12, p['lth_sh'])
    for x in (CX - 1, CX, CX + 1):
        px(x, 75, GOLD)
    for y in range(77, 84):                           # pouch (left hip)
        hspan(y, CX - 13, CX - 8, p['lth'])
    for y in range(77, 80):
        hspan(y, CX - 13, CX - 8, p['lth_lt'])
    px(CX - 10, 80, GOLD_DK)
    shade_right([p['lth']], 77, 83, 1, p['lth_sh'])

    # ---- flared skirt ----
    SK = {77: 12, 78: 13, 79: 13, 80: 14, 81: 14, 82: 15, 83: 15,
          84: 16, 85: 16, 86: 17, 87: 17, 88: 18, 89: 18}
    for y, hw in SK.items():
        sym(y, hw, p['skirt'])
    for fx, y0, y1 in [(-9, 79, 85), (-3, 82, 88), (3, 78, 84),
                       (9, 81, 88)]:                  # staggered folds
        for y in range(y0, y1 + 1):
            px(CX + fx + (y - y0) // 5, y, p['skirt_sh'])
    sym(88, 18, p['skirt_lt'])                        # hem trim
    sym(89, 18, p['skirt_sh'])
    shade_right([p['skirt']], 77, 89, 3, p['skirt_sh'])
    light_left([p['skirt']], 77, 87, 2, p['skirt_lt'])

    # ---- tights ----
    for y in range(90, 97):
        hspan(y, CX - 10, CX - 2, p['tights'])
        hspan(y, CX + 2, CX + 10, p['tights'])
    shade_right([p['tights']], 90, 96, 2, p['tights_sh'])

    # ---- knee boots ----
    for y in range(95, 100):
        hspan(y, CX - 10, CX - 2, p['lth'])
        hspan(y, CX + 2, CX + 10, p['lth'])
    for y in range(95, 97):                           # top band
        hspan(y, CX - 11, CX - 1, p['lth_lt'])
        hspan(y, CX + 1, CX + 11, p['lth_lt'])
    hspan(96, CX - 11, CX - 1, p['lth_dk'])
    hspan(96, CX + 1, CX + 11, p['lth_dk'])
    for y in range(100, 104):                         # foot
        hspan(y, CX - 11, CX - 2, p['lth'])
        hspan(y, CX + 2, CX + 11, p['lth'])
    hspan(100, CX - 11, CX - 8, p['lth_lt'])
    hspan(100, CX + 4, CX + 7, p['lth_lt'])
    for y in range(104, 106):                         # sole
        hspan(y, CX - 11, CX - 2, p['lth_dk'])
        hspan(y, CX + 2, CX + 11, p['lth_dk'])
    shade_right([p['lth']], 95, 103, 2, p['lth_sh'])

    # ---- hair: crown, curtain fringe, falls, braid ----
    CAP = {0: 10, 1: 13, 2: 15, 3: 16, 4: 17, 5: 18, 6: 19, 7: 19,
           8: 20, 9: 20, 10: 20, 11: 20, 12: 20, 13: 20}
    for y, hw in CAP.items():
        sym(y, hw, p['hair'])
    PART = 2
    WISP = {-9: 2, -3: 1, 4: 2, 9: 1, -6: -1, 7: -1}
    def fdepth(dx):
        return min(19 + abs(dx - PART) + WISP.get(dx, 0), 27)
    for dx in range(-18, 19):
        depth = fdepth(dx)
        for y in range(9, depth + 1):
            px(CX + dx, y, p['hair'])
        px(CX + dx, depth, p['hair_dk'])
    for y in range(12, 59):                           # long falls
        w0, w1 = 19, 23
        if y > 50:
            w0 = 20
        hspan(y, CX - w1, CX - w0, p['hair'])
        hspan(y, CX + w0, CX + w1, p['hair'])
    for x, yend in [(-23, 58), (-22, 62), (-21, 59), (-20, 63),
                    (20, 62), (21, 58), (22, 63), (23, 59)]:
        for y in range(54, yend + 1):
            px(CX + x, y, p['hair'])
        px(CX + x, yend, p['hair_dk'])
    for y in range(26, 41):                           # face-framing strands
        px(CX - 17, y, p['hair'])
    px(CX - 17, 40, p['hair_dk'])
    for y in range(26, 38):
        px(CX + 17, y, p['hair'])
    px(CX + 17, 37, p['hair_dk'])
    # side braid (viewer left)
    for y in range(30, 71):
        hspan(y, CX - 27, CX - 24, p['hair'])
    for y in range(30, 71):
        seg = (y - 30) % 6
        if seg in (0, 1):
            hspan(y, CX - 27, CX - 26, p['hair_lt'])
            px(CX - 24, y, p['hair_dk'])
        elif seg in (3, 4):
            hspan(y, CX - 25, CX - 24, p['hair_lt'])
            px(CX - 27, y, p['hair_dk'])
    for y in (71, 72):                                # tie
        hspan(y, CX - 27, CX - 24, p['lth_dk'])
    for y, (a, b) in {73: (27, 24), 74: (26, 24), 75: (26, 25)}.items():
        hspan(y, CX - a, CX - b, p['hair'])
    px(CX - 26, 76, p['hair_dk'])
    # sheen
    for x, y in [(-14, 3), (-13, 3), (-12, 4), (-11, 4), (-10, 5), (-6, 4),
                 (-5, 5), (-4, 5), (0, 4), (1, 4), (5, 3), (6, 4), (7, 4),
                 (8, 5), (12, 5), (13, 6)]:
        px(CX + x, y, p['hair_hi'])
    for x, y in [(-17, 5), (-16, 5), (-15, 4), (-8, 6), (-7, 6), (3, 5),
                 (4, 5), (10, 6), (11, 6), (15, 7), (16, 8)]:
        px(CX + x, y, p['hair_lt'])
    for y in range(28, 40):                           # sheen on falls
        px(CX - 22, y, p['hair_lt'])
        px(CX + 21, y, p['hair_lt'])
    for y in range(31, 36):
        px(CX - 21, y, p['hair_hi'])
        px(CX + 22, y, p['hair_hi'])
    for sx in (-12, -6, -1, 6, 12):                   # strand separators
        for y in range(15, 20):
            px(CX + sx, y, p['hair_dk'])
    for sx in (-10, -4, 2, 8):
        for y in range(14, 18):
            px(CX + sx, y, p['hair_lt'])
    shade_right([p['hair'], p['hair_dk']], 0, 76, 2, p['hair_dk'])
    light_left([p['hair']], 1, 10, 1, p['hair_lt'])
    for dx in range(-18, 19):                         # fringe shadow
        cc = get(CX + dx, fdepth(dx) + 1)
        if cc in (p['skin'], p['skin_lt'], p['skin_sh']):
            px(CX + dx, fdepth(dx) + 1, p['skin_sh'])

    # ---- face features (feminine) ----
    draw_eyes(c, p)
    px(CX - 17, 26, p['skin_ln'])                     # lash flicks
    px(CX + 17, 26, p['skin_ln'])
    hspan(23, CX - 14, CX - 8, p['hair_dk'])          # thin brows
    hspan(23, CX + 8, CX + 14, p['hair_dk'])
    px(CX + 1, 35, p['skin_dk'])                      # petite nose
    px(CX, 36, p['skin_sh'])
    hspan(39, CX - 1, CX + 1, p['skin_ln'])           # smile
    px(CX - 2, 38, p['skin_dk'])
    px(CX + 2, 38, p['skin_dk'])
    hspan(40, CX - 1, CX + 1, p['blush'])             # soft lower lip
    for x, y in [(-15, 33), (-14, 34), (-13, 33), (13, 33), (14, 34),
                 (15, 33)]:
        px(CX + x, y, p['blush'])

    return outline(c['img'], p, extra=[
        (('blouse', 'blouse_lt', 'blouse_sh'), 'blouse_ln'),
        (('bodice', 'bodice_lt', 'bodice_sh'), 'bodice_ln'),
        (('skirt', 'skirt_lt', 'skirt_sh'), 'skirt_ln'),
        (('tights', 'tights_sh'), 'tights_ln'),
    ])


# ============================================================ BASE
def draw_base(p):
    """Bare unisex body layer: neutral face, no eyes, no hair, briefs.
    Matches the app's sprite layering (eyes + hair are separate layers)."""
    c = canvas()
    draw_face(c, p)
    draw_body(c, p)
    draw_briefs(c, p)
    return outline(c['img'], p)


if __name__ == '__main__':
    outdir = sys.argv[1] if len(sys.argv) > 1 else '.'
    base = draw_base(dict(SKIN))
    male = draw_male(MALE)
    female = draw_female(FEMALE)
    for name, im in [('base', base), ('male', male), ('female', female)]:
        Image.fromarray(im).save(f'{outdir}/avatar_concept_v4_{name}_1x.png')
        Image.fromarray(im).resize((W * 5, H * 5), Image.NEAREST).save(
            f'{outdir}/avatar_concept_v4_{name}_5x.png')
    trio = Image.new('RGBA', ((W + 6) * 3 * 5, H * 5), (0, 0, 0, 0))
    for i, im in enumerate([base, male, female]):
        trio.alpha_composite(
            Image.fromarray(im).resize((W * 5, H * 5), Image.NEAREST),
            (i * (W + 6) * 5, 0))
    trio.save(f'{outdir}/avatar_concept_v4_trio.png')
    print('saved v4 concept images to', outdir)
