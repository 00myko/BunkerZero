import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clean import *
R = "assets/Game UI Art/Upgrade Tables/refs/"
im = load(R+"ref_zombie_payout.jpg")
rows = [(159,201),(204,245),(248,289),(292,333),(336,376),(379,420),(423,463)]
for i,(a,b) in enumerate(rows):
    im = detail_fill(im, (201, a+2, 258, b-1), (440, 0), r=2)
for i,(a,b) in enumerate(rows[:4]):
    im = detail_fill(im, (206, a+5, 450, b-4), (400, 0), r=3)
for i,(a,b) in enumerate(rows[4:]):
    k = i  # borrow detail from cleaned rows 0..2
    im = detail_fill(im, (206, a+5, 864, b-4), (0, rows[k][0]-a), r=3)
for i,(a,b) in enumerate(rows):
    im = detail_fill(im, (874, a+5, 964, b-4), (-320, 0), r=3)
# Bank words (coin stack stays).
im = tiled_fill(im, (228, 54, 318, 110), (880, 36, 960, 110), r=3)
# Title: tone from the border, detail from plate further down/right.
im = tiled_fill(im, (348, 40, 868, 117), (880, 36, 960, 110), r=4, seed=1)
im = tiled_fill(im, (416, 117, 792, 150), (880, 36, 960, 110), r=3, seed=2)
# MULTIPLIER, UPGRADE COST + price.
im = detail_fill(im, (186, 484, 314, 512), (330, 0), r=3)
im = tiled_fill(im, (186, 577, 504, 618), (640, 578, 960, 609), r=3, sigma=4, seed=3)

orig = load(R+"ref_zombie_payout.jpg")
O = "assets/Game UI Art/Upgrade Tables/payout_"
# Icons straight from the photo (row background feathered out).
icon_sprite(orig, (210, 162, 252, 201), O+"icon_skull.png")
icon_sprite(orig, (210, 294, 252, 333), O+"icon_elite.png")
icon_sprite(orig, (212, 338, 250, 376), O+"icon_lock.png")
icon_sprite(orig, (334, 527, 362, 555), O+"arrow.png")
# Pills: paint the numbers out, then lift them as sprites.
pills = {"dim": (195, 515, 327, 564), "lit": (686, 514, 812, 566), "next": (849, 515, 979, 566)}
for key, (x0,y0,x1,y1) in pills.items():
    im = tiled_fill(im, (x0+14, y0+9, x1-12, y1-8), (x0+5, y0+8, x0+14, y1-8), r=2, sigma=3, seed=len(key))
    crop_rgba(im, (x0, y0, x1, y1), rounded_alpha(im.shape, [(x0, y0, x1-1, y1-1, 6)], soft=0.8), O+"pill_%s.png" % key)
# Clear the bar: all pills and arrows go, drawn live instead.
im = tiled_fill(im, (186, 512, 990, 569), (330, 486, 640, 510), r=3, seed=7)
# CLOSE / INSTALL words.
im = tiled_fill(im, (262, 644, 452, 710), (212, 652, 262, 702), r=3, seed=8)
im = tiled_fill(im, (660, 640, 920, 712), (618, 650, 662, 702), r=3, seed=9)
alpha = rounded_alpha(im.shape, [(145, 10, 1026, 760, 20)], soft=1.0)
cutout(im, alpha, O+"plate.png")
