extends Camera3D
class_name FollowCamera

## Step 4 — Adjustable Isometric/Third-Person Follow Camera.
## Tracks the mower smoothly, looks slightly ahead of its movement velocity,
## clamps camera framing near garden boundaries, and supports adjustable zoom.

@export var base_offset: Vector3 = Vector3(0.0, 13.5, 13.0)
@export var follow_smoothness: float = 8.5
@export var look_ahead_factor: float = 0.22
@export var min_zoom: float = 0.65
@export var max_zoom: float = 1.45
@export var zoom_step: float = 0.12
@export var arena_camera_limit: float = 14.5

var target_node: Node3D
var zoom_level: float = 1.0
var _smoothed_look_target: Vector3 = Vector3.ZERO

func _ready() -> void:
	current = true

func set_follow_target(target: Node3D, snap_immediately: bool = true) -> void:
	target_node = target
	if target_node and snap_immediately:
		snap_to_target()

func set_zoom_level(new_zoom: float) -> void:
	zoom_level = clampf(new_zoom, min_zoom, max_zoom)

func adjust_zoom(delta_zoom: float) -> void:
	set_zoom_level(zoom_level + delta_zoom)

func snap_to_target() -> void:
	if target_node == null:
		return
	var clamped_focus := _get_clamped_focus(target_node.global_position)
	_smoothed_look_target = clamped_focus + Vector3(0.0, 0.35, -0.8)
	global_position = clamped_focus + (base_offset * zoom_level)
	look_at(_smoothed_look_target, Vector3.UP)

func _physics_process(delta: float) -> void:
	update_camera(delta)

func update_camera(delta: float) -> void:
	if target_node == null:
		return

	var raw_pos := target_node.global_position
	var lead_offset := Vector3.ZERO
	if target_node is CharacterBody3D:
		var vel := (target_node as CharacterBody3D).velocity
		lead_offset = Vector3(vel.x, 0.0, vel.z) * look_ahead_factor

	var focus_pos := _get_clamped_focus(raw_pos + lead_offset)
	var desired_cam_pos := focus_pos + (base_offset * zoom_level)
	var t := clampf(follow_smoothness * delta, 0.0, 1.0)

	global_position = global_position.lerp(desired_cam_pos, t)
	var desired_look := focus_pos + Vector3(0.0, 0.35, -0.8)
	_smoothed_look_target = _smoothed_look_target.lerp(desired_look, t)
	look_at(_smoothed_look_target, Vector3.UP)

func _get_clamped_focus(pos: Vector3) -> Vector3:
	return Vector3(
		clampf(pos.x, -arena_camera_limit, arena_camera_limit),
		maxf(pos.y, 0.0),
		clampf(pos.z, -arena_camera_limit, arena_camera_limit)
	)
