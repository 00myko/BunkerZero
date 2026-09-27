class_name PlateUI
extends RefCounted

## Kit for the photo-plate screens (hub upgrade tables, RUN ENDED). Each
## screen is a cleaned reference photo drawn 1:1 on a "stage" in the photo's
## own pixel space; live stencil text, LEDs and hit areas are placed on the
## measured spots. Coordinates everywhere are photo pixels.

const ART := "res://assets/Game UI Art/Upgrade Tables/"
const TITLE_FONT_PATH := "res://assets/fonts/Oswald-Bold.woff"
const BODY_FONT_PATH := "res://assets/fonts/BarlowCondensed-Bold.woff"
const WEAR_SHADER_PATH := "res://shaders/worn_stencil.gdshader"
## Cap height / em of the two faces (measured).
const TITLE_CAP := 0.81
const BODY_CAP := 0.70

const OFF_WHITE := Color(0.87, 0.86, 0.81, 1.0)
const INK := Color(0.07, 0.08, 0.06, 1.0)
const GREEN := Color(0.52, 0.86, 0.20, 1.0)
const GREEN_PALE := Color(0.80, 0.97, 0.62, 1.0)
const AMBER := Color(0.93, 0.66, 0.24, 1.0)
const DIM := Color(0.47, 0.48, 0.46, 1.0)

enum { TITLE, BODY }

static var _fonts: Dictionary = {}
static var _tex: Dictionary = {}
static var _wear: ShaderMaterial = null
static var _wear_light: ShaderMaterial = null


static func font(kind: int) -> Font:
	if not _fonts.has(kind):
		var f := load(TITLE_FONT_PATH if kind == TITLE else BODY_FONT_PATH) as Font
		if f == null:
			var sys := SystemFont.new()
			sys.font_names = PackedStringArray(["DIN Condensed", "Arial Narrow", "Helvetica Neue"])
			sys.font_weight = 750
			sys.font_stretch = 84
			f = sys
		_fonts[kind] = f
	return _fonts[kind]


static func tex(file: String) -> Texture2D:
	var path := file if file.begins_with("res://") else ART + file
	if not _tex.has(path):
		_tex[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _tex[path]


## Worn-paint material; `heavy` for big stencil words, light for small text.
static func wear(heavy: bool = true) -> ShaderMaterial:
	if (_wear if heavy else _wear_light) == null:
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.frequency = 0.06
		noise.fractal_octaves = 4
		var n := NoiseTexture2D.new()
		n.width = 256
		n.height = 256
		n.seamless = true
		n.noise = noise
		for h in [true, false]:
			var m := ShaderMaterial.new()
			m.shader = load(WEAR_SHADER_PATH)
			m.set_shader_parameter("wear", n)
			m.set_shader_parameter("chip", 0.26 if h else 0.16)
			m.set_shader_parameter("wear_scale", 0.02 if h else 0.03)
			if h:
				_wear = m
			else:
				_wear_light = m
	return _wear if heavy else _wear_light


static func font_size(kind: int, cap: float) -> int:
	return maxi(8, int(round(cap / (TITLE_CAP if kind == TITLE else BODY_CAP))))


static func text_width(s: String, kind: int, cap: float) -> float:
	return font(kind).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size(kind, cap)).x


## Label whose capitals span cap_top..cap_top+cap. x is the left edge, centre
## or right edge depending on `align`. `max_w` shrinks the text to fit.
static func text(parent: Node, s: String, kind: int, cap: float, x: float, cap_top: float,
		color: Color = OFF_WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		max_w: float = 0.0, heavy: bool = false) -> Label:
	var w := text_width(s, kind, cap)
	if max_w > 0.0 and w > max_w:
		cap *= max_w / w
		w = text_width(s, kind, cap)
	var size := font_size(kind, cap)
	var f := font(kind)
	var l := Label.new()
	l.text = s
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_constant_override("line_spacing", 0)
	l.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.material = wear(heavy)
	var real_cap := size * (TITLE_CAP if kind == TITLE else BODY_CAP)
	var top := cap_top - (f.get_ascent(size) - real_cap)
	var left := x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		left = x - w * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		left = x - w
	l.position = Vector2(roundf(left), roundf(top))
	l.size = Vector2(ceilf(w) + 4.0, f.get_height(size))
	parent.add_child(l)
	return l


static func sprite(parent: Node, file: String, rect: Rect2, tint: Color = Color.WHITE) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex(file)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.position = rect.position
	r.size = rect.size
	r.modulate = tint
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


## Photo sprite stretched as a 9-patch (rivets in the margins stay square).
static func plate(parent: Node, file: String, rect: Rect2, margins: Vector4) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = tex(file)
	n.patch_margin_left = int(margins.x)
	n.patch_margin_top = int(margins.y)
	n.patch_margin_right = int(margins.z)
	n.patch_margin_bottom = int(margins.w)
	n.position = rect.position
	n.size = rect.size
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(n)
	return n


static func rect(parent: Node, r: Rect2, color: Color, border: Color = Color.TRANSPARENT, width: int = 0) -> Panel:
	var p := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	p.add_theme_stylebox_override("panel", box)
	p.position = r.position
	p.size = r.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


## Invisible hit area over a baked photo button. Pressing darkens the block;
## disabled greys it. Text is optional (the stencil word on the block).
static func hit(parent: Node, r: Rect2, callback: Callable, word: String = "", cap: float = 0.0,
		color: Color = OFF_WHITE, radius: int = 6) -> Button:
	var b := Button.new()
	b.position = r.position
	b.size = r.size
	b.focus_mode = Control.FOCUS_NONE
	b.flat = false
	var clear := StyleBoxFlat.new()
	clear.bg_color = Color(0, 0, 0, 0)
	clear.set_corner_radius_all(radius)
	var hover := clear.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1, 1, 1, 0.04)
	var down := clear.duplicate() as StyleBoxFlat
	down.bg_color = Color(0, 0, 0, 0.28)
	var off := clear.duplicate() as StyleBoxFlat
	off.bg_color = Color(0, 0, 0, 0.5)
	b.add_theme_stylebox_override("normal", clear)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	b.add_theme_stylebox_override("disabled", off)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if not word.is_empty():
		b.text = word
		b.add_theme_font_override("font", font(TITLE))
		b.add_theme_font_size_override("font_size", font_size(TITLE, cap))
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(key, color)
		b.add_theme_color_override("font_disabled_color", Color(color.r, color.g, color.b, 0.35))
		b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
		b.add_theme_constant_override("shadow_offset_x", 2)
		b.add_theme_constant_override("shadow_offset_y", 2)
		b.material = wear(true)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


static func money(amount: int) -> String:
	return ("-$" if amount < 0 else "$") + str(absi(amount))


## Scale the stage (photo space) to fit the viewport, centred.
static func fit(stage: Control, design: Vector2, viewport_size: Vector2, top_align: bool = false) -> float:
	var s := minf(viewport_size.x / design.x, viewport_size.y / design.y)
	stage.size = design
	stage.scale = Vector2(s, s)
	stage.position = Vector2((viewport_size.x - design.x * s) * 0.5,
		0.0 if top_align else (viewport_size.y - design.y * s) * 0.5)
	return s


static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
