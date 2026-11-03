extends RefCounted
## Skewed seven-segment digits, used on bit tiles and empty chambers.


## glyph: 0, 1, 2, 8 or "_" (the empty-chamber underscore).
static func draw(ci: CanvasItem, x: float, y: float, w: float, h: float, t: float, glyph: Variant, color: Color) -> void:
	var polys: Array[PackedVector2Array] = []
	if glyph is int and glyph == 1:
		# A 1 is one continuous bar with a flag, so it never reads as a colon at speed.
		var xc := t * 0.45
		var top := -h / 2
		polys.append(PackedVector2Array([Vector2(xc - t / 2, top), Vector2(xc + t / 2, top), Vector2(xc + t / 2, h / 2), Vector2(xc - t / 2, h / 2)]))
		polys.append(PackedVector2Array([Vector2(xc - t / 2, top), Vector2(xc - t * 1.9, top + t * 1.15), Vector2(xc - t * 1.9, top + t * 2.35), Vector2(xc - t / 2, top + t * 1.3)]))
	else:
		var segs := "abcdefg"
		if glyph is int and glyph == 0:
			segs = "abcdef"
		elif glyph is int and glyph == 2:
			segs = "abged"
		elif glyph is String:
			segs = "d"
		polys = _segments(-w / 2, -h / 2, w, h, t, segs)
	# Italic skew around the digit's centre.
	var cx := x + w / 2
	var cy := y + h / 2
	for poly in polys:
		var out := PackedVector2Array()
		for p in poly:
			out.append(Vector2(cx + p.x - 0.08 * p.y, cy + p.y))
		ci.draw_colored_polygon(out, color)


static func _segments(x: float, y: float, w: float, h: float, t: float, segs: String) -> Array[PackedVector2Array]:
	var m := y + h / 2
	var out: Array[PackedVector2Array] = []
	for s in segs:
		match s:
			"a": out.append(_horizontal(x, x + w, y + t / 2, t))
			"g": out.append(_horizontal(x, x + w, m, t))
			"d": out.append(_horizontal(x, x + w, y + h - t / 2, t))
			"f": out.append(_vertical(x + t / 2, y, m, t))
			"e": out.append(_vertical(x + t / 2, m, y + h, t))
			"b": out.append(_vertical(x + w - t / 2, y, m, t))
			"c": out.append(_vertical(x + w - t / 2, m, y + h, t))
	return out


static func _horizontal(x0: float, x1: float, yc: float, t: float) -> PackedVector2Array:
	var g := t * 0.03
	return PackedVector2Array([
		Vector2(x0 + t / 2 + g, yc), Vector2(x0 + t + g, yc - t / 2), Vector2(x1 - t - g, yc - t / 2),
		Vector2(x1 - t / 2 - g, yc), Vector2(x1 - t - g, yc + t / 2), Vector2(x0 + t + g, yc + t / 2)])


static func _vertical(xc: float, y0: float, y1: float, t: float) -> PackedVector2Array:
	var g := t * 0.03
	return PackedVector2Array([
		Vector2(xc, y0 + t / 2 + g), Vector2(xc + t / 2, y0 + t + g), Vector2(xc + t / 2, y1 - t - g),
		Vector2(xc, y1 - t / 2 - g), Vector2(xc - t / 2, y1 - t - g), Vector2(xc - t / 2, y0 + t + g)])
