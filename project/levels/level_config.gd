extends RefCounted

## Step 6 & Step 7 — Level Configuration & All-Level Catalog Definitions.
## Provides data-driven level metadata, objective goals, completion evaluation,
## star rating calculation, and full all-unlocked level catalog access.

var level_id: String = "level_01_sunlit_courtyard"
var level_number: int = 1
var title: String = "Level 1 — Sunlit Courtyard"
var subtitle: String = "Mow the courtyard grass, gather blossoms, and sculpt the shrubs."
var target_overall_percent: float = 85.0
var time_limit_seconds: float = 0.0
var three_star_time_seconds: float = 75.0
var two_star_time_seconds: float = 120.0
var base_coin_reward: int = 250
var initial_cutter_power: int = 3
var initial_cutting_radius: float = 1.45
var unlocked_by_default: bool = true

var objectives: Array[Dictionary] = []

static func get_all_level_ids() -> Array[String]:
	return [
		"level_01_sunlit_courtyard",
		"level_02_blossom_terrace",
		"level_03_royal_topiary_maze"
	]

static func get_level_catalog_summaries() -> Array[Dictionary]:
	return [
		{
			"id": "level_01_sunlit_courtyard",
			"number": 1,
			"title": "Level 1 — Sunlit Courtyard",
			"subtitle": "Mow 85% lawn, 35 flowers, 25 shrubs, 15 topiaries.",
			"unlocked": true
		},
		{
			"id": "level_02_blossom_terrace",
			"number": 2,
			"title": "Level 2 — Blossom Terrace",
			"subtitle": "Mow 90% lawn, 50 flowers, 35 shrubs, 25 topiaries.",
			"unlocked": true
		},
		{
			"id": "level_03_royal_topiary_maze",
			"number": 3,
			"title": "Level 3 — Royal Topiary Garden",
			"subtitle": "Mow 95% lawn, 55 flowers, 45 shrubs, 40 topiaries.",
			"unlocked": true
		}
	]

func configure_by_id(target_id: String) -> void:
	match target_id:
		"level_02_blossom_terrace":
			configure_level_2_blossom_terrace()
		"level_03_royal_topiary_maze":
			configure_level_3_royal_topiary_maze()
		_:
			configure_level_1_sunlit_courtyard()

func configure_level_1_sunlit_courtyard() -> void:
	level_id = "level_01_sunlit_courtyard"
	level_number = 1
	title = "Level 1 — Sunlit Courtyard"
	subtitle = "Mow the courtyard grass, gather blossoms, and sculpt the shrubs."
	target_overall_percent = 85.0
	time_limit_seconds = 0.0
	three_star_time_seconds = 75.0
	two_star_time_seconds = 120.0
	base_coin_reward = 250
	initial_cutter_power = 3
	initial_cutting_radius = 1.45
	unlocked_by_default = true
	objectives = [
		{
			"id": "mow_85_percent",
			"label": "Mow at least 85% of the garden",
			"type": "overall_percent",
			"plant_key": "",
			"target": 85
		},
		{
			"id": "harvest_flowers",
			"label": "Harvest 35 colorful flowers",
			"type": "plant_type_count",
			"plant_key": "colorful_flowers",
			"target": 35
		},
		{
			"id": "trim_shrubs",
			"label": "Trim 25 small shrubs",
			"type": "plant_type_count",
			"plant_key": "small_shrubs",
			"target": 25
		},
		{
			"id": "sculpt_topiary",
			"label": "Sculpt 15 large topiary plants",
			"type": "plant_type_count",
			"plant_key": "large_trim_plants",
			"target": 15
		}
	]

func configure_level_2_blossom_tertyard() -> void:
	configure_level_2_blossom_terrace()

func configure_level_2_blossom_terrace() -> void:
	level_id = "level_02_blossom_terrace"
	level_number = 2
	title = "Level 2 — Blossom Terrace"
	subtitle = "Clear a fuller terrace and harvest rich flower beds."
	target_overall_percent = 90.0
	time_limit_seconds = 0.0
	three_star_time_seconds = 85.0
	two_star_time_seconds = 135.0
	base_coin_reward = 350
	initial_cutter_power = 3
	initial_cutting_radius = 1.55
	unlocked_by_default = true
	objectives = [
		{
			"id": "mow_90_percent",
			"label": "Mow at least 90% of the garden",
			"type": "overall_percent",
			"plant_key": "",
			"target": 90
		},
		{
			"id": "harvest_flowers_50",
			"label": "Harvest 50 colorful flowers",
			"type": "plant_type_count",
			"plant_key": "colorful_flowers",
			"target": 50
		},
		{
			"id": "trim_shrubs_35",
			"label": "Trim 35 small shrubs",
			"type": "plant_type_count",
			"plant_key": "small_shrubs",
			"target": 35
		},
		{
			"id": "sculpt_topiary_25",
			"label": "Sculpt 25 large topiary plants",
			"type": "plant_type_count",
			"plant_key": "large_trim_plants",
			"target": 25
		}
	]

func configure_level_3_royal_topiary_maze() -> void:
	level_id = "level_03_royal_topiary_maze"
	level_number = 3
	title = "Level 3 — Royal Topiary Garden"
	subtitle = "Master precision mowing and sculpt dense ornamental topiaries."
	target_overall_percent = 95.0
	time_limit_seconds = 0.0
	three_star_time_seconds = 95.0
	two_star_time_seconds = 150.0
	base_coin_reward = 500
	initial_cutter_power = 3
	initial_cutting_radius = 1.65
	unlocked_by_default = true
	objectives = [
		{
			"id": "mow_95_percent",
			"label": "Mow at least 95% of the garden",
			"type": "overall_percent",
			"plant_key": "",
			"target": 95
		},
		{
			"id": "harvest_flowers_55",
			"label": "Harvest 55 colorful flowers",
			"type": "plant_type_count",
			"plant_key": "colorful_flowers",
			"target": 55
		},
		{
			"id": "trim_shrubs_45",
			"label": "Trim 45 small shrubs",
			"type": "plant_type_count",
			"plant_key": "small_shrubs",
			"target": 45
		},
		{
			"id": "sculpt_topiary_40",
			"label": "Sculpt 40 large topiary plants",
			"type": "plant_type_count",
			"plant_key": "large_trim_plants",
			"target": 40
		}
	]

func evaluate_objective(obj: Dictionary, completion_pct: float, cut_type_counts: Dictionary, total_points: int) -> Dictionary:
	var obj_type: String = String(obj.get("type", "overall_percent"))
	var target_val: int = int(obj.get("target", 100))
	var current_val: int = 0

	if obj_type == "overall_percent":
		current_val = int(floor(completion_pct + 0.001))
	elif obj_type == "plant_type_count":
		var key: String = String(obj.get("plant_key", ""))
		current_val = int(cut_type_counts.get(key, 0))
	elif obj_type == "total_points":
		current_val = total_points

	var completed: bool = current_val >= target_val
	var ratio: float = clampf(float(current_val) / float(maxi(1, target_val)), 0.0, 1.0)
	return {
		"id": String(obj.get("id", "")),
		"label": String(obj.get("label", "")),
		"current": current_val,
		"target": target_val,
		"ratio": ratio,
		"completed": completed,
		"is_percent": obj_type == "overall_percent"
	}

func evaluate_all(completion_pct: float, cut_type_counts: Dictionary, total_points: int) -> Dictionary:
	var items: Array[Dictionary] = []
	var completed_count: int = 0
	for obj in objectives:
		var status := evaluate_objective(obj, completion_pct, cut_type_counts, total_points)
		items.append(status)
		if bool(status["completed"]):
			completed_count += 1

	var all_done: bool = (items.size() > 0 and completed_count == items.size())
	return {
		"items": items,
		"completed_count": completed_count,
		"total_count": items.size(),
		"all_completed": all_done
	}

func calculate_stars(completion_pct: float, elapsed_seconds: float) -> int:
	if completion_pct >= 98.0 or elapsed_seconds <= three_star_time_seconds:
		return 3
	if completion_pct >= 90.0 or elapsed_seconds <= two_star_time_seconds:
		return 2
	return 1
