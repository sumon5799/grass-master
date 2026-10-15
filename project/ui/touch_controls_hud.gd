extends Control
class_name TouchControlsHUD

## Step 4 — Mobile Touch Controls & Camera Framing HUD.
## Provides:
## - Left-thumb virtual analog joystick (touch + mouse drag)
## - Right-side swipe steering fallback
## - Large >= 48dp Boost button and Camera Zoom (+/-) buttons

signal joystick_changed(vector: Vector2)
signal boost_toggled(active: bool)
signal zoom_requested(delta_zoom: float)

const JOYSTICK_BASE_RADIUS: float = 72.0
const JOYSTICK_KNOB_RADIUS: float = 28.0
const JOYSTICK_MAX_RANGE: float = 54.0

var joystick_vector: Vector2 = Vector2.ZERO
var _joystick_touch_index: int = -1
var _swipe_touch_index: int = -1
var _joystick_center: Vector2 = Vector2(124.0, 580.0)
var _knob_offset: Vector2 = Vector2.ZERO
var _swipe_origin: Vector2 = Vector2.ZERO

var boost_button: Button
var zoom_in_button: Button
var zoom_out_button: Button
var controls_hint_label: Label

func _ready() -> void:
	name = "TouchControlsHUD"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_action_buttons()
	_update_joystick_center()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_joystick_center()
		queue_redraw()

func _update_joystick_center() -> void:
	var rect_size := get_viewport_rect().size
	if rect_size.x <= 128.0 or rect_size.y <= 128.0:
		rect_size = Vector2(1280.0, 720.0)
	_joystick_center = Vector2(136.0, rect_size.y - 132.0)

func _build_action_buttons() -> void:
	# Right-side action container inside safe margins
	var right_panel := VBoxContainer.new()
	right_panel.name = "RightControlsBox"
	right_panel.anchor_left = 1.0
	right_panel.anchor_top = 1.0
	right_panel.anchor_right = 1.0
	right_panel.anchor_bottom = 1.0
	right_panel.offset_left = -210.0
	right_panel.offset_top = -230.0
	right_panel.offset_right = -28.0
	right_panel.offset_bottom = -28.0
	right_panel.add_theme_constant_override("separation", 12)
	add_child(right_panel)

	var zoom_row := HBoxContainer.new()
	zoom_row.name = "ZoomRow"
	zoom_row.alignment = BoxContainer.ALIGNMENT_END
	zoom_row.add_theme_constant_override("separation", 10)
	right_panel.add_child(zoom_row)

	zoom_in_button = Button.new()
	zoom_in_button.name = "ZoomInButton"
	zoom_in_button.text = "Zoom +"
	zoom_in_button.custom_minimum_size = Vector2(84.0, 54.0)
	zoom_in_button.pressed.connect(func() -> void: zoom_requested.emit(-0.12))
	zoom_row.add_child(zoom_in_button)

	zoom_out_button = Button.new()
	zoom_out_button.name = "ZoomOutButton"
	zoom_out_button.text = "Zoom -"
	zoom_out_button.custom_minimum_size = Vector2(84.0, 54.0)
	zoom_out_button.pressed.connect(func() -> void: zoom_requested.emit(0.12))
	zoom_row.add_child(zoom_out_button)

	boost_button = Button.new()
	boost_button.name = "BoostButton"
	boost_button.text = "BOOST"
	boost_button.custom_minimum_size = Vector2(178.0, 68.0)
	boost_button.button_down.connect(func() -> void: boost_toggled.emit(true))
	boost_button.button_up.connect(func() -> void: boost_toggled.emit(false))
	right_panel.add_child(boost_button)

	controls_hint_label = Label.new()
	controls_hint_label.name = "ControlsHintLabel"
	controls_hint_label.text = "Touch Joystick / Swipe | WASD / Arrows + Space"
	controls_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls_hint_label.add_theme_font_size_override("font_size", 14)
	controls_hint_label.add_theme_color_override("font_color", Color(0.92, 0.98, 0.88, 0.90))
	right_panel.add_child(controls_hint_label)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _is_in_joystick_zone(touch.position) and _joystick_touch_index == -1:
				_joystick_touch_index = touch.index
				_update_joystick_from_screen_pos(touch.position)
			elif _is_in_swipe_zone(touch.position) and _swipe_touch_index == -1:
				_swipe_touch_index = touch.index
				_swipe_origin = touch.position
		else:
			if touch.index == _joystick_touch_index:
				_joystick_touch_index = -1
				_reset_joystick()
			elif touch.index == _swipe_touch_index:
				_swipe_touch_index = -1
				if _joystick_touch_index == -1:
					_reset_joystick()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _joystick_touch_index:
			_update_joystick_from_screen_pos(drag.position)
		elif drag.index == _swipe_touch_index:
			var delta_vec := (drag.position - _swipe_origin) / JOYSTICK_MAX_RANGE
			set_simulated_joystick(delta_vec)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_requested.emit(-0.10)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_requested.emit(0.10)

func _is_in_joystick_zone(pos: Vector2) -> bool:
	var rect_size := get_viewport_rect().size
	if rect_size.x <= 128.0:
		rect_size = Vector2(1280.0, 720.0)
	return pos.x <= rect_size.x * 0.45 and pos.y >= rect_size.y * 0.35

func _is_in_swipe_zone(pos: Vector2) -> bool:
	var rect_size := get_viewport_rect().size
	if rect_size.x <= 128.0:
		rect_size = Vector2(1280.0, 720.0)
	return pos.x > rect_size.x * 0.45 and pos.y >= rect_size.y * 0.25 and pos.y < rect_size.y - 190.0

func _update_joystick_from_screen_pos(pos: Vector2) -> void:
	var diff := pos - _joystick_center
	if diff.length() > JOYSTICK_MAX_RANGE:
		_knob_offset = diff.normalized() * JOYSTICK_MAX_RANGE
	else:
		_knob_offset = diff
	joystick_vector = _knob_offset / JOYSTICK_MAX_RANGE
	joystick_changed.emit(joystick_vector)
	queue_redraw()

func set_simulated_joystick(vec: Vector2) -> void:
	var clamped := vec
	if clamped.length() > 1.0:
		clamped = clamped.normalized()
	joystick_vector = clamped
	_knob_offset = clamped * JOYSTICK_MAX_RANGE
	joystick_changed.emit(joystick_vector)
	queue_redraw()

func _reset_joystick() -> void:
	joystick_vector = Vector2.ZERO
	_knob_offset = Vector2.ZERO
	joystick_changed.emit(Vector2.ZERO)
	queue_redraw()

func _draw() -> void:
	# Outer soft translucent joystick base ring
	draw_circle(_joystick_center, JOYSTICK_BASE_RADIUS, Color(0.08, 0.16, 0.10, 0.52))
	draw_arc(_joystick_center, JOYSTICK_BASE_RADIUS, 0.0, TAU, 36, Color(0.56, 0.88, 0.48, 0.82), 3.0)
	# Direction crosshairs
	draw_line(
		_joystick_center + Vector2(-JOYSTICK_BASE_RADIUS * 0.65, 0.0),
		_joystick_center + Vector2(JOYSTICK_BASE_RADIUS * 0.65, 0.0),
		Color(0.56, 0.88, 0.48, 0.28),
		2.0
	)
	draw_line(
		_joystick_center + Vector2(0.0, -JOYSTICK_BASE_RADIUS * 0.65),
		_joystick_center + Vector2(0.0, JOYSTICK_BASE_RADIUS * 0.65),
		Color(0.56, 0.88, 0.48, 0.28),
		2.0
	)
	# Inner analog thumb knob
	var knob_pos := _joystick_center + _knob_offset
	draw_circle(knob_pos, JOYSTICK_KNOB_RADIUS, Color(0.32, 0.78, 0.28, 0.92))
	draw_arc(knob_pos, JOYSTICK_KNOB_RADIUS, 0.0, TAU, 24, Color(0.92, 0.99, 0.88, 0.95), 2.5)
