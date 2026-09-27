V37 — LIGHTING + FPS WEAPON MOTION PASS

What changed:
- Kept the stable V36 iOS/input path intact.
- Upgraded bunker environment lighting (safer scene-only changes).
- Added dedicated three-point camera lighting for the hand/weapon only.
- Increased default weapon size and lowered it slightly on screen.
- Improved directional sway / movement carry / sprint tilt so the pistol moves more like a modern FPS.
- Bumped viewmodel config version so the new placement overrides older saved placement once.
- Preserved the V36 zombie no-hit-reaction behavior.

# Zombie Survival — Room 01

This is Room 01 of a first-person Godot prototype for a 20-room zombie survival game, now assembled with the supplied headquarters art.

The current room is a 14m x 9m concrete shell with:

- floor, ceiling, four wall sections, and a real 1.8m doorway opening;
- collision bodies on every structural surface;
- four recessed ceiling lights with cold industrial lighting;
- a vent panel, duct, and door frame detail;
- smooth WASD movement, sprint, mouse look, head bob, and first-person camera;
- a room/objective HUD ready for future zombies, keys, weapons, and room transitions.
- imported GLB bed, couch, nightstand, storage cabinet, wall TV, thin floor panel, thin wall panels, and three duplicated upgrade toolboxes;

Only the player needs a character model later. The room is intentionally built from primitives so it stays lightweight while the layout is being designed.

The three toolbox instances are the same physical asset by design. Give them different names, LED colors, and UI functions in Godot: Eliminations Multiplier, Weapons Upgrade, and Resources/Crafting.

## Open

Install Godot 4.3 or newer, import this folder, open `project.godot`, and press Play.

## Controls

- W/A/S/D: move
- Mouse: look
- Shift: sprint
- Escape: release mouse

## Next room architecture

Duplicate `Room01_ConcreteShell`, change the dimensions or door layout in the Inspector, and connect rooms through the existing doorway. Future systems can be added as separate nodes: `ZombieManager`, `LootManager`, `DoorController`, `WeaponController`, and `RoomTransition`.
