class_name UpgradeTerminal
extends Control

## The three hub tables (WEAPON SYSTEMS / SURVIVOR VITALS / ZOMBIE PAYOUT) on a
## riveted steel plate over the live hub, plus the proximity prompt. Every row
## is built from UpgradeManager's tables, so a new gun, vitals row or zombie
## type shows up here with no UI change. World interaction and pausing live in
## upgrade_ui_controller.gd.

signal prompt_pressed
signal close_pressed
signal install_pressed

const TABLES := {
	"weapon": {"title": "title_weapon_systems.png", "name": "WEAPON SYSTEMS"},
	"survivor": {"title": "title_survivor_vitals.png", "name": "SURVIVOR VITALS"},
	"earnings": {"title": "title_zombie_payout.png", "name": "ZOMBIE PAYOUT"},
}

var interaction_prompt: Button = null

var _overlay: Control = null
var _stage: Control = null
var _title: TextureRect = null
var _bank_value: Label = null
var _body: Control = null
var _status: Label = null
var _status_cost: Label = null
var _install: Button = null
var _last_viewport := Vector2.ZERO

var _table := ""
var _weapon_id := "pistol"
var _track_id := "damage"
var _survivor_row := "max_health"
var _gun_rows: Dictionary = {}
var _gun_scroll: ScrollContainer = null
var _refresh_queued := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_prompt()
	_build_overlay()
	EconomyManager.money_changed.connect(func(_b: int) -> void: refresh())
	UpgradeManager.upgrades_changed.connect(refresh)
	_layout()


func _process(_delta: float) -> void:
	if get_viewport().get_visible_rect().size != _last_viewport:
		_layout()


func _layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	_last_viewport = vp
	SteelUI.fit_stage(_stage, vp)
	var s := minf(vp.x / SteelUI.DESIGN.x, vp.y / SteelUI.DESIGN.y)
	interaction_prompt.scale = Vector2(s, s)
	interaction_prompt.size = Vector2(470.0, 62.0)
	interaction_prompt.position = Vector2((vp.x - 470.0 * s) * 0.5, vp.y - 138.0 * s)

# ------------------------------------------------------------------ public API

func is_popup_open() -> bool:
	return _overlay != null and _overlay.visible


func set_prompt_visible(shown: bool, label_text: String = "") -> void:
	interaction_prompt.visible = shown
	if shown and not label_text.is_empty():
		interaction_prompt.text = label_text


func table_name(table: String) -> String:
	return String(TABLES.get(table, {}).get("name", "UPGRADE TERMINAL"))


func open_popup(table: String = "weapon") -> void:
	_table = table if TABLES.has(table) else "weapon"
	_title.texture = SteelUI.tex(SteelUI.ART + String(TABLES[_table]["title"]))
	if _table == "weapon":
		var primary := String(RunManager.run_primary_weapon)
		if not UpgradeManager.get_weapon(primary).is_empty() and bool(UpgradeManager.get_weapon(primary).get("listed", true)):
			_weapon_id = primary
		_pick_first_track()
	interaction_prompt.visible = false
	_overlay.visible = true
	_rebuild_body()


func close_popup() -> void:
	_overlay.visible = false
	_clear(_body)
	_gun_rows.clear()


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
		_rebuild_body()

# ------------------------------------------------------------------ frame

func _build_prompt() -> void:
	interaction_prompt = Button.new()
	interaction_prompt.name = "UpgradeInteractionPrompt"
	interaction_prompt.visible = false
	interaction_prompt.z_index = 850
	interaction_prompt.focus_mode = Control.FOCUS_NONE
	interaction_prompt.add_theme_font_override("font", SteelUI.font())
	interaction_prompt.add_theme_font_size_override("font_size", 24)
	var face := SteelUI.plate("row_green.png", 14.0, 0.0)
	for key in ["normal", "hover", "pressed", "hover_pressed"]:
		interaction_prompt.add_theme_stylebox_override(key, face)
	interaction_prompt.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		interaction_prompt.add_theme_color_override(key, SteelUI.GREEN)
	interaction_prompt.pressed.connect(func() -> void: prompt_pressed.emit())
	add_child(interaction_prompt)


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.name = "UpgradePopupOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	_overlay.z_index = 900
	add_child(_overlay)

	# Dim, don't hide, the live 3D hub behind the plate.
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.02, 0.0, 0.52)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(dim)

	_stage = Control.new()
	_stage.name = "Stage"
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_stage)

	var panel := PanelContainer.new()
	panel.name = "SteelPlate"
	panel.position = Vector2(20.0, 14.0)
	panel.size = SteelUI.DESIGN - Vector2(40.0, 28.0)
	panel.add_theme_stylebox_override("panel", SteelUI.plate("panel_steel.png", 40.0, 34.0))
	_stage.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	# Header: stencil title + bank.
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0.0, 62.0)
	column.add_child(header)
	_title = TextureRect.new()
	_title.name = "Title"
	_title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_title.custom_minimum_size = Vector2(560.0, 56.0)
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_title)
	header.add_child(SteelUI.spacer())
	var bank := SteelUI.well(10.0)
	bank.custom_minimum_size = Vector2(250.0, 0.0)
	header.add_child(bank)
	var bank_row := HBoxContainer.new()
	bank_row.add_theme_constant_override("separation", 12)
	bank.add_child(bank_row)
	bank_row.add_child(SteelUI.label("BANK", 20, SteelUI.TEXT_DIM))
	_bank_value = SteelUI.label("$0", 34, SteelUI.AMBER, HORIZONTAL_ALIGNMENT_RIGHT)
	_bank_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_row.add_child(_bank_value)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	rule.color = Color(SteelUI.GREEN.r, SteelUI.GREEN.g, SteelUI.GREEN.b, 0.35)
	column.add_child(rule)

	_body = Control.new()
	_body.name = "Body"
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_body)

	# Footer: what INSTALL buys, then CLOSE + INSTALL.
	var footer := HBoxContainer.new()
	footer.custom_minimum_size = Vector2(0.0, 64.0)
	footer.add_theme_constant_override("separation", 16)
	column.add_child(footer)
	var status_box := VBoxContainer.new()
	status_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_box.add_theme_constant_override("separation", 0)
	status_box.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_child(status_box)
	_status = SteelUI.label("", 20, SteelUI.TEXT_DIM)
	status_box.add_child(_status)
	_status_cost = SteelUI.label("", 30, SteelUI.AMBER)
	status_box.add_child(_status_cost)
	var close := SteelUI.action_button("CLOSE", false, Vector2(210.0, 62.0))
	close.name = "CloseButton"
	close.pressed.connect(func() -> void: close_pressed.emit())
	footer.add_child(close)
	_install = SteelUI.action_button("INSTALL", true, Vector2(250.0, 62.0))
	_install.name = "InstallButton"
	_install.pressed.connect(func() -> void: install_pressed.emit())
	footer.add_child(_install)


func _rebuild_body() -> void:
	var keep_scroll := _gun_scroll.scroll_vertical if is_instance_valid(_gun_scroll) else 0
	_clear(_body)
	_gun_rows.clear()
	_gun_scroll = null
	_bank_value.text = SteelUI.money(EconomyManager.get_balance())
	var root: Control
	match _table:
		"weapon":
			root = _build_weapon_screen()
		"survivor":
			root = _build_survivor_screen()
		_:
			root = _build_payout_screen()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.add_child(root)
	if _gun_scroll != null and keep_scroll > 0:
		_gun_scroll.set_deferred("scroll_vertical", keep_scroll)


## cost < 0 means maxed / not applicable; `why` explains that case.
func _set_footer(caption: String, cost: int, why: String) -> void:
	if cost < 0:
		_status.text = caption
		_status_cost.text = why
		_status_cost.add_theme_color_override("font_color", SteelUI.GREEN if why == "MAXED" else SteelUI.LOCKED)
		_install.disabled = true
		return
	var short := cost - EconomyManager.get_balance()
	_status.text = caption if short <= 0 else "%s  //  NEED %s MORE" % [caption, SteelUI.money(short)]
	_status_cost.text = SteelUI.money(cost)
	_status_cost.add_theme_color_override("font_color", SteelUI.AMBER)
	_install.disabled = short > 0


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

# ------------------------------------------------------------------ WEAPON SYSTEMS

func _pick_first_track() -> void:
	if UpgradeManager.is_track_available(_weapon_id, _track_id):
		return
	for track in UpgradeManager.TRACKS:
		if UpgradeManager.is_track_available(_weapon_id, track["id"]):
			_track_id = track["id"]
			return


func _build_weapon_screen() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)

	# Left: riveted gun list, selected = green bar.
	var list_well := SteelUI.well(10.0)
	list_well.custom_minimum_size = Vector2(300.0, 0.0)
	list_well.mouse_filter = Control.MOUSE_FILTER_PASS
	h.add_child(list_well)
	_gun_scroll = ScrollContainer.new()
	_gun_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_well.add_child(_gun_scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	_gun_scroll.add_child(list)
	for gun in UpgradeManager.listed_weapons():
		var id := String(gun["id"])
		var row := SteelUI.row_button(40.0)
		SteelUI.set_row_selected(row, id == _weapon_id)
		row.pressed.connect(_select_weapon.bind(id))
		var c := SteelUI.row_content(row, 40.0, 22.0)
		c.add_child(SteelUI.label(String(gun["name"]), 22, SteelUI.GREEN if id == _weapon_id else SteelUI.TEXT_LIGHT))
		c.add_child(SteelUI.spacer())
		c.add_child(SteelUI.label("LV %d" % UpgradeManager.get_weapon_tier(id), 18, SteelUI.GREEN_SOFT if id == _weapon_id else SteelUI.TEXT_DIM))
		list.add_child(row)
		_gun_rows[id] = row

	# Right: gun plate + live stats, then the five tracks.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	h.add_child(right)
	var gun := UpgradeManager.get_weapon(_weapon_id)

	var top := HBoxContainer.new()
	top.custom_minimum_size = Vector2(0.0, 168.0)
	top.add_theme_constant_override("separation", 12)
	right.add_child(top)
	var plate := SteelUI.well(12.0)
	plate.custom_minimum_size = Vector2(390.0, 0.0)
	top.add_child(plate)
	var plate_v := VBoxContainer.new()
	plate_v.add_theme_constant_override("separation", 0)
	plate.add_child(plate_v)
	var art := TextureRect.new()
	art.texture = SteelUI.tex("res://assets/UI/weapon_%s.png" % _weapon_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate_v.add_child(art)
	plate_v.add_child(SteelUI.label(String(gun.get("name", _weapon_id.to_upper())), 30, SteelUI.GREEN))
	plate_v.add_child(SteelUI.label(String(gun.get("subtitle", "")), 17, SteelUI.TEXT_DIM))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	top.add_child(grid)
	var stats := [
		["DMG", "%.0f" % UpgradeManager.get_weapon_damage(_weapon_id)],
		["MAG", "%d" % UpgradeManager.get_weapon_mag(_weapon_id)],
		["RATE", "%.0f RPM" % (60.0 / UpgradeManager.get_weapon_shot_interval(_weapon_id))],
		["RELOAD", _reload_text(UpgradeManager.get_weapon_reload_time(_weapon_id))],
	]
	for stat in stats:
		var cell := SteelUI.well(10.0)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var cell_h := HBoxContainer.new()
		cell.add_child(cell_h)
		cell_h.add_child(SteelUI.label(stat[0], 20, SteelUI.TEXT_DIM))
		cell_h.add_child(SteelUI.spacer())
		cell_h.add_child(SteelUI.label(stat[1], 32, SteelUI.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_RIGHT))
		grid.add_child(cell)

	for track in UpgradeManager.TRACKS:
		right.add_child(_weapon_track_row(track))

	var track_name := _track_name(_track_id)
	var cost := UpgradeManager.get_weapon_track_cost(_weapon_id, _track_id)
	var maxed := UpgradeManager.get_weapon_rank(_weapon_id, _track_id) >= UpgradeManager.MAX_RANK
	_set_footer("%s  //  %s  RANK %d" % [String(gun.get("name", "")), track_name,
		mini(UpgradeManager.get_weapon_rank(_weapon_id, _track_id) + 1, UpgradeManager.MAX_RANK)],
		cost, "MAXED" if maxed else "N/A FOR THIS GUN")
	return h


func _weapon_track_row(track: Dictionary) -> Control:
	var id := String(track["id"])
	var available := UpgradeManager.is_track_available(_weapon_id, id)
	var rank := UpgradeManager.get_weapon_rank(_weapon_id, id)
	var selected := available and id == _track_id
	var row := SteelUI.row_button(52.0)
	SteelUI.set_row_selected(row, selected)
	row.disabled = not available
	if available:
		row.pressed.connect(_select_track.bind(id))
	var c := SteelUI.row_content(row)
	var name_label := SteelUI.label(String(track["name"]), 24, SteelUI.GREEN if selected else (SteelUI.TEXT_LIGHT if available else SteelUI.LOCKED))
	name_label.custom_minimum_size = Vector2(190.0, 0.0)
	c.add_child(name_label)
	c.add_child(SteelUI.pips(rank, UpgradeManager.MAX_RANK, Vector2(26.0, 14.0), not available, selected))
	var value := SteelUI.label("", 24, SteelUI.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cost_label := SteelUI.label("", 24, SteelUI.AMBER, HORIZONTAL_ALIGNMENT_RIGHT)
	cost_label.custom_minimum_size = Vector2(110.0, 0.0)
	if not available:
		value.text = "N/A"
		value.add_theme_color_override("font_color", SteelUI.LOCKED)
		cost_label.text = "LOCKED"
		cost_label.add_theme_color_override("font_color", SteelUI.LOCKED)
	else:
		var now := _track_value(id, rank)
		if rank >= UpgradeManager.MAX_RANK:
			value.text = now
			cost_label.text = "MAX"
			cost_label.add_theme_color_override("font_color", SteelUI.GREEN)
		else:
			value.text = "%s  >  %s" % [now, _track_value(id, rank + 1)]
			cost_label.text = SteelUI.money(UpgradeManager.get_weapon_track_cost(_weapon_id, id))
	c.add_child(value)
	c.add_child(cost_label)
	return row


func _track_value(track_id: String, rank: int) -> String:
	var v := UpgradeManager.get_weapon_stat_at(_weapon_id, track_id, rank)
	match track_id:
		"rate":
			return "%.0f RPM" % v
		"reload":
			return _reload_text(v)
	return "%.0f" % v


func _reload_text(seconds: float) -> String:
	var per_shell := bool(UpgradeManager.get_weapon(_weapon_id).get("per_shell", false))
	return "%.2fs%s" % [seconds, "/SH" if per_shell else ""]


func _track_name(track_id: String) -> String:
	for track in UpgradeManager.TRACKS:
		if track["id"] == track_id:
			return String(track["name"])
	return track_id.to_upper()


func _select_weapon(weapon_id: String) -> void:
	_weapon_id = weapon_id
	_pick_first_track()
	_rebuild_body()


func _select_track(track_id: String) -> void:
	_track_id = track_id
	_rebuild_body()

# ------------------------------------------------------------------ SURVIVOR VITALS

func _build_survivor_screen() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var selected_row := UpgradeManager.get_survivor_row(_survivor_row)
	if not bool(selected_row.get("unlocked", false)):
		_survivor_row = String(UpgradeManager.SURVIVOR[0]["id"])
		selected_row = UpgradeManager.SURVIVOR[0]
	for entry in UpgradeManager.SURVIVOR:
		v.add_child(_survivor_row_control(entry))

	var note := SteelUI.well(12.0)
	note.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(note)
	var note_text := SteelUI.label("", 20, SteelUI.TEXT_DIM)
	note_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	note_text.text = _survivor_note(selected_row)
	note.add_child(note_text)

	var rank := UpgradeManager.get_survivor_rank(_survivor_row)
	_set_footer("%s  RANK %d" % [String(selected_row["name"]), mini(rank + 1, UpgradeManager.MAX_RANK)],
		UpgradeManager.get_survivor_cost(_survivor_row), "MAXED")
	return v


func _survivor_row_control(entry: Dictionary) -> Control:
	var id := String(entry["id"])
	var unlocked := bool(entry.get("unlocked", false))
	var selected := unlocked and id == _survivor_row
	var rank := UpgradeManager.get_survivor_rank(id)
	var row := SteelUI.row_button(66.0)
	SteelUI.set_row_selected(row, selected)
	row.disabled = not unlocked
	if unlocked:
		row.pressed.connect(_select_survivor.bind(id))
	var c := SteelUI.row_content(row)
	var tint := SteelUI.GREEN if selected else (SteelUI.TEXT_LIGHT if unlocked else SteelUI.LOCKED)
	c.add_child(SteelUI.icon(String(entry.get("icon", "icon_lock.svg")) if unlocked else "icon_lock.svg", 38.0, tint if unlocked else SteelUI.LOCKED))
	var name_label := SteelUI.label(String(entry["name"]), 28, tint)
	name_label.custom_minimum_size = Vector2(230.0, 0.0)
	c.add_child(name_label)
	c.add_child(SteelUI.pips(rank, UpgradeManager.MAX_RANK, Vector2(30.0, 16.0), not unlocked, selected))
	var value := SteelUI.label("", 26, SteelUI.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tag := SteelUI.label("", 18, SteelUI.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	tag.custom_minimum_size = Vector2(130.0, 0.0)
	var cost_label := SteelUI.label("", 26, SteelUI.AMBER, HORIZONTAL_ALIGNMENT_RIGHT)
	cost_label.custom_minimum_size = Vector2(120.0, 0.0)
	if not unlocked:
		value.text = "--"
		value.add_theme_color_override("font_color", SteelUI.LOCKED)
		tag.text = "LOCKED"
		tag.add_theme_color_override("font_color", SteelUI.LOCKED)
		cost_label.text = "--"
		cost_label.add_theme_color_override("font_color", SteelUI.LOCKED)
	else:
		var fmt := String(entry.get("format", "%d"))
		var now := fmt % int(UpgradeManager.get_survivor_value(id, rank))
		if rank >= UpgradeManager.MAX_RANK:
			value.text = now
			cost_label.text = "MAX"
			cost_label.add_theme_color_override("font_color", SteelUI.GREEN)
		else:
			value.text = "%s  >  %s" % [now, fmt % int(UpgradeManager.get_survivor_value(id, rank + 1))]
			cost_label.text = SteelUI.money(UpgradeManager.get_survivor_cost(id))
		var live := bool(entry.get("live", false))
		tag.text = "IN COMBAT" if live else "STORED"
		tag.add_theme_color_override("font_color", SteelUI.GREEN_SOFT if live else SteelUI.TEXT_DIM)
	c.add_child(value)
	c.add_child(tag)
	c.add_child(cost_label)
	return row


func _survivor_note(entry: Dictionary) -> String:
	if bool(entry.get("live", false)):
		return "%s  //  APPLIES TO EVERY RUN FROM THE NEXT SPAWN. RANKS ARE PERMANENT." % String(entry["name"])
	return "%s  //  STORED RANK. THERE ARE NO MEDKITS IN COMBAT YET; THIS VALUE IS SAVED AND APPLIES WHEN THEY SHIP." % String(entry["name"])


func _select_survivor(row_id: String) -> void:
	_survivor_row = row_id
	_rebuild_body()

# ------------------------------------------------------------------ ZOMBIE PAYOUT

func _build_payout_screen() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var rank := UpgradeManager.get_payout_rank()
	var maxed := rank >= UpgradeManager.MAX_RANK

	var list_well := SteelUI.well(10.0)
	list_well.custom_minimum_size = Vector2(600.0, 0.0)
	h.add_child(list_well)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list_well.add_child(list)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	list.add_child(head)
	var head_type := SteelUI.label("ZOMBIE TYPE", 18, SteelUI.TEXT_DIM)
	head_type.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_type.custom_minimum_size = Vector2(0.0, 26.0)
	var head_base := SteelUI.label("BASE", 18, SteelUI.TEXT_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	head_base.custom_minimum_size = Vector2(80.0, 0.0)
	var head_pay := SteelUI.label("PAYS / KILL", 18, SteelUI.TEXT_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	head_pay.custom_minimum_size = Vector2(170.0, 0.0)
	head.add_child(SteelUI.spacer(14.0))
	head.add_child(head_type)
	head.add_child(head_base)
	head.add_child(head_pay)
	head.add_child(SteelUI.spacer(10.0))
	head.get_child(0).size_flags_horizontal = Control.SIZE_FILL
	head.get_child(4).size_flags_horizontal = Control.SIZE_FILL
	for entry in UpgradeManager.ZOMBIE_TYPES:
		list.add_child(_payout_row(entry, rank))

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	h.add_child(right)
	var mult_well := SteelUI.well(16.0)
	right.add_child(mult_well)
	var mult_v := VBoxContainer.new()
	mult_well.add_child(mult_v)
	mult_v.add_child(SteelUI.label("KILL PAYOUT MULTIPLIER", 20, SteelUI.TEXT_DIM))
	var mult_h := HBoxContainer.new()
	mult_v.add_child(mult_h)
	mult_h.add_child(SteelUI.label("x%.2f" % UpgradeManager.get_earnings_multiplier(), 72, SteelUI.GREEN))
	mult_h.add_child(SteelUI.spacer())
	mult_h.add_child(SteelUI.label("MAXED" if maxed else "NEXT  x%.2f" % UpgradeManager.PAYOUT_MULTIPLIERS[rank + 1],
		30, SteelUI.GREEN if maxed else SteelUI.GREEN_SOFT, HORIZONTAL_ALIGNMENT_RIGHT))

	# Multiplier bar: one plate per rank, lit up to the installed rank.
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	right.add_child(bar)
	for i in UpgradeManager.PAYOUT_MULTIPLIERS.size():
		var seg := PanelContainer.new()
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seg.custom_minimum_size = Vector2(0.0, 64.0)
		var lit := i <= rank
		var is_next := i == rank + 1
		var box := SteelUI.flat(SteelUI.GREEN_DARK if lit else Color(0.06, 0.065, 0.06),
			SteelUI.GREEN if lit else (SteelUI.GREEN_SOFT if is_next else Color(0.25, 0.27, 0.25)), 2)
		if lit:
			box.shadow_color = Color(SteelUI.GREEN.r, SteelUI.GREEN.g, SteelUI.GREEN.b, 0.35)
			box.shadow_size = 5
		seg.add_theme_stylebox_override("panel", box)
		seg.add_child(SteelUI.label("x%.2f" % UpgradeManager.PAYOUT_MULTIPLIERS[i], 22,
			SteelUI.GREEN if lit else (SteelUI.GREEN_SOFT if is_next else SteelUI.LOCKED), HORIZONTAL_ALIGNMENT_CENTER))
		bar.add_child(seg)

	var note := SteelUI.well(14.0)
	note.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(note)
	var note_text := SteelUI.label(
		"EVERY KILL PAYS ITS BASE BOUNTY x THE MULTIPLIER, BANKED THE MOMENT IT DROPS. INSTALL BUYS THE NEXT MULTIPLIER ONLY.",
		20, SteelUI.TEXT_DIM)
	note_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	note.add_child(note_text)

	_set_footer("PAYOUT RANK %d  //  x%.2f" % [mini(rank + 1, UpgradeManager.MAX_RANK),
		UpgradeManager.PAYOUT_MULTIPLIERS[mini(rank + 1, UpgradeManager.MAX_RANK)]],
		UpgradeManager.get_payout_cost(), "MAXED")
	return h


func _payout_row(entry: Dictionary, rank: int) -> Control:
	var unlocked := bool(entry.get("unlocked", false))
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0.0, 50.0)
	row.add_theme_stylebox_override("panel", SteelUI.plate("row_steel.png", 14.0, 0.0))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var c := HBoxContainer.new()
	c.add_theme_constant_override("separation", 14)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 22)
	pad.add_theme_constant_override("margin_right", 22)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(c)
	row.add_child(pad)
	var tint := SteelUI.TEXT_LIGHT if unlocked else SteelUI.LOCKED
	c.add_child(SteelUI.icon("icon_skull.svg" if unlocked else "icon_lock.svg", 30.0, tint))
	var name_label := SteelUI.label(String(entry.get("name", "")), 24, tint)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.add_child(name_label)
	var base := SteelUI.label(SteelUI.money(int(entry.get("base_reward", 0))) if unlocked else "--", 22, SteelUI.TEXT_DIM if unlocked else SteelUI.LOCKED, HORIZONTAL_ALIGNMENT_RIGHT)
	base.custom_minimum_size = Vector2(80.0, 0.0)
	c.add_child(base)
	var pays := SteelUI.label("--", 26, SteelUI.LOCKED, HORIZONTAL_ALIGNMENT_RIGHT)
	pays.custom_minimum_size = Vector2(170.0, 0.0)
	if unlocked:
		var reward := UpgradeManager.get_zombie_reward(String(entry["id"]))
		pays.text = SteelUI.money(reward)
		pays.add_theme_color_override("font_color", SteelUI.AMBER)
		if rank < UpgradeManager.MAX_RANK:
			var next := int(round(float(entry["base_reward"]) * UpgradeManager.PAYOUT_MULTIPLIERS[rank + 1]))
			pays.text = "%s  >  %s" % [SteelUI.money(reward), SteelUI.money(next)]
	c.add_child(pays)
	return row
