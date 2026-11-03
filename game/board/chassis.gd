extends Node2D
## The instrument's static body: grained case, screws, readout window, the
## glass bed with column stripes and row ticks, the gun rail and the key
## wells. Printed text lives in child PrintLabels.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const Shapes := preload("res://game/art/shapes.gd")

const TICK := Color(160 / 255.0, 200 / 255.0, 210 / 255.0, 0.1)
const STRIPE := Color(160 / 255.0, 200 / 255.0, 210 / 255.0, 0.028)

var _grain: ImageTexture


func _ready() -> void:
	_grain = _make_grain()


func _draw() -> void:
	_draw_case()
	_draw_glass_bed()
	for key in Lay.KEY_ORDER:
		Shapes.fill_rr(self, Lay.key_rect(key).grow(3), 12, Pal.INK)


func _draw_case() -> void:
	var body := Shapes.rr_points(Rect2(4, 4, Lay.W - 8, Lay.H - 8), 12)
	Shapes.grad_stops(self, body, 0, Lay.H, [[0.0, Pal.CHASSIS_HI], [0.2, Pal.CHASSIS], [1.0, Pal.CHASSIS_LO]])
	draw_texture(_grain, Vector2.ZERO)
	Shapes.stroke_rr(self, Rect2(4.5, 4.5, Lay.W - 9, Lay.H - 9), 12, Pal.CHASSIS_HI, 1)
	for p: Vector2 in [Vector2(15, 15), Vector2(Lay.W - 15, 15), Vector2(15, Lay.H - 15), Vector2(Lay.W - 15, Lay.H - 15)]:
		draw_circle(p, 5, Pal.STEEL_LO)
		draw_circle(p, 4, Pal.STEEL)
		var slot := Vector2.from_angle(p.x * 0.7 + p.y) * 3.4
		draw_line(p - slot, p + slot, Pal.STEEL_LO, 1.6)
	# Readout window
	Shapes.fill_rr(self, Rect2(262, 12, 286, 46), 5, Pal.GLASS)
	Shapes.stroke_rr(self, Rect2(262, 12, 286, 46), 5, Pal.INK, 2)


func _draw_glass_bed() -> void:
	Shapes.fill_rr(self, Lay.GLASS.grow(3), 10, Pal.INK)
	Shapes.grad_stops(self, Shapes.rr_points(Lay.GLASS, 7), Lay.GLASS.position.y, Lay.GLASS.end.y, [[0.0, Pal.GLASS_HI], [0.5, Pal.GLASS], [1.0, Pal.GLASS]])
	for i in Lay.N:
		if i % 2 == 0:
			draw_rect(Rect2(Lay.col_x(i), Lay.TOP, Lay.CW, Lay.FLOOR - Lay.TOP), STRIPE)
	for r in Lay.ROWS + 1:
		var y := Lay.FLOOR - r * Lay.ROW_H - 0.5
		draw_rect(Rect2(Lay.GX - 3, y, 3, 1), TICK)
		draw_rect(Rect2(Lay.GX + Lay.CW * Lay.N, y, 3, 1), TICK)
	draw_rect(Rect2(Lay.GX - 3, Lay.GLASS.position.y, 1, Lay.TOP - Lay.GLASS.position.y), Color(TICK, 0.14))
	# Ceiling, floor and gun rail
	draw_rect(Rect2(Lay.GX, Lay.TOP - 1, Lay.CW * Lay.N, 1.5), Color(Pal.FAULT, 0.45))
	draw_rect(Rect2(Lay.GX, Lay.FLOOR, Lay.CW * Lay.N, 2), Pal.STEEL_LO)
	draw_rect(Rect2(Lay.GX - 2, Lay.RAIL_Y - 2, Lay.CW * Lay.N + 4, 7), Pal.HOUSING)
	for i in Lay.N + 1:
		draw_rect(Rect2(Lay.col_x(i) - 0.5, Lay.RAIL_Y - 2, 1, 7), Pal.STEEL_LO)


func _make_grain() -> ImageTexture:
	var img := Image.create(int(Lay.W), int(Lay.H), false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 9000:
		var p := Vector2i(rng.randi_range(8, int(Lay.W) - 9), rng.randi_range(8, int(Lay.H) - 9))
		img.set_pixelv(p, Color(1, 1, 1, 0.05) if i % 2 else Color(0, 0, 0, 0.05))
	return ImageTexture.create_from_image(img)
