class_name HudRoundButton
extends Control

## One touch control face. Used by the gameplay HUD for the round action
## buttons (aim, reload, crouch, melee, interact) and by the settings preview as
## a 1:1 stand-in for every control. When `art` is set it draws the authored
## painted texture; otherwise it draws a riveted metal disc around `icon`.

const RIM := Color(0.36, 0.38, 0.40, 1.0)
const RIM_DARK := Color(0.06, 0.065, 0.07, 1.0)
const FACE := Color(0.11, 0.12, 0.13, 0.92)
const FACE_INNER := Color(0.16, 0.17, 0.18, 0.92)
const ACTIVE := Color(0.94, 0.18, 0.16, 1.0)

var art: Texture2D = null:
	set(value):
		art = value
		queue_redraw()
var knob: Texture2D = null:
	set(value):
		knob = value
		queue_redraw()
var icon: Texture2D = null:
	set(value):
		icon = value
		queue_redraw()
var caption := "":
	set(value):
		caption = value
		queue_redraw()
var show_caption := false:
	set(value):
		show_caption = value
		queue_redraw()
var active := false:
	set(value):
		active = value
		queue_redraw()
var caption_font: Font = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if art != null:
		draw_texture_rect(art, rect, false)
		if knob != null:
			var knob_size := size * (116.0 / 282.0)
			draw_texture_rect(knob, Rect2((size - knob_size) * 0.5, knob_size), false)
	else:
		_draw_disc()
	if show_caption and not caption.is_empty():
		_draw_caption()


func _draw_disc() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	draw_circle(center, radius, RIM_DARK)
	draw_circle(center, radius * 0.94, ACTIVE if active else RIM)
	draw_circle(center, radius * 0.86, RIM_DARK)
	draw_circle(center, radius * 0.82, FACE)
	draw_circle(center + Vector2(0.0, -radius * 0.08), radius * 0.66, FACE_INNER)
	# Four rivets on the rim sell the industrial plate look at any size.
	for i in range(4):
		var angle := PI * 0.25 + TAU * float(i) / 4.0
		draw_circle(center + Vector2(cos(angle), sin(angle)) * radius * 0.90, maxf(radius * 0.035, 1.0), Color(0.55, 0.57, 0.6, 1.0))
	if icon != null:
		var icon_size := Vector2.ONE * radius * 0.95
		draw_texture_rect(
			icon,
			Rect2(center - icon_size * 0.5, icon_size),
			false,
			ACTIVE if active else Color(0.92, 0.93, 0.94, 1.0)
		)


func _draw_caption() -> void:
	var font := caption_font if caption_font != null else get_theme_default_font()
	var font_size := int(clampf(minf(size.x, size.y) * 0.14, 8.0, 22.0))
	var text_size := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var baseline := Vector2((size.x - text_size.x) * 0.5, size.y + font_size * 1.05)
	draw_string_outline(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, maxi(2, font_size / 6), Color(0, 0, 0, 0.85))
	draw_string(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.92, 0.93, 0.94, 1.0))
