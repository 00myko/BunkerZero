class_name ViewmodelTunePanel
extends Control

## P live tune board. Pose every gun, then nudge feel while you play.

signal weapon_chosen(weapon_id: String)
signal hip_pressed
signal ready_pressed
signal reset_pressed
signal lock_pressed
signal refill_pressed
signal heal_pressed

const GREEN := Color(0.38, 1.0, 0.20, 1.0)
const TEXT := Color(0.92, 0.93, 0.88, 1.0)
const DIM := Color(0.62, 0.66, 0.60, 1.0)
const WEAPONS: Array[String] = [
	"pistol", "uzi", "shotgun", "sawnoffs", "crossbow", "knife", "minigun",
	"smg", "grenade_launcher", "lmg", "sawnoff",
]

var _title: Label
var _value_labels: Dictionary = {}
var _captions: Dictionary = {}
var _sliders: Dictionary = {}
var _refreshing := false
var _weapon_id := "pistol"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 800
	visible = false
	set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	offset_left = -430.0
	offset_top = 10.0
	offset_right = -10.0
	offset_bottom = -10.0
	_build()


func show_for(weapon_id: String, target: String) -> void:
	visible = true
	_weapon_id = weapon_id
	# Changing a slider's min/max clamps its value and fires value_changed;
	# without this guard that clamped leftover (e.g. the knife's 0.08 scale)
	# was written into the newly selected gun's pose and saved.
	var was_refreshing := _refreshing
	_refreshing = true
	_apply_ranges(weapon_id)
	_refreshing = was_refreshing
	_highlight_target(target)
	_sync_feel_from_player()


func hide_panel() -> void:
	visible = false


func set_values(pos: Vector3, scale: float, rot: Vector3) -> void:
	_refreshing = true
	_set_slider("pos_x", pos.x)
	_set_slider("pos_y", pos.y)
	_set_slider("pos_z", pos.z)
	_set_slider("scale", scale)
	_set_slider("rot_x", rot.x)
	_set_slider("rot_y", rot.y)
	_set_slider("rot_z", rot.z)
	_refreshing = false


func _build() -> void:
	var plate := Panel.new()
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.03, 0.03, 0.94)
	style.border_color = Color(0.72, 0.16, 0.12, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	plate.add_theme_stylebox_override("panel", style)
	add_child(plate)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 12
	scroll.offset_top = 10
	scroll.offset_right = -12
	scroll.offset_bottom = -10
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	scroll.add_child(col)

	_title = _label(col, "DEV MENU", 20, GREEN)
	_label(col, "P open / close. Shoot while it is open to judge feel.", 11, DIM)

	_label(col, "WEAPON", 12, GREEN)
	var row_a := HBoxContainer.new()
	row_a.add_theme_constant_override("separation", 6)
	col.add_child(row_a)
	_weapon_button(row_a, "pistol", "PISTOL")
	_weapon_button(row_a, "uzi", "UZI")
	_weapon_button(row_a, "shotgun", "SHOTGUN")
	var row_b := HBoxContainer.new()
	row_b.add_theme_constant_override("separation", 6)
	col.add_child(row_b)
	_weapon_button(row_b, "sawnoffs", "SAWN")
	_weapon_button(row_b, "crossbow", "BOW")
	_weapon_button(row_b, "knife", "KNIFE")
	_weapon_button(row_b, "minigun", "MINI")
	var row_c := HBoxContainer.new()
	row_c.add_theme_constant_override("separation", 6)
	col.add_child(row_c)
	_weapon_button(row_c, "smg", "SMG")
	_weapon_button(row_c, "grenade_launcher", "GL")
	_weapon_button(row_c, "lmg", "LMG")
	_weapon_button(row_c, "sawnoff", "SAWN2")

	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 8)
	col.add_child(modes)
	_button(modes, "HIP  (T)", hip_pressed)
	_button(modes, "READY / ADS", ready_pressed)

	_label(col, "POSITION", 12, GREEN)
	_add_slider(col, "pos_x", "X  left / right", -1.20, 1.20, 0.001)
	_add_slider(col, "pos_y", "Y  up / down", -2.80, 0.80, 0.001)
	_add_slider(col, "pos_z", "Z  depth", -1.20, 1.20, 0.001)
	_add_slider(col, "scale", "SCALE", 0.001, 12.0, 0.001)
	_add_slider(col, "rot_x", "PITCH", -45.0, 45.0, 0.1)
	_add_slider(col, "rot_y", "YAW", 90.0, 270.0, 0.1)
	_add_slider(col, "rot_z", "ROLL", -45.0, 45.0, 0.1)

	var pose_actions := HBoxContainer.new()
	pose_actions.add_theme_constant_override("separation", 8)
	col.add_child(pose_actions)
	_button(pose_actions, "RESET POSE", reset_pressed)
	_button(pose_actions, "REFILL AMMO", refill_pressed)
	_button(pose_actions, "FULL HP", heal_pressed)

	_label(col, "FEEL  (live)", 12, GREEN)
	_add_slider(col, "feel_mouse", "MOUSE SENS", 0.0006, 0.0080, 0.0001)
	_add_slider(col, "feel_hip_fov", "HIP FOV", 60.0, 90.0, 0.5)
	_add_slider(col, "feel_ads_fov", "ADS FOV", 50.0, 75.0, 0.5)
	_add_slider(col, "feel_sprint_fov", "SPRINT FOV +", 0.0, 10.0, 0.1)
	_add_slider(col, "feel_ads_recoil", "ADS RECOIL", 0.20, 1.00, 0.01)
	_add_slider(col, "feel_walk_bob", "WALK BOB", 0.0, 2.0, 0.05)
	_add_slider(col, "feel_kick", "GUN KICK", 0.10, 6.0, 0.05)
	_add_slider(col, "feel_land", "LAND DIP", 0.02, 0.16, 0.002)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	col.add_child(footer)
	_button(footer, "CLOSE / SAVE", lock_pressed)
	_label(col, "WASD still moves. Click the world to shoot. Arrows nudge pose.", 11, DIM)


func _weapon_button(parent: Control, weapon_id: String, text: String) -> void:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 30)
	button.pressed.connect(func() -> void: weapon_chosen.emit(weapon_id))
	parent.add_child(button)


func _label(parent: Control, text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, pressed_signal: Signal) -> void:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 32)
	button.pressed.connect(func() -> void: pressed_signal.emit())
	parent.add_child(button)


func _apply_ranges(weapon_id: String) -> void:
	if weapon_id == "pistol":
		_range("pos_x", -2.00, 2.00, 0.01)
		_range("pos_y", -2.40, 0.80, 0.01)
		_range("pos_z", -2.00, 1.00, 0.01)
		_range("scale", 1.00, 14.00, 0.05)
	elif weapon_id == "uzi":
		_range("pos_x", -1.20, 1.20, 0.001)
		_range("pos_y", -2.80, 0.80, 0.001)
		_range("pos_z", -1.20, 1.20, 0.001)
		_range("scale", 0.10, 4.00, 0.01)
	elif weapon_id == "minigun":
		_range("pos_x", -1.20, 1.20, 0.001)
		_range("pos_y", -1.80, 0.80, 0.001)
		_range("pos_z", -1.60, 0.80, 0.001)
		_range("scale", 0.05, 2.00, 0.01)
	else:
		_range("pos_x", -0.80, 0.80, 0.001)
		_range("pos_y", -1.80, 0.40, 0.001)
		_range("pos_z", -0.80, 0.80, 0.001)
		_range("scale", 0.001, 0.080, 0.0005)


func _range(id: String, min_v: float, max_v: float, step: float) -> void:
	var slider := _sliders.get(id) as HSlider
	if slider == null:
		return
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step


func _add_slider(parent: Control, id: String, caption: String, min_v: float, max_v: float, step: float) -> void:
	var caption_label := _label(parent, caption, 12, TEXT)
	_value_labels[id] = caption_label
	_captions[id] = caption
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.custom_minimum_size = Vector2(10, 20)
	slider.value_changed.connect(_on_slider.bind(id, caption))
	parent.add_child(slider)
	_sliders[id] = slider


func _set_slider(id: String, value: float) -> void:
	var slider := _sliders.get(id) as HSlider
	if slider == null:
		return
	slider.value = value
	_refresh_caption(id, String(_captions.get(id, id)), value)


func _on_slider(value: float, id: String, caption: String) -> void:
	_refresh_caption(id, caption, value)
	if _refreshing:
		return
	var player := _player()
	if player == null or not player.viewmodel_tune_enabled:
		return
	if id.begins_with("feel_"):
		player._dev_set_feel(id, value)
		return
	var pos: Vector3 = player._active_tune_position()
	var rot: Vector3 = player._active_tune_rotation()
	var scl: float = player._active_tune_scale()
	match id:
		"pos_x":
			pos.x = value
		"pos_y":
			pos.y = value
		"pos_z":
			pos.z = value
		"scale":
			scl = value
		"rot_x":
			rot.x = value
		"rot_y":
			rot.y = value
		"rot_z":
			rot.z = value
	player._set_active_tune_position(pos)
	player._set_active_tune_rotation(rot)
	player._set_active_tune_scale(scl)
	player._apply_viewmodel_tune()
	player._save_viewmodel_settings()
	player._update_viewmodel_tune_label()


func _refresh_caption(id: String, caption: String, value: float) -> void:
	var label := _value_labels.get(id) as Label
	if label == null:
		return
	if id == "feel_mouse":
		label.text = "%s    %.4f" % [caption, value]
	elif id == "scale" or id.begins_with("pos") or id == "feel_land":
		label.text = "%s    %.3f" % [caption, value]
	elif id.begins_with("rot"):
		label.text = "%s    %.1f" % [caption, value]
	else:
		label.text = "%s    %.2f" % [caption, value]


func _highlight_target(target: String) -> void:
	if _title == null:
		return
	var weapon := _weapon_id.to_upper()
	var player := _player()
	if player != null and not String(player.current_weapon_id).is_empty():
		weapon = String(player.current_weapon_id).to_upper()
	_title.text = "DEV MENU  —  %s  %s" % [weapon, target.to_upper()]


func _sync_feel_from_player() -> void:
	var player := _player()
	if player == null:
		return
	_refreshing = true
	_set_slider("feel_mouse", float(player.mouse_sensitivity))
	_set_slider("feel_hip_fov", float(player.hip_fov))
	_set_slider("feel_ads_fov", float(player.ads_fov))
	_set_slider("feel_sprint_fov", float(player.sprint_fov_increase))
	_set_slider("feel_ads_recoil", float(player.ads_recoil_multiplier))
	_set_slider("feel_walk_bob", float(player.walk_weapon_motion_multiplier))
	_set_slider("feel_kick", player._dev_get_kick())
	_set_slider("feel_land", float(player.landing_camera_drop))
	_refreshing = false


func _player() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var scene := tree.current_scene
	if scene != null:
		var direct := scene.get_node_or_null("Player")
		if direct != null:
			return direct
		var nested := scene.find_child("Player", true, false)
		if nested != null:
			return nested
	return tree.root.find_child("Player", true, false)
