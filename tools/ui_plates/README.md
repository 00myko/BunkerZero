# UI plate textures

The hub upgrade tables and RUN ENDED are drawn from the four reference photos
in `assets/Game UI Art/Upgrade Tables/refs/`. These scripts paint every baked
word/number out of the photos, cut the plates out (the live hub shows around
them) and lift the state sprites (pills, LEDs, bars, rows, icons).

    pip install opencv-python-headless numpy pillow
    python3 tools/ui_plates/do_payout.py    # run from the repo root
    python3 tools/ui_plates/do_vitals.py
    python3 tools/ui_plates/do_runend.py
    python3 tools/ui_plates/do_weapons.py

Live text, LEDs and hit areas are placed in photo-pixel coordinates by
`scripts/ui/upgrade_terminal.gd` and `scripts/ui/hud_controller.gd` (RUN ENDED)
through `scripts/ui/plate_ui.gd`.
