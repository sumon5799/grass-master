extends SceneTree

## Step 5 Automated Script & Resource Compilation Check
## Verifies that all Step 5 cutting, particle burst, and sound hook scripts load without errors.

func _init() -> void:
	var paths := [
		"res://project/materials/garden_materials.gd",
		"res://project/scripts/sound_hooks.gd",
		"res://project/scripts/clipping_burst_manager.gd",
		"res://project/scripts/mower_placeholder.gd",
		"res://project/scripts/garden_arena.gd",
		"res://project/scripts/main.gd",
		"res://project/scenes/main.tscn",
	]
	for p in paths:
		var res := ResourceLoader.load(p)
		if res == null:
			push_error("[TestStep5Scripts] Failed to load resource: " + p)
			quit(1)
			return
	print("[TestStep5Scripts] PASS — All Step 5 scripts and scenes compiled and loaded cleanly.")
	quit(0)
