extends Node3D

## Shared encounter owner for combat rooms 3–20. Room 1 and Room 2 keep their
## authored controllers. This script reads RunManager for count/HP/damage/payout,
## starts a small opening pack, then a wave director refills it until the room
## lifetime limit is spent: a short breather once the pack is thinned out, never
## more than max_alive at once, and never zero alive while bodies remain (an
## empty room would let the player clear it before the lifetime was spawned).

const ZOMBIE_SCRIPT = preload("res://scripts/zombie.gd")
const ZOMBIE_CONTAINER_NAME := "EncounterZombies"
const SAFE_CHECK_MASK := 1 | 16
const SAFE_RADIUS := 0.38
const SAFE_HEIGHT := 1.50
const MIN_ZOMBIE_SPACING := 1.42
const REINFORCE_EVERY_KILLS := 4
const REINFORCE_MIN_PLAYER_DISTANCE := 8.2
const MAX_ALIVE := [6, 6, 7, 8]
const SPAWN_RETRY_LIMIT := 6
const SPAWNS_PER_FRAME := 2
## If the floor has sat below the cap this long with bodies still to come,
## top it up even without a kill, so pressure never stalls.
const TOP_UP_INTERVAL := 4.0

@export var combat_room_number: int = 3

var encounter_started := false
var spawning := false
var walk_floor_local_y := 0.0
var floor_min := Vector2(-8.0, -8.0)
var floor_max := Vector2(8.0, 8.0)
var total_spawned := 0
var total_killed := 0
var kills_since_reinforce := 0
var next_zombie_index := 1
var room_alerted := false
var lifetime_limit := 13
var initial_spawn_count := 5
var reinforce_count := 2
var max_alive := 6
var refill_threshold := 2
var wave_pending := false
var spawn_retries := 0
var alert_scheduled := false
var top_up_timer := 0.0
var _spawn_aborted := false
var _spawn_rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("combat_room_controller")
	_spawn_rng.randomize()
	_apply_room_config()
	_ensure_stable_floor()
	_ensure_perimeter_walls()


func _apply_room_config() -> void:
	var config: Dictionary = RunManager.get_room_config(combat_room_number)
	lifetime_limit = maxi(int(config.get("zombie_count", 13)), 8)
	var tier: int = clampi(int(config.get("tier", 2)) - 1, 0, 3)
	max_alive = MAX_ALIVE[tier]
	# Empty box rooms cannot open with a Room-2-sized rush. Seed a small pack,
	# then refill up to the lifetime limit as kills come in.
	initial_spawn_count = mini(maxi(max_alive - 1, 5), lifetime_limit)
	reinforce_count = 2 if lifetime_limit < 20 else 3
	# Rooms 3-5 let the player clear space before the next 2-3 arrive; later
	# rooms top the pack up earlier so pressure stays on.
	refill_threshold = 2 if combat_room_number <= 5 else (3 if combat_room_number <= 10 else 4)


func on_destination_revealed() -> void:
	if encounter_started:
		return
	encounter_started = true
	room_alerted = false
	RunManager.set_combat_room(combat_room_number)
	call_deferred("_prepare_encounter")


func enter_room(_player: CharacterBody3D) -> void:
	if not encounter_started:
		on_destination_revealed()
	MusicManager.begin_combat_room(false)
	# The door calls this once the player has crossed. Give the room a beat to
	# notice them (per-zombie sight/hearing still works sooner), then wake it.
	if not alert_scheduled:
		alert_scheduled = true
		get_tree().create_timer(_spawn_rng.randf_range(0.8, 1.4), false).timeout.connect(_alert_room_zombies)


func _prepare_encounter() -> void:
	for _frame in range(12):
		if not await _wait_process_frame():
			return
	if not await _wait_physics_frame():
		return
	_ensure_stable_floor()
	_ensure_perimeter_walls()
	_spawn_wave(initial_spawn_count, false)


func _visual_tile_surface_local_y() -> float:
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
	return -0.80


func _measure_floor_bounds() -> void:
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
		min_x = -8.0
		max_x = 8.0
		min_z = -8.0
		max_z = 8.0
	floor_min = Vector2(min_x, min_z)
	floor_max = Vector2(max_x, max_z)
	walk_floor_local_y = _visual_tile_surface_local_y()


func _ensure_stable_floor() -> void:
	_measure_floor_bounds()
	const FLOOR_HEIGHT := 0.22
	var pad := 1.25
	var door_pad := 1.85
	var body := get_node_or_null("RoomStableFloor") as StaticBody3D
	if body == null:
		body = StaticBody3D.new()
		body.name = "RoomStableFloor"
		body.collision_layer = 1
		body.collision_mask = 0
		var collision := CollisionShape3D.new()
		collision.shape = BoxShape3D.new()
		body.add_child(collision)
		add_child(body)
	body.position = Vector3(
		(floor_min.x + floor_max.x) * 0.5,
		walk_floor_local_y - FLOOR_HEIGHT * 0.5,
		(floor_min.y + floor_max.y) * 0.5
	)
	var collision := body.get_child(0) as CollisionShape3D
	if collision != null and collision.shape is BoxShape3D:
		(collision.shape as BoxShape3D).size = Vector3(
			floor_max.x - floor_min.x + pad * 2.0,
			FLOOR_HEIGHT,
			floor_max.y - floor_min.y + door_pad * 2.0
		)
	set_meta("room_walk_floor_y", to_global(Vector3(0.0, walk_floor_local_y, 0.0)).y)


func _ensure_perimeter_walls() -> void:
	if get_node_or_null("RoomPerimeterWalls") != null:
		return
	var root := Node3D.new()
	root.name = "RoomPerimeterWalls"
	add_child(root)
	var wall_y := walk_floor_local_y + 1.85
	var mid_x := (floor_min.x + floor_max.x) * 0.5
	var mid_z := (floor_min.y + floor_max.y) * 0.5
	var width := floor_max.x - floor_min.x + 2.6
	var depth := floor_max.y - floor_min.y + 2.6
	var west_x := floor_min.x - 0.85
	var east_x := floor_max.x + 0.85
	var south_z := floor_min.y - 0.55
	var north_z := floor_max.y + 0.55
	var door_gap := 2.70
	_add_wall_slab(root, "West", Vector3(west_x, wall_y, mid_z), Vector3(0.42, 3.8, depth))
	_add_wall_slab(root, "East", Vector3(east_x, wall_y, mid_z), Vector3(0.42, 3.8, depth))
	_add_gapped_wall(root, "South", mid_x, south_z, width, wall_y, door_gap)
	if combat_room_number < 20:
		_add_gapped_wall(root, "North", mid_x, north_z, width, wall_y, door_gap)
	else:
		_add_wall_slab(root, "North", Vector3(mid_x, wall_y, north_z), Vector3(width, 3.8, 0.42))


func _add_gapped_wall(
	root: Node3D,
	side: String,
	center_x: float,
	wall_z: float,
	width: float,
	wall_y: float,
	gap: float
) -> void:
	var left_width := maxf((width - gap) * 0.5, 1.2)
	var right_width := left_width
	var left_x := center_x - (gap * 0.5 + left_width * 0.5)
	var right_x := center_x + (gap * 0.5 + right_width * 0.5)
	_add_wall_slab(root, side + "West", Vector3(left_x, wall_y, wall_z), Vector3(left_width, 3.8, 0.42))
	_add_wall_slab(root, side + "East", Vector3(right_x, wall_y, wall_z), Vector3(right_width, 3.8, 0.42))


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


func _alert_room_zombies() -> void:
	room_alerted = true
	var scene := get_tree().current_scene
	if scene != null:
		scene.set_meta("combat_room_%d_alerted" % combat_room_number, true)
	var container := get_node_or_null(ZOMBIE_CONTAINER_NAME)
	if container == null:
		return
	for child in container.get_children():
		if child.has_method("activate_chase"):
			child.activate_chase()


func _spawn_wave(count: int, reinforce: bool) -> void:
	if spawning or not encounter_started or not _can_continue():
		return
	var remaining := lifetime_limit - total_spawned
	if remaining <= 0 or count <= 0:
		return
	count = mini(count, remaining)
	count = mini(count, maxi(max_alive - _alive_count(), 0))
	if count <= 0:
		return
	spawning = true
	_ensure_stable_floor()

	var container := get_node_or_null(ZOMBIE_CONTAINER_NAME) as Node3D
	if container == null:
		container = Node3D.new()
		container.name = ZOMBIE_CONTAINER_NAME
		add_child(container)

	var min_player_distance := 6.0 if not reinforce else REINFORCE_MIN_PLAYER_DISTANCE
	var points := _choose_safe_spawn_points(count, reinforce, min_player_distance)
	if points.size() < count and _alive_count() == 0:
		# Emergency refill: any legal floor point beats an empty room.
		for extra_point in _choose_safe_spawn_points(count - points.size(), false, 3.0):
			points.append(extra_point)
	var config: Dictionary = RunManager.get_room_config(combat_room_number)
	var move_speed: float = float(config.get("move_speed", 2.18))
	var nav_bounds := _world_navigation_bounds()
	var start_index := total_spawned
	for i in range(points.size()):
		var zombie := CharacterBody3D.new()
		zombie.name = "Room%dZombie_%02d" % [combat_room_number, next_zombie_index]
		next_zombie_index += 1
		zombie.set_script(ZOMBIE_SCRIPT)
		# Most open-room infected idle until they see or get shot. Only a couple
		# start angry so the doorway is not an instant surround.
		var start_behavior := 2
		if reinforce or i < 2:
			start_behavior = 0
		zombie.set("initial_behavior_override", start_behavior)
		zombie.set("locomotion_clip_override", (start_index + i) % 4)
		zombie.set("surround_slot_override", start_index + i)
		zombie.set("surround_slot_count_override", lifetime_limit)
		zombie.set("route_variant_override", (start_index + i) % 5)
		zombie.set("navigation_bounds_override", nav_bounds)
		zombie.set("max_health", float(config.get("health", 195.0)))
		zombie.set("attack_damage", float(config.get("damage", 18.5)))
		zombie.set("move_speed", move_speed)
		zombie.set("wander_speed", move_speed * 0.32)
		zombie.set("attack_speed_scale", 1.20 + float(combat_room_number - 3) * 0.012)
		zombie.set("stay_on_room_floor", true)
		zombie.set("base_money_reward", int(config.get("base_reward", 14)))
		zombie.set("combat_room_number", combat_room_number)
		zombie.position = container.to_local(points[i])
		container.add_child(zombie)
		if zombie.has_signal("killed"):
			zombie.killed.connect(_on_room_zombie_killed)
		total_spawned += 1
		if (room_alerted or reinforce) and zombie.has_method("activate_chase"):
			zombie.activate_chase()
		# Two rigs per frame; the first batch is synchronous so an emergency
		# refill lands before the player's deferred room-clear check.
		if i % SPAWNS_PER_FRAME == SPAWNS_PER_FRAME - 1 and i < points.size() - 1:
			if not await _yield_frame() or not is_instance_valid(container):
				spawning = false
				return
	spawning = false
	top_up_timer = TOP_UP_INTERVAL
	var missing: int = count - points.size()
	if missing > 0:
		if spawn_retries < SPAWN_RETRY_LIMIT:
			spawn_retries += 1
			push_warning("Room %d: placed %d/%d zombies; retrying %d." % [combat_room_number, points.size(), count, missing])
			get_tree().create_timer(0.7, false).timeout.connect(_spawn_wave.bind(missing, true))
		else:
			push_warning("Room %d: could not place %d zombies after %d retries." % [combat_room_number, missing, SPAWN_RETRY_LIMIT])
	else:
		spawn_retries = 0
	print("ROOM %d: spawned %d (%d/%d lifetime, %d alive, max %d)." % [
		combat_room_number, points.size(), total_spawned, lifetime_limit, _alive_count(), max_alive
	])


func _on_room_zombie_killed() -> void:
	total_killed += 1
	kills_since_reinforce += 1
	if total_spawned >= lifetime_limit:
		return
	var alive := _alive_count()
	if alive >= max_alive:
		return
	if alive == 0:
		# Deferred calls run in order: this refill is queued before the player's
		# own "room cleared?" check, so the room can never clear early.
		kills_since_reinforce = 0
		call_deferred("_spawn_reinforcements")
		return
	if wave_pending:
		return
	if alive <= refill_threshold or kills_since_reinforce >= REINFORCE_EVERY_KILLS or alive <= max_alive - reinforce_count:
		wave_pending = true
		var t: float = clampf(float(combat_room_number - 3) / 17.0, 0.0, 1.0)
		var breather: float = lerpf(2.4, 1.1, t) + _spawn_rng.randf_range(0.0, 0.6)
		get_tree().create_timer(breather, false).timeout.connect(_spawn_reinforcements)


func _spawn_reinforcements() -> void:
	wave_pending = false
	kills_since_reinforce = 0
	_spawn_wave(reinforce_count, true)


func _process(delta: float) -> void:
	if _spawn_aborted or not encounter_started or not room_alerted or spawning or wave_pending:
		return
	if total_spawned >= lifetime_limit or total_spawned == 0:
		return
	top_up_timer -= delta
	if top_up_timer > 0.0:
		return
	top_up_timer = TOP_UP_INTERVAL
	if _alive_count() < max_alive:
		_spawn_wave(mini(reinforce_count, max_alive - _alive_count()), true)


func _alive_count() -> int:
	var container := get_node_or_null(ZOMBIE_CONTAINER_NAME)
	if container == null:
		return 0
	var alive := 0
	for child in container.get_children():
		if is_instance_valid(child) and bool(child.get("alive")):
			alive += 1
	return alive


func _choose_safe_spawn_points(
	count: int,
	require_off_camera: bool,
	min_player_distance: float
) -> Array[Vector3]:
	var local_candidates: Array[Vector2] = _build_floor_candidates()
	local_candidates.shuffle()
	var selected: Array[Vector3] = []
	for candidate in local_candidates:
		if selected.size() >= count:
			break
		_try_add_spawn_point(candidate, selected, require_off_camera, min_player_distance)
	if selected.size() < count:
		for _extra in range(80):
			if selected.size() >= count:
				break
			var random_xz := Vector2(
				_spawn_rng.randf_range(floor_min.x + 1.4, floor_max.x - 1.4),
				_spawn_rng.randf_range(floor_min.y + 1.6, floor_max.y - 1.4)
			)
			_try_add_spawn_point(random_xz, selected, require_off_camera, min_player_distance)
	if selected.size() < count and require_off_camera:
		for candidate in local_candidates:
			if selected.size() >= count:
				break
			_try_add_spawn_point(candidate, selected, false, min_player_distance * 0.72)
	return selected


func _try_add_spawn_point(
	candidate: Vector2,
	selected: Array[Vector3],
	require_off_camera: bool,
	min_player_distance: float
) -> void:
	for _attempt in range(4):
		var adjusted := candidate + Vector2(
			_spawn_rng.randf_range(-0.22, 0.22),
			_spawn_rng.randf_range(-0.22, 0.22)
		)
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
	var x := floor_min.x + 1.6
	while x <= floor_max.x - 1.6:
		var z := floor_min.y + 2.2
		while z <= floor_max.y - 1.4:
			local_candidates.append(Vector2(x, z))
			z += 1.7
		x += 1.8
	return local_candidates


func _find_floor_point(local_xz: Vector2) -> Vector3:
	var ray_top := to_global(Vector3(local_xz.x, walk_floor_local_y + 6.0, local_xz.y))
	var ray_bottom := to_global(Vector3(local_xz.x, walk_floor_local_y - 4.0, local_xz.y))
	var query := PhysicsRayQueryParameters3D.create(ray_top, ray_bottom, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var authored_floor_y := to_global(Vector3(0.0, walk_floor_local_y, 0.0)).y
	if hit.is_empty():
		return Vector3(to_global(Vector3(local_xz.x, walk_floor_local_y, local_xz.y)))
	var normal: Vector3 = hit.get("normal", Vector3.ZERO)
	if normal.dot(Vector3.UP) < 0.65:
		return Vector3.INF
	var hit_pos: Vector3 = hit.get("position", Vector3.INF)
	if hit_pos.y > authored_floor_y + 0.28:
		return Vector3.INF
	return Vector3(hit_pos.x, authored_floor_y, hit_pos.z)


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
	## Hidden from the player: outside the view, or behind cover.
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
		to_global(Vector3(floor_min.x + 0.8, 0.0, floor_min.y + 0.8)),
		to_global(Vector3(floor_max.x - 0.8, 0.0, floor_min.y + 0.8)),
		to_global(Vector3(floor_min.x + 0.8, 0.0, floor_max.y - 0.8)),
		to_global(Vector3(floor_max.x - 0.8, 0.0, floor_max.y - 0.8)),
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


# ---------------------------------------------------------------- safe waits
# Restart Run / Main Menu swap the whole scene while these coroutines may be
# mid-wait (Room 1 sits parked in the hub). Every wait bails once the node has
# left the tree or spawning was aborted, instead of touching a null tree.

func abort_spawning() -> void:
	_spawn_aborted = true
	spawning = false


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
