extends Node
## Plays the sound effects. Each sound is rendered once per parameter value,
## cached, and played on one polyphonic stream so hits can overlap. A few
## noisy sounds keep several random variants so repeats don't sound canned.

const Renderer := preload("res://audio/synth/renderer.gd")
const Recipes := preload("res://audio/sfx_recipes.gd")
const RenderCache := preload("res://audio/render_cache.gd")

## Renders are stored scaled down and played back louder, so stacked hits keep headroom.
const RENDER_SCALE := 0.4
const MASTER_GAIN := 0.75
const POLYPHONY := 48
const VARIED: Array[StringName] = [&"rattle", &"spark", &"tick"]
const VARIANTS := 3

## 0 is silent, 1 full volume.
var volume := 1.0
var cache: RenderCache

var _player: AudioStreamPlayer
var _playback: AudioStreamPlaybackPolyphonic
var _rng := RandomNumberGenerator.new()


func start(render_cache: RenderCache) -> void:
	cache = render_cache
	_rng.randomize()
	_player = AudioStreamPlayer.new()
	var poly := AudioStreamPolyphonic.new()
	poly.polyphony = POLYPHONY
	_player.stream = poly
	_player.bus = &"Sfx"
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()


func stop() -> void:
	if _player:
		_player.stop()
	_playback = null


func play(sound: StringName, arg := 1.0) -> void:
	if volume <= 0.0:
		return
	if _player and not _player.playing:
		_player.play()
		_playback = _player.get_stream_playback()
	if _playback == null:
		return
	var wav := stream(sound, arg, _rng.randi() % VARIANTS if sound in VARIED else 0)
	if wav:
		_playback.play_stream(wav, 0.0, linear_to_db(MASTER_GAIN * volume / RENDER_SCALE))


## The rendered stream for a sound. Safe to call from the warm-up thread.
func stream(sound: StringName, arg: float, variant := 0) -> AudioStreamWAV:
	var q := _quantize(sound, arg)
	var key := "sfx|%s|%.2f|%d" % [sound, q, variant]
	return cache.fetch(key, func() -> AudioStreamWAV:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		return Renderer.to_wav(Renderer.render(Recipes.voices(sound, q, rng)), RENDER_SCALE))


## Snaps the parameter so similar calls share a render.
func _quantize(sound: StringName, arg: float) -> float:
	match sound:
		&"tick": return clampf(snappedf(arg, 0.25), 0.25, 1.0)
		&"shatter": return clampf(roundf(arg), 0.0, 10.0)
		&"row_clear": return clampf(roundf(arg), 1.0, 6.0)
	return snappedf(arg, 0.01)
