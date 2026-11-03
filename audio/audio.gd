extends Node
## Autoload "Audio" (audio.tscn): the game's one entry point for sound.
## Sound effects go to the SfxPlayer child, the music to the MusicPlayer child.
## Everything is synthesized; a worker thread pre-renders the common sounds
## at startup so the first bars never hitch. Silent when run headless.

signal beat

const RenderCache := preload("res://audio/render_cache.gd")
const Song := preload("res://audio/music/song.gd")
const SfxPlayer := preload("res://audio/sfx_player.gd")
const MusicPlayer := preload("res://audio/music/music_player.gd")

var sound_volume := 1.0:
	set(v):
		sound_volume = clampf(v, 0.0, 1.0)
		_sfx.volume = sound_volume
var music_volume := 0.5:
	set(v):
		music_volume = clampf(v, 0.0, 1.0)
		_music.volume = music_volume
## Whether the music should play (set by the game every frame).
var wanted := false:
	set(v):
		wanted = v
		_music.wanted = v
## Danger, 0 to 1: drives the arrangement.
var heat := 0.0:
	set(v):
		heat = v
		_music.heat = v
var level := 1:
	set(v):
		level = v
		_music.level = v

var _cache := RenderCache.new()
var _warm_task := -1

@onready var _sfx: SfxPlayer = $SfxPlayer
@onready var _music: MusicPlayer = $MusicPlayer


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_sfx.start(_cache)
	_music.start(_cache)
	_music.beat.connect(beat.emit)
	_warm_task = WorkerThreadPool.add_task(_warm_up, false, "BitShift audio warm-up")


func _exit_tree() -> void:
	if _warm_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_warm_task)
	_sfx.stop()
	_music.stop()


func play(sound: StringName, arg := 1.0) -> void:
	_sfx.play(sound, arg)


func music_reset() -> void:
	_music.reset()


func _setup_buses() -> void:
	for bus_name: StringName in [&"Sfx", &"Music"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")
	# Stands in for the web build's DynamicsCompressor on the master output.
	if AudioServer.get_bus_effect_count(0) == 0:
		var comp := AudioEffectCompressor.new()
		comp.threshold = -18.0
		comp.ratio = 6.0
		comp.attack_us = 3000.0
		comp.release_ms = 250.0
		AudioServer.add_bus_effect(0, comp)
		var limiter := AudioEffectHardLimiter.new()
		limiter.ceiling_db = -0.5
		AudioServer.add_bus_effect(0, limiter)


## Renders the level 1 notes and the common sound effects off the main thread.
func _warm_up() -> void:
	for kind in Song.DRUMS:
		_music.note(kind, 0)
	for row: Array in Song.BARS:
		var root: int = row[0]
		var tones := Song.chord(row)
		for iv in tones.slice(0, 3):
			_music.note(&"pad", root + 24 + iv)
		for n: int in [root, root + 12, root + 7]:
			_music.note(&"bass", n)
			_music.note(&"drive_bass", n)
		for iv in tones:
			_music.note(&"lead", root + 48 + iv)
			_music.note(&"alarm", root + 48 + iv)
			for octave: int in [0, 12]:
				for h: float in [0.0, 0.5, 1.0]:
					_music.note(&"arp", root + 36 + iv + octave, h)
	for sound: StringName in [&"load", &"slide", &"fire", &"dead", &"land", &"misfire", &"siphon", &"recoil", &"crack", &"laser", &"flip"]:
		_sfx.stream(sound, 1.0)
	for pitch: float in [0.65, 0.8, 0.9, 1.06, 1.2]:
		_sfx.stream(&"key_down", pitch)
	for pitch: float in [0.9, 1.0]:
		_sfx.stream(&"key_up", pitch)
	for combo in 11:
		_sfx.stream(&"shatter", combo)
