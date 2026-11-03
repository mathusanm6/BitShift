extends Node2D
## A white rectangle that fades out: a shattered tile or an exploding row.

const Pal := preload("res://game/palette.gd")
const Shapes := preload("res://game/art/shapes.gd")

var _rect := Rect2()
var _radius := 0.0
var _dur := 0.2
var _t := 0.0


func setup(rect: Rect2, radius: float, duration: float) -> Node2D:
	_rect = rect
	_radius = radius
	_dur = duration
	return self


func _process(delta: float) -> void:
	_t += minf(0.033, delta)
	if _t >= _dur:
		queue_free()
	queue_redraw()


func _draw() -> void:
	Shapes.fill_rr(self, _rect, _radius, Color(Pal.WHITE, maxf(0.0, 1.0 - _t / _dur)))
