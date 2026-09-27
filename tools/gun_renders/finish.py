# Crop the raw renders, drop detached loose parts, export 1600 px wide into
# assets/UI/weapon_<id>.png. Run from the folder holding the raw renders:
#   python3 finish.py /path/to/BunkerZero/assets/UI
import sys
DEST = sys.argv[1] if len(sys.argv) > 1 else "."
import cv2, numpy as np
from PIL import Image
ids=["pistol","uzi","smg","shotgun","sawnoff","lmg","grenade_launcher"]
for i in ids:
    im=cv2.imread(i+".png",-1)
    a=im[...,3]
    edge=(a[0].max()>24, a[-1].max()>24, a[:,0].max()>24, a[:,-1].max()>24)
    n,lab,st,_=cv2.connectedComponentsWithStats((a>8).astype(np.uint8),8)
    big=st[1:,4].max()
    keep=np.zeros_like(a)
    for k in range(1,n):
        if st[k,4] >= big*0.05:
            keep[lab==k]=1
    keep=cv2.dilate(keep,np.ones((5,5),np.uint8))
    im[...,3]=(a*keep).astype(np.uint8)
    ys,xs=np.where(im[...,3]>24)
    pad=24
    x0,x1=max(0,xs.min()-pad),min(im.shape[1],xs.max()+pad+1)
    y0,y1=max(0,ys.min()-pad),min(im.shape[0],ys.max()+pad+1)
    c=Image.fromarray(cv2.cvtColor(im[y0:y1,x0:x1],cv2.COLOR_BGRA2RGBA))
    c=c.resize((1600,round(c.height*1600/c.width)),Image.LANCZOS)
    c.save(DEST+"/weapon_"+i+".png"); print(i,c.size,"touches edge" if any(edge) else "")
c=Image.new("RGBA",(2*600, 4*300),(40,42,40,255))
for k,i in enumerate(ids):
    im=Image.open(DEST+"/weapon_"+i+".png"); im.thumbnail((580,280))
    c.alpha_composite(im,((k%2)*600+10,(k//2)*300+10))
c.save("sheet.png")
