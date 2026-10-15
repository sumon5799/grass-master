extends Node3D
class_name GardenArena

## Original stylized low-poly 3D garden arena for Step 3 & Step 5.
## Builds:
## - Ground lawn + decorative perimeter border + stepping stones
## - Wooden fence boundaries + physics StaticBody3D walls
## - 5 distinct vegetation types:
##     1. short_grass
##     2. tall_grass
##     3. colorful_flowers
##     4. small_shrubs
##     5. large_trim_plants
## - Step 5: Tracks per-plant uncut/cut state, cutting resistance, reward points,
##   spatial cutting detection around the mower deck, cut-stubble visual transforms,
##   pooled 3D clipping bursts, sound hooks, and duplicate-reward prevention.

signal plants_cut(newly_cut_count: int, points_earned: int, cut_by_type: Dictionary)

const GardenMaterialsScript := preload("res://project/materials/garden_materials.gd")
const MowerPlaceholderScript := preload("res://project/scripts/mower_placeholder.gd")
const ClippingBurstManagerScript := preload("res://project/scripts/clipping_burst_manager.gd")
const SoundHooksScript := preload("res://project/scripts/sound_hooks.gd")

const ARENA_HALF_SIZE: float = 16.0
const FENCE_POST_SPACING: float = 4.0

var ground_body: StaticBody3D
var boundary_body: StaticBody3D
var vegetation_root: Node3D
var mower_placeholder: CharacterBody3D
var clipping_burst_manager: Node3D
var sound_hooks: Node

var plant_type_counts: Dictionary = {
	"short_grass": 0,
	"tall_grass": 0,
	"colorful_flowers": 0,
	"small_shrubs": 0,
	"large_trim_plants": 0,
}

var cut_type_counts: Dictionary = {
	"short_grass": 0,
	"tall_grass": 0,
	"colorful_flowers": 0,
	"small_shrubs": 0,
	"large_trim_plants": 0,
}

var plant_type_rewards: Dictionary = {
	"short_grass": 1,
	"tall_grass": 2,
	"colorful_flowers": 3,
	"small_shrubs": 5,
	"large_trim_plants": 8,
}

var plant_type_resistance: Dictionary = {
	"short_grass": 1,
	"tall_grass": 1,
	"colorful_flowers": 1,
	"small_shrubs": 2,
	"large_trim_plants": 3,
}

var total_cut_count: int = 0
var total_reward_points: int = 0

## Internal array of MultiMesh patch records:
## Each entry: {
##   "name": String,
##   "plant_type": String,
##   "multimesh": MultiMesh,
##   "uncut_transforms": Array[Transform3D],
##   "positions_2d": PackedVector2Array,
##   "is_cut": PackedByteArray
## }
var _patch_records: Array[Dictionary] = []

func _ready() -> void:
	name = "GardenArena"
	_build_ground()
	_build_boundaries()
	_build_vegetation()
	_build_cutting_feedback_systems()
	_build_mower_placeholder()

func _exit_tree() -> void:
	GardenMaterialsScript.clear_cache()

func _physics_process(_delta: float) -> void:
	if mower_placeholder:
		var radius: float = float(mower_placeholder.get("cutting_radius"))
		var power: int = int(mower_placeholder.get("cutting_power"))
		cut_plants_in_radius(mower_placeholder.global_position, radius, power)

func _build_ground() -> void:
	ground_body = StaticBody3D.new()
	ground_body.name = "GroundBody"
	add_child(ground_body)

	# Outer border base
	var outer_mesh_inst := MeshInstance3D.new()
	outer_mesh_inst.name = "OuterGroundMesh"
	var outer_box := BoxMesh.new()
	outer_box.size = Vector3(ARENA_HALF_SIZE * 2.0 + 6.0, 0.35, ARENA_HALF_SIZE * 2.0 + 6.0)
	outer_mesh_inst.mesh = outer_box
	outer_mesh_inst.position = Vector3(0.0, -0.20, 0.0)
	outer_mesh_inst.material_override = GardenMaterialsScript.get_material("ground_border")
	ground_body.add_child(outer_mesh_inst)

	# Main garden lawn surface
	var lawn_mesh_inst := MeshInstance3D.new()
	lawn_mesh_inst.name = "LawnGroundMesh"
	var lawn_box := BoxMesh.new()
	lawn_box.size = Vector3(ARENA_HALF_SIZE * 2.0, 0.20, ARENA_HALF_SIZE * 2.0)
	lawn_mesh_inst.mesh = lawn_box
	lawn_mesh_inst.position = Vector3(0.0, -0.10, 0.0)
	lawn_mesh_inst.material_override = GardenMaterialsScript.get_material("ground_soil")
	ground_body.add_child(lawn_mesh_inst)

	# Ground physics collision shape
	var ground_col := CollisionShape3D.new()
	ground_col.name = "GroundCollision"
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(ARENA_HALF_SIZE * 2.0 + 4.0, 0.40, ARENA_HALF_SIZE * 2.0 + 4.0)
	ground_col.shape = box_shape
	ground_col.position = Vector3(0.0, -0.20, 0.0)
	ground_body.add_child(ground_col)

	# Decorative stone spawn pad around center
	var pad_mesh_inst := MeshInstance3D.new()
	pad_mesh_inst.name = "SpawnStonePad"
	var pad_cyl := CylinderMesh.new()
	pad_cyl.top_radius = 2.2
	pad_cyl.bottom_radius = 2.35
	pad_cyl.height = 0.04
	pad_cyl.radial_segments = 16
	pad_mesh_inst.mesh = pad_cyl
	pad_mesh_inst.position = Vector3(0.0, 0.02, 0.0)
	pad_mesh_inst.material_override = GardenMaterialsScript.get_material("path_stone")
	ground_body.add_child(pad_mesh_inst)

func _build_boundaries() -> void:
	boundary_body = StaticBody3D.new()
	boundary_body.name = "GardenBoundaries"
	add_child(boundary_body)

	var wall_configs := [
		{"name": "WallNorth", "pos": Vector3(0.0, 0.75, -ARENA_HALF_SIZE), "size": Vector3(ARENA_HALF_SIZE * 2.0, 1.5, 0.5)},
		{"name": "WallSouth", "pos": Vector3(0.0, 0.75, ARENA_HALF_SIZE), "size": Vector3(ARENA_HALF_SIZE * 2.0, 1.5, 0.5)},
		{"name": "WallWest", "pos": Vector3(-ARENA_HALF_SIZE, 0.75, 0.0), "size": Vector3(0.5, 1.5, ARENA_HALF_SIZE * 2.0)},
		{"name": "WallEast", "pos": Vector3(ARENA_HALF_SIZE, 0.75, 0.0), "size": Vector3(0.5, 1.5, ARENA_HALF_SIZE * 2.0)},
	]

	for cfg in wall_configs:
		var col := CollisionShape3D.new()
		col.name = String(cfg["name"])
		var shape := BoxShape3D.new()
		shape.size = cfg["size"]
		col.shape = shape
		col.position = cfg["pos"]
		boundary_body.add_child(col)

	# Visual low-poly wooden perimeter fence (rails + posts)
	var fence_visuals := Node3D.new()
	fence_visuals.name = "FenceVisuals"
	boundary_body.add_child(fence_visuals)

	var rail_horiz_mesh := BoxMesh.new()
	rail_horiz_mesh.size = Vector3(ARENA_HALF_SIZE * 2.0, 0.14, 0.12)
	var rail_vert_mesh := BoxMesh.new()
	rail_vert_mesh.size = Vector3(0.12, 0.14, ARENA_HALF_SIZE * 2.0)

	for rail_y in [0.42, 0.84]:
		for z_side in [-ARENA_HALF_SIZE, ARENA_HALF_SIZE]:
			var rail_ns := MeshInstance3D.new()
			rail_ns.mesh = rail_horiz_mesh.duplicate()
			rail_ns.position = Vector3(0.0, rail_y, z_side)
			rail_ns.material_override = GardenMaterialsScript.get_material("fence_wood")
			fence_visuals.add_child(rail_ns)
		for x_side in [-ARENA_HALF_SIZE, ARENA_HALF_SIZE]:
			var rail_ew := MeshInstance3D.new()
			rail_ew.mesh = rail_vert_mesh.duplicate()
			rail_ew.position = Vector3(x_side, rail_y, 0.0)
			rail_ew.material_override = GardenMaterialsScript.get_material("fence_wood")
			fence_visuals.add_child(rail_ew)

	# Fence posts around perimeter using MultiMeshInstance3D for low draw calls
	var post_positions: Array[Vector3] = []
	var steps := int((ARENA_HALF_SIZE * 2.0) / FENCE_POST_SPACING)
	for i in range(steps + 1):
		var offset := -ARENA_HALF_SIZE + float(i) * FENCE_POST_SPACING
		post_positions.append(Vector3(offset, 0.55, -ARENA_HALF_SIZE))
		post_positions.append(Vector3(offset, 0.55, ARENA_HALF_SIZE))
		if i > 0 and i < steps:
			post_positions.append(Vector3(-ARENA_HALF_SIZE, 0.55, offset))
			post_positions.append(Vector3(ARENA_HALF_SIZE, 0.55, offset))

	var post_mm_inst := MultiMeshInstance3D.new()
	post_mm_inst.name = "FencePostsMultiMesh"
	var post_mm := MultiMesh.new()
	post_mm.transform_format = MultiMesh.TRANSFORM_3D
	post_mm.instance_count = post_positions.size()
	var post_box := BoxMesh.new()
	post_box.size = Vector3(0.26, 1.10, 0.26)
	post_mm.mesh = post_box
	for idx in range(post_positions.size()):
		post_mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, post_positions[idx]))
	post_mm_inst.multimesh = post_mm
	post_mm_inst.material_override = GardenMaterialsScript.get_material("fence_post_cap")
	fence_visuals.add_child(post_mm_inst)

func _build_vegetation() -> void:
	vegetation_root = Node3D.new()
	vegetation_root.name = "VegetationRoot"
	add_child(vegetation_root)

	_patch_records.clear()
	total_cut_count = 0
	total_reward_points = 0
	for k in cut_type_counts.keys():
		cut_type_counts[k] = 0

	var rng := RandomNumberGenerator.new()
	rng.seed = 20261015 # Deterministic original layout

	var short_grass_transforms: Array[Transform3D] = []
	var tall_grass_transforms: Array[Transform3D] = []
	var flower_pink_transforms: Array[Transform3D] = []
	var flower_gold_transforms: Array[Transform3D] = []
	var flower_blue_transforms: Array[Transform3D] = []
	var shrub_transforms: Array[Transform3D] = []
	var large_plant_transforms: Array[Transform3D] = []

	var grid_min := -14.0
	var grid_max := 14.0
	var step := 1.4

	var x := grid_min
	while x <= grid_max:
		var z := grid_min
		while z <= grid_max:
			var dist_center := Vector2(x, z).length()
			# Keep spawn pad clear around the mower start position
			if dist_center > 2.8:
				var jitter_x := x + rng.randf_range(-0.42, 0.42)
				var jitter_z := z + rng.randf_range(-0.42, 0.42)
				var yaw := rng.randf_range(0.0, TAU)
				var basis := Basis.from_euler(Vector3(0.0, yaw, 0.0))

				if dist_center > 11.8 and rng.randf() < 0.28:
					var scale_f := rng.randf_range(0.9, 1.25)
					large_plant_transforms.append(Transform3D(basis.scaled(Vector3(scale_f, scale_f, scale_f)), Vector3(jitter_x, 0.65 * scale_f, jitter_z)))
				elif dist_center > 8.5 and rng.randf() < 0.25:
					var scale_s := rng.randf_range(0.85, 1.20)
					shrub_transforms.append(Transform3D(basis.scaled(Vector3(scale_s, scale_s, scale_s)), Vector3(jitter_x, 0.42 * scale_s, jitter_z)))
				elif rng.randf() < 0.22:
					var f_scale := rng.randf_range(0.9, 1.15)
					var f_xform := Transform3D(basis.scaled(Vector3(f_scale, f_scale, f_scale)), Vector3(jitter_x, 0.36 * f_scale, jitter_z))
					var color_pick := rng.randi_range(0, 2)
					if color_pick == 0:
						flower_pink_transforms.append(f_xform)
					elif color_pick == 1:
						flower_gold_transforms.append(f_xform)
					else:
						flower_blue_transforms.append(f_xform)
				elif rng.randf() < 0.45:
					var tg_scale := Vector3(rng.randf_range(0.9, 1.2), rng.randf_range(1.0, 1.35), rng.randf_range(0.9, 1.2))
					tall_grass_transforms.append(Transform3D(basis.scaled(tg_scale), Vector3(jitter_x, 0.42 * tg_scale.y, jitter_z)))
				else:
					var sg_scale := Vector3(rng.randf_range(0.85, 1.15), rng.randf_range(0.85, 1.15), rng.randf_range(0.85, 1.15))
					short_grass_transforms.append(Transform3D(basis.scaled(sg_scale), Vector3(jitter_x, 0.22 * sg_scale.y, jitter_z)))
			z += step
		x += step

	# 1. Short Grass (Low-poly tapered tuft prism)
	var short_mesh := PrismMesh.new()
	short_mesh.size = Vector3(0.46, 0.44, 0.36)
	_add_multimesh_group("ShortGrassPatch", "short_grass", short_mesh, "short_grass", short_grass_transforms)
	plant_type_counts["short_grass"] = short_grass_transforms.size()

	# 2. Tall Grass (Taller stylized blade cluster)
	var tall_mesh := PrismMesh.new()
	tall_mesh.size = Vector3(0.56, 0.86, 0.46)
	_add_multimesh_group("TallGrassPatch", "tall_grass", tall_mesh, "tall_grass", tall_grass_transforms)
	plant_type_counts["tall_grass"] = tall_grass_transforms.size()

	# 3. Colorful Flowers (Pink, Gold, and Blue blossoms)
	var flower_pink_mesh := SphereMesh.new()
	flower_pink_mesh.radius = 0.28
	flower_pink_mesh.height = 0.48
	flower_pink_mesh.radial_segments = 10
	flower_pink_mesh.rings = 6
	var flower_gold_mesh := flower_pink_mesh.duplicate() as SphereMesh
	var flower_blue_mesh := flower_pink_mesh.duplicate() as SphereMesh
	_add_multimesh_group("FlowersPinkPatch", "colorful_flowers", flower_pink_mesh, "flower_pink", flower_pink_transforms)
	_add_multimesh_group("FlowersGoldPatch", "colorful_flowers", flower_gold_mesh, "flower_gold", flower_gold_transforms)
	_add_multimesh_group("FlowersBluePatch", "colorful_flowers", flower_blue_mesh, "flower_blue", flower_blue_transforms)
	plant_type_counts["colorful_flowers"] = (
		flower_pink_transforms.size()
		+ flower_gold_transforms.size()
		+ flower_blue_transforms.size()
	)

	# 4. Small Shrubs (Low-poly rounded bush)
	var shrub_mesh := SphereMesh.new()
	shrub_mesh.radius = 0.52
	shrub_mesh.height = 0.84
	shrub_mesh.radial_segments = 10
	shrub_mesh.rings = 6
	_add_multimesh_group("SmallShrubsPatch", "small_shrubs", shrub_mesh, "shrub_leaf", shrub_transforms)
	plant_type_counts["small_shrubs"] = shrub_transforms.size()

	# 5. Larger Trim-able Plants (Stylized conical topiary)
	var large_mesh := CylinderMesh.new()
	large_mesh.top_radius = 0.14
	large_mesh.bottom_radius = 0.68
	large_mesh.height = 1.32
	large_mesh.radial_segments = 10
	_add_multimesh_group("LargeTrimPlantsPatch", "large_trim_plants", large_mesh, "large_plant_leaf", large_plant_transforms)
	plant_type_counts["large_trim_plants"] = large_plant_transforms.size()

func _add_multimesh_group(
	node_name: String,
	plant_type: String,
	mesh: Mesh,
	material_key: String,
	transforms: Array[Transform3D]
) -> MultiMeshInstance3D:
	var mm_inst := MultiMeshInstance3D.new()
	mm_inst.name = node_name
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()

	var pos_2d := PackedVector2Array()
	pos_2d.resize(transforms.size())
	var is_cut := PackedByteArray()
	is_cut.resize(transforms.size())

	for i in range(transforms.size()):
		var xform := transforms[i]
		mm.set_instance_transform(i, xform)
		pos_2d[i] = Vector2(xform.origin.x, xform.origin.z)
		is_cut[i] = 0

	mm_inst.multimesh = mm
	mm_inst.material_override = GardenMaterialsScript.get_material(material_key)
	vegetation_root.add_child(mm_inst)

	_patch_records.append({
		"name": node_name,
		"plant_type": plant_type,
		"multimesh": mm,
		"uncut_transforms": transforms.duplicate(),
		"positions_2d": pos_2d,
		"is_cut": is_cut,
	})
	return mm_inst

func _build_cutting_feedback_systems() -> void:
	clipping_burst_manager = ClippingBurstManagerScript.new()
	add_child(clipping_burst_manager)

	sound_hooks = SoundHooksScript.new()
	add_child(sound_hooks)

func _build_mower_placeholder() -> void:
	mower_placeholder = MowerPlaceholderScript.new()
	mower_placeholder.position = Vector3(0.0, 0.0, 0.0)
	add_child(mower_placeholder)

## Cuts any uncut plants whose 2D ground coordinates lie within `radius` of `world_pos`
## and whose resistance <= `cutter_power`.
## Returns a Dictionary summarizing `{ "newly_cut": int, "points_earned": int, "by_type": Dictionary }`.
## Once a plant is cut (`is_cut[i] == 1`), passing over it again will NEVER cut or reward it again.
func cut_plants_in_radius(world_pos: Vector3, radius: float, cutter_power: int = 3) -> Dictionary:
	var center_2d := Vector2(world_pos.x, world_pos.z)
	var radius_sq := radius * radius
	var newly_cut := 0
	var points_earned := 0
	var newly_cut_by_type: Dictionary = {}
	var last_cut_plant_type: String = ""

	for record in _patch_records:
		var p_type: String = String(record["plant_type"])
		var req_power: int = int(plant_type_resistance.get(p_type, 1))
		if cutter_power < req_power:
			continue

		var pos_2d: PackedVector2Array = record["positions_2d"]
		var is_cut: PackedByteArray = record["is_cut"]
		var uncut_xforms: Array = record["uncut_transforms"]
		var mm: MultiMesh = record["multimesh"]
		var reward_per_plant: int = int(plant_type_rewards.get(p_type, 1))

		var count := pos_2d.size()
		for i in range(count):
			if is_cut[i] != 0:
				continue
			if center_2d.distance_squared_to(pos_2d[i]) <= radius_sq:
				is_cut[i] = 1
				newly_cut += 1
				total_cut_count += 1
				cut_type_counts[p_type] = int(cut_type_counts.get(p_type, 0)) + 1
				newly_cut_by_type[p_type] = int(newly_cut_by_type.get(p_type, 0)) + 1
				points_earned += reward_per_plant
				total_reward_points += reward_per_plant
				last_cut_plant_type = p_type

				# Transform uncut plant into low trimmed lawn stubble (14% height)
				var orig_xform: Transform3D = uncut_xforms[i]
				var trimmed_basis := orig_xform.basis.scaled(Vector3(0.82, 0.14, 0.82))
				var trimmed_origin := Vector3(orig_xform.origin.x, 0.03, orig_xform.origin.z)
				mm.set_instance_transform(i, Transform3D(trimmed_basis, trimmed_origin))

				if clipping_burst_manager and clipping_burst_manager.has_method("spawn_clipping_burst"):
					clipping_burst_manager.spawn_clipping_burst(orig_xform.origin, 4)

		record["is_cut"] = is_cut

	if newly_cut > 0:
		if sound_hooks and sound_hooks.has_method("play_cut_sound"):
			sound_hooks.play_cut_sound(last_cut_plant_type, newly_cut)
		if mower_placeholder and mower_placeholder.has_method("notify_cut_feedback"):
			mower_placeholder.notify_cut_feedback()
		plants_cut.emit(newly_cut, points_earned, newly_cut_by_type)

	return {
		"newly_cut": newly_cut,
		"points_earned": points_earned,
		"by_type": newly_cut_by_type,
	}

## Resets all plants back to their uncut state and zeroes all cut/reward counters.
func reset_all_plants() -> void:
	total_cut_count = 0
	total_reward_points = 0
	for k in cut_type_counts.keys():
		cut_type_counts[k] = 0

	for record in _patch_records:
		var is_cut: PackedByteArray = record["is_cut"]
		var uncut_xforms: Array = record["uncut_transforms"]
		var mm: MultiMesh = record["multimesh"]
		for i in range(is_cut.size()):
			is_cut[i] = 0
			mm.set_instance_transform(i, uncut_xforms[i])
		record["is_cut"] = is_cut

func get_total_plant_count() -> int:
	var total := 0
	for key in plant_type_counts.keys():
		total += int(plant_type_counts[key])
	return total

func get_total_cut_count() -> int:
	return total_cut_count

func get_remaining_plant_count() -> int:
	return maxi(0, get_total_plant_count() - total_cut_count)

func get_completion_percentage() -> float:
	var total := get_total_plant_count()
	if total <= 0:
		return 100.0
	return (float(total_cut_count) / float(total)) * 100.0
