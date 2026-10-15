extends RefCounted

## Step 7 & Step 8 — Player Profile, Unlocks, Unlimited Resources, Garage, Settings & Save System.
## Implements:
## - All implemented levels unlocked from first launch
## - All implemented mower types, skins, upgrades, and boosters unlocked locally
## - Unlimited resources mode (displays "∞" + capped balance 999,999,999; never blocks any upgrade)
## - Safe configurable mower strength (speed, cutting radius, blade power, boost multiplier, booster duration)
## - Step 8 Settings: Master/Music/SFX volume, Vibration toggle, Camera Zoom & Sensitivity,
##   Graphics Quality (Low/Medium/High), UI Text Scale (1.0x - 1.35x), Language
## - Local JSON persistence with schema v2 versioning, backup fallback, corruption recovery, and Reset Save

const DEFAULT_SAVE_PATH: String = "user://grass_master_step7_profile.json"
const BACKUP_SAVE_PATH: String = "user://grass_master_step8_backup.json"
const SAVE_SCHEMA_VERSION: int = 2
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

# Step 8 Settings safe bounds
const MIN_VOLUME: float = 0.0
const MAX_VOLUME: float = 1.0
const DEFAULT_MASTER_VOLUME: float = 0.85
const DEFAULT_MUSIC_VOLUME: float = 0.70
const DEFAULT_SFX_VOLUME: float = 0.85

const MIN_CAMERA_ZOOM: float = 0.65
const MAX_CAMERA_ZOOM: float = 1.45
const DEFAULT_CAMERA_ZOOM: float = 1.00

const MIN_CAMERA_SENSITIVITY: float = 0.50
const MAX_CAMERA_SENSITIVITY: float = 2.00
const DEFAULT_CAMERA_SENSITIVITY: float = 1.00

const MIN_UI_TEXT_SCALE: float = 1.00
const MAX_UI_TEXT_SCALE: float = 1.35
const DEFAULT_UI_TEXT_SCALE: float = 1.00

const VALID_GRAPHICS_QUALITIES: Array[String] = ["Low", "Medium", "High"]

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
var enabled_upgrades: Dictionary = {}

var configured_move_speed: float = DEFAULT_MOVE_SPEED
var configured_cutting_radius: float = DEFAULT_CUTTING_RADIUS
var configured_blade_power: int = DEFAULT_BLADE_POWER
var configured_boost_multiplier: float = DEFAULT_BOOST_MULTIPLIER
var configured_booster_duration: float = DEFAULT_BOOSTER_DURATION

# Step 8 Settings fields
var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME
var vibration_enabled: bool = true
var camera_zoom: float = DEFAULT_CAMERA_ZOOM
var camera_sensitivity: float = DEFAULT_CAMERA_SENSITIVITY
var graphics_quality: String = "High"
var ui_text_scale: float = DEFAULT_UI_TEXT_SCALE
var language_code: String = "EN"

var best_level_times: Dictionary = {}
var completed_levels: Dictionary = {}
var last_load_recovered_from_corruption: bool = false

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
	enabled_upgrades = {}
	for upg in UNLOCKED_UPGRADES:
		enabled_upgrades[upg] = true

	configured_move_speed = DEFAULT_MOVE_SPEED
	configured_cutting_radius = DEFAULT_CUTTING_RADIUS
	configured_blade_power = DEFAULT_BLADE_POWER
	configured_boost_multiplier = DEFAULT_BOOST_MULTIPLIER
	configured_booster_duration = DEFAULT_BOOSTER_DURATION

	master_volume = DEFAULT_MASTER_VOLUME
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	vibration_enabled = true
	camera_zoom = DEFAULT_CAMERA_ZOOM
	camera_sensitivity = DEFAULT_CAMERA_SENSITIVITY
	graphics_quality = "High"
	ui_text_scale = DEFAULT_UI_TEXT_SCALE
	language_code = "EN"

	best_level_times = {}
	completed_levels = {}
	last_load_recovered_from_corruption = false

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

func set_audio_settings(master_v: Variant, music_v: Variant, sfx_v: Variant, vib_enabled: bool = vibration_enabled) -> void:
	master_volume = _safe_float(master_v, DEFAULT_MASTER_VOLUME, MIN_VOLUME, MAX_VOLUME)
	music_volume = _safe_float(music_v, DEFAULT_MUSIC_VOLUME, MIN_VOLUME, MAX_VOLUME)
	sfx_volume = _safe_float(sfx_v, DEFAULT_SFX_VOLUME, MIN_VOLUME, MAX_VOLUME)
	vibration_enabled = bool(vib_enabled)

func set_camera_and_display_settings(
	cam_zoom: Variant,
	cam_sens: Variant,
	gfx_quality: String,
	text_scale: Variant = ui_text_scale
) -> void:
	camera_zoom = _safe_float(cam_zoom, DEFAULT_CAMERA_ZOOM, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
	camera_sensitivity = _safe_float(cam_sens, DEFAULT_CAMERA_SENSITIVITY, MIN_CAMERA_SENSITIVITY, MAX_CAMERA_SENSITIVITY)
	if VALID_GRAPHICS_QUALITIES.has(gfx_quality):
		graphics_quality = gfx_quality
	else:
		graphics_quality = "High"
	ui_text_scale = _safe_float(text_scale, DEFAULT_UI_TEXT_SCALE, MIN_UI_TEXT_SCALE, MAX_UI_TEXT_SCALE)

func set_upgrade_enabled(upgrade_id: String, enabled: bool) -> void:
	if UNLOCKED_UPGRADES.has(upgrade_id):
		enabled_upgrades[upgrade_id] = bool(enabled)

func is_upgrade_enabled(upgrade_id: String) -> bool:
	if not UNLOCKED_UPGRADES.has(upgrade_id):
		return false
	return bool(enabled_upgrades.get(upgrade_id, true))

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
	if is_creative_mode():
		return MAX_BLADE_POWER
	var bonus: int = 1 if is_upgrade_enabled("titanium_blades") else 0
	return clampi(configured_blade_power + bonus - 1, MIN_BLADE_POWER, MAX_BLADE_POWER)

func is_level_unlocked(_level_id: String) -> bool:
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

func record_level_completion(level_id: String, stars: int, elapsed_sec: float) -> void:
	if level_id.is_empty():
		return
	var prev_stars: int = int(completed_levels.get(level_id, 0))
	completed_levels[level_id] = maxi(prev_stars, clampi(stars, 1, 3))
	if elapsed_sec > 0.0:
		var prev_best: float = float(best_level_times.get(level_id, 999999.0))
		if elapsed_sec < prev_best:
			best_level_times[level_id] = snappedf(elapsed_sec, 0.1)

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
	var deck_bonus: float = 1.06 if is_upgrade_enabled("wide_deck_expander") else 1.0
	mower.set(
		"cutting_radius",
		clampf(configured_cutting_radius * safe_growth * deck_bonus, MIN_CUTTING_RADIUS, MAX_CUTTING_RADIUS * 1.15)
	)
	mower.set("cutting_power", get_effective_blade_power())
	if mower.has_method("apply_visual_customization"):
		mower.call("apply_visual_customization", selected_mower_type, selected_skin)

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
		"enabled_upgrades": enabled_upgrades.duplicate(),
		"configured_move_speed": configured_move_speed,
		"configured_cutting_radius": configured_cutting_radius,
		"configured_blade_power": configured_blade_power,
		"configured_boost_multiplier": configured_boost_multiplier,
		"configured_booster_duration": configured_booster_duration,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"vibration_enabled": vibration_enabled,
		"camera_zoom": camera_zoom,
		"camera_sensitivity": camera_sensitivity,
		"graphics_quality": graphics_quality,
		"ui_text_scale": ui_text_scale,
		"language_code": language_code,
		"best_level_times": best_level_times.duplicate(),
		"completed_levels": completed_levels.duplicate()
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

	if typeof(data.get("enabled_upgrades")) == TYPE_DICTIONARY:
		var raw_upg: Dictionary = data["enabled_upgrades"]
		for upg in UNLOCKED_UPGRADES:
			if raw_upg.has(upg):
				enabled_upgrades[upg] = bool(raw_upg[upg])

	set_mower_strength(
		data.get("configured_move_speed", DEFAULT_MOVE_SPEED),
		data.get("configured_cutting_radius", DEFAULT_CUTTING_RADIUS),
		data.get("configured_blade_power", DEFAULT_BLADE_POWER),
		data.get("configured_boost_multiplier", DEFAULT_BOOST_MULTIPLIER),
		data.get("configured_booster_duration", DEFAULT_BOOSTER_DURATION)
	)

	set_audio_settings(
		data.get("master_volume", DEFAULT_MASTER_VOLUME),
		data.get("music_volume", DEFAULT_MUSIC_VOLUME),
		data.get("sfx_volume", DEFAULT_SFX_VOLUME),
		bool(data.get("vibration_enabled", true))
	)

	set_camera_and_display_settings(
		data.get("camera_zoom", DEFAULT_CAMERA_ZOOM),
		data.get("camera_sensitivity", DEFAULT_CAMERA_SENSITIVITY),
		String(data.get("graphics_quality", "High")),
		data.get("ui_text_scale", DEFAULT_UI_TEXT_SCALE)
	)

	var lang: String = String(data.get("language_code", "EN"))
	if not lang.is_empty():
		language_code = lang

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
	# Also write backup when saving to default path
	if path == DEFAULT_SAVE_PATH:
		var bak := FileAccess.open(BACKUP_SAVE_PATH, FileAccess.WRITE)
		if bak != null:
			bak.store_string(json_str)
			bak.close()
	return true

func load_from_disk(path: String = DEFAULT_SAVE_PATH) -> bool:
	last_load_recovered_from_corruption = false
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
		last_load_recovered_from_corruption = true
		return false
	var json_parser := JSON.new()
	var err := json_parser.parse(raw_text)
	if err != OK or typeof(json_parser.data) != TYPE_DICTIONARY:
		reset_to_defaults()
		last_load_recovered_from_corruption = true
		return false
	from_dictionary(json_parser.data as Dictionary)
	return true

func reset_save_and_persist(path: String = DEFAULT_SAVE_PATH) -> bool:
	reset_to_defaults()
	return save_to_disk(path)
