extends Node2D
## The left wall lights up where the gun scraped it while wrapping around.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")

var _level := 0.0


func _ready() -> void:
	Events.wall_wrap.connect(func() -> void: _level = 1.0)
	Events.reset.connect(func() -> void: _level = 0.0)


func _process(delta: float) -> void:
	_level = maxf(0.0, _level - minf(0.033, delta) * 3.5)
	queue_redraw()


func _draw() -> void:
	if _level > 0.01:
		draw_rect(Rect2(Lay.GX - 8, Lay.GUN_Y - 14, 11, 92), Color(Pal.ONE, _level * 0.2))
		draw_rect(Rect2(Lay.GX - 4, Lay.GUN_Y - 10, 3, 84), Color(Pal.ONE_HI, _level))
