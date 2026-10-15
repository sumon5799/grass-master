extends SceneTree

## Automated Step 4 script & class compilation test.
## Full runtime physics/boundary/camera verification runs via:
## godot4 --headless --path /vercel/share/v0-project --quit-after 3 -- --verify-step4

func _init() -> void:
	var scripts_to_verify := [
		"res://project/materials/garden_materials.gd",
		"res://project/scripts/mower_placeholder.gd",
		"res://project/scripts/follow_camera.gd",
		"res://project/ui/touch_controls_hud.gd",
		"res://project/scripts/garden_arena.gd",
		"res://project/scripts/main.gd",
	]
	for path in scripts_to_verify:
		var scr := load(path) as Script
		if scr == null or not scr.can_instantiate():
			push_error("[TestStep4Scripts] Failed to compile/load script: " + path)
			quit(1)
			return

	print("[TestStep4Scripts] PASS — All Step 4 scripts compiled and loaded cleanly.")
	quit(0)
