extends Node2D
## An indicator lamp that lights on blink() and fades out.

const Pal := preload("res://game/palette.gd")

## A colour name from palette.gd.
@export var ink: StringName = &"SPARE"
## How fast the lamp fades, per second.
@export var fade_rate := 8.0

var _on := 0.0


func blink() -> void:
	_on = 1.0


func _process(delta: float) -> void:
	_on = maxf(0.0, _on - minf(0.033, delta) * fade_rate)
	queue_redraw()


func _draw() -> void:
	var color := PrintLabel.ink_color(ink)
	draw_circle(Vector2.ZERO, 5, Pal.GHOST)
	if _on > 0.01:
		draw_circle(Vector2.ZERO, 9, Color(color, _on * 0.18))
		draw_circle(Vector2.ZERO, 5, Color(color, _on))
