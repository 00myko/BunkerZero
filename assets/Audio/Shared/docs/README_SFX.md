# Weapon SFX — sawnoffs / crossbow / knife / minigun

All WAVs: 44.1 kHz, 16-bit, mono. Procedurally synthesized **placeholders** — usable in-game now, but swap in AI-generated or library sounds using the prompts below for final quality. Keep the same filenames and nothing else has to change.

`sfx_cues.json` = machine-readable version of the timing tables (time in seconds from clip start).
`_preview/*_timeline_preview.wav` = every cue mixed at its time over the full clip length — play it alongside the animation to check sync.

---

## 1. What each packed clip contains (from keyframe analysis)

All four GLBs pack everything into ONE clip at 30 fps. In Godot, play sub-ranges (e.g. `AnimationPlayer.play()` + `seek()`, or split into new animations in the import dialog) using these segment times:

| GLB | Clip | Length | Segments (s) |
|---|---|---|---|
| sawnoffs | CINEMA_4D_Main | 5.00 | fire R 0.00–0.40 · fire L 0.40–0.90 · reload (both) 0.90–2.65 · handle/flourish 2.65–5.00 |
| crossbow | allanimations | 5.67 | fire 0.00–0.95 · re-cock 0.95–1.60 · load bolt 1.60–2.60 · idle/handle 2.60–4.90 · jab/raise 4.90–5.67 |
| knife | anims | 4.83 | idle 0.00–1.30 · slash 1 1.30–1.90 · slash 2 1.90–2.60 · inspect flips 2.60–4.83 |
| minigun | allanims | 6.00 | fire step 0.00–0.20 (loop) · idle 0.20–2.00 · reload 2.00–4.10 · inspect/rev 4.10–6.00 |

Interpretations to double-check by eye: crossbow 5.03 spike (melee jab vs. raise), knife 2.70–4.10 (inspect flips vs. attack), minigun 4.30 button (inspect vs. rev).

---

## 2. Cue sheets (clip time → sound)

### Sawed-offs (`CINEMA_4D_Main`)
| t | sound | event |
|---|---|---|
| 0.00 | sawnoff_fire_1 | right gun fires |
| 0.40 | sawnoff_fire_2 | left gun fires |
| 0.97 | sawnoff_latch_open | top-lever release |
| 1.13 | sawnoff_break_open | barrels break open |
| 1.25 | sawnoff_shell_extract | extractor pushes shells |
| 1.60 / 1.70 | shared_shell_drop_1 / _2 | spent shells fall |
| 1.80 | shared_foley_rustle_1 | guns tipped up |
| 1.88 | sawnoff_shell_insert | fresh shells seated |
| 2.17 | sawnoff_break_close | barrels snap shut |
| 2.30 | sawnoff_latch_close | lever returns |
| 4.27 | sawnoff_flourish_twirl | fast twirl/snap |

### Crossbow (`allanimations`)
| t | sound | event |
|---|---|---|
| 0.00 | crossbow_fire_1 | trigger, string snap, bolt away |
| 0.97 | crossbow_string_draw_ratchet | string dragged back |
| 1.33 | crossbow_lever_latch | loader lever closes |
| 2.10 | crossbow_bolt_slide_in | bolt slides in, seats 2.50 |
| 2.45 / 3.65 | crossbow_handling_creak | tilts |
| 4.98 | crossbow_bash_swing | jab / raise |

### Knife (`anims`)
| t | sound | event |
|---|---|---|
| 1.37 | knife_swing_1 | slash 1 |
| 2.03 | knife_swing_2 | slash 2 |
| 2.70 | knife_flip_1 + knife_swing_3 | flip to reverse grip |
| 3.32 / 3.47 / 4.03 | knife_flip_2 / _3 / _1 | flips |
| on hit (gameplay) | knife_hit_flesh_1-3 / knife_hit_wall | impact |
| on equip | knife_draw_shing | draw |

### Minigun (`allanims`)
| t | sound | event |
|---|---|---|
| trigger down | minigun_spin_up → minigun_fire_loop (loop) | loop the 0.00–0.20 anim segment while firing |
| trigger up | minigun_spin_down + minigun_fire_tail | stop |
| alt-fire / hold | minigun_spin_loop (loop) | spinning, not firing |
| 2.43 | minigun_feed_lid_open | lid pops |
| 2.47 | minigun_box_mag_out | mag pulled |
| 3.47 | minigun_box_mag_in | mag slammed (seated 3.57) |
| 3.95 | minigun_feed_lid_close | lid closes |
| 4.30 | minigun_button_click | button |
| 5.33 | minigun_heavy_handling_thud | heavy re-grip |

Shared: `shared_dry_fire_click` (empty), `shared_weapon_raise_1/2` (equip), `shared_foley_rustle_1-3`, `shared_shell_drop_1-3`.

**Godot hookup:** easiest is an Audio Playback track (or Call Method track → `play_sfx("name")`) in each weapon's AnimationPlayer at the times above. Set the loop mode on `minigun_fire_loop.wav` / `minigun_spin_loop.wav` in the Import dock (Loop Mode: Forward). Randomize pitch ±5% on fire/swing sounds.

---

## 3. Prompts for AI sound generation (ElevenLabs SFX, Stable Audio, etc.)

Generate 3–4 takes each, pick the best, trim silence, export mono WAV. Durations in brackets.

**Sawed-off (double-barrel, 12 gauge, sawn short)**
- `sawnoff_fire` [1.5s] — "Sawed-off double-barrel shotgun single shot, very loud close-mic boom, heavy low-end punch, short metallic ring, outdoor echo tail, first-person"
- `sawnoff_latch_open` [0.3s] — "Break-action shotgun top lever pushed aside, crisp steel click, close"
- `sawnoff_break_open` [0.6s] — "Double-barrel shotgun breaking open, hinge swing and solid metal clunk at the end"
- `sawnoff_shell_extract` [0.4s] — "Shotgun shells sliding out of barrels, plastic hull scrape and extractor pop"
- `shared_shell_drop` [0.5s] — "Two empty plastic shotgun shells dropping and bouncing on concrete"
- `sawnoff_shell_insert` [0.5s] — "Two shotgun shells pushed into barrels one after another, soft plastic slide and thunk"
- `sawnoff_break_close` [0.7s] — "Double-barrel shotgun snapped shut, heavy satisfying metal clack and lock"
- `sawnoff_latch_close` [0.2s] — "Shotgun top lever snapping back to center, small steel click"
- `sawnoff_flourish_twirl` [0.7s] — "Two heavy pistols spun quickly in hands, air whoosh and leather glove grip"

**Crossbow**
- `crossbow_fire` [1.0s] — "Heavy crossbow firing, trigger click, deep bowstring twang and wooden thump, bolt whoosh away"
- `crossbow_string_draw_ratchet` [0.4s] — "Crossbow cocking lever pulled back, ratcheting clicks and taut string creak"
- `crossbow_lever_latch` [0.4s] — "Crossbow lever locking into place, solid metal and wood clack"
- `crossbow_bolt_slide_in` [0.6s] — "Crossbow bolt slid along a metal rail then clicking into place"
- `crossbow_handling_creak` [0.5s] — "Wooden crossbow stock creaking under grip, soft cloth movement"
- `crossbow_bash_swing` [0.5s] — "Heavy wooden weapon swung fast, air swish ending in a dull hit"

**Knife**
- `knife_swing` [0.3s] — "Combat knife slash through air, sharp fast whoosh, close"
- `knife_draw_shing` [0.8s] — "Steel combat knife drawn from sheath, bright metallic shing ring"
- `knife_flip` [0.3s] — "Knife flipped in hand, short spinning whirr and palm catch slap"
- `knife_hit_flesh` [0.3s] — "Knife stab into flesh, wet meaty thud, no scream"
- `knife_hit_wall` [0.5s] — "Knife blade striking concrete wall, metallic clang and scrape"

**Minigun (rotary, 6 barrels)**
- `minigun_spin_up` [1.2s] — "Minigun barrels spinning up, electric motor whine rising in pitch, mechanical rattle"
- `minigun_spin_loop` [1.0s, seamless loop] — "Minigun barrels spinning at full speed with no firing, steady motor whine, seamless loop"
- `minigun_spin_down` [1.6s] — "Minigun barrels winding down, whine falling in pitch until stop"
- `minigun_fire_loop` [1.0s, seamless loop] — "Minigun firing continuously, extremely fast buzzing gunfire over motor whine, seamless loop"
- `minigun_fire_tail` [1.5s] — "Last shot of a minigun burst with echo tail and motor winding down"
- `minigun_feed_lid_open` / `_close` [0.4s] — "Heavy steel feed cover flipped open / slammed shut on a machine gun"
- `minigun_box_mag_out` [0.4s] — "Heavy ammo box unlatched and pulled off a gun, metal scrape and belt rattle"
- `minigun_box_mag_in` [0.7s] — "Heavy ammo box slammed onto machine gun, loud metal clunk and latch"
- `minigun_button_click` [0.1s] — "Chunky industrial push button click"
- `minigun_heavy_handling_thud` [0.7s] — "Heavy weapon re-gripped and hefted, gear rustle and low thud"

**Shared**
- `shared_dry_fire_click` [0.15s] — "Gun trigger pulled on empty chamber, dry metal click"
- `shared_weapon_raise` [0.6s] — "Weapon raised from holster, cloth rustle and light metal rattle"
- `shared_foley_rustle` [0.4s] — "Tactical gloves and jacket movement, subtle cloth rustle"
