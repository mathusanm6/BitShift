extends RefCounted
## Builders for synth voices, the input to renderer.gd. A voice is a Dictionary:
##   k: "o" oscillator | "n" noise
##   at, dur, gain           start, length (s) and peak gain
##   env: "ramp"             gain falls exponentially to 0.0008 over dur (Web Audio A.o / A.n)
##        "tone"             linear attack, then exponential fall (music mTone)
##   type: sine|square|sawtooth|triangle, f0, f1, fdur (osc pitch sweeps f0 -> f1 over fdur)
##   vib: [rate, depth]      vibrato on the oscillator frequency
##   ftype, freq, q          biquad on the voice: lowpass|highpass|bandpass


## An oscillator sweeping f0 -> f1 with a falling envelope.
static func osc(at: float, dur: float, type: String, f0: float, f1: float, gain: float, vib: Array = []) -> Dictionary:
	return {k = "o", at = at, dur = dur, type = type, f0 = f0, f1 = maxf(20.0, f1), gain = gain, vib = vib, env = "ramp", stop = 0.02}


## Filtered white noise with a falling envelope.
static func noise(at: float, dur: float, ftype: String, freq: float, q: float, gain: float) -> Dictionary:
	return {k = "n", at = at, dur = dur, ftype = ftype, freq = freq, q = q, gain = gain, env = "ramp", stop = 0.02}


## A music note: steady pitch, short attack, optional lowpass at `cut` Hz.
static func tone(dur: float, type: String, hz: float, gain: float, cut := 0.0, attack := 0.004) -> Dictionary:
	var v := {k = "o", at = 0.0, dur = dur, type = type, f0 = hz, f1 = hz, gain = gain, env = "tone", attack = attack, stop = 0.03}
	if cut > 0.0:
		v.ftype = "lowpass"
		v.freq = cut
		v.q = 0.8
	return v
