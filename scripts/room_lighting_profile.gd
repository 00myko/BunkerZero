extends Node3D

## Per-room lighting mood and light ownership.
##
## Only one WorldEnvironment can drive a World3D, and the hub (main.tscn) is the
## permanent scene root, so its environment, MoonLight and long-range fills
## used to light every streamed room until the hub geometry unloaded.
##
## Drop this node as a direct child of a room root (the hub's lives under
## SafeHubRoot). When it activates, the live WorldEnvironment blends to this
## room's mood and the room takes over the lights:
##   * lights under this room (plus `extra_owned_paths`) are switched on;
##   * every other world light is silenced (cull mask 0, which flicker scripts
##     that toggle `visible` cannot undo);
##   * lights under the Player (viewmodel key/fill/rim, muzzle) and lights in
##     the "lighting_persistent" group are never touched.
##
## Activation happens the moment the blast door sees the player cross into the
## room (room_transition_door.gd calls activate()), with an interior-box poll
## as a fallback. Nothing is ever restored to the previous room's look: when a
## room frees while still active, the mood hands off to the room the player is
## standing in, never back to the hub.

const META_ACTIVE := "room_lighting_active_profile"
const META_SAVED_MASK := "room_lighting_saved_cull_mask"
const PERSISTENT_GROUP := "lighting_persistent"
const WORLD_RENDER_LAYER := 1

@export var environment: Environment
@export var interior_min := Vector3(-8.0, -6.0, -8.0)
@export var interior_max := Vector3(8.0, 6.0, 8.0)
## Kept for scene compatibility; foreign lights of every type are handled now.
@export var hide_foreign_directional_lights := true
## Scene-root-relative nodes whose lights also belong to this room (e.g. the
## hub's MoonLight on the persistent root).
@export var extra_owned_paths: PackedStringArray = []
## Low "standing water" mist: world fog_height is derived from this room-local Y.
@export var use_height_fog := false
@export var height_fog_local_y := 0.0
@export_range(0.0, 3.0, 0.05) var blend_time := 0.6

var _active := false
var _blend_env: Environment


func _enter_tree() -> void:
	add_to_group("room_lighting_profile")


func _ready() -> void:
	if Engine.is_editor_hint() or environment == null:
		set_process(false)
		return
	set_process(true)


func _process(_delta: float) -> void:
	if _active:
		set_process(false)
		return
	# The hub profile lives under SafeHubRoot, which only gathers the hub's
	# lights at the end of its first frame. Wait so they count as owned.
	var gathered: Variant = get_parent().get("content_collected")
	if gathered is bool and not gathered:
		return
	if contains_player():
		activate()


func is_active() -> bool:
	return _active


func contains_player() -> bool:
	var room := get_parent() as Node3D
	if room == null or bool(room.get_meta("stream_parked", false)) or room.is_queued_for_deletion():
		return false
	var player := _player()
	if player == null:
		return false
	var local := room.to_local(player.global_position)
	return (
		local.x >= interior_min.x and local.x <= interior_max.x
		and local.y >= interior_min.y and local.y <= interior_max.y
		and local.z >= interior_min.z and local.z <= interior_max.z
	)


func activate() -> void:
	if _active or environment == null or not is_inside_tree():
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var world_env := _live_world_environment(scene)
	if world_env == null:
		return
	var previous: Variant = scene.get_meta(META_ACTIVE) if scene.has_meta(META_ACTIVE) else null
	if previous is Node and is_instance_valid(previous) and previous != self and previous.has_method("deactivate"):
		previous.call("deactivate")

	var target := environment.duplicate() as Environment
	if use_height_fog:
		var room := get_parent() as Node3D
		target.fog_height = room.to_global(Vector3(0.0, height_fog_local_y, 0.0)).y
	_blend_env = _blend_environment(world_env, target, blend_time)

	scene.set_meta(META_ACTIVE, self)
	_active = true
	set_process(false)
	apply_light_ownership(scene, _owned_roots(scene))
	_watch_new_lights(true)
	print("ROOM LIGHTING: %s mood active." % String(get_parent().name))


## Stops being the active mood. Lights and environment are left exactly as
## they are; the next activation decides what is on.
func deactivate(_restore_environment: bool = false) -> void:
	if not _active:
		return
	_active = false
	_watch_new_lights(false)
	var tree := get_tree()
	var scene := tree.current_scene if tree != null else null
	if scene != null and is_instance_valid(scene) and scene.has_meta(META_ACTIVE) and scene.get_meta(META_ACTIVE) == self:
		scene.set_meta(META_ACTIVE, null)


func _exit_tree() -> void:
	if not _active:
		return
	# This room is being freed while it is still the mood (the previous room
	# unloads behind the player). Hand off forward, never back to the hub.
	deactivate()
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var leaving := get_parent()
	for node in tree.get_nodes_in_group("room_lighting_profile"):
		if node == self or not is_instance_valid(node) or leaving.is_ancestor_of(node):
			continue
		if node.has_method("contains_player") and bool(node.call("contains_player")):
			node.call("activate")
			return
	_fallback_to_room_environment(tree.current_scene, leaving)


## Rooms without a profile (4–20) keep their own authored WorldEnvironment
## resource. Godot never renders it (the hub's node owns the world), so blend
## the live environment to it and give that room the lights.
func _fallback_to_room_environment(scene: Node, leaving: Node) -> void:
	var player := _player()
	var best: Node3D = null
	var best_distance := INF
	for child in scene.get_children():
		var room := child as Node3D
		if room == null or room == leaving or room.is_queued_for_deletion():
			continue
		if bool(room.get_meta("stream_parked", false)):
			continue
		var room_env := room.get_node_or_null("WorldEnvironment") as WorldEnvironment
		if room_env == null or room_env.environment == null:
			continue
		var distance := 0.0 if player == null else room.global_position.distance_to(player.global_position)
		if distance < best_distance:
			best_distance = distance
			best = room
	if best == null:
		return
	var world_env := _live_world_environment(scene)
	var room_world_env := best.get_node("WorldEnvironment") as WorldEnvironment
	if world_env != null and world_env != room_world_env:
		_blend_environment(world_env, room_world_env.environment.duplicate() as Environment, blend_time)
	apply_light_ownership(scene, [best])
	print("ROOM LIGHTING: handed off to %s's own environment." % String(best.name))


# ------------------------------------------------------------------ lights

static func apply_light_ownership(scene: Node, owned_roots: Array) -> void:
	var player := scene.get_node_or_null("Player")
	for node in scene.find_children("*", "Light3D", true, false):
		var light := node as Light3D
		if light == null:
			continue
		if _is_under(light, owned_roots):
			_show_light(light)
		elif not _is_protected(light, player):
			_silence_light(light)


static func _is_under(node: Node, roots: Array) -> bool:
	for root in roots:
		if root is Node and is_instance_valid(root) and (root == node or (root as Node).is_ancestor_of(node)):
			return true
	return false


static func _is_protected(light: Light3D, player: Node) -> bool:
	if light.is_in_group(PERSISTENT_GROUP):
		return true
	if player != null and player.is_ancestor_of(light):
		return true
	if light.has_meta(META_SAVED_MASK):
		return false
	# Layer-only rigs such as the FPS viewmodel key light.
	return (light.light_cull_mask & WORLD_RENDER_LAYER) == 0


static func _silence_light(light: Light3D) -> void:
	if light.has_meta(META_SAVED_MASK):
		return
	light.set_meta(META_SAVED_MASK, light.light_cull_mask)
	light.light_cull_mask = 0


static func _show_light(light: Light3D) -> void:
	if not light.has_meta(META_SAVED_MASK):
		return
	light.light_cull_mask = int(light.get_meta(META_SAVED_MASK))
	light.remove_meta(META_SAVED_MASK)


func _owned_roots(scene: Node) -> Array:
	var roots: Array = [get_parent()]
	for path in extra_owned_paths:
		var node := scene.get_node_or_null(NodePath(path))
		if node != null:
			roots.append(node)
	return roots


func _watch_new_lights(enabled: bool) -> void:
	var tree := get_tree()
	if tree == null:
		return
	if enabled and not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)
	elif not enabled and tree.node_added.is_connected(_on_node_added):
		tree.node_added.disconnect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is Light3D:
		# Streamed rooms and generated fixtures add lights after activation.
		# Cull masks are often assigned right after add_child(), so defer.
		_classify_new_light.call_deferred(node)


func _classify_new_light(light: Light3D) -> void:
	if not _active or light == null or not is_instance_valid(light) or not light.is_inside_tree():
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	if _is_under(light, _owned_roots(scene)):
		_show_light(light)
	elif not _is_protected(light, scene.get_node_or_null("Player")):
		_silence_light(light)


# ------------------------------------------------------------------ environment

## Swap the live WorldEnvironment to `target`, tweening the mood properties
## from the current look. The tween belongs to the SceneTree so it survives
## this room being freed mid-blend.
static func _blend_environment(world_env: WorldEnvironment, target: Environment, seconds: float) -> Environment:
	var from_env: Environment = world_env.environment
	world_env.environment = target
	if from_env == null or seconds <= 0.01:
		return target
	var properties := [
		"ambient_light_color", "ambient_light_energy", "background_color",
		"fog_light_color", "fog_light_energy", "fog_density", "tonemap_exposure",
	]
	var goals := {}
	for property in properties:
		goals[property] = target.get(property)
		target.set(property, from_env.get(property))
	var tween := world_env.get_tree().create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for property in properties:
		tween.tween_property(target, property, goals[property], seconds)
	return target


func _live_world_environment(scene: Node) -> WorldEnvironment:
	# The persistent scene's own WorldEnvironment is the one Godot renders with.
	var direct := scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if direct != null:
		return direct
	for node in scene.find_children("*", "WorldEnvironment", true, false):
		return node as WorldEnvironment
	return null


func _player() -> Node3D:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return null
	return tree.current_scene.get_node_or_null("Player") as Node3D
