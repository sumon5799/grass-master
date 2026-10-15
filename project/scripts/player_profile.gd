extends RefCounted

## Step 7 — Unlocks, Unlimited Resources, Safe Mower Strength & Creative/Relax Mode Profile.
## Implements:
## - All implemented levels unlocked from first launch
## - All implemented mower types, skins, upgrades, and boosters unlocked locally
## - Unlimited resources mode (displays "∞" + high capped balance 999,999,999; never blocks any upgrade)
## - Safe configurable mower strength (speed, cutting radius, blade power, booster multiplier, booster duration)
##   with hard safety clamps so extreme/NaN/Inf values never launch off the map or break physics
## - Creative / Relax Mode (no timer, no fail state, all plants can be cut freely regardless of resistance)
## - Local JSON persistence with schema versioning and corruption fallback

const DEFAULT_SAVE_PATH: String = "user://grass_master_step7_profile.json"
const SAVE_SCHEMA_VERSION: int = 1
const UNLIMITED_COIN_CAP: int = 999999999

# Hard safe bounds (Spec Section 5C: clamp extreme values to safe ranges)
const MIN_MOVE_SPEED: float = 4.0
const MAX_MOVE_SPEED: float = 16.0
const DEFAULT_MOVE_SPEED: float = 8.5

const MIN_CUTTING_RADIUS: float = 0.85
const MAX_CUTTING_RADIUS: float = 3.20
const DEFAULT_CUTTING_RADIUS: float = 1.45

const MIN_BLADE_POWER: int = 1
const MAX_BLADE_POWER: int = 5
const DEFAULT_BLADE_POWER: int = 3

const MIN_BOOST_MULTIPLIER: float = 1.10
const MAX_BOOST_MULTIPLIER: float = 2.10
const DEFAULT_BOOST_MULTIPLIER: float = 1.55

const MIN_BOOSTER_DURATION: float = 2.0
const MAX_BOOSTER_DURATION: float = 30.0
const DEFAULT_BOOSTER_DURATION: float = 10.0

enum PlayMode {
	NORMAL = 0,
	CREATIVE_RELAX = 1,
	CHALLENGE = 2
}

const UNLOCKED_MOWER_TYPES: Array[String] = [
	"standard_rotary",
	"twin_blade_pro",
	"turbo_hover_deck",
	"heavy_topiary_sculptor"
]

const UNLOCKED_SKINS: Array[String] = [
	"emerald_classic",
	"sunlit_gold",
	"cobalt_breeze",
	"crimson_blazer"
]

const UNLOCKED_UPGRADES: Array[String] = [
	"titanium_blades",
	"wide_deck_expander",
	"high_torque_motor",
	"overdrive_booster",
	"clipping_vortex"
]

const UNLOCKED_BOOSTERS: Array[String] = [
	"turbo_drive",
	"mega_radius",
	"instant_sculpt"
]

var unlimited_resources: bool = true
var coins_balance: int = UNLIMITED_COIN_CAP
var gems_balance: int = UNLIMITED_COIN_CAP
var play_mode: int = PlayMode.NORMAL

var selected_level_id: String = "level_01_sunlit_courtyard"
var selected_mower_type: String = "standard_rotary"
var selected_skin: String = "emerald_classic"

var configured_move_speed: float = DEFAULT_MOVE_SPEED
var configured_cutting_radius: float = DEFAULT_CUTTING_RADIUS
var configured_blade_power: int = DEFAULT_BLADE_POWER
var configured_boost_multiplier: float = DEFAULT_BOOST_MULTIPLIER
var configured_booster_duration: float = DEFAULT_BOOSTER_DURATION

var best_level_times: Dictionary = {}
var completed_levels: Dictionary = {}

func _init() -> void:
	reset_to_defaults()

func reset_to_defaults() -> void:
	unlimited_resources = true
	coins_balance = UNLIMITED_COIN_CAP
	gems_balance = UNLIMITED_COIN_CAP
	play_mode = PlayMode.NORMAL
	selected_level_id = "level_01_sunlit_courtyard"
	selected_mower_type = "standard_rotary"
	selected_skin = "emerald_classic"
	configured_move_speed = DEFAULT_MOVE_SPEED
	configured_cutting_radius = DEFAULT_CUTTING_RADIUS
	configured_blade_power = DEFAULT_BLADE_POWER
	configured_boost_multiplier = DEFAULT_BOOST_MULTIPLIER
	configured_booster_duration = DEFAULT_BOOSTER_DURATION
	best_level_times = {}
	completed_levels = {}

static func _safe_float(val: Variant, fallback: float, min_v: float, max_v: float) -> float:
	if typeof(val) != TYPE_FLOAT and typeof(val) != TYPE_INT:
		return fallback
	var f: float = float(val)
	if is_nan(f) or is_inf(f):
		return fallback
	return clampf(f, min_v, max_v)

static func _safe_int(val: Variant, fallback: int, min_v: int, max_v: int) -> int:
	if typeof(val) == TYPE_FLOAT:
		var f: float = float(val)
		if is_nan(f) or is_inf(f):
			return fallback
		return clampi(int(round(f)), min_v, max_v)
	if typeof(val) != TYPE_INT:
		return fallback
	return clampi(int(val), min_v, max_v)

func set_mower_strength(
	move_speed: Variant,
	cutting_radius: Variant,
	blade_power: Variant,
	boost_multiplier: Variant = configured_boost_multiplier,
	booster_duration: Variant = configured_booster_duration
) -> void:
	configured_move_speed = _safe_float(move_speed, DEFAULT_MOVE_SPEED, MIN_MOVE_SPEED, MAX_MOVE_SPEED)
	configured_cutting_radius = _safe_float(cutting_radius, DEFAULT_CUTTING_RADIUS, MIN_CUTTING_RADIUS, MAX_CUTTING_RADIUS)
	configured_blade_power = _safe_int(blade_power, DEFAULT_BLADE_POWER, MIN_BLADE_POWER, MAX_BLADE_POWER)
	configured_boost_multiplier = _safe_float(boost_multiplier, DEFAULT_BOOST_MULTIPLIER, MIN_BOOST_MULTIPLIER, MAX_BOOST_MULTIPLIER)
	configured_booster_duration = _safe_float(booster_duration, DEFAULT_BOOSTER_DURATION, MIN_BOOSTER_DURATION, MAX_BOOSTER_DURATION)

func set_play_mode(mode: Variant) -> void:
	var m: int = _safe_int(mode, PlayMode.NORMAL, PlayMode.NORMAL, PlayMode.CHALLENGE)
	play_mode = m

func is_creative_mode() -> bool:
	return play_mode == PlayMode.CREATIVE_RELAX

func get_mode_display_name() -> String:
	match play_mode:
		PlayMode.CREATIVE_RELAX:
			return "CREATIVE / RELAX"
		PlayMode.CHALLENGE:
			return "CHALLENGE"
		_:
			return "NORMAL"

func get_effective_blade_power() -> int:
	# Spec Section 5B.1: Creative / Relax — all plants can be cut freely
	if is_creative_mode():
		return MAX_BLADE_POWER
	return configured_blade_power

func is_level_unlocked(_level_id: String) -> bool:
	# Spec Section 5C: All implemented levels are selectable from the first launch
	return true

func is_mower_unlocked(mower_id: String) -> bool:
	return UNLOCKED_MOWER_TYPES.has(mower_id)

func is_skin_unlocked(skin_id: String) -> bool:
	return UNLOCKED_SKINS.has(skin_id)

func is_upgrade_unlocked(upgrade_id: String) -> bool:
	return UNLOCKED_UPGRADES.has(upgrade_id)

func is_booster_unlocked(booster_id: String) -> bool:
	return UNLOCKED_BOOSTERS.has(booster_id)

func select_mower_type(mower_id: String) -> void:
	if UNLOCKED_MOWER_TYPES.has(mower_id):
		selected_mower_type = mower_id

func select_skin(skin_id: String) -> void:
	if UNLOCKED_SKINS.has(skin_id):
		selected_skin = skin_id

func can_afford(_cost: int) -> bool:
	return true

func spend_coins(cost: int) -> bool:
	if unlimited_resources:
		coins_balance = UNLIMITED_COIN_CAP
		return true
	var safe_cost: int = maxi(0, cost)
	coins_balance = maxi(0, coins_balance - safe_cost)
	return true

func add_coins(amount: int) -> void:
	if unlimited_resources:
		coins_balance = UNLIMITED_COIN_CAP
		return
	var safe_add: int = maxi(0, amount)
	coins_balance = mini(UNLIMITED_COIN_CAP, coins_balance + safe_add)

func get_coins_display() -> String:
	if unlimited_resources:
		return "∞ (Unlimited)"
	return str(coins_balance)

func apply_to_mower(mower: CharacterBody3D, growth_scale: float = 1.0) -> void:
	if mower == null:
		return
	var safe_growth: float = _safe_float(growth_scale, 1.0, 1.0, 1.25)
	mower.set("base_move_speed", configured_move_speed)
	mower.set("boost_multiplier", configured_boost_multiplier)
	mower.set("cutting_radius", clampf(configured_cutting_radius * safe_growth, MIN_CUTTING_RADIUS, MAX_CUTTING_RADIUS * 1.15))
	mower.set("cutting_power", get_effective_blade_power())

func to_dictionary() -> Dictionary:
	return {
		"schema_version": SAVE_SCHEMA_VERSION,
		"unlimited_resources": unlimited_resources,
		"coins_balance": coins_balance,
		"gems_balance": gems_balance,
		"play_mode": play_mode,
		"selected_level_id": selected_level_id,
		"selected_mower_type": selected_mower_type,
		"selected_skin": selected_skin,
		"configured_move_speed": configured_move_speed,
		"configured_cutting_radius": configured_cutting_radius,
		"configured_blade_power": configured_blade_power,
		"configured_boost_multiplier": configured_boost_multiplier,
		"configured_booster_duration": configured_booster_duration,
		"best_level_times": best_level_times,
		"completed_levels": completed_levels
	}

func from_dictionary(data: Dictionary) -> void:
	reset_to_defaults()
	if data.is_empty():
		return
	unlimited_resources = bool(data.get("unlimited_resources", true))
	coins_balance = _safe_int(data.get("coins_balance", UNLIMITED_COIN_CAP), UNLIMITED_COIN_CAP, 0, UNLIMITED_COIN_CAP)
	gems_balance = _safe_int(data.get("gems_balance", UNLIMITED_COIN_CAP), UNLIMITED_COIN_CAP, 0, UNLIMITED_COIN_CAP)
	if unlimited_resources:
		coins_balance = UNLIMITED_COIN_CAP
		gems_balance = UNLIMITED_COIN_CAP

	set_play_mode(data.get("play_mode", PlayMode.NORMAL))

	var lvl_id: String = String(data.get("selected_level_id", "level_01_sunlit_courtyard"))
	if not lvl_id.is_empty():
		selected_level_id = lvl_id

	select_mower_type(String(data.get("selected_mower_type", "standard_rotary")))
	select_skin(String(data.get("selected_skin", "emerald_classic")))

	set_mower_strength(
		data.get("configured_move_speed", DEFAULT_MOVE_SPEED),
		data.get("configured_cutting_radius", DEFAULT_CUTTING_RADIUS),
		data.get("configured_blade_power", DEFAULT_BLADE_POWER),
		data.get("configured_boost_multiplier", DEFAULT_BOOST_MULTIPLIER),
		data.get("configured_booster_duration", DEFAULT_BOOSTER_DURATION)
	)

	if typeof(data.get("best_level_times")) == TYPE_DICTIONARY:
		best_level_times = data["best_level_times"].duplicate()
	if typeof(data.get("completed_levels")) == TYPE_DICTIONARY:
		completed_levels = data["completed_levels"].duplicate()

func save_to_disk(path: String = DEFAULT_SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var json_str := JSON.stringify(to_dictionary(), "\t")
	file.store_string(json_str)
	file.close()
	return true

func load_from_disk(path: String = DEFAULT_SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		reset_to_defaults()
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		reset_to_defaults()
		return false
	var raw_text := file.get_as_text().strip_edges()
	file.close()
	if not raw_text.begins_with("{") or not raw_text.ends_with("}"):
		reset_to_defaults()
		return false
	var json_parser := JSON.new()
	var err := json_parser.parse(raw_text)
	if err != OK or typeof(json_parser.data) != TYPE_DICTIONARY:
		reset_to_defaults()
		return false
	from_dictionary(json_parser.data as Dictionary)
	return true
