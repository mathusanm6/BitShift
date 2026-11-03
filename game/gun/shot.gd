class_name Shot
extends Node2D
## A bullet climbing one column. Its origin is the column centre at its tip.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")

var column := 0
var value := 0


func setup(col: int, b: int, y: float) -> Shot:
	column = col
	value = b
	position = Vector2(Lay.col_x(col) + Lay.CW / 2, y)
	return self


func _draw() -> void:
	var color := Pal.ONE if value else Pal.ZERO
	draw_rect(Rect2(-8, -4, 16, 42), Color(color, 0.25))
	draw_rect(Rect2(-3, 0, 6, 34), color)
	draw_rect(Rect2(-1.5, 0, 3, 16), Pal.WHITE)
