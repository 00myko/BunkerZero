extends Node

## Catalog renders of the in-game gun models: arms hidden, side profile,
## orthographic, studio lights, transparent background.
const OUT := "user://gun_renders/"
const GUNS := {
	"minigun": "res://assets/Weapons/minigun_animated.glb",
	"pistol": "res://assets/Weapons/animated_pistol_complete.glb",
	"uzi": "res://assets/Weapons/Uzi  14 Animations.glb",
	"smg": "res://assets/Weapons/fps_animated_smg.glb",
	"shotgun": "res://assets/Weapons/shotgun_animated.glb",
	"sawnoff": "res://assets/Weapons/sawnoff_animated.glb",
	"lmg": "res://assets/Weapons/lmg_animated.glb",
	"grenade_launcher": "res://assets/Weapons/grenadelauncher_animated.glb",
	"sawnoffs": "res://assets/Weapons/sawnoffs_animated.glb",
	"crossbow": "res://assets/Weapons/crossbow_animated.glb",
	"knife": "res://assets/Weapons/knife_animated.glb",
}
var only: PackedStringArray = []
var side := {}   # id -> +1 / -1 camera side
## Loose parts that float away from the gun at rest (ejected casings).
const HIDE := {"pistol": ["shell_1"]}
## Seconds into the model's animation clip to pose it (idle/loaded frame).
const POSE := {"minigun": 0.25, "crossbow": 3.30}

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	get_viewport().transparent_bg = true
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("only="):
			only = a.substr(5).split(",")
		elif a.begins_with("side="):
			for kv in a.substr(5).split(","):
				var p := kv.split(":")
				side[p[0]] = float(p[1])
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _run() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.62, 0.64, 0.68)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.25
	env.environment = e
	add_child(env)
	for id in GUNS:
		if not only.is_empty() and not only.has(id):
			continue
		await _render(id)
	get_tree().quit()

func _render(id: String) -> void:
	var root := Node3D.new()
	add_child(root)
	var model: Node3D = (load(GUNS[id]) as PackedScene).instantiate()
	root.add_child(model)
	for ap in model.find_children("*", "AnimationPlayer", true, false):
		var player := ap as AnimationPlayer
		player.stop()
		if POSE.has(id) and not player.get_animation_list().is_empty():
			player.play(player.get_animation_list()[0])
			player.seek(float(POSE[id]), true)
			player.pause()
	await _frames(2)
	var box := AABB()
	var first := true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var is_arms := false
		for s in m.mesh.get_surface_count():
			var mat := m.get_active_material(s)
			var n := String(mat.resource_name).to_lower() if mat else ""
			if n.contains("arm") or n == "material" and m.skin != null:
				is_arms = true
		if m.name.to_lower().contains("character"):
			is_arms = true
		for part in HIDE.get(id, []):
			if String(model.get_path_to(m)).contains("/%s/" % part):
				is_arms = true
		if is_arms:
			m.visible = false
			continue
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var g := m.global_transform * m.get_aabb()
		box = g if first else box.merge(g)
		first = false
	# Long axis of the gun = barrel axis; look at it from the side.
	var ax := 0
	if box.size.y > box.size[ax]: ax = 1
	if box.size.z > box.size[ax]: ax = 2
	var along := Vector3.ZERO; along[ax] = 1.0
	var up := Vector3.UP if ax != 1 else Vector3.BACK
	var look := along.cross(up).normalized() * float(side.get(id, 1.0))
	var center := box.get_center()
	var extent := box.size.length()
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var vert := absf(box.size.dot(up.abs()))
	cam.size = maxf(vert * 1.15, box.size[ax] * 1.1 * 0.5)
	cam.near = 0.01
	cam.far = extent * 4.0
	add_child(cam)
	cam.global_position = center + look * extent * 1.5
	cam.look_at(center, up)
	cam.current = true
	# Studio lights relative to the camera: key upper-left front, fill, rim.
	var lights: Array[DirectionalLight3D] = []
	for spec in [[Vector3(-0.5, 0.8, 1.0), 2.1, Color(1.0, 0.97, 0.93)],
			[Vector3(0.9, 0.1, 0.8), 0.7, Color(0.85, 0.9, 1.0)],
			[Vector3(0.2, 0.6, -1.0), 1.4, Color(1, 1, 1)]]:
		var l := DirectionalLight3D.new()
		add_child(l)
		var dir: Vector3 = cam.global_transform.basis * (spec[0] as Vector3).normalized()
		l.look_at_from_position(center + dir * extent, center, up if absf(dir.normalized().dot(up)) < 0.99 else Vector3.RIGHT)
		l.light_energy = spec[1]
		l.light_color = spec[2]
		lights.append(l)
	await _frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + id + ".png")
	print("RENDERED ", id, " axis=", ax, " box=", box.size)
	for l in lights: l.queue_free()
	cam.queue_free()
	root.queue_free()
	await _frames(2)
