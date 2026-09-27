class_name PauseMenu
extends ColorRect

signal resume_requested
signal restart_requested
signal main_menu_requested
signal sensitivity_changed(value: float)
signal music_changed(value: float)
signal haptics_changed(enabled: bool)
signal edit_layout_requested

## Source size of the painted background. Only the art uses it now; text and
## buttons are sized from the device's point scale (see _compute_layout).
const PANEL_SIZE := Vector2(1672.0, 941.0)
const ART_DIR := "res://assets/Game UI Art/Pause Menu/"
const BACKGROUND_PATH := ART_DIR + "Pause_Background.webp"
const STATUS_PANEL_PATH := ART_DIR + "Pause_Status_Panel.webp"
const HEALTH_ICON_PATH := ART_DIR + "Pause_Health_Icon.webp"
const STATUS_STRIP_PATH := ART_DIR + "Pause_Status_Strip.webp"
const TITLE_LOGO_PATH := ART_DIR + "Pause_Title_Logo.png"
const RESUME_ICON_PATH := ART_DIR + "Pause_Icon_Resume.svg"
const RESTART_ICON_PATH := ART_DIR + "Pause_Icon_Restart.svg"
const SETTINGS_ICON_PATH := ART_DIR + "Pause_Icon_Settings.svg"
const MAIN_MENU_ICON_PATH := ART_DIR + "Pause_Icon_Main_Menu.svg"
const JOURNAL_ICON_PATH := ART_DIR + "Pause_Icon_Journal.svg"

## Dashboard design space. The panel art is fitted to whatever room is left
## and every well below is scaled from these numbers, so the wells always sit
## on the painted frame.
const DASH_SIZE := Vector2(960.0, 630.0)
## Painted frame inside Pause_Status_Panel.webp (960x800 with empty margins).
const STATUS_PANEL_REGION := Rect2(8.0, 88.0, 944.0, 620.0)
const TITLE_PLATE := Rect2(183.0, 15.0, 598.0, 58.0)
const QUAD_TL := Rect2(17.0, 83.0, 460.0, 262.0)
const QUAD_TR := Rect2(485.0, 83.0, 458.0, 262.0)
const QUAD_BL := Rect2(17.0, 354.0, 460.0, 248.0)
const QUAD_BR := Rect2(485.0, 354.0, 458.0, 248.0)
const SELECTION_SOUND_PATH := "res://assets/Audio/UI/Menu Selection.mp3"
const CONFIRM_SOUND_PATH := "res://assets/Audio/UI/Settings Confirmation Credits.mp3"

## One type ramp, in device points (1 pt = 1/163 in on iPhone). Multiplied by
## the vpx-per-point unit at layout time. Phones get the compact ramp.
const RAMP_REGULAR := {"cap": 13.0, "body": 16.0, "head": 19.0, "value": 22.0, "nav": 24.0, "display": 30.0}
const RAMP_COMPACT := {"cap": 11.0, "body": 14.0, "head": 16.0, "value": 19.0, "nav": 23.0, "display": 24.0}
## Below this many points of screen height the phone layout is used.
const COMPACT_HEIGHT_PT := 520.0
const NAV_ROW_PT_COMPACT := 56.0
const NAV_ROW_PT_REGULAR := 62.0
const NAV_GAP_PT_COMPACT := 8.0
const NAV_GAP_PT_REGULAR := 14.0
const JOURNAL_ROW_PT := 44.0
## Nav plate art (see NavPlate): cropped, nine-patched riveted bar.
const NAV_PLATE_REGION := NavPlate.REGION
## Inside the left green bar / clear of the selected chevron (x 581-615).
const NAV_LABEL_LEFT_TEX := 46.0
const NAV_LABEL_RIGHT_TEX := 84.0
## The three live sections painted on Pause_Status_Strip.webp, as fractions of
## its width (the far-right box is the decorative pause plate).
const STRIP_SECTIONS := [Vector2(0.0146, 0.3049), Vector2(0.3114, 0.5886), Vector2(0.5951, 0.8780)]
const LOGO_ASPECT := 360.0 / 156.0
const JOURNAL_HEADERS := ["DATE", "RESULT", "ROOM", "TIME", "K / HS / ACC", "EARNED", "WEAPON"]
## Widest realistic cell per column; the run log sizes its columns and font
## from these so nothing is clipped. Phones drop WEAPON (it is in the detail).
const JOURNAL_SAMPLES := ["00/00 00:00", "CLEARED", "ROOM 20", "00:00", "000 / 00 / 00%", "$00000", "SAWN-OFFS"]

const GREEN := Color(0.38, 1.0, 0.20, 1.0)
const GREEN_SOFT := Color(0.52, 0.88, 0.38, 1.0)
const GREEN_MUTED := Color(0.39, 0.58, 0.31, 1.0)
const TEXT_LIGHT := Color(0.87, 0.89, 0.84, 1.0)
const TEXT_DIM := Color(0.55, 0.61, 0.52, 1.0)
const PANEL_DARK := Color(0.015, 0.022, 0.018, 0.94)
const PAUSED_RED := Color(0.94, 0.18, 0.16, 1.0)

var pause_panel: PanelContainer = null
var pause_menu_page: VBoxContainer = null
var pause_settings_page: Control = null
var pause_sensitivity_value: Label = null
var pause_sensitivity_slider: HSlider = null
var pause_music_value: Label = null
var pause_music_slider: HSlider = null
var pause_haptics_toggle: CheckButton = null
var settings_screen: SettingsScreen = null
var settings_category_buttons: Array[Button] = []
var settings_gameplay_page: VBoxContainer = null
var settings_controls_page: Control = null
var settings_graphics_page: VBoxContainer = null
var settings_audio_page: VBoxContainer = null
var settings_content: Control = null
var layout_editor_active: bool = false
var pause_weapon_value: Label = null
var pause_weapon_icon: Label = null
var pause_bank_value: Label = null
var pause_time_value: Label = null

var dashboard_root: Control = null
var health_status_value: Label = null
var player_health_value: Label = null
var player_room_value: Label = null
var player_upgrade_value: Label = null
var player_run_state_value: Label = null
var weapon_ammo_value: Label = null
var weapon_damage_value: Label = null
var weapon_rate_value: Label = null
var weapon_tier_value: Label = null
var stat_kills_value: Label = null
var stat_accuracy_value: Label = null
var stat_damage_value: Label = null
var stat_earnings_value: Label = null
var stat_headshots_value: Label = null
var stat_dealt_value: Label = null
var dashboard_art: TextureRect = null
var player_name_value: Label = null
var name_edit: LineEdit = null
var name_edit_button: Button = null
var weapon_image: TextureRect = null
var weapon_secondary_value: Label = null
var objective_rows: Array[Dictionary] = []
var journal_button: Button = null
var journal_root: Control = null
var journal_list: VBoxContainer = null
var journal_name_value: Label = null
var journal_runs_value: Label = null
var career_values: Dictionary = {}
## "dashboard", "journal" or "settings": which nav plate stays lit.
var current_page := "dashboard"

var nav_buttons: Array[Button] = []
var selected_nav_button: Button = null
var resume_button: Button = null
var restart_button: Button = null
var settings_button: Button = null
var main_menu_button: Button = null
var selection_audio: AudioStreamPlayer = null
var confirmation_audio: AudioStreamPlayer = null
var menu_font: SystemFont = null
var last_viewport_size := Vector2.ZERO
var hidden_hud_states: Dictionary = {}

## Testing / tuning hooks. >0 forces the device points per viewport pixel
## (iPhone 14 landscape is ~0.54). x >= 0 forces safe-area insets in viewport
## pixels as (left, top, right, bottom).
var points_per_vpx_override := 0.0
var safe_insets_override := Vector4(-1.0, 0.0, 0.0, 0.0)

var _canvas: Control = null
## Viewport pixels per device point, the one unit all text and hit targets use.
var _u := 1.0
var _compact := false
## Font sizes in viewport pixels: _fs for chrome, _wfs inside the four wells
## (same ramp, scaled together so the busiest well fits its frame).
var _fs: Dictionary = {}
var _wfs: Dictionary = {}
var _safe := Rect2()
var _dash_rect := Rect2()
var _dash_k := Vector2.ONE
var _journal_weights: Array[float] = []
var _journal_row_fs := 16
var _journal_header_fs := 13
var _cached_health := Vector2(100.0, 100.0)
var _cached_live_stats: Dictionary = {}
var _cached_bank := 0
var _cached_time := 0.0


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 400
	_build_interface()
	layout_overlay()
	if not RunManager.run_stats_changed.is_connected(_on_run_stats_changed):
		RunManager.run_stats_changed.connect(_on_run_stats_changed)


func _process(_delta: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size != last_viewport_size:
		layout_overlay()


func _build_interface() -> void:
	menu_font = SystemFont.new()
	menu_font.font_names = PackedStringArray(
		[
			"DIN Condensed",
			"Avenir Next Condensed",
			"Arial Narrow",
			"Bank Gothic",
			"Eurostile Extended",
			"Helvetica Neue",
		]
	)
	menu_font.font_weight = 750
	menu_font.font_stretch = 84

	pause_panel = PanelContainer.new()
	pause_panel.name = "PauseDesign"
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_panel.add_theme_stylebox_override("panel", _empty_style())
	add_child(pause_panel)

	_build_settings_screen()
	_build_audio()


# ------------------------------------------------------------------ layout

## Rebuilds the whole pause canvas for the current viewport. Cheap (a few
## dozen controls) and only runs when the viewport size changes.
func _rebuild_canvas(viewport_size: Vector2) -> void:
	_compute_layout(viewport_size)
	if name_edit != null and name_edit.visible:
		_cancel_name_edit()
	if _canvas != null:
		pause_panel.remove_child(_canvas)
		_canvas.queue_free()
	nav_buttons.clear()
	objective_rows.clear()
	career_values.clear()
	selected_nav_button = null

	_canvas = Control.new()
	_canvas.name = "DesignCanvas"
	_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	pause_panel.add_child(_canvas)

	var background := TextureRect.new()
	background.name = "BunkerBackground"
	background.texture = _load_texture(BACKGROUND_PATH)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.position = Vector2.ZERO
	background.size = viewport_size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(background)

	var shade := ColorRect.new()
	shade.name = "ReadabilityShade"
	shade.color = Color(0.0, 0.015, 0.0, 0.30)
	shade.position = Vector2.ZERO
	shade.size = viewport_size
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(shade)

	var s := _safe
	var gap := roundf((NAV_GAP_PT_COMPACT if _compact else NAV_GAP_PT_REGULAR) * _u)
	var band_h := ceilf((_fs["cap"] * 1.3 + _fs["value"] * 1.25) / 0.78)

	# Left column: logo + PAUSED, then the nav plates.
	var logo_h := band_h if _compact else clampf(s.size.y * 0.15, band_h, 150.0 * _u)
	var logo_rect := Rect2(s.position, Vector2(logo_h * LOGO_ASPECT, logo_h))
	var paused_text_w := _text_width("PAUSED", _fs["head"])
	var paused_w: float = paused_text_w + _fs["head"] * 3.2
	var title_bottom := logo_rect.end.y
	if not _compact:
		title_bottom += _fs["head"] * 1.6
	var row_pt := NAV_ROW_PT_COMPACT if _compact else NAV_ROW_PT_REGULAR
	var nav_top := title_bottom + gap * (1.5 if _compact else 1.0)
	var row_h := floorf(minf(row_pt * _u, (s.end.y - nav_top - gap * 4.0) / 5.0))
	var plate_s := row_h / NAV_PLATE_REGION.size.y
	var icon_size := roundf(_fs["nav"] * 1.1)
	var label_left: float = NAV_LABEL_LEFT_TEX * plate_s + icon_size + _fs["nav"] * 0.5
	var label_right := NAV_LABEL_RIGHT_TEX * plate_s
	var widest := 0.0
	for text in ["RESUME", "RESTART RUN", "SETTINGS", "JOURNAL", "MAIN MENU"]:
		widest = maxf(widest, _text_width(text, _fs["nav"]))
	var nav_w := ceilf(label_left + widest + label_right + _fs["nav"] * 0.6)
	# Narrow phones: give the dashboard more room by trimming the nav type,
	# never below 22pt.
	var nav_cap := s.size.x * (0.3 if _compact else 0.42)
	while nav_w > nav_cap and _fs["nav"] > int(ceilf(22.0 * _u)):
		_fs["nav"] = int(_fs["nav"]) - 1
		icon_size = roundf(_fs["nav"] * 1.1)
		label_left = NAV_LABEL_LEFT_TEX * plate_s + icon_size + _fs["nav"] * 0.5
		widest = 0.0
		for text in ["RESUME", "RESTART RUN", "SETTINGS", "JOURNAL", "MAIN MENU"]:
			widest = maxf(widest, _text_width(text, _fs["nav"]))
		nav_w = ceilf(label_left + widest + label_right + _fs["nav"] * 0.6)
	nav_w = maxf(nav_w, logo_rect.size.x + (gap + paused_w if _compact else 0.0))
	nav_w = minf(nav_w, s.size.x * 0.42)

	# Right column: status strip above the dashboard, both the same width.
	var col_x := s.position.x + nav_w + gap * 2.5
	var col_w: float = s.end.x - col_x
	var dash_avail := Vector2(col_w, s.end.y - (s.position.y + band_h + gap))
	var aspect := STATUS_PANEL_REGION.size.x / STATUS_PANEL_REGION.size.y
	var dash_size := dash_avail
	if dash_size.x / dash_size.y > aspect:
		dash_size.x = floorf(dash_size.y * aspect)
	else:
		# Width-bound (4:3 tablets, narrow phones): let the plate grow up to
		# 14% taller than the art so the wells gain room for type. The riveted
		# frame reads the same at that stretch.
		dash_size.y = floorf(minf(dash_avail.y, dash_size.x / aspect * 1.14))
	var block_top := s.position.y
	if not _compact:
		block_top += floorf((dash_avail.y - dash_size.y) * 0.5)
	var strip_rect := Rect2(col_x + (col_w - dash_size.x) * 0.5, block_top, dash_size.x, band_h)
	_dash_rect = Rect2(Vector2(strip_rect.position.x, strip_rect.end.y + gap), dash_size)
	_dash_k = dash_size / DASH_SIZE
	if not _compact:
		# Line the nav up with the dashboard when the column has the room.
		nav_top = clampf(_dash_rect.position.y, nav_top, maxf(nav_top, s.end.y - row_h * 5.0 - gap * 4.0))

	_build_title(logo_rect, paused_w)
	_build_top_status(strip_rect)
	_build_navigation(Rect2(s.position.x, nav_top, nav_w, row_h * 5.0 + gap * 4.0), row_h, gap, icon_size, label_left, label_right)
	_compute_well_type()
	_build_dashboard()
	_build_journal()


func _compute_layout(viewport_size: Vector2) -> void:
	var points_per_vpx := points_per_vpx_override if points_per_vpx_override > 0.0 else _detect_points_per_vpx(viewport_size)
	var art_scale := minf(viewport_size.x / PANEL_SIZE.x, viewport_size.y / PANEL_SIZE.y)
	# Never smaller than the old art-relative size on desktop, never smaller
	# than the point ramp on a phone.
	_u = maxf(art_scale * 1.25, 1.0 / maxf(points_per_vpx, 0.05))
	_compact = viewport_size.y * points_per_vpx < COMPACT_HEIGHT_PT
	var ramp: Dictionary = RAMP_COMPACT if _compact else RAMP_REGULAR
	_fs.clear()
	for key in ramp.keys():
		_fs[key] = int(roundf(float(ramp[key]) * _u))
	_safe = _safe_rect(viewport_size)


func _detect_points_per_vpx(viewport_size: Vector2) -> float:
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.y <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	var screen_scale := DisplayServer.screen_get_scale()
	if screen_scale <= 0.0:
		screen_scale = 1.0
	return (window_size.y / viewport_size.y) / screen_scale


## Notch / home-indicator insets plus a small breathing margin.
func _safe_rect(viewport_size: Vector2) -> Rect2:
	var margin := maxf(viewport_size.y * 0.025, 8.0 * _u)
	var insets := Vector4.ZERO
	if safe_insets_override.x >= 0.0:
		insets = safe_insets_override
	elif OS.has_feature("mobile"):
		var display_safe := Rect2(DisplayServer.get_display_safe_area())
		var window_size := Vector2(DisplayServer.window_get_size())
		if display_safe.size.x > 0.0 and display_safe.size.y > 0.0 and window_size.x > 0.0 and window_size.y > 0.0:
			var k := viewport_size / window_size
			insets = Vector4(
				display_safe.position.x * k.x,
				display_safe.position.y * k.y,
				maxf(window_size.x - display_safe.end.x, 0.0) * k.x,
				maxf(window_size.y - display_safe.end.y, 0.0) * k.y
			)
	var left := maxf(margin, insets.x + margin * 0.5)
	var top := maxf(margin, insets.y + margin * 0.5)
	var right := maxf(margin, insets.z + margin * 0.5)
	var bottom := maxf(margin, insets.w + margin * 0.5)
	return Rect2(left, top, maxf(viewport_size.x - left - right, 200.0), maxf(viewport_size.y - top - bottom, 200.0))


# ------------------------------------------------------------------ title + strip

func _build_title(logo_rect: Rect2, paused_w: float) -> void:
	var title_logo := TextureRect.new()
	title_logo.name = "BunkerZeroLogo"
	title_logo.position = logo_rect.position
	title_logo.size = logo_rect.size
	title_logo.texture = _load_texture(TITLE_LOGO_PATH)
	title_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(title_logo)

	var head: int = _fs["head"]
	var row := Rect2(logo_rect.position.x, logo_rect.end.y + head * 0.1, logo_rect.size.x, head * 1.4)
	if _compact:
		# Phones: beside the logo, so the nav keeps its full height.
		row = Rect2(logo_rect.end.x + head * 0.6, logo_rect.position.y + (logo_rect.size.y - head * 1.4) * 0.5, paused_w, head * 1.4)
	var text_w := _text_width("PAUSED", head) + head * 0.6
	var rule_w := maxf((row.size.x - text_w) * 0.5 - head * 0.2, head * 0.8)
	var rule_h := maxf(roundf(head * 0.12), 2.0)
	var rule_y := row.position.y + row.size.y * 0.5 - rule_h * 0.5
	_make_pause_rule(_canvas, Vector2(row.position.x, rule_y), Vector2(rule_w, rule_h))
	_make_label(_canvas, "PAUSED", Vector2(row.position.x + (row.size.x - text_w) * 0.5, row.position.y), Vector2(text_w, row.size.y), head, PAUSED_RED, HORIZONTAL_ALIGNMENT_CENTER)
	_make_pause_rule(_canvas, Vector2(row.end.x - rule_w, rule_y), Vector2(rule_w, rule_h))


func _build_top_status(strip_rect: Rect2) -> void:
	var strip := TextureRect.new()
	strip.name = "LiveStatusStrip"
	strip.position = strip_rect.position
	strip.size = strip_rect.size
	strip.texture = _load_texture(STATUS_STRIP_PATH)
	strip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	strip.stretch_mode = TextureRect.STRETCH_SCALE
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(strip)

	var cap: int = _fs["cap"]
	var value: int = _fs["value"]
	var cap_h := ceilf(cap * 1.3)
	var value_h := ceilf(value * 1.25)
	# Shared rows: every caption on one baseline, every value on another.
	var caption_y := strip_rect.position.y + floorf((strip_rect.size.y - cap_h - value_h) * 0.5)
	var value_y := caption_y + cap_h
	var pad := cap * 0.9
	var captions := ["HEALTH", "ELAPSED TIME", "PLAYER BANK"]
	var colors := [GREEN_SOFT, TEXT_LIGHT, GREEN_SOFT]
	var values: Array[Label] = []
	for index in range(3):
		var section: Vector2 = STRIP_SECTIONS[index]
		var x0 := strip_rect.position.x + strip_rect.size.x * section.x + pad
		var x1 := strip_rect.position.x + strip_rect.size.x * section.y - pad * 0.5
		if index == 0:
			var icon_size := minf(cap_h + value_h, strip_rect.size.y * 0.72)
			var health_icon := TextureRect.new()
			health_icon.position = Vector2(x0, strip_rect.position.y + (strip_rect.size.y - icon_size) * 0.5)
			health_icon.size = Vector2(icon_size, icon_size)
			health_icon.texture = _load_texture(HEALTH_ICON_PATH)
			health_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			health_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			health_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_canvas.add_child(health_icon)
			x0 += icon_size + cap * 0.5
		var width := maxf(x1 - x0, cap * 3.0)
		var caption := _make_label(_canvas, captions[index], Vector2(x0, caption_y), Vector2(width, cap_h), cap, TEXT_LIGHT)
		caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_enable_fit(caption, cap, int(cap * 0.8))
		var value_label := _make_label(_canvas, "", Vector2(x0, value_y), Vector2(width, value_h), value, colors[index])
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		_enable_fit(value_label, value, cap)
		values.append(value_label)
	health_status_value = values[0]
	pause_time_value = values[1]
	pause_bank_value = values[2]


# ------------------------------------------------------------------ navigation

func _build_navigation(area: Rect2, row_h: float, gap: float, icon_size: float, label_left: float, label_right: float) -> void:
	pause_menu_page = VBoxContainer.new()
	pause_menu_page.name = "Navigation"
	pause_menu_page.position = area.position
	pause_menu_page.size = area.size
	pause_menu_page.add_theme_constant_override("separation", int(gap))
	_canvas.add_child(pause_menu_page)

	var geometry := {"size": Vector2(area.size.x, row_h), "icon": icon_size, "left": label_left, "right": label_right}
	resume_button = _make_nav_button("RESUME", RESUME_ICON_PATH, _on_resume, geometry)
	restart_button = _make_nav_button("RESTART RUN", RESTART_ICON_PATH, _on_restart, geometry)
	settings_button = _make_nav_button("SETTINGS", SETTINGS_ICON_PATH, open_settings, geometry)
	journal_button = _make_nav_button("JOURNAL", JOURNAL_ICON_PATH, _on_journal_pressed, geometry)
	main_menu_button = _make_nav_button("MAIN MENU", MAIN_MENU_ICON_PATH, _on_main_menu, geometry)
	_configure_nav_focus()


func _make_nav_button(label_text: String, icon_path: String, callback: Callable, geometry: Dictionary) -> Button:
	var row_size: Vector2 = geometry["size"]
	var holder := Control.new()
	holder.custom_minimum_size = row_size
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	pause_menu_page.add_child(holder)

	# Nine-patch drawn at plate scale, so the rivets keep proportion while the
	# plate stretches to the label width. Hover/selection lights this same
	# plate in place (NavPlate.lit); it never swaps to a different box.
	var plate_s := row_size.y / NAV_PLATE_REGION.size.y
	var plate := NavPlate.new()
	plate.fit(row_size)
	holder.add_child(plate)

	var icon_size: float = geometry["icon"]
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = Vector2(NAV_LABEL_LEFT_TEX * plate_s, (row_size.y - icon_size) * 0.5)
	icon.size = Vector2(icon_size, icon_size)
	icon.texture = _load_texture(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(icon)

	var button := Button.new()
	button.name = label_text.to_pascal_case().replace(" ", "") + "Button"
	button.text = label_text
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.position = Vector2.ZERO
	button.size = row_size
	button.add_theme_font_override("font", menu_font)
	button.add_theme_font_size_override("font_size", _fs["nav"])
	button.add_theme_color_override("font_color", TEXT_LIGHT)
	button.add_theme_color_override("font_hover_color", GREEN)
	button.add_theme_color_override("font_pressed_color", GREEN)
	# Label starts right of the icon and stops short of the selected plate's
	# chevron, so long labels never run under either.
	var pad := StyleBoxEmpty.new()
	pad.content_margin_left = geometry["left"]
	pad.content_margin_right = geometry["right"]
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
		button.add_theme_stylebox_override(state, pad)
	button.set_meta("plate", plate)
	button.set_meta("icon", icon)
	button.mouse_entered.connect(_select_nav_button.bind(button, true))
	button.mouse_exited.connect(_restore_page_highlight)
	button.focus_entered.connect(_select_nav_button.bind(button, true))
	button.button_down.connect(_select_nav_button.bind(button, true))
	button.pressed.connect(callback)
	holder.add_child(button)
	nav_buttons.append(button)
	return button


func _configure_nav_focus() -> void:
	if nav_buttons.size() < 2:
		return
	for index in range(nav_buttons.size()):
		var button := nav_buttons[index]
		var previous := nav_buttons[(index - 1 + nav_buttons.size()) % nav_buttons.size()]
		var following := nav_buttons[(index + 1) % nav_buttons.size()]
		button.focus_neighbor_top = previous.get_path()
		button.focus_neighbor_bottom = following.get_path()


# ------------------------------------------------------------------ dashboard

## Status panel art cropped to its painted frame. The source image has wide
## transparent margins, which pushed text off the quadrants when stretched.
func _status_panel_texture() -> Texture2D:
	var source := _load_texture(STATUS_PANEL_PATH)
	if source == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = STATUS_PANEL_REGION
	return atlas


func _well_rect(quad: Rect2) -> Rect2:
	return Rect2(quad.position * _dash_k, quad.size * _dash_k)


func _well_inner(quad: Rect2) -> Rect2:
	var rect := _well_rect(quad)
	var pad_x := maxf(rect.size.x * 0.05, 8.0)
	var pad_y := maxf(rect.size.y * 0.05, 6.0)
	return rect.grow_individual(-pad_x, -pad_y, -pad_x, -pad_y)


func _header_height(sizes: Dictionary) -> float:
	return float(sizes["head"]) * 1.55


func _cell_height(sizes: Dictionary) -> float:
	return float(sizes["cap"]) * 1.1 + float(sizes["body"]) * 1.2


func _run_stat_columns(inner_width: float, cap_size: int) -> int:
	var widest := 0.0
	for caption in ["ZOMBIES KILLED", "HEADSHOTS", "ACCURACY", "DAMAGE DEALT", "DAMAGE TAKEN", "EARNINGS"]:
		widest = maxf(widest, _text_width(caption, cap_size))
	return 3 if widest <= inner_width / 3.0 - cap_size * 0.5 else 2


## Scale the ramp once for all four wells so the busiest one fits its frame.
## Every well then uses the same sizes.
func _compute_well_type() -> void:
	var header := _header_height(_fs)
	var cell := _cell_height(_fs)
	var needs := {
		QUAD_TL: header + _fs["display"] * 1.15 + 3.0 * _fs["body"] * 1.4,
		QUAD_TR: header + _fs["value"] * 1.1 + _fs["cap"] * 1.2 + 2.0 * cell,
		QUAD_BL: header + 4.0 * _fs["body"] * 1.5,
		QUAD_BR: header + (6.0 / _run_stat_columns(_well_inner(QUAD_BR).size.x, _fs["cap"])) * cell,
	}
	var k := 1.15
	for quad in needs.keys():
		k = minf(k, _well_inner(quad).size.y / float(needs[quad]))
	k = clampf(k, 0.8, 1.15)
	_wfs.clear()
	for key in _fs.keys():
		_wfs[key] = maxi(int(roundf(_fs[key] * k)), 9)


func _build_dashboard() -> void:
	var panel_art := TextureRect.new()
	panel_art.name = "StatusPanelArt"
	panel_art.position = _dash_rect.position
	panel_art.size = _dash_rect.size
	panel_art.texture = _status_panel_texture()
	panel_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel_art.stretch_mode = TextureRect.STRETCH_SCALE
	panel_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(panel_art)
	dashboard_art = panel_art

	dashboard_root = Control.new()
	dashboard_root.name = "Dashboard"
	dashboard_root.position = _dash_rect.position
	dashboard_root.size = _dash_rect.size
	dashboard_root.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.add_child(dashboard_root)
	var plate := _well_rect(TITLE_PLATE)
	var title_size := mini(_fs["head"], int(plate.size.y * 0.52))
	var title := _make_label(dashboard_root, "PLAYER & MISSION STATUS", plate.position, plate.size, title_size, TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	_enable_fit(title, title_size, int(title_size * 0.75))

	_build_player_status(dashboard_root)
	_build_weapon_status(dashboard_root)
	_build_mission_status(dashboard_root)
	_build_run_stats(dashboard_root)


## Well title, optional right-hand tag, divider. Returns the content top.
func _well_header(parent: Control, inner: Rect2, title: String, color: Color = TEXT_LIGHT, reserve_right: float = 0.0) -> float:
	var head: int = _wfs["head"]
	var h := ceilf(head * 1.25)
	var title_w := inner.size.x * 0.6
	if reserve_right > 0.0:
		title_w = inner.size.x - reserve_right - _wfs["cap"] * 0.6
	var label := _make_label(parent, title, inner.position, Vector2(title_w, h), head, color)
	_enable_fit(label, head, int(head * 0.8))
	var line := maxf(roundf(_u * 0.6), 1.0)
	_make_divider(parent, inner.position + Vector2(0.0, h + head * 0.1), Vector2(inner.size.x, line))
	return inner.position.y + _header_height(_wfs)


func _well_tag(parent: Control, inner: Rect2, text: String, color: Color) -> Label:
	var h := ceilf(_wfs["head"] * 1.25)
	var tag := _make_label(parent, text, inner.position + Vector2(inner.size.x * 0.45, 0.0), Vector2(inner.size.x * 0.55, h), _wfs["cap"], color, HORIZONTAL_ALIGNMENT_RIGHT)
	_enable_fit(tag, _wfs["cap"], int(_wfs["cap"] * 0.8))
	return tag


## Small header button (EDIT NAME / VIEW JOURNAL). The hit area runs from the
## top of the well to the divider so it is a comfortable tap.
func _well_button(parent: Control, quad: Rect2, inner: Rect2, text: String, callback: Callable) -> Button:
	var cap: int = _wfs["cap"]
	var well := _well_rect(quad)
	var width := _well_button_width(text, inner)
	var top := well.position.y + 3.0
	var bottom := inner.position.y + ceilf(_wfs["head"] * 1.25)
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.position = Vector2(inner.end.x - width, top)
	button.size = Vector2(width, maxf(bottom - top, cap * 1.8))
	button.clip_text = true
	_style_small_button(button, cap)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _well_button_width(text: String, inner: Rect2) -> float:
	return minf(_text_width(text, _wfs["cap"]) + _wfs["cap"] * 1.6, inner.size.x * 0.45)


## "CAPTION ........ VALUE" on one line; caption small, value one step up.
func _stat_line(parent: Control, origin: Vector2, width: float, height: float, caption: String, value_color: Color) -> Label:
	var cap: int = _wfs["cap"]
	var body: int = _wfs["body"]
	var line_h := maxf(height, body * 1.25)
	var y := origin.y + (height - line_h) * 0.5
	var caption_label := _make_label(parent, caption, Vector2(origin.x, y), Vector2(width * 0.5, line_h), cap, TEXT_DIM)
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_enable_fit(caption_label, cap, int(cap * 0.8))
	var value := _make_label(parent, "0", Vector2(origin.x + width * 0.5, y), Vector2(width * 0.5, line_h), body, value_color, HORIZONTAL_ALIGNMENT_RIGHT)
	_enable_fit(value, body, cap)
	return value


## Caption stacked over a value, used in the grids.
func _stat_cell(parent: Control, rect: Rect2, caption: String, value_color: Color) -> Label:
	var cap: int = _wfs["cap"]
	var body: int = _wfs["body"]
	var cap_h := ceilf(cap * 1.1)
	var value_h := ceilf(body * 1.2)
	var y := rect.position.y + maxf((rect.size.y - cap_h - value_h) * 0.5, 0.0)
	var width := rect.size.x - cap * 0.5
	var caption_label := _make_label(parent, caption, Vector2(rect.position.x, y), Vector2(width, cap_h), cap, TEXT_DIM)
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_enable_fit(caption_label, cap, int(cap * 0.8))
	var value := _make_label(parent, "0", Vector2(rect.position.x, y + cap_h), Vector2(width, value_h), body, value_color)
	value.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_enable_fit(value, body, int(cap * 0.85))
	return value


func _build_player_status(parent: Control) -> void:
	var inner := _well_inner(QUAD_TL)
	var y := _well_header(parent, inner, "PLAYER STATUS", TEXT_LIGHT, _well_button_width("EDIT NAME", inner))
	name_edit_button = _well_button(parent, QUAD_TL, inner, "EDIT NAME", _on_edit_name_pressed)

	var display: int = _wfs["display"]
	var name_h := ceilf(display * 1.15)
	player_name_value = _make_label(parent, "SURVIVOR", Vector2(inner.position.x, y), Vector2(inner.size.x, name_h), display, TEXT_LIGHT)
	_enable_fit(player_name_value, display, _wfs["value"])
	name_edit = LineEdit.new()
	name_edit.visible = false
	name_edit.max_length = JournalManager.MAX_NAME_LENGTH
	name_edit.placeholder_text = "ENTER NAME"
	name_edit.position = Vector2(inner.position.x, y + name_h * 0.06)
	name_edit.size = Vector2(inner.size.x, name_h * 0.88)
	name_edit.add_theme_font_override("font", menu_font)
	name_edit.add_theme_font_size_override("font_size", _wfs["value"])
	name_edit.add_theme_color_override("font_color", TEXT_LIGHT)
	name_edit.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.03, 0.02, 0.96), GREEN_MUTED, 2, 3))
	name_edit.add_theme_stylebox_override("focus", _panel_style(Color(0.02, 0.03, 0.02, 0.96), GREEN, 2, 3))
	name_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	name_edit.text_changed.connect(_on_name_text_changed)
	name_edit.text_submitted.connect(func(_text: String) -> void: _commit_name_edit())
	parent.add_child(name_edit)

	var top := y + name_h
	var pitch := (inner.end.y - top) / 3.0
	player_room_value = _stat_line(parent, Vector2(inner.position.x, top), inner.size.x, pitch, "CURRENT ROOM", GREEN_SOFT)
	player_upgrade_value = _stat_line(parent, Vector2(inner.position.x, top + pitch), inner.size.x, pitch, "SURVIVOR LEVEL", GREEN_SOFT)
	player_run_state_value = _stat_line(parent, Vector2(inner.position.x, top + pitch * 2.0), inner.size.x, pitch, "RUN STATE", GREEN_SOFT)


func _build_weapon_status(parent: Control) -> void:
	var inner := _well_inner(QUAD_TR)
	var y := _well_header(parent, inner, "WEAPON")
	pause_weapon_icon = _well_tag(parent, inner, "SIDEARM", GREEN_MUTED)

	var value: int = _wfs["value"]
	var cap: int = _wfs["cap"]
	var name_h := ceilf(value * 1.1)
	var swap_h := ceilf(cap * 1.2)
	var hero_h := name_h + swap_h
	# Art box sized for the widest silhouettes (knife, minigun) and still tall
	# enough for the pistol / crossbow.
	var image_w := floorf(inner.size.x * 0.42)
	weapon_image = TextureRect.new()
	weapon_image.name = "WeaponArt"
	weapon_image.position = Vector2(inner.end.x - image_w, y)
	weapon_image.size = Vector2(image_w, hero_h)
	weapon_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	weapon_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(weapon_image)
	var text_w := inner.size.x - image_w - cap * 0.6
	pause_weapon_value = _make_label(parent, "UNARMED", Vector2(inner.position.x, y), Vector2(text_w, name_h), value, TEXT_LIGHT)
	_enable_fit(pause_weapon_value, value, _wfs["body"])
	weapon_secondary_value = _make_label(parent, "", Vector2(inner.position.x, y + name_h), Vector2(text_w, swap_h), cap, TEXT_DIM)
	_enable_fit(weapon_secondary_value, cap, int(cap * 0.8))

	# Left column is wider: it carries "AMMO 150 / 450" and "1.2 RPS · 45 DPS".
	var grid_top := y + hero_h + cap * 0.2
	var cell_h := (inner.end.y - grid_top) / 2.0
	var left_w := floorf(inner.size.x * 0.58)
	var right_w := inner.size.x - left_w
	weapon_ammo_value = _stat_cell(parent, Rect2(inner.position.x, grid_top, left_w, cell_h), "AMMO", GREEN_SOFT)
	weapon_damage_value = _stat_cell(parent, Rect2(inner.position.x + left_w, grid_top, right_w, cell_h), "DAMAGE", GREEN_SOFT)
	weapon_rate_value = _stat_cell(parent, Rect2(inner.position.x, grid_top + cell_h, left_w, cell_h), "FIRE RATE", GREEN_SOFT)
	weapon_tier_value = _stat_cell(parent, Rect2(inner.position.x + left_w, grid_top + cell_h, right_w, cell_h), "UPGRADE LEVEL", GREEN_SOFT)


func _build_mission_status(parent: Control) -> void:
	var inner := _well_inner(QUAD_BL)
	var y := _well_header(parent, inner, "MISSION")
	_well_tag(parent, inner, "CONTAINMENT", GREEN)
	objective_rows.clear()
	var count := maxi(RunManager.OBJECTIVES.size(), 1)
	var pitch := (inner.end.y - y) / float(count)
	var body: int = _wfs["body"]
	var box_size := floorf(minf(body * 0.95, pitch * 0.7))
	var progress_w := inner.size.x * (0.32 if _compact else 0.28)
	for index in range(RunManager.OBJECTIVES.size()):
		var row_y := y + pitch * index
		var box := ObjectiveCheck.new()
		box.position = Vector2(inner.position.x, row_y + (pitch - box_size) * 0.5)
		box.size = Vector2(box_size, box_size)
		parent.add_child(box)
		var title_x := inner.position.x + box_size + body * 0.5
		var title := _make_label(parent, "", Vector2(title_x, row_y), Vector2(inner.end.x - progress_w - title_x, pitch), body, TEXT_LIGHT)
		_enable_fit(title, body, int(_wfs["cap"] * 0.85))
		var progress := _make_label(parent, "", Vector2(inner.end.x - progress_w, row_y), Vector2(progress_w, pitch), body, TEXT_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
		_enable_fit(progress, body, _wfs["cap"])
		objective_rows.append({"box": box, "title": title, "progress": progress})


func _build_run_stats(parent: Control) -> void:
	var inner := _well_inner(QUAD_BR)
	var y := _well_header(parent, inner, "RUN STATS", TEXT_LIGHT, _well_button_width("VIEW JOURNAL  ›", inner))
	_well_button(parent, QUAD_BR, inner, "VIEW JOURNAL  ›", _on_journal_pressed)
	var columns := _run_stat_columns(inner.size.x, _wfs["cap"])
	var rows := int(ceil(6.0 / columns))
	var cell := Vector2(inner.size.x / columns, (inner.end.y - y) / rows)
	var fields := [
		["ZOMBIES KILLED", TEXT_LIGHT], ["HEADSHOTS", TEXT_LIGHT], ["ACCURACY", TEXT_LIGHT],
		["DAMAGE DEALT", TEXT_LIGHT], ["DAMAGE TAKEN", TEXT_LIGHT], ["EARNINGS", GREEN_SOFT],
	]
	var labels: Array[Label] = []
	for index in range(fields.size()):
		var origin := Vector2(inner.position.x + cell.x * (index % columns), y + cell.y * (index / columns))
		labels.append(_stat_cell(parent, Rect2(origin, cell), fields[index][0], fields[index][1]))
	stat_kills_value = labels[0]
	stat_headshots_value = labels[1]
	stat_accuracy_value = labels[2]
	stat_dealt_value = labels[3]
	stat_damage_value = labels[4]
	stat_earnings_value = labels[5]


func _style_small_button(button: Button, font_size: int) -> void:
	button.add_theme_font_override("font", menu_font)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", TEXT_LIGHT)
	button.add_theme_color_override("font_hover_color", GREEN)
	button.add_theme_color_override("font_pressed_color", GREEN)
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.04, 0.05, 0.045, 0.92), Color(0.38, 0.42, 0.38, 0.9), 1, 3))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.05, 0.09, 0.04, 0.95), GREEN_MUTED, 1, 3))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.05, 0.12, 0.04, 0.95), GREEN, 1, 3))
	button.add_theme_stylebox_override("focus", _empty_style())


# ------------------------------------------------------------------ journal page

func _build_journal() -> void:
	var page_size := _dash_rect.size
	var cap: int = _fs["cap"]
	var body: int = _fs["body"]
	var head: int = _fs["head"]
	var value: int = _fs["value"]
	var pad := maxf(page_size.x * 0.025, 10.0)

	journal_root = Control.new()
	journal_root.name = "Journal"
	journal_root.position = _dash_rect.position
	journal_root.size = page_size
	journal_root.visible = false
	journal_root.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.add_child(journal_root)

	var frame := Panel.new()
	frame.position = Vector2.ZERO
	frame.size = page_size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := _panel_style(Color(0.03, 0.035, 0.032, 0.95), Color(0.34, 0.35, 0.34, 1.0), 3, 6)
	frame_style.shadow_color = Color(0, 0, 0, 0.6)
	frame_style.shadow_size = 10
	frame.add_theme_stylebox_override("panel", frame_style)
	journal_root.add_child(frame)
	var plate_rect := _well_rect(TITLE_PLATE)
	var plate := TextureRect.new()
	var plate_texture := AtlasTexture.new()
	plate_texture.atlas = _load_texture(STATUS_PANEL_PATH)
	plate_texture.region = Rect2(188.0, 103.0, 588.0, 57.0)
	plate.texture = plate_texture
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	plate.position = plate_rect.position
	plate.size = plate_rect.size
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	journal_root.add_child(plate)
	var title_size := mini(head, int(plate_rect.size.y * 0.52))
	var title := _make_label(journal_root, "SURVIVOR JOURNAL", plate_rect.position, plate_rect.size, title_size, TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	_enable_fit(title, title_size, int(title_size * 0.75))
	var back := Button.new()
	back.text = "‹  STATUS"
	back.focus_mode = Control.FOCUS_NONE
	back.position = Vector2(pad, plate_rect.position.y)
	back.size = Vector2(minf(_text_width(back.text, cap) + cap * 1.8, plate_rect.position.x - pad * 1.5), plate_rect.size.y)
	back.clip_text = true
	_style_small_button(back, cap)
	back.pressed.connect(_show_dashboard)
	journal_root.add_child(back)

	# Career block: name + run count on the left, a 3x2 grid of records.
	var cell_h := ceilf(cap * 1.1 + value * 1.2)
	var left_h := ceilf(cap * 1.2 + value * 1.25 + cap * 1.2)
	var inner_pad := cap * 1.0
	var career_h := maxf(left_h, cell_h * 2.0 + cap * 0.4) + inner_pad * 2.0
	var career := Panel.new()
	career.position = Vector2(pad, plate_rect.end.y + pad * 0.8)
	career.size = Vector2(page_size.x - pad * 2.0, career_h)
	career.mouse_filter = Control.MOUSE_FILTER_IGNORE
	career.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.025, 0.022, 0.9), Color(0.25, 0.27, 0.25, 1.0), 1, 4))
	journal_root.add_child(career)
	var left_w: float = career.size.x * 0.3
	var left_y := (career_h - left_h) * 0.5
	_make_label(career, "CAREER", Vector2(inner_pad, left_y), Vector2(left_w, cap * 1.2), cap, GREEN)
	journal_name_value = _make_label(career, "SURVIVOR", Vector2(inner_pad, left_y + cap * 1.2), Vector2(left_w - inner_pad, value * 1.25), value, TEXT_LIGHT)
	_enable_fit(journal_name_value, value, body)
	journal_runs_value = _make_label(career, "0 RUNS PLAYED", Vector2(inner_pad, left_y + cap * 1.2 + value * 1.25), Vector2(left_w - inner_pad, cap * 1.2), cap, TEXT_DIM)
	career_values.clear()
	var career_fields := [
		["best_room", "BEST ROOM"], ["kills", "KILLS"], ["headshots", "HEADSHOTS"],
		["best_accuracy", "BEST ACCURACY"], ["longest_time", "LONGEST RUN"], ["earnings", "EARNINGS"],
	]
	var grid_x: float = inner_pad + left_w
	var col_w: float = (career.size.x - grid_x - inner_pad) / 3.0
	var grid_y := (career_h - cell_h * 2.0 - cap * 0.4) * 0.5
	for index in range(career_fields.size()):
		var origin := Vector2(grid_x + col_w * (index % 3), grid_y + (cell_h + cap * 0.4) * (index / 3))
		var caption := _make_label(career, career_fields[index][1], origin, Vector2(col_w - cap * 0.5, cap * 1.1), cap, TEXT_DIM)
		caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_enable_fit(caption, cap, int(cap * 0.8))
		var field := _make_label(career, "0", origin + Vector2(0.0, cap * 1.1), Vector2(col_w - cap * 0.5, value * 1.2), value, GREEN_SOFT)
		field.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		_enable_fit(field, value, body)
		career_values[career_fields[index][0]] = field

	# Run log
	var log_y := career.position.y + career_h + pad * 0.6
	var log_h := ceilf(body * 1.4)
	var log_title_w := _text_width("RUN LOG", body) + body
	_make_label(journal_root, "RUN LOG", Vector2(pad, log_y), Vector2(log_title_w, log_h), body, GREEN)
	var hint := _make_label(journal_root, "Newest first. Tap a run for details.", Vector2(pad + log_title_w, log_y), Vector2(page_size.x - pad * 2.0 - log_title_w, log_h), cap, TEXT_DIM)
	_enable_fit(hint, cap, int(cap * 0.85))
	var row_pad := body * 0.6
	_plan_journal_columns(page_size.x - pad * 2.0 - row_pad * 2.0)
	var header := _journal_columns(null, JOURNAL_HEADERS, TEXT_DIM, _journal_header_fs)
	header.position = Vector2(pad + row_pad, log_y + log_h)
	header.size = Vector2(page_size.x - pad * 2.0 - row_pad * 2.0, ceilf(cap * 1.4))
	journal_root.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.name = "RunLog"
	var scroll_top: float = header.position.y + header.size.y + cap * 0.3
	scroll.position = Vector2(pad, scroll_top)
	scroll.size = Vector2(page_size.x - pad * 2.0, page_size.y - scroll_top - pad)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	journal_root.add_child(scroll)
	journal_list = VBoxContainer.new()
	journal_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_list.add_theme_constant_override("separation", int(maxf(_u * 5.0, 4.0)))
	scroll.add_child(journal_list)


func _plan_journal_columns(width: float) -> void:
	var count := 6 if _compact else 7
	var body: int = _fs["body"]
	var cap: int = _fs["cap"]
	_journal_weights.clear()
	var total := 0.0
	for index in range(count):
		var need := maxf(_text_width(JOURNAL_SAMPLES[index], 100), _text_width(JOURNAL_HEADERS[index], 100) * float(cap) / float(body)) / 100.0
		_journal_weights.append(need)
		total += need
	# Font that makes every sample fit, never above the body size.
	var fit := width / (total * 1.04 + 0.5 * (count - 1))
	_journal_row_fs = clampi(int(floorf(fit)), mini(cap, body), body)
	_journal_header_fs = mini(cap, int(_journal_row_fs * 0.9))


func _journal_columns(parent: Control, all_values: Array, color: Color, font_size: int) -> HBoxContainer:
	var values := all_values.slice(0, _journal_weights.size())
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", int(_journal_row_fs * 0.5))
	for index in range(values.size()):
		var label := Label.new()
		label.text = String(values[index])
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_stretch_ratio = _journal_weights[index]
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", menu_font)
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", color)
		row.add_child(label)
	if parent != null:
		parent.add_child(row)
	return row


func _refresh_journal() -> void:
	if journal_root == null:
		return
	journal_name_value.text = JournalManager.get_display_name()
	_refit(journal_name_value)
	var career := JournalManager.get_career()
	journal_runs_value.text = "%d RUN%s PLAYED" % [int(career["runs"]), "" if int(career["runs"]) == 1 else "S"]
	_set_text(career_values["best_room"], "ROOM %d" % int(career["best_room"]) if int(career["best_room"]) > 0 else "—")
	_set_text(career_values["kills"], "%d" % int(career["kills"]))
	_set_text(career_values["headshots"], "%d" % int(career["headshots"]))
	_set_text(career_values["best_accuracy"], "%.0f%%" % float(career["best_accuracy"]))
	_set_text(career_values["longest_time"], _format_clock(float(career["longest_time"])))
	_set_text(career_values["earnings"], "$%d" % int(career["earnings"]))
	for child in journal_list.get_children():
		child.queue_free()
	var runs := JournalManager.get_runs()
	if runs.is_empty():
		journal_list.add_child(_journal_empty_state())
		return
	for entry in runs:
		journal_list.add_child(_journal_run_card(entry as Dictionary))


## Framed card rather than a stray line of text.
func _journal_empty_state() -> Control:
	var scroll := journal_list.get_parent() as Control
	var card := PanelContainer.new()
	card.name = "EmptyState"
	var style := _panel_style(Color(0.025, 0.035, 0.025, 0.92), Color(GREEN_MUTED.r, GREEN_MUTED.g, GREEN_MUTED.b, 0.55), 1, 4)
	style.content_margin_left = _fs["body"]
	style.content_margin_right = _fs["body"]
	style.content_margin_top = _fs["body"] * 0.8
	style.content_margin_bottom = _fs["body"] * 0.8
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = Vector2(0.0, minf(scroll.size.y - 6.0, _fs["head"] * 5.5) if scroll != null else _fs["head"] * 5.0)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", int(_fs["cap"] * 0.6))
	card.add_child(column)
	var title := _container_label("NO RUNS LOGGED YET", _fs["head"], GREEN_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(title)
	var body := _container_label("Your next run is saved here when you die, clear it or quit to the menu.", _fs["body"], TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(body)
	return card


func _journal_run_card(entry: Dictionary) -> Control:
	var body: int = _fs["body"]
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 0)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0.0, maxf(JOURNAL_ROW_PT * _u, body * 2.2))
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.035, 0.04, 0.037, 0.95), Color(0.22, 0.24, 0.22, 1.0), 1, 3))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.05, 0.08, 0.045, 0.95), GREEN_MUTED, 1, 3))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.05, 0.1, 0.045, 0.95), GREEN, 1, 3))
	button.add_theme_stylebox_override("focus", _empty_style())
	card.add_child(button)
	var result := String(entry.get("result", "QUIT"))
	var result_color := GREEN if result == "CLEARED" else (Color(0.94, 0.22, 0.18, 1.0) if result == "DIED" else TEXT_DIM)
	var columns := _journal_columns(button, [
		_format_date(int(entry.get("ended_unix", 0))),
		result,
		"ROOM %d" % int(entry.get("room", 0)) if int(entry.get("room", 0)) > 0 else "HUB",
		_format_clock(float(entry.get("time", 0.0))),
		"%d / %d / %.0f%%" % [int(entry.get("kills", 0)), int(entry.get("headshots", 0)), float(entry.get("accuracy", 0.0))],
		"$%d" % int(entry.get("earnings", 0)),
		_weapon_label(String(entry.get("weapon", ""))),
	], TEXT_LIGHT, _journal_row_fs)
	columns.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	columns.offset_left = body * 0.6
	columns.offset_right = -body * 0.6
	(columns.get_child(1) as Label).add_theme_color_override("font_color", result_color)

	var detail := PanelContainer.new()
	detail.visible = false
	detail.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.03, 0.022, 0.95), Color(0.22, 0.3, 0.2, 1.0), 1, 3))
	var detail_text := _container_label(
		"SURVIVOR  %s     ROOMS CLEARED  %d     SHOTS  %d FIRED / %d HIT\nDAMAGE DEALT  %d     DAMAGE TAKEN  %d     LOADOUT  %s" % [
			String(entry.get("name", "SURVIVOR")),
			int(entry.get("rooms_cleared", 0)),
			int(entry.get("shots_fired", 0)),
			int(entry.get("shots_hit", 0)),
			int(entry.get("damage_dealt", 0)),
			int(entry.get("damage_taken", 0)),
			_weapon_label(String(entry.get("weapon", ""))) + (("  +  " + _weapon_label(String(entry.get("secondary", "")))) if String(entry.get("secondary", "")) != "" else ""),
		],
		_fs["cap"],
		TEXT_LIGHT
	)
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, int(body * 0.6))
	margin.add_child(detail_text)
	detail.add_child(margin)
	card.add_child(detail)
	button.pressed.connect(func() -> void:
		detail.visible = not detail.visible
		_play_sound(selection_audio))
	return card


func _format_date(unix: int) -> String:
	if unix <= 0:
		return "—"
	var info := Time.get_datetime_dict_from_unix_time(unix + _utc_offset_seconds())
	return "%02d/%02d %02d:%02d" % [int(info["month"]), int(info["day"]), int(info["hour"]), int(info["minute"])]


func _utc_offset_seconds() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


func _format_clock(seconds: float) -> String:
	var total := int(maxf(seconds, 0.0))
	return "%d:%02d" % [total / 60, total % 60]


func _weapon_label(weapon_id: String) -> String:
	match weapon_id:
		"pistol":
			return "PISTOL"
		"uzi":
			return "UZI"
		"shotgun":
			return "SHOTGUN"
		"sawnoffs":
			return "SAWN-OFFS"
		"crossbow":
			return "CROSSBOW"
		"knife":
			return "KNIFE"
		"minigun":
			return "MINIGUN"
		"smg":
			return "SMG"
		"grenade_launcher":
			return "GRENADE LAUNCHER"
		"lmg":
			return "LMG"
		"sawnoff":
			return "SAWN-OFF"
	return "UNARMED"


# ------------------------------------------------------------------ pages

func _on_journal_pressed() -> void:
	_play_confirmation()
	if journal_root != null and journal_root.visible:
		_show_dashboard()
		return
	_show_journal()


func _show_journal() -> void:
	current_page = "journal"
	_cancel_name_edit()
	_refresh_journal()
	dashboard_root.visible = false
	dashboard_art.visible = false
	journal_root.visible = true
	_restore_page_highlight()


func _show_dashboard() -> void:
	current_page = "dashboard"
	if journal_root != null:
		journal_root.visible = false
	if dashboard_root != null:
		dashboard_root.visible = true
	if dashboard_art != null:
		dashboard_art.visible = true
	_restore_page_highlight()


## Hover/focus highlight a button temporarily; when the pointer leaves, the
## green plate goes back to the button for the page on screen.
func _restore_page_highlight() -> void:
	var page_button := resume_button
	if current_page == "journal":
		page_button = journal_button
	elif current_page == "settings":
		page_button = settings_button
	selected_nav_button = null
	_select_nav_button(page_button, false)


# ------------------------------------------------------------------ player name

func _on_edit_name_pressed() -> void:
	if name_edit.visible:
		_commit_name_edit()
		return
	name_edit.text = JournalManager.get_display_name()
	name_edit.visible = true
	player_name_value.visible = false
	name_edit_button.text = "SAVE NAME"
	name_edit.grab_focus()
	name_edit.select_all()


func _on_name_text_changed(new_text: String) -> void:
	var clean := JournalManager.sanitize_name(new_text)
	if clean != new_text:
		var caret := name_edit.caret_column
		name_edit.text = clean
		name_edit.caret_column = mini(caret, clean.length())


func _commit_name_edit() -> void:
	if name_edit == null or not name_edit.visible:
		return
	var saved := JournalManager.set_display_name(name_edit.text)
	_set_text(player_name_value, saved)
	_cancel_name_edit()
	_play_confirmation()


func _cancel_name_edit() -> void:
	if name_edit == null:
		return
	name_edit.visible = false
	name_edit.release_focus()
	player_name_value.visible = true
	name_edit_button.text = "EDIT NAME"


# ------------------------------------------------------------------ live refresh

func refresh_dashboard() -> void:
	if player_name_value != null and not name_edit.visible:
		_set_text(player_name_value, JournalManager.get_display_name())
	if player_room_value != null:
		_set_text(player_room_value, "ROOM %d" % RunManager.current_combat_room if RunManager.run_active and RunManager.current_combat_room > 0 else "SAFE HUB")
	if player_upgrade_value != null:
		_set_text(player_upgrade_value, "LEVEL %d" % UpgradeManager.survivor_level)
	if player_run_state_value != null:
		var state := "STANDBY"
		if RunManager.run_active:
			state = "ROOM CLEARED" if RunManager.is_combat_room_cleared(RunManager.current_combat_room) else "IN COMBAT"
		_set_text(player_run_state_value, state)
		player_run_state_value.add_theme_color_override("font_color", Color(0.94, 0.3, 0.2, 1.0) if state == "IN COMBAT" else GREEN_SOFT)
	if stat_kills_value != null:
		_set_text(stat_kills_value, "%d" % RunManager.run_kills)
		_set_text(stat_headshots_value, "%d" % RunManager.run_headshots)
		_set_text(stat_accuracy_value, "%.0f%%" % RunManager.get_accuracy())
		_set_text(stat_dealt_value, "%d" % int(round(RunManager.run_damage_dealt)))
		_set_text(stat_damage_value, "%d" % int(round(RunManager.run_damage_taken)))
		_set_text(stat_earnings_value, "$%d" % RunManager.run_earnings)
	var objectives := RunManager.get_objectives()
	for index in range(mini(objectives.size(), objective_rows.size())):
		var objective: Dictionary = objectives[index]
		var row: Dictionary = objective_rows[index]
		var done := bool(objective["done"])
		(row["box"] as ObjectiveCheck).checked = done
		var title := row["title"] as Label
		_set_text(title, String(objective["title"]))
		title.add_theme_color_override("font_color", GREEN_SOFT if done else TEXT_LIGHT)
		var progress := row["progress"] as Label
		if done:
			_set_text(progress, "DONE")
			progress.add_theme_color_override("font_color", GREEN)
		elif String(objective["id"]) == "survive_120":
			_set_text(progress, "%s / %s" % [_format_clock(float(objective["current"])), _format_clock(float(objective["target"]))])
			progress.add_theme_color_override("font_color", TEXT_DIM)
		else:
			_set_text(progress, "%d / %d" % [int(objective["current"]), int(objective["target"])])
			progress.add_theme_color_override("font_color", TEXT_DIM)
	if pause_time_value != null:
		_set_text(pause_time_value, _format_time(RunManager.elapsed_time))
	if pause_bank_value != null:
		_set_text(pause_bank_value, "$%d" % EconomyManager.get_balance())


func _refresh_weapon(stats: Dictionary) -> void:
	_cached_live_stats = stats.duplicate()
	if pause_weapon_value == null:
		return
	var weapon_id := String(stats.get("weapon_id", ""))
	var display_name := _weapon_label(weapon_id)
	_set_text(pause_weapon_value, display_name)
	_set_text(pause_weapon_icon, {"pistol": "SIDEARM", "uzi": "UZI", "shotgun": "12 GAUGE", "sawnoffs": "DOUBLE", "crossbow": "BOLT", "knife": "MELEE", "minigun": "ROTARY", "smg": "SMG", "grenade_launcher": "GL", "lmg": "LMG", "sawnoff": "SAWN-OFF"}.get(weapon_id, "NO WEAPON"))
	var image_path := "res://assets/UI/weapon_%s.png" % weapon_id
	weapon_image.texture = load(image_path) as Texture2D if weapon_id != "" and ResourceLoader.exists(image_path) else null
	var secondary := String(stats.get("secondary_id", ""))
	_set_text(weapon_secondary_value, ("⇄  SWAP TO %s" % _weapon_label(secondary)) if secondary != "" else "")
	if weapon_id == "":
		_set_text(weapon_ammo_value, "—")
		_set_text(weapon_damage_value, "—")
		_set_text(weapon_rate_value, "—")
	else:
		if bool(stats.get("unlimited", false)):
			_set_text(weapon_ammo_value, "UNLIMITED")
		else:
			_set_text(weapon_ammo_value, "%d / %d" % [int(stats.get("ammo", 0)), int(stats.get("reserve", 0))])
		var hit_damage := UpgradeManager.get_weapon_damage(weapon_id)
		_set_text(weapon_damage_value, "%d" % int(round(hit_damage)))
		var interval := float(stats.get("shot_interval", 0.0))
		# Sustained cycle (break-reloads, recocks and spin cadence included) so
		# the dashboard's rate and DPS match what the gun actually delivers.
		var cycle := float(stats.get("sustained_interval", interval))
		if interval > 0.0 and cycle > 0.0:
			_set_text(weapon_rate_value, "%.1f RPS · %d DPS" % [1.0 / cycle, int(round(hit_damage / cycle))])
		else:
			_set_text(weapon_rate_value, "—")
	_set_text(weapon_tier_value, "LEVEL %d" % UpgradeManager.weapon_level)


func _on_run_stats_changed() -> void:
	if visible:
		refresh_dashboard()


## Green-ticked checkbox used by the mission list.
class ObjectiveCheck:
	extends Control

	var checked := false:
		set(value):
			checked = value
			queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var line := maxf(size.x * 0.09, 2.0)
		if checked:
			draw_rect(rect, Color(0.12, 0.42, 0.08, 1.0), true)
			draw_rect(rect, Color(0.45, 1.0, 0.25, 1.0), false, line)
			var tick := PackedVector2Array([size * Vector2(0.2, 0.52), size * Vector2(0.42, 0.74), size * Vector2(0.82, 0.26)])
			draw_polyline(tick, Color(0.85, 1.0, 0.8, 1.0), line * 1.4, true)
		else:
			draw_rect(rect, Color(0.02, 0.03, 0.02, 0.9), true)
			draw_rect(rect, Color(0.55, 0.61, 0.52, 1.0), false, line)


func _build_settings_screen() -> void:
	# Full-screen Settings takeover (same screen the main menu uses). It lives
	# beside the pause design so opening it replaces the whole pause canvas.
	settings_screen = SettingsScreen.new()
	settings_screen.name = "SettingsScreen"
	add_child(settings_screen)
	settings_screen.closed.connect(_on_settings_screen_closed)
	settings_screen.sensitivity_changed.connect(func(value: float) -> void: sensitivity_changed.emit(value))
	settings_screen.haptics_changed.connect(func(enabled: bool) -> void: haptics_changed.emit(enabled))


func _on_settings_screen_closed() -> void:
	if current_page == "settings":
		current_page = "journal" if journal_root != null and journal_root.visible else "dashboard"
	if pause_panel != null:
		pause_panel.visible = true
	if current_page == "journal":
		_refresh_journal()
	elif visible:
		refresh_dashboard()
	if visible:
		_restore_page_highlight()


func begin_layout_editor() -> void:
	layout_editor_active = true
	visible = false
	_restore_gameplay_hud()


func end_layout_editor() -> void:
	layout_editor_active = false
	visible = true
	_hide_gameplay_hud()
	open_settings()


func _build_audio() -> void:
	selection_audio = _make_audio_player("PauseSelectionSFX", SELECTION_SOUND_PATH, -9.0)
	confirmation_audio = _make_audio_player("PauseConfirmationSFX", CONFIRM_SOUND_PATH, -2.0)


func _make_audio_player(player_name: String, path: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.volume_db = volume_db
	if ResourceLoader.exists(path):
		player.stream = load(path) as AudioStream
	add_child(player)
	return player


func _select_nav_button(button: Button, play_sound: bool = true) -> void:
	if button == null or selected_nav_button == button:
		return
	selected_nav_button = button
	if play_sound:
		_play_sound(selection_audio)
	for candidate in nav_buttons:
		var plate := candidate.get_meta("plate", null) as NavPlate
		var icon := candidate.get_meta("icon", null) as TextureRect
		var selected := candidate == selected_nav_button
		if plate != null:
			plate.lit = selected
		if icon != null:
			icon.modulate = GREEN_SOFT if selected else TEXT_LIGHT
		candidate.add_theme_color_override("font_color", GREEN if selected else TEXT_LIGHT)
		candidate.add_theme_color_override("font_focus_color", GREEN if selected else TEXT_LIGHT)


## Lays the pause canvas out for the current viewport. The art (background,
## strip, panel frame) scales with the screen; type and hit targets come from
## the device point size, so a phone gets readable text instead of a shrunken
## 1672x941 poster.
func layout_overlay() -> void:
	if pause_panel == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	if _canvas != null and viewport_size == last_viewport_size:
		return
	last_viewport_size = viewport_size
	var focused := get_viewport().gui_get_focus_owner()
	var had_nav_focus := focused != null and nav_buttons.has(focused)
	_rebuild_canvas(viewport_size)
	_apply_cached_state()
	if had_nav_focus and visible and resume_button != null:
		resume_button.call_deferred("grab_focus")


## Refill a freshly built canvas from the last values it was shown with.
func _apply_cached_state() -> void:
	refresh_stats("", "", _cached_bank, _cached_time)
	_refresh_player_status(_cached_health.x, _cached_health.y)
	_refresh_weapon(_cached_live_stats)
	refresh_dashboard()
	if current_page == "journal":
		_show_journal()
	else:
		if current_page != "settings":
			current_page = "dashboard"
		_show_dashboard_widgets()
		_restore_page_highlight()


func _show_dashboard_widgets() -> void:
	if journal_root != null:
		journal_root.visible = false
	if dashboard_root != null:
		dashboard_root.visible = true
	if dashboard_art != null:
		dashboard_art.visible = true


func show_pause(
	weapon_name: String,
	ammo_text: String,
	bank: int,
	elapsed_time: float,
	look_sensitivity: float,
	haptics_enabled: bool,
	live_stats: Dictionary = {}
) -> void:
	_cached_live_stats = live_stats.duplicate()
	_cached_health = Vector2(float(live_stats.get("health", 100.0)), float(live_stats.get("max_health", 100.0)))
	layout_overlay()
	refresh_stats(weapon_name, ammo_text, bank, elapsed_time)
	_refresh_player_status(_cached_health.x, _cached_health.y)
	_refresh_weapon(live_stats)
	close_settings(false)
	_cancel_name_edit()
	_show_dashboard()
	refresh_dashboard()
	_hide_gameplay_hud()
	visible = true
	resume_button.call_deferred("grab_focus")


func hide_pause() -> void:
	if settings_screen != null and settings_screen.visible:
		settings_screen.close(false)
	visible = false
	_restore_gameplay_hud()


func _hide_gameplay_hud() -> void:
	if not hidden_hud_states.is_empty() or get_parent() == null:
		return
	for sibling in get_parent().get_children():
		if sibling == self or not (sibling is CanvasItem):
			continue
		var canvas_item := sibling as CanvasItem
		hidden_hud_states[canvas_item] = canvas_item.visible
		canvas_item.visible = false


func _restore_gameplay_hud() -> void:
	for item in hidden_hud_states:
		if is_instance_valid(item):
			var canvas_item := item as CanvasItem
			canvas_item.visible = bool(hidden_hud_states[item])
	hidden_hud_states.clear()


## Called by player.gd (set_equipped_weapon_display) and show_pause. The
## weapon quadrant itself is filled from live stats in _refresh_weapon().
func refresh_stats(_weapon_name: String, _ammo_text: String, bank: int, elapsed_time: float) -> void:
	_cached_bank = bank
	_cached_time = elapsed_time
	if pause_bank_value != null:
		_set_text(pause_bank_value, "$%d" % bank)
	if pause_time_value != null:
		_set_text(pause_time_value, _format_time(elapsed_time))


func _refresh_player_status(current_health: float, maximum_health: float) -> void:
	_cached_health = Vector2(current_health, maximum_health)
	var health_text := "%d / %d" % [int(round(current_health)), int(round(maximum_health))]
	if health_status_value != null:
		_set_text(health_status_value, health_text)


func open_settings() -> void:
	current_page = "settings"
	_cancel_name_edit()
	_restore_page_highlight()
	if settings_screen == null:
		return
	if pause_panel != null:
		pause_panel.visible = false
	settings_screen.open("pause", "controls")


func close_settings(play_sound: bool = true) -> void:
	if settings_screen != null and settings_screen.visible:
		settings_screen.close(play_sound)
	if pause_panel != null:
		pause_panel.visible = true


func _on_resume() -> void:
	_play_confirmation()
	resume_requested.emit()


func _on_restart() -> void:
	_play_confirmation()
	restart_requested.emit()


func _on_main_menu() -> void:
	_play_confirmation()
	main_menu_requested.emit()


func _play_confirmation() -> void:
	if selection_audio != null:
		selection_audio.stop()
	_play_sound(confirmation_audio)


func _play_sound(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		return
	player.stop()
	player.play()


func _format_time(total_seconds: float) -> String:
	var safe_seconds := maxf(total_seconds, 0.0)
	var minutes := int(floor(safe_seconds / 60.0))
	var seconds := int(floor(safe_seconds)) % 60
	var tenths := int(floor(fmod(safe_seconds, 1.0) * 10.0))
	return "%02d:%02d.%d" % [minutes, seconds, tenths]


# ------------------------------------------------------------------ text helpers

func _text_width(text: String, font_size: int) -> float:
	if menu_font == null:
		return text.length() * font_size * 0.5
	return menu_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


## Marks a label as shrink-to-fit between max_size and min_size (never below
## min_size; anything still too long is ellipsized instead of overflowing).
func _enable_fit(label: Label, max_size: int, min_size: int) -> void:
	if label == null:
		return
	label.set_meta("fit_max", max_size)
	label.set_meta("fit_min", mini(min_size, max_size))
	_refit(label)


func _refit(label: Label) -> void:
	if label == null or not label.has_meta("fit_max"):
		return
	var max_size := int(label.get_meta("fit_max"))
	var min_size := int(label.get_meta("fit_min"))
	var width := label.size.x - 2.0
	var font_size := max_size
	while font_size > min_size and _text_width(label.text, font_size) > width:
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)


func _set_text(label: Label, text_value: String) -> void:
	if label == null:
		return
	label.text = text_value
	_refit(label)


func _make_label(
	parent: Control,
	text_value: String,
	position_value: Vector2,
	size_value: Vector2,
	font_size: int,
	font_color: Color,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var label := Label.new()
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Never grow past the box it was given.
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_override("font", menu_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.90))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.position = position_value
	label.size = size_value
	parent.add_child(label)
	return label


func _container_label(
	text_value: String,
	font_size: int,
	font_color: Color,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", menu_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _make_divider(parent: Control, position_value: Vector2, size_value: Vector2) -> void:
	var divider := ColorRect.new()
	divider.position = position_value
	divider.size = size_value
	divider.color = Color(GREEN_MUTED.r, GREEN_MUTED.g, GREEN_MUTED.b, 0.42)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(divider)


func _make_pause_rule(parent: Control, position_value: Vector2, size_value: Vector2) -> void:
	var rule := ColorRect.new()
	rule.position = position_value
	rule.size = size_value
	rule.color = Color(0.82, 0.08, 0.07, 0.92)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rule)


func _panel_style(
	background_color: Color, border_color: Color, border_width: int, radius: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _empty_style() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("Pause menu art not found: %s" % path)
	return null
