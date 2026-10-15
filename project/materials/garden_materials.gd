extends RefCounted
class_name GardenMaterials

## Original stylized low-poly material palette for Grass Master.
## Uses shared StandardMaterial3D instances to minimize draw state switches on mobile.

static var _cache: Dictionary = {}

static func get_material(key: String) -> StandardMaterial3D:
	if _cache.has(key):
		return _cache[key]
	var mat := _create_material(key)
	_cache[key] = mat
	return mat

static func clear_cache() -> void:
	_cache.clear()

static func _create_material(key: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.85
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX

	match key:
		"ground_soil":
			mat.albedo_color = Color(0.28, 0.56, 0.24)
			mat.roughness = 0.92
		"ground_border":
			mat.albedo_color = Color(0.22, 0.46, 0.19)
			mat.roughness = 0.95
		"path_stone":
			mat.albedo_color = Color(0.76, 0.73, 0.67)
			mat.roughness = 0.88
		"fence_wood":
			mat.albedo_color = Color(0.55, 0.36, 0.20)
			mat.roughness = 0.82
		"fence_post_cap":
			mat.albedo_color = Color(0.66, 0.45, 0.27)
			mat.roughness = 0.78
		"short_grass":
			mat.albedo_color = Color(0.32, 0.76, 0.27)
			mat.roughness = 0.80
		"tall_grass":
			mat.albedo_color = Color(0.20, 0.66, 0.24)
			mat.roughness = 0.78
		"flower_stem":
			mat.albedo_color = Color(0.24, 0.68, 0.26)
			mat.roughness = 0.80
		"flower_pink":
			mat.albedo_color = Color(0.96, 0.42, 0.66)
			mat.roughness = 0.65
		"flower_gold":
			mat.albedo_color = Color(0.99, 0.80, 0.18)
			mat.roughness = 0.65
		"flower_blue":
			mat.albedo_color = Color(0.36, 0.68, 0.98)
			mat.roughness = 0.65
		"shrub_leaf":
			mat.albedo_color = Color(0.16, 0.56, 0.25)
			mat.roughness = 0.84
		"large_plant_leaf":
			mat.albedo_color = Color(0.12, 0.48, 0.28)
			mat.roughness = 0.76
		"mower_body":
			mat.albedo_color = Color(0.92, 0.24, 0.18)
			mat.roughness = 0.42
			mat.metallic = 0.18
		"mower_deck":
			mat.albedo_color = Color(0.98, 0.76, 0.16)
			mat.roughness = 0.48
			mat.metallic = 0.12
		"mower_dark":
			mat.albedo_color = Color(0.16, 0.18, 0.20)
			mat.roughness = 0.65
			mat.metallic = 0.25
		"mower_blade_ring":
			mat.albedo_color = Color(0.78, 0.84, 0.88)
			mat.roughness = 0.30
			mat.metallic = 0.65
		"mower_blade_ring_active":
			mat.albedo_color = Color(0.42, 0.98, 0.48)
			mat.roughness = 0.25
			mat.metallic = 0.35
		"clipping_particle":
			mat.albedo_color = Color(0.45, 0.88, 0.32)
			mat.roughness = 0.65
		_:
			mat.albedo_color = Color(0.5, 0.5, 0.5)
	return mat
