#!/usr/bin/env python3
"""QuestUp avatar redesign concept — Stardew-flavored chibi, 47x94 native.

Parametrized by palette so one drawing yields a whole set (skin tones,
hair colors, outfit colors). Run: python3 avatar_final.py <outdir>
"""
import sys
import numpy as np
from PIL import Image

W, H = 47, 94
CX = 23
INK = (58, 34, 40)
WHITE = (250, 248, 242)
BUTTON = (230, 196, 110)

DEFAULT = dict(
    skin=(245, 200, 158), skin_sh=(222, 165, 120), skin_dk=(188, 126, 92),
    blush=(240, 150, 130),
    hair=(150, 84, 54), hair_lt=(186, 118, 76), hair_dk=(110, 58, 42),
    hair_hi=(222, 160, 104),
    iris=(96, 150, 82), iris_lt=(152, 198, 120), iris_dk=(46, 84, 50),
    shirt=(238, 176, 74), shirt_sh=(198, 132, 56), shirt_lt=(250, 208, 122),
    pants=(86, 112, 158), pants_sh=(60, 80, 120), pants_lt=(116, 144, 188),
    boot=(122, 82, 54), boot_dk=(86, 54, 38),
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

    def runs_of(y, colors):
        row = img[y]
        out, start = [], None
        for x in range(W):
            m = tuple(row[x][:3]) in colors and row[x][3] > 0
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

    # ---- face ----
    FACE = {6: 9, 7: 11, 8: 13, 9: 14, 10: 14, 11: 15, 12: 15, 13: 15,
            14: 16, 15: 16, 16: 16, 17: 16, 18: 16, 19: 16, 20: 16, 21: 16,
            22: 16, 23: 16, 24: 15, 25: 15, 26: 14, 27: 13, 28: 12, 29: 10,
            30: 7}
    for y, hw in FACE.items():
        sym(y, hw, p['skin'])
    shade_right([p['skin']], 6, 30, 2, p['skin_sh'])
    for y in range(31, 36):
        sym(y, 4, p['skin'])
    sym(31, 5, p['skin_sh'])
    sym(32, 4, p['skin_sh'])

    # ---- hair ----
    CAP = {0: 7, 1: 10, 2: 12, 3: 14, 4: 15, 5: 16, 6: 17, 7: 17, 8: 18,
           9: 18, 10: 18, 11: 18, 12: 18, 13: 18, 14: 17, 15: 17}
    for y, hw in CAP.items():
        sym(y, hw, p['hair'])
    FRINGE = {-16: 13, -15: 14, -14: 16, -13: 14, -12: 13, -11: 14, -10: 16,
              -9: 15, -8: 13, -7: 14, -6: 16, -5: 15, -4: 13, -3: 14, -2: 15,
              -1: 16, 0: 14, 1: 13, 2: 14, 3: 16, 4: 15, 5: 13, 6: 14,
              7: 16, 8: 15, 9: 13, 10: 14, 11: 16, 12: 14, 13: 13, 14: 14,
              15: 15, 16: 13}
    for dx, depth in FRINGE.items():
        for y in range(8, depth + 1):
            px(CX + dx, y, p['hair'])
    for y in range(12, 28):
        w = 2 if y < 24 else 1
        hspan(y, CX - 18, CX - 18 + w, p['hair'])
        hspan(y, CX + 18 - w, CX + 18, p['hair'])
    for y in range(24, 28):
        px(CX - 17, y, p['hair'])
        px(CX + 17, y, p['hair'])
    px(CX, 0, p['hair'])
    px(CX + 1, 0, p['hair'])
    px(CX + 1, 1, p['hair'])
    px(CX + 2, 1, p['hair'])
    shade_right([p['hair']], 0, 28, 3, p['hair_dk'])
    light_left([p['hair']], 1, 6, 2, p['hair_lt'])
    for dx, depth in FRINGE.items():
        px(CX + dx, depth, p['hair_dk'])
    # lock texture: short dark strokes in the fringe
    for dx in (-10, -3, 4, 11):
        for y in range(10, 13):
            px(CX + dx, y, p['hair_dk'])
    for x, y in [(-9, 2), (-8, 2), (-7, 2), (-11, 3), (-10, 3), (-6, 3),
                 (-5, 3), (-12, 4), (-4, 4)]:
        px(CX + x, y, p['hair_hi'])

    # ---- eyes (rows 18-25) ----
    EYE = [
        "..XXXX..",
        ".XLLLLX.",
        "XLWWLIIX",
        "XLWWIIIX",
        "XIIIIIPX",
        "XIIIIPPX",
        ".PIPPPP.",
        "..PPPP..",
    ]
    def draw_eye(ox, flip=False):
        for dy, row in enumerate(EYE):
            r = row[::-1] if flip else row
            for dx, ch in enumerate(r):
                c = {'X': INK, 'W': WHITE, 'I': p['iris'],
                     'P': p['iris_dk'], 'L': p['iris_lt']}.get(ch)
                if c:
                    px(ox + dx, 18 + dy, c)
    draw_eye(CX - 13)
    draw_eye(CX + 6, flip=True)
    hspan(17, CX - 11, CX - 8, p['hair_dk'])   # brows
    hspan(17, CX + 8, CX + 11, p['hair_dk'])
    hspan(27, CX - 13, CX - 11, p['blush'])
    hspan(27, CX + 11, CX + 13, p['blush'])
    hspan(28, CX - 1, CX + 1, p['skin_dk'])    # smile
    px(CX - 2, 27, p['skin_dk'])
    px(CX + 2, 27, p['skin_dk'])

    # ---- body ----
    for y in range(36, 59):
        sym(y, 11 if y > 36 else 9, p['skin'])
    for y in range(37, 60):
        lw = 14 if y < 42 else 15
        hspan(y, CX - lw, CX - 12, p['skin'])
        hspan(y, CX + 12, CX + lw, p['skin'])
    for y in range(58, 62):
        hspan(y, CX - 15, CX - 12, p['skin'])
        hspan(y, CX + 12, CX + 15, p['skin'])
    shade_right([p['skin']], 56, 61, 1, p['skin_sh'])
    for y in range(58, 84):
        hspan(y, CX - 9, CX - 2, p['skin'])
        hspan(y, CX + 2, CX + 9, p['skin'])

    # ---- shirt ----
    for y in range(35, 52):
        sym(y, 12, p['shirt'])
    for y in range(37, 48):
        w0 = 15 if y == 37 else 16   # rounded sleeve cap
        hspan(y, CX - w0, CX - 11, p['shirt'])
        hspan(y, CX + 11, CX + w0, p['shirt'])
    hspan(47, CX - 16, CX - 11, p['shirt_sh'])
    hspan(47, CX + 11, CX + 16, p['shirt_sh'])
    shade_right([p['shirt']], 35, 51, 2, p['shirt_sh'])
    light_left([p['shirt']], 36, 40, 2, p['shirt_lt'])
    sym(35, 5, p['shirt_sh'])

    # ---- overalls ----
    for y in range(43, 52):
        sym(y, 8, p['pants'])
    for y in range(37, 44):
        hspan(y, CX - 8, CX - 6, p['pants_sh'])
        hspan(y, CX + 6, CX + 8, p['pants_sh'])
    px(CX - 7, 44, BUTTON)
    px(CX + 7, 44, BUTTON)
    for y in range(52, 74):
        if y < 60:
            sym(y, 12, p['pants'])
        else:
            hspan(y, CX - 11, CX - 1, p['pants'])
            hspan(y, CX + 1, CX + 11, p['pants'])
    for y in range(46, 50):
        hspan(y, CX - 3, CX + 3, p['pants_sh'])
    shade_right([p['pants']], 43, 73, 2, p['pants_sh'])
    hspan(52, CX - 12, CX + 12, p['pants_lt'])
    hspan(73, CX - 11, CX - 1, p['pants_lt'])
    hspan(73, CX + 1, CX + 11, p['pants_lt'])

    # ---- boots ----
    for y in range(74, 84):
        hspan(y, CX - 10, CX - 1, p['boot'])
        hspan(y, CX + 1, CX + 10, p['boot'])
    for y in range(80, 84):
        hspan(y, CX - 11, CX - 1, p['boot_dk'])
        hspan(y, CX + 1, CX + 11, p['boot_dk'])
    shade_right([p['boot']], 74, 83, 2, p['boot_dk'])

    # ---- outline ----
    mask = img[:, :, 3] > 0
    edge = mask & ~(np.roll(mask, 1, 0) & np.roll(mask, -1, 0)
                    & np.roll(mask, 1, 1) & np.roll(mask, -1, 1))
    img[edge] = (*INK, 255)
    return img

VARIANTS = [
    DEFAULT,
    # raven hair, hazel eyes, sage shirt, brown pants, warm skin
    dict(DEFAULT,
         hair=(70, 58, 66), hair_lt=(104, 88, 96), hair_dk=(48, 38, 46),
         hair_hi=(140, 122, 130),
         iris=(168, 122, 62), iris_lt=(208, 168, 104), iris_dk=(112, 74, 40),
         shirt=(148, 172, 120), shirt_sh=(108, 132, 88),
         shirt_lt=(180, 200, 152),
         pants=(122, 92, 64), pants_sh=(92, 66, 46), pants_lt=(150, 118, 86)),
    # copper hair, blue eyes, rose shirt, slate pants, deep skin
    dict(DEFAULT,
         skin=(178, 124, 88), skin_sh=(150, 98, 68), skin_dk=(118, 74, 52),
         blush=(206, 110, 96),
         hair=(196, 106, 56), hair_lt=(230, 146, 86), hair_dk=(150, 74, 40),
         hair_hi=(246, 190, 120),
         iris=(92, 132, 190), iris_lt=(140, 178, 224), iris_dk=(54, 84, 138),
         shirt=(216, 130, 138), shirt_sh=(172, 92, 104),
         shirt_lt=(238, 168, 172),
         pants=(96, 104, 128), pants_sh=(70, 76, 98), pants_lt=(126, 134, 158)),
]

if __name__ == '__main__':
    outdir = sys.argv[1] if len(sys.argv) > 1 else '.'
    hero = draw(DEFAULT)
    Image.fromarray(hero).save(f'{outdir}/avatar_concept_1x.png')
    Image.fromarray(hero).resize((W * 3, H * 3), Image.NEAREST).save(
        f'{outdir}/avatar_concept_3x.png')
    Image.fromarray(hero).resize((W * 6, H * 6), Image.NEAREST).save(
        f'{outdir}/avatar_concept_6x.png')
    strip = Image.new('RGBA', (len(VARIANTS) * (W + 4) * 4, H * 4),
                      (0, 0, 0, 0))
    for i, v in enumerate(VARIANTS):
        im = Image.fromarray(draw(v)).resize((W * 4, H * 4), Image.NEAREST)
        strip.alpha_composite(im, (i * (W + 4) * 4, 0))
    strip.save(f'{outdir}/avatar_concept_variants.png')
    print('saved concept images to', outdir)
