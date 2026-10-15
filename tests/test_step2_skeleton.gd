extends SceneTree
## Automated verification script for Step 2: Clean Godot Project Skeleton.

const EXPECTED_DIRS: Array[String] = [
	"res://project/scenes",
	"res://project/scripts",
	"res://project/materials",
	"res://project/models",
	"res://project/audio",
	"res://project/ui",
	"res://project/levels",
	"res://project/shaders",
	"res://tests",
	"res://build"
]

const EXPECTED_ACTIONS: Array[StringName] = [
	&"move_forward",
	&"move_backward",
	&"turn_left",
	&"turn_right",
	&"boost",
	&"pause"
]


func _init() -> void:
	var errors: Array[String] = []

	# 1. Verify project settings
	var app_name := str(ProjectSettings.get_setting("application/config/name"))
	var main_scene_path := str(ProjectSettings.get_setting("application/run/main_scene"))
	var vp_w := int(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var vp_h := int(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var orientation := int(ProjectSettings.get_setting("display/window/handheld/orientation"))
	var renderer := str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))

	if app_name != "Grass Master":
		errors.append("Unexpected application/config/name: " + app_name)
	if main_scene_path != "res://project/scenes/main.tscn":
		errors.append("Unexpected main_scene: " + main_scene_path)
	if vp_w != 1280 or vp_h != 720:
		errors.append("Unexpected viewport dimensions: %dx%d" % [vp_w, vp_h])
	if orientation != 0:
		errors.append("Expected landscape orientation (0), got: %d" % orientation)
	if renderer != "mobile":
		errors.append("Expected mobile renderer, got: " + renderer)

	# 2. Verify required directories exist
	for dir_path in EXPECTED_DIRS:
		if not DirAccess.dir_exists_absolute(dir_path):
			errors.append("Missing directory: " + dir_path)

	# 3. Verify input actions exist
	for action_name in EXPECTED_ACTIONS:
		if not InputMap.has_action(action_name):
			errors.append("Missing InputMap action: " + str(action_name))

	# 4. Load and instantiate startup scene
	var packed: PackedScene = load(main_scene_path)
	if packed == null:
		errors.append("Failed to load main scene: " + main_scene_path)
	else:
		var instance: Node = packed.instantiate()
		if instance == null:
			errors.append("Failed to instantiate main scene")
		else:
			root.add_child(instance)
			instance.free()

	if errors.is_empty():
		print("[TestStep2] PASS — Project skeleton, settings, folders, input actions, and startup scene verified.")
		quit(0)
	else:
		for err in errors:
			push_error("[TestStep2] FAIL: " + err)
		quit(1)
