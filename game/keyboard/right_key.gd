class_name RightKey
extends KeyCap
## The >> key, which wears out. Every slide right costs one use: the cap
## rattles, then works loose and tilts, then breaks off and falls, leaving the
## bare switch sparking. A spare switch shot out of the field refits two uses.
## Origin: the key's top-left corner (the cap tilts about PIVOT, not its centre).

signal worn(durability: int)
signal repaired(before: int)

const LooseCapScene := preload("res://game/keyboard/loose_cap.tscn")
const MAX_DURABILITY := 3
const REPAIR_USES := 2
## Seconds a launched spare switch takes to fly into the key.
const SPARE_FLIGHT := 0.62
const STAGES: Array[String] = ["Broken", "Unseated", "Loose", "Seated"]
const PIVOT := Vector2(18, 10)

var durability := MAX_DURABILITY

## Where the broken-off cap falls: a layer that never shakes, since moving a
## physics body's parent teleports the body. Set by Keyboard.
var debris_layer: Node2D

var _spares: Array[float] = []
var _cap_on := true
var _tilt := 0.0
var _tilt_v := 0.0
var _offset := 0.0
var _offset_v := 0.0
var _drop_t := 1.0
var _spark_t := 1.0
var _flare := 0.0

@onready var _switch: SwitchArt = $Switch
@onready var _stage: PrintLabel = $Stage


func _ready() -> void:
	super()
	position = rect.position
	_switch.position = rect.size / 2 + Vector2(0, -6)
	_show_stage()


func is_dead() -> bool:
	return durability == 0


# -------------------------------------------------------------------- rules

## One use of the key. Called after a successful slide right.
func wear() -> void:
	durability -= 1
	Events.log_event(">> durability %d→%d (%s)" % [durability + 1, durability, STAGES[durability]])
	worn.emit(durability)
	_show_stage()
	match durability:
		2:
			_tilt_v += 1.6
			Events.sound(&"rattle")
		1:
			_tilt_v += 5.5
			Events.shake.emit(0.12)
			Events.sound(&"snap")
		0:
			_detach_cap()


func repair() -> void:
	var before := durability
	durability = mini(MAX_DURABILITY, before + REPAIR_USES)
	if before == 0:
		_drop_cap_in()
	else:
		_tilt_v -= 3.0
	Events.burst.emit(rect.get_center(), 18, Pal.SPARE, 300.0, true)
	Events.sound(&"repair")
	Events.log_event("Spare switch fitted: >> durability %d→%d" % [before, durability])
	_show_stage()
	repaired.emit(before)


func set_durability(n: int, quiet := false) -> void:
	durability = n
	if n > 0 and not _cap_on:
		_drop_cap_in()
	elif n == 0:
		_cap_on = false
		_spark_t = 0.2
	_show_stage()
	if not quiet:
		Events.log_event("Bench set >> durability to %d (%s)" % [n, STAGES[n]])


## A spare switch was shot loose at `from`: it flies over and refits the key.
func send_spare(from: Vector2) -> void:
	_spares.append(SPARE_FLIGHT)
	Events.spare_launched.emit(from, SPARE_FLIGHT)


## Gameplay clock: lands spares in flight.
func tick(dt: float) -> void:
	for i in range(_spares.size() - 1, -1, -1):
		_spares[i] -= dt
		if _spares[i] <= 0.0:
			_spares.remove_at(i)
			repair()


func reset() -> void:
	durability = MAX_DURABILITY
	_spares.clear()
	_cap_on = true
	_tilt = 0.0
	_tilt_v = 0.0
	_offset = 0.0
	_offset_v = 0.0
	_drop_t = 1.0
	_spark_t = 1.0
	_flare = 0.0
	_show_stage()


func _show_stage() -> void:
	if _stage:
		_stage.text = STAGES[durability].to_upper()
	queue_redraw()


# ------------------------------------------------------------------- motion

func _pose() -> void:
	pass  # The cap tilts about its own pivot in _draw; the key never rotates.


func _process(delta: float) -> void:
	super(delta)
	var dt := minf(0.033, delta)
	# Stage motion: Loose sits 2px off, Unseated tilts 15°, and wobble rides on top.
	var tilt_to := deg_to_rad(15.0) if durability == 1 else 0.0
	if _cap_on:
		var k := 150.0 if durability == 1 else 240.0
		var c := 5.5 if durability == 1 else 13.0
		_tilt_v += (k * (tilt_to - _tilt) - c * _tilt_v) * dt
		_tilt += _tilt_v * dt
		_offset_v += (300 * ((2.0 if durability == 2 else 0.0) - _offset) - 16 * _offset_v) * dt
		_offset += _offset_v * dt
	if _drop_t < 1.0:
		_drop_t = minf(1.0, _drop_t + dt / 0.22)
		if _drop_t == 1.0:
			Events.shake.emit(0.12)
			Events.sound(&"key_down", 0.9)
			_travel_v += 6.0
	if durability == 0 and not _cap_on:
		_spark(dt)
	_flare = maxf(0.0, _flare - dt * 7)
	_switch.dip = clampf(travel, 0.0, 1.0) * 5
	_switch.flare = 0.0 if _cap_on else _flare
	_switch.queue_redraw()


func _spark(dt: float) -> void:
	_spark_t -= dt
	if _spark_t > 0.0:
		return
	_spark_t = randf_range(0.55, 2.3)
	var color := Pal.ONE_HI if randf() < 0.5 else Pal.WHITE
	Events.burst.emit(rect.get_center() + Vector2(randf_range(-6, 6), -6), randi_range(6, 14), color, 330.0, true)
	Events.sound(&"spark")
	_flare = 1.0


func _drop_cap_in() -> void:
	_cap_on = true
	_drop_t = 0.0
	_offset = 0.0
	_offset_v = 0.0
	_tilt = 0.5
	_tilt_v = 0.0


func _detach_cap() -> void:
	var cap: LooseCap = LooseCapScene.instantiate()
	var centre := PIVOT + (rect.size / 2 - PIVOT).rotated(_tilt) + Vector2(_offset, 0)
	debris_layer.add_child(cap)
	cap.launch(to_global(centre), _tilt, legend, caption, hint)
	_cap_on = false
	_spark_t = 0.15
	Events.slow_motion.emit(0.12)
	Events.shake.emit(0.3)
	Events.burst.emit(rect.get_center(), 26, Pal.ONE_HI, 420.0, true)
	Events.sound(&"break_cap")


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	var lit := Pal.FAULT if durability == 1 else (Pal.ONE if durability == 2 else Pal.SPARE)
	for i in MAX_DURABILITY:
		var p := Vector2(35 + i * 12, -14)
		draw_circle(p, 4.6, Pal.INK)
		draw_circle(p, 3.2, lit if durability > i else Pal.GRAPHITE_LO)
	if not _cap_on:
		return
	var t := Time.get_ticks_msec() * 0.001
	var hov := 1.0 if hover else 0.45
	var wobble := 0.0
	var shift := 0.0
	if durability == 2:
		wobble = sin(t * 9.2) * 0.015 * hov + sin(t * 23) * 0.006 * hov
		shift = sin(t * 13) * 0.8 * hov
	elif durability == 1:
		wobble = sin(t * 2.7) * 0.022 + (sin(t * 27) * 0.012 if hover else 0.0)
	var drop := (1 - _drop_t) * (1 - _drop_t) * -90.0 if _drop_t < 1.0 else 0.0
	draw_set_transform_matrix(Transform2D(_tilt + wobble + spin, PIVOT + Vector2(_offset + shift, drop)) * Transform2D(0, -PIVOT))
	var face := KeyArt.cap(self, Rect2(Vector2.ZERO, rect.size), travel * 0.55 if durability == 1 else travel, Pal.CAPS[palette])
	_draw_face(face)
	draw_set_transform_matrix(Transform2D.IDENTITY)
