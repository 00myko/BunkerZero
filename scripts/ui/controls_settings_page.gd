class_name ControlsSettingsPage
extends Control

signal edit_layout_requested
signal look_preview_changed(horizontal: float, vertical: float)

const GREEN := Color(0.38, 1.0, 0.20, 1.0)
const GREEN_SOFT := Color(0.52, 0.88, 0.38, 1.0)
const TEXT_LIGHT := Color(0.87, 0.89, 0.84, 1.0)
const TEXT_DIM := Color(0.55, 0.61, 0.52, 1.0)
const BLUE := Color(0.55, 0.86, 1.0, 0.95)
const GREEN_DEEP := Color(0.05, 0.16, 0.04, 0.94)

var _mode_buttons: Array[Button] = []
var _joystick_size: HSlider
var _joystick_opacity: HSlider
var _deadzone: HSlider
var _activation: HSlider
var _zone_size: HSlider
var _look_h: HSlider
var _look_v: HSlider
var _smoothing: HSlider
var _invert: CheckButton
var _joystick_size_label: Label
var _joystick_opacity_label: Label
var _deadzone_label: Label
var _activation_label: Label
var _zone_size_label: Label
var _look_h_label: Label
var _look_v_label: Label
var _smoothing_label: Label
var _menu_font: Font


func setup(menu_font: Font) -> void:
	_menu_font = menu_font
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	refresh_from_manager()


func refresh_from_manager() -> void:
	_select_mode(ControlSettingsManager.movement_mode, false)
	var joystick := ControlSettingsManager.get_control("joystick")
	_set_slider(_joystick_size, float(joystick.get("scale", 1.0)), _joystick_size_label, "JOYSTICK SIZE    %d%%")
	_set_slider(_joystick_opacity, float(joystick.get("opacity", 1.0)), _joystick_opacity_label, "JOYSTICK OPACITY    %d%%")
	_set_slider(_deadzone, ControlSettingsManager.joystick_deadzone, _deadzone_label, "DEAD ZONE    %d%%", 100.0)
	_set_slider(_activation, ControlSettingsManager.joystick_activation_radius, _activation_label, "ACTIVATION RADIUS    %d%%")
	var zone := ControlSettingsManager.get_control("movement_zone")
	_set_slider(_zone_size, float(zone.get("nw", 0.42)), _zone_size_label, "MOVEMENT ZONE SIZE    %d%%")
	_set_slider(_look_h, ControlSettingsManager.look_sensitivity_h, _look_h_label, "HORIZONTAL SENS.    %d%%", 0.0, true)
	_set_slider(_look_v, ControlSettingsManager.look_sensitivity_v, _look_v_label, "VERTICAL SENS.    %d%%", 0.0, true)
	_set_slider(_smoothing, ControlSettingsManager.look_smoothing, _smoothing_label, "CAMERA SMOOTHING    %d%%", 100.0)
	if _invert != null:
		_invert.set_pressed_no_signal(ControlSettingsManager.invert_y)


func _build() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)

	column.add_child(_heading("CONTROLS", 28, GREEN))
	column.add_child(_heading("CUSTOMIZE YOUR LAYOUT", 14, TEXT_DIM))
	column.add_child(_rule())

	column.add_child(_heading("MOVEMENT INPUT MODE", 16, TEXT_LIGHT))
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 8)
	column.add_child(modes)
	_mode_buttons.append(_mode_button(modes, "FIXED JOYSTICK", ControlSettingsManager.MODE_FIXED))
	_mode_buttons.append(_mode_button(modes, "FLOATING JOYSTICK", ControlSettingsManager.MODE_FLOATING))
	_mode_buttons.append(_mode_button(modes, "TOUCH ZONE", ControlSettingsManager.MODE_TOUCH_ZONE))

	column.add_child(_heading("MOVEMENT", 16, TEXT_LIGHT))
	_joystick_size_label = _heading("JOYSTICK SIZE    100%", 14, BLUE)
	column.add_child(_joystick_size_label)
	_joystick_size = _slider(column, 0.55, 1.85, 0.01, 1.0, _on_joystick_size)
	_joystick_opacity_label = _heading("JOYSTICK OPACITY    100%", 14, BLUE)
	column.add_child(_joystick_opacity_label)
	_joystick_opacity = _slider(column, 0.15, 1.0, 0.01, 1.0, _on_joystick_opacity)
	_deadzone_label = _heading("DEAD ZONE    16%", 14, BLUE)
	column.add_child(_deadzone_label)
	_deadzone = _slider(column, 0.04, 0.45, 0.01, 0.16, _on_deadzone)
	_activation_label = _heading("ACTIVATION RADIUS    115%", 14, BLUE)
	column.add_child(_activation_label)
	_activation = _slider(column, 0.70, 1.80, 0.01, 1.15, _on_activation)
	_zone_size_label = _heading("MOVEMENT ZONE SIZE    42%", 14, BLUE)
	column.add_child(_zone_size_label)
	_zone_size = _slider(column, 0.22, 0.70, 0.01, 0.42, _on_zone_size)

	column.add_child(_rule())
	column.add_child(_heading("CAMERA / LOOK", 16, TEXT_LIGHT))
	_look_h_label = _heading("HORIZONTAL SENS.    50%", 14, BLUE)
	column.add_child(_look_h_label)
	_look_h = _slider(column, 0.0015, 0.0060, 0.0001, 0.0032, _on_look_h)
	_look_v_label = _heading("VERTICAL SENS.    50%", 14, BLUE)
	column.add_child(_look_v_label)
	_look_v = _slider(column, 0.0015, 0.0060, 0.0001, 0.0032, _on_look_v)
	_smoothing_label = _heading("CAMERA SMOOTHING    0%", 14, BLUE)
	column.add_child(_smoothing_label)
	_smoothing = _slider(column, 0.0, 0.85, 0.01, 0.0, _on_smoothing)
	_invert = CheckButton.new()
	_invert.text = "INVERT Y"
	_invert.add_theme_font_size_override("font_size", 16)
	_invert.add_theme_color_override("font_color", GREEN_SOFT)
	if _menu_font != null:
		_invert.add_theme_font_override("font", _menu_font)
	_invert.toggled.connect(_on_invert)
	column.add_child(_invert)

	column.add_child(_rule())
	column.add_child(_heading("CUSTOM HUD", 16, TEXT_LIGHT))
	column.add_child(_action_button("EDIT CONTROL LAYOUT", func() -> void: edit_layout_requested.emit(), true))
	var presets := HBoxContainer.new()
	presets.add_theme_constant_override("separation", 8)
	column.add_child(presets)
	presets.add_child(_action_button("DEFAULT", _preset.bind(ControlSettingsManager.PRESET_DEFAULT)))
	presets.add_child(_action_button("COMPACT", _preset.bind(ControlSettingsManager.PRESET_COMPACT)))
	presets.add_child(_action_button("LARGE", _preset.bind(ControlSettingsManager.PRESET_LARGE)))
	column.add_child(_action_button("RESET TO DEFAULT", _reset_all))


func _heading(text_value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if _menu_font != null:
		label.add_theme_font_override("font", _menu_font)
	return label


func _rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(10, 3)
	rule.color = Color(GREEN.r, GREEN.g, GREEN.b, 0.70)
	return rule


func _slider(parent: Control, min_value: float, max_value: float, step: float, value: float, callback: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(10, 28)
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	parent.add_child(slider)
	return slider


func _mode_button(parent: Control, text_value: String, mode: int) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(150, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 13)
	if _menu_font != null:
		button.add_theme_font_override("font", _menu_font)
	button.pressed.connect(func() -> void: _select_mode(mode, true))
	parent.add_child(button)
	return button


func _action_button(text_value: String, callback: Callable, accent: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(180, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 15)
	if _menu_font != null:
		button.add_theme_font_override("font", _menu_font)
	var border := GREEN if accent else Color(0.42, 0.72, 0.86, 0.90)
	var fill := GREEN_DEEP if accent else Color(0.03, 0.06, 0.07, 0.90)
	button.add_theme_color_override("font_color", GREEN if accent else TEXT_LIGHT)
	button.add_theme_stylebox_override("normal", _style(fill, border))
	button.add_theme_stylebox_override("hover", _style(fill.lightened(0.08), border))
	button.pressed.connect(callback)
	return button


func _select_mode(mode: int, persist: bool) -> void:
	ControlSettingsManager.set_movement_mode(mode, persist)
	for index in _mode_buttons.size():
		var button := _mode_buttons[index]
		var selected := index == mode
		var border := GREEN if selected else Color(0.35, 0.55, 0.62, 0.80)
		var fill := GREEN_DEEP if selected else Color(0.03, 0.05, 0.06, 0.88)
		button.add_theme_color_override("font_color", GREEN if selected else TEXT_LIGHT)
		button.add_theme_stylebox_override("normal", _style(fill, border))
		button.add_theme_stylebox_override("hover", _style(fill.lightened(0.08), border))
	if persist:
		ControlSettingsManager.save_settings()


func _on_joystick_size(value: float) -> void:
	ControlSettingsManager.update_control("joystick", "scale", value)
	_joystick_size_label.text = "JOYSTICK SIZE    %d%%" % int(round(value * 100.0))
	ControlSettingsManager.save_settings()


func _on_joystick_opacity(value: float) -> void:
	ControlSettingsManager.update_control("joystick", "opacity", value)
	_joystick_opacity_label.text = "JOYSTICK OPACITY    %d%%" % int(round(value * 100.0))
	ControlSettingsManager.save_settings()


func _on_deadzone(value: float) -> void:
	ControlSettingsManager.set_joystick_deadzone(value)
	_deadzone_label.text = "DEAD ZONE    %d%%" % int(round(value * 100.0))
	ControlSettingsManager.save_settings()


func _on_activation(value: float) -> void:
	ControlSettingsManager.set_joystick_activation_radius(value)
	_activation_label.text = "ACTIVATION RADIUS    %d%%" % int(round(value * 100.0))
	ControlSettingsManager.save_settings()


func _on_zone_size(value: float) -> void:
	ControlSettingsManager.update_control("movement_zone", "nw", value)
	_zone_size_label.text = "MOVEMENT ZONE SIZE    %d%%" % int(round(value * 100.0))
	ControlSettingsManager.save_settings()


func _on_look_h(value: float) -> void:
	ControlSettingsManager.set_look_sensitivity(value, ControlSettingsManager.look_sensitivity_v)
	_look_h_label.text = "HORIZONTAL SENS.    %d%%" % _sens_percent(value)
	look_preview_changed.emit(value, ControlSettingsManager.look_sensitivity_v)
	ControlSettingsManager.save_settings()


func _on_look_v(value: float) -> void:
	ControlSettingsManager.set_look_sensitivity(ControlSettingsManager.look_sensitivity_h, value)
	_look_v_label.text = "VERTICAL SENS.    %d%%" % _sens_percent(value)
	look_preview_changed.emit(ControlSettingsManager.look_sensitivity_h, value)
	ControlSettingsManager.save_settings()


func _on_smoothing(value: float) -> void:
	ControlSettingsManager.set_look_smoothing(value)
	_smoothing_label.text = "CAMERA SMOOTHING    %d%%" % int(round(value * 100.0))
	ControlSettingsManager.save_settings()


func _on_invert(enabled: bool) -> void:
	ControlSettingsManager.set_invert_y(enabled)
	ControlSettingsManager.save_settings()


func _preset(preset_id: String) -> void:
	ControlSettingsManager.apply_preset(preset_id)
	ControlSettingsManager.save_settings()
	refresh_from_manager()


func _reset_all() -> void:
	ControlSettingsManager.reset_all()
	refresh_from_manager()


func _set_slider(slider: HSlider, value: float, label: Label, format: String, percent_scale: float = 100.0, sensitivity: bool = false) -> void:
	if slider != null:
		slider.set_value_no_signal(value)
	if label != null:
		if sensitivity:
			label.text = format % _sens_percent(value)
		else:
			label.text = format % int(round(value * percent_scale))


func _sens_percent(value: float) -> int:
	return clampi(int(round(inverse_lerp(0.0015, 0.0060, value) * 100.0)), 0, 100)


func _style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style
