extends Node

## DEV-ONLY playthrough + screenshot harness (safe to delete, not used by the game).
## Open tools/capture/capture_harness.tscn and press "Run Current Scene".
## It loads main.tscn, walks hub -> Room 1 -> Cafeteria -> Room 3 through the real
## door streaming, freezes zombies, and writes PNGs + report.txt to res://_captures/<tag>/.
## Tag comes from res://_captures/tag.txt (first line), default "shot".

const OUT_ROOT := "res://_captures"
const VIEWMODEL_LAYER := 1 << 19

var is_driver := false
var tag := "shot"
var out_dir := ""
var report: PackedStringArray = []
var cam: Camera3D
var scene: Node
var player: CharacterBody3D
var freeze_zombies := true
var zombie_peak := {}


func _ready() -> void:
	if is_driver:
		call_deferred("_run")
		return
	var driver := Node.new()
	driver.name = "CaptureDriver"
	driver.set_script(get_script())
	driver.set("is_driver", true)
	get_tree().root.call_deferred("add_child", driver)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main.tscn")


func _log(line: String) -> void:
	print("[CAPTURE] ", line)
	report.append(line)
	if out_dir != "":
		var f := FileAccess.open(out_dir + "/report.txt", FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(report))
		else:
			print("[CAPTURE] cannot write report: ", FileAccess.get_open_error(), " ", out_dir)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _process(_delta: float) -> void:
	if not is_driver or scene == null or not is_instance_valid(scene):
		return
	for container in scene.find_children("EncounterZombies", "", true, false):
		var room_name := String(container.get_parent().name)
		var alive := 0
		for z in container.get_children():
			alive += 1
			if freeze_zombies and z.process_mode != Node.PROCESS_MODE_DISABLED:
				z.process_mode = Node.PROCESS_MODE_DISABLED
		zombie_peak[room_name] = maxi(int(zombie_peak.get(room_name, 0)), alive)


func _run() -> void:
	var tag_path := ProjectSettings.globalize_path(OUT_ROOT + "/tag.txt")
	if FileAccess.file_exists(tag_path):
		var f := FileAccess.open(tag_path, FileAccess.READ)
		tag = f.get_line().strip_edges()
	out_dir = ProjectSettings.globalize_path("%s/%s" % [OUT_ROOT, tag])
	var mk := DirAccess.make_dir_recursive_absolute(out_dir)
	print("[CAPTURE] out_dir=", out_dir, " mkdir=", mk)
	for _i in range(20):
		await get_tree().process_frame
	scene = get_tree().current_scene
	while scene == null or String(scene.name) != "ZombieSurvival":
		await get_tree().process_frame
		scene = get_tree().current_scene
	await _wait(2.0)
	player = scene.get_node_or_null("Player") as CharacterBody3D
	var hud := scene.get_node_or_null("HUD")
	if hud != null and "visible" in hud:
		hud.set("visible", false)
	cam = Camera3D.new()
	cam.name = "CaptureCam"
	cam.fov = 72.0
	cam.near = 0.05
	cam.cull_mask = cam.cull_mask & ~VIEWMODEL_LAYER
	add_child(cam)
	_log("tag=%s engine=%s" % [tag, Engine.get_version_info().string])
	for scene_path in ["res://scenes/Room 1 Infested Living Quarters.tscn", "res://scenes/Cafeteria.tscn", "res://scenes/Room 3.tscn"]:
		var packed := load(scene_path) as PackedScene
		var inst: Node = packed.instantiate() if packed != null else null
		_log("preflight %s loaded=%s instantiated=%s" % [scene_path.get_file(), packed != null, inst != null])
		if inst != null:
			inst.free()
	_copy_log()

	# ---------------- HUB -> ROOM 1 ----------------
	var door1 := scene.get_node_or_null("Room1DoorTransition")
	await _teleport(Vector3(0.0, 1.0, -2.6))
	await _wait_ready(door1, "Room1 door")
	await _open(door1, "Room1 door")
	await _walk_through(Vector3(0.0, 1.0, -3.2), Vector3(0.0, 1.0, -8.0))
	await _wait(3.0)
	var room1 := _find_room("Room 1 Infested Living Quarters")
	if room1 == null:
		_log("ABORT: room1 missing")
		_copy_log()
		get_tree().quit()
		return
	_log("room1 present=%s  hub unloaded=%s" % [room1 != null, scene.find_child("SafeHubRoot", true, false) == null])
	await _wait(2.5)
	_room_stats(room1, "ROOM1")
	await _seam_floor_check(room1, Vector3(0.0, 0.0, -4.6), Vector3(0, 0, -1), "hub->room1")
	await _shot(room1, "r1_entry", Vector3(0.0, 1.65, -5.6), Vector3(0.0, 1.3, -15.0))
	await _shot(room1, "r1_left_aisle", Vector3(-4.8, 1.65, -8.0), Vector3(-2.0, 1.1, -21.0))
	await _shot(room1, "r1_right_aisle", Vector3(4.4, 1.65, -8.4), Vector3(3.0, 1.1, -21.0))
	await _shot(room1, "r1_far_back", Vector3(3.2, 1.65, -21.0), Vector3(-2.5, 1.3, -8.0))
	await _shot(room1, "r1_south_door", Vector3(-1.5, 1.65, -16.5), Vector3(0.0, 1.4, -22.3))
	await _shot(room1, "r1_overview", Vector3(0.0, 4.6, -5.0), Vector3(0.0, 0.2, -16.5))

	# ---------------- ROOM 1 -> CAFETERIA ----------------
	scene.set_meta("combat_room_1_cleared", true)
	RunManager.mark_combat_room_cleared(1)
	var door2 := room1.get_node_or_null("CafeteriaDoorTransition") if room1 != null else null
	await _teleport(room1.to_global(Vector3(0.0, 1.0, -20.4)))
	await _wait_ready(door2, "Cafeteria door")
	await _open(door2, "Cafeteria door")
	await _walk_through(room1.to_global(Vector3(0.0, 1.0, -21.2)), room1.to_global(Vector3(0.0, 1.0, -26.5)))
	await _wait(3.5)
	var caf := _find_room("Cafeteria")
	_log("cafeteria present=%s  room1 unloaded=%s" % [caf != null, not is_instance_valid(room1)])
	await _wait(2.0)
	_room_stats(caf, "CAFETERIA")
	if caf != null:
		await _seam_floor_check(caf, Vector3(2.13, -3.17, -4.21), Vector3(0, 0, 1), "room1->cafeteria")
		await _seam_floor_check(caf, Vector3(2.13, -3.17, 15.40), Vector3(0, 0, 1), "cafeteria->room3 (pre)")
		var fy := -1.55
		await _shot(caf, "c_entry", Vector3(2.13, fy, -2.4), Vector3(3.5, -2.3, 10.0))
		await _shot(caf, "c_tables", Vector3(-5.2, fy, -1.0), Vector3(5.0, -2.6, 12.5))
		await _shot(caf, "c_kitchen", Vector3(12.8, fy, -2.4), Vector3(10.0, -2.3, 12.0))
		await _shot(caf, "c_serving_line", Vector3(4.6, fy, 8.8), Vector3(12.5, -2.0, 8.8))
		await _shot(caf, "c_exit", Vector3(0.5, fy, 9.0), Vector3(2.13, -1.8, 15.4))
		await _shot(caf, "c_overview", Vector3(-5.5, 0.9, -3.4), Vector3(8.0, -3.1, 11.0))

	# ---------------- CAFETERIA -> ROOM 3 ----------------
	scene.set_meta("combat_room_2_cleared", true)
	RunManager.mark_combat_room_cleared(2)
	var door3 := caf.get_node_or_null("Room3DoorTransition") if caf != null else null
	await _teleport(caf.to_global(Vector3(1.2, -2.1, 13.9)))
	await _wait_ready(door3, "Room3 door")
	await _open(door3, "Room3 door")
	await _walk_through(caf.to_global(Vector3(2.13, -2.1, 14.4)), caf.to_global(Vector3(2.13, -2.1, 19.6)))
	await _wait(3.5)
	var r3 := _find_room("Room 3")
	_log("room3 present=%s  cafeteria unloaded=%s" % [r3 != null, not is_instance_valid(caf)])
	await _wait(2.0)
	_room_stats(r3, "ROOM3")
	if r3 != null:
		await _seam_floor_check(r3, Vector3(0.0, -3.17, -0.02), Vector3(0, 0, 1), "cafeteria->room3")
		await _seam_floor_check(r3, Vector3(0.0, -3.17, 16.22), Vector3(0, 0, 1), "room3->room4 (pre)")
		var ry := -1.55
		await _shot(r3, "r3_entry", Vector3(0.0, ry, 1.4), Vector3(0.0, -2.1, 14.0))
		await _shot(r3, "r3_diag", Vector3(-7.2, ry, 1.2), Vector3(5.0, -2.6, 14.0))
		await _shot(r3, "r3_far", Vector3(6.8, ry, 15.2), Vector3(-4.0, -2.6, 3.0))
		await _shot(r3, "r3_cross", Vector3(-7.0, ry, 8.0), Vector3(7.0, -2.4, 8.0))
		await _shot(r3, "r3_lookback", Vector3(0.0, ry, 5.0), Vector3(0.0, -1.8, -0.02))
		await _shot(r3, "r3_overview", Vector3(-7.6, 0.2, 0.6), Vector3(5.0, -3.1, 14.0))
		# Door to Room 4 must stay reachable: check the passage is not blocked by art.
		_passage_check(r3, Vector3(0.0, 0.0, 16.22), "room3 north door")
		_passage_check(r3, Vector3(0.0, 0.0, -0.02), "room3 south door")
	_log("zombie peaks: %s" % str(zombie_peak))
	_write_report()
	await _wait(0.5)
	get_tree().quit()


func _find_room(room_name: String) -> Node3D:
	for child in scene.get_children():
		if String(child.name) == room_name:
			return child as Node3D
	return scene.find_child(room_name, false, false) as Node3D


func _teleport(pos: Vector3) -> void:
	if player == null:
		return
	player.global_position = pos
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame


func _walk_through(from: Vector3, to: Vector3) -> void:
	var steps := 24
	for i in range(steps + 1):
		var p := from.lerp(to, float(i) / float(steps))
		p.y = player.global_position.y if i > 0 else from.y
		player.global_position = Vector3(p.x, player.global_position.y, p.z)
		player.velocity = Vector3.ZERO
		await get_tree().physics_frame
		await get_tree().physics_frame
	_log("walked to %s (player y=%.2f)" % [str(player.global_position), player.global_position.y])


func _wait_ready(door: Node, label: String) -> void:
	if door == null:
		_log("ERROR: %s missing" % label)
		return
	var t := 0.0
	while t < 20.0 and not bool(door.call("is_destination_ready")):
		await _wait(0.25)
		t += 0.25
	_log("%s ready=%s after %.1fs" % [label, str(door.call("is_destination_ready")), t])


func _open(door: Node, label: String) -> void:
	if door == null:
		return
	var ok := bool(door.call("request_open_from_hud"))
	_log("%s access=%s paused=%s player=%s" % [label, str(door.call("is_access_granted")), str(get_tree().paused), str(player.global_position)])
	var t := 0.0
	while t < 6.0 and not bool(door.call("is_door_unlocked")):
		await _wait(0.2)
		t += 0.2
	_log("%s open requested=%s unlocked=%s" % [label, str(ok), str(door.call("is_door_unlocked"))])


func _room_stats(room: Node3D, label: String) -> void:
	if room == null:
		_log("%s: MISSING" % label)
		return
	var omni := 0
	var spot := 0
	var area := 0
	var dir := 0
	var shadowed := 0
	for l in room.find_children("*", "Light3D", true, false):
		if l is OmniLight3D:
			omni += 1
		elif l is SpotLight3D:
			spot += 1
		elif l is DirectionalLight3D:
			dir += 1
		else:
			area += 1
		if (l as Light3D).shadow_enabled:
			shadowed += 1
	var zc := 0
	var cont := room.get_node_or_null("EncounterZombies")
	if cont != null:
		zc = cont.get_child_count()
	var active_dirs := 0
	for l in scene.find_children("*", "DirectionalLight3D", true, false):
		var dl := l as DirectionalLight3D
		if dl.is_visible_in_tree() and (dl.light_cull_mask & 1) != 0:
			active_dirs += 1
	var we := scene.find_children("*", "WorldEnvironment", true, false)
	var env_desc := ""
	var vp_env := get_viewport().world_3d.environment
	if vp_env != null:
		env_desc = "ambient=%.2f fog=%.4f" % [vp_env.ambient_light_energy, vp_env.fog_density]
	_log("%s lights omni=%d spot=%d area=%d dir=%d shadowed=%d | zombies now=%d | active world dir lights=%d | WorldEnvs=%d viewport env %s" % [label, omni, spot, area, dir, shadowed, zc, active_dirs, we.size(), env_desc])
	var ctrl_hp = ""
	if cont != null and cont.get_child_count() > 0:
		var z := cont.get_child(0)
		ctrl_hp = "first zombie max_health=%s damage=%s move=%s" % [str(z.get("max_health")), str(z.get("attack_damage")), str(z.get("move_speed"))]
		_log("%s %s" % [label, ctrl_hp])


func _seam_floor_check(room: Node3D, local_door: Vector3, local_forward: Vector3, label: String) -> void:
	await get_tree().physics_frame
	var space := room.get_world_3d().direct_space_state
	var door_world := room.to_global(local_door)
	var fwd := (room.global_transform.basis * local_forward).normalized()
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var misses := 0
	var ys: Array[float] = []
	for d in range(-8, 9):
		for s in [-0.9, 0.0, 0.9]:
			var origin := door_world + fwd * (float(d) * 0.4) + right * float(s) + Vector3.UP * 2.6
			var q := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * 5.5, 1)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				misses += 1
				if misses <= 4:
					_log("   miss at %s" % str(origin))
			else:
				ys.append(float(hit.position.y))
	var lo := 1e9
	var hi := -1e9
	for y in ys:
		lo = minf(lo, y)
		hi = maxf(hi, y)
	_log("SEAM %s: %d/%d rays hit floor, misses=%d, floor y range %.3f..%.3f (step %.3f)" % [label, ys.size(), ys.size() + misses, misses, lo, hi, hi - lo])


func _passage_check(room: Node3D, local_door: Vector3, label: String) -> void:
	var space := room.get_world_3d().direct_space_state
	var ctrl_floor := float(room.get_meta("room_walk_floor_y", room.to_global(Vector3(0, -3.17, 0)).y))
	for dz in [-1.4, 1.4]:
		var p := room.to_global(Vector3(local_door.x, 0.0, local_door.z + dz))
		p.y = ctrl_floor + 1.0
		var cap := CapsuleShape3D.new()
		cap.radius = 0.36
		cap.height = 1.6
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = cap
		q.transform = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.1)
		q.collision_mask = 1
		var hits := space.intersect_shape(q, 8)
		var names: PackedStringArray = []
		for h in hits:
			var c := h.get("collider") as Node
			if c != null and c != player:
				names.append(str(c.get_path()).get_file() + "<" + String(c.get_parent().name))
		_log("PASSAGE %s dz=%.1f blockers=%s" % [label, dz, ",".join(names)])


func _shot(room: Node3D, shot_name: String, local_pos: Vector3, local_target: Vector3) -> void:
	if room == null:
		return
	var p := room.to_global(local_pos)
	var t := room.to_global(local_target)
	cam.global_position = p
	cam.look_at(t, Vector3.UP)
	cam.current = true
	await _wait(0.9)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [out_dir, shot_name]
	img.save_png(path)
	_log("shot %s" % shot_name)
	var pcam := player.get_node_or_null("CameraPivot/JumpOffset/Camera3D") as Camera3D
	if pcam != null:
		pcam.current = true


func _copy_log() -> void:
	var src := FileAccess.open("user://logs/godot.log", FileAccess.READ)
	if src == null:
		_log("no user log available")
		return
	var dst := FileAccess.open(out_dir + "/godot_log.txt", FileAccess.WRITE)
	if dst != null:
		dst.store_string(src.get_as_text())


func _write_report() -> void:
	_copy_log()
	var f := FileAccess.open(out_dir + "/report.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(report))
