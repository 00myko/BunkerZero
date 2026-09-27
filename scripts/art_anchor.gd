@tool
extends Node3D

## Places one imported GLB and normalizes it to a known room scale.

@export var source_scene: PackedScene
@export var target_size_meters: float = 1.0
@export var fit_height: bool = false
@export var rotate_degrees: Vector3 = Vector3.ZERO

const GENERATED_NAME := "__GENERATED_ART__"

func _ready() -> void:
	call_deferred("_rebuild")

func _rebuild() -> void:
	var old: Node = get_node_or_null(GENERATED_NAME)
	if old != null:
		old.free()
	if source_scene == null:
		return
	var generated: Node3D = Node3D.new()
	generated.name = GENERATED_NAME
	add_child(generated)
	var instance: Node3D = source_scene.instantiate() as Node3D
	if instance == null:
		return
	instance.name = "SourceModel"
	instance.rotation_degrees = rotate_degrees
	generated.add_child(instance)
	call_deferred("_normalize", instance)

func _normalize(instance: Node3D) -> void:
	await get_tree().process_frame
	if not is_instance_valid(instance):
		return
	var bounds: AABB = _bounds(instance)
	var current_size: float = bounds.size.y if fit_height else maxf(bounds.size.x, bounds.size.z)
	if current_size <= 0.0001:
		return
	instance.scale = Vector3.ONE * (target_size_meters / current_size)
	await get_tree().process_frame
	bounds = _bounds(instance)
	instance.position = Vector3(-(bounds.position.x + bounds.size.x * 0.5), -bounds.position.y, -(bounds.position.z + bounds.size.z * 0.5))

func _bounds(root: Node3D) -> AABB:
	var result: AABB = AABB()
	var initialized: bool = false
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var local_aabb: AABB = mesh_instance.mesh.get_aabb()
		var transform_to_root: Transform3D = root.global_transform.affine_inverse() * mesh_instance.global_transform
		for x in [local_aabb.position.x, local_aabb.end.x]:
			for y in [local_aabb.position.y, local_aabb.end.y]:
				for z in [local_aabb.position.z, local_aabb.end.z]:
					var point: Vector3 = transform_to_root * Vector3(x, y, z)
					if not initialized:
						result = AABB(point, Vector3.ZERO)
						initialized = true
					else:
						result = result.expand(point)
	return result
