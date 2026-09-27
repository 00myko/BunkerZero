extends Node3D

## Lightweight Room 1 ambience. Only the damaged red utility light flickers;
## the main navigation lights stay stable so combat remains readable.

@export var damaged_light_path: NodePath = NodePath("FarEmergencyRed")
@export_range(1.5, 10.0, 0.1) var minimum_pause := 3.2
@export_range(1.5, 12.0, 0.1) var maximum_pause := 7.4

var _damaged_light: OmniLight3D
var _base_energy := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_damaged_light = get_node_or_null(damaged_light_path) as OmniLight3D
	if _damaged_light == null:
		return
	_base_energy = _damaged_light.light_energy
	_rng.randomize()
	_run_flicker_loop()


func _run_flicker_loop() -> void:
	while is_inside_tree() and is_instance_valid(_damaged_light):
		await get_tree().create_timer(
			_rng.randf_range(minimum_pause, maximum_pause),
			false
		).timeout
		if not is_inside_tree() or not is_instance_valid(_damaged_light):
			return
		await _play_irregular_flicker()


func _play_irregular_flicker() -> void:
	var tween := create_tween()
	# Short, uneven dips read like an aging bunker circuit instead of a repeating
	# horror-game strobe. The light never switches fully off during combat.
	tween.tween_property(_damaged_light, "light_energy", _base_energy * 0.42, 0.045)
	tween.tween_property(_damaged_light, "light_energy", _base_energy * 0.92, 0.075)
	if _rng.randf() < 0.48:
		tween.tween_interval(_rng.randf_range(0.035, 0.11))
		tween.tween_property(_damaged_light, "light_energy", _base_energy * 0.58, 0.04)
		tween.tween_property(_damaged_light, "light_energy", _base_energy, 0.11)
	else:
		tween.tween_property(_damaged_light, "light_energy", _base_energy, 0.14)
	await tween.finished
