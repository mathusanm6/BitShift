extends Node2D
## One dashed aim line per chamber, up to the column's lowest bit. Green means
## the loaded bit will shatter it, red means it will stick, white is a laser
## and violet a flipper. The target bit gets a matching outline.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const Shapes := preload("res://game/art/shapes.gd")

@export var field: Field
@export var gun: Gun


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for n in Lay.CHAMBERS:
		var c := gun.column + n
		var chamber: Barrel.Chamber = gun.barrel.chambers[n]
		var target := field.column(c).lowest()
		var color := _aim_color(chamber, target)
		var xc := Lay.col_x(gun.visual_column() + n) + Lay.CW / 2
		var y_top := Lay.row_px(target.row) + Lay.ROW_H if target else Lay.TOP
		var y := Lay.GUN_Y - 4
		while y > y_top:
			draw_rect(Rect2(xc - 1, y - 5, 2, 5), Color(color, 0.75 if chamber else 0.3))
			y -= 9
		if target and chamber:
			Shapes.stroke_rr(self, Rect2(Lay.col_x(c) + 1, Lay.row_px(target.row + target.lift), Lay.TW + 2, 38), 5, color, 3)


func _aim_color(chamber: Barrel.Chamber, target: Bit) -> Color:
	if chamber == null:
		return Pal.STEEL_LO
	if chamber.value == Barrel.LASER:
		return Pal.WHITE
	if chamber.value == Barrel.FLIP:
		return Pal.FLIP
	if target == null:
		return Pal.STEEL
	return Pal.SPARE if target.value == chamber.value else Pal.FAULT
