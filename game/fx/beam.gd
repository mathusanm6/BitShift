extends Node2D
## A laser or flipper beam up one column, narrowing as it fades.

const Lay := preload("res://game/layout.gd")

var _color := Color.WHITE
var _width := 18.0
var _dur := 0.2
var _t := 0.0


func setup(col: int, color: Color, width: float, duration: float) -> Node2D:
	position = Vector2(Lay.col_x(col) + Lay.CW / 2, Lay.TOP)
	_color = color
	_width = width
	_dur = duration
	return self


func _process(delta: float) -> void:
	_t += minf(0.033, delta)
	if _t >= _dur:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var p := minf(1.0, _t / _dur)
	var w := _width * (1 - p)
	var h := Lay.GUN_Y - Lay.TOP
	draw_rect(Rect2(-w / 2 - 8, 0, w + 16, h), Color(_color, (1 - p) * 0.2))
	draw_rect(Rect2(-w / 2, 0, w, h), Color(_color, 1 - p))
