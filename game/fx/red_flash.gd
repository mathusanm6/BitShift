extends Node2D
## A red rim inside the glass when the player is hurt.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const Shapes := preload("res://game/art/shapes.gd")

var _level := 0.0


func _ready() -> void:
	Events.hurt.connect(func() -> void: _level = 1.0)
	Events.reset.connect(func() -> void: _level = 0.0)


func _process(delta: float) -> void:
	_level = maxf(0.0, _level - minf(0.033, delta) * 3.2)
	queue_redraw()


func _draw() -> void:
	if _level > 0.01:
		Shapes.stroke_rr(self, Lay.GLASS.grow(-4), 5, Color(Pal.FAULT, _level * 0.55), 8)
