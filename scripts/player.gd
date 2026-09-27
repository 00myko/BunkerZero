extends CharacterBody3D

@export var walk_speed: float = 3.4
@export var sprint_speed: float = 5.2
@export var acceleration: float = 9.5
@export var deceleration: float = 14.0
@export var mouse_sensitivity: float = 0.0024
@export var touch_look_sensitivity: float = 0.0032
@export_range(0.25, 1.50, 0.05) var shoot_drag_look_multiplier: float = 0.85
@export var jump_velocity: float = 4.35
@export var jump_up_gravity_multiplier: float = 1.35
@export var jump_fall_gravity_multiplier: float = 1.78
@export var obstacle_jump_velocity: float = 4.45
@export var large_obstacle_jump_velocity: float = 4.65
@export var air_control: float = 0.42
@export var gravity: float = 9.8

@export_category("Health Regeneration")
@export var health_regen_delay: float = 9.0
@export var health_regen_per_second: float = 0.60

@export_category("Low Health Feedback")
@export_range(0.10, 0.50, 0.01) var low_health_threshold: float = 0.32
@export var low_health_camera_drop: float = 0.006
@export var low_health_camera_push: float = 0.004
@export var low_health_camera_pitch_degrees: float = 0.34
@export var low_health_camera_roll_degrees: float = 0.12
@export_range(0.0, 0.25, 0.01) var low_health_red_base_alpha: float = 0.018
@export_range(0.0, 0.30, 0.01) var low_health_red_pulse_alpha: float = 0.12
## Below this health ratio the beat gets physically stronger on top of the
## normal low-health ramp.
@export_range(0.05, 0.30, 0.01) var low_health_critical_threshold: float = 0.15
@export var low_health_critical_boost: float = 0.85
@export var low_health_fov_breathe: float = 0.95
@export var low_health_hand_drop: float = 0.0042
@export var low_health_hand_pitch_degrees: float = 1.5
@export var low_health_hand_roll_degrees: float = 1.1

@export_category("Sprint & Stamina")
@export var stamina_max: float = 100.0
@export var sprint_duration_seconds: float = 7.0
@export var stamina_regen_delay: float = 1.25
@export var stamina_full_recharge_seconds: float = 5.0
@export var stamina_exhausted_restart_percent: float = 0.25

@export_category("Walk Camera & Weapon")
@export var walk_camera_vertical_drop: float = 0.031
@export var walk_camera_lateral_shift: float = 0.015
@export var walk_camera_forward_shift: float = 0.011
@export var walk_camera_roll_degrees: float = 0.68
@export var walk_camera_pitch_degrees: float = 0.46
@export var walk_weapon_motion_multiplier: float = 1.0

@export_category("Sprint Camera")
@export var sprint_camera_enabled: bool = true
@export var sprint_forward_offset: float = 0.034
@export var sprint_acceleration_lean: float = 0.52
@export var sprint_deceleration_lean: float = 0.42
@export var sprint_acceleration_pos_lag: float = 0.020
@export var sprint_deceleration_pos_lag: float = 0.026
@export var sprint_side_inertia: float = 0.012
@export var sprint_roll_strength: float = 0.32
@export var sprint_bob_vertical: float = 0.018
@export var sprint_bob_horizontal: float = 0.010
@export var sprint_bob_frequency: float = 1.0
@export var sprint_step_impact: float = 0.005
@export var sprint_fov_increase: float = 4.5
## Sustained forward/down lean of the view while at sprint speed (degrees).
@export var sprint_lean_degrees: float = 0.75
## Body drops a little into the run posture (metres).
@export var sprint_camera_drop: float = 0.012
## Weapon tuck while sprinting: muzzle down, turned in, canted (degrees).
@export var sprint_weapon_tuck_degrees: Vector3 = Vector3(-2.6, 1.6, 3.8)
## Hands dip into the run on sprint start instead of snapping to the carry.
@export var sprint_entry_weapon_dip: float = 0.30
## Multiplier on the per-footstep hand thud while sprinting.
@export var sprint_weapon_step_thud: float = 1.0
@export var sprint_fov_response: float = 8.5
@export var sprint_spring_strength: float = 120.0
@export var sprint_spring_damping: float = 22.0
@export var sprint_acceleration_smoothing: float = 11.0
@export var sprint_blend_speed: float = 5.5
@export var sprint_weapon_lag: float = 0.028
@export var sprint_viewmodel_center_offset: float = -0.034
@export var sprint_viewmodel_vertical_offset: float = -0.014
@export var sprint_viewmodel_depth_offset: float = -0.034
@export var max_sprint_pitch: float = 1.4
@export var max_sprint_roll: float = 0.65
@export var max_sprint_position_offset: float = 0.055

@export_category("Lateral Camera Inertia")
@export var lateral_inertia_enabled: bool = true
@export var lateral_position_strength: float = 0.018
@export var lateral_roll_strength: float = 0.34
@export var lateral_yaw_strength: float = 0.14
@export var lateral_acceleration_reference: float = 15.0
@export var lateral_acceleration_deadzone: float = 1.10
@export var lateral_acceleration_smoothing: float = 15.0
@export var lateral_spring_strength: float = 150.0
@export var lateral_spring_damping: float = 24.0
@export var lateral_max_position: float = 0.032
@export var lateral_max_roll: float = 0.70
@export var lateral_max_yaw: float = 0.32
@export var lateral_sprint_multiplier: float = 1.0
@export var lateral_walk_multiplier: float = 0.72
@export var lateral_airborne_multiplier: float = 0.34
@export var weapon_lateral_inertia_strength: float = 1.55
@export var weapon_lateral_max_position: float = 0.040
@export var weapon_lateral_max_roll: float = 1.25
@export var weapon_lateral_max_yaw: float = 0.75
@export var obstacle_check_distance: float = 1.05
@export var large_obstacle_check_distance: float = 1.38
@export var large_obstacle_clearance_height: float = 2.10
@export var obstacle_low_ray_height: float = 0.42
@export var obstacle_clearance_height: float = 1.15

# Procedural FPS jump camera tuning. These affect camera/viewmodel feel only,
# except the physical jump/gravity/air-control values above.
@export var jump_takeoff_dip: float = 0.034
@export var jump_takeoff_duration: float = 0.070
@export var airborne_camera_lag: float = 0.028
@export_category("Landing Camera")
@export var landing_camera_enabled: bool = true
@export var landing_min_speed: float = 2.0
@export var landing_camera_drop: float = 0.072
## Normal landing: view nods down and the FOV compresses on impact.
@export var landing_pitch_degrees: float = 1.05
@export var landing_fov_compression: float = 1.4
@export var landing_weapon_drop: float = 0.040
@export var landing_recovery_speed: float = 0.30
@export var landing_spring_strength: float = 145.0
@export var landing_spring_damping: float = 24.0

# Hard landing is intentionally gated for Bunker Zero:
# by default it is used when the player DOUBLE-JUMPS while clearing an obstacle.
# A normal double-jump in open space does NOT use the hard-landing profile.
@export var hard_landing_from_obstacle_double_jump: bool = true
@export var hard_landing_from_falls_enabled: bool = true
@export var hard_landing_fall_trigger_speed: float = 7.2
@export var hard_landing_min_speed: float = 3.2
@export var hard_landing_max_reference_speed: float = 6.2
@export var hard_landing_strength_curve_power: float = 1.15
@export var hard_landing_min_obstacle_strength: float = 0.58
@export var hard_landing_camera_drop: float = 0.095
@export var hard_landing_max_camera_drop: float = 0.13
@export var hard_landing_rebound: float = 0.011
@export var hard_landing_pitch_strength: float = 2.3
@export var hard_landing_max_pitch: float = 3.2
@export var hard_landing_roll_strength: float = 0.75
@export var hard_landing_fov_compression: float = 3.0
@export var hard_landing_spring_strength: float = 175.0
@export var hard_landing_spring_damping: float = 25.5
@export var hard_landing_recovery_time: float = 0.46

@export_category("Landing Weapon")
@export var hard_landing_weapon_drop: float = 0.100
@export var hard_landing_weapon_pitch: float = 5.5
@export var hard_landing_weapon_rebound: float = 0.012
@export var hard_landing_weapon_spring_strength: float = 118.0
@export var hard_landing_weapon_spring_damping: float = 17.5

@export_category("Landing Feedback")
@export var hard_landing_grunt_threshold: float = 0.62
@export_range(0.0, 1.0, 0.01) var hard_landing_grunt_chance: float = 0.72
@export var hard_landing_grunt_cooldown: float = 0.75
@export var hard_landing_haptic_threshold: float = 0.45
@export var jump_spring_strength: float = 105.0
@export var jump_spring_damping: float = 20.0
@export var jump_fov_amount: float = 1.0
## Takeoff: a short FOV kick and the hands lifting with the push-off.
@export var jump_takeoff_fov_kick: float = 1.4
@export var jump_takeoff_weapon_lift: float = 0.22
@export var jump_fov_speed: float = 8.5
@export var maximum_jump_camera_pitch: float = 0.9
@export var viewmodel_jump_lag: float = 0.035

# Guard-rail / large-obstacle camera feel.
# These are VISUAL ONLY and do not change physical jump height.
@export var large_jump_takeoff_dip: float = 0.032
@export var large_jump_ascent_lag: float = 0.028
@export var large_jump_descent_lag: float = 0.022
@export var large_jump_forward_offset: float = 0.012
@export var large_jump_forward_pitch_degrees: float = 0.48
@export var large_jump_landing_drop: float = 0.072
@export var large_jump_landing_rebound: float = 0.010
@export var large_jump_camera_spring_strength: float = 132.0
@export var large_jump_camera_spring_damping: float = 24.0
@export var large_jump_viewmodel_drop: float = 0.030
@export_range(0.0, 1.0, 0.01) var normal_jump_voice_chance: float = 0.26
@export_range(0.0, 1.0, 0.01) var small_obstacle_voice_chance: float = 0.48
@export_range(0.0, 1.0, 0.01) var large_obstacle_voice_chance: float = 0.66
@export var double_tap_jump_window: float = 0.34
@export var double_jump_vertical_speed: float = 4.10
@export var show_mobile_hud_in_editor: bool = true

@export_category("Damage Camera")
@export var damage_camera_enabled: bool = true

# Projectile / gun damage: quick and restrained.
@export var projectile_position_strength: float = 0.012
@export var projectile_pitch_strength: float = 0.42
@export var projectile_yaw_strength: float = 0.28
@export var projectile_roll_strength: float = 0.30
@export var projectile_weapon_kick: float = 0.62
@export var projectile_fov_kick: float = 0.18

# Zombie melee: deliberately stronger and more physical.
# The head is knocked AWAY from the attacker: yaw and roll turn off the hit,
# a hit from the front snaps the view up, one from behind throws it forward.
@export var melee_pitch_strength: float = 2.2
@export var melee_yaw_strength: float = 2.6
@export var melee_roll_strength: float = 2.7
@export var melee_position_strength: float = 0.060
@export var melee_weapon_kick_strength: float = 2.1
@export var melee_fov_kick: float = 2.2
# Light claw = fast whip (more yaw/roll snap, quick recovery). Heavy hit =
# slower, deeper shove with more drop and FOV. Heavy is a zombie_heavy hit or
# any melee at/above this damage.
@export var melee_heavy_damage_threshold: float = 15.0
@export var melee_heavy_spring_strength: float = 88.0
@export var melee_heavy_spring_damping: float = 15.5
@export var melee_light_spring_strength: float = 165.0
@export var melee_light_spring_damping: float = 23.0

# Shared spring / accumulation controls.
@export var melee_spring_strength: float = 128.0
@export var melee_spring_damping: float = 22.0
@export var projectile_spring_strength: float = 165.0
@export var projectile_spring_damping: float = 26.0
@export var melee_rotation_velocity_multiplier: float = 32.0
@export var melee_position_velocity_multiplier: float = 27.0
@export var melee_max_pitch: float = 4.2
@export var melee_max_yaw: float = 4.8
@export var melee_max_roll: float = 4.8
@export var melee_max_position_offset: float = 0.105
@export var melee_damage_reference: float = 10.0
@export_range(0.0, 0.25, 0.01) var melee_randomness: float = 0.10
@export var melee_fov_recovery: float = 14.0
@export_range(0.4, 1.0, 0.01) var melee_multi_hit_reduction: float = 0.84

# Tiny contact vibration layered on top of the directional shove.
@export var damage_micro_jolt_position: float = 0.002
@export var damage_micro_jolt_rotation: float = 0.10
@export var melee_immediate_position_fraction: float = 0.48
@export var melee_immediate_rotation_fraction: float = 0.42
@export var melee_weapon_immediate_position_fraction: float = 0.32
@export var melee_weapon_immediate_rotation_fraction: float = 0.30
@export var projectile_immediate_position_fraction: float = 0.18
@export var projectile_immediate_rotation_fraction: float = 0.14

# Haptic timing/strength. Gameplay damage is never altered by these settings.
@export var projectile_haptic_duration_ms: int = 16
@export var projectile_haptic_strength: float = 0.30
@export var melee_haptic_duration_ms: int = 34
@export var melee_haptic_strength: float = 0.68

@export_category("Pistol Firing")
# Press-and-hold remains available for mobile accessibility, but each shot must
# finish its slide/recoil recovery before another trigger cycle can begin.
@export_range(0.18, 0.60, 0.01) var pistol_shot_interval: float = 0.26
@export var pistol_hand_recoil_strength: float = 0.86
@export var pistol_camera_recoil_degrees: float = 1.05
## The authored pistol "sprint" clip holds the gun at the face, off-frame.
## Off = sprint with the idle clip plus the procedural run carry.
@export var use_pistol_sprint_clip: bool = false

# Recoil is a directed impulse into damped springs whose rest point is the
# shot's aim point: the camera always settles back onto what the crosshair
# was on, never onto a new random angle. Camera kick lives on Camera3D
# (pitch / yaw / roll / push-back + FOV); hand kick lives on the viewmodel root.
@export_category("Recoil Feel")
# PISTOL — snappy, expert. Same-frame muzzle climb, hands punch harder than
# the view, near-critical spring that is home before the next trigger pull.
@export var pistol_camera_yaw_degrees: float = 0.22
@export var pistol_camera_roll_degrees: float = 0.38
@export var pistol_camera_fov_punch: float = 0.55
@export var pistol_camera_spring: float = 560.0
@export var pistol_camera_damping: float = 44.0
@export var pistol_hand_kick_up: float = 0.0085
@export var pistol_hand_kick_back: float = 0.026
@export var pistol_hand_kick_pitch_degrees: float = 5.5
@export var pistol_hand_kick_roll_degrees: float = 1.6
@export var pistol_hand_spring: float = 330.0
@export var pistol_hand_damping: float = 31.0
# UZI — planted sights, body buzz. Small per-round chatter with an alternating
# roll, a capped burst climb that settles once the trigger is released, and
# micro hand kick only so the Ready_To_Fire sights never leave the hit point.
@export var uzi_camera_kick_degrees: float = 0.30
@export var uzi_camera_yaw_degrees: float = 0.10
@export var uzi_camera_roll_degrees: float = 0.34
@export var uzi_camera_fov_punch: float = 0.14
@export var uzi_camera_spring: float = 900.0
@export var uzi_camera_damping: float = 46.0
@export var uzi_burst_climb_degrees: float = 0.10
@export var uzi_burst_climb_max_degrees: float = 0.80
@export var uzi_burst_climb_spring: float = 60.0
@export var uzi_burst_climb_damping: float = 15.5
@export var uzi_hand_kick_up: float = 0.0010
@export var uzi_hand_kick_back: float = 0.0050
@export var uzi_hand_kick_pitch_degrees: float = 0.9
@export var uzi_hand_kick_roll_degrees: float = 0.7
@export var uzi_hand_spring: float = 1100.0
@export var uzi_hand_damping: float = 52.0
# SHOTGUN — violent, one-shot body. Big climb + push-back + roll, a slower
# heavier settle you feel through the pump, and a 12-gauge hand shove.
@export var shotgun_camera_kick_degrees: float = 3.1
@export var shotgun_camera_yaw_degrees: float = 0.55
@export var shotgun_camera_roll_degrees: float = 1.25
@export var shotgun_camera_push_back: float = 0.045
@export var shotgun_camera_fov_punch: float = 2.4
@export var shotgun_camera_spring: float = 150.0
@export var shotgun_camera_damping: float = 19.5
@export var shotgun_hand_kick_up: float = 0.012
@export var shotgun_hand_kick_back: float = 0.040
@export var shotgun_hand_kick_pitch_degrees: float = 11.0
@export var shotgun_hand_kick_roll_degrees: float = 3.2
@export var shotgun_hand_spring: float = 150.0
@export var shotgun_hand_damping: float = 17.0
@export var shotgun_pump_camera_dip_degrees: float = 0.55
@export var shotgun_pump_hand_pull: float = 0.010
# Look sway: an under-damped spring so the gun lags the look, then catches up.
@export var look_sway_spring: float = 210.0
@export var look_sway_damping: float = 19.0

@export_category("Pistol ADS")
## Local model-space values. They use the same authored units as the approved
## hip transform and are uniformly depth-compressed with the viewmodel.
## Solved so the front post and rear notch tops sit level on the exact
## screen-centre pixel (sight line along the view axis, no cant).
@export var ads_position: Vector3 = Vector3(0.0, -0.9164, -0.8038)
@export var ads_rotation_degrees: Vector3 = Vector3(0.0, 180.0, 0.0)
@export_range(0.75, 1.0, 0.01) var ads_scale_multiplier: float = 0.94
@export_range(0.05, 0.30, 0.01) var ads_enter_time: float = 0.13
@export_range(0.08, 0.35, 0.01) var ads_exit_time: float = 0.19
@export_range(0.0, 0.20, 0.01) var ads_fire_delay: float = 0.09
@export_range(0.08, 0.35, 0.01) var ads_post_shot_hold: float = 0.18
@export_range(50.0, 72.0, 0.5) var ads_fov: float = 67.0
@export_range(60.0, 90.0, 0.5) var hip_fov: float = 72.0
@export_range(0.0, 1.0, 0.05) var ads_sway_multiplier: float = 0.18
@export_range(0.0, 1.0, 0.05) var ads_bob_multiplier: float = 0.24
@export_range(0.0, 1.0, 0.05) var ads_recoil_multiplier: float = 0.62

const PISTOL_VIEWMODEL_SCENE: PackedScene = preload("res://assets/Weapons/animated_pistol_complete.glb")
const UZI_VIEWMODEL_SCENE: PackedScene = preload("res://assets/Weapons/Uzi  14 Animations.glb")
const SHOTGUN_VIEWMODEL_SCENE: PackedScene = preload("res://assets/Weapons/shotgun_animated.glb")
const WEAPON_CHOICE_OVERLAY_SCRIPT = preload("res://scripts/ui/weapon_choice_overlay.gd")
const VIEWMODEL_TUNE_PANEL_SCRIPT = preload("res://scripts/ui/viewmodel_tune_panel.gd")
const PISTOL_IDLE_ANIMATION: StringName = &"idle"
const PISTOL_FIRE_ANIMATION: StringName = &"fire"
const PISTOL_RELOAD_ANIMATION: StringName = &"reload"
const PISTOL_READY_ANIMATION: StringName = &"ready_to_fire"
const PISTOL_SPRINT_ANIMATION: StringName = &"sprint"
const PISTOL_FIRE_SPEED := 1.22
const PISTOL_RELOAD_SPEED := 1.05
const PISTOL_MAG_CAPACITY := 8
const PISTOL_STARTING_TOTAL_AMMO := 120
const UZI_MAG_CAPACITY := 24
const UZI_STARTING_TOTAL_AMMO := 192
const UZI_SHOT_INTERVAL := 0.065
const SHOTGUN_MAG_CAPACITY := 6
const SHOTGUN_STARTING_TOTAL_AMMO := 42
const SHOTGUN_SHOT_INTERVAL := 1.12
const SHOTGUN_ANIM := &"allanims"
const SHOTGUN_FIRE_START := 0.00
const SHOTGUN_FIRE_END := 0.46
const SHOTGUN_PUMP_START := 0.50
const SHOTGUN_PUMP_END := 1.08
const SHOTGUN_RELOAD_START := 1.16
const SHOTGUN_RELOAD_END := 2.86
const SHOTGUN_RELOAD_INSERT_TIME := 0.58
const SHOTGUN_PELLETS := 8
const SHOTGUN_SPREAD_HIP := 0.048
const SHOTGUN_SPREAD_ADS := 0.018
# Hip poses (all weapons): classic lower-right carry, weapon fully in frame,
# rear sight about 230 px right / 130 px below centre at 720p and the barrel
# aimed at a point ~8 m down the crosshair. Ready poses: the sight line was
# solved to run through the exact screen-centre pixel the hitscan uses.
const SHOTGUN_MODEL_OFFSET := Vector3(0.1264, -0.1833, -0.1067)
const SHOTGUN_DEFAULT_SCALE := 0.006
const SHOTGUN_DEFAULT_ROTATION := Vector3(-0.57, 180.96, 4.03)
# Front blade tip centred in the ghost ring, both on the crosshair.
const SHOTGUN_READY_OFFSET := Vector3(0.0, -0.1086, -0.0823)
const SHOTGUN_READY_ROTATION := Vector3(0.0, 180.0, 0.0)
const SHOTGUN_ADS_ENTER_TIME := 0.16
const SHOTGUN_ADS_EXIT_TIME := 0.18
const UZI_MODEL_OFFSET := Vector3(0.060, -1.505, -0.020)
const UZI_DEFAULT_SCALE := 1.0
const UZI_DEFAULT_ROTATION := Vector3(0.0, 186.0, 2.0)
# Ready-to-fire: the front post tip sits on the exact screen-centre pixel the
# hitscan uses (measured from the render), ring around it, no cant.
const UZI_READY_OFFSET := Vector3(-0.0143, -1.4822, 0.1957)
const UZI_READY_ROTATION := Vector3(0.894, 178.213, 0.074)
const UZI_READY_SCALE := 1.0
const UZI_ADS_ENTER_TIME := 0.40
const UZI_ADS_EXIT_TIME := 0.24
const UZI_READY_BLEND := 0.12
const UZI_ANIM_IDLE := &"Idle"
const UZI_ANIM_IDLE_2 := &"Idle_2"
const UZI_ANIM_WALK := &"Walk"
const UZI_ANIM_RUN := &"Run"
const UZI_ANIM_FIRE := &"Fire"
const UZI_ANIM_RELOAD := &"Reload"
const UZI_ANIM_RELOAD_EMPTY := &"Reload_Empty"
const UZI_ANIM_AIM_IN := &"Aim_In"
const UZI_ANIM_AIM_OUT := &"Aim_Out"
const UZI_ANIM_READY := &"Ready_To_Fire"
const UZI_ANIM_EQUIP := &"Equip"
const UZI_ANIM_UNEQUIP := &"Unequip"
const UZI_ANIM_INSPECT := &"Inspect"
const UZI_ANIM_FIREMODE := &"Firemode"
const UZI_ANIM_REF_POSE := &"Ref_Pose"
const UZI_HAND_TEXTURE_PATH: String = "res://assets/Weapons/Uzi_Hands_Tactical.png"
const PISTOL_HD_ALBEDO_PATH: String = "res://assets/Weapons/HD_Viewmodel/Pistol_HD_Albedo.png"
const HAND_HD_ALBEDO_PATH: String = "res://assets/Weapons/HD_Viewmodel/Hand_HD_Albedo.png"
const ARM_HD_ALBEDO_PATH: String = "res://assets/Weapons/HD_Viewmodel/Arm_HD_Albedo.png"
const PISTOL_SHOT_SFX: AudioStream = preload("res://assets/Audio/Pistol Shot.wav")
const PISTOL_RELOAD_SFX: AudioStream = preload("res://assets/Audio/Pistol Reload.wav")
const PISTOL_LOW_IMPACT_PATH: String = "res://assets/Audio/Pistol Layers/Pistol Low Impact.mp3"
const PISTOL_SLIDE_ACTION_PATH: String = "res://assets/Audio/Pistol Layers/Pistol Slide Action.mp3"
const PISTOL_BUNKER_REFLECTION_PATH: String = "res://assets/Audio/Pistol Layers/Pistol Bunker Reflection.mp3"
const PISTOL_SHELL_CASING_PATH: String = "res://assets/Audio/Pistol Layers/Pistol Shell Casing.mp3"
const UZI_SHOT_PATH: String = "res://assets/Audio/Uzi/Uzi_Shot.mp3"
const UZI_RELOAD_PATH: String = "res://assets/Audio/Uzi/Uzi_Reload.mp3"
const UZI_RELOAD_EMPTY_PATH: String = "res://assets/Audio/Uzi/Uzi_Reload_Empty.mp3"
const UZI_EMPTY_CLICK_PATH: String = "res://assets/Audio/Uzi/Uzi_Empty_Click.mp3"
const UZI_LOW_IMPACT_PATH: String = "res://assets/Audio/Uzi/Layers/Uzi_Low_Impact.mp3"
const UZI_BOLT_ACTION_PATH: String = "res://assets/Audio/Uzi/Layers/Uzi_Bolt_Action.mp3"
const UZI_BUNKER_REFLECTION_PATH: String = "res://assets/Audio/Uzi/Layers/Uzi_Bunker_Reflection.mp3"
const UZI_SHELL_CASING_PATH: String = "res://assets/Audio/Uzi/Layers/Uzi_Shell_Casing.mp3"
const UZI_MAG_TAP_PATH: String = "res://assets/Audio/Uzi/Layers/Uzi_Mag_Tap.mp3"
const SHOTGUN_SHOT_PATH: String = "res://assets/Audio/Shotgun/Shotgun_Shot.mp3"
const SHOTGUN_RELOAD_PATH: String = "res://assets/Audio/Shotgun/Shotgun_Reload.mp3"
const SHOTGUN_RELOAD_SEQUENCE_PATH: String = "res://assets/Audio/Shotgun/Shotgun_Reload_Sequence.mp3"
const SHOTGUN_EMPTY_CLICK_PATH: String = "res://assets/Audio/Shotgun/Shotgun_Empty_Click.mp3"
const SHOTGUN_DRY_FIRE_PATH: String = "res://assets/Audio/Shotgun/Shotgun_Dry_Fire.mp3"
const SHOTGUN_LOW_IMPACT_PATH: String = "res://assets/Audio/Shotgun/Layers/Shotgun_Low_Impact.mp3"
const SHOTGUN_PUMP_ACTION_PATH: String = "res://assets/Audio/Shotgun/Layers/Shotgun_Pump_Action.mp3"
const SHOTGUN_PUMP_BACK_PATH: String = "res://assets/Audio/Shotgun/Layers/Shotgun_Pump_Back.mp3"
const SHOTGUN_PUMP_FORWARD_PATH: String = "res://assets/Audio/Shotgun/Layers/Shotgun_Pump_Forward.mp3"
const SHOTGUN_BUNKER_REFLECTION_PATH: String = "res://assets/Audio/Shotgun/Layers/Shotgun_Bunker_Reflection.mp3"
const SHOTGUN_SHELL_EJECT_PATH: String = "res://assets/Audio/Shotgun/Layers/Shotgun_Shell_Eject.mp3"
const SHOTGUN_SHELL_INSERT_PATH: String = "res://assets/Audio/Shotgun/Layers/Shotgun_Shell_Insert.mp3"

const SMALL_OBSTACLE_JUMP_PATHS: Array[String] = [
	"res://assets/Audio/Player Movement/Small Obstacle/Small Obstacle Jump 01.mp3",
	"res://assets/Audio/Player Movement/Small Obstacle/Small Obstacle Jump 02.mp3",
	"res://assets/Audio/Player Movement/Small Obstacle/Small Obstacle Jump 03.mp3",
	"res://assets/Audio/Player Movement/Small Obstacle/Small Obstacle Jump 04.mp3",
]
const LARGE_OBSTACLE_JUMP_PATHS: Array[String] = [
	"res://assets/Audio/Player Movement/Large Obstacle/Large Obstacle Jump 01.mp3",
	"res://assets/Audio/Player Movement/Large Obstacle/Large Obstacle Jump 02.mp3",
	"res://assets/Audio/Player Movement/Large Obstacle/Large Obstacle Jump 03.mp3",
	"res://assets/Audio/Player Movement/Large Obstacle/Large Obstacle Jump 04.mp3",
]

const PLAYER_DEATH_VOCAL_PATHS: Array[String] = [
	"res://assets/Audio/Death/Player Death Vocal 01.mp3",
	"res://assets/Audio/Death/Player Death Vocal 02.mp3",
	"res://assets/Audio/Death/Player Death Vocal 03.mp3",
	"res://assets/Audio/Death/Player Death Vocal 04.mp3",
]

# Generated gameplay audio. Player death remains on the existing authored set.
const PLAYER_LIGHT_PAIN_PATHS: Array[String] = [
	"res://assets/Audio/Generated/Player Damage/Light Pain/Light Pain 01.ogg",
	"res://assets/Audio/Generated/Player Damage/Light Pain/Light Pain 02.ogg",
	"res://assets/Audio/Generated/Player Damage/Light Pain/Light Pain 03.ogg",
]
const PLAYER_HEAVY_PAIN_PATHS: Array[String] = [
	"res://assets/Audio/Generated/Player Damage/Heavy Pain/Heavy Pain 01.ogg",
	"res://assets/Audio/Generated/Player Damage/Heavy Pain/Heavy Pain 02.ogg",
	"res://assets/Audio/Generated/Player Damage/Heavy Pain/Heavy Pain 03.ogg",
]
const LOW_HEALTH_BREATHING_PATH := "res://assets/Audio/Generated/Player Damage/Low Health Breathing.ogg"
const LOW_HEALTH_HEARTBEAT_PATH := "res://assets/Audio/Generated/Player Damage/Low Health Heartbeat.ogg"
const PLAYER_FOOTSTEP_PATHS := {
	"concrete": "res://assets/Audio/Generated/Player Footsteps/Concrete/Step 01.wav",
	"metal": "res://assets/Audio/Generated/Player Footsteps/Metal/Step 01.wav",
	"debris": "res://assets/Audio/Generated/Player Footsteps/Debris/Step 01.wav",
	"wet": "res://assets/Audio/Generated/Player Footsteps/Wet/Step 01.wav",
}
# One left/right heel pair per gait cycle. Camera dip, weapon drop, and the
# audible step all fire on these exact marks so the mechanism reads as one event.
const FOOTSTEP_HEEL_LEFT := PI * 0.5
const FOOTSTEP_HEEL_RIGHT := PI * 1.5
const FOOTSTEP_BUS_NAME := "Footsteps"

# Measured transient positions in the supplied 10-second heartbeat recording.
# Sampling the AudioStreamPlayer's playback position keeps the red pulse and
# camera motion locked to the actual irregular heartbeat, including quiet
# secondary beats, instead of running an unrelated visual timer.
const LOW_HEALTH_HEARTBEAT_LENGTH := 10.0
const LOW_HEALTH_HEARTBEAT_TIMES: Array[float] = [
	0.220, 1.025, 1.315, 1.879, 2.141, 2.718, 3.594,
	4.340, 5.196, 5.936, 6.812, 7.737, 8.621, 8.874,
]
const LOW_HEALTH_HEARTBEAT_STRENGTHS: Array[float] = [
	0.90, 0.81, 0.31, 0.89, 0.28, 0.99, 0.61,
	0.96, 0.72, 0.85, 0.93, 0.83, 0.89, 0.30,
]

# Exact scene paths only. No asset guessing/searching is used for jump classification.
const LARGE_JUMP_OBSTACLE_SCENES: Array[String] = [
	"res://assets/Guard Rails/industrial+guardrail+3d+model.glb",
]
const SMALL_JUMP_OBSTACLE_SCENES: Array[String] = [
	"res://assets/Furniture/Box+2.glb",
	"res://assets/Crate/Mini Crate.glb",
	"res://assets/Crate/Military Storage crate.glb",
]
# Replacement pistol has its own centered origin and points along local +Z.
# Hip carry: lower-right, slide aimed at a point ~8 m down the crosshair
# (same framing language as the Uzi and shotgun; see SHOTGUN_MODEL_OFFSET).
const VIEWMODEL_POSITION := Vector3.ZERO
const VIEWMODEL_MODEL_OFFSET := Vector3(0.4928, -1.3133, -0.1003)
const VIEWMODEL_DEFAULT_SCALE := 7.30
const VIEWMODEL_SCALE := Vector3(7.30, 7.30, 7.30)
const VIEWMODEL_DEFAULT_ROTATION := Vector3(-2.93, 179.05, 2.57)
const VIEWMODEL_CONFIG_PATH := "user://viewmodel_settings.cfg"
const MOBILE_UI_CONFIG_PATH := "user://mobile_ui_settings.cfg"
const VIEWMODEL_CONFIG_VERSION := 13
const ROOM2_EQUIP_Z := -4.85

@onready var camera_pivot: Node3D = $CameraPivot
@onready var jump_offset: Node3D = $CameraPivot/JumpOffset
@onready var camera: Camera3D = $CameraPivot/JumpOffset/Camera3D

# FPS viewmodel stays on the real gameplay camera, but its entire local transform is
# uniformly compressed toward the camera. Position AND scale use the same factor,
# so its screen-space placement is unchanged while its real depth is only ~10%.
# This keeps normal material/depth behavior (no ugly self-overdraw) while preventing
# the floor/walls from swallowing the gun when looking down or standing near props.
const VIEWMODEL_RENDER_LAYER := 1 << 19
const VIEWMODEL_DEPTH_FACTOR := 0.10

var pitch: float = 0.0
var bob_time: float = 0.0
var base_camera_y: float = 0.62

var has_pistol := false
var current_weapon_id: String = ""
var primary_weapon_id: String = ""
var secondary_weapon_id: String = ""
var equipped_weapon_display_name: String = ""
var equipped_weapon_ammo_display: String = ""
var weapon_ammo_store: Dictionary = {}
var swap_button: BaseButton = null
var weapon_choice_active := false
var weapon_choice_shown_for: Dictionary = {}
var pending_incoming_weapon_id: String = ""
var weapon_intro_locked := false
var uzi_idle_alt_timer: float = 8.0
var viewmodel_root: Node3D
var viewmodel_visual: Node3D
var pistol_viewmodel: Node3D = null
var uzi_viewmodel: Node3D = null
var shotgun_viewmodel: Node3D = null
var pistol_anim_player: AnimationPlayer = null
var shotgun_action: StringName = &"idle"
var shotgun_section_playing := false
var shotgun_section_end: float = 0.0
var shotgun_reload_needed: int = 0
var shotgun_reload_total: int = 0
var shotgun_empty_reload := false
var uzi_skeleton: Skeleton3D = null
var uzi_rear_bone: int = -1
var uzi_front_bone: int = -1
var hip_anchor: Marker3D = null
var ads_anchor: Marker3D = null
var viewmodel_anim_player: AnimationPlayer = null
var shoot_button: TextureButton
var jump_button: TextureButton = null
var sprint_button: TextureButton = null
var sprint_bar_root: Control = null
var sprint_bar_fill: Panel = null
var sprint_bar_fill_max_width: float = 253.0
var sprint_bar_alpha: float = 0.0
var ammo_label: Label
var shot_flash: ColorRect
var weapon_time := 0.0
# Camera kick (radians: x pitch up, y yaw, z roll) + push-back (m, local +Z)
# + FOV punch. All springs rest at zero = the shot's aim point.
var camera_kick := Vector3.ZERO
var camera_kick_velocity := Vector3.ZERO
var camera_kick_push := 0.0
var camera_kick_push_velocity := 0.0
# Legacy scalar pitch-velocity nudge (radians/s). room_transition_door.gd adds
# to it for the blast-door thud; it is folded into camera_kick each frame.
var camera_recoil_velocity := 0.0
var uzi_burst_climb := 0.0
var uzi_burst_climb_velocity := 0.0
var uzi_roll_sign := 1.0
var recoil_fov_offset := 0.0
var recoil_fov_velocity := 0.0
# Hand kick on the viewmodel root (position m, rotation degrees).
var hand_kick_position := Vector3.ZERO
var hand_kick_position_velocity := Vector3.ZERO
var hand_kick_rotation := Vector3.ZERO
var hand_kick_rotation_velocity := Vector3.ZERO
# Direct (unsmoothed) viewmodel offsets written last frame, so the smoothed
# carry pose can be recovered from viewmodel_root without a second state.
var viewmodel_direct_position := Vector3.ZERO
var viewmodel_direct_rotation := Vector3.ZERO
var look_sway_velocity := Vector2.ZERO
var camera_base_fov := 72.0
var sprint_was_active := false
var muzzle_flash_time := 0.0
var shot_cooldown := 0.0
var aim_hold_timer := 0.0
var ammo := PISTOL_MAG_CAPACITY
var reserve_ammo := PISTOL_STARTING_TOTAL_AMMO - PISTOL_MAG_CAPACITY
var unlimited_ammo := false
var is_reloading: bool = false
var reload_timer: float = 0.0
var reload_pending_timer: float = 0.0
var damage_flash: ColorRect
@export var max_health: float = 100.0
var health: float = 100.0
var health_bar: ProgressBar
var health_root: Control = null
var timer_root: Control = null
var bank_root: Control = null
var health_fill: ColorRect = null
var health_fill_max_width: float = 250.0
var health_value_label: Label
var stopwatch_label: Label = null
var money_label: Label = null
var elapsed_time: float = 0.0
var stopwatch_refresh_accum: float = 0.0
var muzzle_light: OmniLight3D
var look_sway_target := Vector2.ZERO
var look_sway := Vector2.ZERO
var camera_roll: float = 0.0
var was_on_floor: bool = false
var jump_requested: bool = false
var double_jump_requested: bool = false
var double_jump_used: bool = false
var jump_started_msec: int = -100000
var airborne_time: float = 0.0
enum JumpMovementState { GROUNDED, NORMAL_JUMP, OBSTACLE_JUMP, FALLING, LANDING }
enum JumpObstacleKind { NONE, GENERIC, SMALL, LARGE }
var jump_state: JumpMovementState = JumpMovementState.GROUNDED
var active_jump_was_obstacle: bool = false
var active_jump_obstacle_kind: JumpObstacleKind = JumpObstacleKind.NONE
var jump_phase_time: float = 0.0
var landing_intensity: float = 0.0
var obstacle_double_jump_active: bool = false
var hard_landing_active: bool = false
var hard_landing_strength: float = 0.0
var hard_landing_impact_speed: float = 0.0
var hard_landing_last_grunt_msec: int = -100000
var jump_horizontal_speed_at_takeoff: float = 0.0
var jump_camera_velocity := Vector3.ZERO
var jump_rotation_velocity := Vector3.ZERO
var jump_fov_offset: float = 0.0
var jump_fov_velocity: float = 0.0
var jump_weapon_position_offset := Vector3.ZERO
var jump_weapon_position_velocity := Vector3.ZERO
var jump_weapon_rotation_offset := Vector3.ZERO
var jump_weapon_rotation_velocity := Vector3.ZERO

# Dedicated additive zombie-melee camera layer.
var melee_impact_pivot: Node3D = null
var melee_rotation_offset := Vector3.ZERO
var melee_rotation_velocity := Vector3.ZERO
var melee_position_offset := Vector3.ZERO
var melee_position_velocity := Vector3.ZERO
var melee_weapon_position_offset := Vector3.ZERO
var melee_weapon_position_velocity := Vector3.ZERO
var melee_weapon_rotation_offset := Vector3.ZERO
var melee_weapon_rotation_velocity := Vector3.ZERO
var melee_fov_offset: float = 0.0
var melee_fov_velocity: float = 0.0
var melee_last_hit_msec: int = -100000
var melee_rapid_hit_count: int = 0
var damage_last_profile_is_melee: bool = true
var damage_last_is_heavy: bool = false
var damage_last_contact_msec: int = -100000
var finisher_camera_timer: float = 0.0
var finisher_camera_duration: float = 0.0
var finisher_camera_side: float = 0.0
var finisher_camera_style_sign: float = 1.0
var smoothed_move_input := Vector2.ZERO
var movement_speed_ratio: float = 0.0
var gait_phase: float = 0.0
var gait_blend: float = 0.0
var camera_walk_pitch: float = 0.0
var previous_horizontal_velocity := Vector2.ZERO
var acceleration_lean: float = 0.0
var pistol_shot_players: Array[AudioStreamPlayer] = []
var pistol_shot_voice_index: int = 0
var reload_audio: AudioStreamPlayer = null
var uzi_reload_audio: AudioStreamPlayer = null
var uzi_reload_empty_audio: AudioStreamPlayer = null
var uzi_empty_click_audio: AudioStreamPlayer = null
var uzi_mag_tap_audio: AudioStreamPlayer = null
var shotgun_reload_audio: AudioStreamPlayer = null
var shotgun_reload_sequence_audio: AudioStreamPlayer = null
var shotgun_empty_click_audio: AudioStreamPlayer = null
var shotgun_dry_fire_audio: AudioStreamPlayer = null
var shotgun_insert_audio: AudioStreamPlayer = null
var shotgun_shot_players: Array[AudioStreamPlayer] = []
var shotgun_low_impact_players: Array[AudioStreamPlayer] = []
var shotgun_pump_players: Array[AudioStreamPlayer] = []
var shotgun_pump_back_players: Array[AudioStreamPlayer] = []
var shotgun_pump_forward_players: Array[AudioStreamPlayer] = []
var shotgun_reflection_players: Array[AudioStreamPlayer] = []
var shotgun_shell_players: Array[AudioStreamPlayer] = []
var shotgun_shot_voice_index: int = 0
var shotgun_low_voice_index: int = 0
var shotgun_pump_voice_index: int = 0
var shotgun_pump_back_voice_index: int = 0
var shotgun_pump_forward_voice_index: int = 0
var shotgun_reflection_voice_index: int = 0
var shotgun_shell_voice_index: int = 0
var empty_click_cooldown: float = 0.0
var pistol_low_impact_players: Array[AudioStreamPlayer] = []
var pistol_slide_players: Array[AudioStreamPlayer] = []
var pistol_reflection_players: Array[AudioStreamPlayer] = []
var pistol_shell_players: Array[AudioStreamPlayer] = []
var uzi_shot_players: Array[AudioStreamPlayer] = []
var uzi_low_impact_players: Array[AudioStreamPlayer] = []
var uzi_bolt_players: Array[AudioStreamPlayer] = []
var uzi_reflection_players: Array[AudioStreamPlayer] = []
var uzi_shell_players: Array[AudioStreamPlayer] = []
var pistol_low_voice_index: int = 0
var pistol_slide_voice_index: int = 0
var pistol_reflection_voice_index: int = 0
var pistol_shell_voice_index: int = 0
var uzi_shot_voice_index: int = 0
var uzi_low_voice_index: int = 0
var uzi_bolt_voice_index: int = 0
var uzi_reflection_voice_index: int = 0
var uzi_shell_voice_index: int = 0
var small_obstacle_jump_streams: Array[AudioStream] = []
var large_obstacle_jump_streams: Array[AudioStream] = []
var jump_effort_audio: AudioStreamPlayer = null
var last_small_jump_voice_index: int = -1
var last_large_jump_voice_index: int = -1
var footstep_streams: Dictionary = {}
var footstep_audio_pool: Array[AudioStreamPlayer] = []
var footstep_voice_index: int = 0
var footstep_last_gait_phase: float = 0.0
var footstep_phase_initialized: bool = false
var footstep_left_next: bool = true
var footstep_weapon_drop: float = 0.0
var pending_footstep_impact: float = 0.0
var damage_voice_audio: AudioStreamPlayer = null
var light_pain_streams: Array[AudioStream] = []
var heavy_pain_streams: Array[AudioStream] = []
var last_light_pain_index: int = -1
var last_heavy_pain_index: int = -1
var damage_voice_cooldown: float = 0.0
var low_health_breathing_audio: AudioStreamPlayer = null
var low_health_heartbeat_audio: AudioStreamPlayer = null
var health_regen_wait: float = 0.0
var low_health_camera_position := Vector3.ZERO
var low_health_camera_rotation := Vector3.ZERO
# Same heartbeat sample drives the hands and a FOV breathe.
var low_health_hand_position := Vector3.ZERO
var low_health_hand_rotation := Vector3.ZERO
var low_health_fov_offset := 0.0
var low_health_active_blend := 0.0
var pistol_hd_albedo: Texture2D = null
var hand_hd_albedo: Texture2D = null
var arm_hd_albedo: Texture2D = null

# Mobile FPS controls. The left joystick feeds the same movement vector as WASD.
var mobile_move_input := Vector2.ZERO
var mobile_sprint := false
var sprint_touch_id: int = -1

# Sprint stamina.
var stamina: float = 100.0
var stamina_regen_wait: float = 0.0
var sprint_exhausted: bool = false
var sprint_active: bool = false

# Additive sprint camera state.
var sprint_effect_pivot: Node3D = null
var sprint_pos_offset := Vector3.ZERO
var sprint_pos_velocity := Vector3.ZERO
var sprint_rot_offset := Vector3.ZERO
var sprint_rot_velocity := Vector3.ZERO
var sprint_fov_offset: float = 0.0
var sprint_fov_velocity: float = 0.0
var sprint_blend: float = 0.0
var sprint_prev_horizontal_velocity := Vector2.ZERO
var sprint_smoothed_acceleration := Vector2.ZERO
var sprint_weapon_position_offset := Vector3.ZERO
var sprint_weapon_position_velocity := Vector3.ZERO
var sprint_weapon_rotation_offset := Vector3.ZERO
var sprint_weapon_rotation_velocity := Vector3.ZERO
var sprint_last_gait_phase: float = 0.0

# Dedicated sharp-direction-change inertia. This is separate from sprint,
# jump, landing and melee so each effect can add naturally.
var lateral_inertia_pivot: Node3D = null
var lateral_previous_horizontal_velocity := Vector3.ZERO
var lateral_smoothed_acceleration: float = 0.0
var lateral_camera_offset: float = 0.0
var lateral_camera_velocity: float = 0.0
var lateral_roll_offset: float = 0.0
var lateral_roll_velocity: float = 0.0
var lateral_yaw_offset: float = 0.0
var lateral_yaw_velocity: float = 0.0
var lateral_weapon_position_offset := Vector3.ZERO
var lateral_weapon_position_velocity := Vector3.ZERO
var lateral_weapon_rotation_offset := Vector3.ZERO
var lateral_weapon_rotation_velocity := Vector3.ZERO
var joystick_base: Control = null
var joystick_knob: Control = null
var joystick_radius: float = 66.0
var joystick_touch_id: int = -1
var joystick_mouse_dragging: bool = false
var joystick_rest_position := Vector2.ZERO
var joystick_visual_tween: Tween = null
var look_touch_id: int = -1
var fire_touch_id: int = -1
var jump_touch_id: int = -1
var movement_origin := Vector2.ZERO
var look_smoothed_delta := Vector2.ZERO
var desktop_fire_held: bool = false
var control_layout_editor: ControlLayoutEditor = null
var viewmodel_animation_state: StringName = &""
var last_mobile_viewport_size := Vector2.ZERO
var viewmodel_key_light: DirectionalLight3D = null
var viewmodel_fill_light: OmniLight3D = null
var viewmodel_rim_light: SpotLight3D = null

# Authored UI scenes. Layout lives in .tscn files; these are runtime handles.
var gameplay_hud: HudController = null
var pause_menu: PauseMenu = null

# Match / pause / game-over state.
var pause_button: TextureButton = null
var pause_overlay: Control = null
var pause_panel: PanelContainer = null
var pause_menu_page: VBoxContainer = null
var pause_settings_page: Control = null
var pause_weapon_value: Label = null
var pause_weapon_icon: Control = null
var pause_bank_value: Label = null
var pause_time_value: Label = null
var pause_sensitivity_value: Label = null
var pause_sensitivity_slider: HSlider = null
var pause_music_value: Label = null
var pause_music_slider: HSlider = null
var pause_haptics_toggle: CheckButton = null
var haptics_enabled: bool = true
## AIM button / right mouse: holds the ADS pose without firing.
var aim_toggle_active := false
var crouch_active := false
var crouch_blend := 0.0
const CROUCH_CAMERA_DROP := 0.55
const CROUCH_SPEED_MULTIPLIER := 0.55
const AIM_ASSIST_CONE_DEGREES := 7.0
const AIM_ASSIST_RANGE := 32.0
const AIM_ASSIST_STRENGTH := 5.5
const ZOMBIE_DEAD_STATE := 5
var upgrade_modal_active: bool = false
var game_over_overlay: Control = null
var game_over_stats_label: Label = null
var game_over: bool = false
var encounter_started: bool = false
var zombies_killed: int = 0
var shots_fired: int = 0
var shots_hit: int = 0
var damage_taken: float = 0.0
var survival_time: float = 0.0
var encounter_completion_pending: bool = false

# Cinematic death sequence.
var death_sequence_active: bool = false
var death_overlay: Control = null
var death_vignette: ColorRect = null
var death_top_mask: ColorRect = null
var death_bottom_mask: ColorRect = null
var death_heartbeat_audio: AudioStreamPlayer = null
var death_impact_audio: AudioStreamPlayer = null
var death_vocal_audio: AudioStreamPlayer = null
var death_vocal_streams: Array[AudioStream] = []
var last_death_vocal_index: int = -1
var death_master_lowpass_index: int = -1
var death_camera_start_pivot := Vector3.ZERO
var death_camera_start_rotation := Vector3.ZERO
var death_viewmodel_start_position := Vector3.ZERO
var death_viewmodel_start_rotation := Vector3.ZERO

const ROOM2_RETRY_POSITION := Vector3(0.0, 1.0, -6.2)

# Gameplay wrapper scenes can override this without forking the player logic.
# The default preserves the established Room 1 retry behavior.
@export var retry_position: Vector3 = ROOM2_RETRY_POSITION

# Live FPS viewmodel tuning. T cycles hip / ready-to-aim / off. Y jumps to ready.
# Saved values persist in user://viewmodel_settings.cfg.
var viewmodel_tune_enabled := false
var viewmodel_tune_target := "hip"
var viewmodel_tune_label: Label
var viewmodel_tune_panel: Control = null
var viewmodel_tune_position := VIEWMODEL_MODEL_OFFSET
var viewmodel_tune_scale := VIEWMODEL_DEFAULT_SCALE
var viewmodel_tune_rotation := VIEWMODEL_DEFAULT_ROTATION
var uzi_ready_position := UZI_READY_OFFSET
var uzi_ready_scale := UZI_READY_SCALE
var uzi_ready_rotation := UZI_READY_ROTATION
var shotgun_ready_position := SHOTGUN_READY_OFFSET
var shotgun_ready_scale := SHOTGUN_DEFAULT_SCALE
var shotgun_ready_rotation := SHOTGUN_READY_ROTATION
var extra_ready_position: Dictionary = {}
var extra_ready_scale: Dictionary = {}
var extra_ready_rotation: Dictionary = {}

enum AimState { HIP, ENTERING_ADS, ADS, EXITING_ADS }
enum PistolMotionState { COMBAT, SPRINT_ENTER, SPRINT_LOOP, SPRINT_EXIT }
var aim_state: AimState = AimState.HIP
var pistol_motion_state: PistolMotionState = PistolMotionState.COMBAT
var pistol_motion_transition_timer: float = 0.0
var sprint_exit_fire_pending: bool = false
var sprint_suppressed_for_combat: bool = false
var ads_blend: float = 0.0
var ads_requested: bool = false
var ads_pending_initial_shot: bool = false
var ads_fire_delay_remaining: float = 0.0
var ads_release_hold_remaining: float = 0.0

func _ready() -> void:
	_ensure_sprint_camera_pivot()
	_ensure_lateral_inertia_pivot()
	_ensure_melee_impact_pivot()
	camera_base_fov = camera.fov
	stamina = stamina_max
	# Cap mobile gameplay at 60 FPS. This keeps controls responsive while greatly
	# reducing unnecessary GPU load/heat on high-refresh iPhones.
	ControlSettingsManager.apply_graphics()
	# Player input/menu code must keep processing while the SceneTree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Pistol keeps the approved production pose. Uzi placement is loaded per-weapon
	# so live T-key tuning can persist without overwriting the pistol.
	_load_mobile_ui_settings()
	_sync_look_from_control_settings()
	haptics_enabled = ControlSettingsManager.haptics_enabled
	# The replacement pistol carries materials authored for its own UV layout.
	# Legacy albedo overrides belong to the previous pistol and must not be loaded.
	_set_desktop_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	max_health = 100.0 + UpgradeManager.get_health_bonus()
	health = max_health
	_create_viewmodel()
	_load_viewmodel_settings()
	# Player can be a scene-tree sibling that readies before the HUD/CanvasLayer,
	# which means the HUD's own @onready widget references aren't populated yet.
	# Defer the bind so it runs after every node in the scene has finished _ready().
	call_deferred("_bind_authored_ui")
	_create_muzzle_light()
	_create_viewmodel_fill_lights()
	_create_game_audio()
	_create_extra_weapon_audio()
	MusicManager.enter_gameplay()
	if not EconomyManager.money_changed.is_connected(_on_money_changed):
		EconomyManager.money_changed.connect(_on_money_changed)
	_on_money_changed(EconomyManager.get_balance())
	# Room 01 is the safe hub. A fresh gameplay scene always begins outside a run.
	RunManager.reset_to_hub()

func _bind_authored_ui() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		push_error("Player could not bind authored UI: current scene is null.")
		return
	var hud_layer := scene.get_node_or_null("HUD") as CanvasLayer
	if hud_layer == null:
		push_error("HUD CanvasLayer is missing from the gameplay scene.")
		return

	gameplay_hud = hud_layer as HudController
	if gameplay_hud == null:
		gameplay_hud = hud_layer.get_node_or_null("GameplayHud") as HudController
	pause_menu = hud_layer.get_node_or_null("PauseMenu") as PauseMenu
	if gameplay_hud == null or pause_menu == null:
		push_error("HUD or PauseMenu scene is missing.")
		return

	shot_flash = gameplay_hud.shot_flash
	damage_flash = gameplay_hud.damage_flash
	health_root = gameplay_hud.health_root
	health_fill = gameplay_hud.health_fill
	health_fill_max_width = gameplay_hud.health_fill_max_width
	health_value_label = gameplay_hud.health_value_label
	sprint_bar_root = gameplay_hud.sprint_bar_root
	sprint_bar_fill = gameplay_hud.sprint_bar_fill
	sprint_bar_fill_max_width = gameplay_hud.sprint_bar_fill_max_width
	timer_root = gameplay_hud.timer_root
	stopwatch_label = gameplay_hud.stopwatch_label
	bank_root = gameplay_hud.bank_root
	money_label = gameplay_hud.money_label
	ammo_label = gameplay_hud.ammo_label
	viewmodel_tune_label = gameplay_hud.viewmodel_tune_label
	if viewmodel_tune_label != null:
		viewmodel_tune_label.visible = false
		viewmodel_tune_label.text = ""
		viewmodel_tune_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base = gameplay_hud.joystick_base
	joystick_knob = gameplay_hud.joystick_knob
	shoot_button = gameplay_hud.shoot_button
	jump_button = gameplay_hud.jump_button
	sprint_button = gameplay_hud.sprint_button
	pause_button = gameplay_hud.pause_button
	swap_button = gameplay_hud.get("swap_button") as BaseButton
	if swap_button != null and not swap_button.pressed.is_connected(_on_swap_button_pressed):
		swap_button.pressed.connect(_on_swap_button_pressed)
	death_overlay = gameplay_hud.death_overlay
	death_vignette = gameplay_hud.death_vignette
	death_top_mask = gameplay_hud.death_top_mask
	death_bottom_mask = gameplay_hud.death_bottom_mask
	game_over_overlay = gameplay_hud.game_over_overlay
	game_over_stats_label = gameplay_hud.game_over_stats_label

	pause_overlay = pause_menu
	pause_panel = pause_menu.pause_panel
	pause_menu_page = pause_menu.pause_menu_page
	pause_settings_page = pause_menu.pause_settings_page
	pause_sensitivity_value = pause_menu.pause_sensitivity_value
	pause_sensitivity_slider = pause_menu.pause_sensitivity_slider
	pause_music_value = pause_menu.pause_music_value
	pause_music_slider = pause_menu.pause_music_slider
	pause_haptics_toggle = pause_menu.pause_haptics_toggle
	pause_weapon_value = pause_menu.pause_weapon_value
	pause_weapon_icon = pause_menu.pause_weapon_icon
	pause_bank_value = pause_menu.pause_bank_value
	pause_time_value = pause_menu.pause_time_value

	if not gameplay_hud.retry_requested.is_connected(_retry_room2):
		gameplay_hud.retry_requested.connect(_retry_room2)
	if not gameplay_hud.main_menu_requested.is_connected(_go_main_menu):
		gameplay_hud.main_menu_requested.connect(_go_main_menu)
	if not pause_menu.resume_requested.is_connected(_resume_game):
		pause_menu.resume_requested.connect(_resume_game)
	if not pause_menu.restart_requested.is_connected(_restart_from_hub):
		pause_menu.restart_requested.connect(_restart_from_hub)
	if not pause_menu.main_menu_requested.is_connected(_go_main_menu):
		pause_menu.main_menu_requested.connect(_go_main_menu)
	if not pause_menu.sensitivity_changed.is_connected(_on_pause_sensitivity_changed):
		pause_menu.sensitivity_changed.connect(_on_pause_sensitivity_changed)
	if not pause_menu.haptics_changed.is_connected(_on_pause_haptics_toggled):
		pause_menu.haptics_changed.connect(_on_pause_haptics_toggled)
	if not pause_menu.edit_layout_requested.is_connected(_open_control_layout_editor):
		pause_menu.edit_layout_requested.connect(_open_control_layout_editor)
	if not ControlSettingsManager.settings_changed.is_connected(_on_control_settings_changed):
		ControlSettingsManager.settings_changed.connect(_on_control_settings_changed)

	_ensure_control_layout_editor()
	gameplay_hud.configure_mobile_visibility(_should_show_mobile_hud(), has_pistol)
	gameplay_hud.apply_hud_art()
	_layout_mobile_action_buttons()
	joystick_radius = gameplay_hud.joystick_radius
	joystick_rest_position = gameplay_hud.joystick_rest_position
	_update_health_ui()
	_update_stamina_ui(0.0)
	_update_stopwatch_ui()
	_reset_joystick_immediate()
	_ensure_viewmodel_tune_panel()

func _ensure_sprint_camera_pivot() -> void:
	if sprint_effect_pivot != null:
		return

	sprint_effect_pivot = Node3D.new()
	sprint_effect_pivot.name = "SprintEffectsOffset"
	camera_pivot.add_child(sprint_effect_pivot)

	# Additive hierarchy:
	# CameraPivot (look/walk)
	#   -> SprintEffectsOffset
	#      -> JumpOffset
	#         -> MeleeImpactOffset
	#            -> Camera3D
	jump_offset.reparent(sprint_effect_pivot, true)
	sprint_effect_pivot.position = Vector3.ZERO
	sprint_effect_pivot.rotation = Vector3.ZERO


func _ensure_lateral_inertia_pivot() -> void:
	if lateral_inertia_pivot != null:
		return

	lateral_inertia_pivot = Node3D.new()
	lateral_inertia_pivot.name = "LateralInertiaOffset"
	sprint_effect_pivot.add_child(lateral_inertia_pivot)

	# Final additive hierarchy:
	# CameraPivot
	#   -> SprintEffectsOffset
	#      -> LateralInertiaOffset
	#         -> JumpOffset
	#            -> MeleeImpactOffset
	#               -> Camera3D
	jump_offset.reparent(lateral_inertia_pivot, true)
	lateral_inertia_pivot.position = Vector3.ZERO
	lateral_inertia_pivot.rotation = Vector3.ZERO

	var hvel := Vector3(velocity.x, 0.0, velocity.z)
	lateral_previous_horizontal_velocity = hvel


func _ensure_melee_impact_pivot() -> void:
	if melee_impact_pivot != null:
		return

	melee_impact_pivot = Node3D.new()
	melee_impact_pivot.name = "MeleeImpactOffset"
	jump_offset.add_child(melee_impact_pivot)

	# Additive hierarchy:
	# CameraPivot -> JumpOffset -> MeleeImpactOffset -> Camera3D
	camera.reparent(melee_impact_pivot, true)
	melee_impact_pivot.position = Vector3.ZERO
	melee_impact_pivot.rotation = Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if death_sequence_active:
		return
	if weapon_choice_active:
		return
	if upgrade_modal_active:
		if event is InputEventKey:
			var modal_key := event as InputEventKey
			if modal_key.pressed and not modal_key.echo and modal_key.keycode == KEY_ESCAPE:
				var upgrade_controller := get_tree().current_scene.get_node_or_null("UpgradeUIController")
				if upgrade_controller != null and upgrade_controller.has_method("close_popup"):
					upgrade_controller.call("close_popup")
		return
	if (game_over or get_tree().paused) and not (event is InputEventKey):
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-80.0), deg_to_rad(80.0))
		look_sway_target.x = clampf(-event.relative.x * 0.00045, -0.018, 0.018)
		look_sway_target.y = clampf(event.relative.y * 0.00035, -0.014, 0.014)
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed and _try_upgrade_interaction(mouse_event.position):
				return
			if not _is_mobile_ui():
				desktop_fire_held = mouse_event.pressed and has_pistol and not game_over
				if desktop_fire_held:
					_begin_fire_input()
				else:
					_end_fire_input()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and not _is_mobile_ui():
			_set_aim_toggle(mouse_event.pressed)
		if mouse_event.pressed and not _is_mobile_ui() and not viewmodel_tune_enabled:
			_set_desktop_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventKey and event.pressed:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_P and not key_event.echo:
			if viewmodel_tune_enabled and viewmodel_tune_panel != null and viewmodel_tune_panel.visible:
				_exit_viewmodel_tuning()
			else:
				_open_dev_menu()
			return
		if (
			not key_event.echo
			and not game_over
			and not get_tree().paused
			and viewmodel_tune_enabled
			and key_event.keycode == KEY_T
		):
			_enter_or_toggle_tune("hip")
			return
		if viewmodel_tune_enabled and _handle_viewmodel_tune_key(key_event):
			return
		if key_event.keycode == KEY_SPACE and not key_event.echo and not game_over and not get_tree().paused:
			request_jump()
			return
		if key_event.keycode == KEY_R and not key_event.echo and not game_over and not get_tree().paused:
			_start_reload()
			return
		if key_event.keycode == KEY_C and not key_event.echo and not game_over and not get_tree().paused:
			_toggle_crouch()
			return
		if key_event.keycode == KEY_V and not key_event.echo and not game_over and not get_tree().paused:
			_on_melee_pressed()
			return
		if (
			(key_event.keycode == KEY_F6 or key_event.keycode == KEY_F7)
			and not key_event.echo
			and OS.is_debug_build()
			and not _is_mobile_ui()
			and has_pistol
			and not game_over
			and not get_tree().paused
		):
			# Debug-only playtest hook: open the offer as if Room 3 (F6) or
			# Room 6 (F7) had just been cleared. Release/mobile builds ignore it.
			var cleared := 3 if key_event.keycode == KEY_F6 else 6
			offer_weapon_choice(cleared + 1, "DEBUG: ROOM %d CLEARED" % cleared, true)
			return
		if (
			(key_event.keycode == KEY_TAB or key_event.keycode == KEY_2)
			and not key_event.echo
			and not game_over
			and not get_tree().paused
		):
			swap_to_secondary_weapon()
			return
		if key_event.keycode == KEY_E and not key_event.echo and _try_upgrade_center_interaction():
			return
		if key_event.keycode == KEY_ESCAPE:
			if ControlSettingsManager.suspend_hud_layout and control_layout_editor != null:
				control_layout_editor.close_editor(false)
				return
			_toggle_pause_menu()

func _input(event: InputEvent) -> void:
	if death_sequence_active:
		return
	if weapon_choice_active:
		return
	# A modal upgrade screen owns all pointer/touch input until it closes.  This
	# prevents stale look/fire/joystick touch IDs from locking mobile controls.
	if upgrade_modal_active:
		return
	if ControlSettingsManager.suspend_hud_layout:
		return

	# Pointer fallback for the iPad-on-Mac build and Godot debug preview.
	# Native iPhone/iPad touch still uses InputEventScreenTouch below.
	if _should_show_mobile_hud():
		if event is InputEventMouseButton:
			var mouse_button := event as InputEventMouseButton
			if mouse_button.button_index == MOUSE_BUTTON_LEFT:
				# Never start a joystick drag while paused: the pause/settings
				# menus own the pointer then, and this ran before the GUI, so a
				# click on a menu button over the joystick (settings BACK) died.
				if mouse_button.pressed and not get_tree().paused and _point_in_movement_input(mouse_button.position):
					joystick_mouse_dragging = true
					_begin_movement_touch(mouse_button.position)
					get_viewport().set_input_as_handled()
					return
				elif not mouse_button.pressed and joystick_mouse_dragging:
					joystick_mouse_dragging = false
					_end_movement_touch()
					get_viewport().set_input_as_handled()
					return
		elif event is InputEventMouseMotion and joystick_mouse_dragging:
			var mouse_motion := event as InputEventMouseMotion
			_update_movement_touch(mouse_motion.position)
			get_viewport().set_input_as_handled()
			return

	# iOS/Android uses raw touch IDs so movement, aiming, jump and firing can happen together.
	if not _is_mobile_ui():
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			# Upgrade-table taps get first priority while the player is in the safe hub.
			if _try_upgrade_interaction(touch.position):
				get_viewport().set_input_as_handled()
				return
			# Door interaction uses the actual 3D door surface on mobile. This runs
			# before look/fire assignment so tapping a blast door cannot accidentally
			# capture the finger as a camera or weapon touch.
			if gameplay_hud != null and gameplay_hud.has_method("try_mobile_door_tap") and \
					bool(gameplay_hud.call("try_mobile_door_tap", touch.position)):
				get_viewport().set_input_as_handled()
				return
			if _point_in_pause_button(touch.position) and not game_over:
				_toggle_pause_menu()
				get_viewport().set_input_as_handled()
				return
			if game_over or get_tree().paused:
				return
			if _point_in_jump_button(touch.position):
				jump_touch_id = touch.index
				request_jump()
				get_viewport().set_input_as_handled()
				return
			if _point_in_sprint_button(touch.position):
				sprint_touch_id = touch.index
				mobile_sprint = true
				get_viewport().set_input_as_handled()
				return
			if _point_in_swap_button(touch.position):
				swap_to_secondary_weapon()
				get_viewport().set_input_as_handled()
				return
			if _try_round_button_tap(touch.position):
				get_viewport().set_input_as_handled()
				return
			if fire_touch_id == -1 and _point_in_fire_button(touch.position):
				fire_touch_id = touch.index
				_begin_fire_input()
				get_viewport().set_input_as_handled()
				return

			if joystick_touch_id == -1 and _point_in_movement_input(touch.position):
				joystick_touch_id = touch.index
				_begin_movement_touch(touch.position)
				get_viewport().set_input_as_handled()
				return

			if look_touch_id == -1 and _point_in_look_zone(touch.position) and not _point_in_action_button(touch.position):
				look_touch_id = touch.index
		else:
			if touch.index == joystick_touch_id:
				joystick_touch_id = -1
				_end_movement_touch()
			elif touch.index == look_touch_id:
				look_touch_id = -1
				look_smoothed_delta = Vector2.ZERO
			elif touch.index == fire_touch_id:
				fire_touch_id = -1
				_end_fire_input()
			elif touch.index == sprint_touch_id:
				sprint_touch_id = -1
				mobile_sprint = false
			elif touch.index == jump_touch_id:
				jump_touch_id = -1

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == joystick_touch_id:
			_update_movement_touch(drag.position)
			get_viewport().set_input_as_handled()
		elif drag.index == fire_touch_id:
			# SHOOT doubles as a right-side aiming surface while held. The touch
			# remains captured by fire_touch_id even after the finger leaves the
			# visible button, allowing one continuous press-drag-fire gesture.
			_apply_mobile_look_drag(drag.relative, shoot_drag_look_multiplier)
			get_viewport().set_input_as_handled()
		elif drag.index == look_touch_id:
			_apply_mobile_look_drag(drag.relative)
			get_viewport().set_input_as_handled()
		elif drag.index == jump_touch_id or drag.index == sprint_touch_id:
			get_viewport().set_input_as_handled()


func _apply_mobile_look_drag(relative: Vector2, sensitivity_multiplier: float = 1.0) -> void:
	if game_over or get_tree().paused or death_sequence_active or upgrade_modal_active:
		return
	var applied_multiplier := clampf(sensitivity_multiplier, 0.0, 2.0)
	var look_delta := relative * applied_multiplier
	var smoothing := ControlSettingsManager.look_smoothing
	if smoothing > 0.001:
		look_smoothed_delta = look_smoothed_delta.lerp(look_delta, 1.0 - smoothing)
		look_delta = look_smoothed_delta
	else:
		look_smoothed_delta = look_delta
	var horiz := ControlSettingsManager.look_sensitivity_h
	var vert := ControlSettingsManager.look_sensitivity_v
	var y_sign := -1.0 if ControlSettingsManager.invert_y else 1.0
	rotation.y -= look_delta.x * horiz
	pitch = clampf(
		pitch - look_delta.y * vert * y_sign,
		deg_to_rad(-80.0),
		deg_to_rad(80.0)
	)
	look_sway_target.x = clampf(-look_delta.x * 0.0009, -0.022, 0.022)
	look_sway_target.y = clampf(look_delta.y * 0.00075, -0.018, 0.018)

func request_jump() -> void:
	if game_over or get_tree().paused:
		return

	# Second tap shortly after takeoff = one controlled double-jump boost.
	if not is_on_floor() and not double_jump_used:
		var since_takeoff: float = float(Time.get_ticks_msec() - jump_started_msec) / 1000.0
		if since_takeoff >= 0.03 and since_takeoff <= double_tap_jump_window:
			double_jump_requested = true
			return

	jump_requested = true


func _detect_obstacle_jump() -> JumpObstacleKind:
	# Run only when a grounded jump is consumed.
	#
	# IMPORTANT:
	# The current main scene scales the guard-rail instances much taller than the
	# value originally assumed by V54. If we test the generic 1.15 m clearance
	# ray first, that rail is rejected as "too tall" and the player receives only
	# the normal jump. We therefore identify the EXACT guard-rail scene from the
	# low collision hit first, then use its dedicated large-obstacle clearance.
	var forward_intent: float = -smoothed_move_input.y
	var facing_forward := -global_transform.basis.z
	facing_forward.y = 0.0
	facing_forward = facing_forward.normalized()
	var facing_right := global_transform.basis.x
	facing_right.y = 0.0
	facing_right = facing_right.normalized()

	var forward_speed: float = Vector3(velocity.x, 0.0, velocity.z).dot(facing_forward)
	if forward_intent < 0.28 and forward_speed < 0.75:
		return JumpObstacleKind.NONE

	var world := get_world_3d().direct_space_state
	var feet_y: float = global_position.y - 0.90
	var exclude: Array[RID] = [get_rid()]
	var obstacle_hit: Dictionary = {}

	# Check farther ahead for a large guard rail so the physical body has enough
	# horizontal travel time to gain clearance before reaching the collider.
	var probe_distance: float = large_obstacle_check_distance

	for lateral_offset: float in [-0.24, 0.0, 0.24]:
		var low_from := Vector3(global_position.x, feet_y + obstacle_low_ray_height, global_position.z)
		low_from += facing_right * lateral_offset
		var low_to := low_from + facing_forward * probe_distance
		var low_query := PhysicsRayQueryParameters3D.create(low_from, low_to, collision_mask, exclude)
		var hit: Dictionary = world.intersect_ray(low_query)
		if not hit.is_empty():
			obstacle_hit = hit
			break

	if obstacle_hit.is_empty():
		return JumpObstacleKind.NONE

	var obstacle_collider: Object = obstacle_hit.get("collider")
	if obstacle_collider is CharacterBody3D or obstacle_collider is Area3D:
		return JumpObstacleKind.NONE

	# Classify the exact asset BEFORE applying generic height rejection.
	var source_path: String = _get_obstacle_source_scene_path(obstacle_collider)
	var is_exact_large_guardrail: bool = LARGE_JUMP_OBSTACLE_SCENES.has(source_path)

	var clearance_height: float = large_obstacle_clearance_height if is_exact_large_guardrail else obstacle_clearance_height
	var clearance_distance: float = large_obstacle_check_distance if is_exact_large_guardrail else obstacle_check_distance

	var high_from := Vector3(global_position.x, feet_y + clearance_height, global_position.z)
	var high_to := high_from + facing_forward * (clearance_distance + 0.20)
	var high_query := PhysicsRayQueryParameters3D.create(high_from, high_to, collision_mask, exclude)
	if not world.intersect_ray(high_query).is_empty():
		# Still reject genuinely wall-height geometry. The dedicated guard-rail
		# clearance ray is simply higher than the generic crate/chest ray.
		return JumpObstacleKind.NONE

	var low_hit_position: Vector3 = obstacle_hit.get(
		"position",
		global_position + facing_forward * clearance_distance
	)

	# Confirm a floor/landing surface beyond the obstacle.
	var landing_forward_distance: float = 1.05 if is_exact_large_guardrail else 0.70
	var landing_ray_height: float = 1.55 if is_exact_large_guardrail else 0.82
	var landing_from := low_hit_position + facing_forward * landing_forward_distance + Vector3.UP * landing_ray_height
	var landing_to := landing_from + Vector3.DOWN * 3.00
	var landing_query := PhysicsRayQueryParameters3D.create(landing_from, landing_to, collision_mask, exclude)
	var landing_hit: Dictionary = world.intersect_ray(landing_query)
	if landing_hit.is_empty():
		return JumpObstacleKind.NONE

	var landing_position: Vector3 = landing_hit["position"]
	if landing_position.y < feet_y - 1.15 or landing_position.y > feet_y + 0.85:
		return JumpObstacleKind.NONE

	if is_exact_large_guardrail:
		return JumpObstacleKind.LARGE
	if SMALL_JUMP_OBSTACLE_SCENES.has(source_path):
		return JumpObstacleKind.SMALL
	return JumpObstacleKind.GENERIC


func _get_obstacle_source_scene_path(collider: Object) -> String:
	if not collider is Node:
		return ""
	var current: Node = collider as Node
	while current != null:
		if not current.scene_file_path.is_empty():
			return current.scene_file_path
		current = current.get_parent()
	return ""

func _begin_jump_camera(obstacle_kind: JumpObstacleKind) -> void:
	jump_state = JumpMovementState.OBSTACLE_JUMP if obstacle_kind != JumpObstacleKind.NONE else JumpMovementState.NORMAL_JUMP
	active_jump_obstacle_kind = obstacle_kind
	active_jump_was_obstacle = obstacle_kind != JumpObstacleKind.NONE
	jump_phase_time = 0.0
	landing_intensity = 0.0
	hard_landing_active = false
	hard_landing_strength = 0.0
	hard_landing_impact_speed = 0.0
	jump_horizontal_speed_at_takeoff = Vector2(velocity.x, velocity.z).length()
	# Push-off: short FOV kick and the hands lift before they lag in the air.
	jump_fov_velocity += jump_takeoff_fov_kick * jump_fov_speed * 2.2
	jump_weapon_position_velocity += Vector3(0.0, jump_takeoff_weapon_lift, -0.06)
	jump_weapon_rotation_velocity.x += deg_to_rad(30.0) * jump_takeoff_weapon_lift / 0.22
	_play_jump_effort_for_obstacle(obstacle_kind)

func _begin_falling_camera() -> void:
	if jump_state == JumpMovementState.FALLING or jump_state == JumpMovementState.LANDING:
		return
	jump_state = JumpMovementState.FALLING
	jump_phase_time = 0.0

func _begin_landing_camera(landing_speed: float) -> void:
	if not landing_camera_enabled:
		return

	jump_state = JumpMovementState.LANDING
	jump_phase_time = 0.0

	# The authoritative input is the downward velocity captured BEFORE
	# move_and_slide() resolves floor contact.
	hard_landing_impact_speed = maxf(landing_speed, 0.0)
	landing_intensity = clampf(
		inverse_lerp(landing_min_speed, 9.0, hard_landing_impact_speed),
		0.0,
		1.0
	)

	var obstacle_double_jump_trigger: bool = (
		hard_landing_from_obstacle_double_jump
		and obstacle_double_jump_active
		and active_jump_was_obstacle
	)
	var severe_fall_trigger: bool = (
		hard_landing_from_falls_enabled
		and hard_landing_impact_speed >= hard_landing_fall_trigger_speed
	)

	hard_landing_active = obstacle_double_jump_trigger or severe_fall_trigger
	hard_landing_strength = 0.0

	if hard_landing_active:
		var normalized: float = clampf(
			inverse_lerp(
				hard_landing_min_speed,
				hard_landing_max_reference_speed,
				hard_landing_impact_speed
			),
			0.0,
			1.0
		)
		normalized = pow(normalized, hard_landing_strength_curve_power)

		# An obstacle double-jump is intentionally a committed athletic landing,
		# but impact speed still determines how strong it becomes above this floor.
		if obstacle_double_jump_trigger:
			normalized = maxf(normalized, hard_landing_min_obstacle_strength)

		hard_landing_strength = clampf(normalized, 0.0, 1.0)

		# Feedback is synchronized to the exact confirmed landing frame.
		if _is_mobile_ui() and haptics_enabled and hard_landing_strength >= hard_landing_haptic_threshold:
			Input.vibrate_handheld(
				int(lerpf(30.0, 58.0, hard_landing_strength)),
				lerpf(0.48, 0.82, hard_landing_strength)
			)

		_play_hard_landing_grunt(hard_landing_strength)
	else:
		# Keep the existing restrained normal-landing haptic behavior.
		if _is_mobile_ui() and haptics_enabled and landing_intensity > 0.18:
			Input.vibrate_handheld(
				int(lerpf(18.0, 42.0, landing_intensity)),
				lerpf(0.25, 0.62, landing_intensity)
			)
	_apply_landing_impulse()


## The landing profile targets are only held for ~70 ms, which on their own
## let the springs reach a fraction of the drop. Impact weight is an impulse on
## the landing frame; the hands' softer spring peaks a beat after the camera.
func _apply_landing_impulse() -> void:
	var weight: float = lerpf(0.55, 1.1, landing_intensity)
	var drop: float = landing_camera_drop
	var pitch_degrees: float = landing_pitch_degrees
	var fov_compress: float = landing_fov_compression
	var weapon_drop: float = landing_weapon_drop
	var weapon_pitch_degrees: float = 3.0
	var camera_omega: float = sqrt(landing_spring_strength)
	var weapon_omega: float = sqrt(92.0)
	if hard_landing_active:
		weight = lerpf(0.75, 1.2, hard_landing_strength)
		drop = hard_landing_camera_drop
		pitch_degrees = hard_landing_pitch_strength
		fov_compress = hard_landing_fov_compression
		weapon_drop = hard_landing_weapon_drop
		weapon_pitch_degrees = hard_landing_weapon_pitch
		camera_omega = sqrt(hard_landing_spring_strength)
		weapon_omega = sqrt(hard_landing_weapon_spring_strength)
	elif active_jump_obstacle_kind == JumpObstacleKind.LARGE:
		drop = large_jump_landing_drop
		camera_omega = sqrt(large_jump_camera_spring_strength)
		weapon_omega = sqrt(105.0)
	# A hard landing is an order of magnitude more weight, not a scaled hop.
	var hard: float = 1.0 if hard_landing_active else 0.0
	jump_camera_velocity.y -= drop * weight * camera_omega * lerpf(1.35, 2.5, hard)
	jump_rotation_velocity.x -= deg_to_rad(pitch_degrees) * weight * camera_omega * lerpf(1.9, 2.4, hard)
	jump_fov_velocity -= fov_compress * weight * jump_fov_speed * lerpf(1.6, 2.4, hard)
	jump_weapon_position_velocity.y -= weapon_drop * weight * weapon_omega * lerpf(1.2, 1.6, hard)
	jump_weapon_rotation_velocity.x -= deg_to_rad(weapon_pitch_degrees) * weight * weapon_omega * lerpf(1.2, 1.6, hard)


func _play_hard_landing_grunt(strength: float) -> void:
	if strength < hard_landing_grunt_threshold:
		return
	if large_obstacle_jump_streams.is_empty() or jump_effort_audio == null:
		return
	if randf() > hard_landing_grunt_chance:
		return

	var now_msec: int = Time.get_ticks_msec()
	if now_msec - hard_landing_last_grunt_msec < int(hard_landing_grunt_cooldown * 1000.0):
		return
	hard_landing_last_grunt_msec = now_msec

	# Reuse the existing short LARGE exertion set for now; randomized with the
	# same anti-repetition behavior as obstacle jump vocals.
	var index: int = randi_range(0, large_obstacle_jump_streams.size() - 1)
	if large_obstacle_jump_streams.size() > 1 and index == last_large_jump_voice_index:
		index = (index + 1 + randi_range(0, large_obstacle_jump_streams.size() - 2)) % large_obstacle_jump_streams.size()

	last_large_jump_voice_index = index
	jump_effort_audio.stream = large_obstacle_jump_streams[index]
	jump_effort_audio.volume_db = -5.5
	jump_effort_audio.pitch_scale = randf_range(0.94, 1.02)
	jump_effort_audio.play()


func _finish_landing_camera() -> void:
	jump_state = JumpMovementState.GROUNDED if is_on_floor() else JumpMovementState.FALLING
	active_jump_was_obstacle = false
	active_jump_obstacle_kind = JumpObstacleKind.NONE
	obstacle_double_jump_active = false
	hard_landing_active = false
	hard_landing_strength = 0.0
	hard_landing_impact_speed = 0.0
	jump_phase_time = 0.0
	landing_intensity = 0.0

func _kill_jump_tweens() -> void:
	# Kept under the existing function name because death/reset code already calls
	# it. The new camera is spring-driven, so resetting means clearing spring state.
	jump_camera_velocity = Vector3.ZERO
	jump_rotation_velocity = Vector3.ZERO
	jump_fov_velocity = 0.0
	jump_fov_offset = 0.0
	jump_weapon_position_velocity = Vector3.ZERO
	jump_weapon_rotation_velocity = Vector3.ZERO

func _spring_vector3(
	current: Vector3,
	current_velocity: Vector3,
	target: Vector3,
	strength: float,
	damping: float,
	delta: float
) -> Array:
	var acceleration_value: Vector3 = (target - current) * strength - current_velocity * damping
	current_velocity += acceleration_value * delta
	current += current_velocity * delta
	return [current, current_velocity]

func _spring_float(
	current: float,
	current_velocity: float,
	target: float,
	strength: float,
	damping: float,
	delta: float
) -> Vector2:
	var acceleration_value: float = (target - current) * strength - current_velocity * damping
	current_velocity += acceleration_value * delta
	current += current_velocity * delta
	return Vector2(current, current_velocity)

func _update_jump_camera_effects(delta: float, horizontal_speed: float) -> void:
	jump_phase_time += delta

	var position_target := Vector3.ZERO
	var rotation_target := Vector3.ZERO
	var fov_target: float = 0.0
	var weapon_position_target := Vector3.ZERO
	var weapon_rotation_target := Vector3.ZERO

	var is_large: bool = active_jump_obstacle_kind == JumpObstacleKind.LARGE
	var is_small: bool = active_jump_obstacle_kind == JumpObstacleKind.SMALL
	var running_jump: bool = maxf(jump_horizontal_speed_at_takeoff, horizontal_speed) >= walk_speed * 0.72

	# ------------------------------------------------------------------
	# HARD LANDING — obstacle double-jump landing or optional severe fall.
	#
	# This REPLACES the normal landing profile for the landing frame sequence;
	# it does not stack another full landing animation on top.
	# ------------------------------------------------------------------
	if hard_landing_active and jump_state == JumpMovementState.LANDING:
		var strength: float = hard_landing_strength
		var drop: float = clampf(
			hard_landing_camera_drop * lerpf(0.72, 1.22, strength),
			0.0,
			hard_landing_max_camera_drop
		)
		var rebound: float = hard_landing_rebound * lerpf(0.70, 1.35, strength)
		var pitch_deg: float = minf(
			hard_landing_pitch_strength * lerpf(0.72, 1.20, strength),
			hard_landing_max_pitch
		)
		var lateral_speed: float = velocity.dot(global_transform.basis.x)
		var roll_deg: float = clampf(
			-lateral_speed / maxf(sprint_speed, 0.01) * hard_landing_roll_strength,
			-hard_landing_roll_strength,
			hard_landing_roll_strength
		)

		# Phase 1: sharp compression. Reach most of the drop within ~70 ms.
		if jump_phase_time < 0.070:
			var alpha: float = clampf(jump_phase_time / 0.070, 0.0, 1.0)
			var compression: float = sin(alpha * PI * 0.5)
			# Knees buckle: the view drops and nods DOWN hard (negative pitch).
			position_target.y = -drop * compression
			position_target.z = 0.010 * strength
			rotation_target.x = -deg_to_rad(pitch_deg * compression)
			rotation_target.z = deg_to_rad(roll_deg * compression)

			weapon_position_target = Vector3(
				0.0,
				-hard_landing_weapon_drop * lerpf(0.72, 1.10, strength) * compression,
				0.016 * strength
			)
			weapon_rotation_target = Vector3(
				-deg_to_rad(hard_landing_weapon_pitch * lerpf(0.72, 1.12, strength) * compression),
				0.0,
				deg_to_rad(roll_deg * 2.2 * compression)
			)

			# FOV compresses with the impact; unmistakable but still a camera, not a zoom.
			fov_target = -hard_landing_fov_compression * strength * compression

		# Phase 2/3: single upward rebound.
		elif jump_phase_time < 0.200:
			var alpha: float = clampf((jump_phase_time - 0.070) / 0.130, 0.0, 1.0)
			position_target.y = lerpf(-drop * 0.30, rebound, alpha)
			rotation_target.x = -deg_to_rad(lerpf(pitch_deg * 0.35, -0.18 * strength, alpha))
			rotation_target.z = deg_to_rad(lerpf(roll_deg * 0.30, 0.0, alpha))
			weapon_position_target = Vector3(
				0.0,
				lerpf(-hard_landing_weapon_drop * 0.35, hard_landing_weapon_rebound, alpha),
				0.0
			)
			weapon_rotation_target = Vector3(
				-deg_to_rad(lerpf(hard_landing_weapon_pitch * 0.35, -0.5 * strength, alpha)),
				0.0,
				0.0
			)
			fov_target = lerpf(-hard_landing_fov_compression * strength * 0.25, 0.0, alpha)

		# Phase 4: settle naturally toward zero through the spring.
		else:
			position_target = Vector3.ZERO
			rotation_target = Vector3.ZERO
			weapon_position_target = Vector3.ZERO
			weapon_rotation_target = Vector3.ZERO
			fov_target = 0.0

		if jump_phase_time >= hard_landing_recovery_time:
			_finish_landing_camera()

	elif is_large and (
		jump_state == JumpMovementState.OBSTACLE_JUMP
		or jump_state == JumpMovementState.FALLING
		or jump_state == JumpMovementState.LANDING
	):
		if jump_state == JumpMovementState.OBSTACLE_JUMP:
			if jump_phase_time <= jump_takeoff_duration:
				# 0.00–~0.07 s: tiny leg compression. Barely visible.
				var takeoff_alpha: float = clampf(jump_phase_time / maxf(jump_takeoff_duration, 0.001), 0.0, 1.0)
				var compression_shape: float = sin(takeoff_alpha * PI)
				position_target.y = -large_jump_takeoff_dip * compression_shape
				position_target.z = 0.0
				rotation_target.x = deg_to_rad(0.22 * compression_shape)

				weapon_position_target.y = -large_jump_viewmodel_drop * 0.70 * compression_shape
				weapon_rotation_target.x = deg_to_rad(1.2 * compression_shape)
			else:
				# REAL ascent: strongest head lag immediately after takeoff,
				# naturally disappearing as vertical velocity approaches the apex.
				var launch_speed: float = maxf(large_obstacle_jump_velocity, 0.001)
				var upward_ratio: float = clampf(velocity.y / launch_speed, 0.0, 1.0)
				var speed_ratio: float = clampf(horizontal_speed / maxf(walk_speed, 0.001), 0.0, 1.25)

				position_target.y = -large_jump_ascent_lag * upward_ratio
				position_target.z = -large_jump_forward_offset * speed_ratio * (1.0 - upward_ratio * 0.35)

				# Less than half a degree of additive forward lean.
				var forward_pitch: float = large_jump_forward_pitch_degrees * speed_ratio * (1.0 - upward_ratio * 0.45)
				rotation_target.x = deg_to_rad(-forward_pitch)
				rotation_target.z = deg_to_rad(clampf(-smoothed_move_input.x * 0.10, -0.10, 0.10))

				# Weapon has its own tiny inertia and is NOT welded to the camera.
				weapon_position_target = Vector3(
					0.0,
					-large_jump_viewmodel_drop * lerpf(0.55, 0.20, 1.0 - upward_ratio),
					0.008
				)
				weapon_rotation_target = Vector3(
					deg_to_rad(1.8 * upward_ratio),
					0.0,
					deg_to_rad(clampf(-smoothed_move_input.x * 0.45, -0.45, 0.45))
				)

				# Very small speed-based FOV breathing only.
				if running_jump:
					fov_target = jump_fov_amount * 0.55 * speed_ratio

		elif jump_state == JumpMovementState.FALLING:
			# Descent is driven by actual downward speed. The body drops beneath
			# the head by ~1–2 cm, then this returns toward neutral before impact.
			var expected_fall_speed: float = maxf(large_obstacle_jump_velocity, 0.001)
			var downward_ratio: float = clampf(absf(minf(velocity.y, 0.0)) / expected_fall_speed, 0.0, 1.0)
			var speed_ratio: float = clampf(horizontal_speed / maxf(walk_speed, 0.001), 0.0, 1.25)

			# Peak lag in early/mid descent; reduce it again near faster impact.
			var descent_shape: float = sin(clampf(downward_ratio, 0.0, 1.0) * PI)
			position_target.y = large_jump_descent_lag * descent_shape
			position_target.z = -large_jump_forward_offset * 0.45 * speed_ratio

			# Do not force the player to look at the ground.
			rotation_target.x = deg_to_rad(0.16 * descent_shape)
			rotation_target.z = deg_to_rad(clampf(-smoothed_move_input.x * 0.06, -0.06, 0.06))

			weapon_position_target = Vector3(0.0, -0.010 * descent_shape, 0.005)
			weapon_rotation_target = Vector3(deg_to_rad(0.7 * descent_shape), 0.0, 0.0)

			if running_jump:
				fov_target = jump_fov_amount * 0.22 * speed_ratio

		elif jump_state == JumpMovementState.LANDING:
			# Landing uses REAL impact detection from the physics process.
			# Fast compression -> ONE tiny rebound -> settle.
			var impact_scale: float = lerpf(0.82, 1.08, landing_intensity)
			var drop: float = minf(large_jump_landing_drop * impact_scale, 0.070)

			if jump_phase_time < 0.075:
				var alpha: float = clampf(jump_phase_time / 0.075, 0.0, 1.0)
				position_target.y = -drop * sin(alpha * PI * 0.5)
				position_target.z = 0.006
				rotation_target.x = -deg_to_rad(lerpf(0.9, 1.5, landing_intensity))
				weapon_position_target = Vector3(0.0, -0.042 * impact_scale, 0.014)
				weapon_rotation_target = Vector3(-deg_to_rad(3.2 * impact_scale), 0.0, deg_to_rad(0.6))
				fov_target = -landing_fov_compression * lerpf(1.0, 1.5, landing_intensity)
			elif jump_phase_time < 0.145:
				var alpha: float = clampf((jump_phase_time - 0.075) / 0.070, 0.0, 1.0)
				position_target.y = lerpf(-drop * 0.18, large_jump_landing_rebound, alpha)
				position_target.z = 0.0
				rotation_target.x = -deg_to_rad(lerpf(0.35, -0.12, alpha))
				weapon_position_target = Vector3(0.0, lerpf(-0.014, 0.004, alpha), 0.0)
				weapon_rotation_target = Vector3(-deg_to_rad(lerpf(1.0, -0.3, alpha)), 0.0, 0.0)
			else:
				position_target = Vector3.ZERO
				rotation_target = Vector3.ZERO
				weapon_position_target = Vector3.ZERO
				weapon_rotation_target = Vector3.ZERO

			if jump_phase_time >= 0.23:
				_finish_landing_camera()

	else:
		# ------------------------------------------------------------------
		# Existing normal/small-obstacle behavior, kept restrained.
		# ------------------------------------------------------------------
		match jump_state:
			JumpMovementState.NORMAL_JUMP, JumpMovementState.OBSTACLE_JUMP:
				if jump_phase_time <= jump_takeoff_duration:
					var dip_scale: float = 1.05 if is_small else 1.0
					position_target.y = -jump_takeoff_dip * dip_scale
					rotation_target.x = deg_to_rad(0.28)
					weapon_position_target.y = -viewmodel_jump_lag * 0.85
					weapon_rotation_target.x = deg_to_rad(1.7)
				else:
					var ascent_progress: float = clampf(
						(jump_phase_time - jump_takeoff_duration) / 0.18,
						0.0,
						1.0
					)
					position_target.y = -airborne_camera_lag * (1.0 - ascent_progress)
					position_target.z = lerpf(0.0, -0.010 if is_small else -0.004, ascent_progress)
					rotation_target.x = deg_to_rad(-(0.42 if is_small else 0.22) * ascent_progress)
					weapon_position_target = Vector3(0.0, -viewmodel_jump_lag * 0.55, 0.006)
					weapon_rotation_target = Vector3(deg_to_rad(1.8), 0.0, deg_to_rad(0.25))

				if running_jump:
					fov_target = jump_fov_amount * 0.45

			JumpMovementState.FALLING:
				position_target.y = airborne_camera_lag * 0.70
				rotation_target.x = deg_to_rad(0.14)
				weapon_position_target = Vector3(0.0, -0.008, 0.005)
				weapon_rotation_target = Vector3(deg_to_rad(0.6), 0.0, 0.0)

			JumpMovementState.LANDING:
				var landing_drop: float = landing_camera_drop * lerpf(0.80, 1.15, landing_intensity)

				# Weight: drop + nod down + FOV compress. The hands use a softer
				# spring below, so they arrive a beat after the camera.
				if jump_phase_time < 0.085:
					position_target = Vector3(0.0, -landing_drop, 0.008)
					rotation_target.x = -deg_to_rad(landing_pitch_degrees * lerpf(0.7, 1.25, landing_intensity))
					weapon_position_target = Vector3(0.0, -landing_weapon_drop * lerpf(0.7, 1.15, landing_intensity), 0.012)
					weapon_rotation_target = Vector3(-deg_to_rad(lerpf(2.2, 4.0, landing_intensity)), 0.0, deg_to_rad(0.5))
					fov_target = -landing_fov_compression * lerpf(0.7, 1.25, landing_intensity)
				elif jump_phase_time < 0.160:
					position_target = Vector3(0.0, lerpf(0.006, 0.010, landing_intensity), 0.0)
					rotation_target.x = deg_to_rad(0.18)
					weapon_position_target = Vector3(0.0, 0.006, 0.0)
					weapon_rotation_target = Vector3(deg_to_rad(0.5), 0.0, 0.0)
				else:
					position_target = Vector3.ZERO
					rotation_target = Vector3.ZERO
					weapon_position_target = Vector3.ZERO
					weapon_rotation_target = Vector3.ZERO

				if jump_phase_time >= landing_recovery_speed:
					_finish_landing_camera()

			_:
				position_target = Vector3.ZERO
				rotation_target = Vector3.ZERO
				weapon_position_target = Vector3.ZERO
				weapon_rotation_target = Vector3.ZERO

	# Airborne look stays restrained; landings get their own (larger) limit.
	var max_pitch_rad: float = deg_to_rad(
		hard_landing_max_pitch if jump_state == JumpMovementState.LANDING else maximum_jump_camera_pitch
	)
	rotation_target.x = clampf(rotation_target.x, -max_pitch_rad, max_pitch_rad)

	var spring_strength: float
	var spring_damping: float
	if hard_landing_active and jump_state == JumpMovementState.LANDING:
		spring_strength = hard_landing_spring_strength
		spring_damping = hard_landing_spring_damping
	elif is_large:
		spring_strength = large_jump_camera_spring_strength
		spring_damping = large_jump_camera_spring_damping
	elif jump_state == JumpMovementState.LANDING:
		spring_strength = landing_spring_strength
		spring_damping = landing_spring_damping
	else:
		spring_strength = jump_spring_strength
		spring_damping = jump_spring_damping

	# Substep springs so camera feel remains stable at 30/60/120+ FPS.
	var step_count: int = maxi(1, int(ceil(delta / (1.0 / 60.0))))
	var step_delta: float = delta / float(step_count)
	for _step in range(step_count):
		var position_result: Array = _spring_vector3(
			jump_offset.position,
			jump_camera_velocity,
			position_target,
			spring_strength,
			spring_damping,
			step_delta
		)
		jump_offset.position = position_result[0] as Vector3
		jump_camera_velocity = position_result[1] as Vector3

		var rotation_result: Array = _spring_vector3(
			jump_offset.rotation,
			jump_rotation_velocity,
			rotation_target,
			spring_strength,
			spring_damping,
			step_delta
		)
		jump_offset.rotation = rotation_result[0] as Vector3
		jump_rotation_velocity = rotation_result[1] as Vector3

		var weapon_spring_strength: float = hard_landing_weapon_spring_strength if hard_landing_active else (105.0 if is_large else 92.0)
		var weapon_spring_damping: float = hard_landing_weapon_spring_damping if hard_landing_active else (19.0 if is_large else 16.5)
		var weapon_position_result: Array = _spring_vector3(
			jump_weapon_position_offset,
			jump_weapon_position_velocity,
			weapon_position_target,
			weapon_spring_strength,
			weapon_spring_damping,
			step_delta
		)
		jump_weapon_position_offset = weapon_position_result[0] as Vector3
		jump_weapon_position_velocity = weapon_position_result[1] as Vector3

		var weapon_rotation_result: Array = _spring_vector3(
			jump_weapon_rotation_offset,
			jump_weapon_rotation_velocity,
			weapon_rotation_target,
			weapon_spring_strength * 0.94,
			weapon_spring_damping,
			step_delta
		)
		jump_weapon_rotation_offset = weapon_rotation_result[0] as Vector3
		jump_weapon_rotation_velocity = weapon_rotation_result[1] as Vector3

	var fov_result: Vector2 = _spring_float(
		jump_fov_offset,
		jump_fov_velocity,
		fov_target,
		jump_fov_speed * jump_fov_speed,
		jump_fov_speed * 2.0,
		delta
	)
	jump_fov_offset = fov_result.x
	jump_fov_velocity = fov_result.y

func _physics_process(delta: float) -> void:
	_layout_mobile_action_buttons()
	aim_hold_timer = maxf(0.0, aim_hold_timer - delta)
	damage_voice_cooldown = maxf(0.0, damage_voice_cooldown - delta)
	_update_health_regeneration(delta)
	_update_low_health_audio()
	_update_low_health_feedback(delta)
	if not game_over and not get_tree().paused:
		elapsed_time = RunManager.elapsed_time
		stopwatch_refresh_accum += delta
		if stopwatch_refresh_accum >= 0.10:
			stopwatch_refresh_accum = 0.0
			_update_stopwatch_ui()
	if death_sequence_active:
		velocity = Vector3.ZERO
		_update_extra_weapons_blocked()
		return
	if game_over or get_tree().paused or weapon_choice_active:
		velocity = Vector3.ZERO
		_update_extra_weapons_blocked()
		return
	if encounter_started:
		survival_time += delta

	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if mobile_move_input.length() > 0.01:
		input_vector = mobile_move_input

	# Smooth the player's intent a little instead of snapping instantly between
	# full-left/full-right. This is subtle but removes the prototype/indie feel.
	smoothed_move_input = smoothed_move_input.lerp(input_vector, minf(1.0, delta * 14.0))
	if input_vector.length() < 0.02:
		smoothed_move_input = smoothed_move_input.lerp(Vector2.ZERO, minf(1.0, delta * 20.0))

	var forward: Vector3 = -global_transform.basis.z
	var right: Vector3 = global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	var direction: Vector3 = (right * smoothed_move_input.x + forward * -smoothed_move_input.y)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	var sprint_requested_now: bool = (
		(Input.is_action_pressed("sprint") or mobile_sprint)
		and not is_reloading
		and not sprint_suppressed_for_combat
		and not _minigun_barrels_up()
	)
	if sprint_suppressed_for_combat and not Input.is_action_pressed("sprint") and not mobile_sprint:
		sprint_suppressed_for_combat = false
	var sprinting: bool = _update_sprint_stamina(
		delta,
		sprint_requested_now,
		input_vector.length() > 0.35,
		is_on_floor()
	)
	if sprint_exit_fire_pending and not sprinting:
		sprint_exit_fire_pending = false
		_begin_fire_after_sprint_exit()
	if sprinting and crouch_active:
		crouch_active = false
	var target_speed: float = sprint_speed if sprinting else walk_speed
	if _minigun_barrels_up():
		target_speed = walk_speed * MINIGUN_WALK_MULTIPLIER
	if crouch_active:
		target_speed *= CROUCH_SPEED_MULTIPLIER
	var target_velocity: Vector2 = Vector2(direction.x, direction.z) * target_speed
	var horizontal_velocity: Vector2 = Vector2(velocity.x, velocity.z)
	var on_floor_before_move: bool = is_on_floor()

	if on_floor_before_move:
		var movement_rate: float = acceleration if target_velocity.length() > horizontal_velocity.length() else deceleration
		horizontal_velocity = horizontal_velocity.move_toward(target_velocity, movement_rate * delta)
	else:
		# Preserve jump momentum. Air input can steer, but releasing the stick does
		# not instantly brake the player in midair.
		if input_vector.length() > 0.05:
			horizontal_velocity = horizontal_velocity.move_toward(
				target_velocity,
				acceleration * air_control * delta
			)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y

	if jump_requested and on_floor_before_move:
		active_jump_obstacle_kind = _detect_obstacle_jump()
		active_jump_was_obstacle = active_jump_obstacle_kind != JumpObstacleKind.NONE
		double_jump_used = false
		double_jump_requested = false
		obstacle_double_jump_active = false
		hard_landing_active = false
		hard_landing_strength = 0.0
		hard_landing_impact_speed = 0.0
		jump_started_msec = Time.get_ticks_msec()

		if active_jump_obstacle_kind == JumpObstacleKind.LARGE:
			velocity.y = large_obstacle_jump_velocity
		elif active_jump_was_obstacle:
			velocity.y = obstacle_jump_velocity
		else:
			velocity.y = jump_velocity

		_begin_jump_camera(active_jump_obstacle_kind)
		_mobile_jump_feedback()
		jump_requested = false
		on_floor_before_move = false
		airborne_time = 0.0
	elif jump_requested:
		jump_requested = false

	if double_jump_requested and not on_floor_before_move and not double_jump_used:
		double_jump_requested = false
		double_jump_used = true

		# IMPORTANT: hard landing eligibility is ONLY recorded when this second
		# jump belongs to a jump that originally detected an obstacle.
		# Double-jumping normally in open space does not set this flag.
		if active_jump_was_obstacle:
			obstacle_double_jump_active = true

		velocity.y = maxf(velocity.y, double_jump_vertical_speed)
		# Tiny physical-feeling second push; does not restart the whole jump camera.
		jump_camera_velocity.y -= 0.34
		jump_weapon_position_velocity.y -= 0.16
		jump_fov_velocity += 0.55

	if not on_floor_before_move:
		var gravity_multiplier: float = jump_up_gravity_multiplier if velocity.y > 0.0 else jump_fall_gravity_multiplier
		velocity.y -= gravity * gravity_multiplier * delta
	else:
		velocity.y = -0.5
	var vertical_velocity_before_move: float = velocity.y
	move_and_slide()

	var on_floor_after_move: bool = is_on_floor()
	if not on_floor_after_move:
		airborne_time += delta
		if jump_state == JumpMovementState.GROUNDED and velocity.y < -0.05:
			active_jump_was_obstacle = false
			active_jump_obstacle_kind = JumpObstacleKind.NONE
			obstacle_double_jump_active = false
			_begin_falling_camera()
		if velocity.y <= 0.05 and (
			jump_state == JumpMovementState.NORMAL_JUMP
			or jump_state == JumpMovementState.OBSTACLE_JUMP
		):
			_begin_falling_camera()
	else:
		double_jump_used = false
		double_jump_requested = false
		if not was_on_floor and airborne_time > 0.05:
			_begin_landing_camera(absf(vertical_velocity_before_move))
		airborne_time = 0.0
	was_on_floor = on_floor_after_move

	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	_update_jump_camera_effects(delta, horizontal_speed)
	_update_melee_camera_effects(delta)
	movement_speed_ratio = clampf(horizontal_speed / walk_speed, 0.0, 1.2)
	var moving: bool = horizontal_speed > 0.16 and is_on_floor()

	# Distance-driven FPS gait. The camera now reacts to actual meters travelled
	# rather than a timer, so slow movement produces slow steps and stopping
	# immediately settles instead of looking like a floating sine-wave camera.
	var target_gait_blend: float = clampf(horizontal_speed / walk_speed, 0.0, 1.0) if moving else 0.0
	gait_blend = move_toward(gait_blend, target_gait_blend, delta * (5.5 if moving else 8.5))

	if moving:
		var stride_length: float = 1.58 if not sprinting else 1.92
		gait_phase = fmod(gait_phase + (horizontal_speed * delta / stride_length) * TAU, TAU)
	_update_player_footsteps(moving, sprinting)

	# Two heel strikes happen during one full left/right stride. Vertical drop and
	# downward nod share the same heel_wave so the camera lands with the audio.
	var double_phase: float = gait_phase * 2.0
	var heel_wave: float = 0.5 - 0.5 * cos(double_phase)
	var walk_gait_scale: float = lerpf(1.0, 0.45, sprint_blend)
	var vertical_drop: float = -pow(heel_wave, 2.1) * walk_camera_vertical_drop * gait_blend * walk_gait_scale
	var lateral_weight: float = sin(gait_phase) * walk_camera_lateral_shift * gait_blend * walk_gait_scale
	var fore_aft: float = cos(double_phase) * walk_camera_forward_shift * gait_blend * walk_gait_scale

	# Inertial lean when accelerating/braking. This gives the player a body with
	# mass instead of a camera sliding at constant height.
	var current_hvel := Vector2(velocity.x, velocity.z)
	var local_forward_speed: float = current_hvel.dot(Vector2(-global_transform.basis.z.x, -global_transform.basis.z.z))
	var previous_forward_speed: float = previous_horizontal_velocity.dot(Vector2(-global_transform.basis.z.x, -global_transform.basis.z.z))
	var forward_accel: float = (local_forward_speed - previous_forward_speed) / maxf(delta, 0.001)
	previous_horizontal_velocity = current_hvel
	var lean_target: float = clampf(-forward_accel * 0.10, -1.15, 1.15)
	acceleration_lean = lerpf(acceleration_lean, lean_target, minf(1.0, delta * 5.0))

	var gait_roll: float = sin(gait_phase) * deg_to_rad(walk_camera_roll_degrees) * gait_blend * walk_gait_scale
	# Sharp strafing inertia is handled by LateralInertiaOffset from ACTUAL
	# acceleration instead of directly tilting from input.
	var target_roll: float = gait_roll
	camera_roll = lerpf(camera_roll, target_roll, minf(1.0, delta * 12.0))

	_update_stair_camera(delta, horizontal_speed)
	var nod_target: float = (
		-heel_wave * deg_to_rad(walk_camera_pitch_degrees) * gait_blend * walk_gait_scale
		+ deg_to_rad(acceleration_lean)
		+ deg_to_rad(stair_camera_pitch_degrees)
	)
	camera_walk_pitch = lerpf(camera_walk_pitch, nod_target, minf(1.0, delta * 26.0))
	footstep_weapon_drop = move_toward(footstep_weapon_drop, 0.0, delta * 0.028)

	crouch_blend = move_toward(crouch_blend, 1.0 if crouch_active else 0.0, delta * 5.0)
	var target_pivot: Vector3 = Vector3(
		lateral_weight,
		base_camera_y + vertical_drop - CROUCH_CAMERA_DROP * smoothstep(0.0, 1.0, crouch_blend) + stair_camera_offset,
		fore_aft
	)
	# Lateral/fore-aft stay smooth. Height snaps onto the heel so the dip is
	# visible on the same frame the boot hits, instead of easing in late.
	var next_pivot: Vector3 = camera_pivot.position
	next_pivot.x = lerpf(next_pivot.x, target_pivot.x, minf(1.0, delta * 16.0))
	next_pivot.z = lerpf(next_pivot.z, target_pivot.z, minf(1.0, delta * 16.0))
	next_pivot.y = lerpf(next_pivot.y, target_pivot.y, minf(1.0, delta * 48.0))
	camera_pivot.position = next_pivot
	_consume_pending_footstep_impact()

	# Keep bob_time synchronized for the weapon gait, but the phase is now based on
	# distance travelled instead of elapsed time.
	bob_time = gait_phase

	_update_sprint_camera_effects(delta, horizontal_speed, is_on_floor())
	_update_lateral_camera_inertia(delta, horizontal_speed, is_on_floor())

	_apply_gyro_look(delta)
	_apply_aim_assist(delta)
	_update_recoil(delta)
	_update_reload(delta)
	_update_ads(delta, sprinting)
	var movement_fov: float = hip_fov
	var base_weapon_fov: float = lerpf(movement_fov, ads_fov, ads_blend)
	var fov_response: float = lerpf(5.5, 14.0, ads_blend)
	# Only the hip/ADS base is smoothed here. Every offset is already its own
	# spring (or heartbeat envelope), so they are added unsmoothed and a shot
	# or landing punch reads on the frame it happens.
	camera_base_fov = lerpf(camera_base_fov, base_weapon_fov, minf(1.0, delta * fov_response))
	camera.fov = clampf(
		camera_base_fov + sprint_fov_offset + jump_fov_offset + melee_fov_offset + recoil_fov_offset + low_health_fov_offset,
		ads_fov - 3.0,
		82.0
	)
	_update_weapon_float(delta, moving, sprinting)
	_update_viewmodel_animation(sprinting, delta)
	_update_ads_fire(delta, sprinting)
	_update_extra_weapons(delta, sprinting)
	_check_room2_auto_equip()
	_update_uzi_idle_alt(delta)


func _update_lateral_camera_inertia(delta: float, horizontal_speed: float, grounded: bool) -> void:
	if lateral_inertia_pivot == null:
		return

	if not lateral_inertia_enabled:
		lateral_camera_offset = move_toward(lateral_camera_offset, 0.0, delta * 0.20)
		lateral_roll_offset = move_toward(lateral_roll_offset, 0.0, delta * 0.20)
		lateral_yaw_offset = move_toward(lateral_yaw_offset, 0.0, delta * 0.20)
		lateral_inertia_pivot.position = Vector3(lateral_camera_offset, 0.0, 0.0)
		lateral_inertia_pivot.rotation = Vector3(0.0, lateral_yaw_offset, lateral_roll_offset)
		return

	# Actual body acceleration, never raw key/button state.
	var current_hvel := Vector3(velocity.x, 0.0, velocity.z)
	var raw_world_accel: Vector3 = (
		current_hvel - lateral_previous_horizontal_velocity
	) / maxf(delta, 0.001)
	lateral_previous_horizontal_velocity = current_hvel

	# Convert world acceleration into the player's local body space.
	var local_accel: Vector3 = global_transform.basis.inverse() * raw_world_accel
	var raw_lateral_accel: float = local_accel.x

	# Reject absurd one-frame contact-resolution spikes before visual smoothing.
	var physics_spike_limit: float = maxf(lateral_acceleration_reference * 2.8, 20.0)
	raw_lateral_accel = clampf(
		raw_lateral_accel,
		-physics_spike_limit,
		physics_spike_limit
	)

	# Exponential smoothing is frame-rate independent and affects ONLY visuals.
	var smooth_alpha: float = 1.0 - exp(-lateral_acceleration_smoothing * delta)
	lateral_smoothed_acceleration = lerpf(
		lateral_smoothed_acceleration,
		raw_lateral_accel,
		smooth_alpha
	)

	var filtered_accel: float = lateral_smoothed_acceleration
	if absf(filtered_accel) < lateral_acceleration_deadzone:
		filtered_accel = 0.0

	# Non-linear strength curve: mild strafes stay very subtle, while a genuine
	# left<->right reversal naturally approaches the clamp because actual
	# acceleration is much stronger.
	var normalized_strength: float = clampf(
		absf(filtered_accel) / maxf(lateral_acceleration_reference, 0.01),
		0.0,
		1.0
	)
	normalized_strength = smoothstep(0.0, 1.0, normalized_strength)

	var speed_ratio: float = clampf(
		horizontal_speed / maxf(sprint_speed, 0.01),
		0.0,
		1.0
	)
	var speed_multiplier: float = lerpf(
		lateral_walk_multiplier,
		lateral_sprint_multiplier,
		speed_ratio
	)
	var airborne_multiplier: float = 1.0 if grounded else lateral_airborne_multiplier
	var visual_strength: float = normalized_strength * speed_multiplier * airborne_multiplier

	var direction_sign: float = signf(filtered_accel)

	# Head inertia goes OPPOSITE the body's acceleration.
	# Body accelerates left (negative local X) -> camera target goes right.
	var target_x: float = -direction_sign * lateral_position_strength * visual_strength
	var target_roll_deg: float = -direction_sign * lateral_roll_strength * visual_strength
	var target_yaw_deg: float = -direction_sign * lateral_yaw_strength * visual_strength

	target_x = clampf(target_x, -lateral_max_position, lateral_max_position)
	target_roll_deg = clampf(target_roll_deg, -lateral_max_roll, lateral_max_roll)
	target_yaw_deg = clampf(target_yaw_deg, -lateral_max_yaw, lateral_max_yaw)

	var target_roll: float = deg_to_rad(target_roll_deg)
	var target_yaw: float = deg_to_rad(target_yaw_deg)

	# Scalar damped springs allow existing momentum to interact with a new
	# opposite-direction target during rapid LEFT -> RIGHT -> LEFT changes.
	var step_count: int = maxi(1, int(ceil(delta / (1.0 / 60.0))))
	var step_delta: float = delta / float(step_count)

	for _step in range(step_count):
		var x_accel: float = (
			-lateral_spring_strength * (lateral_camera_offset - target_x)
			- lateral_spring_damping * lateral_camera_velocity
		)
		lateral_camera_velocity += x_accel * step_delta
		lateral_camera_offset += lateral_camera_velocity * step_delta

		var roll_accel: float = (
			-lateral_spring_strength * (lateral_roll_offset - target_roll)
			- lateral_spring_damping * lateral_roll_velocity
		)
		lateral_roll_velocity += roll_accel * step_delta
		lateral_roll_offset += lateral_roll_velocity * step_delta

		var yaw_accel: float = (
			-lateral_spring_strength * (lateral_yaw_offset - target_yaw)
			- lateral_spring_damping * lateral_yaw_velocity
		)
		lateral_yaw_velocity += yaw_accel * step_delta
		lateral_yaw_offset += lateral_yaw_velocity * step_delta

		# Weapon gets a slightly stronger/slower version so movement is felt more
		# in the arms than in the player's actual aim.
		var weapon_target_position := Vector3(
			clampf(
				target_x * weapon_lateral_inertia_strength,
				-weapon_lateral_max_position,
				weapon_lateral_max_position
			),
			0.0,
			0.0
		)
		var weapon_target_rotation := Vector3(
			0.0,
			deg_to_rad(clampf(
				target_yaw_deg * weapon_lateral_inertia_strength,
				-weapon_lateral_max_yaw,
				weapon_lateral_max_yaw
			)),
			deg_to_rad(clampf(
				target_roll_deg * weapon_lateral_inertia_strength,
				-weapon_lateral_max_roll,
				weapon_lateral_max_roll
			))
		)

		var wp_result: Array = _spring_vector3(
			lateral_weapon_position_offset,
			lateral_weapon_position_velocity,
			weapon_target_position,
			lateral_spring_strength * 0.82,
			lateral_spring_damping * 0.86,
			step_delta
		)
		lateral_weapon_position_offset = wp_result[0] as Vector3
		lateral_weapon_position_velocity = wp_result[1] as Vector3

		var wr_result: Array = _spring_vector3(
			lateral_weapon_rotation_offset,
			lateral_weapon_rotation_velocity,
			weapon_target_rotation,
			lateral_spring_strength * 0.78,
			lateral_spring_damping * 0.84,
			step_delta
		)
		lateral_weapon_rotation_offset = wr_result[0] as Vector3
		lateral_weapon_rotation_velocity = wr_result[1] as Vector3

	# Absolute comfort clamps. These remain in effect even if physics produces a
	# strange value at a wall/corner.
	lateral_camera_offset = clampf(
		lateral_camera_offset,
		-lateral_max_position,
		lateral_max_position
	)
	lateral_roll_offset = clampf(
		lateral_roll_offset,
		-deg_to_rad(lateral_max_roll),
		deg_to_rad(lateral_max_roll)
	)
	lateral_yaw_offset = clampf(
		lateral_yaw_offset,
		-deg_to_rad(lateral_max_yaw),
		deg_to_rad(lateral_max_yaw)
	)

	lateral_inertia_pivot.position = Vector3(lateral_camera_offset, 0.0, 0.0)
	lateral_inertia_pivot.rotation = Vector3(
		0.0,
		lateral_yaw_offset,
		lateral_roll_offset
	)


func _update_sprint_camera_effects(delta: float, horizontal_speed: float, grounded: bool) -> void:
	if sprint_effect_pivot == null or not sprint_camera_enabled:
		return

	var current_hvel := Vector2(velocity.x, velocity.z)
	var raw_accel := (current_hvel - sprint_prev_horizontal_velocity) / maxf(delta, 0.001)
	sprint_prev_horizontal_velocity = current_hvel

	# Raw CharacterBody3D acceleration can contain collision/slope spikes.
	# Exponential smoothing only affects visual input, never gameplay movement.
	var accel_alpha: float = 1.0 - exp(-sprint_acceleration_smoothing * delta)
	sprint_smoothed_acceleration = sprint_smoothed_acceleration.lerp(raw_accel, accel_alpha)

	var forward2 := Vector2(-global_transform.basis.z.x, -global_transform.basis.z.z).normalized()
	var forward_accel: float = sprint_smoothed_acceleration.dot(forward2)

	# Actual speed drives the sprint blend. Releasing Sprint or exhausting stamina
	# does not snap the visuals off; they fade as CharacterBody3D actually slows.
	var speed_start: float = walk_speed * 0.98
	var speed_full: float = maxf(sprint_speed * 0.90, speed_start + 0.01)
	var actual_speed_blend: float = clampf((horizontal_speed - speed_start) / (speed_full - speed_start), 0.0, 1.0)
	if not grounded:
		# Keep some forward momentum/FOV in the air, but remove footstep bob.
		actual_speed_blend *= 0.80

	# Exponential follow of actual speed: eases in, and coming off sprint the
	# carry settles smoothly instead of a linear ramp that stops dead.
	var blend_rate: float = sprint_blend_speed * (1.25 if actual_speed_blend > sprint_blend else 0.9)
	sprint_blend = lerpf(sprint_blend, actual_speed_blend, 1.0 - exp(-blend_rate * delta))
	if absf(sprint_blend - actual_speed_blend) < 0.002:
		sprint_blend = actual_speed_blend

	# Sprint start: the hands dip into the run on this frame's spring velocity
	# rather than teleporting to the tuck pose.
	if sprint_active and not sprint_was_active and not viewmodel_tune_enabled:
		sprint_weapon_position_velocity += Vector3(-0.08, -1.0, 0.25) * sprint_entry_weapon_dip
		sprint_weapon_rotation_velocity += Vector3(deg_to_rad(-22.0), 0.0, deg_to_rad(14.0)) * sprint_entry_weapon_dip
		sprint_pos_velocity.y -= 0.10 * sprint_entry_weapon_dip
	sprint_was_active = sprint_active

	var pos_target := Vector3.ZERO
	var rot_target := Vector3.ZERO

	# Acceleration/deceleration response is strongest while speed is changing,
	# then settles to a restrained sustained sprint posture.
	var accel_norm: float = clampf(forward_accel / maxf(acceleration, 0.01), -1.0, 1.0)

	# Godot local forward is -Z. Positive Z trails backward; negative Z biases forward.
	var accel_lag: float = 0.0
	var pitch_deg: float = 0.0
	if accel_norm > 0.03:
		accel_lag = sprint_acceleration_pos_lag * accel_norm
		pitch_deg = sprint_acceleration_lean * accel_norm
	elif accel_norm < -0.03:
		accel_lag = -sprint_deceleration_pos_lag * absf(accel_norm)
		pitch_deg = -sprint_deceleration_lean * absf(accel_norm)

	pos_target.z = (
		-sprint_forward_offset * sprint_blend
		+ accel_lag
	)
	pos_target.y = -sprint_camera_drop * sprint_blend
	# Lateral acceleration is handled by the dedicated LateralInertiaOffset.

	# Sustained lean into the run (view tips forward/down). The acceleration
	# head-lag above still leads it, so a sprint start reads as push-off.
	pitch_deg -= sprint_lean_degrees * sprint_blend
	var roll_deg: float = 0.0

	# Same heel-strike curve as walk/audio: peak dip at PI/2 and 3PI/2.
	# The extra thud impulse is applied in _consume_pending_footstep_impact so
	# sprint bob cannot drift onto a different rhythm than the footsteps.
	if grounded and sprint_blend > 0.02:
		var sprint_phase: float = gait_phase * sprint_bob_frequency
		var sprint_double_phase: float = sprint_phase * 2.0
		var heel: float = 0.5 - 0.5 * cos(sprint_double_phase)
		var impact_shape: float = pow(heel, 1.75)
		var rise_shape: float = (1.0 - heel) * 0.16
		pos_target.y += (-impact_shape + rise_shape) * sprint_bob_vertical * sprint_blend
		pos_target.x += sin(sprint_phase) * sprint_bob_horizontal * sprint_blend
		roll_deg += sin(sprint_phase) * sprint_roll_strength * sprint_blend
		sprint_last_gait_phase = gait_phase
	else:
		sprint_last_gait_phase = gait_phase

	# Hard clamps keep collisions/walls from producing an absurd visual kick.
	pos_target.x = clampf(pos_target.x, -0.020, 0.020)
	pos_target.y = clampf(pos_target.y, -0.045, 0.025)
	pos_target.z = clampf(pos_target.z, -max_sprint_position_offset, max_sprint_position_offset)
	rot_target.x = deg_to_rad(clampf(pitch_deg, -max_sprint_pitch, max_sprint_pitch))
	rot_target.z = deg_to_rad(clampf(roll_deg, -max_sprint_roll, max_sprint_roll))

	# Viewmodel inertia is intentionally stronger than camera inertia.
	var weapon_pos_target := Vector3(
		-pos_target.x * 0.55 + sprint_viewmodel_center_offset * sprint_blend,
		sprint_viewmodel_vertical_offset * sprint_blend - maxf(accel_norm, 0.0) * 0.006,
		sprint_viewmodel_depth_offset * sprint_blend + accel_lag * 0.35
	)
	var weapon_rot_target := Vector3(
		deg_to_rad(clampf(-0.40 * sprint_blend + accel_norm * 0.75, -1.8, 1.8)),
		0.0,
		deg_to_rad(clampf(-roll_deg * 1.35, -1.4, 1.4))
	)

	var step_count: int = maxi(1, int(ceil(delta / (1.0 / 60.0))))
	var step_delta: float = delta / float(step_count)
	for _step in range(step_count):
		var pos_result: Array = _spring_vector3(
			sprint_pos_offset,
			sprint_pos_velocity,
			pos_target,
			sprint_spring_strength,
			sprint_spring_damping,
			step_delta
		)
		sprint_pos_offset = pos_result[0] as Vector3
		sprint_pos_velocity = pos_result[1] as Vector3

		var rot_result: Array = _spring_vector3(
			sprint_rot_offset,
			sprint_rot_velocity,
			rot_target,
			sprint_spring_strength,
			sprint_spring_damping,
			step_delta
		)
		sprint_rot_offset = rot_result[0] as Vector3
		sprint_rot_velocity = rot_result[1] as Vector3

		# Slightly under-damped so the hands overshoot a touch as they settle
		# back to the combat carry when the sprint ends.
		var wp_result: Array = _spring_vector3(
			sprint_weapon_position_offset,
			sprint_weapon_position_velocity,
			weapon_pos_target,
			95.0,
			16.0,
			step_delta
		)
		sprint_weapon_position_offset = wp_result[0] as Vector3
		sprint_weapon_position_velocity = wp_result[1] as Vector3

		var wr_result: Array = _spring_vector3(
			sprint_weapon_rotation_offset,
			sprint_weapon_rotation_velocity,
			weapon_rot_target,
			92.0,
			15.5,
			step_delta
		)
		sprint_weapon_rotation_offset = wr_result[0] as Vector3
		sprint_weapon_rotation_velocity = wr_result[1] as Vector3

	sprint_effect_pivot.position = sprint_pos_offset
	sprint_effect_pivot.rotation = sprint_rot_offset

	var desired_fov: float = sprint_fov_increase * sprint_blend
	var fov_result: Vector2 = _spring_float(
		sprint_fov_offset,
		sprint_fov_velocity,
		desired_fov,
		sprint_fov_response * sprint_fov_response,
		sprint_fov_response * 2.0,
		delta
	)
	sprint_fov_offset = clampf(fov_result.x, 0.0, 6.0)
	sprint_fov_velocity = fov_result.y


func _create_viewmodel() -> void:
	# Keep the viewmodel as a child of the real gameplay camera. This preserves the
	# exact screen-space placement the user tuned and saved in earlier builds.
	viewmodel_root = Node3D.new()
	viewmodel_root.name = "FirstPersonWeapon"
	viewmodel_root.position = VIEWMODEL_POSITION
	camera.add_child(viewmodel_root)

	# Named anchors keep hip and ADS as explicit local transforms. The exported
	# ADS values can be nudged in the Player Inspector without editing this script.
	hip_anchor = Marker3D.new()
	hip_anchor.name = "HipAnchor"
	hip_anchor.position = VIEWMODEL_MODEL_OFFSET * VIEWMODEL_DEPTH_FACTOR
	hip_anchor.rotation_degrees = VIEWMODEL_DEFAULT_ROTATION
	viewmodel_root.add_child(hip_anchor)
	ads_anchor = Marker3D.new()
	ads_anchor.name = "ADSAnchor"
	ads_anchor.position = ads_position * VIEWMODEL_DEPTH_FACTOR
	ads_anchor.rotation_degrees = ads_rotation_degrees
	viewmodel_root.add_child(ads_anchor)

	pistol_viewmodel = PISTOL_VIEWMODEL_SCENE.instantiate()
	pistol_viewmodel.name = "PistolArmViewmodel"
	pistol_viewmodel.visible = false
	viewmodel_root.add_child(pistol_viewmodel)
	_prepare_viewmodel_geometry(pistol_viewmodel)

	uzi_viewmodel = UZI_VIEWMODEL_SCENE.instantiate()
	uzi_viewmodel.name = "UziArmViewmodel"
	uzi_viewmodel.visible = false
	viewmodel_root.add_child(uzi_viewmodel)
	_strip_imported_cameras(uzi_viewmodel)
	_prepare_viewmodel_geometry(uzi_viewmodel)
	_cache_uzi_sight_nodes()
	_style_uzi_character()

	shotgun_viewmodel = SHOTGUN_VIEWMODEL_SCENE.instantiate()
	shotgun_viewmodel.name = "ShotgunArmViewmodel"
	shotgun_viewmodel.visible = false
	viewmodel_root.add_child(shotgun_viewmodel)
	_strip_imported_cameras(shotgun_viewmodel)
	_prepare_viewmodel_geometry(shotgun_viewmodel)
	_create_extra_viewmodels()

	viewmodel_visual = pistol_viewmodel
	viewmodel_visual.position = hip_anchor.position
	viewmodel_visual.scale = Vector3.ONE * (viewmodel_tune_scale * VIEWMODEL_DEPTH_FACTOR)
	viewmodel_visual.rotation_degrees = hip_anchor.rotation_degrees
	pistol_anim_player = _find_animation_player(pistol_viewmodel)
	viewmodel_anim_player = pistol_anim_player
	if viewmodel_anim_player != null:
		viewmodel_anim_player.stop()
		_configure_viewmodel_animation_loops()
		if viewmodel_anim_player.has_animation(PISTOL_IDLE_ANIMATION):
			viewmodel_anim_player.assigned_animation = PISTOL_IDLE_ANIMATION
			viewmodel_anim_player.seek(0.0, true)
			viewmodel_animation_state = PISTOL_IDLE_ANIMATION
	print("FPS viewmodel: pistol, Uzi, shotgun, extras and pending guns ready")


func _strip_imported_cameras(root: Node) -> void:
	for node in root.find_children("*", "Camera3D", true, false):
		var imported_camera := node as Camera3D
		if imported_camera == null:
			continue
		imported_camera.current = false
		imported_camera.queue_free()


func _configure_viewmodel_animation_loops() -> void:
	if viewmodel_anim_player == null:
		return
	var loop_names: Array[StringName] = [
		PISTOL_IDLE_ANIMATION, PISTOL_SPRINT_ANIMATION,
		UZI_ANIM_IDLE, UZI_ANIM_IDLE_2, UZI_ANIM_WALK, UZI_ANIM_RUN,
	]
	for animation_name: StringName in loop_names:
		if viewmodel_anim_player.has_animation(animation_name):
			var animation := viewmodel_anim_player.get_animation(animation_name)
			if animation != null:
				animation.loop_mode = Animation.LOOP_LINEAR


func _play_viewmodel_animation(
	animation_name: StringName,
	blend_time: float = 0.10,
	playback_speed: float = 1.0
) -> void:
	if viewmodel_anim_player == null or not viewmodel_anim_player.has_animation(animation_name):
		return
	viewmodel_anim_player.speed_scale = 1.0
	viewmodel_anim_player.play(animation_name, blend_time, playback_speed)
	viewmodel_animation_state = animation_name


func _hold_ready_to_fire_pose() -> void:
	if viewmodel_anim_player == null or not viewmodel_anim_player.has_animation(PISTOL_READY_ANIMATION):
		return
	var ready_animation := viewmodel_anim_player.get_animation(PISTOL_READY_ANIMATION)
	if ready_animation == null:
		return
	viewmodel_anim_player.assigned_animation = PISTOL_READY_ANIMATION
	viewmodel_anim_player.seek(ready_animation.length, true)
	viewmodel_animation_state = &"ready_hold"


func _update_viewmodel_animation(sprinting: bool, delta: float) -> void:
	if not has_pistol or viewmodel_anim_player == null:
		return
	if current_weapon_id == "uzi":
		_update_uzi_animation(sprinting, delta)
		return
	if current_weapon_id == "shotgun":
		_update_shotgun_animation(sprinting, delta)
		return
	if _is_extra_weapon():
		_update_packed_animation(sprinting, delta)
		return
	if is_reloading:
		pistol_motion_state = PistolMotionState.COMBAT
		pistol_motion_transition_timer = 0.0
		# _start_reload() owns this non-looping clip. Do not let idle, ADS, fire,
		# or sprint replace it before the magazine transfer completes.
		if viewmodel_animation_state != PISTOL_RELOAD_ANIMATION:
			_play_viewmodel_animation(PISTOL_RELOAD_ANIMATION, 0.10, PISTOL_RELOAD_SPEED)
		return

	if sprinting:
		# The authored sprint clip swings the pistol up beside the face and off
		# the top-right corner. Keep the combat idle clip instead and let the
		# shared procedural run carry (sprint_viewmodel_* offsets, tuck, gait
		# bounce) frame it, exactly like the shotgun. The clip is left intact.
		if not use_pistol_sprint_clip:
			if viewmodel_animation_state != PISTOL_IDLE_ANIMATION or not viewmodel_anim_player.is_playing():
				_play_viewmodel_animation(PISTOL_IDLE_ANIMATION, 0.18)
			return
		var sprint_playback_speed := 1.0
		if viewmodel_anim_player.has_animation(PISTOL_SPRINT_ANIMATION):
			var sprint_animation := viewmodel_anim_player.get_animation(PISTOL_SPRINT_ANIMATION)
			if sprint_animation != null and sprint_animation.length > 0.001:
				var horizontal_speed := Vector2(velocity.x, velocity.z).length()
				# The rebuilt clip is authored as a 0.70-second physical arm cycle.
				# Only tiny speed matching is allowed so it never becomes frantic bob.
				sprint_playback_speed = clampf(
					horizontal_speed / maxf(sprint_speed, 0.01),
					0.92,
					1.08
				)
		if viewmodel_animation_state != PISTOL_SPRINT_ANIMATION:
			pistol_motion_state = PistolMotionState.SPRINT_ENTER
			pistol_motion_transition_timer = 0.18
			_play_viewmodel_animation(PISTOL_SPRINT_ANIMATION, 0.18)
			viewmodel_anim_player.speed_scale = sprint_playback_speed
			var sprint_clip := viewmodel_anim_player.get_animation(PISTOL_SPRINT_ANIMATION)
			if sprint_clip != null:
				viewmodel_anim_player.seek(
					fposmod(gait_phase, TAU) / TAU * sprint_clip.length,
					true
				)
		else:
			viewmodel_anim_player.speed_scale = sprint_playback_speed
			if pistol_motion_state == PistolMotionState.SPRINT_ENTER:
				pistol_motion_transition_timer = maxf(0.0, pistol_motion_transition_timer - delta)
				if pistol_motion_transition_timer <= 0.0:
					pistol_motion_state = PistolMotionState.SPRINT_LOOP
		return

	if viewmodel_animation_state == PISTOL_SPRINT_ANIMATION:
		pistol_motion_state = PistolMotionState.SPRINT_EXIT
		pistol_motion_transition_timer = 0.20
		_play_viewmodel_animation(PISTOL_READY_ANIMATION, 0.20, 1.15)
		return
	if pistol_motion_state == PistolMotionState.SPRINT_EXIT:
		pistol_motion_transition_timer = maxf(0.0, pistol_motion_transition_timer - delta)
		if pistol_motion_transition_timer > 0.0 and viewmodel_anim_player.is_playing():
			return
		pistol_motion_state = PistolMotionState.COMBAT

	if viewmodel_animation_state == PISTOL_FIRE_ANIMATION:
		if viewmodel_anim_player.is_playing():
			return
		if _ads_should_be_active() or ads_blend > 0.01:
			_hold_ready_to_fire_pose()
			return

	if viewmodel_animation_state == PISTOL_READY_ANIMATION and viewmodel_anim_player.is_playing():
		return
	if _ads_should_be_active() or ads_blend > 0.01:
		if viewmodel_animation_state != &"ready_hold":
			_hold_ready_to_fire_pose()
		return

	if viewmodel_animation_state != PISTOL_IDLE_ANIMATION or not viewmodel_anim_player.is_playing():
		_play_viewmodel_animation(PISTOL_IDLE_ANIMATION, 0.12)


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _prepare_viewmodel_geometry(root: Node) -> void:
	if root is MeshInstance3D:
		var mesh_instance := root as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_instance.extra_cull_margin = 16384.0
		mesh_instance.layers = VIEWMODEL_RENDER_LAYER
	for child in root.get_children():
		_prepare_viewmodel_geometry(child)

func _load_hd_viewmodel_textures() -> void:
	# Runtime loading is intentional: a missing optional texture must never prevent
	# the whole project from parsing/starting. If a file is absent, the original
	# material from the animated viewmodel remains in place.
	if ResourceLoader.exists(PISTOL_HD_ALBEDO_PATH):
		pistol_hd_albedo = load(PISTOL_HD_ALBEDO_PATH) as Texture2D
	if ResourceLoader.exists(HAND_HD_ALBEDO_PATH):
		hand_hd_albedo = load(HAND_HD_ALBEDO_PATH) as Texture2D
	if ResourceLoader.exists(ARM_HD_ALBEDO_PATH):
		arm_hd_albedo = load(ARM_HD_ALBEDO_PATH) as Texture2D

func _apply_hd_viewmodel_textures(root: Node) -> void:
	# Keep the existing animated SLIDE_FIRE GLB. Override only albedo textures
	# when the optional HD texture files are actually available.
	if root is MeshInstance3D:
		var mesh_instance: MeshInstance3D = root as MeshInstance3D
		var mesh: Mesh = mesh_instance.mesh
		if mesh != null:
			for surface_index: int in range(mesh.get_surface_count()):
				var original_material: Material = mesh.surface_get_material(surface_index)
				var replacement: StandardMaterial3D
				if original_material is StandardMaterial3D:
					replacement = (original_material as StandardMaterial3D).duplicate(true) as StandardMaterial3D
				else:
					replacement = StandardMaterial3D.new()

				var node_key: String = String(mesh_instance.name).to_lower()
				var material_key: String = ""
				if original_material != null:
					material_key = String(original_material.resource_name).to_lower()
				var key: String = node_key + " " + material_key

				var chosen_texture: Texture2D = null
				if key.contains("hand"):
					chosen_texture = hand_hd_albedo
				elif key.contains("arm"):
					chosen_texture = arm_hd_albedo
				else:
					chosen_texture = pistol_hd_albedo

				if chosen_texture != null:
					replacement.albedo_texture = chosen_texture
				mesh_instance.set_surface_override_material(surface_index, replacement)

	for child: Node in root.get_children():
		_apply_hd_viewmodel_textures(child)

func _disable_viewmodel_shadows(root: Node) -> void:
	if root is GeometryInstance3D:
		(root as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in root.get_children():
		_disable_viewmodel_shadows(child)

func _update_stamina_ui(delta: float) -> void:
	if sprint_bar_root == null or sprint_bar_fill == null:
		return

	var ratio: float = clampf(stamina / maxf(stamina_max, 0.01), 0.0, 1.0)
	sprint_bar_fill.size.x = sprint_bar_fill_max_width * ratio

	# Orange while spending stamina; cool blue while recovering.
	var style := sprint_bar_fill.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		if sprint_active:
			style.bg_color = Color(0.96, 0.42, 0.06, 0.78)
		else:
			style.bg_color = Color(0.16, 0.58, 0.96, 0.78)

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
		if sprint_exhausted:
			sprint_button.modulate = Color(0.45, 0.48, 0.52, 0.72)
		elif sprint_active:
			sprint_button.modulate = Color(1.0, 0.72, 0.34, 1.0)
		else:
			sprint_button.modulate = Color.WHITE


func _update_sprint_stamina(delta: float, wants_sprint: bool, moving_enough: bool, grounded: bool) -> bool:
	var can_begin: bool = not sprint_exhausted and stamina > 0.05
	var actively_sprinting: bool = wants_sprint and moving_enough and grounded and can_begin

	if actively_sprinting:
		var drain_rate: float = stamina_max / maxf(sprint_duration_seconds, 0.1)
		stamina = maxf(0.0, stamina - drain_rate * delta)
		stamina_regen_wait = stamina_regen_delay
		if stamina <= 0.01:
			stamina = 0.0
			sprint_exhausted = true
			actively_sprinting = false
	else:
		stamina_regen_wait = maxf(0.0, stamina_regen_wait - delta)
		if stamina_regen_wait <= 0.0 and stamina < stamina_max:
			var regen_rate: float = stamina_max / maxf(stamina_full_recharge_seconds, 0.1)
			stamina = minf(stamina_max, stamina + regen_rate * delta)

		if sprint_exhausted:
			var restart_level: float = stamina_max * clampf(stamina_exhausted_restart_percent, 0.05, 0.95)
			if stamina >= restart_level:
				sprint_exhausted = false

	sprint_active = actively_sprinting
	_update_stamina_ui(delta)
	return actively_sprinting


func _update_stopwatch_ui() -> void:
	if stopwatch_label == null:
		return
	elapsed_time = RunManager.elapsed_time
	var total_seconds: float = maxf(elapsed_time, 0.0)
	var minutes: int = int(floor(total_seconds / 60.0))
	var seconds: int = int(floor(total_seconds)) % 60
	var tenths: int = int(floor(fmod(total_seconds, 1.0) * 10.0))
	stopwatch_label.text = "%02d:%02d.%d" % [minutes, seconds, tenths]

func _on_money_changed(balance: int) -> void:
	if money_label != null:
		money_label.text = "$%d" % balance

func _update_health_ui() -> void:
	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = health
	if health_fill != null:
		var ratio: float = clampf(health / maxf(max_health, 1.0), 0.0, 1.0)
		health_fill.size.x = health_fill_max_width * ratio
	if health_value_label != null:
		health_value_label.text = "%d / %d" % [int(round(health)), int(round(max_health))]

func take_damage(
	amount: float,
	attack_origin: Vector3 = Vector3.ZERO,
	attack_strength: float = 1.0,
	damage_type: String = "generic"
) -> void:
	if game_over:
		return

	var applied: float = maxf(amount, 0.0)
	damage_taken += minf(applied, health)
	RunManager.register_damage_taken(minf(applied, health))
	health = clampf(health - applied, 0.0, max_health)
	health_regen_wait = health_regen_delay
	_update_health_ui()

	if health > 0.0 and RunManager.run_active:
		MusicManager.notify_combat_action(0.85)
		_play_damage_vocal(applied)

	# Existing red damage flash remains synchronized to accepted damage.
	if damage_flash != null:
		damage_flash.color = Color(0.72, 0.03, 0.02, 0.18 if health > 0.0 else 0.32)
		var hurt_tween := create_tween()
		hurt_tween.tween_property(damage_flash, "color:a", 0.0, 0.24)

	# Directional camera/haptic happens on the SAME confirmed damage frame.
	# A legacy take_damage(amount) call with no origin still works; it simply
	# cannot create a trustworthy directional shove.
	if health > 0.0 and damage_camera_enabled and attack_origin != Vector3.ZERO:
		_apply_directional_damage_impulse(
			applied,
			attack_origin,
			damage_type,
			attack_strength
		)

	if health <= 0.0:
		_start_death_sequence()


func _apply_directional_damage_impulse(
	damage_amount: float,
	attack_origin: Vector3,
	damage_type: String,
	impact_strength: float = 1.0
) -> void:
	if melee_impact_pivot == null:
		return

	# Actual world-space hit origin -> player-local direction.
	var to_source: Vector3 = attack_origin - global_position
	to_source.y = 0.0
	if to_source.length_squared() < 0.0001:
		return
	to_source = to_source.normalized()

	var local_direction: Vector3 = global_transform.basis.inverse() * to_source

	# local +X = source on player's right.
	# local -Z = source in front of player.
	var side: float = clampf(local_direction.x, -1.0, 1.0)
	var front: float = clampf(-local_direction.z, -1.0, 1.0)

	var normalized_type: String = damage_type.to_lower()
	var is_melee: bool = (
		normalized_type == "zombie_melee"
		or normalized_type == "zombie_claw"
		or normalized_type == "zombie_heavy"
		or normalized_type == "melee"
	)
	var is_heavy_melee: bool = normalized_type == "zombie_heavy" or (
		is_melee and damage_amount >= melee_heavy_damage_threshold
	)
	damage_last_profile_is_melee = is_melee
	damage_last_is_heavy = is_heavy_melee

	# Damage contributes to visual strength, but is deliberately clamped so raw
	# damage values can never generate absurd camera rotations.
	var damage_scale: float = clampf(
		damage_amount / maxf(melee_damage_reference, 0.01),
		0.65 if is_melee else 0.45,
		1.35 if is_melee else 1.0
	)
	var strength: float = damage_scale * clampf(impact_strength, 0.55, 1.55)
	if is_heavy_melee:
		strength *= 1.28

	# Multiple legitimate hits still occur, but visual stacking diminishes when
	# several zombies connect within ~100 ms.
	var now_msec: int = Time.get_ticks_msec()
	if now_msec - melee_last_hit_msec <= 105:
		melee_rapid_hit_count = mini(melee_rapid_hit_count + 1, 3)
	else:
		melee_rapid_hit_count = 0
	melee_last_hit_msec = now_msec
	damage_last_contact_msec = now_msec

	strength *= pow(melee_multi_hit_reduction, float(melee_rapid_hit_count))
	var jitter: float = randf_range(1.0 - melee_randomness, 1.0 + melee_randomness)

	var position_strength: float = melee_position_strength if is_melee else projectile_position_strength
	var pitch_strength: float = melee_pitch_strength if is_melee else projectile_pitch_strength
	var yaw_strength: float = melee_yaw_strength if is_melee else projectile_yaw_strength
	var roll_strength: float = melee_roll_strength if is_melee else projectile_roll_strength
	var weapon_strength: float = melee_weapon_kick_strength if is_melee else projectile_weapon_kick
	var fov_strength: float = melee_fov_kick if is_melee else projectile_fov_kick

	# Continuous vector blend:
	# source LEFT  -> camera travels RIGHT
	# source RIGHT -> camera travels LEFT
	# source FRONT -> camera shifts BACK (+Z)
	# source REAR  -> camera shifts FORWARD (-Z)
	var positional_direction := Vector3(
		-side,
		0.0,
		front
	)
	# Heavy blows shove more into the body (back/down); light claws whip.
	var heavy_shape: float = 1.0 if is_heavy_melee else 0.0

	# Vertical response is also directional: a front chest hit lifts the viewpoint
	# slightly while a rear strike drives it forward/down. Randomness changes only
	# magnitude below; it never invents a false attack direction.
	positional_direction.y = (front * 0.10 - heavy_shape * 0.35) if is_melee else 0.0
	if positional_direction.length_squared() > 0.0001:
		positional_direction = positional_direction.normalized()

	var position_impulse: Vector3 = positional_direction * position_strength * strength * jitter

	# Rotation is also direction-derived. Side hits emphasize roll/yaw; front
	# and rear hits emphasize pitch. Diagonal hits naturally blend both.
	var pitch_deg: float = front * pitch_strength
	var yaw_deg: float = side * yaw_strength * lerpf(1.15, 0.8, heavy_shape)
	var roll_deg: float = side * roll_strength * lerpf(1.1, 0.9, heavy_shape)
	if is_heavy_melee:
		# A heavy hit also buckles the knees: the view drops forward a touch
		# after the snap, carried by the slower heavy spring.
		pitch_deg -= 0.6 * pitch_strength * (1.0 - absf(front) * 0.5)

	# A near-perfect front/rear strike gets only a tiny asymmetry so repeated
	# centered claw hits do not look mechanically identical.
	if is_melee and absf(side) < 0.16:
		var hand_bias: float = -1.0 if randf() < 0.5 else 1.0
		yaw_deg += hand_bias * 0.12 * strength
		roll_deg += hand_bias * 0.28 * strength

	pitch_deg += randf_range(-0.08, 0.08) * strength

	var rotation_impulse := Vector3(
		deg_to_rad(pitch_deg),
		deg_to_rad(yaw_deg),
		deg_to_rad(roll_deg)
	) * strength * jitter

	# Extremely brief contact jolt: tiny amplitude only. Directional shove remains
	# the dominant readable motion.
	var micro_position := Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-0.45, 0.45),
		randf_range(-1.0, 1.0)
	).normalized() * damage_micro_jolt_position * strength
	var micro_rotation := Vector3(
		deg_to_rad(randf_range(-damage_micro_jolt_rotation, damage_micro_jolt_rotation)),
		deg_to_rad(randf_range(-damage_micro_jolt_rotation, damage_micro_jolt_rotation)),
		deg_to_rad(randf_range(-damage_micro_jolt_rotation, damage_micro_jolt_rotation))
	) * strength

	# Give the impact an immediate readable contact displacement, then let spring
	# momentum carry it farther. This fixes hits that technically had an impulse
	# but visually looked almost unchanged because the first few frames were too
	# subtle.
	var immediate_pos_fraction: float = melee_immediate_position_fraction if is_melee else projectile_immediate_position_fraction
	var immediate_rot_fraction: float = melee_immediate_rotation_fraction if is_melee else projectile_immediate_rotation_fraction
	melee_position_offset += position_impulse * immediate_pos_fraction
	melee_rotation_offset += rotation_impulse * immediate_rot_fraction

	# Impulse into CURRENT spring velocity. No tween is restarted.
	melee_position_velocity += (
		position_impulse * melee_position_velocity_multiplier
		+ micro_position * 10.0
	)
	melee_rotation_velocity += (
		rotation_impulse * melee_rotation_velocity_multiplier
		+ micro_rotation * 9.0
	)

	# Arms/gun absorb more of melee violence than the camera. Apply a smaller
	# immediate displacement on the confirmed contact frame, then let their
	# deliberately softer spring lag slightly behind the camera recovery.
	# The gun is ripped off-centre harder than the head moves, then fights back.
	# The head snaps with the blow; the hands are knocked the other way (muzzle
	# driven down and dragged off the hit) so the pose visibly breaks.
	var weapon_position_impulse := Vector3(
		position_impulse.x * 1.75,
		-(0.034 if is_melee else 0.010) * strength * (1.35 if is_heavy_melee else 1.0),
		position_impulse.z * 0.55
	) * weapon_strength

	var weapon_rotation_impulse := Vector3(
		-absf(rotation_impulse.x) * 1.1 - deg_to_rad(1.2) * strength,
		rotation_impulse.y * 1.25,
		rotation_impulse.z * 1.45
	) * weapon_strength

	if is_melee:
		melee_weapon_position_offset += weapon_position_impulse * melee_weapon_immediate_position_fraction
		melee_weapon_rotation_offset += weapon_rotation_impulse * melee_weapon_immediate_rotation_fraction
	melee_weapon_position_velocity += weapon_position_impulse * melee_position_velocity_multiplier
	melee_weapon_rotation_velocity += weapon_rotation_impulse * melee_rotation_velocity_multiplier
	_clamp_directional_damage_offsets()

	# Small FOV pulse. Projectile damage is intentionally much weaker.
	melee_fov_velocity += fov_strength * melee_fov_recovery * 0.50 * strength * (1.35 if is_heavy_melee else 0.85)

	# One short impact haptic, exactly when accepted damage occurs.
	if _is_mobile_ui() and haptics_enabled:
		if is_melee:
			Input.vibrate_handheld(
				melee_haptic_duration_ms,
				clampf(melee_haptic_strength * strength, 0.0, 0.90)
			)
		else:
			Input.vibrate_handheld(
				projectile_haptic_duration_ms,
				clampf(projectile_haptic_strength * strength, 0.0, 0.55)
			)


func _update_melee_camera_effects(delta: float) -> void:
	if melee_impact_pivot == null:
		return

	var active_spring_strength: float = projectile_spring_strength
	var active_spring_damping: float = projectile_spring_damping
	if damage_last_profile_is_melee:
		active_spring_strength = melee_heavy_spring_strength if damage_last_is_heavy else melee_light_spring_strength
		active_spring_damping = melee_heavy_spring_damping if damage_last_is_heavy else melee_light_spring_damping

	var step_count: int = maxi(1, int(ceil(delta / (1.0 / 60.0))))
	var step_delta: float = delta / float(step_count)

	for _step in range(step_count):
		var rot_accel: Vector3 = -active_spring_strength * melee_rotation_offset - active_spring_damping * melee_rotation_velocity
		melee_rotation_velocity += rot_accel * step_delta
		melee_rotation_offset += melee_rotation_velocity * step_delta

		var pos_accel: Vector3 = -active_spring_strength * melee_position_offset - active_spring_damping * melee_position_velocity
		melee_position_velocity += pos_accel * step_delta
		melee_position_offset += melee_position_velocity * step_delta

		# Under-damped: the hands overshoot once as they fight back to the pose.
		var wrot_accel: Vector3 = -(active_spring_strength * 0.72) * melee_weapon_rotation_offset - (active_spring_damping * 0.58) * melee_weapon_rotation_velocity
		melee_weapon_rotation_velocity += wrot_accel * step_delta
		melee_weapon_rotation_offset += melee_weapon_rotation_velocity * step_delta

		var wpos_accel: Vector3 = -(active_spring_strength * 0.70) * melee_weapon_position_offset - (active_spring_damping * 0.60) * melee_weapon_position_velocity
		melee_weapon_position_velocity += wpos_accel * step_delta
		melee_weapon_position_offset += melee_weapon_position_velocity * step_delta

	_clamp_directional_damage_offsets()

	var finisher_position := Vector3.ZERO
	var finisher_rotation := Vector3.ZERO
	if finisher_camera_timer > 0.0:
		finisher_camera_timer = maxf(0.0, finisher_camera_timer - delta)
		var elapsed: float = finisher_camera_duration - finisher_camera_timer
		var phase: float = clampf(elapsed / maxf(finisher_camera_duration, 0.01), 0.0, 1.0)
		var envelope: float = sin(phase * PI)
		finisher_position = Vector3(finisher_camera_side * 0.035, -0.018, -0.075) * envelope
		finisher_rotation = Vector3(
			deg_to_rad(-2.2),
			deg_to_rad(-finisher_camera_side * 3.4),
			deg_to_rad(finisher_camera_style_sign * 1.8)
		) * envelope

	melee_impact_pivot.position = melee_position_offset + finisher_position + low_health_camera_position
	melee_impact_pivot.rotation = melee_rotation_offset + finisher_rotation + low_health_camera_rotation

	var fov_accel: float = -(melee_fov_recovery * melee_fov_recovery) * melee_fov_offset - (2.0 * melee_fov_recovery) * melee_fov_velocity
	melee_fov_velocity += fov_accel * delta
	melee_fov_offset += melee_fov_velocity * delta
	melee_fov_offset = clampf(melee_fov_offset, 0.0, 3.0)


func _clamp_directional_damage_offsets() -> void:
	# Clamp immediately as well as after spring integration. Two zombies can land
	# valid hits before the next player physics update, but their combined visual
	# impulse must never throw the camera or weapon outside gameplay-safe limits.
	melee_rotation_offset.x = clampf(melee_rotation_offset.x, -deg_to_rad(melee_max_pitch), deg_to_rad(melee_max_pitch))
	melee_rotation_offset.y = clampf(melee_rotation_offset.y, -deg_to_rad(melee_max_yaw), deg_to_rad(melee_max_yaw))
	melee_rotation_offset.z = clampf(melee_rotation_offset.z, -deg_to_rad(melee_max_roll), deg_to_rad(melee_max_roll))
	if melee_position_offset.length() > melee_max_position_offset:
		melee_position_offset = melee_position_offset.normalized() * melee_max_position_offset

	const MAX_WEAPON_DAMAGE_POSITION: float = 0.060
	if melee_weapon_position_offset.length() > MAX_WEAPON_DAMAGE_POSITION:
		melee_weapon_position_offset = melee_weapon_position_offset.normalized() * MAX_WEAPON_DAMAGE_POSITION
	melee_weapon_rotation_offset.x = clampf(melee_weapon_rotation_offset.x, -deg_to_rad(9.0), deg_to_rad(9.0))
	melee_weapon_rotation_offset.y = clampf(melee_weapon_rotation_offset.y, -deg_to_rad(9.0), deg_to_rad(9.0))
	melee_weapon_rotation_offset.z = clampf(melee_weapon_rotation_offset.z, -deg_to_rad(10.0), deg_to_rad(10.0))


func begin_zombie_finisher(
	attacker_position: Vector3,
	finisher_name: String,
	contact_time: float
) -> void:
	if game_over or melee_impact_pivot == null:
		return
	var to_attacker: Vector3 = attacker_position - global_position
	to_attacker.y = 0.0
	if to_attacker.length_squared() > 0.0001:
		var local_attacker: Vector3 = global_transform.basis.inverse() * to_attacker.normalized()
		finisher_camera_side = clampf(local_attacker.x, -1.0, 1.0)
	else:
		finisher_camera_side = 0.0
	finisher_camera_style_sign = -1.0 if finisher_name.contains("backhand") else 1.0
	finisher_camera_duration = maxf(contact_time + 0.34, 0.80)
	finisher_camera_timer = finisher_camera_duration


func _reset_lateral_camera_inertia() -> void:
	lateral_smoothed_acceleration = 0.0
	lateral_camera_offset = 0.0
	lateral_camera_velocity = 0.0
	lateral_roll_offset = 0.0
	lateral_roll_velocity = 0.0
	lateral_yaw_offset = 0.0
	lateral_yaw_velocity = 0.0
	lateral_weapon_position_offset = Vector3.ZERO
	lateral_weapon_position_velocity = Vector3.ZERO
	lateral_weapon_rotation_offset = Vector3.ZERO
	lateral_weapon_rotation_velocity = Vector3.ZERO
	lateral_previous_horizontal_velocity = Vector3(velocity.x, 0.0, velocity.z)
	if lateral_inertia_pivot != null:
		lateral_inertia_pivot.position = Vector3.ZERO
		lateral_inertia_pivot.rotation = Vector3.ZERO


func _reset_melee_camera_effects() -> void:
	melee_rotation_offset = Vector3.ZERO
	melee_rotation_velocity = Vector3.ZERO
	melee_position_offset = Vector3.ZERO
	melee_position_velocity = Vector3.ZERO
	melee_weapon_position_offset = Vector3.ZERO
	melee_weapon_position_velocity = Vector3.ZERO
	melee_weapon_rotation_offset = Vector3.ZERO
	melee_weapon_rotation_velocity = Vector3.ZERO
	melee_fov_offset = 0.0
	melee_fov_velocity = 0.0
	damage_last_profile_is_melee = true
	melee_rapid_hit_count = 0
	finisher_camera_timer = 0.0
	finisher_camera_duration = 0.0
	if melee_impact_pivot != null:
		melee_impact_pivot.position = Vector3.ZERO
		melee_impact_pivot.rotation = Vector3.ZERO


func heal(amount: float) -> void:
	health = clampf(health + maxf(amount, 0.0), 0.0, max_health)
	_update_health_ui()


func _update_health_regeneration(delta: float) -> void:
	if death_sequence_active or game_over or get_tree().paused or health <= 0.0 or health >= max_health:
		return
	if health_regen_wait > 0.0:
		health_regen_wait = maxf(0.0, health_regen_wait - delta)
		return
	var previous_health := health
	health = minf(max_health, health + maxf(health_regen_per_second, 0.0) * delta)
	if not is_equal_approx(previous_health, health):
		_update_health_ui()

func _toggle_viewmodel_tuning() -> void:
	if viewmodel_tune_enabled:
		_exit_viewmodel_tuning()
	else:
		_enter_viewmodel_tune("hip")


func _enter_or_toggle_tune(target: String) -> void:
	if not viewmodel_tune_enabled:
		_enter_viewmodel_tune(target)
		return
	if viewmodel_tune_target == target:
		return
	_enter_viewmodel_tune(target)


func _enter_viewmodel_tune(target: String) -> void:
	if current_weapon_id.is_empty():
		return
	if target == "ready" and current_weapon_id != "pistol" and current_weapon_id != "uzi" and current_weapon_id != "shotgun" and not _extra_has_ads():
		target = "hip"
	viewmodel_tune_enabled = true
	viewmodel_tune_target = target
	if target == "ready":
		ads_blend = 1.0
		aim_state = AimState.ADS
	else:
		ads_blend = 0.0
		aim_state = AimState.HIP
	_apply_viewmodel_tune()
	_update_viewmodel_tune_label()
	_sync_viewmodel_tune_panel()
	if not _is_mobile_ui():
		_set_desktop_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("VIEWMODEL TUNING %s — %s" % [current_weapon_id.to_upper(), target.to_upper()])


func _exit_viewmodel_tuning() -> void:
	_save_viewmodel_settings()
	viewmodel_tune_enabled = false
	viewmodel_tune_target = "hip"
	if viewmodel_tune_label != null:
		viewmodel_tune_label.visible = false
	if viewmodel_tune_panel != null:
		viewmodel_tune_panel.hide_panel()
	if not _is_mobile_ui():
		_set_desktop_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if not _ads_should_be_active():
		ads_blend = 0.0
		aim_state = AimState.HIP
		_apply_ads_viewmodel_transform()
	print("VIEWMODEL TUNING LOCKED — %s hip POS=%s SCALE=%.4f ROT=%s ready POS=%s SCALE=%.4f ROT=%s" % [
		current_weapon_id.to_upper(),
		viewmodel_tune_position,
		viewmodel_tune_scale,
		viewmodel_tune_rotation,
		_ready_tune_position(),
		_ready_tune_scale(),
		_ready_tune_rotation(),
	])


func _ready_tune_position() -> Vector3:
	if current_weapon_id == "shotgun":
		return shotgun_ready_position
	if current_weapon_id == "uzi":
		return uzi_ready_position
	if current_weapon_id == "pistol":
		return ads_position
	if _extra_has_ads():
		return extra_ready_position.get(current_weapon_id, _extra_vm().get("ready", _weapon_hip_offset())) as Vector3
	return viewmodel_tune_position


func _ready_tune_rotation() -> Vector3:
	if current_weapon_id == "shotgun":
		return shotgun_ready_rotation
	if current_weapon_id == "uzi":
		return uzi_ready_rotation
	if current_weapon_id == "pistol":
		return ads_rotation_degrees
	if _extra_has_ads():
		return extra_ready_rotation.get(current_weapon_id, _extra_vm().get("ready_rot", _weapon_hip_rotation())) as Vector3
	return viewmodel_tune_rotation


func _ready_tune_scale() -> float:
	if current_weapon_id == "shotgun":
		return shotgun_ready_scale
	if current_weapon_id == "uzi":
		return uzi_ready_scale
	if current_weapon_id == "pistol":
		return viewmodel_tune_scale * ads_scale_multiplier
	if _extra_has_ads():
		return float(extra_ready_scale.get(current_weapon_id, _weapon_default_scale()))
	return viewmodel_tune_scale


func _active_tune_position() -> Vector3:
	return _ready_tune_position() if viewmodel_tune_target == "ready" else viewmodel_tune_position


func _active_tune_rotation() -> Vector3:
	return _ready_tune_rotation() if viewmodel_tune_target == "ready" else viewmodel_tune_rotation


func _active_tune_scale() -> float:
	return _ready_tune_scale() if viewmodel_tune_target == "ready" else viewmodel_tune_scale


func _set_active_tune_position(value: Vector3) -> void:
	if viewmodel_tune_target == "ready":
		if current_weapon_id == "shotgun":
			shotgun_ready_position = value
		elif current_weapon_id == "uzi":
			uzi_ready_position = value
		elif current_weapon_id == "pistol":
			ads_position = value
		elif _extra_has_ads():
			extra_ready_position[current_weapon_id] = value
	else:
		viewmodel_tune_position = value


func _set_active_tune_rotation(value: Vector3) -> void:
	if viewmodel_tune_target == "ready":
		if current_weapon_id == "shotgun":
			shotgun_ready_rotation = value
		elif current_weapon_id == "uzi":
			uzi_ready_rotation = value
		elif current_weapon_id == "pistol":
			ads_rotation_degrees = value
		elif _extra_has_ads():
			extra_ready_rotation[current_weapon_id] = value
	else:
		viewmodel_tune_rotation = value


func _set_active_tune_scale(value: float) -> void:
	if viewmodel_tune_target == "ready":
		if current_weapon_id == "shotgun":
			shotgun_ready_scale = value
		elif current_weapon_id == "uzi":
			uzi_ready_scale = value
		elif current_weapon_id == "pistol":
			ads_scale_multiplier = clampf(value / maxf(viewmodel_tune_scale, 0.01), 0.75, 1.0)
		elif _extra_has_ads():
			extra_ready_scale[current_weapon_id] = value
	else:
		viewmodel_tune_scale = value


func _handle_viewmodel_tune_key(event: InputEventKey) -> bool:
	if viewmodel_visual == null:
		return false
	var key_code := event.keycode
	if key_code == KEY_NONE:
		key_code = event.physical_keycode
	var pos_step := 0.008 if current_weapon_id == "shotgun" else (0.015 if viewmodel_tune_target == "ready" else (0.03 if current_weapon_id == "uzi" else 0.25))
	var rot_step := 1.0
	var scale_step := 0.002 if current_weapon_id == "shotgun" else (0.02 if viewmodel_tune_target == "ready" else (0.05 if current_weapon_id == "uzi" else 0.30))
	if event.shift_pressed:
		pos_step *= 4.0
		rot_step *= 5.0
		scale_step *= 4.0
	var pos := _active_tune_position()
	var rot := _active_tune_rotation()
	var scl := _active_tune_scale()
	var changed := true

	match key_code:
		KEY_LEFT:
			pos.x -= pos_step
		KEY_RIGHT:
			pos.x += pos_step
		KEY_UP:
			pos.y += pos_step
		KEY_DOWN:
			pos.y -= pos_step
		KEY_Q:
			pos.z -= pos_step
		KEY_E:
			pos.z += pos_step
		KEY_EQUAL:
			scl += scale_step
		KEY_B:
			scl += scale_step
		KEY_MINUS:
			scl = maxf(0.001 if current_weapon_id == "shotgun" else 0.1, scl - scale_step)
		KEY_N:
			scl = maxf(0.001 if current_weapon_id == "shotgun" else 0.1, scl - scale_step)
		KEY_I:
			rot.x += rot_step
		KEY_K:
			rot.x -= rot_step
		KEY_J:
			rot.y += rot_step
		KEY_L:
			rot.y -= rot_step
		KEY_U:
			rot.z += rot_step
		KEY_O:
			rot.z -= rot_step
		KEY_R:
			_reset_active_viewmodel_tune()
			return true
		_:
			changed = false

	if changed:
		_set_active_tune_position(pos)
		_set_active_tune_rotation(rot)
		_set_active_tune_scale(scl)
		_apply_viewmodel_tune()
		_save_viewmodel_settings()
		_update_viewmodel_tune_label()
		_print_viewmodel_values()
	return changed

func _apply_viewmodel_tune() -> void:
	if viewmodel_visual == null:
		return
	var depth := _weapon_depth_factor()
	viewmodel_visual.position = _active_tune_position() * depth
	viewmodel_visual.scale = Vector3.ONE * (_active_tune_scale() * depth)
	viewmodel_visual.rotation_degrees = _active_tune_rotation()

func _update_viewmodel_tune_label() -> void:
	if viewmodel_tune_label == null:
		return
	if not viewmodel_tune_enabled:
		viewmodel_tune_label.visible = false
		viewmodel_tune_label.text = ""
		return
	var pos := _active_tune_position()
	var rot := _active_tune_rotation()
	viewmodel_tune_label.visible = true
	viewmodel_tune_label.text = (
		"%s EDIT — %s\nPOS  %.3f  %.3f  %.3f\nSCALE  %.4f\nROT  %.1f  %.1f  %.1f\nP close   T hip   arrows move"
		% [
			current_weapon_id.to_upper(),
			viewmodel_tune_target.to_upper(),
			pos.x, pos.y, pos.z,
			_active_tune_scale(),
			rot.x, rot.y, rot.z,
		]
	)
	_sync_viewmodel_tune_panel()


func _ensure_viewmodel_tune_panel() -> void:
	if viewmodel_tune_panel != null or gameplay_hud == null:
		return
	viewmodel_tune_panel = Control.new()
	viewmodel_tune_panel.set_script(VIEWMODEL_TUNE_PANEL_SCRIPT)
	viewmodel_tune_panel.name = "ViewmodelTunePanel"
	gameplay_hud.add_child(viewmodel_tune_panel)
	viewmodel_tune_panel.weapon_chosen.connect(_mod_equip_weapon)
	viewmodel_tune_panel.hip_pressed.connect(_enter_viewmodel_tune.bind("hip"))
	viewmodel_tune_panel.ready_pressed.connect(_enter_viewmodel_tune.bind("ready"))
	viewmodel_tune_panel.reset_pressed.connect(_reset_active_viewmodel_tune)
	viewmodel_tune_panel.lock_pressed.connect(_exit_viewmodel_tuning)
	viewmodel_tune_panel.refill_pressed.connect(_dev_refill_current_weapon)
	if viewmodel_tune_panel.has_signal("heal_pressed"):
		viewmodel_tune_panel.heal_pressed.connect(_dev_heal_full)


func _open_dev_menu(weapon_id: String = "") -> void:
	if _is_mobile_ui() or game_over:
		return
	_ensure_viewmodel_tune_panel()
	if not has_pistol:
		give_starting_pistol()
	if primary_weapon_id.is_empty():
		primary_weapon_id = current_weapon_id if not current_weapon_id.is_empty() else "pistol"
	var wanted := weapon_id if not weapon_id.is_empty() else current_weapon_id
	if wanted.is_empty():
		wanted = "pistol"
	if current_weapon_id != wanted:
		_mod_equip_weapon(wanted)
		return
	_enter_viewmodel_tune("hip" if not viewmodel_tune_enabled else viewmodel_tune_target)
	_sync_viewmodel_tune_panel()


func _mod_equip_weapon(weapon_id: String) -> void:
	if _is_mobile_ui() or game_over or weapon_id.is_empty():
		return
	_ensure_viewmodel_tune_panel()
	if not has_pistol:
		give_starting_pistol()
	if primary_weapon_id.is_empty():
		primary_weapon_id = current_weapon_id if not current_weapon_id.is_empty() else "pistol"
	if viewmodel_tune_enabled:
		_save_viewmodel_settings()
	if not _owns_weapon(weapon_id):
		if weapon_id != primary_weapon_id:
			secondary_weapon_id = weapon_id
			_ensure_weapon_ammo(weapon_id)
	if current_weapon_id != weapon_id:
		_equip_weapon(weapon_id, false)
	_enter_viewmodel_tune("hip" if not viewmodel_tune_enabled else viewmodel_tune_target)
	_sync_viewmodel_tune_panel()


func _dev_refill_current_weapon() -> void:
	if current_weapon_id.is_empty():
		return
	_refill_weapon_ammo(current_weapon_id)
	if current_weapon_id == "knife":
		heal(KNIFE_REFILL_HEAL)


func _dev_heal_full() -> void:
	heal(max_health)


func _dev_get_kick() -> float:
	if current_weapon_id == "uzi":
		return uzi_camera_kick_degrees
	if current_weapon_id == "shotgun":
		return shotgun_camera_kick_degrees
	return pistol_camera_recoil_degrees


func _dev_set_feel(id: String, value: float) -> void:
	match id:
		"feel_mouse":
			mouse_sensitivity = value
		"feel_ads_fov":
			ads_fov = value
		"feel_hip_fov":
			hip_fov = value
		"feel_sprint_fov":
			sprint_fov_increase = value
		"feel_ads_recoil":
			ads_recoil_multiplier = value
		"feel_walk_bob":
			walk_weapon_motion_multiplier = value
		"feel_kick":
			if current_weapon_id == "uzi":
				uzi_camera_kick_degrees = value
			elif current_weapon_id == "shotgun":
				shotgun_camera_kick_degrees = value
			else:
				pistol_camera_recoil_degrees = value
		"feel_land":
			landing_camera_drop = value
	_save_viewmodel_settings()


func _open_uzi_layout_editor() -> void:
	_open_dev_menu("uzi")


func _open_shotgun_layout_editor() -> void:
	_open_dev_menu("shotgun")


func _reset_active_viewmodel_tune() -> void:
	if viewmodel_tune_target == "ready":
		if current_weapon_id == "shotgun":
			_set_active_tune_position(SHOTGUN_READY_OFFSET)
			_set_active_tune_scale(SHOTGUN_DEFAULT_SCALE)
			_set_active_tune_rotation(SHOTGUN_READY_ROTATION)
		elif current_weapon_id == "uzi":
			_set_active_tune_position(UZI_READY_OFFSET)
			_set_active_tune_scale(UZI_READY_SCALE)
			_set_active_tune_rotation(UZI_READY_ROTATION)
		elif current_weapon_id == "pistol":
			ads_position = Vector3(0.0, -0.9164, -0.8038)
			ads_rotation_degrees = Vector3(0.0, 180.0, 0.0)
			ads_scale_multiplier = 0.94
		elif _extra_has_ads():
			var data := _extra_vm()
			_set_active_tune_position(data.get("ready", _weapon_hip_offset()) as Vector3)
			_set_active_tune_rotation(data.get("ready_rot", _weapon_hip_rotation()) as Vector3)
			_set_active_tune_scale(_weapon_default_scale())
		else:
			_set_active_tune_position(_weapon_hip_offset())
			_set_active_tune_scale(_weapon_default_scale())
			_set_active_tune_rotation(_weapon_hip_rotation())
	else:
		_set_active_tune_position(_weapon_hip_offset())
		_set_active_tune_scale(_weapon_default_scale())
		_set_active_tune_rotation(_weapon_hip_rotation())
	_apply_viewmodel_tune()
	_save_viewmodel_settings()
	_update_viewmodel_tune_label()
	_sync_viewmodel_tune_panel()


func _sync_viewmodel_tune_panel() -> void:
	if viewmodel_tune_panel == null or not viewmodel_tune_enabled:
		return
	viewmodel_tune_panel.show_for(current_weapon_id, viewmodel_tune_target)
	viewmodel_tune_panel.set_values(_active_tune_position(), _active_tune_scale(), _active_tune_rotation())


func _weapon_tune_section(weapon_id: String = current_weapon_id) -> String:
	if weapon_id.is_empty() or weapon_id == "pistol":
		return "viewmodel"
	return weapon_id


func _save_viewmodel_settings() -> void:
	var config := ConfigFile.new()
	config.load(VIEWMODEL_CONFIG_PATH)
	var section := _weapon_tune_section()
	config.set_value(section, "version", VIEWMODEL_CONFIG_VERSION)
	config.set_value(section, "position", viewmodel_tune_position)
	config.set_value(section, "scale", viewmodel_tune_scale)
	config.set_value(section, "rotation", viewmodel_tune_rotation)
	config.set_value("uzi_ready", "version", VIEWMODEL_CONFIG_VERSION)
	config.set_value("uzi_ready", "position", uzi_ready_position)
	config.set_value("uzi_ready", "scale", uzi_ready_scale)
	config.set_value("uzi_ready", "rotation", uzi_ready_rotation)
	config.set_value("shotgun_ready", "version", VIEWMODEL_CONFIG_VERSION)
	config.set_value("shotgun_ready", "position", shotgun_ready_position)
	config.set_value("shotgun_ready", "scale", shotgun_ready_scale)
	config.set_value("shotgun_ready", "rotation", shotgun_ready_rotation)
	config.set_value("pistol_ready", "version", VIEWMODEL_CONFIG_VERSION)
	config.set_value("pistol_ready", "position", ads_position)
	config.set_value("pistol_ready", "rotation", ads_rotation_degrees)
	config.set_value("pistol_ready", "scale_mul", ads_scale_multiplier)
	for extra_id in EXTRA_WEAPON_IDS:
		var ready_section := "%s_ready" % extra_id
		if extra_ready_position.has(extra_id):
			config.set_value(ready_section, "position", extra_ready_position[extra_id])
			config.set_value(ready_section, "rotation", extra_ready_rotation.get(extra_id, Vector3(0.0, 180.0, 0.0)))
			config.set_value(ready_section, "scale", float(extra_ready_scale.get(extra_id, 0.006)))
	config.set_value("feel", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("feel", "ads_fov", ads_fov)
	config.set_value("feel", "hip_fov", hip_fov)
	config.set_value("feel", "sprint_fov_increase", sprint_fov_increase)
	config.set_value("feel", "ads_recoil_multiplier", ads_recoil_multiplier)
	config.set_value("feel", "walk_weapon_motion_multiplier", walk_weapon_motion_multiplier)
	config.set_value("feel", "pistol_kick", pistol_camera_recoil_degrees)
	config.set_value("feel", "uzi_kick", uzi_camera_kick_degrees)
	config.set_value("feel", "shotgun_kick", shotgun_camera_kick_degrees)
	config.set_value("feel", "landing_camera_drop", landing_camera_drop)
	var err := config.save(VIEWMODEL_CONFIG_PATH)
	if err != OK:
		push_warning("Could not save FPS viewmodel settings: %s" % error_string(err))

func _load_viewmodel_settings() -> void:
	_init_extra_ready_defaults()
	var defaults_pos := _weapon_hip_offset()
	var defaults_scale := _weapon_default_scale()
	var defaults_rot := _weapon_hip_rotation()
	var config := ConfigFile.new()
	var err := config.load(VIEWMODEL_CONFIG_PATH)
	var section := _weapon_tune_section()
	# Weapon poses saved by an older build are discarded so new defaults show
	# up. Only the pistol/Uzi/shotgun pose sections are versioned; "feel" and
	# the extra weapons' ready poses are left alone.
	if err == OK:
		for saved_section in ["viewmodel", "uzi", "shotgun", "uzi_ready", "shotgun_ready", "pistol_ready"]:
			if config.has_section(saved_section) and int(config.get_value(saved_section, "version", 0)) != VIEWMODEL_CONFIG_VERSION:
				config.erase_section(saved_section)
	if err != OK or not config.has_section_key(section, "position"):
		viewmodel_tune_position = defaults_pos
		viewmodel_tune_scale = defaults_scale
		viewmodel_tune_rotation = defaults_rot
	else:
		viewmodel_tune_position = config.get_value(section, "position", defaults_pos) as Vector3
		viewmodel_tune_scale = float(config.get_value(section, "scale", defaults_scale))
		viewmodel_tune_rotation = config.get_value(section, "rotation", defaults_rot) as Vector3
		# A saved pose far off the gun's default size is a corrupted save (the
		# dev panel once wrote clamped slider values into it) and can shrink the
		# gun out of view. Fall back to the stock pose and repair the file.
		var scale_ratio := viewmodel_tune_scale / maxf(defaults_scale, 0.000001)
		if scale_ratio < 0.4 or scale_ratio > 2.5 or viewmodel_tune_position.distance_to(defaults_pos) > 1.2:
			push_warning("Viewmodel pose for %s looked corrupted (scale %.4f vs default %.4f); reset to default." % [section, viewmodel_tune_scale, defaults_scale])
			viewmodel_tune_position = defaults_pos
			viewmodel_tune_scale = defaults_scale
			viewmodel_tune_rotation = defaults_rot
			config.set_value(section, "position", defaults_pos)
			config.set_value(section, "scale", defaults_scale)
			config.set_value(section, "rotation", defaults_rot)
			config.save(VIEWMODEL_CONFIG_PATH)
	if err == OK and config.has_section("uzi_ready"):
		uzi_ready_position = config.get_value("uzi_ready", "position", UZI_READY_OFFSET) as Vector3
		uzi_ready_scale = float(config.get_value("uzi_ready", "scale", UZI_READY_SCALE))
		uzi_ready_rotation = config.get_value("uzi_ready", "rotation", UZI_READY_ROTATION) as Vector3
	else:
		uzi_ready_position = UZI_READY_OFFSET
		uzi_ready_scale = UZI_READY_SCALE
		uzi_ready_rotation = UZI_READY_ROTATION
	if err == OK and config.has_section("shotgun_ready"):
		shotgun_ready_position = config.get_value("shotgun_ready", "position", SHOTGUN_READY_OFFSET) as Vector3
		shotgun_ready_scale = float(config.get_value("shotgun_ready", "scale", SHOTGUN_DEFAULT_SCALE))
		shotgun_ready_rotation = config.get_value("shotgun_ready", "rotation", SHOTGUN_READY_ROTATION) as Vector3
	else:
		shotgun_ready_position = SHOTGUN_READY_OFFSET
		shotgun_ready_scale = SHOTGUN_DEFAULT_SCALE
		shotgun_ready_rotation = SHOTGUN_READY_ROTATION
	if err == OK and config.has_section("pistol_ready"):
		ads_position = config.get_value("pistol_ready", "position", ads_position) as Vector3
		ads_rotation_degrees = config.get_value("pistol_ready", "rotation", ads_rotation_degrees) as Vector3
		ads_scale_multiplier = float(config.get_value("pistol_ready", "scale_mul", ads_scale_multiplier))
	if err == OK:
		for extra_id in EXTRA_WEAPON_IDS:
			var ready_section := "%s_ready" % extra_id
			if not config.has_section(ready_section):
				continue
			var data := EXTRA_VIEWMODEL.get(extra_id, {}) as Dictionary
			extra_ready_position[extra_id] = config.get_value(ready_section, "position", data.get("ready", Vector3.ZERO))
			extra_ready_rotation[extra_id] = config.get_value(ready_section, "rotation", data.get("ready_rot", Vector3(0.0, 180.0, 0.0)))
			extra_ready_scale[extra_id] = float(config.get_value(ready_section, "scale", data.get("scale", 0.006)))
		if config.has_section("feel"):
			mouse_sensitivity = float(config.get_value("feel", "mouse_sensitivity", mouse_sensitivity))
			ads_fov = float(config.get_value("feel", "ads_fov", ads_fov))
			hip_fov = float(config.get_value("feel", "hip_fov", hip_fov))
			sprint_fov_increase = float(config.get_value("feel", "sprint_fov_increase", sprint_fov_increase))
			ads_recoil_multiplier = float(config.get_value("feel", "ads_recoil_multiplier", ads_recoil_multiplier))
			walk_weapon_motion_multiplier = float(config.get_value("feel", "walk_weapon_motion_multiplier", walk_weapon_motion_multiplier))
			pistol_camera_recoil_degrees = float(config.get_value("feel", "pistol_kick", pistol_camera_recoil_degrees))
			uzi_camera_kick_degrees = float(config.get_value("feel", "uzi_kick", uzi_camera_kick_degrees))
			shotgun_camera_kick_degrees = float(config.get_value("feel", "shotgun_kick", shotgun_camera_kick_degrees))
			landing_camera_drop = float(config.get_value("feel", "landing_camera_drop", landing_camera_drop))


func _init_extra_ready_defaults() -> void:
	for extra_id in EXTRA_WEAPON_IDS:
		if extra_ready_position.has(extra_id):
			continue
		var data := EXTRA_VIEWMODEL.get(extra_id, {}) as Dictionary
		var hip: Vector3 = data.get("hip", Vector3.ZERO)
		extra_ready_position[extra_id] = data.get("ready", hip)
		extra_ready_rotation[extra_id] = data.get("ready_rot", data.get("hip_rot", Vector3(0.0, 180.0, 0.0)))
		extra_ready_scale[extra_id] = float(data.get("scale", 0.006))


func _has_saved_weapon_pose(weapon_id: String) -> bool:
	var config := ConfigFile.new()
	if config.load(VIEWMODEL_CONFIG_PATH) != OK:
		return false
	return config.has_section_key(_weapon_tune_section(weapon_id), "position")

func _print_viewmodel_values() -> void:
	print("VIEWMODEL HIP POSITION = ", viewmodel_tune_position)
	print("VIEWMODEL HIP SCALE = ", viewmodel_tune_scale)
	print("VIEWMODEL HIP ROTATION = ", viewmodel_tune_rotation)
	print("READY POSITION = ", _ready_tune_position())
	print("READY SCALE = ", _ready_tune_scale())
	print("READY ROTATION = ", _ready_tune_rotation())


func give_starting_pistol() -> void:
	if has_pistol:
		return
	_equip_pistol()


func offer_weapon_choice(room_id: int, room_label: String = "", force: bool = false) -> void:
	if weapon_choice_active or game_over or death_sequence_active:
		return
	if not force and bool(weapon_choice_shown_for.get(room_id, false)):
		return
	weapon_choice_shown_for[room_id] = true
	weapon_choice_active = true
	desktop_fire_held = false
	_end_fire_input()
	_set_desktop_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if room_label.is_empty():
		room_label = "ROOM %d" % room_id
	var hint := "NEW GUNS BECOME YOUR SECONDARY"
	if _has_secondary_weapon():
		hint = "OWNED GUNS REFILL AMMO"
	var options := _weapon_choice_options(room_id)
	var captions := {}
	for weapon_id in options:
		if _owns_weapon(weapon_id) and weapon_id == "knife":
			captions[weapon_id] = "HEAL +%d" % int(KNIFE_REFILL_HEAL)
		elif _owns_weapon(weapon_id):
			captions[weapon_id] = "REFILL AMMO"
		elif _has_secondary_weapon():
			captions[weapon_id] = "REPLACE A GUN"
		else:
			captions[weapon_id] = "ADD SECONDARY"
	var overlay := _make_weapon_choice_overlay()
	overlay.weapon_chosen.connect(_on_weapon_chosen)
	overlay.present(options, room_label, hint, captions)
	get_tree().paused = true


## Role-aware, room-gated offer. `room_id` is the room being entered, so the
## gates read the room that was just CLEARED (room_id - 1).
func _weapon_choice_options(room_id: int = 2) -> Array:
	return _pick_weapon_choice_options(maxi(room_id - 1, 1))


func _make_weapon_choice_overlay() -> CanvasLayer:
	var overlay := CanvasLayer.new()
	overlay.set_script(WEAPON_CHOICE_OVERLAY_SCRIPT)
	get_tree().current_scene.add_child(overlay)
	return overlay


func _on_weapon_chosen(weapon_id: String) -> void:
	if _owns_weapon(weapon_id):
		if weapon_id == "knife":
			# Nothing to refill: a small heal so the pick is not a dead tap.
			_knife_refill_heal()
		else:
			_refill_weapon_ammo(weapon_id)
		_close_weapon_choice()
		return
	if not has_pistol:
		primary_weapon_id = weapon_id
		_equip_weapon(weapon_id, true)
		_close_weapon_choice()
		return
	if not _has_secondary_weapon():
		if primary_weapon_id.is_empty():
			primary_weapon_id = current_weapon_id
		secondary_weapon_id = weapon_id
		_refill_weapon_ammo(weapon_id)
		_close_weapon_choice()
		return
	pending_incoming_weapon_id = weapon_id
	_offer_weapon_replace(weapon_id)


func _offer_weapon_replace(incoming_id: String) -> void:
	weapon_choice_active = true
	desktop_fire_held = false
	_end_fire_input()
	_set_desktop_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var overlay := _make_weapon_choice_overlay()
	overlay.weapon_chosen.connect(_on_weapon_slot_replaced)
	var owned: Array = []
	if not primary_weapon_id.is_empty():
		owned.append(primary_weapon_id)
	if not secondary_weapon_id.is_empty() and secondary_weapon_id != primary_weapon_id:
		owned.append(secondary_weapon_id)
	overlay.present_replace(owned, incoming_id, "")
	get_tree().paused = true


func _on_weapon_slot_replaced(replaced_id: String) -> void:
	var incoming_id := pending_incoming_weapon_id
	pending_incoming_weapon_id = ""
	if incoming_id.is_empty() or replaced_id.is_empty() or incoming_id == replaced_id:
		_close_weapon_choice()
		return
	_replace_weapon_slot(replaced_id, incoming_id)
	_close_weapon_choice()


func _replace_weapon_slot(replaced_id: String, incoming_id: String) -> void:
	weapon_ammo_store.erase(replaced_id)
	if primary_weapon_id == replaced_id:
		primary_weapon_id = incoming_id
	elif secondary_weapon_id == replaced_id:
		secondary_weapon_id = incoming_id
	_refill_weapon_ammo(incoming_id)
	if current_weapon_id == replaced_id:
		_equip_weapon(incoming_id, true)


func _owns_weapon(weapon_id: String) -> bool:
	return (
		weapon_id == current_weapon_id
		or weapon_id == primary_weapon_id
		or weapon_id == secondary_weapon_id
	)


## The other owned weapon the player can swap to, or "" if none.
func _swap_target_weapon_id() -> String:
	if not _has_secondary_weapon():
		return ""
	return secondary_weapon_id if current_weapon_id != secondary_weapon_id else primary_weapon_id


func _has_secondary_weapon() -> bool:
	return not secondary_weapon_id.is_empty() and secondary_weapon_id != primary_weapon_id


func _close_weapon_choice() -> void:
	if has_pistol:
		RunManager.set_loadout(primary_weapon_id if not primary_weapon_id.is_empty() else current_weapon_id, secondary_weapon_id)
	weapon_choice_active = false
	pending_incoming_weapon_id = ""
	get_tree().paused = false
	_set_desktop_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_refresh_swap_button()
	_update_pistol_ammo_display()


func _equip_pistol() -> void:
	if primary_weapon_id.is_empty():
		primary_weapon_id = "pistol"
	_equip_weapon("pistol", not has_pistol)
	_refresh_swap_button()


func swap_to_secondary_weapon() -> void:
	if game_over or is_reloading or weapon_choice_active or weapon_intro_locked:
		return
	var other := ""
	if current_weapon_id == primary_weapon_id and not secondary_weapon_id.is_empty():
		other = secondary_weapon_id
	elif current_weapon_id == secondary_weapon_id and not primary_weapon_id.is_empty():
		other = primary_weapon_id
	if other.is_empty() or other == current_weapon_id:
		return
	_equip_weapon(other, false)
	_refresh_swap_button()


func _on_swap_button_pressed() -> void:
	swap_to_secondary_weapon()


func _refresh_swap_button() -> void:
	if swap_button == null:
		return
	var can_swap := not secondary_weapon_id.is_empty() and secondary_weapon_id != primary_weapon_id
	var pause_open: bool = get_tree().paused and not game_over and not ControlSettingsManager.suspend_hud_layout
	swap_button.visible = can_swap and not pause_open and ControlSettingsManager.control_visible("swap")
	swap_button.disabled = not can_swap
	if can_swap:
		var other := secondary_weapon_id if current_weapon_id != secondary_weapon_id else primary_weapon_id
		swap_button.text = "⇄  %s" % _weapon_display_name(other)


func _equip_weapon(weapon_id: String, play_inspect: bool) -> void:
	# Drop any timed cue / delayed hit / spinning barrels from the old weapon.
	_bump_extra_serial()
	_minigun_force_stop(false)
	crossbow_bash_active = false
	_store_current_weapon_ammo()
	current_weapon_id = weapon_id
	RunManager.set_loadout(primary_weapon_id if not primary_weapon_id.is_empty() else weapon_id, secondary_weapon_id)
	has_pistol = true
	encounter_started = true
	unlimited_ammo = false
	is_reloading = false
	reload_timer = 0.0
	reload_pending_timer = 0.0
	weapon_intro_locked = play_inspect
	_ensure_weapon_ammo(weapon_id)
	_restore_weapon_ammo(weapon_id)
	_show_weapon_viewmodel(weapon_id)
	_update_pistol_ammo_display()
	if gameplay_hud != null:
		gameplay_hud.configure_mobile_visibility(_should_show_mobile_hud(), true)
		gameplay_hud.set_ammo(_ammo_hud_text(), true)
		joystick_radius = gameplay_hud.joystick_radius
	elif shoot_button != null:
		shoot_button.visible = _should_show_mobile_hud()
		shoot_button.modulate = Color.WHITE
	if ammo_label != null:
		ammo_label.visible = true
		ammo_label.text = _ammo_hud_text()
	_apply_weapon_viewmodel_pose()
	if weapon_id == "uzi":
		if play_inspect:
			_play_uzi_intro()
		else:
			_play_viewmodel_animation(UZI_ANIM_IDLE, 0.08)
	elif weapon_id == "shotgun":
		weapon_intro_locked = false
		_hold_shotgun_idle()
		if play_inspect:
			_play_shotgun_section(&"pump", SHOTGUN_PUMP_START, SHOTGUN_PUMP_END, 0.10, 1.05)
			_play_shotgun_pump_sfx()
	elif _is_extra_weapon(weapon_id):
		_equip_extra_weapon(weapon_id, play_inspect)
		_update_pistol_ammo_display()
	else:
		_play_viewmodel_animation(PISTOL_READY_ANIMATION, 0.0, 1.15)
		# The pistol ready clip is just the combat pose. Leaving this locked
		# made Room 1's starting pistol unable to fire in desktop debug.
		weapon_intro_locked = false
	var tween := create_tween()
	viewmodel_root.position = VIEWMODEL_POSITION + Vector3(0.0, -0.22, 0.18) * _weapon_depth_factor()
	tween.tween_property(viewmodel_root, "position", VIEWMODEL_POSITION, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if viewmodel_tune_enabled:
		_enter_viewmodel_tune(viewmodel_tune_target)


func _show_weapon_viewmodel(weapon_id: String) -> void:
	if pistol_viewmodel != null:
		pistol_viewmodel.visible = weapon_id == "pistol"
		_set_all_meshes_visible(pistol_viewmodel, true)
	if uzi_viewmodel != null:
		uzi_viewmodel.visible = weapon_id == "uzi"
		_set_all_meshes_visible(uzi_viewmodel, true)
	if shotgun_viewmodel != null:
		shotgun_viewmodel.visible = weapon_id == "shotgun"
		_set_all_meshes_visible(shotgun_viewmodel, true)
	for extra_id in EXTRA_WEAPON_IDS:
		var extra_model := _extra_viewmodel_node(extra_id)
		if extra_model != null:
			extra_model.visible = weapon_id == extra_id
			_set_all_meshes_visible(extra_model, true)
	if weapon_id == "uzi":
		viewmodel_visual = uzi_viewmodel
	elif weapon_id == "shotgun":
		viewmodel_visual = shotgun_viewmodel
	elif _is_extra_weapon(weapon_id) and _extra_viewmodel_node(weapon_id) != null:
		viewmodel_visual = _extra_viewmodel_node(weapon_id)
	else:
		viewmodel_visual = pistol_viewmodel
	viewmodel_anim_player = _find_animation_player(viewmodel_visual)
	if viewmodel_anim_player != null:
		_configure_viewmodel_animation_loops()
	if weapon_id == "uzi":
		_cache_uzi_sight_nodes()
		_style_uzi_character()


func _set_all_meshes_visible(root: Node, visible: bool) -> void:
	if root == null:
		return
	if root is MeshInstance3D:
		(root as MeshInstance3D).visible = visible
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance != null:
			mesh_instance.visible = visible


func _uzi_ready_clip() -> StringName:
	if viewmodel_anim_player != null and viewmodel_anim_player.has_animation(UZI_ANIM_READY):
		return UZI_ANIM_READY
	return UZI_ANIM_AIM_IN


func _uzi_ready_play_speed() -> float:
	var clip_len := _clip_length(_uzi_ready_clip(), 0.567)
	return clampf(clip_len / UZI_ADS_ENTER_TIME, 1.08, 1.60)


func _hold_uzi_ready_pose() -> void:
	var ready_clip := _uzi_ready_clip()
	if viewmodel_anim_player != null and viewmodel_anim_player.has_animation(ready_clip):
		var aim := viewmodel_anim_player.get_animation(ready_clip)
		if aim != null:
			viewmodel_anim_player.assigned_animation = ready_clip
			viewmodel_anim_player.seek(aim.length, true)
	viewmodel_animation_state = &"ready_hold"


func _cache_uzi_sight_nodes() -> void:
	uzi_skeleton = null
	uzi_rear_bone = -1
	uzi_front_bone = -1
	if uzi_viewmodel == null:
		return
	var skeletons := uzi_viewmodel.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	uzi_skeleton = skeletons[0] as Skeleton3D
	if uzi_skeleton == null:
		return
	uzi_rear_bone = uzi_skeleton.find_bone("UZI BP")
	uzi_front_bone = uzi_skeleton.find_bone("UZI FP")
	if uzi_rear_bone < 0 or uzi_front_bone < 0:
		for bone_index in range(uzi_skeleton.get_bone_count()):
			var bone_name := uzi_skeleton.get_bone_name(bone_index).to_lower()
			if uzi_rear_bone < 0 and (bone_name.contains("uzi bp") or bone_name.ends_with(" bp")):
				uzi_rear_bone = bone_index
			elif uzi_front_bone < 0 and (bone_name.contains("uzi fp") or bone_name.ends_with(" fp")):
				uzi_front_bone = bone_index


func _style_uzi_character() -> void:
	if uzi_viewmodel == null:
		return
	var hidden := StandardMaterial3D.new()
	hidden.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	hidden.alpha_scissor_threshold = 1.0
	hidden.albedo_color = Color(0.0, 0.0, 0.0, 0.0)
	hidden.cull_mode = BaseMaterial3D.CULL_DISABLED
	hidden.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var hand_texture: Texture2D = null
	if ResourceLoader.exists(UZI_HAND_TEXTURE_PATH):
		hand_texture = load(UZI_HAND_TEXTURE_PATH) as Texture2D
	for node in uzi_viewmodel.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var mesh_name := String(mesh_instance.name).to_lower()
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var material := mesh_instance.get_active_material(surface_index)
			var material_name := String(material.resource_name).to_lower() if material != null else ""
			var hide_watch := material_name.contains("watch")
			if mesh_name.contains("character") and (surface_index == 2 or surface_index == 3):
				hide_watch = true
			if hide_watch:
				mesh_instance.set_surface_override_material(surface_index, hidden)
				continue
			var is_glove := material_name.contains("glove") or material_name.contains("hand")
			if mesh_name.contains("character") and surface_index == 4:
				is_glove = true
			if is_glove:
				mesh_instance.set_surface_override_material(
					surface_index,
					_make_uzi_hand_material(material, hand_texture)
				)


func _make_uzi_hand_material(source: Material, hand_texture: Texture2D) -> StandardMaterial3D:
	var hand: StandardMaterial3D
	if source is StandardMaterial3D:
		hand = (source as StandardMaterial3D).duplicate(true) as StandardMaterial3D
	else:
		hand = StandardMaterial3D.new()
		hand.roughness = 0.72
	if hand_texture != null:
		hand.albedo_texture = hand_texture
		hand.albedo_color = Color(1.28, 1.22, 1.16)
	else:
		hand.albedo_color = Color(0.30, 0.28, 0.26)
	return hand


func _apply_uzi_sight_alignment(eased_blend: float) -> void:
	# Hip stays on the idle layout. Ready-to-fire uses the exact T-menu pose
	# so shooting matches what you see when the values are locked.
	var depth := _weapon_depth_factor()
	var t := clampf(eased_blend, 0.0, 1.0)
	viewmodel_visual.position = viewmodel_tune_position.lerp(uzi_ready_position, t) * depth
	viewmodel_visual.rotation_degrees = viewmodel_tune_rotation.lerp(uzi_ready_rotation, t)
	viewmodel_visual.scale = Vector3.ONE * (lerpf(viewmodel_tune_scale, uzi_ready_scale, t) * depth)


func _weapon_starting_ammo(weapon_id: String) -> Dictionary:
	if _is_extra_weapon(weapon_id):
		return _extra_starting_ammo(weapon_id)
	if weapon_id == "uzi":
		return {
			"mag": UZI_MAG_CAPACITY,
			"reserve": UZI_STARTING_TOTAL_AMMO - UZI_MAG_CAPACITY,
		}
	if weapon_id == "shotgun":
		return {
			"mag": SHOTGUN_MAG_CAPACITY,
			"reserve": SHOTGUN_STARTING_TOTAL_AMMO - SHOTGUN_MAG_CAPACITY,
		}
	return {
		"mag": PISTOL_MAG_CAPACITY,
		"reserve": PISTOL_STARTING_TOTAL_AMMO - PISTOL_MAG_CAPACITY,
	}


func _ensure_weapon_ammo(weapon_id: String) -> void:
	if weapon_ammo_store.has(weapon_id):
		return
	weapon_ammo_store[weapon_id] = _weapon_starting_ammo(weapon_id)


func _refill_weapon_ammo(weapon_id: String) -> void:
	if weapon_id.is_empty():
		return
	if weapon_id == current_weapon_id:
		_store_current_weapon_ammo()
	weapon_ammo_store[weapon_id] = _weapon_starting_ammo(weapon_id)
	if weapon_id == current_weapon_id:
		_restore_weapon_ammo(weapon_id)
		_update_pistol_ammo_display()


func _store_current_weapon_ammo() -> void:
	if current_weapon_id.is_empty():
		return
	weapon_ammo_store[current_weapon_id] = {
		"mag": ammo,
		"reserve": reserve_ammo,
	}


func _restore_weapon_ammo(weapon_id: String) -> void:
	var stored: Dictionary = weapon_ammo_store.get(weapon_id, {})
	ammo = int(stored.get("mag", _weapon_mag_capacity(weapon_id)))
	reserve_ammo = int(stored.get("reserve", 0))


func _weapon_mag_capacity(weapon_id: String = current_weapon_id) -> int:
	if _is_extra_weapon(weapon_id):
		return _extra_mag_capacity(weapon_id)
	if weapon_id == "uzi":
		return UZI_MAG_CAPACITY
	if weapon_id == "shotgun":
		return SHOTGUN_MAG_CAPACITY
	return PISTOL_MAG_CAPACITY


func _weapon_shot_interval() -> float:
	if _is_extra_weapon():
		return _extra_shot_interval(current_weapon_id)
	if current_weapon_id == "uzi":
		return UZI_SHOT_INTERVAL
	if current_weapon_id == "shotgun":
		return SHOTGUN_SHOT_INTERVAL
	return maxf(pistol_shot_interval, 0.18)


func _weapon_depth_factor() -> float:
	return 1.0 if _weapon_uses_full_depth() else VIEWMODEL_DEPTH_FACTOR


func _weapon_hip_offset() -> Vector3:
	if _is_extra_weapon():
		return _extra_vm().get("hip", Vector3.ZERO)
	if current_weapon_id == "uzi":
		return UZI_MODEL_OFFSET
	if current_weapon_id == "shotgun":
		return SHOTGUN_MODEL_OFFSET
	return VIEWMODEL_MODEL_OFFSET


func _weapon_hip_rotation() -> Vector3:
	if _is_extra_weapon():
		return _extra_vm().get("hip_rot", Vector3(0.0, 180.0, 0.0))
	if current_weapon_id == "uzi":
		return UZI_DEFAULT_ROTATION
	if current_weapon_id == "shotgun":
		return SHOTGUN_DEFAULT_ROTATION
	return VIEWMODEL_DEFAULT_ROTATION


func _weapon_default_scale() -> float:
	if _is_extra_weapon():
		return float(_extra_vm().get("scale", 0.006))
	if current_weapon_id == "uzi":
		return UZI_DEFAULT_SCALE
	if current_weapon_id == "shotgun":
		return SHOTGUN_DEFAULT_SCALE
	return VIEWMODEL_DEFAULT_SCALE


func _weapon_display_name(weapon_id: String = current_weapon_id) -> String:
	if _is_extra_weapon(weapon_id):
		return _extra_display_name(weapon_id)
	if weapon_id == "uzi":
		return "UZI"
	if weapon_id == "shotgun":
		return "SHOTGUN"
	return "PISTOL"


func _apply_weapon_viewmodel_pose() -> void:
	_load_viewmodel_settings()
	if hip_anchor != null:
		hip_anchor.position = viewmodel_tune_position * _weapon_depth_factor()
		hip_anchor.rotation_degrees = viewmodel_tune_rotation
	if viewmodel_tune_enabled:
		_apply_viewmodel_tune()
	else:
		_apply_ads_viewmodel_transform()


func _play_uzi_intro() -> void:
	weapon_intro_locked = true
	_play_viewmodel_animation(UZI_ANIM_REF_POSE, 0.0)
	_play_viewmodel_animation(UZI_ANIM_EQUIP, 0.0)
	await get_tree().create_timer(_clip_length(UZI_ANIM_EQUIP, 2.23)).timeout
	if current_weapon_id != "uzi" or not is_instance_valid(self):
		return
	_play_viewmodel_animation(UZI_ANIM_INSPECT, 0.08)
	await get_tree().create_timer(_clip_length(UZI_ANIM_INSPECT, 5.60)).timeout
	if current_weapon_id != "uzi" or not is_instance_valid(self):
		return
	_play_viewmodel_animation(UZI_ANIM_FIREMODE, 0.08)
	await get_tree().create_timer(_clip_length(UZI_ANIM_FIREMODE, 0.37)).timeout
	if current_weapon_id != "uzi" or not is_instance_valid(self):
		return
	weapon_intro_locked = false
	_play_viewmodel_animation(UZI_ANIM_IDLE, 0.12)


func _clip_length(animation_name: StringName, fallback: float) -> float:
	if viewmodel_anim_player != null and viewmodel_anim_player.has_animation(animation_name):
		var animation := viewmodel_anim_player.get_animation(animation_name)
		if animation != null:
			return maxf(animation.length, 0.05)
	return fallback


func _update_uzi_animation(sprinting: bool, _delta: float) -> void:
	if weapon_intro_locked or is_reloading:
		return
	if viewmodel_tune_enabled:
		if viewmodel_tune_target == "ready":
			var ready_clip := _uzi_ready_clip()
			if viewmodel_animation_state == ready_clip and viewmodel_anim_player.is_playing():
				return
			if viewmodel_animation_state != &"ready_hold":
				if viewmodel_animation_state != ready_clip:
					_play_viewmodel_animation(ready_clip, UZI_READY_BLEND, _uzi_ready_play_speed())
				else:
					_hold_uzi_ready_pose()
		return
	if viewmodel_animation_state == UZI_ANIM_FIRE:
		_hold_uzi_ready_pose()
		return
	if viewmodel_animation_state == UZI_ANIM_READY and viewmodel_anim_player.is_playing():
		return
	if viewmodel_animation_state == UZI_ANIM_AIM_IN and viewmodel_anim_player.is_playing():
		return
	if viewmodel_animation_state == UZI_ANIM_AIM_OUT and viewmodel_anim_player.is_playing():
		return
	if sprinting:
		if viewmodel_animation_state != UZI_ANIM_RUN:
			_play_viewmodel_animation(UZI_ANIM_RUN, 0.12)
		return
	var moving := Vector2(velocity.x, velocity.z).length() > 0.45
	if _ads_should_be_active() or ads_blend > 0.12:
		var ready_clip := _uzi_ready_clip()
		if viewmodel_animation_state == UZI_ANIM_FIRE:
			_hold_uzi_ready_pose()
			return
		if viewmodel_animation_state == ready_clip and viewmodel_anim_player.is_playing():
			return
		if viewmodel_animation_state != &"ready_hold":
			if viewmodel_animation_state != ready_clip:
				_play_viewmodel_animation(ready_clip, UZI_READY_BLEND, _uzi_ready_play_speed())
			else:
				_hold_uzi_ready_pose()
		return
	if viewmodel_animation_state == UZI_ANIM_READY or viewmodel_animation_state == UZI_ANIM_AIM_IN or viewmodel_animation_state == UZI_ANIM_FIRE or viewmodel_animation_state == &"ready_hold":
		_play_viewmodel_animation(UZI_ANIM_AIM_OUT, 0.08)
		return
	if moving:
		if viewmodel_animation_state != UZI_ANIM_WALK:
			_play_viewmodel_animation(UZI_ANIM_WALK, 0.12)
		return
	if viewmodel_animation_state != UZI_ANIM_IDLE and viewmodel_animation_state != UZI_ANIM_IDLE_2:
		_play_viewmodel_animation(UZI_ANIM_IDLE, 0.12)


func _update_uzi_idle_alt(delta: float) -> void:
	if current_weapon_id != "uzi" or weapon_intro_locked or is_reloading:
		return
	if viewmodel_animation_state != UZI_ANIM_IDLE:
		return
	uzi_idle_alt_timer = maxf(0.0, uzi_idle_alt_timer - delta)
	if uzi_idle_alt_timer > 0.0:
		return
	uzi_idle_alt_timer = randf_range(7.5, 12.0)
	_play_viewmodel_animation(UZI_ANIM_IDLE_2, 0.16)


func _update_shotgun_animation(_sprinting: bool, _delta: float) -> void:
	if viewmodel_tune_enabled:
		_hold_shotgun_idle()
		return
	_advance_shotgun_section()
	if is_reloading or shotgun_action == &"fire" or shotgun_action == &"pump" or shotgun_section_playing:
		return
	if viewmodel_animation_state != &"shotgun_idle":
		_hold_shotgun_idle()


func _advance_shotgun_section() -> void:
	if not shotgun_section_playing or viewmodel_anim_player == null:
		return
	var reached_end := (
		not viewmodel_anim_player.is_playing()
		or viewmodel_anim_player.current_animation_position >= shotgun_section_end - 0.012
	)
	if not reached_end:
		return
	shotgun_section_playing = false
	viewmodel_anim_player.pause()
	viewmodel_anim_player.seek(shotgun_section_end, true)
	if shotgun_action == &"fire":
		_play_shotgun_section(&"pump", SHOTGUN_PUMP_START, SHOTGUN_PUMP_END, 0.04, 1.08)
		_play_shotgun_pump_sfx()
		_apply_shotgun_pump_recoil()
		_play_shotgun_shell_delayed(0.10)
	elif shotgun_action == &"pump":
		_hold_shotgun_idle()


func _play_shotgun_section(
	action: StringName,
	from_time: float,
	to_time: float,
	blend_time: float = 0.06,
	playback_speed: float = 1.0
) -> void:
	var clip := _shotgun_clip()
	if viewmodel_anim_player == null or clip.is_empty() or not viewmodel_anim_player.has_animation(clip):
		return
	shotgun_action = action
	shotgun_section_end = to_time
	shotgun_section_playing = true
	viewmodel_anim_player.speed_scale = 1.0
	if viewmodel_anim_player.has_method("play_section"):
		viewmodel_anim_player.call("play_section", clip, from_time, to_time, blend_time, playback_speed)
	else:
		viewmodel_anim_player.play(clip, blend_time, playback_speed)
		viewmodel_anim_player.seek(from_time, true)
	viewmodel_animation_state = action


func _shotgun_clip() -> StringName:
	if viewmodel_anim_player == null:
		return SHOTGUN_ANIM
	if viewmodel_anim_player.has_animation(SHOTGUN_ANIM):
		return SHOTGUN_ANIM
	var names := viewmodel_anim_player.get_animation_list()
	if names.is_empty():
		return SHOTGUN_ANIM
	return StringName(names[0])


func _hold_shotgun_idle() -> void:
	shotgun_action = &"idle"
	shotgun_section_playing = false
	var clip := _shotgun_clip()
	if viewmodel_anim_player != null and viewmodel_anim_player.has_animation(clip):
		# No cross-fade: pausing mid-blend froze a half-blended pose, which
		# left the bead ~25-40 px off the crosshair after every pump.
		viewmodel_anim_player.play(clip, 0.0, 1.0)
		viewmodel_anim_player.seek(SHOTGUN_FIRE_START, true)
		viewmodel_anim_player.pause()
	viewmodel_animation_state = &"shotgun_idle"


func _apply_shotgun_sight_alignment(eased_blend: float) -> void:
	if viewmodel_visual == null:
		return
	var depth := _weapon_depth_factor()
	var t := clampf(eased_blend, 0.0, 1.0)
	viewmodel_visual.position = viewmodel_tune_position.lerp(shotgun_ready_position, t) * depth
	viewmodel_visual.rotation_degrees = viewmodel_tune_rotation.lerp(shotgun_ready_rotation, t)
	viewmodel_visual.scale = Vector3.ONE * (lerpf(viewmodel_tune_scale, shotgun_ready_scale, t) * depth)


func _check_room2_auto_equip() -> void:
	# Room 01 is the safe hub. Crossing into physical Room 02 begins Combat Room 01.
	if global_position.z <= ROOM2_EQUIP_Z:
		if not RunManager.run_active:
			RunManager.start_run(1)
			MusicManager.begin_combat_room()
		if not has_pistol:
			give_starting_pistol()


func _ammo_hud_text() -> String:
	if current_weapon_id == "knife":
		return "KNIFE"
	return "%s  %d / %d" % [_weapon_display_name(), ammo, reserve_ammo]


func _update_pistol_ammo_display() -> void:
	if current_weapon_id == "knife":
		# Melee: no digits anywhere (HUD, pause card).
		set_equipped_weapon_display(_weapon_display_name(), "")
	else:
		set_equipped_weapon_display(_weapon_display_name(), "%d / %d" % [ammo, reserve_ammo])
	if gameplay_hud != null:
		gameplay_hud.set_ammo(_ammo_hud_text(), has_pistol)
	elif ammo_label != null:
		ammo_label.visible = has_pistol
		ammo_label.text = _ammo_hud_text()


func _start_reload(from_pending: bool = false) -> void:
	if not has_pistol or is_reloading or reload_pending_timer > 0.0:
		return
	if current_weapon_id == "knife" or quick_knife_active or crossbow_bash_active:
		return
	if current_weapon_id == "shotgun" and (shotgun_action == &"fire" or shotgun_action == &"pump"):
		reload_pending_timer = maxf(shot_cooldown, 0.12)
		return
	# The sawn-offs' forced break-reload has already waited out the left-barrel
	# clip; the visual clip can trail that wait by a few frames, and deferring
	# again used to leave the empty gun without a reload.
	var forced_break := from_pending and current_weapon_id in ["sawnoffs", "sawnoff"]
	if _is_extra_weapon() and packed_section_playing and packed_action == &"fire" and not forced_break:
		reload_pending_timer = maxf(packed_section_end - viewmodel_anim_player.current_animation_position, 0.05) if viewmodel_anim_player != null else 0.2
		return
	if ammo >= _weapon_mag_capacity() or reserve_ammo <= 0:
		if _weapon_clicks_when_empty():
			_play_weapon_empty_click()
		return
	is_reloading = true
	ads_pending_initial_shot = false
	# Uzi reload is only the reload clip. Do not lerp sights or play Ready_To_Fire.
	_cancel_ads(_weapon_uses_full_depth())
	shot_cooldown = maxf(shot_cooldown, 0.12)
	if current_weapon_id == "shotgun":
		_start_shotgun_reload()
		return
	if _is_extra_weapon():
		_start_extra_reload()
		return
	var reload_clip: StringName = PISTOL_RELOAD_ANIMATION
	var reload_speed := PISTOL_RELOAD_SPEED
	var empty_reload := false
	if current_weapon_id == "uzi":
		empty_reload = ammo <= 0
		reload_clip = UZI_ANIM_RELOAD_EMPTY if empty_reload else UZI_ANIM_RELOAD
		reload_speed = 1.0
	var animation_duration: float = 2.20
	if viewmodel_anim_player != null and viewmodel_anim_player.has_animation(reload_clip):
		var reload_animation := viewmodel_anim_player.get_animation(reload_clip)
		if reload_animation != null:
			animation_duration = reload_animation.length / reload_speed
		viewmodel_anim_player.stop()
		viewmodel_anim_player.play(reload_clip, 0.10, reload_speed)
		viewmodel_anim_player.seek(0.0, true)
		viewmodel_animation_state = reload_clip
	reload_timer = animation_duration
	if current_weapon_id == "uzi":
		_play_uzi_reload_sfx(empty_reload)
	elif reload_audio != null:
		reload_audio.stop()
		reload_audio.play()


func _start_shotgun_reload() -> void:
	shotgun_reload_needed = mini(_weapon_mag_capacity() - ammo, reserve_ammo)
	shotgun_reload_total = shotgun_reload_needed
	shotgun_empty_reload = ammo <= 0
	if shotgun_reload_needed <= 0:
		is_reloading = false
		return
	var insert_speed := (SHOTGUN_RELOAD_END - SHOTGUN_RELOAD_START) / SHOTGUN_RELOAD_INSERT_TIME
	_play_shotgun_section(&"reload", SHOTGUN_RELOAD_START, SHOTGUN_RELOAD_END, 0.10, insert_speed)
	reload_timer = SHOTGUN_RELOAD_INSERT_TIME
	if shotgun_reload_needed >= 3:
		_play_shotgun_reload_sequence()
	elif shotgun_reload_needed == 2 and shotgun_reload_audio != null:
		shotgun_reload_audio.stop()
		shotgun_reload_audio.pitch_scale = randf_range(0.985, 1.02)
		shotgun_reload_audio.play()
	else:
		_play_shotgun_insert_sfx()


func _play_uzi_reload_sfx(empty_reload: bool) -> void:
	if empty_reload:
		if uzi_reload_empty_audio != null:
			uzi_reload_empty_audio.stop()
			uzi_reload_empty_audio.pitch_scale = randf_range(0.985, 1.02)
			# Empty clip is 3.70s; audio events sit ~0.45s in so mag-out / mag-in / bolt land on the hands.
			_play_stream_delayed(uzi_reload_empty_audio, 0.42)
		if uzi_mag_tap_audio != null:
			uzi_mag_tap_audio.pitch_scale = randf_range(0.97, 1.04)
		_play_stream_delayed(uzi_mag_tap_audio, 1.62)
	else:
		if uzi_reload_audio != null:
			uzi_reload_audio.stop()
			uzi_reload_audio.pitch_scale = randf_range(0.985, 1.02)
			# Tactical clip is 2.03s; delay so mag-out / mag-in hit the animated hands.
			_play_stream_delayed(uzi_reload_audio, 0.24)
		if uzi_mag_tap_audio != null:
			uzi_mag_tap_audio.pitch_scale = randf_range(0.97, 1.04)
		_play_stream_delayed(uzi_mag_tap_audio, 1.46)


func _play_stream_delayed(player: AudioStreamPlayer, delay: float) -> void:
	if player == null:
		return
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(self) or not is_reloading:
		return
	player.stop()
	player.play()


func _play_uzi_empty_click() -> void:
	_play_weapon_empty_click()


func _play_weapon_empty_click() -> void:
	if empty_click_cooldown > 0.0:
		return
	if _is_extra_weapon():
		_play_extra_empty_click()
		return
	if current_weapon_id == "shotgun":
		var click := shotgun_dry_fire_audio if randf() < 0.35 and shotgun_dry_fire_audio != null else shotgun_empty_click_audio
		if click == null:
			click = shotgun_empty_click_audio
		if click == null:
			return
		click.stop()
		click.pitch_scale = randf_range(0.97, 1.04)
		click.play()
		empty_click_cooldown = 0.22
		return
	if uzi_empty_click_audio == null:
		return
	uzi_empty_click_audio.stop()
	uzi_empty_click_audio.pitch_scale = randf_range(0.97, 1.04)
	uzi_empty_click_audio.play()
	empty_click_cooldown = 0.22


func _update_reload(delta: float) -> void:
	if reload_pending_timer > 0.0:
		reload_pending_timer = maxf(0.0, reload_pending_timer - delta)
		if reload_pending_timer <= 0.0:
			_start_reload(true)
	if not is_reloading:
		return
	# Reload owns the animation state and always cancels ADS until the magazine is seated.
	_cancel_ads(false)
	reload_timer = maxf(0.0, reload_timer - delta)
	if reload_timer <= 0.0:
		_finish_reload()


func _finish_reload() -> void:
	if not is_reloading:
		return
	if current_weapon_id == "shotgun":
		_finish_shotgun_reload_shell()
		return
	var rounds_needed: int = _weapon_mag_capacity() - ammo
	var rounds_loaded: int = mini(rounds_needed, reserve_ammo)
	ammo += rounds_loaded
	reserve_ammo -= rounds_loaded
	is_reloading = false
	reload_timer = 0.0
	_update_pistol_ammo_display()
	if _is_extra_weapon():
		_finish_extra_reload()
		return
	if current_weapon_id == "uzi":
		# Stay on the reload clip's end pose. Do not run Ready_To_Fire / sight adjust.
		if fire_touch_id != -1 or desktop_fire_held:
			ads_requested = true
			ads_pending_initial_shot = false
			ads_fire_delay_remaining = 0.0
			ads_blend = 1.0
			_hold_uzi_ready_pose()
			_apply_uzi_sight_alignment(1.0)
		return
	# If the player kept holding SHOOT during the reload, immediately rebuild ADS
	# and resume firing through the normal fire-delay/cooldown path.
	if fire_touch_id != -1 or desktop_fire_held:
		_begin_fire_input()


func _finish_shotgun_reload_shell() -> void:
	if reserve_ammo > 0 and ammo < _weapon_mag_capacity():
		ammo += 1
		reserve_ammo -= 1
		shotgun_reload_needed = maxi(0, shotgun_reload_needed - 1)
		_update_pistol_ammo_display()
	if shotgun_reload_needed > 0 and reserve_ammo > 0 and ammo < _weapon_mag_capacity():
		var insert_speed := (SHOTGUN_RELOAD_END - SHOTGUN_RELOAD_START) / SHOTGUN_RELOAD_INSERT_TIME
		_play_shotgun_section(&"reload", SHOTGUN_RELOAD_START, SHOTGUN_RELOAD_END, 0.06, insert_speed)
		if shotgun_reload_total >= 3 and (shotgun_reload_total - shotgun_reload_needed) >= 2:
			_play_shotgun_insert_sfx()
		reload_timer = SHOTGUN_RELOAD_INSERT_TIME
		return
	is_reloading = false
	reload_timer = 0.0
	shotgun_reload_needed = 0
	shotgun_reload_total = 0
	if shotgun_reload_sequence_audio != null:
		shotgun_reload_sequence_audio.stop()
	if shotgun_reload_audio != null:
		shotgun_reload_audio.stop()
	_play_shotgun_section(&"pump", SHOTGUN_PUMP_START, SHOTGUN_PUMP_END, 0.08, 1.0)
	_play_shotgun_pump_sfx()
	shotgun_empty_reload = false
	if fire_touch_id != -1 or desktop_fire_held:
		_begin_fire_input()


func _begin_fire_input() -> void:
	if game_over or get_tree().paused or not has_pistol or is_reloading or weapon_intro_locked or weapon_choice_active:
		return
	if crossbow_bash_active:
		return
	if sprint_active:
		# Shooting breaks the running stance first. Keep the touch captured, suppress
		# sprint until its input is released, and fire after the combat pose begins.
		sprint_exit_fire_pending = true
		sprint_suppressed_for_combat = true
		mobile_sprint = false
		return
	if _extra_begin_fire_input():
		return
	if ammo <= 0:
		if _weapon_clicks_when_empty() and reserve_ammo <= 0:
			_play_weapon_empty_click()
			return
		_start_reload()
		return
	ads_requested = fire_touch_id != -1 or desktop_fire_held
	ads_pending_initial_shot = true
	ads_fire_delay_remaining = ads_fire_delay
	ads_release_hold_remaining = ads_post_shot_hold
	# The authored ready clip now visibly establishes the two-hand aiming pose.
	# Procedural ADS handles screen alignment; the GLB clip handles the hands.
	if current_weapon_id == "shotgun":
		ads_fire_delay_remaining = maxf(0.04, (1.0 - ads_blend) * SHOTGUN_ADS_ENTER_TIME)
	elif _extra_has_ads():
		ads_fire_delay_remaining = maxf(0.04, (1.0 - ads_blend) * float(_extra_vm().get("ads_in", 0.16)))
	elif current_weapon_id == "uzi":
		var ready_clip := _uzi_ready_clip()
		var already_up := viewmodel_animation_state == &"ready_hold" or viewmodel_animation_state == UZI_ANIM_FIRE
		if already_up:
			ads_pending_initial_shot = false
			ads_fire_delay_remaining = 0.0
		else:
			ads_fire_delay_remaining = maxf(0.05, (1.0 - ads_blend) * UZI_ADS_ENTER_TIME)
		if viewmodel_animation_state != ready_clip and viewmodel_animation_state != UZI_ANIM_FIRE and viewmodel_animation_state != &"ready_hold":
			_play_viewmodel_animation(ready_clip, UZI_READY_BLEND, _uzi_ready_play_speed())
	elif viewmodel_anim_player != null and viewmodel_animation_state != PISTOL_FIRE_ANIMATION:
		_play_viewmodel_animation(PISTOL_READY_ANIMATION, 0.055, 2.8)


func _begin_fire_after_sprint_exit() -> void:
	if game_over or get_tree().paused or not has_pistol or is_reloading:
		return
	if _extra_begin_fire_input():
		return
	if ammo <= 0:
		if _weapon_clicks_when_empty() and reserve_ammo <= 0:
			_play_weapon_empty_click()
			return
		_start_reload()
		return
	ads_requested = fire_touch_id != -1 or desktop_fire_held
	ads_pending_initial_shot = true
	# Give the hands enough time to rebuild the two-handed support grip before
	# the shot occurs. AnimationPlayer blends from the sprint loop concurrently.
	ads_fire_delay_remaining = maxf(ads_fire_delay, 0.14)
	ads_release_hold_remaining = ads_post_shot_hold
	pistol_motion_state = PistolMotionState.SPRINT_EXIT
	pistol_motion_transition_timer = 0.18
	if viewmodel_anim_player != null:
		if current_weapon_id == "shotgun":
			ads_fire_delay_remaining = maxf(ads_fire_delay_remaining, (1.0 - ads_blend) * SHOTGUN_ADS_ENTER_TIME)
		elif _extra_has_ads():
			ads_fire_delay_remaining = maxf(ads_fire_delay_remaining, (1.0 - ads_blend) * float(_extra_vm().get("ads_in", 0.16)))
		elif current_weapon_id == "uzi":
			var ready_clip := _uzi_ready_clip()
			ads_fire_delay_remaining = maxf(ads_fire_delay_remaining, (1.0 - ads_blend) * UZI_ADS_ENTER_TIME)
			_play_viewmodel_animation(ready_clip, UZI_READY_BLEND, _uzi_ready_play_speed())
		else:
			_play_viewmodel_animation(PISTOL_READY_ANIMATION, 0.16, 1.55)


func _end_fire_input() -> void:
	var had_active_aim: bool = ads_requested or ads_pending_initial_shot or ads_blend > 0.01
	ads_requested = false
	if had_active_aim:
		ads_release_hold_remaining = maxf(ads_release_hold_remaining, ads_post_shot_hold)


func _cancel_ads(immediate: bool = false) -> void:
	aim_toggle_active = false
	ads_requested = false
	ads_pending_initial_shot = false
	ads_fire_delay_remaining = 0.0
	ads_release_hold_remaining = 0.0
	if immediate:
		ads_blend = 0.0
		aim_state = AimState.HIP
		_apply_ads_viewmodel_transform()


func _ads_should_be_active() -> bool:
	return aim_toggle_active or ads_requested or ads_pending_initial_shot or ads_release_hold_remaining > 0.0


func _update_ads(delta: float, sprinting: bool) -> void:
	if viewmodel_tune_enabled:
		ads_blend = 1.0 if viewmodel_tune_target == "ready" else 0.0
		aim_state = AimState.ADS if viewmodel_tune_target == "ready" else AimState.HIP
		_apply_ads_viewmodel_transform()
		_update_ads_crosshair_visibility()
		return
	if is_reloading and _weapon_uses_full_depth():
		ads_requested = false
		ads_pending_initial_shot = false
		ads_blend = 0.0
		aim_state = AimState.HIP
		if current_weapon_id == "uzi":
			_apply_uzi_sight_alignment(0.0)
		elif _is_extra_weapon():
			_apply_packed_sight_alignment(0.0)
		else:
			_apply_shotgun_sight_alignment(0.0)
		_update_ads_crosshair_visibility()
		return
	if current_weapon_id == "knife" or current_weapon_id == "minigun" or crossbow_bash_active:
		# No ADS pose. The knife keeps aim_toggle_active as its stab stance.
		if current_weapon_id == "minigun":
			aim_toggle_active = false
		ads_requested = false
		ads_pending_initial_shot = false
		ads_release_hold_remaining = 0.0
		ads_blend = move_toward(ads_blend, 0.0, delta / 0.12)
		aim_state = AimState.HIP if ads_blend <= 0.001 else AimState.EXITING_ADS
		_apply_ads_viewmodel_transform()
		_update_ads_crosshair_visibility()
		return

	if not has_pistol or game_over or get_tree().paused or death_sequence_active or sprinting:
		_cancel_ads(false)

	if not ads_requested and not ads_pending_initial_shot:
		ads_release_hold_remaining = maxf(0.0, ads_release_hold_remaining - delta)

	var target: float = 1.0 if _ads_should_be_active() else 0.0
	var enter_time: float = ads_enter_time
	var exit_time: float = ads_exit_time
	if current_weapon_id == "uzi":
		enter_time = UZI_ADS_ENTER_TIME
		exit_time = UZI_ADS_EXIT_TIME
	elif current_weapon_id == "shotgun":
		enter_time = SHOTGUN_ADS_ENTER_TIME
		exit_time = SHOTGUN_ADS_EXIT_TIME
	elif _extra_has_ads():
		enter_time = float(_extra_vm().get("ads_in", 0.16))
		exit_time = float(_extra_vm().get("ads_out", 0.18))
	var duration: float = enter_time if target > ads_blend else exit_time
	ads_blend = move_toward(ads_blend, target, delta / maxf(duration, 0.001))
	# Ease-out entering ADS and ease-in/out returning to hip.
	if ads_blend >= 0.999:
		ads_blend = 1.0
		aim_state = AimState.ADS
	elif ads_blend <= 0.001:
		ads_blend = 0.0
		aim_state = AimState.HIP
	elif target > ads_blend:
		aim_state = AimState.ENTERING_ADS
	else:
		aim_state = AimState.EXITING_ADS
	_apply_ads_viewmodel_transform()
	_update_ads_crosshair_visibility()


func _update_ads_crosshair_visibility() -> void:
	if gameplay_hud == null or gameplay_hud.crosshair == null:
		return
	var crosshair := gameplay_hud.crosshair
	# Hitscan stays on camera center. The Uzi shoot reticle is a small cross
	# on that same point. Pistol ADS still fades the hip dot.
	var target_alpha: float
	if current_weapon_id == "knife" or current_weapon_id == "minigun":
		# Hip weapons: the hitscan dot stays up.
		target_alpha = 1.0
		crosshair.text = "•"
		crosshair.add_theme_font_size_override("font_size", 20)
	elif current_weapon_id == "uzi" or current_weapon_id == "shotgun" or _extra_has_ads():
		target_alpha = clampf(ads_blend * 2.4, 0.0, 1.0)
		crosshair.text = "+"
		crosshair.add_theme_font_size_override("font_size", 22)
	else:
		target_alpha = clampf(1.0 - ads_blend * 4.0, 0.0, 1.0)
		crosshair.text = "•"
		crosshair.add_theme_font_size_override("font_size", 20)
	crosshair.modulate.a = target_alpha
	crosshair.visible = has_pistol and target_alpha > 0.01
	_apply_crosshair_aim_position()


func _apply_ads_viewmodel_transform() -> void:
	if viewmodel_visual == null or hip_anchor == null or ads_anchor == null:
		return
	if viewmodel_tune_enabled:
		_apply_viewmodel_tune()
		return
	var eased_blend: float
	if current_weapon_id == "uzi":
		_apply_uzi_sight_alignment(_ads_ease(ads_blend))
		return
	if current_weapon_id == "shotgun":
		_apply_shotgun_sight_alignment(_ads_ease(ads_blend))
		return
	if _is_extra_weapon():
		_apply_packed_sight_alignment(_ads_ease(ads_blend))
		return
	eased_blend = _ads_ease(ads_blend)

	# Hip comes from the same tune values as the Uzi/shotgun (loaded from the
	# PISTOL_* defaults or a current-version save), so there is one source.
	var pistol_depth := VIEWMODEL_DEPTH_FACTOR
	var pistol_hip_pos := viewmodel_tune_position * pistol_depth
	var pistol_hip_rot := viewmodel_tune_rotation
	var pistol_ads_pos := ads_position * pistol_depth
	var pistol_ads_rot := ads_rotation_degrees
	var pistol_hip_scale := viewmodel_tune_scale * pistol_depth
	var pistol_ads_scale := pistol_hip_scale * ads_scale_multiplier
	hip_anchor.position = pistol_hip_pos
	hip_anchor.rotation_degrees = pistol_hip_rot
	ads_anchor.position = pistol_ads_pos
	ads_anchor.rotation_degrees = pistol_ads_rot
	viewmodel_visual.position = hip_anchor.position.lerp(ads_anchor.position, eased_blend)
	viewmodel_visual.rotation_degrees = hip_anchor.rotation_degrees.lerp(
		ads_anchor.rotation_degrees,
		eased_blend
	)
	viewmodel_visual.scale = Vector3.ONE * lerpf(pistol_hip_scale, pistol_ads_scale, eased_blend)


## Hip <-> ready easing shared by every weapon: smootherstep has zero
## velocity and acceleration at both ends, so the pose neither pops out of
## hip nor snaps when it lands on the sights.
func _ads_ease(blend: float) -> float:
	var t := clampf(blend, 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


func _update_ads_fire(delta: float, sprinting: bool) -> void:
	if sprinting or game_over or get_tree().paused or death_sequence_active:
		return
	if ads_pending_initial_shot:
		ads_fire_delay_remaining = maxf(0.0, ads_fire_delay_remaining - delta)
		if ads_fire_delay_remaining <= 0.0:
			ads_pending_initial_shot = false
			_shoot()
		return
	# Preserve hold-to-fire accessibility with a deliberately paced semi-auto
	# trigger cadence. _shoot() owns the exposed interval and animation restart.
	if ads_requested and (fire_touch_id != -1 or desktop_fire_held):
		_shoot()


func _shoot() -> void:
	if game_over or get_tree().paused:
		return
	if sprint_active or is_reloading:
		return
	if not has_pistol or shot_cooldown > 0.0 or weapon_intro_locked or weapon_choice_active:
		return
	if current_weapon_id == "knife" or crossbow_bash_active:
		return
	if ammo <= 0:
		if _weapon_clicks_when_empty() and reserve_ammo <= 0:
			_play_weapon_empty_click()
			return
		if current_weapon_id != "minigun":
			_start_reload()
		return
	if viewmodel_tune_enabled:
		# Keep the editor open so shotgun / Uzi poses can be judged while firing.
		_save_viewmodel_settings()

	ammo -= 1
	_update_pistol_ammo_display()
	shots_fired += 1
	RunManager.register_shot()
	MusicManager.notify_combat_action(0.34)
	shot_cooldown = _weapon_shot_interval()
	aim_hold_timer = ads_post_shot_hold
	ads_release_hold_remaining = maxf(ads_release_hold_remaining, ads_post_shot_hold)
	_mobile_shoot_feedback()
	_play_weapon_shot_sfx()

	# The GLB owns the mechanical slide; this is the body absorbing the shot.
	_apply_shot_recoil()
	muzzle_flash_time = 0.055
	if muzzle_light != null:
		muzzle_light.light_energy = 5.5
	if viewmodel_anim_player != null:
		if current_weapon_id == "uzi":
			# Ready-to-aim is the fire stance. Do not swap to the authored Fire
			# clip — it pulls the gun off the locked sights.
			_hold_uzi_ready_pose()
		elif current_weapon_id == "shotgun":
			_play_shotgun_section(&"fire", SHOTGUN_FIRE_START, SHOTGUN_FIRE_END, 0.02, 1.18)
		elif _is_extra_weapon():
			_extra_shoot_effects()
		else:
			var fire_clip: StringName = PISTOL_FIRE_ANIMATION
			if viewmodel_anim_player.has_animation(fire_clip):
				viewmodel_anim_player.stop()
				viewmodel_anim_player.play(fire_clip, 0.015, PISTOL_FIRE_SPEED)
				viewmodel_anim_player.seek(0.0, true)
				viewmodel_animation_state = fire_clip
				viewmodel_anim_player.advance(0.0)

	# Quick warm muzzle/screen flash.
	if shot_flash != null:
		shot_flash.color = Color(1.0, 0.72, 0.30, 0.20)
		var flash_tween := create_tween()
		flash_tween.tween_property(shot_flash, "color:a", 0.0, 0.055)

	if current_weapon_id == "shotgun":
		_fire_shotgun_pellets()
	elif _is_extra_weapon():
		_extra_fire_damage()
	else:
		_fire_hitscan_bullet(UpgradeManager.get_weapon_damage(current_weapon_id))
	# The kick is shown only after the ray has left the un-kicked camera, so
	# every shot lands on the crosshair it was fired from.
	_write_camera_recoil()

	# Let the last shot finish its slide / pump cycle before beginning reload.
	if ammo <= 0 and reserve_ammo > 0:
		if current_weapon_id == "minigun":
			pass   # Spin state machine reloads once the trigger lets go.
		elif _is_extra_weapon():
			reload_pending_timer = _extra_empty_reload_delay()
		else:
			reload_pending_timer = 1.12 if current_weapon_id == "shotgun" else 0.16


func _get_aim_screen_position() -> Vector2:
	# Gameplay ray and the shoot cross both use exact camera center.
	return get_viewport().get_visible_rect().size * 0.5


func _fire_hitscan_bullet(damage: float, aim_dir: Vector3 = Vector3.ZERO) -> Dictionary:
	var aim_screen_position := _get_aim_screen_position()
	var from := camera.project_ray_origin(aim_screen_position)
	var direction := aim_dir
	if direction == Vector3.ZERO:
		direction = camera.project_ray_normal(aim_screen_position)
	var to := from + direction * 100.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 1 | 8 | 32
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {}
	var collider = hit.get("collider")
	var damage_target: Object = collider
	var is_headshot: bool = false
	if collider is Area3D and bool(collider.get_meta("zombie_head_hitbox", false)):
		is_headshot = true
		damage_target = collider.get_parent()
	if damage_target != null and damage_target.has_method("receive_bullet_hit"):
		shots_hit += 1
		RunManager.register_hit(is_headshot)
		damage_target.call(
			"receive_bullet_hit",
			damage,
			hit.get("position", to),
			from,
			is_headshot,
			hit.get("normal", Vector3.ZERO)
		)
	elif damage_target != null and damage_target.has_method("take_damage"):
		shots_hit += 1
		RunManager.register_hit(is_headshot)
		damage_target.call("take_damage", damage)
	hit["damage_target"] = damage_target
	hit["is_headshot"] = is_headshot
	return hit


func _fire_shotgun_pellets() -> void:
	var aim_screen_position := _get_aim_screen_position()
	var from := camera.project_ray_origin(aim_screen_position)
	var aim_dir := camera.project_ray_normal(aim_screen_position)
	var spread := lerpf(SHOTGUN_SPREAD_HIP, SHOTGUN_SPREAD_ADS, ads_blend)
	var pellet_damage := UpgradeManager.get_weapon_damage("shotgun") / float(SHOTGUN_PELLETS)
	var grouped: Dictionary = {}
	for _pellet in range(SHOTGUN_PELLETS):
		var dir := aim_dir.rotated(camera.global_basis.x, randf_range(-spread, spread))
		dir = dir.rotated(camera.global_basis.y, randf_range(-spread, spread)).normalized()
		var to := from + dir * 100.0
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [self]
		query.collision_mask = 1 | 8 | 32
		query.collide_with_areas = true
		query.collide_with_bodies = true
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		var collider = hit.get("collider")
		var damage_target: Object = collider
		var is_headshot: bool = false
		if collider is Area3D and bool(collider.get_meta("zombie_head_hitbox", false)):
			is_headshot = true
			damage_target = collider.get_parent()
		if damage_target == null:
			continue
		var key := damage_target.get_instance_id()
		if not grouped.has(key):
			grouped[key] = {
				"target": damage_target,
				"damage": 0.0,
				"position": hit.get("position", to),
				"normal": hit.get("normal", Vector3.ZERO),
				"headshot": false,
				"pellet_hits": PackedVector3Array(),
			}
		grouped[key]["damage"] += pellet_damage * (2.0 if is_headshot else 1.0)
		var pellet_hits: PackedVector3Array = grouped[key]["pellet_hits"]
		pellet_hits.append(hit.get("position", to))
		grouped[key]["pellet_hits"] = pellet_hits
		if is_headshot:
			grouped[key]["headshot"] = true
	for entry in grouped.values():
		var damage_target: Object = entry["target"]
		if damage_target.has_method("receive_bullet_hit"):
			shots_hit += 1
			RunManager.register_hit(bool(entry["headshot"]))
			damage_target.set_meta("blood_pellet_hits", entry["pellet_hits"])
			# Headshot bonus is already folded into damage so the zombie
			# method does not double it.
			damage_target.call(
				"receive_bullet_hit",
				entry["damage"],
				entry["position"],
				from,
				false,
				entry["normal"]
			)
		elif damage_target.has_method("take_damage"):
			shots_hit += 1
			RunManager.register_hit(bool(entry["headshot"]))
			damage_target.call("take_damage", entry["damage"])


func _apply_crosshair_aim_position() -> void:
	if gameplay_hud == null or gameplay_hud.crosshair == null:
		return
	var crosshair := gameplay_hud.crosshair
	var aim := _get_aim_screen_position()
	# + sits slightly high in the label box; a 1px drop puts the junction
	# on the hitscan.
	var optical := Vector2(0.0, 1.0) if current_weapon_id == "uzi" or current_weapon_id == "shotgun" or _extra_has_ads() else Vector2(0.0, 1.5)
	crosshair.position = aim - crosshair.size * 0.5 + optical

func _is_mobile_ui() -> bool:
	# Real mobile behavior only. Do NOT make the Godot desktop debugger behave
	# like iOS, otherwise mouse capture / desktop shooting / editor controls break.
	return OS.has_feature("mobile") or OS.get_name() == "iOS" or OS.get_name() == "Android"

func _should_show_mobile_hud() -> bool:
	return _is_mobile_ui() or (show_mobile_hud_in_editor and OS.has_feature("editor"))

func _layout_gameplay_hud() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	# Final layout matched against the approved 1672x941 reference.
	var s: float = viewport_size.y / 941.0

	if health_root != null:
		health_root.layout_mode = 3
		health_root.size = Vector2(466.0, 82.0)
		health_root.scale = Vector2.ONE * s
		health_root.position = Vector2(42.0 * s, 31.0 * s)

	if sprint_bar_root != null:
		sprint_bar_root.layout_mode = 3
		sprint_bar_root.size = Vector2(420.0, 140.0)
		sprint_bar_root.scale = Vector2.ONE * s
		sprint_bar_root.position = Vector2(42.0 * s, 111.0 * s)
		sprint_bar_root.z_index = 180

	if timer_root != null:
		timer_root.layout_mode = 3
		timer_root.size = Vector2(306.0, 80.0)
		timer_root.scale = Vector2.ONE * s
		timer_root.position = Vector2(
			(viewport_size.x - timer_root.size.x * s) * 0.5,
			31.0 * s
		)

	if bank_root != null:
		bank_root.layout_mode = 3
		bank_root.size = Vector2(342.0, 76.0)
		bank_root.scale = Vector2.ONE * s
		bank_root.position = Vector2(
			viewport_size.x - bank_root.size.x * s - 44.0 * s,
			31.0 * s
		)

	if ammo_label != null:
		ammo_label.layout_mode = 3
		ammo_label.position = Vector2(viewport_size.x - 300.0 * s, 116.0 * s)
		ammo_label.size = Vector2(185.0, 32.0) * s
		ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ammo_label.add_theme_font_size_override("font_size", int(round(18.0 * s)))

func _layout_mobile_action_buttons() -> void:
	if not _should_show_mobile_hud():
		_layout_gameplay_hud()
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	_layout_gameplay_hud()
	var pause_open: bool = get_tree().paused and not game_over and not ControlSettingsManager.suspend_hud_layout
	if gameplay_hud != null:
		gameplay_hud.set_meta("preserve_live_joystick", joystick_touch_id != -1 or joystick_mouse_dragging)
		gameplay_hud.apply_saved_control_layout(joystick_touch_id == -1 and not joystick_mouse_dragging, false)
		joystick_radius = gameplay_hud.joystick_radius
		joystick_rest_position = gameplay_hud.joystick_rest_position

	if joystick_base != null:
		joystick_base.visible = joystick_base.visible and not pause_open
	if joystick_knob != null:
		joystick_knob.visible = joystick_knob.visible and not pause_open
	if shoot_button != null:
		var weapon_is_visibly_equipped: bool = has_pistol
		if viewmodel_visual != null and viewmodel_visual.visible:
			weapon_is_visibly_equipped = true
		shoot_button.visible = (
			not pause_open
			and ControlSettingsManager.control_visible("shoot")
			and (weapon_is_visibly_equipped or OS.has_feature("editor"))
		)
	if jump_button != null:
		jump_button.visible = not pause_open and ControlSettingsManager.control_visible("jump")
	if sprint_button != null:
		sprint_button.visible = not pause_open and ControlSettingsManager.control_visible("sprint")
	if gameplay_hud != null:
		for control_id in gameplay_hud.round_buttons.keys():
			var round_button := gameplay_hud.round_buttons[control_id] as Control
			var needs_weapon: bool = control_id == "aim" or control_id == "reload"
			round_button.visible = (
				not pause_open
				and not game_over
				and ControlSettingsManager.control_visible(control_id)
				and (has_pistol or not needs_weapon)
			)
		gameplay_hud.set_round_button_active("aim", aim_toggle_active)
		gameplay_hud.set_round_button_active("crouch", crouch_active)
	_refresh_swap_button()

	last_mobile_viewport_size = viewport_size

func _point_in_joystick(screen_pos: Vector2) -> bool:
	if joystick_base == null:
		return false
	var center: Vector2 = joystick_base.position + joystick_base.size * 0.5
	return screen_pos.distance_to(center) <= joystick_base.size.x * 0.50 * ControlSettingsManager.joystick_activation_radius


func _point_in_movement_input(screen_pos: Vector2) -> bool:
	var mode := ControlSettingsManager.movement_mode
	if mode == ControlSettingsManager.MODE_FIXED:
		return _point_in_joystick(screen_pos)
	return _point_in_saved_zone("movement_zone", screen_pos)


func _point_in_look_zone(screen_pos: Vector2) -> bool:
	return _point_in_saved_zone("look_zone", screen_pos)


func _point_in_saved_zone(zone_id: String, screen_pos: Vector2) -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	return ControlSettingsManager.point_in_control(zone_id, screen_pos, viewport_size)


func _point_in_action_button(screen_pos: Vector2) -> bool:
	if gameplay_hud != null and gameplay_hud.door_interact_button != null and gameplay_hud.door_interact_button.visible:
		if gameplay_hud.door_interact_button.get_global_rect().grow(12.0).has_point(screen_pos):
			return true
	return (
		_point_in_fire_button(screen_pos)
		or _point_in_jump_button(screen_pos)
		or _point_in_sprint_button(screen_pos)
		or _point_in_swap_button(screen_pos)
		or _point_in_pause_button(screen_pos)
		or _round_button_at(screen_pos) != ""
	)


func _point_in_fire_button(screen_pos: Vector2) -> bool:
	if shoot_button == null or not shoot_button.visible:
		return false
	return shoot_button.get_global_rect().grow(22.0).has_point(screen_pos)

func _point_in_jump_button(screen_pos: Vector2) -> bool:
	if jump_button == null or not jump_button.visible:
		return false
	return jump_button.get_global_rect().grow(18.0).has_point(screen_pos)

func _point_in_sprint_button(screen_pos: Vector2) -> bool:
	if sprint_button == null or not sprint_button.visible:
		return false
	return sprint_button.get_global_rect().grow(20.0).has_point(screen_pos)

func _point_in_swap_button(screen_pos: Vector2) -> bool:
	if swap_button == null or not swap_button.visible:
		return false
	return swap_button.get_global_rect().grow(16.0).has_point(screen_pos)

func _point_in_pause_button(screen_pos: Vector2) -> bool:
	if pause_button == null or not pause_button.visible:
		return false
	return pause_button.get_global_rect().grow(10.0).has_point(screen_pos)


func _round_button_at(screen_pos: Vector2) -> String:
	if gameplay_hud == null:
		return ""
	for control_id in gameplay_hud.round_buttons.keys():
		var widget := gameplay_hud.round_buttons[control_id] as Control
		if widget != null and widget.visible and widget.get_global_rect().grow(14.0).has_point(screen_pos):
			return String(control_id)
	return ""


func _try_round_button_tap(screen_pos: Vector2) -> bool:
	var control_id := _round_button_at(screen_pos)
	if control_id == "":
		return false
	var widget := gameplay_hud.get_action_widget(control_id)
	match control_id:
		"aim":
			_set_aim_toggle(not aim_toggle_active)
		"reload":
			_start_reload()
		"crouch":
			_toggle_crouch()
		"interact":
			_mobile_interact()
		"melee":
			# Knife equipped: slash (stab while AIM is on). Gun equipped with the
			# knife in the other slot: quick-stab, no swap. Otherwise nothing.
			_on_melee_pressed()
	if widget != null and gameplay_hud != null:
		gameplay_hud.pulse_button(widget, 0.9, 0.14)
	return true


func _set_aim_toggle(enabled: bool) -> void:
	if not enabled:
		aim_toggle_active = false
		return
	if game_over or get_tree().paused or not has_pistol or is_reloading or weapon_intro_locked or weapon_choice_active:
		return
	if current_weapon_id == "minigun":
		# No ADS on the minigun: aim does nothing.
		return
	if sprint_active:
		sprint_suppressed_for_combat = true
		mobile_sprint = false
	aim_toggle_active = true
	if _is_extra_weapon():
		return
	if current_weapon_id == "uzi":
		var ready_clip := _uzi_ready_clip()
		if viewmodel_animation_state != ready_clip and viewmodel_animation_state != UZI_ANIM_FIRE and viewmodel_animation_state != &"ready_hold":
			_play_viewmodel_animation(ready_clip, UZI_READY_BLEND, _uzi_ready_play_speed())
	elif current_weapon_id != "shotgun" and viewmodel_anim_player != null and viewmodel_animation_state != PISTOL_FIRE_ANIMATION:
		_play_viewmodel_animation(PISTOL_READY_ANIMATION, 0.055, 2.8)


func _toggle_crouch() -> void:
	if game_over or get_tree().paused:
		return
	crouch_active = not crouch_active
	if crouch_active:
		mobile_sprint = false


func _mobile_interact() -> void:
	# Upgrade benches first (safe hub), then the nearest blast door in range.
	if _try_upgrade_center_interaction():
		return
	if gameplay_hud != null:
		gameplay_hud.try_interact_nearest_door()


func _apply_gyro_look(delta: float) -> void:
	if not ControlSettingsManager.gyroscope_enabled or not _is_mobile_ui():
		return
	var rate := Input.get_gyroscope()
	if rate.length_squared() < 0.0004:
		return
	# Sensor axes are portrait-relative. In landscape the device X axis points
	# along world up, so yaw comes from X and pitch from Y; the sign flips
	# between the two landscape orientations.
	var orientation := DisplayServer.screen_get_orientation()
	var side := -1.0 if orientation == DisplayServer.SCREEN_REVERSE_LANDSCAPE or orientation == DisplayServer.SCREEN_SENSOR_LANDSCAPE and Input.get_accelerometer().x < 0.0 else 1.0
	var gain := ControlSettingsManager.gyroscope_sensitivity
	var y_sign := -1.0 if ControlSettingsManager.invert_y else 1.0
	rotation.y += rate.x * side * gain * delta
	pitch = clampf(pitch + rate.y * side * gain * y_sign * delta, deg_to_rad(-80.0), deg_to_rad(80.0))


## Gentle magnet toward a living zombie already near the reticle. Only runs for
## touch play while shooting or aiming, and only with Aim Assist on.
func _apply_aim_assist(delta: float) -> void:
	if not ControlSettingsManager.aim_assist or not _should_show_mobile_hud() or camera == null:
		return
	if fire_touch_id == -1 and not aim_toggle_active and ads_blend < 0.2:
		return
	var cam_pos := camera.global_position
	var forward := -camera.global_basis.z
	var best_angle := deg_to_rad(AIM_ASSIST_CONE_DEGREES)
	var best_dir := Vector3.ZERO
	var space := get_world_3d().direct_space_state
	for node in get_tree().get_nodes_in_group("zombies"):
		var zombie := node as Node3D
		if zombie == null or not zombie.is_visible_in_tree() or int(zombie.get("state")) == ZOMBIE_DEAD_STATE:
			continue
		var target := zombie.global_position + Vector3.UP * 1.3
		var to_target := target - cam_pos
		var distance := to_target.length()
		if distance < 0.5 or distance > AIM_ASSIST_RANGE:
			continue
		var dir := to_target / distance
		var angle := forward.angle_to(dir)
		if angle >= best_angle:
			continue
		var query := PhysicsRayQueryParameters3D.create(cam_pos, target, 1)
		query.exclude = [get_rid()]
		if zombie is CollisionObject3D:
			query.exclude.append((zombie as CollisionObject3D).get_rid())
		if not space.intersect_ray(query).is_empty():
			continue
		best_angle = angle
		best_dir = dir
	if best_dir == Vector3.ZERO:
		return
	var pull := clampf(AIM_ASSIST_STRENGTH * delta, 0.0, 1.0)
	var flat_forward := Vector3(forward.x, 0.0, forward.z).normalized()
	var flat_target := Vector3(best_dir.x, 0.0, best_dir.z).normalized()
	var yaw_error := atan2(flat_forward.cross(flat_target).y, flat_forward.dot(flat_target))
	rotation.y += yaw_error * pull
	var pitch_error := asin(clampf(best_dir.y, -1.0, 1.0)) - asin(clampf(forward.y, -1.0, 1.0))
	pitch = clampf(pitch + pitch_error * pull, deg_to_rad(-80.0), deg_to_rad(80.0))


func _begin_movement_touch(screen_pos: Vector2) -> void:
	movement_origin = screen_pos
	var mode := ControlSettingsManager.movement_mode
	if gameplay_hud != null:
		gameplay_hud.set_meta("preserve_live_joystick", true)
		gameplay_hud.set_meta("touch_zone_indicator_active", mode == ControlSettingsManager.MODE_TOUCH_ZONE)
	if mode == ControlSettingsManager.MODE_FLOATING or mode == ControlSettingsManager.MODE_TOUCH_ZONE:
		_place_live_joystick(screen_pos)
	_set_joystick_screen(screen_pos)


func _update_movement_touch(screen_pos: Vector2) -> void:
	_set_joystick_screen(screen_pos)


func _end_movement_touch() -> void:
	_reset_joystick()
	if gameplay_hud != null:
		gameplay_hud.set_meta("preserve_live_joystick", false)
		gameplay_hud.set_meta("touch_zone_indicator_active", false)
		gameplay_hud.apply_saved_control_layout(true, true)


func _place_live_joystick(screen_pos: Vector2) -> void:
	if joystick_base == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var size := ControlSettingsManager.pixel_size("joystick", viewport_size)
	var pos := ControlSettingsManager.clamp_position(screen_pos - size * 0.5, size, viewport_size)
	joystick_base.position = pos
	joystick_base.size = size
	joystick_base.visible = true
	joystick_radius = size.x * (82.0 / 282.0)
	if joystick_knob != null:
		joystick_knob.size = size * (116.0 / 282.0)
		joystick_knob.pivot_offset = joystick_knob.size * 0.5
		joystick_knob.visible = true
		joystick_knob.modulate.a = 0.72 if ControlSettingsManager.movement_mode == ControlSettingsManager.MODE_TOUCH_ZONE else ControlSettingsManager.control_opacity("joystick")
	if ControlSettingsManager.movement_mode == ControlSettingsManager.MODE_TOUCH_ZONE and not ControlSettingsManager.show_touch_zone_indicator:
		joystick_base.visible = false
		if joystick_knob != null:
			joystick_knob.visible = false


func _ensure_control_layout_editor() -> void:
	if control_layout_editor != null or gameplay_hud == null:
		return
	control_layout_editor = ControlLayoutEditor.new()
	control_layout_editor.name = "ControlLayoutEditor"
	gameplay_hud.add_child(control_layout_editor)


func _open_control_layout_editor() -> void:
	_ensure_control_layout_editor()
	if control_layout_editor == null:
		return
	joystick_touch_id = -1
	look_touch_id = -1
	fire_touch_id = -1
	jump_touch_id = -1
	sprint_touch_id = -1
	mobile_sprint = false
	_reset_joystick_immediate()
	control_layout_editor.open_editor(gameplay_hud, pause_menu)


func _sync_look_from_control_settings() -> void:
	if not FileAccess.file_exists(ControlSettingsManager.SETTINGS_PATH):
		ControlSettingsManager.look_sensitivity_h = touch_look_sensitivity
		ControlSettingsManager.look_sensitivity_v = touch_look_sensitivity
		ControlSettingsManager.save_settings()
	touch_look_sensitivity = ControlSettingsManager.look_sensitivity_h


func _on_control_settings_changed() -> void:
	touch_look_sensitivity = ControlSettingsManager.look_sensitivity_h
	haptics_enabled = ControlSettingsManager.haptics_enabled
	if gameplay_hud != null and not ControlSettingsManager.suspend_hud_layout:
		gameplay_hud.apply_saved_control_layout(joystick_touch_id == -1 and not joystick_mouse_dragging, true)

func set_equipped_weapon_display(weapon_name: String, ammo_text: String = "") -> void:
	# Rifle, bat, and future weapon scripts can call this without changing the
	# pause menu.  Pass an empty ammo string for melee weapons.
	equipped_weapon_display_name = weapon_name.strip_edges().to_upper()
	equipped_weapon_ammo_display = ammo_text.strip_edges()
	if pause_menu != null:
		pause_menu.refresh_stats(
			equipped_weapon_display_name,
			equipped_weapon_ammo_display,
			EconomyManager.get_balance(),
			RunManager.elapsed_time
		)

func _on_pause_sensitivity_changed(value: float) -> void:
	touch_look_sensitivity = float(value)
	ControlSettingsManager.set_look_sensitivity(touch_look_sensitivity, ControlSettingsManager.look_sensitivity_v, false)
	_save_mobile_ui_settings()

func _on_pause_haptics_toggled(enabled: bool) -> void:
	haptics_enabled = enabled
	ControlSettingsManager.set_haptics_enabled(enabled, false)
	_save_mobile_ui_settings()

func _save_mobile_ui_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("mobile_ui", "touch_look_sensitivity", touch_look_sensitivity)
	config.set_value("mobile_ui", "haptics_enabled", haptics_enabled)
	var err: Error = config.save(MOBILE_UI_CONFIG_PATH)
	if err != OK:
		push_warning("Could not save mobile UI settings: %s" % error_string(err))

func _load_mobile_ui_settings() -> void:
	var config := ConfigFile.new()
	var err: Error = config.load(MOBILE_UI_CONFIG_PATH)
	if err != OK:
		return
	touch_look_sensitivity = float(config.get_value("mobile_ui", "touch_look_sensitivity", touch_look_sensitivity))
	haptics_enabled = bool(config.get_value("mobile_ui", "haptics_enabled", true))

func _toggle_pause_menu() -> void:
	if game_over:
		return
	if ControlSettingsManager.suspend_hud_layout and control_layout_editor != null:
		control_layout_editor.close_editor(false)
		return
	desktop_fire_held = false
	fire_touch_id = -1
	jump_touch_id = -1
	_cancel_ads(true)
	if get_tree().paused:
		_resume_game()
	else:
		get_tree().paused = true
		MusicManager.set_paused_duck(true)
		if pause_menu != null:
			pause_menu.show_pause(
				equipped_weapon_display_name if not equipped_weapon_display_name.is_empty() else ("PISTOL" if has_pistol else ""),
				equipped_weapon_ammo_display if not equipped_weapon_ammo_display.is_empty() else ("∞" if has_pistol and unlimited_ammo else ""),
				EconomyManager.get_balance(),
				RunManager.elapsed_time,
				touch_look_sensitivity,
				haptics_enabled,
				{
					"health": health,
					"max_health": max_health,
					"kills": zombies_killed,
					"shots_fired": shots_fired,
					"shots_hit": shots_hit,
					"damage_taken": damage_taken,
					"weapon_id": current_weapon_id if has_pistol else "",
					"secondary_id": _swap_target_weapon_id(),
					"ammo": ammo,
					"reserve": reserve_ammo,
					"unlimited": unlimited_ammo,
					"shot_interval": _weapon_shot_interval(),
					"sustained_interval": _weapon_sustained_interval(),
				}
			)
		elif pause_overlay != null:
			pause_overlay.visible = true
		_set_desktop_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_reset_joystick()

func _resume_game() -> void:
	if pause_menu != null:
		pause_menu.hide_pause()
	elif pause_overlay != null:
		pause_overlay.visible = false
	get_tree().paused = false
	MusicManager.set_paused_duck(false)
	_set_desktop_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _make_death_thump_stream(duration: float, frequency: float, strength: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var sample_count: int = maxi(1, int(duration * float(sample_rate)))
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)

	for i in range(sample_count):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = exp(-t * 18.0)
		var fundamental: float = sin(TAU * frequency * t)
		var harmonic: float = sin(TAU * frequency * 0.52 * t) * 0.34
		var sample: float = clampf((fundamental + harmonic) * envelope * strength, -1.0, 1.0)
		var value: int = int(round(sample * 32767.0))
		pcm.encode_s16(i * 2, value)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

func _play_random_death_vocal() -> void:
	if death_vocal_audio == null or death_vocal_streams.is_empty():
		return

	var index: int = randi_range(0, death_vocal_streams.size() - 1)
	if death_vocal_streams.size() > 1 and index == last_death_vocal_index:
		index = (index + 1 + randi_range(0, death_vocal_streams.size() - 2)) % death_vocal_streams.size()

	last_death_vocal_index = index
	death_vocal_audio.stop()
	death_vocal_audio.stream = death_vocal_streams[index]
	death_vocal_audio.pitch_scale = randf_range(0.985, 1.015)
	death_vocal_audio.volume_db = -3.5
	death_vocal_audio.play()


func _start_death_sequence() -> void:
	if death_sequence_active or game_over:
		return

	death_sequence_active = true
	_stop_low_health_audio()
	_cancel_ads(true)
	is_reloading = false
	reload_timer = 0.0
	reload_pending_timer = 0.0
	if reload_audio != null:
		reload_audio.stop()
	_reset_lateral_camera_inertia()
	_reset_melee_camera_effects()
	MusicManager.death_sequence()
	health = 0.0
	_update_health_ui()
	RunManager.end_run(false)
	elapsed_time = RunManager.elapsed_time

	# 0.0 sec — kill all control immediately.
	velocity = Vector3.ZERO
	jump_requested = false
	_kill_jump_tweens()
	jump_offset.position = Vector3.ZERO
	jump_offset.rotation = Vector3.ZERO
	jump_weapon_position_offset = Vector3.ZERO
	jump_weapon_rotation_offset = Vector3.ZERO
	mobile_move_input = Vector2.ZERO
	smoothed_move_input = Vector2.ZERO
	joystick_touch_id = -1
	joystick_mouse_dragging = false
	look_touch_id = -1
	fire_touch_id = -1
	desktop_fire_held = false
	_reset_joystick()
	_set_desktop_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	death_camera_start_pivot = camera_pivot.position
	death_camera_start_rotation = camera.rotation
	if viewmodel_root != null:
		death_viewmodel_start_position = viewmodel_root.position
		death_viewmodel_start_rotation = viewmodel_root.rotation

	if death_overlay != null:
		death_overlay.visible = true
	if death_vignette != null:
		death_vignette.modulate.a = 0.0
	_set_death_eyelids(0.0)

	if death_impact_audio != null:
		death_impact_audio.play()
	_play_random_death_vocal()
	if _is_mobile_ui() and haptics_enabled:
		Input.vibrate_handheld(90, 0.92)

	# Lethal impact kick — small backward/head recoil.
	var impact_tween: Tween = create_tween()
	impact_tween.set_parallel(true)
	impact_tween.set_trans(Tween.TRANS_QUAD)
	impact_tween.set_ease(Tween.EASE_OUT)
	impact_tween.tween_property(camera_pivot, "position:z", death_camera_start_pivot.z + 0.075, 0.11)
	impact_tween.tween_property(camera, "rotation:x", death_camera_start_rotation.x + deg_to_rad(-4.0), 0.11)

	if viewmodel_root != null:
		impact_tween.tween_property(viewmodel_root, "position", death_viewmodel_start_position + Vector3(0.03, -0.10, 0.03), 0.13)
		impact_tween.tween_property(viewmodel_root, "rotation", death_viewmodel_start_rotation + Vector3(deg_to_rad(12.0), 0.0, deg_to_rad(7.0)), 0.13)

	await get_tree().create_timer(0.15).timeout
	if not death_sequence_active:
		return

	_fade_gameplay_hud_for_death()
	_enable_death_audio_muffle()
	var fall_roll: float = deg_to_rad(28.0 if randf() > 0.5 else -28.0)

	# 0.15–0.70 sec — crumple. Knees give: the head drops and nods down, the
	# gun sags, and the body starts to tip toward the side it will fall to.
	var crumple_time := 0.55
	var crumple_tween: Tween = create_tween()
	crumple_tween.set_parallel(true)
	crumple_tween.set_trans(Tween.TRANS_SINE)
	crumple_tween.set_ease(Tween.EASE_OUT)
	crumple_tween.tween_property(camera_pivot, "position", death_camera_start_pivot + Vector3(0.0, -0.26, 0.10), crumple_time)
	crumple_tween.tween_property(camera, "rotation:x", deg_to_rad(-14.0), crumple_time)
	crumple_tween.tween_property(camera, "rotation:z", fall_roll * 0.22, crumple_time)
	if viewmodel_root != null:
		crumple_tween.tween_property(viewmodel_root, "position", death_viewmodel_start_position + Vector3(0.04, -0.16, 0.05), crumple_time)
		crumple_tween.tween_property(viewmodel_root, "rotation", death_viewmodel_start_rotation + Vector3(deg_to_rad(-16.0), deg_to_rad(-6.0), deg_to_rad(14.0)), crumple_time)
	if death_vignette != null:
		var vignette_tween: Tween = create_tween()
		vignette_tween.tween_property(death_vignette, "modulate:a", 1.0, 1.2)

	await get_tree().create_timer(crumple_time).timeout
	if not death_sequence_active:
		return

	# 0.70–1.52 sec — collapse. The Player origin is ~1.1m above the floor in
	# main.tscn, so pivot Y -0.88 puts the eyes roughly 20–25cm above floor level.
	var fall_time := 0.82
	var fall_tween: Tween = create_tween()
	fall_tween.set_parallel(true)
	fall_tween.set_trans(Tween.TRANS_CUBIC)
	fall_tween.set_ease(Tween.EASE_IN)

	fall_tween.tween_property(camera_pivot, "position", Vector3(0.055, -0.88, 0.09), fall_time)
	fall_tween.tween_property(camera, "rotation:x", deg_to_rad(-9.0), fall_time)
	fall_tween.tween_property(camera, "rotation:z", fall_roll, fall_time)

	if viewmodel_root != null:
		fall_tween.tween_property(viewmodel_root, "position", death_viewmodel_start_position + Vector3(0.20, -0.72, 0.20), fall_time * 0.75)
		fall_tween.tween_property(viewmodel_root, "rotation", death_viewmodel_start_rotation + Vector3(deg_to_rad(42.0), deg_to_rad(-18.0), deg_to_rad(34.0)), fall_time * 0.75)

	await get_tree().create_timer(fall_time).timeout
	if not death_sequence_active:
		return

	if viewmodel_visual != null:
		viewmodel_visual.visible = false

	# 1.2–1.55 sec — head impacts floor, tiny bounce, then settles.
	var floor_y: float = -0.88
	var bounce_tween: Tween = create_tween()
	bounce_tween.tween_property(camera_pivot, "position:y", floor_y - 0.045, 0.085).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	bounce_tween.tween_property(camera_pivot, "position:y", floor_y + 0.032, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property(camera_pivot, "position:y", floor_y, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Heartbeat starts quickly, then spreads out / weakens.
	_play_death_heartbeat(-7.0, 1.0)
	await get_tree().create_timer(0.38).timeout
	_play_death_heartbeat(-9.0, 0.94)
	await get_tree().create_timer(0.52).timeout

	# 2.05 sec — first quick partial blink.
	await _death_blink(0.28, 0.10, 0.11)
	await get_tree().create_timer(0.40).timeout

	_play_death_heartbeat(-13.0, 0.88)

	# Second blink is slower/deeper.
	await _death_blink(0.42, 0.18, 0.17)
	await get_tree().create_timer(0.30).timeout

	# Final close. Hold black.
	await _death_close_permanently(0.46)
	_disable_death_audio_muffle()

	await get_tree().create_timer(0.68).timeout
	if not death_sequence_active:
		return

	# 4-ish sec — bring up run stats over black.
	_show_game_over(true)

func _fade_gameplay_hud_for_death() -> void:
	if gameplay_hud != null:
		gameplay_hud.fade_for_death()
		return

func _set_death_eyelids(fraction: float) -> void:
	if death_top_mask == null or death_bottom_mask == null:
		return
	var height: float = get_viewport().get_visible_rect().size.y
	var half_cover: float = maxf(0.0, height * 0.5 * clampf(fraction, 0.0, 1.0))
	death_top_mask.offset_bottom = half_cover
	death_bottom_mask.offset_top = -half_cover

func _death_blink(fraction: float, close_time: float, open_time: float) -> void:
	if death_top_mask == null or death_bottom_mask == null:
		return

	var height: float = get_viewport().get_visible_rect().size.y
	var half_cover: float = height * 0.5 * clampf(fraction, 0.0, 1.0)

	var close: Tween = create_tween()
	close.set_parallel(true)
	close.set_trans(Tween.TRANS_QUAD)
	close.set_ease(Tween.EASE_IN_OUT)
	close.tween_property(death_top_mask, "offset_bottom", half_cover, close_time)
	close.tween_property(death_bottom_mask, "offset_top", -half_cover, close_time)
	await close.finished

	var open: Tween = create_tween()
	open.set_parallel(true)
	open.set_trans(Tween.TRANS_QUAD)
	open.set_ease(Tween.EASE_OUT)
	open.tween_property(death_top_mask, "offset_bottom", 0.0, open_time)
	open.tween_property(death_bottom_mask, "offset_top", 0.0, open_time)
	await open.finished

func _death_close_permanently(duration: float) -> void:
	if death_top_mask == null or death_bottom_mask == null:
		return
	var height: float = get_viewport().get_visible_rect().size.y
	var half_cover: float = height * 0.505

	var close: Tween = create_tween()
	close.set_parallel(true)
	close.set_trans(Tween.TRANS_SINE)
	close.set_ease(Tween.EASE_IN_OUT)
	close.tween_property(death_top_mask, "offset_bottom", half_cover, duration)
	close.tween_property(death_bottom_mask, "offset_top", -half_cover, duration)
	await close.finished

func _play_death_heartbeat(volume_db: float, pitch_scale: float) -> void:
	if death_heartbeat_audio == null:
		return
	death_heartbeat_audio.volume_db = volume_db
	death_heartbeat_audio.pitch_scale = pitch_scale
	death_heartbeat_audio.play()

func _enable_death_audio_muffle() -> void:
	if death_master_lowpass_index >= 0:
		return
	var bus_index: int = AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return
	var lowpass := AudioEffectLowPassFilter.new()
	lowpass.cutoff_hz = 1050.0
	lowpass.resonance = 0.35
	AudioServer.add_bus_effect(bus_index, lowpass)
	death_master_lowpass_index = AudioServer.get_bus_effect_count(bus_index) - 1

func _disable_death_audio_muffle() -> void:
	if death_master_lowpass_index < 0:
		return
	var bus_index: int = AudioServer.get_bus_index("Master")
	if bus_index >= 0 and death_master_lowpass_index < AudioServer.get_bus_effect_count(bus_index):
		AudioServer.remove_bus_effect(bus_index, death_master_lowpass_index)
	death_master_lowpass_index = -1

func _restore_after_death_sequence() -> void:
	death_sequence_active = false
	_disable_death_audio_muffle()
	_set_death_eyelids(0.0)

	if death_overlay != null:
		death_overlay.visible = false
	if death_vignette != null:
		death_vignette.modulate.a = 0.0

	camera_pivot.position = Vector3(0.0, base_camera_y, 0.0)
	camera_pivot.rotation = Vector3(pitch, 0.0, 0.0)
	jump_offset.position = Vector3.ZERO
	jump_offset.rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	camera.position = Vector3.ZERO
	camera_roll = 0.0
	camera_walk_pitch = 0.0
	_reset_recoil_state()
	footstep_weapon_drop = 0.0
	pending_footstep_impact = 0.0
	jump_weapon_position_offset = Vector3.ZERO
	jump_weapon_rotation_offset = Vector3.ZERO
	jump_state = JumpMovementState.GROUNDED
	active_jump_was_obstacle = false
	active_jump_obstacle_kind = JumpObstacleKind.NONE
	jump_phase_time = 0.0
	landing_intensity = 0.0

	if viewmodel_root != null:
		viewmodel_root.position = VIEWMODEL_POSITION
		viewmodel_root.rotation = Vector3.ZERO
	if viewmodel_visual != null:
		viewmodel_visual.visible = has_pistol

	if gameplay_hud != null:
		gameplay_hud.restore_after_death(_should_show_mobile_hud())
	else:
		for item in [
			health_root,
			timer_root,
			bank_root,
			joystick_base,
			jump_button,
			shoot_button,
			pause_button,
			ammo_label
		]:
			if item != null:
				(item as CanvasItem).modulate.a = 1.0

func _show_game_over(run_failed: bool = true) -> void:
	if game_over:
		return
	if not death_sequence_active:
		RunManager.end_run(not run_failed)
	elapsed_time = RunManager.elapsed_time
	game_over = true
	_reset_joystick()
	var accuracy: float = (float(shots_hit) / float(shots_fired) * 100.0) if shots_fired > 0 else 0.0
	var stats_text: String = "ZOMBIES KILLED  %d\nSHOTS FIRED  %d\nHITS  %d\nACCURACY  %.0f%%\nDAMAGE TAKEN  %d\nTIME  %.1f sec" % [zombies_killed, shots_fired, shots_hit, accuracy, int(round(damage_taken)), elapsed_time]
	if gameplay_hud != null:
		gameplay_hud.show_game_over(stats_text)
	else:
		if pause_button != null:
			pause_button.visible = false
		if shoot_button != null:
			shoot_button.visible = false
		if jump_button != null:
			jump_button.visible = false
		if game_over_stats_label != null:
			game_over_stats_label.text = stats_text
		if game_over_overlay != null:
			game_over_overlay.visible = true
	death_sequence_active = false
	_set_desktop_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true

func register_zombie_kill(_reward: int = 0) -> void:
	if game_over:
		return
	zombies_killed += 1
	call_deferred("_check_room2_encounter_complete")

func _check_room2_encounter_complete() -> void:
	if game_over or encounter_completion_pending:
		return

	var zombie_nodes := get_tree().get_nodes_in_group("zombies")
	# This function is only scheduled by register_zombie_kill(). The final zombie
	# may queue_free before this deferred check runs, so an empty group means the
	# encounter is complete rather than "not started".
	for zombie in zombie_nodes:
		if is_instance_valid(zombie) and bool(zombie.get("alive")):
			return

	# Clearing a combat room advances the run. It is not a win/game-over state:
	# keep controls, HUD and the next-room door active and show only a short banner.
	var cleared_room: int = maxi(RunManager.current_combat_room, 1)
	RunManager.mark_combat_room_cleared(cleared_room)
	var scene := get_tree().current_scene
	if scene != null:
		# RoomTransitionDoor.is_access_granted() reads this exact persistent scene
		# flag. It must be set before the banner delay so Door 2 unlocks immediately.
		scene.set_meta("combat_room_%d_cleared" % cleared_room, true)
	for door: Node in get_tree().get_nodes_in_group("room_transition_door"):
		if is_instance_valid(door) and door.has_method("notify_combat_room_cleared"):
			door.call("notify_combat_room_cleared", cleared_room)
	MusicManager.room_cleared()
	encounter_completion_pending = true
	if gameplay_hud != null and gameplay_hud.has_method("show_room_cleared"):
		gameplay_hud.show_room_cleared(cleared_room)
	# Room 1 starts with the pistol. The first pistol/Uzi pick happens after
	# the last zombie in that room is down, then again after later clears.
	if has_pistol:
		offer_weapon_choice(cleared_room + 1, "", true)
	await get_tree().create_timer(2.6).timeout
	encounter_completion_pending = false

func _reset_match_stats() -> void:
	encounter_completion_pending = false
	zombies_killed = 0
	shots_fired = 0
	shots_hit = 0
	damage_taken = 0.0
	survival_time = 0.0
	elapsed_time = 0.0
	_update_stopwatch_ui()

func _retry_room2() -> void:
	get_tree().paused = false
	_restore_after_death_sequence()
	game_over = false
	health = max_health
	_update_health_ui()
	if current_weapon_id.is_empty():
		current_weapon_id = "pistol"
	_ensure_weapon_ammo(current_weapon_id)
	_restore_weapon_ammo(current_weapon_id)
	if ammo <= 0 and reserve_ammo <= 0:
		_ensure_weapon_ammo(current_weapon_id)
		weapon_ammo_store.erase(current_weapon_id)
		_ensure_weapon_ammo(current_weapon_id)
		_restore_weapon_ammo(current_weapon_id)
	is_reloading = false
	reload_timer = 0.0
	reload_pending_timer = 0.0
	_update_pistol_ammo_display()
	_reset_match_stats()
	encounter_started = true
	RunManager.start_run(1, true)
	MusicManager.restart_combat()
	global_position = retry_position
	rotation = Vector3.ZERO
	pitch = 0.0
	velocity = Vector3.ZERO
	if not has_pistol:
		_equip_pistol()
	if viewmodel_visual != null:
		viewmodel_visual.visible = true
	var room2_nodes: Array = get_tree().get_nodes_in_group("room2_builder")
	if not room2_nodes.is_empty():
		var room2: Node = room2_nodes[0]
		if room2.has_method("_build"):
			room2.call("_build")
	var room1_controllers: Array = get_tree().get_nodes_in_group("room1_infested_controller")
	if not room1_controllers.is_empty():
		var room1_controller: Node = room1_controllers[0]
		if room1_controller.has_method("reset_encounter"):
			room1_controller.call("reset_encounter")
	if gameplay_hud != null:
		gameplay_hud.hide_game_over(_should_show_mobile_hud(), has_pistol)
	if pause_menu != null:
		pause_menu.hide_pause()
	elif pause_overlay != null:
		pause_overlay.visible = false
	mobile_sprint = false
	sprint_touch_id = -1
	_set_desktop_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _restart_from_hub() -> void:
	get_tree().paused = false
	_abort_room_spawning()
	_restore_after_death_sequence()
	RunManager.abandon_run()
	RunManager.reset_to_hub()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


## Rooms streamed into the hub (Room 1 parks there before its door opens) keep
## spawn coroutines waiting on frames. Stop them before the scene is swapped so
## none resumes against a freed tree.
func _abort_room_spawning() -> void:
	for group_name in ["room1_infested_controller", "cafeteria_controller", "combat_room_controller"]:
		for controller: Node in get_tree().get_nodes_in_group(group_name):
			if is_instance_valid(controller) and controller.has_method("abort_spawning"):
				controller.call("abort_spawning")

func _go_main_menu() -> void:
	get_tree().paused = false
	MusicManager.set_paused_duck(false)
	MusicManager.leave_gameplay()
	_abort_room_spawning()
	_restore_after_death_sequence()
	RunManager.abandon_run()
	RunManager.reset_to_hub()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _reset_joystick_immediate() -> void:
	mobile_move_input = Vector2.ZERO
	if joystick_base == null or joystick_knob == null:
		return
	joystick_knob.position = joystick_base.position + (joystick_base.size - joystick_knob.size) * 0.5
	joystick_knob.rotation = 0.0
	joystick_knob.scale = Vector2.ONE
	joystick_knob.modulate = Color.WHITE


func _set_joystick_screen(screen_pos: Vector2) -> void:
	if joystick_base == null or joystick_knob == null:
		return
	if gameplay_hud != null:
		joystick_radius = gameplay_hud.joystick_radius

	# Base and knob are HUD siblings, so screen/input coordinates map 1:1.
	var center_screen: Vector2 = joystick_base.position + joystick_base.size * 0.5
	var delta_from_center: Vector2 = screen_pos - center_screen

	if delta_from_center.length() > joystick_radius:
		delta_from_center = delta_from_center.normalized() * joystick_radius

	var raw_input: Vector2 = delta_from_center / maxf(joystick_radius, 1.0)
	var magnitude: float = raw_input.length()

	var deadzone := ControlSettingsManager.joystick_deadzone
	if magnitude < deadzone:
		mobile_move_input = Vector2.ZERO
	else:
		var normalized_magnitude: float = inverse_lerp(deadzone, 1.0, magnitude)
		mobile_move_input = raw_input.normalized() * pow(normalized_magnitude, 1.03)

	# Move ONLY the visible center knob. The base never changes position.
	var centered_knob: Vector2 = joystick_base.position + (joystick_base.size - joystick_knob.size) * 0.5
	joystick_knob.position = centered_knob + delta_from_center
	joystick_knob.rotation = raw_input.x * 0.045
	joystick_knob.scale = Vector2.ONE * (1.0 + minf(magnitude, 1.0) * 0.035)
	joystick_knob.modulate = Color.WHITE


func _reset_joystick() -> void:
	mobile_move_input = Vector2.ZERO
	if joystick_base == null or joystick_knob == null:
		return
	if joystick_visual_tween != null and joystick_visual_tween.is_valid():
		joystick_visual_tween.kill()

	var centered_knob: Vector2 = joystick_base.position + (joystick_base.size - joystick_knob.size) * 0.5
	joystick_visual_tween = create_tween()
	joystick_visual_tween.set_parallel(true)
	joystick_visual_tween.set_trans(Tween.TRANS_BACK)
	joystick_visual_tween.set_ease(Tween.EASE_OUT)
	joystick_visual_tween.tween_property(joystick_knob, "position", centered_knob, 0.12)
	joystick_visual_tween.tween_property(joystick_knob, "rotation", 0.0, 0.12)
	joystick_visual_tween.tween_property(joystick_knob, "scale", Vector2.ONE, 0.12)


func _set_desktop_mouse_mode(mode: Input.MouseMode) -> void:
	# iOS has no desktop pointer to capture. Avoid repeatedly asking the platform
	# for an unsupported mouse mode while touches are coming in.
	if _is_mobile_ui():
		return
	Input.mouse_mode = mode

func _mobile_shoot_feedback() -> void:
	if not _is_mobile_ui() or not haptics_enabled:
		return
	# Short, sharp firearm pulse.
	Input.vibrate_handheld(18, 0.38)
	_pulse_mobile_button(shoot_button, 0.90, 0.055)

func _mobile_jump_feedback() -> void:
	if not _is_mobile_ui() or not haptics_enabled:
		return
	# Longer/heavier than shooting so the actions feel different.
	Input.vibrate_handheld(48, 0.68)
	_pulse_mobile_button(jump_button, 0.88, 0.085)

func _pulse_mobile_button(button: Control, pressed_scale: float, duration: float) -> void:
	if button == null:
		return
	button.pivot_offset = button.size * 0.5
	var tween: Tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * pressed_scale, duration * 0.42)
	tween.tween_property(button, "scale", Vector2.ONE, duration * 0.58)

func _try_upgrade_interaction(screen_pos: Vector2) -> bool:
	if RunManager.run_active or get_tree().paused:
		return false
	var controller := get_tree().current_scene.get_node_or_null("UpgradeUIController")
	if controller == null or not controller.has_method("try_screen_interaction"):
		return false
	return bool(controller.call("try_screen_interaction", screen_pos, camera, global_position))

func _try_upgrade_center_interaction() -> bool:
	if RunManager.run_active or get_tree().paused:
		return false
	var controller := get_tree().current_scene.get_node_or_null("UpgradeUIController")
	if controller == null or not controller.has_method("try_center_interaction"):
		return false
	return bool(controller.call("try_center_interaction", camera, global_position))

func set_upgrade_modal_active(active: bool) -> void:
	upgrade_modal_active = active
	joystick_touch_id = -1
	look_touch_id = -1
	fire_touch_id = -1
	jump_touch_id = -1
	desktop_fire_held = false
	joystick_mouse_dragging = false
	mobile_move_input = Vector2.ZERO
	mobile_sprint = false
	sprint_touch_id = -1
	if joystick_base != null and joystick_knob != null:
		_reset_joystick_immediate()

func refresh_persistent_upgrades() -> void:
	var previous_max: float = max_health
	max_health = 100.0 + UpgradeManager.get_health_bonus()
	if max_health > previous_max:
		health = minf(max_health, health + (max_health - previous_max))
	else:
		health = minf(health, max_health)
	_update_health_ui()

func _load_required_audio(path: String) -> AudioStream:
	# Exact path only. No directory searching, alternate names, or guessing.
	if not ResourceLoader.exists(path):
		push_error("Required audio file missing: %s" % path)
		return null
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_error("Audio resource failed to load: %s" % path)
	return stream

func _make_audio_pool(
	prefix: String,
	stream: AudioStream,
	voice_count: int,
	volume_db: float
) -> Array[AudioStreamPlayer]:
	var pool: Array[AudioStreamPlayer] = []
	if stream == null:
		return pool
	for i in range(voice_count):
		var player := AudioStreamPlayer.new()
		player.name = "%s_%d" % [prefix, i]
		player.stream = stream
		player.volume_db = volume_db
		add_child(player)
		pool.append(player)
	return pool

func _create_game_audio() -> void:
	# Existing main gunshot remains authoritative. The new files are deliberately
	# quiet support layers so the pistol gains weight/mechanics/room response
	# without becoming a giant cinematic cannon.
	for i in range(4):
		var shot_player := AudioStreamPlayer.new()
		shot_player.name = "PistolShotAudio_%d" % i
		shot_player.stream = PISTOL_SHOT_SFX
		shot_player.volume_db = -3.2
		add_child(shot_player)
		pistol_shot_players.append(shot_player)

	var low_impact_stream: AudioStream = _load_required_audio(PISTOL_LOW_IMPACT_PATH)
	var slide_stream: AudioStream = _load_required_audio(PISTOL_SLIDE_ACTION_PATH)
	var reflection_stream: AudioStream = _load_required_audio(PISTOL_BUNKER_REFLECTION_PATH)
	var shell_stream: AudioStream = _load_required_audio(PISTOL_SHELL_CASING_PATH)

	pistol_low_impact_players = _make_audio_pool("PistolLowImpact", low_impact_stream, 4, -9.5)
	pistol_slide_players = _make_audio_pool("PistolSlide", slide_stream, 4, -13.5)
	pistol_reflection_players = _make_audio_pool("PistolBunkerReflection", reflection_stream, 4, -15.5)
	pistol_shell_players = _make_audio_pool("PistolShell", shell_stream, 4, -17.5)

	var uzi_shot_stream: AudioStream = _load_required_audio(UZI_SHOT_PATH)
	for i in range(6):
		var uzi_shot_player := AudioStreamPlayer.new()
		uzi_shot_player.name = "UziShotAudio_%d" % i
		uzi_shot_player.stream = uzi_shot_stream
		uzi_shot_player.volume_db = -3.0
		add_child(uzi_shot_player)
		uzi_shot_players.append(uzi_shot_player)
	uzi_low_impact_players = _make_audio_pool("UziLowImpact", _load_required_audio(UZI_LOW_IMPACT_PATH), 6, -10.0)
	uzi_bolt_players = _make_audio_pool("UziBolt", _load_required_audio(UZI_BOLT_ACTION_PATH), 6, -14.5)
	uzi_reflection_players = _make_audio_pool("UziBunkerReflection", _load_required_audio(UZI_BUNKER_REFLECTION_PATH), 6, -16.5)
	uzi_shell_players = _make_audio_pool("UziShell", _load_required_audio(UZI_SHELL_CASING_PATH), 4, -23.0)

	uzi_reload_audio = AudioStreamPlayer.new()
	uzi_reload_audio.name = "UziReloadAudio"
	uzi_reload_audio.stream = _load_required_audio(UZI_RELOAD_PATH)
	uzi_reload_audio.volume_db = -4.0
	add_child(uzi_reload_audio)
	uzi_reload_empty_audio = AudioStreamPlayer.new()
	uzi_reload_empty_audio.name = "UziReloadEmptyAudio"
	uzi_reload_empty_audio.stream = _load_required_audio(UZI_RELOAD_EMPTY_PATH)
	uzi_reload_empty_audio.volume_db = -4.0
	add_child(uzi_reload_empty_audio)
	uzi_empty_click_audio = AudioStreamPlayer.new()
	uzi_empty_click_audio.name = "UziEmptyClickAudio"
	uzi_empty_click_audio.stream = _load_required_audio(UZI_EMPTY_CLICK_PATH)
	uzi_empty_click_audio.volume_db = -7.5
	add_child(uzi_empty_click_audio)
	uzi_mag_tap_audio = AudioStreamPlayer.new()
	uzi_mag_tap_audio.name = "UziMagTapAudio"
	uzi_mag_tap_audio.stream = _load_required_audio(UZI_MAG_TAP_PATH)
	uzi_mag_tap_audio.volume_db = -11.0
	add_child(uzi_mag_tap_audio)

	var shotgun_shot_stream: AudioStream = _load_required_audio(SHOTGUN_SHOT_PATH)
	for i in range(4):
		var shotgun_shot_player := AudioStreamPlayer.new()
		shotgun_shot_player.name = "ShotgunShotAudio_%d" % i
		shotgun_shot_player.stream = shotgun_shot_stream
		shotgun_shot_player.volume_db = -2.4
		add_child(shotgun_shot_player)
		shotgun_shot_players.append(shotgun_shot_player)
	shotgun_low_impact_players = _make_audio_pool("ShotgunLowImpact", _load_required_audio(SHOTGUN_LOW_IMPACT_PATH), 4, -8.5)
	shotgun_pump_players = _make_audio_pool("ShotgunPump", _load_required_audio(SHOTGUN_PUMP_ACTION_PATH), 4, -6.0)
	shotgun_pump_back_players = _make_audio_pool("ShotgunPumpBack", _load_required_audio(SHOTGUN_PUMP_BACK_PATH), 4, -5.5)
	shotgun_pump_forward_players = _make_audio_pool("ShotgunPumpForward", _load_required_audio(SHOTGUN_PUMP_FORWARD_PATH), 4, -5.5)
	shotgun_reflection_players = _make_audio_pool("ShotgunBunkerReflection", _load_required_audio(SHOTGUN_BUNKER_REFLECTION_PATH), 4, -14.5)
	shotgun_shell_players = _make_audio_pool("ShotgunShell", _load_required_audio(SHOTGUN_SHELL_EJECT_PATH), 4, -16.0)
	shotgun_reload_audio = AudioStreamPlayer.new()
	shotgun_reload_audio.name = "ShotgunReloadAudio"
	shotgun_reload_audio.stream = _load_required_audio(SHOTGUN_RELOAD_PATH)
	shotgun_reload_audio.volume_db = -5.0
	add_child(shotgun_reload_audio)
	shotgun_reload_sequence_audio = AudioStreamPlayer.new()
	shotgun_reload_sequence_audio.name = "ShotgunReloadSequenceAudio"
	shotgun_reload_sequence_audio.stream = _load_required_audio(SHOTGUN_RELOAD_SEQUENCE_PATH)
	shotgun_reload_sequence_audio.volume_db = -5.5
	add_child(shotgun_reload_sequence_audio)
	shotgun_insert_audio = AudioStreamPlayer.new()
	shotgun_insert_audio.name = "ShotgunInsertAudio"
	shotgun_insert_audio.stream = _load_required_audio(SHOTGUN_SHELL_INSERT_PATH)
	shotgun_insert_audio.volume_db = -6.5
	add_child(shotgun_insert_audio)
	shotgun_empty_click_audio = AudioStreamPlayer.new()
	shotgun_empty_click_audio.name = "ShotgunEmptyClickAudio"
	shotgun_empty_click_audio.stream = _load_required_audio(SHOTGUN_EMPTY_CLICK_PATH)
	shotgun_empty_click_audio.volume_db = -6.8
	add_child(shotgun_empty_click_audio)
	shotgun_dry_fire_audio = AudioStreamPlayer.new()
	shotgun_dry_fire_audio.name = "ShotgunDryFireAudio"
	shotgun_dry_fire_audio.stream = _load_required_audio(SHOTGUN_DRY_FIRE_PATH)
	shotgun_dry_fire_audio.volume_db = -7.2
	add_child(shotgun_dry_fire_audio)

	for path: String in SMALL_OBSTACLE_JUMP_PATHS:
		var stream: AudioStream = _load_required_audio(path)
		if stream != null:
			small_obstacle_jump_streams.append(stream)

	for path: String in LARGE_OBSTACLE_JUMP_PATHS:
		var stream: AudioStream = _load_required_audio(path)
		if stream != null:
			large_obstacle_jump_streams.append(stream)

	jump_effort_audio = AudioStreamPlayer.new()
	jump_effort_audio.name = "PlayerJumpEffortAudio"
	jump_effort_audio.volume_db = -5.5
	add_child(jump_effort_audio)

	reload_audio = AudioStreamPlayer.new()
	reload_audio.name = "PistolReloadAudio"
	reload_audio.stream = PISTOL_RELOAD_SFX
	reload_audio.volume_db = -3.5
	add_child(reload_audio)

	# Four pooled players allow quick sprint strides to overlap naturally instead
	# of cutting off the previous heel/toe decay. A dedicated bus adds weight
	# and a short bunker room without stacking four dry slaps.
	_ensure_footstep_audio_bus()
	for surface_name: String in PLAYER_FOOTSTEP_PATHS:
		var footstep_stream := _load_required_audio(String(PLAYER_FOOTSTEP_PATHS[surface_name]))
		if footstep_stream != null:
			footstep_streams[surface_name] = footstep_stream
	for i in range(4):
		var footstep_player := AudioStreamPlayer.new()
		footstep_player.name = "PlayerFootstepAudio_%d" % i
		footstep_player.bus = FOOTSTEP_BUS_NAME
		add_child(footstep_player)
		footstep_audio_pool.append(footstep_player)

	for path: String in PLAYER_LIGHT_PAIN_PATHS:
		var stream := _load_required_audio(path)
		if stream != null:
			light_pain_streams.append(stream)
	for path: String in PLAYER_HEAVY_PAIN_PATHS:
		var stream := _load_required_audio(path)
		if stream != null:
			heavy_pain_streams.append(stream)
	damage_voice_audio = AudioStreamPlayer.new()
	damage_voice_audio.name = "PlayerDamageVoiceAudio"
	add_child(damage_voice_audio)

	low_health_breathing_audio = AudioStreamPlayer.new()
	low_health_breathing_audio.name = "LowHealthBreathingAudio"
	low_health_breathing_audio.stream = _load_required_audio(LOW_HEALTH_BREATHING_PATH)
	_set_stream_looping(low_health_breathing_audio.stream, true)
	add_child(low_health_breathing_audio)
	low_health_heartbeat_audio = AudioStreamPlayer.new()
	low_health_heartbeat_audio.name = "LowHealthHeartbeatAudio"
	low_health_heartbeat_audio.stream = _load_required_audio(LOW_HEALTH_HEARTBEAT_PATH)
	_set_stream_looping(low_health_heartbeat_audio.stream, true)
	add_child(low_health_heartbeat_audio)

	death_heartbeat_audio = AudioStreamPlayer.new()
	death_heartbeat_audio.name = "DeathHeartbeatAudio"
	death_heartbeat_audio.stream = _make_death_thump_stream(0.19, 58.0, 0.72)
	death_heartbeat_audio.volume_db = -8.0
	add_child(death_heartbeat_audio)

	death_impact_audio = AudioStreamPlayer.new()
	death_impact_audio.name = "DeathImpactAudio"
	death_impact_audio.stream = _make_death_thump_stream(0.24, 43.0, 0.95)
	death_impact_audio.volume_db = -3.0
	add_child(death_impact_audio)

	for path: String in PLAYER_DEATH_VOCAL_PATHS:
		var vocal_stream: AudioStream = _load_required_audio(path)
		if vocal_stream != null:
			death_vocal_streams.append(vocal_stream)

	death_vocal_audio = AudioStreamPlayer.new()
	death_vocal_audio.name = "PlayerDeathVocalAudio"
	death_vocal_audio.volume_db = -3.5
	add_child(death_vocal_audio)

func _set_stream_looping(stream: AudioStream, enabled: bool) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = enabled
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = enabled

func _update_player_footsteps(moving: bool, sprinting: bool) -> void:
	var current_phase := fposmod(gait_phase, TAU)
	if not footstep_phase_initialized:
		footstep_last_gait_phase = current_phase
		footstep_phase_initialized = true
		return
	if not moving or not is_on_floor():
		footstep_last_gait_phase = current_phase
		return

	# The camera reaches each shaped heel-impact dip at PI/2 and 3PI/2.
	var crossed_left_heel := _gait_phase_crossed(footstep_last_gait_phase, current_phase, FOOTSTEP_HEEL_LEFT)
	var crossed_right_heel := _gait_phase_crossed(footstep_last_gait_phase, current_phase, FOOTSTEP_HEEL_RIGHT)
	footstep_last_gait_phase = current_phase
	if not crossed_left_heel and not crossed_right_heel:
		return
	footstep_left_next = crossed_left_heel
	_play_player_footstep(_detect_footstep_surface(), sprinting)


func _gait_phase_crossed(previous_phase: float, current_phase: float, marker: float) -> bool:
	if current_phase >= previous_phase:
		return previous_phase < marker and current_phase >= marker
	# gait_phase wrapped from TAU back to zero this frame.
	return previous_phase < marker or current_phase >= marker


func _ensure_footstep_audio_bus() -> void:
	if AudioServer.get_bus_index(FOOTSTEP_BUS_NAME) >= 0:
		return
	var bus_idx: int = AudioServer.bus_count
	AudioServer.add_bus(bus_idx)
	AudioServer.set_bus_name(bus_idx, FOOTSTEP_BUS_NAME)
	AudioServer.set_bus_send(bus_idx, "Master")
	AudioServer.set_bus_volume_db(bus_idx, -0.5)

	var eq := AudioEffectEQ6.new()
	eq.set_band_gain_db(0, 3.2)   # 32 Hz — weight under the boot
	eq.set_band_gain_db(1, 4.0)   # 100 Hz — concrete body
	eq.set_band_gain_db(2, 0.6)   # 320 Hz
	eq.set_band_gain_db(3, -1.6)  # 1 kHz — less slap
	eq.set_band_gain_db(4, -3.4)  # 3.2 kHz
	eq.set_band_gain_db(5, -5.5)  # 10 kHz — take the click off
	AudioServer.add_bus_effect(bus_idx, eq)

	var compressor := AudioEffectCompressor.new()
	compressor.threshold = -17.0
	compressor.ratio = 3.4
	compressor.attack_us = 55.0
	compressor.release_ms = 95.0
	compressor.gain = 0.6
	AudioServer.add_bus_effect(bus_idx, compressor)

	var reverb := AudioEffectReverb.new()
	reverb.room_size = 0.26
	reverb.damping = 0.56
	reverb.spread = 0.40
	reverb.hipass = 0.17
	reverb.dry = 0.82
	reverb.wet = 0.16
	reverb.predelay_msec = 14.0
	AudioServer.add_bus_effect(bus_idx, reverb)


func _consume_pending_footstep_impact() -> void:
	if pending_footstep_impact <= 0.0 or camera_pivot == null:
		pending_footstep_impact = 0.0
		return
	var strength: float = pending_footstep_impact
	pending_footstep_impact = 0.0
	# Applied after the gait lerp so the thud is on the same frame as play().
	camera_walk_pitch -= deg_to_rad(0.24) * strength
	camera_pivot.position.y -= 0.0030 * strength
	footstep_weapon_drop = 0.0048 * strength
	if sprint_blend > 0.30:
		sprint_pos_velocity.y -= sprint_step_impact * 2.6 * strength
		# Heavier boot in the arms: the gun drops and the muzzle nods on the
		# same frame the sprint footstep plays.
		var thud: float = strength * sprint_blend * sprint_weapon_step_thud
		sprint_weapon_position_velocity.y -= sprint_step_impact * 5.5 * thud
		sprint_weapon_position_velocity.z += sprint_step_impact * 1.5 * thud
		sprint_weapon_rotation_velocity.x -= deg_to_rad(9.0) * thud
		sprint_weapon_rotation_velocity.z += deg_to_rad(6.0 if footstep_left_next else -6.0) * thud

func _detect_footstep_surface() -> String:
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.24,
		global_position + Vector3.DOWN * 0.85,
		1 | 16
	)
	query.exclude = [self]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return "concrete"
	var node := hit.get("collider") as Node
	var description := ""
	for _depth in range(4):
		if node == null:
			break
		if node.has_meta("footstep_surface"):
			var authored := String(node.get_meta("footstep_surface")).to_lower()
			if footstep_streams.has(authored):
				return authored
		description += " " + String(node.name).to_lower() + " " + node.scene_file_path.to_lower()
		node = node.get_parent()
	if "wet" in description or "water" in description or "puddle" in description:
		return "wet"
	if "grate" in description or "metal" in description or "steel" in description:
		return "metal"
	if "debris" in description or "rubble" in description or "broken" in description:
		return "debris"
	return "concrete"

func _play_player_footstep(surface_name: String, sprinting: bool) -> void:
	if footstep_audio_pool.is_empty():
		return
	var stream := footstep_streams.get(surface_name) as AudioStream
	if stream == null:
		stream = footstep_streams.get("concrete") as AudioStream
	if stream == null:
		return
	var player := footstep_audio_pool[footstep_voice_index % footstep_audio_pool.size()]
	footstep_voice_index = (footstep_voice_index + 1) % footstep_audio_pool.size()
	player.stream = stream
	player.volume_db = -23.0 if sprinting else -25.5
	# Slightly lower and split left/right so each boot has weight instead of a
	# bright slap on every identical sample.
	var foot_bias: float = 0.972 if footstep_left_next else 1.012
	player.pitch_scale = randf_range(0.955, 0.990) * foot_bias * (1.018 if sprinting else 1.0)
	player.play()
	pending_footstep_impact = 1.16 if sprinting else 1.0

func _play_damage_vocal(damage_amount: float) -> void:
	if damage_voice_audio == null or damage_voice_cooldown > 0.0:
		return
	var use_heavy := damage_amount >= 16.0 or health / maxf(max_health, 1.0) <= 0.22
	var streams := heavy_pain_streams if use_heavy else light_pain_streams
	if streams.is_empty():
		return
	var previous := last_heavy_pain_index if use_heavy else last_light_pain_index
	var index := _pick_nonrepeating_index(streams.size(), previous)
	if use_heavy:
		last_heavy_pain_index = index
	else:
		last_light_pain_index = index
	damage_voice_audio.stop()
	damage_voice_audio.stream = streams[index]
	damage_voice_audio.volume_db = -4.5 if use_heavy else -7.0
	damage_voice_audio.pitch_scale = randf_range(0.985, 1.015)
	damage_voice_audio.play()
	damage_voice_cooldown = 0.72 if use_heavy else 0.48

func _update_low_health_audio() -> void:
	if low_health_breathing_audio == null or low_health_heartbeat_audio == null:
		return
	var ratio := health / maxf(max_health, 1.0)
	var active := ratio > 0.0 and ratio < low_health_threshold and not death_sequence_active and not game_over
	if not active:
		_stop_low_health_audio()
		return
	var intensity := clampf(inverse_lerp(low_health_threshold, 0.07, ratio), 0.0, 1.0)
	low_health_breathing_audio.volume_db = lerpf(-23.0, -8.0, intensity)
	low_health_heartbeat_audio.volume_db = lerpf(-26.0, -7.0, intensity)
	if not low_health_breathing_audio.playing:
		low_health_breathing_audio.play()
	if not low_health_heartbeat_audio.playing:
		low_health_heartbeat_audio.play()


func _update_low_health_feedback(delta: float) -> void:
	var ratio := health / maxf(max_health, 1.0)
	var active := (
		ratio > 0.0
		and ratio < low_health_threshold
		and not death_sequence_active
		and not game_over
		and low_health_heartbeat_audio != null
		and low_health_heartbeat_audio.playing
	)
	if not active:
		# Healing above the threshold or dying stops the beat on this frame.
		low_health_camera_position = Vector3.ZERO
		low_health_camera_rotation = Vector3.ZERO
		low_health_hand_position = Vector3.ZERO
		low_health_hand_rotation = Vector3.ZERO
		low_health_fov_offset = 0.0
		low_health_active_blend = 0.0
		if gameplay_hud != null and gameplay_hud.has_method("set_low_health_pulse"):
			gameplay_hud.call("set_low_health_pulse", 0.0)
		return

	var intensity := clampf(inverse_lerp(low_health_threshold, 0.07, ratio), 0.0, 1.0)
	# Retain a faint warning at the threshold, while the beat becomes much more
	# physical near critical health, and pushes harder again below ~15%.
	var visual_intensity := lerpf(0.28, 1.0, intensity)
	var critical := clampf(inverse_lerp(low_health_critical_threshold, 0.04, ratio), 0.0, 1.0)
	visual_intensity *= 1.0 + low_health_critical_boost * critical
	# One sample of the real heartbeat recording drives camera, hands, FOV and
	# the red pulse, so nothing runs on a separate timer.
	var heartbeat_sample := _sample_low_health_heartbeat(
		fposmod(low_health_heartbeat_audio.get_playback_position(), LOW_HEALTH_HEARTBEAT_LENGTH)
	)
	var pulse: float = heartbeat_sample.x
	var side: float = heartbeat_sample.y
	var target_position := Vector3(
		side * 0.0012 * pulse,
		-low_health_camera_drop * pulse,
		low_health_camera_push * pulse
	) * visual_intensity
	var target_rotation := Vector3(
		deg_to_rad(low_health_camera_pitch_degrees) * pulse,
		0.0,
		deg_to_rad(low_health_camera_roll_degrees) * side * pulse
	) * visual_intensity
	var overlay_alpha: float = (
		low_health_red_base_alpha * visual_intensity
		+ low_health_red_pulse_alpha * pulse * visual_intensity
	)
	# Hands jolt on the beat; the aim point itself only gets the small camera
	# pitch above, so the gun reads scared while the crosshair stays usable.
	var hand_position_target := Vector3(
		side * 0.0014 * pulse,
		-low_health_hand_drop * pulse,
		0.0018 * pulse
	) * visual_intensity
	var hand_rotation_target := Vector3(
		-low_health_hand_pitch_degrees * pulse,
		side * 0.5 * pulse,
		side * low_health_hand_roll_degrees * pulse
	) * visual_intensity

	var response := 1.0 - exp(-24.0 * delta)
	low_health_camera_position = low_health_camera_position.lerp(target_position, response)
	low_health_camera_rotation = low_health_camera_rotation.lerp(target_rotation, response)
	low_health_hand_position = low_health_hand_position.lerp(hand_position_target, response)
	low_health_hand_rotation = low_health_hand_rotation.lerp(hand_rotation_target, response)
	# FOV breathes in on each beat (the room closes in on the pulse).
	low_health_fov_offset = lerpf(low_health_fov_offset, -low_health_fov_breathe * pulse * visual_intensity, response)
	low_health_active_blend = move_toward(low_health_active_blend, 1.0, delta * 3.0)
	if gameplay_hud != null and gameplay_hud.has_method("set_low_health_pulse"):
		gameplay_hud.call("set_low_health_pulse", clampf(overlay_alpha, 0.0, 0.45))


func _sample_low_health_heartbeat(playback_position: float) -> Vector2:
	var strongest_pulse := 0.0
	var strongest_side := 1.0
	for index: int in range(LOW_HEALTH_HEARTBEAT_TIMES.size()):
		var elapsed := fposmod(
			playback_position - LOW_HEALTH_HEARTBEAT_TIMES[index],
			LOW_HEALTH_HEARTBEAT_LENGTH
		)
		if elapsed > 0.34:
			continue
		# Fast contact followed by a short organic decay. Strengths were measured
		# from the recording, so quieter secondary beats remain visually quieter.
		var envelope := exp(-elapsed * 11.5) * LOW_HEALTH_HEARTBEAT_STRENGTHS[index]
		if envelope > strongest_pulse:
			strongest_pulse = envelope
			strongest_side = -1.0 if index % 2 == 0 else 1.0
	return Vector2(strongest_pulse, strongest_side)

func _stop_low_health_audio() -> void:
	if low_health_breathing_audio != null and low_health_breathing_audio.playing:
		low_health_breathing_audio.stop()
	if low_health_heartbeat_audio != null and low_health_heartbeat_audio.playing:
		low_health_heartbeat_audio.stop()
	if gameplay_hud != null and gameplay_hud.has_method("set_low_health_pulse"):
		gameplay_hud.call("set_low_health_pulse", 0.0)

func _play_pool_voice(
	pool: Array[AudioStreamPlayer],
	voice_index: int,
	pitch_min: float,
	pitch_max: float
) -> int:
	if pool.is_empty():
		return voice_index
	var player: AudioStreamPlayer = pool[voice_index % pool.size()]
	player.stop()
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.play()
	return (voice_index + 1) % pool.size()

func _play_weapon_shot_sfx() -> void:
	if _is_extra_weapon():
		return   # Extra guns play their shot inside _extra_shoot_effects().
	if current_weapon_id == "uzi":
		_play_uzi_shot_sfx()
	elif current_weapon_id == "shotgun":
		_play_shotgun_shot_sfx()
	else:
		_play_pistol_shot_sfx()


func _play_shotgun_shot_sfx() -> void:
	if shotgun_shot_players.is_empty():
		return
	var shot_player := shotgun_shot_players[shotgun_shot_voice_index]
	shotgun_shot_voice_index = (shotgun_shot_voice_index + 1) % shotgun_shot_players.size()
	shot_player.stop()
	shot_player.pitch_scale = randf_range(0.985, 1.025)
	shot_player.play()
	shotgun_low_voice_index = _play_pool_voice(shotgun_low_impact_players, shotgun_low_voice_index, 0.98, 1.04)
	_play_shotgun_reflection_delayed(randf_range(0.010, 0.018))


func _play_shotgun_pump_sfx() -> void:
	# Rack back, then the forward slam. The original take has both strokes
	# with a hole in the middle — playing them as two hits keeps the full pump.
	if not shotgun_pump_back_players.is_empty():
		shotgun_pump_back_voice_index = _play_pool_voice(
			shotgun_pump_back_players,
			shotgun_pump_back_voice_index,
			0.97,
			1.04
		)
		_play_shotgun_pump_forward_delayed(0.34)
	else:
		shotgun_pump_voice_index = _play_pool_voice(shotgun_pump_players, shotgun_pump_voice_index, 0.98, 1.05)


func _play_shotgun_pump_forward_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(self) or current_weapon_id != "shotgun":
		return
	if shotgun_pump_forward_players.is_empty():
		return
	shotgun_pump_forward_voice_index = _play_pool_voice(
		shotgun_pump_forward_players,
		shotgun_pump_forward_voice_index,
		0.97,
		1.05
	)


func _play_shotgun_insert_sfx() -> void:
	if shotgun_insert_audio == null:
		return
	shotgun_insert_audio.stop()
	shotgun_insert_audio.pitch_scale = randf_range(0.97, 1.05)
	shotgun_insert_audio.play()


func _play_shotgun_reload_sequence() -> void:
	if shotgun_reload_sequence_audio != null:
		shotgun_reload_sequence_audio.stop()
		shotgun_reload_sequence_audio.pitch_scale = randf_range(0.985, 1.02)
		shotgun_reload_sequence_audio.play()
	elif shotgun_reload_audio != null:
		shotgun_reload_audio.stop()
		shotgun_reload_audio.pitch_scale = randf_range(0.985, 1.02)
		shotgun_reload_audio.play()


func _play_shotgun_reflection_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(self):
		return
	shotgun_reflection_voice_index = _play_pool_voice(
		shotgun_reflection_players,
		shotgun_reflection_voice_index,
		0.985,
		1.02
	)


func _play_shotgun_shell_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(self) or current_weapon_id != "shotgun":
		return
	shotgun_shell_voice_index = _play_pool_voice(
		shotgun_shell_players,
		shotgun_shell_voice_index,
		0.94,
		1.08
	)


func _play_uzi_shot_sfx() -> void:
	if uzi_shot_players.is_empty():
		return
	var shot_player := uzi_shot_players[uzi_shot_voice_index]
	uzi_shot_voice_index = (uzi_shot_voice_index + 1) % uzi_shot_players.size()
	shot_player.stop()
	shot_player.pitch_scale = randf_range(0.992, 1.028)
	shot_player.play()
	uzi_low_voice_index = _play_pool_voice(uzi_low_impact_players, uzi_low_voice_index, 0.98, 1.04)
	_play_uzi_bolt_delayed(randf_range(0.006, 0.012))
	_play_uzi_reflection_delayed(randf_range(0.008, 0.016))
	if randf() < 0.38:
		_play_uzi_shell_delayed(randf_range(0.10, 0.18))


func _play_uzi_bolt_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	uzi_bolt_voice_index = _play_pool_voice(uzi_bolt_players, uzi_bolt_voice_index, 0.99, 1.05)


func _play_uzi_reflection_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	uzi_reflection_voice_index = _play_pool_voice(uzi_reflection_players, uzi_reflection_voice_index, 0.985, 1.02)


func _play_uzi_shell_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	uzi_shell_voice_index = _play_pool_voice(uzi_shell_players, uzi_shell_voice_index, 0.94, 1.08)


func _play_pistol_shot_sfx() -> void:
	if pistol_shot_players.is_empty():
		return

	var shot_player := pistol_shot_players[pistol_shot_voice_index]
	pistol_shot_voice_index = (pistol_shot_voice_index + 1) % pistol_shot_players.size()
	shot_player.stop()
	shot_player.pitch_scale = randf_range(1.018, 1.048)
	shot_player.play()

	# Immediate low-end body: subtle enough that the existing shot still defines
	# the weapon's character.
	pistol_low_voice_index = _play_pool_voice(
		pistol_low_impact_players,
		pistol_low_voice_index,
		1.00,
		1.03
	)

	# Slide and room layers stack sooner so the crack reads as one snap.
	_play_pistol_slide_delayed(randf_range(0.008, 0.014))
	_play_pistol_reflection_delayed(randf_range(0.010, 0.018))

	# A casing ping every single trigger pull becomes irritating quickly.
	if randf() < 0.58:
		_play_pistol_shell_delayed(randf_range(0.12, 0.22))

func _play_pistol_slide_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if pistol_slide_players.is_empty():
		return
	pistol_slide_voice_index = _play_pool_voice(
		pistol_slide_players,
		pistol_slide_voice_index,
		1.00,
		1.055
	)

func _play_pistol_reflection_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if pistol_reflection_players.is_empty():
		return
	pistol_reflection_voice_index = _play_pool_voice(
		pistol_reflection_players,
		pistol_reflection_voice_index,
		0.985,
		1.015
	)

func _play_pistol_shell_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if pistol_shell_players.is_empty():
		return
	pistol_shell_voice_index = _play_pool_voice(
		pistol_shell_players,
		pistol_shell_voice_index,
		0.92,
		1.08
	)

func _pick_nonrepeating_index(count: int, previous_index: int) -> int:
	if count <= 1:
		return 0
	var index: int = randi_range(0, count - 1)
	if index == previous_index:
		index = (index + randi_range(1, count - 1)) % count
	return index

func _play_jump_effort_for_obstacle(obstacle_kind: JumpObstacleKind) -> void:
	if jump_effort_audio == null:
		return

	var streams: Array[AudioStream] = []
	var chance: float = 0.0
	var previous_index: int = -1

	if obstacle_kind == JumpObstacleKind.LARGE:
		streams = large_obstacle_jump_streams
		chance = large_obstacle_voice_chance
		previous_index = last_large_jump_voice_index
		jump_effort_audio.volume_db = -6.0
	elif obstacle_kind == JumpObstacleKind.SMALL:
		streams = small_obstacle_jump_streams
		chance = small_obstacle_voice_chance
		previous_index = last_small_jump_voice_index
		jump_effort_audio.volume_db = -7.5
	else:
		# Normal/generic jumps occasionally reuse the LIGHT set.
		streams = small_obstacle_jump_streams
		chance = normal_jump_voice_chance
		previous_index = last_small_jump_voice_index
		jump_effort_audio.volume_db = -9.0

	if streams.is_empty() or randf() > chance:
		return

	var index: int = _pick_nonrepeating_index(streams.size(), previous_index)
	jump_effort_audio.stop()
	jump_effort_audio.stream = streams[index]
	jump_effort_audio.pitch_scale = randf_range(0.985, 1.015)
	jump_effort_audio.play()

	if obstacle_kind == JumpObstacleKind.LARGE:
		last_large_jump_voice_index = index
	else:
		last_small_jump_voice_index = index

func _create_viewmodel_fill_lights() -> void:
	# Cinematic three-point lighting for the FPS hand + weapon only.
	# These lights never touch the room; they illuminate only the dedicated
	# viewmodel render layer so the pistol stays crisp and readable on iPhone.
	viewmodel_key_light = DirectionalLight3D.new()
	viewmodel_key_light.name = "FPSKeyLight"
	viewmodel_key_light.rotation_degrees = Vector3(-20.0, -32.0, 0.0)
	viewmodel_key_light.light_color = Color(0.98, 0.97, 0.94)
	viewmodel_key_light.light_energy = 1.65
	viewmodel_key_light.light_specular = 1.15
	viewmodel_key_light.shadow_enabled = false
	viewmodel_key_light.light_cull_mask = VIEWMODEL_RENDER_LAYER
	camera.add_child(viewmodel_key_light)

	viewmodel_fill_light = OmniLight3D.new()
	viewmodel_fill_light.name = "FPSFillLight"
	viewmodel_fill_light.position = Vector3(-0.16, -0.06, -0.30)
	viewmodel_fill_light.light_color = Color(0.42, 0.56, 0.86)
	viewmodel_fill_light.light_energy = 2.1
	viewmodel_fill_light.light_specular = 1.05
	viewmodel_fill_light.omni_range = 1.15
	viewmodel_fill_light.shadow_enabled = false
	viewmodel_fill_light.light_cull_mask = VIEWMODEL_RENDER_LAYER
	camera.add_child(viewmodel_fill_light)

	viewmodel_rim_light = SpotLight3D.new()
	viewmodel_rim_light.name = "FPSRimLight"
	viewmodel_rim_light.position = Vector3(0.28, 0.02, -0.18)
	viewmodel_rim_light.rotation_degrees = Vector3(-6.0, 108.0, 0.0)
	viewmodel_rim_light.light_color = Color(1.0, 0.82, 0.62)
	viewmodel_rim_light.light_energy = 2.45
	viewmodel_rim_light.light_specular = 1.25
	viewmodel_rim_light.spot_range = 1.25
	viewmodel_rim_light.spot_angle = 42.0
	viewmodel_rim_light.spot_angle_attenuation = 0.65
	viewmodel_rim_light.shadow_enabled = false
	viewmodel_rim_light.light_cull_mask = VIEWMODEL_RENDER_LAYER
	camera.add_child(viewmodel_rim_light)

func _create_muzzle_light() -> void:
	muzzle_light = OmniLight3D.new()
	muzzle_light.name = "PistolMuzzleLight"
	muzzle_light.position = Vector3(0.11, -0.10, -0.78) * VIEWMODEL_DEPTH_FACTOR
	muzzle_light.light_color = Color(1.0, 0.62, 0.24)
	muzzle_light.light_energy = 0.0
	muzzle_light.light_specular = 1.4
	muzzle_light.omni_range = 0.95
	muzzle_light.shadow_enabled = false
	# Only illuminate the FPS viewmodel render layer, never the room.
	muzzle_light.light_cull_mask = VIEWMODEL_RENDER_LAYER
	camera.add_child(muzzle_light)

func _weapon_camera_spring() -> Vector2:
	if _is_extra_weapon():
		var extra := _extra_recoil(current_weapon_id)
		return Vector2(float(extra.get("cam_spring", 300.0)), float(extra.get("cam_damp", 30.0)))
	match current_weapon_id:
		"uzi":
			return Vector2(uzi_camera_spring, uzi_camera_damping)
		"shotgun":
			return Vector2(shotgun_camera_spring, shotgun_camera_damping)
	return Vector2(pistol_camera_spring, pistol_camera_damping)


func _weapon_hand_spring() -> Vector2:
	if _is_extra_weapon():
		var extra := _extra_recoil(current_weapon_id)
		return Vector2(float(extra.get("hand_spring", 300.0)), float(extra.get("hand_damp", 30.0)))
	match current_weapon_id:
		"uzi":
			return Vector2(uzi_hand_spring, uzi_hand_damping)
		"shotgun":
			return Vector2(shotgun_hand_spring, shotgun_hand_damping)
	# Pistol ADS snaps home harder so the next shot is still on the zombie.
	# Damping scales with sqrt(stiffness) to keep the same settle character.
	return Vector2(
		pistol_hand_spring * lerpf(1.0, 1.45, ads_blend),
		pistol_hand_damping * lerpf(1.0, 1.2, ads_blend)
	)


## Directed shot impulse. Part of the kick lands on the shot frame (so the
## climb is visible immediately), the rest goes into spring velocity; the
## springs then pull back to zero, i.e. onto the shot's own aim point.
func _apply_shot_recoil() -> void:
	var ads_scale: float = lerpf(1.0, ads_recoil_multiplier, ads_blend)
	var pitch_deg: float = pistol_camera_recoil_degrees * randf_range(0.94, 1.06)
	var yaw_deg: float = randf_range(-1.0, 1.0) * pistol_camera_yaw_degrees
	var roll_deg: float = randf_range(-1.0, 1.0) * pistol_camera_roll_degrees
	var push: float = 0.006
	var fov_punch: float = pistol_camera_fov_punch
	var camera_immediate: float = 0.62
	var hand_side: float = randf_range(-1.0, 1.0)
	var hand_position := Vector3(
		hand_side * 0.0012,
		pistol_hand_kick_up,
		pistol_hand_kick_back
	) * pistol_hand_recoil_strength
	var hand_rotation := Vector3(
		pistol_hand_kick_pitch_degrees,
		-hand_side * 0.7,
		hand_side * pistol_hand_kick_roll_degrees
	) * pistol_hand_recoil_strength
	var hand_scale: float = ads_scale
	var hand_immediate: float = 0.55

	match current_weapon_id:
		"uzi":
			# Alternating roll reads as body buzz, not a random spray.
			uzi_roll_sign = -uzi_roll_sign
			pitch_deg = uzi_camera_kick_degrees * randf_range(0.85, 1.12)
			yaw_deg = randf_range(-1.0, 1.0) * uzi_camera_yaw_degrees
			roll_deg = uzi_roll_sign * uzi_camera_roll_degrees * randf_range(0.7, 1.0)
			push = 0.0025
			fov_punch = uzi_camera_fov_punch
			camera_immediate = 0.55
			uzi_burst_climb = minf(
				uzi_burst_climb + deg_to_rad(uzi_burst_climb_degrees) * ads_scale,
				deg_to_rad(uzi_burst_climb_max_degrees) * ads_scale
			)
			hand_position = Vector3(uzi_roll_sign * 0.0006, uzi_hand_kick_up, uzi_hand_kick_back)
			hand_rotation = Vector3(uzi_hand_kick_pitch_degrees, 0.0, uzi_roll_sign * uzi_hand_kick_roll_degrees)
			# Micro kick is already planted-safe; ADS does not need to shrink it.
			hand_scale = 1.0
			hand_immediate = 0.7
		"shotgun":
			var roll_side: float = -1.0 if randf() < 0.5 else 1.0
			pitch_deg = shotgun_camera_kick_degrees * randf_range(0.92, 1.06)
			yaw_deg = randf_range(-1.0, 1.0) * shotgun_camera_yaw_degrees
			roll_deg = roll_side * shotgun_camera_roll_degrees * randf_range(0.75, 1.0)
			push = shotgun_camera_push_back
			fov_punch = shotgun_camera_fov_punch
			camera_immediate = 0.45
			hand_position = Vector3(roll_side * 0.0035, shotgun_hand_kick_up, shotgun_hand_kick_back)
			hand_rotation = Vector3(
				shotgun_hand_kick_pitch_degrees,
				-roll_side * 1.4,
				roll_side * shotgun_hand_kick_roll_degrees
			)
			# ADS shrink (to 0.6) is applied where the pose is written.
			hand_scale = 1.0
			hand_immediate = 0.5
		"sawnoffs", "crossbow", "minigun", "smg", "grenade_launcher", "lmg", "sawnoff":
			var r := _extra_recoil(current_weapon_id)
			var side: float = -1.0 if randf() < 0.5 else 1.0
			var roll_boost: float = 1.0
			if current_weapon_id in ["sawnoffs", "sawnoff"] and ammo == 0:
				roll_boost = 1.7   # second barrel twists harder
				side = -1.0
			if current_weapon_id == "minigun":
				uzi_roll_sign = -uzi_roll_sign
				side = uzi_roll_sign
				uzi_burst_climb = minf(
					uzi_burst_climb + deg_to_rad(float(r["climb"])),
					deg_to_rad(float(r["climb_max"]))
				)
			pitch_deg = float(r["pitch"]) * randf_range(0.88, 1.08)
			yaw_deg = randf_range(-1.0, 1.0) * float(r["yaw"])
			roll_deg = side * float(r["roll"]) * roll_boost * randf_range(0.75, 1.0)
			push = float(r["push"])
			fov_punch = float(r["fov"])
			camera_immediate = 0.5
			hand_position = Vector3(side * 0.002, float(r["hand_up"]), float(r["hand_back"]))
			hand_rotation = Vector3(float(r["hand_pitch"]), -side * 0.8, side * float(r["hand_roll"]) * roll_boost)
			hand_scale = 1.0 if current_weapon_id == "minigun" else lerpf(1.0, 0.7, ads_blend)
			hand_immediate = 0.55

	var camera_omega: float = sqrt(_weapon_camera_spring().x)
	var kick := Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), deg_to_rad(roll_deg)) * ads_scale
	camera_kick += kick * camera_immediate
	camera_kick_velocity += kick * (1.0 - camera_immediate) * camera_omega * 2.4
	camera_kick_push += push * ads_scale * camera_immediate
	camera_kick_push_velocity += push * ads_scale * (1.0 - camera_immediate) * camera_omega * 2.4
	recoil_fov_offset = clampf(recoil_fov_offset + fov_punch * ads_scale, 0.0, 3.2)

	var hand_omega: float = sqrt(_weapon_hand_spring().x)
	hand_position *= hand_scale
	hand_rotation *= hand_scale
	hand_kick_position += hand_position * hand_immediate
	hand_kick_position_velocity += hand_position * (1.0 - hand_immediate) * hand_omega * 2.4
	hand_kick_rotation += hand_rotation * hand_immediate
	hand_kick_rotation_velocity += hand_rotation * (1.0 - hand_immediate) * hand_omega * 2.4
	_clamp_recoil_state()


## Extra body beat when the pump section of the allanims clip starts.
func _apply_shotgun_pump_recoil() -> void:
	if viewmodel_tune_enabled:
		return
	var ads_scale: float = lerpf(1.0, ads_recoil_multiplier, ads_blend)
	var camera_omega: float = sqrt(_weapon_camera_spring().x)
	var hand_omega: float = sqrt(_weapon_hand_spring().x)
	# Negative pitch = the view nods down as the fore-end is racked back.
	camera_kick_velocity.x -= deg_to_rad(shotgun_pump_camera_dip_degrees) * ads_scale * camera_omega * 2.4
	camera_kick_velocity.z += deg_to_rad(0.35) * ads_scale * camera_omega
	hand_kick_position_velocity += Vector3(0.0, -0.45, 1.0) * shotgun_pump_hand_pull * lerpf(1.0, 0.5, ads_blend) * hand_omega * 2.4
	hand_kick_rotation_velocity += Vector3(-2.2, 0.0, 1.4) * lerpf(1.0, 0.5, ads_blend) * hand_omega


func _clamp_recoil_state() -> void:
	camera_kick.x = clampf(camera_kick.x, -deg_to_rad(2.0), deg_to_rad(5.0))
	camera_kick.y = clampf(camera_kick.y, -deg_to_rad(1.5), deg_to_rad(1.5))
	camera_kick.z = clampf(camera_kick.z, -deg_to_rad(2.5), deg_to_rad(2.5))
	camera_kick_push = clampf(camera_kick_push, -0.02, 0.07)
	hand_kick_position = hand_kick_position.clamp(Vector3(-0.012, -0.018, -0.015), Vector3(0.012, 0.022, 0.060))
	hand_kick_rotation = hand_kick_rotation.clamp(Vector3(-6.0, -4.0, -6.0), Vector3(16.0, 4.0, 6.0))


func _reset_recoil_state() -> void:
	camera_kick = Vector3.ZERO
	camera_kick_velocity = Vector3.ZERO
	camera_kick_push = 0.0
	camera_kick_push_velocity = 0.0
	camera_recoil_velocity = 0.0
	uzi_burst_climb = 0.0
	uzi_burst_climb_velocity = 0.0
	recoil_fov_offset = 0.0
	recoil_fov_velocity = 0.0
	hand_kick_position = Vector3.ZERO
	hand_kick_position_velocity = Vector3.ZERO
	hand_kick_rotation = Vector3.ZERO
	hand_kick_rotation_velocity = Vector3.ZERO
	viewmodel_direct_position = Vector3.ZERO
	viewmodel_direct_rotation = Vector3.ZERO
	look_sway = Vector2.ZERO
	look_sway_target = Vector2.ZERO
	look_sway_velocity = Vector2.ZERO


## Camera3D is the single writer for recoil + walk pitch/roll: body yaw lives
## on Player, mouse pitch on CameraPivot, jump/landing on JumpOffset, and the
## shot kick (pitch/yaw/roll/push-back) plus gait nod/roll here.
func _write_camera_recoil() -> void:
	camera_pivot.rotation.x = pitch
	camera.rotation = Vector3(
		camera_kick.x + uzi_burst_climb + camera_walk_pitch,
		camera_kick.y,
		camera_roll + camera_kick.z
	)
	camera.position = Vector3(0.0, 0.0, camera_kick_push)


func _update_recoil(delta: float) -> void:
	shot_cooldown = maxf(0.0, shot_cooldown - delta)
	empty_click_cooldown = maxf(0.0, empty_click_cooldown - delta)

	var camera_spring := _weapon_camera_spring()
	var hand_spring := _weapon_hand_spring()
	var fov_omega: float = 7.5 if current_weapon_id == "shotgun" else (8.5 if current_weapon_id == "sawnoffs" else 15.0)
	if camera_recoil_velocity != 0.0:
		camera_kick_velocity.x += camera_recoil_velocity
		camera_recoil_velocity = 0.0
	# Recoil springs are stiff, so they substep at 120 Hz to stay identical at
	# 30/60/120 FPS.
	var step_count: int = maxi(1, int(ceil(delta * 120.0)))
	var h: float = delta / float(step_count)
	for _step in range(step_count):
		camera_kick_velocity += (-camera_spring.x * camera_kick - camera_spring.y * camera_kick_velocity) * h
		camera_kick += camera_kick_velocity * h
		camera_kick_push_velocity += (-camera_spring.x * camera_kick_push - camera_spring.y * camera_kick_push_velocity) * h
		camera_kick_push += camera_kick_push_velocity * h
		uzi_burst_climb_velocity += (-uzi_burst_climb_spring * uzi_burst_climb - uzi_burst_climb_damping * uzi_burst_climb_velocity) * h
		uzi_burst_climb += uzi_burst_climb_velocity * h
		recoil_fov_velocity += (-fov_omega * fov_omega * recoil_fov_offset - 2.0 * fov_omega * recoil_fov_velocity) * h
		recoil_fov_offset += recoil_fov_velocity * h
		hand_kick_position_velocity += (-hand_spring.x * hand_kick_position - hand_spring.y * hand_kick_position_velocity) * h
		hand_kick_position += hand_kick_position_velocity * h
		hand_kick_rotation_velocity += (-hand_spring.x * hand_kick_rotation - hand_spring.y * hand_kick_rotation_velocity) * h
		hand_kick_rotation += hand_kick_rotation_velocity * h
	_clamp_recoil_state()
	_write_camera_recoil()

	if muzzle_flash_time > 0.0:
		muzzle_flash_time -= delta
		if muzzle_light != null:
			muzzle_light.light_energy = 5.5 * clampf(muzzle_flash_time / 0.055, 0.0, 1.0)
	elif muzzle_light != null:
		muzzle_light.light_energy = 0.0


## Gun mass against look input: the sway target trails the look, and an
## under-damped spring lets the gun lag a beat and then catch up past centre.
func _update_look_sway(delta: float) -> void:
	var step_count: int = maxi(1, int(ceil(delta * 120.0)))
	var h: float = delta / float(step_count)
	for _step in range(step_count):
		look_sway_velocity += ((look_sway_target - look_sway) * look_sway_spring - look_sway_velocity * look_sway_damping) * h
		look_sway += look_sway_velocity * h
	look_sway_target = look_sway_target.lerp(Vector2.ZERO, 1.0 - exp(-8.5 * delta))


func _degrees3(radians: Vector3) -> Vector3:
	return Vector3(rad_to_deg(radians.x), rad_to_deg(radians.y), rad_to_deg(radians.z))


func _update_weapon_float(delta: float, moving: bool, sprinting: bool = false) -> void:
	if not has_pistol or viewmodel_root == null:
		return
	_update_look_sway(delta)
	var heavy_planted := current_weapon_id == "uzi" or current_weapon_id == "shotgun" or _extra_has_ads()
	if viewmodel_tune_enabled or (heavy_planted and ads_blend >= 0.999):
		# Locked ready pose. Only transient impulses move it (shot kick, a
		# zombie ripping the gun, a landing), and all of them spring back to
		# exactly this pose, so the sights return to the crosshair.
		var planted_position := Vector3.ZERO
		var planted_rotation := Vector3.ZERO
		if not viewmodel_tune_enabled:
			var hand_scale: float = 0.6 if current_weapon_id == "shotgun" else (0.7 if _extra_has_ads() else 1.0)
			planted_position = (
				hand_kick_position * hand_scale
				+ melee_weapon_position_offset * 0.55
				+ jump_weapon_position_offset * 0.35
				+ low_health_hand_position * 0.3
			)
			planted_rotation = (
				hand_kick_rotation * hand_scale
				+ _degrees3(melee_weapon_rotation_offset) * 0.55
				+ _degrees3(jump_weapon_rotation_offset) * 0.35
				+ low_health_hand_rotation * 0.3
			)
		viewmodel_root.position = VIEWMODEL_POSITION + planted_position
		viewmodel_root.rotation_degrees = planted_rotation
		viewmodel_direct_position = planted_position
		viewmodel_direct_rotation = planted_rotation
		return

	weapon_time += delta

	# Quiet breathing/hand settlement so the weapon never feels frozen when idle.
	# At low health the heartbeat takes over instead of stacking two motions.
	var idle_float := Vector3(
		sin(weapon_time * 1.05) * 0.0016,
		sin(weapon_time * 1.38 + 0.55) * 0.0018,
		cos(weapon_time * 1.05) * 0.0010
	) * (1.0 - low_health_active_blend)

	var locomotion_offset := Vector3.ZERO
	var locomotion_rotation := Vector3.ZERO
	var directional_offset := Vector3.ZERO
	var directional_rotation := Vector3.ZERO

	# Directional carry from actual input so strafing/forward motion changes the gun,
	# not just the camera. This is what helps it feel less like a floating prop.
	var input_x := smoothed_move_input.x
	var input_y := -smoothed_move_input.y
	directional_offset = Vector3(
		input_x * 0.0045,
		abs(input_y) * -0.0018,
		maxf(input_y, 0.0) * 0.0028
	)
	directional_rotation = Vector3(
		input_y * -1.2,
		input_x * 1.8,
		-input_x * 2.7
	)

	if moving:
		var phase := gait_phase
		var step_phase := phase * 2.0
		var move_strength := clampf(gait_blend, 0.0, 1.0)

		if not sprinting:
			var side := sin(phase)
			var step := 0.5 - 0.5 * cos(step_phase)
			var depth := cos(phase)

			locomotion_offset = Vector3(
				side * 0.0105,
				-step * 0.0068 - footstep_weapon_drop,
				depth * 0.0088
			) * move_strength * walk_weapon_motion_multiplier

			locomotion_rotation = Vector3(
				-step * 0.62,
				side * 0.72,
				sin(phase) * 0.94
			) * move_strength * walk_weapon_motion_multiplier
		else:
			# Run state on the same gait clock as the footsteps: lower carry,
			# stronger cant, and a heel-shaped drop so each boot lands in the arms.
			var side := sin(phase)
			var step := pow(0.5 - 0.5 * cos(step_phase), 1.6)
			var depth := cos(phase)

			locomotion_offset = Vector3(
				side * 0.0175,
				-step * 0.0175 - footstep_weapon_drop,
				depth * 0.0185
			) * move_strength

			locomotion_rotation = Vector3(
				-step * 1.45,
				side * 1.50,
				sin(phase) * 2.10
			) * move_strength

	# Blend sprint carry instead of snapping between two poses.
	# Translation is owned by sprint_weapon_position_offset so the authored clip
	# stays centered and does not get pushed toward the near plane twice.
	var tuck := sprint_weapon_tuck_degrees
	if current_weapon_id == "shotgun" or _is_extra_weapon():
		# No authored run clip on the shotgun / packed guns, so the procedural
		# tuck carries it. The knife tucks a little further.
		tuck *= 1.9 if current_weapon_id == "knife" else 1.6
	var run_carry_rotation := tuck * sprint_blend

	var look_offset := Vector3(
		clampf(look_sway.x, -0.012, 0.012),
		clampf(look_sway.y, -0.010, 0.010),
		0.0
	)
	var ads_sway_scale: float = lerpf(1.0, ads_sway_multiplier, ads_blend)
	var ads_bob_scale: float = lerpf(1.0, ads_bob_multiplier, ads_blend)
	var hand_kick_scale: float = 1.0
	if heavy_planted:
		ads_sway_scale = lerpf(1.0, 0.04, ads_blend)
		ads_bob_scale = lerpf(1.0, 0.02, ads_blend)
		if current_weapon_id == "shotgun":
			hand_kick_scale = lerpf(1.0, 0.6, ads_blend)
	idle_float *= ads_sway_scale
	look_offset *= ads_sway_scale
	directional_offset *= ads_bob_scale
	directional_rotation *= ads_bob_scale
	locomotion_offset *= ads_bob_scale
	locomotion_rotation *= ads_bob_scale

	# These are camera-local presentation offsets, not model-space coordinates.
	# Multiplying them by VIEWMODEL_DEPTH_FACTOR made walking/recoil nearly invisible.
	# Continuous carry motion is smoothed (mass); transient impulses below are
	# spring-driven already and are added directly so they stay sharp.
	var target_position: Vector3 = VIEWMODEL_POSITION + (
		idle_float
		+ locomotion_offset
		+ directional_offset
		+ look_offset
	) + sprint_weapon_position_offset + lateral_weapon_position_offset

	var direct_position: Vector3 = (
		hand_kick_position * hand_kick_scale
		+ melee_weapon_position_offset * lerpf(1.0, 0.55, ads_blend)
		+ jump_weapon_position_offset * lerpf(1.0, 0.35, ads_blend)
		+ low_health_hand_position * lerpf(1.0, 0.3, ads_blend)
	)

	var position_response: float = lerpf(11.5, 13.0, sprint_blend)
	if not moving:
		position_response = maxf(position_response, 8.5)
	var carry_position: Vector3 = (viewmodel_root.position - viewmodel_direct_position).lerp(
		target_position,
		minf(1.0, delta * position_response)
	)
	viewmodel_root.position = carry_position + direct_position
	viewmodel_direct_position = direct_position

	var target_rotation := locomotion_rotation + directional_rotation + run_carry_rotation + _degrees3(sprint_weapon_rotation_offset) + _degrees3(lateral_weapon_rotation_offset) + Vector3(
		look_sway.y * 17.0 * ads_sway_scale,
		-look_sway.x * 18.0 * ads_sway_scale,
		-look_sway.x * 7.0 * ads_sway_scale
	)
	var direct_rotation: Vector3 = (
		hand_kick_rotation * hand_kick_scale
		+ _degrees3(melee_weapon_rotation_offset) * lerpf(1.0, 0.55, ads_blend)
		+ _degrees3(jump_weapon_rotation_offset) * lerpf(1.0, 0.35, ads_blend)
		+ low_health_hand_rotation * lerpf(1.0, 0.3, ads_blend)
	)

	var rotation_response: float = lerpf(10.0, 11.5, sprint_blend)
	if not moving:
		rotation_response = maxf(rotation_response, 7.5)
	var carry_rotation: Vector3 = (viewmodel_root.rotation_degrees - viewmodel_direct_rotation).lerp(
		target_rotation,
		minf(1.0, delta * rotation_response)
	)
	viewmodel_root.rotation_degrees = carry_rotation + direct_rotation
	viewmodel_direct_rotation = direct_rotation


# =============================================================================
# EXTRA LOADOUT WEAPONS — sawn-offs, crossbow, knife, minigun
# -----------------------------------------------------------------------------
# All four are the same Sketchfab FPS arm family as the pistol / shotgun
# (_rootJoint / L_arm_* rigs) and ship ONE packed clip each at 30 fps. They are
# played in sub-ranges exactly like the shotgun's allanims. Every value that
# decides balance lives in this block; gameplay damage is always a multiple of
# UpgradeManager.get_pistol_damage() so the weapon tree keeps mattering.
# Hitscan stays on camera centre for every gun; the knife is a short ray.
# =============================================================================

const EXTRA_WEAPON_IDS: Array[String] = [
	"sawnoffs", "crossbow", "knife", "minigun",
	"smg", "grenade_launcher", "lmg", "sawnoff",
]
const SAWNOFFS_VIEWMODEL_SCENE: PackedScene = preload("res://assets/Weapons/sawnoffs_animated.glb")
const CROSSBOW_VIEWMODEL_SCENE: PackedScene = preload("res://assets/Weapons/crossbow_animated.glb")
const KNIFE_VIEWMODEL_SCENE: PackedScene = preload("res://assets/Weapons/knife_animated.glb")
const MINIGUN_VIEWMODEL_SCENE: PackedScene = preload("res://assets/Weapons/minigun_animated.glb")
const SMG_VIEWMODEL_SCENE: PackedScene = preload("res://assets/Weapons/fps_animated_smg.glb")
const GRENADE_LAUNCHER_VIEWMODEL_SCENE: PackedScene = preload("res://assets/Weapons/grenadelauncher_animated.glb")
const LMG_VIEWMODEL_SCENE: PackedScene = preload("res://assets/Weapons/lmg_animated.glb")
const SAWNOFF_VIEWMODEL_SCENE: PackedScene = preload("res://assets/Weapons/sawnoff_animated.glb")

# Loadout design: two slots, role-aware offers, room gates (room CLEARED).
const WEAPON_ROLES := {
	"pistol": "precision", "crossbow": "precision",
	"uzi": "spray", "minigun": "spray", "smg": "spray", "lmg": "spray",
	"shotgun": "blast", "sawnoffs": "blast", "sawnoff": "blast",
	"grenade_launcher": "explosive",
	"knife": "melee",
}
const WEAPON_UNLOCK_AFTER_ROOM := {
	"pistol": 1, "uzi": 1, "shotgun": 1, "knife": 1, "sawnoffs": 1, "smg": 1, "sawnoff": 1,
	"crossbow": 3, "grenade_launcher": 3,
	"lmg": 5,
	"minigun": 6,
}
const KNIFE_REFILL_HEAL := 15.0

# Viewmodel placement (camera-local, full depth like the shotgun / Uzi).
# "ready" is the ADS pose; knife and minigun have no ADS.
const EXTRA_VIEWMODEL := {
	"sawnoffs": {
		"clip": &"CINEMA_4D_Main",
		"hip": Vector3(0.094, -0.24, -0.33), "hip_rot": Vector3(2.5, 180.0, 0.0), "scale": 0.006,
		"ready": Vector3(0.045, -0.165, -0.245), "ready_rot": Vector3(0.5, 180.0, 0.0),
		"ads_in": 0.14, "ads_out": 0.18,
	},
	"crossbow": {
		"clip": &"allanimations",
		"hip": Vector3(0.10, -0.19, -0.30), "hip_rot": Vector3(2.5, 180.0, 0.0), "scale": 0.006,
		"ready": Vector3(0.0, -0.128, -0.26), "ready_rot": Vector3(1.0, 180.0, 0.0),
		"ads_in": 0.20, "ads_out": 0.20,
	},
	"knife": {
		"clip": &"anims",
		"hip": Vector3(0.13, -0.17, -0.26), "hip_rot": Vector3(2.5, 180.0, 0.0), "scale": 0.006,
	},
	"minigun": {
		"clip": &"allanims",
		"hip": Vector3(0.10, -0.19, -0.52), "hip_rot": Vector3(2.5, 180.0, 0.0), "scale": 0.6,
	},
	"smg": {
		"clip": &"allanims",
		"hip": Vector3(0.10, -0.22, -0.30), "hip_rot": Vector3(2.5, 180.0, 0.0), "scale": 0.006,
		"ready": Vector3(0.02, -0.145, -0.24), "ready_rot": Vector3(0.5, 180.0, 0.0),
		"ads_in": 0.12, "ads_out": 0.16,
	},
	"grenade_launcher": {
		"clip": &"allanims",
		"hip": Vector3(0.11, -0.23, -0.34), "hip_rot": Vector3(2.5, 180.0, 0.0), "scale": 0.006,
		"ready": Vector3(0.03, -0.155, -0.26), "ready_rot": Vector3(0.8, 180.0, 0.0),
		"ads_in": 0.16, "ads_out": 0.18,
	},
	"lmg": {
		"clip": &"allanims",
		"hip": Vector3(0.12, -0.24, -0.40), "hip_rot": Vector3(2.5, 180.0, 0.0), "scale": 0.006,
		"ready": Vector3(0.04, -0.160, -0.30), "ready_rot": Vector3(0.6, 180.0, 0.0),
		"ads_in": 0.16, "ads_out": 0.20,
	},
	"sawnoff": {
		"clip": &"allanims",
		"hip": Vector3(0.094, -0.24, -0.33), "hip_rot": Vector3(2.5, 180.0, 0.0), "scale": 0.006,
		"ready": Vector3(0.045, -0.165, -0.245), "ready_rot": Vector3(0.5, 180.0, 0.0),
		"ads_in": 0.14, "ads_out": 0.18,
	},
}

# --- SAWN-OFFS: two-shot panic blast, forced break-reload.
const SAWNOFFS_MAG_CAPACITY := 2
const SAWNOFFS_STARTING_TOTAL_AMMO := 18
const SAWNOFFS_SHOT_INTERVAL := 0.38
const SAWNOFFS_PELLETS := 7
const SAWNOFFS_SPREAD_HIP := 0.090
const SAWNOFFS_SPREAD_ADS := 0.042
# Cut from the CINEMA_4D_Main keys: right trigger 0.03, guns settle 0.37;
# left trigger 0.43, settle 0.77; latches 0.97 -> barrels shut 2.30, guns home
# 2.67; twirl 2.70-3.33, hold, spin 4.27-5.00 back to the rest pose.
const SAWNOFFS_FIRE_R := Vector2(0.00, 0.40)
const SAWNOFFS_FIRE_L := Vector2(0.40, 0.80)
const SAWNOFFS_RELOAD := Vector2(0.80, 2.67)
const SAWNOFFS_FLOURISH := Vector2(2.70, 5.00)
# README_SFX cue times (absolute clip seconds).
const SAWNOFFS_RELOAD_CUES := [
	[0.97, "sawnoff_latch_open"], [1.13, "sawnoff_break_open"], [1.25, "sawnoff_shell_extract"],
	[1.60, "shared_shell_drop_1"], [1.70, "shared_shell_drop_2"], [1.80, "shared_foley_rustle_1"],
	[1.88, "sawnoff_shell_insert"], [2.17, "sawnoff_break_close"], [2.30, "sawnoff_latch_close"],
]
const SAWNOFFS_FLOURISH_CUES := [
	[2.80, "shared_foley_rustle_2"], [4.27, "sawnoff_flourish_twirl"], [4.60, "shared_foley_rustle_3"],
]

# --- CROSSBOW: one bolt, slow auto-recock, heavy headshots.
const CROSSBOW_MAG_CAPACITY := 1
const CROSSBOW_STARTING_TOTAL_AMMO := 14
# Cut from the allanimations keys. 0.00 is the loaded rest (bolt on the rail,
# string drawn). Bolt leaves 0.03-0.10, bow settles 0.37 (empty rest).
# Recock: tilt up 0.50, string 0.97-1.13, lever 1.10-1.47, bolt slid in
# 2.10-2.50, bow back to rest 3.30. Handle flourish 3.30-4.17, then rest
# until the jab 5.00-5.67.
const CROSSBOW_FIRE := Vector2(0.00, 0.37)
const CROSSBOW_RELOAD := Vector2(0.37, 3.30)
const CROSSBOW_HANDLE := Vector2(3.30, 4.17)
const CROSSBOW_BASH := Vector2(5.00, 5.67)
const CROSSBOW_BASH_RANGE := 2.0
const CROSSBOW_RELOAD_CUES := [
	[0.97, "crossbow_string_draw_ratchet"], [1.33, "crossbow_lever_latch"],
	[1.70, "shared_foley_rustle_1"], [2.10, "crossbow_bolt_slide_in"],
]
const CROSSBOW_HANDLE_CUES := [
	[3.33, "crossbow_handling_creak"], [3.45, "shared_foley_rustle_2"], [3.70, "crossbow_handling_creak"],
]

# --- KNIFE: infinite, uses a slot, risk melee.
const KNIFE_SLASH_RANGE := 2.15
const KNIFE_STAB_RANGE := 2.55
const KNIFE_SLASH_INTERVAL := 0.58
const KNIFE_STAB_INTERVAL := 0.72
# Wrist-goal keys: breathing idle 0.00-1.33, slash 1 1.37-2.00, slash 2
# 2.03-2.67, flips 2.70-4.13 and a last twist back to rest by 4.83.
const KNIFE_IDLE := Vector2(0.00, 1.30)
const KNIFE_SLASH_1 := Vector2(1.35, 2.00)
const KNIFE_SLASH_2 := Vector2(2.01, 2.67)
const KNIFE_INSPECT := Vector2(2.68, 4.83)
const KNIFE_INSPECT_CUES := [
	[2.70, "knife_flip_1"], [2.72, "knife_swing_3"], [3.32, "knife_flip_2"],
	[3.47, "knife_flip_3"], [4.03, "knife_flip_1"], [4.50, "shared_foley_rustle_1"],
]
const KNIFE_QUICK_STAB_TIME := 0.50

# --- MINIGUN: spin-up, huge mag, heavy, no ADS.
const MINIGUN_MAG_CAPACITY := 100
const MINIGUN_STARTING_TOTAL_AMMO := 200
const MINIGUN_SHOT_INTERVAL := 0.050
const MINIGUN_SPIN_UP_TIME := 0.85
const MINIGUN_SPIN_DOWN_TIME := 1.10
const MINIGUN_WALK_MULTIPLIER := 0.82
# Barrel step 0.00-0.20, idle sway 0.23-2.03, reload (box out 2.43, in
# 3.57) until the gun is home at 4.27, button check / heft 4.30-6.00.
const MINIGUN_FIRE_LOOP := Vector2(0.00, 0.20)
const MINIGUN_IDLE := Vector2(0.23, 1.97)
const MINIGUN_RELOAD := Vector2(2.03, 4.27)
const MINIGUN_INSPECT := Vector2(4.30, 6.00)
const MINIGUN_RELOAD_CUES := [
	[2.03, "shared_foley_rustle_1"], [2.43, "minigun_feed_lid_open"], [2.47, "minigun_box_mag_out"],
	[3.47, "minigun_box_mag_in"], [3.95, "minigun_feed_lid_close"],
]
const MINIGUN_INSPECT_CUES := [[4.30, "minigun_button_click"], [5.33, "minigun_heavy_handling_thud"]]

# --- SMG: compact auto, packed allanim ~7.8s.
const SMG_MAG_CAPACITY := 28
const SMG_STARTING_TOTAL_AMMO := 140
const SMG_SHOT_INTERVAL := 0.092
# Cut from the allanims keys: carrier cycles 0.03-0.17, gun home 0.27.
# Empty reload 0.27-2.70 (mag out 0.77, in 1.23-1.33, bolt 1.83-2.20); a
# second, tactical mag swap 2.70-4.30 is not used. Bolt check 4.30-5.87,
# still rest 5.87-7.17 (loops as idle, trimmed), then a swing to 7.80 (unused).
const SMG_FIRE := Vector2(0.00, 0.27)
const SMG_IDLE := Vector2(5.87, 7.10)   # stop short of the 7.17 swing
const SMG_RELOAD := Vector2(0.27, 2.70)
const SMG_INSPECT := Vector2(4.30, 5.87)
const SMG_RELOAD_CUES := [
	[0.77, "smg_mag_out"], [1.23, "smg_mag_in"], [1.85, "shared_foley_rustle_1"],
]

# --- GRENADE LAUNCHER: 6-tube, impact splash, packed allanim ~10.1s.
const GRENADE_LAUNCHER_MAG_CAPACITY := 6
const GRENADE_LAUNCHER_STARTING_TOTAL_AMMO := 12
const GRENADE_LAUNCHER_SHOT_INTERVAL := 0.95
const GRENADE_LAUNCHER_SPLASH_RADIUS := 3.4
# Cut from the allanims keys. 0.00 is the closed, loaded rest. Trigger
# 0.07, cylinder advance 0.30-0.43, gun home 0.45 (the old 0.80 end ran into
# the break-open). Reload: front swings open 0.47-0.73, casings out 0.83-1.20,
# six slugs in 1.37 / 2.23 / 3.10 / 3.97 / 4.83 / 5.70, front shut 6.83-6.97,
# gun home 7.10. Inspect: tilt + cylinder spin 7.13-10.07, back to rest.
const GRENADE_LAUNCHER_FIRE := Vector2(0.00, 0.45)
const GRENADE_LAUNCHER_RELOAD := Vector2(0.47, 7.10)
const GRENADE_LAUNCHER_INSPECT := Vector2(7.13, 10.06)
const GRENADE_LAUNCHER_RELOAD_CUES := [
	[0.55, "gl_breech_open"], [1.40, "gl_shell_in"], [2.27, "gl_shell_in"], [3.13, "gl_shell_in"],
	[4.00, "gl_shell_in"], [4.87, "gl_shell_in"], [5.73, "gl_shell_in"], [6.88, "gl_breech_close"],
]

# --- LMG: heavy auto, packed allanim ~14.9s.
const LMG_MAG_CAPACITY := 50
const LMG_STARTING_TOTAL_AMMO := 150
const LMG_SHOT_INTERVAL := 0.100
# Cut from the allanims keys: bolt cycles 0.03-0.27, gun home 0.33.
# Reload 0.37-6.10 (bolt back 0.83, lid open 1.93, mag out 2.45, in 3.20,
# lid shut 4.25, bolt home 5.40-5.67, gun home 6.10). Swing inspect
# 6.13-7.23, still rest 7.27-8.33 (loops as idle). 8.37-14.93 is a second
# flourish + reload take and is not used.
const LMG_FIRE := Vector2(0.00, 0.33)
const LMG_IDLE := Vector2(7.27, 8.27)   # stop short of the 8.37 swing
const LMG_RELOAD := Vector2(0.37, 6.10)
const LMG_INSPECT := Vector2(6.13, 7.23)
const LMG_RELOAD_CUES := [
	[1.93, "lmg_lid_open"], [2.45, "lmg_mag_out"], [3.20, "lmg_mag_in"], [4.25, "lmg_lid_close"],
]

# --- SAWN-OFF (new GLB, allanim ~9s): two-shell break-action, separate from sawnoffs.
const SAWNOFF_MAG_CAPACITY := 2
const SAWNOFF_STARTING_TOTAL_AMMO := 22
const SAWNOFF_SHOT_INTERVAL := 0.46
const SAWNOFF_PELLETS := 7
const SAWNOFF_SPREAD_HIP := 0.052
const SAWNOFF_SPREAD_ADS := 0.022
# Cut from the allanims keys. The clip has ONE shot (both triggers 0.03,
# gun home 0.43), a one-shell reload 0.47-3.50 and a two-shell reload
# 3.53-6.43 (release 3.90, front open 4.23-4.40, both shells out 4.93-5.27,
# in 5.43-5.60, shut 6.07-6.20, gun home 6.43). Flourish 6.47-7.30, still rest
# 7.33-8.33, swing 8.37-9.00 (unused). Both barrels play the same shot.
const SAWNOFF_FIRE_R := Vector2(0.00, 0.43)
const SAWNOFF_FIRE_L := Vector2(0.00, 0.43)
const SAWNOFF_RELOAD := Vector2(3.53, 6.43)
const SAWNOFF_INSPECT := Vector2(6.47, 7.30)
const SAWNOFF_RELOAD_CUES := [
	[3.90, "sawnoff_break_open"], [4.47, "sawnoff_shell_extract"],
	[4.95, "shared_shell_drop_1"], [5.43, "sawnoff_shell_insert"],
	[6.07, "sawnoff_break_close"], [6.20, "sawnoff_latch_close"],
]

# Per-gun recoil numbers (camera pitch/yaw/roll deg, push m, FOV punch, springs).
const EXTRA_RECOIL := {
	# Harder punch than the Uzi, shorter than the pump's single slam; extra
	# roll on the second barrel.
	"sawnoffs": {"pitch": 2.35, "yaw": 0.45, "roll": 1.0, "push": 0.034, "fov": 1.9, "cam_spring": 210.0, "cam_damp": 22.0,
		"hand_up": 0.010, "hand_back": 0.034, "hand_pitch": 9.0, "hand_roll": 2.6, "hand_spring": 200.0, "hand_damp": 20.0},
	"crossbow": {"pitch": 1.1, "yaw": 0.18, "roll": 0.35, "push": 0.012, "fov": 0.6, "cam_spring": 260.0, "cam_damp": 26.0,
		"hand_up": 0.004, "hand_back": 0.014, "hand_pitch": 3.0, "hand_roll": 0.8, "hand_spring": 260.0, "hand_damp": 26.0},
	# Planted chatter + alternating roll, a heavier Uzi. Climb capped low.
	"minigun": {"pitch": 0.34, "yaw": 0.12, "roll": 0.42, "push": 0.003, "fov": 0.12, "cam_spring": 820.0, "cam_damp": 44.0,
		"hand_up": 0.0014, "hand_back": 0.0065, "hand_pitch": 1.1, "hand_roll": 0.9, "hand_spring": 900.0, "hand_damp": 48.0,
		"climb": 0.07, "climb_max": 0.85},
	"knife": {"pitch": 0.0, "yaw": 0.0, "roll": 0.0, "push": 0.0, "fov": 0.0, "cam_spring": 320.0, "cam_damp": 30.0,
		"hand_up": 0.0, "hand_back": 0.0, "hand_pitch": 0.0, "hand_roll": 0.0, "hand_spring": 260.0, "hand_damp": 24.0},
	"smg": {"pitch": 0.42, "yaw": 0.16, "roll": 0.28, "push": 0.006, "fov": 0.22, "cam_spring": 520.0, "cam_damp": 34.0,
		"hand_up": 0.0024, "hand_back": 0.010, "hand_pitch": 1.8, "hand_roll": 0.7, "hand_spring": 560.0, "hand_damp": 32.0},
	"grenade_launcher": {"pitch": 2.8, "yaw": 0.55, "roll": 1.1, "push": 0.040, "fov": 2.2, "cam_spring": 180.0, "cam_damp": 20.0,
		"hand_up": 0.012, "hand_back": 0.040, "hand_pitch": 10.0, "hand_roll": 2.2, "hand_spring": 190.0, "hand_damp": 18.0},
	"lmg": {"pitch": 0.48, "yaw": 0.18, "roll": 0.36, "push": 0.008, "fov": 0.28, "cam_spring": 480.0, "cam_damp": 36.0,
		"hand_up": 0.0030, "hand_back": 0.012, "hand_pitch": 2.2, "hand_roll": 0.9, "hand_spring": 500.0, "hand_damp": 34.0},
	"sawnoff": {"pitch": 2.50, "yaw": 0.50, "roll": 1.1, "push": 0.036, "fov": 2.0, "cam_spring": 200.0, "cam_damp": 22.0,
		"hand_up": 0.011, "hand_back": 0.036, "hand_pitch": 9.4, "hand_roll": 2.8, "hand_spring": 190.0, "hand_damp": 20.0},
}

const EXTRA_SFX := {
	# key: [volume_db, voices]
	"sawnoff_fire_1": [-1.5, 2], "sawnoff_fire_2": [-1.5, 2], "sawnoff_fire_3": [-1.5, 2],
	"sawnoff_latch_open": [-6.0, 1], "sawnoff_break_open": [-4.0, 1], "sawnoff_shell_extract": [-6.0, 1],
	"sawnoff_shell_insert": [-5.0, 1], "sawnoff_break_close": [-3.5, 1], "sawnoff_latch_close": [-6.0, 1],
	"sawnoff_flourish_twirl": [-7.0, 1],
	"crossbow_fire_1": [-2.0, 1], "crossbow_fire_2": [-2.0, 1], "crossbow_string_draw_ratchet": [-5.0, 1],
	"crossbow_lever_latch": [-5.0, 1], "crossbow_bolt_slide_in": [-6.0, 1], "crossbow_handling_creak": [-12.0, 1],
	"crossbow_bash_swing": [-4.0, 1],
	"knife_swing_1": [-4.0, 1], "knife_swing_2": [-4.0, 1], "knife_swing_3": [-4.0, 1],
	"knife_draw_shing": [-6.0, 1], "knife_flip_1": [-8.0, 1], "knife_flip_2": [-8.0, 1], "knife_flip_3": [-8.0, 1],
	"knife_hit_flesh_1": [-3.0, 1], "knife_hit_flesh_2": [-3.0, 1], "knife_hit_flesh_3": [-3.0, 1],
	"knife_hit_wall": [-4.0, 2],
	"minigun_spin_up": [-5.0, 1], "minigun_spin_down": [-5.0, 1], "minigun_fire_tail": [-3.0, 1],
	"minigun_button_click": [-9.0, 1], "minigun_feed_lid_open": [-6.0, 1], "minigun_feed_lid_close": [-5.0, 1],
	"minigun_box_mag_out": [-6.0, 1], "minigun_box_mag_in": [-3.5, 1], "minigun_heavy_handling_thud": [-7.0, 1],
	"shared_shell_drop_1": [-11.0, 1], "shared_shell_drop_2": [-11.0, 1], "shared_shell_drop_3": [-11.0, 1],
	"shared_foley_rustle_1": [-13.0, 1], "shared_foley_rustle_2": [-13.0, 1], "shared_foley_rustle_3": [-13.0, 1],
	"shared_dry_fire_click": [-7.0, 1], "shared_weapon_raise_1": [-9.0, 1], "shared_weapon_raise_2": [-9.0, 1],
	"smg_fire_1": [-2.0, 2], "smg_fire_2": [-2.0, 2], "smg_mag_out": [-6.0, 1], "smg_mag_in": [-4.0, 1],
	"lmg_fire_1": [-1.5, 2], "lmg_fire_2": [-1.5, 2], "lmg_lid_open": [-6.0, 1], "lmg_lid_close": [-5.0, 1],
	"lmg_mag_out": [-6.0, 1], "lmg_mag_in": [-3.5, 1],
	"gl_fire_1": [-1.0, 1], "gl_fire_2": [-1.0, 1], "gl_breech_open": [-5.0, 1], "gl_shell_in": [-6.0, 1],
	"gl_breech_close": [-4.0, 1],
	"sawnoff_single_fire_1": [-1.5, 2], "sawnoff_single_fire_2": [-1.5, 2],
}

var sawnoffs_viewmodel: Node3D = null
var crossbow_viewmodel: Node3D = null
var knife_viewmodel: Node3D = null
var minigun_viewmodel: Node3D = null
var smg_viewmodel: Node3D = null
var grenade_launcher_viewmodel: Node3D = null
var lmg_viewmodel: Node3D = null
var sawnoff_viewmodel: Node3D = null
var extra_sfx_pools: Dictionary = {}
var extra_sfx_voice: Dictionary = {}
var minigun_fire_loop_audio: AudioStreamPlayer = null
var minigun_spin_loop_audio: AudioStreamPlayer = null
# Packed-clip section player for the four extra viewmodels.
var packed_action: StringName = &"idle"
var packed_section_playing := false
var packed_section_start: float = 0.0
var packed_section_end: float = 0.0
var packed_section_speed: float = 1.0
var packed_section_loop := false
# Invalidates timed SFX cues and delayed hits whenever the weapon changes.
var extra_cue_serial: int = 0
# Knife.
var knife_next_slash_is_second := false
var knife_attack_cooldown: float = 0.0
var quick_knife_active := false
var quick_knife_return_id: String = ""
# Crossbow bash.
var crossbow_bash_active := false
# Minigun.
var minigun_spin: float = 0.0
var minigun_trigger_was_down := false
var minigun_fired_this_burst := false


func _is_extra_weapon(weapon_id: String = current_weapon_id) -> bool:
	return EXTRA_WEAPON_IDS.has(weapon_id)


## Full-depth viewmodels (placement values are real camera-local metres).
func _weapon_uses_full_depth(weapon_id: String = current_weapon_id) -> bool:
	return weapon_id == "uzi" or weapon_id == "shotgun" or _is_extra_weapon(weapon_id)


## Guns that click dry instead of auto-reloading when fully empty.
func _weapon_clicks_when_empty(weapon_id: String = current_weapon_id) -> bool:
	return weapon_id != "pistol" and weapon_id != "knife"


## Weapons with a procedural "ready" ADS pose (like the shotgun).
func _extra_has_ads(weapon_id: String = current_weapon_id) -> bool:
	return weapon_id in ["sawnoffs", "crossbow", "smg", "grenade_launcher", "lmg", "sawnoff"]


func _extra_vm(weapon_id: String = current_weapon_id) -> Dictionary:
	return EXTRA_VIEWMODEL.get(weapon_id, {}) as Dictionary


# ----------------------------------------------------------------- setup

func _create_extra_viewmodels() -> void:
	sawnoffs_viewmodel = _instantiate_extra_viewmodel(SAWNOFFS_VIEWMODEL_SCENE, "SawnoffsArmViewmodel")
	crossbow_viewmodel = _instantiate_extra_viewmodel(CROSSBOW_VIEWMODEL_SCENE, "CrossbowArmViewmodel")
	knife_viewmodel = _instantiate_extra_viewmodel(KNIFE_VIEWMODEL_SCENE, "KnifeArmViewmodel")
	minigun_viewmodel = _instantiate_extra_viewmodel(MINIGUN_VIEWMODEL_SCENE, "MinigunArmViewmodel")
	smg_viewmodel = _instantiate_extra_viewmodel(SMG_VIEWMODEL_SCENE, "SmgArmViewmodel")
	grenade_launcher_viewmodel = _instantiate_extra_viewmodel(GRENADE_LAUNCHER_VIEWMODEL_SCENE, "GrenadeLauncherArmViewmodel")
	lmg_viewmodel = _instantiate_extra_viewmodel(LMG_VIEWMODEL_SCENE, "LmgArmViewmodel")
	sawnoff_viewmodel = _instantiate_extra_viewmodel(SAWNOFF_VIEWMODEL_SCENE, "SawnoffArmViewmodel")


func _instantiate_extra_viewmodel(scene: PackedScene, node_name: String) -> Node3D:
	var model := scene.instantiate() as Node3D
	model.name = node_name
	model.visible = false
	viewmodel_root.add_child(model)
	_strip_imported_cameras(model)
	_prepare_viewmodel_geometry(model)
	return model


func _extra_viewmodel_node(weapon_id: String) -> Node3D:
	match weapon_id:
		"sawnoffs":
			return sawnoffs_viewmodel
		"crossbow":
			return crossbow_viewmodel
		"knife":
			return knife_viewmodel
		"minigun":
			return minigun_viewmodel
		"smg":
			return smg_viewmodel
		"grenade_launcher":
			return grenade_launcher_viewmodel
		"lmg":
			return lmg_viewmodel
		"sawnoff":
			return sawnoff_viewmodel
	return null


func _create_extra_weapon_audio() -> void:
	for key: String in EXTRA_SFX.keys():
		var spec: Array = EXTRA_SFX[key]
		var stream := _load_required_audio(_extra_sfx_path(key))
		var pool := _make_audio_pool("Extra_%s" % key, stream, int(spec[1]), float(spec[0]))
		for player in pool:
			# Paused tree = paused sound (the player node itself runs ALWAYS).
			player.process_mode = Node.PROCESS_MODE_PAUSABLE
		extra_sfx_pools[key] = pool
		extra_sfx_voice[key] = 0
	minigun_fire_loop_audio = _make_extra_loop_player("MinigunFireLoop", "minigun_fire_loop", -3.0)
	minigun_spin_loop_audio = _make_extra_loop_player("MinigunSpinLoop", "minigun_spin_loop", -6.0)


func _make_extra_loop_player(node_name: String, key: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.stream = _load_required_audio(_extra_sfx_path(key))
	player.volume_db = volume_db
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	return player


func _extra_sfx_path(key: String) -> String:
	var folder := "Shared"
	if key.begins_with("sawnoff"):
		folder = "Sawnoffs"
	elif key.begins_with("crossbow"):
		folder = "Crossbow"
	elif key.begins_with("knife"):
		folder = "Knife"
	elif key.begins_with("minigun"):
		folder = "Minigun"
	elif key.begins_with("smg"):
		folder = "SMG"
	elif key.begins_with("lmg"):
		folder = "LMG"
	elif key.begins_with("gl_"):
		folder = "GrenadeLauncher"
	elif key.begins_with("sawnoff_single"):
		folder = "Sawnoff"
	return "res://assets/Audio/%s/%s.wav" % [folder, key]


## pitch_variation 0.05 = ±5% (fire / swing sounds).
func _play_extra_sfx(key: String, pitch_variation: float = 0.02, from_position: float = 0.0) -> void:
	var pool: Array = extra_sfx_pools.get(key, [])
	if pool.is_empty():
		return
	var index := int(extra_sfx_voice.get(key, 0)) % pool.size()
	var player := pool[index] as AudioStreamPlayer
	extra_sfx_voice[key] = (index + 1) % pool.size()
	player.stop()
	player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	player.play(maxf(from_position, 0.0))


func _stop_extra_sfx(key: String) -> void:
	for player in extra_sfx_pools.get(key, []):
		(player as AudioStreamPlayer).stop()


## Schedules README cue times relative to a section start. Cues are dropped if
## the weapon changes (serial) or the tree is paused mid-wait (timer pauses).
func _schedule_extra_cues(cues: Array, section_start: float, playback_speed: float = 1.0) -> void:
	var serial := extra_cue_serial
	var weapon_id := current_weapon_id
	for cue in cues:
		var delay := maxf(0.0, (float(cue[0]) - section_start) / maxf(playback_speed, 0.01))
		_play_extra_cue_later(delay, String(cue[1]), serial, weapon_id)


func _play_extra_cue_later(delay: float, key: String, serial: int, weapon_id: String) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	if not is_instance_valid(self) or serial != extra_cue_serial or current_weapon_id != weapon_id:
		return
	_play_extra_sfx(key, 0.02)


func _bump_extra_serial() -> void:
	extra_cue_serial += 1


# ------------------------------------------------------------ ammo / stats

func _extra_starting_ammo(weapon_id: String) -> Dictionary:
	match weapon_id:
		"sawnoffs":
			return {"mag": SAWNOFFS_MAG_CAPACITY, "reserve": SAWNOFFS_STARTING_TOTAL_AMMO - SAWNOFFS_MAG_CAPACITY}
		"crossbow":
			return {"mag": CROSSBOW_MAG_CAPACITY, "reserve": CROSSBOW_STARTING_TOTAL_AMMO - CROSSBOW_MAG_CAPACITY}
		"knife":
			return {"mag": 1, "reserve": 0}
		"minigun":
			return {"mag": MINIGUN_MAG_CAPACITY, "reserve": MINIGUN_STARTING_TOTAL_AMMO - MINIGUN_MAG_CAPACITY}
		"smg":
			return {"mag": SMG_MAG_CAPACITY, "reserve": SMG_STARTING_TOTAL_AMMO - SMG_MAG_CAPACITY}
		"grenade_launcher":
			return {"mag": GRENADE_LAUNCHER_MAG_CAPACITY, "reserve": GRENADE_LAUNCHER_STARTING_TOTAL_AMMO - GRENADE_LAUNCHER_MAG_CAPACITY}
		"lmg":
			return {"mag": LMG_MAG_CAPACITY, "reserve": LMG_STARTING_TOTAL_AMMO - LMG_MAG_CAPACITY}
		"sawnoff":
			return {"mag": SAWNOFF_MAG_CAPACITY, "reserve": SAWNOFF_STARTING_TOTAL_AMMO - SAWNOFF_MAG_CAPACITY}
	return {}


func _extra_mag_capacity(weapon_id: String) -> int:
	match weapon_id:
		"sawnoffs":
			return SAWNOFFS_MAG_CAPACITY
		"crossbow":
			return CROSSBOW_MAG_CAPACITY
		"knife":
			return 1
		"minigun":
			return MINIGUN_MAG_CAPACITY
		"smg":
			return SMG_MAG_CAPACITY
		"grenade_launcher":
			return GRENADE_LAUNCHER_MAG_CAPACITY
		"lmg":
			return LMG_MAG_CAPACITY
		"sawnoff":
			return SAWNOFF_MAG_CAPACITY
	return PISTOL_MAG_CAPACITY


func _extra_shot_interval(weapon_id: String) -> float:
	match weapon_id:
		"sawnoffs":
			return SAWNOFFS_SHOT_INTERVAL
		"crossbow":
			return CROSSBOW_FIRE.y - CROSSBOW_FIRE.x
		"knife":
			return KNIFE_SLASH_INTERVAL
		"minigun":
			return MINIGUN_SHOT_INTERVAL
		"smg":
			return SMG_SHOT_INTERVAL
		"grenade_launcher":
			return GRENADE_LAUNCHER_SHOT_INTERVAL
		"lmg":
			return LMG_SHOT_INTERVAL
		"sawnoff":
			return SAWNOFF_SHOT_INTERVAL
	return maxf(pistol_shot_interval, 0.18)


## Sustained seconds per damage event, reload / recock included. Pause dashboard.
func _weapon_sustained_interval(weapon_id: String = current_weapon_id) -> float:
	match weapon_id:
		"sawnoffs":
			return (SAWNOFFS_FIRE_L.y + (SAWNOFFS_RELOAD.y - SAWNOFFS_RELOAD.x)) / 2.0
		"crossbow":
			return CROSSBOW_RELOAD.y
		"minigun":
			return (MINIGUN_MAG_CAPACITY * MINIGUN_SHOT_INTERVAL + MINIGUN_SPIN_UP_TIME + (MINIGUN_RELOAD.y - MINIGUN_RELOAD.x)) / float(MINIGUN_MAG_CAPACITY)
		"shotgun":
			return SHOTGUN_SHOT_INTERVAL
		"uzi":
			return UZI_SHOT_INTERVAL
		"knife":
			return KNIFE_SLASH_INTERVAL
		"smg":
			return (SMG_MAG_CAPACITY * SMG_SHOT_INTERVAL + (SMG_RELOAD.y - SMG_RELOAD.x)) / float(SMG_MAG_CAPACITY)
		"lmg":
			return (LMG_MAG_CAPACITY * LMG_SHOT_INTERVAL + (LMG_RELOAD.y - LMG_RELOAD.x)) / float(LMG_MAG_CAPACITY)
		"grenade_launcher":
			return GRENADE_LAUNCHER_FIRE.y + (GRENADE_LAUNCHER_RELOAD.y - GRENADE_LAUNCHER_RELOAD.x) / float(GRENADE_LAUNCHER_MAG_CAPACITY)
		"sawnoff":
			return (SAWNOFF_FIRE_L.y + (SAWNOFF_RELOAD.y - SAWNOFF_RELOAD.x)) / 2.0
	return maxf(pistol_shot_interval, 0.18)


func _extra_display_name(weapon_id: String) -> String:
	match weapon_id:
		"sawnoffs":
			return "SAWN-OFFS"
		"crossbow":
			return "CROSSBOW"
		"knife":
			return "KNIFE"
		"minigun":
			return "MINIGUN"
		"smg":
			return "SMG"
		"grenade_launcher":
			return "GRENADE LAUNCHER"
		"lmg":
			return "LMG"
		"sawnoff":
			return "SAWN-OFF"
	return "PISTOL"


# ------------------------------------------------------------ offers

func _weapon_role(weapon_id: String) -> String:
	return String(WEAPON_ROLES.get(weapon_id, weapon_id))


## Legal pool for the choice shown after clearing `cleared_room`.
func _weapon_offer_pool(cleared_room: int) -> Array[String]:
	var pool: Array[String] = []
	for weapon_id: String in ["pistol", "uzi", "shotgun", "knife", "sawnoffs", "crossbow", "minigun", "smg", "grenade_launcher", "lmg", "sawnoff"]:
		if cleared_room >= int(WEAPON_UNLOCK_AFTER_ROOM.get(weapon_id, 99)):
			pool.append(weapon_id)
	return pool


func _pick_weapon_choice_options(cleared_room: int) -> Array:
	var legal := _weapon_offer_pool(cleared_room)
	var unowned: Array[String] = []
	var owned: Array[String] = []
	for weapon_id in legal:
		if _owns_weapon(weapon_id):
			owned.append(weapon_id)
		else:
			unowned.append(weapon_id)
	unowned.shuffle()
	owned.shuffle()
	var shown: Array = []
	var first := ""
	if not unowned.is_empty():
		first = unowned.pop_front()
	elif not owned.is_empty():
		first = owned.pop_front()
	if first.is_empty():
		return shown
	shown.append(first)
	var first_role := _weapon_role(first)
	# Second pick: never the same role. Unowned first, then an owned refill.
	for candidates: Array[String] in [unowned, owned]:
		for weapon_id in candidates:
			if shown.size() >= 2:
				break
			if _weapon_role(weapon_id) != first_role:
				shown.append(weapon_id)
	if shown.size() < 2:
		# Every legal gun shares a role with the first pick (cannot happen with
		# the current pools). Still show two guns.
		for weapon_id in legal:
			if not shown.has(weapon_id):
				shown.append(weapon_id)
				break
	return shown


func _knife_refill_heal() -> void:
	heal(KNIFE_REFILL_HEAL)


# ------------------------------------------------------------ equip

func _equip_extra_weapon(weapon_id: String, play_inspect: bool) -> void:
	_bump_extra_serial()
	_reset_packed_state()
	weapon_intro_locked = false
	unlimited_ammo = weapon_id == "knife"
	if weapon_id == "knife":
		_play_extra_sfx("knife_draw_shing", 0.03)
	else:
		_play_extra_sfx("shared_weapon_raise_%d" % (1 + randi() % 2), 0.03)
	match weapon_id:
		"sawnoffs":
			_hold_packed_idle()
			if play_inspect:
				_play_packed_section(&"inspect", SAWNOFFS_FLOURISH.x, SAWNOFFS_FLOURISH.y, 0.10, 1.0)
				_schedule_extra_cues(SAWNOFFS_FLOURISH_CUES, SAWNOFFS_FLOURISH.x)
		"crossbow":
			_hold_packed_idle()
			if play_inspect:
				_play_packed_section(&"inspect", CROSSBOW_HANDLE.x, CROSSBOW_HANDLE.y, 0.10, 1.0)
				_schedule_extra_cues(CROSSBOW_HANDLE_CUES, CROSSBOW_HANDLE.x)
		"knife":
			if play_inspect:
				_play_packed_section(&"inspect", KNIFE_INSPECT.x, KNIFE_INSPECT.y, 0.10, 1.0)
				_schedule_extra_cues(KNIFE_INSPECT_CUES, KNIFE_INSPECT.x)
			else:
				_hold_packed_idle()
		"minigun":
			if play_inspect:
				_play_packed_section(&"inspect", MINIGUN_INSPECT.x, MINIGUN_INSPECT.y, 0.10, 1.0)
				_schedule_extra_cues(MINIGUN_INSPECT_CUES, MINIGUN_INSPECT.x)
			else:
				_hold_packed_idle()
		"smg":
			_hold_packed_idle()
			if play_inspect:
				_play_packed_section(&"inspect", SMG_INSPECT.x, SMG_INSPECT.y, 0.10, 1.0)
		"grenade_launcher":
			_hold_packed_idle()
			if play_inspect:
				_play_packed_section(&"inspect", GRENADE_LAUNCHER_INSPECT.x, GRENADE_LAUNCHER_INSPECT.y, 0.10, 1.0)
		"lmg":
			_hold_packed_idle()
			if play_inspect:
				_play_packed_section(&"inspect", LMG_INSPECT.x, LMG_INSPECT.y, 0.10, 1.0)
		"sawnoff":
			_hold_packed_idle()
			if play_inspect:
				_play_packed_section(&"inspect", SAWNOFF_INSPECT.x, SAWNOFF_INSPECT.y, 0.10, 1.0)


## Called whenever a weapon is equipped or the viewmodel leaves an extra gun.
func _reset_packed_state() -> void:
	packed_action = &"idle"
	packed_section_playing = false
	packed_section_loop = false
	crossbow_bash_active = false
	knife_attack_cooldown = 0.0
	_minigun_force_stop(false)


# ------------------------------------------------------------ section player

func _packed_clip() -> StringName:
	var clip := StringName(_extra_vm().get("clip", &""))
	if viewmodel_anim_player == null:
		return clip
	if viewmodel_anim_player.has_animation(clip):
		return clip
	var names := viewmodel_anim_player.get_animation_list()
	return StringName(names[0]) if not names.is_empty() else clip


func _play_packed_section(
	action: StringName,
	from_time: float,
	to_time: float,
	blend_time: float = 0.06,
	playback_speed: float = 1.0,
	loop: bool = false
) -> void:
	var clip := _packed_clip()
	if viewmodel_anim_player == null or not viewmodel_anim_player.has_animation(clip):
		return
	packed_action = action
	packed_section_start = from_time
	packed_section_end = to_time
	packed_section_speed = playback_speed
	packed_section_loop = loop
	packed_section_playing = true
	viewmodel_anim_player.speed_scale = 1.0
	viewmodel_anim_player.play(clip, blend_time, playback_speed)
	viewmodel_anim_player.seek(from_time, true)
	viewmodel_animation_state = action


func _hold_packed_at(time: float, state: StringName = &"packed_idle") -> void:
	packed_action = &"idle"
	packed_section_playing = false
	packed_section_loop = false
	var clip := _packed_clip()
	if viewmodel_anim_player != null and viewmodel_anim_player.has_animation(clip):
		viewmodel_anim_player.play(clip, 0.08, 1.0)
		viewmodel_anim_player.seek(time, true)
		viewmodel_anim_player.pause()
	viewmodel_animation_state = state


## Resting pose for the current extra weapon (depends on what is chambered).
func _hold_packed_idle() -> void:
	match current_weapon_id:
		"sawnoffs":
			if ammo >= 2:
				_hold_packed_at(SAWNOFFS_FIRE_R.x)
			elif ammo == 1:
				_hold_packed_at(SAWNOFFS_FIRE_L.x)
			else:
				_hold_packed_at(SAWNOFFS_FIRE_L.y)
		"crossbow":
			# 0.00 = bolt home, string drawn; FIRE.y = shot settled, no bolt.
			_hold_packed_at(CROSSBOW_FIRE.x if ammo > 0 else CROSSBOW_FIRE.y)
		"knife":
			_play_packed_section(&"idle_loop", KNIFE_IDLE.x, KNIFE_IDLE.y, 0.12, 1.0, true)
		"minigun":
			_play_packed_section(&"idle_loop", MINIGUN_IDLE.x, MINIGUN_IDLE.y, 0.12, 1.0, true)
		"smg":
			_play_packed_section(&"idle_loop", SMG_IDLE.x, SMG_IDLE.y, 0.10, 1.0, true)
		"grenade_launcher":
			# Both are the closed gun at rest: 0.00 before a shot, FIRE.y after
			# the cylinder advance (before the break-open that starts reload).
			_hold_packed_at(GRENADE_LAUNCHER_FIRE.x if ammo > 0 else GRENADE_LAUNCHER_FIRE.y)
		"lmg":
			_play_packed_section(&"idle_loop", LMG_IDLE.x, LMG_IDLE.y, 0.10, 1.0, true)
		"sawnoff":
			# Loaded rest is the pre-shot frame; empty is the settled
			# post-shot frame (barrels shut), never a reload frame.
			_hold_packed_at(SAWNOFF_FIRE_R.x if ammo > 0 else SAWNOFF_FIRE_L.y)


func _update_packed_animation(_sprinting: bool, _delta: float) -> void:
	if viewmodel_anim_player == null:
		return
	if packed_section_playing:
		var reached_end := (
			not viewmodel_anim_player.is_playing()
			or viewmodel_anim_player.current_animation_position >= packed_section_end - 0.012
		)
		if not reached_end:
			return
		if packed_section_loop:
			viewmodel_anim_player.seek(packed_section_start, true)
			if not viewmodel_anim_player.is_playing():
				viewmodel_anim_player.play(_packed_clip(), 0.0, packed_section_speed)
				viewmodel_anim_player.seek(packed_section_start, true)
			return
		packed_section_playing = false
		viewmodel_anim_player.pause()
		viewmodel_anim_player.seek(packed_section_end, true)
		_on_packed_section_finished(packed_action)
		return
	if is_reloading or crossbow_bash_active:
		return
	if viewmodel_animation_state != &"packed_idle" and packed_action == &"idle":
		_hold_packed_idle()


func _on_packed_section_finished(action: StringName) -> void:
	match action:
		&"fire", &"inspect", &"slash", &"bash":
			crossbow_bash_active = false
			_hold_packed_idle()
			# Both barrels spent: the break-reload starts the moment the
			# left-barrel clip ends, not on a later trigger pull.
			if action == &"fire" and current_weapon_id in ["sawnoffs", "sawnoff"] and ammo <= 0 and reserve_ammo > 0 and not is_reloading:
				reload_pending_timer = 0.0
				_start_reload(true)
		&"reload":
			pass   # _finish_reload() returns to idle when the rounds land.
		_:
			_hold_packed_idle()


# ------------------------------------------------------------ ADS pose

func _apply_packed_sight_alignment(eased_blend: float) -> void:
	if viewmodel_visual == null:
		return
	_init_extra_ready_defaults()
	var hip_pos := viewmodel_tune_position
	var hip_rot := viewmodel_tune_rotation
	var scl := viewmodel_tune_scale
	var ready_pos: Vector3 = extra_ready_position.get(current_weapon_id, hip_pos) as Vector3
	var ready_rot: Vector3 = extra_ready_rotation.get(current_weapon_id, hip_rot) as Vector3
	var ready_scl: float = float(extra_ready_scale.get(current_weapon_id, scl))
	var t := clampf(eased_blend, 0.0, 1.0) if _extra_has_ads() else 0.0
	viewmodel_visual.position = hip_pos.lerp(ready_pos, t)
	viewmodel_visual.rotation_degrees = hip_rot.lerp(ready_rot, t)
	viewmodel_visual.scale = Vector3.ONE * lerpf(scl, ready_scl, t)


# ------------------------------------------------------------ per-frame

## Runs after _update_ads_fire every physics frame.
func _update_extra_weapons(delta: float, sprinting: bool) -> void:
	knife_attack_cooldown = maxf(0.0, knife_attack_cooldown - delta)
	if current_weapon_id == "minigun" and not quick_knife_active:
		_update_minigun(delta, sprinting)
	elif minigun_spin > 0.0 or minigun_trigger_was_down:
		_minigun_force_stop(false)
	if current_weapon_id == "knife" and not quick_knife_active:
		# Hold fire = keep slashing on the knife's own interval.
		if _fire_input_held() and not sprinting and not sprint_active and knife_attack_cooldown <= 0.0 and not weapon_intro_locked:
			_knife_attack(aim_toggle_active)


## Stops loops when the game pauses, a choice screen opens, or the run ends.
func _update_extra_weapons_blocked() -> void:
	if minigun_spin > 0.0 or minigun_trigger_was_down or (minigun_fire_loop_audio != null and minigun_fire_loop_audio.playing):
		_minigun_force_stop(true)


func _fire_input_held() -> bool:
	return fire_touch_id != -1 or desktop_fire_held


# ------------------------------------------------------------ fire routing

## Returns true when the extra weapon consumed the fire press.
func _extra_begin_fire_input() -> bool:
	match current_weapon_id:
		"knife":
			if knife_attack_cooldown <= 0.0 and not weapon_intro_locked:
				_knife_attack(aim_toggle_active)
			return true
		"minigun":
			# The spin state machine reads the held trigger every frame.
			return true
	return false


func _extra_shoot_effects() -> void:
	match current_weapon_id:
		"sawnoffs":
			var right_barrel := ammo >= 1   # ammo already decremented: 1 left = right barrel just fired
			if right_barrel:
				_play_packed_section(&"fire", SAWNOFFS_FIRE_R.x, SAWNOFFS_FIRE_R.y, 0.02, 1.0)
				_play_extra_sfx("sawnoff_fire_1", 0.05)
			else:
				_play_packed_section(&"fire", SAWNOFFS_FIRE_L.x, SAWNOFFS_FIRE_L.y, 0.02, 1.0)
				_play_extra_sfx("sawnoff_fire_%d" % (2 + randi() % 2), 0.05)
		"crossbow":
			_play_packed_section(&"fire", CROSSBOW_FIRE.x, CROSSBOW_FIRE.y, 0.02, 1.0)
			_play_extra_sfx("crossbow_fire_%d" % (1 + randi() % 2), 0.05)
		"minigun":
			if packed_action != &"mg_fire":
				_play_packed_section(&"mg_fire", MINIGUN_FIRE_LOOP.x, MINIGUN_FIRE_LOOP.y, 0.04, 1.0, true)
		"smg":
			_play_packed_section(&"fire", SMG_FIRE.x, SMG_FIRE.y, 0.02, 1.0)
			_play_extra_sfx("smg_fire_%d" % (1 + randi() % 2), 0.05)
		"grenade_launcher":
			_play_packed_section(&"fire", GRENADE_LAUNCHER_FIRE.x, GRENADE_LAUNCHER_FIRE.y, 0.02, 1.0)
			_play_extra_sfx("gl_fire_%d" % (1 + randi() % 2), 0.04)
		"lmg":
			_play_packed_section(&"fire", LMG_FIRE.x, LMG_FIRE.y, 0.02, 1.0)
			_play_extra_sfx("lmg_fire_%d" % (1 + randi() % 2), 0.05)
		"sawnoff":
			if ammo >= 1:
				_play_packed_section(&"fire", SAWNOFF_FIRE_R.x, SAWNOFF_FIRE_R.y, 0.02, 1.0)
				_play_extra_sfx("sawnoff_single_fire_1", 0.05)
			else:
				_play_packed_section(&"fire", SAWNOFF_FIRE_L.x, SAWNOFF_FIRE_L.y, 0.02, 1.0)
				_play_extra_sfx("sawnoff_single_fire_2", 0.05)


## Damage for the shot _shoot() just took.
func _extra_fire_damage() -> void:
	match current_weapon_id:
		"sawnoffs":
			_fire_pellet_blast("sawnoffs", SAWNOFFS_PELLETS, SAWNOFFS_SPREAD_HIP, SAWNOFFS_SPREAD_ADS)
		"sawnoff":
			_fire_pellet_blast("sawnoff", SAWNOFF_PELLETS, SAWNOFF_SPREAD_HIP, SAWNOFF_SPREAD_ADS)
		"grenade_launcher":
			_fire_grenade_blast()
		_:
			# Crossbow, minigun, SMG, LMG: straight camera-centre hitscan.
			_fire_hitscan_bullet(UpgradeManager.get_weapon_damage(current_weapon_id))


## Seconds to wait before the auto reload after the last round leaves.
func _extra_empty_reload_delay() -> float:
	match current_weapon_id:
		"sawnoffs":
			return SAWNOFFS_FIRE_L.y - SAWNOFFS_FIRE_L.x
		"crossbow":
			return CROSSBOW_FIRE.y - CROSSBOW_FIRE.x
		"minigun":
			return 0.35
		"smg":
			return SMG_FIRE.y - SMG_FIRE.x
		"lmg":
			return LMG_FIRE.y - LMG_FIRE.x
		"grenade_launcher":
			return GRENADE_LAUNCHER_FIRE.y - GRENADE_LAUNCHER_FIRE.x
		"sawnoff":
			return SAWNOFF_FIRE_L.y - SAWNOFF_FIRE_L.x
	return 0.16


# ------------------------------------------------------------ reload

func _start_extra_reload() -> void:
	_bump_extra_serial()
	match current_weapon_id:
		"sawnoffs":
			_play_packed_section(&"reload", SAWNOFFS_RELOAD.x, SAWNOFFS_RELOAD.y, 0.06, 1.0)
			_schedule_extra_cues(SAWNOFFS_RELOAD_CUES, SAWNOFFS_RELOAD.x)
			reload_timer = SAWNOFFS_RELOAD.y - SAWNOFFS_RELOAD.x
		"crossbow":
			_play_packed_section(&"reload", CROSSBOW_RELOAD.x, CROSSBOW_RELOAD.y, 0.04, 1.0)
			_schedule_extra_cues(CROSSBOW_RELOAD_CUES, CROSSBOW_RELOAD.x)
			reload_timer = CROSSBOW_RELOAD.y - CROSSBOW_RELOAD.x
		"minigun":
			_minigun_force_stop(false)
			_play_packed_section(&"reload", MINIGUN_RELOAD.x, MINIGUN_RELOAD.y, 0.08, 1.0)
			_schedule_extra_cues(MINIGUN_RELOAD_CUES, MINIGUN_RELOAD.x)
			reload_timer = MINIGUN_RELOAD.y - MINIGUN_RELOAD.x
		"smg":
			_play_packed_section(&"reload", SMG_RELOAD.x, SMG_RELOAD.y, 0.06, 1.0)
			_schedule_extra_cues(SMG_RELOAD_CUES, SMG_RELOAD.x)
			reload_timer = SMG_RELOAD.y - SMG_RELOAD.x
		"grenade_launcher":
			_play_packed_section(&"reload", GRENADE_LAUNCHER_RELOAD.x, GRENADE_LAUNCHER_RELOAD.y, 0.06, 1.0)
			_schedule_extra_cues(GRENADE_LAUNCHER_RELOAD_CUES, GRENADE_LAUNCHER_RELOAD.x)
			reload_timer = GRENADE_LAUNCHER_RELOAD.y - GRENADE_LAUNCHER_RELOAD.x
		"lmg":
			_play_packed_section(&"reload", LMG_RELOAD.x, LMG_RELOAD.y, 0.08, 1.0)
			_schedule_extra_cues(LMG_RELOAD_CUES, LMG_RELOAD.x)
			reload_timer = LMG_RELOAD.y - LMG_RELOAD.x
		"sawnoff":
			_play_packed_section(&"reload", SAWNOFF_RELOAD.x, SAWNOFF_RELOAD.y, 0.06, 1.0)
			_schedule_extra_cues(SAWNOFF_RELOAD_CUES, SAWNOFF_RELOAD.x)
			reload_timer = SAWNOFF_RELOAD.y - SAWNOFF_RELOAD.x
		_:
			is_reloading = false


func _finish_extra_reload() -> void:
	packed_section_playing = false
	_hold_packed_idle()
	if current_weapon_id != "minigun" and _fire_input_held():
		_begin_fire_input()


func _play_extra_empty_click() -> void:
	_play_extra_sfx("shared_dry_fire_click", 0.04)
	empty_click_cooldown = 0.25


# ------------------------------------------------------------ pellets

## Shared pellet blast (shotgun + sawn-offs). Headshot bonus folded into the
## damage per target so zombie.gd does not double it.
func _fire_pellet_blast(weapon_id: String, pellet_count: int, spread_hip: float, spread_ads: float) -> void:
	var aim_screen_position := _get_aim_screen_position()
	var from := camera.project_ray_origin(aim_screen_position)
	var aim_dir := camera.project_ray_normal(aim_screen_position)
	var spread := lerpf(spread_hip, spread_ads, ads_blend)
	var pellet_damage := UpgradeManager.get_weapon_damage(weapon_id) / float(pellet_count)
	var grouped: Dictionary = {}
	for _pellet in range(pellet_count):
		var dir := aim_dir.rotated(camera.global_basis.x, randf_range(-spread, spread))
		dir = dir.rotated(camera.global_basis.y, randf_range(-spread, spread)).normalized()
		var hit := _camera_ray(from, dir, 100.0)
		if hit.is_empty():
			continue
		var damage_target: Object = hit["damage_target"]
		if damage_target == null:
			continue
		var key := damage_target.get_instance_id()
		if not grouped.has(key):
			grouped[key] = {
				"target": damage_target,
				"damage": 0.0,
				"position": hit.get("position", from + dir * 100.0),
				"normal": hit.get("normal", Vector3.ZERO),
				"headshot": false,
			}
		var is_headshot := bool(hit["is_headshot"])
		grouped[key]["damage"] += pellet_damage * (2.0 if is_headshot else 1.0)
		if is_headshot:
			grouped[key]["headshot"] = true
	for entry in grouped.values():
		var damage_target: Object = entry["target"]
		if damage_target.has_method("receive_bullet_hit"):
			shots_hit += 1
			RunManager.register_hit(bool(entry["headshot"]))
			damage_target.call("receive_bullet_hit", entry["damage"], entry["position"], from, false, entry["normal"])
		elif damage_target.has_method("take_damage"):
			shots_hit += 1
			RunManager.register_hit(bool(entry["headshot"]))
			damage_target.call("take_damage", entry["damage"])


## Impact grenade: hitscan to the aim point, then splash nearby zombies.
func _fire_grenade_blast() -> void:
	var aim_screen_position := _get_aim_screen_position()
	var from := camera.project_ray_origin(aim_screen_position)
	var aim_dir := camera.project_ray_normal(aim_screen_position)
	var hit := _camera_ray(from, aim_dir, 80.0)
	var impact: Vector3 = hit.get("position", from + aim_dir * 24.0) if not hit.is_empty() else from + aim_dir * 24.0
	var direct: Object = hit.get("damage_target", null) if not hit.is_empty() else null
	var base_damage := UpgradeManager.get_weapon_damage("grenade_launcher")
	var scored := false
	for node in get_tree().get_nodes_in_group("zombies"):
		if node == null or not is_instance_valid(node) or not bool(node.get("alive")):
			continue
		var body_pos: Vector3 = node.global_position + Vector3.UP * 0.9
		var dist := body_pos.distance_to(impact)
		if dist > GRENADE_LAUNCHER_SPLASH_RADIUS:
			continue
		var falloff := 1.0 - (dist / GRENADE_LAUNCHER_SPLASH_RADIUS) * 0.55
		var is_direct := node == direct
		var damage := base_damage * falloff * (1.15 if is_direct else 1.0)
		if node.has_method("receive_bullet_hit"):
			node.call("receive_bullet_hit", damage, body_pos, from, is_direct, Vector3.UP)
		elif node.has_method("take_damage"):
			node.call("take_damage", damage)
		scored = true
	if scored:
		shots_hit += 1
		RunManager.register_hit(direct != null)


## Raw camera ray with the same mask/areas as gun hitscan. Resolves the zombie
## head hitbox to its owner and flags the headshot. Does not apply damage.
func _camera_ray(from: Vector3, direction: Vector3, max_range: float) -> Dictionary:
	var to := from + direction * max_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 1 | 8 | 32
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {}
	var collider = hit.get("collider")
	var damage_target: Object = collider
	var is_headshot := false
	if collider is Area3D and bool(collider.get_meta("zombie_head_hitbox", false)):
		is_headshot = true
		damage_target = collider.get_parent()
	hit["damage_target"] = damage_target
	hit["is_headshot"] = is_headshot
	hit["is_zombie"] = damage_target != null and (damage_target.has_method("receive_bullet_hit") or damage_target.has_method("take_damage"))
	return hit


# ------------------------------------------------------------ melee

## Short melee trace from camera centre. The centre ray wins; two small side
## rays make the slash forgiving without leaving camera-centre hitscan law.
func _melee_trace(max_range: float, arc: float) -> Dictionary:
	var aim := _get_aim_screen_position()
	var from := camera.project_ray_origin(aim)
	var forward := camera.project_ray_normal(aim)
	var first_world: Dictionary = {}
	for yaw: float in [0.0, -arc, arc]:
		var dir := forward.rotated(camera.global_basis.y, yaw).normalized()
		var hit := _camera_ray(from, dir, max_range)
		if hit.is_empty():
			continue
		if bool(hit.get("is_zombie", false)):
			hit["from"] = from
			return hit
		if first_world.is_empty() and yaw == 0.0:
			first_world = hit
	if not first_world.is_empty():
		first_world["from"] = from
	return first_world


func _apply_melee_hit(hit: Dictionary, damage: float, flesh_prefix: String, wall_key: String) -> void:
	if hit.is_empty():
		return
	if bool(hit.get("is_zombie", false)):
		var target: Object = hit["damage_target"]
		if target.has_method("receive_bullet_hit"):
			target.call("receive_bullet_hit", damage, hit.get("position", Vector3.ZERO), hit.get("from", global_position), bool(hit["is_headshot"]), hit.get("normal", Vector3.ZERO))
		else:
			target.call("take_damage", damage * (2.0 if bool(hit["is_headshot"]) else 1.0))
		RunManager.register_hit(bool(hit["is_headshot"]))
		MusicManager.notify_combat_action(0.30)
		_mobile_shoot_feedback()
		if flesh_prefix != "":
			_play_extra_sfx("%s_%d" % [flesh_prefix, 1 + randi() % 3], 0.05)
	elif wall_key != "":
		_play_extra_sfx(wall_key, 0.05)


func _knife_attack(stab: bool, quick: bool = false) -> void:
	if game_over or get_tree().paused or weapon_choice_active or death_sequence_active:
		return
	if sprint_active and not quick:
		# Same law as guns: attacking breaks the sprint first.
		sprint_exit_fire_pending = true
		sprint_suppressed_for_combat = true
		mobile_sprint = false
		return
	var interval := KNIFE_STAB_INTERVAL if stab else KNIFE_SLASH_INTERVAL
	if quick:
		interval = KNIFE_QUICK_STAB_TIME
	knife_attack_cooldown = interval
	var section := KNIFE_SLASH_2 if (knife_next_slash_is_second or stab) else KNIFE_SLASH_1
	if not stab:
		knife_next_slash_is_second = not knife_next_slash_is_second
	var speed := (section.y - section.x) / interval
	_play_packed_section(&"slash", section.x, section.y, 0.03, speed)
	_play_extra_sfx("knife_swing_%d" % (1 + randi() % 3), 0.05)
	_apply_knife_swing_feel(stab)
	var damage := UpgradeManager.get_weapon_damage("knife_stab" if stab else "knife")
	var reach := KNIFE_STAB_RANGE if stab else KNIFE_SLASH_RANGE
	# The blade connects near the middle of the swing, not on the button press.
	_deliver_melee_later(interval * (0.30 if stab else 0.22), reach, damage, 0.0 if stab else 0.09, "knife_hit_flesh", "knife_hit_wall")


func _deliver_melee_later(delay: float, reach: float, damage: float, arc: float, flesh_prefix: String, wall_key: String) -> void:
	var serial := extra_cue_serial
	await get_tree().create_timer(delay, false).timeout
	if not is_instance_valid(self) or serial != extra_cue_serial or game_over:
		return
	_apply_melee_hit(_melee_trace(reach, arc), damage, flesh_prefix, wall_key)


func _apply_knife_swing_feel(stab: bool) -> void:
	var camera_omega: float = sqrt(_weapon_camera_spring().x)
	var hand_omega: float = sqrt(_weapon_hand_spring().x)
	var side: float = -1.0 if knife_next_slash_is_second else 1.0
	if stab:
		# Lunge: the view drives forward a touch and the hand punches out.
		camera_kick_push_velocity -= 0.028 * camera_omega * 2.0
		camera_kick_velocity.x += deg_to_rad(-0.6) * camera_omega * 2.0
		hand_kick_position_velocity += Vector3(0.0, 0.004, -0.030) * hand_omega * 2.0
	else:
		camera_kick_velocity.y += deg_to_rad(0.55) * side * camera_omega * 2.0
		camera_kick_velocity.z += deg_to_rad(0.70) * side * camera_omega * 2.0
		hand_kick_rotation_velocity += Vector3(-1.5, 3.0 * side, 4.0 * side) * hand_omega


## Settings MELEE button / V key.
func _on_melee_pressed() -> void:
	if game_over or get_tree().paused or not has_pistol or weapon_choice_active or death_sequence_active:
		return
	if quick_knife_active:
		return
	if current_weapon_id == "knife":
		if knife_attack_cooldown <= 0.0 and not weapon_intro_locked:
			_knife_attack(aim_toggle_active)
		return
	if current_weapon_id == "crossbow" and _crossbow_try_bash():
		return
	if _swap_target_weapon_id() == "knife":
		_quick_knife_stab()


func _quick_knife_stab() -> void:
	if is_reloading or weapon_intro_locked or crossbow_bash_active:
		return
	if current_weapon_id == "shotgun" and (shotgun_action == &"fire" or shotgun_action == &"pump"):
		return
	quick_knife_return_id = current_weapon_id
	quick_knife_active = true
	weapon_intro_locked = true
	desktop_fire_held = false
	_end_fire_input()
	_cancel_ads(true)
	_minigun_force_stop(false)
	# Ammo vars are untouched: the knife never spends them, so the gun comes
	# back exactly as it left. Loadout and RunManager do not change.
	current_weapon_id = "knife"
	_bump_extra_serial()
	_show_weapon_viewmodel("knife")
	_apply_weapon_viewmodel_pose()
	knife_attack_cooldown = 0.0
	_knife_attack(false, true)
	var serial := extra_cue_serial
	await get_tree().create_timer(KNIFE_QUICK_STAB_TIME, false).timeout
	if not is_instance_valid(self):
		return
	_end_quick_knife(serial)


func _end_quick_knife(_serial: int = -1) -> void:
	if not quick_knife_active:
		return
	quick_knife_active = false
	var back := quick_knife_return_id
	quick_knife_return_id = ""
	if back.is_empty() or game_over:
		weapon_intro_locked = false
		return
	current_weapon_id = back
	_equip_weapon(back, false)
	_refresh_swap_button()


func _crossbow_try_bash() -> bool:
	if is_reloading or crossbow_bash_active or shot_cooldown > 0.05:
		return false
	var hit := _melee_trace(CROSSBOW_BASH_RANGE, 0.10)
	if hit.is_empty() or not bool(hit.get("is_zombie", false)):
		return false
	crossbow_bash_active = true
	shot_cooldown = CROSSBOW_BASH.y - CROSSBOW_BASH.x
	_cancel_ads(true)
	_play_packed_section(&"bash", CROSSBOW_BASH.x, CROSSBOW_BASH.y, 0.04, 1.0)
	_schedule_extra_cues([[4.98, "crossbow_bash_swing"]], CROSSBOW_BASH.x)
	_deliver_melee_later(0.16, CROSSBOW_BASH_RANGE, UpgradeManager.get_weapon_damage("crossbow_bash"), 0.10, "knife_hit_flesh", "")
	return true


# ------------------------------------------------------------ minigun

func _minigun_barrels_up() -> bool:
	return current_weapon_id == "minigun" and (minigun_spin > 0.01 or minigun_trigger_was_down)


func _update_minigun(delta: float, sprinting: bool) -> void:
	var trigger_down := (
		_fire_input_held()
		and not is_reloading
		and not weapon_intro_locked
		and not sprinting
		and not game_over
	)
	if trigger_down and not minigun_trigger_was_down:
		# Barrels start (or resume) spinning from wherever they are.
		_stop_extra_sfx("minigun_spin_down")
		_play_extra_sfx("minigun_spin_up", 0.0, minigun_spin * MINIGUN_SPIN_UP_TIME)
		minigun_fired_this_burst = false
	elif not trigger_down and minigun_trigger_was_down:
		_minigun_release()
	minigun_trigger_was_down = trigger_down

	if trigger_down:
		minigun_spin = minf(1.0, minigun_spin + delta / MINIGUN_SPIN_UP_TIME)
	else:
		minigun_spin = maxf(0.0, minigun_spin - delta / MINIGUN_SPIN_DOWN_TIME)

	if trigger_down and minigun_spin >= 1.0:
		if ammo > 0:
			if minigun_spin_loop_audio != null and minigun_spin_loop_audio.playing:
				minigun_spin_loop_audio.stop()
			if minigun_fire_loop_audio != null and not minigun_fire_loop_audio.playing:
				minigun_fire_loop_audio.play()
			if shot_cooldown <= 0.0:
				_shoot()
				minigun_fired_this_burst = true
			if ammo <= 0:
				# Box is dry: barrels keep turning on the trigger, no rounds.
				if minigun_fire_loop_audio != null:
					minigun_fire_loop_audio.stop()
				_play_extra_sfx("minigun_fire_tail", 0.03)
				minigun_fired_this_burst = false
		else:
			if minigun_fire_loop_audio != null and minigun_fire_loop_audio.playing:
				minigun_fire_loop_audio.stop()
			if minigun_spin_loop_audio != null and not minigun_spin_loop_audio.playing:
				minigun_spin_loop_audio.play()
	# Barrel visual: the 0.00–0.20 fire loop is one 60° barrel step. Run it at
	# the spin speed so the cluster visibly winds up and down.
	if not is_reloading and packed_action != &"inspect":
		if minigun_spin > 0.02:
			if packed_action != &"mg_fire":
				_play_packed_section(&"mg_fire", MINIGUN_FIRE_LOOP.x, MINIGUN_FIRE_LOOP.y, 0.06, maxf(minigun_spin, 0.15), true)
			elif viewmodel_anim_player != null:
				packed_section_speed = maxf(minigun_spin, 0.15)
				viewmodel_anim_player.speed_scale = packed_section_speed
		elif packed_action == &"mg_fire":
			viewmodel_anim_player.speed_scale = 1.0
			_hold_packed_idle()
	# Auto reload once the trigger is released on an empty box.
	if not trigger_down and ammo <= 0 and reserve_ammo > 0 and not is_reloading and reload_pending_timer <= 0.0 and minigun_spin <= 0.35:
		_start_reload()


func _minigun_release() -> void:
	_stop_extra_sfx("minigun_spin_up")
	if minigun_fire_loop_audio != null:
		minigun_fire_loop_audio.stop()
	if minigun_spin_loop_audio != null:
		minigun_spin_loop_audio.stop()
	if minigun_fired_this_burst:
		_play_extra_sfx("minigun_fire_tail", 0.03)
	# A tap shorter than the spin-up still plays up + down, never a free round.
	var spin_down_len := 1.6
	_play_extra_sfx("minigun_spin_down", 0.0, (1.0 - minigun_spin) * spin_down_len * 0.6)
	minigun_fired_this_burst = false


func _minigun_force_stop(play_down: bool) -> void:
	if play_down and (minigun_spin > 0.05 or minigun_trigger_was_down):
		_minigun_release()
	else:
		_stop_extra_sfx("minigun_spin_up")
		if minigun_fire_loop_audio != null:
			minigun_fire_loop_audio.stop()
		if minigun_spin_loop_audio != null:
			minigun_spin_loop_audio.stop()
	minigun_spin = 0.0
	minigun_trigger_was_down = false
	minigun_fired_this_burst = false
	if viewmodel_anim_player != null and packed_action == &"mg_fire":
		viewmodel_anim_player.speed_scale = 1.0


# ------------------------------------------------------------ recoil

func _extra_recoil(weapon_id: String) -> Dictionary:
	return EXTRA_RECOIL.get(weapon_id, {}) as Dictionary



# =============================================================================
# Grounded stair camera layer (additive)
# -----------------------------------------------------------------------------
# Rides on top of walk / sprint / jump / land. Only active while the capsule is
# ON THE FLOOR and the floor it slid on this frame is tagged "stair_surface"
# (Cafeteria exit flight). Stairs are never treated as airborne, so nothing here
# can start the jump, landing or hard-landing cameras. Output is two small
# springs: CameraPivot height and a camera pitch term, both capped.
# =============================================================================

@export_category("Stair Camera")
@export var stair_camera_lift_up: float = 0.011
@export var stair_camera_drop_down: float = 0.013
@export var stair_camera_pitch_up_degrees: float = 0.40
@export var stair_camera_pitch_down_degrees: float = -0.55
@export var stair_camera_spring: float = 110.0
@export var stair_camera_damping: float = 19.0
@export var stair_step_run: float = 0.30
@export var stair_step_thud_up: float = 0.0034
@export var stair_step_thud_down: float = 0.0020

const STAIR_CAMERA_MAX_OFFSET := 0.022
const STAIR_CAMERA_MAX_PITCH := 0.8

var stair_camera_offset: float = 0.0
var stair_camera_offset_velocity: float = 0.0
var stair_camera_pitch_degrees: float = 0.0
var stair_camera_pitch_velocity: float = 0.0
var stair_contact_active := false
var stair_step_distance: float = 0.0


## Up-slope direction of the stair surface under the player, or ZERO.
func _stair_surface_up_direction() -> Vector3:
	if not is_on_floor():
		return Vector3.ZERO
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		if collision == null:
			continue
		if collision.get_normal().y < 0.55:
			continue
		var collider := collision.get_collider() as Node
		if collider != null and collider.has_meta("stair_surface"):
			var up_dir: Vector3 = collider.get_meta("stair_up_direction", Vector3.ZERO)
			if up_dir != Vector3.ZERO and collider is Node3D:
				# Authored in the stair body's local space; rooms are rotated
				# into place by the door alignment.
				up_dir = ((collider as Node3D).global_transform.basis * up_dir).normalized()
			if up_dir == Vector3.ZERO:
				# Derive from the floor normal: uphill is against its horizontal lean.
				var n := collision.get_normal()
				up_dir = -Vector3(n.x, 0.0, n.z)
			return up_dir
	# Walking DOWN a slope the floor snap keeps the capsule attached without a
	# slide collision, so also look straight under the feet.
	var from := global_position
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 1.35, 1)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var under := hit.get("collider") as Node
		if under != null and under.has_meta("stair_surface"):
			var dir: Vector3 = under.get_meta("stair_up_direction", Vector3.ZERO)
			if dir != Vector3.ZERO and under is Node3D:
				return ((under as Node3D).global_transform.basis * dir).normalized()
			var n: Vector3 = hit.get("normal", Vector3.UP)
			return -Vector3(n.x, 0.0, n.z)
	return Vector3.ZERO


func _update_stair_camera(delta: float, horizontal_speed: float) -> void:
	var up_dir := _stair_surface_up_direction()
	var target_offset := 0.0
	var target_pitch := 0.0
	var on_stairs := up_dir != Vector3.ZERO
	if on_stairs and horizontal_speed > 0.3:
		var up_flat := Vector2(up_dir.x, up_dir.z)
		if up_flat.length_squared() > 0.0001:
			up_flat = up_flat.normalized()
			var along := Vector2(velocity.x, velocity.z).dot(up_flat) / maxf(horizontal_speed, 0.001)
			var pace := clampf(horizontal_speed / maxf(walk_speed, 0.01), 0.0, 1.3)
			if along > 0.25:
				target_offset = stair_camera_lift_up * pace
				target_pitch = stair_camera_pitch_up_degrees
			elif along < -0.25:
				target_offset = -stair_camera_drop_down * pace
				target_pitch = stair_camera_pitch_down_degrees
			# One extra thud in the hands per tread, on top of the footsteps.
			stair_step_distance += horizontal_speed * delta * absf(along)
			if stair_step_distance >= stair_step_run:
				stair_step_distance = fmod(stair_step_distance, stair_step_run)
				if along > 0.25:
					footstep_weapon_drop = minf(footstep_weapon_drop + stair_step_thud_up, 0.012)
				elif along < -0.25:
					footstep_weapon_drop = minf(footstep_weapon_drop + stair_step_thud_down, 0.012)
	if not on_stairs:
		stair_step_distance = 0.0
		if not is_on_floor():
			# Left the stairs through the air (jump / step off): the layer is
			# gone this frame so it never mixes into the jump or landing camera.
			stair_camera_offset = 0.0
			stair_camera_offset_velocity = 0.0
			stair_camera_pitch_degrees = 0.0
			stair_camera_pitch_velocity = 0.0
			stair_contact_active = false
			return
	stair_contact_active = on_stairs
	# Leaving onto the landing / dining floor: targets drop to zero this frame
	# and a stiffer spring settles the last few millimetres without a pop.
	var stiffness := stair_camera_spring if on_stairs else stair_camera_spring * 3.2
	var damping := stair_camera_damping if on_stairs else stair_camera_damping * 1.8
	var steps: int = maxi(1, int(ceil(delta * 120.0)))
	var h: float = delta / float(steps)
	for _i in range(steps):
		stair_camera_offset_velocity += (-stiffness * (stair_camera_offset - target_offset) - damping * stair_camera_offset_velocity) * h
		stair_camera_offset += stair_camera_offset_velocity * h
		stair_camera_pitch_velocity += (-stiffness * (stair_camera_pitch_degrees - target_pitch) - damping * stair_camera_pitch_velocity) * h
		stair_camera_pitch_degrees += stair_camera_pitch_velocity * h
	stair_camera_offset = clampf(stair_camera_offset, -STAIR_CAMERA_MAX_OFFSET, STAIR_CAMERA_MAX_OFFSET)
	stair_camera_pitch_degrees = clampf(stair_camera_pitch_degrees, -STAIR_CAMERA_MAX_PITCH, STAIR_CAMERA_MAX_PITCH)
