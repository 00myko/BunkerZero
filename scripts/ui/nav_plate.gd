class_name NavPlate
extends NinePatchRect

## The riveted Pause_Button.webp bar shared by every menu button (pause rail,
## settings rail, BACK, category tabs). Idle and highlighted use the SAME
## texture and the SAME rect: highlighting lights the bar's own left lamp and
## washes its inner face green in place, so the outline never changes shape.
## (Pause_Button_Selected.webp is a different silhouette and is not used.)

const TEXTURE_PATH := "res://assets/Game UI Art/Pause Menu/Pause_Button.webp"
## Opaque rows of the 640x128 source; the rest is transparent padding.
const REGION := Rect2(0.0, 16.0, 640.0, 104.0)
## Riveted ends stay unstretched.
const MARGIN_LEFT := 44
const MARGIN_RIGHT := 76
const MARGIN_Y := 24
## Painted lamp slot and inner face, in REGION coordinates (measured on the art).
const LAMP_RECT := Rect2(15.0, 30.0, 8.0, 36.0)
const FACE_LEFT := 35.0
const FACE_RIGHT_INSET := 34.0
const FACE_TOP := 19.0
const FACE_BOTTOM_INSET := 28.0

const GREEN := Color(0.38, 1.0, 0.20, 1.0)
const GREEN_SOFT := Color(0.52, 0.88, 0.38, 1.0)
const TEXT_LIGHT := Color(0.87, 0.89, 0.84, 1.0)

static var _atlas: AtlasTexture = null

var lit := false:
	set(value):
		lit = value
		if _lamp != null:
			_lamp.visible = lit
			_wash.visible = lit

var _lamp: Panel = null
var _wash: Panel = null


static func plate_texture() -> Texture2D:
	if _atlas == null:
		var source := load(TEXTURE_PATH) as Texture2D
		if source == null:
			return null
		_atlas = AtlasTexture.new()
		_atlas.atlas = source
		_atlas.region = REGION
	return _atlas


func _init() -> void:
	name = "Plate"
	texture = plate_texture()
	patch_margin_left = MARGIN_LEFT
	patch_margin_right = MARGIN_RIGHT
	patch_margin_top = MARGIN_Y
	patch_margin_bottom = MARGIN_Y
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_wash = Panel.new()
	_wash.name = "LitFace"
	_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := StyleBoxFlat.new()
	face.bg_color = Color(GREEN.r, GREEN.g, GREEN.b, 0.10)
	face.border_color = Color(GREEN.r, GREEN.g, GREEN.b, 0.62)
	face.set_border_width_all(2)
	# corner_detail 1 draws a straight bevel, matching the plate's chamfer.
	face.set_corner_radius_all(7)
	face.corner_detail = 1
	_wash.add_theme_stylebox_override("panel", face)
	_wash.visible = false
	add_child(_wash)

	_lamp = Panel.new()
	_lamp.name = "LitLamp"
	_lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lamp := StyleBoxFlat.new()
	lamp.bg_color = GREEN
	lamp.set_corner_radius_all(3)
	lamp.shadow_color = Color(GREEN.r, GREEN.g, GREEN.b, 0.55)
	lamp.shadow_size = 5
	_lamp.add_theme_stylebox_override("panel", lamp)
	_lamp.position = LAMP_RECT.position
	_lamp.size = LAMP_RECT.size
	_lamp.visible = false
	add_child(_lamp)
	resized.connect(_layout_face)


## Fit the plate to a row: scaled so the riveted ends keep their proportion
## while the middle stretches to the row width.
func fit(row_size: Vector2) -> void:
	# Buttons report a zero size until their container lays them out; a zero
	# height would give an infinite plate scale.
	if row_size.x <= 0.0 or row_size.y <= 0.0:
		return
	var s := row_size.y / REGION.size.y
	scale = Vector2(s, s)
	position = Vector2.ZERO
	size = Vector2(row_size.x / s, REGION.size.y)
	# resized is not emitted before the plate is in the tree; lay out now.
	_layout_face()


func _layout_face() -> void:
	_wash.position = Vector2(FACE_LEFT, FACE_TOP)
	_wash.size = Vector2(
		maxf(size.x - FACE_LEFT - FACE_RIGHT_INSET, 0.0),
		maxf(size.y - FACE_TOP - FACE_BOTTOM_INSET, 0.0)
	)


## Plate that follows `button`'s rect and draws behind its text. For buttons
## without a separate icon node (category tabs).
static func attach_behind(button: Control) -> NavPlate:
	var plate := NavPlate.new()
	plate.show_behind_parent = true
	button.add_child(plate)
	var refit := func() -> void: plate.fit(button.size)
	button.resized.connect(refit)
	refit.call()
	return plate
