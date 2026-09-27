# Weapon catalog renders

`assets/UI/weapon_<id>.png` for pistol, uzi, smg, shotgun, sawnoff, lmg and
grenade_launcher are renders of the in-game viewmodel GLBs: arms hidden, side
profile with the barrel to the right, orthographic camera, studio key/fill/rim
lights, transparent background. (minigun, sawnoffs and crossbow are the
hand-made keepers and are not regenerated.)

1. Copy `render_guns.gd` to the project root as `_render.gd` with a one-node
   scene `_render.tscn` using it, then run (needs a display, e.g. xvfb-run):

       godot --rendering-driver opengl3 --resolution 2400x1200 --path . res://_render.tscn -- only=pistol,uzi,smg,shotgun,sawnoff,lmg,grenade_launcher

   Raw 2400x1200 renders land in `user://gun_renders/`.
2. From that folder: `python3 finish.py <repo>/assets/UI` (needs
   opencv-python-headless, numpy, pillow).
3. Delete the temporary `_render.*` files.
