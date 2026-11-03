class_name Bit
extends Node2D
## One enemy bit in a column. Its row is fractional while it falls; the
## column moves it, and the bit draws itself from its own state.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const BitArt := preload("res://game/art/bit_art.gd")
const Shapes := preload("res://game/art/shapes.gd")
const HEIGHT := 36.0

var value := 0:
	set(v):
		value = v
		queue_redraw()
## Rows above the floor, 0 at the bottom. Fractional while falling.
var row := 0.0
## Still arriving from above: falls at wave speed and is drawn faded.
var incoming := false:
	set(v):
		incoming = v
		queue_redraw()
## Shooting it launches a spare switch that refits the >> key.
var spare := false
## Needs two matching shots: the first only breaks the lock.
var locked := false:
	set(v):
		locked = v
		queue_redraw()
var cracked := false:
	set(v):
		cracked = v
		queue_redraw()
var fall_speed := 0.0
## Visual bounce offset in rows, springs back to 0.
var lift := 0.0
var flash := 0.0:
	set(v):
		flash = v
		queue_redraw()


func setup(b: int, at_row: float, is_incoming := false, is_spare := false, is_locked := false) -> Bit:
	value = b
	row = at_row
	incoming = is_incoming
	spare = is_spare
	locked = is_locked
	return self


func _process(_delta: float) -> void:
	if spare:
		queue_redraw()


func _draw() -> void:
	BitArt.tile(self, value, 0, 0, HEIGHT, 0.8 if incoming else 1.0)
	if locked:
		BitArt.lock(self, 0, 0, HEIGHT)
	if cracked:
		BitArt.crack(self, 0, 0)
	if flash > 0.0:
		Shapes.fill_rr(self, Rect2(0, 0, Lay.TW, HEIGHT), 4, Color(Pal.WHITE, flash * 0.8))
	if spare:
		var bob := sin(Time.get_ticks_msec() * 0.005) * 1.5
		BitArt.spare_icon(self, Vector2(Lay.TW - 8, 1 + bob), 17)
