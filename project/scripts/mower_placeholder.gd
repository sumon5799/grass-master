extends CharacterBody3D
class_name MowerPlaceholder

## Step 4 & Step 5 — Playable 3D Lawnmower Controller & Visuals.
## Implements smooth analog/8-direction movement, smooth heading turn, boost,
## physics collision response against garden boundaries, wheel spin, subtle engine
## vibration, cutting radius configuration, and cut flash feedback.

const GardenMaterialsScript := preload("res://project/materials/garden_materials.gd")

@export var base_move_speed: float = 8.5
@export var boost_multiplier: float = 1.55
@export var acceleration: float = 18.0
@export var friction: float = 16.0
@export var turn_speed: float = 10.5
@export var collision_radius: float = 0.92
@export var cutting_radius: float = 1.45
@export var cutting_power: int = 3
@export var arena_limit: float = 15.05

var body_root: Node3D
var collision_shape: CollisionShape3D
var cutter_indicator: MeshInstance3D
var wheels: Array[MeshInstance3D] = []

var touch_input_vector: Vector2 = Vector2.ZERO
var touch_boost_pressed: bool = false
var is_boosting: bool = false
var current_speed: float = 0.0
var last_input_vector: Vector2 = Vector2.ZERO
var boundary_hit_count: int = 0
var _vibration_time: float = 0.0
var _cut_flash_timer: float = 0.0

func _ready() -> void:
	name = "MowerPlaceholder"
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_stop_on_slope = true
	wall_min_slide_angle = 0.05
	_build_collision_shape()
	_build_mower_mesh()

func _build_collision_shape() -> void:
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "MowerCollisionShape"
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = collision_radius
	cyl_shape.height = 1.20
	collision_shape.shape = cyl_shape
	collision_shape.position = Vector3(0.0, 0.60, 0.0)
	add_child(collision_shape)

func _build_mower_mesh() -> void:
	body_root = Node3D.new()
	body_root.name = "BodyRoot"
	add_child(body_root)

	# Cutting deck base
	var deck := MeshInstance3D.new()
	deck.name = "CuttingDeck"
	var deck_mesh := CylinderMesh.new()
	deck_mesh.top_radius = 0.85
	deck_mesh.bottom_radius = 0.92
	deck_mesh.height = 0.26
	deck_mesh.radial_segments = 16
	deck.mesh = deck_mesh
	deck.position = Vector3(0.0, 0.22, 0.0)
	deck.material_override = GardenMaterialsScript.get_material("mower_deck")
	body_root.add_child(deck)

	# Upper engine housing
	var chassis := MeshInstance3D.new()
	chassis.name = "EngineChassis"
	var chassis_mesh := BoxMesh.new()
	chassis_mesh.size = Vector3(1.05, 0.42, 1.25)
	chassis.mesh = chassis_mesh
	chassis.position = Vector3(0.0, 0.52, 0.05)
	chassis.material_override = GardenMaterialsScript.get_material("mower_body")
	body_root.add_child(chassis)

	# Front direction nose marker (points toward -Z local forward)
	var nose := MeshInstance3D.new()
	nose.name = "FrontBumper"
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.76, 0.18, 0.26)
	nose.mesh = nose_mesh
	nose.position = Vector3(0.0, 0.30, -0.78)
	nose.material_override = GardenMaterialsScript.get_material("mower_dark")
	body_root.add_child(nose)

	# Top engine cap
	var cap := MeshInstance3D.new()
	cap.name = "EngineCap"
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.30
	cap_mesh.bottom_radius = 0.36
	cap_mesh.height = 0.18
	cap_mesh.radial_segments = 12
	cap.mesh = cap_mesh
	cap.position = Vector3(0.0, 0.80, 0.0)
	cap.material_override = GardenMaterialsScript.get_material("mower_dark")
	body_root.add_child(cap)

	# Handlebar frame (rear)
	var handle_left := MeshInstance3D.new()
	handle_left.name = "HandleLeft"
	var strut_mesh := CylinderMesh.new()
	strut_mesh.top_radius = 0.045
	strut_mesh.bottom_radius = 0.045
	strut_mesh.height = 1.25
	strut_mesh.radial_segments = 8
	handle_left.mesh = strut_mesh
	handle_left.position = Vector3(-0.38, 0.95, 0.78)
	handle_left.rotation_degrees = Vector3(-36.0, 0.0, 0.0)
	handle_left.material_override = GardenMaterialsScript.get_material("mower_dark")
	body_root.add_child(handle_left)

	var handle_right := MeshInstance3D.new()
	handle_right.name = "HandleRight"
	handle_right.mesh = strut_mesh.duplicate()
	handle_right.position = Vector3(0.38, 0.95, 0.78)
	handle_right.rotation_degrees = Vector3(-36.0, 0.0, 0.0)
	handle_right.material_override = GardenMaterialsScript.get_material("mower_dark")
	body_root.add_child(handle_right)

	var crossbar := MeshInstance3D.new()
	crossbar.name = "HandleCrossbar"
	var bar_mesh := CylinderMesh.new()
	bar_mesh.top_radius = 0.05
	bar_mesh.bottom_radius = 0.05
	bar_mesh.height = 0.84
	bar_mesh.radial_segments = 8
	crossbar.mesh = bar_mesh
	crossbar.position = Vector3(0.0, 1.42, 1.12)
	crossbar.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	crossbar.material_override = GardenMaterialsScript.get_material("mower_body")
	body_root.add_child(crossbar)

	# 4 Low-poly wheels
	wheels.clear()
	var wheel_mesh := CylinderMesh.new()
	wheel_mesh.top_radius = 0.24
	wheel_mesh.bottom_radius = 0.24
	wheel_mesh.height = 0.16
	wheel_mesh.radial_segments = 12

	var wheel_offsets: Array[Vector3] = [
		Vector3(-0.62, 0.24, -0.52),
		Vector3(0.62, 0.24, -0.52),
		Vector3(-0.64, 0.24, 0.56),
		Vector3(0.64, 0.24, 0.56),
	]
	for i in range(wheel_offsets.size()):
		var wheel := MeshInstance3D.new()
		wheel.name = "Wheel_%d" % i
		wheel.mesh = wheel_mesh.duplicate()
		wheel.position = wheel_offsets[i]
		wheel.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		wheel.material_override = GardenMaterialsScript.get_material("mower_dark")
		body_root.add_child(wheel)
		wheels.append(wheel)

	# Subtle cutter radius ring near ground
	cutter_indicator = MeshInstance3D.new()
	cutter_indicator.name = "CutterIndicator"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.94
	ring_mesh.outer_radius = 1.02
	ring_mesh.rings = 16
	ring_mesh.ring_segments = 12
	cutter_indicator.mesh = ring_mesh
	cutter_indicator.position = Vector3(0.0, 0.05, 0.0)
	cutter_indicator.material_override = GardenMaterialsScript.get_material("mower_blade_ring")
	body_root.add_child(cutter_indicator)

func set_touch_input(vec: Vector2) -> void:
	if vec.length() > 1.0:
		touch_input_vector = vec.normalized()
	else:
		touch_input_vector = vec

func set_touch_boost(active: bool) -> void:
	touch_boost_pressed = active

func get_combined_input_vector() -> Vector2:
	var kb_vec := Vector2(
		Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	var combined := kb_vec + touch_input_vector
	if combined.length() > 1.0:
		combined = combined.normalized()
	return combined

func _physics_process(delta: float) -> void:
	step_movement(delta)

func step_movement(delta: float) -> void:
	var input_vec := get_combined_input_vector()
	last_input_vector = input_vec
	is_boosting = Input.is_action_pressed("boost") or touch_boost_pressed

	var max_speed := base_move_speed * (boost_multiplier if is_boosting else 1.0)
	var desired_dir := Vector3(input_vec.x, 0.0, input_vec.y)

	if desired_dir.length_squared() > 0.001:
		var target_vel := desired_dir * max_speed
		velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)

		# Smoothly turn mower body toward movement direction (-Z is local forward)
		var target_yaw := atan2(-desired_dir.x, -desired_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	# Keep mower grounded on the lawn plane
	if not is_on_floor():
		velocity.y = -9.8
	else:
		velocity.y = 0.0

	move_and_slide()

	# Count wall collisions and enforce hard safety clamp inside garden boundaries
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col and absf(col.get_normal().y) < 0.4:
			boundary_hit_count += 1

	if absf(global_position.x) > arena_limit or absf(global_position.z) > arena_limit:
		global_position.x = clampf(global_position.x, -arena_limit, arena_limit)
		global_position.z = clampf(global_position.z, -arena_limit, arena_limit)
		boundary_hit_count += 1

	if global_position.y < 0.0:
		global_position.y = 0.0

	current_speed = Vector2(velocity.x, velocity.z).length()
	_animate_mower_visuals(delta)

func _animate_mower_visuals(delta: float) -> void:
	if body_root == null:
		return

	_vibration_time += delta * (28.0 if current_speed > 0.2 else 10.0)
	var vib_amp := 0.012 if current_speed > 0.2 else 0.003
	body_root.position.y = sin(_vibration_time) * vib_amp

	if cutter_indicator:
		cutter_indicator.rotate_y(delta * (6.0 if is_boosting else 3.2))
		if _cut_flash_timer > 0.0:
			_cut_flash_timer = maxf(0.0, _cut_flash_timer - delta)
			if _cut_flash_timer <= 0.0:
				cutter_indicator.material_override = GardenMaterialsScript.get_material("mower_blade_ring")
		var ring_scale := 1.12 if _cut_flash_timer > 0.0 else (1.06 if is_boosting else 1.0)
		cutter_indicator.scale = Vector3(ring_scale, 1.0, ring_scale)

	if current_speed > 0.05:
		var wheel_spin := delta * current_speed * 4.2
		for wheel in wheels:
			if wheel:
				wheel.rotate_x(-wheel_spin)

func notify_cut_feedback() -> void:
	_cut_flash_timer = 0.18
	if cutter_indicator:
		cutter_indicator.material_override = GardenMaterialsScript.get_material("mower_blade_ring_active")
		cutter_indicator.scale = Vector3(1.12, 1.0, 1.12)
