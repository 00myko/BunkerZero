class_name SettingsScreen
extends Control

## Full-screen Settings takeover shared by the pause menu and the main menu.
##
## Left rail: logo + GAMEPLAY / CONTROLS / GRAPHICS / AUDIO / BACK.
## CONTROLS > TOUCH CONTROLS is a live layout editor: the centre is a real 3D
## view (LivePreview) with 1:1 stand-ins for every HUD control on top. Dragging
## a stand-in or a chip writes normalized coordinates to ControlSettingsManager;
## the in-run HUD re-reads those every frame, so Resume shows the new layout.
## Every slider and toggle writes through to ControlSettingsManager (or the
## music/save managers) and persists immediately.

signal closed
signal haptics_changed(enabled: bool)
signal sensitivity_changed(value: float)
signal menu_audio_changed

const DESIGN_HEIGHT := 941.0
const MIN_DESIGN_WIDTH := 1672.0
const ART_DIR := "res://assets/Game UI Art/Pause Menu/"
const BACKGROUND_PATH := ART_DIR + "Pause_Background.webp"
const LOGO_PATH := ART_DIR + "Pause_Title_Logo.png"
const SELECTION_SOUND_PATH := "res://assets/Audio/UI/Menu Selection.mp3"
const CONFIRM_SOUND_PATH := "res://assets/Audio/UI/Settings Confirmation Credits.mp3"

# Same green selection language as the pause rail (see NavPlate).
const LIT := NavPlate.GREEN
const LIT_SOFT := NavPlate.GREEN_SOFT
const TEXT_LIGHT := NavPlate.TEXT_LIGHT
const WHITE := Color(0.93, 0.93, 0.92, 1.0)
const DIM := Color(0.63, 0.65, 0.67, 1.0)
const DIMMER := Color(0.45, 0.47, 0.49, 1.0)
const GREEN := Color(0.25, 0.80, 0.22, 1.0)
const GREEN_DEEP := Color(0.07, 0.20, 0.06, 0.96)
const STEEL := Color(0.075, 0.08, 0.085, 0.94)
const STEEL_EDGE := Color(0.30, 0.31, 0.33, 1.0)

const RAIL_LEFT := 36.0
const RAIL_WIDTH := 300.0
const CENTER_LEFT := 372.0
const RIGHT_WIDTH := 372.0
const EDGE := 30.0

const CATEGORIES := [
	["gameplay", "GAMEPLAY"],
	["controls", "CONTROLS"],
	["graphics", "GRAPHICS"],
	["audio", "AUDIO"],
]

var context := "pause"
var design_width := MIN_DESIGN_WIDTH
var font: SystemFont = null
var canvas: Control = null
var background: TextureRect = null
var rail_buttons: Array[Button] = []
var category_buttons: Dictionary = {}
var pages: Dictionary = {}
var current_category := "controls"
var current_tab := "touch"
var selected_id := ""
var last_viewport_size := Vector2.ZERO
var _selection_audio: AudioStreamPlayer = null
var _confirm_audio: AudioStreamPlayer = null

# Controls page
var controls_header: Control = null
var tab_buttons: Dictionary = {}
var reset_button: Button = null
var preview_frame: MetalPanel = null
var preview: LivePreview = null
var widget_layer: Control = null
var proxies: Dictionary = {}
var chip_bar: MetalPanel = null
var chips: Dictionary = {}
var right_panel: Control = null
var alt_tab_panel: MetalPanel = null
var alt_tab_title: Label = null
var alt_tab_body: VBoxContainer = null
var mode_joystick: Button = null
var mode_touch_aim: Button = null
var mode_description: Label = null
var floating_toggle: PillToggle = null
var floating_row: Control = null
var editing_label: Label = null
var editing_all_button: Button = null
var size_slider: HSlider = null
var size_value: Label = null
var opacity_slider: HSlider = null
var opacity_value: Label = null
var labels_toggle: PillToggle = null
var invert_toggle: PillToggle = null
var aim_assist_toggle: PillToggle = null
var gyro_toggle: PillToggle = null
var _syncing := false

# Drag state (shared by preview widgets and chips)
var _drag_id := ""
var _drag_from_chip := false
var _drag_moved := false
var _drag_start := Vector2.ZERO
var _drag_offset := Vector2.ZERO
var _drag_ghost: HudRoundButton = null

# Other pages
var value_rows: Dictionary = {}


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func _process(_delta: float) -> void:
	if not visible:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size != last_viewport_size:
		_relayout()


# ------------------------------------------------------------------ public API

func open(from_context: String = "pause", category: String = "controls") -> void:
	context = from_context
	visible = true
	_relayout()
	_show_category(category, false)
	refresh_from_settings()
	_play(_confirm_audio)


func close(play_sound: bool = true) -> void:
	if not visible:
		return
	_end_drag(false)
	if preview != null:
		preview.stop()
	ControlSettingsManager.save_settings()
	visible = false
	if play_sound:
		_play(_confirm_audio)
	closed.emit()


func refresh_from_settings() -> void:
	_syncing = true
	var mode := ControlSettingsManager.movement_mode
	_set_radio(mode_joystick, mode != ControlSettingsManager.MODE_TOUCH_ZONE)
	_set_radio(mode_touch_aim, mode == ControlSettingsManager.MODE_TOUCH_ZONE)
	floating_toggle.set_on(mode == ControlSettingsManager.MODE_FLOATING)
	floating_row.visible = mode != ControlSettingsManager.MODE_TOUCH_ZONE
	mode_description.text = (
		"Tap anywhere on the left to move. Drag the right side of the screen to look and aim."
		if mode == ControlSettingsManager.MODE_TOUCH_ZONE
		else "Use a virtual joystick to move and drag the right side to look."
	)
	labels_toggle.set_on(ControlSettingsManager.show_button_labels)
	invert_toggle.set_on(ControlSettingsManager.invert_y)
	aim_assist_toggle.set_on(ControlSettingsManager.aim_assist)
	gyro_toggle.set_on(ControlSettingsManager.gyroscope_enabled)
	_refresh_selection_sliders()
	for page_id in value_rows.keys():
		var row: Dictionary = value_rows[page_id]
		if row.has("refresh"):
			(row["refresh"] as Callable).call()
	_syncing = false
	_refresh_chips()
	_layout_proxies()


# ------------------------------------------------------------------ build

func _build() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(
		["DIN Condensed", "Avenir Next Condensed", "Arial Narrow", "Bank Gothic", "Helvetica Neue"]
	)
	font.font_weight = 750
	font.font_stretch = 84

	var letterbox := ColorRect.new()
	letterbox.color = Color(0.0, 0.0, 0.0, 1.0)
	letterbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	letterbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(letterbox)

	canvas = Control.new()
	canvas.name = "SettingsCanvas"
	canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(canvas)

	background = TextureRect.new()
	background.texture = _load_texture(BACKGROUND_PATH)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)
	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.color = Color(0.0, 0.0, 0.0, 0.48)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_build_rail()
	_build_controls_page()
	_build_gameplay_page()
	_build_graphics_page()
	_build_audio_page()
	# The rail is built first but must stay on top: pages, the live preview and
	# its widget layer can never sit over (and swallow clicks meant for) BACK.
	for button in rail_buttons:
		canvas.move_child(button.get_parent(), -1)

	_selection_audio = _make_audio(SELECTION_SOUND_PATH, -9.0)
	_confirm_audio = _make_audio(CONFIRM_SOUND_PATH, -2.0)


func _build_rail() -> void:
	var logo := TextureRect.new()
	logo.name = "Logo"
	logo.texture = _load_texture(LOGO_PATH)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = Vector2(RAIL_LEFT + 6.0, 34.0)
	logo.size = Vector2(RAIL_WIDTH - 12.0, 150.0)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(logo)
	var y := 226.0
	for entry in CATEGORIES:
		var button := _make_rail_button(entry[1], entry[0], Vector2(RAIL_LEFT, y))
		button.pressed.connect(_show_category.bind(entry[0], true))
		category_buttons[entry[0]] = button
		y += 88.0
	var back := _make_rail_button("BACK", "back", Vector2(RAIL_LEFT, y))
	# Close on the press itself, so one click always leaves settings even if
	# the release lands a few pixels away.
	back.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	back.pressed.connect(close)


func _make_rail_button(text_value: String, icon_id: String, pos: Vector2) -> Button:
	# Same riveted plate + in-place green highlight as the pause rail.
	var holder := Control.new()
	holder.position = pos
	holder.size = Vector2(RAIL_WIDTH, 76.0)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(holder)
	var plate := NavPlate.new()
	plate.fit(holder.size)
	holder.add_child(plate)
	var icon := TextureRect.new()
	icon.texture = HudArt.icon(icon_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(30.0, 17.0)
	icon.size = Vector2(42.0, 42.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = TEXT_LIGHT
	holder.add_child(icon)
	var button := Button.new()
	button.text = text_value
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_theme_constant_override("h_separation", 0)
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 27)
	button.add_theme_color_override("font_color", TEXT_LIGHT)
	button.add_theme_color_override("font_hover_color", LIT)
	button.add_theme_color_override("font_pressed_color", LIT)
	button.add_theme_color_override("font_hover_pressed_color", LIT)
	button.add_theme_color_override("font_focus_color", TEXT_LIGHT)
	var pad := StyleBoxEmpty.new()
	pad.content_margin_left = 96.0
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		button.add_theme_stylebox_override(state, pad)
	holder.add_child(button)
	button.set_meta("plate", plate)
	button.set_meta("icon", icon)
	button.mouse_entered.connect(_on_rail_hover.bind(button, true))
	button.mouse_exited.connect(_on_rail_hover.bind(button, false))
	button.button_down.connect(_play.bind(_selection_audio))
	rail_buttons.append(button)
	return button


var _hovered_rail: Button = null


func _on_rail_hover(button: Button, entered: bool) -> void:
	if entered:
		_hovered_rail = button
	elif _hovered_rail == button:
		_hovered_rail = null
	_refresh_rail()


## Lit = the open category, plus whichever rail button the pointer is over.
func _refresh_rail() -> void:
	for button in rail_buttons:
		var lit: bool = button == _hovered_rail or category_buttons.get(current_category) == button
		(button.get_meta("plate") as NavPlate).lit = lit
		(button.get_meta("icon") as TextureRect).modulate = LIT_SOFT if lit else TEXT_LIGHT
		button.add_theme_color_override("font_color", LIT if lit else TEXT_LIGHT)
		button.add_theme_color_override("font_focus_color", LIT if lit else TEXT_LIGHT)


func _build_controls_page() -> void:
	var page := Control.new()
	page.name = "ControlsPage"
	page.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas.add_child(page)
	pages["controls"] = page

	controls_header = MetalPanel.new()
	controls_header.name = "Header"
	page.add_child(controls_header)
	var title := _label(controls_header, "CONTROLS", 58, WHITE)
	title.position = Vector2(34.0, 20.0)
	title.size = Vector2(520.0, 64.0)
	var subtitle := _label(controls_header, "CUSTOMIZE YOUR LAYOUT", 26, DIM)
	subtitle.position = Vector2(36.0, 80.0)
	subtitle.size = Vector2(520.0, 32.0)
	subtitle.name = "Subtitle"

	for tab in [["touch", "TOUCH CONTROLS"], ["gamepad", "GAMEPAD"], ["keyboard", "KEYBOARD & MOUSE"]]:
		var tab_button := _plain_button(tab[1], 22)
		# Tabs sit on the same riveted plate as the rail; selection lights it.
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			tab_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		tab_button.set_meta("plate", NavPlate.attach_behind(tab_button))
		tab_button.pressed.connect(_show_tab.bind(tab[0]))
		controls_header.add_child(tab_button)
		tab_buttons[tab[0]] = tab_button

	reset_button = _plain_button("RESET TO DEFAULT", 24)
	reset_button.icon = HudArt.icon("reset")
	reset_button.expand_icon = true
	reset_button.add_theme_constant_override("icon_max_width", 34)
	reset_button.add_theme_constant_override("h_separation", 18)
	reset_button.pressed.connect(_on_reset_pressed)
	page.add_child(reset_button)

	preview_frame = MetalPanel.new()
	preview_frame.name = "PreviewFrame"
	page.add_child(preview_frame)
	preview = LivePreview.new()
	preview.name = "LivePreview"
	preview_frame.add_child(preview)
	widget_layer = Control.new()
	widget_layer.name = "WidgetLayer"
	widget_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	widget_layer.gui_input.connect(_on_widget_layer_input)
	preview_frame.add_child(widget_layer)
	var crosshair := _label(widget_layer, "+", 30, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_CENTER)
	crosshair.name = "Crosshair"
	for control_id in ControlSettingsManager.CONTROL_IDS:
		var proxy := HudRoundButton.new()
		proxy.name = "Proxy_%s" % control_id
		proxy.art = HudArt.control_texture(control_id)
		if control_id == "joystick":
			proxy.knob = HudArt.control_texture("joystick_knob")
		proxy.icon = HudArt.icon(control_id)
		proxy.caption = String(ControlSettingsManager.CONTROL_LABELS[control_id])
		proxy.caption_font = font
		widget_layer.add_child(proxy)
		if ControlSettingsManager.is_locked(control_id):
			# Shown for reference at its fixed spot; not selectable or draggable.
			proxy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			proxy.mouse_filter = Control.MOUSE_FILTER_STOP
			proxy.gui_input.connect(_on_proxy_input.bind(control_id))
		var frame := SelectionFrame.new()
		frame.name = "SelectionFrame"
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.move_icon = HudArt.icon("move")
		proxy.add_child(frame)
		proxies[control_id] = proxy

	chip_bar = MetalPanel.new()
	chip_bar.name = "ButtonsBar"
	page.add_child(chip_bar)
	var buttons_title := _label(chip_bar, "BUTTONS", 30, WHITE)
	buttons_title.position = Vector2(26.0, 10.0)
	buttons_title.size = Vector2(140.0, 40.0)
	var hint := _label(chip_bar, "Drag to rearrange. Tap to toggle on/off.", 20, DIM)
	hint.position = Vector2(176.0, 14.0)
	hint.size = Vector2(520.0, 34.0)
	for control_id in ControlSettingsManager.editable_control_ids():
		var chip := ControlChip.new()
		chip.name = "Chip_%s" % control_id
		chip.control_id = control_id
		chip.caption = String(ControlSettingsManager.CONTROL_LABELS[control_id])
		chip.icon = HudArt.control_texture(control_id) if control_id == "joystick" else HudArt.icon(control_id)
		chip.caption_font = font
		chip.gui_input.connect(_on_chip_input.bind(control_id))
		chip_bar.add_child(chip)
		chips[control_id] = chip

	right_panel = Control.new()
	right_panel.name = "RightPanel"
	page.add_child(right_panel)
	_build_right_panel()

	alt_tab_panel = MetalPanel.new()
	alt_tab_panel.name = "AltTabPanel"
	alt_tab_panel.visible = false
	page.add_child(alt_tab_panel)
	alt_tab_title = _label(alt_tab_panel, "", 32, WHITE)
	alt_tab_title.position = Vector2(34.0, 22.0)
	alt_tab_title.size = Vector2(700.0, 44.0)
	alt_tab_body = VBoxContainer.new()
	alt_tab_body.position = Vector2(34.0, 84.0)
	alt_tab_body.add_theme_constant_override("separation", 6)
	alt_tab_panel.add_child(alt_tab_body)


func _build_right_panel() -> void:
	# Section 1: control mode
	var mode_panel := MetalPanel.new()
	mode_panel.name = "ModePanel"
	mode_panel.position = Vector2.ZERO
	mode_panel.size = Vector2(RIGHT_WIDTH, 214.0)
	right_panel.add_child(mode_panel)
	_section_title(mode_panel, "CONTROL MODE", Vector2(22.0, 14.0))
	mode_joystick = _radio_button("JOYSTICK", "joystick")
	mode_joystick.position = Vector2(20.0, 58.0)
	mode_joystick.custom_minimum_size = Vector2(160.0, 56.0)
	mode_joystick.size = Vector2(160.0, 56.0)
	mode_joystick.pressed.connect(_on_mode_pressed.bind(false))
	mode_panel.add_child(mode_joystick)
	mode_touch_aim = _radio_button("TOUCH AIM", "aim")
	mode_touch_aim.position = Vector2(192.0, 58.0)
	mode_touch_aim.custom_minimum_size = Vector2(160.0, 56.0)
	mode_touch_aim.size = Vector2(160.0, 56.0)
	mode_touch_aim.pressed.connect(_on_mode_pressed.bind(true))
	mode_panel.add_child(mode_touch_aim)
	mode_description = _wrap_label(mode_panel, "", 16, DIM, Vector2(22.0, 120.0), Vector2(RIGHT_WIDTH - 44.0, 44.0))
	floating_row = Control.new()
	floating_row.position = Vector2(22.0, 172.0)
	floating_row.size = Vector2(RIGHT_WIDTH - 44.0, 30.0)
	mode_panel.add_child(floating_row)
	var floating_label := _label(floating_row, "FLOATING STICK", 18, WHITE)
	floating_label.size = Vector2(200.0, 30.0)
	floating_toggle = _pill(floating_row, Vector2(RIGHT_WIDTH - 44.0 - 84.0, 0.0), Vector2(84.0, 30.0))
	floating_toggle.toggled.connect(_on_floating_toggled)

	# Section 2: customize layout
	var layout_panel := MetalPanel.new()
	layout_panel.name = "LayoutPanel"
	layout_panel.position = Vector2(0.0, 226.0)
	layout_panel.size = Vector2(RIGHT_WIDTH, 330.0)
	right_panel.add_child(layout_panel)
	_section_title(layout_panel, "CUSTOMIZE LAYOUT", Vector2(22.0, 14.0))
	_wrap_label(layout_panel, "Drag and move buttons to your preferred position on the screen.", 16, DIM, Vector2(22.0, 54.0), Vector2(RIGHT_WIDTH - 44.0, 44.0))
	editing_label = _label(layout_panel, "EDITING: ALL BUTTONS", 16, LIT)
	editing_label.position = Vector2(22.0, 100.0)
	editing_label.size = Vector2(220.0, 26.0)
	editing_all_button = _plain_button("ALL", 15)
	editing_all_button.position = Vector2(RIGHT_WIDTH - 22.0 - 64.0, 98.0)
	editing_all_button.size = Vector2(64.0, 28.0)
	editing_all_button.pressed.connect(_select.bind(""))
	layout_panel.add_child(editing_all_button)
	var size_row := _slider_row(layout_panel, "BUTTON SIZE", Vector2(22.0, 130.0))
	size_slider = size_row[0]
	size_value = size_row[1]
	size_slider.value_changed.connect(_on_size_changed)
	var opacity_row := _slider_row(layout_panel, "BUTTON OPACITY", Vector2(22.0, 196.0))
	opacity_slider = opacity_row[0]
	opacity_value = opacity_row[1]
	opacity_slider.value_changed.connect(_on_opacity_changed)
	var labels_title := _label(layout_panel, "SHOW BUTTON LABELS", 19, WHITE)
	labels_title.position = Vector2(22.0, 262.0)
	labels_title.size = Vector2(RIGHT_WIDTH - 44.0 - 96.0, 28.0)
	labels_title.clip_text = true
	var labels_copy := _label(layout_panel, "Show/hide button icons and labels.", 14, DIMMER)
	labels_copy.position = Vector2(22.0, 290.0)
	labels_copy.size = Vector2(RIGHT_WIDTH - 44.0 - 96.0, 22.0)
	labels_copy.clip_text = true
	labels_toggle = _pill(layout_panel, Vector2(RIGHT_WIDTH - 22.0 - 84.0, 266.0), Vector2(84.0, 36.0))
	labels_toggle.toggled.connect(_on_labels_toggled)

	# Section 3: advanced
	var advanced := MetalPanel.new()
	advanced.name = "AdvancedPanel"
	advanced.position = Vector2(0.0, 568.0)
	advanced.size = Vector2(RIGHT_WIDTH, 200.0)
	right_panel.add_child(advanced)
	_section_title(advanced, "ADVANCED", Vector2(22.0, 14.0))
	invert_toggle = _toggle_row(advanced, "INVERT Y AXIS (LOOK)", 56.0)
	invert_toggle.toggled.connect(_on_invert_toggled)
	aim_assist_toggle = _toggle_row(advanced, "AIM ASSIST", 102.0)
	aim_assist_toggle.toggled.connect(_on_aim_assist_toggled)
	gyro_toggle = _toggle_row(advanced, "GYROSCOPE (TILT TO LOOK)", 148.0)
	gyro_toggle.toggled.connect(_on_gyro_toggled)


func _build_gameplay_page() -> void:
	var page := _make_list_page("gameplay", "GAMEPLAY", "LOOK, FEEL AND FEEDBACK")
	var list: VBoxContainer = page.get_meta("list")
	_add_slider_setting(list, "gameplay_look_h", "LOOK SENSITIVITY",
		func() -> float: return inverse_lerp(0.0010, 0.0100, ControlSettingsManager.look_sensitivity_h),
		func(v: float) -> void:
			var value := lerpf(0.0010, 0.0100, v)
			ControlSettingsManager.set_look_sensitivity(value, ControlSettingsManager.look_sensitivity_v)
			sensitivity_changed.emit(value))
	_add_slider_setting(list, "gameplay_look_v", "VERTICAL SENSITIVITY",
		func() -> float: return inverse_lerp(0.0010, 0.0100, ControlSettingsManager.look_sensitivity_v),
		func(v: float) -> void:
			ControlSettingsManager.set_look_sensitivity(ControlSettingsManager.look_sensitivity_h, lerpf(0.0010, 0.0100, v)))
	_add_slider_setting(list, "gameplay_smoothing", "CAMERA SMOOTHING",
		func() -> float: return ControlSettingsManager.look_smoothing / 0.85,
		func(v: float) -> void: ControlSettingsManager.set_look_smoothing(v * 0.85))
	_add_slider_setting(list, "gameplay_deadzone", "JOYSTICK DEAD ZONE",
		func() -> float: return inverse_lerp(0.04, 0.45, ControlSettingsManager.joystick_deadzone),
		func(v: float) -> void: ControlSettingsManager.set_joystick_deadzone(lerpf(0.04, 0.45, v)))
	_add_slider_setting(list, "gameplay_gyro", "GYROSCOPE SENSITIVITY",
		func() -> float: return inverse_lerp(0.25, 2.5, ControlSettingsManager.gyroscope_sensitivity),
		func(v: float) -> void: ControlSettingsManager.set_gyroscope_sensitivity(lerpf(0.25, 2.5, v)))
	_add_toggle_setting(list, "gameplay_haptics", "HAPTIC FEEDBACK",
		func() -> bool: return ControlSettingsManager.haptics_enabled,
		func(on: bool) -> void:
			ControlSettingsManager.set_haptics_enabled(on)
			haptics_changed.emit(on))


func _build_graphics_page() -> void:
	var page := _make_list_page("graphics", "GRAPHICS", "DEVICE QUALITY AND PERFORMANCE")
	var list: VBoxContainer = page.get_meta("list")
	_add_slider_setting(list, "graphics_scale", "RENDER RESOLUTION",
		func() -> float: return inverse_lerp(0.5, 1.0, ControlSettingsManager.render_scale),
		func(v: float) -> void: ControlSettingsManager.set_render_scale(lerpf(0.5, 1.0, v)),
		func(v: float) -> String: return "%d%%" % int(round(lerpf(50.0, 100.0, v))))
	_add_choice_setting(list, "graphics_fps", "FRAME RATE LIMIT", [["30 FPS", 30], ["60 FPS", 60], ["UNCAPPED", 0]],
		func() -> int: return ControlSettingsManager.fps_cap,
		func(value: int) -> void: ControlSettingsManager.set_fps_cap(value))
	_add_info_setting(list, "RENDERER", func() -> String:
		return String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "mobile")).to_upper())
	_add_info_setting(list, "DISPLAY", func() -> String:
		var size_now := get_viewport().get_visible_rect().size
		return "%d x %d" % [int(size_now.x), int(size_now.y)])


func _build_audio_page() -> void:
	var page := _make_list_page("audio", "AUDIO", "MIX AND MUSIC")
	var list: VBoxContainer = page.get_meta("list")
	_add_slider_setting(list, "audio_master", "MASTER VOLUME",
		func() -> float: return ControlSettingsManager.master_volume / 100.0,
		func(v: float) -> void: ControlSettingsManager.set_master_volume(v * 100.0))
	_add_slider_setting(list, "audio_music", "GAMEPLAY MUSIC",
		func() -> float: return MusicManager.get_user_volume() / 100.0,
		func(v: float) -> void: MusicManager.set_user_volume(v * 100.0))
	_add_slider_setting(list, "audio_menu_music", "MENU MUSIC",
		func() -> float: return float(SaveManager.get_value("audio", "menu_music", 100.0)) / 100.0,
		func(v: float) -> void:
			SaveManager.set_value("audio", "menu_music", round(v * 100.0))
			menu_audio_changed.emit())
	_add_slider_setting(list, "audio_menu_ambience", "MENU AMBIENCE",
		func() -> float: return float(SaveManager.get_value("audio", "menu_ambience", 100.0)) / 100.0,
		func(v: float) -> void:
			SaveManager.set_value("audio", "menu_ambience", round(v * 100.0))
			menu_audio_changed.emit())


# ------------------------------------------------------------------ layout

func _relayout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	last_viewport_size = viewport_size
	var scale_factor := viewport_size.y / DESIGN_HEIGHT
	design_width = viewport_size.x / scale_factor
	if design_width < MIN_DESIGN_WIDTH:
		# Narrow (4:3) screens letterbox vertically instead of cramping the page.
		design_width = MIN_DESIGN_WIDTH
		scale_factor = viewport_size.x / MIN_DESIGN_WIDTH
	canvas.scale = Vector2.ONE * scale_factor
	canvas.size = Vector2(design_width, DESIGN_HEIGHT)
	canvas.position = (viewport_size - canvas.size * scale_factor) * 0.5
	background.position = Vector2.ZERO
	background.size = canvas.size

	var right_left := design_width - EDGE - RIGHT_WIDTH
	var center_right := right_left - 18.0
	var center_width := center_right - CENTER_LEFT

	controls_header.position = Vector2(CENTER_LEFT, 26.0)
	controls_header.size = Vector2(center_width, 196.0)
	var tab_width := (center_width - 40.0 - 2.0 * 12.0) / 3.0
	var tab_x := 20.0
	for tab_id in ["touch", "gamepad", "keyboard"]:
		var tab_button: Button = tab_buttons[tab_id]
		tab_button.position = Vector2(tab_x, 128.0)
		tab_button.size = Vector2(tab_width, 52.0)
		tab_x += tab_width + 12.0
	reset_button.position = Vector2(right_left, 34.0)
	reset_button.size = Vector2(RIGHT_WIDTH, 66.0)
	right_panel.position = Vector2(right_left, 118.0)
	right_panel.size = Vector2(RIGHT_WIDTH, 760.0)

	var chip_top := DESIGN_HEIGHT - 26.0 - 184.0
	chip_bar.position = Vector2(CENTER_LEFT, chip_top)
	chip_bar.size = Vector2(center_width, 184.0)
	var chip_ids := ControlSettingsManager.editable_control_ids()
	var chip_count := chip_ids.size()
	var chip_gap := 8.0
	var chip_width := minf(108.0, (center_width - 40.0 - chip_gap * (chip_count - 1)) / chip_count)
	var chips_total := chip_width * chip_count + chip_gap * (chip_count - 1)
	var chip_x := (center_width - chips_total) * 0.5
	for control_id in chip_ids:
		var chip: ControlChip = chips[control_id]
		chip.position = Vector2(chip_x, 60.0)
		chip.size = Vector2(chip_width, 108.0)
		chip_x += chip_width + chip_gap

	# Preview keeps the device aspect so widget positions map 1:1.
	var area := Rect2(CENTER_LEFT, 236.0, center_width, chip_top - 12.0 - 236.0)
	preview_frame.position = area.position
	preview_frame.size = area.size
	var inner := Rect2(Vector2(12.0, 12.0), area.size - Vector2(24.0, 24.0))
	var aspect := viewport_size.x / viewport_size.y
	var view_size := inner.size
	if view_size.x / view_size.y > aspect:
		view_size.x = view_size.y * aspect
	else:
		view_size.y = view_size.x / aspect
	var view_pos := inner.position + (inner.size - view_size) * 0.5
	preview.position = view_pos
	preview.size = view_size
	widget_layer.position = view_pos
	widget_layer.size = view_size
	var crosshair := widget_layer.get_node("Crosshair") as Label
	crosshair.size = Vector2(40.0, 40.0)
	crosshair.position = view_size * 0.5 - crosshair.size * 0.5

	alt_tab_panel.position = Vector2(CENTER_LEFT, 236.0)
	alt_tab_panel.size = Vector2(design_width - EDGE - CENTER_LEFT, DESIGN_HEIGHT - 26.0 - 236.0)
	alt_tab_body.size = Vector2(alt_tab_panel.size.x - 68.0, alt_tab_panel.size.y - 110.0)

	for page_id in ["gameplay", "graphics", "audio"]:
		var list_page: Control = pages[page_id]
		list_page.position = Vector2(CENTER_LEFT, 26.0)
		list_page.size = Vector2(design_width - EDGE - CENTER_LEFT, DESIGN_HEIGHT - 52.0)
		var header := list_page.get_node("Header") as MetalPanel
		header.size = Vector2(list_page.size.x, 132.0)
		var body := list_page.get_node("Body") as MetalPanel
		body.position = Vector2(0.0, 148.0)
		body.size = Vector2(list_page.size.x, list_page.size.y - 148.0)
		var list: VBoxContainer = list_page.get_meta("list")
		list.position = Vector2(40.0, 30.0)
		list.size = Vector2(minf(body.size.x - 80.0, 980.0), body.size.y - 60.0)
	_layout_proxies()


func _layout_proxies() -> void:
	if widget_layer == null or preview == null:
		return
	var game_size := get_viewport().get_visible_rect().size
	if game_size.x <= 0.0 or widget_layer.size.x <= 0.0:
		return
	var k := widget_layer.size.x / game_size.x
	var touch_aim := ControlSettingsManager.movement_mode == ControlSettingsManager.MODE_TOUCH_ZONE
	for control_id in proxies.keys():
		var proxy: HudRoundButton = proxies[control_id]
		var rect := ControlSettingsManager.pixel_rect(control_id, game_size)
		if not (_drag_id == control_id and not _drag_from_chip):
			proxy.position = rect.position * k
		proxy.size = rect.size * k
		var shown := ControlSettingsManager.control_visible(control_id)
		proxy.visible = shown
		proxy.modulate.a = ControlSettingsManager.control_opacity(control_id) * (0.55 if control_id == "joystick" and touch_aim else 1.0)
		proxy.show_caption = ControlSettingsManager.show_button_labels and control_id != "pause"
		var frame := proxy.get_node("SelectionFrame") as SelectionFrame
		frame.size = proxy.size
		frame.selected = selected_id == control_id
		frame.visible = not ControlSettingsManager.is_locked(control_id)


func _refresh_chips() -> void:
	for control_id in chips.keys():
		var chip: ControlChip = chips[control_id]
		chip.enabled = ControlSettingsManager.control_visible(control_id)
		chip.selected = selected_id == control_id


# ------------------------------------------------------------------ navigation

func _show_category(category: String, play_sound: bool = true) -> void:
	current_category = category
	for page_id in pages.keys():
		(pages[page_id] as Control).visible = page_id == category
	_refresh_rail()
	if category == "controls":
		_show_tab(current_tab, false)
	elif preview != null:
		preview.stop()
	if play_sound:
		_play(_confirm_audio)


func _show_tab(tab_id: String, play_sound: bool = true) -> void:
	current_tab = tab_id
	for key in tab_buttons.keys():
		_style_tab(tab_buttons[key], key == tab_id)
	var touch := tab_id == "touch"
	preview_frame.visible = touch
	chip_bar.visible = touch
	right_panel.visible = touch
	reset_button.visible = touch
	alt_tab_panel.visible = not touch
	if touch:
		preview.start(LivePreview.MODE_HUB if context == "menu" else LivePreview.MODE_MIRROR)
		_layout_proxies()
	else:
		preview.stop()
		_fill_alt_tab(tab_id)
	if play_sound:
		_play(_selection_audio)


func _fill_alt_tab(tab_id: String) -> void:
	for child in alt_tab_body.get_children():
		child.queue_free()
	if tab_id == "keyboard":
		alt_tab_title.text = "KEYBOARD & MOUSE BINDINGS"
		for binding in [
			["MOVE", "W  A  S  D"], ["LOOK", "MOUSE"], ["SHOOT", "LEFT MOUSE"], ["AIM", "RIGHT MOUSE (HOLD)"],
			["SPRINT", "SHIFT"], ["JUMP", "SPACE"], ["CROUCH", "C"], ["RELOAD", "R"],
			["SWAP WEAPON", "TAB  /  2"], ["INTERACT", "E"], ["PAUSE", "ESC"],
		]:
			alt_tab_body.add_child(_binding_row(binding[0], binding[1]))
	else:
		alt_tab_title.text = "GAMEPAD"
		var note := _label(null, "Controller input is not supported in this build yet. Touch and keyboard & mouse layouts are fully customizable.", 22, DIM)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(600.0, 90.0)
		alt_tab_body.add_child(note)
		var state := _label(null, "NO CONTROLLER DETECTED" if Input.get_connected_joypads().is_empty() else "CONTROLLER CONNECTED — NOT YET MAPPED", 22, LIT)
		state.custom_minimum_size = Vector2(600.0, 40.0)
		alt_tab_body.add_child(state)


# ------------------------------------------------------------------ selection + sliders

func _select(control_id: String) -> void:
	selected_id = control_id
	_refresh_selection_sliders()
	_refresh_chips()
	_layout_proxies()


func _refresh_selection_sliders() -> void:
	var was_syncing := _syncing
	_syncing = true
	if selected_id == "":
		editing_label.text = "EDITING: ALL BUTTONS"
		editing_all_button.visible = false
		size_slider.min_value = 60.0
		size_slider.max_value = 150.0
		size_slider.value = ControlSettingsManager.global_button_scale * 100.0
		opacity_slider.min_value = 20.0
		opacity_slider.max_value = 100.0
		opacity_slider.value = ControlSettingsManager.global_button_opacity * 100.0
	else:
		var data := ControlSettingsManager.get_control(selected_id)
		editing_label.text = "EDITING: %s" % String(ControlSettingsManager.CONTROL_LABELS[selected_id])
		editing_all_button.visible = true
		size_slider.min_value = 55.0
		size_slider.max_value = 185.0
		size_slider.value = float(data.get("scale", 1.0)) * 100.0
		opacity_slider.min_value = 15.0
		opacity_slider.max_value = 100.0
		opacity_slider.value = float(data.get("opacity", 1.0)) * 100.0
	size_value.text = "%d%%" % int(round(size_slider.value))
	opacity_value.text = "%d%%" % int(round(opacity_slider.value))
	_syncing = was_syncing


func _on_size_changed(value: float) -> void:
	size_value.text = "%d%%" % int(round(value))
	if _syncing:
		return
	if selected_id == "":
		ControlSettingsManager.set_global_button_scale(value / 100.0)
	else:
		ControlSettingsManager.update_control(selected_id, "scale", value / 100.0)
	ControlSettingsManager.save_settings()
	_layout_proxies()


func _on_opacity_changed(value: float) -> void:
	opacity_value.text = "%d%%" % int(round(value))
	if _syncing:
		return
	if selected_id == "":
		ControlSettingsManager.set_global_button_opacity(value / 100.0)
	else:
		ControlSettingsManager.update_control(selected_id, "opacity", value / 100.0)
	ControlSettingsManager.save_settings()
	_layout_proxies()


func _on_mode_pressed(touch_aim: bool) -> void:
	if touch_aim:
		ControlSettingsManager.set_movement_mode(ControlSettingsManager.MODE_TOUCH_ZONE)
	else:
		ControlSettingsManager.set_movement_mode(
			ControlSettingsManager.MODE_FLOATING if floating_toggle.on else ControlSettingsManager.MODE_FIXED
		)
	ControlSettingsManager.save_settings()
	_play(_selection_audio)
	refresh_from_settings()


func _on_floating_toggled(on: bool) -> void:
	if _syncing:
		return
	ControlSettingsManager.set_movement_mode(ControlSettingsManager.MODE_FLOATING if on else ControlSettingsManager.MODE_FIXED)
	ControlSettingsManager.save_settings()
	refresh_from_settings()


func _on_labels_toggled(on: bool) -> void:
	if _syncing:
		return
	ControlSettingsManager.set_show_button_labels(on)
	ControlSettingsManager.save_settings()
	_layout_proxies()


func _on_invert_toggled(on: bool) -> void:
	if _syncing:
		return
	ControlSettingsManager.set_invert_y(on)
	ControlSettingsManager.save_settings()


func _on_aim_assist_toggled(on: bool) -> void:
	if _syncing:
		return
	ControlSettingsManager.set_aim_assist(on)
	ControlSettingsManager.save_settings()


func _on_gyro_toggled(on: bool) -> void:
	if _syncing:
		return
	ControlSettingsManager.set_gyroscope_enabled(on)
	ControlSettingsManager.save_settings()


func _on_reset_pressed() -> void:
	ControlSettingsManager.reset_controls_to_default()
	selected_id = ""
	_play(_confirm_audio)
	refresh_from_settings()


# ------------------------------------------------------------------ dragging

func _on_proxy_input(event: InputEvent, control_id: String) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var button := event as InputEventMouseButton
		if button.pressed:
			_begin_drag(control_id, false, _canvas_point(button.global_position))
			_select(control_id)
		else:
			_end_drag(true)
		accept_event()
	elif event is InputEventMouseMotion and _drag_id == control_id:
		_update_drag(_canvas_point((event as InputEventMouseMotion).global_position))
		accept_event()


func _on_chip_input(event: InputEvent, control_id: String) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var button := event as InputEventMouseButton
		if button.pressed:
			_begin_drag(control_id, true, _canvas_point(button.global_position))
		else:
			if _drag_id == control_id and not _drag_moved:
				_toggle_visibility(control_id)
				_end_drag(false)
			else:
				_end_drag(true)
		accept_event()
	elif event is InputEventMouseMotion and _drag_id == control_id:
		_update_drag(_canvas_point((event as InputEventMouseMotion).global_position))
		accept_event()


func _on_widget_layer_input(event: InputEvent) -> void:
	# Tapping empty preview space returns the sliders to "all buttons".
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_select("")


func _begin_drag(control_id: String, from_chip: bool, canvas_point: Vector2) -> void:
	_drag_id = control_id
	_drag_from_chip = from_chip
	_drag_moved = false
	_drag_start = canvas_point
	var proxy: HudRoundButton = proxies[control_id]
	_drag_offset = _layer_point(canvas_point) - proxy.position
	if from_chip:
		_drag_offset = proxy.size * 0.5


func _update_drag(canvas_point: Vector2) -> void:
	if _drag_id == "":
		return
	if not _drag_moved and canvas_point.distance_to(_drag_start) < 12.0:
		return
	_drag_moved = true
	var proxy: HudRoundButton = proxies[_drag_id]
	if _drag_from_chip:
		if _drag_ghost == null:
			_drag_ghost = HudRoundButton.new()
			_drag_ghost.art = proxy.art
			_drag_ghost.knob = proxy.knob
			_drag_ghost.icon = proxy.icon
			_drag_ghost.modulate.a = 0.85
			canvas.add_child(_drag_ghost)
		var layer_scale := 1.0
		_drag_ghost.size = proxy.size * layer_scale
		_drag_ghost.position = canvas_point - _drag_ghost.size * 0.5
		return
	var target := _layer_point(canvas_point) - _drag_offset
	proxy.position = target
	_write_proxy_rect(_drag_id, Rect2(target, proxy.size), false)
	# Snap the stand-in to the clamped (safe-area) position the HUD will use.
	var game_size := get_viewport().get_visible_rect().size
	var k := widget_layer.size.x / game_size.x
	proxy.position = ControlSettingsManager.pixel_position(_drag_id, game_size) * k


func _end_drag(commit: bool) -> void:
	if _drag_id == "":
		return
	var control_id := _drag_id
	if commit and _drag_moved:
		if _drag_from_chip and _drag_ghost != null:
			var drop_center := _layer_point(_drag_ghost.position + _drag_ghost.size * 0.5)
			if Rect2(Vector2.ZERO, widget_layer.size).has_point(drop_center):
				var proxy: HudRoundButton = proxies[control_id]
				ControlSettingsManager.update_control(control_id, "visible", true, false)
				_write_proxy_rect(control_id, Rect2(drop_center - proxy.size * 0.5, proxy.size), true)
				_select(control_id)
		else:
			var proxy: HudRoundButton = proxies[control_id]
			_write_proxy_rect(control_id, Rect2(proxy.position, proxy.size), true)
		ControlSettingsManager.save_settings()
	if _drag_ghost != null:
		_drag_ghost.queue_free()
		_drag_ghost = null
	_drag_id = ""
	_drag_moved = false
	_refresh_chips()
	_layout_proxies()


func _write_proxy_rect(control_id: String, layer_rect: Rect2, emit_change: bool) -> void:
	var game_size := get_viewport().get_visible_rect().size
	var k := widget_layer.size.x / game_size.x
	if k <= 0.0:
		return
	var game_rect := Rect2(layer_rect.position / k, ControlSettingsManager.pixel_size(control_id, game_size))
	# Only move: keep scale untouched by writing the current pixel size back.
	var data := ControlSettingsManager.get_control(control_id)
	var safe := ControlSettingsManager.clamp_rect(game_rect, game_size)
	data["nx"] = safe.position.x / game_size.x
	data["ny"] = safe.position.y / game_size.y
	ControlSettingsManager.set_control(control_id, data, emit_change)


func _toggle_visibility(control_id: String) -> void:
	var shown := ControlSettingsManager.control_visible(control_id)
	ControlSettingsManager.update_control(control_id, "visible", not shown)
	ControlSettingsManager.save_settings()
	_play(_selection_audio)
	_refresh_chips()
	_layout_proxies()


func _canvas_point(global_point: Vector2) -> Vector2:
	return canvas.get_global_transform_with_canvas().affine_inverse() * global_point


func _layer_point(canvas_point: Vector2) -> Vector2:
	return canvas_point - (widget_layer.global_position - canvas.global_position) / canvas.scale.x


# ------------------------------------------------------------------ list pages

func _make_list_page(page_id: String, title_text: String, subtitle_text: String) -> Control:
	var page := Control.new()
	page.name = "%sPage" % title_text.capitalize()
	page.visible = false
	page.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas.add_child(page)
	pages[page_id] = page
	var header := MetalPanel.new()
	header.name = "Header"
	page.add_child(header)
	var title := _label(header, title_text, 58, WHITE)
	title.position = Vector2(34.0, 18.0)
	title.size = Vector2(700.0, 64.0)
	var subtitle := _label(header, subtitle_text, 26, DIM)
	subtitle.position = Vector2(36.0, 80.0)
	subtitle.size = Vector2(700.0, 32.0)
	var body := MetalPanel.new()
	body.name = "Body"
	page.add_child(body)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 14)
	body.add_child(list)
	page.set_meta("list", list)
	return page


func _setting_row(list: VBoxContainer, title_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 76.0)
	row.add_theme_constant_override("separation", 24)
	var strip := PanelContainer.new()
	strip.add_theme_stylebox_override("panel", _box(Color(0.03, 0.035, 0.04, 0.72), Color(0.2, 0.21, 0.23, 1.0), 1, 3))
	strip.custom_minimum_size = Vector2(0.0, 76.0)
	list.add_child(strip)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	strip.add_child(margin)
	margin.add_child(row)
	var title := _label(null, title_text, 24, WHITE)
	title.custom_minimum_size = Vector2(330.0, 0.0)
	row.add_child(title)
	return row


func _add_slider_setting(
	list: VBoxContainer,
	key: String,
	title_text: String,
	getter: Callable,
	setter: Callable,
	formatter: Callable = Callable()
) -> void:
	var row := _setting_row(list, title_text)
	var slider := _make_slider()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value_label := _label(null, "", 24, WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.custom_minimum_size = Vector2(90.0, 0.0)
	row.add_child(value_label)
	var format := func(v: float) -> String:
		return formatter.call(v) if formatter.is_valid() else "%d%%" % int(round(v * 100.0))
	slider.value_changed.connect(func(v: float) -> void:
		value_label.text = format.call(v)
		if not _syncing:
			setter.call(v)
			ControlSettingsManager.save_settings())
	value_rows[key] = {
		"refresh": func() -> void:
			slider.set_value_no_signal(clampf(getter.call(), 0.0, 1.0))
			value_label.text = format.call(slider.value)
	}


func _add_toggle_setting(list: VBoxContainer, key: String, title_text: String, getter: Callable, setter: Callable) -> void:
	var row := _setting_row(list, title_text)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var pill := PillToggle.new()
	pill.custom_minimum_size = Vector2(96.0, 40.0)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.label_font = font
	row.add_child(pill)
	pill.toggled.connect(func(on: bool) -> void:
		if not _syncing:
			setter.call(on)
			ControlSettingsManager.save_settings())
	value_rows[key] = {"refresh": func() -> void: pill.set_on(getter.call())}


func _add_choice_setting(list: VBoxContainer, key: String, title_text: String, options: Array, getter: Callable, setter: Callable) -> void:
	var row := _setting_row(list, title_text)
	var buttons: Array[Button] = []
	for option in options:
		var button := _radio_button(option[0], "")
		button.custom_minimum_size = Vector2(150.0, 50.0)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.set_meta("value", option[1])
		row.add_child(button)
		buttons.append(button)
	var refresh := func() -> void:
		for candidate in buttons:
			_set_radio(candidate, int(candidate.get_meta("value")) == int(getter.call()))
	for button in buttons:
		button.pressed.connect(func() -> void:
			setter.call(int(button.get_meta("value")))
			ControlSettingsManager.save_settings()
			refresh.call())
	value_rows[key] = {"refresh": refresh}


func _add_info_setting(list: VBoxContainer, title_text: String, getter: Callable) -> void:
	var row := _setting_row(list, title_text)
	var value_label := _label(null, "", 24, DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value_label)
	value_rows["info_" + title_text] = {"refresh": func() -> void: value_label.text = getter.call()}


func _binding_row(action: String, keys: String) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0.0, 44.0)
	row.add_theme_stylebox_override("panel", _box(Color(0.03, 0.035, 0.04, 0.72), Color(0.2, 0.21, 0.23, 1.0), 1, 3))
	var box := HBoxContainer.new()
	row.add_child(box)
	var left := _label(null, "   " + action, 22, WHITE)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(left)
	var right := _label(null, keys + "   ", 22, LIT, HORIZONTAL_ALIGNMENT_RIGHT)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(right)
	return row


# ------------------------------------------------------------------ widget factories

func _label(parent: Node, text_value: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	if parent != null:
		parent.add_child(label)
	return label


func _wrap_label(parent: Control, text_value: String, font_size: int, color: Color, pos: Vector2, label_size: Vector2) -> Label:
	var label := _label(parent, text_value, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.custom_minimum_size = Vector2(label_size.x, 0.0)
	label.position = pos
	label.size = label_size
	return label


func _section_title(parent: Control, text_value: String, pos: Vector2) -> void:
	var label := _label(parent, text_value, 28, WHITE)
	label.position = pos
	label.size = Vector2(RIGHT_WIDTH - 40.0, 36.0)


func _plain_button(text_value: String, font_size: int) -> Button:
	var button := Button.new()
	button.text = text_value
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", font_size)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, WHITE)
	button.add_theme_stylebox_override("normal", _box(STEEL, STEEL_EDGE, 2, 4))
	button.add_theme_stylebox_override("hover", _box(Color(0.12, 0.12, 0.13, 0.96), Color(0.5, 0.5, 0.52, 1.0), 2, 4))
	button.add_theme_stylebox_override("pressed", _box(GREEN_DEEP, GREEN, 2, 4))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _style_tab(button: Button, selected: bool) -> void:
	var plate := button.get_meta("plate", null) as NavPlate
	if plate != null:
		plate.lit = selected
	button.add_theme_color_override("font_color", LIT if selected else TEXT_LIGHT)
	button.add_theme_color_override("font_hover_color", LIT)
	button.add_theme_color_override("font_pressed_color", LIT)


func _radio_button(text_value: String, icon_id: String) -> Button:
	var button := _plain_button(text_value, 19)
	if icon_id != "":
		button.icon = HudArt.icon(icon_id)
		# The SVG icons are 128 px; without expand_icon they set the min height.
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 26)
		button.add_theme_constant_override("h_separation", 8)
	_set_radio(button, false)
	return button


func _set_radio(button: Button, selected: bool) -> void:
	if button == null:
		return
	if selected:
		var style := _box(GREEN_DEEP, GREEN, 3, 4)
		style.shadow_color = Color(GREEN.r, GREEN.g, GREEN.b, 0.35)
		style.shadow_size = 8
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_color_override("font_color", WHITE)
		button.add_theme_color_override("icon_normal_color", GREEN)
	else:
		button.add_theme_stylebox_override("normal", _box(STEEL, STEEL_EDGE, 2, 4))
		button.add_theme_stylebox_override("hover", _box(Color(0.12, 0.12, 0.13, 0.96), Color(0.5, 0.5, 0.52, 1.0), 2, 4))
		button.add_theme_color_override("font_color", DIM)
		button.add_theme_color_override("icon_normal_color", DIM)


func _slider_row(parent: Control, title_text: String, pos: Vector2) -> Array:
	var title := _label(parent, title_text, 20, WHITE)
	title.position = pos
	title.size = Vector2(220.0, 28.0)
	var slider := _make_slider()
	slider.position = pos + Vector2(0.0, 30.0)
	slider.size = Vector2(RIGHT_WIDTH - 44.0 - 70.0, 30.0)
	parent.add_child(slider)
	var value_label := _label(parent, "100%", 20, WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.position = pos + Vector2(RIGHT_WIDTH - 44.0 - 64.0, 30.0)
	value_label.size = Vector2(64.0, 30.0)
	return [slider, value_label]


func _make_slider() -> HSlider:
	var slider := HSlider.new()
	slider.focus_mode = Control.FOCUS_NONE
	slider.step = 1.0
	slider.custom_minimum_size = Vector2(120.0, 30.0)
	var rail := _box(Color(0.02, 0.022, 0.025, 1.0), Color(0.24, 0.25, 0.27, 1.0), 1, 4)
	rail.content_margin_top = 4.0
	rail.content_margin_bottom = 4.0
	slider.add_theme_stylebox_override("slider", rail)
	var fill := _box(Color(0.18, 0.62, 0.16, 1.0), Color(0.36, 0.86, 0.3, 1.0), 1, 4)
	fill.content_margin_top = 4.0
	fill.content_margin_bottom = 4.0
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	var knob := _knob_texture()
	slider.add_theme_icon_override("grabber", knob)
	slider.add_theme_icon_override("grabber_highlight", knob)
	return slider


static var _knob_cache: Texture2D = null


func _knob_texture() -> Texture2D:
	if _knob_cache != null:
		return _knob_cache
	var knob_size := 30
	var image := Image.create(knob_size, knob_size, false, Image.FORMAT_RGBA8)
	var center := Vector2(knob_size, knob_size) * 0.5
	for y in range(knob_size):
		for x in range(knob_size):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if d > 14.0:
				continue
			var shade := lerpf(0.92, 0.55, clampf((y as float) / knob_size, 0.0, 1.0))
			var color := Color(shade, shade, shade * 1.02, 1.0)
			if d > 12.5:
				color = Color(0.1, 0.1, 0.11, 1.0)
			image.set_pixel(x, y, color)
	_knob_cache = ImageTexture.create_from_image(image)
	return _knob_cache


func _pill(parent: Control, pos: Vector2, pill_size: Vector2) -> PillToggle:
	var pill := PillToggle.new()
	pill.position = pos
	pill.size = pill_size
	pill.label_font = font
	parent.add_child(pill)
	return pill


func _toggle_row(parent: Control, title_text: String, y: float) -> PillToggle:
	var label := _label(parent, title_text, 18, WHITE)
	label.position = Vector2(22.0, y)
	label.size = Vector2(RIGHT_WIDTH - 44.0 - 96.0, 38.0)
	label.clip_text = true
	return _pill(parent, Vector2(RIGHT_WIDTH - 22.0 - 84.0, y + 2.0), Vector2(84.0, 36.0))


func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	return style


func _make_audio(path: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.volume_db = volume_db
	if ResourceLoader.exists(path):
		player.stream = load(path) as AudioStream
	add_child(player)
	return player


func _play(player: AudioStreamPlayer) -> void:
	if player != null and player.stream != null and visible:
		player.stop()
		player.play()


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("Settings art not found: %s" % path)
	return null


# ------------------------------------------------------------------ drawn widgets

## Dark riveted steel plate with a chamfered bevel, matching the pause art.
class MetalPanel:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		resized.connect(queue_redraw)

	func _draw() -> void:
		var c := 10.0
		var w := size.x
		var h := size.y
		var outline := PackedVector2Array([
			Vector2(c, 0), Vector2(w - c, 0), Vector2(w, c), Vector2(w, h - c),
			Vector2(w - c, h), Vector2(c, h), Vector2(0, h - c), Vector2(0, c),
		])
		draw_colored_polygon(outline, Color(0.045, 0.048, 0.052, 0.93))
		var inset := PackedVector2Array()
		for point in outline:
			inset.append(point + (size * 0.5 - point).normalized() * 6.0)
		draw_colored_polygon(inset, Color(0.07, 0.074, 0.08, 0.60))
		var closed := outline.duplicate()
		closed.append(outline[0])
		draw_polyline(closed, Color(0.30, 0.31, 0.33, 1.0), 2.0, true)
		draw_line(Vector2(c + 4.0, 3.0), Vector2(w - c - 4.0, 3.0), Color(0.55, 0.56, 0.58, 0.35), 1.0)
		for corner in [Vector2(14, 14), Vector2(w - 14, 14), Vector2(14, h - 14), Vector2(w - 14, h - 14)]:
			draw_circle(corner, 4.0, Color(0.16, 0.17, 0.18, 1.0))
			draw_circle(corner + Vector2(-0.8, -0.8), 2.4, Color(0.48, 0.49, 0.51, 1.0))


## ON/OFF pill switch from the reference (green with knob right when ON).
class PillToggle:
	extends Control

	signal toggled(on: bool)

	var on := false
	var label_font: Font = null

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(queue_redraw)

	func set_on(value: bool) -> void:
		on = value
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		var button := event as InputEventMouseButton
		if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			on = not on
			queue_redraw()
			toggled.emit(on)
			accept_event()

	func _draw() -> void:
		var radius := size.y * 0.5
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(int(radius))
		style.bg_color = Color(0.13, 0.56, 0.12, 1.0) if on else Color(0.07, 0.075, 0.08, 1.0)
		style.border_color = Color(0.36, 0.86, 0.3, 1.0) if on else Color(0.30, 0.31, 0.33, 1.0)
		style.set_border_width_all(2)
		draw_style_box(style, Rect2(Vector2.ZERO, size))
		var knob_x := size.x - radius if on else radius
		draw_circle(Vector2(knob_x, radius), radius * 0.72, Color(0.92, 0.93, 0.94, 1.0) if on else Color(0.55, 0.56, 0.58, 1.0))
		var font := label_font if label_font != null else get_theme_default_font()
		var font_size := int(size.y * 0.5)
		var text := "ON" if on else "OFF"
		var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var text_x := radius * 0.8 if on else size.x - radius * 0.8 - text_width
		draw_string(font, Vector2(text_x, radius + font_size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.96, 0.95, 1.0))


## Dashed selection box with a move handle, drawn over each preview control.
class SelectionFrame:
	extends Control

	var selected := false:
		set(value):
			selected = value
			queue_redraw()
	var move_icon: Texture2D = null

	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var rect := Rect2(Vector2(-4, -4), size + Vector2(8, 8))
		var color := Color(0.94, 0.18, 0.16, 1.0) if selected else Color(1, 1, 1, 0.55)
		var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for i in range(4):
			draw_dashed_line(corners[i], corners[(i + 1) % 4], color, 1.5 if not selected else 2.2, 5.0)
		var handle := clampf(minf(size.x, size.y) * 0.28, 12.0, 30.0)
		var handle_center := Vector2(rect.end.x, rect.position.y)
		draw_circle(handle_center, handle * 0.62, Color(0.06, 0.065, 0.07, 0.92))
		draw_arc(handle_center, handle * 0.62, 0.0, TAU, 24, color, 1.5, true)
		if move_icon != null:
			draw_texture_rect(move_icon, Rect2(handle_center - Vector2.ONE * handle * 0.42, Vector2.ONE * handle * 0.84), false)


## One chip in the BUTTONS bar: icon + caption; dim when the control is hidden.
class ControlChip:
	extends Control

	var control_id := ""
	var caption := ""
	var icon: Texture2D = null
	var caption_font: Font = null
	var enabled := true:
		set(value):
			enabled = value
			queue_redraw()
	var selected := false:
		set(value):
			selected = value
			queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(queue_redraw)

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(4)
		style.set_border_width_all(3 if selected else 2)
		style.bg_color = Color(0.25, 0.04, 0.04, 0.95) if selected else Color(0.07, 0.075, 0.08, 0.95)
		style.border_color = Color(0.94, 0.18, 0.16, 1.0) if selected else (Color(0.40, 0.41, 0.43, 1.0) if enabled else Color(0.18, 0.19, 0.2, 1.0))
		if selected:
			style.shadow_color = Color(0.94, 0.18, 0.16, 0.45)
			style.shadow_size = 8
		draw_style_box(style, rect)
		var alpha := 1.0 if enabled else 0.32
		if icon != null:
			var icon_size := Vector2.ONE * minf(size.x * 0.6, size.y * 0.52)
			draw_texture_rect(icon, Rect2(Vector2((size.x - icon_size.x) * 0.5, size.y * 0.14), icon_size), false, Color(0.93, 0.94, 0.95, alpha))
		var font := caption_font if caption_font != null else get_theme_default_font()
		var font_size := int(clampf(size.x * 0.17, 12.0, 20.0))
		var text_width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, Vector2((size.x - text_width) * 0.5, size.y - 12.0), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.93, 0.94, 0.95, alpha))
		if not enabled:
			draw_string(font, Vector2(size.x - 34.0, 20.0), "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.94, 0.18, 0.16, 0.9))
