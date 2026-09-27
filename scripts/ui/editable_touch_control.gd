class_name EditableTouchControl
extends Control

signal selected(control_id: String)
signal drag_finished(control_id: String)
signal resize_finished(control_id: String)
signal layout_updated(control_id: String)

const HANDLE_SIZE := 28.0
const MIN_SCALE := 0.55
const MAX_SCALE := 1.85

var control_id: String = ""
var display_name: String = ""
var is_zone: bool = false
var selected_state: bool = false

var _dragging: bool = false
var _resizing: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _resize_start_size: Vector2 = Vector2.ZERO
var _resize_start_pos: Vector2 = Vector2.ZERO
var _touch_index: int = -1

var _border: Panel
var _label: Label
var _move_badge: Label
var _handle: ColorRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_border = Panel.new()
	_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_border)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(0.86, 0.90, 0.94, 0.95))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	add_child(_label)

	_move_badge = Label.new()
	_move_badge.text = "MOVE"
	_move_badge.position = Vector2(8, 6)
	_move_badge.size = Vector2(70, 20)
	_move_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_move_badge.add_theme_font_size_override("font_size", 11)
	_move_badge.add_theme_color_override("font_color", Color(0.55, 0.86, 1.0, 0.95))
	add_child(_move_badge)

	_handle = ColorRect.new()
	_handle.size = Vector2(HANDLE_SIZE, HANDLE_SIZE)
	_handle.color = Color(0.18, 0.82, 0.38, 0.95)
	_handle.mouse_filter = Control.MOUSE_FILTER_STOP
	_handle.gui_input.connect(_on_handle_gui_input)
	add_child(_handle)
	_refresh_visual()


func setup(id: String, title: String, zone: bool = false) -> void:
	control_id = id
	display_name = title
	is_zone = zone
	if _label != null:
		_label.text = title
	_refresh_visual()


func set_selected(on: bool) -> void:
	selected_state = on
	_refresh_visual()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_place_handle()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_drag(touch.index, touch.position)
			accept_event()
		elif touch.index == _touch_index:
			_end_drag()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_update_drag(drag.position)
			accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(-2, event.position)
			accept_event()
		elif _touch_index == -2:
			_end_drag()
			accept_event()
	elif event is InputEventMouseMotion and _dragging and _touch_index == -2 and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_update_drag(event.position)
		accept_event()


func _on_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_resize(touch.index, _to_parent(touch.position + _handle.position))
			accept_event()
		elif touch.index == _touch_index:
			_end_resize()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index and _resizing:
		_update_resize(_to_parent(event.position + _handle.position))
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_resize(-3, _to_parent(event.position + _handle.position))
			accept_event()
		elif _touch_index == -3:
			_end_resize()
			accept_event()
	elif event is InputEventMouseMotion and _resizing and _touch_index == -3 and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_update_resize(_to_parent(event.position + _handle.position))
		accept_event()


func _begin_drag(index: int, local_pos: Vector2) -> void:
	_dragging = true
	_resizing = false
	_touch_index = index
	_drag_offset = local_pos
	set_selected(true)
	selected.emit(control_id)


func _update_drag(local_pos: Vector2) -> void:
	if not _dragging:
		return
	var parent_control := get_parent() as Control
	if parent_control == null:
		return
	var next := position + (local_pos - _drag_offset)
	position = ControlSettingsManager.clamp_position(next, size, parent_control.size)
	ControlSettingsManager.set_pixel_rect(control_id, Rect2(position, size), parent_control.size, false)
	layout_updated.emit(control_id)


func _end_drag() -> void:
	if not _dragging:
		_touch_index = -1
		return
	_dragging = false
	_touch_index = -1
	drag_finished.emit(control_id)


func _begin_resize(index: int, parent_pos: Vector2) -> void:
	_resizing = true
	_dragging = false
	_touch_index = index
	_resize_start_size = size
	_resize_start_pos = parent_pos
	set_selected(true)
	selected.emit(control_id)


func _update_resize(parent_pos: Vector2) -> void:
	if not _resizing:
		return
	var parent_control := get_parent() as Control
	if parent_control == null:
		return
	var delta := parent_pos - _resize_start_pos
	var next_size := _resize_start_size + delta
	if is_zone:
		next_size.x = maxf(parent_control.size.x * 0.18, next_size.x)
		next_size.y = maxf(parent_control.size.y * 0.28, next_size.y)
	else:
		var base := ControlSettingsManager.default_pixel_size(control_id, parent_control.size)
		var scale := clampf(next_size.x / maxf(base.x, 1.0), MIN_SCALE, MAX_SCALE)
		next_size = base * scale
	size = next_size
	position = ControlSettingsManager.clamp_position(position, size, parent_control.size)
	ControlSettingsManager.set_pixel_rect(control_id, Rect2(position, size), parent_control.size, false)
	_place_handle()
	layout_updated.emit(control_id)


func _end_resize() -> void:
	if not _resizing:
		_touch_index = -1
		return
	_resizing = false
	_touch_index = -1
	resize_finished.emit(control_id)


func _to_parent(local_pos: Vector2) -> Vector2:
	return position + local_pos


func _place_handle() -> void:
	if _handle == null:
		return
	_handle.position = Vector2(size.x - HANDLE_SIZE - 4.0, size.y - HANDLE_SIZE - 4.0)


func _refresh_visual() -> void:
	if _border == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.07, 0.10 if not is_zone else 0.16)
	style.border_color = Color(0.95, 0.18, 0.14, 0.95) if selected_state else Color(0.62, 0.78, 0.88, 0.72)
	style.set_border_width_all(3 if selected_state else 2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.95, 0.14, 0.10, 0.35 if selected_state else 0.0)
	style.shadow_size = 10 if selected_state else 0
	_border.add_theme_stylebox_override("panel", style)
	if _label != null:
		_label.text = display_name
		_label.visible = is_zone or size.x >= 90.0
	_place_handle()
