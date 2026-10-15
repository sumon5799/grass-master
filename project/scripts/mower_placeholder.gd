extends Node3D
class_name MowerPlaceholder

## Original low-poly stylized lawnmower placeholder for Step 3.
## Includes chassis, blade deck, wheels, handle bar, and visual cutter ring.
## Step 4 will attach full movement, turning, collision, and camera follow.

const GardenMaterialsScript := preload("res://project/materials/garden_materials.gd")

var body_root: Node3D
var cutter_indicator: MeshInstance3D

func _ready() -> void:
	name = "MowerPlaceholder"
	_build_mower_mesh()

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
