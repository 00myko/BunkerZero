import cv2, numpy as np
from PIL import Image

def load(p):
    return cv2.imread(p, cv2.IMREAD_COLOR)

def text_mask(img, box, thr=26, k=0, dil=3, dark=False, sat_thr=None):
    """Pixels in box that stand out from the local background (text strokes)."""
    x0,y0,x1,y1 = box
    m = np.zeros(img.shape[:2], np.uint8)
    pad = 40
    X0,Y0 = max(0,x0-pad), max(0,y0-pad)
    X1,Y1 = min(img.shape[1],x1+pad), min(img.shape[0],y1+pad)
    sub = img[Y0:Y1, X0:X1]
    g = cv2.cvtColor(sub, cv2.COLOR_BGR2GRAY).astype(np.int16)
    k = k or (max(y1-y0, 15) * 2 + 1) | 1
    k = min(k, 255) | 1
    bg = cv2.medianBlur(g.astype(np.uint8), min(k, 255)).astype(np.int16)
    loc = (g - bg > thr) if not dark else (bg - g > thr)
    if sat_thr is not None:
        hsv = cv2.cvtColor(sub, cv2.COLOR_BGR2HSV)
        loc |= hsv[...,1] > sat_thr
    loc = loc.astype(np.uint8)
    inner = np.zeros_like(loc); inner[y0-Y0:y1-Y0, x0-X0:x1-X0] = 1
    loc &= inner
    if dil:
        loc = cv2.dilate(loc, np.ones((2*dil+1, 2*dil+1), np.uint8))
        # drop shadow sits down-right of the strokes
        sh = np.roll(np.roll(loc, 2, 0), 2, 1)
        loc = loc | sh
    m[Y0:Y1, X0:X1] = loc * 255
    return m

def box_mask(img, box):
    m = np.zeros(img.shape[:2], np.uint8)
    x0,y0,x1,y1 = box; m[y0:y1, x0:x1] = 255
    return m

def feather(m, r=3):
    f = cv2.GaussianBlur(m.astype(np.float32)/255.0, (2*r+1, 2*r+1), 0)
    return np.clip(f*1.6, 0, 1)

def shift_fill(img, mask, dx=0, dy=0, r=3):
    """Replace masked pixels with pixels offset by (dx,dy): keeps rows' bevels aligned."""
    src = np.roll(np.roll(img, -dy, 0), -dx, 1)
    a = feather(mask, r)[..., None]
    return (img*(1-a) + src*a).astype(np.uint8)

def inpaint(img, mask, r=6, grain=True):
    out = cv2.inpaint(img, mask, r, cv2.INPAINT_TELEA)
    if grain:
        # put back sensor/steel grain the fill smoothed away
        hp = img.astype(np.float32) - cv2.GaussianBlur(img, (0,0), 2).astype(np.float32)
        ring = cv2.dilate(mask, np.ones((25,25),np.uint8)) & ~mask
        sd = hp[ring>0].std() if (ring>0).any() else 6
        n = np.random.default_rng(1).normal(0, sd*0.9, img.shape[:2]).astype(np.float32)
        n = cv2.GaussianBlur(n, (0,0), 0.7)[...,None]
        a = feather(mask, 2)[...,None]
        out = np.clip(out.astype(np.float32) + n*a, 0, 255).astype(np.uint8)
    return out

def paste(img, src, box_src, at):
    x0,y0,x1,y1 = box_src
    img[at[1]:at[1]+(y1-y0), at[0]:at[0]+(x1-x0)] = src[y0:y1, x0:x1]
    return img

def rounded_alpha(shape, rects, r=18, soft=1.5):
    a = np.zeros(shape[:2], np.uint8)
    for (x0,y0,x1,y1,*rr) in rects:
        rad = rr[0] if rr else r
        cv2.rectangle(a, (x0+rad,y0), (x1-rad,y1), 255, -1)
        cv2.rectangle(a, (x0,y0+rad), (x1,y1-rad), 255, -1)
        for cx,cy in [(x0+rad,y0+rad),(x1-rad,y0+rad),(x0+rad,y1-rad),(x1-rad,y1-rad)]:
            cv2.circle(a, (cx,cy), rad, 255, -1, cv2.LINE_AA)
    if soft:
        a = cv2.GaussianBlur(a, (0,0), soft)
    return a

def save_rgba(img, alpha, path):
    b = cv2.cvtColor(img, cv2.COLOR_BGR2BGRA); b[...,3] = alpha
    cv2.imwrite(path, b)

def crop_rgba(img, box, alpha=None, path=None):
    x0,y0,x1,y1 = box
    c = cv2.cvtColor(img[y0:y1, x0:x1], cv2.COLOR_BGR2BGRA)
    if alpha is not None: c[...,3] = alpha[y0:y1, x0:x1]
    if path: cv2.imwrite(path, c)
    return c

def detail_fill(img, box, off, r=4, sigma=5.0, mask=None, lf_sigma=None):
    """Fill `box` (or `mask`) with smooth tone interpolated from its border plus
    the fine rust/grain detail of the clean patch at box+off."""
    if mask is None:
        mask = box_mask(img, box)
    dx, dy = off
    lf_src = cv2.inpaint(img, mask, 9, cv2.INPAINT_TELEA).astype(np.float32)
    lf = cv2.GaussianBlur(lf_src, (0,0), lf_sigma or sigma)
    src = np.roll(np.roll(img, -dy, 0), -dx, 1).astype(np.float32)
    hf = src - cv2.GaussianBlur(src, (0,0), sigma)
    fill = np.clip(lf + hf, 0, 255)
    a = cv2.GaussianBlur(mask.astype(np.float32)/255.0, (2*r+1, 2*r+1), 0)[..., None]
    return (img*(1-a) + fill*a).astype(np.uint8)

def tiled_fill(img, box, src_box, r=4, sigma=5.0, seed=0, mask=None, tile=None, gain=1.0, flip=True):
    """detail_fill whose grain comes from tiles of src_box: randomly flipped
    copies of the whole patch, or (tile=(w,h)) random un-flipped crops of it."""
    x0,y0,x1,y1 = box
    sx0,sy0,sx1,sy1 = src_box
    patch = img[sy0:sy1, sx0:sx1].astype(np.float32)
    full_hf = (patch - cv2.GaussianBlur(patch, (0,0), sigma)) * gain
    rng = np.random.default_rng(seed)
    H, W = y1-y0, x1-x0
    if tile:
        tw, th = tile
    else:
        th, tw = full_hf.shape[:2]
    phf = full_hf
    canvas = np.zeros((H, W, 3), np.float32); weight = np.zeros((H, W, 1), np.float32)
    ov = min(12, max(2, min(tw, th) // 3))
    win = np.ones((th, tw, 1), np.float32)
    ramp_x = np.minimum(np.arange(tw)+1, np.arange(tw)[::-1]+1).clip(max=ov)/ov
    ramp_y = np.minimum(np.arange(th)+1, np.arange(th)[::-1]+1).clip(max=ov)/ov
    win = (ramp_y[:,None]*ramp_x[None,:])[...,None].astype(np.float32)
    for ty in range(-ov, H, th-ov):
        for tx in range(-ov, W, tw-ov):
            if tile:
                oy = rng.integers(0, full_hf.shape[0]-th+1); ox = rng.integers(0, full_hf.shape[1]-tw+1)
                t = full_hf[oy:oy+th, ox:ox+tw]
            else:
                t = phf
            if flip and not tile and rng.random() < .5: t = t[:, ::-1]
            if flip and not tile and rng.random() < .5: t = t[::-1, :]
            ya, xa = max(ty,0), max(tx,0)
            yb, xb = min(ty+th, H), min(tx+tw, W)
            canvas[ya:yb, xa:xb] += t[ya-ty:yb-ty, xa-tx:xb-tx]*win[ya-ty:yb-ty, xa-tx:xb-tx]
            weight[ya:yb, xa:xb] += win[ya-ty:yb-ty, xa-tx:xb-tx]
    hf = canvas/np.maximum(weight, 1e-3)
    if mask is None:
        mask = box_mask(img, box)
    lf = cv2.GaussianBlur(cv2.inpaint(img, mask, 9, cv2.INPAINT_TELEA).astype(np.float32), (0,0), sigma)
    fill = lf.copy()
    fill[y0:y1, x0:x1] += hf
    fill = np.clip(fill, 0, 255)
    a = cv2.GaussianBlur(mask.astype(np.float32)/255.0, (2*r+1, 2*r+1), 0)[..., None]
    return (img*(1-a) + fill*a).astype(np.uint8)

def shadowed_alpha(plate_alpha, spread=26, strength=0.85, offset=(0, 8)):
    """Plate alpha plus a soft drop shadow outside it (colour black)."""
    sh = np.roll(np.roll(plate_alpha, offset[1], 0), offset[0], 1).astype(np.float32)
    sh = cv2.GaussianBlur(sh, (0,0), spread/2.5) * strength
    return np.maximum(plate_alpha.astype(np.float32), sh).clip(0,255).astype(np.uint8)

def cutout(img, plate_alpha, path, **kw):
    a = shadowed_alpha(plate_alpha, **kw)
    pa = plate_alpha.astype(np.float32)[...,None]/255.0
    # outside the plate the colour is shadow black
    rgb = (img.astype(np.float32)*pa).astype(np.uint8)
    save_rgba(rgb, a, path)

def icon_sprite(img, box, path, soft=3, ellipse=True):
    x0,y0,x1,y1 = box
    h, w = y1-y0, x1-x0
    a = np.zeros((h,w), np.uint8)
    if ellipse:
        cv2.ellipse(a, (w//2, h//2), (w//2-soft, h//2-soft), 0, 0, 360, 255, -1)
    else:
        a[soft:h-soft, soft:w-soft] = 255
    a = cv2.GaussianBlur(a, (0,0), soft*0.6)
    c = cv2.cvtColor(img[y0:y1, x0:x1], cv2.COLOR_BGR2BGRA); c[...,3] = a
    cv2.imwrite(path, c)
