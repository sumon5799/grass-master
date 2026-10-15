extends Node3D
## Basic startup scene script for Step 2 (Clean Godot Project Skeleton).
## Verifies scene tree initialization, viewport settings, and input map actions.

const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_forward",
	&"move_backward",
	&"turn_left",
	&"turn_right",
	&"boost",
	&"pause"
]

@onready var status_label: Label = $StartupHUD/SafeMargin/StatusPanel/VBox/StatusLabel


func _ready() -> void:
	var missing_actions: Array[StringName] = []
	for action_name in REQUIRED_ACTIONS:
		if not InputMap.has_action(action_name):
			missing_actions.append(action_name)

	var vp_size: Vector2i = get_viewport().size
	if missing_actions.is_empty():
		var msg := "Grass Master Skeleton Ready | Viewport: %dx%d | Actions: %d OK" % [
			vp_size.x,
			vp_size.y,
			REQUIRED_ACTIONS.size()
		]
		if is_instance_valid(status_label):
			status_label.text = msg
		print("[Step2] ", msg)
	else:
		push_error("[Step2] Missing required input actions: %s" % [str(missing_actions)])
