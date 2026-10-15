extends SceneTree

## Standalone script verification for Step 3 scripts and resources.
## Note: Full runtime scene-tree inspection runs via:
##   godot4 --headless --path /vercel/share/v0-project --quit-after 2 -- --verify-step3

func _init() -> void:
	var required_scripts := [
		"res://project/materials/garden_materials.gd",
		"res://project/scripts/mower_placeholder.gd",
		"res://project/scripts/garden_arena.gd",
		"res://project/scripts/main.gd",
	]

	for path in required_scripts:
		var scr := load(path) as Script
		if scr == null or not scr.can_instantiate():
			push_error("[TestStep3Scripts] FAIL: Script failed to load or compile: %s" % path)
			quit(1)
			return

	print("[TestStep3Scripts] PASS — All Step 3 scripts compiled and loaded cleanly.")
	quit(0)
