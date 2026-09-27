extends Node3D

## Runtime owner for Safe Hub environment content.
##
## main.tscn remains the permanent gameplay root. This node collects only the
## hub art, lighting, collision, and upgrade-table models so those objects can
## be released after entry. The seam blast door remains persistent behind the
## player and is intentionally not owned by this unloadable group.

const EXACT_HUB_NODE_NAMES: PackedStringArray = [
	"RoomFillLight",
	"RoomAccentLight",
	"RoomDoorFill",
	"RoomOrangeWest",
	"RoomOrangeGenerator",
	"RoomCoolEast",
	"RoomCoolCenter",
	"RoomDoorWarmEdge",
	"RoomDoorCoolEdge",
	"Room1StableFloor",
	"Room1BoundaryCollision",
	"SurfaceArt",
	"Furniture",
	"Pipe Valve",
	"Weapons Upgrde Table",
	"Health Upgrades Table",
	"Zombie Multiplier Table",
	"CommandPost",
]

const HUB_NODE_PREFIXES: PackedStringArray = [
	"Industrial Pipe",
	"Tile Floor",
	"Ceiling",
]

var content_collected := false
var unloading := false


func _ready() -> void:
	add_to_group("safe_hub_root")
	call_deferred("_collect_hub_content")


func _collect_hub_content() -> void:
	if content_collected:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	for child in scene.get_children():
		if child == self or not _is_safe_hub_content(child):
			continue
		child.reparent(self, true)
	content_collected = true
	print("SAFE HUB: environment grouped for unload (%d roots)." % get_child_count())


func _is_safe_hub_content(node: Node) -> bool:
	var node_name := String(node.name)
	if node_name in EXACT_HUB_NODE_NAMES:
		return true
	for prefix in HUB_NODE_PREFIXES:
		if node_name.begins_with(prefix):
			return true
	return false


func unload_hub_content() -> void:
	if unloading:
		return
	unloading = true
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	queue_free()
	print("SAFE HUB: environment unloaded after doorway crossing.")
