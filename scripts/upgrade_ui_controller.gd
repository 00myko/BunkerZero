extends Node3D

## World-side upgrade interaction. The popup/prompt layout lives in
## scenes/ui/upgrade_terminal.tscn.

const INTERACTION_LAYER: int = 1 << 20
const MAX_INTERACTION_DISTANCE: float = 3.65
const AMBER := Color(1.0, 0.56, 0.14, 1.0)

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
		if not terminal.buy_pressed.is_connected(_purchase_active_upgrade):
			terminal.buy_pressed.connect(_purchase_active_upgrade)
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
		terminal.set_prompt_visible(true, "TAP TO ACCESS  //  %s" % _table_display_name(nearby_upgrade_type))

func _table_display_name(upgrade_type: String) -> String:
	match upgrade_type:
		"weapon":
			return "WEAPON SYSTEMS"
		"survivor":
			return "SURVIVOR VITALS"
		"earnings":
			return "ZOMBIE PAYOUT"
	return "UPGRADE TERMINAL"

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
	_refresh_popup()
	terminal.open_popup()
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

func _refresh_popup() -> void:
	if terminal == null:
		return
	terminal.bank_label.text = "PLAYER BANK   $%d" % EconomyManager.get_balance()
	var cost := UpgradeManager.get_next_cost(active_upgrade_type)
	var maxed := cost < 0
	terminal.buy_button.disabled = maxed or not EconomyManager.can_afford(cost)
	terminal.buy_button.text = "MAXIMUM LEVEL" if maxed else "INSTALL UPGRADE"
	terminal.cost_label.text = "ALL UPGRADES INSTALLED" if maxed else "UPGRADE COST   $%d" % cost

	var level := 0
	var accent := AMBER
	match active_upgrade_type:
		"weapon":
			level = UpgradeManager.weapon_level
			var current_damage := UpgradeManager.get_pistol_damage()
			var next_damage := current_damage if maxed else UpgradeManager.PISTOL_DAMAGE_BY_LEVEL[level + 1]
			terminal.category_label.text = "A R M O R Y   / /   B A L L I S T I C S"
			terminal.title_label.text = "WEAPON SYSTEMS"
			terminal.subtitle_label.text = "P I S T O L   P E R F O R M A N C E   T U N I N G"
			terminal.level_label.text = "WEAPON LEVEL   %d / 5" % level
			terminal.current_caption.text = "CURRENT DAMAGE"
			terminal.current_value.text = "%.0f  DMG" % current_damage
			terminal.next_caption.text = "NEXT DAMAGE"
			terminal.next_value.text = "MAX" if maxed else "%.0f  DMG" % next_damage
			terminal.description_label.text = "INCREASE BALLISTIC DAMAGE FOR EVERY PISTOL ROUND."
		"survivor":
			accent = Color(0.93, 0.25, 0.16, 1.0)
			level = UpgradeManager.survivor_level
			var current_health := 100.0 + UpgradeManager.get_health_bonus()
			var next_health := current_health if maxed else 100.0 + UpgradeManager.HEALTH_BONUS_BY_LEVEL[level + 1]
			terminal.category_label.text = "M E D I C A L   / /   B I O - S U P P O R T"
			terminal.title_label.text = "SURVIVOR VITALS"
			terminal.subtitle_label.text = "H E A L T H   A N D   R E S I L I E N C E"
			terminal.level_label.text = "VITALS LEVEL   %d / 5" % level
			terminal.current_caption.text = "CURRENT MAX HEALTH"
			terminal.current_value.text = "%.0f  HP" % current_health
			terminal.next_caption.text = "NEXT MAX HEALTH"
			terminal.next_value.text = "MAX" if maxed else "%.0f  HP" % next_health
			terminal.description_label.text = "FORTIFY MAXIMUM HEALTH FOR EVERY FUTURE RUN."
		"earnings":
			accent = Color(0.95, 0.68, 0.16, 1.0)
			level = UpgradeManager.earnings_level
			var current_multiplier := UpgradeManager.get_earnings_multiplier()
			var next_multiplier := current_multiplier if maxed else UpgradeManager.EARNINGS_MULTIPLIERS[level + 1]
			terminal.category_label.text = "E C O N O M Y   / /   R E C O V E R Y"
			terminal.title_label.text = "ZOMBIE PAYOUT"
			terminal.subtitle_label.text = "C R E D I T   R E C O V E R Y   M U L T I P L I E R"
			terminal.level_label.text = "PAYOUT LEVEL   %d / 5" % level
			terminal.current_caption.text = "CURRENT PAYOUT"
			terminal.current_value.text = "%.2fx" % current_multiplier
			terminal.next_caption.text = "NEXT PAYOUT"
			terminal.next_value.text = "MAX" if maxed else "%.2fx" % next_multiplier
			terminal.description_label.text = "MULTIPLY ALL CREDITS RECOVERED FROM ZOMBIE KILLS."

	terminal.apply_accent(accent)
	terminal.set_level_segments(level, accent)

func _purchase_active_upgrade() -> void:
	if active_upgrade_type.is_empty():
		return
	if UpgradeManager.purchase(active_upgrade_type):
		if player != null and player.has_method("refresh_persistent_upgrades"):
			player.call("refresh_persistent_upgrades")
	_refresh_popup()

func _is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.get_name() == "iOS" or OS.get_name() == "Android"
