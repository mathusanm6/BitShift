class_name Barrel
extends Node
## The gun's four chambers. Bits load from the right and shift left; firing
## empties every chamber at once. Pasting a slot over loaded chambers turns
## them into lasers (same bit) or flippers (different bit).

const Lay := preload("res://game/layout.gd")
const LASER := 2
const FLIP := 3


class Chamber:
	var value: int
	## Pixels still to slide left after a shift (cosmetic, springs to 0).
	var slide: float
	var slide_v := 0.0
	var flash := 0.0

	func _init(v: int, offset := 0.0) -> void:
		value = v
		slide = offset


## One entry per chamber, left to right: a Chamber or null.
var chambers: Array[Chamber] = []


func _init() -> void:
	clear()


func clear() -> void:
	chambers.clear()
	chambers.resize(Lay.CHAMBERS)


## Sets every chamber from a list of 0, 1 or null.
func fill(values: Array) -> void:
	clear()
	for i in values.size():
		if values[i] != null:
			chambers[i] = Chamber.new(values[i])


func is_empty() -> bool:
	return chambers.all(func(c: Chamber) -> bool: return c == null)


## Shifts the chambers right of the rightmost gap left and loads b on the right.
## With no gap, the oldest bit drops out: its value is returned, else -1.
func load_bit(b: int) -> int:
	var dropped := -1
	var gap := chambers.rfind(null)
	if gap < 0:
		dropped = chambers[0].value
		gap = 0
	for i in range(gap, Lay.CHAMBERS - 1):
		chambers[i] = chambers[i + 1]
		if chambers[i]:
			chambers[i].slide += Lay.CW
	chambers[Lay.CHAMBERS - 1] = Chamber.new(b, Lay.CW)
	return dropped


## Empties the barrel and returns what was in it.
func take_all() -> Array[Chamber]:
	var out := chambers.duplicate()
	clear()
	return out


## Loads a slot's cartridge. Returns (lasers made, flippers made).
func paste(cartridge: Array) -> Vector2i:
	var made := Vector2i.ZERO
	for n in cartridge.size():
		var b: Variant = cartridge[n]
		if b == null:
			continue
		var chamber := chambers[n]
		if chamber == null:
			chambers[n] = Chamber.new(b)
			chambers[n].flash = 1.0
			continue
		if chamber.value == LASER or chamber.value == FLIP:
			continue
		if chamber.value == b:
			chamber.value = LASER
			made.x += 1
		else:
			chamber.value = FLIP
			made.y += 1
		chamber.flash = 1.0
	return made


static func glyph(v: int) -> String:
	return "2" if v == LASER else ("*" if v == FLIP else str(v))


func describe() -> String:
	var s := ""
	for c in chambers:
		s += glyph(c.value) if c else "_"
	return s


func _process(delta: float) -> void:
	var dt := minf(0.033, delta)
	for c in chambers:
		if c == null:
			continue
		c.slide_v += (760 * (0.0 - c.slide) - 38 * c.slide_v) * dt
		c.slide += c.slide_v * dt
		if absf(c.slide) < 0.02 and absf(c.slide_v) < 0.02:
			c.slide = 0.0
			c.slide_v = 0.0
		c.flash = maxf(0.0, c.flash - dt * 3)
