extends Control

const MENU_BG_PATH: String = "res://assets/Game UI Art/V51/Main_Menu_Background.png"
const TITLE_TEX_PATH: String = "res://assets/Game UI Art/V52/Game_Title_Reference.png"
const MUSIC_PATH: String = "res://assets/Audio/Menu Game Music.mp3"
const AMBIENCE_PATH: String = "res://assets/Audio/Menu Bunker Ambience.mp3"
const GAME_SCENE_PATH: String = "res://scenes/main.tscn"
const LIVE_BACKGROUND_PATH: String = "res://assets/Game UI Art/V51/Live_Main_Menu.ogv"
const PLAY_BUTTON_PATH: String = "res://assets/Game UI Art/V52/Menu_Play.png"
const SECONDARY_BUTTON_PATH: String = "res://assets/Game UI Art/V52/Menu_Secondary.png"
const MENU_SELECTION_SOUND_PATH: String = "res://assets/Audio/UI/Menu Selection.mp3"
const PLAY_CONFIRMATION_SOUND_PATH: String = "res://assets/Audio/UI/Play confirmation.mp3"
const SECONDARY_CONFIRMATION_SOUND_PATH: String = \
	"res://assets/Audio/UI/Settings Confirmation Credits.mp3"

const MUSIC_BASE_DB: float = -14.0
const AMBIENCE_BASE_DB: float = 18.0
const MENU_SELECTION_SOUND_DB: float = -9.0
const PLAY_CONFIRMATION_SOUND_DB: float = 3.0
const SECONDARY_CONFIRMATION_SOUND_DB: float = -2.0

# Main-menu layout uses a 1360x768 reference canvas. Adjust only these values
# when visually fine-tuning the title or buttons; device scaling remains automatic.
const MENU_TITLE_POSITION := Vector2(450.0, 80.0)
const MENU_TITLE_SIZE := Vector2(370.0, 275.0)
const MENU_PLAY_POSITION := Vector2(440.0, 280.0)
const MENU_PLAY_SIZE := Vector2(390.0, 125.0)
const MENU_SECONDARY_SIZE := Vector2(355.0, 80.0)
const MENU_SETTINGS_POSITION := Vector2(460.0, 365.0)
const MENU_CREDITS_POSITION := Vector2(460.0, 415.0)

var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var settings_overlay: Control
var credits_overlay: Control
var music_slider: HSlider
var gameplay_music_slider: HSlider
var ambience_slider: HSlider
var menu_media_root: Control = null
var menu_panel: PanelContainer = null
var menu_ui_font: SystemFont = null
var menu_title_font: SystemFont = null
var last_menu_viewport_size := Vector2.ZERO
var menu_buttons: Array[Button] = []
var selected_menu_button: Button = null
var menu_selection_player: AudioStreamPlayer = null
var play_confirmation_player: AudioStreamPlayer = null
var secondary_confirmation_player: AudioStreamPlayer = null
var menu_selection_audio_enabled := false
var live_background: VideoStreamPlayer = null
var background_fallback: TextureRect = null
var title_rect: TextureRect = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Required for normal Control/Button nodes to react reliably to iPhone taps.
	Input.emulate_mouse_from_touch = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MusicManager.leave_gameplay()
	_init_menu_fonts()
	_build_menu()
	# The initial PLAY highlight is visual setup, not a user selection.
	menu_selection_audio_enabled = true
	_build_settings_overlay()
	_build_credits_overlay()
	# Let iOS present the first real menu frame before opening video/audio files.
	# This prevents optional media from extending the native Godot splash screen.
	call_deferred("_start_deferred_menu_media")

func _process(_delta: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size != last_menu_viewport_size:
		_layout_main_menu()

func _build_menu() -> void:
	# Letterbox when necessary rather than stretching/cropping the reference's
	# 16:9 bunker composition. This is especially important on iPad.
	var letterbox := ColorRect.new()
	letterbox.name = "MenuLetterbox"
	letterbox.color = Color.BLACK
	letterbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	letterbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(letterbox)

	menu_media_root = Control.new()
	menu_media_root.name = "MenuMediaFrame16x9"
	menu_media_root.clip_contents = true
	menu_media_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu_media_root)

	# Static artwork remains underneath as an instant fallback while the video
	# imports/starts and if the live background is ever missing.
	background_fallback = TextureRect.new()
	background_fallback.name = "BackgroundFallback"
	background_fallback.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_fallback.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_media_root.add_child(background_fallback)

	# Keep the complete bunker artwork visible. The reference relies on the dark
	# center door itself, not a large translucent UI panel, for readability.
	var vignette := ColorRect.new()
	vignette.name = "MenuReadabilityVignette"
	vignette.color = Color(0.0, 0.0, 0.0, 0.055)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_media_root.add_child(vignette)

	var center := CenterContainer.new()
	center.name = "MenuCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_media_root.add_child(center)

	menu_panel = PanelContainer.new()
	menu_panel.name = "MenuPanel"
	# Reference composition canvas. Scaling this complete 16:9 canvas keeps the
	# title/buttons registered to the animated background on every device.
	menu_panel.custom_minimum_size = Vector2(1360.0, 768.0)
	menu_panel.pivot_offset = Vector2(680.0, 384.0)
	menu_panel.add_theme_stylebox_override("panel", _menu_panel_style())
	center.add_child(menu_panel)

	var content := Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_panel.add_child(content)

	title_rect = TextureRect.new()
	title_rect.name = "BunkerZeroTitle"
	title_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Smaller title and lower menu stack match the new framed-menu reference.
	title_rect.position = MENU_TITLE_POSITION
	title_rect.size = MENU_TITLE_SIZE
	title_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title_rect)

	var play := _make_art_menu_button(
		"PLAY",
		null,
		Color(1.0, 0.10, 0.055, 1.0),
		MENU_PLAY_SIZE,
		32
	)
	play.name = "Play"
	play.position = MENU_PLAY_POSITION
	play.pressed.connect(_on_play_pressed)
	content.add_child(play)

	var settings := _make_art_menu_button(
		"SETTINGS",
		null,
		Color(0.08, 0.62, 1.0, 1.0),
		MENU_SECONDARY_SIZE,
		23
	)
	settings.name = "Settings"
	settings.position = MENU_SETTINGS_POSITION
	settings.pressed.connect(_open_settings)
	content.add_child(settings)

	var credits := _make_art_menu_button(
		"CREDITS",
		null,
		Color(0.08, 0.62, 1.0, 1.0),
		MENU_SECONDARY_SIZE,
		23
	)
	credits.name = "Credits"
	credits.position = MENU_CREDITS_POSITION
	credits.pressed.connect(_open_credits)
	content.add_child(credits)

	menu_buttons = [play, settings, credits]
	play.focus_neighbor_bottom = settings.get_path()
	settings.focus_neighbor_top = play.get_path()
	settings.focus_neighbor_bottom = credits.get_path()
	credits.focus_neighbor_top = settings.get_path()
	_on_menu_button_selected(play)
	play.call_deferred("grab_focus")

	_layout_main_menu()

func _start_deferred_menu_media() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	if background_fallback != null and ResourceLoader.exists(MENU_BG_PATH):
		background_fallback.texture = load(MENU_BG_PATH) as Texture2D
	await get_tree().process_frame
	if title_rect != null and ResourceLoader.exists(TITLE_TEX_PATH):
		title_rect.texture = load(TITLE_TEX_PATH) as Texture2D
	var play_texture := _load_menu_texture(PLAY_BUTTON_PATH)
	var secondary_texture := _load_menu_texture(SECONDARY_BUTTON_PATH)
	for button in menu_buttons:
		if button == null:
			continue
		var plate := button.get_node_or_null("Plate") as TextureRect
		if plate != null:
			plate.texture = play_texture if button.name == "Play" else secondary_texture
	await get_tree().process_frame
	_build_menu_sfx()
	_start_menu_audio()
	await get_tree().process_frame
	_start_live_background()

func _start_live_background() -> void:
	if not ResourceLoader.exists(LIVE_BACKGROUND_PATH):
		push_warning("Live main-menu background missing: %s" % LIVE_BACKGROUND_PATH)
		return
	var stream := load(LIVE_BACKGROUND_PATH) as VideoStream
	if stream == null or menu_media_root == null:
		push_warning("Live main-menu background could not be loaded: %s" % LIVE_BACKGROUND_PATH)
		return
	live_background = VideoStreamPlayer.new()
	live_background.name = "LiveBackground"
	live_background.stream = stream
	live_background.expand = true
	live_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	live_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	live_background.volume_db = -80.0
	live_background.finished.connect(_restart_live_background.bind(live_background))
	# Keep it above the static fallback and below the vignette/menu children.
	menu_media_root.add_child(live_background)
	menu_media_root.move_child(live_background, 1)
	live_background.play()

func _restart_live_background(player: VideoStreamPlayer) -> void:
	if is_instance_valid(player):
		player.play()

func _init_menu_fonts() -> void:
	menu_ui_font = SystemFont.new()
	menu_ui_font.font_names = PackedStringArray(["Eurostile Extended", "Microgramma D Extended", "Bank Gothic", "Orbitron", "Eurostile", "Helvetica Neue"])
	menu_ui_font.font_weight = 600
	menu_ui_font.font_stretch = 112
	menu_title_font = SystemFont.new()
	menu_title_font.font_names = menu_ui_font.font_names
	menu_title_font.font_weight = 700

func _apply_menu_font(control: Control, bold: bool = false) -> void:
	control.add_theme_font_override("font", menu_title_font if bold else menu_ui_font)

func _layout_main_menu() -> void:
	if menu_panel == null or menu_media_root == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var reference_aspect: float = 1360.0 / 768.0
	var media_size := Vector2.ZERO
	if viewport_size.x / viewport_size.y > reference_aspect:
		media_size = Vector2(viewport_size.y * reference_aspect, viewport_size.y)
	else:
		media_size = Vector2(viewport_size.x, viewport_size.x / reference_aspect)
	menu_media_root.position = (viewport_size - media_size) * 0.5
	menu_media_root.size = media_size
	var scale_factor := media_size.x / 1360.0
	menu_panel.scale = Vector2.ONE * scale_factor
	last_menu_viewport_size = viewport_size

func _menu_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	return style

func _load_menu_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_error("BUNKER ZERO: Missing menu button texture: %s" % path)
		return null
	return load(path) as Texture2D

func _make_art_menu_button(
	label_text: String,
	button_texture: Texture2D,
	accent: Color,
	button_size: Vector2,
	font_size: int
) -> Button:
	var button := Button.new()
	button.text = ""
	button.size = button_size
	button.custom_minimum_size = button_size
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.add_theme_stylebox_override("normal", _transparent_button_style())
	button.add_theme_stylebox_override("hover", _transparent_button_style())
	button.add_theme_stylebox_override("pressed", _transparent_button_style())
	button.add_theme_stylebox_override("focus", _transparent_button_style())
	button.set_meta("menu_accent", accent)

	var plate := TextureRect.new()
	plate.name = "Plate"
	plate.texture = button_texture
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.material = _make_menu_plate_material(accent)
	button.add_child(plate)

	var label := Label.new()
	label.name = "ButtonLabel"
	label.text = label_text
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", menu_title_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.78, 0.80, 0.81, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.96))
	label.add_theme_constant_override("outline_size", 5)
	button.add_child(label)

	button.focus_entered.connect(_on_menu_button_selected.bind(button))
	button.mouse_entered.connect(_on_menu_button_selected.bind(button))
	button.button_down.connect(_on_menu_button_selected.bind(button))
	return button

func _transparent_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	return style

func _make_menu_plate_material(accent: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec4 accent_color : source_color = vec4(1.0, 0.1, 0.05, 1.0);
uniform float selected = 0.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float red_signal = max(source.r - max(source.g, source.b), 0.0);
	float luminance = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 metal = mix(vec3(luminance), source.rgb, 0.68);
	metal.r = max(0.0, metal.r - red_signal * 0.84);
	float idle_light = 0.20;
	float accent_strength = mix(idle_light, 1.25, selected);
	vec3 final_color = metal + accent_color.rgb * red_signal * accent_strength;
	final_color *= mix(0.68, 1.08, selected);
	COLOR = vec4(clamp(final_color, vec3(0.0), vec3(1.0)), source.a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("accent_color", accent)
	material.set_shader_parameter("selected", 0.0)
	return material

func _on_menu_button_selected(button: Button) -> void:
	if button == null or selected_menu_button == button:
		return
	selected_menu_button = button
	if menu_selection_audio_enabled:
		_play_menu_sound(menu_selection_player)
	for candidate in menu_buttons:
		if candidate == null:
			continue
		var is_selected := candidate == selected_menu_button
		var plate := candidate.get_node_or_null("Plate") as TextureRect
		var label := candidate.get_node_or_null("ButtonLabel") as Label
		var accent: Color = candidate.get_meta("menu_accent", Color.WHITE)
		if plate != null and plate.material is ShaderMaterial:
			(plate.material as ShaderMaterial).set_shader_parameter(
				"selected",
				1.0 if is_selected else 0.0
			)
		if label != null:
			label.add_theme_color_override(
				"font_color",
				Color(1.0, 0.97, 0.92, 1.0) if is_selected
				else Color(0.68, 0.70, 0.71, 1.0)
			)
			label.add_theme_color_override(
				"font_outline_color",
				Color(accent.r, accent.g, accent.b, 0.74) if is_selected
				else Color(0.0, 0.0, 0.0, 0.96)
			)

func _make_menu_button(label_text: String, text_color: Color, accent: Color, primary: bool) -> Button:
	var button := Button.new()
	button.text = label_text
	button.size = Vector2(400.0, 48.0)
	button.custom_minimum_size = button.size
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.add_theme_font_size_override("font_size", 38 if primary else 34)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.88, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.80, 0.48, 1.0))
	button.add_theme_color_override("font_outline_color", Color(accent.r, accent.g, accent.b, 0.94))
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_stylebox_override("normal", _menu_button_style(Color(0.0, 0.0, 0.0, 0.09), accent, 1))
	button.add_theme_stylebox_override("hover", _menu_button_style(Color(accent.r * 0.08, accent.g * 0.06, accent.b * 0.06, 0.30), accent, 1))
	button.add_theme_stylebox_override("pressed", _menu_button_style(Color(accent.r * 0.12, accent.g * 0.08, accent.b * 0.08, 0.40), accent, 2))
	button.add_theme_stylebox_override("focus", _menu_button_style(Color(0, 0, 0, 0), accent, 1))
	_apply_menu_font(button, primary)

	# Button has a crisp outline but no native soft text-shadow theme property.
	# A transparent duplicate Label supplies the wider additive-looking halo while
	# remaining input-transparent and inexpensive on mobile.
	var glow := Label.new()
	glow.name = "TextGlow"
	glow.text = label_text
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.offset_top = -2.0
	glow.offset_bottom = -2.0
	glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.show_behind_parent = true
	glow.add_theme_font_size_override("font_size", 38 if primary else 34)
	glow.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.10))
	glow.add_theme_color_override("font_outline_color", Color(accent.r, accent.g, accent.b, 0.48))
	glow.add_theme_constant_override("outline_size", 8)
	_apply_menu_font(glow, primary)
	button.add_child(glow)
	return button

func _menu_button_style(background: Color, accent: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = accent
	style.border_width_bottom = width
	style.content_margin_bottom = 4.0
	return style

func _add_menu_glow_rule(parent: Control, rule_name: String, rule_position: Vector2, rule_width: float, color: Color, glow_size: int) -> void:
	var rule := Panel.new()
	rule.name = rule_name
	rule.position = rule_position
	rule.size = Vector2(rule_width, 1.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.shadow_color = Color(color.r, color.g, color.b, 0.56)
	style.shadow_size = glow_size
	style.shadow_offset = Vector2.ZERO
	rule.add_theme_stylebox_override("panel", style)
	parent.add_child(rule)

func _build_settings_overlay() -> void:
	# Same Settings screen as the pause menu. With no run loaded, its Controls
	# preview renders the hub level live instead of the player camera.
	var screen := SettingsScreen.new()
	screen.name = "SettingsScreen"
	screen.z_index = 60
	add_child(screen)
	screen.menu_audio_changed.connect(_apply_menu_audio_levels)
	settings_overlay = screen

func _apply_menu_audio_levels() -> void:
	if music_player != null:
		music_player.volume_db = _menu_music_db()
	if ambience_player != null:
		ambience_player.volume_db = _menu_ambience_db()

func _build_credits_overlay() -> void:
	credits_overlay = _make_modal_shell("CREDITS")
	credits_overlay.visible = false
	add_child(credits_overlay)
	var box := credits_overlay.get_node("Center/Panel/Margin/VBox") as VBoxContainer
	var text := Label.new()
	text.text = "BUNKER ZERO\n\nGAME DESIGN & DEVELOPMENT\nCredits can be finalized here before release."
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 18)
	text.add_theme_color_override("font_color", Color(0.82, 0.88, 0.90, 1.0))
	box.add_child(text)
	var back := _make_text_button("BACK")
	back.pressed.connect(_close_credits)
	box.add_child(back)

func _make_modal_shell(title_text: String) -> Control:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 50

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(520.0, 380.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.028, 0.032, 0.036, 0.98)
	style.border_color = Color(0.42, 0.44, 0.46, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.name = "VBox"
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.94, 0.95, 0.95, 1.0))
	box.add_child(title)
	return overlay

func _make_text_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(360.0, 54.0)
	button.add_theme_font_size_override("font_size", 20)
	return button

func _start_menu_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MenuMusic"
	music_player.stream = load(MUSIC_PATH) as AudioStream
	music_player.volume_db = _menu_music_db()
	music_player.finished.connect(_restart_music)
	add_child(music_player)

	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "BunkerAmbience"
	ambience_player.stream = load(AMBIENCE_PATH) as AudioStream
	ambience_player.volume_db = _menu_ambience_db()
	ambience_player.finished.connect(_restart_ambience)
	add_child(ambience_player)

	if music_player.stream != null:
		music_player.play()
	if ambience_player.stream != null:
		ambience_player.play()

func _menu_music_db() -> float:
	var slider_value: float = float(SaveManager.get_value("audio", "menu_music", 100.0))
	if slider_value <= 0.0:
		return -80.0
	return MUSIC_BASE_DB + lerpf(-30.0, 0.0, slider_value / 100.0)

func _menu_ambience_db() -> float:
	var slider_value: float = float(SaveManager.get_value("audio", "menu_ambience", 100.0))
	if slider_value <= 0.0:
		return -80.0
	return AMBIENCE_BASE_DB + lerpf(-30.0, 0.0, slider_value / 100.0)

func _on_music_slider_changed(value: float) -> void:
	SaveManager.set_value("audio", "menu_music", value)
	if music_player != null:
		music_player.volume_db = -80.0 if value <= 0.0 else MUSIC_BASE_DB + lerpf(-30.0, 0.0, value / 100.0)

func _on_ambience_slider_changed(value: float) -> void:
	SaveManager.set_value("audio", "menu_ambience", value)
	if ambience_player != null:
		ambience_player.volume_db = -80.0 if value <= 0.0 else AMBIENCE_BASE_DB + lerpf(-30.0, 0.0, value / 100.0)

func _on_gameplay_music_slider_changed(value: float) -> void:
	MusicManager.set_user_volume(value)

func _restart_music() -> void:
	if music_player != null:
		music_player.play()

func _restart_ambience() -> void:
	if ambience_player != null:
		ambience_player.play()

func _build_menu_sfx() -> void:
	menu_selection_player = _make_menu_sound_player(
		"MenuSelectionSFX",
		MENU_SELECTION_SOUND_PATH,
		MENU_SELECTION_SOUND_DB
	)
	play_confirmation_player = _make_menu_sound_player(
		"PlayConfirmationSFX",
		PLAY_CONFIRMATION_SOUND_PATH,
		PLAY_CONFIRMATION_SOUND_DB
	)
	secondary_confirmation_player = _make_menu_sound_player(
		"SecondaryConfirmationSFX",
		SECONDARY_CONFIRMATION_SOUND_PATH,
		SECONDARY_CONFIRMATION_SOUND_DB
	)

func _make_menu_sound_player(
	player_name: String,
	stream_path: String,
	volume_db: float
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.volume_db = volume_db
	if ResourceLoader.exists(stream_path):
		player.stream = load(stream_path) as AudioStream
	else:
		push_warning("Menu sound not found: %s" % stream_path)
	add_child(player)
	return player

func _play_menu_sound(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		return
	player.stop()
	player.play()

func _play_confirmation_sound(player: AudioStreamPlayer) -> void:
	# Hover/touch selection and confirmation can occur on the same frame.
	# Let the intentional confirmation sound take priority over the selector.
	if menu_selection_player != null:
		menu_selection_player.stop()
	_play_menu_sound(player)

func _on_play_pressed() -> void:
	if LoadingScreen.is_loading():
		return
	_play_confirmation_sound(play_confirmation_player)
	RunManager.reset_to_hub()
	if not ResourceLoader.exists(GAME_SCENE_PATH):
		LoadingScreen.show_error("MAIN SCENE NOT FOUND")
		return
	LoadingScreen.load_scene(GAME_SCENE_PATH)

func _open_settings() -> void:
	_play_confirmation_sound(secondary_confirmation_player)
	(settings_overlay as SettingsScreen).open("menu", "controls")

func _close_settings() -> void:
	(settings_overlay as SettingsScreen).close(false)

func _open_credits() -> void:
	_play_confirmation_sound(secondary_confirmation_player)
	credits_overlay.visible = true

func _close_credits() -> void:
	credits_overlay.visible = false
