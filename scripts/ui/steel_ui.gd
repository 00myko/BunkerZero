class_name SteelUI
extends RefCounted

## Shared kit for the riveted-steel hub tables and the RUN ENDED plate, in the
## pause menu's language: worn steel plates, acid-green = live/selected/buy,
## dim grey = locked, amber only for money.

const ART := "res://assets/Game UI Art/Upgrade Tables/"
const ICONS := ART + "icons/"

const GREEN := Color(0.38, 1.0, 0.20, 1.0)
const GREEN_SOFT := Color(0.52, 0.88, 0.38, 1.0)
const GREEN_DARK := Color(0.06, 0.16, 0.04, 1.0)
const TEXT_LIGHT := Color(0.87, 0.89, 0.84, 1.0)
const TEXT_DIM := Color(0.55, 0.61, 0.52, 1.0)
const LOCKED := Color(0.40, 0.42, 0.40, 1.0)
const AMBER := Color(1.0, 0.72, 0.20, 1.0)
const RED := Color(0.94, 0.18, 0.16, 1.0)
const PIP_OFF := Color(0.13, 0.14, 0.13, 1.0)

## Layout is authored at this size and scaled to the viewport.
const DESIGN := Vector2(1280.0, 720.0)

static var _font: SystemFont = null
static var _tex_cache: Dictionary = {}


static func font() -> SystemFont:
	if _font == null:
		_font = SystemFont.new()
		_font.font_names = PackedStringArray([
			"DIN Condensed", "Avenir Next Condensed", "Arial Narrow",
			"Bank Gothic", "Eurostile Extended", "Helvetica Neue",
		])
		_font.font_weight = 750
		_font.font_stretch = 84
	return _font


static func tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _tex_cache[path]


## Nine-patch StyleBox from one of the generated plates.
static func plate(file: String, margin: float, content: float = -1.0) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = tex(ART + file)
	box.set_texture_margin_all(margin)
	box.set_content_margin_all(margin if content < 0.0 else content)
	return box


static func flat(bg: Color, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	return box


static func label(text: String, size: int, color: Color = TEXT_LIGHT,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func icon(file: String, size: float, tint: Color = Color.WHITE) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex(ICONS + file) if not file.begins_with("res://") else tex(file)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(size, size)
	r.modulate = tint
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Riveted action button. green = the buy/confirm action (INSTALL, RETRY).
static func action_button(text: String, green: bool, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", int(size.y * 0.44))
	var face := "button_green.png" if green else "button_steel.png"
	var normal := plate(face, 30.0, 8.0)
	var hover := normal.duplicate() as StyleBoxTexture
	hover.modulate_color = Color(1.12, 1.12, 1.12)
	var pressed := normal.duplicate() as StyleBoxTexture
	pressed.modulate_color = Color(0.82, 0.82, 0.82)
	var disabled := plate("button_steel.png", 30.0, 8.0)
	disabled.modulate_color = Color(0.55, 0.55, 0.55)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ink := Color(0.03, 0.08, 0.02) if green else TEXT_LIGHT
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(key, ink)
	b.add_theme_color_override("font_disabled_color", LOCKED)
	return b


## Row plate: steel when idle, green-barred when selected. Children are laid
## out by the caller inside an HBox placed on top (mouse passes through).
static func row_button(height: float) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0.0, height)
	b.focus_mode = Control.FOCUS_NONE
	b.toggle_mode = false
	set_row_selected(b, false)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


static func set_row_selected(b: Button, selected: bool) -> void:
	var normal := plate("row_green.png" if selected else "row_steel.png", 14.0, 0.0)
	var hover := normal.duplicate() as StyleBoxTexture
	hover.modulate_color = Color(1.15, 1.15, 1.15)
	for key in ["normal", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(key, normal)
	b.add_theme_stylebox_override("hover", hover)


## HBox filling a row button, inset past the lamp bar and rivets.
static func row_content(row: Button, left: float = 44.0, right: float = 26.0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = left
	h.offset_right = -right
	h.add_theme_constant_override("separation", 14)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(h)
	return h


static func well(pad: float = 14.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", plate("well_dark.png", 20.0, pad))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## rank lit pips out of `count`; `next` outlines the rank INSTALL would add.
static func pips(rank: int, count: int, pip: Vector2, locked: bool = false, show_next: bool = false) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", int(pip.x * 0.28))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in count:
		var p := Panel.new()
		p.custom_minimum_size = pip
		p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var box: StyleBoxFlat
		if locked:
			box = flat(Color(0.09, 0.09, 0.09), Color(0.22, 0.22, 0.22), 1)
		elif i < rank:
			box = flat(GREEN, Color(0.75, 1.0, 0.6), 1)
			box.shadow_color = Color(GREEN.r, GREEN.g, GREEN.b, 0.45)
			box.shadow_size = 4
		elif show_next and i == rank:
			box = flat(PIP_OFF, GREEN_SOFT, 2)
		else:
			box = flat(PIP_OFF, Color(0.28, 0.30, 0.28), 1)
		p.add_theme_stylebox_override("panel", box)
		h.add_child(p)
	return h


static func spacer(min_w: float = 0.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(min_w, 0.0)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func money(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-$" if amount < 0 else "$") + digits + out


static func fit_stage(stage: Control, viewport_size: Vector2, fill: float = 1.0) -> void:
	var s := minf(viewport_size.x / DESIGN.x, viewport_size.y / DESIGN.y) * fill
	stage.size = DESIGN
	stage.scale = Vector2(s, s)
	stage.position = (viewport_size - DESIGN * s) * 0.5
