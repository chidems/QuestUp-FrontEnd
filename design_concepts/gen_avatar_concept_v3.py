#!/usr/bin/env python3
"""QuestUp avatar concept v3 — RPG adventurer duo, 96x144 native.

Masculine + feminine heroes with fantasy gear (tunic + leather jerkin,
pauldrons, bracers, belt pouch / blouse + corset bodice, flared skirt,
knee boots), complex layered hair (swept spikes / long falls + braid),
selective per-material outlines.

Run: python3 gen_avatar_concept_v3.py <outdir>
"""
import sys
import numpy as np
from PIL import Image

W, H = 96, 144
CX = 47

WHITE = (250, 248, 242)
GOLD = (232, 190, 96)
GOLD_DK = (170, 128, 56)

SKIN = dict(
    skin=(246, 205, 164), skin_lt=(252, 226, 194),
    skin_sh=(224, 168, 124), skin_dk=(186, 125, 92), skin_ln=(138, 84, 64),
    blush=(242, 158, 134),
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

    return img, px, hspan, sym, get, runs_of, shade_right, light_left


def outline(img, p, extra=()):
    OUT = {}
    fams = [
        (('skin', 'skin_lt', 'skin_sh', 'skin_dk', 'blush'), 'skin_ln'),
        (('hair', 'hair_lt', 'hair_hi', 'hair_dk'), 'hair_ln'),
        (('lth', 'lth_lt', 'lth_sh', 'lth_dk'), 'lth_ln'),
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


EYE = [
    ".kkkkkkkk.",
    "kWiCCiipWk",
    "kWiCCiipWk",
    "kWiiiiipWk",
    "kWIIIIIIWk",
    "..tttttt..",
]


def draw_eyes(px, hspan, p, ey):
    def one(ox):
        for dy, row in enumerate(EYE):
            for dx, ch in enumerate(row):
                c = {'k': p['skin_ln'], 'W': WHITE, 'C': WHITE,
                     'i': p['iris'], 't': p['skin_dk'],
                     'I': p['iris_lt'], 'p': p['iris_dk']}.get(ch)
                if c:
                    px(ox + dx, ey + dy, c)
    one(CX - 16)
    one(CX + 7)


# ============================================================ MALE
def draw_male(p):
    img, px, hspan, sym, get, runs_of, shade_right, light_left = canvas()

    # ---- face: square jaw ----
    FACE = {14: 13, 15: 15, 16: 16, 17: 17, 18: 18, 19: 18, 20: 19}
    for y in range(21, 34):
        FACE[y] = 19
    FACE.update({34: 18, 35: 18, 36: 18, 37: 17, 38: 17, 39: 16, 40: 15,
                 41: 13, 42: 11, 43: 8})
    for y, hw in FACE.items():
        sym(y, hw, p['skin'])
    sym(44, 5, p['skin'])
    sym(45, 4, p['skin'])
    light_left([p['skin']], 15, 44, 2, p['skin_lt'])
    shade_right([p['skin']], 15, 44, 3, p['skin_sh'])
    hspan(43, CX + 2, CX + 7, p['skin_sh'])          # jaw shading
    hspan(44, CX, CX + 4, p['skin_sh'])
    hspan(45, CX - 1, CX + 3, p['skin_sh'])

    # ---- neck ----
    for y in range(46, 55):
        sym(y, 7, p['skin'])
    for y in range(46, 50):
        sym(y, 7, p['skin_sh'])
    shade_right([p['skin']], 50, 54, 2, p['skin_sh'])

    # ---- torso: tunic ----
    for y in range(54, 84):
        sym(y, 16, p['tunic'])
    # V-neck undershirt
    for y, hw in [(54, 6), (55, 5), (56, 4), (57, 3), (58, 2), (59, 1)]:
        sym(y, hw, p['under'])
    for y, hw in [(54, 7), (55, 6), (56, 5), (57, 4), (58, 3), (59, 2)]:
        px(CX - hw, y, p['tunic_sh'])
        px(CX + hw, y, p['tunic_sh'])
    shade_right([p['tunic']], 54, 83, 3, p['tunic_sh'])
    light_left([p['tunic']], 54, 66, 2, p['tunic_lt'])

    # ---- sleeves ----
    for y in range(55, 70):
        w = 21 if y > 57 else (19 if y == 55 else 20)
        hspan(y, CX - w, CX - 16, p['tunic'])
        hspan(y, CX + 16, CX + w, p['tunic'])
    hspan(69, CX - 21, CX - 16, p['tunic_sh'])
    hspan(69, CX + 16, CX + 21, p['tunic_sh'])
    shade_right([p['tunic']], 55, 69, 2, p['tunic_sh'])

    # ---- leather jerkin over tunic ----
    for y in range(60, 84):
        hspan(y, CX - 15, CX - 6, p['lth'])
        hspan(y, CX + 6, CX + 15, p['lth'])
    for y in range(80, 84):
        sym(y, 15, p['lth'])
    # jerkin front edges + cross lacing
    for y in range(60, 80):
        px(CX - 6, y, p['lth_dk'])
        px(CX + 6, y, p['lth_dk'])
    for y in (63, 68, 73):
        hspan(y, CX - 5, CX + 5, p['lth_dk'])
        px(CX - 5, y - 1, GOLD_DK)
        px(CX + 5, y - 1, GOLD_DK)
    shade_right([p['lth']], 60, 83, 2, p['lth_sh'])
    light_left([p['lth']], 60, 72, 1, p['lth_lt'])

    # ---- pauldrons ----
    for y, (a, b) in {54: (13, 19), 55: (12, 21), 56: (12, 22),
                      57: (12, 22), 58: (13, 22), 59: (14, 21)}.items():
        hspan(y, CX - b, CX - a, p['lth'])
        hspan(y, CX + a, CX + b, p['lth'])
    hspan(55, CX - 20, CX - 14, p['lth_lt'])
    hspan(55, CX + 14, CX + 20, p['lth_lt'])
    hspan(59, CX - 21, CX - 14, p['lth_dk'])
    hspan(59, CX + 14, CX + 21, p['lth_dk'])
    px(CX - 17, 56, GOLD)                             # rivets
    px(CX + 17, 56, GOLD)

    # ---- bracers + hands ----
    for y in range(70, 84):
        hspan(y, CX - 21, CX - 17, p['lth'])
        hspan(y, CX + 17, CX + 21, p['lth'])
    hspan(70, CX - 21, CX - 17, p['lth_lt'])
    hspan(70, CX + 17, CX + 21, p['lth_lt'])
    for sy in (75, 80):                               # straps
        hspan(sy, CX - 21, CX - 17, p['lth_dk'])
        hspan(sy, CX + 17, CX + 21, p['lth_dk'])
    shade_right([p['lth']], 70, 83, 1, p['lth_sh'])
    for y in range(84, 90):
        hspan(y, CX - 21, CX - 17, p['skin'])
        hspan(y, CX + 17, CX + 21, p['skin'])
    shade_right([p['skin']], 84, 89, 1, p['skin_sh'])

    # ---- belt + buckle + pouch ----
    for y in range(84, 89):
        sym(y, 15, p['lth_dk'])
    hspan(84, CX - 15, CX + 15, p['lth_sh'])
    for y in range(84, 89):
        for x in (CX - 2, CX - 1, CX, CX + 1, CX + 2):
            px(x, y, GOLD if y in (85, 86, 87) else GOLD_DK)
    px(CX, 86, GOLD_DK)
    for y in range(88, 98):                           # hip pouch (right)
        hspan(y, CX + 9, CX + 16, p['lth'])
    for y in range(88, 92):
        hspan(y, CX + 9, CX + 16, p['lth_lt'])
    px(CX + 12, 92, GOLD_DK)
    shade_right([p['lth']], 88, 97, 2, p['lth_sh'])

    # ---- pants ----
    for y in range(89, 100):
        sym(y, 14, p['pants'])
    for y in range(100, 116):
        ow = 13 if y < 108 else 12
        hspan(y, CX - ow, CX - 2, p['pants'])
        hspan(y, CX + 2, CX + ow, p['pants'])
    hspan(105, CX - 11, CX - 7, p['pants_sh'])        # knee folds
    hspan(105, CX + 6, CX + 10, p['pants_sh'])
    hspan(106, CX - 8, CX - 5, p['pants_ln'])
    hspan(106, CX + 8, CX + 11, p['pants_ln'])
    shade_right([p['pants']], 89, 115, 2, p['pants_sh'])
    light_left([p['pants']], 90, 112, 1, p['pants_lt'])

    # ---- tall boots ----
    for y in range(114, 132):
        hspan(y, CX - 12, CX - 2, p['lth'])
        hspan(y, CX + 2, CX + 12, p['lth'])
    for y in range(114, 118):                         # folded top band
        hspan(y, CX - 13, CX - 1, p['lth_lt'])
        hspan(y, CX + 1, CX + 13, p['lth_lt'])
    hspan(117, CX - 13, CX - 1, p['lth_dk'])
    hspan(117, CX + 1, CX + 13, p['lth_dk'])
    hspan(124, CX - 12, CX - 2, p['lth_dk'])          # ankle strap
    hspan(124, CX + 2, CX + 12, p['lth_dk'])
    px(CX - 7, 124, GOLD)
    px(CX + 7, 124, GOLD)
    for y in range(132, 138):                         # foot
        hspan(y, CX - 13, CX - 2, p['lth'])
        hspan(y, CX + 2, CX + 13, p['lth'])
    hspan(132, CX - 13, CX - 9, p['lth_lt'])
    hspan(132, CX + 5, CX + 9, p['lth_lt'])
    for y in range(138, 140):                         # sole
        hspan(y, CX - 13, CX - 2, p['lth_dk'])
        hspan(y, CX + 2, CX + 13, p['lth_dk'])
    shade_right([p['lth']], 114, 137, 2, p['lth_sh'])
    light_left([p['lth']], 118, 130, 1, p['lth_lt'])

    # ---- hair: swept spiky crown, fringe swept right ----
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
    # side volume + behind ears
    for y in range(12, 40):
        w = 3 if y < 30 else 2
        hspan(y, CX - 22, CX - 22 + w, p['hair'])
        hspan(y, CX + 22 - w, CX + 22, p['hair'])
    for y in range(36, 42):
        px(CX - 20, y, p['hair'])
        px(CX + 20, y, p['hair_dk'])
    # sweep strand separators (short, in the fringe only)
    for sx in (-11, -4, 3, 10):
        for d in range(4):
            px(CX + sx + d // 2, 11 + d, p['hair_dk'])
    # crown highlight zigzag
    for x, y in [(-13, 4), (-12, 4), (-11, 5), (-10, 4), (-9, 4), (-5, 5),
                 (-4, 6), (-3, 5), (-2, 4), (2, 4), (3, 5), (4, 6), (5, 5),
                 (9, 6), (10, 6), (11, 7), (12, 8), (15, 8), (16, 9)]:
        px(CX + x, y, p['hair_hi'])
    for x, y in [(-16, 6), (-15, 6), (-14, 5), (-7, 6), (-6, 7), (0, 6),
                 (1, 7), (7, 7), (8, 8), (13, 9), (14, 10)]:
        px(CX + x, y, p['hair_lt'])
    shade_right([p['hair'], p['hair_dk']], 0, 41, 3, p['hair_dk'])
    light_left([p['hair']], 2, 12, 1, p['hair_lt'])
    # fringe shadow on forehead
    for dx in range(-19, 20):
        c = get(CX + dx, FRDEPTH[dx] + 1)
        if c in (p['skin'], p['skin_lt'], p['skin_sh']):
            px(CX + dx, FRDEPTH[dx] + 1, p['skin_sh'])

    # ---- face features ----
    draw_eyes(px, hspan, p, 25)
    hspan(22, CX - 15, CX - 8, p['hair_dk'])          # thick brows
    hspan(23, CX - 15, CX - 8, p['hair_dk'])
    hspan(22, CX + 8, CX + 15, p['hair_dk'])
    hspan(23, CX + 8, CX + 15, p['hair_dk'])
    for y in range(34, 37):                            # nose
        px(CX + 1, y, p['skin_dk'])
    px(CX, 37, p['skin_sh'])
    px(CX + 1, 37, p['skin_sh'])
    hspan(40, CX - 3, CX + 3, p['skin_ln'])           # mouth
    px(CX - 4, 39, p['skin_dk'])
    px(CX + 4, 39, p['skin_dk'])
    hspan(41, CX - 2, CX + 2, p['skin_sh'])           # lower lip shadow

    return outline(img, p, extra=[
        (('tunic', 'tunic_lt', 'tunic_sh'), 'tunic_ln'),
        (('pants', 'pants_lt', 'pants_sh'), 'pants_ln'),
        (('under',), 'tunic_ln'),
    ])


# ============================================================ FEMALE
def draw_female(p):
    img, px, hspan, sym, get, runs_of, shade_right, light_left = canvas()

    # ---- face: soft round, tapered chin ----
    FACE = {14: 12, 15: 14, 16: 15, 17: 16, 18: 17, 19: 17, 20: 18}
    for y in range(21, 33):
        FACE[y] = 18
    FACE.update({33: 17, 34: 17, 35: 16, 36: 15, 37: 14, 38: 13, 39: 11,
                 40: 9, 41: 7, 42: 5})
    for y, hw in FACE.items():
        sym(y, hw, p['skin'])
    sym(43, 3, p['skin'])
    light_left([p['skin']], 15, 42, 2, p['skin_lt'])
    shade_right([p['skin']], 15, 42, 3, p['skin_sh'])
    hspan(42, CX, CX + 4, p['skin_sh'])
    hspan(43, CX - 1, CX + 2, p['skin_sh'])

    # ---- neck ----
    for y in range(44, 52):
        sym(y, 5, p['skin'])
    for y in range(44, 48):
        sym(y, 5, p['skin_sh'])
    shade_right([p['skin']], 48, 51, 1, p['skin_sh'])

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
    for y in range(53, 68):
        w = 18 if 55 <= y <= 64 else 17
        hspan(y, CX - w, CX - 13, p['blouse'])
        hspan(y, CX + 13, CX + w, p['blouse'])
    hspan(67, CX - 17, CX - 13, p['blouse_sh'])       # cuff gather
    hspan(67, CX + 13, CX + 17, p['blouse_sh'])
    shade_right([p['blouse']], 52, 67, 2, p['blouse_sh'])
    light_left([p['blouse']], 52, 60, 2, p['blouse_lt'])

    # ---- arms + hands ----
    for y in range(68, 82):
        hspan(y, CX - 17, CX - 14, p['skin'])
        hspan(y, CX + 14, CX + 17, p['skin'])
    for y in range(82, 88):
        hspan(y, CX - 18, CX - 14, p['skin'])
        hspan(y, CX + 14, CX + 18, p['skin'])
    shade_right([p['skin']], 68, 87, 1, p['skin_sh'])
    light_left([p['skin']], 68, 84, 1, p['skin_lt'])

    # ---- corset bodice (waist taper) ----
    BOD = {64: 13, 65: 13, 66: 12, 67: 12, 68: 12, 69: 11, 70: 11,
           71: 11, 72: 10, 73: 10, 74: 10, 75: 10, 76: 10, 77: 10,
           78: 10, 79: 11}
    for y, hw in BOD.items():
        sym(y, hw, p['bodice'])
    sym(64, 13, p['bodice_lt'])                       # top trim
    # front lacing
    for y in range(66, 79, 3):
        hspan(y, CX - 2, CX + 2, p['bodice_lt'])
        px(CX - 3, y + 1, p['bodice_sh'])
        px(CX + 3, y + 1, p['bodice_sh'])
    for y in range(65, 79):
        px(CX, y, p['bodice_sh'])
    shade_right([p['bodice']], 64, 79, 2, p['bodice_sh'])
    light_left([p['bodice']], 64, 74, 1, p['bodice_lt'])

    # ---- belt + side pouch ----
    for y in range(79, 83):
        sym(y, 11, p['lth_dk'])
    hspan(79, CX - 11, CX + 11, p['lth_sh'])
    for x in (CX - 1, CX, CX + 1):
        px(x, 80, GOLD)
        px(x, 81, GOLD_DK)
    for y in range(83, 92):                           # pouch (left hip)
        hspan(y, CX - 15, CX - 9, p['lth'])
    for y in range(83, 86):
        hspan(y, CX - 15, CX - 9, p['lth_lt'])
    px(CX - 12, 86, GOLD_DK)
    shade_right([p['lth']], 83, 91, 1, p['lth_sh'])

    # ---- flared skirt with folds + hem trim ----
    SK = {83: 12, 84: 13, 85: 13, 86: 14, 87: 14, 88: 15, 89: 15,
          90: 16, 91: 16, 92: 17, 93: 17, 94: 18, 95: 18, 96: 19,
          97: 19, 98: 19, 99: 19}
    for y, hw in SK.items():
        sym(y, hw, p['skirt'])
    for fx, y0, y1 in [(-11, 85, 92), (-4, 88, 96), (3, 84, 91),
                       (10, 87, 96)]:                 # staggered folds
        for y in range(y0, y1 + 1):
            px(CX + fx + (y - y0) // 6, y, p['skirt_sh'])
    for y in (97, 98):                                # hem trim
        sym(y, 19, p['skirt_lt'])
    sym(99, 19, p['skirt_sh'])
    shade_right([p['skirt']], 83, 99, 3, p['skirt_sh'])
    light_left([p['skirt']], 83, 96, 2, p['skirt_lt'])

    # ---- legs (tights) ----
    for y in range(100, 118):
        hspan(y, CX - 9, CX - 2, p['tights'])
        hspan(y, CX + 2, CX + 9, p['tights'])
    shade_right([p['tights']], 100, 117, 2, p['tights_sh'])

    # ---- knee boots ----
    for y in range(114, 132):
        hspan(y, CX - 10, CX - 2, p['lth'])
        hspan(y, CX + 2, CX + 10, p['lth'])
    for y in range(114, 117):                         # top band
        hspan(y, CX - 11, CX - 1, p['lth_lt'])
        hspan(y, CX + 1, CX + 11, p['lth_lt'])
    hspan(116, CX - 11, CX - 1, p['lth_dk'])
    hspan(116, CX + 1, CX + 11, p['lth_dk'])
    for y in range(132, 137):                         # foot
        hspan(y, CX - 11, CX - 2, p['lth'])
        hspan(y, CX + 2, CX + 11, p['lth'])
    hspan(132, CX - 11, CX - 8, p['lth_lt'])
    hspan(132, CX + 4, CX + 7, p['lth_lt'])
    for y in range(137, 139):                         # sole
        hspan(y, CX - 11, CX - 2, p['lth_dk'])
        hspan(y, CX + 2, CX + 11, p['lth_dk'])
    shade_right([p['lth']], 114, 136, 2, p['lth_sh'])
    light_left([p['lth']], 117, 130, 1, p['lth_lt'])

    # ---- hair: crown + curtain fringe, long falls, side braid ----
    CAP = {0: 10, 1: 13, 2: 15, 3: 16, 4: 17, 5: 18, 6: 19, 7: 19,
           8: 20, 9: 20, 10: 20, 11: 20, 12: 20, 13: 20}
    for y, hw in CAP.items():
        sym(y, hw, p['hair'])
    # soft curtain fringe, gently parted right of center
    PART = 2
    WISP = {-9: 2, -3: 1, 4: 2, 9: 1, -6: -1, 7: -1}  # tip variation
    def fdepth(dx):
        return min(19 + abs(dx - PART) + WISP.get(dx, 0), 27)
    for dx in range(-18, 19):
        depth = fdepth(dx)
        for y in range(9, depth + 1):
            px(CX + dx, y, p['hair'])
        px(CX + dx, depth, p['hair_dk'])
    # long falls framing the body
    for y in range(12, 68):
        w0, w1 = 19, 23
        if y > 56:
            w0 = 20
        hspan(y, CX - w1, CX - w0, p['hair'])
        hspan(y, CX + w0, CX + w1, p['hair'])
    # zigzag tips of the falls
    for x, yend in [(-23, 66), (-22, 70), (-21, 67), (-20, 71),
                    (20, 70), (21, 66), (22, 71), (23, 67)]:
        for y in range(64, yend + 1):
            px(CX + x, y, p['hair'])
        px(CX + x, yend, p['hair_dk'])
    # face-framing strands hugging the cheeks
    for y in range(26, 41):
        px(CX - 17, y, p['hair'])
    px(CX - 17, 40, p['hair_dk'])
    for y in range(26, 38):
        px(CX + 17, y, p['hair'])
    px(CX + 17, 37, p['hair_dk'])
    # side braid (viewer left): chevron segments + tie + tuft
    for y in range(30, 82):
        hspan(y, CX - 27, CX - 24, p['hair'])
    for y in range(30, 82):
        seg = (y - 30) % 6
        if seg in (0, 1):
            hspan(y, CX - 27, CX - 26, p['hair_lt'])
            px(CX - 24, y, p['hair_dk'])
        elif seg in (3, 4):
            hspan(y, CX - 25, CX - 24, p['hair_lt'])
            px(CX - 27, y, p['hair_dk'])
    for y in (82, 83):                                # tie
        hspan(y, CX - 27, CX - 24, p['lth_dk'])
    for y, (a, b) in {84: (27, 24), 85: (26, 24), 86: (26, 25)}.items():
        hspan(y, CX - a, CX - b, p['hair'])
    px(CX - 26, 87, p['hair_dk'])
    # sheen bands
    for x, y in [(-14, 3), (-13, 3), (-12, 4), (-11, 4), (-10, 5), (-6, 4),
                 (-5, 5), (-4, 5), (0, 4), (1, 4), (5, 3), (6, 4), (7, 4),
                 (8, 5), (12, 5), (13, 6)]:
        px(CX + x, y, p['hair_hi'])
    for x, y in [(-17, 5), (-16, 5), (-15, 4), (-8, 6), (-7, 6), (3, 5),
                 (4, 5), (10, 6), (11, 6), (15, 7), (16, 8)]:
        px(CX + x, y, p['hair_lt'])
    # sheen on the falls
    for y in range(30, 44):
        px(CX - 22, y, p['hair_lt'])
        px(CX + 21, y, p['hair_lt'])
    for y in range(34, 40):
        px(CX - 21, y, p['hair_hi'])
        px(CX + 22, y, p['hair_hi'])
    # strand separators in fringe
    for sx in (-12, -6, -1, 6, 12):
        for y in range(15, 20):
            px(CX + sx, y, p['hair_dk'])
    for sx in (-10, -4, 2, 8):
        for y in range(14, 18):
            px(CX + sx, y, p['hair_lt'])
    shade_right([p['hair'], p['hair_dk']], 0, 87, 2, p['hair_dk'])
    light_left([p['hair']], 1, 10, 1, p['hair_lt'])
    # fringe shadow on forehead
    for dx in range(-18, 19):
        c = get(CX + dx, fdepth(dx) + 1)
        if c in (p['skin'], p['skin_lt'], p['skin_sh']):
            px(CX + dx, fdepth(dx) + 1, p['skin_sh'])

    # ---- face features ----
    draw_eyes(px, hspan, p, 25)
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

    return outline(img, p, extra=[
        (('blouse', 'blouse_lt', 'blouse_sh'), 'blouse_ln'),
        (('bodice', 'bodice_lt', 'bodice_sh'), 'bodice_ln'),
        (('skirt', 'skirt_lt', 'skirt_sh'), 'skirt_ln'),
        (('tights', 'tights_sh'), 'tights_ln'),
    ])


if __name__ == '__main__':
    outdir = sys.argv[1] if len(sys.argv) > 1 else '.'
    male = draw_male(MALE)
    female = draw_female(FEMALE)
    for name, im in [('male', male), ('female', female)]:
        Image.fromarray(im).save(f'{outdir}/avatar_concept_v3_{name}_1x.png')
        Image.fromarray(im).resize((W * 4, H * 4), Image.NEAREST).save(
            f'{outdir}/avatar_concept_v3_{name}_4x.png')
    duo = Image.new('RGBA', ((W + 8) * 2 * 4, H * 4), (0, 0, 0, 0))
    duo.alpha_composite(
        Image.fromarray(male).resize((W * 4, H * 4), Image.NEAREST), (0, 0))
    duo.alpha_composite(
        Image.fromarray(female).resize((W * 4, H * 4), Image.NEAREST),
        ((W + 8) * 4, 0))
    duo.save(f'{outdir}/avatar_concept_v3_duo.png')
    print('saved v3 concept images to', outdir)
