extends Node2D
## Draws the loaded chambers of one gun copy, sliding and flashing.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const BitArt := preload("res://game/art/bit_art.gd")
const Shapes := preload("res://game/art/shapes.gd")

var barrel: Barrel


func _draw() -> void:
	if barrel == null:
		return
	for n in Lay.CHAMBERS:
		var chamber: Barrel.Chamber = barrel.chambers[n]
		if chamber == null:
			continue
		var x := n * Lay.CW + 2 + chamber.slide
		BitArt.tile(self, chamber.value, x, 7, Lay.CHAMBER_H)
		if chamber.flash > 0.0:
			Shapes.fill_rr(self, Rect2(x, 7, Lay.TW, Lay.CHAMBER_H), 4, Color(Pal.WHITE, chamber.flash))
