extends Node

## Persists mobile HUD layout, movement mode, and look settings.
## Positions are always stored as normalized viewport coordinates.

const SETTINGS_PATH := "user://control_settings.cfg"
const SETTINGS_VERSION := 2
const REFERENCE_HEIGHT := 941.0

const MODE_FIXED := 0
const MODE_FLOATING := 1
const MODE_TOUCH_ZONE := 2

const PRESET_DEFAULT := "default"
const PRESET_COMPACT := "compact"
const PRESET_LARGE := "large"

const CONTROL_IDS := [
	"joystick", "shoot", "aim", "jump", "sprint", "crouch", "reload", "melee", "interact", "swap", "pause"
]
## Order and captions for the settings chip row and HUD button labels.
const CONTROL_LABELS := {
	"joystick": "JOYSTICK",
	"shoot": "SHOOT",
	"aim": "AIM",
	"jump": "JUMP",
	"sprint": "SPRINT",
	"crouch": "CROUCH",
	"reload": "RELOAD",
	"melee": "MELEE",
	"interact": "INTERACT",
	"swap": "SWAP",
	"pause": "PAUSE",
}
const ZONE_IDS := ["movement_zone", "look_zone"]
## Controls pinned to their stock rect. They still render and work, but the
## layout editors cannot move, resize, hide or fade them, and saved overrides
## are discarded on load.
const LOCKED_CONTROL_IDS := ["pause"]

signal settings_changed
signal layout_changed
signal movement_mode_changed(mode: int)

var control_settings_version: int = SETTINGS_VERSION
var movement_mode: int = MODE_FIXED
var joystick_deadzone: float = 0.16
var joystick_activation_radius: float = 1.15
var look_sensitivity_h: float = 0.0032
var look_sensitivity_v: float = 0.0032
var invert_y: bool = false
var look_smoothing: float = 0.0
var show_touch_zone_indicator: bool = true
## Multipliers applied on top of each control's own scale / opacity.
var global_button_scale: float = 1.0
var global_button_opacity: float = 1.0
var show_button_labels: bool = true
var aim_assist: bool = true
var gyroscope_enabled: bool = false
var gyroscope_sensitivity: float = 1.0
var haptics_enabled: bool = true
var master_volume: float = 100.0
var render_scale: float = 1.0
## 0 = uncapped.
var fps_cap: int = 60

## When true, HUD/player skip rewriting control positions so the editor can drag them.
var suspend_hud_layout: bool = false

var _controls: Dictionary = {}
var _snapshot: Dictionary = {}


func _ready() -> void:
	_controls = _default_controls()
	fps_cap = _default_fps_cap()
	load_settings()
	apply_audio()
	call_deferred("apply_graphics")


func is_locked(control_id: String) -> bool:
	return LOCKED_CONTROL_IDS.has(control_id)


## CONTROL_IDS minus the locked ones: what the Settings editor offers.
func editable_control_ids() -> Array:
	var ids: Array = []
	for control_id in CONTROL_IDS:
		if not is_locked(control_id):
			ids.append(control_id)
	return ids


func get_control(control_id: String) -> Dictionary:
	if not _controls.has(control_id):
		_controls[control_id] = _default_control(control_id)
	return (_controls[control_id] as Dictionary).duplicate(true)


func set_control(control_id: String, data: Dictionary, emit_change: bool = true) -> void:
	var merged := _default_control(control_id)
	merged.merge(data, true)
	_controls[control_id] = _sanitize_control(control_id, merged)
	if emit_change:
		layout_changed.emit()
		settings_changed.emit()


func update_control(control_id: String, key: String, value: Variant, emit_change: bool = true) -> void:
	var data := get_control(control_id)
	data[key] = value
	set_control(control_id, data, emit_change)


func set_movement_mode(mode: int, emit_change: bool = true) -> void:
	movement_mode = clampi(mode, MODE_FIXED, MODE_TOUCH_ZONE)
	if emit_change:
		movement_mode_changed.emit(movement_mode)
		settings_changed.emit()


func set_look_sensitivity(horizontal: float, vertical: float, emit_change: bool = true) -> void:
	look_sensitivity_h = clampf(horizontal, 0.0010, 0.0100)
	look_sensitivity_v = clampf(vertical, 0.0010, 0.0100)
	if emit_change:
		settings_changed.emit()


func set_invert_y(enabled: bool, emit_change: bool = true) -> void:
	invert_y = enabled
	if emit_change:
		settings_changed.emit()


func set_look_smoothing(amount: float, emit_change: bool = true) -> void:
	look_smoothing = clampf(amount, 0.0, 0.85)
	if emit_change:
		settings_changed.emit()


func set_global_button_scale(value: float, emit_change: bool = true) -> void:
	global_button_scale = clampf(value, 0.6, 1.5)
	if emit_change:
		layout_changed.emit()
		settings_changed.emit()


func set_global_button_opacity(value: float, emit_change: bool = true) -> void:
	global_button_opacity = clampf(value, 0.2, 1.0)
	if emit_change:
		layout_changed.emit()
		settings_changed.emit()


func set_show_button_labels(enabled: bool, emit_change: bool = true) -> void:
	show_button_labels = enabled
	if emit_change:
		layout_changed.emit()
		settings_changed.emit()


func set_aim_assist(enabled: bool, emit_change: bool = true) -> void:
	aim_assist = enabled
	if emit_change:
		settings_changed.emit()


func set_gyroscope_enabled(enabled: bool, emit_change: bool = true) -> void:
	gyroscope_enabled = enabled
	if emit_change:
		settings_changed.emit()


func set_gyroscope_sensitivity(value: float, emit_change: bool = true) -> void:
	gyroscope_sensitivity = clampf(value, 0.25, 2.5)
	if emit_change:
		settings_changed.emit()


func set_haptics_enabled(enabled: bool, emit_change: bool = true) -> void:
	haptics_enabled = enabled
	if emit_change:
		settings_changed.emit()


func set_master_volume(value: float, emit_change: bool = true) -> void:
	master_volume = clampf(value, 0.0, 100.0)
	apply_audio()
	if emit_change:
		settings_changed.emit()


func set_render_scale(value: float, emit_change: bool = true) -> void:
	render_scale = clampf(value, 0.5, 1.0)
	apply_graphics()
	if emit_change:
		settings_changed.emit()


func set_fps_cap(value: int, emit_change: bool = true) -> void:
	fps_cap = maxi(value, 0)
	apply_graphics()
	if emit_change:
		settings_changed.emit()


func apply_audio() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	AudioServer.set_bus_mute(bus, master_volume <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume / 100.0, 0.0001)))


func apply_graphics() -> void:
	Engine.max_fps = fps_cap
	var tree := get_tree()
	if tree != null and tree.root != null:
		tree.root.scaling_3d_scale = render_scale


func _default_fps_cap() -> int:
	# Mobile gameplay is capped to keep high-refresh iPhones cool. Desktop builds
	# default to uncapped.
	if OS.has_feature("mobile") or OS.get_name() == "iOS" or OS.get_name() == "Android":
		return 60
	return 0


func set_joystick_deadzone(value: float, emit_change: bool = true) -> void:
	joystick_deadzone = clampf(value, 0.04, 0.45)
	if emit_change:
		settings_changed.emit()


func set_joystick_activation_radius(value: float, emit_change: bool = true) -> void:
	joystick_activation_radius = clampf(value, 0.70, 1.80)
	if emit_change:
		settings_changed.emit()


func default_pixel_size(control_id: String, viewport_size: Vector2) -> Vector2:
	var scale_y := _height_scale(viewport_size)
	match control_id:
		"joystick":
			return Vector2(282.0, 282.0) * scale_y
		"shoot":
			return Vector2(204.0, 204.0) * scale_y
		"jump":
			return Vector2(124.0, 124.0) * scale_y
		"sprint":
			return Vector2(142.0, 142.0) * scale_y
		"swap":
			return Vector2(108.0, 56.0) * scale_y
		"pause":
			return Vector2(58.0, 58.0) * scale_y
		"aim":
			return Vector2(116.0, 116.0) * scale_y
		"reload", "crouch", "melee", "interact":
			return Vector2(104.0, 104.0) * scale_y
		"movement_zone":
			return Vector2(viewport_size.x * 0.42, viewport_size.y * 0.80)
		"look_zone":
			return Vector2(viewport_size.x * 0.64, viewport_size.y)
		_:
			return Vector2(120.0, 120.0) * scale_y


func pixel_size(control_id: String, viewport_size: Vector2) -> Vector2:
	if is_locked(control_id):
		return default_pixel_size(control_id, viewport_size)
	var data := get_control(control_id)
	var size := default_pixel_size(control_id, viewport_size) * float(data.get("scale", 1.0))
	if not control_id.ends_with("_zone"):
		size *= global_button_scale
	if control_id.ends_with("_zone"):
		size.x = viewport_size.x * float(data.get("nw", 0.42))
		size.y = viewport_size.y * float(data.get("nh", 0.80))
	return size


func pixel_position(control_id: String, viewport_size: Vector2) -> Vector2:
	var data := get_control(control_id)
	var size := pixel_size(control_id, viewport_size)
	var pos := Vector2(
		float(data.get("nx", 0.0)) * viewport_size.x,
		float(data.get("ny", 0.0)) * viewport_size.y
	)
	return clamp_position(pos, size, viewport_size)


func pixel_rect(control_id: String, viewport_size: Vector2) -> Rect2:
	return Rect2(pixel_position(control_id, viewport_size), pixel_size(control_id, viewport_size))


func control_opacity(control_id: String) -> float:
	if is_locked(control_id):
		return 1.0
	var own := clampf(float(get_control(control_id).get("opacity", 1.0)), 0.15, 1.0)
	if control_id.ends_with("_zone"):
		return own
	return clampf(own * global_button_opacity, 0.1, 1.0)


func control_visible(control_id: String) -> bool:
	if is_locked(control_id):
		return true
	return bool(get_control(control_id).get("visible", true))


func set_pixel_rect(control_id: String, rect: Rect2, viewport_size: Vector2, emit_change: bool = false) -> void:
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0 or is_locked(control_id):
		return
	var safe := clamp_rect(rect, viewport_size)
	var data := get_control(control_id)
	data["nx"] = safe.position.x / viewport_size.x
	data["ny"] = safe.position.y / viewport_size.y
	if control_id.ends_with("_zone"):
		data["nw"] = clampf(safe.size.x / viewport_size.x, 0.18, 0.80)
		data["nh"] = clampf(safe.size.y / viewport_size.y, 0.28, 1.0)
	else:
		var base := default_pixel_size(control_id, viewport_size) * global_button_scale
		var ratio := 1.0
		if base.x > 0.0:
			ratio = safe.size.x / base.x
		data["scale"] = clampf(ratio, 0.55, 1.85)
	set_control(control_id, data, emit_change)


func safe_area_rect(viewport_size: Vector2) -> Rect2:
	var left := maxf(viewport_size.x * 0.012, 10.0)
	var top := maxf(viewport_size.y * 0.028, 16.0)
	var right := maxf(viewport_size.x * 0.012, 10.0)
	var bottom := maxf(viewport_size.y * 0.046, 22.0)
	var display_safe := DisplayServer.get_display_safe_area()
	var window_size := Vector2(DisplayServer.window_get_size())
	if display_safe.size.x > 0.0 and display_safe.size.y > 0.0 and window_size.x > 0.0 and window_size.y > 0.0:
		left = maxf(left, (display_safe.position.x / window_size.x) * viewport_size.x)
		top = maxf(top, (display_safe.position.y / window_size.y) * viewport_size.y)
		right = maxf(right, ((window_size.x - display_safe.end.x) / window_size.x) * viewport_size.x)
		bottom = maxf(bottom, ((window_size.y - display_safe.end.y) / window_size.y) * viewport_size.y)
	var width := maxf(viewport_size.x - left - right, 80.0)
	var height := maxf(viewport_size.y - top - bottom, 80.0)
	return Rect2(Vector2(left, top), Vector2(width, height))


func clamp_position(position: Vector2, size: Vector2, viewport_size: Vector2) -> Vector2:
	var safe := safe_area_rect(viewport_size)
	var max_pos := Vector2(
		maxf(safe.position.x, safe.end.x - size.x),
		maxf(safe.position.y, safe.end.y - size.y)
	)
	return Vector2(
		clampf(position.x, safe.position.x, max_pos.x),
		clampf(position.y, safe.position.y, max_pos.y)
	)


func clamp_rect(rect: Rect2, viewport_size: Vector2) -> Rect2:
	var safe := safe_area_rect(viewport_size)
	var size := Vector2(
		clampf(rect.size.x, 36.0, safe.size.x),
		clampf(rect.size.y, 36.0, safe.size.y)
	)
	var pos := clamp_position(rect.position, size, viewport_size)
	return Rect2(pos, size)


func point_in_control(control_id: String, screen_pos: Vector2, viewport_size: Vector2, extra_pad: float = 0.0) -> bool:
	var rect := pixel_rect(control_id, viewport_size)
	if extra_pad > 0.0:
		rect = rect.grow(extra_pad)
	return rect.has_point(screen_pos)


func snapshot() -> void:
	_snapshot = {
		"movement_mode": movement_mode,
		"joystick_deadzone": joystick_deadzone,
		"joystick_activation_radius": joystick_activation_radius,
		"look_sensitivity_h": look_sensitivity_h,
		"look_sensitivity_v": look_sensitivity_v,
		"invert_y": invert_y,
		"look_smoothing": look_smoothing,
		"show_touch_zone_indicator": show_touch_zone_indicator,
		"global_button_scale": global_button_scale,
		"global_button_opacity": global_button_opacity,
		"show_button_labels": show_button_labels,
		"aim_assist": aim_assist,
		"gyroscope_enabled": gyroscope_enabled,
		"controls": _duplicate_controls(_controls),
	}


func restore_snapshot() -> void:
	if _snapshot.is_empty():
		return
	movement_mode = int(_snapshot.get("movement_mode", MODE_FIXED))
	joystick_deadzone = float(_snapshot.get("joystick_deadzone", 0.16))
	joystick_activation_radius = float(_snapshot.get("joystick_activation_radius", 1.15))
	look_sensitivity_h = float(_snapshot.get("look_sensitivity_h", 0.0032))
	look_sensitivity_v = float(_snapshot.get("look_sensitivity_v", 0.0032))
	invert_y = bool(_snapshot.get("invert_y", false))
	look_smoothing = float(_snapshot.get("look_smoothing", 0.0))
	show_touch_zone_indicator = bool(_snapshot.get("show_touch_zone_indicator", true))
	global_button_scale = float(_snapshot.get("global_button_scale", 1.0))
	global_button_opacity = float(_snapshot.get("global_button_opacity", 1.0))
	show_button_labels = bool(_snapshot.get("show_button_labels", true))
	aim_assist = bool(_snapshot.get("aim_assist", true))
	gyroscope_enabled = bool(_snapshot.get("gyroscope_enabled", false))
	_controls = _duplicate_controls(_snapshot.get("controls", _default_controls()))
	layout_changed.emit()
	settings_changed.emit()


func reset_control(control_id: String) -> void:
	_controls[control_id] = _default_control(control_id)
	layout_changed.emit()
	settings_changed.emit()


func reset_all() -> void:
	apply_preset(PRESET_DEFAULT, false)
	save_settings()


## RESET TO DEFAULT on the Controls page: layout, visibility, size, opacity,
## labels, control mode and the advanced look options.
func reset_controls_to_default() -> void:
	apply_preset(PRESET_DEFAULT, false)
	global_button_scale = 1.0
	global_button_opacity = 1.0
	show_button_labels = true
	invert_y = false
	aim_assist = true
	gyroscope_enabled = false
	gyroscope_sensitivity = 1.0
	save_settings()


func apply_preset(preset_id: String, emit_change: bool = true) -> void:
	_controls = _default_controls()
	movement_mode = MODE_FIXED
	joystick_deadzone = 0.16
	joystick_activation_radius = 1.15
	show_touch_zone_indicator = true
	match preset_id:
		PRESET_COMPACT:
			_scale_all_buttons(0.82)
			_nudge("joystick", 0.008, 0.018)
			_nudge("sprint", -0.010, 0.010)
			_nudge("shoot", -0.006, 0.012)
			_nudge("jump", -0.004, 0.010)
		PRESET_LARGE:
			_scale_all_buttons(1.22)
			_nudge("joystick", 0.000, -0.012)
			_nudge("sprint", -0.018, -0.008)
			_nudge("shoot", -0.020, -0.010)
			_nudge("jump", -0.012, -0.008)
		_:
			pass
	if emit_change:
		layout_changed.emit()
		settings_changed.emit()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		_controls = _default_controls()
		return
	control_settings_version = int(config.get_value("meta", "control_settings_version", SETTINGS_VERSION))
	movement_mode = clampi(int(config.get_value("movement", "movement_mode", MODE_FIXED)), MODE_FIXED, MODE_TOUCH_ZONE)
	joystick_deadzone = clampf(float(config.get_value("movement", "joystick_deadzone", 0.16)), 0.04, 0.45)
	joystick_activation_radius = clampf(float(config.get_value("movement", "joystick_activation_radius", 1.15)), 0.70, 1.80)
	show_touch_zone_indicator = bool(config.get_value("movement", "show_touch_zone_indicator", true))
	look_sensitivity_h = clampf(float(config.get_value("camera", "horizontal_sensitivity", 0.0032)), 0.0010, 0.0100)
	look_sensitivity_v = clampf(float(config.get_value("camera", "vertical_sensitivity", look_sensitivity_h)), 0.0010, 0.0100)
	invert_y = bool(config.get_value("camera", "invert_y", false))
	look_smoothing = clampf(float(config.get_value("camera", "look_smoothing", 0.0)), 0.0, 0.85)
	aim_assist = bool(config.get_value("camera", "aim_assist", true))
	gyroscope_enabled = bool(config.get_value("camera", "gyroscope_enabled", false))
	gyroscope_sensitivity = clampf(float(config.get_value("camera", "gyroscope_sensitivity", 1.0)), 0.25, 2.5)
	global_button_scale = clampf(float(config.get_value("hud", "global_button_scale", 1.0)), 0.6, 1.5)
	global_button_opacity = clampf(float(config.get_value("hud", "global_button_opacity", 1.0)), 0.2, 1.0)
	show_button_labels = bool(config.get_value("hud", "show_button_labels", true))
	haptics_enabled = bool(config.get_value("gameplay", "haptics_enabled", true))
	master_volume = clampf(float(config.get_value("audio", "master_volume", 100.0)), 0.0, 100.0)
	render_scale = clampf(float(config.get_value("graphics", "render_scale", 1.0)), 0.5, 1.0)
	fps_cap = maxi(int(config.get_value("graphics", "fps_cap", _default_fps_cap())), 0)
	_controls = _default_controls()
	var locked_reset := false
	for control_id in _controls.keys():
		if not config.has_section(control_id):
			continue
		var data: Dictionary = (_controls[control_id] as Dictionary).duplicate(true)
		for key in data.keys():
			data[key] = config.get_value(control_id, key, data[key])
		if is_locked(control_id) and data != _controls[control_id]:
			locked_reset = true
		_controls[control_id] = _sanitize_control(control_id, data)
	if control_settings_version != SETTINGS_VERSION:
		_migrate_settings(control_settings_version)
		control_settings_version = SETTINGS_VERSION
		save_settings()
	elif locked_reset:
		# An older save moved / resized / hid the pause button: write the stock
		# entry back so the file matches what the HUD shows.
		save_settings()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "control_settings_version", SETTINGS_VERSION)
	config.set_value("movement", "movement_mode", movement_mode)
	config.set_value("movement", "joystick_deadzone", joystick_deadzone)
	config.set_value("movement", "joystick_activation_radius", joystick_activation_radius)
	config.set_value("movement", "show_touch_zone_indicator", show_touch_zone_indicator)
	config.set_value("camera", "horizontal_sensitivity", look_sensitivity_h)
	config.set_value("camera", "vertical_sensitivity", look_sensitivity_v)
	config.set_value("camera", "invert_y", invert_y)
	config.set_value("camera", "look_smoothing", look_smoothing)
	config.set_value("camera", "aim_assist", aim_assist)
	config.set_value("camera", "gyroscope_enabled", gyroscope_enabled)
	config.set_value("camera", "gyroscope_sensitivity", gyroscope_sensitivity)
	config.set_value("hud", "global_button_scale", global_button_scale)
	config.set_value("hud", "global_button_opacity", global_button_opacity)
	config.set_value("hud", "show_button_labels", show_button_labels)
	config.set_value("gameplay", "haptics_enabled", haptics_enabled)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("graphics", "render_scale", render_scale)
	config.set_value("graphics", "fps_cap", fps_cap)
	for control_id in _controls.keys():
		var data: Dictionary = _controls[control_id]
		for key in data.keys():
			config.set_value(String(control_id), String(key), data[key])
	config.save(SETTINGS_PATH)
	layout_changed.emit()
	settings_changed.emit()


func apply_to_control(widget: Control, control_id: String, viewport_size: Vector2, apply_opacity: bool = true) -> void:
	if widget == null or viewport_size.x <= 0.0:
		return
	var rect := pixel_rect(control_id, viewport_size)
	widget.layout_mode = 0
	widget.scale = Vector2.ONE
	widget.position = rect.position
	widget.size = rect.size
	widget.visible = control_visible(control_id)
	if apply_opacity:
		widget.modulate.a = control_opacity(control_id)


func _default_controls() -> Dictionary:
	return {
		"joystick": {"nx": 0.0311, "ny": 0.5909, "scale": 1.0, "opacity": 1.0, "visible": true},
		"shoot": {"nx": 0.8517, "ny": 0.6865, "scale": 1.0, "opacity": 1.0, "visible": true},
		"jump": {"nx": 0.8950, "ny": 0.5462, "scale": 1.0, "opacity": 1.0, "visible": true},
		"sprint": {"nx": 0.7596, "ny": 0.5951, "scale": 1.0, "opacity": 1.0, "visible": true},
		"swap": {"nx": 0.7480, "ny": 0.7800, "scale": 1.0, "opacity": 1.0, "visible": true},
		"pause": {"nx": 0.9396, "ny": 0.1179, "scale": 1.0, "opacity": 1.0, "visible": true},
		"aim": {"nx": 0.9050, "ny": 0.4000, "scale": 1.0, "opacity": 1.0, "visible": true},
		"reload": {"nx": 0.7750, "ny": 0.4000, "scale": 1.0, "opacity": 1.0, "visible": true},
		"crouch": {"nx": 0.6650, "ny": 0.6600, "scale": 1.0, "opacity": 1.0, "visible": true},
		"melee": {"nx": 0.6650, "ny": 0.5000, "scale": 1.0, "opacity": 1.0, "visible": false},
		"interact": {"nx": 0.7000, "ny": 0.2900, "scale": 1.0, "opacity": 1.0, "visible": true},
		"movement_zone": {"nx": 0.0000, "ny": 0.1600, "nw": 0.4200, "nh": 0.8000, "scale": 1.0, "opacity": 0.22, "visible": true},
		"look_zone": {"nx": 0.3600, "ny": 0.0000, "nw": 0.6400, "nh": 1.0000, "scale": 1.0, "opacity": 0.16, "visible": true},
	}


func _default_control(control_id: String) -> Dictionary:
	var defaults := _default_controls()
	if defaults.has(control_id):
		return (defaults[control_id] as Dictionary).duplicate(true)
	return {"nx": 0.80, "ny": 0.70, "scale": 1.0, "opacity": 1.0, "visible": true}


func _sanitize_control(control_id: String, data: Dictionary) -> Dictionary:
	if is_locked(control_id):
		return _default_control(control_id)
	var clean := _default_control(control_id)
	clean.merge(data, true)
	clean["nx"] = clampf(float(clean.get("nx", 0.0)), 0.0, 0.98)
	clean["ny"] = clampf(float(clean.get("ny", 0.0)), 0.0, 0.98)
	clean["scale"] = clampf(float(clean.get("scale", 1.0)), 0.55, 1.85)
	clean["opacity"] = clampf(float(clean.get("opacity", 1.0)), 0.15, 1.0)
	clean["visible"] = bool(clean.get("visible", true))
	if clean.has("nw"):
		clean["nw"] = clampf(float(clean.get("nw", 0.42)), 0.18, 0.80)
	if clean.has("nh"):
		clean["nh"] = clampf(float(clean.get("nh", 0.80)), 0.28, 1.0)
	return clean


func _scale_all_buttons(scale: float) -> void:
	for control_id in CONTROL_IDS:
		if is_locked(control_id):
			continue
		var data: Dictionary = _controls[control_id]
		data["scale"] = clampf(scale, 0.55, 1.85)
		_controls[control_id] = data


func _nudge(control_id: String, dx: float, dy: float) -> void:
	if not _controls.has(control_id):
		return
	var data: Dictionary = _controls[control_id]
	data["nx"] = clampf(float(data.get("nx", 0.0)) + dx, 0.0, 0.98)
	data["ny"] = clampf(float(data.get("ny", 0.0)) + dy, 0.0, 0.98)
	_controls[control_id] = data


func _height_scale(viewport_size: Vector2) -> float:
	if viewport_size.y <= 0.0:
		return 1.0
	return viewport_size.y / REFERENCE_HEIGHT


func _duplicate_controls(source: Dictionary) -> Dictionary:
	var copy := {}
	for key in source.keys():
		copy[key] = (source[key] as Dictionary).duplicate(true)
	return copy


func _migrate_settings(_from_version: int) -> void:
	# v2 adds aim/reload/crouch/melee/interact. They have no saved sections in a
	# v1 file, so load_settings() already gave them defaults; nothing to rewrite.
	pass
