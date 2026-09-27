extends Node3D

## Irregular bunker emergency-lamp flicker. Hard cuts and short blackouts,
## not a looping strobe. Drives every Light3D under this fixture and the
## housing emission so the lamp itself goes dark with the bulb.

@export var light_path: NodePath = NodePath("AreaLight3D")
@export_range(0.0, 1.0, 0.01) var off_energy_scale := 0.0
@export_range(0.70, 1.0, 0.01) var on_jitter_min := 0.86
@export_range(0.8, 8.0, 0.05) var min_steady := 1.15
@export_range(1.5, 12.0, 0.05) var max_steady := 4.8

var _lights: Array[Light3D] = []
var _base_energy: Array[float] = []
var _emission_mats: Array[BaseMaterial3D] = []
var _base_emission: Array[float] = []
var _rng := RandomNumberGenerator.new()
var _level := 1.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_rng.randomize()
	_collect_lights()
	_collect_emission_materials()
	if _lights.is_empty() and _emission_mats.is_empty():
		return
	_apply(1.0)
	_run_loop()


func _collect_lights() -> void:
	var named := get_node_or_null(light_path) as Light3D
	if named != null:
		_lights.append(named)
	for node in find_children("*", "Light3D", true, false):
		var light := node as Light3D
		if light == null or _lights.has(light):
			continue
		_lights.append(light)
	for light in _lights:
		_base_energy.append(light.light_energy)


func _collect_emission_materials() -> void:
	for node in find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var source: Material = mesh_instance.get_surface_override_material(surface_index)
			if source == null:
				source = mesh_instance.mesh.surface_get_material(surface_index)
			if source == null:
				continue
			var copied := source.duplicate() as BaseMaterial3D
			if copied == null:
				continue
			copied.emission_enabled = true
			if copied.emission.r + copied.emission.g + copied.emission.b < 0.12:
				copied.emission = Color(1.0, 0.08, 0.02, 1.0)
			if copied.emission_energy_multiplier < 0.35:
				copied.emission_energy_multiplier = 1.35
			mesh_instance.set_surface_override_material(surface_index, copied)
			_emission_mats.append(copied)
			_base_emission.append(copied.emission_energy_multiplier)


func _run_loop() -> void:
	while is_inside_tree():
		_apply(_rng.randf_range(on_jitter_min, 1.0))
		await _wait(_rng.randf_range(min_steady, max_steady))
		if not is_inside_tree():
			return
		await _play_burst()


func _play_burst() -> void:
	var roll := _rng.randf()
	if roll < 0.34:
		await _stutter(3, 7)
	elif roll < 0.58:
		await _blackout(_rng.randf_range(0.12, 0.55))
	elif roll < 0.76:
		await _dying_clicks()
	elif roll < 0.90:
		await _brownout()
	else:
		await _blackout(_rng.randf_range(0.85, 2.2))
		await _stutter(2, 4)


func _stutter(min_clicks: int, max_clicks: int) -> void:
	var clicks := _rng.randi_range(min_clicks, max_clicks)
	for _i in range(clicks):
		_apply(0.0)
		await _wait(_rng.randf_range(0.028, 0.085))
		_apply(_rng.randf_range(0.55, 1.0))
		await _wait(_rng.randf_range(0.035, 0.12))


func _blackout(duration: float) -> void:
	_apply(0.0)
	await _wait(duration)
	_apply(_rng.randf_range(on_jitter_min, 1.0))


func _dying_clicks() -> void:
	_apply(0.0)
	await _wait(_rng.randf_range(0.16, 0.42))
	_apply(_rng.randf_range(0.22, 0.45))
	await _wait(_rng.randf_range(0.04, 0.08))
	_apply(0.0)
	await _wait(_rng.randf_range(0.18, 0.55))
	_apply(_rng.randf_range(0.70, 1.0))


func _brownout() -> void:
	var tween := create_tween()
	tween.tween_method(_apply, _level, 0.12, _rng.randf_range(0.18, 0.38))
	await tween.finished
	await _wait(_rng.randf_range(0.06, 0.16))
	_apply(0.0)
	await _wait(_rng.randf_range(0.05, 0.14))
	_apply(_rng.randf_range(on_jitter_min, 1.0))


func _apply(level: float) -> void:
	_level = clampf(level, 0.0, 1.0)
	for i in _lights.size():
		var light := _lights[i]
		if not is_instance_valid(light):
			continue
		var on_energy: float = _base_energy[i]
		light.light_energy = lerpf(on_energy * off_energy_scale, on_energy, _level)
		light.visible = _level > 0.03
	for i in _emission_mats.size():
		var mat := _emission_mats[i]
		if mat == null:
			continue
		mat.emission_energy_multiplier = _base_emission[i] * _level


func _wait(seconds: float) -> void:
	await get_tree().create_timer(maxf(seconds, 0.01), false).timeout
