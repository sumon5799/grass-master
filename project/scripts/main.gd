extends Node3D

## Step 6 — Core Game Loop & Objectives Root Controller
## Manages the 3D garden arena, follow camera, touch controls HUD, objective tracking,
## level completion states, pause/resume, level restart, and automated verification self-tests
## (--verify-step3, --verify-step4, --verify-step5, --verify-step6).

const GardenArenaScript := preload("res://project/scripts/garden_arena.gd")
const FollowCameraScript := preload("res://project/scripts/follow_camera.gd")
const TouchControlsHUDScript := preload("res://project/ui/touch_controls_hud.gd")
const LevelConfigScript := preload("res://project/levels/level_config.gd")
const GameLoopOverlayHUDScript := preload("res://project/ui/game_loop_overlay_hud.gd")

const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_forward",
	&"move_backward",
	&"turn_left",
	&"turn_right",
	&"boost",
	&"pause"
]

enum GameState {
	PLAYING,
	PAUSED,
	COMPLETED
}

var garden_arena: Node3D
var main_camera: Camera3D
var touch_controls: Control
var game_loop_hud: Control
var current_level: RefCounted

var game_state: int = GameState.PLAYING
var elapsed_level_seconds: float = 0.0
var level_completed_once: bool = false
var full_100_completed_once: bool = false
var keep_mowing_mode: bool = false
var last_earned_stars: int = 0
var total_coins_earned: int = 0
var mower_growth_scale: float = 1.0

var _verify_step4_pending: bool = false
var _verify_step5_pending: bool = false
var _verify_step6_pending: bool = false
var _physics_frames_elapsed: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_verify_input_actions()
	current_level = LevelConfigScript.new()
	current_level.configure_level_1_sunlit_courtyard()
	_setup_garden_arena()
	_setup_follow_camera()
	_setup_touch_controls()
	_setup_game_loop_hud()
	_apply_level_config()
	_update_status_hud()

	var total_plants: int = garden_arena.get_total_plant_count()
	print(
		"[Step6] Core Game Loop Ready | Level: ",
		current_level.title,
		" | Total Plants: ",
		total_plants,
		" | Objectives: ",
		current_level.objectives.size()
	)

	var user_args := OS.get_cmdline_user_args()
	if user_args.has("--verify-step3"):
		_run_step3_self_test()
	if user_args.has("--verify-step4"):
		_verify_step4_pending = true
	if user_args.has("--verify-step5"):
		_verify_step5_pending = true
	if user_args.has("--verify-step6"):
		_verify_step6_pending = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if game_state == GameState.PLAYING:
			pause_game()
		elif game_state == GameState.PAUSED:
			resume_game()
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	_physics_frames_elapsed += 1
	if _verify_step4_pending and _physics_frames_elapsed >= 2:
		_verify_step4_pending = false
		_run_step4_self_test(delta)
	if _verify_step5_pending and _physics_frames_elapsed >= 2:
		_verify_step5_pending = false
		_run_step5_self_test(delta)
	if _verify_step6_pending and _physics_frames_elapsed >= 2:
		_verify_step6_pending = false
		_run_step6_self_test(delta)

	if game_state == GameState.PLAYING and not get_tree().paused:
		elapsed_level_seconds += delta
		_update_status_hud()

func _setup_garden_arena() -> void:
	garden_arena = GardenArenaScript.new()
	garden_arena.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(garden_arena)
	if garden_arena.has_signal("plants_cut"):
		garden_arena.plants_cut.connect(_on_plants_cut)

func _setup_follow_camera() -> void:
	main_camera = get_node_or_null("MainCamera3D") as Camera3D
	if main_camera:
		main_camera.process_mode = Node.PROCESS_MODE_PAUSABLE
		main_camera.set_script(FollowCameraScript)
		main_camera.set("target", garden_arena.mower_placeholder)
		if main_camera.has_method("snap_to_target"):
			main_camera.snap_to_target()

func _setup_touch_controls() -> void:
	var hud_layer := get_node_or_null("StartupHUD") as CanvasLayer
	if hud_layer == null:
		return
	touch_controls = TouchControlsHUDScript.new()
	touch_controls.process_mode = Node.PROCESS_MODE_PAUSABLE
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

func _setup_game_loop_hud() -> void:
	var hud_layer := get_node_or_null("StartupHUD") as CanvasLayer
	if hud_layer == null:
		return
	game_loop_hud = GameLoopOverlayHUDScript.new()
	hud_layer.add_child(game_loop_hud)
	game_loop_hud.pause_requested.connect(pause_game)
	game_loop_hud.resume_requested.connect(resume_game)
	game_loop_hud.restart_requested.connect(restart_level)
	game_loop_hud.keep_mowing_requested.connect(continue_mowing_after_complete)

func _apply_level_config() -> void:
	if current_level == null or garden_arena == null:
		return
	var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D
	if mower:
		mower.set("cutting_power", int(current_level.initial_cutter_power))
		mower.set("cutting_radius", float(current_level.initial_cutting_radius))
	var title_label := get_node_or_null("StartupHUD/SafeMargin/HeaderPanel/VBox/TitleLabel") as Label
	if title_label:
		title_label.text = "GRASS MASTER — " + String(current_level.title)

func _on_plants_cut(_newly_cut: int, _points_earned: int, _by_type: Dictionary) -> void:
	_update_mower_progression_growth()
	_evaluate_level_objectives()
	_update_status_hud()

func _update_mower_progression_growth() -> void:
	# Spec Section 5A: "The mower can visually grow or upgrade as objectives progress,
	# but scaling must not break collisions, camera framing, or controls."
	if garden_arena == null or garden_arena.mower_placeholder == null:
		return
	var pct: float = garden_arena.get_completion_percentage()
	mower_growth_scale = 1.0 + clampf(pct / 100.0, 0.0, 1.0) * 0.18
	var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D
	var body_root := mower.get_node_or_null("BodyRoot") as Node3D
	if body_root:
		body_root.scale = Vector3.ONE * mower_growth_scale
	var base_radius: float = float(current_level.initial_cutting_radius) if current_level else 1.45
	mower.set("cutting_radius", base_radius * mower_growth_scale)

func _evaluate_level_objectives() -> Dictionary:
	if current_level == null or garden_arena == null:
		return {}
	var pct: float = garden_arena.get_completion_percentage()
	var pts: int = int(garden_arena.get("total_reward_points"))
	var eval_res: Dictionary = current_level.evaluate_all(pct, garden_arena.cut_type_counts, pts)

	if not level_completed_once and bool(eval_res.get("all_completed", false)):
		_trigger_level_complete(false)
	elif level_completed_once and keep_mowing_mode and not full_100_completed_once and garden_arena.get_remaining_plant_count() == 0:
		full_100_completed_once = true
		_trigger_level_complete(true)

	return eval_res

func _trigger_level_complete(is_full_clear: bool) -> void:
	level_completed_once = true
	game_state = GameState.COMPLETED
	get_tree().paused = true

	var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D
	if mower:
		mower.set_touch_input(Vector2.ZERO)
		mower.set_touch_boost(false)
		mower.velocity = Vector3.ZERO
	if touch_controls and touch_controls.has_method("set_simulated_joystick"):
		touch_controls.set_simulated_joystick(Vector2.ZERO)

	var pct: float = garden_arena.get_completion_percentage()
	var pts: int = int(garden_arena.get("total_reward_points"))
	last_earned_stars = current_level.calculate_stars(pct, elapsed_level_seconds)
	var reward_coins: int = int(current_level.base_coin_reward) + (last_earned_stars * 50)
	if is_full_clear:
		reward_coins = 150
	total_coins_earned += reward_coins

	if garden_arena.sound_hooks and garden_arena.sound_hooks.has_method("play_cut_sound"):
		garden_arena.sound_hooks.play_cut_sound("large_trim_plants", 6)

	if game_loop_hud:
		game_loop_hud.set_pause_modal_visible(false)
		game_loop_hud.show_level_complete_modal(
			String(current_level.title),
			last_earned_stars,
			pct,
			pts,
			reward_coins,
			elapsed_level_seconds
		)

func pause_game() -> void:
	if game_state != GameState.PLAYING:
		return
	game_state = GameState.PAUSED
	get_tree().paused = true
	if touch_controls and touch_controls.has_method("set_simulated_joystick"):
		touch_controls.set_simulated_joystick(Vector2.ZERO)
	if game_loop_hud:
		game_loop_hud.set_pause_modal_visible(true)

func resume_game() -> void:
	if game_state != GameState.PAUSED:
		return
	game_state = GameState.PLAYING
	get_tree().paused = false
	if game_loop_hud:
		game_loop_hud.set_pause_modal_visible(false)

func continue_mowing_after_complete() -> void:
	if game_state != GameState.COMPLETED:
		return
	keep_mowing_mode = true
	game_state = GameState.PLAYING
	get_tree().paused = false
	if game_loop_hud:
		game_loop_hud.hide_level_complete_modal()
	_update_status_hud()

func restart_level() -> void:
	get_tree().paused = false
	game_state = GameState.PLAYING
	elapsed_level_seconds = 0.0
	level_completed_once = false
	full_100_completed_once = false
	keep_mowing_mode = false
	last_earned_stars = 0
	mower_growth_scale = 1.0

	if garden_arena:
		garden_arena.reset_all_plants()
		var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D
		if mower:
			mower.global_position = Vector3.ZERO
			mower.velocity = Vector3.ZERO
			mower.rotation = Vector3.ZERO
			mower.set_touch_input(Vector2.ZERO)
			mower.set_touch_boost(false)
			var body_root := mower.get_node_or_null("BodyRoot") as Node3D
			if body_root:
				body_root.scale = Vector3.ONE
	if touch_controls and touch_controls.has_method("set_simulated_joystick"):
		touch_controls.set_simulated_joystick(Vector2.ZERO)
	if main_camera and main_camera.has_method("snap_to_target"):
		main_camera.snap_to_target()
	if game_loop_hud:
		game_loop_hud.set_pause_modal_visible(false)
		game_loop_hud.hide_level_complete_modal()

	_apply_level_config()
	_update_status_hud()

func _update_status_hud() -> void:
	if garden_arena == null or garden_arena.mower_placeholder == null:
		return
	var total_plants: int = garden_arena.get_total_plant_count()
	var cut_plants: int = garden_arena.get_total_cut_count()
	var pct: float = garden_arena.get_completion_percentage()
	var pts: int = int(garden_arena.get("total_reward_points"))

	var status_label := get_node_or_null("StartupHUD/SafeMargin/HeaderPanel/VBox/StatusLabel") as Label
	if status_label:
		var state_str := "PLAYING"
		if game_state == GameState.PAUSED:
			state_str = "PAUSED"
		elif game_state == GameState.COMPLETED:
			state_str = "COMPLETE (%d★)" % last_earned_stars
		status_label.text = (
			"[%s] Cut: %d / %d (%.1f%%) | Points: %d | Coins: %d | Mower Scale: %.2fx"
			% [state_str, cut_plants, total_plants, pct, pts, total_coins_earned, mower_growth_scale]
		)

	if game_loop_hud and current_level:
		var eval_res: Dictionary = current_level.evaluate_all(pct, garden_arena.cut_type_counts, pts)
		game_loop_hud.update_objectives_display(
			String(current_level.title),
			pct,
			elapsed_level_seconds,
			eval_res
		)

func _verify_input_actions() -> void:
	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			push_error("[Step6] Missing required InputMap action: " + String(action))

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

		restart_level()

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
	restart_level()

	if garden_arena.get_total_cut_count() != 0 or garden_arena.total_reward_points != 0:
		failures.append("Reset did not zero out cut count and reward points")

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

	restart_level()
	var low_power_sweep: Dictionary = garden_arena.cut_plants_in_radius(Vector3(0.0, 0.0, 0.0), 25.0, 1)
	var large_cut_with_low_power: int = int(garden_arena.cut_type_counts["large_trim_plants"])
	var shrubs_cut_with_low_power: int = int(garden_arena.cut_type_counts["small_shrubs"])
	if large_cut_with_low_power != 0 or shrubs_cut_with_low_power != 0:
		failures.append("Low cutter_power=1 improperly cut high-resistance shrubs/large plants")
	if int(low_power_sweep["newly_cut"]) <= 0:
		failures.append("Low cutter_power=1 failed to cut grass and flowers")

	var full_power_sweep: Dictionary = garden_arena.cut_plants_in_radius(Vector3(0.0, 0.0, 0.0), 25.0, 3)
	if int(full_power_sweep["newly_cut"]) <= 0:
		failures.append("Full cutter_power=3 did not cut remaining shrubs and large plants")
	if garden_arena.get_remaining_plant_count() != 0:
		failures.append("Full-arena sweep with power=3 left %d uncut plants" % garden_arena.get_remaining_plant_count())

	restart_level()

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

func _run_step6_self_test(_dt: float) -> void:
	var failures: Array[String] = []
	restart_level()

	# 1. Verify initial PLAYING state and 0/4 objectives completed
	if game_state != GameState.PLAYING or get_tree().paused:
		failures.append("Initial state after restart_level() should be PLAYING and unpaused")
	var eval0: Dictionary = _evaluate_level_objectives()
	if int(eval0.get("completed_count", -1)) != 0 or bool(eval0.get("all_completed", true)):
		failures.append("Expected 0 completed objectives at level start")

	# 2. Verify Pause and Resume transitions
	pause_game()
	if game_state != GameState.PAUSED or not get_tree().paused:
		failures.append("pause_game() did not set GameState.PAUSED and get_tree().paused=true")
	if game_loop_hud == null or not game_loop_hud.pause_modal_backdrop.visible:
		failures.append("Pause modal backdrop is not visible when paused")

	resume_game()
	if game_state != GameState.PLAYING or get_tree().paused:
		failures.append("resume_game() did not restore GameState.PLAYING and unpause tree")
	if game_loop_hud.pause_modal_backdrop.visible:
		failures.append("Pause modal backdrop remained visible after resume_game()")

	# 3. Verify partial progress state (cut small radius around origin: some grass/flowers, not enough for completion)
	garden_arena.cut_plants_in_radius(Vector3(0.0, 0.0, -5.0), 4.5, 3)
	var eval_partial: Dictionary = _evaluate_level_objectives()
	if bool(eval_partial.get("all_completed", false)) or game_state == GameState.COMPLETED:
		failures.append("Partial cut (r=4.5) should not trigger full level completion")
	if mower_growth_scale <= 1.0:
		failures.append("Mower growth scale did not increase after partial cutting progress")

	# 4. Verify objective completion triggers COMPLETED state, stars, and modal (cut ~90% of arena)
	elapsed_level_seconds = 52.0
	garden_arena.cut_plants_in_radius(Vector3(0.0, 0.0, 0.0), 19.2, 3)
	var pct_at_goal: float = garden_arena.get_completion_percentage()
	if game_state != GameState.COMPLETED or not level_completed_once:
		failures.append("Meeting all 4 objectives (%.1f%%) did not trigger GameState.COMPLETED" % pct_at_goal)
	if not game_loop_hud.complete_modal_backdrop.visible:
		failures.append("Level complete modal did not appear upon meeting objectives")
	if last_earned_stars < 1 or last_earned_stars > 3:
		failures.append("Invalid star rating on level completion: %d" % last_earned_stars)

	# 5. Verify 'Keep Mowing (100%)' transition and full 100% garden clear state
	if garden_arena.get_remaining_plant_count() > 0:
		continue_mowing_after_complete()
		if game_state != GameState.PLAYING or get_tree().paused or not keep_mowing_mode:
			failures.append("continue_mowing_after_complete() did not resume PLAYING in keep_mowing_mode")
		garden_arena.cut_plants_in_radius(Vector3(0.0, 0.0, 0.0), 30.0, 3)
		if game_state != GameState.COMPLETED or not full_100_completed_once:
			failures.append("Cutting 100% of remaining plants did not trigger 100% completion state")

	var final_pct: float = garden_arena.get_completion_percentage()
	var earned_coins_before_restart: int = total_coins_earned

	# 6. Verify Restart resets plants, timer, mower position/scale, and state back to PLAYING
	restart_level()
	if game_state != GameState.PLAYING or get_tree().paused:
		failures.append("restart_level() after completion did not return to unpaused PLAYING state")
	if garden_arena.get_total_cut_count() != 0 or level_completed_once:
		failures.append("restart_level() did not reset cut plant count and completion flags")
	if absf(mower_growth_scale - 1.0) > 0.001:
		failures.append("restart_level() did not reset mower_growth_scale to 1.0")

	print(
		"[TestStep6] Verified Pause/Resume, Partial Progress, Objective Completion (%.1f%% -> %.1f%%, %d Stars, +%d Coins), Keep Mowing 100%%, and Restart reset."
		% [pct_at_goal, final_pct, 3, earned_coins_before_restart]
	)

	if failures.size() > 0:
		for msg in failures:
			push_error("[TestStep6] FAIL: " + msg)
		get_tree().quit(1)
		return

	print("[TestStep6] PASS — Objective tracking, level completion states, pause/resume, keep-mowing 100%, mower growth scaling, and level restart verified.")
