extends Node
class_name SoundHooks

## Procedural offline audio hooks for Grass Master (Step 5).
## Uses AudioStreamGenerator so cutting sounds play cleanly with zero external audio dependencies
## and gracefully degrade in headless mode.

signal sound_triggered(event_name: String, plant_type: String, count: int)

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _sample_rate: float = 22050.0
var _phase: float = 0.0
var _active_freq: float = 0.0
var _remaining_frames: int = 0
var _amplitude: float = 0.0
var total_sound_events: int = 0
var last_sound_event: String = "none"

func _ready() -> void:
	name = "SoundHooks"
	_player = AudioStreamPlayer.new()
	_player.name = "SynthPlayer"
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = _sample_rate
	gen.buffer_length = 0.12
	_player.stream = gen
	_player.volume_db = -9.0
	add_child(_player)
	_player.play()
	if _player.has_stream_playback():
		_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback

func _process(_delta: float) -> void:
	if _playback == null or _remaining_frames <= 0:
		return
	var frames_available := _playback.get_frames_available()
	var to_fill := mini(frames_available, _remaining_frames)
	for _i in range(to_fill):
		var env := clampf(float(_remaining_frames) / 900.0, 0.0, 1.0)
		var sample := sin(_phase * TAU) * _amplitude * env
		_playback.push_frame(Vector2(sample, sample))
		_phase = fmod(_phase + (_active_freq / _sample_rate), 1.0)
		_remaining_frames -= 1

func play_cut_sound(plant_type: String, batch_count: int = 1) -> void:
	total_sound_events += 1
	last_sound_event = "cut:" + plant_type
	match plant_type:
		"short_grass":
			_active_freq = 440.0
			_amplitude = 0.18
		"tall_grass":
			_active_freq = 370.0
			_amplitude = 0.22
		"colorful_flowers":
			_active_freq = 587.33
			_amplitude = 0.24
		"small_shrubs":
			_active_freq = 311.13
			_amplitude = 0.26
		"large_trim_plants":
			_active_freq = 261.63
			_amplitude = 0.28
		_:
			_active_freq = 400.0
			_amplitude = 0.18
	_remaining_frames = mini(1400, 450 + batch_count * 120)
	sound_triggered.emit("cut", plant_type, batch_count)
