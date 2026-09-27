import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clean import *
R = "assets/Game UI Art/Upgrade Tables/refs/"
im = load(R+"ref_survivor_vitals.jpg"); orig = im.copy()
O = "assets/Game UI Art/Upgrade Tables/vitals_"
# Sprites from the untouched photo.
icon_sprite(orig, (578, 162, 609, 193), O+"led_on.png", soft=1)
icon_sprite(orig, (703, 162, 734, 193), O+"led_off.png", soft=1)
icon_sprite(orig, (304, 184, 364, 214), O+"arrow.png", soft=3, ellipse=False)
icon_sprite(orig, (364, 442, 408, 497), O+"icon_lock.png", soft=2)
PATCH = (826, 282, 1000, 330)          # clean dark block steel (row 2, right)
rows = [(117,232),(236,338),(340,435),(438,505),(507,575)]
for i,(a,b) in enumerate(rows):
    im = tiled_fill(im, (166, a+9, 534, b-6), PATCH, r=3, seed=10+i)
    im = tiled_fill(im, (568, a+9, 800, b-4), PATCH, r=3, seed=20+i)
# right-most column: COST/$ on row 1, empty elsewhere
im = tiled_fill(im, (800, 124, 1000, 198), PATCH, r=3, seed=30)
# Small INSTALL: clean its words, lift it, then rebuild the blocks under it
im = tiled_fill(im, (838, 216, 978, 256), (826, 205, 990, 219), r=2, sigma=3, seed=31)
crop_rgba(im, (806, 200, 1010, 272), rounded_alpha(im.shape, [(808, 202, 1007, 269, 7)], soft=0.8), O+"install_small.png")
sep = np.zeros(im.shape[:2], np.uint8); sep[196:276, 804:1011] = 255
im = shift_fill(im, sep, dx=-236, r=2)
im = tiled_fill(im, (804, 196, 1010, 227), PATCH, r=3, seed=32)
im = tiled_fill(im, (804, 243, 1010, 330), PATCH, r=3, seed=33)
for i,(a,b) in enumerate(rows[2:]):
    im = tiled_fill(im, (790, a+9, 1004, b-6), PATCH, r=3, seed=50+i)
# Restore the two block rivets the button covered (copied from row 3's).
for ty in (221, 246):
    rv = np.zeros(im.shape[:2], np.uint8); cv2.circle(rv, (1006, ty), 7, 255, -1)
    im = shift_fill(im, rv, dy=353-ty, r=1)
# Title + bank
im = tiled_fill(im, (158, 34, 656, 102), (660, 36, 860, 100), r=4, seed=40)
im = tiled_fill(im, (862, 46, 1008, 98), (660, 36, 860, 100), r=3, seed=41)
# CLOSE / INSTALL words
im = tiled_fill(im, (200, 676, 336, 728), (336, 678, 372, 726), r=3, sigma=3, seed=42)
im = tiled_fill(im, (780, 678, 966, 730), (964, 682, 998, 726), r=3, sigma=3, seed=43)
alpha = rounded_alpha(im.shape, [(120, 10, 1046, 763, 22)], soft=1.0)
cutout(im, alpha, O+"plate.png")
