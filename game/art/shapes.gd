extends RefCounted
## Rounded rectangles, gradients and glows drawn into any CanvasItem, under
## whatever transform that item has set.


static func fade(c: Color, a: float) -> Color:
	return Color(c, c.a * a)


static func rr_points(r: Rect2, rad: float) -> PackedVector2Array:
	rad = clampf(rad, 0.0, minf(r.size.x, r.size.y) / 2)
	if rad <= 0.01:
		return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var centers := [
		Vector2(r.end.x - rad, r.position.y + rad), r.end - Vector2(rad, rad),
		Vector2(r.position.x + rad, r.end.y - rad), r.position + Vector2(rad, rad),
	]
	var pts := PackedVector2Array()
	for c in 4:
		for i in 6:
			var a := -PI / 2 + c * PI / 2 + i * PI / 10
			pts.append(centers[c] + Vector2(cos(a), sin(a)) * rad)
	return pts


static func fill_rr(ci: CanvasItem, r: Rect2, rad: float, color: Color) -> void:
	ci.draw_colored_polygon(rr_points(r, rad), color)


static func stroke_rr(ci: CanvasItem, r: Rect2, rad: float, color: Color, width: float) -> void:
	var pts := rr_points(r, rad)
	pts.append(pts[0])
	ci.draw_polyline(pts, color, width, true)


## Vertical linear gradient from c0 at y0 to c1 at y1 (defaults to the rect's span).
static func grad_rr(ci: CanvasItem, r: Rect2, rad: float, c0: Color, c1: Color, y0 := NAN, y1 := NAN) -> void:
	if is_nan(y0):
		y0 = r.position.y
	if is_nan(y1):
		y1 = r.end.y
	var pts := rr_points(r, rad)
	var colors := PackedColorArray()
	for p in pts:
		colors.append(c0.lerp(c1, clampf((p.y - y0) / maxf(0.001, y1 - y0), 0.0, 1.0)))
	ci.draw_polygon(pts, colors)


## Multi-stop vertical gradient. The polygon is cut into bands at each stop so the
## per-vertex colours interpolate exactly. stops: [[t, Color], ...] with t in 0..1.
static func grad_stops(ci: CanvasItem, pts: PackedVector2Array, y0: float, y1: float, stops: Array) -> void:
	for i in range(1, stops.size()):
		var ya := lerpf(y0, y1, stops[i - 1][0]) if i > 1 else -1e6
		var yb := lerpf(y0, y1, stops[i][0]) if i < stops.size() - 1 else 1e6
		var band := PackedVector2Array([Vector2(-1e6, ya), Vector2(1e6, ya), Vector2(1e6, yb), Vector2(-1e6, yb)])
		for poly: PackedVector2Array in Geometry2D.intersect_polygons(pts, band):
			if poly.size() < 3:
				continue
			var colors := PackedColorArray()
			for p in poly:
				colors.append(_color_at(stops, clampf((p.y - y0) / maxf(0.001, y1 - y0), 0.0, 1.0)))
			ci.draw_polygon(poly, colors)


static func _color_at(stops: Array, q: float) -> Color:
	for i in range(1, stops.size()):
		if q <= stops[i][0]:
			var a: Array = stops[i - 1]
			var b: Array = stops[i]
			return (a[1] as Color).lerp(b[1], (q - a[0]) / maxf(0.0001, b[0] - a[0]))
	return stops[-1][1]


## Stand-in for canvas shadowBlur: a few soft rings behind the shape.
static func glow_rr(ci: CanvasItem, r: Rect2, rad: float, color: Color, blur: float) -> void:
	for i in 3:
		var g := blur * (3 - i) / 3.0
		fill_rr(ci, r.grow(g), rad + g, fade(color, 0.13 + i * 0.05))
