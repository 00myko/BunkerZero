class_name UpgradeTerminal
extends Control

## The three hub tables drawn as the cleaned reference photos (WEAPON SYSTEMS,
## SURVIVOR VITALS, ZOMBIE PAYOUT) over the dimmed live hub, plus the
## proximity prompt. Every live word, number, LED and row comes from
## UpgradeManager's tables; the photos carry only steel, rivets, slots and the
## physical CLOSE / INSTALL blocks. Coordinates are photo pixels (PlateUI).
## World interaction and pausing live in upgrade_ui_controller.gd.

signal prompt_pressed
signal close_pressed
signal install_pressed

const TABLES := {
	"weapon": "WEAPON SYSTEMS",
	"survivor": "SURVIVOR VITALS",
	"earnings": "ZOMBIE PAYOUT",
}
const PHOTO := Vector2(1168.0, 784.0)
## The weapons photo has no title; a header plate sits above it.
const WEAPON_TOP := 80.0

var interaction_prompt: Button = null

var _overlay: Control = null
var _stage: Control = null
var _install: Button = null
var _last_viewport := Vector2.ZERO
var _refresh_queued := false

var _table := ""
var _weapon_id := "pistol"
var _track_id := "damage"
var _survivor_row := "max_health"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_prompt()
	_overlay = Control.new()
	_overlay.name = "UpgradePopupOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	_overlay.z_index = 900
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(dim)
	_stage = Control.new()
	_stage.name = "Stage"
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_stage)
	EconomyManager.money_changed.connect(func(_b: int) -> void: refresh())
	UpgradeManager.upgrades_changed.connect(refresh)
	_layout()


func _process(_delta: float) -> void:
	if get_viewport().get_visible_rect().size != _last_viewport:
		_layout()


func _design() -> Vector2:
	return PHOTO + Vector2(0.0, WEAPON_TOP) if _table == "weapon" else PHOTO


func _layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	_last_viewport = vp
	PlateUI.fit(_stage, _design(), vp)
	var s := minf(vp.x / PHOTO.x, vp.y / PHOTO.y)
	interaction_prompt.scale = Vector2(s, s)
	interaction_prompt.size = Vector2(500.0, 62.0)
	interaction_prompt.position = Vector2((vp.x - 500.0 * s) * 0.5, vp.y - 140.0 * s)

# ------------------------------------------------------------------ public API

func is_popup_open() -> bool:
	return _overlay != null and _overlay.visible


func set_prompt_visible(shown: bool, label_text: String = "") -> void:
	interaction_prompt.visible = shown
	if shown and not label_text.is_empty():
		interaction_prompt.text = label_text


func table_name(table: String) -> String:
	return String(TABLES.get(table, "UPGRADE TERMINAL"))


func open_popup(table: String = "weapon") -> void:
	_table = table if TABLES.has(table) else "weapon"
	if _table == "weapon":
		var primary := String(RunManager.run_primary_weapon)
		var entry := UpgradeManager.get_weapon(primary)
		if not entry.is_empty() and bool(entry.get("listed", true)):
			_weapon_id = primary
		_pick_first_track()
	interaction_prompt.visible = false
	_overlay.visible = true
	_layout()
	_rebuild()


func close_popup() -> void:
	_overlay.visible = false
	PlateUI.clear(_stage)


## Buys the next rank of whatever row is selected. Returns true on a purchase.
func purchase_selected() -> bool:
	match _table:
		"weapon":
			return UpgradeManager.purchase_weapon_track(_weapon_id, _track_id)
		"survivor":
			return UpgradeManager.purchase_survivor(_survivor_row)
		"earnings":
			return UpgradeManager.purchase_payout()
	return false


## Coalesced: a purchase fires money_changed and upgrades_changed together.
func refresh() -> void:
	if not is_popup_open() or _refresh_queued:
		return
	_refresh_queued = true
	_do_refresh.call_deferred()


func _do_refresh() -> void:
	_refresh_queued = false
	if is_popup_open():
		_rebuild()

# ------------------------------------------------------------------ frame

func _build_prompt() -> void:
	interaction_prompt = Button.new()
	interaction_prompt.name = "UpgradeInteractionPrompt"
	interaction_prompt.visible = false
	interaction_prompt.z_index = 850
	interaction_prompt.focus_mode = Control.FOCUS_NONE
	interaction_prompt.add_theme_font_override("font", PlateUI.font(PlateUI.BODY))
	interaction_prompt.add_theme_font_size_override("font_size", 30)
	var face := StyleBoxTexture.new()
	face.texture = PlateUI.tex("weapon_gun_bar_selected.png")
	face.set_texture_margin_all(22.0)
	face.content_margin_left = 40.0
	for key in ["normal", "hover", "pressed", "hover_pressed"]:
		interaction_prompt.add_theme_stylebox_override(key, face)
	interaction_prompt.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		interaction_prompt.add_theme_color_override(key, PlateUI.GREEN_PALE)
	interaction_prompt.pressed.connect(func() -> void: prompt_pressed.emit())
	add_child(interaction_prompt)


func _rebuild() -> void:
	PlateUI.clear(_stage)
	_install = null
	match _table:
		"weapon":
			_build_weapons()
		"survivor":
			_build_vitals()
		_:
			_build_payout()


func _close() -> void:
	close_pressed.emit()


func _buy() -> void:
	install_pressed.emit()


## Photo INSTALL block; disabled when broke or nothing to buy.
func _install_block(r: Rect2, cap: float, color: Color, cost: int) -> void:
	_install = PlateUI.hit(_stage, r, _buy, "INSTALL", cap, color)
	_install.disabled = cost < 0 or not EconomyManager.can_afford(cost)

# ------------------------------------------------------------------ ZOMBIE PAYOUT

func _build_payout() -> void:
	PlateUI.sprite(_stage, "payout_plate.png", Rect2(Vector2.ZERO, PHOTO))
	# Bank badge (coins are in the photo).
	PlateUI.text(_stage, "BANK", PlateUI.BODY, 17.0, 233.0, 59.0)
	PlateUI.text(_stage, PlateUI.money(EconomyManager.get_balance()), PlateUI.BODY, 22.0, 233.0, 84.0, PlateUI.AMBER, HORIZONTAL_ALIGNMENT_LEFT, 88.0)
	PlateUI.text(_stage, "ZOMBIE PAYOUT", PlateUI.TITLE, 63.0, 607.0, 47.0, PlateUI.OFF_WHITE, HORIZONTAL_ALIGNMENT_CENTER, 0.0, true)
	PlateUI.text(_stage, "CREDIT RECOVERY MULTIPLIER", PlateUI.BODY, 21.0, 604.0, 122.0, PlateUI.OFF_WHITE, HORIZONTAL_ALIGNMENT_CENTER)

	# Seven recessed rows in the photo; types fill them in table order.
	var rows := [159.0, 204.0, 248.0, 292.0, 336.0, 379.0, 423.0]
	var types := UpgradeManager.ZOMBIE_TYPES
	for i in rows.size():
		if i >= types.size():
			break
		var entry: Dictionary = types[i]
		var top: float = rows[i]
		var unlocked := bool(entry.get("unlocked", false))
		var icon := "payout_icon_lock.png"
		if unlocked:
			icon = String(entry.get("icon", "payout_icon_skull.png"))
		PlateUI.sprite(_stage, icon, Rect2(211.0, top + 2.0, 40.0, 38.0), Color.WHITE if unlocked else Color(0.8, 0.8, 0.8))
		var word := String(entry.get("name", "")) if unlocked else "LOCKED"
		var name_label := PlateUI.text(_stage, word + (":" if unlocked else ""), PlateUI.BODY, 21.0, 268.0, top + 12.0,
			PlateUI.OFF_WHITE if unlocked else PlateUI.DIM)
		_leader(name_label.position.x + name_label.size.x + 8.0, 858.0, top + 31.0)
		var value := PlateUI.money(UpgradeManager.get_zombie_reward(String(entry["id"]))) if unlocked else "---"
		PlateUI.text(_stage, value, PlateUI.BODY, 22.0, 948.0, top + 12.0, PlateUI.AMBER if unlocked else PlateUI.DIM, HORIZONTAL_ALIGNMENT_RIGHT)

	# Multiplier pills: one per rank in the table, current lit, next outlined.
	PlateUI.text(_stage, "MULTIPLIER", PlateUI.BODY, 18.0, 193.0, 490.0)
	var mults := UpgradeManager.PAYOUT_MULTIPLIERS
	var rank := UpgradeManager.get_payout_rank()
	var left := 193.0
	var right := 982.0
	var gap := 32.0
	var pill_w := (right - left - gap * (mults.size() - 1)) / mults.size()
	for i in mults.size():
		var x := left + i * (pill_w + gap)
		var state := "dim"
		var ink := Color(PlateUI.OFF_WHITE.r, PlateUI.OFF_WHITE.g, PlateUI.OFF_WHITE.b, 0.85)
		if i == rank:
			state = "lit"
			ink = PlateUI.GREEN_PALE
		elif i == rank + 1:
			state = "next"
			ink = PlateUI.GREEN
		PlateUI.sprite(_stage, "payout_pill_%s.png" % state, Rect2(x, 515.0, pill_w, 49.0))
		PlateUI.text(_stage, "%.2fx" % mults[i], PlateUI.BODY, 21.0, x + pill_w * 0.5, 529.0, ink, HORIZONTAL_ALIGNMENT_CENTER)
		if i < mults.size() - 1:
			PlateUI.sprite(_stage, "payout_arrow.png", Rect2(x + pill_w + 3.0, 526.0, 26.0, 26.0))

	var cost := UpgradeManager.get_payout_cost()
	PlateUI.text(_stage, "UPGRADE COST", PlateUI.BODY, 19.0, 193.0, 589.0)
	PlateUI.text(_stage, PlateUI.money(cost) if cost >= 0 else "MAXED", PlateUI.BODY, 30.0, 377.0, 583.0,
		PlateUI.AMBER if cost >= 0 else PlateUI.GREEN)
	PlateUI.hit(_stage, Rect2(189.0, 625.0, 345.0, 101.0), _close, "CLOSE", 48.0)
	_install_block(Rect2(596.0, 620.0, 389.0, 106.0), 50.0, PlateUI.OFF_WHITE, cost)


## Dotted leader from a row name to the value column.
func _leader(x0: float, x1: float, y: float) -> void:
	if x1 - x0 < 12.0:
		return
	var dots := Control.new()
	dots.position = Vector2(x0, y)
	dots.size = Vector2(x1 - x0, 2.0)
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots.draw.connect(func() -> void:
		var x := 0.0
		while x < dots.size.x:
			dots.draw_rect(Rect2(x, 0.0, 2.0, 2.0), Color(0.78, 0.77, 0.72, 0.55))
			x += 5.0)
	_stage.add_child(dots)

# ------------------------------------------------------------------ SURVIVOR VITALS

## The photo's five row slots (top, bottom); tall slots have room for the
## captioned CURRENT / NEXT layout, short ones use the one-line layout.
const VITAL_SLOTS := [[117.0, 232.0], [236.0, 338.0], [340.0, 435.0], [438.0, 505.0], [507.0, 575.0]]

func _build_vitals() -> void:
	PlateUI.sprite(_stage, "vitals_plate.png", Rect2(Vector2.ZERO, PHOTO))
	PlateUI.text(_stage, "SURVIVOR VITALS", PlateUI.TITLE, 57.0, 170.0, 40.0, PlateUI.OFF_WHITE, HORIZONTAL_ALIGNMENT_LEFT, 480.0, true)
	PlateUI.text(_stage, PlateUI.money(EconomyManager.get_balance()), PlateUI.BODY, 36.0, 998.0, 53.0, PlateUI.AMBER, HORIZONTAL_ALIGNMENT_RIGHT)

	var rows := UpgradeManager.SURVIVOR
	if not bool(UpgradeManager.get_survivor_row(_survivor_row).get("unlocked", false)):
		_survivor_row = String(rows[0]["id"])
	for i in VITAL_SLOTS.size():
		if i >= rows.size():
			break
		var entry: Dictionary = rows[i]
		var top: float = VITAL_SLOTS[i][0]
		var bottom: float = VITAL_SLOTS[i][1]
		var unlocked := bool(entry.get("unlocked", false))
		if unlocked:
			PlateUI.hit(_stage, Rect2(150.0, top, 870.0, bottom - top), _select_survivor.bind(String(entry["id"])))
		if bottom - top >= 90.0 and unlocked:
			_vital_tall(entry, top, bottom)
		else:
			_vital_short(entry, top, unlocked)

	PlateUI.hit(_stage, Rect2(147.0, 662.0, 245.0, 78.0), _close, "CLOSE", 38.0)
	_install_block(Rect2(733.0, 663.0, 284.0, 79.0), 38.0, PlateUI.GREEN, UpgradeManager.get_survivor_cost(_survivor_row))


func _vital_values(entry: Dictionary) -> Array:
	var id := String(entry["id"])
	var rank := UpgradeManager.get_survivor_rank(id)
	var fmt := String(entry.get("format", "%d"))
	var now := fmt % int(UpgradeManager.get_survivor_value(id, rank))
	var nxt := "MAX" if rank >= UpgradeManager.MAX_RANK else fmt % int(UpgradeManager.get_survivor_value(id, rank + 1))
	return [rank, now, nxt]


func _vital_tall(entry: Dictionary, top: float, bottom: float) -> void:
	var id := String(entry["id"])
	var selected := id == _survivor_row
	var v := _vital_values(entry)
	var rank: int = v[0]
	PlateUI.text(_stage, String(entry["name"]), PlateUI.BODY, 26.0, 175.0, top + 14.0, PlateUI.OFF_WHITE, HORIZONTAL_ALIGNMENT_LEFT, 350.0)
	PlateUI.text(_stage, "CURRENT", PlateUI.BODY, 16.0, 218.0, top + 57.0, PlateUI.OFF_WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	PlateUI.text(_stage, v[1], PlateUI.BODY, 25.0, 222.0, top + 79.0, PlateUI.GREEN, HORIZONTAL_ALIGNMENT_CENTER, 150.0)
	PlateUI.sprite(_stage, "vitals_arrow.png", Rect2(304.0, top + 67.0, 60.0, 30.0))
	PlateUI.text(_stage, "NEXT", PlateUI.BODY, 16.0, 436.0, top + 57.0, PlateUI.OFF_WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	PlateUI.text(_stage, v[2], PlateUI.BODY, 25.0, 440.0, top + 79.0, PlateUI.OFF_WHITE, HORIZONTAL_ALIGNMENT_CENTER, 150.0)

	PlateUI.text(_stage, "LEVEL", PlateUI.BODY, 17.0, 582.0, top + 15.0)
	if selected:
		_leds(rank, 593.0, top + 60.0, 22.0, 42.0, true)
		var cost := UpgradeManager.get_survivor_cost(id)
		PlateUI.text(_stage, "COST", PlateUI.BODY, 17.0, 828.0, top + 16.0)
		PlateUI.text(_stage, PlateUI.money(cost) if cost >= 0 else "MAXED", PlateUI.BODY, 27.0, 828.0, top + 46.0,
			PlateUI.AMBER if cost >= 0 else PlateUI.GREEN)
		# Small INSTALL on the selected row, as on the photo's first row.
		var r := Rect2(809.0, top + 86.0, 197.0, 63.0)
		PlateUI.sprite(_stage, "vitals_install_small.png", Rect2(r.position - Vector2(3.0, 3.0), Vector2(204.0, 72.0)))
		var small := PlateUI.hit(_stage, r, _buy, "INSTALL", 25.0, PlateUI.GREEN)
		small.disabled = cost < 0 or not EconomyManager.can_afford(cost)
	else:
		PlateUI.text(_stage, "%d/5" % rank, PlateUI.BODY, 24.0, 582.0, top + 35.0, PlateUI.GREEN)
		_leds(rank, 593.0, bottom - 20.0, 22.0, 42.0, false)


## Locked rows (and live rows in a short slot): name + LOCKED on the left,
## CURRENT -> NEXT -> LEVEL n/5 in one line on the right.
func _vital_short(entry: Dictionary, top: float, unlocked: bool) -> void:
	var ink := PlateUI.OFF_WHITE if unlocked else PlateUI.DIM
	var name_label := PlateUI.text(_stage, String(entry["name"]), PlateUI.BODY, 22.0, 175.0, top + 13.0, ink)
	var now := "--"
	var nxt := "--"
	var rank := 0
	if unlocked:
		var v := _vital_values(entry)
		rank = v[0]
		now = v[1]
		nxt = v[2]
	else:
		PlateUI.text(_stage, "LOCKED", PlateUI.BODY, 14.0, 176.0, top + 44.0, PlateUI.DIM)
		PlateUI.sprite(_stage, "vitals_icon_lock.png", Rect2(name_label.position.x + name_label.size.x + 22.0, top + 6.0, 40.0, 50.0))
	PlateUI.text(_stage, "CURRENT", PlateUI.BODY, 15.0, 580.0, top + 13.0, ink)
	PlateUI.text(_stage, now, PlateUI.BODY, 18.0, 580.0, top + 39.0, PlateUI.GREEN if unlocked else PlateUI.DIM)
	PlateUI.sprite(_stage, "vitals_arrow.png", Rect2(675.0, top + 30.0, 36.0, 18.0), Color(1, 1, 1, 0.6))
	PlateUI.text(_stage, "NEXT", PlateUI.BODY, 15.0, 733.0, top + 13.0, ink)
	PlateUI.text(_stage, nxt, PlateUI.BODY, 18.0, 733.0, top + 39.0, ink)
	PlateUI.sprite(_stage, "vitals_arrow.png", Rect2(797.0, top + 30.0, 36.0, 18.0), Color(1, 1, 1, 0.6))
	PlateUI.text(_stage, "LEVEL %d/5" % rank, PlateUI.BODY, 15.0, 848.0, top + 13.0, ink)
	_leds(rank, 856.0, top + 47.0, 16.0, 24.0, false)


## Five round LEDs; `numbered` prints 1..5 underneath.
func _leds(rank: int, x0: float, cy: float, d: float, pitch: float, numbered: bool) -> void:
	for i in UpgradeManager.MAX_RANK:
		var cx := x0 + i * pitch
		PlateUI.sprite(_stage, "vitals_led_on.png" if i < rank else "vitals_led_off.png", Rect2(cx - d * 0.5, cy - d * 0.5, d, d))
		if numbered:
			PlateUI.text(_stage, str(i + 1), PlateUI.BODY, 17.0, cx, cy + d * 0.5 + 12.0, PlateUI.OFF_WHITE, HORIZONTAL_ALIGNMENT_CENTER)


func _select_survivor(row_id: String) -> void:
	_survivor_row = row_id
	_rebuild()

# ------------------------------------------------------------------ WEAPON SYSTEMS

func _pick_first_track() -> void:
	if UpgradeManager.is_track_available(_weapon_id, _track_id):
		return
	for track in UpgradeManager.TRACKS:
		if UpgradeManager.is_track_available(_weapon_id, track["id"]):
			_track_id = track["id"]
			return


func _build_weapons() -> void:
	var y0 := WEAPON_TOP
	# Title plate (the photo has none) above the board.
	var hdr_w := 520.0
	PlateUI.sprite(_stage, "weapon_header.png", Rect2((PHOTO.x - hdr_w) * 0.5, 4.0, hdr_w, 70.0))
	PlateUI.text(_stage, "WEAPON SYSTEMS", PlateUI.TITLE, 34.0, PHOTO.x * 0.5, 21.0, PlateUI.OFF_WHITE, HORIZONTAL_ALIGNMENT_CENTER, 0.0, true)
	PlateUI.sprite(_stage, "weapon_plate.png", Rect2(0.0, y0, PHOTO.x, PHOTO.y))

	# Gun list: one riveted bar per listed gun, filling the photo's column.
	var guns := UpgradeManager.listed_weapons()
	var col_top := 24.0 + y0
	var col_h := 599.0
	var gap := 5.0
	var bar_h := (col_h - gap * (guns.size() - 1)) / maxf(guns.size(), 1)
	for i in guns.size():
		var id := String(guns[i]["id"])
		var selected := id == _weapon_id
		var r := Rect2(25.0, col_top + i * (bar_h + gap), 292.0, bar_h)
		PlateUI.plate(_stage, "weapon_gun_bar_selected.png" if selected else "weapon_gun_bar.png", r, Vector4(30, 20, 30, 20))
		var cap := minf(26.0, bar_h * 0.43)
		PlateUI.text(_stage, String(guns[i]["name"]), PlateUI.BODY, cap, 69.0, r.position.y + (bar_h - cap) * 0.5,
			PlateUI.GREEN if selected else PlateUI.OFF_WHITE, HORIZONTAL_ALIGNMENT_LEFT, 214.0)
		PlateUI.hit(_stage, r, _select_weapon.bind(id))

	# Gun plate: name, subtitle, photo in the dark well, live stats.
	var gun := UpgradeManager.get_weapon(_weapon_id)
	PlateUI.text(_stage, String(gun.get("name", _weapon_id.to_upper())), PlateUI.TITLE, 37.0, 540.0, 43.0 + y0, PlateUI.OFF_WHITE, HORIZONTAL_ALIGNMENT_LEFT, 340.0, true)
	PlateUI.text(_stage, String(gun.get("subtitle", "")), PlateUI.BODY, 17.0, 540.0, 93.0 + y0, PlateUI.OFF_WHITE, HORIZONTAL_ALIGNMENT_LEFT, 340.0)
	var art := TextureRect.new()
	art.texture = PlateUI.tex("res://assets/UI/weapon_%s.png" % _weapon_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.position = Vector2(550.0, 130.0 + y0)
	art.size = Vector2(314.0, 158.0)
	art.modulate = Color(1.45, 1.42, 1.38)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(art)
	var stats := [
		["DMG", "%.0f" % UpgradeManager.get_weapon_damage(_weapon_id)],
		["MAG", "%d" % UpgradeManager.get_weapon_mag(_weapon_id)],
		["RATE", "%.0f" % (60.0 / UpgradeManager.get_weapon_shot_interval(_weapon_id))],
		["RELOAD", _reload_text(UpgradeManager.get_weapon_reload_time(_weapon_id))],
	]
	for i in stats.size():
		var cy := 131.0 + i * 40.7 + y0
		PlateUI.text(_stage, stats[i][0], PlateUI.BODY, 21.0, 902.0, cy, PlateUI.GREEN)
		PlateUI.text(_stage, stats[i][1], PlateUI.BODY, 23.0, 1025.0, cy - 1.0, PlateUI.OFF_WHITE, HORIZONTAL_ALIGNMENT_LEFT, 105.0)

	# Tracks: UPGRADES / OWNED, then one row per track.
	PlateUI.text(_stage, "UPGRADES", PlateUI.BODY, 22.0, 537.0, 326.0 + y0)
	PlateUI.text(_stage, "OWNED", PlateUI.BODY, 22.0, 1093.0, 326.0 + y0, PlateUI.GREEN, HORIZONTAL_ALIGNMENT_RIGHT)
	var tracks := UpgradeManager.TRACKS
	var row_top := 359.0 + y0
	var row_pitch := 247.0 / maxf(tracks.size(), 1)
	for i in tracks.size():
		_track_row(tracks[i], Rect2(529.0, row_top + i * row_pitch, 594.0, row_pitch - 5.0))

	# Bottom bar.
	PlateUI.text(_stage, "PLAYER BANK", PlateUI.BODY, 20.0, 59.0, 670.0 + y0, PlateUI.GREEN)
	PlateUI.text(_stage, PlateUI.money(EconomyManager.get_balance()), PlateUI.BODY, 35.0, 59.0, 703.0 + y0, PlateUI.AMBER, HORIZONTAL_ALIGNMENT_LEFT, 370.0)
	PlateUI.hit(_stage, Rect2(446.0, 662.0 + y0, 280.0, 86.0), _close, "CLOSE", 37.0, PlateUI.INK)
	_install_block(Rect2(836.0, 662.0 + y0, 297.0, 86.0), 37.0, PlateUI.INK,
		UpgradeManager.get_weapon_track_cost(_weapon_id, _track_id))


func _track_row(track: Dictionary, r: Rect2) -> void:
	var id := String(track["id"])
	var available := UpgradeManager.is_track_available(_weapon_id, id)
	var rank := UpgradeManager.get_weapon_rank(_weapon_id, id)
	var maxed := rank >= UpgradeManager.MAX_RANK
	var selected := available and id == _track_id
	PlateUI.plate(_stage, "weapon_track_row_selected.png" if selected else "weapon_track_row.png", r, Vector4(30, 12, 30, 12))
	var cy := r.position.y + r.size.y * 0.5
	PlateUI.text(_stage, String(track["name"]), PlateUI.BODY, 20.0, 558.0, cy - 10.0,
		PlateUI.GREEN if selected else (PlateUI.OFF_WHITE if available else PlateUI.DIM))
	if not available:
		# Locked: lock box, no price, no bar.
		PlateUI.sprite(_stage, "weapon_lock_box.png", Rect2(946.0, cy - 24.0, 54.0, 48.0))
		return
	PlateUI.hit(_stage, r, _select_track.bind(id))
	if selected and not maxed:
		_segments(rank, Rect2(783.0, cy - 11.0, 150.0, 22.0))
		PlateUI.sprite(_stage, "weapon_check_box.png", Rect2(946.0, cy - 24.0, 54.0, 48.0))
		PlateUI.text(_stage, PlateUI.money(UpgradeManager.get_weapon_track_cost(_weapon_id, id)), PlateUI.BODY, 24.0, 1101.0, cy - 12.0,
			PlateUI.AMBER, HORIZONTAL_ALIGNMENT_RIGHT, 100.0)
	else:
		_segments(rank, Rect2(783.0, cy - 11.0, 309.0, 22.0))


## Segmented LED bar: `rank` of MAX_RANK segments lit.
func _segments(rank: int, r: Rect2) -> void:
	var n := UpgradeManager.MAX_RANK
	var gap := 4.0
	var w := (r.size.x - gap * (n - 1)) / n
	for i in n:
		var s := Rect2(r.position.x + i * (w + gap), r.position.y, w, r.size.y)
		if i < rank:
			PlateUI.sprite(_stage, "weapon_seg_on.png", s)
		else:
			PlateUI.rect(_stage, s, Color(0.02, 0.025, 0.02, 0.55), Color(0.30, 0.33, 0.28, 0.45), 1)


func _reload_text(seconds: float) -> String:
	var per_shell := bool(UpgradeManager.get_weapon(_weapon_id).get("per_shell", false))
	return "%.1fs%s" % [seconds, "/sh" if per_shell else ""]


func _select_weapon(weapon_id: String) -> void:
	_weapon_id = weapon_id
	_pick_first_track()
	_rebuild()


func _select_track(track_id: String) -> void:
	_track_id = track_id
	_rebuild()
