extends RefCounted
## Decides what plays on each sixteenth. heat (0 calm to 1 panic, from how
## close the stack is to the ceiling) drives the arrangement: the bass starts
## chugging, the arpeggio fills in, an alarm blips and the drums harden.

const Song := preload("res://audio/music/song.gd")

## A note to play: an instrument, its midi note, the heat it was rendered at,
## its gain, and whether it feeds the echo.
class Note:
	var kind: StringName
	var midi: int
	var heat: float
	var gain: float
	var echo: bool

	func _init(k: StringName, m: int, g: float, e := false, h := 0.0) -> void:
		kind = k
		midi = m
		gain = g
		echo = e
		heat = h


## Sixteenth within the bar, 0 to 15.
var step := 0
var bar := 0
var lfsr := 9


func reset() -> void:
	step = 0
	bar = 0
	lfsr = 9


func advance() -> void:
	step = (step + 1) % 16
	if step == 0:
		bar += 1


## The notes for the current step.
func notes(heat: float) -> Array[Note]:
	var row := Song.bar(bar)
	var root: int = row[0]
	var tones := Song.chord(row)
	var heat_q := snappedf(heat, 0.5)
	lfsr = Song.lfsr_next(lfsr)
	var out: Array[Note] = []
	_pad(out, root, tones, heat)
	_bass(out, root, heat, heat_q)
	_arp(out, root, tones, heat, heat_q)
	if bar % 16 >= 8 and step % 8 == 0:
		out.append(Note.new(&"lead", root + 48 + tones[(lfsr >> 2) & 3], 1.0, true))
	_alarm(out, root, tones, heat)
	_drums(out, heat)
	return out


func _pad(out: Array[Note], root: int, tones: Array[int], heat: float) -> void:
	if step == 0 or (heat >= 0.7 and step == 8):
		for iv in tones.slice(0, 3):
			out.append(Note.new(&"pad", root + 24 + iv, 1.0 if step == 0 else 0.65))


func _bass(out: Array[Note], root: int, heat: float, heat_q: float) -> void:
	if heat < 0.6:
		if Song.BASS[step] == "x":
			out.append(Note.new(&"bass", root + 12 if step == 10 else (root + 7 if step == 12 else root), 1.0))
		return
	# Driving bassline chug when in danger.
	var hit: bool = step in [0, 2, 3, 6, 8, 10, 11, 14] if heat < 0.85 else (step % 2 == 0 or step in [3, 7, 11, 15])
	if hit:
		var n := root + 12 if step in [2, 6, 10, 14] else (root + 7 if step in [3, 11] else root)
		out.append(Note.new(&"drive_bass", n, 0.85, false, heat_q))


func _arp(out: Array[Note], root: int, tones: Array[int], heat: float, heat_q: float) -> void:
	var play := bool(lfsr & 1)
	if heat >= 0.7:
		play = true
	elif heat >= 0.4:
		play = play or step % 2 == 1
	if not play:
		return
	var octave := 12 * ((lfsr >> 3) & 1)
	if heat >= 0.7 and step % 4 >= 2:
		octave += 12
	var gain := 0.7 if heat < 0.4 else (0.85 if heat < 0.7 else 1.0)
	out.append(Note.new(&"arp", root + 36 + tones[(lfsr >> 1) & 3] + octave, gain, true, heat_q))


## A warning blip when the stack nears the ceiling.
func _alarm(out: Array[Note], root: int, tones: Array[int], heat: float) -> void:
	if heat < 0.65:
		return
	var blip: bool = (step == 2 or step == 10) if heat < 0.85 else step in [2, 6, 10, 14]
	if blip:
		out.append(Note.new(&"alarm", root + 48 + tones[step % tones.size()], 0.75, true))


func _drums(out: Array[Note], heat: float) -> void:
	var s := step
	var kick: bool
	if heat < 0.4:
		kick = s == 0 or s == 8
	elif heat < 0.7:
		kick = s in [0, 6, 8, 11]
	elif heat < 0.85:
		kick = s % 4 == 0 or s == 6 or s == 11
	else:
		kick = s % 4 == 0 or s in [2, 10, 14]
	if kick:
		out.append(Note.new(&"hard_kick" if heat >= 0.65 else &"kick", 0, 1.0))

	var fill := bar % (4 if heat >= 0.7 else 8) == (3 if heat >= 0.7 else 7) and s >= 12
	if s == 4 or s == 12 or fill or (heat >= 0.85 and (s == 7 or s == 15)):
		out.append(Note.new(&"snare_fill" if fill else &"snare", 0, 1.0))

	if heat < 0.4:
		if s % 2 == 0:
			out.append(Note.new(&"hat_open" if s == 14 else &"hat", 0, 0.05))
	elif heat < 0.7:
		var open := s == 14
		out.append(Note.new(&"hat_open" if open else &"hat", 0, 0.075 if (s % 4 == 2 or open) else 0.045))
	else:
		var open := s in [2, 6, 10, 14]
		out.append(Note.new(&"hat_open" if open else &"hat", 0, 0.085 if open else 0.055))
