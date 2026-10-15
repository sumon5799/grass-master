extends Control
class_name GameLoopOverlayHUD

## Step 6 — Core Game Loop UI Overlay.
## Provides:
## - Top-left Objective Tracker checklist + progress bar + timer
## - Top-right Pause & Restart quick-action buttons (>= 48dp touch targets)
## - Center Modal Pause Overlay (Resume, Restart Level)
## - Center Modal Level Complete Overlay (Stars, Stats, Play Again / Restart, Keep Mowing 100%)

signal pause_requested()
signal resume_requested()
signal restart_requested()
signal keep_mowing_requested()

var objective_title_label: Label
var timer_label: Label
var overall_progress_bar: ProgressBar
var checklist_vbox: VBoxContainer
var pause_top_button: Button
var restart_top_button: Button

var pause_modal_backdrop: ColorRect
var resume_button: Button
var pause_restart_button: Button

var complete_modal_backdrop: ColorRect
var complete_title_label: Label
var complete_stars_label: Label
var complete_stats_label: Label
var complete_restart_button: Button
var complete_keep_mowing_button: Button

func _ready() -> void:
	name = "GameLoopOverlayHUD"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_objective_panel()
	_build_top_right_buttons()
	_build_pause_modal()
	_build_complete_modal()

func _build_objective_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "ObjectiveTrackerPanel"
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.offset_left = 24.0
	panel.offset_top = 92.0
	panel.offset_right = 374.0
	panel.offset_bottom = 292.0
	panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.14, 0.08, 0.82)
	style.border_color = Color(0.45, 0.85, 0.38, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

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
	var top_right := HBoxContainer.new()
	top_right.name = "TopRightLoopButtons"
	top_right.anchor_left = 1.0
	top_right.anchor_right = 1.0
	top_right.offset_left = -254.0
	top_right.offset_top = 92.0
	top_right.offset_right = -24.0
	top_right.offset_bottom = 148.0
	top_right.alignment = BoxContainer.ALIGNMENT_END
	top_right.add_theme_constant_override("separation", 10)
	add_child(top_right)

	restart_top_button = Button.new()
	restart_top_button.name = "QuickRestartButton"
	restart_top_button.text = "Restart"
	restart_top_button.custom_minimum_size = Vector2(108.0, 52.0)
	restart_top_button.pressed.connect(func() -> void: restart_requested.emit())
	top_right.add_child(restart_top_button)

	pause_top_button = Button.new()
	pause_top_button.name = "PauseButton"
	pause_top_button.text = "Pause"
	pause_top_button.custom_minimum_size = Vector2(108.0, 52.0)
	pause_top_button.pressed.connect(func() -> void: pause_requested.emit())
	top_right.add_child(pause_top_button)

func _build_pause_modal() -> void:
	pause_modal_backdrop = ColorRect.new()
	pause_modal_backdrop.name = "PauseModalBackdrop"
	pause_modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_modal_backdrop.color = Color(0.02, 0.06, 0.03, 0.72)
	pause_modal_backdrop.visible = false
	pause_modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(pause_modal_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_modal_backdrop.add_child(center)

	var card := PanelContainer.new()
	card.name = "PauseCard"
	card.custom_minimum_size = Vector2(420.0, 260.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.19, 0.11, 0.96)
	style.border_color = Color(0.52, 0.90, 0.44, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	var title := Label.new()
	title.text = "GAME PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 1.0, 0.92))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Take a breather or restart the garden."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.92, 0.74))
	vbox.add_child(subtitle)

	resume_button = Button.new()
	resume_button.name = "ResumeButton"
	resume_button.text = "Resume Game"
	resume_button.custom_minimum_size = Vector2(260.0, 56.0)
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	vbox.add_child(resume_button)

	pause_restart_button = Button.new()
	pause_restart_button.name = "PauseRestartButton"
	pause_restart_button.text = "Restart Level"
	pause_restart_button.custom_minimum_size = Vector2(260.0, 56.0)
	pause_restart_button.pressed.connect(func() -> void: restart_requested.emit())
	vbox.add_child(pause_restart_button)

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
	card.custom_minimum_size = Vector2(460.0, 320.0)
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
	btn_row.add_theme_constant_override("separation", 14)
	vbox.add_child(btn_row)

	complete_keep_mowing_button = Button.new()
	complete_keep_mowing_button.name = "KeepMowingButton"
	complete_keep_mowing_button.text = "Keep Mowing (100%)"
	complete_keep_mowing_button.custom_minimum_size = Vector2(190.0, 56.0)
	complete_keep_mowing_button.pressed.connect(func() -> void: keep_mowing_requested.emit())
	btn_row.add_child(complete_keep_mowing_button)

	complete_restart_button = Button.new()
	complete_restart_button.name = "CompleteRestartButton"
	complete_restart_button.text = "Play Again"
	complete_restart_button.custom_minimum_size = Vector2(190.0, 56.0)
	complete_restart_button.pressed.connect(func() -> void: restart_requested.emit())
	btn_row.add_child(complete_restart_button)

func update_objectives_display(
	level_title: String,
	completion_pct: float,
	elapsed_sec: float,
	eval_result: Dictionary
) -> void:
	if objective_title_label:
		objective_title_label.text = level_title
	if timer_label:
		var mins := int(elapsed_sec) / 60
		var secs := int(elapsed_sec) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
	if overall_progress_bar:
		overall_progress_bar.value = completion_pct

	if checklist_vbox == null:
		return

	var items: Array = eval_result.get("items", [])
	while checklist_vbox.get_child_count() < items.size():
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 13)
		checklist_vbox.add_child(lbl)

	for i in range(items.size()):
		var item: Dictionary = items[i]
		var lbl := checklist_vbox.get_child(i) as Label
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
			"%s\nMowed: %.1f%%  |  Points: %d  |  Reward: +%d Coins  |  Time: %02d:%02d"
			% [level_title, completion_pct, points, coins_reward, mins, secs]
		)
	if complete_keep_mowing_button:
		complete_keep_mowing_button.visible = completion_pct < 99.9

func hide_level_complete_modal() -> void:
	if complete_modal_backdrop:
		complete_modal_backdrop.visible = false
