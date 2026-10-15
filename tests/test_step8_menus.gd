extends SceneTree

## Headless verification test for Step 8 scripts (Menus, Garage, Settings & Save System).

func _init() -> void:
	var scripts_to_verify: Array[String] = [
		"res://project/scripts/player_profile.gd",
		"res://project/scripts/mower_placeholder.gd",
		"res://project/ui/menu_system_overlay.gd",
		"res://project/ui/game_loop_overlay_hud.gd",
		"res://project/scripts/main.gd",
	]
	for path in scripts_to_verify:
		var res := load(path)
		if res == null:
			push_error("[TestStep8Scripts] FAIL — Could not load script: " + path)
			quit(1)
			return
	print("[TestStep8Scripts] PASS — All Step 8 scripts compiled and loaded cleanly.")
	quit(0)
