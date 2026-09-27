extends CanvasLayer

# BUNKER ZERO loading screen
# Add, remove, or rewrite entries here as the game grows.
const TIPS = [
	"Headshots drop infected faster and conserve ammunition.",
	"Keep moving—infection swarms are most dangerous when they surround you.",
	"Upgrade your weapons in the safe hub before pushing deeper.",
	"Listen for doors, vents, and footsteps before entering a new room.",
	"Money earned from eliminations is kept when you return to the safe hub."
]

const BACKGROUND_PATH := "res://assets/Game UI Art/Loading Screen.png"
const DESIGN_SIZE := Vector2(1672.0, 941.0)
const MINIMUM_VISIBLE_TIME := 0.85
const COMPLETION_HOLD_TIME := 0.16
const FADE_OUT_TIME := 0.24
const PRELOAD_ANIMATION_TIME := 0.65

var _overlay: Control
var _design_canvas: Control
var _fill_clip: Control
var _fill_panel: Panel
var _percent_label: Label
var _tip_label: Label
var _error_label: Label
var _background_rect: TextureRect
var _ui_font: SystemFont
var _rng := RandomNumberGenerator.new()
var _last_tip_index := -1
var _loading := false
var _target_progress := 0.0
var _display_progress := 0.0
var _visible_time := 0.0
var _load_path := ""
var _loaded_scene: PackedScene


func _ready() -> void:
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_build_interface()
	get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()
	_overlay.visible = false
	set_process(false)


func _load_background_after_boot() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if _background_rect == null or not is_instance_valid(_background_rect):
		return
	if ResourceLoader.exists(BACKGROUND_PATH):
		_background_rect.texture = load(BACKGROUND_PATH) as Texture2D
	else:
		push_error("BUNKER ZERO: Loading screen image is missing: %s" % BACKGROUND_PATH)


func is_loading() -> bool:
	return _loading


func load_scene(scene_path: String) -> void:
	if _loading:
		return
	if not ResourceLoader.exists(scene_path):
		show_error("SCENE NOT FOUND")
		return

	_loading = true
	_load_path = scene_path
	_loaded_scene = null
	_target_progress = 0.0
	_display_progress = 0.0
	_visible_time = 0.0
	_error_label.visible = false
	_select_tip()
	_apply_progress(0.0)
	_overlay.modulate = Color.WHITE
	_overlay.visible = true

	# Guarantee that the loading artwork reaches the screen before disk work starts.
	await get_tree().process_frame
	await get_tree().process_frame
	# Load this only after the black loading layer is visible. Loading it from the
	# autoload's _ready() would delay the first main-menu frame on iOS.
	if _background_rect != null and _background_rect.texture == null:
		await _load_background_after_boot()
		await get_tree().process_frame
	var request_error := ResourceLoader.load_threaded_request(
		_load_path,
		"PackedScene",
		false,
		ResourceLoader.CACHE_MODE_REPLACE
	)
	if request_error != OK:
		show_error("BACKGROUND LOAD COULD NOT START (%d)" % int(request_error))
		return
	set_process(true)


func show_error(message: String) -> void:
	_loading = false
	set_process(false)
	_overlay.modulate = Color.WHITE
	_overlay.visible = true
	_error_label.text = "LOAD FAILED — %s" % message
	_error_label.visible = true
	push_error("BUNKER ZERO: %s" % message)


func _process(delta: float) -> void:
	if not _loading:
		return

	_visible_time += delta
	if _loaded_scene != null:
		_target_progress = 1.0
		_display_progress = move_toward(
			_display_progress,
			_target_progress,
			delta * 1.8
		)
		_apply_progress(_display_progress)
		if _display_progress >= 0.999 and _visible_time >= MINIMUM_VISIBLE_TIME:
			_finish_scene_change()
		return

	var progress_values: Array = []
	var load_status := ResourceLoader.load_threaded_get_status(_load_path, progress_values)
	if load_status == ResourceLoader.THREAD_LOAD_FAILED or load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		show_error("SCENE COULD NOT BE LOADED")
		return
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		_loaded_scene = ResourceLoader.load_threaded_get(_load_path) as PackedScene
		if _loaded_scene == null:
			show_error("SCENE COULD NOT BE LOADED")
			return
		_target_progress = 1.0
		_display_progress = maxf(_display_progress, 0.92)
		return

	var real_progress := 0.0
	if not progress_values.is_empty():
		real_progress = clampf(float(progress_values[0]), 0.0, 1.0)
	_target_progress = maxf(
		minf(0.90, (_visible_time / PRELOAD_ANIMATION_TIME) * 0.90),
		real_progress * 0.90
	)
	_display_progress = move_toward(_display_progress, _target_progress, delta * 2.8)
	_apply_progress(_display_progress)


func _finish_scene_change() -> void:
	set_process(false)
	_apply_progress(1.0)
	await get_tree().create_timer(COMPLETION_HOLD_TIME, true, false, true).timeout

	var change_error: Error = get_tree().change_scene_to_packed(_loaded_scene)
	if change_error != OK:
		show_error("SCENE CHANGE FAILED (%d)" % int(change_error))
		return

	# The autoload remains visible while the gameplay scene is instantiated.
	await get_tree().process_frame
	await get_tree().process_frame
	var fade: Tween = create_tween()
	fade.tween_property(
		_overlay,
		"modulate",
		Color(1.0, 1.0, 1.0, 0.0),
		FADE_OUT_TIME
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await fade.finished

	_overlay.visible = false
	_overlay.modulate = Color.WHITE
	_loading = false
	_load_path = ""
	_loaded_scene = null


func _build_interface() -> void:
	_overlay = Control.new()
	_overlay.name = "LoadingOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var black_backdrop := ColorRect.new()
	black_backdrop.color = Color.BLACK
	black_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(black_backdrop)

	_design_canvas = Control.new()
	_design_canvas.name = "ReferenceCanvas1672x941"
	_design_canvas.size = DESIGN_SIZE
	_design_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_design_canvas)

	_background_rect = TextureRect.new()
	_background_rect.name = "LoadingArtwork"
	_background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_background_rect.position = Vector2.ZERO
	_background_rect.size = DESIGN_SIZE
	_background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design_canvas.add_child(_background_rect)

	_ui_font = SystemFont.new()
	_ui_font.font_names = PackedStringArray([
		"DIN Condensed", "Roboto Condensed", "Helvetica Neue Condensed",
		"Arial Narrow", "Helvetica Neue", "Arial"
	])
	_ui_font.font_weight = 700
	_ui_font.font_stretch = 88

	# The empty metal track is already part of the supplied background artwork.
	# Clip the live fill to the exact inner opening measured from the reference.
	_fill_clip = Control.new()
	_fill_clip.name = "ProgressFillClip"
	_fill_clip.position = Vector2(544.0, 636.0)
	_fill_clip.size = Vector2(500.0, 29.0)
	_fill_clip.clip_contents = true
	_fill_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design_canvas.add_child(_fill_clip)

	_fill_panel = Panel.new()
	_fill_panel.name = "ProgressFill"
	_fill_panel.position = Vector2.ZERO
	_fill_panel.size = Vector2(0.0, 29.0)
	_fill_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color("50c02d")
	fill_style.border_color = Color("6dde43")
	fill_style.set_border_width_all(1)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	fill_style.shadow_color = Color(0.20, 0.88, 0.10, 0.34)
	fill_style.shadow_size = 6
	fill_style.shadow_offset = Vector2.ZERO
	_fill_panel.add_theme_stylebox_override("panel", fill_style)
	_fill_clip.add_child(_fill_panel)

	_percent_label = Label.new()
	_percent_label.name = "LoadingPercent"
	_percent_label.position = Vector2(1065.0, 626.0)
	_percent_label.size = Vector2(100.0, 48.0)
	_percent_label.text = "0%"
	_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_percent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_percent_label.add_theme_font_override("font", _ui_font)
	_percent_label.add_theme_font_size_override("font_size", 31)
	_percent_label.add_theme_color_override("font_color", Color("55cf32"))
	_percent_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.35, 0.03, 0.9))
	_percent_label.add_theme_constant_override("shadow_offset_x", 1)
	_percent_label.add_theme_constant_override("shadow_offset_y", 2)
	_design_canvas.add_child(_percent_label)

	var tip_icon := PanelContainer.new()
	tip_icon.name = "TipIcon"
	tip_icon.position = Vector2(586.0, 704.0)
	tip_icon.size = Vector2(34.0, 34.0)
	tip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color(0.01, 0.025, 0.012, 0.80)
	icon_style.border_color = Color("55cf32")
	icon_style.set_border_width_all(3)
	icon_style.corner_radius_top_left = 17
	icon_style.corner_radius_top_right = 17
	icon_style.corner_radius_bottom_left = 17
	icon_style.corner_radius_bottom_right = 17
	tip_icon.add_theme_stylebox_override("panel", icon_style)
	_design_canvas.add_child(tip_icon)

	var exclamation := Label.new()
	exclamation.text = "!"
	exclamation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	exclamation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exclamation.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exclamation.add_theme_font_override("font", _ui_font)
	exclamation.add_theme_font_size_override("font_size", 24)
	exclamation.add_theme_color_override("font_color", Color("55cf32"))
	tip_icon.add_child(exclamation)

	var tip_prefix := Label.new()
	tip_prefix.name = "TipPrefix"
	tip_prefix.position = Vector2(634.0, 699.0)
	tip_prefix.size = Vector2(58.0, 44.0)
	tip_prefix.text = "TIP:"
	tip_prefix.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_prefix.add_theme_font_override("font", _ui_font)
	tip_prefix.add_theme_font_size_override("font_size", 25)
	tip_prefix.add_theme_color_override("font_color", Color("55cf32"))
	_design_canvas.add_child(tip_prefix)

	_tip_label = Label.new()
	_tip_label.name = "TipText"
	_tip_label.position = Vector2(689.0, 699.0)
	_tip_label.size = Vector2(665.0, 44.0)
	_tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tip_label.add_theme_font_override("font", _ui_font)
	_tip_label.add_theme_font_size_override("font_size", 23)
	_tip_label.add_theme_color_override("font_color", Color(0.72, 0.73, 0.70, 1.0))
	_tip_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	_tip_label.add_theme_constant_override("shadow_offset_x", 2)
	_tip_label.add_theme_constant_override("shadow_offset_y", 2)
	_design_canvas.add_child(_tip_label)

	_error_label = Label.new()
	_error_label.name = "LoadError"
	_error_label.position = Vector2(475.0, 758.0)
	_error_label.size = Vector2(720.0, 50.0)
	_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_error_label.add_theme_font_override("font", _ui_font)
	_error_label.add_theme_font_size_override("font_size", 22)
	_error_label.add_theme_color_override("font_color", Color(1.0, 0.22, 0.16, 1.0))
	_error_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_error_label.add_theme_constant_override("outline_size", 5)
	_error_label.visible = false
	_design_canvas.add_child(_error_label)


func _layout_for_viewport() -> void:
	if _design_canvas == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var cover_scale: float = max(
		viewport_size.x / DESIGN_SIZE.x,
		viewport_size.y / DESIGN_SIZE.y
	)
	_design_canvas.scale = Vector2.ONE * cover_scale
	_design_canvas.position = (viewport_size - DESIGN_SIZE * cover_scale) * 0.5


func _select_tip() -> void:
	if TIPS.is_empty():
		_tip_label.text = ""
		return
	var index := _rng.randi_range(0, TIPS.size() - 1)
	if TIPS.size() > 1 and index == _last_tip_index:
		index = (index + _rng.randi_range(1, TIPS.size() - 1)) % TIPS.size()
	_last_tip_index = index
	_tip_label.text = TIPS[index]


func _apply_progress(value: float) -> void:
	var clamped := clampf(value, 0.0, 1.0)
	_fill_panel.size.x = _fill_clip.size.x * clamped
	_percent_label.text = "%d%%" % int(round(clamped * 100.0))
