extends Node3D

## Owns the first combat-room encounter. Zombies are created as children of the
## Living Quarters scene only after the imported furniture has physics bodies.

const ZOMBIE_SCRIPT = preload("res://scripts/zombie.gd")
const ZOMBIE_CONTAINER_NAME := "EncounterZombies"
const ENTRY_LOCAL_POSITION := Vector3(0.0, 1.0, -6.65)
const SAFE_CHECK_MASK := 1 | 16
const SAFE_RADIUS := 0.38
const SAFE_HEIGHT := 1.50
const SAFE_BOTTOM_CLEARANCE := 0.22
const MIN_ZOMBIE_SPACING := 1.35
const REQUIRED_ROOM_ONE_ZOMBIES := 12
## Pacing: open with a pack, refill off-camera up to MAX_ALIVE until all
## twelve have been spawned. Lifetime stays twelve.
const OPENING_PACK := 6
const MAX_ALIVE := 6
const REFILL_BATCH := 2
const REFILL_DELAY_MIN := 0.8
const REFILL_DELAY_MAX := 1.6
const REFILL_MIN_PLAYER_DISTANCE := 6.0
const SPAWNS_PER_FRAME := 2
const ROOM_GRID_Z := [-10.30, -11.45, -12.60, -13.75, -14.90, -16.05, -17.20, -18.35, -19.50, -20.65, -21.75]
const ROOM_GRID_X := [-6.45, -5.35, -4.25, -3.15, -2.05, -0.95, 0.15, 1.25, 2.35, 3.45, 4.55, 5.55]

var spawning := false
var spawn_generation := 0
var director_generation := 0
var total_spawned := 0
var lifetime_limit := REQUIRED_ROOM_ONE_ZOMBIES
var refill_pending := false
var _spawn_aborted := false
var zombie_health := 100.0
var zombie_damage := 10.0
var base_reward := 8
var locomotion_styles: Array[int] = []
var surround_slots: Array[int] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("room1_infested_controller")
	_rng.randomize()
	_ensure_world_collision_builder()
	_ensure_stable_floor()
	if not Engine.is_editor_hint():
		call_deferred("_prepare_initial_encounter")


func _ensure_world_collision_builder() -> void:
	if get_node_or_null("WorldCollisionBuilder") != null:
		return
	var builder := Node.new()
	builder.name = "WorldCollisionBuilder"
	builder.set_script(preload("res://scripts/solidify_world.gd"))
	add_child(builder)


func _ensure_stable_floor() -> void:
	if get_node_or_null("RoomStableFloor") != null:
		return
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
		return
	var body := StaticBody3D.new()
	body.name = "RoomStableFloor"
	body.collision_layer = 1
	body.collision_mask = 0
	var pad := 1.25
	# Hub walk surface is y ≈ -0.06. Keep this slab under that plane so the
	# doorway is a flat walk-in, not a 30 cm invisible step.
	const FLOOR_HEIGHT := 0.24
	const HUB_WALK_Y := -0.06
	body.position = Vector3((min_x + max_x) * 0.5, HUB_WALK_Y - FLOOR_HEIGHT * 0.5, (min_z + max_z) * 0.5)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(max_x - min_x + pad * 2.0, FLOOR_HEIGHT, max_z - min_z + pad * 2.0)
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _prepare_initial_encounter() -> void:
	# solidify_world.gd performs its second imported-prop pass after eight frames.
	# Waiting twelve frames plus a physics tick ensures those bodies are queryable.
	for _frame in range(12):
		if not await _wait_process_frame():
			return
	if not await _wait_physics_frame():
		return
	# Do not spawn while this room is parked off-stage. CharacterBody3D children
	# keep world positions when the parent snaps back, so the horde would vanish.
	while bool(get_meta("stream_parked", false)):
		if not await _wait_process_frame():
			return
	if not await _wait_physics_frame():
		return
	# on_destination_revealed() may already have placed the horde; spawning
	# again used to free those 12 and build a second set.
	if get_node_or_null(ZOMBIE_CONTAINER_NAME) != null and get_node(ZOMBIE_CONTAINER_NAME).get_child_count() > 0:
		return
	_spawn_encounter_zombies()


func on_destination_revealed() -> void:
	if get_node_or_null(ZOMBIE_CONTAINER_NAME) != null:
		return
	call_deferred("_spawn_after_reveal")


func _spawn_after_reveal() -> void:
	if not await _wait_physics_frame():
		return
	if get_node_or_null(ZOMBIE_CONTAINER_NAME) != null:
		return
	_spawn_encounter_zombies()

func enter_room(player: CharacterBody3D) -> void:
	if player == null:
		return

	player.global_position = to_global(ENTRY_LOCAL_POSITION)
	player.velocity = Vector3.ZERO

	var scene := get_tree().current_scene
	if scene != null:
		# Starting the run does not instantly wake every zombie. The player gets a
		# short spatial buffer inside the doorway; crossing the alert line or firing
		# at an infected wakes the horde through zombie.gd.
		scene.set_meta("room2_encounter_alerted", false)

	RunManager.start_run(1)
	MusicManager.begin_combat_room()
	if player.has_method("give_starting_pistol"):
		player.give_starting_pistol()

func reset_encounter() -> void:
	spawn_generation += 1
	director_generation += 1
	refill_pending = false
	var scene := get_tree().current_scene
	if scene != null:
		scene.set_meta("room2_encounter_alerted", false)
	var old := get_node_or_null(ZOMBIE_CONTAINER_NAME)
	if old != null:
		old.queue_free()
	call_deferred("_respawn_after_cleanup", spawn_generation)

func _respawn_after_cleanup(generation: int) -> void:
	if not await _wait_process_frame():
		return
	if not await _wait_physics_frame():
		return
	if generation == spawn_generation:
		_spawn_encounter_zombies()

func _spawn_encounter_zombies() -> void:
	## Opening pack only. The rest of the twelve arrive through the refill
	## director below, off-camera, so entering the room never instantiates the
	## whole lifetime in one frame.
	if spawning or Engine.is_editor_hint() or not _can_continue():
		return
	spawning = true
	director_generation += 1
	total_spawned = 0
	refill_pending = false

	var old := get_node_or_null(ZOMBIE_CONTAINER_NAME)
	if old != null:
		old.free()

	var container := Node3D.new()
	container.name = ZOMBIE_CONTAINER_NAME
	add_child(container)

	var config: Dictionary = RunManager.get_room_config(1)
	# Room 1 is authored and balanced around a full twelve-zombie encounter. Do
	# not silently downgrade it when an older run configuration reports less.
	lifetime_limit = maxi(REQUIRED_ROOM_ONE_ZOMBIES, int(config.get("zombie_count", 12)))
	zombie_health = float(config.get("health", 100.0))
	zombie_damage = float(config.get("damage", 10.0))
	base_reward = int(config.get("base_reward", 8))

	var opening: int = mini(OPENING_PACK, lifetime_limit)
	var safe_points := _choose_safe_spawn_points(opening, _rng)
	# Sentries, one roamer, matching the authored encounter.
	var roaming_index := _rng.randi_range(0, maxi(safe_points.size() - 1, 0))
	locomotion_styles.clear()
	for style_index in range(lifetime_limit):
		locomotion_styles.append(style_index % 4)
	locomotion_styles.shuffle()
	surround_slots.clear()
	for slot_index in range(lifetime_limit):
		surround_slots.append(slot_index)
	surround_slots.shuffle()

	var generation := director_generation
	for i in range(safe_points.size()):
		var mode := 2 # LOOK_AROUND
		if i == roaming_index:
			mode = 0 if _rng.randf() < 0.62 else 1
		_spawn_zombie(container, safe_points[i], mode)
		# Two bodies per frame: each rig is a large skinned GLB and the room
		# is revealed while the door is still opening on iOS.
		if i % SPAWNS_PER_FRAME == SPAWNS_PER_FRAME - 1 and i < safe_points.size() - 1:
			if not await _yield_frame() or generation != director_generation or not is_instance_valid(container):
				spawning = false
				return
	spawning = false
	print("LIVING QUARTERS: opening pack %d (%d/%d lifetime)." % [safe_points.size(), total_spawned, lifetime_limit])
	_schedule_refill(REFILL_DELAY_MIN)


func _spawn_zombie(container: Node3D, local_point: Vector3, mode: int) -> CharacterBody3D:
	var index := total_spawned
	var zombie := CharacterBody3D.new()
	zombie.name = "Zombie_%02d" % (index + 1)
	zombie.set_script(ZOMBIE_SCRIPT)
	zombie.set("initial_behavior_override", mode)
	zombie.set("locomotion_clip_override", locomotion_styles[index % locomotion_styles.size()] if not locomotion_styles.is_empty() else index % 4)
	zombie.set("surround_slot_override", surround_slots[index % surround_slots.size()] if not surround_slots.is_empty() else index)
	zombie.set("surround_slot_count_override", lifetime_limit)
	zombie.set("max_health", zombie_health)
	zombie.set("attack_damage", zombie_damage)
	zombie.set("base_money_reward", base_reward)
	# Five stable route styles: fastest/direct, mild left/right, and wide
	# left/right, cycled by spawn order.
	zombie.set("route_variant_override", index % 5)
	zombie.set("combat_room_number", 1)
	zombie.position = local_point
	container.add_child(zombie)
	if zombie.has_signal("killed"):
		zombie.killed.connect(_on_zombie_killed)
	total_spawned += 1
	return zombie


# ---------------------------------------------------------------- refill director

func _alive_count() -> int:
	var container := get_node_or_null(ZOMBIE_CONTAINER_NAME)
	if container == null:
		return 0
	var alive := 0
	for child in container.get_children():
		if is_instance_valid(child) and bool(child.get("alive")):
			alive += 1
	return alive


func _on_zombie_killed() -> void:
	if total_spawned >= lifetime_limit:
		return
	if _alive_count() == 0:
		# Queued before the player's deferred "room cleared?" check, and the
		# first body is placed synchronously, so the room can never clear early.
		call_deferred("_refill", director_generation, true)
		return
	_schedule_refill(_rng.randf_range(REFILL_DELAY_MIN, REFILL_DELAY_MAX))


func _schedule_refill(delay: float) -> void:
	if refill_pending or total_spawned >= lifetime_limit or not _can_continue():
		return
	refill_pending = true
	var generation := director_generation
	get_tree().create_timer(delay, false).timeout.connect(func() -> void:
		refill_pending = false
		if generation == director_generation:
			_refill(generation, false))


func _refill(generation: int, emergency: bool) -> void:
	if generation != director_generation or spawning or not _can_continue():
		return
	var container := get_node_or_null(ZOMBIE_CONTAINER_NAME) as Node3D
	if container == null or bool(get_meta("stream_parked", false)):
		_schedule_refill(REFILL_DELAY_MIN)
		return
	var remaining: int = lifetime_limit - total_spawned
	var room: int = MAX_ALIVE - _alive_count()
	var count: int = mini(mini(remaining, room), REFILL_BATCH)
	if count <= 0:
		return
	var points := _choose_reinforcement_points(count, emergency)
	var alerted := false
	var scene := get_tree().current_scene
	if scene != null:
		alerted = bool(scene.get_meta("room2_encounter_alerted", false))
	for i in range(points.size()):
		# Before the horde wakes, refills stand as sentries; after, they come in
		# angry (zombie.gd reads the alert flag and activates the chase).
		_spawn_zombie(container, points[i], 0 if alerted else 2)
		if i < points.size() - 1:
			if not await _yield_frame() or generation != director_generation or not is_instance_valid(container):
				return
	if total_spawned < lifetime_limit and _alive_count() < MAX_ALIVE:
		_schedule_refill(_rng.randf_range(REFILL_DELAY_MIN, REFILL_DELAY_MAX) if points.size() > 0 else 0.6)


func _choose_reinforcement_points(count: int, emergency: bool) -> Array[Vector3]:
	## Off-camera or behind cover, and never on top of the player. Falls back
	## to the farthest legal cell rather than skipping, so the room keeps its
	## lifetime and is never empty.
	var candidates: Array[Vector3] = []
	for z in ROOM_GRID_Z:
		for x in ROOM_GRID_X:
			candidates.append(Vector3(float(x) + _rng.randf_range(-0.25, 0.25), 0.06, float(z) + _rng.randf_range(-0.25, 0.25)))
	candidates.shuffle()
	var occupied: Array[Vector3] = []
	var container := get_node_or_null(ZOMBIE_CONTAINER_NAME)
	if container != null:
		for child in container.get_children():
			if child is Node3D and bool(child.get("alive")):
				occupied.append((child as Node3D).position)
	var selected: Array[Vector3] = []
	var fallback: Array[Vector3] = []
	for point in candidates:
		if selected.size() >= count:
			break
		if not _is_clear_of_selected(point, occupied) or not _is_clear_of_selected(point, selected):
			continue
		var distance := _player_distance(point)
		if distance < REFILL_MIN_PLAYER_DISTANCE * (0.6 if emergency else 1.0):
			continue
		if not _is_spawn_point_safe(point):
			continue
		if _is_hidden_from_player(point):
			selected.append(point)
		else:
			fallback.append(point)
	if selected.size() < count and (emergency or _alive_count() <= 1):
		fallback.sort_custom(func(a: Vector3, b: Vector3) -> bool: return _player_distance(a) > _player_distance(b))
		for point in fallback:
			if selected.size() >= count:
				break
			if _is_clear_of_selected(point, selected):
				selected.append(point)
	return selected


func _player_distance(local_point: Vector3) -> float:
	var player := get_tree().current_scene.get_node_or_null("Player") as Node3D if get_tree().current_scene != null else null
	if player == null:
		return INF
	var world := to_global(local_point)
	return Vector2(world.x - player.global_position.x, world.z - player.global_position.z).length()


func _is_hidden_from_player(local_point: Vector3) -> bool:
	## Outside the view frustum, or the camera's line to the head is blocked by
	## furniture / walls.
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return true
	var head := to_global(local_point + Vector3.UP * 1.45)
	if camera.is_position_behind(head) or not camera.is_position_in_frustum(head):
		return true
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, head, SAFE_CHECK_MASK)
	query.collide_with_areas = false
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _choose_safe_spawn_points(count: int, rng: RandomNumberGenerator) -> Array[Vector3]:
	var candidates: Array[Vector3] = []
	# Sample the complete authored floor width at much finer intervals instead of
	# only seven crowded center points. The floor tiles span approximately X -7.1
	# through +6.0; a supporting-floor ray below guarantees that no candidate can
	# be accepted beyond those tiles. The front remains clear for room entry.
	for z in [-10.30, -11.45, -12.60, -13.75, -14.90, -16.05, -17.20, -18.35, -19.50, -20.65, -21.75]:
		for x in [-6.45, -5.35, -4.25, -3.15, -2.05, -0.95, 0.15, 1.25, 2.35, 3.45, 4.55, 5.55]:
			candidates.append(Vector3(float(x), 0.06, float(z)))
	candidates.shuffle()

	var selected: Array[Vector3] = []
	for candidate in candidates:
		if selected.size() >= count:
			break
		# Try the exact authored cell and several small offsets. A single unlucky
		# random offset near a bed rail must not discard an otherwise safe region.
		var attempts: Array[Vector3] = [candidate]
		for _attempt_index in range(3):
			attempts.append(candidate + Vector3(
				rng.randf_range(-0.30, 0.30),
				0.0,
				rng.randf_range(-0.30, 0.30)
			))
		for point in attempts:
			if not _is_clear_of_selected(point, selected):
				continue
			if _is_spawn_point_safe(point):
				selected.append(point)
				break

	print("LIVING QUARTERS: spawned %d/%d collision-safe zombies." % [selected.size(), count])
	return selected

func _is_clear_of_selected(point: Vector3, selected: Array[Vector3]) -> bool:
	for other in selected:
		if Vector2(point.x - other.x, point.z - other.z).length() < MIN_ZOMBIE_SPACING:
			return false
	return true

func _is_spawn_point_safe(local_point: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = SAFE_RADIUS
	capsule.height = SAFE_HEIGHT

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(
		Basis.IDENTITY,
		# Keep the test above the decorative floor-tile boxes. Furniture also has
		# full-height layer-16 blockers, so it remains impossible to pass this test.
		to_global(local_point + Vector3(0.0, SAFE_HEIGHT * 0.5 + SAFE_BOTTOM_CLEARANCE, 0.0))
	)
	query.collision_mask = SAFE_CHECK_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var space_state := get_world_3d().direct_space_state
	if not space_state.intersect_shape(query, 1).is_empty():
		return false

	# Shape clearance alone cannot prove that a floor exists; an empty point just
	# outside the room would otherwise look valid. Require a near-horizontal layer
	# 1 surface directly beneath every accepted zombie.
	var floor_origin: Vector3 = to_global(local_point + Vector3(0.0, 0.75, 0.0))
	var floor_query := PhysicsRayQueryParameters3D.create(
		floor_origin,
		floor_origin + Vector3(0.0, -1.35, 0.0),
		1
	)
	floor_query.collide_with_areas = false
	floor_query.collide_with_bodies = true
	var floor_hit: Dictionary = space_state.intersect_ray(floor_query)
	if floor_hit.is_empty():
		return false
	var floor_normal: Vector3 = floor_hit.get("normal", Vector3.ZERO)
	return floor_normal.dot(Vector3.UP) >= 0.65


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
