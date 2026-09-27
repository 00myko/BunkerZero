extends Node3D

## Standalone gameplay bootstrap for the Cafeteria_Playtest scene.
## The reusable Cafeteria.tscn intentionally remains room art only so it can be
## streamed into the persistent main scene without duplicating Player or HUD.

@export var player_path: NodePath = NodePath("Player")
@export_range(1, 20, 1) var combat_room_number: int = 2


func _ready() -> void:
	call_deferred("_begin_cafeteria_test")


func _begin_cafeteria_test() -> void:
	var player := get_node_or_null(player_path)
	if player == null:
		push_error("Cafeteria playtest could not find its Player node.")
		return

	# player.gd resets run state while it initializes. Starting here, deferred,
	# guarantees the HUD timer and weapon state are activated afterward.
	RunManager.start_run(combat_room_number, true)
	MusicManager.begin_combat_room()
	if player.has_method("_equip_pistol"):
		player.call("_equip_pistol")
