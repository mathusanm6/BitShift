extends Node2D
## A bit tile flying between two points while shrinking: siphoned bits going
## into a slot, or the oldest bit dropping out of a full barrel.

const Lay := preload("res://game/layout.gd")
const BitArt := preload("res://game/art/bit_art.gd")

var _b := 0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _h := 36.0
var _dur := 0.2
var _t := 0.0


## from and to are the tile's top-left corner at the start and end.
func setup(b: int, from: Vector2, to: Vector2, height: float, duration: float) -> Node2D:
	_b = b
	_from = from
	_to = to
	_h = height
	_dur = duration
	_process(0.0)
	return self


func _process(delta: float) -> void:
	_t += minf(0.033, delta)
	if _t >= _dur:
		queue_free()
	var p := minf(1.0, _t / _dur)
	var q := p * p * (3 - 2 * p)
	position = _from.lerp(_to, q) + Vector2(Lay.TW, _h) / 2
	scale = Vector2.ONE * (1.0 - q * 0.6)
	queue_redraw()


func _draw() -> void:
	BitArt.tile(self, _b, -Lay.TW / 2, -_h / 2, _h)
