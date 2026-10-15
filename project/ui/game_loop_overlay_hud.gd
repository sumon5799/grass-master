extends Control
class_name GameLoopOverlayHUD

## Step 6, Step 7 & Step 8 — In-Game HUD, Quick Tuning, Pause & Level Complete Overlay.
## Provides:
## - Top-left Objective Tracker checklist + progress bar + timer (or Creative/Relax Zen banner)
## - Top-right Quick Actions: Main Menu, Creative Mode Toggle, Unlocks & Tuning, Restart, Pause (>= 48dp touch targets)
## - Center Modal Pause Overlay (Resume, Restart Level, Garage, Settings, Main Menu)
## - Center Modal Level Complete Overlay (Stars, Stats, Play Again / Restart, Keep Mowing 100%, Level Select)
## - Responsive layout & large-text accessibility scaling

signal pause_requested()
signal resume_requested()
signal restart_requested()
signal keep_mowing_requested()
signal creative_mode_toggled(enabled: bool)
signal level_selected(level_id: String)
signal strength_changed(move_speed: float, cutting_radius: float, blade_power: int, boost_mult: float)
signal regrow_garden_requested()
signal main_menu_requested()
signal garage_requested()
signal settings_requested()
signal level_select_requested()

var objective_panel: PanelContainer
var objective_title_label: Label
var timer_label: Label
var overall_progress_bar: ProgressBar
var checklist_vbox: VBoxContainer

var top_right_hbox: HBoxContainer
var menu_top_button: Button
var creative_toggle_button: Button
var tuning_open_button: Button
var pause_top_button: Button
var restart_top_button: Button

var tuning_modal_backdrop: ColorRect
var speed_slider: HSlider
var speed_value_label: Label
var radius_slider: HSlider
var radius_value_label: Label
var power_slider: HSlider
var power_value_label: Label
var boost_slider: HSlider
var boost_value_label: Label
var level_buttons_hbox: HBoxContainer

var pause_modal_backdrop: ColorRect
var resume_button: Button
var pause_restart_button: Button
var pause_garage_button: Button
var pause_settings_button: Button
var pause_main_menu_button: Button

var complete_modal_backdrop: ColorRect
var complete_title_label: Label
var complete_stars_label: Label
var complete_stats_label: Label
var complete_restart_button: Button
var complete_keep_mowing_button: Button
var complete_level_select_button: Button

func _ready() -> void:
	name = "GameLoopOverlayHUD"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_objective_panel()
	_build_top_right_buttons()
	_build_tuning_modal()
	_build_pause_modal()
	_build_complete_modal()

func _build_objective_panel() -> void:
	objective_panel = PanelContainer.new()
	objective_panel.name = "ObjectiveTrackerPanel"
	objective_panel.anchor_left = 0.0
	objective_panel.anchor_top = 0.0
	objective_panel.offset_left = 24.0
	objective_panel.offset_top = 92.0
	objective_panel.offset_right = 388.0
	objective_panel.offset_bottom = 298.0
	objective_panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.14, 0.08, 0.82)
	style.border_color = Color(0.45, 0.85, 0.38, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	objective_panel.add_theme_stylebox_override("panel", style)
	add_child(objective_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	objective_panel.add_child(vbox)

	var header_row := HBoxContainer.new()
	vbox.add_child(header_row)

	objective_title_label = Label.new()
	objective_title_label.name = "ObjectiveTitleLabel"
	objective_title_label.text = "Level 1 — Sunlit Courtyard"
	objective_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_title_label.add_theme_font_size_override("font_size", 15)
	objective_title_label.add_theme_color_override("font_color", Color(0.95, 1.0, 0.90))
	header_row.add_child(objective_title_label)

	timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.text = "00:00"
	timer_label.add_theme_font_size_override("font_size", 14)
	timer_label.add_theme_color_override("font_color", Color(0.80, 0.95, 0.75))
	header_row.add_child(timer_label)

	overall_progress_bar = ProgressBar.new()
	overall_progress_bar.name = "OverallProgressBar"
	overall_progress_bar.min_value = 0.0
	overall_progress_bar.max_value = 100.0
	overall_progress_bar.value = 0.0
	overall_progress_bar.custom_minimum_size = Vector2(0.0, 18.0)
	vbox.add_child(overall_progress_bar)

	checklist_vbox = VBoxContainer.new()
	checklist_vbox.name = "ChecklistVBox"
	checklist_vbox.add_theme_constant_override("separation", 3)
	vbox.add_child(checklist_vbox)

func _build_top_right_buttons() -> void:
	top_right_hbox = HBoxContainer.new()
	top_right_hbox.name = "TopRightLoopButtons"
	top_right_hbox.anchor_left = 1.0
	top_right_hbox.anchor_right = 1.0
	top_right_hbox.offset_left = -660.0
	top_right_hbox.offset_top = 92.0
	top_right_hbox.offset_right = -24.0
	top_right_hbox.offset_bottom = 148.0
	top_right_hbox.alignment = BoxContainer.ALIGNMENT_END
	top_right_hbox.add_theme_constant_override("separation", 8)
	add_child(top_right_hbox)

	menu_top_button = Button.new()
	menu_top_button.name = "MainMenuTopButton"
	menu_top_button.text = "Menu"
	menu_top_button.custom_minimum_size = Vector2(88.0, 52.0)
	menu_top_button.pressed.connect(func() -> void: main_menu_requested.emit())
	top_right_hbox.add_child(menu_top_button)

	creative_toggle_button = Button.new()
	creative_toggle_button.name = "CreativeModeButton"
	creative_toggle_button.text = "Mode: Normal"
	creative_toggle_button.custom_minimum_size = Vector2(138.0, 52.0)
	creative_toggle_button.pressed.connect(_on_creative_button_pressed)
	top_right_hbox.add_child(creative_toggle_button)

	tuning_open_button = Button.new()
	tuning_open_button.name = "MowerStrengthButton"
	tuning_open_button.text = "Unlocks & Tuning"
	tuning_open_button.custom_minimum_size = Vector2(142.0, 52.0)
	tuning_open_button.pressed.connect(func() -> void: set_tuning_modal_visible(true))
	top_right_hbox.add_child(tuning_open_button)

	restart_top_button = Button.new()
	restart_top_button.name = "QuickRestartButton"
	restart_top_button.text = "Restart"
	restart_top_button.custom_minimum_size = Vector2(96.0, 52.0)
	restart_top_button.pressed.connect(func() -> void: restart_requested.emit())
	top_right_hbox.add_child(restart_top_button)

	pause_top_button = Button.new()
	pause_top_button.name = "PauseButton"
	pause_top_button.text = "Pause"
	pause_top_button.custom_minimum_size = Vector2(96.0, 52.0)
	pause_top_button.pressed.connect(func() -> void: pause_requested.emit())
	top_right_hbox.add_child(pause_top_button)

func _build_tuning_modal() -> void:
	tuning_modal_backdrop = ColorRect.new()
	tuning_modal_backdrop.name = "TuningModalBackdrop"
	tuning_modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tuning_modal_backdrop.color = Color(0.02, 0.06, 0.03, 0.78)
	tuning_modal_backdrop.visible = false
	tuning_modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(tuning_modal_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tuning_modal_backdrop.add_child(center)

	var card := PanelContainer.new()
	card.name = "TuningCard"
	card.custom_minimum_size = Vector2(620.0, 460.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.18, 0.10, 0.97)
	style.border_color = Color(0.55, 0.92, 0.42, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	var title := Label.new()
	title.text = "UNLOCKS, UNLIMITED RESOURCES (∞) & MOWER STRENGTH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.96, 1.0, 0.88))
	vbox.add_child(title)

	var unlock_badge := Label.new()
	unlock_badge.text = "Coins: ∞ (Unlimited) | All Levels, 4 Mowers, 4 Skins & 5 Upgrades UNLOCKED"
	unlock_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_badge.add_theme_font_size_override("font_size", 13)
	unlock_badge.add_theme_color_override("font_color", Color(0.62, 0.98, 0.56))
	vbox.add_child(unlock_badge)

	var lvl_label := Label.new()
	lvl_label.text = "Select Any Unlocked Level:"
	lvl_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lvl_label)

	level_buttons_hbox = HBoxContainer.new()
	level_buttons_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(level_buttons_hbox)

	var level_defs := [
		{"id": "level_01_sunlit_courtyard", "label": "Level 1: Courtyard"},
		{"id": "level_02_blossom_terrace", "label": "Level 2: Terrace"},
		{"id": "level_03_royal_topiary_maze", "label": "Level 3: Royal Topiary"}
	]
	for def in level_defs:
		var btn := Button.new()
		btn.text = String(def["label"])
		btn.custom_minimum_size = Vector2(180.0, 48.0)
		var lid: String = String(def["id"])
		btn.pressed.connect(func() -> void:
			level_selected.emit(lid)
			set_tuning_modal_visible(false)
		)
		level_buttons_hbox.add_child(btn)

	speed_slider = _add_slider_row(vbox, "Move Speed (m/s):", 4.0, 16.0, 0.5, 8.5, "speed")
	radius_slider = _add_slider_row(vbox, "Cutting Radius (m):", 0.85, 3.20, 0.05, 1.45, "radius")
	power_slider = _add_slider_row(vbox, "Blade Power (1-5):", 1.0, 5.0, 1.0, 3.0, "power")
	boost_slider = _add_slider_row(vbox, "Boost Multiplier:", 1.10, 2.10, 0.05, 1.55, "boost")

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 12)
	vbox.add_child(action_row)

	var regrow_btn := Button.new()
	regrow_btn.text = "Regrow All Plants"
	regrow_btn.custom_minimum_size = Vector2(185.0, 50.0)
	regrow_btn.pressed.connect(func() -> void: regrow_garden_requested.emit())
	action_row.add_child(regrow_btn)

	var close_btn := Button.new()
	close_btn.name = "CloseTuningButton"
	close_btn.text = "Apply & Close"
	close_btn.custom_minimum_size = Vector2(185.0, 50.0)
	close_btn.pressed.connect(func() -> void: set_tuning_modal_visible(false))
	action_row.add_child(close_btn)

func _add_slider_row(
	parent: VBoxContainer,
	title_text: String,
	min_v: float,
	max_v: float,
	step_v: float,
	initial_v: float,
	kind: String
) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = title_text
	lbl.custom_minimum_size = Vector2(170.0, 28.0)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = initial_v
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(240.0, 32.0)
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size = Vector2(72.0, 28.0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.text = "%.2f" % initial_v
	row.add_child(val_lbl)

	if kind == "speed":
		speed_value_label = val_lbl
	elif kind == "radius":
		radius_value_label = val_lbl
	elif kind == "power":
		power_value_label = val_lbl
		val_lbl.text = "%d" % int(initial_v)
	elif kind == "boost":
		boost_value_label = val_lbl

	slider.value_changed.connect(func(_v: float) -> void: _emit_slider_strength())
	return slider

func _emit_slider_strength() -> void:
	if speed_slider == null or radius_slider == null or power_slider == null or boost_slider == null:
		return
	var spd: float = float(speed_slider.value)
	var rad: float = float(radius_slider.value)
	var pwr: int = int(round(power_slider.value))
	var bst: float = float(boost_slider.value)
	if speed_value_label:
		speed_value_label.text = "%.1f" % spd
	if radius_value_label:
		radius_value_label.text = "%.2f" % rad
	if power_value_label:
		power_value_label.text = "%d" % pwr
	if boost_value_label:
		boost_value_label.text = "%.2fx" % bst
	strength_changed.emit(spd, rad, pwr, bst)

func sync_tuning_sliders(spd: float, rad: float, pwr: int, bst: float, is_creative: bool) -> void:
	if speed_slider:
		speed_slider.set_value_no_signal(spd)
	if radius_slider:
		radius_slider.set_value_no_signal(rad)
	if power_slider:
		power_slider.set_value_no_signal(float(pwr))
	if boost_slider:
		boost_slider.set_value_no_signal(bst)
	if speed_value_label:
		speed_value_label.text = "%.1f" % spd
	if radius_value_label:
		radius_value_label.text = "%.2f" % rad
	if power_value_label:
		power_value_label.text = "%d" % pwr
	if boost_value_label:
		boost_value_label.text = "%.2fx" % bst
	if creative_toggle_button:
		creative_toggle_button.text = "Mode: Creative ∞" if is_creative else "Mode: Normal"

var _creative_active_state: bool = false

func _on_creative_button_pressed() -> void:
	_creative_active_state = not _creative_active_state
	if creative_toggle_button:
		creative_toggle_button.text = "Mode: Creative ∞" if _creative_active_state else "Mode: Normal"
	creative_mode_toggled.emit(_creative_active_state)

func set_creative_button_state(active: bool) -> void:
	_creative_active_state = active
	if creative_toggle_button:
		creative_toggle_button.text = "Mode: Creative ∞" if active else "Mode: Normal"

func set_tuning_modal_visible(show_modal: bool) -> void:
	if tuning_modal_backdrop:
		tuning_modal_backdrop.visible = show_modal

func _build_pause_modal() -> void:
	pause_modal_backdrop = ColorRect.new()
	pause_modal_backdrop.name = "PauseModalBackdrop"
	pause_modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_modal_backdrop.color = Color(0.02, 0.06, 0.03, 0.76)
	pause_modal_backdrop.visible = false
	pause_modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(pause_modal_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_modal_backdrop.add_child(center)

	var card := PanelContainer.new()
	card.name = "PauseCard"
	card.custom_minimum_size = Vector2(460.0, 380.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.19, 0.11, 0.96)
	style.border_color = Color(0.52, 0.90, 0.44, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 22.0
	style.content_margin_bottom = 22.0
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	var title := Label.new()
	title.text = "GAME PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 1.0, 0.92))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Take a breather, tune your mower, or switch levels."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.92, 0.74))
	vbox.add_child(subtitle)

	resume_button = Button.new()
	resume_button.name = "ResumeButton"
	resume_button.text = "Resume Game"
	resume_button.custom_minimum_size = Vector2(280.0, 50.0)
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	vbox.add_child(resume_button)

	pause_restart_button = Button.new()
	pause_restart_button.name = "PauseRestartButton"
	pause_restart_button.text = "Restart Level"
	pause_restart_button.custom_minimum_size = Vector2(280.0, 48.0)
	pause_restart_button.pressed.connect(func() -> void: restart_requested.emit())
	vbox.add_child(pause_restart_button)

	pause_garage_button = Button.new()
	pause_garage_button.name = "PauseGarageButton"
	pause_garage_button.text = "Garage & Upgrades"
	pause_garage_button.custom_minimum_size = Vector2(280.0, 48.0)
	pause_garage_button.pressed.connect(func() -> void: garage_requested.emit())
	vbox.add_child(pause_garage_button)

	pause_settings_button = Button.new()
	pause_settings_button.name = "PauseSettingsButton"
	pause_settings_button.text = "Settings & Save"
	pause_settings_button.custom_minimum_size = Vector2(280.0, 48.0)
	pause_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	vbox.add_child(pause_settings_button)

	pause_main_menu_button = Button.new()
	pause_main_menu_button.name = "PauseMainMenuButton"
	pause_main_menu_button.text = "Main Menu"
	pause_main_menu_button.custom_minimum_size = Vector2(280.0, 48.0)
	pause_main_menu_button.pressed.connect(func() -> void: main_menu_requested.emit())
	vbox.add_child(pause_main_menu_button)

func _build_complete_modal() -> void:
	complete_modal_backdrop = ColorRect.new()
	complete_modal_backdrop.name = "LevelCompleteModalBackdrop"
	complete_modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	complete_modal_backdrop.color = Color(0.03, 0.09, 0.04, 0.76)
	complete_modal_backdrop.visible = false
	complete_modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(complete_modal_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	complete_modal_backdrop.add_child(center)

	var card := PanelContainer.new()
	card.name = "LevelCompleteCard"
	card.custom_minimum_size = Vector2(540.0, 330.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.22, 0.12, 0.97)
	style.border_color = Color(0.95, 0.82, 0.28, 0.98)
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	complete_title_label = Label.new()
	complete_title_label.name = "CompleteTitleLabel"
	complete_title_label.text = "GARDEN COMPLETE!"
	complete_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	complete_title_label.add_theme_font_size_override("font_size", 28)
	complete_title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.38))
	vbox.add_child(complete_title_label)

	complete_stars_label = Label.new()
	complete_stars_label.name = "CompleteStarsLabel"
	complete_stars_label.text = "Rating: [ * * * ] (3 / 3 Stars)"
	complete_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	complete_stars_label.add_theme_font_size_override("font_size", 20)
	complete_stars_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.65))
	vbox.add_child(complete_stars_label)

	complete_stats_label = Label.new()
	complete_stats_label.name = "CompleteStatsLabel"
	complete_stats_label.text = "Mowed: 100% | Points: 0 | Time: 00:00"
	complete_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	complete_stats_label.add_theme_font_size_override("font_size", 15)
	complete_stats_label.add_theme_color_override("font_color", Color(0.88, 0.98, 0.86))
	vbox.add_child(complete_stats_label)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	complete_keep_mowing_button = Button.new()
	complete_keep_mowing_button.name = "KeepMowingButton"
	complete_keep_mowing_button.text = "Keep Mowing (100%)"
	complete_keep_mowing_button.custom_minimum_size = Vector2(165.0, 54.0)
	complete_keep_mowing_button.pressed.connect(func() -> void: keep_mowing_requested.emit())
	btn_row.add_child(complete_keep_mowing_button)

	complete_restart_button = Button.new()
	complete_restart_button.name = "CompleteRestartButton"
	complete_restart_button.text = "Play Again"
	complete_restart_button.custom_minimum_size = Vector2(145.0, 54.0)
	complete_restart_button.pressed.connect(func() -> void: restart_requested.emit())
	btn_row.add_child(complete_restart_button)

	complete_level_select_button = Button.new()
	complete_level_select_button.name = "CompleteLevelSelectButton"
	complete_level_select_button.text = "Level Select"
	complete_level_select_button.custom_minimum_size = Vector2(150.0, 54.0)
	complete_level_select_button.pressed.connect(func() -> void: level_select_requested.emit())
	btn_row.add_child(complete_level_select_button)

func update_objectives_display(
	level_title: String,
	completion_pct: float,
	elapsed_sec: float,
	eval_result: Dictionary,
	is_creative: bool = false
) -> void:
	if objective_title_label:
		if is_creative:
			objective_title_label.text = "Creative / Relax — " + level_title
		else:
			objective_title_label.text = level_title
	if timer_label:
		if is_creative:
			timer_label.text = "NO TIMER (∞)"
		else:
			var mins := int(elapsed_sec) / 60
			var secs := int(elapsed_sec) % 60
			timer_label.text = "%02d:%02d" % [mins, secs]
	if overall_progress_bar:
		overall_progress_bar.value = completion_pct

	if checklist_vbox == null:
		return

	if is_creative:
		while checklist_vbox.get_child_count() < 2:
			var lbl := Label.new()
			lbl.add_theme_font_size_override("font_size", 13)
			checklist_vbox.add_child(lbl)
		for idx in range(checklist_vbox.get_child_count()):
			var child_lbl := checklist_vbox.get_child(idx) as Label
			child_lbl.visible = idx < 2
		var lbl0 := checklist_vbox.get_child(0) as Label
		lbl0.text = "[ZEN] Free Mowing — No Timer, No Fail State, Max Blade Power (5)"
		lbl0.add_theme_color_override("font_color", Color(0.62, 0.98, 0.56))
		var lbl1 := checklist_vbox.get_child(1) as Label
		lbl1.text = "[∞] Unlimited Coins & All Upgrades Active | Lawn Cleared: %.1f%%" % completion_pct
		lbl1.add_theme_color_override("font_color", Color(0.90, 0.96, 0.88))
		return

	var items: Array = eval_result.get("items", [])
	while checklist_vbox.get_child_count() < items.size():
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 13)
		checklist_vbox.add_child(lbl)

	for i in range(checklist_vbox.get_child_count()):
		var lbl := checklist_vbox.get_child(i) as Label
		if i >= items.size():
			lbl.visible = false
			continue
		lbl.visible = true
		var item: Dictionary = items[i]
		var done: bool = bool(item.get("completed", false))
		var mark := "[DONE]" if done else "[    ]"
		var suffix := "%" if bool(item.get("is_percent", false)) else ""
		lbl.text = "%s %s (%d%s / %d%s)" % [
			mark,
			String(item.get("label", "")),
			int(item.get("current", 0)),
			suffix,
			int(item.get("target", 0)),
			suffix
		]
		if done:
			lbl.add_theme_color_override("font_color", Color(0.55, 0.98, 0.48))
		else:
			lbl.add_theme_color_override("font_color", Color(0.90, 0.95, 0.88))

func set_pause_modal_visible(show_modal: bool) -> void:
	if pause_modal_backdrop:
		pause_modal_backdrop.visible = show_modal

func show_level_complete_modal(
	level_title: String,
	stars: int,
	completion_pct: float,
	points: int,
	coins_reward: int,
	elapsed_sec: float
) -> void:
	if complete_modal_backdrop == null:
		return
	complete_modal_backdrop.visible = true
	if complete_title_label:
		if completion_pct >= 99.9:
			complete_title_label.text = "100% PERFECT GARDEN!"
		else:
			complete_title_label.text = "LEVEL COMPLETE!"
	if complete_stars_label:
		var star_str := ""
		for i in range(3):
			star_str += "★ " if i < stars else "☆ "
		complete_stars_label.text = "%s  (%d / 3 Stars)" % [star_str.strip_edges(), stars]
	if complete_stats_label:
		var mins := int(elapsed_sec) / 60
		var secs := int(elapsed_sec) % 60
		complete_stats_label.text = (
			"%s\nMowed: %.1f%%  |  Points: %d  |  Reward: +%d Coins (Balance: ∞)  |  Time: %02d:%02d"
			% [level_title, completion_pct, points, coins_reward, mins, secs]
		)
	if complete_keep_mowing_button:
		complete_keep_mowing_button.visible = completion_pct < 99.9

func hide_level_complete_modal() -> void:
	if complete_modal_backdrop:
		complete_modal_backdrop.visible = false

func apply_responsive_layout(viewport_size: Vector2, text_scale: float = 1.0) -> void:
	var aspect: float = viewport_size.x / maxf(viewport_size.y, 1.0)
	var safe_inset: float = 48.0 if aspect >= 2.0 else 24.0
	if objective_panel:
		objective_panel.offset_left = safe_inset
		objective_panel.offset_right = safe_inset + 368.0
	if top_right_hbox:
		top_right_hbox.offset_right = -safe_inset
		top_right_hbox.offset_left = -safe_inset - 630.0
	if objective_title_label:
		objective_title_label.add_theme_font_size_override("font_size", int(round(15.0 * text_scale)))
	if timer_label:
		timer_label.add_theme_font_size_override("font_size", int(round(14.0 * text_scale)))
