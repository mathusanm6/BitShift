extends Node2D
## The glass over the field: faint scanlines and a diagonal reflection that
## stops dead halfway, like a real sheet of glass.

const Lay := preload("res://game/layout.gd")
const Shapes := preload("res://game/art/shapes.gd")


func _draw() -> void:
	var g := Lay.GLASS
	var line := Color(0, 0, 0, 0.13)
	var y := g.position.y
	while y < g.end.y:
		draw_rect(Rect2(g.position.x, y, g.size.x, 1), line)
		y += 3
	var p0 := g.position
	var v := Vector2(240, 300)
	var edge := p0 + v * 0.51
	var u := Vector2(-v.y, v.x).normalized() * 3000
	var back := -v.normalized() * 3000
	var half := PackedVector2Array([edge + u, edge - u, edge - u + back, edge + u + back])
	for poly: PackedVector2Array in Geometry2D.intersect_polygons(Shapes.rr_points(g, 7), half):
		var colors := PackedColorArray()
		for p in poly:
			var q := clampf((p - p0).dot(v) / v.length_squared(), 0.0, 0.5)
			colors.append(Color(1, 1, 1, lerpf(0.05, 0.012, q / 0.5)))
		draw_polygon(poly, colors)
