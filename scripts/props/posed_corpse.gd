extends Node3D

## Static set-dressing body: plays one clip of the child model's AnimationPlayer,
## seeks to `pose_time` and freezes there. No AI, no collision, no zombie.gd;
## it is scenery, not part of any encounter count.

@export var clip: StringName = &"death_seated_fold"
@export var pose_time := 1.0


func _ready() -> void:
	var player := _find_animation_player(self)
	if player == null or not player.has_animation(clip):
		return
	player.play(clip)
	player.seek(pose_time, true)
	player.pause()


func _find_animation_player(root: Node) -> AnimationPlayer:
	for child in root.get_children():
		if child is AnimationPlayer:
			return child
		var nested := _find_animation_player(child)
		if nested != null:
			return nested
	return null
