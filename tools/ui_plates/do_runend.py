import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clean import *
R = "assets/Game UI Art/Upgrade Tables/refs/"
im = load(R+"ref_run_ended.jpg"); orig = im.copy()
O = "assets/Game UI Art/Upgrade Tables/runend_"
icon_sprite(orig, (440, 16, 508, 64), O+"speaker.png", soft=3, ellipse=False)
# Red strip: speaker + word out, grunge in.
left = orig[0:74, 0:420]
strip = np.concatenate([left, left[:, ::-1]], axis=1)
seam = cv2.GaussianBlur(strip, (0,0), 2)
strip[:, 410:430] = seam[:, 410:430]
# Title
im = tiled_fill(im, (326, 120, 866, 222), (234, 150, 286, 520), r=4, seed=61, tile=(40, 56), gain=0.8)
CELL = (452, 490, 574, 533)
rows = [(230,272),(280,322),(329,372),(379,423),(430,473)]
for i,(a,b) in enumerate(rows):
    im = tiled_fill(im, (298, a+5, 602, b-5), CELL, r=3, seed=62+i, tile=(70, 30), gain=0.75)
    im = tiled_fill(im, (684, a+5, 876, b-5), CELL, r=3, seed=70+i, tile=(70, 30), gain=0.75)
im = tiled_fill(im, (298, 487, 878, 536), CELL, r=3, seed=80, tile=(60, 38), gain=0.75)
# The photo's crosshair pad bleeds into MAIN MENU's bottom-right corner:
# mirror the clean bottom-left corner over it.
corner = im[640:690, 605:665][:, ::-1].copy()
m = np.zeros(im.shape[:2], np.uint8); m[640:690, 874:934] = 255
tmp = im.copy(); tmp[640:690, 874:934] = corner
a = feather(m, 3)[..., None]
im = (im*(1-a) + tmp*a).astype(np.uint8)
# Button words
im = tiled_fill(im, (276, 596, 560, 658), (268, 577, 562, 596), r=3, sigma=3, seed=81)
im = tiled_fill(im, (646, 598, 896, 656), (624, 580, 914, 598), r=3, sigma=3, seed=82)
alpha = rounded_alpha(im.shape, [(218, 92, 958, 572, 14), (243, 565, 589, 687, 8), (605, 567, 934, 687, 8)], soft=1.0)
cutout(im, alpha, O+"plate.png")
save_rgba(strip, np.full(strip.shape[:2], 255, np.uint8), O+"strip.png")
