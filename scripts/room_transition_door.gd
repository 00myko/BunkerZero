extends Node3D

## Animated Room 1 blast-door transition.
##
## The Living Quarters is streamed before interaction as the player approaches.
## The closed blast door hides the transition while ResourceLoader performs the
## expensive resource work on a background thread.

@export var player_path: NodePath
@export var destination_room_path: NodePath
@export var door_visual_path: NodePath
@export var animated_door_path: NodePath
@export var interaction_anchor_path: NodePath
@export_file("*.tscn") var destination_scene_path := "res://scenes/Room 1 Infested Living Quarters.tscn"
@export var door_open_sound: AudioStream = preload("res://assets/Audio/Sliding Door Open.ogg")
@export var door_close_sound: AudioStream = preload("res://assets/Audio/Sliding Door Open.ogg")
@export var previous_room_path: NodePath
@export var unload_previous_room_on_close := true
@export var notify_destination_on_crossing := false
@export_range(0, 20, 1) var required_cleared_combat_room := 0
@export var crossing_direction := Vector3(0.0, 0.0, -1.0)
## When true, crossing_direction is read in this door node's local space, so it
## stays correct after the room is rotated into place by door alignment.
@export var crossing_direction_is_local := false
@export var destination_alignment_marker_name := ""
@export var flip_destination_at_door := false
## Invisible seam floor laid across the threshold. Defaults are the original
## floor-level doors. A raised door (Cafeteria stair landing) keeps it on the
## destination side so it cannot become a ledge beside the landing.
@export var threshold_floor_size := Vector3(4.4, 0.34, 4.8)
@export var threshold_floor_forward_offset := 0.55
@export_range(0.45, 0.85, 0.01) var open_duration := 0.65
@export_range(0.0, 0.6, 0.01) var close_delay := 0.20
@export_range(0.45, 0.85, 0.01) var close_duration := 0.65
@export_range(0.25, 0.55, 0.01) var load_start_delay := 0.30
@export_range(0.45, 0.85, 0.01) var transfer_delay := 0.62
@export_range(2.0, 4.0, 0.05) var auto_door_scale := 3.25
@export_range(1.5, 4.0, 0.05) var interact_distance := 2.40
@export_range(3.0, 12.0, 0.25) var preload_distance := 6.0
@export_range(0.75, 2.5, 0.05) var hub_unload_clearance := 0.95

const OPEN_ANIMATION := &"open"
const DOOR_ASSET_CANDIDATES: PackedStringArray = [
	"res://assets/Bunker Door/animated Blast Door.glb",
	"res://assets/bunker Door/animated Blast Door.glb",
]

var player: CharacterBody3D = null
var destination_room: Node = null
var safe_hub_root: Node3D = null
var previous_room_root: Node3D = null
var destination_seam_door: Node3D = null
var legacy_door_visual: Node3D = null
var animated_door_root: Node3D = null
var interaction_anchor: Node3D = null
var door_animation_player: AnimationPlayer = null
var left_door_leaf: Node3D = null
var right_door_leaf: Node3D = null
var left_leaf_closed_position := Vector3.ZERO
var right_leaf_closed_position := Vector3.ZERO
var door_motion_tween: Tween = null
var blocker_shape: CollisionShape3D = null
var prompt_button: Button = null
var prompt_is_hud_managed := false
var door_audio: AudioStreamPlayer3D = null

var unlocked := false
var transitioning := false
var transition_finishing := false
var transition_elapsed := 0.0
var load_started := false
var room_ready := false
var threaded_load_active := false
var blocker_released := false
var safe_hub_unloaded := false
var exit_sequence_started := false
var closing_behind_player := false
var closing_elapsed := 0.0
var destination_notified := false
var open_requested_while_loading := false
var destination_ready_xform := Transform3D.IDENTITY
var destination_parked := false


func _enter_tree() -> void:
	add_to_group("room_transition_door")


func _ready() -> void:
	player = _resolve_player()
	destination_room = get_node_or_null(destination_room_path)
	room_ready = destination_room != null
	var scene := get_tree().current_scene
	if scene != null:
		safe_hub_root = scene.find_child("SafeHubRoot", true, false) as Node3D
	previous_room_root = _resolve_previous_room_root()
	if not door_visual_path.is_empty():
		legacy_door_visual = get_node_or_null(door_visual_path) as Node3D
	blocker_shape = get_node_or_null("LockedBlocker/CollisionShape3D") as CollisionShape3D
	_resolve_or_create_animated_door()
	_align_locked_blocker_to_visible_door()
	if not interaction_anchor_path.is_empty():
		interaction_anchor = get_node_or_null(interaction_anchor_path) as Node3D
	if interaction_anchor == null:
		interaction_anchor = animated_door_root
	_prepare_door_audio()
	_build_prompt_ui()
	# Room 1 must not contribute a second door at the shared seam.  Run after all
	# scene children finish entering the tree so an accidentally duplicated GLB
	# cannot hide the controlled door or leave a second collision in the opening.
	call_deferred("_remove_overlapping_duplicate_doors")


func _process(delta: float) -> void:
	_update_proximity_preload()
	if threaded_load_active:
		_poll_threaded_room_load()
	if transitioning:
		_update_transition(delta)
	elif unlocked and not closing_behind_player and not exit_sequence_started:
		if Engine.get_process_frames() % 2 == 0:
			_clear_doorway_passage()
	elif prompt_button != null and not prompt_is_hud_managed:
		prompt_button.visible = _can_interact() and not _is_mobile_platform()
	if closing_behind_player:
		_update_closing_behind_player(delta)
	_try_unload_safe_hub_after_crossing()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_E and _can_interact():
			get_viewport().set_input_as_handled()
			_begin_opening(false)


func _can_interact() -> bool:
	return room_ready and _can_request_interaction()


func _can_request_interaction() -> bool:
	if unlocked or transitioning or player == null or get_tree().paused or not is_access_granted():
		return false
	# Always use the live transform of the animated GLB. The interaction follows
	# the door automatically when its position, rotation, or scale is edited.
	var anchor_position := global_position
	if interaction_anchor != null and is_instance_valid(interaction_anchor):
		anchor_position = interaction_anchor.global_position
	var flat_delta := Vector2(
		player.global_position.x - anchor_position.x,
		player.global_position.z - anchor_position.z
	)
	return flat_delta.length() <= interact_distance


func is_access_granted() -> bool:
	if required_cleared_combat_room <= 0:
		return true
	if RunManager.is_combat_room_cleared(required_cleared_combat_room):
		return true
	var scene := get_tree().current_scene
	if scene == null:
		return false
	return bool(scene.get_meta("combat_room_%d_cleared" % required_cleared_combat_room, false))

func notify_combat_room_cleared(combat_room: int) -> void:
	if combat_room != required_cleared_combat_room:
		return
	_refresh_runtime_references()
	if not room_ready:
		_begin_room_readiness()


## Public, HUD-safe interaction API.  The HUD owns presentation while this
## controller remains the single owner of animation, loading, and collision.
## References are refreshed here so a stale editor NodePath cannot permanently
## disable the door after the visible GLB is moved, resized, or replaced.
func request_open_from_hud() -> bool:
	_refresh_runtime_references()
	_remove_overlapping_duplicate_doors()
	if not _can_request_interaction():
		return false
	if not room_ready:
		open_requested_while_loading = true
		_begin_room_readiness()
		return true
	return _begin_opening(true)


func is_destination_ready() -> bool:
	return room_ready or (destination_room != null and is_instance_valid(destination_room))


func is_destination_loading() -> bool:
	return load_started and not is_destination_ready()


func is_door_unlocked() -> bool:
	return unlocked


func is_door_transitioning() -> bool:
	return transitioning


func can_interact_from_hud() -> bool:
	_refresh_runtime_references()
	return _can_request_interaction()


func get_door_visual_root() -> Node3D:
	return animated_door_root


func get_interaction_world_position() -> Vector3:
	if interaction_anchor != null and is_instance_valid(interaction_anchor):
		# The imported model origin is at floor level.  This local offset places
		# the screen prompt across the centre of the scaled door panels.
		return interaction_anchor.global_transform * Vector3(0.0, 0.46, 0.0)
	return global_position + Vector3.UP * 1.35


func get_live_player() -> CharacterBody3D:
	if player == null or not is_instance_valid(player):
		player = _resolve_player()
	return player


func _refresh_runtime_references() -> void:
	if player == null or not is_instance_valid(player):
		player = _resolve_player()
	if destination_room == null or not is_instance_valid(destination_room):
		if not destination_room_path.is_empty():
			destination_room = get_node_or_null(destination_room_path)
	if blocker_shape == null or not is_instance_valid(blocker_shape):
		blocker_shape = get_node_or_null("LockedBlocker/CollisionShape3D") as CollisionShape3D
	if animated_door_root == null or not is_instance_valid(animated_door_root) or \
			door_animation_player == null or not is_instance_valid(door_animation_player):
		_resolve_or_create_animated_door()
		_align_locked_blocker_to_visible_door()
	if interaction_anchor == null or not is_instance_valid(interaction_anchor):
		if not interaction_anchor_path.is_empty():
			interaction_anchor = get_node_or_null(interaction_anchor_path) as Node3D
		if interaction_anchor == null:
			interaction_anchor = animated_door_root


func _resolve_player() -> CharacterBody3D:
	var configured := get_node_or_null(player_path) as CharacterBody3D
	if configured != null:
		return configured

	# Newer project layouts may move the transition controller without preserving
	# the old ../Player relative path. Resolve the existing player by name before
	# giving up, without changing or duplicating the player scene.
	var scene := get_tree().current_scene
	if scene != null:
		var named_player := scene.find_child("Player", true, false) as CharacterBody3D
		if named_player != null:
			return named_player

		for node in scene.find_children("*", "CharacterBody3D", true, false):
			var body := node as CharacterBody3D
			if body == null:
				continue
			var body_script := body.get_script() as Script
			if body_script != null:
				var script_path := body_script.resource_path.to_lower()
				if script_path.ends_with("/player.gd"):
					return body

	push_error("Blast door interaction could not locate the Player node.")
	return null


func _build_prompt_ui() -> void:
	var scene := get_tree().current_scene
	if scene != null:
		prompt_button = scene.get_node_or_null("HUD/DoorInteractButton") as Button
		prompt_is_hud_managed = prompt_button != null
	if prompt_button == null:
		push_error("HUD/DoorInteractButton is missing; creating a runtime fallback.")
		prompt_button = _create_fallback_prompt_button()
		prompt_is_hud_managed = false
	if not prompt_is_hud_managed and not prompt_button.pressed.is_connected(_begin_opening):
		prompt_button.pressed.connect(_begin_opening)
	prompt_button.disabled = false
	prompt_button.visible = false

func _create_fallback_prompt_button() -> Button:
	var scene := get_tree().current_scene
	var hud: Node = null
	if scene != null:
		hud = scene.get_node_or_null("HUD")
	var fallback := Button.new()
	fallback.name = "DoorInteractButtonFallback"
	fallback.text = "E / TAP   OPEN BLAST DOOR"
	fallback.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	fallback.offset_left = -195.0
	fallback.offset_top = -110.0
	fallback.offset_right = 195.0
	fallback.offset_bottom = -48.0
	fallback.add_theme_font_size_override("font_size", 20)
	fallback.z_index = 500
	if hud != null:
		hud.add_child(fallback)
	else:
		var emergency_layer := CanvasLayer.new()
		emergency_layer.layer = 80
		add_child(emergency_layer)
		emergency_layer.add_child(fallback)
	return fallback


func _is_mobile_platform() -> bool:
	return OS.has_feature("mobile") or OS.get_name() == "iOS" or OS.get_name() == "Android"


func _align_locked_blocker_to_visible_door() -> void:
	if animated_door_root == null or not is_instance_valid(animated_door_root):
		return
	var blocker_body := get_node_or_null("LockedBlocker") as StaticBody3D
	if blocker_body == null:
		return
	# The old Room 1 blocker sat behind the rendered panel, allowing the player's
	# camera to cross the mesh and see through its back face. Match the live door
	# origin/rotation while keeping an unscaled collision body and authored shape.
	var door_basis := animated_door_root.global_transform.basis.orthonormalized()
	blocker_body.global_transform = Transform3D(
		door_basis,
		animated_door_root.global_position
	)


func _resolve_or_create_animated_door() -> void:
	var configured_door: Node3D = null
	if not animated_door_path.is_empty():
		configured_door = get_node_or_null(animated_door_path) as Node3D
	if configured_door != null:
		door_animation_player = _find_open_animation_player(configured_door)
		if door_animation_player != null:
			animated_door_root = configured_door

	# The current authored scene names this exact placed instance. Resolve it
	# directly before attempting any generic AnimationPlayer search.
	if door_animation_player == null:
		var current_scene := get_tree().current_scene
		if current_scene != null:
			# Prefer the doorway owned directly by main.tscn.  A room scene may
			# accidentally contain another node with the same name underneath it.
			var named_door := current_scene.get_node_or_null("Animated Blast Door") as Node3D
			if named_door == null:
				named_door = current_scene.find_child("Animated Blast Door", true, false) as Node3D
			if named_door != null:
				door_animation_player = _find_open_animation_player(named_door)
				if door_animation_player != null:
					animated_door_root = named_door

	# Prefer the exact imported door. This avoids accidentally selecting an
	# AnimationPlayer belonging to a weapon, zombie, or other animated prop.
	if door_animation_player == null:
		var scene := get_tree().current_scene
		if scene != null:
			for node in scene.find_children("*", "AnimationPlayer", true, false):
				var candidate := node as AnimationPlayer
				if candidate == null or not candidate.has_animation(OPEN_ANIMATION):
					continue
				var imported_root := _find_imported_scene_root(candidate)
				if imported_root != null and \
						"animated blast door" in imported_root.scene_file_path.to_lower():
					door_animation_player = candidate
					animated_door_root = imported_root
					break

	# If the GLB was copied into the project but not instanced in main.tscn, place
	# it at this controller's transform. The known model is authored at ground
	# level and one metre wide, so a 3.25 uniform scale fits the existing opening.
	if door_animation_player == null:
		var usable_path := _find_door_asset_path()
		if not usable_path.is_empty():
			var packed := load(usable_path) as PackedScene
			if packed != null:
				var instance := packed.instantiate() as Node3D
				if instance != null:
					instance.name = "AnimatedBlastDoor"
					instance.scale = Vector3.ONE * auto_door_scale
					add_child(instance)
					animated_door_root = instance
					door_animation_player = _find_open_animation_player(instance)

	if door_animation_player == null:
		push_warning(
			"Animated blast door could not be found. The room transition will still work, " +
			"but the door cannot visually open."
		)
		return

	_resolve_door_leaves()

	# Replace the old static door art only after the animated asset was found.
	if legacy_door_visual != null and legacy_door_visual != animated_door_root:
		legacy_door_visual.visible = false

	# Force the imported animation to its closed first frame, regardless of the
	# GLB importer's autoplay state.
	door_animation_player.play(OPEN_ANIMATION)
	door_animation_player.seek(0.0, true)
	door_animation_player.pause()
	_make_door_double_sided(animated_door_root)


func _resolve_door_leaves() -> void:
	if animated_door_root == null or not is_instance_valid(animated_door_root):
		return
	left_door_leaf = animated_door_root.find_child("Left Door Leaf", true, false) as Node3D
	right_door_leaf = animated_door_root.find_child("Right Door Leaf", true, false) as Node3D
	if left_door_leaf != null:
		left_leaf_closed_position = left_door_leaf.position
	if right_door_leaf != null:
		right_leaf_closed_position = right_door_leaf.position


func _remove_overlapping_duplicate_doors() -> void:
	if animated_door_root == null or not is_instance_valid(animated_door_root):
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var removed_count := 0
	for node in scene.find_children("*", "Node3D", true, false):
		var candidate := node as Node3D
		if candidate == null or candidate == animated_door_root:
			continue
		if animated_door_root.is_ancestor_of(candidate):
			continue
		if destination_room != null and is_instance_valid(destination_room) and destination_room.is_ancestor_of(candidate):
			continue
		var candidate_name := String(candidate.name).to_lower()
		var candidate_source := candidate.scene_file_path.to_lower()
		var is_door_root := (
			candidate_name.begins_with("animated blast door")
			or candidate_name.begins_with("animatedblastdoor")
			or "animated blast door" in candidate_source
		)
		if not is_door_root:
			continue
		if candidate.global_position.distance_to(animated_door_root.global_position) > 1.25:
			continue
		# Hide immediately, then free the entire duplicate imported hierarchy. Any
		# generated mesh collisions beneath it are removed with the same root.
		candidate.visible = false
		candidate.process_mode = Node.PROCESS_MODE_DISABLED
		candidate.queue_free()
		removed_count += 1
	if removed_count > 0:
		print("BLAST DOOR: removed %d overlapping Room 1 door duplicate(s)." % removed_count)


func _find_door_asset_path() -> String:
	for candidate in DOOR_ASSET_CANDIDATES:
		if ResourceLoader.exists(candidate):
			return candidate
	return ""


func _find_open_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		var direct := root as AnimationPlayer
		if direct.has_animation(OPEN_ANIMATION):
			return direct
	for child in root.get_children():
		var found := _find_open_animation_player(child)
		if found != null:
			return found
	return null


func _find_imported_scene_root(node: Node) -> Node3D:
	var current := node
	while current != null:
		if current is Node3D:
			var source := current.scene_file_path.to_lower()
			if source.ends_with(".glb") or source.ends_with(".gltf"):
				return current as Node3D
		current = current.get_parent()
	return null


func _prepare_door_audio() -> void:
	if door_open_sound == null:
		return
	door_audio = AudioStreamPlayer3D.new()
	door_audio.name = "BlastDoorOpenAudio"
	door_audio.stream = door_open_sound
	door_audio.volume_db = -2.0
	door_audio.unit_size = 5.0
	door_audio.max_distance = 20.0
	door_audio.attenuation_filter_cutoff_hz = 10000.0
	add_child(door_audio)


func _begin_opening(validated_by_hud: bool = false) -> bool:
	if unlocked or transitioning or get_tree().paused:
		return false
	if not is_access_granted():
		return false
	if not room_ready:
		open_requested_while_loading = validated_by_hud
		_begin_room_readiness()
		return validated_by_hud
	if not _can_request_interaction():
		return false
	open_requested_while_loading = false
	transitioning = true
	transition_finishing = false
	transition_elapsed = 0.0
	blocker_released = false
	_unpark_streamed_destination()
	_set_connecting_door_solid(false)
	_disable_generated_door_collisions()
	_release_doorway_blocker()
	_clear_doorway_passage()
	call_deferred("_clear_doorway_passage")

	if prompt_button != null:
		prompt_button.visible = not _is_mobile_platform()
		prompt_button.disabled = true
		prompt_button.text = "OPENING..."

	_apply_door_feedback()
	if door_audio != null:
		door_audio.play()

	# Drive the actual imported GLB leaves directly.  The source animation moves
	# Left Door Leaf from X 0 to -0.445 and Right Door Leaf from X 0 to +0.445.
	# Using the same endpoints through the configured 0.65-second tween avoids any
	# AnimationPlayer/import-name failure while preserving the authored motion.
	if left_door_leaf != null and right_door_leaf != null:
		if door_animation_player != null:
			door_animation_player.stop()
		if door_motion_tween != null and door_motion_tween.is_valid():
			door_motion_tween.kill()
		door_motion_tween = create_tween().set_parallel(true)
		door_motion_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		door_motion_tween.tween_property(
			left_door_leaf,
			"position",
			left_leaf_closed_position + Vector3(-0.445, 0.0, 0.0),
			open_duration
		)
		door_motion_tween.tween_property(
			right_door_leaf,
			"position",
			right_leaf_closed_position + Vector3(0.445, 0.0, 0.0),
			open_duration
		)
	elif door_animation_player != null:
		var animation := door_animation_player.get_animation(OPEN_ANIMATION)
		var source_length := animation.length if animation != null else 2.2
		var playback_speed := source_length / maxf(open_duration, 0.01)
		door_animation_player.play(OPEN_ANIMATION, 0.04, playback_speed)
	else:
		push_error("Blast door accepted interaction but has no usable leaves or open animation.")

	print("BLAST DOOR: interaction accepted; opening sequence started.")
	return true


func _apply_door_feedback() -> void:
	# Door feedback belongs to the door system, not player.gd. Reuse the player's
	# existing damped recoil spring without adding another player responsibility.
	if player != null:
		var recoil_value: Variant = player.get("camera_recoil_velocity")
		if typeof(recoil_value) == TYPE_FLOAT:
			player.set(
				"camera_recoil_velocity",
				float(recoil_value) - deg_to_rad(0.65)
			)
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(32, 0.42)


func _update_proximity_preload() -> void:
	if room_ready:
		return
	if destination_room != null and is_instance_valid(destination_room):
		room_ready = true
		return
	if load_started or player == null or not is_instance_valid(player):
		return
	var anchor_position := global_position
	if interaction_anchor != null and is_instance_valid(interaction_anchor):
		anchor_position = interaction_anchor.global_position
	var flat_distance := Vector2(
		player.global_position.x - anchor_position.x,
		player.global_position.z - anchor_position.z
	).length()
	if flat_distance <= preload_distance:
		print("BLAST DOOR: player entered preload radius; streaming destination.")
		_begin_room_readiness()


func _update_transition(delta: float) -> void:
	transition_elapsed += delta
	if not blocker_released and transition_elapsed >= open_duration * 0.45:
		_release_doorway_blocker()

	if not load_started and transition_elapsed >= load_start_delay:
		_begin_room_readiness()

	if room_ready and transition_elapsed >= transfer_delay and not transition_finishing:
		transition_finishing = true
		_finish_transition()


func _begin_room_readiness() -> void:
	if room_ready or load_started:
		return
	if destination_room != null and is_instance_valid(destination_room):
		room_ready = true
		return
	load_started = true

	if destination_scene_path.is_empty() or not ResourceLoader.exists(destination_scene_path):
		push_error("Blast door destination scene does not exist: %s" % destination_scene_path)
		_show_load_failure()
		return

	var request_error := ResourceLoader.load_threaded_request(
		destination_scene_path,
		"PackedScene"
	)
	if request_error != OK:
		load_started = false
		push_error("Could not begin threaded room load (error %d)." % request_error)
		_show_load_failure()
		return
	threaded_load_active = true


func _poll_threaded_room_load() -> void:
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(destination_scene_path, progress)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		if prompt_button != null and not progress.is_empty():
			prompt_button.text = "PREPARING ROOM...  %d%%" % int(float(progress[0]) * 100.0)
		return

	threaded_load_active = false
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("Threaded room load failed with status %d." % status)
		_show_load_failure()
		return

	var packed := ResourceLoader.load_threaded_get(destination_scene_path) as PackedScene
	if packed == null:
		push_error("Threaded room resource was not a PackedScene.")
		_show_load_failure()
		return

	var instance := packed.instantiate()
	var scene := get_tree().current_scene
	if instance == null or scene == null:
		push_error("Loaded room could not be instantiated into the active scene.")
		_show_load_failure()
		return
	# Keep the room visible in-tree so GLB box collision can be built, but park
	# it far from the live doorway. Hiding or zeroing collision layers skipped
	# floors/props and let the player fall through Room 2.
	scene.add_child(instance)
	destination_room = instance
	_align_destination_to_door()
	_park_streamed_destination()
	call_deferred("_remove_overlapping_duplicate_doors")
	# Dynamically added imported furniture was not present during the global
	# collision builder's startup passes. Re-run its idempotent pass before the
	# room controller performs its delayed, collision-safe zombie placement.
	_rebuild_world_collision()
	room_ready = true
	print("BLAST DOOR: destination room proximity preload completed.")
	if open_requested_while_loading:
		call_deferred("_open_after_background_load")


func _open_after_background_load() -> void:
	if not open_requested_while_loading:
		return
	open_requested_while_loading = false
	_begin_opening(false)


func _align_destination_to_door() -> void:
	if destination_alignment_marker_name.is_empty() or destination_room == null or not (destination_room is Node3D):
		return
	var marker := destination_room.find_child(destination_alignment_marker_name, true, false) as Node3D
	if marker == null or animated_door_root == null:
		push_warning("Blast door could not align destination marker: " + destination_alignment_marker_name)
		return
	var room_root := destination_room as Node3D
	var marker_relative := room_root.global_transform.affine_inverse() * marker.global_transform
	var desired_marker := animated_door_root.global_transform
	if flip_destination_at_door:
		desired_marker.basis = desired_marker.basis.rotated(Vector3.UP, PI)
	room_root.global_transform = desired_marker * marker_relative.affine_inverse()
	destination_seam_door = marker
	_match_destination_floor_height()
	_ensure_threshold_floor()
	# Keep one live door at the seam. The destination copy stays hidden so the
	# authored door can be seen from both rooms without a second overlapping GLB.
	destination_seam_door.visible = false
	destination_seam_door.process_mode = Node.PROCESS_MODE_DISABLED
	_disable_node_collision(destination_seam_door)
	_make_door_double_sided(animated_door_root)
	_mark_doorway_walls()
	print("BLAST DOOR: destination aligned to authored doorway marker.")


func _park_streamed_destination() -> void:
	if destination_room == null or not (destination_room is Node3D):
		return
	var room := destination_room as Node3D
	destination_ready_xform = room.global_transform
	destination_parked = true
	room.set_meta("stream_parked", true)
	# Unique park slot per door so two preloaded rooms cannot stack.
	var park_sign := 1.0 if destination_alignment_marker_name.is_empty() else -1.0
	room.global_position = Vector3(140.0 * park_sign, -240.0, 140.0 * park_sign)
	room.force_update_transform()
	print("BLAST DOOR: destination parked off-stage until the door opens.")


func _unpark_streamed_destination() -> void:
	if not destination_parked or destination_room == null or not (destination_room is Node3D):
		return
	var room := destination_room as Node3D
	var parked_xform := room.global_transform
	var physics_bodies: Array[Node3D] = []
	var physics_xforms: Array[Transform3D] = []
	for node in room.find_children("*", "PhysicsBody3D", true, false):
		var body := node as Node3D
		if body == null:
			continue
		physics_bodies.append(body)
		physics_xforms.append(body.global_transform)
	room.global_transform = destination_ready_xform
	room.force_update_transform()
	var delta := destination_ready_xform * parked_xform.affine_inverse()
	for i in range(physics_bodies.size()):
		var body := physics_bodies[i]
		if not is_instance_valid(body):
			continue
		body.global_transform = delta * physics_xforms[i]
		if body is CharacterBody3D:
			(body as CharacterBody3D).velocity = Vector3.ZERO
	destination_parked = false
	room.set_meta("stream_parked", false)
	room.set_meta("stream_ready", true)
	_ensure_threshold_floor()
	_rebuild_world_collision()
	if room.has_method("on_destination_revealed"):
		room.call("on_destination_revealed")
	print("BLAST DOOR: destination restored at the doorway.")


func _rebuild_world_collision() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	for solidifier in scene.find_children("WorldCollisionBuilder", "", true, false):
		if solidifier != null and solidifier.has_method("_build_glb_collisions"):
			solidifier._build_glb_collisions()
			solidifier.call_deferred("_build_glb_collisions")
	call_deferred("_clear_doorway_passage")


func _finish_transition() -> void:
	# The destination now stays physically connected. Opening the door removes
	# the blocker and lets the player walk across the threshold; player.gd starts
	# the combat run only after that crossing, so no teleport or camera fade occurs.
	unlocked = true
	_release_doorway_blocker()
	_clear_doorway_passage()
	transitioning = false
	if prompt_button != null:
		prompt_button.visible = false


func _release_doorway_blocker() -> void:
	blocker_released = true
	if blocker_shape != null and is_instance_valid(blocker_shape):
		blocker_shape.set_deferred("disabled", true)


func _disable_generated_door_collisions() -> void:
	if animated_door_root == null or not is_instance_valid(animated_door_root):
		return
	_disable_node_collision(animated_door_root)


func _disable_node_collision(root: Node) -> void:
	if root == null or not is_instance_valid(root):
		return
	var nodes: Array[Node] = [root]
	nodes.append_array(root.find_children("*", "CollisionObject3D", true, false))
	for node in nodes:
		var collider := node as CollisionObject3D
		if collider == null:
			continue
		if String(collider.name).begins_with("ClosedDoorSolid"):
			continue
		collider.collision_layer = 0
		collider.collision_mask = 0
		for child in collider.find_children("*", "CollisionShape3D", true, false):
			var collision := child as CollisionShape3D
			if collision != null:
				collision.disabled = true


func _mark_doorway_walls() -> void:
	if destination_room == null or destination_seam_door == null:
		return
	var door_xz := Vector2(destination_seam_door.position.x, destination_seam_door.position.z)
	for child in destination_room.get_children():
		if not (child is Node3D):
			continue
		var child_name := String(child.name)
		if not child_name.begins_with("Kitchen Walls") and not child_name.begins_with("Door from"):
			continue
		var child_xz := Vector2((child as Node3D).position.x, (child as Node3D).position.z)
		# Only the wall module sitting in the opening. A 4.5 m radius was
		# stripping collision from the adjacent Room 2 walls, which let the
		# player walk halfway through them.
		if child_xz.distance_to(door_xz) > 1.15:
			continue
		child.set_meta("doorway_wall", true)
		_disable_node_collision(child)


func _clear_doorway_passage() -> void:
	if destination_seam_door != null:
		_disable_node_collision(destination_seam_door)
	_disable_generated_door_collisions()
	_mark_doorway_walls()

	var door: Node3D = animated_door_root if animated_door_root != null else self
	var forward := _crossing_forward()
	var right := forward.cross(Vector3.UP)
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	right = right.normalized()
	var center := door.global_position + Vector3(0.0, 1.2, 0.0) + forward * 0.15

	var box := BoxShape3D.new()
	box.size = Vector3(2.15, 2.55, 1.25)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.transform = Transform3D(Basis(right, Vector3.UP, -forward), center)
	query.collision_mask = 1 | 16
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var space := get_world_3d().direct_space_state
	if space == null:
		return
	for hit in space.intersect_shape(query, 64):
		var collider := hit.get("collider") as CollisionObject3D
		if collider == null or collider is CharacterBody3D:
			continue
		if _is_protected_doorway_collider(collider):
			continue
		collider.collision_layer = 0
		collider.collision_mask = 0
		for child in collider.find_children("*", "CollisionShape3D", true, false):
			var collision := child as CollisionShape3D
			if collision != null:
				collision.disabled = true


func _is_protected_doorway_collider(collider: CollisionObject3D) -> bool:
	var current: Node = collider
	while current != null:
		var node_name := String(current.name)
		if node_name.begins_with("ClosedDoorSolid"):
			return true
		if node_name == "ClosedEntryDoorBlocker" and not unlocked and not transitioning:
			return true
		if node_name == "LockedBlocker":
			return not (unlocked or transitioning)
		if node_name == "RoomStableFloor" or node_name.begins_with("Tile Floor"):
			return true
		if node_name.begins_with("ThresholdFloor"):
			return true
		if node_name.begins_with("RoomPerimeter") or node_name == "RoomPerimeterWalls":
			return true
		current = current.get_parent()
	return false


func _try_unload_safe_hub_after_crossing() -> void:
	if not unlocked or exit_sequence_started:
		return
	if player == null or not is_instance_valid(player):
		player = _resolve_player()
	if player == null or not is_instance_valid(player):
		return
	if not _has_player_crossed_into_destination():
		return

	exit_sequence_started = true
	_activate_destination_lighting()
	_notify_destination_entered()
	_begin_closing_behind_player()
	print("BLAST DOOR: player cleared threshold; closing before previous-room unload.")


## Lighting hands over the instant the player commits through the door, not
## when it finishes closing: the destination's mood takes the environment and
## silences the lights of the room being left (see room_lighting_profile.gd).
func _activate_destination_lighting() -> void:
	if destination_room == null or not is_instance_valid(destination_room):
		return
	var profile := destination_room.get_node_or_null("RoomLightingProfile")
	if profile != null and profile.has_method("activate"):
		profile.call("activate")


func _has_player_crossed_into_destination() -> bool:
	var doorway := global_position
	if animated_door_root != null and is_instance_valid(animated_door_root):
		doorway = animated_door_root.global_position
	var into_destination := _into_destination_direction(doorway)
	var crossed := (player.global_position - doorway).dot(into_destination)
	if crossed >= hub_unload_clearance:
		return true
	# If the authored axis was wrong, still close once the player is clearly
	# standing inside the streamed room and away from the seam.
	if destination_room is Node3D and crossed > 0.35:
		var interior := _destination_interior_position()
		var to_interior := interior - doorway
		to_interior.y = 0.0
		var player_to_interior := interior - player.global_position
		player_to_interior.y = 0.0
		if to_interior.length() > 1.0 and player_to_interior.length() < to_interior.length() - 0.4:
			return true
	return false


func _into_destination_direction(doorway: Vector3) -> Vector3:
	var interior := _destination_interior_position()
	var to_interior := interior - doorway
	to_interior.y = 0.0
	if to_interior.length_squared() >= 0.36:
		return to_interior.normalized()
	return _crossing_forward()


func _destination_interior_position() -> Vector3:
	if destination_room == null or not (destination_room is Node3D) or not is_instance_valid(destination_room):
		return global_position + _crossing_forward() * 4.0
	var room := destination_room as Node3D
	var floor := room.get_node_or_null("RoomStableFloor") as Node3D
	if floor != null:
		return floor.global_position
	var acc := Vector3.ZERO
	var count := 0
	for child in room.get_children():
		if child is Node3D and String(child.name).begins_with("Tile Floor"):
			acc += (child as Node3D).global_position
			count += 1
	if count > 0:
		return acc / float(count)
	return room.to_global(Vector3(0.0, 0.0, 8.0))


func _resolve_previous_room_root() -> Node3D:
	if not previous_room_path.is_empty():
		var configured := get_node_or_null(previous_room_path) as Node3D
		if configured != null:
			return configured
	var scene := get_tree().current_scene
	if scene != null:
		if safe_hub_root == null or not is_instance_valid(safe_hub_root):
			safe_hub_root = scene.find_child("SafeHubRoot", true, false) as Node3D
	var current: Node = get_parent()
	while current != null and current != scene:
		if current.get_parent() == scene and current != destination_room:
			return current as Node3D
		current = current.get_parent()
	if safe_hub_root != null and is_instance_valid(safe_hub_root):
		return safe_hub_root
	return null


func _notify_destination_entered() -> void:
	if destination_notified or not notify_destination_on_crossing:
		return
	destination_notified = true
	if destination_room != null and is_instance_valid(destination_room) and destination_room.has_method("enter_room"):
		destination_room.call("enter_room", player)


func _begin_closing_behind_player() -> void:
	if closing_behind_player:
		return
	closing_behind_player = true
	closing_elapsed = 0.0
	if door_audio != null and door_close_sound != null:
		door_audio.stop()
		door_audio.stream = door_close_sound
		door_audio.pitch_scale = 0.92
		door_audio.play()
	if door_motion_tween != null and door_motion_tween.is_valid():
		door_motion_tween.kill()

	if left_door_leaf != null and is_instance_valid(left_door_leaf) and \
			right_door_leaf != null and is_instance_valid(right_door_leaf):
		door_motion_tween = create_tween().set_parallel(true)
		door_motion_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		door_motion_tween.tween_property(
			left_door_leaf, "position", left_leaf_closed_position, close_duration
		).set_delay(close_delay)
		door_motion_tween.tween_property(
			right_door_leaf, "position", right_leaf_closed_position, close_duration
		).set_delay(close_delay)
	elif door_animation_player != null and is_instance_valid(door_animation_player) and \
			door_animation_player.has_animation(&"close"):
		var close_animation := door_animation_player.get_animation(&"close")
		var source_length := close_animation.length if close_animation != null else 2.2
		var playback_speed := source_length / maxf(close_duration, 0.01)
		door_animation_player.play(&"close", 0.04, playback_speed)
	print("BLAST DOOR: player cleared doorway; automatic close started.")


func _update_closing_behind_player(delta: float) -> void:
	closing_elapsed += delta
	var blocker_time := close_delay + close_duration * 0.45
	if blocker_released and closing_elapsed >= blocker_time:
		blocker_released = false
		if blocker_shape != null and is_instance_valid(blocker_shape):
			blocker_shape.set_deferred("disabled", false)

	if closing_elapsed < close_delay + close_duration:
		return
	closing_behind_player = false
	if left_door_leaf != null and is_instance_valid(left_door_leaf):
		left_door_leaf.position = left_leaf_closed_position
	if right_door_leaf != null and is_instance_valid(right_door_leaf):
		right_door_leaf.position = right_leaf_closed_position
	if blocker_shape != null and is_instance_valid(blocker_shape):
		blocker_shape.set_deferred("disabled", false)
	blocker_released = false
	_set_connecting_door_solid(true)
	print("BLAST DOOR: automatic close completed; doorway secured.")
	_unload_safe_hub_after_door_closed()


func _unload_safe_hub_after_door_closed() -> void:
	if safe_hub_unloaded or not unload_previous_room_on_close:
		return
	safe_hub_unloaded = true
	var unload_target: Node3D = previous_room_root
	if unload_target == null or not is_instance_valid(unload_target):
		unload_target = _resolve_previous_room_root()
		previous_room_root = unload_target
	if unload_target == null or not is_instance_valid(unload_target):
		unload_target = safe_hub_root
	var persist_parent := _persistent_door_parent()
	# Keep this controller and the visible door alive after the old room is freed.
	if persist_parent != null and get_parent() != persist_parent:
		var self_xform := global_transform
		reparent(persist_parent, true)
		global_transform = self_xform
		force_update_transform()
	_preserve_connecting_door()
	if destination_seam_door != null and is_instance_valid(destination_seam_door):
		destination_seam_door.visible = false
		destination_seam_door.process_mode = Node.PROCESS_MODE_DISABLED
		_disable_node_collision(destination_seam_door)
	if blocker_shape != null and is_instance_valid(blocker_shape):
		var blocker_body := blocker_shape.get_parent() as StaticBody3D
		if blocker_body != null and persist_parent != null:
			blocker_body.name = "ClosedEntryDoorBlocker"
			blocker_body.reparent(persist_parent, true)
			blocker_body.collision_layer = 1
			blocker_body.collision_mask = 0
			blocker_shape.disabled = false
	_set_connecting_door_solid(true)
	if unload_target != null and is_instance_valid(unload_target) and unload_target != destination_room and unload_target != persist_parent:
		if unload_target.has_method("unload_hub_content"):
			unload_target.call("unload_hub_content")
		else:
			unload_target.queue_free()
		print("BLAST DOOR: previous room unloaded (%s)." % unload_target.name)
	if required_cleared_combat_room == 1:
		for support_node: Node in get_tree().get_nodes_in_group("room2_builder"):
			if is_instance_valid(support_node):
				support_node.queue_free()
	print("BLAST DOOR: door closed; connecting door kept for the next room.")


func _crossing_forward() -> Vector3:
	var direction := crossing_direction
	if crossing_direction_is_local and is_inside_tree():
		direction = global_transform.basis * crossing_direction
	var forward := Vector3(direction.x, 0.0, direction.z)
	if forward.length_squared() < 0.001:
		forward = Vector3(0.0, 0.0, -1.0)
	return forward.normalized()


func _ray_floor_y(from: Vector3) -> float:
	var space := get_world_3d().direct_space_state
	if space == null:
		return NAN
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3(0.0, -6.0, 0.0), 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return NAN
	var normal: Vector3 = hit.get("normal", Vector3.ZERO)
	if normal.dot(Vector3.UP) < 0.55:
		return NAN
	return float(hit.get("position", Vector3.ZERO).y)


func _match_destination_floor_height() -> void:
	if destination_room == null or not (destination_room is Node3D) or animated_door_root == null:
		return
	var room := destination_room as Node3D
	var forward := _crossing_forward()
	var door_pos := animated_door_root.global_position
	var source_y := _ray_floor_y(door_pos + Vector3(0.0, 2.4, 0.0) - forward * 1.35)
	var dest_y := _ray_floor_y(door_pos + Vector3(0.0, 3.6, 0.0) + forward * 1.8)
	if crossing_direction_is_local:
		# The destination was moved this frame, so its colliders (and the floor
		# meta written at _ready) are stale. Read its stable slab transform.
		var dest_stable := room.get_node_or_null("RoomStableFloor") as Node3D
		if dest_stable != null:
			dest_y = dest_stable.global_position.y + 0.11
			# Both sides in "visible floor" terms: the source ray hit collision
			# that the source room lifts above its tiles.
			if previous_room_root != null and is_instance_valid(previous_room_root):
				source_y -= float(previous_room_root.get_meta("floor_collision_lift", 0.0))
	if is_nan(dest_y) and room.has_meta("room_walk_floor_y"):
		dest_y = float(room.get_meta("room_walk_floor_y"))
	if is_nan(dest_y):
		var stable := room.get_node_or_null("RoomStableFloor") as Node3D
		if stable != null:
			dest_y = stable.global_position.y + 0.11
	if is_nan(source_y):
		source_y = 0.0
	if is_nan(dest_y):
		return
	var delta := source_y - dest_y
	if absf(delta) < 0.03:
		return
	room.global_position.y += delta
	room.force_update_transform()
	if room.has_method("_refresh_walk_floor_meta"):
		room.call("_refresh_walk_floor_meta")
	print("BLAST DOOR: destination floor leveled by %.3f m." % delta)


func _ensure_threshold_floor() -> void:
	var persist := get_tree().current_scene
	if persist == null or animated_door_root == null or not is_instance_valid(animated_door_root):
		return
	var body_name := "ThresholdFloor_%d" % get_instance_id()
	var body := persist.get_node_or_null(body_name) as StaticBody3D
	if body == null:
		body = StaticBody3D.new()
		body.name = body_name
		body.collision_layer = 1
		body.collision_mask = 0
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = threshold_floor_size
		collision.shape = box
		body.add_child(collision)
		persist.add_child(body)
	var door_pos := animated_door_root.global_position
	var forward := _crossing_forward()
	var source_y := _ray_floor_y(door_pos + Vector3(0.0, 2.4, 0.0) - forward * 1.35)
	if is_nan(source_y) and destination_room is Node3D and (destination_room as Node3D).has_meta("room_walk_floor_y"):
		source_y = float((destination_room as Node3D).get_meta("room_walk_floor_y"))
	if is_nan(source_y):
		source_y = door_pos.y + 0.95
	body.global_position = Vector3(door_pos.x, source_y - threshold_floor_size.y * 0.5 + 0.01, door_pos.z) + forward * threshold_floor_forward_offset
	body.force_update_transform()


func _set_connecting_door_solid(solid: bool) -> void:
	var body := _closed_door_solid()
	if body == null:
		return
	if animated_door_root != null and is_instance_valid(animated_door_root):
		var door_basis := animated_door_root.global_transform.basis.orthonormalized()
		body.global_transform = Transform3D(
			door_basis,
			animated_door_root.global_position + Vector3(0.0, 1.45, 0.0)
		)
		var void_floor := body.get_node_or_null("VoidFloor") as CollisionShape3D
		if void_floor != null:
			var back := -_crossing_forward()
			var local_back := door_basis.inverse() * back
			void_floor.position = Vector3(0.0, -1.52, 0.0) + local_back * 0.90
	body.collision_layer = 1 if solid else 0
	body.collision_mask = 0
	for child in body.find_children("*", "CollisionShape3D", true, false):
		var collision := child as CollisionShape3D
		if collision != null:
			collision.disabled = not solid
	if blocker_shape != null and is_instance_valid(blocker_shape):
		var blocker_body := blocker_shape.get_parent() as CollisionObject3D
		if blocker_body != null:
			blocker_body.collision_layer = 1 if solid else 0
			blocker_body.collision_mask = 0
		blocker_shape.disabled = not solid


func _closed_door_solid() -> StaticBody3D:
	var persist := get_tree().current_scene
	if persist == null:
		return null
	var body_name := "ClosedDoorSolid"
	if animated_door_root != null:
		body_name = "ClosedDoorSolid_%d" % animated_door_root.get_instance_id()
	var body := persist.get_node_or_null(body_name) as StaticBody3D
	if body != null:
		return body
	body = StaticBody3D.new()
	body.name = body_name
	body.collision_layer = 1
	body.collision_mask = 0
	var door_col := CollisionShape3D.new()
	door_col.name = "DoorSlab"
	var door_box := BoxShape3D.new()
	door_box.size = Vector3(3.5, 3.2, 0.58)
	door_col.shape = door_box
	body.add_child(door_col)
	var floor_col := CollisionShape3D.new()
	floor_col.name = "VoidFloor"
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(3.6, 0.30, 1.8)
	floor_col.shape = floor_box
	floor_col.position = Vector3(0.0, -1.52, 0.85)
	body.add_child(floor_col)
	persist.add_child(body)
	return body


func _persistent_door_parent() -> Node:
	if destination_room != null and is_instance_valid(destination_room):
		return destination_room
	return get_tree().current_scene


func _preserve_connecting_door() -> void:
	if animated_door_root == null or not is_instance_valid(animated_door_root):
		return
	_make_door_double_sided(animated_door_root)
	animated_door_root.visible = true
	animated_door_root.process_mode = Node.PROCESS_MODE_INHERIT
	var persist_parent := _persistent_door_parent()
	if persist_parent == null or animated_door_root.get_parent() == persist_parent:
		return
	var unload_target: Node = previous_room_root
	if unload_target == null or not is_instance_valid(unload_target):
		unload_target = safe_hub_root
	var parent := animated_door_root.get_parent()
	var will_be_freed := unload_target != null and (
		unload_target == parent or unload_target.is_ancestor_of(animated_door_root)
	)
	if not will_be_freed:
		return
	var xform := animated_door_root.global_transform
	animated_door_root.reparent(persist_parent, true)
	animated_door_root.global_transform = xform
	animated_door_root.force_update_transform()
	print("BLAST DOOR: connecting door kept in the destination room.")


func _make_door_double_sided(door: Node3D) -> void:
	if door == null or not is_instance_valid(door) or door.has_meta("door_double_sided"):
		return
	door.set_meta("door_double_sided", true)
	for node in door.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var source: Material = mesh_instance.get_surface_override_material(surface_index)
			if source == null:
				source = mesh_instance.mesh.surface_get_material(surface_index)
			if source == null:
				var fallback := StandardMaterial3D.new()
				fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
				mesh_instance.set_surface_override_material(surface_index, fallback)
				continue
			var copied := source.duplicate()
			if copied is BaseMaterial3D:
				(copied as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh_instance.set_surface_override_material(surface_index, copied)


func _show_load_failure() -> void:
	load_started = false
	threaded_load_active = false
	transitioning = false
	transition_finishing = false
	if prompt_button != null:
		prompt_button.disabled = false
		prompt_button.text = "ROOM LOAD FAILED — TAP TO RETRY"
		prompt_button.visible = not _is_mobile_platform()
