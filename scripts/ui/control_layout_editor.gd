class_name ControlLayoutEditor
extends CanvasLayer

signal closed(saved: bool)

const CONTROL_DEFS := [
	{"id": "movement_zone", "title": "MOVEMENT ZONE", "zone": true},
	{"id": "look_zone", "title": "LOOK ZONE", "zone": true},
	{"id": "joystick", "title": "JOYSTICK", "zone": false},
	{"id": "sprint", "title": "SPRINT", "zone": false},
	{"id": "shoot", "title": "SHOOT", "zone": false},
	{"id": "jump", "title": "JUMP", "zone": false},
	# "pause" is intentionally absent: it is locked to its stock rect.
]

var gameplay_hud: HudController = null
var pause_menu: PauseMenu = null

var _root: Control
var _dim: ColorRect
var _stage: Control
var _header: Label
var _subhead: Label
var _selected_panel: PanelContainer
var _selected_title: Label
var _size_slider: HSlider
var _opacity_slider: HSlider
var _size_value: Label
var _opacity_value: Label
var _hide_toggle: CheckButton
var _widgets: Dictionary = {}
var _selected_id: String = "shoot"
var _open: bool = false


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_build()


func open_editor(hud: HudController, menu: PauseMenu) -> void:
	gameplay_hud = hud
	pause_menu = menu
	ControlSettingsManager.snapshot()
	ControlSettingsManager.suspend_hud_layout = true
	if pause_menu != null:
		pause_menu.begin_layout_editor()
	_open = true
	visible = true
	_selected_id = "shoot"
	_refresh_all()
	_select_control(_selected_id)


func close_editor(save_changes: bool) -> void:
	if not _open:
		return
	if save_changes:
		ControlSettingsManager.save_settings()
	else:
		ControlSettingsManager.restore_snapshot()
	ControlSettingsManager.suspend_hud_layout = false
	if gameplay_hud != null:
		gameplay_hud.apply_saved_control_layout(true, true)
	if pause_menu != null:
		pause_menu.end_layout_editor()
	_open = false
	visible = false
	closed.emit(save_changes)


func register_control(control_id: String, title: String, is_zone: bool = false) -> void:
	if _widgets.has(control_id):
		return
	var widget := EditableTouchControl.new()
	widget.setup(control_id, title, is_zone)
	widget.selected.connect(_select_control)
	widget.drag_finished.connect(_on_widget_changed)
	widget.resize_finished.connect(_on_widget_changed)
	widget.layout_updated.connect(_on_widget_live_update)
	_stage.add_child(widget)
	_widgets[control_id] = widget


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_dim = ColorRect.new()
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.01, 0.02, 0.02, 0.42)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dim)

	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stage)

	for def in CONTROL_DEFS:
		register_control(String(def.id), String(def.title), bool(def.zone))

	_header = _make_label("CONTROL LAYOUT", 34, Color(0.94, 0.18, 0.16, 1.0))
	_header.position = Vector2(36, 18)
	_header.size = Vector2(520, 40)
	_root.add_child(_header)

	_subhead = _make_label("DRAG CONTROLS TO REPOSITION", 16, Color(0.70, 0.78, 0.82, 0.92))
	_subhead.position = Vector2(36, 56)
	_subhead.size = Vector2(520, 24)
	_root.add_child(_subhead)

	_build_selected_panel()
	_build_bottom_bar()


func _build_selected_panel() -> void:
	_selected_panel = PanelContainer.new()
	_selected_panel.custom_minimum_size = Vector2(360, 248)
	_selected_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color(0.03, 0.04, 0.045, 0.92), Color(0.72, 0.16, 0.12, 0.95), 2, 4)
	)
	_root.add_child(_selected_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_selected_panel.add_child(column)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	column.add_child(pad)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 7)
	pad.add_child(inner)

	inner.add_child(_make_label("SELECTED CONTROL", 12, Color(0.62, 0.68, 0.70, 0.90)))
	_selected_title = _make_label("SHOOT", 22, Color(0.38, 1.0, 0.20, 1.0))
	inner.add_child(_selected_title)

	_size_value = _make_label("SIZE    100%", 14, Color(0.55, 0.86, 1.0, 0.95))
	inner.add_child(_size_value)
	_size_slider = _make_slider(0.55, 1.85, 0.01, 1.0)
	_size_slider.value_changed.connect(_on_size_changed)
	inner.add_child(_size_slider)

	_opacity_value = _make_label("OPACITY    100%", 14, Color(0.55, 0.86, 1.0, 0.95))
	inner.add_child(_opacity_value)
	_opacity_slider = _make_slider(0.15, 1.0, 0.01, 1.0)
	_opacity_slider.value_changed.connect(_on_opacity_changed)
	inner.add_child(_opacity_slider)

	var reset_row := HBoxContainer.new()
	reset_row.add_theme_constant_override("separation", 8)
	inner.add_child(reset_row)
	reset_row.add_child(_make_bar_button("RESET POS", _reset_selected_position, Vector2(110, 36)))
	reset_row.add_child(_make_bar_button("RESET SIZE", _reset_selected_size, Vector2(110, 36)))

	_hide_toggle = CheckButton.new()
	_hide_toggle.text = "SHOW CONTROL"
	_hide_toggle.button_pressed = true
	_hide_toggle.add_theme_font_size_override("font_size", 14)
	_hide_toggle.add_theme_color_override("font_color", Color(0.38, 1.0, 0.20, 1.0))
	_hide_toggle.toggled.connect(_on_hide_toggled)
	inner.add_child(_hide_toggle)


func _build_bottom_bar() -> void:
	var bar := HBoxContainer.new()
	bar.name = "EditorActions"
	bar.add_theme_constant_override("separation", 12)
	_root.add_child(bar)
	bar.set_meta("dock", true)
	bar.add_child(_make_bar_button("DEFAULT", _apply_preset.bind(ControlSettingsManager.PRESET_DEFAULT), Vector2(150, 52)))
	bar.add_child(_make_bar_button("COMPACT", _apply_preset.bind(ControlSettingsManager.PRESET_COMPACT), Vector2(150, 52)))
	bar.add_child(_make_bar_button("LARGE", _apply_preset.bind(ControlSettingsManager.PRESET_LARGE), Vector2(150, 52)))
	bar.add_child(_make_bar_button("RESET ALL", _reset_all, Vector2(170, 52)))
	bar.add_child(_make_bar_button("CANCEL", _cancel, Vector2(150, 52)))
	bar.add_child(_make_bar_button("SAVE", _save, Vector2(170, 52), true))
	_root.set_meta("action_bar", bar)


func _process(_delta: float) -> void:
	if not _open:
		return
	_layout_chrome()


func _layout_chrome() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if _selected_panel != null:
		_selected_panel.position = Vector2(viewport_size.x - 392.0, 84.0)
	var bar := _root.get_meta("action_bar", null) as HBoxContainer
	if bar != null:
		bar.position = Vector2(28.0, viewport_size.y - 78.0)
		bar.size = Vector2(viewport_size.x - 56.0, 56.0)


func _refresh_all() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	for control_id in _widgets.keys():
		var widget: EditableTouchControl = _widgets[control_id]
		var rect := ControlSettingsManager.pixel_rect(String(control_id), viewport_size)
		widget.position = rect.position
		widget.size = rect.size
		widget.visible = true
		widget.modulate.a = 1.0 if not widget.is_zone else 0.92
		if String(control_id) == "joystick":
			widget.visible = ControlSettingsManager.movement_mode != ControlSettingsManager.MODE_TOUCH_ZONE
	if gameplay_hud != null:
		gameplay_hud.apply_saved_control_layout(true, true)
	_refresh_selected_panel()


func _select_control(control_id: String) -> void:
	_selected_id = control_id
	for id in _widgets.keys():
		var widget: EditableTouchControl = _widgets[id]
		widget.set_selected(String(id) == control_id)
	_refresh_selected_panel()


func _refresh_selected_panel() -> void:
	var data := ControlSettingsManager.get_control(_selected_id)
	if _selected_title != null:
		_selected_title.text = _title_for(_selected_id)
	if _size_slider != null:
		_size_slider.set_value_no_signal(float(data.get("scale", 1.0)))
		_size_slider.visible = not _selected_id.ends_with("_zone")
	if _size_value != null:
		_size_value.text = "SIZE    %d%%" % int(round(float(data.get("scale", 1.0)) * 100.0))
		_size_value.visible = not _selected_id.ends_with("_zone")
	if _opacity_slider != null:
		_opacity_slider.set_value_no_signal(float(data.get("opacity", 1.0)))
	if _opacity_value != null:
		_opacity_value.text = "OPACITY    %d%%" % int(round(float(data.get("opacity", 1.0)) * 100.0))
	if _hide_toggle != null:
		_hide_toggle.set_pressed_no_signal(bool(data.get("visible", true)))
		_hide_toggle.visible = not _selected_id.ends_with("_zone")


func _on_size_changed(value: float) -> void:
	ControlSettingsManager.update_control(_selected_id, "scale", value, false)
	_refresh_all()


func _on_opacity_changed(value: float) -> void:
	ControlSettingsManager.update_control(_selected_id, "opacity", value, false)
	_refresh_all()


func _on_hide_toggled(enabled: bool) -> void:
	ControlSettingsManager.update_control(_selected_id, "visible", enabled, false)
	_refresh_all()


func _on_widget_changed(_control_id: String) -> void:
	_refresh_all()


func _on_widget_live_update(_control_id: String) -> void:
	if gameplay_hud != null:
		gameplay_hud.apply_saved_control_layout(false, true)
	_refresh_selected_panel()


func _reset_selected_position() -> void:
	var defaults := ControlSettingsManager.get_control(_selected_id)
	ControlSettingsManager.reset_control(_selected_id)
	var restored := ControlSettingsManager.get_control(_selected_id)
	restored["scale"] = defaults.get("scale", 1.0)
	restored["opacity"] = defaults.get("opacity", 1.0)
	restored["visible"] = defaults.get("visible", true)
	ControlSettingsManager.set_control(_selected_id, restored, false)
	_refresh_all()


func _reset_selected_size() -> void:
	ControlSettingsManager.update_control(_selected_id, "scale", 1.0, false)
	_refresh_all()


func _apply_preset(preset_id: String) -> void:
	ControlSettingsManager.apply_preset(preset_id, false)
	_refresh_all()


func _reset_all() -> void:
	ControlSettingsManager.apply_preset(ControlSettingsManager.PRESET_DEFAULT, false)
	_refresh_all()


func _save() -> void:
	close_editor(true)


func _cancel() -> void:
	close_editor(false)


func _title_for(control_id: String) -> String:
	for def in CONTROL_DEFS:
		if String(def.id) == control_id:
			return String(def.title)
	return control_id.to_upper()


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_slider(min_value: float, max_value: float, step: float, value: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(300, 22)
	return slider


func _make_bar_button(text_value: String, callback: Callable, min_size: Vector2, accent: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 16)
	var border := Color(0.95, 0.18, 0.14, 0.95) if accent else Color(0.42, 0.72, 0.86, 0.90)
	var fill := Color(0.18, 0.04, 0.04, 0.92) if accent else Color(0.04, 0.07, 0.09, 0.92)
	button.add_theme_color_override("font_color", Color(0.95, 0.96, 0.92, 1.0))
	button.add_theme_stylebox_override("normal", _panel_style(fill, border, 2, 3))
	button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.08), border, 2, 3))
	button.pressed.connect(callback)
	return button


func _panel_style(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
