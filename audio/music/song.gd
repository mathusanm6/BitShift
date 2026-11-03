extends RefCounted
## The music's material: a 16-bar chord progression, the bass rhythm, and the
## instrument voices. Notes are rendered at the level 1 tempo so each render
## can be reused at every level.

const V := preload("res://audio/synth/voices.gd")

## One chord per bar: [root midi note, "m" minor or "M" major seventh].
const BARS: Array[Array] = [
	[38, "m"], [34, "M"], [41, "M"], [36, "M"], [38, "m"], [34, "M"], [41, "M"], [36, "M"],
	[31, "m"], [38, "m"], [34, "M"], [33, "M"], [31, "m"], [38, "m"], [34, "M"], [33, "M"],
]
## The calm bassline, one character per sixteenth.
const BASS := "x..x..x...x.x..."
const BASE_BPM := 106.0
## A sixteenth note at the level 1 tempo, used for every note length.
const D16_BASE := 60.0 / 116.0 / 4.0
const DRUMS: Array[StringName] = [&"kick", &"hard_kick", &"snare", &"snare_fill", &"hat", &"hat_open"]


static func bar(i: int) -> Array:
	return BARS[i % BARS.size()]


## The bar's chord tones as semitones above the root.
static func chord(row: Array) -> Array[int]:
	var minor: Array[int] = [0, 3, 7, 10]
	var major: Array[int] = [0, 4, 7, 11]
	return minor if row[1] == "m" else major


static func midi_hz(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


## The 4-bit shift register behind the arpeggio: 15 steps against a 16-step
## bar, so the pattern keeps drifting.
static func lfsr_next(s: int) -> int:
	return ((s << 1) | (((s >> 3) ^ (s >> 2)) & 1)) & 15


## Synth voices for one note of an instrument. heat brightens some of them.
static func voices(kind: StringName, midi: int, heat := 0.0) -> Array[Dictionary]:
	var d := D16_BASE
	var hz := midi_hz(midi)
	match kind:
		&"pad": return [V.tone(d * 15, "sawtooth", hz, 0.03, 780, 0.14)]
		&"bass": return [V.tone(d * 1.7, "square", hz, 0.17, 430)]
		&"drive_bass": return [V.tone(d * 1.3, "sawtooth", hz, 0.22, 1300 + heat * 900, 0.002), V.tone(d * 1.5, "square", hz, 0.16, 520)]
		&"arp": return [V.tone(d * 1.6, "square", hz, 0.055, 1200 + heat * 2800)]
		&"lead": return [V.tone(d * 7, "triangle", hz, 0.07, 0.0, 0.02)]
		&"alarm": return [V.tone(d * 0.75, "square", hz, 0.11, 4400, 0.002)]
		&"kick":
			var k := V.osc(0, 0.16, "sine", 135, 44, 0.62)
			k.fdur = 0.11
			return [k]
		&"hard_kick":
			var punch := V.osc(0, 0.15, "sine", 220, 38, 0.85)
			punch.fdur = 0.06
			return [punch, V.noise(0, 0.015, "bandpass", 3200, 1.8, 0.5)]
		&"snare": return [V.noise(0, 0.1, "bandpass", 1900, 1, 0.3), V.tone(0.06, "triangle", 190, 0.13)]
		&"snare_fill": return [V.noise(0, 0.06, "bandpass", 1900, 1, 0.2), V.tone(0.06, "triangle", 190, 0.13)]
		&"hat": return [V.noise(0, 0.024, "highpass", 7200, 1, 1.0)]
		&"hat_open": return [V.noise(0, 0.07, "highpass", 7200, 1, 1.0)]
	return []
