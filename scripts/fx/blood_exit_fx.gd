class_name BloodExitFx
extends Node3D

## World-space blood leaving a bullet wound.
##
## Two GPUParticles3D layers, built in code:
##   * Spray  – a short, fast, almost gravity-free jet of dark venous mist
##              leaving the hole along the wound axis (the "shooting out").
##   * Drops  – slower, heavier droplets on the same cone that arc and fall
##              past the body under gravity (the "it's real liquid").
## plus a lethal-only extra drop burst and a tiny dark-red flash.
##
## Nodes live under a bucket on the current scene, never on the zombie, so a
## flinch or death animation cannot drag the blood like a sticker. A fixed
## pool is reused round-robin; a new hit restarts the oldest slot, so
## full-auto fire can never create unbounded particle systems.

const POOL_SIZE := 8
const BUCKET_NAME := "BloodFxBucket"

enum Kind { BODY, HEAD, PELLET }

# Particle budgets (amount_ratio of each emitter's max).
const SPRAY_MAX := 44
const DROPS_MAX := 20
const LETHAL_DROPS_MAX := 14
const SPRAY_BODY := 26
const SPRAY_PELLET := 13
const DROPS_BODY := 11
const DROPS_PELLET := 5
const HEADSHOT_COUNT_SCALE := 1.7

# Dark venous red, almost black in the core. Never candy / orange / pink.
const SPRAY_DARK := Color(0.22, 0.01, 0.02)
const SPRAY_LIGHT := Color(0.38, 0.03, 0.04)
const DROP_COLOR := Color(0.17, 0.008, 0.014)

static var _pool: Array = []
static var _stamp: int = 0
static var _disc: Texture2D = null

var _spray: GPUParticles3D
var _drops: GPUParticles3D
var _lethal_drops: GPUParticles3D
var _flash: OmniLight3D
var _flash_time := 0.0
var _last_used := 0


## Spawn (or recycle) one blood exit at `hit_position`, travelling along
## `outward` (already flipped to face the shooter by the caller).
static func spray(
	tree: SceneTree,
	hit_position: Vector3,
	outward: Vector3,
	kind: int = Kind.BODY,
	lethal: bool = false
) -> void:
	if tree == null or tree.current_scene == null:
		return
	var fx := _acquire(tree.current_scene)
	if fx != null:
		fx._play(hit_position, outward, kind, lethal)


static func _acquire(scene: Node) -> BloodExitFx:
	var bucket := scene.get_node_or_null(BUCKET_NAME) as Node3D
	if bucket == null:
		bucket = Node3D.new()
		bucket.name = BUCKET_NAME
		scene.add_child(bucket)
	# Rooms and scenes free their children; drop pool entries that died with them.
	var live: Array = []
	for entry in _pool:
		if is_instance_valid(entry) and (entry as Node).is_inside_tree():
			live.append(entry)
	_pool = live
	if _pool.size() < POOL_SIZE:
		var fresh := BloodExitFx.new()
		fresh.name = "BloodExit%d" % _pool.size()
		bucket.add_child(fresh)
		_pool.append(fresh)
		return fresh
	var oldest: BloodExitFx = _pool[0]
	for entry in _pool:
		if (entry as BloodExitFx)._last_used < oldest._last_used:
			oldest = entry
	return oldest


func _ready() -> void:
	top_level = true
	_spray = _make_spray()
	_drops = _make_drops(DROPS_MAX, 0.9)
	_lethal_drops = _make_drops(LETHAL_DROPS_MAX, 1.0)
	(_lethal_drops.process_material as ParticleProcessMaterial).spread = 48.0
	(_lethal_drops.process_material as ParticleProcessMaterial).initial_velocity_min = 1.2
	(_lethal_drops.process_material as ParticleProcessMaterial).initial_velocity_max = 3.2
	for emitter in [_spray, _drops, _lethal_drops]:
		add_child(emitter)
	_flash = OmniLight3D.new()
	_flash.light_color = Color(0.55, 0.02, 0.03)
	_flash.light_energy = 0.15
	_flash.omni_range = 0.6
	_flash.shadow_enabled = false
	_flash.visible = false
	add_child(_flash)
	set_process(false)


func _play(hit_position: Vector3, outward: Vector3, kind: int, lethal: bool) -> void:
	_stamp += 1
	_last_used = _stamp
	var axis := outward
	if axis.length_squared() < 0.0001:
		axis = Vector3.UP
	axis = axis.normalized()
	var speed_scale := 1.0
	if kind == Kind.HEAD:
		# Headshots jet slightly higher and further forward.
		axis = (axis + Vector3.UP * 0.28).normalized()
		speed_scale = 1.15
	elif kind == Kind.PELLET:
		speed_scale = 0.85
	# Emitters shoot along local +Y; build a basis whose Y is the wound axis.
	var side := axis.cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = axis.cross(Vector3.RIGHT)
	side = side.normalized().rotated(axis, randf() * TAU)
	var forward := side.cross(axis).normalized()
	global_transform = Transform3D(Basis(side, axis, forward), hit_position + axis * 0.015)

	var count_scale := HEADSHOT_COUNT_SCALE if kind == Kind.HEAD else 1.0
	var spray_count := float(SPRAY_PELLET if kind == Kind.PELLET else SPRAY_BODY) * count_scale
	var drop_count := float(DROPS_PELLET if kind == Kind.PELLET else DROPS_BODY) * count_scale
	_fire(_spray, spray_count / SPRAY_MAX, speed_scale)
	_fire(_drops, drop_count / DROPS_MAX, speed_scale)
	if lethal:
		_fire(_lethal_drops, 1.0, 1.0)
	else:
		_lethal_drops.emitting = false

	_flash.light_energy = 0.15 * (1.4 if kind == Kind.HEAD else 1.0)
	_flash.visible = true
	_flash_time = 0.08
	set_process(true)


func _fire(emitter: GPUParticles3D, ratio: float, speed_scale: float) -> void:
	emitter.amount_ratio = clampf(ratio, 0.05, 1.0)
	emitter.speed_scale = speed_scale
	emitter.restart()
	emitter.emitting = true


func _process(delta: float) -> void:
	_flash_time -= delta
	if _flash_time <= 0.0:
		_flash.visible = false
		set_process(false)
		return
	_flash.light_energy = 0.15 * clampf(_flash_time / 0.08, 0.0, 1.0)


# ------------------------------------------------------------------ builders

func _make_spray() -> GPUParticles3D:
	var emitter := _base_emitter(SPRAY_MAX, 0.2)
	emitter.explosiveness = 0.72  # a jet over the first 2–3 frames, not one pop
	emitter.lifetime = 0.2
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 22.0
	process.initial_velocity_min = 4.0
	process.initial_velocity_max = 9.0
	process.gravity = Vector3(0.0, -1.2, 0.0)
	process.damping_min = 7.0
	process.damping_max = 12.0
	process.scale_min = 0.7
	process.scale_max = 1.25
	process.lifetime_randomness = 0.45  # 0.11–0.20 s
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.012
	process.color_initial_ramp = _gradient([[0.0, SPRAY_DARK], [1.0, SPRAY_LIGHT]])
	process.color_ramp = _gradient([
		[0.0, Color(1, 1, 1, 0.85)],
		[0.66, Color(0.9, 0.9, 0.9, 0.85)],
		[1.0, Color(0.8, 0.8, 0.8, 0.0)],
	])
	process.scale_curve = _curve([[0.0, 0.8], [0.25, 1.0], [1.0, 1.35]])
	emitter.process_material = process
	# Slightly stretched quads, billboarded and aligned to their velocity.
	emitter.draw_pass_1 = _quad(Vector2(0.017, 0.058), 0.85)
	return emitter


func _make_drops(max_amount: int, explosiveness: float) -> GPUParticles3D:
	var emitter := _base_emitter(max_amount, 0.7)
	emitter.explosiveness = explosiveness
	emitter.lifetime = 0.7
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 32.0
	process.initial_velocity_min = 1.8
	process.initial_velocity_max = 4.4
	process.gravity = Vector3(0.0, -14.0, 0.0)
	process.damping_min = 0.4
	process.damping_max = 1.2
	process.scale_min = 0.75
	process.scale_max = 1.3
	process.lifetime_randomness = 0.5  # 0.35–0.70 s
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.02
	process.color = DROP_COLOR
	process.color_ramp = _gradient([
		[0.0, Color(1, 1, 1, 0.95)],
		[0.75, Color(1, 1, 1, 0.9)],
		[1.0, Color(1, 1, 1, 0.0)],
	])
	# Drops shrink as they die.
	process.scale_curve = _curve([[0.0, 1.0], [0.6, 0.75], [1.0, 0.25]])
	emitter.process_material = process
	emitter.draw_pass_1 = _quad(Vector2(0.022, 0.034), 1.0)
	return emitter


func _base_emitter(max_amount: int, lifetime: float) -> GPUParticles3D:
	var emitter := GPUParticles3D.new()
	emitter.amount = max_amount
	emitter.lifetime = lifetime
	emitter.one_shot = true
	emitter.emitting = false
	emitter.local_coords = false  # particles stay in the world once emitted
	emitter.fixed_fps = 0
	# No interpolation: pooled emitters jump between wounds and must not smear
	# their first particles along the path from the previous hit.
	emitter.interpolate = false
	emitter.transform_align = GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY
	emitter.visibility_aabb = AABB(Vector3(-1.8, -3.0, -1.8), Vector3(3.6, 4.8, 3.6))
	emitter.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	emitter.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	return emitter


func _quad(size: Vector2, alpha_scale: float) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = size
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = _disc_texture()
	material.albedo_color = Color(1, 1, 1, alpha_scale)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = true
	material.no_depth_test = false
	quad.material = material
	return quad


## Soft round particle: darker core, soft alpha edge. Generated once.
static func _disc_texture() -> Texture2D:
	if _disc != null:
		return _disc
	var size := 48
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := (size - 1) * 0.5
	for y in size:
		for x in size:
			var r := Vector2(x - center, y - center).length() / center
			var alpha := clampf(1.0 - smoothstep(0.55, 1.0, r), 0.0, 1.0)
			var shade := lerpf(0.55, 1.0, smoothstep(0.0, 0.9, r))
			image.set_pixel(x, y, Color(shade, shade, shade, alpha))
	_disc = ImageTexture.create_from_image(image)
	return _disc


static func _gradient(stops: Array) -> GradientTexture1D:
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for stop in stops:
		offsets.append(float(stop[0]))
		colors.append(stop[1])
	var gradient := Gradient.new()
	gradient.offsets = offsets
	gradient.colors = colors
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


static func _curve(points: Array) -> CurveTexture:
	var curve := Curve.new()
	for point in points:
		curve.add_point(Vector2(float(point[0]), float(point[1])))
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture
