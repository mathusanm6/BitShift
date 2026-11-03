extends Node2D
## A red band under the ceiling that pulses harder as the tallest column
## climbs into the top three rows.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")

## Height of the tallest column, in bits.
var peak := 0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var near := clampf((peak - (Lay.ROWS - 3)) / 3.0, 0.0, 1.0)
	if near <= 0.0:
		return
	var t := Time.get_ticks_msec() * 0.001
	var pulse := 0.15 + 0.10 * sin(t * (12.0 + near * 16.0))
	draw_rect(Rect2(Lay.GX, Lay.TOP, Lay.CW * Lay.N, Lay.ROW_H * 2), Color(Pal.FAULT, near * pulse))
