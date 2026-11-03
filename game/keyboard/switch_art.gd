class_name SwitchArt
extends Node2D
## The bare key switch under the >> cap: housing, red cross stem, and the
## flare when it sparks. Drawn behind the cap. Origin: the stem's centre.

const Pal := preload("res://game/palette.gd")
const Shapes := preload("res://game/art/shapes.gd")
const SIZE := 66.0

## How far the stem is pushed down, in px.
var dip := 0.0
## Spark flare, 0 to 1.
var flare := 0.0


func _draw() -> void:
	var housing := Rect2(-Vector2(SIZE, SIZE) / 2, Vector2(SIZE, SIZE))
	Shapes.fill_rr(self, housing, 6, Pal.HOUSING)
	Shapes.stroke_rr(self, housing, 6, Pal.STEEL_LO, 2)
	for d: Vector2 in [Vector2(-24, -24), Vector2(24, -24), Vector2(-24, 24), Vector2(24, 24)]:
		draw_rect(Rect2(d - Vector2(3, 1), Vector2(6, 2)), Pal.STEEL_LO)
	draw_rect(Rect2(-6, -18, 12, 40), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(-18, -6, 40, 12), Color(0, 0, 0, 0.5))
	Shapes.fill_rr(self, Rect2(-5, -19 + dip, 10, 38), 1.5, Pal.STEM)
	Shapes.fill_rr(self, Rect2(-19, -5 + dip, 38, 10), 1.5, Pal.STEM)
	if flare > 0.0:
		for i in 5:
			var color := Pal.ONE_HI if i < 4 else Pal.WHITE
			draw_circle(Vector2.ZERO, 70.0 * (5 - i) / 5.0, Color(color, flare * (0.08 + i * 0.06)))
