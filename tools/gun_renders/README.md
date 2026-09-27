# Weapon catalog renders

Every `assets/UI/weapon_<id>.png` is an image of the exact in-game viewmodel
GLB in `assets/Weapons/`. pistol, uzi, smg, shotgun, sawnoff, lmg,
grenade_launcher and minigun are renders from this tool: arms hidden, side
profile with the barrel to the right, orthographic camera, studio key/fill/rim
lights, transparent background, posed at the frame in `POSE` where a part
only sits right when animated.

sawnoffs, crossbow and knife were already renders of their own GLBs and are
not regenerated here: the twin sawn-offs sit side by side (a pure side view
stacks them into one gun) and the crossbow's limbs point at a side camera, so
those two use an angled view.

1. Copy `render_guns.gd` to the project root as `_render.gd` with a one-node
   scene `_render.tscn` using it, then run (needs a display, e.g. xvfb-run):

       godot --rendering-driver opengl3 --resolution 2400x1200 --path . res://_render.tscn -- only=pistol,uzi,smg,shotgun,sawnoff,lmg,grenade_launcher

   Raw 2400x1200 renders land in `user://gun_renders/`.
2. From that folder: `python3 finish.py <repo>/assets/UI` (needs
   opencv-python-headless, numpy, pillow).
3. Delete the temporary `_render.*` files.
