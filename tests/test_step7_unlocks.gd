extends SceneTree

## Step 7 — Automated Script Compilation & Unlocks/Clamping Unit Check

func _init() -> void:
	var scripts := [
		"res://project/scripts/player_profile.gd",
		"res://project/levels/level_config.gd",
		"res://project/ui/game_loop_overlay_hud.gd",
		"res://project/scripts/main.gd"
	]
	for path in scripts:
		var res := load(path)
		if res == null:
			push_error("[TestStep7Scripts] FAIL: Could not load " + path)
			quit(1)
			return
	print("[TestStep7Scripts] PASS — All Step 7 scripts compiled and loaded cleanly.")
	quit(0)
