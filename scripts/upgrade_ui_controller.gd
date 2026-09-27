extends Node3D

## World-side upgrade interaction: finds the three hub tables, shows the
## proximity prompt, pauses the hub while a table is open and routes INSTALL.
## What each table shows and sells is data in UpgradeManager; the plate itself
## is built by scripts/ui/upgrade_terminal.gd.

const INTERACTION_LAYER: int = 1 << 20
const MAX_INTERACTION_DISTANCE: float = 3.65

var player: CharacterBody3D = null
var interaction_areas: Array[Area3D] = []
var nearby_upgrade_type: String = ""
var active_upgrade_type: String = ""
var terminal: UpgradeTerminal = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_setup")

func _setup() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	player = scene.get_node_or_null("Player") as CharacterBody3D
	terminal = scene.get_node_or_null("HUD/UpgradeTerminal") as UpgradeTerminal
	if terminal != null:
		if not terminal.prompt_pressed.is_connected(_open_nearby_upgrade):
			terminal.prompt_pressed.connect(_open_nearby_upgrade)
		if not terminal.close_pressed.is_connected(close_popup):
			terminal.close_pressed.connect(close_popup)
		if not terminal.install_pressed.is_connected(_purchase_active_upgrade):
			terminal.install_pressed.connect(_purchase_active_upgrade)
	_create_interaction_area("weapon", "Weapons Upgrde Table")
	_create_interaction_area("survivor", "Health Upgrades Table")
	_create_interaction_area("earnings", "Zombie Multiplier Table")

func _process(_delta: float) -> void:
	_update_nearby_table()

func _input(event: InputEvent) -> void:
	if not is_popup_open():
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			close_popup()
			get_viewport().set_input_as_handled()

func _create_interaction_area(upgrade_type: String, table_name: String) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var table: Node3D = scene.find_child(table_name, true, false) as Node3D
	if table == null:
		push_warning("Upgrade table not found: %s" % table_name)
		return
	var area := Area3D.new()
	area.name = "UpgradeArea_%s" % upgrade_type
	area.collision_layer = INTERACTION_LAYER
	area.collision_mask = 0
	area.input_ray_pickable = true
	area.set_meta("upgrade_type", upgrade_type)
	add_child(area)
	area.global_position = table.global_position + Vector3(0.0, 0.9, 0.0)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.45
	shape.shape = sphere
	area.add_child(shape)
	interaction_areas.append(area)

func _update_nearby_table() -> void:
	if terminal == null:
		return
	if player == null or is_popup_open() or RunManager.run_active or get_tree().paused:
		nearby_upgrade_type = ""
		terminal.set_prompt_visible(false)
		return
	var closest_distance := INF
	var closest_type := ""
	for area in interaction_areas:
		if not is_instance_valid(area):
			continue
		var player_flat := Vector2(player.global_position.x, player.global_position.z)
		var area_flat := Vector2(area.global_position.x, area.global_position.z)
		var distance := player_flat.distance_to(area_flat)
		if distance <= MAX_INTERACTION_DISTANCE and distance < closest_distance:
			closest_distance = distance
			closest_type = String(area.get_meta("upgrade_type", ""))
	nearby_upgrade_type = closest_type
	if nearby_upgrade_type.is_empty():
		terminal.set_prompt_visible(false)
	else:
		terminal.set_prompt_visible(true, "TAP TO ACCESS  //  %s" % terminal.table_name(nearby_upgrade_type))

func is_popup_open() -> bool:
	return terminal != null and terminal.is_popup_open()

func try_screen_interaction(screen_pos: Vector2, camera: Camera3D, player_position: Vector3) -> bool:
	if is_popup_open() or camera == null or RunManager.run_active:
		return false
	if terminal != null and terminal.interaction_prompt != null and terminal.interaction_prompt.visible:
		if terminal.interaction_prompt.get_global_rect().grow(18.0).has_point(screen_pos):
			_open_nearby_upgrade()
			return true
	if _is_mobile():
		return false
	var from: Vector3 = camera.project_ray_origin(screen_pos)
	var to: Vector3 = from + camera.project_ray_normal(screen_pos) * 7.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = INTERACTION_LAYER
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var area := hit.get("collider") as Area3D
	if area == null or player_position.distance_to(area.global_position) > MAX_INTERACTION_DISTANCE:
		return false
	var upgrade_type := String(area.get_meta("upgrade_type", ""))
	if upgrade_type.is_empty():
		return false
	open_upgrade(upgrade_type)
	return true

func try_center_interaction(camera: Camera3D, player_position: Vector3) -> bool:
	if not nearby_upgrade_type.is_empty():
		open_upgrade(nearby_upgrade_type)
		return true
	if camera == null:
		return false
	return try_screen_interaction(camera.get_viewport().get_visible_rect().size * 0.5, camera, player_position)

func _open_nearby_upgrade() -> void:
	if not nearby_upgrade_type.is_empty():
		open_upgrade(nearby_upgrade_type)

func open_upgrade(upgrade_type: String) -> void:
	if terminal == null or upgrade_type.is_empty():
		return
	active_upgrade_type = upgrade_type
	terminal.open_popup(upgrade_type)
	if player != null and player.has_method("set_upgrade_modal_active"):
		player.call("set_upgrade_modal_active", true)
	get_tree().paused = true
	if not _is_mobile():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_popup() -> void:
	if terminal != null:
		terminal.close_popup()
	active_upgrade_type = ""
	get_tree().paused = false
	if player != null and player.has_method("set_upgrade_modal_active"):
		player.call("set_upgrade_modal_active", false)
	if not _is_mobile():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _purchase_active_upgrade() -> void:
	if terminal == null or active_upgrade_type.is_empty():
		return
	if terminal.purchase_selected():
		if player != null and player.has_method("refresh_persistent_upgrades"):
			player.call("refresh_persistent_upgrades")

func _is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.get_name() == "iOS" or OS.get_name() == "Android"
