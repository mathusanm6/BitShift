extends Node2D
## Expanding geometric pulse at a column when a combo hit lands.

const Shapes := preload("res://game/art/shapes.gd")
const DURATION := 0.32

var _color := Color.WHITE
var _size := Vector2(64, 24)
var _t := 0.0


func setup(pos: Vector2, color: Color, big := false) -> Node2D:
	position = pos
	_color = color
	_size = Vector2(82, 30) if big else Vector2(64, 22)
	return self


func _process(delta: float) -> void:
	_t += minf(0.033, delta) * Events.time_scale
	if _t >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var q := _t / DURATION
	var ease := 1.0 - pow(1.0 - q, 3.0)
	var w := lerpf(_size.x * 0.45, _size.x * 1.15, ease)
	var h := lerpf(_size.y * 0.45, _size.y * 1.25, ease)
	var r := Rect2(-w * 0.5, -h * 0.5 - ease * 14.0, w, h)
	var alpha := (1.0 - q) * 0.85
	Shapes.stroke_rr(self, r, 4.0, Color(_color, alpha), lerpf(2.6, 1.0, q))
