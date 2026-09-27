class_name LivePreview
extends Control

## Live 3D view for the Controls settings page. Never a screenshot.
##
## MODE_MIRROR (pause): the SubViewport shares the running game's World3D and
## its camera copies the player camera every frame, so the preview shows the
## current room, lighting and equipped weapon viewmodel.
##
## MODE_HUB (main menu): no run exists, so the hub level from main.tscn is
## instanced into the SubViewport's own world (without the player, HUD or door
## streaming) and viewed from the player's spawn.

const MODE_MIRROR := 0
const MODE_HUB := 1
const HUB_SCENE_PATH := "res://scenes/main.tscn"
## Nodes in main.tscn that need a live run (input, HUD, streaming, economy).
const HUB_STRIP_NODES := ["Player", "HUD", "UpgradeUIController", "Room1DoorTransition", "SafeHubRoot", "WorldCollisionBuilder"]

var mode := MODE_MIRROR
var container: SubViewportContainer = null
var viewport: SubViewport = null
var preview_camera: Camera3D = null
var _hub_root: Node3D = null
var _hub_yaw := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	container = SubViewportContainer.new()
	container.name = "ViewportContainer"
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)
	viewport = SubViewport.new()
	viewport.name = "LiveView"
	viewport.handle_input_locally = false
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.audio_listener_enable_3d = false
	container.add_child(viewport)
	preview_camera = Camera3D.new()
	preview_camera.name = "PreviewCamera"
	viewport.add_child(preview_camera)


func start(preview_mode: int) -> void:
	mode = preview_mode
	if viewport == null:
		return
	if mode == MODE_HUB:
		_load_hub()
	else:
		_free_hub()
		viewport.own_world_3d = false
		viewport.world_3d = null
	preview_camera.current = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sync_camera(0.0)


func stop() -> void:
	if viewport != null:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_free_hub()


func _process(delta: float) -> void:
	if viewport == null or viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED:
		return
	_sync_camera(delta)


func _sync_camera(delta: float) -> void:
	if mode == MODE_HUB:
		# Slow idle pan so the menu preview reads as live.
		_hub_yaw += delta * 0.08
		if _hub_root != null:
			var basis := Basis(Vector3.UP, sin(_hub_yaw) * 0.35) * _hub_base_basis
			preview_camera.global_transform = Transform3D(basis, _hub_base_origin)
		return
	var source := _source_camera()
	if source == null:
		return
	preview_camera.global_transform = source.global_transform
	preview_camera.fov = source.fov
	preview_camera.near = source.near
	preview_camera.far = source.far
	preview_camera.cull_mask = source.cull_mask
	preview_camera.h_offset = source.h_offset
	preview_camera.v_offset = source.v_offset
	preview_camera.keep_aspect = source.keep_aspect
	preview_camera.attributes = source.attributes
	preview_camera.environment = source.environment


func _source_camera() -> Camera3D:
	var root_viewport := get_tree().root
	var camera := root_viewport.get_camera_3d()
	if camera != null and camera != preview_camera:
		return camera
	var scene := get_tree().current_scene
	if scene != null:
		var player := scene.get_node_or_null("Player")
		if player != null:
			return player.find_child("Camera3D", true, false) as Camera3D
	return null


var _hub_base_basis := Basis.IDENTITY
var _hub_base_origin := Vector3.ZERO


func _load_hub() -> void:
	if _hub_root != null:
		return
	viewport.own_world_3d = true
	if not ResourceLoader.exists(HUB_SCENE_PATH):
		return
	var packed := load(HUB_SCENE_PATH) as PackedScene
	if packed == null:
		return
	var hub := packed.instantiate() as Node3D
	var spawn := Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, 1.1))
	var player := hub.get_node_or_null("Player") as Node3D
	if player != null:
		spawn = player.transform
	for node_name in HUB_STRIP_NODES:
		var node := hub.get_node_or_null(node_name)
		if node != null:
			hub.remove_child(node)
			node.free()
	_hub_root = hub
	viewport.add_child(hub)
	# Player spawn plus the authored camera pivot height, looking into the hub.
	_hub_base_origin = spawn.origin + Vector3.UP * 0.62
	var forward := -spawn.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
	_hub_base_basis = Basis.looking_at(forward.normalized() + Vector3.DOWN * 0.08, Vector3.UP)
	preview_camera.fov = 72.0
	preview_camera.near = 0.05
	preview_camera.far = 200.0


func _free_hub() -> void:
	if _hub_root != null and is_instance_valid(_hub_root):
		_hub_root.queue_free()
	_hub_root = null
