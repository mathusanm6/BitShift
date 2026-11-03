extends RefCounted
## Offline renderer for voices (see voices.gd), ported from the web build's
## Web Audio graph: PolyBLEP oscillators, RBJ biquads and exponential ramps.
## Renders are pure functions of their input, so they are safe on a worker thread.

const RATE := 32000
const FLOOR_GAIN := 0.0008
const WAVES: Array[String] = ["sine", "square", "sawtooth", "triangle"]


static func render(voices: Array[Dictionary], seed_value := 0) -> PackedFloat32Array:
	var length := 0.0
	for v: Dictionary in voices:
		length = maxf(length, v.at + v.dur + v.stop)
	var out := PackedFloat32Array()
	out.resize(int(length * RATE) + 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value else randi()
	for v: Dictionary in voices:
		_add_voice(out, v, rng)
	return out


## Packs a render into a 16-bit stream. scale keeps loud layered hits from clipping.
static func to_wav(data: PackedFloat32Array, scale: float) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i] * scale, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav


static func _add_voice(out: PackedFloat32Array, v: Dictionary, rng: RandomNumberGenerator) -> void:
	var start := int(v.at * RATE)
	var count := mini(int((v.dur + v.stop) * RATE), out.size() - start)
	var gain: float = v.gain
	var attack: float = v.get("attack", 0.0)

	# Envelope, stepped multiplicatively for an exact exponential ramp.
	var tone_env: bool = v.env == "tone"
	var attack_n := int(attack * RATE)
	var decay_n := maxi(1, int((maxf(v.dur, attack + 0.01) - attack) * RATE)) if tone_env else maxi(1, int(v.dur * RATE))
	var env_k := pow(FLOOR_GAIN / gain, 1.0 / decay_n)
	var env := 0.0001 if tone_env and attack_n > 0 else gain

	var osc: Oscillator = Oscillator.new(v, decay_n) if v.k == "o" else null
	var filter: Biquad = Biquad.new(v.ftype, v.freq, v.q) if v.has("ftype") else null
	for i in count:
		var s: float = osc.next(i) if osc else rng.randf() * 2.0 - 1.0
		if filter:
			s = filter.next(s)
		if tone_env and i < attack_n:
			env = lerpf(0.0001, gain, float(i) / attack_n)
		elif env > FLOOR_GAIN:
			env *= env_k
		out[start + i] += s * env


## A band-limited oscillator with an exponential pitch sweep and fading vibrato.
class Oscillator:
	var wave: int
	var freq: float
	var freq_k := 1.0
	var sweep_n := 0
	var vib_rate := 0.0
	var vib_depth := 0.0
	var vib_k := 1.0
	var decay_n: int
	var phase := 0.0

	func _init(v: Dictionary, decay_samples: int) -> void:
		decay_n = decay_samples
		wave = WAVES.find(v.type)
		freq = v.f0
		sweep_n = maxi(1, int(v.get("fdur", v.dur) * RATE))
		freq_k = pow(v.f1 / v.f0, 1.0 / sweep_n)
		var vib: Array = v.get("vib", [])
		if vib.size() == 2:
			vib_rate = vib[0]
			vib_depth = vib[1]
			vib_k = pow(1.0 / vib_depth, 1.0 / maxi(1, int(v.dur * RATE)))

	func next(i: int) -> float:
		var f := freq
		if vib_depth > 0.0:
			f += sin(TAU * vib_rate * i / float(RATE)) * vib_depth
			if i < decay_n:
				vib_depth *= vib_k
		var dt := absf(f) / float(RATE)
		phase += dt
		phase -= floorf(phase)
		if i < sweep_n:
			freq *= freq_k
		match wave:
			0: return sin(TAU * phase)
			1: return (1.0 if phase < 0.5 else -1.0) + _blep(phase, dt) - _blep(fposmod(phase + 0.5, 1.0), dt)
			2: return 2.0 * phase - 1.0 - _blep(phase, dt)
		return 1.0 - 4.0 * absf(phase - 0.5)

	static func _blep(t: float, dt: float) -> float:
		if t < dt:
			t /= dt
			return t + t - t * t - 1.0
		if t > 1.0 - dt:
			t = (t - 1.0) / dt
			return t * t + t + t + 1.0
		return 0.0


## RBJ cookbook biquad with Web Audio's Q conventions (dB for low/high pass).
class Biquad:
	var b0: float
	var b1: float
	var b2: float
	var a1: float
	var a2: float
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0

	func _init(type: String, freq: float, q: float) -> void:
		var w0 := TAU * minf(freq, RATE * 0.45) / RATE
		var cw := cos(w0)
		var alpha := sin(w0) / (2.0 * q) if type == "bandpass" else sin(w0) / (2.0 * pow(10.0, q / 20.0))
		var a0 := 1.0 + alpha
		match type:
			"lowpass":
				b0 = (1.0 - cw) / 2.0
				b1 = 1.0 - cw
				b2 = b0
			"highpass":
				b0 = (1.0 + cw) / 2.0
				b1 = -(1.0 + cw)
				b2 = b0
			_:
				b0 = alpha
				b1 = 0.0
				b2 = -alpha
		b0 /= a0
		b1 /= a0
		b2 /= a0
		a1 = -2.0 * cw / a0
		a2 = (1.0 - alpha) / a0

	func next(x: float) -> float:
		var y := b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		return y
