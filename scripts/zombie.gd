extends CharacterBody3D

## Bunker Zero infected controller (V70).
##
## One rig, one AnimationPlayer, never rebuilt. A single animation layer owns
## idle / walk / one-shot clips with real crossfades, and walk playback speed is
## driven by ground speed so feet do not skate. The body turns toward where it
## wants to go and moves along its facing (no strafing, no moonwalk, no yaw
## snaps). Each room's horde is organised by a light surround coordinator: a
## few zombies hold attack tokens and close in to swing, the rest hold an outer
## ring around the player, and ring angles are re-spread every 0.25 s so holes
## close when one dies. Damage is still gated by the animated striking hand
## reaching the player at the authored contact frame.

enum ZombieState { WANDER, CHASE, ATTACK, REACT, ALERT, DEAD }
enum ZombieVisualMode { ANGRY, LIMP, LOOK_AROUND }

# ---------------------------------------------------------------- animation
# Measured from the combined GLB: every attack starts 25-30 deg (mean per bone)
# away from any walk frame, so the crossfade — not walk phase — is what hides
# the change. Contact frames stay on the source clip timeline.
const ATTACK_CONTACT_TIMES: Array[float] = [0.87, 1.07, 0.82]
const FINISHER_CONTACT_TIMES: Array[float] = [1.43, 0.79]
# Centre-to-centre distance each swing wants at its contact frame (measured hand
# reach: claw 0.38 m, lunge 0.86 m, maul 0.45 m forward of the body).
const ATTACK_CONTACT_DISTANCES: Array[float] = [0.76, 0.92, 0.80]
const FINISHER_CONTACT_DISTANCE: float = 0.72
const ATTACK_BLEND_IN: float = 0.24
const ATTACK_BLEND_OUT: float = 0.28
const ATTACK_EXIT_FRACTION: float = 0.86
const REACTION_BLEND_IN: float = 0.12
const ONE_SHOT_BLEND_OUT: float = 0.26
const LOCOMOTION_BLEND: float = 0.30
const RESUME_RAMP_TIME: float = 0.55
const ATTACK_PLAYBACK_SPEED: float = 1.12
const RIGHT_HAND_BONE: StringName = &"mixamorig:RightHand"
const LEFT_HAND_BONE: StringName = &"mixamorig:LeftHand"
const ANGRY_ATTACK_START_RANGE: float = 1.02
const LIMP_ATTACK_START_RANGE: float = 1.18
const ATTACK_HAND_CONTACT_RADIUS: float = 0.68
const ATTACK_WINDUP_APPROACH_SPEED: float = 0.52
const WALK_CLIPS: Array[StringName] = [&"walk_angry", &"walk_limp", &"walk_slow", &"walk_heavy_limp"]
# Ground speed (m/s at MODEL_SCALE) each walk covers at playback 1.0, measured
# from the stance-foot speed in the clip. Used to match cycle rate to velocity.
const WALK_NATURAL_SPEEDS: Array[float] = [0.73, 1.05, 0.84, 1.07]
const WALK_MOVE_MULTIPLIERS: Array[float] = [1.00, 0.90, 0.76, 0.82]
const WALK_ANIM_MIN: float = 0.55
const WALK_ANIM_MAX: float = 2.40
const IDLE_CLIPS: Array[StringName] = [&"idle_search", &"idle_restless", &"idle_look_around"]
const LOOK_AROUND_LOOP_SPEED: float = 0.92

# ---------------------------------------------------------------- crowd / surround
const COORDINATOR_INTERVAL_MSEC: int = 250
const TOKEN_RING_RADIUS: float = 1.15
const TOKEN_KEEP_DISTANCE: float = 4.5
const HOLD_ARRIVE_DISTANCE: float = 0.50
const ZOMBIE_PERSONAL_SPACE: float = 1.10
const CROWD_PUSH_MAX: float = 0.55
const LANE_LOCK_MIN: float = 4.0
const LANE_LOCK_MAX: float = 7.0

const COMBINED_ZOMBIE_PATH: String = "res://assets/Zombies/Bunker Zombie Complete 26 Animations.glb"
const HEADSHOT_DAMAGE_MULTIPLIER: float = 2.0
const HEAD_HITBOX_LAYER: int = 32
# Heavy stagger is rare: only a big single hit (shotgun blast, crossbow bolt,
# point-blank pistol headshot) can roll it, and then not again for a while.
const HEAVY_STAGGER_CHANCE: float = 0.30
const HEAVY_STAGGER_MIN_FORCE: float = 1.25
const HEAVY_STAGGER_COOLDOWN_MIN: float = 5.0
const HEAVY_STAGGER_COOLDOWN_MAX: float = 7.5

# ---------------------------------------------------------------- hit impact
# Every landed bullet gets a procedural impact on top of whatever clip is
# playing: the body is torqued away from the shot (lean + twist from where it
# was hit), shoved a little along the bullet and physically knocked back.
# Directional hit clips are gated separately so automatic fire reads as a
# stream of impacts instead of the same flinch restarting every tick.
# Force is damage relative to a pistol-plus hit: Uzi ~0.4, pistol ~0.6,
# shotgun / crossbow at the cap.
const IMPACT_REF_DAMAGE: float = 40.0
const IMPACT_FORCE_MIN: float = 0.2
const IMPACT_FORCE_MAX: float = 1.8
const IMPACT_HEADSHOT_FORCE: float = 1.25
const IMPACT_TORQUE_GAIN: float = 0.24
const IMPACT_MAX_LEAN: float = 0.30          # rad (~17 deg) total lean + twist
const IMPACT_SPRING: float = 150.0           # stiffness of the lean spring
const IMPACT_DAMPING: float = 13.5           # slightly under-damped: a small rebound
const IMPACT_SHOVE_PER_FORCE: float = 0.055  # visual shove along the shot (m)
const IMPACT_SHOVE_MAX: float = 0.10
const IMPACT_KNOCK_PER_FORCE: float = 1.05   # physical knock speed (m/s)
const IMPACT_KNOCK_MAX: float = 2.1
const IMPACT_KNOCK_DAMP: float = 7.5         # 1/s exponential decay
const IMPACT_ATTACK_SCALE: float = 0.35      # committed swings barely move
# Directional clip gating.
const CLIP_FORCE_THRESHOLD: float = 0.55     # a pistol round or harder plays a clip
const POISE_CLIP_THRESHOLD: float = 1.3      # stacked light hits eventually do too
const POISE_DECAY: float = 1.1               # per second
const HARD_HIT_CLIP_COOLDOWN: float = 0.80
const RAPID_HIT_CLIP_COOLDOWN: float = 1.25
const LIGHT_REACT_HOLD: float = 0.34         # seconds the body stops for a flinch
const LIGHT_REACT_SPEED: float = 1.15
const SAME_CLIP_RESTART_FRACTION: float = 0.45
# Shotgun pellets that hit this body this frame (set by the player just
# before receive_bullet_hit); each gets its own small blood exit.
const BLOOD_PELLET_HITS_META := "blood_pellet_hits"
const BLOOD_MAX_PELLET_SPRAYS := 3
const ZOMBIE_WALK_SFX: AudioStream = preload("res://assets/Audio/Zombie Walking.wav")
const ZOMBIE_GROWL_SFX: AudioStream = preload("res://assets/Audio/Zombie Growl.wav")
const ZOMBIE_ATTACK_SFX: AudioStream = preload("res://assets/Audio/Zombie Attack.wav")
const ZOMBIE_DAMAGE_SFX: AudioStream = preload("res://assets/Audio/Zombie taking Damage.wav")
const ZOMBIE_DEATH_SFX: Array[AudioStream] = [
	preload("res://assets/Audio/Zombie Dying 1.wav"),
	preload("res://assets/Audio/Zombie Dying 2.wav"),
	preload("res://assets/Audio/Zombie Dying 3.wav"),
	preload("res://assets/Audio/Zombie Dying 4.wav"),
]

const FLESH_IMPACT_PATHS: Array[String] = [
	"res://assets/Audio/Zombie Flesh Hits/Zombie_Flesh_Hit_01.mp3",
	"res://assets/Audio/Zombie Flesh Hits/Zombie_Flesh_Hit_02.mp3",
	"res://assets/Audio/Zombie Flesh Hits/Zombie_Flesh_Hit_03.mp3",
]
const FLESH_HIT_CHANCE: float = 0.85
const HEADSHOT_IMPACT_PATHS: Array[String] = [
	"res://assets/Audio/Generated/Bullet Impacts/Headshots/Headshot Impact 01.ogg",
	"res://assets/Audio/Generated/Bullet Impacts/Headshots/Headshot Impact 02.ogg",
	"res://assets/Audio/Generated/Bullet Impacts/Headshots/Headshot Impact 03.ogg",
	"res://assets/Audio/Generated/Bullet Impacts/Headshots/Headshot Impact 04.ogg",
]
const CLAW_HIT_PATHS: Array[String] = [
	"res://assets/Audio/Generated/Zombie Attacks/Claw Hit 01.ogg",
	"res://assets/Audio/Generated/Zombie Attacks/Claw Hit 02.ogg",
	"res://assets/Audio/Generated/Zombie Attacks/Claw Hit 03.ogg",
]
const MISSED_SWIPE_PATHS: Array[String] = [
	"res://assets/Audio/Generated/Zombie Attacks/Missed Swipe 01.ogg",
	"res://assets/Audio/Generated/Zombie Attacks/Missed Swipe 02.ogg",
	"res://assets/Audio/Generated/Zombie Attacks/Missed Swipe 03.ogg",
]
const ATTACK_VOCAL_PATHS: Array[String] = [
	"res://assets/Audio/Generated/Zombie Attacks/Attack Vocal 01.ogg",
	"res://assets/Audio/Generated/Zombie Attacks/Attack Vocal 02.ogg",
	"res://assets/Audio/Generated/Zombie Attacks/Attack Vocal 03.ogg",
	"res://assets/Audio/Generated/Zombie Attacks/Attack Vocal 04.ogg",
]
const ALERT_VOCAL_PATHS: Array[String] = [
	"res://assets/Audio/Generated/Zombie Vocals/Alert 01.ogg",
	"res://assets/Audio/Generated/Zombie Vocals/Alert 02.ogg",
	"res://assets/Audio/Generated/Zombie Vocals/Alert 03.ogg",
	"res://assets/Audio/Generated/Zombie Vocals/Alert 04.ogg",
]
const CHASE_VOCAL_PATHS: Array[String] = [
	"res://assets/Audio/Generated/Zombie Vocals/Chase Loop 01.ogg",
	"res://assets/Audio/Generated/Zombie Vocals/Chase Loop 02.ogg",
	"res://assets/Audio/Generated/Zombie Vocals/Chase Loop 03.ogg",
]
const ZOMBIE_MOVEMENT_PATHS: Array[String] = [
	"res://assets/Audio/Generated/Zombie Movement/Shuffle Step.ogg",
	"res://assets/Audio/Generated/Zombie Movement/Long Foot Drag.ogg",
]
const BODY_FALL_PATHS: Array[String] = [
	"res://assets/Audio/Generated/Zombie Body Falls/Fall 01.ogg",
	"res://assets/Audio/Generated/Zombie Body Falls/Fall 02.ogg",
	"res://assets/Audio/Generated/Zombie Body Falls/Fall 03.ogg",
]
const HEADSHOT_DEATH_FALL_PATH := "res://assets/Audio/Generated/Zombie Body Falls/Headshot Death Fall.ogg"
const FLESH_IMPACT_START_OFFSETS: Array[float] = [0.0, 0.0, 0.0]
const HEADSHOT_IMPACT_START_OFFSETS: Array[float] = [0.0, 0.0, 0.0, 0.0]
const CLAW_HIT_START_OFFSETS: Array[float] = [0.140, 0.025, 0.170]
const MISSED_SWIPE_START_OFFSETS: Array[float] = [0.025, 0.070, 0.0]

@export var max_health: float = 100.0
@export var move_speed: float = 1.35
@export var wander_speed: float = 0.52
@export var acceleration: float = 5.5
@export var attack_range: float = 1.05
@export var attack_damage: float = 10.0
@export var base_money_reward: int = 8
@export var initial_behavior_override: int = -1
@export var route_variant_override: int = -1
@export var locomotion_clip_override: int = -1
@export var surround_slot_override: int = -1
@export var surround_slot_count_override: int = 0
@export var navigation_bounds_override := Rect2()
@export var attack_speed_scale: float = 1.0
@export var stay_on_room_floor: bool = false
## 0 = read RunManager.current_combat_room when the zombie spawns.
@export var combat_room_number: int = 0

signal killed

const MODEL_SCALE: float = 1.82
const BODY_HEIGHT: float = 1.44
const BODY_RADIUS: float = 0.30
# The room teleport lands at Z -6.65. Zombies remain dormant until the player
# moves roughly another 2.2 meters inside, giving the entrance a readable buffer.
const ROOM2_ENTRY_Z: float = -8.85
const ROOM1_ZOMBIE_LIMIT: float = -4.82

# Room 1 default navigation rect (the only room without navigation_bounds_override).
const NAV_X_MIN: float = -13.0
const NAV_Z_MIN: float = -21.8
const NAV_CELL: float = 0.50
const NAV_WIDTH: int = 53
const NAV_HEIGHT: int = 35
const NAV_OBSTACLE_MASK: int = 1 | 16
const NAV_BUILD_DELAY_FRAMES: int = 18
const NAV_REPATH_MIN: float = 0.65
const NAV_REPATH_MAX: float = 0.95
const WAYPOINT_REACHED_DISTANCE: float = 0.40
const MIN_GROWL_INTERVAL: float = 14.0
const MAX_GROWL_INTERVAL: float = 30.0
const CORPSE_HOLD_MIN: float = 4.50
const CORPSE_HOLD_MAX: float = 6.00
const CORPSE_FADE_DURATION: float = 0.90
const ZOMBIE_RENDER_LAYER: int = 1 << 18
const VISUAL_FLOOR_CLEARANCE: float = 0.006

# Shared per-room navigation grid (rebuilt when the active room rect changes).
static var shared_nav_grid: AStarGrid2D = null
static var shared_nav_ready: bool = false
static var shared_nav_signature := ""
static var shared_nav_origin := Vector2(NAV_X_MIN, NAV_Z_MIN)
static var shared_nav_width: int = NAV_WIDTH
static var shared_nav_height: int = NAV_HEIGHT
static var global_voice_lock_until_msec: int = 0
static var global_attack_voice_lock_until_msec: int = 0
static var global_alert_voice_lock_until_msec: int = 0
static var global_death_variant_bag: Array[int] = []
static var global_last_death_variant: int = -1
static var coordinator_last_msec: Dictionary = {}
static var generated_audio_ready: bool = false
static var flesh_impact_streams: Array[AudioStream] = []
static var headshot_impact_streams: Array[AudioStream] = []
static var claw_hit_streams: Array[AudioStream] = []
static var missed_swipe_streams: Array[AudioStream] = []
static var attack_vocal_streams: Array[AudioStream] = []
static var alert_vocal_streams: Array[AudioStream] = []
static var chase_vocal_streams: Array[AudioStream] = []
static var zombie_movement_streams: Array[AudioStream] = []
static var body_fall_streams: Array[AudioStream] = []
static var headshot_death_fall_stream: AudioStream = null
static var combined_scene_cache: PackedScene = null

var health: float = 100.0
var alive: bool = true
var state: int = ZombieState.WANDER
var player: CharacterBody3D = null
var gravity: float = 9.8
var rng := RandomNumberGenerator.new()

# Difficulty (0 = Room 1 shamblers, 1 = Room 20). Layered on top of the
# RunManager HP / damage / speed curve the room controllers already apply.
var aggression: float = 0.2
var turn_rate: float = 3.4
var hold_radius: float = 2.6
var max_attack_tokens: int = 3
var sight_radius: float = 15.0
var hearing_radius: float = 12.0
var proximity_radius: float = 2.8

var state_timer: float = 0.0
var growl_timer: float = 0.0
var encounter_alerted: bool = false
var notice_pending: bool = false
var notice_timer: float = 0.0
var detection_timer: float = 0.0
var last_seen_shots_fired: int = -1
var reaction_cooldown: float = 0.0
var heavy_stagger_cooldown: float = 0.0
var impact_poise: float = 0.0
var impact_lean := Vector3.ZERO        # body-local rotation vector (rad)
var impact_lean_velocity := Vector3.ZERO
var impact_shove := Vector3.ZERO       # body-local visual offset
var impact_shove_velocity := Vector3.ZERO
var impact_knock := Vector3.ZERO       # world-space knock velocity
var visual_base_transform := Transform3D.IDENTITY
var resume_ramp: float = 1.0
var damage_rage_timer: float = 0.0

var nav_build_frames_left: int = NAV_BUILD_DELAY_FRAMES
var nav_path: Array[Vector2i] = []
var nav_path_index: int = 0
var nav_goal_world := Vector3.INF
var chase_repath_timer: float = 0.0
var wander_retarget_timer: float = 0.0
var progress_sample_timer: float = 0.8
var progress_sample_position := Vector3.ZERO
var stuck_recovery_count: int = 0
var unstick_timer: float = 0.0
var unstick_direction := Vector3.ZERO
var last_move_intent_msec: int = 0
var individual_speed_multiplier: float = 1.0
var individual_turn_multiplier: float = 1.0

# Surround state written by the room coordinator.
var slot_angle: float = 0.0
var slot_radius: float = 2.6
var has_attack_token: bool = false
var slot_point := Vector3.INF
var slot_point_timer: float = 0.0
var slot_bias: int = 0
var holding_slot: bool = false
# Approach lane (locked for several seconds so it never flips per repath).
var chase_route_variant: int = 0
var chase_lane_sign: float = 1.0
var chase_lane_distance: float = 0.0
var chase_lane_timer: float = 0.0
var crowd_avoid_sign: float = 1.0
var separation_refresh_timer: float = 0.0
var crowd_push := Vector3.ZERO
var obstacle_steer_direction := Vector3.ZERO
var obstacle_steer_timer: float = 0.0

# Attack.
var attack_cooldown_timer: float = 0.0
var attack_elapsed: float = 0.0
var attack_contact_time_runtime: float = 0.0
var attack_contact_animation_time: float = 0.0
var attack_clip_duration_runtime: float = 0.0
var attack_animation_name: StringName = StringName()
var attack_visual_confirmed: bool = false
var attack_damage_applied: bool = false
var attack_target_contact_distance: float = 0.82
var attack_variant: int = 0
var attack_hand_bone_name: StringName = StringName()
var attack_variant_bag: Array[int] = []
var last_attack_variant: int = -1
var repeated_attack_variant_count: int = 0
var attack_is_finisher: bool = false
var attack_missed: bool = false
var lethal_headshot: bool = false
var reaction_return_state: int = ZombieState.CHASE

# Visual / animation.
var collision_shape: CollisionShape3D = null
var head_hitbox: Area3D = null
var head_hitbox_shape: CollisionShape3D = null
var visual_holder: Node3D = null
var locomotion_visual: Node3D = null
var visual_skeleton: Skeleton3D = null
var head_bone_index: int = -1
var right_hand_index: int = -1
var left_hand_index: int = -1
var anim: AnimationPlayer = null
var anim_name_cache: Dictionary = {}
var loop_clip: StringName = StringName()
var loop_speed: float = 1.0
var one_shot_active: bool = false
var one_shot_timer: float = 0.0
var locomotion_mode: int = ZombieVisualMode.ANGRY
var post_alert_mode: int = ZombieVisualMode.ANGRY
var movement_style_index: int = 0
var idle_animation_name: StringName = &"idle_search"
var idle_change_timer: float = 0.0
var visually_moving: bool = false
var was_walking: bool = false

var walk_audio: AudioStreamPlayer3D = null
var voice_audio: AudioStreamPlayer3D = null
var event_audio_pool: Array[AudioStreamPlayer3D] = []
var event_audio_voice_index: int = 0
var last_event_stream_index: int = -1
var attack_audio: AudioStreamPlayer3D = null
var last_attack_stream_index: int = -1
var zombie_step_timer: float = 0.0

func _ready() -> void:
	health = max_health
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	rng.randomize()
	progress_sample_position = global_position

	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_snap_length = 0.12
	floor_max_angle = deg_to_rad(24.0)
	floor_block_on_wall = true
	floor_stop_on_slope = true
	safe_margin = 0.025
	max_slides = 6

	_configure_difficulty()

	# Broad individual traits: some shamble, most walk, a few are urgent.
	var trait_roll: float = rng.randf()
	if trait_roll < 0.20:
		individual_speed_multiplier = rng.randf_range(0.82, 0.92)
	elif trait_roll < 0.85:
		individual_speed_multiplier = rng.randf_range(0.93, 1.06)
	else:
		individual_speed_multiplier = rng.randf_range(1.07, 1.16)
	move_speed *= individual_speed_multiplier
	wander_speed *= rng.randf_range(0.80, 1.02)
	acceleration *= rng.randf_range(0.80, 1.12)
	individual_turn_multiplier = rng.randf_range(0.82, 1.12)
	rotation.y = rng.randf_range(-PI, PI)
	detection_timer = rng.randf_range(0.05, 0.45)
	separation_refresh_timer = rng.randf_range(0.02, 0.16)
	crowd_avoid_sign = -1.0 if rng.randf() < 0.5 else 1.0
	_configure_chase_route()

	collision_layer = 8
	# 1 world, 2 player, 8 other zombies, 16 zombie-only prop blockers.
	collision_mask = 1 | 2 | 8 | 16
	add_to_group("zombies")
	_ensure_zombie_decal_isolation()

	movement_style_index = clampi(
		locomotion_clip_override if locomotion_clip_override >= 0 else rng.randi_range(0, 3), 0, 3
	)
	if initial_behavior_override >= ZombieVisualMode.ANGRY and initial_behavior_override <= ZombieVisualMode.LOOK_AROUND:
		locomotion_mode = initial_behavior_override
	else:
		locomotion_mode = rng.randi_range(ZombieVisualMode.ANGRY, ZombieVisualMode.LOOK_AROUND)
	post_alert_mode = ZombieVisualMode.ANGRY if movement_style_index == 0 else ZombieVisualMode.LIMP
	if locomotion_mode != ZombieVisualMode.LOOK_AROUND:
		locomotion_mode = post_alert_mode
	idle_animation_name = IDLE_CLIPS[rng.randi_range(0, IDLE_CLIPS.size() - 1)]
	idle_change_timer = rng.randf_range(5.0, 9.0)
	# Seed the surround slot from the controller's shuffled index so the first
	# frames already spread out; the coordinator takes over once alerted.
	if surround_slot_override >= 0 and surround_slot_count_override > 0:
		slot_angle = TAU * float(surround_slot_override % surround_slot_count_override) / float(surround_slot_count_override)
	else:
		slot_angle = rng.randf_range(-PI, PI)
	slot_radius = hold_radius

	_build_body()
	_ensure_generated_audio_cache()
	_build_audio()

	player = get_tree().current_scene.get_node_or_null("Player") as CharacterBody3D
	if player != null:
		last_seen_shots_fired = int(player.get("shots_fired")) if player.get("shots_fired") != null else 0
	_update_locomotion_animation(0.0, true)
	growl_timer = rng.randf_range(9.0, 24.0)

	var scene := get_tree().current_scene
	if navigation_bounds_override.size == Vector2.ZERO:
		if scene != null and bool(scene.get_meta("room2_encounter_alerted", false)):
			activate_chase()
	elif scene != null and bool(scene.get_meta("cafeteria_encounter_alerted", false)) and _is_cafeteria_zombie():
		activate_chase()


func _is_cafeteria_zombie() -> bool:
	var room := _room_root()
	return room != null and room.is_in_group("cafeteria_controller")


func _configure_difficulty() -> void:
	var room_number: int = combat_room_number
	if room_number <= 0:
		room_number = maxi(int(RunManager.current_combat_room), 1)
	combat_room_number = room_number
	# Room 1 is the readable tutorial horde, Room 2 the authored spike, and
	# Rooms 3-20 climb from a mid value to full pressure.
	if room_number <= 1:
		aggression = 0.12
	elif room_number == 2:
		aggression = 0.55
	else:
		aggression = lerpf(0.35, 1.0, clampf(float(room_number - 3) / 17.0, 0.0, 1.0))
	turn_rate = lerpf(3.0, 4.6, aggression)
	hold_radius = lerpf(2.8, 1.9, aggression)
	max_attack_tokens = 2 + int(round(aggression * 4.0))
	sight_radius = lerpf(13.0, 20.0, aggression)
	hearing_radius = lerpf(11.0, 17.0, aggression)
	proximity_radius = lerpf(2.6, 3.6, aggression)


func _build_body() -> void:
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "ZombieCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	collision_shape.shape = capsule
	collision_shape.position = Vector3(0.0, BODY_HEIGHT * 0.5, 0.0)
	add_child(collision_shape)

	# Query-only head volume on layer 32 (player rays use mask 1|8|32).
	head_hitbox = Area3D.new()
	head_hitbox.name = "ZombieHeadHitbox"
	head_hitbox.collision_layer = HEAD_HITBOX_LAYER
	head_hitbox.collision_mask = 0
	head_hitbox.monitoring = false
	head_hitbox.monitorable = true
	head_hitbox.set_meta("zombie_head_hitbox", true)
	head_hitbox_shape = CollisionShape3D.new()
	var head_sphere := SphereShape3D.new()
	head_sphere.radius = 0.27
	head_hitbox_shape.shape = head_sphere
	head_hitbox.add_child(head_hitbox_shape)
	head_hitbox.position = Vector3(0.0, 1.56, 0.0)
	add_child(head_hitbox)

	visual_holder = Node3D.new()
	visual_holder.name = "ZombieVisual"
	visual_holder.scale = Vector3.ONE * MODEL_SCALE
	visual_holder.rotation_degrees.y = 180.0
	add_child(visual_holder)
	visual_base_transform = visual_holder.transform

	# The rig is built exactly once. Changing behaviour (look-around -> angry /
	# limp) never re-instantiates it; rebuilding reset the skeleton to its rest
	# pose and the alert clip blended in from a T-pose.
	var source_scene: PackedScene = _get_combined_scene()
	if source_scene == null:
		push_error("Zombie has no valid visual; keeping gameplay body alive.")
		return
	locomotion_visual = source_scene.instantiate() as Node3D
	if locomotion_visual == null:
		push_error("Zombie GLB instantiated as null.")
		return
	locomotion_visual.name = "BunkerZombieVisual"
	visual_holder.add_child(locomotion_visual)
	_disable_visual_shadows(locomotion_visual)
	anim = _find_animation_player(locomotion_visual)
	if anim != null:
		anim.speed_scale = 1.0
		_prepare_clip_loops()
	else:
		push_error("Zombie GLB has no AnimationPlayer; zombie cannot animate or attack.")
	visual_skeleton = _find_skeleton(locomotion_visual)
	_cache_bones()
	_align_visual_to_floor(locomotion_visual)
	call_deferred("_align_visual_to_floor_if_valid", locomotion_visual)


func _prepare_clip_loops() -> void:
	for clip: StringName in WALK_CLIPS:
		_set_clip_loop(clip, true)
	for clip: StringName in IDLE_CLIPS:
		_set_clip_loop(clip, true)
	for clip: String in [
		"alert", "walk_to_idle", "attack_claw", "attack_lunge", "attack_maul", "finisher_grab_bite",
		"finisher_backhand", "attack_miss_recovery", "hit_front", "hit_left", "hit_right", "stagger_heavy",
		"death_headshot", "death_seated_fold", "death_face_first", "death_side_crumple", "death_forward_collapse",
	]:
		_set_clip_loop(StringName(clip), false)


func _set_clip_loop(clip: StringName, looping: bool) -> void:
	var resolved := _clip(clip)
	if resolved == StringName():
		push_warning("Zombie GLB is missing clip '%s'." % clip)
		return
	var animation: Animation = anim.get_animation(resolved)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE


func _load_audio_paths(paths: Array[String]) -> Array[AudioStream]:
	var streams: Array[AudioStream] = []
	for path: String in paths:
		if not ResourceLoader.exists(path):
			push_error("Zombie gameplay audio is missing: %s" % path)
			continue
		var stream := load(path) as AudioStream
		if stream != null:
			streams.append(stream)
	return streams


func _ensure_generated_audio_cache() -> void:
	if generated_audio_ready:
		return
	flesh_impact_streams = _load_audio_paths(FLESH_IMPACT_PATHS)
	headshot_impact_streams = _load_audio_paths(HEADSHOT_IMPACT_PATHS)
	claw_hit_streams = _load_audio_paths(CLAW_HIT_PATHS)
	missed_swipe_streams = _load_audio_paths(MISSED_SWIPE_PATHS)
	attack_vocal_streams = _load_audio_paths(ATTACK_VOCAL_PATHS)
	alert_vocal_streams = _load_audio_paths(ALERT_VOCAL_PATHS)
	chase_vocal_streams = _load_audio_paths(CHASE_VOCAL_PATHS)
	zombie_movement_streams = _load_audio_paths(ZOMBIE_MOVEMENT_PATHS)
	body_fall_streams = _load_audio_paths(BODY_FALL_PATHS)
	if ResourceLoader.exists(HEADSHOT_DEATH_FALL_PATH):
		headshot_death_fall_stream = load(HEADSHOT_DEATH_FALL_PATH) as AudioStream
	generated_audio_ready = true


func _build_audio() -> void:
	walk_audio = AudioStreamPlayer3D.new()
	walk_audio.name = "ZombieWalkAudio"
	walk_audio.volume_db = -20.0
	walk_audio.max_distance = 7.5
	walk_audio.unit_size = 1.6
	walk_audio.pitch_scale = rng.randf_range(0.92, 1.04)
	add_child(walk_audio)

	voice_audio = AudioStreamPlayer3D.new()
	voice_audio.name = "ZombieVoiceAudio"
	voice_audio.volume_db = -18.0
	voice_audio.max_distance = 12.0
	voice_audio.unit_size = 1.8
	add_child(voice_audio)

	# Small pool so one impact tail is not cut off by the next round.
	for i: int in range(3):
		var impact_player := AudioStreamPlayer3D.new()
		impact_player.name = "ZombieEventAudio_%d" % i
		impact_player.volume_db = -9.0
		impact_player.max_distance = 14.0
		impact_player.unit_size = 2.5
		add_child(impact_player)
		event_audio_pool.append(impact_player)

	attack_audio = AudioStreamPlayer3D.new()
	attack_audio.name = "ZombieAttackContactAudio"
	attack_audio.volume_db = -5.0
	attack_audio.max_distance = 12.0
	attack_audio.unit_size = 2.0
	add_child(attack_audio)
	zombie_step_timer = rng.randf_range(0.15, 0.85)

# =====================================================================
# Notice -> alert -> commit
# =====================================================================

func activate_chase() -> void:
	## Public contract used by the room controllers. Wakes this zombie after a
	## very short, per-zombie reaction so a spawned wave does not move in lockstep.
	if not alive or encounter_alerted:
		return
	_schedule_notice(rng.randf_range(0.0, 0.30))


func alert_from_horde(origin: Vector3) -> void:
	## A neighbour spotted the player. The alert ripples outward by distance.
	if not alive or encounter_alerted or notice_pending:
		return
	var distance: float = Vector2(global_position.x - origin.x, global_position.z - origin.z).length()
	var reaction: float = lerpf(0.55, 0.18, aggression)
	_schedule_notice(distance / 10.0 + rng.randf_range(0.05, reaction))


func _schedule_notice(delay: float) -> void:
	if encounter_alerted:
		return
	if notice_pending:
		notice_timer = minf(notice_timer, delay)
		return
	notice_pending = true
	notice_timer = maxf(delay, 0.0)


func _notice_player_self() -> void:
	## This zombie noticed the player itself: react after a beat, wake the room.
	if encounter_alerted or notice_pending:
		return
	_schedule_notice(rng.randf_range(0.12, lerpf(0.75, 0.25, aggression)))
	_alert_horde()


func _alert_horde() -> void:
	var scene: Node = get_tree().current_scene
	if scene != null and navigation_bounds_override.size == Vector2.ZERO:
		scene.set_meta("room2_encounter_alerted", true)
	var room := _room_root()
	for node: Node in get_tree().get_nodes_in_group("zombies"):
		if node == self or not is_instance_valid(node) or not node.has_method("alert_from_horde"):
			continue
		if room != null and not room.is_ancestor_of(node):
			continue
		node.call("alert_from_horde", global_position)
	MusicManager.zombies_alerted()


func _enter_alert() -> void:
	notice_pending = false
	if encounter_alerted or not alive:
		return
	encounter_alerted = true
	if locomotion_mode == ZombieVisualMode.LOOK_AROUND:
		locomotion_mode = post_alert_mode
	var now_msec := Time.get_ticks_msec()
	if now_msec >= global_alert_voice_lock_until_msec:
		_play_random_voice(alert_vocal_streams, -8.5, 0.97, 1.03)
		global_alert_voice_lock_until_msec = now_msec + rng.randi_range(2600, 4200)
	nav_path.clear()
	nav_path_index = 0
	chase_repath_timer = rng.randf_range(0.02, 0.30)
	chase_lane_timer = rng.randf_range(LANE_LOCK_MIN, LANE_LOCK_MAX)
	if state == ZombieState.ATTACK:
		return
	# Close zombies skip the full alert so they do not stand still in the
	# player's face; everyone else plays the real clip for its real length.
	var close: bool = player != null and _flat_to_player().length() < 2.2
	if close:
		state = ZombieState.CHASE
		one_shot_active = false
		resume_ramp = 0.4
		_start_loop_for_current_motion(0.25)
		return
	if not _play_one_shot(&"alert", 0.22, lerpf(1.0, 1.25, aggression), ZombieState.ALERT, ZombieState.CHASE):
		state = ZombieState.CHASE


func _update_detection(delta: float) -> void:
	if encounter_alerted:
		return
	if notice_pending:
		notice_timer -= delta
		if notice_timer <= 0.0:
			_enter_alert()
		return
	detection_timer -= delta
	if detection_timer > 0.0:
		return
	detection_timer = rng.randf_range(0.28, 0.52)
	if player == null:
		return
	# Room 1 keeps its authored buffer past the hub door; streamed rooms wake
	# once the player is properly inside their floor rect.
	if _player_is_inside_this_room(0.25 if navigation_bounds_override.size != Vector2.ZERO else 0.0):
		_notice_player_self()
		return
	var to_player: Vector3 = _flat_to_player()
	var distance: float = to_player.length()
	if not _player_in_same_room_space():
		return
	if distance <= proximity_radius:
		_notice_player_self()
		return
	var shots: Variant = player.get("shots_fired")
	if shots != null:
		var shots_now: int = int(shots)
		if last_seen_shots_fired >= 0 and shots_now > last_seen_shots_fired and distance <= hearing_radius:
			last_seen_shots_fired = shots_now
			_notice_player_self()
			return
		last_seen_shots_fired = shots_now
	if distance <= sight_radius and distance > 0.01:
		var forward: Vector3 = -global_transform.basis.z
		forward.y = 0.0
		var fov_cos: float = cos(deg_to_rad(75.0))
		if forward.normalized().dot(to_player / distance) >= fov_cos and _cheap_player_los():
			_notice_player_self()


func _player_in_same_room_space() -> bool:
	# Zombies in a parked or neighbouring room must not hear through walls.
	if navigation_bounds_override.size != Vector2.ZERO:
		return _player_is_inside_this_room(-1.5)
	return player.global_position.z <= ROOM1_ZOMBIE_LIMIT


func _cheap_player_los() -> bool:
	if player == null:
		return false
	var origin: Vector3 = global_position + Vector3(0.0, 1.25, 0.0)
	var target: Vector3 = player.global_position + Vector3(0.0, 0.45, 0.0)
	var query := PhysicsRayQueryParameters3D.create(origin, target, 1 | 2)
	query.exclude = [get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or (hit.get("collider") as Object) == player


# =====================================================================
# Main loop
# =====================================================================

func _physics_process(delta: float) -> void:
	if not alive:
		velocity = Vector3.ZERO
		_update_impact_layer(delta)
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().current_scene.get_node_or_null("Player") as CharacterBody3D
		if player == null:
			return

	_update_head_hitbox_from_animation()
	_tick_timers(delta)
	_update_detection(delta)
	_ensure_navigation_grid()
	if encounter_alerted:
		_run_room_coordinator()

	if one_shot_active and state != ZombieState.ATTACK and one_shot_timer <= 0.0:
		_finish_one_shot()

	match state:
		ZombieState.WANDER:
			_update_wander(delta)
		ZombieState.CHASE:
			_update_chase(delta)
		ZombieState.ATTACK:
			_update_attack(delta)
		ZombieState.REACT, ZombieState.ALERT:
			_slow_horizontal(delta)
			if encounter_alerted and player != null:
				_turn_toward(_flat_to_player(), delta, turn_rate * 0.6)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.35
	# Bullet knock rides on top of the steering velocity for this step only, so
	# the chase logic never inherits it and it cannot accumulate into a slide.
	var knock := impact_knock * (IMPACT_ATTACK_SCALE if state == ZombieState.ATTACK else 1.0)
	velocity.x += knock.x
	velocity.z += knock.z
	move_and_slide()
	velocity.x -= knock.x
	velocity.z -= knock.z
	_keep_on_room_floor()
	_update_impact_layer(delta)

	# Room 1 zombies never follow the player back through the hub doorway.
	if navigation_bounds_override.size == Vector2.ZERO and global_position.z > ROOM1_ZOMBIE_LIMIT:
		global_position.z = ROOM1_ZOMBIE_LIMIT
		if velocity.z > 0.0:
			velocity.z = 0.0

	_update_crowd_collision_response()
	_update_progress_recovery()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	_update_walk_sound((state == ZombieState.WANDER or state == ZombieState.CHASE) and horizontal_speed > 0.25)
	_update_growl()
	_update_locomotion_animation(delta)


func _tick_timers(delta: float) -> void:
	state_timer = maxf(0.0, state_timer - delta)
	one_shot_timer = maxf(0.0, one_shot_timer - delta)
	growl_timer = maxf(0.0, growl_timer - delta)
	chase_repath_timer = maxf(0.0, chase_repath_timer - delta)
	wander_retarget_timer = maxf(0.0, wander_retarget_timer - delta)
	progress_sample_timer = maxf(0.0, progress_sample_timer - delta)
	chase_lane_timer = maxf(0.0, chase_lane_timer - delta)
	damage_rage_timer = maxf(0.0, damage_rage_timer - delta)
	separation_refresh_timer = maxf(0.0, separation_refresh_timer - delta)
	obstacle_steer_timer = maxf(0.0, obstacle_steer_timer - delta)
	attack_cooldown_timer = maxf(0.0, attack_cooldown_timer - delta)
	reaction_cooldown = maxf(0.0, reaction_cooldown - delta)
	heavy_stagger_cooldown = maxf(0.0, heavy_stagger_cooldown - delta)
	impact_poise = maxf(0.0, impact_poise - POISE_DECAY * delta)
	idle_change_timer = maxf(0.0, idle_change_timer - delta)
	zombie_step_timer = maxf(0.0, zombie_step_timer - delta)
	slot_point_timer = maxf(0.0, slot_point_timer - delta)
	unstick_timer = maxf(0.0, unstick_timer - delta)
	resume_ramp = minf(1.0, resume_ramp + delta / RESUME_RAMP_TIME)
	if chase_lane_timer <= 0.0:
		chase_lane_timer = rng.randf_range(LANE_LOCK_MIN, LANE_LOCK_MAX)


# =====================================================================
# Wander (pre-alert roamers; LOOK_AROUND sentries stand and idle)
# =====================================================================

func _update_wander(delta: float) -> void:
	if locomotion_mode == ZombieVisualMode.LOOK_AROUND or not shared_nav_ready or one_shot_active:
		nav_path.clear()
		_slow_horizontal(delta)
		return
	var path_done: bool = nav_path.is_empty() or nav_path_index >= nav_path.size()
	if path_done and not nav_path.is_empty():
		# Arrived: loiter a few seconds before shambling somewhere else.
		nav_path.clear()
		wander_retarget_timer = rng.randf_range(2.5, 5.5)
	if nav_path.is_empty():
		if wander_retarget_timer > 0.0:
			_slow_horizontal(delta)
			return
		_choose_random_wander_path()
	var direction := _path_direction()
	if direction.length_squared() < 0.0001:
		_slow_horizontal(delta)
		return
	_steer_and_move(_fallback_obstacle_steer(direction), wander_speed * WALK_MOVE_MULTIPLIERS[movement_style_index], delta)


# =====================================================================
# Chase + surround
# =====================================================================

func _update_chase(delta: float) -> void:
	var to_player: Vector3 = _flat_to_player()
	var player_distance: float = to_player.length()

	if attack_cooldown_timer <= 0.0 and _can_attack_player(player_distance):
		_begin_attack()
		return

	var base_speed: float = move_speed * WALK_MOVE_MULTIPLIERS[movement_style_index]

	# Stuck recovery: a short, committed sidestep / detour before rejoining.
	if unstick_timer > 0.0 and unstick_direction.length_squared() > 0.001:
		_steer_and_move(unstick_direction, base_speed * 0.75, delta)
		return

	var goal: Vector3 = _current_chase_goal(player_distance)
	var to_goal: Vector3 = goal - global_position
	to_goal.y = 0.0
	var goal_distance: float = to_goal.length()

	# Outer-ring zombies that reached their spot wait their turn: stop, face the
	# player and idle instead of strafing on the spot.
	if not has_attack_token and goal_distance <= HOLD_ARRIVE_DISTANCE and player_distance > ANGRY_ATTACK_START_RANGE:
		holding_slot = true
		_slow_horizontal(delta)
		_turn_toward(to_player, delta, 1.8)
		return
	if holding_slot and goal_distance < HOLD_ARRIVE_DISTANCE + 0.55 and not has_attack_token:
		# Hysteresis: small player drift does not make the ring start walking.
		_slow_horizontal(delta)
		_turn_toward(to_player, delta, 1.8)
		return
	holding_slot = false

	var speed: float = base_speed * _catch_up_multiplier(goal_distance, player_distance)
	if not has_attack_token and goal_distance < 1.6:
		speed *= lerpf(0.45, 1.0, clampf(goal_distance / 1.6, 0.0, 1.0))

	var direction: Vector3 = Vector3.ZERO
	# Direct approach when close and nothing solid is in the way; A* otherwise.
	if goal_distance < 2.6 and _clear_walk_line(goal):
		direction = to_goal / maxf(goal_distance, 0.001)
	else:
		if shared_nav_ready:
			var goal_moved: bool = nav_goal_world == Vector3.INF or nav_goal_world.distance_to(goal) > 1.3
			if chase_repath_timer <= 0.0 or goal_moved or nav_path.is_empty() or nav_path_index >= nav_path.size():
				_request_chase_path(goal, player_distance)
				chase_repath_timer = rng.randf_range(NAV_REPATH_MIN, NAV_REPATH_MAX)
			direction = _path_direction()
		if direction.length_squared() < 0.0001 and goal_distance > 0.001:
			direction = to_goal / goal_distance
	direction = _fallback_obstacle_steer(direction)
	_steer_and_move(direction, speed, delta)


func _current_chase_goal(player_distance: float) -> Vector3:
	if player == null:
		return global_position
	var player_pos: Vector3 = player.global_position
	player_pos.y = global_position.y
	if has_attack_token:
		# Token holders come in along their ring bearing, then go straight for
		# the player once inside swinging distance.
		if player_distance < 1.9:
			return _clamp_target_to_combat_room(player_pos)
		if slot_point == Vector3.INF or slot_point_timer <= 0.0:
			slot_point = _resolve_slot_point(slot_angle, TOKEN_RING_RADIUS)
			slot_point_timer = 0.35
		return slot_point
	if slot_point == Vector3.INF or slot_point_timer <= 0.0:
		slot_point = _resolve_slot_point(slot_angle, slot_radius)
		slot_point_timer = rng.randf_range(0.30, 0.45)
	return slot_point


func _resolve_slot_point(angle: float, radius: float) -> Vector3:
	## The ideal ring point, or the nearest valid one: rotate toward this
	## zombie's own side first, then compress inward. In a doorway or corner the
	## ring folds in front of the player instead of pathing through walls.
	var center: Vector3 = player.global_position
	var my_bearing: float = atan2(global_position.z - center.z, global_position.x - center.x)
	var side: float = signf(wrapf(my_bearing - angle, -PI, PI))
	if side == 0.0:
		side = crowd_avoid_sign
	var offsets: Array[float] = [0.0, 0.35, -0.35, 0.7, -0.7, 1.05, -1.05, 1.4, -1.4]
	for radius_scale: float in [1.0, 0.72]:
		for offset: float in offsets:
			var a: float = angle + offset * side
			var candidate: Vector3 = center + Vector3(cos(a), 0.0, sin(a)) * radius * radius_scale
			candidate = _clamp_target_to_combat_room(candidate)
			candidate.y = global_position.y
			if _slot_point_is_open(center, candidate):
				return candidate
	# Everything blocked: approach from wherever this zombie already is.
	var fallback: Vector3 = center + Vector3(cos(my_bearing), 0.0, sin(my_bearing)) * minf(radius, 1.2)
	fallback.y = global_position.y
	return _clamp_target_to_combat_room(fallback)


func _slot_point_is_open(center: Vector3, point: Vector3) -> bool:
	if shared_nav_ready and shared_nav_grid != null:
		if shared_nav_grid.is_point_solid(_world_to_nav_cell(point)):
			return false
	var space := get_world_3d().direct_space_state
	var from: Vector3 = center + Vector3(0.0, 0.2, 0.0)
	var to: Vector3 = Vector3(point.x, from.y, point.z)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.exclude = [get_rid()]
	if player != null:
		query.exclude = [get_rid(), player.get_rid()]
	return space.intersect_ray(query).is_empty()


func _clear_walk_line(goal: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var from: Vector3 = global_position + Vector3(0.0, 0.8, 0.0)
	var to: Vector3 = Vector3(goal.x, from.y, goal.z)
	var query := PhysicsRayQueryParameters3D.create(from, to, NAV_OBSTACLE_MASK)
	query.exclude = [get_rid()]
	if player != null:
		query.exclude = [get_rid(), player.get_rid()]
	return space.intersect_ray(query).is_empty()


func _catch_up_multiplier(goal_distance: float, player_distance: float) -> float:
	var multiplier: float = 1.0
	if goal_distance > 8.0:
		multiplier = 1.16
	elif goal_distance > 5.0:
		multiplier = 1.08
	elif player_distance < 2.0:
		multiplier = 0.94
	if damage_rage_timer > 0.0:
		multiplier *= 1.06
	return multiplier


func _run_room_coordinator() -> void:
	## Once per 0.25 s per room (whichever zombie ticks first does the work):
	## hand out attack tokens and spread ring angles around the player.
	var container: Node = get_parent()
	if container == null or player == null:
		return
	var key: int = container.get_instance_id()
	var now: int = Time.get_ticks_msec()
	if now - int(coordinator_last_msec.get(key, -100000)) < COORDINATOR_INTERVAL_MSEC:
		return
	coordinator_last_msec[key] = now

	var center: Vector3 = player.global_position
	var members: Array = []
	for node: Node in container.get_children():
		if not is_instance_valid(node) or node.get_script() != get_script():
			continue
		if not bool(node.get("alive")) or not bool(node.get("encounter_alerted")):
			continue
		members.append(node)
	if members.is_empty():
		return

	# --- attack tokens: keep holders that are still engaged, fill by distance.
	members.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_squared_to(center) < b.global_position.distance_squared_to(center))
	var token_budget: int = int(members[0].get("max_attack_tokens"))
	var holders: Array = []
	for m: Node3D in members:
		var engaged: bool = int(m.get("state")) == ZombieState.ATTACK or m.global_position.distance_to(center) <= TOKEN_KEEP_DISTANCE
		if bool(m.get("has_attack_token")) and engaged and holders.size() < token_budget:
			holders.append(m)
	for m: Node3D in members:
		if holders.size() >= token_budget:
			break
		if not holders.has(m):
			holders.append(m)
	var outer: Array = []
	for m: Node3D in members:
		var holds: bool = holders.has(m)
		if holds != bool(m.get("has_attack_token")):
			m.set("slot_point_timer", 0.0)
		m.set("has_attack_token", holds)
		if not holds:
			outer.append(m)

	_spread_ring(holders, center, TOKEN_RING_RADIUS)
	_spread_ring(outer, center, float(members[0].get("hold_radius")))


static func _spread_ring(ring: Array, center: Vector3, radius: float) -> void:
	## Evenly spaced angles that preserve each zombie's current circular order,
	## rotated to minimise total movement. Nobody crosses anybody, and when a
	## member dies the remaining angles simply re-spread to close the hole.
	var count: int = ring.size()
	if count == 0:
		return
	var bearings: Array = []
	for m: Node3D in ring:
		bearings.append([atan2(m.global_position.z - center.z, m.global_position.x - center.x), m])
	bearings.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var step: float = TAU / float(count)
	var sin_sum: float = 0.0
	var cos_sum: float = 0.0
	for index: int in range(count):
		var offset: float = float(bearings[index][0]) - float(index) * step
		sin_sum += sin(offset)
		cos_sum += cos(offset)
	var base: float = atan2(sin_sum, cos_sum)
	for index: int in range(count):
		var m: Node3D = bearings[index][1]
		var new_angle: float = base + float(index) * step + float(int(m.get("slot_bias"))) * 0.45
		var old_angle: float = float(m.get("slot_angle"))
		# Small corrections are ignored so the ring does not shimmer.
		if absf(wrapf(new_angle - old_angle, -PI, PI)) > 0.12 or absf(float(m.get("slot_radius")) - radius) > 0.05:
			m.set("slot_angle", new_angle)
			m.set("slot_radius", radius)


# =====================================================================
# Steering: body turns toward where it wants to go and walks along its facing
# =====================================================================

func _steer_and_move(direction: Vector3, speed: float, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		_slow_horizontal(delta)
		return
	var desired: Vector3 = Vector3(direction.x, 0.0, direction.z).normalized()
	if speed > 0.2:
		last_move_intent_msec = Time.get_ticks_msec()
	_turn_toward(desired, delta, turn_rate * individual_turn_multiplier)
	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var alignment: float = forward.dot(desired)
	# Misaligned bodies turn first and barely creep; aligned bodies walk at speed.
	var speed_factor: float = clampf((alignment - 0.10) / 0.75, 0.10, 1.0)
	var move_dir: Vector3 = forward.lerp(desired, 0.25).normalized()
	var target_velocity: Vector3 = move_dir * speed * speed_factor * resume_ramp
	target_velocity += _crowd_separation(desired)
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)


func _turn_toward(flat_direction: Vector3, delta: float, rate: float) -> void:
	if flat_direction.length_squared() < 0.0064:
		return
	var direction := flat_direction.normalized()
	var target_yaw := atan2(-direction.x, -direction.z)
	# World yaw: streamed rooms may be rotated onto their doorway.
	global_rotation.y = rotate_toward(global_rotation.y, target_yaw, rate * delta)


func _slow_horizontal(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * 2.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * 2.0 * delta)


func _crowd_separation(desired: Vector3) -> Vector3:
	## Small sideways shove away from close neighbours, capped so bodies can
	## jostle but never slide at full speed sideways under a forward walk.
	if separation_refresh_timer <= 0.0:
		separation_refresh_timer = rng.randf_range(0.10, 0.18)
		var push := Vector3.ZERO
		for node: Node in get_tree().get_nodes_in_group("zombies"):
			if node == self or not is_instance_valid(node) or not (node is Node3D) or not bool(node.get("alive")):
				continue
			var away: Vector3 = global_position - (node as Node3D).global_position
			away.y = 0.0
			var distance: float = away.length()
			if distance <= 0.001 or distance >= ZOMBIE_PERSONAL_SPACE:
				continue
			var closeness: float = (ZOMBIE_PERSONAL_SPACE - distance) / ZOMBIE_PERSONAL_SPACE
			push += away / distance * closeness
			# Someone directly ahead: lean around them on this zombie's side.
			if desired.dot(-away / distance) > 0.35:
				push += Vector3(desired.z, 0.0, -desired.x) * crowd_avoid_sign * closeness * 0.6
		crowd_push = crowd_push.lerp(push * 0.9, 0.6)
	var limited: Vector3 = crowd_push
	if limited.length() > CROWD_PUSH_MAX:
		limited = limited.normalized() * CROWD_PUSH_MAX
	return limited


func _update_crowd_collision_response() -> void:
	for collision_index in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(collision_index)
		if collision == null:
			continue
		var collider: Object = collision.get_collider()
		if collider == null or not (collider is Node) or not (collider as Node).is_in_group("zombies"):
			continue
		# Never ride up on another zombie's capsule (that is what launched bodies).
		if collision.get_normal().y > 0.3:
			var away: Vector3 = global_position - (collider as Node3D).global_position
			away.y = 0.0
			if away.length_squared() < 0.0001:
				away = Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
			velocity.y = minf(velocity.y, 0.0)
			velocity += away.normalized() * 0.8
		break


func _update_progress_recovery() -> void:
	if progress_sample_timer > 0.0:
		return
	progress_sample_timer = rng.randf_range(0.75, 0.95)
	var moved: Vector3 = global_position - progress_sample_position
	moved.y = 0.0
	progress_sample_position = global_position
	var trying: bool = (
		(state == ZombieState.CHASE and not holding_slot) or
		(state == ZombieState.WANDER and locomotion_mode != ZombieVisualMode.LOOK_AROUND)
	) and unstick_timer <= 0.0 and Time.get_ticks_msec() - last_move_intent_msec < 250
	if not trying:
		stuck_recovery_count = 0
		return
	if moved.length() >= 0.12:
		stuck_recovery_count = 0
		return
	stuck_recovery_count += 1
	nav_path.clear()
	nav_path_index = 0
	chase_repath_timer = 0.0
	if state == ZombieState.WANDER:
		wander_retarget_timer = 0.0
		return
	# Escalating ladder; never a frozen zombie, never a teleport.
	match stuck_recovery_count:
		1:
			chase_lane_sign = -chase_lane_sign
			obstacle_steer_timer = 0.0
		2:
			_begin_unstick(true)
		3:
			slot_bias = (slot_bias + 1) % 3
			slot_point_timer = 0.0
			_begin_unstick(false)
		_:
			stuck_recovery_count = 0
			slot_bias = 0
			_begin_unstick(false)
			unstick_timer = 1.2


func _begin_unstick(sidestep: bool) -> void:
	var forward: Vector3 = _flat_to_player().normalized()
	if forward.length_squared() < 0.001:
		forward = -global_transform.basis.z
	var candidates: Array[Vector3] = []
	var tangent := Vector3(-forward.z, 0.0, forward.x) * crowd_avoid_sign
	if sidestep:
		candidates = [tangent, -tangent, (tangent - forward * 0.4).normalized(), (-tangent - forward * 0.4).normalized()]
	else:
		for i: int in range(8):
			var a: float = rng.randf_range(-PI, PI)
			candidates.append(Vector3(cos(a), 0.0, sin(a)))
	var space := get_world_3d().direct_space_state
	var origin: Vector3 = global_position + Vector3(0.0, 0.8, 0.0)
	for candidate: Vector3 in candidates:
		var query := PhysicsRayQueryParameters3D.create(origin, origin + candidate * 1.4, NAV_OBSTACLE_MASK | 8)
		query.exclude = [get_rid()]
		if space.intersect_ray(query).is_empty():
			unstick_direction = candidate
			unstick_timer = rng.randf_range(0.55, 0.8)
			crowd_avoid_sign = -crowd_avoid_sign if not sidestep else crowd_avoid_sign
			return
	unstick_direction = -forward
	unstick_timer = 0.5

# =====================================================================
# Attack: commit, wind up, strike with the hand, recover like a body
# =====================================================================

func _can_attack_player(distance: float) -> bool:
	if player == null:
		return false
	var start_range: float = LIMP_ATTACK_START_RANGE if locomotion_mode == ZombieVisualMode.LIMP else ANGRY_ATTACK_START_RANGE
	if distance > start_range:
		return false
	var to_player: Vector3 = _flat_to_player()
	if to_player.length_squared() > 0.0001:
		var forward: Vector3 = -global_transform.basis.z
		forward.y = 0.0
		if forward.normalized().dot(to_player.normalized()) < cos(deg_to_rad(55.0)):
			# Not facing yet: keep turning (chase steering does it) instead of
			# swiping sideways.
			return false
	return _has_clear_player_line()


func _begin_attack() -> void:
	if not alive or anim == null:
		return
	attack_is_finisher = _should_use_finisher()
	attack_variant = _draw_finisher_variant() if attack_is_finisher else _draw_attack_variant()
	var clip: StringName = _clip(StringName(_attack_clip_for_variant(attack_variant, attack_is_finisher)))
	if clip == StringName():
		# Never fake a hit with a missing clip: fall back to the claw or skip.
		attack_is_finisher = false
		attack_variant = 0
		clip = _clip(&"attack_claw")
		if clip == StringName():
			attack_cooldown_timer = 0.6
			return
	_configure_attack_variant(attack_variant)
	var attack_animation: Animation = anim.get_animation(clip)
	if attack_animation == null:
		attack_cooldown_timer = 0.6
		return

	state = ZombieState.ATTACK
	one_shot_active = true
	attack_elapsed = 0.0
	attack_damage_applied = false
	attack_missed = false
	attack_animation_name = clip
	attack_clip_duration_runtime = attack_animation.length / _attack_playback_speed()
	loop_clip = StringName()
	# Same player, same skeleton: crossfade from whatever the body was doing
	# (walk / idle). No player swap and no seek(0) that would discard the blend.
	anim.speed_scale = 1.0
	if anim.current_animation == String(clip):
		anim.stop(true)
	anim.play(clip, ATTACK_BLEND_IN, _attack_playback_speed())
	attack_visual_confirmed = anim.current_animation == String(clip)
	if not attack_visual_confirmed:
		_abort_attack_without_damage()
		return
	if attack_is_finisher and player != null and player.has_method("begin_zombie_finisher"):
		player.call("begin_zombie_finisher", global_position, String(clip), attack_contact_time_runtime)
	var now_msec: int = Time.get_ticks_msec()
	if now_msec >= global_attack_voice_lock_until_msec and rng.randf() < 0.46:
		_play_random_voice(attack_vocal_streams, -10.5, 0.95, 1.04)
		global_attack_voice_lock_until_msec = now_msec + rng.randi_range(3000, 5200)


func _update_attack(delta: float) -> void:
	if not attack_visual_confirmed or anim == null or anim.current_animation != String(attack_animation_name):
		_abort_attack_without_damage()
		return
	var to_player: Vector3 = _flat_to_player()
	var distance: float = to_player.length()
	attack_elapsed += delta
	var time_until_contact: float = attack_contact_time_runtime - attack_elapsed

	# Windup: keep turning onto the player (rotate_toward, no snap) and take a
	# small controlled step in so the animated hand can actually arrive.
	if time_until_contact > 0.08:
		_turn_toward(to_player, delta, 5.0 * individual_turn_multiplier)
		if distance > attack_target_contact_distance and to_player.length_squared() > 0.0001:
			var approach: Vector3 = to_player.normalized() * minf(ATTACK_WINDUP_APPROACH_SPEED, move_speed * 0.58)
			velocity.x = move_toward(velocity.x, approach.x, acceleration * delta)
			velocity.z = move_toward(velocity.z, approach.z, acceleration * delta)
		else:
			_slow_horizontal(delta)
	else:
		_turn_toward(to_player, delta, 1.6)
		_slow_horizontal(delta)

	if not attack_damage_applied and anim.current_animation_position >= attack_contact_animation_time:
		attack_damage_applied = true
		var hand_world: Vector3 = _striking_hand_on_target()
		if hand_world != Vector3.ZERO:
			_play_random_attack_sound(claw_hit_streams, -4.0, 0.97, 1.03, CLAW_HIT_START_OFFSETS)
			if player != null and player.has_method("take_damage"):
				player.call("take_damage", attack_damage, hand_world, 1.18, "zombie_melee")
		else:
			attack_missed = true
			_play_random_attack_sound(missed_swipe_streams, -7.0, 0.96, 1.04, MISSED_SWIPE_START_OFFSETS)

	# Leave during the follow-through with a long blend so the arms settle into
	# the walk instead of snapping from the last attack frame.
	if attack_elapsed >= attack_clip_duration_runtime * ATTACK_EXIT_FRACTION or not anim.is_playing():
		_finish_attack()


func _finish_attack() -> void:
	one_shot_active = false
	attack_visual_confirmed = false
	attack_animation_name = StringName()
	attack_cooldown_timer = lerpf(0.62, 0.22, aggression) + rng.randf_range(0.0, 0.18)
	chase_repath_timer = 0.0
	slot_point_timer = 0.0
	if attack_missed and not attack_is_finisher:
		# Stumble out of the whiff, then come again. Later rooms recover faster.
		if _play_one_shot(&"attack_miss_recovery", 0.24, lerpf(1.0, 1.3, aggression), ZombieState.REACT, ZombieState.CHASE):
			return
	state = ZombieState.CHASE
	resume_ramp = 0.3
	_start_loop_for_current_motion(ATTACK_BLEND_OUT)


func _abort_attack_without_damage() -> void:
	attack_damage_applied = true
	attack_visual_confirmed = false
	attack_animation_name = StringName()
	one_shot_active = false
	attack_cooldown_timer = 0.25
	state = ZombieState.CHASE
	chase_repath_timer = 0.0
	resume_ramp = 0.4
	_start_loop_for_current_motion(ONE_SHOT_BLEND_OUT)


func _striking_hand_on_target() -> Vector3:
	## Damage only if an animated hand is within reach of the player's upper
	## chest / face at the contact frame. The primary hand is checked first;
	## the maul and finishers use both arms, so the other hand also counts.
	if player == null or not _has_clear_player_line():
		return Vector3.ZERO
	var target: Vector3 = player.global_position + Vector3(0.0, 0.53, 0.0)
	var camera_node: Camera3D = null
	if player.get_viewport() != null:
		camera_node = player.get_viewport().get_camera_3d()
	if camera_node != null and camera_node.is_inside_tree() and player.is_ancestor_of(camera_node):
		target = camera_node.global_position + Vector3(0.0, -0.10, 0.0)
	var primary: int = left_hand_index if attack_hand_bone_name == LEFT_HAND_BONE else right_hand_index
	var secondary: int = right_hand_index if primary == left_hand_index else left_hand_index
	for bone: int in [primary, secondary]:
		if bone < 0 or visual_skeleton == null:
			continue
		var hand: Vector3 = visual_skeleton.global_transform * visual_skeleton.get_bone_global_pose(bone).origin
		if hand.distance_to(target) <= ATTACK_HAND_CONTACT_RADIUS:
			return hand
	return Vector3.ZERO


func _draw_attack_variant() -> int:
	if attack_variant_bag.is_empty():
		attack_variant_bag = [0, 1, 2, 0, 1, 2]
		for index: int in range(attack_variant_bag.size() - 1, 0, -1):
			var swap_index: int = rng.randi_range(0, index)
			var saved_value: int = attack_variant_bag[index]
			attack_variant_bag[index] = attack_variant_bag[swap_index]
			attack_variant_bag[swap_index] = saved_value
	if repeated_attack_variant_count >= 2 and attack_variant_bag.back() == last_attack_variant:
		for index: int in range(attack_variant_bag.size() - 1):
			if attack_variant_bag[index] != last_attack_variant:
				var replacement: int = attack_variant_bag[index]
				attack_variant_bag[index] = attack_variant_bag.back()
				attack_variant_bag[attack_variant_bag.size() - 1] = replacement
				break
	var chosen: int = attack_variant_bag.pop_back()
	if chosen == last_attack_variant:
		repeated_attack_variant_count += 1
	else:
		last_attack_variant = chosen
		repeated_attack_variant_count = 1
	return chosen


func _draw_finisher_variant() -> int:
	return rng.randi_range(0, 1)


func _should_use_finisher() -> bool:
	if player == null:
		return false
	var current_health: Variant = player.get("health")
	if current_health == null:
		return false
	return float(current_health) <= attack_damage and _flat_to_player().length() <= 0.98


func _attack_clip_for_variant(chosen_variant: int, finisher: bool) -> String:
	if finisher:
		return "finisher_grab_bite" if chosen_variant == 0 else "finisher_backhand"
	var clips: Array[String] = ["attack_claw", "attack_lunge", "attack_maul"]
	return clips[clampi(chosen_variant, 0, clips.size() - 1)]


func _configure_attack_variant(chosen_variant: int) -> void:
	if attack_is_finisher:
		attack_contact_animation_time = FINISHER_CONTACT_TIMES[clampi(chosen_variant, 0, 1)]
		attack_target_contact_distance = FINISHER_CONTACT_DISTANCE
		attack_hand_bone_name = LEFT_HAND_BONE if chosen_variant == 1 else RIGHT_HAND_BONE
	else:
		attack_contact_animation_time = ATTACK_CONTACT_TIMES[clampi(chosen_variant, 0, 2)]
		attack_target_contact_distance = ATTACK_CONTACT_DISTANCES[clampi(chosen_variant, 0, 2)]
		attack_hand_bone_name = LEFT_HAND_BONE if chosen_variant == 2 else RIGHT_HAND_BONE
	# Animation timeline vs real seconds: keep both so faster playback never moves
	# damage off the visible hand contact.
	attack_contact_time_runtime = attack_contact_animation_time / _attack_playback_speed()


func _attack_playback_speed() -> float:
	return ATTACK_PLAYBACK_SPEED * maxf(attack_speed_scale, 0.35)


func _has_clear_player_line() -> bool:
	if player == null:
		return false
	var origin: Vector3 = global_position + Vector3(0.0, 1.18, 0.0)
	var destination: Vector3 = player.global_position + Vector3(0.0, 0.1, 0.0)
	var query := PhysicsRayQueryParameters3D.create(origin, destination, 1 | 2 | 16)
	query.exclude = [get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or (hit.get("collider") as Object) == player


# =====================================================================
# Taking damage / dying
# =====================================================================

func take_damage(amount: float) -> void:
	receive_bullet_hit(amount, global_position + Vector3(0.0, 1.0, 0.0), Vector3.ZERO, false)


func receive_bullet_hit(
	base_damage: float,
	hit_position: Vector3,
	shot_origin: Vector3,
	is_headshot: bool = false,
	hit_normal: Vector3 = Vector3.ZERO
) -> void:
	if not alive:
		return
	# Getting shot always wakes this zombie now and ripples to the room.
	if not encounter_alerted:
		notice_pending = false
		_alert_horde()
		_enter_alert()

	var damage: float = maxf(base_damage, 0.0) * (HEADSHOT_DAMAGE_MULTIPLIER if is_headshot else 1.0)
	RunManager.register_damage_dealt(minf(damage, health))
	health = maxf(0.0, health - damage)
	_spawn_blood_exit(hit_position, shot_origin, hit_normal, is_headshot, health <= 0.0)
	if health <= 0.0:
		if not is_headshot:
			_play_flesh_hit_sfx()
		lethal_headshot = is_headshot
		_die(is_headshot)
		return
	if is_headshot:
		_play_random_event(headshot_impact_streams, -2.5, 0.98, 1.02, HEADSHOT_IMPACT_START_OFFSETS)
	else:
		_play_flesh_hit_sfx()

	var force: float = clampf(damage / IMPACT_REF_DAMAGE, IMPACT_FORCE_MIN, IMPACT_FORCE_MAX)
	if is_headshot:
		force = minf(force * IMPACT_HEADSHOT_FORCE, IMPACT_FORCE_MAX)
	_apply_hit_impact(hit_position, shot_origin, force)
	_react_to_hit(hit_position, shot_origin, force)

	damage_rage_timer = rng.randf_range(1.35, 2.80)
	chase_repath_timer = 0.0
	_play_voice_sound(ZOMBIE_DAMAGE_SFX, -8.5, rng.randf_range(0.95, 1.05))


func _play_flesh_hit_sfx() -> void:
	if rng.randf() > FLESH_HIT_CHANCE:
		return
	_play_random_event(flesh_impact_streams, -8.5, 0.96, 1.05, FLESH_IMPACT_START_OFFSETS)


func _spawn_blood_exit(
	hit_position: Vector3,
	shot_origin: Vector3,
	hit_normal: Vector3,
	is_headshot: bool,
	lethal: bool
) -> void:
	# Every landed hit bleeds. The effect lives in world space (see
	# BloodExitFx), never on this body, so flinches and death cannot drag it.
	var pellet_hits := PackedVector3Array()
	if has_meta(BLOOD_PELLET_HITS_META):
		pellet_hits = get_meta(BLOOD_PELLET_HITS_META)
		remove_meta(BLOOD_PELLET_HITS_META)
	var kind: int = BloodExitFx.Kind.HEAD if is_headshot else BloodExitFx.Kind.BODY
	if pellet_hits.is_empty():
		BloodExitFx.spray(get_tree(), hit_position, _blood_exit_axis(hit_position, shot_origin, hit_normal), kind, lethal)
		return
	for i in mini(pellet_hits.size(), BLOOD_MAX_PELLET_SPRAYS):
		var pellet_position: Vector3 = pellet_hits[i]
		BloodExitFx.spray(
			get_tree(),
			pellet_position,
			_blood_exit_axis(pellet_position, shot_origin, hit_normal),
			BloodExitFx.Kind.PELLET,
			lethal and i == 0
		)


func _blood_exit_axis(hit_position: Vector3, shot_origin: Vector3, hit_normal: Vector3) -> Vector3:
	var body_center: Vector3 = global_position + Vector3.UP * (BODY_HEIGHT * 0.5)
	var outward: Vector3 = hit_normal
	if outward.length_squared() < 0.0001:
		outward = hit_position - body_center
	# Entry wounds spray back toward the shooter, not down the bullet.
	if shot_origin != Vector3.ZERO:
		var to_shooter: Vector3 = shot_origin - hit_position
		if to_shooter.length_squared() > 0.0001 and outward.dot(to_shooter) < 0.0:
			outward = -outward
	if outward.length_squared() < 0.0001:
		outward = Vector3.UP
	return outward.normalized()


func _shot_direction(hit_position: Vector3, shot_origin: Vector3) -> Vector3:
	## Horizontal direction the bullet was travelling (shooter -> body).
	var direction: Vector3 = hit_position - shot_origin if shot_origin != Vector3.ZERO else Vector3.ZERO
	if direction.length_squared() < 0.0001 and player != null and is_instance_valid(player):
		direction = global_position - player.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return Vector3.ZERO
	return direction.normalized()


func _apply_hit_impact(hit_position: Vector3, shot_origin: Vector3, force: float) -> void:
	## Procedural layer, every hit: torque from where the round landed (lean
	## away from the shot, twist on a shoulder hit), a short shove along the
	## bullet and a small physical knock. Retriggerable, so rapid fire keeps
	## reading as separate impacts without restarting any clip.
	var direction := _shot_direction(hit_position, shot_origin)
	if direction == Vector3.ZERO:
		return
	var lever: Vector3 = hit_position - global_position
	lever.y = clampf(lever.y, 0.6, 1.8)
	var torque_world: Vector3 = lever.cross(direction) * (IMPACT_TORQUE_GAIN * force)
	var body_inverse: Basis = global_transform.basis.orthonormalized().inverse()
	var torque_local: Vector3 = body_inverse * torque_world
	# Impulse into the spring's velocity: the peak lean lands a frame or two
	# later, which reads as a hit rather than a snapped pose.
	impact_lean_velocity += torque_local * sqrt(IMPACT_SPRING)
	var shove_local: Vector3 = body_inverse * (direction * IMPACT_SHOVE_PER_FORCE * force)
	impact_shove_velocity += shove_local * sqrt(IMPACT_SPRING)
	impact_knock += direction * (IMPACT_KNOCK_PER_FORCE * force)
	var knock_speed: float = impact_knock.length()
	if knock_speed > IMPACT_KNOCK_MAX:
		impact_knock *= IMPACT_KNOCK_MAX / knock_speed


func _update_impact_layer(delta: float) -> void:
	if visual_holder == null:
		return
	impact_knock *= exp(-IMPACT_KNOCK_DAMP * delta)
	if impact_knock.length_squared() < 0.0004:
		impact_knock = Vector3.ZERO
	var at_rest: bool = impact_lean.length_squared() < 0.00002 and impact_lean_velocity.length_squared() < 0.0002 \
		and impact_shove.length_squared() < 0.000002 and impact_shove_velocity.length_squared() < 0.00002
	if at_rest:
		if impact_lean != Vector3.ZERO or impact_shove != Vector3.ZERO:
			impact_lean = Vector3.ZERO
			impact_lean_velocity = Vector3.ZERO
			impact_shove = Vector3.ZERO
			impact_shove_velocity = Vector3.ZERO
			visual_holder.transform = visual_base_transform
		return
	var step: float = minf(delta, 1.0 / 30.0)
	impact_lean_velocity += (-IMPACT_SPRING * impact_lean - IMPACT_DAMPING * impact_lean_velocity) * step
	impact_lean += impact_lean_velocity * step
	if impact_lean.length() > IMPACT_MAX_LEAN:
		impact_lean = impact_lean.normalized() * IMPACT_MAX_LEAN
	impact_shove_velocity += (-IMPACT_SPRING * impact_shove - IMPACT_DAMPING * impact_shove_velocity) * step
	impact_shove += impact_shove_velocity * step
	if impact_shove.length() > IMPACT_SHOVE_MAX:
		impact_shove = impact_shove.normalized() * IMPACT_SHOVE_MAX
	var lean_basis := Basis.IDENTITY
	var angle: float = impact_lean.length()
	if angle > 0.00001:
		lean_basis = Basis(impact_lean / angle, angle)
	visual_holder.transform = Transform3D(
		lean_basis * visual_base_transform.basis,
		visual_base_transform.origin + impact_shove
	)


func _react_to_hit(hit_position: Vector3, shot_origin: Vector3, force: float) -> void:
	## Clip layer. A committed swing is never interrupted. Hard single hits
	## flinch on a short cooldown; light automatic fire stacks poise and only
	## flinches once it builds up, then gets a longer window to keep walking.
	impact_poise += force
	if state == ZombieState.ATTACK or reaction_cooldown > 0.0:
		return
	if force >= HEAVY_STAGGER_MIN_FORCE and heavy_stagger_cooldown <= 0.0 and rng.randf() < HEAVY_STAGGER_CHANCE:
		if _play_one_shot(&"stagger_heavy", REACTION_BLEND_IN, 1.0, ZombieState.REACT, ZombieState.CHASE):
			heavy_stagger_cooldown = rng.randf_range(HEAVY_STAGGER_COOLDOWN_MIN, HEAVY_STAGGER_COOLDOWN_MAX)
			reaction_cooldown = maxf(one_shot_timer, 1.0)
			impact_poise = 0.0
			return
	var hard_hit: bool = force >= CLIP_FORCE_THRESHOLD
	if not hard_hit and impact_poise < POISE_CLIP_THRESHOLD:
		return
	var reaction: StringName = _directional_hit_animation(hit_position, shot_origin)
	if _is_clip_early_in_playback(reaction):
		# Same flinch still in its first half: let it finish instead of
		# snapping it back to frame 0. The procedural impact still lands.
		return
	if not _play_one_shot(reaction, REACTION_BLEND_IN, LIGHT_REACT_SPEED, ZombieState.REACT, ZombieState.CHASE):
		return
	one_shot_timer = minf(one_shot_timer, LIGHT_REACT_HOLD)
	reaction_cooldown = HARD_HIT_CLIP_COOLDOWN if hard_hit else RAPID_HIT_CLIP_COOLDOWN
	impact_poise = 0.0


func _is_clip_early_in_playback(keyword: StringName) -> bool:
	if anim == null:
		return false
	var chosen: StringName = _clip(keyword)
	if chosen == StringName() or anim.current_animation != String(chosen):
		return false
	var length: float = anim.current_animation_length
	return length > 0.0 and anim.current_animation_position < length * SAME_CLIP_RESTART_FRACTION


func _directional_hit_animation(hit_position: Vector3, shot_origin: Vector3) -> StringName:
	var source_direction: Vector3 = shot_origin - global_position
	if shot_origin == Vector3.ZERO:
		source_direction = hit_position - global_position
	source_direction.y = 0.0
	if source_direction.length_squared() < 0.0001:
		return &"hit_front"
	var local_source: Vector3 = global_transform.basis.inverse() * source_direction.normalized()
	if absf(local_source.x) < 0.48:
		return &"hit_front"
	return &"hit_right" if local_source.x > 0.0 else &"hit_left"


func _die(was_headshot: bool = false) -> void:
	if not alive:
		return
	var died_during_attack: bool = state == ZombieState.ATTACK
	alive = false
	state = ZombieState.DEAD
	one_shot_active = true
	velocity = Vector3.ZERO
	killed.emit()

	var earned_reward: int = EconomyManager.award_zombie_kill(base_money_reward)
	RunManager.register_kill(earned_reward)
	if player != null and is_instance_valid(player) and player.has_method("register_zombie_kill"):
		player.call("register_zombie_kill", earned_reward)

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if head_hitbox_shape != null:
		head_hitbox_shape.set_deferred("disabled", true)
	if walk_audio != null:
		walk_audio.stop()
	if voice_audio != null:
		voice_audio.stop()

	if was_headshot:
		_play_death_clip(&"death_headshot", 0.18 if died_during_attack else 0.14, rng.randf_range(0.96, 1.03))
	else:
		var death_names: Array[StringName] = [&"death_seated_fold", &"death_face_first", &"death_side_crumple", &"death_forward_collapse"]
		var speed: float = rng.randf_range(0.92, 1.0) if locomotion_mode == ZombieVisualMode.LIMP else rng.randf_range(0.96, 1.05)
		_play_death_clip(death_names[_draw_global_death_variant()], rng.randf_range(0.18, 0.22) if died_during_attack else rng.randf_range(0.14, 0.18), speed)

	var death_index := rng.randi_range(0, ZOMBIE_DEATH_SFX.size() - 1)
	_play_voice_sound(ZOMBIE_DEATH_SFX[death_index], -5.5, rng.randf_range(0.94, 1.03))


func _play_death_clip(keyword: StringName, blend: float, speed: float) -> void:
	var chosen: StringName = _clip(keyword)
	if anim == null or chosen == StringName():
		push_warning("Zombie GLB is missing death clip '%s'." % keyword)
		_schedule_corpse_cleanup(CORPSE_HOLD_MIN)
		return
	var animation: Animation = anim.get_animation(chosen)
	anim.speed_scale = 1.0
	anim.play(chosen, blend, speed)
	var duration: float = animation.length / speed if animation != null else 1.8
	_schedule_corpse_cleanup(duration + rng.randf_range(CORPSE_HOLD_MIN, CORPSE_HOLD_MAX))


func _draw_global_death_variant() -> int:
	# Shared bag: every four kills use every ordinary death once, no repeats
	# across bag boundaries.
	if global_death_variant_bag.is_empty():
		global_death_variant_bag = [0, 1, 2, 3]
		for index: int in range(global_death_variant_bag.size() - 1, 0, -1):
			var swap_index: int = rng.randi_range(0, index)
			var saved: int = global_death_variant_bag[index]
			global_death_variant_bag[index] = global_death_variant_bag[swap_index]
			global_death_variant_bag[swap_index] = saved
		if global_last_death_variant >= 0 and global_death_variant_bag.back() == global_last_death_variant:
			var swap_with: int = rng.randi_range(0, global_death_variant_bag.size() - 2)
			var replacement: int = global_death_variant_bag[swap_with]
			global_death_variant_bag[swap_with] = global_death_variant_bag.back()
			global_death_variant_bag[global_death_variant_bag.size() - 1] = replacement
	var chosen: int = global_death_variant_bag.pop_back()
	global_last_death_variant = chosen
	return chosen


func _schedule_corpse_cleanup(delay: float) -> void:
	await get_tree().create_timer(maxf(0.1, delay)).timeout
	if not is_inside_tree() or alive:
		return
	if locomotion_visual == null or visual_holder == null:
		queue_free()
		return
	var fade_materials: Array[BaseMaterial3D] = _prepare_corpse_fade_materials()
	if fade_materials.is_empty():
		await get_tree().create_timer(CORPSE_FADE_DURATION).timeout
		if is_inside_tree():
			queue_free()
		return
	var cleanup := create_tween().set_parallel(true)
	cleanup.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	cleanup.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for material: BaseMaterial3D in fade_materials:
		var transparent_color: Color = material.albedo_color
		transparent_color.a = 0.0
		cleanup.tween_property(material, "albedo_color", transparent_color, CORPSE_FADE_DURATION)
	await cleanup.finished
	if is_inside_tree():
		queue_free()


func _prepare_corpse_fade_materials() -> Array[BaseMaterial3D]:
	var fade_materials: Array[BaseMaterial3D] = []
	if locomotion_visual == null:
		return fade_materials
	for child: Node in locomotion_visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		if mesh_instance.material_override is BaseMaterial3D:
			var override_fade := (mesh_instance.material_override as BaseMaterial3D).duplicate(true) as BaseMaterial3D
			if override_fade != null:
				override_fade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mesh_instance.material_override = override_fade
				fade_materials.append(override_fade)
			continue
		for surface_index: int in range(mesh_instance.mesh.get_surface_count()):
			var source_material: Material = mesh_instance.get_active_material(surface_index)
			if not (source_material is BaseMaterial3D):
				continue
			var surface_fade := (source_material as BaseMaterial3D).duplicate(true) as BaseMaterial3D
			if surface_fade == null:
				continue
			surface_fade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_instance.set_surface_override_material(surface_index, surface_fade)
			fade_materials.append(surface_fade)
	return fade_materials

# =====================================================================
# Navigation grid (shared per room rect)
# =====================================================================

func _configure_chase_route() -> void:
	chase_route_variant = route_variant_override % 5 if route_variant_override >= 0 else rng.randi_range(0, 4)
	match chase_route_variant:
		0:
			chase_lane_sign = -1.0 if rng.randf() < 0.5 else 1.0
			chase_lane_distance = 0.0
		1:
			chase_lane_sign = -1.0
			chase_lane_distance = rng.randf_range(1.05, 1.55)
		2:
			chase_lane_sign = 1.0
			chase_lane_distance = rng.randf_range(1.05, 1.55)
		3:
			chase_lane_sign = -1.0
			chase_lane_distance = rng.randf_range(2.05, 2.85)
		_:
			chase_lane_sign = 1.0
			chase_lane_distance = rng.randf_range(2.05, 2.85)
	chase_lane_timer = rng.randf_range(LANE_LOCK_MIN, LANE_LOCK_MAX)


func _ensure_navigation_grid() -> void:
	var nav_rect := _active_navigation_rect()
	var signature := "%0.2f:%0.2f:%0.2f:%0.2f" % [nav_rect.position.x, nav_rect.position.y, nav_rect.size.x, nav_rect.size.y]
	if shared_nav_signature != signature:
		shared_nav_signature = signature
		shared_nav_ready = false
		shared_nav_grid = null
		shared_nav_origin = nav_rect.position
		shared_nav_width = maxi(3, int(floor(nav_rect.size.x / NAV_CELL)) + 1)
		shared_nav_height = maxi(3, int(floor(nav_rect.size.y / NAV_CELL)) + 1)
	if shared_nav_ready:
		return
	if nav_build_frames_left > 0:
		nav_build_frames_left -= 1
		return

	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, shared_nav_width, shared_nav_height)
	grid.cell_size = Vector2(NAV_CELL, NAV_CELL)
	grid.offset = shared_nav_origin
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()

	var box := BoxShape3D.new()
	# Slightly wider than the body so paths keep clearance from props.
	box.size = Vector3(0.54, 1.30, 0.54)
	var space_state := get_world_3d().direct_space_state
	var probe_y := 0.82
	var floor_y := _resolve_room_walk_floor_y()
	if not is_nan(floor_y):
		probe_y = floor_y + 0.78
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = box
	params.collision_mask = NAV_OBSTACLE_MASK
	params.collide_with_bodies = true
	params.collide_with_areas = false
	for z_index in range(shared_nav_height):
		for x_index in range(shared_nav_width):
			var world_x := shared_nav_origin.x + float(x_index) * NAV_CELL
			var world_z := shared_nav_origin.y + float(z_index) * NAV_CELL
			params.transform = Transform3D(Basis.IDENTITY, Vector3(world_x, probe_y, world_z))
			for hit in space_state.intersect_shape(params, 4):
				var collider := hit.get("collider") as Node
				if collider != null and not _is_walk_floor_collider(collider) and not collider.is_in_group("zombies"):
					grid.set_point_solid(Vector2i(x_index, z_index), true)
					break
	shared_nav_grid = grid
	shared_nav_ready = true
	if not encounter_alerted:
		_choose_random_wander_path()
	else:
		chase_repath_timer = 0.0


func _world_to_nav_cell(world_position: Vector3) -> Vector2i:
	var x_index := int(round((world_position.x - shared_nav_origin.x) / NAV_CELL))
	var z_index := int(round((world_position.z - shared_nav_origin.y) / NAV_CELL))
	return Vector2i(clampi(x_index, 0, shared_nav_width - 1), clampi(z_index, 0, shared_nav_height - 1))


func _nearest_open_cell(start: Vector2i) -> Vector2i:
	if shared_nav_grid == null or not shared_nav_grid.is_point_solid(start):
		return start
	for radius in range(1, 7):
		for z_offset in range(-radius, radius + 1):
			for x_offset in range(-radius, radius + 1):
				if abs(x_offset) != radius and abs(z_offset) != radius:
					continue
				var candidate: Vector2i = start + Vector2i(x_offset, z_offset)
				if candidate.x < 0 or candidate.y < 0 or candidate.x >= shared_nav_width or candidate.y >= shared_nav_height:
					continue
				if not shared_nav_grid.is_point_solid(candidate):
					return candidate
	return start


func _request_chase_path(goal: Vector3, distance_to_player: float) -> void:
	var previous_path: Array[Vector2i] = nav_path.duplicate()
	var previous_index: int = nav_path_index
	nav_path.clear()
	nav_path_index = 0
	nav_goal_world = goal
	if not shared_nav_ready or shared_nav_grid == null or player == null:
		return
	var start: Vector2i = _nearest_open_cell(_world_to_nav_cell(global_position))
	var finish: Vector2i = _nearest_open_cell(_world_to_nav_cell(goal))
	var result: Array[Vector2i] = shared_nav_grid.get_id_path(start, finish, true)

	# Far away, side-lane zombies first travel through a locked side waypoint so
	# the horde arrives on several routes instead of one polyline.
	if distance_to_player > 4.5 and chase_lane_distance > 0.0:
		var to_goal: Vector3 = goal - global_position
		to_goal.y = 0.0
		if to_goal.length_squared() > 0.001:
			var forward: Vector3 = to_goal.normalized()
			var tangent: Vector3 = Vector3(-forward.z, 0.0, forward.x) * chase_lane_sign
			var lane_target: Vector3 = global_position.lerp(goal, 0.45) + tangent * chase_lane_distance
			lane_target.x = clampf(lane_target.x, shared_nav_origin.x + 0.8, shared_nav_origin.x + float(shared_nav_width - 1) * NAV_CELL - 0.8)
			lane_target.z = clampf(lane_target.z, shared_nav_origin.y + 0.8, shared_nav_origin.y + float(shared_nav_height - 1) * NAV_CELL - 0.8)
			var lane_cell: Vector2i = _nearest_open_cell(_world_to_nav_cell(lane_target))
			var first_leg: Array[Vector2i] = shared_nav_grid.get_id_path(start, lane_cell, true)
			var second_leg: Array[Vector2i] = shared_nav_grid.get_id_path(lane_cell, finish, true)
			if first_leg.size() >= 2 and second_leg.size() >= 2:
				var routed: Array[Vector2i] = first_leg.duplicate()
				for route_index in range(1, second_leg.size()):
					routed.append(second_leg[route_index])
				if result.size() < 2 or routed.size() <= int(ceil(float(result.size()) * 1.55)) + 4:
					result = routed
	if result.size() < 2:
		# Goal cell sits in a tiny pocket: probe nearby cells in a stable order.
		var direction_offset: int = int(get_instance_id() % 8)
		var ring_directions: Array[Vector2i] = [
			Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
			Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		]
		for radius in range(1, 5):
			for direction_index in range(ring_directions.size()):
				var candidate: Vector2i = finish + ring_directions[(direction_index + direction_offset) % 8] * radius
				if candidate.x < 0 or candidate.y < 0 or candidate.x >= shared_nav_width or candidate.y >= shared_nav_height:
					continue
				if shared_nav_grid.is_point_solid(candidate):
					continue
				var candidate_path: Array[Vector2i] = shared_nav_grid.get_id_path(start, candidate, true)
				if candidate_path.size() >= 2:
					result = candidate_path
					break
			if result.size() >= 2:
				break
	if result.size() >= 2:
		nav_path = result
		nav_path_index = 1
	elif previous_index < previous_path.size():
		nav_path = previous_path
		nav_path_index = previous_index


func _path_direction() -> Vector3:
	if not shared_nav_ready or shared_nav_grid == null or nav_path.is_empty():
		return Vector3.ZERO
	while nav_path_index < nav_path.size():
		var point_2d := shared_nav_grid.get_point_position(nav_path[nav_path_index])
		var to_waypoint := Vector3(point_2d.x - global_position.x, 0.0, point_2d.y - global_position.z)
		if to_waypoint.length() <= WAYPOINT_REACHED_DISTANCE:
			nav_path_index += 1
			continue
		return to_waypoint.normalized()
	return Vector3.ZERO


func _fallback_obstacle_steer(desired_direction: Vector3) -> Vector3:
	## One short probe before translating catches thin props between grid cells.
	## A chosen side is kept for a while so steering never flickers left/right.
	if desired_direction.length_squared() < 0.0001:
		return Vector3.ZERO
	var desired: Vector3 = desired_direction.normalized()
	var space_state := get_world_3d().direct_space_state
	var ray_start: Vector3 = global_position + Vector3(0.0, 0.80, 0.0)
	var forward_query := PhysicsRayQueryParameters3D.create(ray_start, ray_start + desired * 1.1, NAV_OBSTACLE_MASK)
	forward_query.exclude = [get_rid()]
	if space_state.intersect_ray(forward_query).is_empty():
		if obstacle_steer_timer <= 0.0:
			obstacle_steer_direction = Vector3.ZERO
		return desired if obstacle_steer_timer <= 0.0 else obstacle_steer_direction.lerp(desired, 0.5).normalized()
	if obstacle_steer_timer > 0.0 and obstacle_steer_direction.length_squared() > 0.0001:
		return obstacle_steer_direction
	var tangent: Vector3 = Vector3(-desired.z, 0.0, desired.x) * chase_lane_sign
	var side_direction: Vector3 = (desired * 0.35 + tangent).normalized()
	var side_query := PhysicsRayQueryParameters3D.create(ray_start, ray_start + side_direction * 1.3, NAV_OBSTACLE_MASK)
	side_query.exclude = [get_rid()]
	if space_state.intersect_ray(side_query).is_empty():
		obstacle_steer_direction = side_direction
	else:
		obstacle_steer_direction = (desired * 0.30 - tangent).normalized()
	obstacle_steer_timer = rng.randf_range(0.6, 0.9)
	return obstacle_steer_direction


func _choose_random_wander_path() -> void:
	if not shared_nav_ready or shared_nav_grid == null:
		return
	var start: Vector2i = _nearest_open_cell(_world_to_nav_cell(global_position))
	var start_pos: Vector2 = shared_nav_grid.get_point_position(start)
	var best_path: Array[Vector2i] = []
	for _attempt in range(24):
		var candidate := Vector2i(rng.randi_range(1, shared_nav_width - 2), rng.randi_range(1, shared_nav_height - 2))
		if shared_nav_grid.is_point_solid(candidate):
			continue
		var distance: float = start_pos.distance_to(shared_nav_grid.get_point_position(candidate))
		if distance < 3.2:
			continue
		var candidate_path: Array[Vector2i] = shared_nav_grid.get_id_path(start, candidate, true)
		if candidate_path.size() < 2:
			continue
		best_path = candidate_path
		if distance >= rng.randf_range(5.0, 9.0):
			break
	if best_path.is_empty():
		nav_path.clear()
		nav_path_index = 0
		wander_retarget_timer = rng.randf_range(0.4, 0.8)
		return
	nav_path = best_path
	nav_path_index = 1
	wander_retarget_timer = rng.randf_range(12.0, 20.0)


func _clamp_target_to_combat_room(target: Vector3) -> Vector3:
	var safe_target := target
	if navigation_bounds_override.size != Vector2.ZERO:
		var rect := navigation_bounds_override
		safe_target.x = clampf(safe_target.x, rect.position.x + 0.45, rect.end.x - 0.45)
		safe_target.z = clampf(safe_target.z, rect.position.y + 0.45, rect.end.y - 0.45)
	else:
		safe_target.z = minf(safe_target.z, ROOM1_ZOMBIE_LIMIT - 0.20)
	return safe_target


func _active_navigation_rect() -> Rect2:
	if navigation_bounds_override.size.x > 1.0 and navigation_bounds_override.size.y > 1.0:
		return navigation_bounds_override
	return Rect2(Vector2(NAV_X_MIN, NAV_Z_MIN), Vector2(float(NAV_WIDTH - 1) * NAV_CELL, float(NAV_HEIGHT - 1) * NAV_CELL))


func _flat_to_player() -> Vector3:
	if player == null:
		return Vector3.ZERO
	var result := player.global_position - global_position
	result.y = 0.0
	return result


func _player_is_inside_this_room(edge_buffer: float = 0.0) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if navigation_bounds_override.size.x > 1.0 and navigation_bounds_override.size.y > 1.0:
		var rect := navigation_bounds_override.grow(-edge_buffer)
		if rect.size.x <= 0.5 or rect.size.y <= 0.5:
			rect = navigation_bounds_override
		return rect.has_point(Vector2(player.global_position.x, player.global_position.z))
	return player.global_position.z <= ROOM2_ENTRY_Z


func _room_root() -> Node:
	var scene := get_tree().current_scene
	var current: Node = get_parent()
	while current != null and current != scene:
		if current.get_parent() == scene:
			return current
		current = current.get_parent()
	return get_parent()


func _is_walk_floor_collider(node: Node) -> bool:
	var current := node
	while current != null:
		var node_name := String(current.name).to_lower()
		if node_name.begins_with("tile floor") or node_name == "roomstablefloor" or node_name.begins_with("thresholdfloor"):
			return true
		current = current.get_parent()
	return false


func _keep_on_room_floor() -> void:
	if not stay_on_room_floor or not alive:
		return
	var floor_y := _resolve_room_walk_floor_y()
	if is_nan(floor_y):
		return
	# Only rescue a fall-through or a body stranded on top of something.
	if global_position.y < floor_y - 0.05:
		global_position.y = floor_y + 0.02
		velocity.y = 0.0
	elif global_position.y > floor_y + 0.45 and is_on_floor():
		# Standing on a prop / another body: slide it back down to the tile.
		global_position.y = floor_y + 0.02
		velocity.y = 0.0
	elif global_position.y > floor_y + 1.15:
		global_position.y = floor_y + 0.02
		velocity.y = 0.0


func _resolve_room_walk_floor_y() -> float:
	var parent_room: Node = get_parent()
	while parent_room != null and not parent_room.has_meta("room_walk_floor_y"):
		parent_room = parent_room.get_parent()
	if parent_room != null:
		return float(parent_room.get_meta("room_walk_floor_y"))
	var space := get_world_3d().direct_space_state
	if space == null:
		return NAN
	var origin := global_position + Vector3(0.0, 0.9, 0.0)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3(0.0, -3.2, 0.0), 1)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty() or not _is_walk_floor_collider(hit.get("collider") as Node):
		return NAN
	return float(hit.get("position", Vector3.ZERO).y)

# =====================================================================
# Animation layer: one AnimationPlayer, loops + one-shots, real crossfades
# =====================================================================

func _clip(keyword: StringName) -> StringName:
	## Exact (underscores == spaces) match first, then contains. Cached.
	if anim == null:
		return StringName()
	if anim_name_cache.has(keyword):
		return anim_name_cache[keyword]
	var key: String = String(keyword).to_lower().replace("_", " ")
	var found := StringName()
	for animation_name in anim.get_animation_list():
		var text := String(animation_name)
		if text == "RESET":
			continue
		if text.to_lower().replace("_", " ") == key:
			found = StringName(animation_name)
			break
	if found == StringName():
		for animation_name in anim.get_animation_list():
			var text := String(animation_name)
			if text != "RESET" and text.to_lower().replace("_", " ").contains(key):
				found = StringName(animation_name)
				break
	anim_name_cache[keyword] = found
	return found


func _play_one_shot(keyword: StringName, blend: float, speed: float, busy_state: int, return_state: int) -> bool:
	## Alert, hit, stagger, miss recovery. Duration is the real clip length.
	var chosen: StringName = _clip(keyword)
	if anim == null or chosen == StringName():
		return false
	var animation: Animation = anim.get_animation(chosen)
	if animation == null:
		return false
	anim.speed_scale = 1.0
	if anim.current_animation == String(chosen):
		anim.stop(true)
	anim.play(chosen, blend, speed)
	loop_clip = StringName()
	one_shot_active = true
	one_shot_timer = animation.length / maxf(speed, 0.05)
	reaction_return_state = return_state
	state = busy_state
	return true


func _finish_one_shot() -> void:
	one_shot_active = false
	state = reaction_return_state
	if state == ZombieState.CHASE:
		chase_repath_timer = 0.0
		slot_point_timer = 0.0
	resume_ramp = 0.3
	_start_loop_for_current_motion(ONE_SHOT_BLEND_OUT)


func _start_loop_for_current_motion(blend: float) -> void:
	# Leave a one-shot into idle unless already moving; the walk is picked up by
	# _update_locomotion_animation once the body actually accelerates.
	visually_moving = false
	_play_loop(_idle_clip_for_state(), blend, _idle_speed())


func _play_loop(keyword: StringName, blend: float, speed: float) -> void:
	var chosen: StringName = _clip(keyword)
	if anim == null or chosen == StringName():
		return
	if loop_clip == chosen and anim.current_animation == String(chosen) and anim.is_playing():
		return
	loop_clip = chosen
	loop_speed = speed
	anim.speed_scale = speed
	anim.play(chosen, blend, 1.0)


func _idle_clip_for_state() -> StringName:
	if encounter_alerted:
		return &"idle_restless"
	return idle_animation_name


func _idle_speed() -> float:
	if locomotion_mode == ZombieVisualMode.LOOK_AROUND:
		return LOOK_AROUND_LOOP_SPEED
	return rng.randf_range(0.92, 1.06)


func _update_locomotion_animation(delta: float, force: bool = false) -> void:
	if not alive or anim == null:
		return
	if one_shot_active and not force:
		return
	if state != ZombieState.WANDER and state != ZombieState.CHASE and not force:
		return
	var speed: float = Vector2(velocity.x, velocity.z).length()
	# Hysteresis so a body easing to a stop does not flicker walk/idle.
	if visually_moving:
		visually_moving = speed > 0.16
	else:
		visually_moving = speed > 0.34
	if visually_moving:
		was_walking = true
		var walk: StringName = WALK_CLIPS[movement_style_index]
		var target_rate: float = clampf(speed / WALK_NATURAL_SPEEDS[movement_style_index], WALK_ANIM_MIN, WALK_ANIM_MAX)
		if loop_clip != _clip(walk):
			_play_loop(walk, LOCOMOTION_BLEND, target_rate)
		# Cycle rate follows real ground speed so feet stay planted.
		loop_speed = lerpf(loop_speed, target_rate, clampf(delta * 6.0, 0.0, 1.0)) if delta > 0.0 else target_rate
		anim.speed_scale = loop_speed
		return
	# Stopped.
	if state == ZombieState.WANDER and was_walking and locomotion_mode != ZombieVisualMode.LOOK_AROUND:
		was_walking = false
		if _play_one_shot(&"walk_to_idle", 0.2, 1.0, ZombieState.WANDER, ZombieState.WANDER):
			return
	was_walking = false
	if not encounter_alerted and idle_change_timer <= 0.0:
		var next_idle: StringName = IDLE_CLIPS[rng.randi_range(0, IDLE_CLIPS.size() - 1)]
		if next_idle == idle_animation_name:
			next_idle = IDLE_CLIPS[(IDLE_CLIPS.find(next_idle) + 1) % IDLE_CLIPS.size()]
		idle_animation_name = next_idle
		idle_change_timer = rng.randf_range(5.0, 9.0)
	var idle: StringName = _idle_clip_for_state()
	if loop_clip != _clip(idle) or force:
		_play_loop(idle, 0.32 if not force else 0.0, _idle_speed())


func _cache_bones() -> void:
	head_bone_index = -1
	right_hand_index = -1
	left_hand_index = -1
	if visual_skeleton == null:
		return
	head_bone_index = _find_bone(&"mixamorig:Head", ["head"])
	right_hand_index = _find_bone(RIGHT_HAND_BONE, ["righthand", "r_hand"])
	left_hand_index = _find_bone(LEFT_HAND_BONE, ["lefthand", "l_hand"])


func _find_bone(exact: StringName, suffixes: Array) -> int:
	var index: int = visual_skeleton.find_bone(exact)
	if index >= 0:
		return index
	for bone_index: int in range(visual_skeleton.get_bone_count()):
		var bone_name: String = String(visual_skeleton.get_bone_name(bone_index)).to_lower()
		for suffix in suffixes:
			if bone_name == String(suffix) or bone_name.ends_with(":" + String(suffix)) or bone_name.ends_with(String(suffix)):
				return bone_index
	return -1


func _update_head_hitbox_from_animation() -> void:
	if head_hitbox == null or visual_skeleton == null or head_bone_index < 0:
		return
	var bone_pose: Transform3D = visual_skeleton.get_bone_global_pose(head_bone_index)
	head_hitbox.global_position = visual_skeleton.global_transform * bone_pose.origin + Vector3(0.0, 0.08, 0.0)


func _get_combined_scene() -> PackedScene:
	if combined_scene_cache == null:
		var resource: Resource = load(COMBINED_ZOMBIE_PATH)
		if resource is PackedScene:
			combined_scene_cache = resource as PackedScene
		else:
			push_error("Zombie GLB failed to load: " + COMBINED_ZOMBIE_PATH)
	return combined_scene_cache


func _align_visual_to_floor_if_valid(visual_root: Node3D) -> void:
	if visual_root != null and is_instance_valid(visual_root) and visual_root.is_inside_tree():
		_align_visual_to_floor(visual_root)


func _align_visual_to_floor(visual_root: Node3D) -> void:
	if visual_root == null or visual_holder == null:
		return
	var lowest_y: float = INF
	var holder_inverse := visual_holder.global_transform.affine_inverse()
	for child in visual_root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var mesh_to_holder: Transform3D = holder_inverse * mesh_instance.global_transform
		var mesh_bounds: AABB = mesh_instance.get_aabb()
		for corner_index in range(8):
			lowest_y = minf(lowest_y, (mesh_to_holder * mesh_bounds.get_endpoint(corner_index)).y)
	if lowest_y < INF:
		visual_root.position.y += VISUAL_FLOOR_CLEARANCE / MODEL_SCALE - lowest_y


func _disable_visual_shadows(root: Node) -> void:
	if root is GeometryInstance3D:
		var geometry := root as GeometryInstance3D
		geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Own visual layer so floor/wall decals never project onto zombies.
		geometry.layers = ZOMBIE_RENDER_LAYER
	for child in root.get_children():
		_disable_visual_shadows(child)


func _ensure_zombie_decal_isolation() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	# Streamed rooms add new decals later, so run once per room root too.
	var room := _room_root()
	var marker_owner: Node = room if room != null else scene
	if bool(marker_owner.get_meta("zombie_decal_isolation_ready", false)):
		return
	marker_owner.set_meta("zombie_decal_isolation_ready", true)
	_exclude_zombie_layer_from_decals(marker_owner)


func _exclude_zombie_layer_from_decals(root: Node) -> void:
	if root is Decal:
		var decal := root as Decal
		decal.cull_mask = decal.cull_mask & ~ZOMBIE_RENDER_LAYER
	for child in root.get_children():
		_exclude_zombie_layer_from_decals(child)


func _find_skeleton(node: Node) -> Skeleton3D:
	if node == null:
		return null
	if node is Skeleton3D:
		return node as Skeleton3D
	for child: Node in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


# =====================================================================
# Audio
# =====================================================================

func _update_walk_sound(should_play: bool) -> void:
	if walk_audio == null or not should_play or zombie_movement_streams.is_empty():
		return
	if zombie_step_timer > 0.0 or walk_audio.playing:
		return
	var movement_index := 1 if locomotion_mode == ZombieVisualMode.LIMP else rng.randi_range(0, zombie_movement_streams.size() - 1)
	movement_index = clampi(movement_index, 0, zombie_movement_streams.size() - 1)
	walk_audio.stream = zombie_movement_streams[movement_index]
	walk_audio.volume_db = rng.randf_range(-23.0, -19.0)
	walk_audio.pitch_scale = rng.randf_range(0.91, 1.04)
	walk_audio.play()
	zombie_step_timer = rng.randf_range(0.72, 1.10) / maxf(individual_speed_multiplier, 0.75)


func _update_growl() -> void:
	if not alive or growl_timer > 0.0:
		return
	var now_msec := Time.get_ticks_msec()
	if now_msec < global_voice_lock_until_msec:
		growl_timer = rng.randf_range(2.5, 6.0)
		return
	if rng.randf() <= 0.30 and voice_audio != null and not voice_audio.playing:
		_play_random_voice(chase_vocal_streams, rng.randf_range(-21.0, -17.0), 0.94, 1.04)
		global_voice_lock_until_msec = now_msec + rng.randi_range(5000, 8500)
	growl_timer = rng.randf_range(MIN_GROWL_INTERVAL, MAX_GROWL_INTERVAL)


func _play_voice_sound(stream: AudioStream, volume: float, pitch_value: float) -> void:
	if voice_audio == null or stream == null:
		return
	voice_audio.stop()
	voice_audio.stream = stream
	voice_audio.volume_db = volume
	voice_audio.pitch_scale = pitch_value
	voice_audio.play()


func _play_random_event(streams: Array[AudioStream], volume: float, pitch_min: float, pitch_max: float, start_offsets: Array[float] = []) -> void:
	if streams.is_empty() or event_audio_pool.is_empty():
		return
	var stream_index := rng.randi_range(0, streams.size() - 1)
	if streams.size() > 1 and stream_index == last_event_stream_index:
		stream_index = (stream_index + rng.randi_range(1, streams.size() - 1)) % streams.size()
	last_event_stream_index = stream_index
	var event_player: AudioStreamPlayer3D = event_audio_pool[event_audio_voice_index % event_audio_pool.size()]
	event_audio_voice_index = (event_audio_voice_index + 1) % event_audio_pool.size()
	event_player.stop()
	event_player.stream = streams[stream_index]
	event_player.volume_db = volume
	event_player.pitch_scale = rng.randf_range(pitch_min, pitch_max)
	event_player.play(start_offsets[stream_index] if stream_index < start_offsets.size() else 0.0)


func _play_random_voice(streams: Array[AudioStream], volume: float, pitch_min: float, pitch_max: float) -> void:
	if streams.is_empty():
		return
	_play_voice_sound(streams[rng.randi_range(0, streams.size() - 1)], volume, rng.randf_range(pitch_min, pitch_max))


func _play_random_attack_sound(streams: Array[AudioStream], volume: float, pitch_min: float, pitch_max: float, start_offsets: Array[float] = []) -> void:
	if attack_audio == null or streams.is_empty():
		return
	var stream_index := rng.randi_range(0, streams.size() - 1)
	if streams.size() > 1 and stream_index == last_attack_stream_index:
		stream_index = (stream_index + rng.randi_range(1, streams.size() - 1)) % streams.size()
	last_attack_stream_index = stream_index
	attack_audio.stop()
	attack_audio.stream = streams[stream_index]
	attack_audio.volume_db = volume
	attack_audio.pitch_scale = rng.randf_range(pitch_min, pitch_max)
	attack_audio.play(start_offsets[stream_index] if stream_index < start_offsets.size() else 0.0)
