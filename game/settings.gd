class_name PlayerSettings
extends Node
## The player's options, set from the start menu and saved between runs.
## Volumes apply to the audio buses straight away; shake and start speed are
## read by the board and by Game when a run starts.

signal changed

const SaveFile := preload("res://game/save_file.gd")

enum Speed { RELAXED, NORMAL, FAST }

const SPEED_NAMES: Array[String] = ["RELAXED", "NORMAL", "FAST"]
## Multiplies how fast waves fall and arrive, per Speed.
const SPEED_FACTORS: Array[float] = [0.75, 1.0, 1.3]

@export_range(0.0, 1.0, 0.1) var music_volume := 0.5:
	set(v):
		music_volume = clampf(v, 0.0, 1.0)
		Audio.music_volume = music_volume
		_store("music_volume", music_volume)
@export_range(0.0, 1.0, 0.1) var sound_volume := 1.0:
	set(v):
		sound_volume = clampf(v, 0.0, 1.0)
		Audio.sound_volume = sound_volume
		_store("sound_volume", sound_volume)
@export var screen_shake := true:
	set(v):
		screen_shake = v
		_store("screen_shake", v)
@export var start_speed := Speed.NORMAL:
	set(v):
		start_speed = v
		_store("start_speed", v)

var _loaded := false
var _music_before_mute := 0.5


func _ready() -> void:
	music_volume = SaveFile.read("settings", "music_volume", music_volume)
	sound_volume = SaveFile.read("settings", "sound_volume", sound_volume)
	screen_shake = SaveFile.read("settings", "screen_shake", screen_shake)
	start_speed = SaveFile.read("settings", "start_speed", start_speed)
	_loaded = true


func speed_factor() -> float:
	return SPEED_FACTORS[start_speed]


## Mutes the music, or brings it back at its previous volume (the N key).
func toggle_music() -> void:
	if music_volume > 0.0:
		_music_before_mute = music_volume
		music_volume = 0.0
	else:
		music_volume = _music_before_mute if _music_before_mute > 0.0 else 0.5


func _store(key: String, value: Variant) -> void:
	if _loaded:
		SaveFile.write("settings", key, value)
	changed.emit()
