class_name HudController
extends CanvasLayer

## Authored gameplay HUD. Widgets are direct CanvasLayer children so positions
## stay in viewport pixels, matching the original V52 layout.

const HEALTH_BAR_PATH: String = "res://assets/Game UI Art/V52/Health Bar.png"
const TIME_BAR_PATH: String = "res://assets/Game UI Art/V52/Time Bar.png"
const PLAYER_BANK_PATH: String = "res://assets/Game UI Art/V52/Player Bank.png"
const JOYSTICK_BASE_PATH: String = "res://assets/Game UI Art/V52/JoystickBase.png"
const JOYSTICK_KNOB_PATH: String = "res://assets/Game UI Art/V52/JoystickKnob.png"
const JUMP_BUTTON_PATH: String = "res://assets/Game UI Art/V52/Jump Button.png"
const SHOOT_BUTTON_PATH: String = "res://assets/Game UI Art/V52/Shoot.png"
const PAUSE_BUTTON_PATH: String = "res://assets/Game UI Art/V52/Pause Button.png"
const SPRINT_BUTTON_PATH: String = "res://assets/Game UI Art/V52/Sprint Button.png"
const SPRINT_BAR_PATH: String = "res://assets/Game UI Art/V52/Sprinting Bar.png"
const HUD_HEALTH_FALLBACK_PATH: String = "res://assets/Game UI Art/V51/HUD_Health.png"
const HUD_TIMER_FALLBACK_PATH: String = "res://assets/Game UI Art/V51/HUD_Timer.png"
const HUD_BANK_FALLBACK_PATH: String = "res://assets/Game UI Art/V51/HUD_Bank.png"
const HUD_JOYSTICK_FALLBACK_PATH: String = "res://assets/Game UI Art/V51/HUD_Joystick.png"
const HUD_JUMP_FALLBACK_PATH: String = "res://assets/Game UI Art/V51/HUD_Jump.png"
const HUD_SHOOT_FALLBACK_PATH: String = "res://assets/Game UI Art/V51/HUD_Shoot.png"

@onready var shot_flash: ColorRect = $ShotFlash
@onready var damage_flash: ColorRect = $DamageFlash
@onready var health_root: Control = $HealthArtHUD
@onready var health_fill: ColorRect = $HealthArtHUD/HealthFill
@onready var health_value_label: Label = $HealthArtHUD/HealthValue
@onready var sprint_bar_root: Control = $SprintStaminaHUD
@onready var sprint_bar_fill: Panel = $SprintStaminaHUD/SprintStaminaFill
@onready var timer_root: Control = $TimerArtHUD
@onready var stopwatch_label: Label = $TimerArtHUD/StopwatchLabel
@onready var bank_root: Control = $BankArtHUD
@onready var money_label: Label = $BankArtHUD/MoneyLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var viewmodel_tune_label: Label = $ViewmodelTuneLabel
@onready var joystick_base: TextureRect = $MoveJoystickBase
@onready var joystick_knob: TextureRect = $MoveJoystickKnob
@onready var shoot_button: TextureButton = $ShootButton
@onready var jump_button: TextureButton = $JumpButton
@onready var sprint_button: TextureButton = $SprintButton
@onready var swap_button: Button = $SwapButton
@onready var pause_button: TextureButton = $PauseButton
@onready var death_overlay: Control = $DeathSequenceOverlay
@onready var death_vignette: ColorRect = $DeathSequenceOverlay/DeathVignette
@onready var death_top_mask: ColorRect = $DeathSequenceOverlay/TopEyelid
@onready var death_bottom_mask: ColorRect = $DeathSequenceOverlay/BottomEyelid
## RUN ENDED plate, built in code by _build_game_over().
var game_over_overlay: Control = null
var retry_button: Button = null
var game_over_menu_button: Button = null
## Kept for player.gd's binding; the plate has per-stat labels instead.
var game_over_stats_label: Label = null
var _game_over_stage: Control = null
var _game_over_values: Dictionary = {}
@onready var crosshair: Label = $Crosshair
@onready var door_interact_button: Button = get_node_or_null("DoorInteractButton") as Button

signal retry_requested
signal main_menu_requested

var health_fill_max_width: float = 247.0
var sprint_bar_fill_max_width: float = 181.0
var sprint_bar_alpha: float = 0.0
var joystick_radius: float = 62.0
var joystick_rest_position := Vector2.ZERO
var last_viewport_size := Vector2.ZERO
var show_mobile_controls: bool = true
var door_controller: Node = null
var door_visual: Node3D = null
var door_player: CharacterBody3D = null
var door_lookup_cooldown := 0.0
var door_screen_position := Vector2.ZERO
var door_interaction_input_was_down := false
var room_cleared_banner: PanelContainer = null
var room_cleared_label: Label = null
var room_cleared_tween: Tween = null
var low_health_pulse: ColorRect = null
## Round action buttons added after the V52 art pass. Keyed by control id.
var round_buttons: Dictionary = {}
var _caption_labels: Dictionary = {}
var _caption_font: SystemFont = null

const ROUND_BUTTON_IDS := ["aim", "reload", "crouch", "melee", "interact"]

const DOOR_INTERACT_DISTANCE := 2.40
const DOOR_BUTTON_SIZE := Vector2(330.0, 56.0)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_low_health_pulse()
	_build_round_buttons()
	_lock_manual_hud_widgets()
	apply_hud_art()
	if sprint_bar_fill != null:
		var stamina_style := sprint_bar_fill.get_theme_stylebox("panel") as StyleBoxFlat
		if stamina_style != null:
			sprint_bar_fill.add_theme_stylebox_override("panel", stamina_style.duplicate())
	_build_game_over()
	death_overlay.visible = false
	death_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_build_room_cleared_banner()
	_setup_door_interaction()
	layout_for_viewport()


func _build_low_health_pulse() -> void:
	# Separate from DamageFlash so a real hit can flash immediately without its
	# tween fighting the continuous heartbeat warning.
	low_health_pulse = ColorRect.new()
	low_health_pulse.name = "LowHealthPulse"
	low_health_pulse.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	low_health_pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	low_health_pulse.color = Color(0.72, 0.015, 0.01, 0.0)
	add_child(low_health_pulse)
	# Keep the pulse above the two flash layers but below the authored HUD art.
	move_child(low_health_pulse, mini(2, get_child_count() - 1))


func _build_round_buttons() -> void:
	_caption_font = SystemFont.new()
	_caption_font.font_names = PackedStringArray(["DIN Condensed", "Avenir Next Condensed", "Arial Narrow", "Helvetica Neue"])
	_caption_font.font_weight = 700
	for control_id in ROUND_BUTTON_IDS:
		var button := HudRoundButton.new()
		button.name = "%sButton" % String(control_id).capitalize().replace(" ", "")
		button.icon = HudArt.icon(control_id)
		button.caption = String(ControlSettingsManager.CONTROL_LABELS.get(control_id, control_id)).to_upper()
		button.caption_font = _caption_font
		button.visible = false
		button.z_index = 210
		add_child(button)
		# Keep the new buttons under the death/game-over overlays.
		move_child(button, pause_button.get_index() + 1 if pause_button != null else get_child_count() - 1)
		round_buttons[control_id] = button


## The on-screen Control for a settings control id, or null.
func _stock_pause_rect(viewport_size: Vector2) -> Rect2:
	var stock: Dictionary = ControlSettingsManager._default_control("pause")
	var size := ControlSettingsManager.default_pixel_size("pause", viewport_size)
	var pos := Vector2(float(stock["nx"]) * viewport_size.x, float(stock["ny"]) * viewport_size.y)
	return Rect2(ControlSettingsManager.clamp_position(pos, size, viewport_size), size)


func get_action_widget(control_id: String) -> Control:
	match control_id:
		"joystick":
			return joystick_base
		"shoot":
			return shoot_button
		"jump":
			return jump_button
		"sprint":
			return sprint_button
		"swap":
			return swap_button
		"pause":
			return pause_button
	return round_buttons.get(control_id, null) as Control


func set_round_button_active(control_id: String, is_active: bool) -> void:
	var button := round_buttons.get(control_id, null) as HudRoundButton
	if button != null and button.active != is_active:
		button.active = is_active


func _apply_button_captions() -> void:
	var show := ControlSettingsManager.show_button_labels
	for control_id in ROUND_BUTTON_IDS:
		var button := round_buttons.get(control_id, null) as HudRoundButton
		if button != null:
			button.show_caption = show
	# Painted V52 buttons get a caption Label parented to the widget, so it
	# follows drag, scale pulses and visibility.
	for control_id in ["joystick", "shoot", "jump", "sprint"]:
		var widget := get_action_widget(control_id)
		if widget == null:
			continue
		var label := _caption_labels.get(control_id, null) as Label
		if label == null or not is_instance_valid(label):
			label = Label.new()
			label.name = "HudCaption"
			label.text = String(ControlSettingsManager.CONTROL_LABELS.get(control_id, control_id))
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_override("font", _caption_font)
			label.add_theme_color_override("font_color", Color(0.92, 0.93, 0.94, 1.0))
			label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
			widget.add_child(label)
			_caption_labels[control_id] = label
		var font_size := int(clampf(minf(widget.size.x, widget.size.y) * 0.14, 8.0, 22.0))
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_constant_override("outline_size", maxi(2, font_size / 6))
		label.position = Vector2(0.0, widget.size.y)
		label.size = Vector2(widget.size.x, font_size * 1.4)
		label.visible = show


func set_low_health_pulse(alpha: float) -> void:
	if low_health_pulse != null:
		low_health_pulse.color.a = clampf(alpha, 0.0, 0.22)

func _process(delta: float) -> void:
	# Godot reapplies .tscn offsets after _ready. Keep the V52 layout in place
	# every frame so health/timer/bank/joystick cannot snap back to defaults.
	layout_for_viewport(false)
	_update_door_interaction(delta)
	_poll_door_interaction_input()


func _poll_door_interaction_input() -> void:
	# Player FPS input can consume a captured mouse click before Control receives
	# GUI input. Poll the physical state so desktop testing cannot lose the door
	# interaction. Mobile still uses the authored Button/touch rectangle.
	var input_down := Input.is_key_pressed(KEY_E)
	if not OS.has_feature("mobile") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		input_down = input_down or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if door_interact_button != null and door_interact_button.visible and \
			not door_interact_button.disabled and input_down and \
			not door_interaction_input_was_down:
		_on_door_interact_pressed()
	door_interaction_input_was_down = input_down


func _input(event: InputEvent) -> void:
	if _is_mobile_platform() and event is InputEventScreenTouch:
		var mobile_touch := event as InputEventScreenTouch
		if mobile_touch.pressed and try_mobile_door_tap(mobile_touch.position):
			get_viewport().set_input_as_handled()
		return
	if door_interact_button == null or not door_interact_button.visible:
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_E:
			get_viewport().set_input_as_handled()
			_on_door_interact_pressed()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and door_interact_button.get_global_rect().grow(24.0).has_point(touch.position):
			get_viewport().set_input_as_handled()
			_on_door_interact_pressed()
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_LEFT:
			var over_button := door_interact_button.get_global_rect().grow(12.0).has_point(
				mouse_button.position
			)
			# Godot's captured-mouse FPS mode cannot place a cursor over Controls.
			# Treat a centered click as interaction while the door prompt is active.
			var viewport_center := get_viewport().get_visible_rect().size * 0.5
			var aiming_at_door := door_screen_position.distance_to(viewport_center) <= 220.0
			if over_button or (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and aiming_at_door):
				get_viewport().set_input_as_handled()
				_on_door_interact_pressed()


func _setup_door_interaction() -> void:
	if door_interact_button == null:
		door_interact_button = Button.new()
		door_interact_button.name = "DoorInteractButton"
		door_interact_button.text = "E / TAP   OPEN BLAST DOOR"
		door_interact_button.add_theme_font_size_override("font_size", 20)
		door_interact_button.z_index = 500
		add_child(door_interact_button)
	door_interact_button.layout_mode = 0
	door_interact_button.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	door_interact_button.size = DOOR_BUTTON_SIZE
	door_interact_button.focus_mode = Control.FOCUS_NONE
	door_interact_button.mouse_filter = Control.MOUSE_FILTER_STOP
	door_interact_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	door_interact_button.visible = false
	if not door_interact_button.pressed.is_connected(_on_door_interact_pressed):
		door_interact_button.pressed.connect(_on_door_interact_pressed)
	_resolve_door_interaction_nodes()


func _resolve_door_interaction_nodes() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if door_player == null or not is_instance_valid(door_player):
		door_player = scene.find_child("Player", true, false) as CharacterBody3D

	# Streaming adds the cafeteria door after startup. Select the nearest locked
	# transition instead of permanently binding the HUD to Room1DoorTransition.
	var nearest_controller: Node = null
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("room_transition_door"):
		if candidate == null or not is_instance_valid(candidate):
			continue
		if candidate.has_method("is_door_unlocked") and bool(candidate.call("is_door_unlocked")):
			continue
		var candidate_player := door_player
		if candidate_player == null and candidate.has_method("get_live_player"):
			candidate_player = candidate.call("get_live_player") as CharacterBody3D
		if candidate_player == null:
			continue
		var candidate_position := (candidate as Node3D).global_position
		if candidate.has_method("get_interaction_world_position"):
			candidate_position = candidate.call("get_interaction_world_position") as Vector3
		var distance := candidate_player.global_position.distance_squared_to(candidate_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_controller = candidate

	door_controller = nearest_controller
	door_visual = null
	if door_controller != null and door_controller.has_method("get_door_visual_root"):
		door_visual = door_controller.call("get_door_visual_root") as Node3D
	if door_player == null and door_controller != null and door_controller.has_method("get_live_player"):
		door_player = door_controller.call("get_live_player") as CharacterBody3D


func _update_door_interaction(delta: float) -> void:
	if door_interact_button == null:
		return
	door_lookup_cooldown -= delta
	if door_lookup_cooldown <= 0.0:
		door_lookup_cooldown = 0.25
		_resolve_door_interaction_nodes()

	if door_controller == null or not is_instance_valid(door_controller) or \
			door_player == null or not is_instance_valid(door_player):
		door_interact_button.visible = false
		return

	var unlocked := false
	var opening := false
	var destination_ready := true
	var access_granted := true
	if door_controller.has_method("is_door_unlocked"):
		unlocked = bool(door_controller.call("is_door_unlocked"))
	if door_controller.has_method("is_door_transitioning"):
		opening = bool(door_controller.call("is_door_transitioning"))
	if door_controller.has_method("is_destination_ready"):
		destination_ready = bool(door_controller.call("is_destination_ready"))
	if door_controller.has_method("is_access_granted"):
		access_granted = bool(door_controller.call("is_access_granted"))
	if unlocked:
		door_interact_button.visible = false
		return

	var controller_3d := door_controller as Node3D
	var target_position := Vector3.ZERO
	# Use the visible door directly.  This follows editor transform changes and,
	# importantly, never asks the controller to reload/re-instantiate a GLB from
	# the HUD's per-frame update.
	if door_visual != null and is_instance_valid(door_visual):
		target_position = door_visual.global_transform * Vector3(0.0, 0.46, 0.0)
	elif controller_3d != null:
		target_position = controller_3d.global_position + Vector3.UP * 1.35

	var player_position := door_player.global_position
	var flat_distance := Vector2(
		player_position.x - target_position.x,
		player_position.z - target_position.z
	).length()
	var in_range := flat_distance <= DOOR_INTERACT_DISTANCE
	var camera := get_viewport().get_camera_3d()
	var on_screen := camera != null and not camera.is_position_behind(target_position)
	# iPhone/iPad interacts by tapping the physical door; no "PRESS E" overlay.
	door_interact_button.visible = false if _is_mobile_platform() else \
		(opening or (in_range and on_screen and not get_tree().paused))
	door_interact_button.disabled = opening or not destination_ready or not access_granted
	if opening:
		door_interact_button.text = "OPENING..."
	elif not access_granted:
		door_interact_button.text = "LOCKED — CLEAR ROOM"
	elif not destination_ready:
		door_interact_button.text = "PREPARING ROOM..."
	elif door_interact_button.text != "E / TAP   OPEN BLAST DOOR":
		door_interact_button.text = "E / TAP   OPEN BLAST DOOR"

	if door_interact_button.visible:
		var viewport_size := get_viewport().get_visible_rect().size
		var screen_position := viewport_size * Vector2(0.5, 0.68)
		if on_screen:
			screen_position = camera.unproject_position(target_position)
		door_screen_position = screen_position
		var half_size := door_interact_button.size * 0.5
		var desired := screen_position - half_size
		desired.x = clampf(desired.x, 12.0, viewport_size.x - door_interact_button.size.x - 12.0)
		desired.y = clampf(desired.y, 110.0, viewport_size.y - door_interact_button.size.y - 24.0)
		door_interact_button.position = desired


func _on_door_interact_pressed() -> void:
	if door_interact_button == null or not door_interact_button.visible or \
			door_interact_button.disabled:
		return
	if door_controller == null or not is_instance_valid(door_controller):
		_resolve_door_interaction_nodes()
	if door_controller != null and door_controller.has_method("request_open_from_hud"):
		print("BLAST DOOR: HUD activation received.")
		var accepted: Variant = door_controller.call("request_open_from_hud")
		if typeof(accepted) == TYPE_BOOL and bool(accepted):
			door_interact_button.text = "OPENING..."
			door_interact_button.disabled = true
		else:
			push_error("BLAST DOOR: controller rejected the visible interaction prompt.")


## INTERACT button: open the nearest blast door the player is standing at.
func try_interact_nearest_door() -> bool:
	_resolve_door_interaction_nodes()
	if door_controller == null or not is_instance_valid(door_controller) or door_player == null:
		return false
	if not door_controller.has_method("can_interact_from_hud") or \
			not bool(door_controller.call("can_interact_from_hud")):
		return false
	var accepted: Variant = door_controller.call("request_open_from_hud")
	return typeof(accepted) == TYPE_BOOL and bool(accepted)


func try_mobile_door_tap(screen_position: Vector2) -> bool:
	if not _is_mobile_platform() or get_tree().paused:
		return false
	_resolve_door_interaction_nodes()
	if door_controller == null or not is_instance_valid(door_controller):
		return false
	if not door_controller.has_method("can_interact_from_hud") or \
			not bool(door_controller.call("can_interact_from_hud")):
		return false
	var camera := get_viewport().get_camera_3d()
	if camera == null or door_player == null:
		return false

	var ray_from := camera.project_ray_origin(screen_position)
	var ray_to := ray_from + camera.project_ray_normal(screen_position) * 12.0
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [door_player.get_rid()]
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false

	var target_position := (door_controller as Node3D).global_position
	if door_controller.has_method("get_interaction_world_position"):
		target_position = door_controller.call("get_interaction_world_position") as Vector3
	var hit_position: Vector3 = hit.get("position", Vector3.ZERO)
	# The authored blocker covers the complete closed door. This distance check
	# also accepts imported door collision bodies that are children of the GLB.
	if hit_position.distance_to(target_position) > 2.35:
		return false

	var accepted: Variant = door_controller.call("request_open_from_hud")
	return typeof(accepted) == TYPE_BOOL and bool(accepted)


func _is_mobile_platform() -> bool:
	return OS.has_feature("mobile") or OS.get_name() == "iOS" or OS.get_name() == "Android"

func _lock_manual_hud_widgets() -> void:
	var widgets: Array[Control] = [
		health_root, sprint_bar_root, timer_root, bank_root, ammo_label, viewmodel_tune_label,
		joystick_base, joystick_knob, shoot_button, jump_button, sprint_button, pause_button
	]
	for widget in widgets:
		if widget == null:
			continue
		widget.layout_mode = 3
		widget.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		widget.grow_horizontal = Control.GROW_DIRECTION_END
		widget.grow_vertical = Control.GROW_DIRECTION_END

func configure_mobile_visibility(should_show: bool, pistol_equipped: bool) -> void:
	show_mobile_controls = should_show
	if joystick_base != null:
		joystick_base.visible = should_show
	if joystick_knob != null:
		joystick_knob.visible = should_show
	if jump_button != null:
		jump_button.visible = should_show
	if sprint_button != null:
		sprint_button.visible = should_show
	if pause_button != null:
		pause_button.visible = should_show
	if shoot_button != null:
		shoot_button.visible = should_show and (pistol_equipped or OS.has_feature("editor"))
	if crosshair != null:
		crosshair.visible = pistol_equipped
		crosshair.modulate.a = 1.0
	layout_for_viewport()
	apply_saved_control_layout(true, true)

func layout_for_viewport(center_joystick: bool = true) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	# Final layout matched against the approved 1672x941 reference.
	var s: float = viewport_size.y / 941.0

	if health_root != null:
		# Slightly wider than V52.10, same visual height.
		health_root.size = Vector2(466.0, 82.0)
		health_root.scale = Vector2.ONE * s
		health_root.position = Vector2(42.0 * s, 31.0 * s)

	if sprint_bar_root != null:
		# Compact secondary meter: 71.4% of its old size while preserving the
		# source artwork's 3:1 aspect ratio and its internal fill alignment.
		sprint_bar_root.size = Vector2(300.0, 100.0)
		sprint_bar_root.scale = Vector2.ONE * s
		sprint_bar_root.position = Vector2(42.0 * s, 111.0 * s)
		sprint_bar_root.z_index = 180

	if timer_root != null:
		timer_root.size = Vector2(306.0, 80.0)
		timer_root.scale = Vector2.ONE * s
		timer_root.position = Vector2(
			(viewport_size.x - timer_root.size.x * s) * 0.5,
			31.0 * s
		)

	if bank_root != null:
		# Reference bank panel is visibly wider than the prior build.
		bank_root.size = Vector2(342.0, 76.0)
		bank_root.scale = Vector2.ONE * s
		bank_root.position = Vector2(
			viewport_size.x - bank_root.size.x * s - 44.0 * s,
			31.0 * s
		)

	if ammo_label != null:
		# Weapon label sits under bank and to the LEFT of Pause.
		ammo_label.position = Vector2(viewport_size.x - 250.0 * s, 116.0 * s)
		ammo_label.size = Vector2(135.0, 32.0) * s
		ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ammo_label.add_theme_font_size_override("font_size", int(round(18.0 * s)))

	if not show_mobile_controls:
		last_viewport_size = viewport_size
		return

	apply_saved_control_layout(center_joystick, false)
	last_viewport_size = viewport_size


func apply_saved_control_layout(center_joystick: bool = true, force: bool = false) -> void:
	if not show_mobile_controls:
		return
	if ControlSettingsManager.suspend_hud_layout and not force:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var preserve_live_joystick := bool(get_meta("preserve_live_joystick", false))
	if joystick_base != null and not preserve_live_joystick:
		ControlSettingsManager.apply_to_control(joystick_base, "joystick", viewport_size, true)
		joystick_base.z_index = 200
		joystick_rest_position = joystick_base.position
		joystick_radius = joystick_base.size.x * (82.0 / 282.0)
		if joystick_knob != null:
			joystick_knob.layout_mode = 3
			joystick_knob.size = joystick_base.size * (116.0 / 282.0)
			joystick_knob.pivot_offset = joystick_knob.size * 0.5
			joystick_knob.z_index = 205
			joystick_knob.modulate.a = ControlSettingsManager.control_opacity("joystick")
			if center_joystick:
				joystick_knob.position = joystick_base.position + (joystick_base.size - joystick_knob.size) * 0.5
				joystick_knob.rotation = 0.0
				joystick_knob.scale = Vector2.ONE
		_apply_movement_mode_visibility()

	if shoot_button != null:
		ControlSettingsManager.apply_to_control(shoot_button, "shoot", viewport_size, true)
		shoot_button.pivot_offset = shoot_button.size * 0.5
		shoot_button.z_index = 210
	if jump_button != null:
		ControlSettingsManager.apply_to_control(jump_button, "jump", viewport_size, true)
		jump_button.pivot_offset = jump_button.size * 0.5
		jump_button.z_index = 210
	if sprint_button != null:
		ControlSettingsManager.apply_to_control(sprint_button, "sprint", viewport_size, false)
		sprint_button.pivot_offset = sprint_button.size * 0.5
		sprint_button.z_index = 210
		sprint_button.modulate.a = ControlSettingsManager.control_opacity("sprint")
	if swap_button != null:
		ControlSettingsManager.apply_to_control(swap_button, "swap", viewport_size, false)
		swap_button.pivot_offset = swap_button.size * 0.5
		swap_button.z_index = 210
	if pause_button != null:
		# Pause is locked to its stock top-right rect: saved nx/ny/scale,
		# opacity, visibility and the global button size never apply to it.
		var pause_rect := _stock_pause_rect(viewport_size)
		pause_button.layout_mode = 0
		pause_button.scale = Vector2.ONE
		pause_button.position = pause_rect.position
		pause_button.size = pause_rect.size
		pause_button.pivot_offset = pause_button.size * 0.5
		pause_button.visible = true
		pause_button.modulate.a = 1.0
		pause_button.z_index = 260
	for control_id in ROUND_BUTTON_IDS:
		var round_button := round_buttons.get(control_id, null) as HudRoundButton
		if round_button == null:
			continue
		# Visibility belongs to player.gd (weapon, pause and run state); layout
		# only places and fades the widget.
		var was_visible := round_button.visible
		ControlSettingsManager.apply_to_control(round_button, control_id, viewport_size, true)
		round_button.visible = was_visible
		round_button.pivot_offset = round_button.size * 0.5
		round_button.z_index = 210
	_apply_button_captions()


func _apply_movement_mode_visibility() -> void:
	if joystick_base == null:
		return
	var mode := ControlSettingsManager.movement_mode
	var show_stick := ControlSettingsManager.control_visible("joystick")
	if ControlSettingsManager.suspend_hud_layout:
		show_stick = mode != ControlSettingsManager.MODE_TOUCH_ZONE and show_stick
	elif mode == ControlSettingsManager.MODE_TOUCH_ZONE:
		show_stick = bool(get_meta("touch_zone_indicator_active", false)) and ControlSettingsManager.show_touch_zone_indicator
	elif mode == ControlSettingsManager.MODE_FLOATING:
		show_stick = bool(get_meta("preserve_live_joystick", false))
	if joystick_base != null:
		joystick_base.visible = show_mobile_controls and show_stick
	if joystick_knob != null:
		joystick_knob.visible = show_mobile_controls and show_stick

func set_health(current: float, maximum: float) -> void:
	if health_fill != null:
		var ratio: float = clampf(current / maxf(maximum, 1.0), 0.0, 1.0)
		health_fill.size.x = health_fill_max_width * ratio
	if health_value_label != null:
		health_value_label.text = "%d / %d" % [int(round(current)), int(round(maximum))]

func set_stamina(
	stamina: float,
	stamina_max: float,
	sprint_active: bool,
	sprint_exhausted: bool,
	delta: float
) -> void:
	if sprint_bar_root == null or sprint_bar_fill == null:
		return
	var ratio: float = clampf(stamina / maxf(stamina_max, 0.01), 0.0, 1.0)
	sprint_bar_fill.size.x = sprint_bar_fill_max_width * ratio
	var style := sprint_bar_fill.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.bg_color = Color(0.96, 0.42, 0.06, 0.78) if sprint_active else Color(0.16, 0.58, 0.96, 0.78)
	var should_show: bool = sprint_active or stamina < stamina_max - 0.05
	var target_alpha: float = 1.0 if should_show else 0.0
	var fade_speed: float = 12.0 if should_show else 5.5
	if delta <= 0.0:
		sprint_bar_alpha = target_alpha
	else:
		sprint_bar_alpha = move_toward(sprint_bar_alpha, target_alpha, delta * fade_speed)
	sprint_bar_root.modulate.a = sprint_bar_alpha
	sprint_bar_root.visible = sprint_bar_alpha > 0.01
	if sprint_button != null:
		var sprint_alpha := ControlSettingsManager.control_opacity("sprint")
		if sprint_exhausted:
			sprint_button.modulate = Color(0.45, 0.48, 0.52, sprint_alpha * 0.72)
		elif sprint_active:
			sprint_button.modulate = Color(1.0, 0.72, 0.34, sprint_alpha)
		else:
			sprint_button.modulate = Color(1.0, 1.0, 1.0, sprint_alpha) if stamina > 0.01 else Color(0.55, 0.55, 0.55, sprint_alpha * 0.72)

func set_stopwatch(elapsed_time: float) -> void:
	if stopwatch_label == null:
		return
	var total_seconds: float = maxf(elapsed_time, 0.0)
	var minutes: int = int(floor(total_seconds / 60.0))
	var seconds: int = int(floor(total_seconds)) % 60
	var tenths: int = int(floor(fmod(total_seconds, 1.0) * 10.0))
	stopwatch_label.text = "%02d:%02d.%d" % [minutes, seconds, tenths]

func set_money(balance: int) -> void:
	if money_label != null:
		money_label.text = "$%d" % balance

func set_ammo(text_value: String, visible_now: bool) -> void:
	if ammo_label == null:
		return
	ammo_label.text = text_value
	ammo_label.visible = visible_now

func set_shoot_visible(visible_now: bool) -> void:
	if shoot_button != null:
		shoot_button.visible = visible_now and show_mobile_controls and ControlSettingsManager.control_visible("shoot")

func flash_shot() -> void:
	if shot_flash == null:
		return
	shot_flash.color = Color(1.0, 0.72, 0.30, 0.20)
	var flash_tween := create_tween()
	flash_tween.tween_property(shot_flash, "color:a", 0.0, 0.055)

func flash_damage(lethal: bool) -> void:
	if damage_flash == null:
		return
	damage_flash.color = Color(0.72, 0.03, 0.02, 0.32 if lethal else 0.18)
	var hurt_tween := create_tween()
	hurt_tween.tween_property(damage_flash, "color:a", 0.0, 0.24)

func fade_for_death() -> void:
	var controls: Array[CanvasItem] = [
		timer_root, bank_root, joystick_base, jump_button, shoot_button, pause_button, ammo_label
	]
	for round_button in round_buttons.values():
		controls.append(round_button as CanvasItem)
	for item in controls:
		if item != null:
			var tween: Tween = create_tween()
			tween.tween_property(item, "modulate:a", 0.0, 0.52)
	if health_root != null:
		var health_tween: Tween = create_tween()
		health_tween.tween_interval(0.55)
		health_tween.tween_property(health_root, "modulate:a", 0.0, 0.70)
	if crosshair != null:
		var crosshair_tween: Tween = create_tween()
		crosshair_tween.tween_property(crosshair, "modulate:a", 0.0, 0.35)

func restore_after_death(show_mobile: bool) -> void:
	for item in [
		health_root, timer_root, bank_root, joystick_base, jump_button, shoot_button, pause_button, ammo_label
	]:
		if item != null:
			(item as CanvasItem).modulate.a = 1.0
	if crosshair != null:
		crosshair.modulate.a = 1.0
	if death_overlay != null:
		death_overlay.visible = false
	if death_vignette != null:
		death_vignette.modulate.a = 0.0
	configure_mobile_visibility(show_mobile, shoot_button != null and shoot_button.visible)

## `stats_text` is kept for callers; the plate reads RunManager's run summary.
func show_game_over(_stats_text: String = "") -> void:
	var summary := RunManager.get_run_summary()
	var seconds := int(summary.get("time", 0.0))
	var earned := int(summary.get("earnings", 0))
	var values := {
		"room": "ROOM %d" % maxi(1, int(summary.get("room", 1))),
		"kills": str(int(summary.get("kills", 0))),
		"accuracy": "%d%%" % int(round(float(summary.get("accuracy", 0.0)))),
		"time": "%d:%02d" % [seconds / 60, seconds % 60],
		"earned": SteelUI.money(earned),
		# Kill pay is banked on the kill, so a death keeps all of it.
		"kept": SteelUI.money(earned),
	}
	for key in values:
		if _game_over_values.has(key):
			(_game_over_values[key] as Label).text = values[key]
	if pause_button != null:
		pause_button.visible = false
	if shoot_button != null:
		shoot_button.visible = false
	if jump_button != null:
		jump_button.visible = false
	if game_over_overlay != null:
		_layout_game_over()
		game_over_overlay.visible = true

func hide_game_over(show_mobile: bool, pistol_equipped: bool) -> void:
	if game_over_overlay != null:
		game_over_overlay.visible = false
	configure_mobile_visibility(show_mobile, pistol_equipped)

## RUN ENDED: dimmed live 3D, the pause menu's red stripe, a riveted steel
## plate with the run's numbers, RETRY ROOM (green) + MAIN MENU.
func _build_game_over() -> void:
	game_over_overlay = Control.new()
	game_over_overlay.name = "GameOverOverlay"
	game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_overlay.z_index = 950
	game_over_overlay.visible = false
	add_child(game_over_overlay)
	game_over_overlay.resized.connect(_layout_game_over)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.0, 0.0, 0.58)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_overlay.add_child(dim)

	_game_over_stage = Control.new()
	_game_over_stage.name = "Stage"
	_game_over_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_overlay.add_child(_game_over_stage)

	# Red PAUSED stripe, as on the pause menu. Overhangs the stage so it spans
	# wide phones edge to edge; its text stays centred on the plate.
	var stripe := PanelContainer.new()
	stripe.name = "PausedStripe"
	stripe.position = Vector2(-SteelUI.DESIGN.x, 52.0)
	stripe.size = Vector2(SteelUI.DESIGN.x * 3.0, 58.0)
	var stripe_box := SteelUI.flat(Color(0.20, 0.015, 0.015, 0.88))
	stripe_box.border_color = SteelUI.RED
	stripe_box.border_width_top = 2
	stripe_box.border_width_bottom = 2
	stripe.add_theme_stylebox_override("panel", stripe_box)
	_game_over_stage.add_child(stripe)
	var stripe_row := HBoxContainer.new()
	stripe_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stripe_row.add_theme_constant_override("separation", 28)
	stripe.add_child(stripe_row)
	stripe_row.add_child(SteelUI.label("PAUSED", 38, SteelUI.RED))
	stripe_row.add_child(SteelUI.label("//", 30, Color(SteelUI.RED.r, SteelUI.RED.g, SteelUI.RED.b, 0.6)))
	stripe_row.add_child(SteelUI.label("SURVIVOR DOWN", 38, SteelUI.RED))

	var panel := PanelContainer.new()
	panel.name = "SteelPlate"
	panel.size = Vector2(820.0, 540.0)
	panel.position = Vector2((SteelUI.DESIGN.x - 820.0) * 0.5, 138.0)
	panel.add_theme_stylebox_override("panel", SteelUI.plate("panel_steel.png", 40.0, 36.0))
	_game_over_stage.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)

	var title := TextureRect.new()
	title.texture = SteelUI.tex(SteelUI.ART + "title_run_ended.png")
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.custom_minimum_size = Vector2(0.0, 64.0)
	column.add_child(title)
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	rule.color = Color(SteelUI.GREEN.r, SteelUI.GREEN.g, SteelUI.GREEN.b, 0.35)
	column.add_child(rule)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	_game_over_values.clear()
	for stat in [
		["room", "ROOM REACHED"], ["kills", "KILLS"],
		["accuracy", "ACCURACY"], ["time", "TIME"],
		["earned", "$ THIS RUN"], ["kept", "$ KEPT"],
	]:
		var cell := SteelUI.well(12.0)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var row := HBoxContainer.new()
		cell.add_child(row)
		row.add_child(SteelUI.label(stat[1], 22, SteelUI.TEXT_DIM))
		row.add_child(SteelUI.spacer())
		var money_stat: bool = stat[0] == "earned" or stat[0] == "kept"
		var value := SteelUI.label("--", 34, SteelUI.AMBER if money_stat else SteelUI.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
		row.add_child(value)
		_game_over_values[stat[0]] = value
		grid.add_child(cell)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	column.add_child(buttons)
	retry_button = SteelUI.action_button("RETRY ROOM", true, Vector2(330.0, 72.0))
	retry_button.name = "RetryButton"
	retry_button.pressed.connect(_on_retry_pressed)
	buttons.add_child(retry_button)
	game_over_menu_button = SteelUI.action_button("MAIN MENU", false, Vector2(330.0, 72.0))
	game_over_menu_button.name = "MainMenuButton"
	game_over_menu_button.pressed.connect(_on_main_menu_pressed)
	buttons.add_child(game_over_menu_button)


func _layout_game_over() -> void:
	if _game_over_stage != null:
		SteelUI.fit_stage(_game_over_stage, get_viewport().get_visible_rect().size)


func _build_room_cleared_banner() -> void:
	room_cleared_banner = PanelContainer.new()
	room_cleared_banner.name = "RoomClearedBanner"
	room_cleared_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	room_cleared_banner.offset_left = -285.0
	room_cleared_banner.offset_top = 132.0
	room_cleared_banner.offset_right = 285.0
	room_cleared_banner.offset_bottom = 202.0
	room_cleared_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_cleared_banner.visible = false
	room_cleared_banner.modulate.a = 0.0
	room_cleared_banner.pivot_offset = Vector2(285.0, 35.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.012, 0.025, 0.016, 0.94)
	panel_style.border_color = Color(0.40, 0.92, 0.24, 0.92)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(5)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.72)
	panel_style.shadow_size = 10
	room_cleared_banner.add_theme_stylebox_override("panel", panel_style)
	add_child(room_cleared_banner)

	room_cleared_label = Label.new()
	room_cleared_label.text = "ROOM 1 CLEARED"
	room_cleared_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_cleared_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	room_cleared_label.add_theme_font_size_override("font_size", 29)
	room_cleared_label.add_theme_color_override("font_color", Color(0.56, 1.0, 0.36))
	room_cleared_label.add_theme_color_override(
		"font_shadow_color", Color(0.0, 0.0, 0.0, 0.95)
	)
	room_cleared_label.add_theme_constant_override("shadow_offset_x", 2)
	room_cleared_label.add_theme_constant_override("shadow_offset_y", 2)
	room_cleared_banner.add_child(room_cleared_label)

func show_room_cleared(room_number: int) -> void:
	if room_cleared_banner == null or room_cleared_label == null:
		return
	if room_cleared_tween != null and room_cleared_tween.is_valid():
		room_cleared_tween.kill()
	room_cleared_label.text = "ROOM %d CLEARED" % maxi(room_number, 1)
	room_cleared_banner.visible = true
	room_cleared_banner.modulate.a = 0.0
	room_cleared_banner.scale = Vector2(0.96, 0.96)
	room_cleared_tween = create_tween()
	room_cleared_tween.set_parallel(true)
	room_cleared_tween.tween_property(room_cleared_banner, "modulate:a", 1.0, 0.16)
	room_cleared_tween.tween_property(
		room_cleared_banner, "scale", Vector2.ONE, 0.20
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	room_cleared_tween.set_parallel(false)
	room_cleared_tween.tween_interval(1.70)
	room_cleared_tween.tween_property(room_cleared_banner, "modulate:a", 0.0, 0.42)
	room_cleared_tween.tween_callback(room_cleared_banner.hide)

func pulse_button(button: Control, pressed_scale: float, duration: float) -> void:
	if button == null:
		return
	button.pivot_offset = button.size * 0.5
	var tween: Tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * pressed_scale, duration * 0.42)
	tween.tween_property(button, "scale", Vector2.ONE, duration * 0.58)

func _on_retry_pressed() -> void:
	retry_requested.emit()

func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()

func apply_hud_art() -> void:
	_set_texture_rect($HealthArtHUD/HealthArt as TextureRect, HEALTH_BAR_PATH, HUD_HEALTH_FALLBACK_PATH)
	_set_texture_rect($SprintStaminaHUD/SprintBarArt as TextureRect, SPRINT_BAR_PATH, "")
	_set_texture_rect($TimerArtHUD/TimerArt as TextureRect, TIME_BAR_PATH, HUD_TIMER_FALLBACK_PATH)
	_set_texture_rect($BankArtHUD/BankArt as TextureRect, PLAYER_BANK_PATH, HUD_BANK_FALLBACK_PATH)
	_set_texture_rect(joystick_base, JOYSTICK_BASE_PATH, HUD_JOYSTICK_FALLBACK_PATH)
	_set_texture_rect(joystick_knob, JOYSTICK_KNOB_PATH, "")
	_set_texture_button(shoot_button, SHOOT_BUTTON_PATH, HUD_SHOOT_FALLBACK_PATH)
	_set_texture_button(jump_button, JUMP_BUTTON_PATH, HUD_JUMP_FALLBACK_PATH)
	_set_texture_button(sprint_button, SPRINT_BUTTON_PATH, "")
	_set_texture_button(pause_button, PAUSE_BUTTON_PATH, "")

func _set_texture_rect(rect: TextureRect, path: String, fallback_path: String) -> void:
	if rect == null:
		return
	# TextureRect.STRETCH_TILE (1) was accidentally written into the split HUD
	# scene. It displayed only repeated/clipped pieces of the health, timer, bank,
	# stamina, and joystick textures. Always enforce the original scaled artwork.
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture = _load_gameplay_ui_texture(path, fallback_path)

func _set_texture_button(button: TextureButton, path: String, fallback_path: String) -> void:
	if button == null:
		return
	button.texture_normal = _load_gameplay_ui_texture(path, fallback_path)

func _load_gameplay_ui_texture(path: String, fallback_path: String = "") -> Texture2D:
	var candidates: Array[String] = [path]
	var filename: String = path.get_file()
	candidates.append("res://assets/Game UI Art/" + filename)
	candidates.append("res://assets/Game Ui Art/V52/" + filename)
	candidates.append("res://assets/Game Ui Art/" + filename)
	for candidate: String in candidates:
		if ResourceLoader.exists(candidate):
			var loaded: Texture2D = load(candidate) as Texture2D
			if loaded != null:
				return _trim_hud_texture(loaded)
	if not fallback_path.is_empty() and ResourceLoader.exists(fallback_path):
		var fallback_loaded: Texture2D = load(fallback_path) as Texture2D
		if fallback_loaded != null:
			return _trim_hud_texture(fallback_loaded)
	push_warning("HUD art not found. Expected: %s" % path)
	return null

func _trim_hud_texture(texture: Texture2D) -> Texture2D:
	# Generated UI PNGs contain large transparent margins. Crop to the painted
	# pixels, then bake a new ImageTexture so the Control size is the real art.
	var image: Image = null
	var source_path := texture.resource_path
	if source_path.begins_with("res://"):
		image = Image.load_from_file(ProjectSettings.globalize_path(source_path))
	if image == null or image.is_empty():
		image = texture.get_image()
	if image == null or image.is_empty():
		return texture
	if image.is_compressed():
		image.decompress()
	var image_size: Vector2i = image.get_size()
	var min_x: int = image_size.x
	var min_y: int = image_size.y
	var max_x: int = -1
	var max_y: int = -1
	const VISIBLE_ALPHA_THRESHOLD: float = 0.02
	for y in range(image_size.y):
		for x in range(image_size.x):
			if image.get_pixel(x, y).a >= VISIBLE_ALPHA_THRESHOLD:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return texture
	var painted_width: int = max_x - min_x + 1
	var painted_height: int = max_y - min_y + 1
	var halo: int = maxi(2, int(ceil(maxi(painted_width, painted_height) * 0.015)))
	min_x = maxi(0, min_x - halo)
	min_y = maxi(0, min_y - halo)
	max_x = mini(image_size.x - 1, max_x + halo)
	max_y = mini(image_size.y - 1, max_y + halo)
	var used := Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	var cropped := image.get_region(used)
	return ImageTexture.create_from_image(cropped)
