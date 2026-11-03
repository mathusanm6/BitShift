extends Node2D
## A spare switch arcing from the shot bit into the >> key, spinning and
## swelling mid-flight. The repair itself is timed by RightKey.

const BitArt := preload("res://game/art/bit_art.gd")

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _dur := 0.62
var _t := 0.0


func setup(from: Vector2, to: Vector2, duration: float) -> Node2D:
	_from = from
	_to = to
	_dur = duration
	_process(0.0)
	return self


func _process(delta: float) -> void:
	_t += minf(0.033, delta)
	if _t >= _dur:
		queue_free()
	var p := minf(1.0, _t / _dur)
	var q := p * p * (3 - 2 * p)
	var ctrl := Vector2((_from.x + _to.x) / 2 + 80, minf(_from.y, _to.y) - 60)
	position = _from * (1 - q) * (1 - q) + ctrl * 2 * (1 - q) * q + _to * q * q
	rotation = p * 8
	queue_redraw()


func _draw() -> void:
	BitArt.spare_icon(self, Vector2.ZERO, 24 + sin(minf(1.0, _t / _dur) * PI) * 10)
