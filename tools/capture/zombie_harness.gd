extends Node

## DEV-ONLY zombie behaviour harness (safe to delete). Run
## tools/capture/zombie_harness.tscn with "Run Current Scene". It walks the real
## doors hub -> Room 1 -> Cafeteria -> Room 3, keeps the player alive, lets the
## hordes chase, samples surround / stacking / moonwalk / attack metrics, then
## kills zombies one by one to check waves, lifetimes and room-clear timing.
## Output: res://_captures/zombies/report.txt (+ a few PNGs).

const OUT := "res://_captures/zombies"

var is_driver := false
var out_dir := ""
var report: PackedStringArray = []
var scene: Node
var player: CharacterBody3D
var cam: Camera3D
var hold_health := true
var hits_taken := 0
var last_health := 0.0


func _ready() -> void:
	if is_driver:
		process_mode = Node.PROCESS_MODE_ALWAYS
		call_deferred("_run")
		return
	var driver := Node.new()
	driver.name = "ZombieHarnessDriver"
	driver.set_script(get_script())
	driver.set("is_driver", true)
	get_tree().root.call_deferred("add_child", driver)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main.tscn")


func _log(line: String) -> void:
	print("[ZH] ", line)
	report.append(line)
	if out_dir != "":
		var f := FileAccess.open(out_dir + "/report.txt", FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(report))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _process(_delta: float) -> void:
	if not is_driver or player == null or not is_instance_valid(player):
		return
	# Weapon-choice popups after a clear pause the tree; take the refill.
	if bool(player.get("weapon_choice_active")):
		var current := String(player.get("current_weapon_id"))
		player.call("_on_weapon_chosen", current if current != "" else "pistol")
		_log("   (dismissed weapon choice popup)")
	if get_tree().paused:
		get_tree().paused = false


func _physics_process(_delta: float) -> void:
	if not is_driver or player == null or not is_instance_valid(player):
		return
	var h: Variant = player.get("health")
	if h != null:
		if float(h) < last_health - 0.01:
			hits_taken += 1
		if hold_health:
			var mh: Variant = player.get("max_health")
			player.set("health", float(mh) if mh != null else 100.0)
		last_health = float(player.get("health"))


func _run() -> void:
	out_dir = ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(out_dir)
	for _i in range(20):
		await get_tree().process_frame
	scene = get_tree().current_scene
	while scene == null or String(scene.name) != "ZombieSurvival":
		await get_tree().process_frame
		scene = get_tree().current_scene
	await _wait(2.0)
	player = scene.get_node_or_null("Player") as CharacterBody3D
	last_health = float(player.get("health"))
	var hud := scene.get_node_or_null("HUD")
	if hud != null and "visible" in hud:
		hud.set("visible", false)
	cam = Camera3D.new()
	cam.fov = 72.0
	cam.cull_mask = cam.cull_mask & ~(1 << 19)
	add_child(cam)

	# ---------------- Room 1
	var door1 := scene.get_node_or_null("Room1DoorTransition")
	await _teleport(Vector3(0.0, 1.0, -2.6))
	await _wait_ready(door1)
	door1.call("request_open_from_hud")
	await _wait(1.5)
	await _walk(Vector3(0.0, 1.0, -3.2), Vector3(0.0, 1.0, -7.2))
	var room1 := _find_room("Room 1 Infested Living Quarters")
	await _wait(2.5)
	_log("ROOM1 spawned=%d (want 12) alerted_before_step_in=%d" % [_count(room1, "alive"), _count(room1, "encounter_alerted")])
	# Step past the authored alert buffer (z -8.85) and hold position.
	await _walk(Vector3(0.0, 1.0, -7.2), Vector3(0.0, 1.0, -9.4))
	await _observe(room1, "ROOM1", 14.0, "r1")
	await _clear_room(room1, "ROOM1", 1)

	# ---------------- Cafeteria
	var door2 := room1.get_node_or_null("CafeteriaDoorTransition")
	await _teleport(room1.to_global(Vector3(0.0, 1.0, -20.4)))
	await _wait_ready(door2)
	door2.call("request_open_from_hud")
	await _wait(1.5)
	await _walk(room1.to_global(Vector3(0.0, 1.0, -21.2)), room1.to_global(Vector3(0.0, 1.0, -25.5)))
	await _wait(3.0)
	var caf := _find_room("Cafeteria")
	_log("CAF spawned=%d (want 10) room1_unloaded=%s" % [_count(caf, "alive"), str(not is_instance_valid(room1))])
	_log("CAF stats %s" % _stats(caf))
	await _observe(caf, "CAF", 12.0, "c")
	await _clear_room(caf, "CAF", 2)

	# ---------------- Room 3
	var door3 := caf.get_node_or_null("Room3DoorTransition")
	await _teleport(caf.to_global(Vector3(1.2, -2.1, 13.9)))
	await _wait_ready(door3)
	door3.call("request_open_from_hud")
	await _wait(1.5)
	await _walk(caf.to_global(Vector3(2.13, -2.1, 14.4)), caf.to_global(Vector3(2.13, -2.1, 19.0)))
	var r3 := _find_room("Room 3")
	await _wait(0.5)
	_log("R3 at door: spawned=%d alerted=%d (want a beat before waking)" % [_count(r3, "alive"), _count(r3, "encounter_alerted")])
	await _wait(2.5)
	_log("R3 after 3s: spawned=%d (want 5) alerted=%d stats %s" % [_count(r3, "alive"), _count(r3, "encounter_alerted"), _stats(r3)])
	# Walk to the middle and backpedal to test that the ring follows.
	await _walk(r3.to_global(Vector3(0.0, -2.1, 2.5)), r3.to_global(Vector3(0.0, -2.1, 6.0)))
	await _observe(r3, "R3", 10.0, "r3")
	await _backpedal(r3, "R3")
	await _clear_room(r3, "R3", 3)
	_log("hits taken total=%d" % hits_taken)
	_log("DONE")
	await _wait(0.5)
	get_tree().quit()


func _stats(room: Node) -> String:
	var c := room.get_node_or_null("EncounterZombies")
	if c == null or c.get_child_count() == 0:
		return "n/a"
	var z := c.get_child(0)
	return "hp=%s dmg=%s move=%.2f atk_scale=%s aggression=%.2f tokens=%s hold_r=%.2f" % [
		str(z.get("max_health")), str(z.get("attack_damage")), float(z.get("move_speed")),
		str(z.get("attack_speed_scale")), float(z.get("aggression")), str(z.get("max_attack_tokens")), float(z.get("hold_radius"))]


func _zombies(room: Node) -> Array:
	var out: Array = []
	if room == null or not is_instance_valid(room):
		return out
	var c := room.get_node_or_null("EncounterZombies")
	if c == null:
		return out
	for z in c.get_children():
		if is_instance_valid(z) and bool(z.get("alive")):
			out.append(z)
	return out


func _count(room: Node, flag: String) -> int:
	var n := 0
	for z in _zombies(room):
		if bool(z.get(flag)):
			n += 1
	return n


func _observe(room: Node, label: String, seconds: float, shot_prefix: String) -> void:
	var t := 0.0
	var samples := 0
	var moonwalk := 0
	var moving := 0
	var min_pair := 99.0
	var stack_events := 0
	var attacks_seen := {}
	var states := {}
	var anim_empty := 0
	var max_dist_to_player := 0.0
	var shot_taken := false
	var positions_prev := {}
	var frozen := 0
	while t < seconds:
		await _wait(0.25)
		t += 0.25
		var zs := _zombies(room)
		for z in zs:
			var v: Vector3 = z.velocity
			v.y = 0.0
			var sp := v.length()
			if sp > 0.45:
				moving += 1
				var fwd: Vector3 = -z.global_transform.basis.z
				fwd.y = 0.0
				if fwd.normalized().dot(v.normalized()) < cos(deg_to_rad(50.0)):
					moonwalk += 1
			var st := int(z.get("state"))
			states[st] = int(states.get(st, 0)) + 1
			if st == 2:
				attacks_seen[z.get_instance_id()] = true
			var ap: AnimationPlayer = z.get("anim")
			if ap == null or ap.current_animation == "":
				anim_empty += 1
			samples += 1
		for i in range(zs.size()):
			for j in range(i + 1, zs.size()):
				var a: Vector3 = zs[i].global_position
				var b: Vector3 = zs[j].global_position
				var d := Vector2(a.x - b.x, a.z - b.z).length()
				min_pair = minf(min_pair, d)
				if d < 0.45:
					stack_events += 1
		if not shot_taken and t >= seconds * 0.6:
			shot_taken = true
			await _shot_overhead(room, "%s_surround" % shot_prefix)
			await _shot_player_view("%s_pov" % shot_prefix)
	# ring spread around the player
	var zs2 := _zombies(room)
	var bearings: Array[float] = []
	var near := 0
	var tokens := 0
	for z in zs2:
		var d: Vector3 = z.global_position - player.global_position
		d.y = 0.0
		if d.length() < 3.6:
			near += 1
			bearings.append(atan2(d.z, d.x))
		if bool(z.get("has_attack_token")):
			tokens += 1
	bearings.sort()
	var max_gap := 0.0
	for i in range(bearings.size()):
		var nxt: float = bearings[(i + 1) % bearings.size()] + (TAU if i == bearings.size() - 1 else 0.0)
		max_gap = maxf(max_gap, nxt - bearings[i])
	_log("%s observe %.0fs: alive=%d alerted=%d near(<3.6m)=%d tokens=%d largest_ring_gap=%.0fdeg min_pair_dist=%.2f stack_events=%d moving_samples=%d moonwalk=%d (%.1f%%) anim_empty=%d attackers=%d states=%s player_hits=%d" % [
		label, seconds, zs2.size(), _count(room, "encounter_alerted"), near, tokens,
		rad_to_deg(max_gap) if bearings.size() > 1 else 360.0, min_pair, stack_events, moving, moonwalk,
		100.0 * float(moonwalk) / maxf(float(moving), 1.0), anim_empty, attacks_seen.size(), str(states), hits_taken])


func _backpedal(room: Node, label: String) -> void:
	var start := player.global_position
	var dir: Vector3 = -(room.global_transform.basis.z).normalized()
	dir.y = 0.0
	var t := 0.0
	while t < 4.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		player.global_position = start + dir * (1.3 * t)
		player.velocity = Vector3.ZERO
	var close := 0
	for z in _zombies(room):
		if (z.global_position - player.global_position).length() < 3.5:
			close += 1
	_log("%s backpedal 5.2m: zombies within 3.5m afterwards=%d / %d" % [label, close, _zombies(room).size()])


func _clear_room(room: Node, label: String, room_number: int) -> void:
	var kills := 0
	var max_alive := 0
	var cleared_early := false
	var guard := 0
	var ctrl_lifetime := int(room.get("lifetime_limit")) if room.get("lifetime_limit") != null else (16 if room_number == 2 else 12)
	while guard < 400:
		guard += 1
		var zs := _zombies(room)
		max_alive = maxi(max_alive, zs.size())
		if zs.is_empty():
			await _wait(0.6)
			if _zombies(room).is_empty():
				await _wait(3.2)
				if _zombies(room).is_empty():
					break
			continue
		var z: Node = zs[0]
		z.call("receive_bullet_hit", 99999.0, (z as Node3D).global_position + Vector3.UP, player.global_position, false)
		kills += 1
		await _wait(0.35)
		if RunManager.is_combat_room_cleared(room_number) and not _zombies(room).is_empty():
			cleared_early = true
	var spawned := int(room.get("total_spawned")) if room.get("total_spawned") != null else kills
	_log("%s cleared: kills=%d total_spawned=%s lifetime=%d max_alive_seen=%d cleared_flag=%s cleared_while_alive=%s" % [
		label, kills, str(spawned), ctrl_lifetime, max_alive, str(RunManager.is_combat_room_cleared(room_number)), str(cleared_early)])


func _shot_overhead(room: Node, name_: String) -> void:
	var p := player.global_position
	cam.global_position = p + Vector3(0.0, 7.5, 0.01)
	cam.look_at(p, Vector3.FORWARD)
	cam.current = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name_])
	cam.current = false
	_restore_cam()


func _shot_player_view(name_: String) -> void:
	# Look toward the nearest zombie from eye height.
	var p := player.global_position + Vector3(0, 0.62, 0)
	var nearest: Node3D = null
	var best := 1e9
	for z in get_tree().get_nodes_in_group("zombies"):
		if bool(z.get("alive")):
			var d := (z as Node3D).global_position.distance_to(p)
			if d < best:
				best = d
				nearest = z
	cam.global_position = p - Vector3(0, 0, 0)
	if nearest != null:
		var tgt := nearest.global_position + Vector3(0, 1.0, 0)
		cam.look_at(tgt, Vector3.UP)
		cam.global_position = p - (tgt - p).normalized() * 0.3
	cam.current = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name_])
	cam.current = false
	_restore_cam()


func _restore_cam() -> void:
	for c in player.find_children("*", "Camera3D", true, false):
		(c as Camera3D).current = true
		return


func _find_room(room_name: String) -> Node3D:
	return scene.find_child(room_name, false, false) as Node3D


func _teleport(pos: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame


func _walk(from: Vector3, to: Vector3) -> void:
	for i in range(25):
		var p := from.lerp(to, float(i) / 24.0)
		player.global_position = Vector3(p.x, player.global_position.y, p.z)
		player.velocity = Vector3.ZERO
		await get_tree().physics_frame
		await get_tree().physics_frame


func _wait_ready(door: Node) -> void:
	var t := 0.0
	while door != null and t < 20.0 and not bool(door.call("is_destination_ready")):
		await _wait(0.25)
		t += 0.25
