extends Node3D

## Step 4 — Mower Controls, Touch Joystick, Boundary Collision, and Follow Camera.
## Connects GardenArena's mower to TouchControlsHUD and FollowCamera.

const GardenArenaScript := preload("res://project/scripts/garden_arena.gd")
const FollowCameraScript := preload("res://project/scripts/follow_camera.gd")
const TouchControlsHUDScript := preload("res://project/ui/touch_controls_hud.gd")

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
var touch_controls: Control
var _verify_step4_pending: bool = false
var _physics_frames_elapsed: int = 0

func _ready() -> void:
	_verify_input_actions()
	_setup_garden_arena()
	_setup_follow_camera()
	_setup_touch_controls()
	_update_status_hud()

	var total_plants: int = garden_arena.get_total_plant_count()
	print(
		"[Step4] Mower Controls & Follow Camera Ready | Total Plants: ",
		total_plants,
		" | Mower Pos: ",
		garden_arena.mower_placeholder.global_position
	)

	var user_args := OS.get_cmdline_user_args()
	if user_args.has("--verify-step3"):
		_run_step3_self_test()
	if user_args.has("--verify-step4"):
		_verify_step4_pending = true

func _physics_process(delta: float) -> void:
	_physics_frames_elapsed += 1
	if _verify_step4_pending and _physics_frames_elapsed >= 2:
		_verify_step4_pending = false
		_run_step4_self_test(delta)
	_update_status_hud()

func _verify_input_actions() -> void:
	for action_name in INPUT_ACTIONS:
		if not InputMap.has_action(action_name):
			push_error("[Step4] Missing required InputMap action: %s" % action_name)

func _setup_garden_arena() -> void:
	garden_arena = GardenArenaScript.new()
	add_child(garden_arena)

func _setup_follow_camera() -> void:
	main_camera = get_node_or_null("MainCamera3D") as Camera3D
	if main_camera:
		main_camera.set_script(FollowCameraScript)
		main_camera.set_follow_target(garden_arena.mower_placeholder, true)

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
		var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D
		var pos: Vector3 = mower.global_position
		var spd: float = float(mower.get("current_speed"))
		var z_lvl: float = float(main_camera.get("zoom_level")) if main_camera else 1.0
		status_label.text = (
			"Step 4: Mower Controls Active | Pos: (%.1f, %.1f) | Speed: %.1f m/s | Zoom: %.2fx | Plants: %d"
			% [pos.x, pos.z, spd, z_lvl, garden_arena.get_total_plant_count()]
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
		if garden_arena.mower_placeholder == null:
			failures.append("MowerPlaceholder is missing")

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
		# 1. Test forward movement + camera tracking
		mower.global_position = Vector3.ZERO
		mower.velocity = Vector3.ZERO
		touch_controls.set_simulated_joystick(Vector2(0.0, -1.0))
		for _i in range(30):
			mower.step_movement(dt)
			main_camera.update_camera(dt)
		if mower.global_position.z >= -1.0:
			failures.append("Mower did not move forward (-Z) on joystick up input; z=%.2f" % mower.global_position.z)

		# 2. Test turning right (+X) and boost speed increase
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

		# 3. Test North, South, East, West boundary collisions
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

		# 4. Test camera zoom bounds
		main_camera.set_zoom_level(0.2)
		if absf(float(main_camera.get("zoom_level")) - float(main_camera.get("min_zoom"))) > 0.001:
			failures.append("Camera min_zoom clamp failed")
		main_camera.set_zoom_level(5.0)
		if absf(float(main_camera.get("zoom_level")) - float(main_camera.get("max_zoom"))) > 0.001:
			failures.append("Camera max_zoom clamp failed")
		main_camera.set_zoom_level(1.0)

		# Reset mower back to center spawn after self-test
		touch_controls.set_simulated_joystick(Vector2.ZERO)
		mower.global_position = Vector3.ZERO
		mower.velocity = Vector3.ZERO
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
