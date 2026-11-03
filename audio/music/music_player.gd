extends Node
## Runs the music. Schedules the arrangement's notes a little ahead, mixes the
## pre-rendered notes sample-accurately into an AudioStreamGenerator, adds the
## echo, and fades the Music bus in and out. Emits beat on every quarter note.

signal beat

const Renderer := preload("res://audio/synth/renderer.gd")
const RenderCache := preload("res://audio/render_cache.gd")
const Song := preload("res://audio/music/song.gd")
const Arrangement := preload("res://audio/music/arrangement.gd")

const RATE := Renderer.RATE
const BUFFER_SECONDS := 0.2
## The web build's delay line: 0.5 into a 0.3 feedback loop, three sixteenths long.
const ECHO_TAPS: Array[float] = [0.5, 0.15, 0.045]

## Set every frame by the game.
var wanted := false
var heat := 0.0
var level := 1
var volume := 0.5:
	set(v):
		volume = clampf(v, 0.0, 1.0)
var cache: RenderCache

var _playback: AudioStreamGeneratorPlayback
var _bus := -1
var _arrangement := Arrangement.new()
var _heat := 0.0
var _active := false
var _gain := 0.0
## Output frames mixed so far, and the frame of the next sixteenth.
var _clock := 0
var _next_step := 0
var _d16 := Song.D16_BASE
var _notes: Array[Array] = []  # [PackedFloat32Array, start frame, gain]
var _beats: Array[int] = []


func start(render_cache: RenderCache) -> void:
	cache = render_cache
	_bus = AudioServer.get_bus_index(&"Music")
	AudioServer.set_bus_volume_db(_bus, -80.0)
	var player := AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = BUFFER_SECONDS
	player.stream = gen
	player.bus = &"Music"
	add_child(player)
	player.play()
	_playback = player.get_stream_playback()
	reset()


func stop() -> void:
	_playback = null


func reset() -> void:
	_arrangement.reset()
	_beats.clear()
	_heat = 0.0


## A rendered note. Safe to call from the warm-up thread.
func note(kind: StringName, midi: int, heat_q := 0.0) -> PackedFloat32Array:
	var key := "m|%s|%d|%.1f" % [kind, midi, heat_q]
	return cache.fetch(key, func() -> PackedFloat32Array: return Renderer.render(Song.voices(kind, midi, heat_q)))


func _process(delta: float) -> void:
	if _playback == null:
		return
	_follow(delta)
	var avail := _playback.get_frames_available()
	if avail <= 0:
		return
	if _active:
		_schedule(_clock + avail)
	_mix(avail)
	# Beat lamp: fire once the output reaches each scheduled downbeat.
	var played := _clock - int(BUFFER_SECONDS * RATE) + avail
	while _beats.size() and _beats[0] <= played:
		_beats.pop_front()
		beat.emit()


## Eases heat and the bus volume toward their targets; starts and stops the sequencer.
func _follow(delta: float) -> void:
	_heat = move_toward(_heat, heat, delta * (3.5 if heat > _heat else 0.75))
	var want := wanted and volume > 0.0
	if want != _active:
		_active = want
		if want:
			_next_step = _clock + int(0.05 * RATE)
		else:
			_beats.clear()
	var target := volume * 0.85 if _active else 0.0
	_gain = lerpf(_gain, target, 1.0 - exp(-delta / (0.03 if _active else 0.05)))
	AudioServer.set_bus_volume_db(_bus, linear_to_db(maxf(_gain, 0.00001)))


## Queues every sixteenth that starts before frame `horizon`.
func _schedule(horizon: int) -> void:
	while _next_step < horizon:
		var bpm := clampf(Song.BASE_BPM + (level - 1) * 2.0 + _heat * 64.0, 90.0, 185.0)
		_d16 = 60.0 / bpm / 4.0
		for n: Arrangement.Note in _arrangement.notes(_heat):
			_add(note(n.kind, n.midi, n.heat), _next_step, n.gain, n.echo)
		if _arrangement.step % 4 == 0:
			_beats.append(_next_step)
		_next_step += int(_d16 * RATE)
		_arrangement.advance()


func _add(buf: PackedFloat32Array, at: int, gain: float, echo: bool) -> void:
	_notes.append([buf, at, gain])
	if echo:
		var gap := int(_d16 * 3.0 * RATE)
		for i in ECHO_TAPS.size():
			_notes.append([buf, at + gap * (i + 1), gain * ECHO_TAPS[i]])


func _mix(frames: int) -> void:
	var mix := PackedFloat32Array()
	mix.resize(frames)
	var end := _clock + frames
	var keep: Array[Array] = []
	for n: Array in _notes:
		var buf: PackedFloat32Array = n[0]
		var start_at: int = n[1]
		var g: float = n[2]
		if start_at < end:
			for f in range(maxi(_clock, start_at), mini(end, start_at + buf.size())):
				mix[f - _clock] += buf[f - start_at] * g
		if start_at + buf.size() > end:
			keep.append(n)
	_notes = keep
	var out := PackedVector2Array()
	out.resize(frames)
	for i in frames:
		out[i] = Vector2(mix[i], mix[i])
	_playback.push_buffer(out)
	_clock = end
