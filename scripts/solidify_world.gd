extends Node

## Collision builder for imported GLB/GLTF environment art ONLY.
## V42 keeps the existing player/world box collision pass and adds a second,
## zombie-only full-height blocker layer around bulky props. This prevents the
## zombie CharacterBody from climbing onto bunk beds, lockers, crates, etc.

const AUTO_BODY_NAME := "__AUTO_GLB_SOLID_BODY__"
const ZOMBIE_BLOCKER_NAME := "__AUTO_ZOMBIE_BLOCKER__"
const MIN_THICKNESS := 0.035
const MAX_REASONABLE_AXIS := 80.0
const ZOMBIE_BLOCKER_LAYER := 16
const ZOMBIE_BLOCKER_MIN_HEIGHT := 2.5
const ZOMBIE_BLOCKER_MARGIN := 0.18

func _ready() -> void:
	_build_glb_collisions()
	for _i in range(8):
		await get_tree().process_frame
	_build_glb_collisions()

func _build_glb_collisions() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var added := 0
	var skipped := 0
	var rejected_outliers := 0
	var zombie_blockers_added := 0

	for node in scene.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue

		var glb_root := _find_glb_root(mesh_instance)
		if _should_skip_glb(mesh_instance, glb_root):
			skipped += 1
			continue

		var aabb := mesh_instance.get_aabb()
		if aabb.size.length_squared() <= 0.000001:
			continue
		# Thin floors can be very wide. Only reject a mesh that is huge on every axis.
		if aabb.size.x > MAX_REASONABLE_AXIS and aabb.size.y > MAX_REASONABLE_AXIS and aabb.size.z > MAX_REASONABLE_AXIS:
			rejected_outliers += 1
			print("SKIP oversized GLB collider: %s  size=%s" % [mesh_instance.get_path(), aabb.size])
			continue

		if mesh_instance.get_node_or_null(AUTO_BODY_NAME) == null and not _is_non_colliding_decor(glb_root):
			var safe_size := Vector3(
				maxf(aabb.size.x, MIN_THICKNESS),
				maxf(aabb.size.y, MIN_THICKNESS),
				maxf(aabb.size.z, MIN_THICKNESS)
			)
			var box_center := aabb.position + aabb.size * 0.5
			if _is_floor_glb(glb_root):
				var floor_box := _thin_floor_box(mesh_instance, aabb)
				safe_size = floor_box[0]
				box_center = floor_box[1]
			elif _is_wall_glb(glb_root):
				# Thin imported wall panels let the player clip halfway through
				# the visible mesh. Keep the authored height, but give the
				# thinnest horizontal axis a usable thickness.
				const WALL_MIN_THICKNESS := 0.28
				if safe_size.x <= safe_size.z:
					safe_size.x = maxf(safe_size.x, WALL_MIN_THICKNESS)
				else:
					safe_size.z = maxf(safe_size.z, WALL_MIN_THICKNESS)

			var body := StaticBody3D.new()
			body.name = AUTO_BODY_NAME
			body.collision_layer = 1
			body.collision_mask = 0

			var collision := CollisionShape3D.new()
			collision.name = "CollisionShape3D"
			var box := BoxShape3D.new()
			box.size = safe_size
			collision.shape = box
			collision.position = box_center

			body.add_child(collision)
			mesh_instance.add_child(body)
			added += 1

		# Bulky props receive a tall invisible box on physics layer 16. The player
		# ignores this layer; zombies use it both for pathfinding and physical blocking.
		if _needs_zombie_blocker(glb_root) and mesh_instance.get_node_or_null(ZOMBIE_BLOCKER_NAME) == null:
			var blocker := StaticBody3D.new()
			blocker.name = ZOMBIE_BLOCKER_NAME
			blocker.collision_layer = ZOMBIE_BLOCKER_LAYER
			blocker.collision_mask = 0

			var blocker_collision := CollisionShape3D.new()
			blocker_collision.name = "CollisionShape3D"
			var blocker_box := BoxShape3D.new()
			blocker_box.size = Vector3(
				maxf(aabb.size.x + ZOMBIE_BLOCKER_MARGIN, MIN_THICKNESS),
				maxf(aabb.size.y, ZOMBIE_BLOCKER_MIN_HEIGHT),
				maxf(aabb.size.z + ZOMBIE_BLOCKER_MARGIN, MIN_THICKNESS)
			)
			blocker_collision.shape = blocker_box
			blocker_collision.position = Vector3(
				aabb.position.x + aabb.size.x * 0.5,
				aabb.position.y + aabb.size.y * 0.5,
				aabb.position.z + aabb.size.z * 0.5
			)
			blocker.add_child(blocker_collision)
			mesh_instance.add_child(blocker)
			zombie_blockers_added += 1

	print("GLB BOX collision: added %d, zombie blockers %d, skipped %d, rejected oversized %d" % [added, zombie_blockers_added, skipped, rejected_outliers])

func _find_glb_root(node: Node) -> Node:
	var current: Node = node
	while current != null:
		var source_path := current.scene_file_path.to_lower()
		if source_path.ends_with(".glb") or source_path.ends_with(".gltf"):
			return current
		current = current.get_parent()
	return null

func _is_floor_glb(glb_root: Node) -> bool:
	if glb_root == null:
		return false
	var source_path := glb_root.scene_file_path.to_lower()
	return "floor" in source_path or "flooring" in source_path


func _is_wall_glb(glb_root: Node) -> bool:
	if glb_root == null:
		return false
	var source_path := glb_root.scene_file_path.to_lower()
	return "kitchen walls" in source_path


func _thin_floor_box(mesh_instance: MeshInstance3D, aabb: AABB) -> Array:
	# Tile GLBs are rotated onto the ground. Their full AABB becomes a thick
	# invisible slab you have to jump onto. Flatten the world-up axis and keep
	# the collider on the lowest face so it meets the hub floor.
	const FLOOR_THICKNESS := 0.10
	var local_up := mesh_instance.global_transform.basis.inverse() * Vector3.UP
	var axis := 1
	var best := absf(local_up.y)
	if absf(local_up.x) > best:
		axis = 0
		best = absf(local_up.x)
	if absf(local_up.z) > best:
		axis = 2
	var size := Vector3(
		maxf(aabb.size.x, MIN_THICKNESS),
		maxf(aabb.size.y, MIN_THICKNESS),
		maxf(aabb.size.z, MIN_THICKNESS)
	)
	var center := aabb.position + aabb.size * 0.5
	var axis_sign := 1.0
	match axis:
		0:
			axis_sign = signf(local_up.x)
		1:
			axis_sign = signf(local_up.y)
		2:
			axis_sign = signf(local_up.z)
	if is_zero_approx(axis_sign):
		axis_sign = 1.0
	center[axis] = center[axis] - axis_sign * (size[axis] * 0.5 - FLOOR_THICKNESS * 0.5)
	size[axis] = FLOOR_THICKNESS
	return [size, center]


func _is_non_colliding_decor(glb_root: Node) -> bool:
	if glb_root == null:
		return false
	var source_path := glb_root.scene_file_path.to_lower()
	for skip_token in ["ceiling", "light", "lamp", "decal"]:
		if source_path.contains(skip_token):
			return true
	return false

func _needs_zombie_blocker(glb_root: Node) -> bool:
	if glb_root == null:
		return false
	var source_path := glb_root.scene_file_path.to_lower()
	# Only solid, floor-level props. Wall-sized 2.5 m boxes were eating every
	# spawn cell and the horde never appeared.
	var keywords := [
		"bunk", "bed", "locker", "/furniture/", "crate", "chest", "box",
		"cabinet", "filing", "shelf", "table", "worktable", "weapon rack",
		"weapon display", "safe", "storage rack", "rail", "bench", "desk",
		"counter", "cup", "tray", "chair", "stool"
	]
	for keyword in keywords:
		if source_path.contains(keyword):
			return true
	return false

func _should_skip_glb(mesh_instance: MeshInstance3D, glb_root: Node) -> bool:
	# Streamed rooms may be parked or briefly hidden. They still need floors and
	# prop boxes so the player and zombies cannot walk through solid art.
	var source_path := ""
	if glb_root != null:
		source_path = glb_root.scene_file_path.to_lower()

	# The animated blast door has its own temporary doorway blocker managed by
	# room_transition_door.gd. Boxing its frame/leaf meshes creates a permanent
	# invisible wall across the opening after the visual panels move apart.
	if "animated blast door" in source_path or "/bunker door/" in source_path:
		return true
	if "/weapons/" in source_path:
		return true

	var ancestor: Node = mesh_instance
	while ancestor != null:
		# Room 02 already has an exact code-generated perimeter collider. Do not
		# add another AABB box around its visual wall GLBs; those duplicate boxes
		# were the source of stray/invisible collision after resizing the room.
		if ancestor.has_meta("generated_room2"):
			return true
		# Entry-wall kitchen pieces sit on the Room 1 / Room 2 seam. Boxing
		# them closes the opening with an invisible wall.
		if ancestor.has_meta("doorway_wall"):
			return true
		# Overhead services, hanging fixtures and grow beds that author their
		# own exact collision opt out of the automatic AABB boxes. Ceiling-hung
		# boxes would otherwise poison the combat controllers' floor raycasts.
		if ancestor.has_meta("no_auto_collision"):
			return true
		var ancestor_name := String(ancestor.name)
		if ancestor_name.begins_with("WallPanel_S"):
			return true
		if ancestor is CharacterBody3D or ancestor is Area3D:
			return true
		var lower_name := ancestor_name.to_lower()
		if "viewmodel" in lower_name or "weapon_visual" in lower_name:
			return true
		ancestor = ancestor.get_parent()

	return false
