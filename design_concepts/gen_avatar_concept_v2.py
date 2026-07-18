#!/usr/bin/env python3
"""QuestUp avatar concept v2 — detailed pixel-art chibi, 64x96 native.

Goals over v1: natural face shape (tapered jaw + chin), smaller almond
eyes with lash line, layered hair with strand clusters + highlights,
clothing with real construction detail (collar, cuffs, bib pocket,
straps, buckles, seams, knee folds, rolled hems), selective per-material
outlines instead of a uniform ink outline.

Run: python3 gen_avatar_concept_v2.py <outdir>
"""
import sys
import numpy as np
from PIL import Image

W, H = 64, 96
CX = 31

WHITE = (250, 248, 242)
GOLD = (232, 190, 96)
GOLD_DK = (176, 132, 58)

DEFAULT = dict(
    skin=(246, 205, 164), skin_lt=(252, 226, 194),
    skin_sh=(224, 168, 124), skin_dk=(186, 125, 92), skin_ln=(140, 86, 66),
    blush=(242, 158, 134),
    hair=(152, 88, 52), hair_lt=(190, 122, 74), hair_hi=(224, 164, 104),
    hair_dk=(112, 60, 40), hair_ln=(78, 40, 30),
    iris=(96, 152, 84), iris_lt=(158, 204, 122), iris_dk=(44, 86, 50),
    shirt=(238, 178, 80), shirt_lt=(250, 210, 128),
    shirt_sh=(202, 136, 58), shirt_ln=(150, 96, 44),
    denim=(88, 116, 162), denim_lt=(122, 150, 194),
    denim_sh=(62, 84, 126), denim_ln=(42, 58, 92),
    boot=(126, 86, 56), boot_lt=(158, 112, 74),
    boot_dk=(88, 56, 40), boot_ln=(58, 36, 28),
)


def draw(p):
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

    # ================= FACE =================
    # tapered skull: full at brow, narrowing cheeks, distinct chin
    FACE = {
        8: 9, 9: 11, 10: 12, 11: 12, 12: 13, 13: 13, 14: 13, 15: 13,
        16: 13, 17: 13, 18: 13, 19: 13, 20: 13, 21: 13, 22: 13, 23: 12,
        24: 12, 25: 11, 26: 10, 27: 9, 28: 7, 29: 6, 30: 4,
    }
    for y, hw in FACE.items():
        sym(y, hw, p['skin'])
    hspan(31, CX - 2, CX + 2, p['skin'])            # chin tip
    light_left([p['skin']], 9, 30, 1, p['skin_lt'])
    shade_right([p['skin']], 9, 30, 2, p['skin_sh'])
    # jaw shading to round the chin
    hspan(30, CX + 1, CX + 4, p['skin_sh'])
    hspan(31, CX, CX + 2, p['skin_sh'])

    # ================= NECK =================
    for y in range(32, 37):
        sym(y, 4, p['skin'])
    for y in range(32, 35):                          # chin shadow
        sym(y, 4, p['skin_sh'])

    # ================= HAIR =================
    CAP = {0: 6, 1: 9, 2: 11, 3: 12, 4: 13, 5: 14, 6: 14, 7: 15,
           8: 15, 9: 15, 10: 15, 11: 15, 12: 15, 13: 15, 14: 15, 15: 14}
    for y, hw in CAP.items():
        sym(y, hw, p['hair'])
    # fringe: strand clusters of varied depth (dx: bottom row of strand)
    FRINGE = {
        -13: 12, -12: 14, -11: 15, -10: 14, -9: 12, -8: 13, -7: 15,
        -6: 16, -5: 14, -4: 12, -3: 13, -2: 15, -1: 16, 0: 14, 1: 12,
        2: 13, 3: 15, 4: 16, 5: 14, 6: 13, 7: 12, 8: 14, 9: 15,
        10: 13, 11: 12, 12: 14, 13: 12,
    }
    for dx, depth in FRINGE.items():
        for y in range(7, depth + 1):
            px(CX + dx, y, p['hair'])
        px(CX + dx, depth, p['hair_dk'])             # strand tip shadow
    # side locks framing the face
    for y in range(10, 27):
        w = 2 if y < 22 else 1
        hspan(y, CX - 15, CX - 15 + w, p['hair'])
        hspan(y, CX + 15 - w, CX + 15, p['hair'])
    for y in range(22, 27):
        px(CX - 14, y, p['hair'])
        px(CX + 14, y, p['hair'])
    px(CX - 14, 27, p['hair_dk'])
    px(CX + 14, 27, p['hair_dk'])
    # crown highlight arcs
    for x, y in [(-8, 2), (-7, 2), (-6, 2), (-5, 2), (-10, 3), (-9, 3),
                 (-4, 3), (-3, 3), (-11, 4), (-2, 4), (-1, 4),
                 (1, 3), (2, 3), (3, 3), (4, 4), (5, 4)]:
        px(CX + x, y, p['hair_hi'])
    for x, y in [(-12, 5), (-11, 5), (0, 5), (1, 5), (6, 5), (7, 5)]:
        px(CX + x, y, p['hair_lt'])
    # strand separation strokes + light strands in fringe
    for dx in (-9, -4, 1, 6, 10):
        for y in range(8, 12):
            px(CX + dx, y, p['hair_dk'])
    for dx in (-8, -3, 2, 7):
        for y in range(8, 11):
            px(CX + dx, y, p['hair_lt'])
    shade_right([p['hair'], p['hair_dk']], 0, 27, 2, p['hair_dk'])
    light_left([p['hair']], 1, 8, 1, p['hair_lt'])
    # forehead shadow cast by fringe
    for dx, depth in FRINGE.items():
        c = get(CX + dx, depth + 1)
        if c == p['skin'] or c == p['skin_lt'] or c == p['skin_sh']:
            px(CX + dx, depth + 1, p['skin_sh'])

    # ================= EYES =================
    # almond eyes: lash line, iris with vertical gradient + catchlight
    EYE = [
        ".kkkkk.",
        "kWCppWk",
        "kWiiiWk",
        "kWIIIWk",
        ".ttttt.",
    ]
    def draw_eye(ox, oy):
        for dy, row in enumerate(EYE):
            for dx, ch in enumerate(row):
                c = {'k': p['skin_ln'], 'W': WHITE, 'C': WHITE,
                     'i': p['iris'], 't': p['skin_dk'],
                     'I': p['iris_lt'], 'p': p['iris_dk']}.get(ch)
                if c:
                    px(ox + dx, oy + dy, c)
    draw_eye(CX - 10, 17)
    draw_eye(CX + 4, 17)
    hspan(15, CX - 9, CX - 5, p['hair_dk'])          # brows
    hspan(15, CX + 5, CX + 9, p['hair_dk'])
    # nose + mouth
    px(CX, 24, p['skin_dk'])
    px(CX + 1, 24, p['skin_sh'])
    px(CX - 2, 27, p['skin_ln'])
    hspan(28, CX - 1, CX + 1, p['skin_ln'])
    px(CX + 2, 27, p['skin_ln'])
    # soft dithered blush
    for x, y in [(-11, 24), (-10, 25), (-9, 24), (9, 24), (10, 25), (11, 24)]:
        px(CX + x, y, p['blush'])

    # ================= TORSO / SHIRT =================
    for y in range(37, 54):
        sym(y, 10, p['shirt'])
    # sleeves (rounded caps, slightly puffed, rolled cuff)
    for y in range(38, 50):
        w = 14 if y > 39 else (12 if y == 38 else 13)
        hspan(y, CX - w, CX - 10, p['shirt'])
        hspan(y, CX + 10, CX + w, p['shirt'])
    hspan(49, CX - 14, CX - 10, p['shirt_sh'])       # cuff roll
    hspan(49, CX + 10, CX + 14, p['shirt_sh'])
    hspan(48, CX - 14, CX - 12, p['shirt_lt'])
    hspan(48, CX + 12, CX + 14, p['shirt_lt'])
    # collar
    sym(37, 5, p['shirt_sh'])
    px(CX - 5, 38, p['shirt_sh'])
    px(CX + 5, 38, p['shirt_sh'])
    px(CX, 38, p['shirt_ln'])                        # placket
    px(CX, 39, p['shirt_ln'])
    shade_right([p['shirt']], 37, 53, 2, p['shirt_sh'])
    light_left([p['shirt']], 38, 44, 2, p['shirt_lt'])
    # fabric folds beside the bib
    for x, y in [(-9, 49), (-9, 50), (-8, 51), (9, 48), (9, 49), (8, 50)]:
        px(CX + x, y, p['shirt_sh'])

    # ================= ARMS / HANDS =================
    for y in range(50, 62):
        hspan(y, CX - 14, CX - 11, p['skin'])
        hspan(y, CX + 11, CX + 14, p['skin'])
    hspan(50, CX - 14, CX - 11, p['skin_sh'])        # cuff shadow
    hspan(50, CX + 11, CX + 14, p['skin_sh'])
    for y in range(62, 66):                          # hands
        hspan(y, CX - 15, CX - 11, p['skin'])
        hspan(y, CX + 11, CX + 15, p['skin'])
    shade_right([p['skin']], 50, 65, 1, p['skin_sh'])
    light_left([p['skin']], 51, 60, 1, p['skin_lt'])

    # ================= OVERALLS =================
    # straps
    for y in range(38, 43):
        hspan(y, CX - 8, CX - 6, p['denim_sh'])
        hspan(y, CX + 6, CX + 8, p['denim_sh'])
    # bib
    for y in range(42, 54):
        sym(y, 7, p['denim'])
    px(CX - 7, 43, GOLD)                             # buckles
    px(CX - 6, 43, GOLD_DK)
    px(CX + 7, 43, GOLD)
    px(CX + 6, 43, GOLD_DK)
    # bib pocket: light stitch border, base interior, shaded bottom
    for y in range(47, 50):
        sym(y, 3, p['denim'])
    sym(50, 3, p['denim_sh'])
    sym(46, 4, p['denim_lt'])
    for y in range(47, 51):
        px(CX - 4, y, p['denim_lt'])
        px(CX + 4, y, p['denim_lt'])
    for y in range(47, 50):                          # pocket center seam
        px(CX, y, p['denim_sh'])
    # hips
    for y in range(54, 64):
        sym(y, 10, p['denim'])
    hspan(54, CX - 10, CX + 10, p['denim_lt'])       # waist seam
    # legs (taper slightly toward the cuff)
    for y in range(64, 80):
        ow = 10 if y < 72 else 9
        hspan(y, CX - ow, CX - 1, p['denim'])
        hspan(y, CX + 1, CX + ow, p['denim'])
    # knee folds
    hspan(70, CX - 8, CX - 5, p['denim_sh'])
    hspan(70, CX + 4, CX + 7, p['denim_sh'])
    hspan(71, CX - 6, CX - 4, p['denim_ln'])
    hspan(71, CX + 6, CX + 8, p['denim_ln'])
    # rolled cuffs
    for y in range(77, 80):
        hspan(y, CX - 9, CX - 1, p['denim_lt'])
        hspan(y, CX + 1, CX + 9, p['denim_lt'])
    hspan(79, CX - 9, CX - 1, p['denim_sh'])
    hspan(79, CX + 1, CX + 9, p['denim_sh'])
    shade_right([p['denim']], 42, 79, 2, p['denim_sh'])
    light_left([p['denim']], 55, 76, 1, p['denim_lt'])
    # outer-leg seam
    for y in range(56, 77):
        px(CX - 10, y, p['denim_lt'])

    # ================= BOOTS =================
    for y in range(80, 88):
        hspan(y, CX - 9, CX - 1, p['boot'])
        hspan(y, CX + 1, CX + 9, p['boot'])
    hspan(80, CX - 9, CX - 1, p['boot_dk'])          # boot top band
    hspan(80, CX + 1, CX + 9, p['boot_dk'])
    for y in range(88, 92):                          # foot
        hspan(y, CX - 10, CX - 1, p['boot'])
        hspan(y, CX + 1, CX + 10, p['boot'])
    hspan(88, CX - 10, CX - 7, p['boot_lt'])         # toe highlight
    hspan(88, CX + 3, CX + 6, p['boot_lt'])
    for y in range(92, 94):                          # sole
        hspan(y, CX - 10, CX - 1, p['boot_dk'])
        hspan(y, CX + 1, CX + 10, p['boot_dk'])
    shade_right([p['boot']], 80, 91, 2, p['boot_dk'])
    light_left([p['boot']], 81, 87, 1, p['boot_lt'])

    # ================= SELECTIVE OUTLINE =================
    OUTLINE = {}
    for base, ln in [
        ([p['skin'], p['skin_lt'], p['skin_sh'], p['skin_dk'], p['blush']],
         p['skin_ln']),
        ([p['hair'], p['hair_lt'], p['hair_hi'], p['hair_dk']], p['hair_ln']),
        ([p['shirt'], p['shirt_lt'], p['shirt_sh']], p['shirt_ln']),
        ([p['denim'], p['denim_lt'], p['denim_sh']], p['denim_ln']),
        ([p['boot'], p['boot_lt'], p['boot_dk']], p['boot_ln']),
        ([GOLD, GOLD_DK], GOLD_DK),
    ]:
        for c in base:
            OUTLINE[c] = ln
    mask = img[:, :, 3] > 0
    edge = mask & ~(np.roll(mask, 1, 0) & np.roll(mask, -1, 0)
                    & np.roll(mask, 1, 1) & np.roll(mask, -1, 1))
    ys, xs = np.nonzero(edge)
    for y, x in zip(ys, xs):
        c = tuple(img[y, x, :3])
        img[y, x] = (*OUTLINE.get(c, p['skin_ln']), 255)
    return img


VARIANTS = [
    DEFAULT,
    dict(DEFAULT,
         hair=(72, 60, 68), hair_lt=(106, 90, 98), hair_hi=(148, 130, 138),
         hair_dk=(50, 40, 48), hair_ln=(34, 26, 32),
         iris=(170, 124, 64), iris_lt=(210, 170, 106), iris_dk=(112, 74, 40),
         shirt=(150, 174, 122), shirt_lt=(184, 204, 154),
         shirt_sh=(110, 134, 90), shirt_ln=(74, 96, 62),
         denim=(124, 94, 66), denim_lt=(152, 120, 88),
         denim_sh=(94, 68, 48), denim_ln=(62, 44, 32)),
    dict(DEFAULT,
         skin=(180, 126, 90), skin_lt=(202, 148, 110),
         skin_sh=(152, 100, 70), skin_dk=(120, 76, 54), skin_ln=(84, 52, 38),
         blush=(208, 112, 98),
         hair=(198, 108, 58), hair_lt=(232, 148, 88), hair_hi=(248, 192, 122),
         hair_dk=(152, 76, 42), hair_ln=(104, 50, 28),
         iris=(94, 134, 192), iris_lt=(142, 180, 226), iris_dk=(54, 84, 138),
         shirt=(218, 132, 140), shirt_lt=(240, 170, 174),
         shirt_sh=(174, 94, 106), shirt_ln=(126, 62, 76),
         denim=(98, 106, 130), denim_lt=(128, 136, 160),
         denim_sh=(72, 78, 100), denim_ln=(48, 52, 70)),
]


if __name__ == '__main__':
    outdir = sys.argv[1] if len(sys.argv) > 1 else '.'
    hero = draw(DEFAULT)
    Image.fromarray(hero).save(f'{outdir}/avatar_concept_v2_1x.png')
    for s in (3, 6):
        Image.fromarray(hero).resize((W * s, H * s), Image.NEAREST).save(
            f'{outdir}/avatar_concept_v2_{s}x.png')
    strip = Image.new('RGBA', (len(VARIANTS) * (W + 4) * 4, H * 4),
                      (0, 0, 0, 0))
    for i, v in enumerate(VARIANTS):
        im = Image.fromarray(draw(v)).resize((W * 4, H * 4), Image.NEAREST)
        strip.alpha_composite(im, (i * (W + 4) * 4, 0))
    strip.save(f'{outdir}/avatar_concept_v2_variants.png')
    print('saved v2 concept images to', outdir)
