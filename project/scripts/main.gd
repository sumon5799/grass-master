extends Node3D

## Step 3 — First Playable 3D Garden Scene Controller.
## Sets up sunlit sky environment, directional sun + fill lighting, isometric follow camera,
## and instantiates the procedural low-poly GardenArena.

const GardenArenaScript := preload("res://project/scripts/garden_arena.gd")

const INPUT_ACTIONS: Array[String] = [
	"move_forward",
	"move_backward",
	"turn_left",
	"turn_right",
	"boost",
	"pause",
]

var garden_arena: Node3D
var main_camera: Camera3D

func _ready() -> void:
	_verify_input_actions()
	_setup_garden_arena()
	_setup_camera_framing()
	_update_status_hud()

	var total_plants: int = garden_arena.get_total_plant_count()
	print(
		"[Step3] First 3D Garden Ready | Total Plants: ",
		total_plants,
		" | Types: ",
		garden_arena.plant_type_counts
	)

	if OS.get_cmdline_user_args().has("--verify-step3"):
		_run_step3_self_test()

func _verify_input_actions() -> void:
	for action_name in INPUT_ACTIONS:
		if not InputMap.has_action(action_name):
			push_error("[Step3] Missing required InputMap action: %s" % action_name)

func _setup_garden_arena() -> void:
	garden_arena = GardenArenaScript.new()
	add_child(garden_arena)

func _setup_camera_framing() -> void:
	main_camera = get_node_or_null("MainCamera3D") as Camera3D
	if main_camera and garden_arena and garden_arena.mower_placeholder:
		var target_pos: Vector3 = garden_arena.mower_placeholder.global_position
		main_camera.global_position = target_pos + Vector3(0.0, 13.5, 13.0)
		main_camera.look_at(target_pos + Vector3(0.0, 0.4, -1.2), Vector3.UP)

func _update_status_hud() -> void:
	var status_label := get_node_or_null("StartupHUD/SafeMargin/HeaderPanel/VBox/StatusLabel") as Label
	if status_label and garden_arena:
		var counts: Dictionary = garden_arena.plant_type_counts
		status_label.text = (
			"Step 3: 3D Garden Ready | %d Plants (Grass: %d, Tall: %d, Flowers: %d, Shrubs: %d, Topiary: %d)"
			% [
				garden_arena.get_total_plant_count(),
				int(counts["short_grass"]),
				int(counts["tall_grass"]),
				int(counts["colorful_flowers"]),
				int(counts["small_shrubs"]),
				int(counts["large_trim_plants"]),
			]
		)

func _run_step3_self_test() -> void:
	var failures: Array[String] = []
	var env_node := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env_node == null or env_node.environment == null or env_node.environment.sky == null:
		failures.append("WorldEnvironment or procedural Sky is missing")

	var sun_node := get_node_or_null("SunLight3D") as DirectionalLight3D
	if sun_node == null:
		failures.append("SunLight3D is missing")

	if main_camera == null or not main_camera.current:
		failures.append("MainCamera3D is missing or not active")

	if garden_arena == null:
		failures.append("GardenArena is missing")
	else:
		if garden_arena.ground_body == null:
			failures.append("GardenArena.ground_body is missing")
		if garden_arena.boundary_body == null:
			failures.append("GardenArena.boundary_body is missing")
		else:
			for wall_name in ["WallNorth", "WallSouth", "WallWest", "WallEast"]:
				if garden_arena.boundary_body.get_node_or_null(wall_name) == null:
					failures.append("Missing boundary collision wall: %s" % wall_name)

		if garden_arena.mower_placeholder == null:
			failures.append("MowerPlaceholder is missing")
		elif garden_arena.mower_placeholder.get_node_or_null("BodyRoot/CuttingDeck") == null:
			failures.append("MowerPlaceholder CuttingDeck mesh is missing")

		var counts: Dictionary = garden_arena.plant_type_counts
		for ptype in ["short_grass", "tall_grass", "colorful_flowers", "small_shrubs", "large_trim_plants"]:
			if int(counts.get(ptype, 0)) <= 0:
				failures.append("Plant type '%s' has count 0" % ptype)

		var total_plants: int = garden_arena.get_total_plant_count()
		var multimesh_batches: int = garden_arena.vegetation_root.get_child_count()
		if total_plants < 100:
			failures.append("Expected at least 100 plants, got %d" % total_plants)
		if multimesh_batches <= 0 or multimesh_batches > 12:
			failures.append("Unexpected MultiMesh batch count: %d" % multimesh_batches)

		print(
			"[TestStep3] Garden Stats -> Total plants: %d | MultiMesh batches: %d | Counts: %s"
			% [total_plants, multimesh_batches, str(counts)]
		)

	if failures.size() > 0:
		for msg in failures:
			push_error("[TestStep3] FAIL: " + msg)
		get_tree().quit(1)
		return

	print("[TestStep3] PASS — 3D garden ground, boundaries, 5 plant types, sky/lighting, mower placeholder, and batching verified.")
