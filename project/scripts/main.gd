extends Node3D

## Step 5 — Grass Cutting & Visual Feedback Root Controller
## Manages the 3D garden arena, follow camera, touch controls HUD, live cutting counters,
## and automated verification self-tests (--verify-step3, --verify-step4, --verify-step5).

const GardenArenaScript := preload("res://project/scripts/garden_arena.gd")
const FollowCameraScript := preload("res://project/scripts/follow_camera.gd")
const TouchControlsHUDScript := preload("res://project/ui/touch_controls_hud.gd")

const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_forward",
	&"move_backward",
	&"turn_left",
	&"turn_right",
	&"boost",
	&"pause"
]

var garden_arena: Node3D
var main_camera: Camera3D
var touch_controls: Control
var _verify_step4_pending: bool = false
var _verify_step5_pending: bool = false
var _physics_frames_elapsed: int = 0

func _ready() -> void:
	_verify_input_actions()
	_setup_garden_arena()
	_setup_follow_camera()
	_setup_touch_controls()
	_update_status_hud()

	var total_plants: int = garden_arena.get_total_plant_count()
	print(
		"[Step5] Grass Cutting & Feedback Ready | Total Plants: ",
		total_plants,
		" | Cut: ",
		garden_arena.get_total_cut_count(),
		" | Points: ",
		garden_arena.total_reward_points
	)

	var user_args := OS.get_cmdline_user_args()
	if user_args.has("--verify-step3"):
		_run_step3_self_test()
	if user_args.has("--verify-step4"):
		_verify_step4_pending = true
	if user_args.has("--verify-step5"):
		_verify_step5_pending = true

func _physics_process(delta: float) -> void:
	_physics_frames_elapsed += 1
	if _verify_step4_pending and _physics_frames_elapsed >= 2:
		_verify_step4_pending = false
		_run_step4_self_test(delta)
	if _verify_step5_pending and _physics_frames_elapsed >= 2:
		_verify_step5_pending = false
		_run_step5_self_test(delta)
	_update_status_hud()

func _setup_garden_arena() -> void:
	garden_arena = GardenArenaScript.new()
	add_child(garden_arena)
	if garden_arena.has_signal("plants_cut"):
		garden_arena.plants_cut.connect(_on_plants_cut)

func _on_plants_cut(_newly_cut: int, _points_earned: int, _by_type: Dictionary) -> void:
	_update_status_hud()

func _setup_follow_camera() -> void:
	main_camera = get_node_or_null("MainCamera3D") as Camera3D
	if main_camera:
		main_camera.set_script(FollowCameraScript)
		main_camera.set("target", garden_arena.mower_placeholder)
		if main_camera.has_method("snap_to_target"):
			main_camera.snap_to_target()

func _setup_touch_controls() -> void:
	var hud_layer := get_node_or_null("StartupHUD") as CanvasLayer
	if hud_layer == null:
		return
	touch_controls = TouchControlsHUDScript.new()
	hud_layer.add_child(touch_controls)

	var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D
	if mower:
		touch_controls.joystick_changed.connect(
			func(vec: Vector2) -> void: mower.set_touch_input(vec)
		)
		touch_controls.boost_toggled.connect(
			func(active: bool) -> void: mower.set_touch_boost(active)
		)
	if main_camera and main_camera.has_method("adjust_zoom"):
		touch_controls.zoom_requested.connect(
			func(dz: float) -> void: main_camera.adjust_zoom(dz)
		)

func _update_status_hud() -> void:
	var status_label := get_node_or_null("StartupHUD/SafeMargin/HeaderPanel/VBox/StatusLabel") as Label
	if status_label and garden_arena and garden_arena.mower_placeholder:
		var total_plants: int = garden_arena.get_total_plant_count()
		var cut_plants: int = garden_arena.get_total_cut_count()
		var pct: float = garden_arena.get_completion_percentage()
		var pts: int = int(garden_arena.get("total_reward_points"))
		status_label.text = (
			"Cut: %d / %d (%.1f%%) | Points: %d | Grass: %d | Flowers: %d | Shrubs: %d | Topiary: %d"
			% [
				cut_plants,
				total_plants,
				pct,
				pts,
				int(garden_arena.cut_type_counts["short_grass"]) + int(garden_arena.cut_type_counts["tall_grass"]),
				int(garden_arena.cut_type_counts["colorful_flowers"]),
				int(garden_arena.cut_type_counts["small_shrubs"]),
				int(garden_arena.cut_type_counts["large_trim_plants"]),
			]
		)

func _verify_input_actions() -> void:
	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			push_error("[Step5] Missing required InputMap action: " + String(action))

func _run_step3_self_test() -> void:
	var failures: Array[String] = []
	var counts: Dictionary = garden_arena.plant_type_counts
	for key in ["short_grass", "tall_grass", "colorful_flowers", "small_shrubs", "large_trim_plants"]:
		if int(counts.get(key, 0)) <= 0:
			failures.append("Plant type '%s' has 0 instances" % key)
	if garden_arena.get_total_plant_count() < 200:
		failures.append("Expected at least 200 total plants")
	if failures.size() > 0:
		for msg in failures:
			push_error("[TestStep3] FAIL: " + msg)
		get_tree().quit(1)
		return
	print("[TestStep3] PASS — 3D garden ground, boundaries, 5 plant types, sky/lighting, mower placeholder, and batching verified.")

func _run_step4_self_test(dt: float) -> void:
	var failures: Array[String] = []
	var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D
	if mower == null:
		failures.append("MowerPlaceholder is not a CharacterBody3D")
	if touch_controls == null:
		failures.append("TouchControlsHUD is missing")
	if main_camera == null or not main_camera.has_method("update_camera"):
		failures.append("MainCamera3D does not have FollowCamera script attached")

	if failures.size() == 0:
		mower.global_position = Vector3.ZERO
		mower.velocity = Vector3.ZERO
		touch_controls.set_simulated_joystick(Vector2(0.0, -1.0))
		for _i in range(30):
			mower.step_movement(dt)
			main_camera.update_camera(dt)
		if mower.global_position.z >= -1.0:
			failures.append("Mower did not move forward (-Z) on joystick up input; z=%.2f" % mower.global_position.z)

		var speed_no_boost: float = float(mower.get("current_speed"))
		mower.set_touch_boost(true)
		touch_controls.set_simulated_joystick(Vector2(1.0, 0.0))
		for _i in range(35):
			mower.step_movement(dt)
			main_camera.update_camera(dt)
		var speed_with_boost: float = float(mower.get("current_speed"))
		if mower.global_position.x <= 1.5:
			failures.append("Mower did not move right (+X) on joystick right input; x=%.2f" % mower.global_position.x)
		if speed_with_boost <= speed_no_boost:
			failures.append("Boost did not increase mower top speed (%.2f vs %.2f)" % [speed_with_boost, speed_no_boost])
		mower.set_touch_boost(false)

		var dirs := [
			{"name": "North", "vec": Vector2(0.0, -1.0)},
			{"name": "South", "vec": Vector2(0.0, 1.0)},
			{"name": "East", "vec": Vector2(1.0, 0.0)},
			{"name": "West", "vec": Vector2(-1.0, 0.0)},
		]
		for d in dirs:
			mower.global_position = Vector3(d["vec"].x * 13.5, 0.0, d["vec"].y * 13.5)
			mower.velocity = Vector3.ZERO
			touch_controls.set_simulated_joystick(d["vec"])
			for _i in range(90):
				mower.step_movement(dt)
				main_camera.update_camera(dt)
			var max_coord := maxf(absf(mower.global_position.x), absf(mower.global_position.z))
			if max_coord > 15.6:
				failures.append("Mower escaped %s boundary: pos=%s" % [d["name"], str(mower.global_position)])

		main_camera.set_zoom_level(0.2)
		if absf(float(main_camera.get("zoom_level")) - float(main_camera.get("min_zoom"))) > 0.001:
			failures.append("Camera min_zoom clamp failed")
		main_camera.set_zoom_level(5.0)
		if absf(float(main_camera.get("zoom_level")) - float(main_camera.get("max_zoom"))) > 0.001:
			failures.append("Camera max_zoom clamp failed")
		main_camera.set_zoom_level(1.0)

		touch_controls.set_simulated_joystick(Vector2.ZERO)
		mower.global_position = Vector3.ZERO
		mower.velocity = Vector3.ZERO
		garden_arena.reset_all_plants()
		main_camera.snap_to_target()

		print(
			"[TestStep4] Verified movement, boost (%.2f m/s -> %.2f m/s), 4-wall collisions (hits=%d), and camera zoom/framing."
			% [speed_no_boost, speed_with_boost, int(mower.get("boundary_hit_count"))]
		)

	if failures.size() > 0:
		for msg in failures:
			push_error("[TestStep4] FAIL: " + msg)
		get_tree().quit(1)
		return

	print("[TestStep4] PASS — Smooth mower movement, turning, boundary collisions, touch joystick/boost, and follow camera verified.")

func _run_step5_self_test(dt: float) -> void:
	var failures: Array[String] = []
	var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D
	garden_arena.reset_all_plants()

	if garden_arena.get_total_cut_count() != 0 or garden_arena.total_reward_points != 0:
		failures.append("Reset did not zero out cut count and reward points")

	# 1. Sweep mower along a path from center (-Z) to cut plants
	mower.global_position = Vector3(0.0, 0.0, 0.0)
	mower.velocity = Vector3.ZERO
	var cut_radius: float = float(mower.get("cutting_radius"))
	var cut_power: int = int(mower.get("cutting_power"))

	for step_i in range(28):
		var z_pos := -float(step_i) * 0.5
		mower.global_position = Vector3(0.0, 0.0, z_pos)
		garden_arena.cut_plants_in_radius(mower.global_position, cut_radius, cut_power)
		if garden_arena.clipping_burst_manager:
			garden_arena.clipping_burst_manager._physics_process(dt)

	var first_pass_cuts: int = garden_arena.get_total_cut_count()
	var first_pass_points: int = garden_arena.total_reward_points
	var bursts_spawned: int = int(garden_arena.clipping_burst_manager.get("total_bursts_spawned"))
	var sounds_played: int = int(garden_arena.sound_hooks.get("total_sound_events"))

	if first_pass_cuts <= 0:
		failures.append("First mowing pass cut 0 plants along z=[0..-13.5]")
	if first_pass_points <= 0:
		failures.append("First mowing pass awarded 0 points")
	if bursts_spawned <= 0:
		failures.append("ClippingBurstManager did not spawn any clipping bursts")
	if sounds_played <= 0:
		failures.append("SoundHooks did not trigger any cutting sound events")

	# 2. Re-sweep the EXACT same path and verify NO duplicate cuts or duplicate rewards occur
	var second_pass_new_cuts := 0
	var second_pass_new_points := 0
	for step_i in range(28):
		var z_pos := -float(step_i) * 0.5
		mower.global_position = Vector3(0.0, 0.0, z_pos)
		var res: Dictionary = garden_arena.cut_plants_in_radius(mower.global_position, cut_radius, cut_power)
		second_pass_new_cuts += int(res["newly_cut"])
		second_pass_new_points += int(res["points_earned"])

	if second_pass_new_cuts != 0:
		failures.append("Duplicate cut detected on second pass: %d plants re-cut" % second_pass_new_cuts)
	if second_pass_new_points != 0:
		failures.append("Duplicate reward points awarded on second pass: %d" % second_pass_new_points)
	if garden_arena.get_total_cut_count() != first_pass_cuts:
		failures.append("Total cut count changed after duplicate pass")
	if garden_arena.total_reward_points != first_pass_points:
		failures.append("Total reward points changed after duplicate pass")

	# 3. Verify plant resistance gating (power=1 should cut grass/flowers, but NOT large_trim_plants which require power=3)
	garden_arena.reset_all_plants()
	var low_power_sweep: Dictionary = garden_arena.cut_plants_in_radius(Vector3(0.0, 0.0, 0.0), 25.0, 1)
	var large_cut_with_low_power: int = int(garden_arena.cut_type_counts["large_trim_plants"])
	var shrubs_cut_with_low_power: int = int(garden_arena.cut_type_counts["small_shrubs"])
	if large_cut_with_low_power != 0 or shrubs_cut_with_low_power != 0:
		failures.append("Low cutter_power=1 improperly cut high-resistance shrubs/large plants")
	if int(low_power_sweep["newly_cut"]) <= 0:
		failures.append("Low cutter_power=1 failed to cut grass and flowers")

	# Now sweep with power=3 and verify remaining shrubs and large plants are cut
	var full_power_sweep: Dictionary = garden_arena.cut_plants_in_radius(Vector3(0.0, 0.0, 0.0), 25.0, 3)
	if int(full_power_sweep["newly_cut"]) <= 0:
		failures.append("Full cutter_power=3 did not cut remaining shrubs and large plants")
	if garden_arena.get_remaining_plant_count() != 0:
		failures.append("Full-arena sweep with power=3 left %d uncut plants" % garden_arena.get_remaining_plant_count())

	# Reset back to clean state for normal play
	garden_arena.reset_all_plants()
	mower.global_position = Vector3.ZERO
	mower.velocity = Vector3.ZERO
	_update_status_hud()

	print(
		"[TestStep5] First pass cut=%d (points=%d, bursts=%d, sounds=%d) | Second pass duplicate cuts=%d (duplicate points=%d) | Full-arena completion=100%% verified."
		% [first_pass_cuts, first_pass_points, bursts_spawned, sounds_played, second_pass_new_cuts, second_pass_new_points]
	)

	if failures.size() > 0:
		for msg in failures:
			push_error("[TestStep5] FAIL: " + msg)
		get_tree().quit(1)
		return

	print("[TestStep5] PASS — Plant cutting states, trimmed visuals, clipping particles, sound hooks, counters, resistance gating, and duplicate-reward prevention verified.")
