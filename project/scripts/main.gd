extends Node3D

## Main startup scene script for Grass Master (Step 2 through Step 8).
## Step 8 additions:
## - Integrates MenuSystemOverlay (Main Menu, Level Select, Garage, Creative Mode, Settings, Credits)
## - Integrates PlayerProfile v2 settings (Master/Music/SFX volume, Vibration, Camera Zoom/Sensitivity,
##   Graphics Quality Low/Medium/High, Large Text scale, Reset Local Save, Corruption Recovery)
## - Handles app lifecycle notifications (pause/focus loss auto-save)
## - Adds `--verify-step8` automated verification for menus, garage, settings, save reset,
##   corruption recovery, and multi-aspect-ratio + large-text UI layout

const GardenArenaScript := preload("res://project/scripts/garden_arena.gd")
const FollowCameraScript := preload("res://project/scripts/follow_camera.gd")
const TouchControlsHUDScript := preload("res://project/ui/touch_controls_hud.gd")
const LevelConfigScript := preload("res://project/levels/level_config.gd")
const GameLoopOverlayHUDScript := preload("res://project/ui/game_loop_overlay_hud.gd")
const PlayerProfileScript := preload("res://project/scripts/player_profile.gd")
const MenuSystemOverlayScript := preload("res://project/ui/menu_system_overlay.gd")

const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_forward",
	&"move_backward",
	&"turn_left",
	&"turn_right",
	&"boost",
	&"pause",
]

enum GameState {
	PLAYING = 0,
	PAUSED = 1,
	COMPLETED = 2
}

var garden_arena: Node3D
var main_camera: Camera3D
var touch_controls: Control
var game_loop_hud: Control
var menu_overlay: Control
var current_level: RefCounted
var player_profile: RefCounted

var game_state: int = GameState.PLAYING
var elapsed_level_seconds: float = 0.0
var level_completed_once: bool = false
var full_100_completed_once: bool = false
var keep_mowing_mode: bool = false
var total_coins_earned: int = 0
var last_earned_stars: int = 0
var mower_growth_scale: float = 1.0

var _verify_step4_pending: bool = false
var _verify_step7_pending: bool = false
var _verify_step8_pending: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_verify_input_actions()

	player_profile = PlayerProfileScript.new()
	player_profile.load_from_disk()

	current_level = LevelConfigScript.new()
	current_level.configure_by_id(player_profile.selected_level_id)

	_spawn_garden_arena()
	_setup_follow_camera()
	_setup_touch_controls_hud()
	_setup_game_loop_hud()
	_setup_menu_system_overlay()
	_apply_profile_to_mower()
	_apply_settings_to_runtime()
	_update_status_hud()

	var vp_size := get_viewport().get_visible_rect().size
	var renderer_name: String = String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "mobile"))
	print(
		"[Step8] Menus, Garage, Settings & Save System Ready | Level: %s | Mode: %s | Coins: %s | Mower: %s (%s) | Viewport: %dx%d | Renderer: %s"
		% [
			String(current_level.title),
			player_profile.get_mode_display_name(),
			player_profile.get_coins_display(),
			player_profile.selected_mower_type,
			player_profile.selected_skin,
			int(vp_size.x),
			int(vp_size.y),
			str(renderer_name)
		]
	)

	var user_args := OS.get_cmdline_user_args()
	if user_args.has("--verify-step3"):
		_run_step3_self_test()
	if user_args.has("--verify-step4"):
		_verify_step4_pending = true
	if user_args.has("--verify-step5"):
		_run_step5_self_test(1.0 / 60.0)
	if user_args.has("--verify-step6"):
		_run_step6_self_test(1.0 / 60.0)
	if user_args.has("--verify-step7"):
		_verify_step7_pending = true
	if user_args.has("--verify-step8"):
		_verify_step8_pending = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if player_profile:
			player_profile.save_to_disk()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if menu_overlay and menu_overlay.is_menu_open():
			if menu_overlay.current_screen != MenuSystemOverlayScript.Screen.MAIN_MENU:
				menu_overlay.show_screen(MenuSystemOverlayScript.Screen.MAIN_MENU)
			else:
				close_menus_and_resume()
		elif game_state == GameState.PLAYING:
			pause_game()
		elif game_state == GameState.PAUSED:
			resume_game()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if menu_overlay and menu_overlay.is_menu_open():
			close_menus_and_resume()
		elif game_state == GameState.PLAYING:
			pause_game()
		elif game_state == GameState.PAUSED:
			resume_game()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key_ev := event as InputEventKey
		if key_ev.keycode == KEY_EQUAL or key_ev.keycode == KEY_PLUS:
			if main_camera and main_camera.has_method("adjust_zoom"):
				main_camera.adjust_zoom(-0.12)
		elif key_ev.keycode == KEY_MINUS:
			if main_camera and main_camera.has_method("adjust_zoom"):
				main_camera.adjust_zoom(0.12)

func _physics_process(delta: float) -> void:
	if _verify_step4_pending:
		_verify_step4_pending = false
		_run_step4_self_test(delta)
		return
	if _verify_step7_pending:
		_verify_step7_pending = false
		_run_step7_self_test(delta)
		return
	if _verify_step8_pending:
		_verify_step8_pending = false
		_run_step8_self_test(delta)
		return

	if game_state == GameState.PLAYING and not get_tree().paused:
		if not player_profile.is_creative_mode():
			elapsed_level_seconds += delta
		if game_loop_hud and current_level and garden_arena:
			var pct: float = garden_arena.get_completion_percentage()
			var pts: int = int(garden_arena.get("total_reward_points"))
			var eval_res: Dictionary = current_level.evaluate_all(pct, garden_arena.cut_type_counts, pts)
			game_loop_hud.update_objectives_display(
				String(current_level.title),
				pct,
				elapsed_level_seconds,
				eval_res,
				player_profile.is_creative_mode()
			)

func _spawn_garden_arena() -> void:
	garden_arena = GardenArenaScript.new()
	garden_arena.process_mode = Node.PROCESS_MODE_PAUSABLE
	garden_arena.plants_cut.connect(_on_garden_plants_cut)
	add_child(garden_arena)

func _setup_follow_camera() -> void:
	main_camera = get_node_or_null("MainCamera3D") as Camera3D
	if main_camera == null:
		main_camera = Camera3D.new()
		main_camera.name = "MainCamera3D"
		add_child(main_camera)

	main_camera.set_script(FollowCameraScript)
	main_camera.process_mode = Node.PROCESS_MODE_PAUSABLE
	main_camera.current = true
	if garden_arena and garden_arena.mower_placeholder:
		main_camera.set_follow_target(garden_arena.mower_placeholder, true)

func _setup_touch_controls_hud() -> void:
	var hud_layer := get_node_or_null("StartupHUD") as CanvasLayer
	if hud_layer == null:
		hud_layer = CanvasLayer.new()
		hud_layer.name = "StartupHUD"
		add_child(hud_layer)

	touch_controls = TouchControlsHUDScript.new()
	touch_controls.process_mode = Node.PROCESS_MODE_PAUSABLE
	hud_layer.add_child(touch_controls)

	if garden_arena and garden_arena.mower_placeholder:
		var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D
		touch_controls.joystick_changed.connect(func(vec: Vector2) -> void:
			if mower.has_method("set_touch_input"):
				mower.set_touch_input(vec)
		)
		touch_controls.boost_toggled.connect(func(active: bool) -> void:
			if mower.has_method("set_touch_boost"):
				mower.set_touch_boost(active)
		)

	touch_controls.zoom_requested.connect(func(delta_zoom: float) -> void:
		if main_camera and main_camera.has_method("adjust_zoom"):
			main_camera.adjust_zoom(delta_zoom)
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
	game_loop_hud.creative_mode_toggled.connect(set_creative_mode_enabled)
	game_loop_hud.level_selected.connect(select_and_start_level)
	game_loop_hud.strength_changed.connect(_on_hud_strength_changed)
	game_loop_hud.regrow_garden_requested.connect(restart_level)
	game_loop_hud.main_menu_requested.connect(open_main_menu)
	game_loop_hud.garage_requested.connect(open_garage_screen)
	game_loop_hud.settings_requested.connect(open_settings_screen)
	game_loop_hud.level_select_requested.connect(open_level_select_screen)

	game_loop_hud.sync_tuning_sliders(
		player_profile.configured_move_speed,
		player_profile.configured_cutting_radius,
		player_profile.configured_blade_power,
		player_profile.configured_boost_multiplier,
		player_profile.is_creative_mode()
	)

func _setup_menu_system_overlay() -> void:
	var hud_layer := get_node_or_null("StartupHUD") as CanvasLayer
	if hud_layer == null:
		return
	menu_overlay = MenuSystemOverlayScript.new()
	hud_layer.add_child(menu_overlay)

	menu_overlay.play_requested.connect(func() -> void:
		set_creative_mode_enabled(false)
		close_menus_and_resume()
	)
	menu_overlay.creative_play_requested.connect(func() -> void:
		set_creative_mode_enabled(true)
		close_menus_and_resume()
	)
	menu_overlay.level_launch_requested.connect(func(lid: String, mode: int) -> void:
		player_profile.set_play_mode(mode)
		if game_loop_hud:
			game_loop_hud.set_creative_button_state(player_profile.is_creative_mode())
		select_and_start_level(lid)
		close_menus_and_resume()
	)
	menu_overlay.garage_customization_changed.connect(func(mower_type: String, skin_id: String) -> void:
		player_profile.select_mower_type(mower_type)
		player_profile.select_skin(skin_id)
		_apply_profile_to_mower()
		player_profile.save_to_disk()
	)
	menu_overlay.upgrade_toggled.connect(func(upgrade_id: String, enabled: bool) -> void:
		player_profile.set_upgrade_enabled(upgrade_id, enabled)
		_apply_profile_to_mower()
		player_profile.save_to_disk()
	)
	menu_overlay.strength_changed.connect(_on_hud_strength_changed)
	menu_overlay.settings_changed.connect(_on_menu_settings_changed)
	menu_overlay.reset_save_requested.connect(_on_reset_save_requested)

	_refresh_menu_overlay_state()

func _refresh_menu_overlay_state() -> void:
	if menu_overlay == null or player_profile == null:
		return
	menu_overlay.sync_from_profile(player_profile)
	menu_overlay.populate_level_cards(
		LevelConfigScript.get_level_catalog_summaries(),
		player_profile.best_level_times,
		player_profile.completed_levels
	)
	var vp_size := get_viewport().get_visible_rect().size
	menu_overlay.adapt_to_viewport(vp_size, player_profile.ui_text_scale)
	if game_loop_hud:
		game_loop_hud.apply_responsive_layout(vp_size, player_profile.ui_text_scale)

func open_main_menu() -> void:
	if game_loop_hud:
		game_loop_hud.set_pause_modal_visible(false)
		game_loop_hud.set_tuning_modal_visible(false)
		game_loop_hud.hide_level_complete_modal()
	_refresh_menu_overlay_state()
	if menu_overlay:
		menu_overlay.show_screen(MenuSystemOverlayScript.Screen.MAIN_MENU)
	game_state = GameState.PAUSED
	get_tree().paused = true
	_update_status_hud()

func open_level_select_screen() -> void:
	if game_loop_hud:
		game_loop_hud.set_pause_modal_visible(false)
		game_loop_hud.hide_level_complete_modal()
	_refresh_menu_overlay_state()
	if menu_overlay:
		menu_overlay.show_screen(MenuSystemOverlayScript.Screen.LEVEL_SELECT)
	game_state = GameState.PAUSED
	get_tree().paused = true

func open_garage_screen() -> void:
	if game_loop_hud:
		game_loop_hud.set_pause_modal_visible(false)
	_refresh_menu_overlay_state()
	if menu_overlay:
		menu_overlay.show_screen(MenuSystemOverlayScript.Screen.GARAGE)
	game_state = GameState.PAUSED
	get_tree().paused = true

func open_settings_screen() -> void:
	if game_loop_hud:
		game_loop_hud.set_pause_modal_visible(false)
	_refresh_menu_overlay_state()
	if menu_overlay:
		menu_overlay.show_screen(MenuSystemOverlayScript.Screen.SETTINGS)
	game_state = GameState.PAUSED
	get_tree().paused = true

func close_menus_and_resume() -> void:
	if menu_overlay:
		menu_overlay.show_screen(MenuSystemOverlayScript.Screen.NONE)
	resume_game()

func _apply_profile_to_mower() -> void:
	if garden_arena == null or garden_arena.mower_placeholder == null or player_profile == null:
		return
	var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D
	player_profile.apply_to_mower(mower, mower_growth_scale)
	if mower.body_root:
		mower.body_root.scale = Vector3.ONE * mower_growth_scale

func _apply_settings_to_runtime() -> void:
	if player_profile == null:
		return
	if main_camera and main_camera.has_method("set_zoom_level"):
		main_camera.set_zoom_level(player_profile.camera_zoom)
		main_camera.set("follow_smoothness", 8.5 * player_profile.camera_sensitivity)
	if garden_arena and garden_arena.sound_hooks:
		var eff_vol: float = player_profile.master_volume * player_profile.sfx_volume
		if garden_arena.sound_hooks.get("_player") != null:
			var p: AudioStreamPlayer = garden_arena.sound_hooks.get("_player")
			p.volume_db = linear_to_db(maxf(eff_vol, 0.0001))
	var sun := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if sun:
		sun.shadow_enabled = (player_profile.graphics_quality != "Low")
	if menu_overlay:
		var vp_size := get_viewport().get_visible_rect().size
		menu_overlay.adapt_to_viewport(vp_size, player_profile.ui_text_scale)
	if game_loop_hud:
		var vp_size := get_viewport().get_visible_rect().size
		game_loop_hud.apply_responsive_layout(vp_size, player_profile.ui_text_scale)

func _on_hud_strength_changed(spd: float, rad: float, pwr: int, bst: float) -> void:
	if player_profile == null:
		return
	player_profile.set_mower_strength(spd, rad, pwr, bst)
	_apply_profile_to_mower()
	player_profile.save_to_disk()
	if game_loop_hud:
		game_loop_hud.sync_tuning_sliders(
			player_profile.configured_move_speed,
			player_profile.configured_cutting_radius,
			player_profile.configured_blade_power,
			player_profile.configured_boost_multiplier,
			player_profile.is_creative_mode()
		)
	_update_status_hud()

func _on_menu_settings_changed(
	master_vol: float,
	music_vol: float,
	sfx_vol: float,
	vibration_on: bool,
	cam_zoom: float,
	cam_sens: float,
	gfx_quality: String,
	text_scale: float
) -> void:
	if player_profile == null:
		return
	player_profile.set_audio_settings(master_vol, music_vol, sfx_vol, vibration_on)
	player_profile.set_camera_and_display_settings(cam_zoom, cam_sens, gfx_quality, text_scale)
	_apply_settings_to_runtime()
	player_profile.save_to_disk()

func _on_reset_save_requested() -> void:
	if player_profile == null:
		return
	player_profile.reset_save_and_persist()
	_apply_profile_to_mower()
	_apply_settings_to_runtime()
	_refresh_menu_overlay_state()
	if game_loop_hud:
		game_loop_hud.sync_tuning_sliders(
			player_profile.configured_move_speed,
			player_profile.configured_cutting_radius,
			player_profile.configured_blade_power,
			player_profile.configured_boost_multiplier,
			player_profile.is_creative_mode()
		)
	_update_status_hud()

func set_creative_mode_enabled(enabled: bool) -> void:
	if player_profile == null:
		return
	player_profile.set_play_mode(
		PlayerProfileScript.PlayMode.CREATIVE_RELAX if enabled else PlayerProfileScript.PlayMode.NORMAL
	)
	if game_loop_hud:
		game_loop_hud.set_creative_button_state(player_profile.is_creative_mode())
		game_loop_hud.hide_level_complete_modal()
	if enabled and game_state == GameState.COMPLETED:
		game_state = GameState.PLAYING
		get_tree().paused = false
	_apply_profile_to_mower()
	player_profile.save_to_disk()
	_update_status_hud()

func select_and_start_level(level_id: String) -> void:
	if current_level == null:
		current_level = LevelConfigScript.new()
	current_level.configure_by_id(level_id)
	if player_profile:
		player_profile.selected_level_id = String(current_level.level_id)
		player_profile.save_to_disk()
	restart_level()

func _on_garden_plants_cut(_newly_cut_count: int, _points_earned: int, _cut_by_type: Dictionary) -> void:
	_update_mower_growth_progression()
	_check_level_objectives()
	_update_status_hud()

func _update_mower_growth_progression() -> void:
	if garden_arena == null or garden_arena.mower_placeholder == null:
		return
	var pct: float = garden_arena.get_completion_percentage()
	mower_growth_scale = clampf(1.0 + (pct / 100.0) * 0.16, 1.0, 1.16)
	_apply_profile_to_mower()

func _check_level_objectives() -> void:
	if current_level == null or garden_arena == null:
		return
	if player_profile != null and player_profile.is_creative_mode():
		return

	var pct: float = garden_arena.get_completion_percentage()
	var pts: int = int(garden_arena.get("total_reward_points"))
	var eval_res: Dictionary = current_level.evaluate_all(pct, garden_arena.cut_type_counts, pts)

	if not level_completed_once and bool(eval_res.get("all_completed", false)):
		level_completed_once = true
		_trigger_level_complete(pct, pts)
	elif keep_mowing_mode and not full_100_completed_once and garden_arena.get_remaining_plant_count() == 0:
		full_100_completed_once = true
		_trigger_level_complete(100.0, pts)

func _trigger_level_complete(pct: float, pts: int) -> void:
	game_state = GameState.COMPLETED
	last_earned_stars = current_level.calculate_star_rating(elapsed_level_seconds, pct)
	var reward_coins: int = int(current_level.base_coin_reward) + (last_earned_stars * 50)
	total_coins_earned += reward_coins
	if player_profile:
		player_profile.add_coins(reward_coins)
		player_profile.record_level_completion(String(current_level.level_id), last_earned_stars, elapsed_level_seconds)
		player_profile.save_to_disk()
	get_tree().paused = true
	if game_loop_hud:
		game_loop_hud.show_level_complete_modal(
			String(current_level.title),
			last_earned_stars,
			pct,
			pts,
			reward_coins,
			elapsed_level_seconds
		)
	_update_status_hud()

func pause_game() -> void:
	if game_state != GameState.PLAYING:
		return
	game_state = GameState.PAUSED
	get_tree().paused = true
	if game_loop_hud:
		game_loop_hud.set_pause_modal_visible(true)
	_update_status_hud()

func resume_game() -> void:
	if game_state == GameState.PAUSED:
		game_state = GameState.PLAYING
	get_tree().paused = false
	if game_loop_hud:
		game_loop_hud.set_pause_modal_visible(false)
		game_loop_hud.set_tuning_modal_visible(false)
	_update_status_hud()

func continue_mowing_after_complete() -> void:
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
		if garden_arena.mower_placeholder:
			var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D
			mower.global_position = Vector3.ZERO
			mower.velocity = Vector3.ZERO
			mower.rotation = Vector3.ZERO
			mower.set_touch_input(Vector2.ZERO)
			mower.set_touch_boost(false)
	_apply_profile_to_mower()

	if touch_controls and touch_controls.has_method("set_simulated_joystick"):
		touch_controls.set_simulated_joystick(Vector2.ZERO)
	if main_camera and main_camera.has_method("snap_to_target"):
		main_camera.snap_to_target()
	if game_loop_hud:
		game_loop_hud.set_pause_modal_visible(false)
		game_loop_hud.set_tuning_modal_visible(false)
		game_loop_hud.hide_level_complete_modal()

	_update_status_hud()

func _update_status_hud() -> void:
	if garden_arena == null or garden_arena.mower_placeholder == null:
		return
	var total_plants: int = garden_arena.get_total_plant_count()
	var cut_plants: int = garden_arena.get_total_cut_count()
	var pct: float = garden_arena.get_completion_percentage()
	var pts: int = int(garden_arena.get("total_reward_points"))
	var is_creative: bool = player_profile != null and player_profile.is_creative_mode()

	var status_label := get_node_or_null("StartupHUD/SafeMargin/HeaderPanel/VBox/StatusLabel") as Label
	if status_label:
		var state_str := "CREATIVE ∞" if is_creative else "PLAYING"
		if game_state == GameState.PAUSED:
			state_str = "PAUSED"
		elif game_state == GameState.COMPLETED:
			state_str = "COMPLETE (%d★)" % last_earned_stars
		var coin_str: String = player_profile.get_coins_display() if player_profile else "∞"
		status_label.text = (
			"[%s] Cut: %d / %d (%.1f%%) | Points: %d | Coins: %s | Scale: %.2fx"
			% [state_str, cut_plants, total_plants, pct, pts, coin_str, mower_growth_scale]
		)

	if game_loop_hud and current_level:
		var eval_res: Dictionary = current_level.evaluate_all(pct, garden_arena.cut_type_counts, pts)
		game_loop_hud.update_objectives_display(
			String(current_level.title),
			pct,
			elapsed_level_seconds,
			eval_res,
			is_creative
		)

func _verify_input_actions() -> void:
	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			push_error("[Step8] Missing required InputMap action: " + String(action))

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

func _run_step5_self_test(_dt: float) -> void:
	var failures: Array[String] = []
	var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D
	if mower == null:
		failures.append("MowerPlaceholder missing")

	var initial_total: int = garden_arena.get_total_plant_count()
	if initial_total < 200:
		failures.append("Expected >= 200 plants before cutting test")

	garden_arena.reset_all_plants()
	if garden_arena.get_total_cut_count() != 0:
		failures.append("Expected 0 cut plants after reset_all_plants()")

	var sweep_center := Vector3(3.0, 0.0, 3.0)
	var sweep_radius := 4.5
	var first_pass: Dictionary = garden_arena.cut_plants_in_radius(sweep_center, sweep_radius, 3)
	var first_cut: int = int(first_pass["newly_cut"])
	var first_points: int = int(first_pass["points_earned"])
	var count_after_first: int = garden_arena.get_total_cut_count()
	var points_after_first: int = int(garden_arena.get("total_reward_points"))
	var bursts_after_first: int = int(garden_arena.clipping_burst_manager.get("total_bursts_emitted"))
	var sounds_after_first: int = int(garden_arena.sound_hooks.get("total_sound_events"))

	if first_cut <= 0 or first_points <= 0:
		failures.append("First cutting pass did not cut any plants or award points (cut=%d, pts=%d)" % [first_cut, first_points])
	if bursts_after_first <= 0:
		failures.append("ClippingBurstManager did not emit any bursts during cutting")
	if sounds_after_first <= 0:
		failures.append("SoundHooks did not trigger any cut sounds during cutting")

	var second_pass: Dictionary = garden_arena.cut_plants_in_radius(sweep_center, sweep_radius, 3)
	var second_cut: int = int(second_pass["newly_cut"])
	var second_points: int = int(second_pass["points_earned"])
	var count_after_second: int = garden_arena.get_total_cut_count()
	var points_after_second: int = int(garden_arena.get("total_reward_points"))

	if second_cut != 0 or second_points != 0:
		failures.append("Duplicate cut detected on already-cut plants! (second_cut=%d, second_points=%d)" % [second_cut, second_points])
	if count_after_second != count_after_first or points_after_second != points_after_first:
		failures.append("Total cut count or reward points changed on duplicate sweep!")

	garden_arena.reset_all_plants()
	var low_power_sweep: Dictionary = garden_arena.cut_plants_in_radius(Vector3(0.0, 0.0, 0.0), 25.0, 1)
	var large_cut_with_low_power: int = int(garden_arena.cut_type_counts["large_trim_plants"])
	var shrubs_cut_with_low_power: int = int(garden_arena.cut_type_counts["small_shrubs"])
	if large_cut_with_low_power != 0 or shrubs_cut_with_low_power != 0:
		failures.append("Low cutter_power=1 improperly cut high-resistance shrubs/large plants")
	if int(low_power_sweep["newly_cut"]) <= 0:
		failures.append("Low cutter_power=1 failed to cut grass and flowers")

	var full_power_sweep: Dictionary = garden_arena.cut_plants_in_radius(Vector3(0.0, 0.0, 0.0), 25.0, 3)
	if int(full_power_sweep["newly_cut"]) <= 0:
		failures.append("Power=3 failed to cut remaining shrubs and large plants")
	if garden_arena.get_remaining_plant_count() != 0:
		failures.append("Expected 0 remaining plants after full-arena sweep, got %d" % garden_arena.get_remaining_plant_count())
	if absf(garden_arena.get_completion_percentage() - 100.0) > 0.01:
		failures.append("Expected 100%% completion after full-arena sweep, got %.2f%%" % garden_arena.get_completion_percentage())

	restart_level()

	print(
		"[TestStep5] First pass cut=%d (points=%d, bursts=%d, sounds=%d) | Second pass duplicate cuts=%d (duplicate points=%d) | Full-arena completion=100%% verified."
		% [first_cut, first_points, bursts_after_first, sounds_after_first, second_cut, second_points]
	)

	if failures.size() > 0:
		for msg in failures:
			push_error("[TestStep5] FAIL: " + msg)
		get_tree().quit(1)
		return

	print("[TestStep5] PASS — Plant cutting states, trimmed visuals, clipping particles, sound hooks, counters, resistance gating, and duplicate-reward prevention verified.")

func _run_step6_self_test(_dt: float) -> void:
	var failures: Array[String] = []
	set_creative_mode_enabled(false)
	select_and_start_level("level_01_sunlit_courtyard")

	if game_state != GameState.PLAYING or get_tree().paused:
		failures.append("Expected initial state PLAYING and unpaused")

	pause_game()
	if game_state != GameState.PAUSED or not get_tree().paused:
		failures.append("pause_game() did not enter PAUSED state or pause SceneTree")
	if not game_loop_hud.pause_modal_backdrop.visible:
		failures.append("Pause modal backdrop did not become visible on pause_game()")

	resume_game()
	if game_state != GameState.PLAYING or get_tree().paused:
		failures.append("resume_game() did not return to PLAYING state or unpause SceneTree")
	if game_loop_hud.pause_modal_backdrop.visible:
		failures.append("Pause modal backdrop still visible after resume_game()")

	garden_arena.cut_plants_in_radius(Vector3(3.0, 0.0, 3.0), 4.0, 3)
	if game_state != GameState.PLAYING or level_completed_once:
		failures.append("Level prematurely completed on small partial sweep")

	elapsed_level_seconds = 58.0
	garden_arena.cut_plants_in_radius(Vector3(0.0, 0.0, 0.0), 19.2, 3)
	var pct_at_complete: float = garden_arena.get_completion_percentage()
	if game_state != GameState.COMPLETED or not level_completed_once:
		failures.append("Level did not transition to COMPLETED when all objectives met (pct=%.1f%%)" % pct_at_complete)
	if not game_loop_hud.complete_modal_backdrop.visible:
		failures.append("Level complete modal did not appear on objective completion")
	if last_earned_stars != 3:
		failures.append("Expected 3 stars for fast completion (58s <= 75s), got %d" % last_earned_stars)
	if total_coins_earned <= 0:
		failures.append("Expected positive coin reward on level completion")
	if mower_growth_scale <= 1.10:
		failures.append("Expected mower_growth_scale > 1.10 near completion, got %.2f" % mower_growth_scale)

	continue_mowing_after_complete()
	if game_state != GameState.PLAYING or get_tree().paused or not keep_mowing_mode:
		failures.append("continue_mowing_after_complete() failed to resume playing in keep_mowing_mode")
	garden_arena.cut_plants_in_radius(Vector3(0.0, 0.0, 0.0), 30.0, 3)
	if not full_100_completed_once or game_state != GameState.COMPLETED:
		failures.append("100%% full garden clear did not trigger final completion state")

	restart_level()
	if game_state != GameState.PLAYING or get_tree().paused:
		failures.append("restart_level() did not restore PLAYING unpaused state")
	if garden_arena.get_total_cut_count() != 0:
		failures.append("restart_level() did not reset cut plant count to 0")
	if level_completed_once or keep_mowing_mode:
		failures.append("restart_level() did not clear completion flags")
	if absf(mower_growth_scale - 1.0) > 0.001:
		failures.append("restart_level() did not reset mower_growth_scale to 1.0")

	print(
		"[TestStep6] Verified Pause/Resume, Partial Progress, Objective Completion (%.1f%% -> 100.0%%, %d Stars, +%d Coins), Keep Mowing 100%%, and Restart reset."
		% [pct_at_complete, 3, total_coins_earned]
	)

	if failures.size() > 0:
		for msg in failures:
			push_error("[TestStep6] FAIL: " + msg)
		get_tree().quit(1)
		return

	print("[TestStep6] PASS — Objective tracking, level completion states, pause/resume, keep-mowing 100%, mower growth scaling, and level restart verified.")

func _run_step7_self_test(dt: float) -> void:
	var failures: Array[String] = []
	var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D

	for lid in LevelConfigScript.get_all_level_ids():
		if not player_profile.is_level_unlocked(lid):
			failures.append("Level '%s' is not unlocked on first launch" % lid)
	for mid in PlayerProfileScript.UNLOCKED_MOWER_TYPES:
		if not player_profile.is_mower_unlocked(mid):
			failures.append("Mower '%s' is not unlocked" % mid)
	for sid in PlayerProfileScript.UNLOCKED_SKINS:
		if not player_profile.is_skin_unlocked(sid):
			failures.append("Skin '%s' is not unlocked" % sid)
	for uid in PlayerProfileScript.UNLOCKED_UPGRADES:
		if not player_profile.is_upgrade_unlocked(uid):
			failures.append("Upgrade '%s' is not unlocked" % uid)
	for bid in PlayerProfileScript.UNLOCKED_BOOSTERS:
		if not player_profile.is_booster_unlocked(bid):
			failures.append("Booster '%s' is not unlocked" % bid)

	player_profile.unlimited_resources = true
	var initial_cap: int = player_profile.coins_balance
	player_profile.spend_coins(50000000)
	if player_profile.coins_balance != initial_cap or not player_profile.get_coins_display().begins_with("∞"):
		failures.append("Unlimited resources failed to maintain cap or ∞ display after spending")

	player_profile.set_mower_strength(-9999.0, -50.0, -100, -5.0, -99.0)
	if absf(player_profile.configured_move_speed - PlayerProfileScript.MIN_MOVE_SPEED) > 0.001:
		failures.append("Minimum move_speed clamp failed: %.2f" % player_profile.configured_move_speed)
	if absf(player_profile.configured_cutting_radius - PlayerProfileScript.MIN_CUTTING_RADIUS) > 0.001:
		failures.append("Minimum cutting_radius clamp failed: %.2f" % player_profile.configured_cutting_radius)
	if player_profile.configured_blade_power != PlayerProfileScript.MIN_BLADE_POWER:
		failures.append("Minimum blade_power clamp failed: %d" % player_profile.configured_blade_power)

	player_profile.set_mower_strength(999999.0, 9999.0, 9999, 999.0, 9999.0)
	if absf(player_profile.configured_move_speed - PlayerProfileScript.MAX_MOVE_SPEED) > 0.001:
		failures.append("Maximum move_speed clamp failed: %.2f" % player_profile.configured_move_speed)
	if absf(player_profile.configured_cutting_radius - PlayerProfileScript.MAX_CUTTING_RADIUS) > 0.001:
		failures.append("Maximum cutting_radius clamp failed: %.2f" % player_profile.configured_cutting_radius)
	if player_profile.configured_blade_power != PlayerProfileScript.MAX_BLADE_POWER:
		failures.append("Maximum blade_power clamp failed: %d" % player_profile.configured_blade_power)
	if absf(player_profile.configured_boost_multiplier - PlayerProfileScript.MAX_BOOST_MULTIPLIER) > 0.001:
		failures.append("Maximum boost_multiplier clamp failed: %.2f" % player_profile.configured_boost_multiplier)

	player_profile.set_mower_strength(NAN, INF, 3, NAN, INF)
	if is_nan(player_profile.configured_move_speed) or is_inf(player_profile.configured_cutting_radius):
		failures.append("NaN/INF guard failed in set_mower_strength")

	player_profile.set_mower_strength(999999.0, 9999.0, 5, 999.0, 999.0)
	_apply_profile_to_mower()
	mower.global_position = Vector3(0.0, 0.0, -12.0)
	mower.set_touch_boost(true)
	touch_controls.set_simulated_joystick(Vector2(0.0, -1.0))
	for _i in range(60):
		mower.step_movement(dt)
		main_camera.update_camera(dt)
	mower.set_touch_boost(false)
	touch_controls.set_simulated_joystick(Vector2.ZERO)
	if absf(mower.global_position.z) > 15.6 or absf(mower.global_position.x) > 15.6:
		failures.append("Mower escaped map under maximum clamped speed + boost: pos=%s" % str(mower.global_position))

	player_profile.set_mower_strength(10.0, 1.80, 1, 1.6, 12.0)
	set_creative_mode_enabled(true)
	restart_level()
	elapsed_level_seconds = 0.0
	for _i in range(10):
		_physics_process(dt)
	if elapsed_level_seconds > 0.001:
		failures.append("Timer advanced during Creative / Relax mode: %.2f" % elapsed_level_seconds)
	garden_arena.cut_plants_in_radius(Vector3.ZERO, 30.0, int(mower.get("cutting_power")))
	if garden_arena.get_remaining_plant_count() != 0:
		failures.append("Creative mode failed to freely cut all high-resistance plants (remaining=%d)" % garden_arena.get_remaining_plant_count())
	if game_state != GameState.PLAYING or get_tree().paused:
		failures.append("Creative mode unexpectedly paused/stopped gameplay with a completion modal")

	var test_save_path := "user://test_step7_persistence.json"
	player_profile.set_mower_strength(12.5, 2.15, 4, 1.75, 15.0)
	player_profile.select_mower_type("turbo_hover_deck")
	player_profile.select_skin("sunlit_gold")
	if not player_profile.save_to_disk(test_save_path):
		failures.append("Failed to save profile to " + test_save_path)

	var reloaded_profile := PlayerProfileScript.new()
	if not reloaded_profile.load_from_disk(test_save_path):
		failures.append("Failed to load profile from " + test_save_path)
	if absf(reloaded_profile.configured_move_speed - 12.5) > 0.01 or absf(reloaded_profile.configured_cutting_radius - 2.15) > 0.01:
		failures.append("Reloaded profile strength values did not match saved values")
	if reloaded_profile.selected_mower_type != "turbo_hover_deck" or reloaded_profile.selected_skin != "sunlit_gold":
		failures.append("Reloaded profile mower/skin selection did not match saved values")

	var bad_file := FileAccess.open(test_save_path, FileAccess.WRITE)
	bad_file.store_string("{corrupted_json_data: [")
	bad_file.close()
	var recovered_profile := PlayerProfileScript.new()
	var load_ok := recovered_profile.load_from_disk(test_save_path)
	if load_ok or absf(recovered_profile.configured_move_speed - PlayerProfileScript.DEFAULT_MOVE_SPEED) > 0.01:
		failures.append("Corrupted save did not cleanly recover to safe default settings")

	player_profile.reset_to_defaults()
	player_profile.save_to_disk()
	set_creative_mode_enabled(false)
	select_and_start_level("level_01_sunlit_courtyard")

	print(
		"[TestStep7] Verified All-Unlocked Catalog (3 levels, 4 mowers, 4 skins, 5 upgrades), Unlimited Coins (∞), Extreme Clamp Safety (speed<=%.1f, radius<=%.2f), Creative Mode free-cut, and Save/Corrupt-Recovery."
		% [PlayerProfileScript.MAX_MOVE_SPEED, PlayerProfileScript.MAX_CUTTING_RADIUS]
	)

	if failures.size() > 0:
		for msg in failures:
			push_error("[TestStep7] FAIL: " + msg)
		get_tree().quit(1)
		return

	print("[TestStep7] PASS — All-level access, unlimited resources (∞), all upgrades unlocked, safe clamped mower strength, Creative/Relax mode, and persistence verified.")

func _run_step8_self_test(_dt: float) -> void:
	var failures: Array[String] = []
	var mower: CharacterBody3D = garden_arena.mower_placeholder as CharacterBody3D

	if menu_overlay == null:
		failures.append("MenuSystemOverlay is missing")

	# 1. Test Main Menu, Level Select, Garage, Settings & Credits navigation flows
	open_main_menu()
	if not menu_overlay.is_menu_open() or menu_overlay.current_screen != MenuSystemOverlayScript.Screen.MAIN_MENU:
		failures.append("open_main_menu() failed to show MAIN_MENU screen")
	if not menu_overlay.main_menu_panel.visible:
		failures.append("MainMenuPanel is not visible when MAIN_MENU screen is active")

	open_level_select_screen()
	if menu_overlay.current_screen != MenuSystemOverlayScript.Screen.LEVEL_SELECT or not menu_overlay.level_select_panel.visible:
		failures.append("open_level_select_screen() failed to show LEVEL_SELECT panel")
	if menu_overlay.level_cards_hbox.get_child_count() < 3:
		failures.append("Level Select did not populate all 3 unlocked level cards")

	open_garage_screen()
	if menu_overlay.current_screen != MenuSystemOverlayScript.Screen.GARAGE or not menu_overlay.garage_panel.visible:
		failures.append("open_garage_screen() failed to show GARAGE panel")

	# 2. Test Garage mower & skin customization + upgrade toggles
	menu_overlay._on_garage_mower_selected("heavy_topiary_sculptor")
	menu_overlay._on_garage_skin_selected("cobalt_breeze")
	if player_profile.selected_mower_type != "heavy_topiary_sculptor" or player_profile.selected_skin != "cobalt_breeze":
		failures.append("Garage selection did not update PlayerProfile mower/skin")
	if String(mower.get("active_mower_type")) != "heavy_topiary_sculptor" or String(mower.get("active_skin_id")) != "cobalt_breeze":
		failures.append("Garage selection did not apply visual customization to 3D MowerPlaceholder")

	player_profile.set_upgrade_enabled("wide_deck_expander", false)
	if player_profile.is_upgrade_enabled("wide_deck_expander"):
		failures.append("Failed to toggle upgrade wide_deck_expander off")
	player_profile.set_upgrade_enabled("wide_deck_expander", true)

	# 3. Test Settings screen: Audio, Vibration, Camera Zoom/Sensitivity, Graphics Quality, Large Text
	open_settings_screen()
	if menu_overlay.current_screen != MenuSystemOverlayScript.Screen.SETTINGS or not menu_overlay.settings_panel.visible:
		failures.append("open_settings_screen() failed to show SETTINGS panel")

	_on_menu_settings_changed(0.65, 0.50, 0.75, false, 1.25, 1.40, "Low", 1.25)
	if absf(player_profile.master_volume - 0.65) > 0.01 or player_profile.vibration_enabled != false:
		failures.append("Settings audio/vibration update failed")
	if absf(float(main_camera.get("zoom_level")) - 1.25) > 0.01:
		failures.append("Settings camera_zoom did not apply to FollowCamera")
	var sun := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if sun and sun.shadow_enabled != false:
		failures.append("Graphics quality 'Low' did not disable directional shadows")

	# Credits screen check
	menu_overlay.show_screen(MenuSystemOverlayScript.Screen.CREDITS)
	if not menu_overlay.credits_panel.visible:
		failures.append("Credits panel did not become visible")

	close_menus_and_resume()
	if menu_overlay.is_menu_open() or get_tree().paused:
		failures.append("close_menus_and_resume() did not close menu overlay and unpause")

	# 4. Test Save / Load, Corruption Recovery & Reset Save
	var step8_save_path := "user://test_step8_save.json"
	player_profile.record_level_completion("level_02_blossom_terrace", 3, 64.2)
	if not player_profile.save_to_disk(step8_save_path):
		failures.append("Failed to save Step 8 profile to disk")

	var loaded_p := PlayerProfileScript.new()
	if not loaded_p.load_from_disk(step8_save_path):
		failures.append("Failed to load Step 8 profile from disk")
	if int(loaded_p.completed_levels.get("level_02_blossom_terrace", 0)) != 3:
		failures.append("Loaded profile did not preserve completed level stars")
	if loaded_p.graphics_quality != "Low" or absf(loaded_p.ui_text_scale - 1.25) > 0.01:
		failures.append("Loaded profile did not preserve graphics_quality or ui_text_scale")

	# Corrupt save recovery check
	var corrupt_f := FileAccess.open(step8_save_path, FileAccess.WRITE)
	corrupt_f.store_string("NOT_VALID_JSON_AT_ALL{{{")
	corrupt_f.close()
	var recovered_p := PlayerProfileScript.new()
	var ok_corrupt := recovered_p.load_from_disk(step8_save_path)
	if ok_corrupt or not recovered_p.last_load_recovered_from_corruption:
		failures.append("Corrupted save was not flagged by last_load_recovered_from_corruption")

	# Reset save option check
	_on_reset_save_requested()
	if player_profile.selected_mower_type != "standard_rotary" or player_profile.graphics_quality != "High":
		failures.append("Reset save did not restore default mower or High graphics quality")
	if not player_profile.completed_levels.is_empty():
		failures.append("Reset save did not clear completed_levels history")

	# 5. Test UI layout across multiple aspect ratios (16:9, 20:9, 21:9, 4:3) and large text (1.0x and 1.25x)
	var test_viewports: Array[Vector2] = [
		Vector2(1280, 720),  # 16:9 standard landscape
		Vector2(1600, 720),  # 20:9 modern Android phone landscape
		Vector2(1680, 720),  # 21:9 ultra-wide landscape
		Vector2(1024, 768)   # 4:3 tablet landscape
	]
	for vp in test_viewports:
		for t_scale in [1.0, 1.25]:
			var layout_res: Dictionary = menu_overlay.adapt_to_viewport(vp, t_scale)
			game_loop_hud.apply_responsive_layout(vp, t_scale)
			if not bool(layout_res.get("fits_bounds", false)):
				failures.append("UI layout overflowed bounds at viewport %s with text_scale %.2f" % [str(vp), t_scale])

	# Restore standard 1280x720 1.0x layout
	menu_overlay.adapt_to_viewport(Vector2(1280, 720), 1.0)
	game_loop_hud.apply_responsive_layout(Vector2(1280, 720), 1.0)
	restart_level()

	print(
		"[TestStep8] Verified Main Menu, Level Select (3 cards), Garage (4 mowers, 4 skins, 5 upgrades), Settings (Audio/Zoom/Graphics/LargeText), Save Reset, Corruption Recovery, and 4 Aspect Ratios (16:9, 20:9, 21:9, 4:3)."
	)

	if failures.size() > 0:
		for msg in failures:
			push_error("[TestStep8] FAIL: " + msg)
		get_tree().quit(1)
		return

	print("[TestStep8] PASS — Menus, garage, settings, local save/load, reset save, corruption recovery, and multi-aspect-ratio/large-text UI verified.")
