class_name HudArt
extends RefCounted

## Shared lookup for HUD control art so the gameplay HUD, the settings preview
## and the chip row all draw the same pictures. Trimmed textures are cached,
## because trimming walks every pixel.

const ICON_DIR := "res://assets/Game UI Art/Settings/"
const TEXTURE_ART := {
	"joystick": "res://assets/Game UI Art/V52/JoystickBase.png",
	"joystick_knob": "res://assets/Game UI Art/V52/JoystickKnob.png",
	"shoot": "res://assets/Game UI Art/V52/Shoot.png",
	"jump": "res://assets/Game UI Art/V52/Jump Button.png",
	"sprint": "res://assets/Game UI Art/V52/Sprint Button.png",
	"pause": "res://assets/Game UI Art/V52/Pause Button.png",
}

static var _cache: Dictionary = {}


## Authored painted art for the original controls; null for the newer round
## buttons, which HudRoundButton draws around an icon.
static func control_texture(control_id: String) -> Texture2D:
	if not TEXTURE_ART.has(control_id):
		return null
	var path: String = TEXTURE_ART[control_id]
	if _cache.has(path):
		return _cache[path]
	var loaded: Texture2D = null
	if ResourceLoader.exists(path):
		loaded = trim_texture(load(path) as Texture2D)
	_cache[path] = loaded
	return loaded


static func icon(icon_id: String) -> Texture2D:
	var path := ICON_DIR + "icon_%s.svg" % icon_id
	if _cache.has(path):
		return _cache[path]
	var loaded: Texture2D = null
	if ResourceLoader.exists(path):
		loaded = load(path) as Texture2D
	_cache[path] = loaded
	return loaded


static func trim_texture(texture: Texture2D) -> Texture2D:
	# Generated UI PNGs carry wide transparent margins. Crop to painted pixels so
	# the Control rect matches the visible art.
	if texture == null:
		return null
	var image: Image = null
	var source_path := texture.resource_path
	if source_path.begins_with("res://"):
		image = Image.load_from_file(ProjectSettings.globalize_path(source_path))
	if image == null or image.is_empty():
		image = texture.get_image()
	if image == null or image.is_empty():
		return texture
	if image.is_compressed():
		image.decompress()
	var used := image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return texture
	var halo: int = maxi(2, int(ceil(maxi(used.size.x, used.size.y) * 0.015)))
	used = used.grow(halo).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	return ImageTexture.create_from_image(image.get_region(used))
