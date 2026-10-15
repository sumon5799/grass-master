extends SceneTree

## Automated compilation and instantiation check for Step 6 scripts.

func _init() -> void:
	var scripts := [
		"res://project/levels/level_config.gd",
		"res://project/ui/game_loop_overlay_hud.gd",
		"res://project/scripts/garden_arena.gd",
		"res://project/scripts/mower_placeholder.gd",
		"res://project/scripts/follow_camera.gd",
		"res://project/ui/touch_controls_hud.gd",
		"res://project/scripts/main.gd"
	]
	for path in scripts:
		var scr := load(path)
		if scr == null:
			push_error("[TestStep6Scripts] FAIL: Could not load " + path)
			quit(1)
			return
	print("[TestStep6Scripts] PASS — All Step 6 scripts compiled and loaded cleanly.")
	quit(0)
