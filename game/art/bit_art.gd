extends RefCounted
## Bit tiles and their markings: the lit tile itself, the steel lock, the crack
## a broken lock leaves, and the green spare-switch badge.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const Shapes := preload("res://game/art/shapes.gd")
const Seg7 := preload("res://game/art/seg7.gd")

const LASER := 2
const FLIP := 3


## Draws a bit tile at (x, y), TW wide and h tall. b: 0, 1, LASER or FLIP.
static func tile(ci: CanvasItem, b: int, x: float, y: float, h: float, a := 1.0) -> void:
	var w := Lay.TW
	var big := h > 45
	var dw := 22.0
	var dx := x + (w - dw) / 2
	var dy := y + h * 0.12
	var dh := h * 0.76
	var r := Rect2(x, y, w, h)
	match b:
		1:
			Shapes.glow_rr(ci, r, 4, Shapes.fade(Pal.ONE, a * 0.8), 9)
			Shapes.grad_rr(ci, r, 4, Shapes.fade(Pal.ONE_HI, a), Shapes.fade(Pal.ONE, a))
			Seg7.draw(ci, dx, dy, dw, dh, 6.0 if big else 4.8, 1, Shapes.fade(Pal.ONE_DEEP, a))
		0:
			Shapes.glow_rr(ci, r.grow(-1), 4, Shapes.fade(Pal.ZERO, a * 0.5), 5)
			Shapes.fill_rr(ci, r.grow(-1), 4, Shapes.fade(Pal.ZERO_DEEP, a))
			Shapes.stroke_rr(ci, r.grow(-1), 4, Shapes.fade(Pal.ZERO, a), 2)
			Seg7.draw(ci, dx, dy, dw, dh, 5.0 if big else 4.0, 0, Shapes.fade(Pal.ZERO, a))
		LASER:
			_laser(ci, r, a, big, dx, dy, dw, dh)
		_:
			_flip(ci, r, a)


static func _laser(ci: CanvasItem, r: Rect2, a: float, big: bool, dx: float, dy: float, dw: float, dh: float) -> void:
	var w := r.size.x
	var h := r.size.y
	Shapes.glow_rr(ci, r, 4, Shapes.fade(Pal.WHITE, a * 0.8), 12)
	Shapes.fill_rr(ci, r, 4, Shapes.fade(Pal.WHITE, a))
	var ink := Shapes.fade(Pal.INK, a)
	for rect: Rect2 in [Rect2(3, 4, 3, h - 8), Rect2(3, 4, 7, 3), Rect2(3, h - 7, 7, 3),
			Rect2(w - 6, 4, 3, h - 8), Rect2(w - 10, 4, 7, 3), Rect2(w - 10, h - 7, 7, 3)]:
		ci.draw_rect(Rect2(rect.position + r.position, rect.size), ink)
	Seg7.draw(ci, dx + 1, dy, dw - 2, dh, 4.6 if big else 4.0, 2, ink)


static func _flip(ci: CanvasItem, r: Rect2, a: float) -> void:
	Shapes.glow_rr(ci, r.grow(-1), 4, Shapes.fade(Pal.FLIP, a * 0.7), 10)
	Shapes.fill_rr(ci, r.grow(-1), 4, Shapes.fade(Pal.FLIP_DEEP, a))
	Shapes.stroke_rr(ci, r.grow(-1), 4, Shapes.fade(Pal.FLIP, a), 2)
	var rad := minf(r.size.x, r.size.y) * 0.26
	var c := r.get_center()
	for i in 3:
		var ang := PI / 2 + i * PI / 3
		var d := Vector2(cos(ang), sin(ang)) * rad
		ci.draw_line(c - d, c + d, Shapes.fade(Pal.FLIP, a), 4, true)
		ci.draw_circle(c - d, 2, Shapes.fade(Pal.FLIP, a))
		ci.draw_circle(c + d, 2, Shapes.fade(Pal.FLIP, a))


static func spare_icon(ci: CanvasItem, c: Vector2, s: float) -> void:
	var r := Rect2(c - Vector2(s, s) / 2, Vector2(s, s))
	Shapes.fill_rr(ci, r, 3, Pal.SPARE_DEEP)
	Shapes.stroke_rr(ci, r, 3, Pal.SPARE, 1.5)
	var a := s * 0.55
	var t := s * 0.2
	ci.draw_rect(Rect2(c.x - a / 2, c.y - t / 2, a, t), Pal.SPARE)
	ci.draw_rect(Rect2(c.x - t / 2, c.y - a / 2, t, a), Pal.SPARE)


## A heavy steel [ ] bolted around the bit: this one takes two matching shots.
static func lock(ci: CanvasItem, x: float, y: float, h: float) -> void:
	var t := 8.0
	var lip := 17.0
	var top := y - 1
	var bot := y + h + 1
	var stops := [[0.0, Pal.WHITE], [0.45, Pal.STEEL], [1.0, Pal.STEEL_LO]]
	for side: Array in [[x, 1.0], [x + Lay.TW, -1.0]]:
		var x0: float = side[0]
		var dir: float = side[1]
		var pts := PackedVector2Array([
			Vector2(x0, top), Vector2(x0 + dir * lip, top), Vector2(x0 + dir * lip, top + t - 2),
			Vector2(x0 + dir * t, top + t - 2), Vector2(x0 + dir * t, bot - t + 2), Vector2(x0 + dir * lip, bot - t + 2),
			Vector2(x0 + dir * lip, bot), Vector2(x0, bot)])
		Shapes.grad_stops(ci, pts, top, bot, stops)
		var outline := pts.duplicate()
		outline.append(pts[0])
		ci.draw_polyline(outline, Pal.INK, 2, true)
		for ry: float in [top + 3.5, bot - 3.5]:
			ci.draw_circle(Vector2(x0 + dir * 4, ry), 1.5, Pal.INK)


static func crack(ci: CanvasItem, x: float, y: float) -> void:
	var c := Color(Pal.WHITE, 0.9)
	ci.draw_polyline(PackedVector2Array([Vector2(x + 9, y + 2), Vector2(x + 21, y + 14), Vector2(x + 15, y + 23), Vector2(x + 25, y + 34)]), c, 1.6, true)
	ci.draw_polyline(PackedVector2Array([Vector2(x + 21, y + 14), Vector2(x + 48, y + 9), Vector2(x + 70, y + 17)]), c, 1.6, true)
