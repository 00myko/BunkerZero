class_name WeaponChoiceOverlay
extends CanvasLayer

## Pauses gameplay and lets the player pick from the guns offered this room.
## The guns themselves are the buttons — no card boxes.

signal weapon_chosen(weapon_id: String)

const WEAPON_BLURBS := {
	"pistol": "8-ROUND MAG\nHARDER HITS\nSEMI-AUTO",
	"uzi": "24-ROUND MAG\nFASTEST SPRAY\nLIGHT HITS",
	"shotgun": "6-SHELL TUBE\nHEAVY PELLET BLAST\nSLOW PUMP",
	"sawnoffs": "2 SHELLS\nWIDE PANIC BLAST\nBREAK-RELOAD",
	"crossbow": "ONE BOLT\nHEADSHOTS DELETE\nSLOW RECOCK",
	"knife": "NO AMMO\nCLOSE RANGE\nFAST SLASH",
	"minigun": "SPIN-UP\n100-ROUND BOX\nHEAVY / NO ADS",
	"smg": "28-ROUND MAG\nHARDER AUTO\nSTEADY RECOIL",
	"grenade_launcher": "6-ROUND CYLINDER\nSPLASH DAMAGE\nLOW RESERVE",
	"lmg": "50-ROUND BOX\nHEAVY AUTO\nLONG RELOAD",
	"sawnoff": "2 SHELLS\nTIGHT HEAVY BLAST\nBREAK-RELOAD",
}
const WEAPON_IMAGES := {
	"pistol": "res://assets/UI/weapon_pistol.png",
	"uzi": "res://assets/UI/weapon_uzi.png",
	"shotgun": "res://assets/UI/weapon_shotgun.png",
	"sawnoffs": "res://assets/UI/weapon_sawnoffs.png",
	"crossbow": "res://assets/UI/weapon_crossbow.png",
	"knife": "res://assets/UI/weapon_knife.png",
	"minigun": "res://assets/UI/weapon_minigun.png",
	"smg": "res://assets/UI/weapon_smg.png",
	"grenade_launcher": "res://assets/UI/weapon_grenade_launcher.png",
	"lmg": "res://assets/UI/weapon_lmg.png",
	"sawnoff": "res://assets/UI/weapon_sawnoff.png",
}


func present(weapon_ids: Array, room_label: String, hint_text: String = "", captions: Dictionary = {}) -> void:
	_build_screen(
		"CHOOSE YOUR WEAPON",
		_combine_subtitles(room_label, hint_text),
		weapon_ids,
		captions
	)


func present_replace(owned_ids: Array, incoming_id: String, room_label: String) -> void:
	var captions := {}
	if owned_ids.size() > 0:
		captions[String(owned_ids[0])] = "PRIMARY"
	if owned_ids.size() > 1:
		captions[String(owned_ids[1])] = "SECONDARY"
	_build_screen(
		"REPLACE WHICH GUN?",
		_combine_subtitles(room_label, "NEW WEAPON: %s" % String(incoming_id).to_upper()),
		owned_ids,
		captions
	)


func _combine_subtitles(room_label: String, hint_text: String) -> String:
	var lines: PackedStringArray = []
	if not room_label.is_empty():
		lines.append(room_label)
	if not hint_text.is_empty():
		lines.append(hint_text)
	return "\n".join(lines)


func _build_screen(title_text: String, subtitle_text: String, weapon_ids: Array, captions: Dictionary) -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	for child in get_children():
		child.queue_free()

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.015, 0.02, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 22)
	center.add_child(column)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.93, 0.95, 0.98))
	column.add_child(title)

	if not subtitle_text.is_empty():
		var subtitle := Label.new()
		subtitle.text = subtitle_text
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.add_theme_font_size_override("font_size", 18)
		subtitle.add_theme_color_override("font_color", Color(0.70, 0.76, 0.82))
		column.add_child(subtitle)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 56 if weapon_ids.size() >= 3 else 72)
	column.add_child(row)

	for weapon_id in weapon_ids:
		var id := String(weapon_id)
		row.add_child(_make_weapon_choice(id, String(captions.get(id, ""))))

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _make_weapon_choice(weapon_id: String, caption: String = "") -> Control:
	var button := Button.new()
	button.flat = true
	button.custom_minimum_size = Vector2(440, 340)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, empty)
	button.pressed.connect(_on_weapon_pressed.bind(weapon_id))

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)

	var image := TextureRect.new()
	image.name = "WeaponImage"
	image.custom_minimum_size = Vector2(420, 230)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture = _weapon_texture(weapon_id)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(image)

	if not caption.is_empty():
		var slot := Label.new()
		slot.text = caption
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_theme_font_size_override("font_size", 16)
		slot.add_theme_color_override("font_color", Color(0.78, 0.62, 0.34))
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(slot)

	var blurb := Label.new()
	blurb.text = String(WEAPON_BLURBS.get(weapon_id, ""))
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blurb.add_theme_font_size_override("font_size", 18)
	blurb.add_theme_color_override("font_color", Color(0.86, 0.89, 0.92))
	blurb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(blurb)

	button.mouse_entered.connect(_set_choice_hover.bind(image, true))
	button.mouse_exited.connect(_set_choice_hover.bind(image, false))
	return button


func _set_choice_hover(image: TextureRect, hovered: bool) -> void:
	if image == null:
		return
	image.modulate = Color(1.12, 1.12, 1.12) if hovered else Color.WHITE


func _weapon_texture(weapon_id: String) -> Texture2D:
	var path := String(WEAPON_IMAGES.get(weapon_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _on_weapon_pressed(weapon_id: String) -> void:
	weapon_chosen.emit(weapon_id)
	queue_free()
