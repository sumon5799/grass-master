extends Control
class_name MenuSystemOverlay

## Step 8 — Original Main Menu, Level Select, Garage, Settings & Credits UI System.
## Implements Spec Section 5E & Step 8:
## - Main Menu: Play, Level Select, Garage, Creative Mode, Settings, Credits
## - Level Select: All levels unlocked from first launch, mode selector (Normal / Creative / Challenge),
##   objective summary, star badge & best time display
## - Garage: Mower preview card, 4 mower types, 4 skins, 5 upgrade toggles, 4 safe strength sliders,
##   all-unlocked labels, Unlimited Coins (∞)
## - Settings: Master/Music/SFX volume, Vibration toggle, Camera Zoom & Sensitivity,
##   Graphics Quality (Low/Medium/High), Large Text toggle (1.0x / 1.25x), and Reset Local Save
## - Responsive layout for multiple aspect ratios (16:9, 20:9, 21:9, 4:3) and large text scaling

signal play_requested()
signal creative_play_requested()
signal level_launch_requested(level_id: String, mode: int)
signal garage_customization_changed(mower_type: String, skin_id: String)
signal upgrade_toggled(upgrade_id: String, enabled: bool)
signal strength_changed(move_speed: float, cutting_radius: float, blade_power: int, boost_mult: float)
signal settings_changed(
	master_vol: float,
	music_vol: float,
	sfx_vol: float,
	vibration_on: bool,
	cam_zoom: float,
	cam_sens: float,
	gfx_quality: String,
	text_scale: float
)
signal reset_save_requested()

enum Screen {
	NONE = 0,
	MAIN_MENU = 1,
	LEVEL_SELECT = 2,
	GARAGE = 3,
	SETTINGS = 4,
	CREDITS = 5
}

var current_screen: int = Screen.NONE
var current_text_scale: float = 1.0

var root_backdrop: ColorRect
var safe_margin: MarginContainer

var main_menu_panel: PanelContainer
var level_select_panel: PanelContainer
var garage_panel: PanelContainer
var settings_panel: PanelContainer
var credits_panel: PanelContainer

# Main Menu buttons
var play_button: Button
var level_select_button: Button
var garage_button: Button
var creative_mode_button: Button
var settings_button: Button
var credits_button: Button

# Level Select widgets
var level_cards_hbox: HBoxContainer
var mode_selector_button: Button
var selected_launch_mode: int = 0

# Garage widgets
var garage_preview_label: Label
var garage_swatch_rect: ColorRect
var mower_type_buttons: Dictionary = {}
var skin_buttons: Dictionary = {}
var upgrade_checkboxes: Dictionary = {}
var garage_speed_slider: HSlider
var garage_radius_slider: HSlider
var garage_power_slider: HSlider
var garage_boost_slider: HSlider

# Settings widgets
var master_vol_slider: HSlider
var music_vol_slider: HSlider
var sfx_vol_slider: HSlider
var vibration_check: CheckButton
var cam_zoom_slider: HSlider
var cam_sens_slider: HSlider
var gfx_quality_button: Button
var large_text_check: CheckButton
var reset_save_button: Button
var reset_status_label: Label

var _scalable_labels: Array[Dictionary] = []
var _scalable_buttons: Array[Dictionary] = []

func _ready() -> void:
	name = "MenuSystemOverlay"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	root_backdrop = ColorRect.new()
	root_backdrop.name = "MenuBackdrop"
	root_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_backdrop.color = Color(0.03, 0.09, 0.05, 0.86)
	root_backdrop.visible = false
	root_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_backdrop)

	safe_margin = MarginContainer.new()
	safe_margin.name = "MenuSafeMargin"
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_theme_constant_override("margin_left", 36)
	safe_margin.add_theme_constant_override("margin_right", 36)
	safe_margin.add_theme_constant_override("margin_top", 24)
	safe_margin.add_theme_constant_override("margin_bottom", 24)
	root_backdrop.add_child(safe_margin)

	var center := CenterContainer.new()
	center.name = "MenuCenterContainer"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_child(center)

	_build_main_menu(center)
	_build_level_select(center)
	_build_garage(center)
	_build_settings(center)
	_build_credits(center)

func _register_label(lbl: Label, base_size: int) -> void:
	lbl.add_theme_font_size_override("font_size", base_size)
	_scalable_labels.append({"node": lbl, "base": base_size})

func _register_button(btn: Button, base_size: int = 15) -> void:
	btn.add_theme_font_size_override("font_size", base_size)
	_scalable_buttons.append({"node": btn, "base": base_size})

func _make_card_style(border_col: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.16, 0.09, 0.97)
	style.border_color = border_col
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.content_margin_left = 26.0
	style.content_margin_right = 26.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	return style

func _build_main_menu(parent: Control) -> void:
	main_menu_panel = PanelContainer.new()
	main_menu_panel.name = "MainMenuPanel"
	main_menu_panel.custom_minimum_size = Vector2(720.0, 440.0)
	main_menu_panel.add_theme_stylebox_override("panel", _make_card_style(Color(0.48, 0.92, 0.42)))
	main_menu_panel.visible = false
	parent.add_child(main_menu_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	main_menu_panel.add_child(vbox)

	var title := Label.new()
	title.name = "MainMenuTitle"
	title.text = "GRASS MASTER — SUNLIT GARDEN MOWER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.96, 1.0, 0.86))
	_register_label(title, 26)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "100% Offline Edition  •  Coins: ∞ (Unlimited)  •  All Levels, Mowers & Upgrades Unlocked"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.62, 0.98, 0.56))
	_register_label(sub, 14)
	vbox.add_child(sub)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(grid)

	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.text = "▶  Play Garden"
	play_button.custom_minimum_size = Vector2(310.0, 58.0)
	play_button.pressed.connect(func() -> void: play_requested.emit())
	_register_button(play_button, 17)
	grid.add_child(play_button)

	creative_mode_button = Button.new()
	creative_mode_button.name = "CreativeModeMenuButton"
	creative_mode_button.text = "∞  Creative / Relax Mode"
	creative_mode_button.custom_minimum_size = Vector2(310.0, 58.0)
	creative_mode_button.pressed.connect(func() -> void: creative_play_requested.emit())
	_register_button(creative_mode_button, 17)
	grid.add_child(creative_mode_button)

	level_select_button = Button.new()
	level_select_button.name = "LevelSelectButton"
	level_select_button.text = "★  Level Select (All Unlocked)"
	level_select_button.custom_minimum_size = Vector2(310.0, 56.0)
	level_select_button.pressed.connect(func() -> void: show_screen(Screen.LEVEL_SELECT))
	_register_button(level_select_button, 16)
	grid.add_child(level_select_button)

	garage_button = Button.new()
	garage_button.name = "GarageButton"
	garage_button.text = "⚙  Garage & Upgrades"
	garage_button.custom_minimum_size = Vector2(310.0, 56.0)
	garage_button.pressed.connect(func() -> void: show_screen(Screen.GARAGE))
	_register_button(garage_button, 16)
	grid.add_child(garage_button)

	settings_button = Button.new()
	settings_button.name = "SettingsButton"
	settings_button.text = "☰  Settings & Save"
	settings_button.custom_minimum_size = Vector2(310.0, 54.0)
	settings_button.pressed.connect(func() -> void: show_screen(Screen.SETTINGS))
	_register_button(settings_button, 15)
	grid.add_child(settings_button)

	credits_button = Button.new()
	credits_button.name = "CreditsButton"
	credits_button.text = "ℹ  Credits & Privacy"
	credits_button.custom_minimum_size = Vector2(310.0, 54.0)
	credits_button.pressed.connect(func() -> void: show_screen(Screen.CREDITS))
	_register_button(credits_button, 15)
	grid.add_child(credits_button)

func _build_level_select(parent: Control) -> void:
	level_select_panel = PanelContainer.new()
	level_select_panel.name = "LevelSelectPanel"
	level_select_panel.custom_minimum_size = Vector2(820.0, 460.0)
	level_select_panel.add_theme_stylebox_override("panel", _make_card_style(Color(0.55, 0.92, 0.46)))
	level_select_panel.visible = false
	parent.add_child(level_select_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	level_select_panel.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "SELECT GARDEN LEVEL — ALL UNLOCKED"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(0.96, 1.0, 0.88))
	_register_label(title, 22)
	header.add_child(title)

	mode_selector_button = Button.new()
	mode_selector_button.name = "LevelSelectModeButton"
	mode_selector_button.text = "Launch Mode: Normal"
	mode_selector_button.custom_minimum_size = Vector2(220.0, 48.0)
	mode_selector_button.pressed.connect(_cycle_launch_mode)
	_register_button(mode_selector_button, 14)
	header.add_child(mode_selector_button)

	level_cards_hbox = HBoxContainer.new()
	level_cards_hbox.name = "LevelCardsHBox"
	level_cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	level_cards_hbox.add_theme_constant_override("separation", 12)
	level_cards_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(level_cards_hbox)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(footer)

	var back_btn := Button.new()
	back_btn.name = "LevelSelectBackButton"
	back_btn.text = "← Back to Main Menu"
	back_btn.custom_minimum_size = Vector2(240.0, 52.0)
	back_btn.pressed.connect(func() -> void: show_screen(Screen.MAIN_MENU))
	_register_button(back_btn, 15)
	footer.add_child(back_btn)

func _cycle_launch_mode() -> void:
	selected_launch_mode = (selected_launch_mode + 1) % 3
	match selected_launch_mode:
		1:
			mode_selector_button.text = "Launch Mode: Creative ∞"
		2:
			mode_selector_button.text = "Launch Mode: Challenge"
		_:
			mode_selector_button.text = "Launch Mode: Normal"

func populate_level_cards(catalog: Array[Dictionary], best_times: Dictionary, completed_stars: Dictionary) -> void:
	if level_cards_hbox == null:
		return
	for child in level_cards_hbox.get_children():
		child.queue_free()

	for entry in catalog:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(245.0, 290.0)
		card.add_theme_stylebox_override("panel", _make_card_style(Color(0.42, 0.82, 0.38)))
		level_cards_hbox.add_child(card)

		var cvbox := VBoxContainer.new()
		cvbox.add_theme_constant_override("separation", 8)
		card.add_child(cvbox)

		var lid: String = String(entry.get("level_id", "level_01_sunlit_courtyard"))
		var ltitle := Label.new()
		ltitle.text = String(entry.get("title", lid))
		ltitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ltitle.add_theme_color_override("font_color", Color(0.98, 1.0, 0.88))
		_register_label(ltitle, 16)
		cvbox.add_child(ltitle)

		var badge := Label.new()
		var stars: int = int(completed_stars.get(lid, 0))
		var best_t: float = float(best_times.get(lid, -1.0))
		var time_str := ("%.1fs" % best_t) if best_t > 0.0 else "--"
		badge.text = "[UNLOCKED]  Stars: %d/3  |  Best: %s" % [stars, time_str]
		badge.add_theme_color_override("font_color", Color(0.62, 0.98, 0.56))
		_register_label(badge, 12)
		cvbox.add_child(badge)

		var summary := Label.new()
		summary.text = "%s\nDifficulty: %s" % [
			String(entry.get("objective_summary", "")),
			String(entry.get("difficulty", "Normal"))
		]
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
		summary.add_theme_color_override("font_color", Color(0.86, 0.94, 0.84))
		_register_label(summary, 13)
		cvbox.add_child(summary)

		var play_lvl_btn := Button.new()
		play_lvl_btn.name = "Launch_" + lid
		play_lvl_btn.text = "Start Level"
		play_lvl_btn.custom_minimum_size = Vector2(200.0, 50.0)
		play_lvl_btn.pressed.connect(func() -> void:
			level_launch_requested.emit(lid, selected_launch_mode)
		)
		_register_button(play_lvl_btn, 15)
		cvbox.add_child(play_lvl_btn)

func _build_garage(parent: Control) -> void:
	garage_panel = PanelContainer.new()
	garage_panel.name = "GaragePanel"
	garage_panel.custom_minimum_size = Vector2(820.0, 480.0)
	garage_panel.add_theme_stylebox_override("panel", _make_card_style(Color(0.95, 0.82, 0.28)))
	garage_panel.visible = false
	parent.add_child(garage_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	garage_panel.add_child(vbox)

	var title := Label.new()
	title.text = "GARAGE — MOWERS, SKINS & UPGRADES [ALL UNLOCKED • ∞ COINS]"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.94, 0.56))
	_register_label(title, 20)
	vbox.add_child(title)

	# Mower Preview Header Banner
	var preview_row := HBoxContainer.new()
	preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_row.add_theme_constant_override("separation", 12)
	vbox.add_child(preview_row)

	garage_swatch_rect = ColorRect.new()
	garage_swatch_rect.custom_minimum_size = Vector2(44.0, 32.0)
	garage_swatch_rect.color = Color(0.18, 0.78, 0.34)
	preview_row.add_child(garage_swatch_rect)

	garage_preview_label = Label.new()
	garage_preview_label.name = "GaragePreviewLabel"
	garage_preview_label.text = "Active Preview: standard_rotary  |  Skin: emerald_classic  |  Status: UNLOCKED (∞)"
	garage_preview_label.add_theme_color_override("font_color", Color(0.68, 1.0, 0.62))
	_register_label(garage_preview_label, 14)
	preview_row.add_child(garage_preview_label)

	# Mower Type selector row
	var mower_row := HBoxContainer.new()
	mower_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mower_row.add_theme_constant_override("separation", 8)
	vbox.add_child(mower_row)

	var mower_defs := [
		{"id": "standard_rotary", "label": "Rotary Deck [UNLOCKED]"},
		{"id": "twin_blade_pro", "label": "Twin-Blade [UNLOCKED]"},
		{"id": "turbo_hover_deck", "label": "Hover Deck [UNLOCKED]"},
		{"id": "heavy_topiary_sculptor", "label": "Sculptor [UNLOCKED]"}
	]
	for mdef in mower_defs:
		var mid: String = String(mdef["id"])
		var btn := Button.new()
		btn.name = "MowerBtn_" + mid
		btn.text = String(mdef["label"])
		btn.custom_minimum_size = Vector2(180.0, 44.0)
		btn.pressed.connect(func() -> void: _on_garage_mower_selected(mid))
		_register_button(btn, 12)
		mower_row.add_child(btn)
		mower_type_buttons[mid] = btn

	# Skin selector row
	var skin_row := HBoxContainer.new()
	skin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	skin_row.add_theme_constant_override("separation", 8)
	vbox.add_child(skin_row)

	var skin_defs := [
		{"id": "emerald_classic", "label": "Skin: Emerald [∞]"},
		{"id": "sunlit_gold", "label": "Skin: Sunlit Gold [∞]"},
		{"id": "cobalt_breeze", "label": "Skin: Cobalt [∞]"},
		{"id": "crimson_blazer", "label": "Skin: Crimson [∞]"}
	]
	for sdef in skin_defs:
		var sid: String = String(sdef["id"])
		var btn := Button.new()
		btn.name = "SkinBtn_" + sid
		btn.text = String(sdef["label"])
		btn.custom_minimum_size = Vector2(180.0, 44.0)
		btn.pressed.connect(func() -> void: _on_garage_skin_selected(sid))
		_register_button(btn, 12)
		skin_row.add_child(btn)
		skin_buttons[sid] = btn

	# Upgrade toggles row
	var upg_row := HBoxContainer.new()
	upg_row.alignment = BoxContainer.ALIGNMENT_CENTER
	upg_row.add_theme_constant_override("separation", 8)
	vbox.add_child(upg_row)

	var upg_defs := [
		{"id": "titanium_blades", "label": "Titanium Blades"},
		{"id": "wide_deck_expander", "label": "Wide Deck"},
		{"id": "high_torque_motor", "label": "High Torque"},
		{"id": "overdrive_booster", "label": "Overdrive"},
		{"id": "clipping_vortex", "label": "Clipping Vortex"}
	]
	for udef in upg_defs:
		var uid: String = String(udef["id"])
		var chk := CheckBox.new()
		chk.name = "UpgChk_" + uid
		chk.text = String(udef["label"])
		chk.button_pressed = true
		chk.toggled.connect(func(on: bool) -> void: upgrade_toggled.emit(uid, on))
		upg_row.add_child(chk)
		upgrade_checkboxes[uid] = chk

	# Safe strength tuning sliders inside Garage
	garage_speed_slider = _add_garage_slider(vbox, "Move Speed (4-16 m/s):", 4.0, 16.0, 0.5, 8.5)
	garage_radius_slider = _add_garage_slider(vbox, "Cutting Radius (0.85-3.2m):", 0.85, 3.20, 0.05, 1.45)
	garage_power_slider = _add_garage_slider(vbox, "Blade Power (1-5):", 1.0, 5.0, 1.0, 3.0)
	garage_boost_slider = _add_garage_slider(vbox, "Boost Multiplier (1.1-2.1x):", 1.10, 2.10, 0.05, 1.55)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 14)
	vbox.add_child(footer)

	var back_btn := Button.new()
	back_btn.name = "GarageBackButton"
	back_btn.text = "← Save & Back to Main Menu"
	back_btn.custom_minimum_size = Vector2(240.0, 48.0)
	back_btn.pressed.connect(func() -> void: show_screen(Screen.MAIN_MENU))
	_register_button(back_btn, 14)
	footer.add_child(back_btn)

	var play_now_btn := Button.new()
	play_now_btn.name = "GaragePlayNowButton"
	play_now_btn.text = "▶ Test Mower in Garden"
	play_now_btn.custom_minimum_size = Vector2(240.0, 48.0)
	play_now_btn.pressed.connect(func() -> void: play_requested.emit())
	_register_button(play_now_btn, 14)
	footer.add_child(play_now_btn)

func _add_garage_slider(parent: VBoxContainer, label_text: String, min_v: float, max_v: float, step_v: float, init_v: float) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(215.0, 24.0)
	_register_label(lbl, 13)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = init_v
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(220.0, 26.0)
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size = Vector2(64.0, 24.0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.text = "%.2f" % init_v
	_register_label(val_lbl, 13)
	row.add_child(val_lbl)

	slider.value_changed.connect(func(v: float) -> void:
		val_lbl.text = "%.2f" % v
		_emit_garage_strength()
	)
	return slider

var _selected_mower_type: String = "standard_rotary"
var _selected_skin_id: String = "emerald_classic"

func _on_garage_mower_selected(mower_id: String) -> void:
	_selected_mower_type = mower_id
	_update_garage_preview_banner()
	garage_customization_changed.emit(_selected_mower_type, _selected_skin_id)

func _on_garage_skin_selected(skin_id: String) -> void:
	_selected_skin_id = skin_id
	_update_garage_preview_banner()
	garage_customization_changed.emit(_selected_mower_type, _selected_skin_id)

func _update_garage_preview_banner() -> void:
	if garage_preview_label:
		garage_preview_label.text = (
			"Active Preview: %s  |  Skin: %s  |  Status: UNLOCKED (∞)"
			% [_selected_mower_type, _selected_skin_id]
		)
	if garage_swatch_rect:
		match _selected_skin_id:
			"sunlit_gold":
				garage_swatch_rect.color = Color(0.98, 0.78, 0.16)
			"cobalt_breeze":
				garage_swatch_rect.color = Color(0.20, 0.56, 0.96)
			"crimson_blazer":
				garage_swatch_rect.color = Color(0.92, 0.24, 0.18)
			_:
				garage_swatch_rect.color = Color(0.18, 0.78, 0.34)

func _emit_garage_strength() -> void:
	if garage_speed_slider == null or garage_radius_slider == null or garage_power_slider == null or garage_boost_slider == null:
		return
	strength_changed.emit(
		float(garage_speed_slider.value),
		float(garage_radius_slider.value),
		int(round(garage_power_slider.value)),
		float(garage_boost_slider.value)
	)

func _build_settings(parent: Control) -> void:
	settings_panel = PanelContainer.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.custom_minimum_size = Vector2(780.0, 470.0)
	settings_panel.add_theme_stylebox_override("panel", _make_card_style(Color(0.45, 0.88, 0.92)))
	settings_panel.visible = false
	parent.add_child(settings_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	settings_panel.add_child(vbox)

	var title := Label.new()
	title.text = "SETTINGS — AUDIO, CAMERA, GRAPHICS & LOCAL SAVE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0))
	_register_label(title, 20)
	vbox.add_child(title)

	master_vol_slider = _add_settings_slider(vbox, "Master Volume:", 0.0, 1.0, 0.05, 0.85)
	music_vol_slider = _add_settings_slider(vbox, "Music Volume:", 0.0, 1.0, 0.05, 0.70)
	sfx_vol_slider = _add_settings_slider(vbox, "SFX Volume:", 0.0, 1.0, 0.05, 0.85)
	cam_zoom_slider = _add_settings_slider(vbox, "Camera Zoom (0.65-1.45x):", 0.65, 1.45, 0.05, 1.00)
	cam_sens_slider = _add_settings_slider(vbox, "Camera Sensitivity:", 0.50, 2.00, 0.05, 1.00)

	var toggles_row := HBoxContainer.new()
	toggles_row.alignment = BoxContainer.ALIGNMENT_CENTER
	toggles_row.add_theme_constant_override("separation", 14)
	vbox.add_child(toggles_row)

	vibration_check = CheckButton.new()
	vibration_check.name = "VibrationCheckButton"
	vibration_check.text = "Haptics / Vibration"
	vibration_check.button_pressed = true
	vibration_check.toggled.connect(func(_v: bool) -> void: _emit_settings_changed())
	toggles_row.add_child(vibration_check)

	gfx_quality_button = Button.new()
	gfx_quality_button.name = "GraphicsQualityButton"
	gfx_quality_button.text = "Graphics: High"
	gfx_quality_button.custom_minimum_size = Vector2(175.0, 44.0)
	gfx_quality_button.pressed.connect(_cycle_graphics_quality)
	_register_button(gfx_quality_button, 13)
	toggles_row.add_child(gfx_quality_button)

	large_text_check = CheckButton.new()
	large_text_check.name = "LargeTextCheckButton"
	large_text_check.text = "Large Text (1.25x)"
	large_text_check.button_pressed = false
	large_text_check.toggled.connect(func(_v: bool) -> void: _emit_settings_changed())
	toggles_row.add_child(large_text_check)

	reset_status_label = Label.new()
	reset_status_label.name = "ResetSaveStatusLabel"
	reset_status_label.text = "Local Save: Active (Schema v2 • 100% Offline • Auto-Backup Enabled)"
	reset_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reset_status_label.add_theme_color_override("font_color", Color(0.72, 0.96, 0.78))
	_register_label(reset_status_label, 13)
	vbox.add_child(reset_status_label)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 16)
	vbox.add_child(footer)

	reset_save_button = Button.new()
	reset_save_button.name = "ResetSaveButton"
	reset_save_button.text = "↺ Reset Local Save Data"
	reset_save_button.custom_minimum_size = Vector2(230.0, 48.0)
	reset_save_button.pressed.connect(_on_reset_save_pressed)
	_register_button(reset_save_button, 14)
	footer.add_child(reset_save_button)

	var back_btn := Button.new()
	back_btn.name = "SettingsBackButton"
	back_btn.text = "← Apply & Back to Main Menu"
	back_btn.custom_minimum_size = Vector2(250.0, 48.0)
	back_btn.pressed.connect(func() -> void: show_screen(Screen.MAIN_MENU))
	_register_button(back_btn, 14)
	footer.add_child(back_btn)

func _add_settings_slider(parent: VBoxContainer, label_text: String, min_v: float, max_v: float, step_v: float, init_v: float) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(215.0, 24.0)
	_register_label(lbl, 13)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = init_v
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(220.0, 26.0)
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size = Vector2(64.0, 24.0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.text = "%.2f" % init_v
	_register_label(val_lbl, 13)
	row.add_child(val_lbl)

	slider.value_changed.connect(func(v: float) -> void:
		val_lbl.text = "%.2f" % v
		_emit_settings_changed()
	)
	return slider

var _gfx_quality_state: String = "High"

func _cycle_graphics_quality() -> void:
	match _gfx_quality_state:
		"High":
			_gfx_quality_state = "Medium"
		"Medium":
			_gfx_quality_state = "Low"
		_:
			_gfx_quality_state = "High"
	if gfx_quality_button:
		gfx_quality_button.text = "Graphics: " + _gfx_quality_state
	_emit_settings_changed()

func _emit_settings_changed() -> void:
	if master_vol_slider == null or music_vol_slider == null or sfx_vol_slider == null:
		return
	var t_scale: float = 1.25 if (large_text_check and large_text_check.button_pressed) else 1.0
	set_text_scale(t_scale)
	settings_changed.emit(
		float(master_vol_slider.value),
		float(music_vol_slider.value),
		float(sfx_vol_slider.value),
		bool(vibration_check.button_pressed) if vibration_check else true,
		float(cam_zoom_slider.value) if cam_zoom_slider else 1.0,
		float(cam_sens_slider.value) if cam_sens_slider else 1.0,
		_gfx_quality_state,
		t_scale
	)

func _on_reset_save_pressed() -> void:
	reset_save_requested.emit()
	if reset_status_label:
		reset_status_label.text = "Local Save Reset to Defaults! (All Levels & ∞ Coins Preserved)"

func _build_credits(parent: Control) -> void:
	credits_panel = PanelContainer.new()
	credits_panel.name = "CreditsPanel"
	credits_panel.custom_minimum_size = Vector2(680.0, 380.0)
	credits_panel.add_theme_stylebox_override("panel", _make_card_style(Color(0.55, 0.90, 0.55)))
	credits_panel.visible = false
	parent.add_child(credits_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	credits_panel.add_child(vbox)

	var title := Label.new()
	title.text = "CREDITS & OFFLINE PRIVACY GUARANTEE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.96, 1.0, 0.88))
	_register_label(title, 22)
	vbox.add_child(title)

	var body := Label.new()
	body.text = (
		"Grass Master — Original 3D Zen Lawn Mowing Game\n"
		+ "• Built with Godot Engine 4.3 (100% original procedural 3D meshes, materials & audio)\n"
		+ "• Zero network requests, zero telemetry, zero ads, zero in-app purchases\n"
		+ "• Works completely offline in Airplane Mode from first launch\n"
		+ "• All levels, mowers, skins, and upgrades are permanently unlocked locally"
	)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", Color(0.86, 0.96, 0.84))
	_register_label(body, 15)
	vbox.add_child(body)

	var back_btn := Button.new()
	back_btn.name = "CreditsBackButton"
	back_btn.text = "← Back to Main Menu"
	back_btn.custom_minimum_size = Vector2(240.0, 52.0)
	back_btn.pressed.connect(func() -> void: show_screen(Screen.MAIN_MENU))
	_register_button(back_btn, 15)
	vbox.add_child(back_btn)

func show_screen(screen: int) -> void:
	current_screen = screen
	if root_backdrop == null:
		return
	root_backdrop.visible = (screen != Screen.NONE)
	if main_menu_panel:
		main_menu_panel.visible = (screen == Screen.MAIN_MENU)
	if level_select_panel:
		level_select_panel.visible = (screen == Screen.LEVEL_SELECT)
	if garage_panel:
		garage_panel.visible = (screen == Screen.GARAGE)
	if settings_panel:
		settings_panel.visible = (screen == Screen.SETTINGS)
	if credits_panel:
		credits_panel.visible = (screen == Screen.CREDITS)

func is_menu_open() -> bool:
	return current_screen != Screen.NONE

func sync_from_profile(profile: RefCounted) -> void:
	if profile == null:
		return
	_selected_mower_type = String(profile.get("selected_mower_type"))
	_selected_skin_id = String(profile.get("selected_skin"))
	_update_garage_preview_banner()

	if garage_speed_slider:
		garage_speed_slider.set_value_no_signal(float(profile.get("configured_move_speed")))
	if garage_radius_slider:
		garage_radius_slider.set_value_no_signal(float(profile.get("configured_cutting_radius")))
	if garage_power_slider:
		garage_power_slider.set_value_no_signal(float(profile.get("configured_blade_power")))
	if garage_boost_slider:
		garage_boost_slider.set_value_no_signal(float(profile.get("configured_boost_multiplier")))

	for uid in upgrade_checkboxes.keys():
		var chk: CheckBox = upgrade_checkboxes[uid]
		if chk and profile.has_method("is_upgrade_enabled"):
			chk.set_pressed_no_signal(bool(profile.call("is_upgrade_enabled", uid)))

	if master_vol_slider:
		master_vol_slider.set_value_no_signal(float(profile.get("master_volume")))
	if music_vol_slider:
		music_vol_slider.set_value_no_signal(float(profile.get("music_volume")))
	if sfx_vol_slider:
		sfx_vol_slider.set_value_no_signal(float(profile.get("sfx_volume")))
	if vibration_check:
		vibration_check.set_pressed_no_signal(bool(profile.get("vibration_enabled")))
	if cam_zoom_slider:
		cam_zoom_slider.set_value_no_signal(float(profile.get("camera_zoom")))
	if cam_sens_slider:
		cam_sens_slider.set_value_no_signal(float(profile.get("camera_sensitivity")))
	_gfx_quality_state = String(profile.get("graphics_quality"))
	if gfx_quality_button:
		gfx_quality_button.text = "Graphics: " + _gfx_quality_state
	var t_scale: float = float(profile.get("ui_text_scale"))
	if large_text_check:
		large_text_check.set_pressed_no_signal(t_scale >= 1.15)
	set_text_scale(t_scale)

func set_text_scale(scale_factor: float) -> void:
	current_text_scale = clampf(scale_factor, 1.0, 1.35)
	for item in _scalable_labels:
		var lbl: Label = item["node"]
		if is_instance_valid(lbl):
			lbl.add_theme_font_size_override("font_size", int(round(float(item["base"]) * current_text_scale)))
	for item in _scalable_buttons:
		var btn: Button = item["node"]
		if is_instance_valid(btn):
			btn.add_theme_font_size_override("font_size", int(round(float(item["base"]) * current_text_scale)))

func adapt_to_viewport(viewport_size: Vector2, text_scale: float = current_text_scale) -> Dictionary:
	set_text_scale(text_scale)
	var w: float = maxf(viewport_size.x, 640.0)
	var h: float = maxf(viewport_size.y, 480.0)
	var aspect: float = w / h

	# Safe area inset adaptation for notched ultra-wide phones (20:9, 21:9) vs 16:9 / 4:3
	var horiz_margin: int = 56 if aspect >= 2.0 else (32 if aspect >= 1.6 else 20)
	var vert_margin: int = 24 if h >= 700.0 else 14
	if safe_margin:
		safe_margin.add_theme_constant_override("margin_left", horiz_margin)
		safe_margin.add_theme_constant_override("margin_right", horiz_margin)
		safe_margin.add_theme_constant_override("margin_top", vert_margin)
		safe_margin.add_theme_constant_override("margin_bottom", vert_margin)

	var max_card_w: float = clampf(w - float(horiz_margin * 2) - 24.0, 580.0, 860.0)
	var max_card_h: float = clampf(h - float(vert_margin * 2) - 20.0, 380.0, 500.0)

	if main_menu_panel:
		main_menu_panel.custom_minimum_size = Vector2(minf(720.0, max_card_w), minf(430.0, max_card_h))
	if level_select_panel:
		level_select_panel.custom_minimum_size = Vector2(minf(820.0, max_card_w), minf(450.0, max_card_h))
	if garage_panel:
		garage_panel.custom_minimum_size = Vector2(minf(820.0, max_card_w), minf(470.0, max_card_h))
	if settings_panel:
		settings_panel.custom_minimum_size = Vector2(minf(780.0, max_card_w), minf(460.0, max_card_h))
	if credits_panel:
		credits_panel.custom_minimum_size = Vector2(minf(680.0, max_card_w), minf(380.0, max_card_h))

	var fits_horizontally: bool = max_card_w <= (w - float(horiz_margin * 2) + 1.0)
	var fits_vertically: bool = max_card_h <= (h - float(vert_margin * 2) + 1.0)
	return {
		"viewport": viewport_size,
		"aspect": snappedf(aspect, 0.01),
		"horiz_margin": horiz_margin,
		"vert_margin": vert_margin,
		"card_max_size": Vector2(max_card_w, max_card_h),
		"fits_bounds": fits_horizontally and fits_vertically
	}
