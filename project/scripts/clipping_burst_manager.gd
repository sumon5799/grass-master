extends Node3D
class_name ClippingBurstManager

## Pooled 3D clipping burst visual effect for Step 5.
## Spawns flying grass/petal/leaf cubes that arc upward and fade down when plants are cut.
## Uses a fixed-size pool of MultiMesh instances so zero nodes are allocated during gameplay.

const GardenMaterialsScript := preload("res://project/materials/garden_materials.gd")

const MAX_PARTICLES: int = 96
const PARTICLE_LIFETIME: float = 0.55
const GRAVITY: float = 11.5

var _mm_inst: MultiMeshInstance3D
var _multimesh: MultiMesh
var _positions: PackedVector3Array = PackedVector3Array()
var _velocities: PackedVector3Array = PackedVector3Array()
var _timers: PackedFloat32Array = PackedFloat32Array()
var _scales: PackedFloat32Array = PackedFloat32Array()
var _cursor: int = 0
var _rng := RandomNumberGenerator.new()
var total_bursts_spawned: int = 0

func _ready() -> void:
	name = "ClippingBurstManager"
	_rng.seed = 20261016
	_positions.resize(MAX_PARTICLES)
	_velocities.resize(MAX_PARTICLES)
	_timers.resize(MAX_PARTICLES)
	_scales.resize(MAX_PARTICLES)

	_mm_inst = MultiMeshInstance3D.new()
	_mm_inst.name = "ClippingParticlesMultiMesh"
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.instance_count = MAX_PARTICLES
	var chip_mesh := BoxMesh.new()
	chip_mesh.size = Vector3(0.14, 0.06, 0.18)
	_multimesh.mesh = chip_mesh

	var hidden_xform := Transform3D(Basis.IDENTITY.scaled(Vector3(0.001, 0.001, 0.001)), Vector3(0.0, -20.0, 0.0))
	for i in range(MAX_PARTICLES):
		_timers[i] = 0.0
		_scales[i] = 1.0
		_multimesh.set_instance_transform(i, hidden_xform)

	_mm_inst.multimesh = _multimesh
	_mm_inst.material_override = GardenMaterialsScript.get_material("clipping_particle")
	add_child(_mm_inst)

func spawn_clipping_burst(world_pos: Vector3, chip_count: int = 5) -> void:
	total_bursts_spawned += 1
	var count := clampi(chip_count, 2, 10)
	for _i in range(count):
		var idx := _cursor
		_cursor = (_cursor + 1) % MAX_PARTICLES
		_positions[idx] = world_pos + Vector3(
			_rng.randf_range(-0.22, 0.22),
			_rng.randf_range(0.18, 0.42),
			_rng.randf_range(-0.22, 0.22)
		)
		var angle := _rng.randf_range(0.0, TAU)
		var speed := _rng.randf_range(1.4, 3.6)
		_velocities[idx] = Vector3(
			cos(angle) * speed,
			_rng.randf_range(2.6, 4.8),
			sin(angle) * speed
		)
		_timers[idx] = PARTICLE_LIFETIME
		_scales[idx] = _rng.randf_range(0.75, 1.30)

func _physics_process(delta: float) -> void:
	if _multimesh == null:
		return
	var hidden_xform := Transform3D(Basis.IDENTITY.scaled(Vector3(0.001, 0.001, 0.001)), Vector3(0.0, -20.0, 0.0))
	for i in range(MAX_PARTICLES):
		var t := _timers[i]
		if t <= 0.0:
			continue
		t -= delta
		_timers[i] = t
		if t <= 0.0:
			_multimesh.set_instance_transform(i, hidden_xform)
			continue
		var vel := _velocities[i]
		vel.y -= GRAVITY * delta
		_velocities[i] = vel
		var pos := _positions[i] + vel * delta
		if pos.y < 0.04:
			pos.y = 0.04
		_positions[i] = pos
		var life_ratio := clampf(t / PARTICLE_LIFETIME, 0.15, 1.0)
		var s := _scales[i] * life_ratio
		var basis := Basis.from_euler(Vector3(t * 7.0, float(i) * 0.9 + t * 5.0, t * 4.0)).scaled(Vector3(s, s, s))
		_multimesh.set_instance_transform(i, Transform3D(basis, pos))
