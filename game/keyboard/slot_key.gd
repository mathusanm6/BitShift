class_name SlotKey
extends KeyCap
## A clip slot. Empty, it siphons four bits off the field; loaded, it pastes
## them into the barrel and dashes the gun right. After a paste it may need
## to recharge. Its face shows the cartridge and what pressing will do.

const Fonts := preload("res://game/art/fonts.gd")

## Four entries of 0, 1 or null (a gap). Empty when the slot is empty.
var cartridge: Array = []
## Seconds until the slot can be used again.
var cooldown := 0.0


func is_loaded() -> bool:
	return not cartridge.is_empty()


func empty() -> void:
	cartridge = []
	cooldown = 0.0


func describe() -> String:
	var s := ""
	for b: Variant in cartridge:
		s += "_" if b == null else str(b)
	return s


func tick(dt: float) -> void:
	cooldown = maxf(0.0, cooldown - dt)


func _draw_face(face: Rect2) -> void:
	var x := face.position.x
	var y := face.position.y
	var w := face.size.x
	Fonts.text(self, "SLOT %d" % (Lay.slot_of(id) + 1), x + 6, y + 13, &"label", 12, ink(), Fonts.Align.LEFT, 1)
	Fonts.text(self, hint, x + w - 6, y + 13, &"mono_med", 11, ink(), Fonts.Align.RIGHT)
	Shapes.fill_rr(self, Rect2(x + 5, y + 17, w - 10, 19), 2, Pal.GLASS)
	var cell_w := (w - 14) / Lay.CHAMBERS
	for n in Lay.CHAMBERS:
		var b: Variant = cartridge[n] if is_loaded() else null
		var cx := x + 7 + n * cell_w
		draw_rect(Rect2(cx + 1, y + 19, cell_w - 2, 15), Pal.ONE if b == 1 else (Pal.ZERO if b == 0 else Pal.GHOST))
		if b != null:
			Fonts.text(self, str(b), cx + cell_w / 2, y + 31, &"mono", 13, Pal.ONE_DEEP if b == 1 else Pal.ZERO_DEEP, Fonts.Align.CENTER)
	var action := "RECHARGE %.1f" % cooldown if cooldown > 0.0 else ("LOAD + DASH" if is_loaded() else "SIPHON")
	Fonts.text(self, action, x + w / 2, y + 50, &"label", 13, ink(), Fonts.Align.CENTER, 1.04)
