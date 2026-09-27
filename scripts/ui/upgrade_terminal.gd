class_name UpgradeTerminal
extends Control

## Authored upgrade popup + proximity prompt. World interaction still lives in
## upgrade_ui_controller.gd.

const PANEL_BASE_SIZE := Vector2(712.0, 620.0)
const AMBER := Color(1.0, 0.56, 0.14, 1.0)

@onready var interaction_prompt: Button = $UpgradeInteractionPrompt
@onready var popup_overlay: ColorRect = $UpgradePopupOverlay
@onready var popup_panel: PanelContainer = $UpgradePopupOverlay/Center/UpgradeGlassPanel
@onready var category_label: Label = $UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/CategoryLabel
@onready var title_label: Label = $UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/TitleLabel
@onready var subtitle_label: Label = $UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/SubtitleLabel
@onready var bank_label: Label = $UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/BankLabel
@onready var level_label: Label = $UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/LevelLabel
@onready var current_caption: Label = $UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/CurrentCard/CurrentCaption
@onready var current_value: Label = $UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/CurrentCard/CurrentValue
@onready var next_caption: Label = $UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/NextCard/NextCaption
@onready var next_value: Label = $UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/NextCard/NextValue
@onready var description_label: Label = $UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/DescriptionLabel
@onready var cost_label: Label = $UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/CostLabel
@onready var buy_button: Button = $UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/BuyButton
@onready var close_button: Button = $UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/CloseButton
@onready var level_segments: Array[ColorRect] = [
	$UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/LevelProgress/Seg0,
	$UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/LevelProgress/Seg1,
	$UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/LevelProgress/Seg2,
	$UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/LevelProgress/Seg3,
	$UpgradePopupOverlay/Center/UpgradeGlassPanel/Content/LevelProgress/Seg4,
]
@onready var accent_lines: Array[Line2D] = [
	$UpgradePopupOverlay/Center/UpgradeGlassPanel/Brackets/TL,
	$UpgradePopupOverlay/Center/UpgradeGlassPanel/Brackets/TR,
	$UpgradePopupOverlay/Center/UpgradeGlassPanel/Brackets/BL,
	$UpgradePopupOverlay/Center/UpgradeGlassPanel/Brackets/BR,
]

signal prompt_pressed
signal close_pressed
signal buy_pressed

var last_viewport_size := Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_overlay.visible = false
	interaction_prompt.visible = false
	interaction_prompt.pressed.connect(func() -> void: prompt_pressed.emit())
	close_button.pressed.connect(func() -> void: close_pressed.emit())
	buy_button.pressed.connect(func() -> void: buy_pressed.emit())
	layout_ui()

func _process(_delta: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size != last_viewport_size:
		layout_ui()

func layout_ui() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	if popup_panel != null:
		var scale_factor := minf(viewport_size.y / 941.0, viewport_size.x / 1672.0)
		popup_panel.scale = Vector2.ONE * scale_factor
	last_viewport_size = viewport_size

func is_popup_open() -> bool:
	return popup_overlay != null and popup_overlay.visible

func set_prompt_visible(shown: bool, label_text: String = "") -> void:
	if interaction_prompt == null:
		return
	interaction_prompt.visible = shown
	if shown and not label_text.is_empty():
		interaction_prompt.text = label_text

func open_popup() -> void:
	interaction_prompt.visible = false
	popup_overlay.visible = true

func close_popup() -> void:
	popup_overlay.visible = false

func apply_accent(accent: Color) -> void:
	for line in accent_lines:
		line.default_color = accent
	var style := popup_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
	else:
		style = style.duplicate() as StyleBoxFlat
	style.bg_color = Color(0, 0, 0, 0.03)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.18)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = 22
	popup_panel.add_theme_stylebox_override("panel", style)

func set_level_segments(level: int, accent: Color) -> void:
	for index in range(level_segments.size()):
		level_segments[index].color = accent if index < level else Color(0.19, 0.19, 0.18, 0.92)
