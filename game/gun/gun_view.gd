class_name GunView
extends Node2D
## One drawn copy of the gun: the steel carriage with its four sockets. The
## loaded bits are drawn by BarrelArt inside BarrelClip, so bits sliding in
## from the right stay inside the chambers. Origin: the carriage's left edge.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const Shapes := preload("res://game/art/shapes.gd")
const Seg7 := preload("res://game/art/seg7.gd")

var barrel: Barrel:
	set(v):
		barrel = v
		$BarrelClip/BarrelArt.barrel = v


func refresh() -> void:
	queue_redraw()
	$BarrelClip/BarrelArt.queue_redraw()


func _draw() -> void:
	var carriage := Rect2(-2, 0, Lay.CW * Lay.CHAMBERS + 4, 66)
	Shapes.grad_rr(self, carriage, 6, Pal.STEEL, Pal.STEEL_LO, 0, 68)
	Shapes.stroke_rr(self, carriage, 6, Pal.INK, 1.5)
	for n in Lay.CHAMBERS:
		var mx := n * Lay.CW + Lay.CW / 2
		draw_rect(Rect2(mx - 7, -5, 14, 8), Pal.INK)
		draw_rect(Rect2(mx - 5, -4, 10, 5), Pal.STEEL)
	for n in Lay.CHAMBERS:
		var cx := n * Lay.CW + 2
		var digit := Rect2(cx + (Lay.TW - 22) / 2, 7 + Lay.CHAMBER_H * 0.12, 22, Lay.CHAMBER_H * 0.76)
		Shapes.fill_rr(self, Rect2(cx, 7, Lay.TW, Lay.CHAMBER_H), 4, Pal.SOCKET)
		Seg7.draw(self, digit.position.x, digit.position.y, digit.size.x, digit.size.y, 5, 8, Pal.GHOST)
		Seg7.draw(self, digit.position.x, digit.position.y, digit.size.x, digit.size.y, 5, "_", Pal.STEEL_LO)
