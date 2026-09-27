import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clean import *
R = "assets/Game UI Art/Upgrade Tables/refs/"
im = load(R+"ref_weapon_systems.jpg"); orig = im.copy()
O = "assets/Game UI Art/Upgrade Tables/weapon_"
PANEL = (790, 34, 1120, 106)   # clean right-panel steel (right of the name)

# --- sprites straight from the photo
icon_sprite(orig, (945, 501, 1000, 550), O+"check_box.png", soft=1, ellipse=False)
icon_sprite(orig, (945, 555, 1000, 605), O+"lock_box.png", soft=1, ellipse=False)
seg = orig[371:390, 787:854]
cv2.imwrite(O+"seg_on.png", seg)

# --- gun bars (idle = PISTOL, selected = SMG), words out
im = tiled_fill(im, (60, 36, 180, 80), (130, 104, 285, 148), r=3, seed=1, tile=(44, 38), gain=0.7)
crop_rgba(im, (25, 24, 317, 90), rounded_alpha(im.shape, [(25, 24, 316, 89, 6)], soft=0.8), O+"gun_bar.png")
im = tiled_fill(im, (62, 174, 142, 214), (150, 172, 290, 216), r=3, seed=2, tile=(40, 36), gain=0.9)
crop_rgba(im, (25, 162, 317, 226), rounded_alpha(im.shape, [(25, 162, 316, 225, 6)], soft=0.8), O+"gun_bar_selected.png")

# --- track rows: DAMAGE (idle) and RELOAD SPEED (selected), emptied
ROWPATCH = (600, 364, 770, 396)
im = tiled_fill(im, (550, 364, 700, 396), (620, 364, 770, 396), r=2, seed=3, tile=(50, 28), gain=0.9)
im = tiled_fill(im, (778, 364, 1096, 396), (600, 364, 770, 396), r=2, seed=4, tile=(50, 28), gain=0.9)
crop_rgba(im, (529, 359, 1123, 401), rounded_alpha(im.shape, [(529, 359, 1122, 400, 5)], soft=0.8), O+"track_row.png")
im = tiled_fill(im, (550, 506, 940, 544), (720, 507, 935, 543), r=2, seed=5, tile=(50, 30), gain=0.9)
im = tiled_fill(im, (938, 506, 1108, 544), (720, 507, 935, 543), r=2, seed=6, tile=(50, 30), gain=0.9)
m = np.zeros(im.shape[:2], np.uint8); m[500:550, 936:1008] = 255
im = shift_fill(im, m, dx=-190, r=2)
crop_rgba(im, (529, 501, 1123, 549), rounded_alpha(im.shape, [(529, 501, 1122, 548, 5)], soft=0.8), O+"track_row_selected.png")

# --- right panel: rows region, name, stats, UPGRADES/OWNED -> bare steel
im = tiled_fill(im, (522, 318, 1128, 614), PANEL, r=4, seed=7, tile=(80, 40), gain=0.9)
im = tiled_fill(im, (530, 36, 780, 116), PANEL, r=3, seed=8, tile=(80, 40), gain=0.9)
im = tiled_fill(im, (892, 122, 1122, 290), PANEL, r=3, seed=9, tile=(80, 40), gain=0.9)
# gun well: empty it and sink it into a dark well
well = (548, 124, 866, 292)
im = tiled_fill(im, well, PANEL, r=3, seed=10, tile=(80, 40), gain=0.8)
for (x0,y0,x1,y1) in [(537, 138, 552, 278), (862, 138, 876, 278)]:
    im = tiled_fill(im, (x0,y0,x1,y1), PANEL, r=2, seed=11, tile=(12, 40), gain=0.8)
dark = np.zeros(im.shape[:2], np.uint8); cv2.rectangle(dark, (539, 124), (874, 292), 255, -1)
a = feather(dark, 4)[..., None] * 0.5
im = (im * (1 - a)).astype(np.uint8)

# --- bottom bar: PLAYER BANK words, CLOSE / INSTALL words
im = tiled_fill(im, (52, 662, 214, 748), (226, 664, 430, 744), r=3, seed=12, tile=(60, 40), gain=0.9)
im = tiled_fill(im, (522, 678, 652, 730), (462, 676, 520, 734), r=3, sigma=3, seed=13)
im = tiled_fill(im, (900, 678, 1068, 732), (850, 678, 898, 732), r=3, sigma=3, seed=14)

# header plate for the WEAPON SYSTEMS title: the bottom bar, scaled down
half = im[648:761, 18:438]
bar = np.concatenate([half, half[:, ::-1]], axis=1)
hdr = cv2.resize(bar, None, fx=0.62, fy=0.62, interpolation=cv2.INTER_AREA)
ha = rounded_alpha(hdr.shape, [(0, 0, hdr.shape[1]-1, hdr.shape[0]-1, 6)], soft=0.8)
save_rgba(hdr, ha, O+"header.png")

alpha = rounded_alpha(im.shape, [(505, 24, 1147, 628, 10), (18, 648, 1150, 760, 8)], soft=1.0)
cutout(im, alpha, O+"plate.png")
