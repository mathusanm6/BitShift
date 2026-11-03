extends RefCounted
## The sound effects as synth recipes, one per A.* function in the web build.
## arg is the sound's parameter: a pitch factor for key clicks, the combo for
## shatter, the chain for row_clear, the impact strength for tick.

const V := preload("res://audio/synth/voices.gd")


static func voices(sound: StringName, arg: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	match sound:
		# Keys and the gun
		&"key_down": return [V.noise(0, 0.018, "bandpass", 2400 * arg, 1.2, 0.55), V.osc(0, 0.055, "sine", 170 * arg, 85, 0.5)]
		&"key_up": return [V.noise(0, 0.012, "bandpass", 3500 * arg, 2, 0.16)]
		&"slide": return [V.osc(0, 0.03, "triangle", 300, 200, 0.14), V.noise(0, 0.02, "bandpass", 1100, 1, 0.14)]
		&"load": return [V.osc(0, 0.022, "triangle", 980, 720, 0.1)]
		&"dead": return [V.noise(0, 0.022, "lowpass", 620, 0.8, 0.5), V.osc(0, 0.028, "sine", 95, 60, 0.3)]
		&"scrape": return [V.noise(0, 0.2, "bandpass", 3200, 2.5, 0.8), V.noise(0.02, 0.16, "highpass", 6000, 0.7, 0.4), V.osc(0, 0.16, "sine", 120, 50, 0.7)]
		&"fire": return [V.noise(0, 0.07, "bandpass", 1500, 0.8, 0.8), V.osc(0, 0.09, "square", 760, 170, 0.22), V.osc(0, 0.1, "sine", 130, 55, 0.6)]
		&"siphon": return [V.noise(0, 0.2, "bandpass", 800, 3, 0.8), V.osc(0, 0.2, "sawtooth", 200, 1500, 0.14)]
		&"recoil": return [V.osc(0, 0.14, "sine", 180, 45, 0.95), V.noise(0, 0.13, "bandpass", 700, 0.9, 0.9), V.osc(0, 0.1, "square", 900, 220, 0.14)]
		&"laser": return [V.osc(0, 0.22, "sawtooth", 2100, 340, 0.24), V.noise(0, 0.18, "highpass", 2600, 0.7, 0.45)]
		&"flip": return [V.osc(0, 0.14, "sawtooth", 1200, 300, 0.14), V.osc(0.02, 0.14, "sawtooth", 300, 1200, 0.12)]
		# The field
		&"shatter": return [V.noise(0, 0.1, "highpass", 3200, 0.7, 0.3), V.osc(0, 0.1, "triangle", 1046 * (1 + arg * 0.06), 800, 0.14)]
		&"crack": return [V.noise(0, 0.05, "bandpass", 2600, 2, 0.8), V.osc(0, 0.06, "square", 720, 240, 0.2), V.noise(0.02, 0.09, "highpass", 5200, 0.7, 0.28)]
		&"misfire": return [V.osc(0, 0.1, "square", 210, 90, 0.22), V.noise(0, 0.04, "lowpass", 1100, 1, 0.6)]
		&"land": return [V.noise(0, 0.018, "bandpass", 900, 1.4, 0.2)]
		&"row_clear": return _row_clear(arg)
		&"hit": return [V.osc(0, 0.22, "sine", 130, 38, 0.95), V.noise(0, 0.1, "lowpass", 1300, 0.8, 0.8), V.noise(0, 0.02, "highpass", 3000, 0.7, 0.4)]
		&"over": return [V.osc(0, 0.9, "sawtooth", 440, 45, 0.28)]
		# The >> key wearing out
		&"rattle": return _rattle(rng)
		&"snap": return [V.noise(0, 0.012, "highpass", 2800, 0.7, 1), V.osc(0, 0.09, "sawtooth", 680, 110, 0.4), V.osc(0.012, 0.42, "sine", 330, 250, 0.55, [37, 130])]
		&"break_cap": return [V.noise(0, 0.06, "bandpass", 1700, 0.7, 1), V.noise(0.004, 0.02, "highpass", 5000, 0.7, 0.8),
			V.osc(0, 0.09, "square", 1400, 190, 0.3), V.osc(0.01, 0.5, "sine", 410, 300, 0.32, [46, 150])]
		&"tick": return [V.noise(0, 0.014, "bandpass", rng.randf_range(2200, 3400), 4, 0.55 * arg), V.osc(0, 0.02, "triangle", rng.randf_range(900, 1300), 600, 0.12 * arg)]
		&"spark": return _spark(rng)
		&"repair": return [V.osc(0, 0.18, "triangle", 500, 1500, 0.2), V.noise(0.17, 0.012, "highpass", 3000, 0.7, 0.8), V.osc(0.17, 0.05, "sine", 240, 110, 0.5)]
		&"floor": return [V.noise(0, 0.02, "bandpass", 1400, 2, 0.14)]
	push_warning("Unknown sound %s" % sound)
	return []


static func _row_clear(chain: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = [V.noise(0, 0.34, "highpass", 1700, 0.7, 0.7), V.osc(0, 0.3, "sawtooth", 120, 1400, 0.22)]
	var notes := [1318, 1568, 2093, 2637]
	for i in 4:
		out.append(V.osc(0.08 + i * 0.06, 0.22, "triangle", notes[i] * (1 + (chain - 1) * 0.12), 1500, 0.15))
	return out


static func _rattle(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var at := 0.03
	for i in 8:
		var v := 1.0 - i / 9.0
		out.append(V.noise(at, 0.014, "bandpass", rng.randf_range(3500, 7500), 9, 0.5 * v))
		if i % 2 == 0:
			out.append(V.osc(at, 0.03, "square", rng.randf_range(2600, 3600), 2200, 0.05 * v))
		at += rng.randf_range(0.022, 0.05)
	return out


static func _spark(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in rng.randi_range(3, 6):
		out.append(V.noise(i * rng.randf_range(0.006, 0.02), rng.randf_range(0.004, 0.012), "highpass", rng.randf_range(4500, 8000), 0.7, rng.randf_range(0.05, 0.16)))
	return out
