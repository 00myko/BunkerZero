@tool
extends Node3D

## Runtime collision and lighting support for the Living Quarters.
## Encounter ownership now lives in Room 1 Infested Living Quarters.tscn.

const GENERATED := "__ROOM2_GENERATED__"
const ART_ANCHOR_SCRIPT = preload("res://scripts/art_anchor.gd")
const WALL_SCENE: PackedScene = preload("res://assets/room_1/Wall Panel.glb")

const ROOM_WIDTH := 14.0
const ROOM_DEPTH := 18.0
const ROOM_HEIGHT := 3.6
const NORTH_Z := -4.5
const SOUTH_Z := NORTH_Z - ROOM_DEPTH
const CENTER_Z := (NORTH_Z + SOUTH_Z) * 0.5

func _ready() -> void:
	add_to_group("room2_builder")
	call_deferred("_build")

func _build() -> void:
	var old := get_node_or_null(GENERATED)
	if old != null:
		old.free()

	var root := Node3D.new()
	root.name = GENERATED
	root.set_meta("generated_room2", true)
	add_child(root)

	_build_invisible_floor(root)
	_build_boundary_colliders(root)

	# V64.2: Do NOT generate the large outer visual wall shell.
	# The room's physics boundary remains active and all manually placed
	# Living Quarters art/props remain untouched.
	# _build_walls(root)

	_build_lighting(root)

func _build_invisible_floor(root: Node3D) -> void:
	# Physics only. No visible floor mesh is created in Room 02.
	var body := StaticBody3D.new()
	body.name = "Room02_InvisibleFloor"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector3(0.0, -0.12, CENTER_Z)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(ROOM_WIDTH, 0.24, ROOM_DEPTH)
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)

func _add_wall_collider(root: Node3D, node_name: String, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)

func _build_boundary_colliders(root: Node3D) -> void:
	# V64.1: the perimeter derives from ROOM_WIDTH / ROOM_DEPTH, so changing the
	# room size cannot leave old invisible collision walls behind.
	var wall_h := 3.8
	var thick := 0.30
	var doorway_width := 5.0

	# Combat Room 1 now exits into the Cafeteria through a centered south blast
	# door. Keep the structural boundary on both sides without boxing the doorway.
	var south_doorway_width := 4.2
	var south_side_width := (ROOM_WIDTH - south_doorway_width) * 0.5
	var south_side_center := south_doorway_width * 0.5 + south_side_width * 0.5
	_add_wall_collider(
		root, "SouthBoundaryLeft",
		Vector3(-south_side_center, wall_h * 0.5, SOUTH_Z),
		Vector3(south_side_width, wall_h, thick)
	)
	_add_wall_collider(
		root, "SouthBoundaryRight",
		Vector3(south_side_center, wall_h * 0.5, SOUTH_Z),
		Vector3(south_side_width, wall_h, thick)
	)
	_add_wall_collider(
		root, "WestBoundary",
		Vector3(-ROOM_WIDTH * 0.5, wall_h * 0.5, CENTER_Z),
		Vector3(thick, wall_h, ROOM_DEPTH)
	)
	_add_wall_collider(
		root, "EastBoundary",
		Vector3(ROOM_WIDTH * 0.5, wall_h * 0.5, CENTER_Z),
		Vector3(thick, wall_h, ROOM_DEPTH)
	)

	var side_width := (ROOM_WIDTH - doorway_width) * 0.5
	var side_center := doorway_width * 0.5 + side_width * 0.5
	_add_wall_collider(
		root, "NorthBoundaryLeft",
		Vector3(-side_center, wall_h * 0.5, NORTH_Z),
		Vector3(side_width, wall_h, thick)
	)
	_add_wall_collider(
		root, "NorthBoundaryRight",
		Vector3(side_center, wall_h * 0.5, NORTH_Z),
		Vector3(side_width, wall_h, thick)
	)

func _build_walls(root: Node3D) -> void:
	# V64.1: 14 m wide x 18 m deep first combat room.
	# NORTH_Z remains -4.5, so the existing Room 01 doorway connection does not move.
	#
	# Physics boundaries are still generated separately from ROOM_WIDTH/ROOM_DEPTH.

	# North wall around the centered 5 m doorway.
	# Two 4 m panels per side give a little harmless visual overlap at the corners.
	for x in [-5.5, -3.25, 3.25, 5.5]:
		_add_art_anchor(
			root, "NorthWall_%s" % str(x), WALL_SCENE,
			Vector3(x, -0.17, NORTH_Z - 0.06),
			Vector3(0, 180, 0), 4.0
		)

	# South wall: four panels across the 14 m width, slightly overlapping.
	for x in [-5.25, -1.75, 1.75, 5.25]:
		_add_art_anchor(
			root, "SouthWall_%s" % str(x), WALL_SCENE,
			Vector3(x, -0.17, SOUTH_Z),
			Vector3.ZERO, 4.0
		)

	# Side walls: five panels cover the 18 m room depth.
	for z in [-6.5, -10.5, -14.5, -18.5, -21.5]:
		_add_art_anchor(
			root, "WestWall_%s" % str(z), WALL_SCENE,
			Vector3(-ROOM_WIDTH * 0.5, -0.17, z),
			Vector3(0, 90, 0), 4.0
		)
		_add_art_anchor(
			root, "EastWall_%s" % str(z), WALL_SCENE,
			Vector3(ROOM_WIDTH * 0.5, -0.17, z),
			Vector3(0, -90, 0), 4.0
		)

func _build_lighting(root: Node3D) -> void:
	# V64.1 lighting fitted to the 14 x 18 m room.
	# Three depth zones keep the longer room readable, while all lights stay
	# comfortably inside the +/-7 m side boundaries.
	var key_positions: Array[Vector3] = [
		Vector3(-3.8, 5.1, -8.0),
		Vector3(3.8, 5.1, -8.0),
		Vector3(-3.8, 5.1, -13.5),
		Vector3(3.8, 5.1, -13.5),
		Vector3(-3.8, 5.1, -19.0),
		Vector3(3.8, 5.1, -19.0),
	]
	for i in range(key_positions.size()):
		var key := SpotLight3D.new()
		key.name = "Room02_Key_%02d" % i
		key.position = key_positions[i]
		key.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		key.light_color = Color(0.72, 0.80, 0.91)
		key.light_energy = 1.40
		key.spot_range = 8.8
		key.spot_angle = 68.0
		key.spot_angle_attenuation = 0.62
		key.light_specular = 0.34
		key.shadow_enabled = (i == 4)
		root.add_child(key)

	var side_fills: Array[Vector3] = [
		Vector3(-5.4, 2.2, -8.5),
		Vector3(5.4, 2.2, -8.5),
		Vector3(-5.4, 2.2, -14.0),
		Vector3(5.4, 2.2, -14.0),
		Vector3(-5.4, 2.2, -19.5),
		Vector3(5.4, 2.2, -19.5),
	]
	for i in range(side_fills.size()):
		var fill := OmniLight3D.new()
		fill.name = "Room02_SideFill_%02d" % i
		fill.position = side_fills[i]
		fill.light_color = Color(0.56, 0.64, 0.75)
		fill.light_energy = 0.66
		fill.omni_range = 5.8
		fill.light_specular = 0.15
		fill.shadow_enabled = false
		root.add_child(fill)

	var center_fill := OmniLight3D.new()
	center_fill.name = "Room02_ReadabilityLift"
	center_fill.position = Vector3(0.0, 2.4, CENTER_Z)
	center_fill.light_color = Color(0.61, 0.68, 0.77)
	center_fill.light_energy = 0.50
	center_fill.omni_range = 9.4
	center_fill.light_specular = 0.10
	center_fill.shadow_enabled = false
	root.add_child(center_fill)

	var accents: Array[Vector3] = [
		Vector3(-5.5, 1.9, -11.0),
		Vector3(5.5, 1.9, -18.0),
	]
	for i in range(accents.size()):
		var accent := OmniLight3D.new()
		accent.name = "Room02_WarmAccent_%02d" % i
		accent.position = accents[i]
		accent.light_color = Color(1.0, 0.31, 0.13)
		accent.light_energy = 0.29
		accent.omni_range = 4.5
		accent.light_specular = 0.19
		accent.shadow_enabled = false
		root.add_child(accent)

	var entrance := SpotLight3D.new()
	entrance.name = "Room02_EntranceFill"
	entrance.position = Vector3(0.0, 3.0, NORTH_Z - 0.1)
	entrance.rotation_degrees = Vector3(-12.0, 180.0, 0.0)
	entrance.light_color = Color(0.64, 0.73, 0.88)
	entrance.light_energy = 1.05
	entrance.spot_range = 8.8
	entrance.spot_angle = 58.0
	entrance.spot_angle_attenuation = 0.68
	entrance.light_specular = 0.24
	entrance.shadow_enabled = false
	root.add_child(entrance)

func _add_art_anchor(parent: Node3D, node_name: String, scene: PackedScene, pos: Vector3, rot: Vector3, target_size: float, fit_height: bool = false, model_rot: Vector3 = Vector3.ZERO) -> void:
	var anchor := Node3D.new()
	anchor.name = node_name
	anchor.position = pos
	anchor.rotation_degrees = rot
	anchor.set_script(ART_ANCHOR_SCRIPT)
	anchor.set("source_scene", scene)
	anchor.set("target_size_meters", target_size)
	anchor.set("fit_height", fit_height)
	anchor.set("rotate_degrees", model_rot)
	parent.add_child(anchor)
