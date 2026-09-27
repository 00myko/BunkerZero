extends Node3D

## Combat Room 2 encounter owner. Room 1 is left untouched. This room starts
## with 10 floor-only zombies, then reinforces 3 at a time after every 3 kills
## until 16 have spawned for the room's lifetime.

const ZOMBIE_SCRIPT = preload("res://scripts/zombie.gd")
const ZOMBIE_CONTAINER_NAME := "EncounterZombies"
# Pacing: an 8-body opening pack (the iOS-safe alive cap), then refills of up
# to three, off-camera, whenever three have died or the floor thins to five.
# Lifetime stays 16.
const INITIAL_SPAWN_COUNT := 8
const MAX_ALIVE := 8
const REINFORCE_COUNT := 3
const REINFORCE_EVERY_KILLS := 3
const REFILL_WHEN_ALIVE_AT_MOST := 5
const REFILL_DELAY_MIN := 0.9
const REFILL_DELAY_MAX := 1.7
const SPAWNS_PER_FRAME := 2
const MAX_LIFETIME_SPAWNS := 16
const ROOM_TWO_HEALTH := 175.0
const ROOM_TWO_DAMAGE := 17.5
const ROOM_TWO_MOVE_SPEED := 2.40
const ROOM_TWO_WANDER_SPEED := 0.72
const ROOM_TWO_ATTACK_SPEED := 1.38
const ROOM_TWO_REWARD := 12
const SAFE_CHECK_MASK := 1 | 16
const SAFE_RADIUS := 0.38
const SAFE_HEIGHT := 1.50
const MIN_ZOMBIE_SPACING := 1.42
const FURNITURE_EXCLUDE_RADIUS := 1.48
const REINFORCE_MIN_PLAYER_DISTANCE := 7.6
const SPAWN_RETRY_LIMIT := 6

# ---- Room 3 exit: raised landing on the kitchen (+X) side of the north wall.
# The scene authors the door ("Door to Room 3") and the staircase GLB; this
# script derives every collider from those two transforms.
const EXIT_DOOR_NAME := "Door to Room 3"
const EXIT_STAIRS_NAME := "Cafeteria Exit Staircase"
const EXIT_DOOR_HALF_WIDTH := 1.25
# Staircase.glb model space (x ±0.33, z ±0.5, landing at the -Z end):
const STAIR_DECK_Y := 0.467          # landing deck top
const STAIR_DECK_FRONT_Z := -0.03     # landing edge / top nosing
const STAIR_BACK_Z := -0.5            # landing back (against the wall)
const STAIR_TOE_Z := 0.545            # nosing line reaches the floor here
const STAIR_FIRST_NOSING := Vector2(0.45, 0.077)
const STAIR_WALK_HALF_X := 0.265      # inside the handrails
const STAIR_RAIL_X := 0.29
const STAIR_RAIL_HALF_T := 0.018
const STAIR_RAIL_TOP := 0.43          # rail height above the walking surface
const STAIR_BACK_RAIL_CUT_Z := -0.455 # back rail spans the doorway: trimmed
# Stairs stay closed until Combat Room 2 is cleared. Zombies are floor-locked
# (zombie.gd stay_on_room_floor), so an open landing would be a free camp spot.
const LOCK_STAIRS_UNTIL_CLEARED := true

var encounter_started := false
var spawning := false
var walk_floor_local_y := -2.3844807
var total_spawned := 0
var total_killed := 0
var kills_since_reinforce := 0
var next_zombie_index := 1
var room_alerted := false
var spawn_retries := 0
var refill_pending := false
var _spawn_aborted := false
var _spawn_rng := RandomNumberGenerator.new()
var stair_exclusion_rect := Rect2()
var stair_gate_body: StaticBody3D = null
var stair_gate_arm: Node3D = null
var stair_gate_open := false


func _ready() -> void:
	add_to_group("cafeteria_controller")
	_spawn_rng.randomize()
	_ensure_stable_floor()
	_ensure_perimeter_walls()
	_ensure_stair_exit()
	if not RunManager.run_stats_changed.is_connected(_refresh_stair_gate):
		RunManager.run_stats_changed.connect(_refresh_stair_gate)


func _visual_tile_surface_local_y() -> float:
	# Tile Floor.glb is a 1 m slab lying on its side. The cafeteria instances
	# rotate it onto the ground, so node.position.y is ~0.78 m above the visible
	# walking surface. Measure the actual mesh top instead of the node origin.
	var surface_y := -INF
	var found := false
	for child in get_children():
		if not (child is Node3D) or not String(child.name).begins_with("Tile Floor"):
			continue
		for node in child.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance := node as MeshInstance3D
			if mesh_instance == null or mesh_instance.mesh == null:
				continue
			var aabb := mesh_instance.get_aabb()
			for corner_index in range(8):
				var world := mesh_instance.global_transform * aabb.get_endpoint(corner_index)
				surface_y = maxf(surface_y, to_local(world).y)
				found = true
	if found:
		return surface_y
	return -3.166


func _ensure_stable_floor() -> void:
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	var found := false
	for child in get_children():
		if child is Node3D and String(child.name).begins_with("Tile Floor"):
			var pos: Vector3 = (child as Node3D).position
			min_x = minf(min_x, pos.x)
			max_x = maxf(max_x, pos.x)
			min_z = minf(min_z, pos.z)
			max_z = maxf(max_z, pos.z)
			found = true
	if not found:
		min_x = -6.08
		max_x = 13.92
		min_z = -4.19
		max_z = 13.81
	var walk_y := _visual_tile_surface_local_y()
	walk_floor_local_y = walk_y
	const FLOOR_HEIGHT := 0.22
	var pad := 1.25
	var body := get_node_or_null("RoomStableFloor") as StaticBody3D
	if body == null:
		body = StaticBody3D.new()
		body.name = "RoomStableFloor"
		body.collision_layer = 1
		body.collision_mask = 0
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
	# The Room 3 exit is a raised landing now. The dining slab stays at floor
	# height and stops at the tiles; the landing and stairs own their colliders.
	body.position = Vector3((min_x + max_x) * 0.5, walk_y - FLOOR_HEIGHT * 0.5, (min_z + max_z) * 0.5)
	var collision := body.get_child(0) as CollisionShape3D
	if collision != null and collision.shape is BoxShape3D:
		(collision.shape as BoxShape3D).size = Vector3(
			max_x - min_x + pad * 2.0,
			FLOOR_HEIGHT,
			max_z - min_z + pad * 2.0
		)
	_refresh_walk_floor_meta()


func _ensure_perimeter_walls() -> void:
	if get_node_or_null("RoomPerimeterWalls") != null:
		return
	var root := Node3D.new()
	root.name = "RoomPerimeterWalls"
	add_child(root)
	# Authored kitchen-wall lines, with a gap only at the Room 1 door.
	var wall_y := walk_floor_local_y + 1.85
	_add_wall_slab(root, "West", Vector3(-6.90, wall_y, 5.90), Vector3(0.42, 3.8, 20.4))
	_add_wall_slab(root, "East", Vector3(15.12, wall_y, 5.90), Vector3(0.42, 3.8, 20.4))
	# North wall is solid except the raised Room 3 door (kitchen side). The
	# old centre seam at x = 2.13 is closed.
	var door_x := _exit_door_local().x
	var gap_l := door_x - EXIT_DOOR_HALF_WIDTH
	var gap_r := door_x + EXIT_DOOR_HALF_WIDTH
	_add_wall_slab(root, "NorthWest", Vector3((-6.90 + gap_l) * 0.5, wall_y, 15.56), Vector3(gap_l + 6.90, 3.8, 0.42))
	_add_wall_slab(root, "NorthEast", Vector3((gap_r + 15.12) * 0.5, wall_y, 15.56), Vector3(15.12 - gap_r, 3.8, 0.42))
	# Above the door header the wall is closed too (door top ≈ 0.87, ceiling 1.4).
	var door := get_node_or_null(EXIT_DOOR_NAME) as Node3D
	if door != null:
		var head_bottom := door.position.y + 3.18
		_add_wall_slab(root, "NorthHeader", Vector3(door_x, head_bottom + 0.6, 15.56), Vector3(gap_r - gap_l, 1.2, 0.42))
	# Door sits at local x = 2.13. Leave a 2.7 m opening so the Room 1 walk-in
	# stays clear while the rest of the south wall stays solid.
	_add_wall_slab(root, "SouthWest", Vector3(-3.06, wall_y, -3.72), Vector3(7.68, 3.8, 0.42))
	_add_wall_slab(root, "SouthEast", Vector3(9.30, wall_y, -3.72), Vector3(11.64, 3.8, 0.42))
	_open_north_exit_gap()


func _open_north_exit_gap() -> void:
	# Authored north kitchen walls sit on the far wall. Hide only the 4 m
	# module that the raised door cuts through; StairExitWalls fills the
	# strips beside/above/below the door. The old centre module stays.
	var door_x := _exit_door_local().x
	for child in get_children():
		if not (child is Node3D):
			continue
		var child_name := String(child.name)
		if not (
			child_name.begins_with("Kitchen Walls")
			or child_name.begins_with("Wall Panel")
		):
			continue
		var pos: Vector3 = (child as Node3D).position
		if pos.z < 14.4:
			continue
		if absf(pos.x - door_x) > 1.6:
			continue
		(child as Node3D).visible = false
		child.set_meta("no_auto_collision", true)
		_disable_colliders(child)


func _disable_colliders(root: Node) -> void:
	if root is CollisionObject3D:
		(root as CollisionObject3D).collision_layer = 0
		(root as CollisionObject3D).collision_mask = 0
	for child in root.get_children():
		_disable_colliders(child)


func _add_wall_slab(root: Node3D, slab_name: String, local_pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "RoomPerimeter_%s" % slab_name
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = local_pos
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)


func on_destination_revealed() -> void:
	if encounter_started:
		return
	encounter_started = true
	room_alerted = true
	RunManager.set_combat_room(2)
	var scene := get_tree().current_scene
	if scene != null:
		scene.set_meta("cafeteria_encounter_alerted", true)
	call_deferred("_prepare_encounter")


func enter_room(_player: CharacterBody3D) -> void:
	if not encounter_started:
		on_destination_revealed()
	MusicManager.begin_combat_room(false)
	_alert_room_zombies()


func _prepare_encounter() -> void:
	for _frame in range(12):
		if not await _wait_process_frame():
			return
	if not await _wait_physics_frame():
		return
	_ensure_stable_floor()
	_ensure_perimeter_walls()
	_spawn_wave(INITIAL_SPAWN_COUNT, false)
	_alert_room_zombies()


func _refresh_walk_floor_meta() -> void:
	set_meta("room_walk_floor_y", to_global(Vector3(0.0, walk_floor_local_y, 0.0)).y)


func _alert_room_zombies() -> void:
	room_alerted = true
	var scene := get_tree().current_scene
	if scene != null:
		scene.set_meta("cafeteria_encounter_alerted", true)
	var container := get_node_or_null(ZOMBIE_CONTAINER_NAME)
	if container == null:
		return
	for child in container.get_children():
		if child.has_method("activate_chase"):
			child.activate_chase()


func _spawn_wave(count: int, reinforce: bool) -> void:
	if spawning or not encounter_started or not _can_continue():
		return
	var remaining := MAX_LIFETIME_SPAWNS - total_spawned
	if remaining <= 0 or count <= 0:
		return
	count = mini(count, remaining)
	count = mini(count, maxi(MAX_ALIVE - _alive_count(), 0))
	if count <= 0:
		return
	spawning = true
	_refresh_walk_floor_meta()

	var container := get_node_or_null(ZOMBIE_CONTAINER_NAME) as Node3D
	if container == null:
		container = Node3D.new()
		container.name = ZOMBIE_CONTAINER_NAME
		add_child(container)

	var min_player_distance := 3.4
	if reinforce:
		min_player_distance = REINFORCE_MIN_PLAYER_DISTANCE
	var points := _choose_safe_spawn_points(count, _spawn_rng, reinforce, min_player_distance)
	if points.size() < count and reinforce and _alive_count() == 0:
		# Never leave the cafeteria empty while authored bodies remain.
		for extra_point in _choose_safe_spawn_points(count - points.size(), _spawn_rng, false, 3.0):
			points.append(extra_point)

	var nav_bounds := _world_navigation_bounds()
	var start_index := total_spawned
	for i in range(points.size()):
		var zombie := CharacterBody3D.new()
		zombie.name = "CafeteriaZombie_%02d" % next_zombie_index
		next_zombie_index += 1
		zombie.set_script(ZOMBIE_SCRIPT)
		zombie.set("initial_behavior_override", 0)
		zombie.set("locomotion_clip_override", (start_index + i) % 4)
		zombie.set("surround_slot_override", start_index + i)
		zombie.set("surround_slot_count_override", MAX_LIFETIME_SPAWNS)
		zombie.set("route_variant_override", (start_index + i) % 5)
		zombie.set("navigation_bounds_override", nav_bounds)
		zombie.set("max_health", ROOM_TWO_HEALTH)
		zombie.set("attack_damage", ROOM_TWO_DAMAGE)
		zombie.set("move_speed", ROOM_TWO_MOVE_SPEED)
		zombie.set("wander_speed", ROOM_TWO_WANDER_SPEED)
		zombie.set("attack_speed_scale", ROOM_TWO_ATTACK_SPEED)
		zombie.set("stay_on_room_floor", true)
		zombie.set("base_money_reward", ROOM_TWO_REWARD)
		zombie.set("combat_room_number", 2)
		zombie.position = container.to_local(points[i])
		container.add_child(zombie)
		if zombie.has_signal("killed"):
			zombie.killed.connect(_on_room_zombie_killed)
		total_spawned += 1
		if room_alerted and zombie.has_method("activate_chase"):
			zombie.activate_chase()
		# Two rigs per frame keeps the door reveal smooth on iOS. The first
		# batch is synchronous so an emergency refill lands before the
		# player's deferred room-clear check.
		if i % SPAWNS_PER_FRAME == SPAWNS_PER_FRAME - 1 and i < points.size() - 1:
			if not await _yield_frame() or not is_instance_valid(container):
				spawning = false
				return

	spawning = false
	var missing: int = count - points.size()
	if missing > 0:
		if spawn_retries < SPAWN_RETRY_LIMIT:
			spawn_retries += 1
			push_warning("Cafeteria: placed %d/%d zombies; retrying %d." % [points.size(), count, missing])
			get_tree().create_timer(0.7, false).timeout.connect(_spawn_wave.bind(missing, true))
		else:
			push_warning("Cafeteria: could not place %d zombies after %d retries." % [missing, SPAWN_RETRY_LIMIT])
	else:
		spawn_retries = 0
	print("CAFETERIA: spawned %d this wave (%d/%d lifetime) at %.0f HP." % [
		points.size(), total_spawned, MAX_LIFETIME_SPAWNS, ROOM_TWO_HEALTH
	])


func _alive_count() -> int:
	var container := get_node_or_null(ZOMBIE_CONTAINER_NAME)
	if container == null:
		return 0
	var alive := 0
	for child in container.get_children():
		if is_instance_valid(child) and bool(child.get("alive")):
			alive += 1
	return alive


func _on_room_zombie_killed() -> void:
	total_killed += 1
	kills_since_reinforce += 1
	if total_spawned >= MAX_LIFETIME_SPAWNS:
		return
	var alive := _alive_count()
	if alive == 0:
		# Never empty while bodies remain: queued ahead of the clear check.
		kills_since_reinforce = 0
		call_deferred("_spawn_reinforcements")
		return
	if refill_pending:
		return
	if kills_since_reinforce < REINFORCE_EVERY_KILLS and alive > REFILL_WHEN_ALIVE_AT_MOST:
		return
	refill_pending = true
	get_tree().create_timer(_spawn_rng.randf_range(REFILL_DELAY_MIN, REFILL_DELAY_MAX), false).timeout.connect(_spawn_reinforcements)


func _spawn_reinforcements() -> void:
	refill_pending = false
	kills_since_reinforce = 0
	_spawn_wave(REINFORCE_COUNT, true)


func _choose_safe_spawn_points(
	count: int,
	rng: RandomNumberGenerator,
	require_off_camera: bool,
	min_player_distance: float
) -> Array[Vector3]:
	var local_candidates: Array[Vector2] = _build_floor_candidates()
	local_candidates.shuffle()

	var selected: Array[Vector3] = []
	for candidate in local_candidates:
		if selected.size() >= count:
			break
		_try_add_spawn_point(candidate, rng, selected, require_off_camera, min_player_distance)

	if selected.size() < count:
		for _extra in range(80):
			if selected.size() >= count:
				break
			var random_xz := Vector2(rng.randf_range(-5.35, 13.35), rng.randf_range(0.55, 13.55))
			_try_add_spawn_point(random_xz, rng, selected, require_off_camera, min_player_distance)

	# Reinforcements must stay off-camera and far, but if the camera covers the
	# whole room, take the farthest legal floor points instead of skipping the wave.
	if selected.size() < count and require_off_camera:
		for candidate in local_candidates:
			if selected.size() >= count:
				break
			_try_add_spawn_point(candidate, rng, selected, false, min_player_distance * 0.72)
	return selected


func _try_add_spawn_point(
	candidate: Vector2,
	rng: RandomNumberGenerator,
	selected: Array[Vector3],
	require_off_camera: bool,
	min_player_distance: float
) -> void:
	if _is_near_furniture(candidate):
		return
	for _attempt in range(4):
		var adjusted := candidate + Vector2(
			rng.randf_range(-0.22, 0.22),
			rng.randf_range(-0.22, 0.22)
		)
		if _is_near_furniture(adjusted):
			continue
		var floor_point := _find_floor_point(adjusted)
		if floor_point == Vector3.INF:
			continue
		if not _is_clear_of_selected(floor_point, selected):
			continue
		if not _is_far_enough_from_player(floor_point, min_player_distance):
			continue
		if require_off_camera and not _is_off_camera(floor_point):
			continue
		if _is_body_space_clear(floor_point):
			selected.append(floor_point + Vector3.UP * 0.04)
			return


func _build_floor_candidates() -> Array[Vector2]:
	var local_candidates: Array[Vector2] = []
	# Aisles only. Table columns sit at x = -1.51 and 3.32; the kitchen counter
	# occupies the east wall around x = 6.9, z = 4.1.
	for z in [1.4, 2.9, 4.5, 6.1, 7.7, 9.3, 10.9, 12.5, 13.5]:
		for x in [-5.15, -3.55, -0.05, 0.95, 5.45, 8.55, 10.55, 12.55]:
			local_candidates.append(Vector2(float(x), float(z)))
	return local_candidates


func _is_near_furniture(local_xz: Vector2) -> bool:
	if stair_exclusion_rect.has_area() and stair_exclusion_rect.has_point(local_xz):
		return true
	for child in get_children():
		if not (child is Node3D):
			continue
		var child_name := String(child.name).to_lower()
		if "table" in child_name:
			var table_pos: Vector3 = (child as Node3D).position
			if local_xz.distance_to(Vector2(table_pos.x, table_pos.z)) < FURNITURE_EXCLUDE_RADIUS:
				return true
		elif "counter" in child_name:
			var counter_pos: Vector3 = (child as Node3D).position
			if absf(local_xz.x - counter_pos.x) < 1.85 and absf(local_xz.y - counter_pos.z) < 4.4:
				return true
	return false


func _find_floor_point(local_xz: Vector2) -> Vector3:
	var ray_top := to_global(Vector3(local_xz.x, 4.5, local_xz.y))
	var ray_bottom := to_global(Vector3(local_xz.x, -5.0, local_xz.y))
	var query := PhysicsRayQueryParameters3D.create(ray_top, ray_bottom, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return Vector3.INF
	var collider := hit.get("collider") as Node
	if _is_furniture_node(collider):
		return Vector3.INF
	var normal: Vector3 = hit.get("normal", Vector3.ZERO)
	if normal.dot(Vector3.UP) < 0.65:
		return Vector3.INF
	var hit_pos: Vector3 = hit.get("position", Vector3.INF)
	var authored_floor_y := to_global(Vector3(0.0, walk_floor_local_y, 0.0)).y
	if hit_pos.y > authored_floor_y + 0.28:
		return Vector3.INF
	return Vector3(hit_pos.x, authored_floor_y, hit_pos.z)


func _is_furniture_node(node: Node) -> bool:
	var current := node
	while current != null:
		var node_name := String(current.name).to_lower()
		if node_name.begins_with("tile floor") or node_name == "roomstablefloor":
			return false
		if (
			"table" in node_name
			or "counter" in node_name
			or "locker" in node_name
			or "cabinet" in node_name
			or "cup" in node_name
			or "tray" in node_name
			or "chair" in node_name
			or "stool" in node_name
		):
			return true
		current = current.get_parent()
	return false


func _is_body_space_clear(floor_point: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = SAFE_RADIUS
	capsule.height = SAFE_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, floor_point + Vector3.UP * (SAFE_HEIGHT * 0.5 + 0.16))
	query.collision_mask = SAFE_CHECK_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _is_clear_of_selected(point: Vector3, selected: Array[Vector3]) -> bool:
	for other in selected:
		if Vector2(point.x - other.x, point.z - other.z).length() < MIN_ZOMBIE_SPACING:
			return false
	return true


func _is_far_enough_from_player(point: Vector3, min_distance: float) -> bool:
	var player := _player()
	if player == null:
		return true
	var offset := Vector2(point.x - player.global_position.x, point.z - player.global_position.z)
	return offset.length() >= min_distance


func _is_off_camera(point: Vector3) -> bool:
	## Hidden from the player: outside the view, or behind a wall / counter.
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return true
	var head := point + Vector3.UP * 1.45
	if camera.is_position_behind(head) or not camera.is_position_in_frustum(head):
		return true
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, head, SAFE_CHECK_MASK)
	query.collide_with_areas = false
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _player() -> CharacterBody3D:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("Player") as CharacterBody3D


func _world_navigation_bounds() -> Rect2:
	var corners: Array[Vector3] = [
		to_global(Vector3(-5.55, 0.0, -3.7)),
		to_global(Vector3(13.85, 0.0, -3.7)),
		to_global(Vector3(-5.55, 0.0, 14.55)),
		to_global(Vector3(13.85, 0.0, 14.55)),
	]
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for corner in corners:
		min_x = minf(min_x, corner.x)
		max_x = maxf(max_x, corner.x)
		min_z = minf(min_z, corner.z)
		max_z = maxf(max_z, corner.z)
	return Rect2(Vector2(min_x, min_z), Vector2(max_x - min_x, max_z - min_z))



# =============================================================================
# Room 3 stair exit
# =============================================================================

func _exit_door_local() -> Vector3:
	var door := get_node_or_null(EXIT_DOOR_NAME) as Node3D
	if door == null:
		return Vector3(6.0, -2.31, 15.4)
	return door.position


func _ensure_stair_exit() -> void:
	if get_node_or_null("StairExitCollision") != null:
		return
	var stairs := get_node_or_null(EXIT_STAIRS_NAME) as Node3D
	if stairs == null:
		push_warning("Cafeteria: %s missing; Room 3 exit has no stairs." % EXIT_STAIRS_NAME)
		return
	var xf := stairs.transform
	var door := _exit_door_local()
	var root := Node3D.new()
	root.name = "StairExitCollision"
	add_child(root)

	# The dining floor's walkable collision (solidify_world thin tile boxes)
	# sits a few cm above the visible tiles, and so does Room 3's. Put the
	# landing and flight on the same physical plane so the dining floor, the
	# flight, the landing and Room 3 all meet without a lip.
	var lift := _tile_collision_lift()
	set_meta("floor_collision_lift", lift)
	var lift_m := lift / maxf(xf.basis.y.length(), 0.001)
	var deck := STAIR_DECK_Y + lift_m
	var hx := STAIR_WALK_HALF_X + 0.02
	# Landing: solid from the dining floor up to the deck, and a little past the
	# wall face so the threshold under the door frame has no gap.
	var back_z_local := (xf * Vector3(0.0, 0.0, STAIR_BACK_Z)).z
	var extra_model_z := (door.z + 0.05 - back_z_local) / (xf.basis * Vector3(0.0, 0.0, 1.0)).z
	var landing_back := STAIR_BACK_Z + extra_model_z
	var landing_pts := _box_points(xf, Vector3(-hx, -0.03, landing_back), Vector3(hx, deck, STAIR_DECK_FRONT_Z))
	_add_convex_body(root, "RoomPerimeter_StairLanding", landing_pts, 1)

	# Flight: a solid wedge whose top face runs along the step nosings, so the
	# capsule walks it as a ~30° ramp (floor_max_angle is 45°) without jumping.
	var wedge_pts := PackedVector3Array()
	for x in [-hx, hx]:
		wedge_pts.append(xf * Vector3(x, lift_m, STAIR_TOE_Z))
		wedge_pts.append(xf * Vector3(x, -0.03, STAIR_TOE_Z))
		wedge_pts.append(xf * Vector3(x, deck, STAIR_DECK_FRONT_Z))
		wedge_pts.append(xf * Vector3(x, -0.03, STAIR_DECK_FRONT_Z))
	var ramp := _add_convex_body(root, "RoomPerimeter_StairFlight", wedge_pts, 1)
	# player.gd reads this to drive the grounded stair camera layer.
	ramp.set_meta("stair_surface", true)
	var slope_dir := (xf * Vector3(0.0, deck, STAIR_DECK_FRONT_Z)) - (xf * Vector3(0.0, lift_m, STAIR_TOE_Z))
	ramp.set_meta("stair_up_direction", slope_dir.normalized())

	# Handrails: thin walls that follow the flight and the landing sides.
	for side in [-1.0, 1.0]:
		var x0: float = side * (STAIR_RAIL_X - STAIR_RAIL_HALF_T)
		var x1: float = side * (STAIR_RAIL_X + STAIR_RAIL_HALF_T)
		var rail := PackedVector3Array()
		for x in [x0, x1]:
			rail.append(xf * Vector3(x, 0.0, STAIR_TOE_Z))
			rail.append(xf * Vector3(x, lift_m + STAIR_RAIL_TOP, STAIR_TOE_Z))
			rail.append(xf * Vector3(x, deck, STAIR_DECK_FRONT_Z))
			rail.append(xf * Vector3(x, deck + STAIR_RAIL_TOP, STAIR_DECK_FRONT_Z))
		_add_convex_body(root, "RoomPerimeter_StairRail%s" % ("L" if side < 0.0 else "R"), rail, 1)
		var landing_rail := _box_points(
			xf,
			Vector3(minf(x0, x1), deck, STAIR_BACK_Z),
			Vector3(maxf(x0, x1), deck + STAIR_RAIL_TOP, STAIR_DECK_FRONT_Z)
		)
		_add_convex_body(root, "RoomPerimeter_LandingRail%s" % ("L" if side < 0.0 else "R"), landing_rail, 1)

	# Zombies are floor-locked: keep their pathing and bodies off the stairs.
	var footprint := _box_points(xf, Vector3(-0.36, 0.0, STAIR_BACK_Z), Vector3(0.36, 1.2, STAIR_TOE_Z + 0.08))
	_add_convex_body(root, "RoomPerimeter_StairZombieBlocker", footprint, 16)
	var rect := Rect2()
	var first := true
	for p in footprint:
		var pt := Vector2(p.x, p.z)
		if first:
			rect = Rect2(pt, Vector2.ZERO)
			first = false
		else:
			rect = rect.expand(pt)
	stair_exclusion_rect = rect.grow(0.7)

	_trim_stair_back_rail(stairs)
	if LOCK_STAIRS_UNTIL_CLEARED:
		_build_stair_gate(root, xf)
	_refresh_stair_gate()


func _box_points(xf: Transform3D, a: Vector3, b: Vector3) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for x in [a.x, b.x]:
		for y in [a.y, b.y]:
			for z in [a.z, b.z]:
				pts.append(xf * Vector3(x, y, z))
	return pts


func _add_convex_body(root: Node3D, body_name: String, points: PackedVector3Array, layer: int) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = body_name
	body.collision_layer = layer
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)
	return body


## Staircase.glb has a top rail across the back of its landing. With the
## landing against the wall that rail would cross the doorway at chest height,
## so the mesh is rebuilt once without those triangles (corner posts stay).
func _trim_stair_back_rail(stairs: Node3D) -> void:
	for node in stairs.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or not (mesh_instance.mesh is ArrayMesh) or mesh_instance.has_meta("back_rail_trimmed"):
			continue
		var to_model := stairs.global_transform.affine_inverse() * mesh_instance.global_transform
		var source := mesh_instance.mesh as ArrayMesh
		var trimmed := ArrayMesh.new()
		var removed := 0
		for surface in range(source.get_surface_count()):
			var arrays := source.surface_get_arrays(surface)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				indices = PackedInt32Array(range(verts.size()))
			var kept := PackedInt32Array()
			for t in range(0, indices.size(), 3):
				var c: Vector3 = to_model * ((verts[indices[t]] + verts[indices[t + 1]] + verts[indices[t + 2]]) / 3.0)
				if c.z < STAIR_BACK_RAIL_CUT_Z and c.y > STAIR_DECK_Y + 0.02 and absf(c.x) < STAIR_RAIL_X - 0.025:
					removed += 1
					continue
				kept.append(indices[t])
				kept.append(indices[t + 1])
				kept.append(indices[t + 2])
			arrays[Mesh.ARRAY_INDEX] = kept
			# LOD index arrays would still draw the old triangles.
			trimmed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			trimmed.surface_set_material(surface, source.surface_get_material(surface))
		mesh_instance.mesh = trimmed
		mesh_instance.set_meta("back_rail_trimmed", true)
		print("CAFETERIA: stair landing back rail trimmed (%d tris)." % removed)


func _build_stair_gate(root: Node3D, xf: Transform3D) -> void:
	# Lockdown boom across the foot of the flight. It lifts when the room clears.
	var gate_center := xf * Vector3(0.0, 0.0, STAIR_TOE_Z + 0.07)
	var across := (xf.basis * Vector3(1.0, 0.0, 0.0)).normalized()
	var width := (xf.basis * Vector3(STAIR_RAIL_X * 2.0 + 0.06, 0.0, 0.0)).length()
	var gate := Node3D.new()
	gate.name = "StairLockdownGate"
	gate.position = gate_center
	gate.basis = Basis(across, Vector3.UP, across.cross(Vector3.UP))
	gate.set_meta("no_auto_collision", true)
	root.add_child(gate)

	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.16, 0.17, 0.18)
	steel.metallic = 0.7
	steel.roughness = 0.45
	var hazard := StandardMaterial3D.new()
	hazard.albedo_color = Color(0.95, 0.66, 0.08)
	hazard.roughness = 0.5
	hazard.emission_enabled = true
	hazard.emission = Color(0.9, 0.45, 0.05)
	hazard.emission_energy_multiplier = 0.35
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.05, 0.05, 0.05)
	dark.roughness = 0.6

	for side in [-0.5, 0.5]:
		var post := MeshInstance3D.new()
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.12, 1.12, 0.12)
		post_mesh.material = steel
		post.mesh = post_mesh
		post.position = Vector3(side * width, 0.56, 0.0)
		gate.add_child(post)

	stair_gate_arm = Node3D.new()
	stair_gate_arm.name = "Arm"
	stair_gate_arm.position = Vector3(-0.5 * width, 0.98, 0.0)
	gate.add_child(stair_gate_arm)
	var stripes := 7
	var stripe_len := width / float(stripes)
	for i in range(stripes):
		var stripe := MeshInstance3D.new()
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(stripe_len, 0.1, 0.07)
		stripe_mesh.material = hazard if i % 2 == 0 else dark
		stripe.mesh = stripe_mesh
		stripe.position = Vector3(stripe_len * (float(i) + 0.5), 0.0, 0.0)
		stair_gate_arm.add_child(stripe)

	stair_gate_body = StaticBody3D.new()
	stair_gate_body.name = "RoomPerimeter_StairGate"
	stair_gate_body.collision_layer = 1
	stair_gate_body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width + 0.2, 1.6, 0.3)
	collision.shape = box
	collision.position = Vector3(0.0, 0.8, 0.0)
	stair_gate_body.add_child(collision)
	gate.add_child(stair_gate_body)


func _refresh_stair_gate() -> void:
	if stair_gate_body == null or stair_gate_open:
		return
	var cleared := RunManager.is_combat_room_cleared(2)
	var scene := get_tree().current_scene if is_inside_tree() else null
	if scene != null and bool(scene.get_meta("combat_room_2_cleared", false)):
		cleared = true
	if not cleared:
		return
	stair_gate_open = true
	stair_gate_body.collision_layer = 0
	for child in stair_gate_body.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).set_deferred("disabled", true)
	if stair_gate_arm != null and is_inside_tree():
		var tween := create_tween()
		tween.tween_property(stair_gate_arm, "rotation_degrees:z", 84.0, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	print("CAFETERIA: Room 2 cleared, stair lockdown lifted.")



## Height of solidify_world's thin tile collider above the visible tile top
## (it keeps a 0.10-unit box on the tile's lowest face). ~0.12 m here.
func _tile_collision_lift() -> float:
	for child in get_children():
		if not (child is Node3D) or not String(child.name).begins_with("Tile Floor"):
			continue
		for node in child.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance := node as MeshInstance3D
			if mesh_instance == null or mesh_instance.mesh == null:
				continue
			var to_room := global_transform.affine_inverse() * mesh_instance.global_transform
			var local_up := to_room.basis.inverse() * Vector3.UP
			var axis := Vector3(1, 0, 0)
			var best := absf(local_up.x)
			if absf(local_up.y) > best:
				axis = Vector3(0, 1, 0)
				best = absf(local_up.y)
			if absf(local_up.z) > best:
				axis = Vector3(0, 0, 1)
			var aabb := mesh_instance.get_aabb()
			var bottom := INF
			var top := -INF
			for i in range(8):
				var y := (to_room * aabb.get_endpoint(i)).y
				bottom = minf(bottom, y)
				top = maxf(top, y)
			var box_top := bottom + 0.10 * (to_room.basis * axis).length()
			return clampf(box_top - top, 0.0, 0.3)
	return 0.0


# ---------------------------------------------------------------- safe waits
# Restart Run / Main Menu swap the whole scene while these coroutines may be
# mid-wait (Room 1 sits parked in the hub). Every wait bails once the node has
# left the tree or spawning was aborted, instead of touching a null tree.

func abort_spawning() -> void:
	_spawn_aborted = true
	spawning = false
	refill_pending = false


func _can_continue() -> bool:
	return not _spawn_aborted and is_inside_tree() and get_tree() != null


func _wait_process_frame() -> bool:
	if not _can_continue():
		return false
	await get_tree().process_frame
	return _can_continue()


func _wait_physics_frame() -> bool:
	if not _can_continue():
		return false
	await get_tree().physics_frame
	return _can_continue()


func _yield_frame() -> bool:
	## Resume on the next rendered frame even when called from a physics step
	## (awaiting process_frame from physics resumes in the same frame).
	if not _can_continue():
		return false
	var frame := Engine.get_process_frames()
	await get_tree().process_frame
	if not _can_continue():
		return false
	if Engine.get_process_frames() == frame:
		await get_tree().process_frame
	return _can_continue()
