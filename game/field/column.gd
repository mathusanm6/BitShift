class_name Column
extends Node2D
## One column of the field: a stack of Bit nodes, lowest first. It applies
## gravity to the stack and resolves whatever is fired into it.

signal changed
signal landed
signal lock_cracked
## The lowest bit was shot away. It is freed at the end of the frame.
signal bit_shot(bit: Bit)
signal misfired
signal lasered(count: int)

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const BitScene := preload("res://game/field/bit.tscn")
const GRAVITY := 75.0
const LASER_DEPTH := 3

@export var index := 0

## Bottom first. A bit's index here is the row it rests on once settled.
var bits: Array[Bit] = []


func size() -> int:
	return bits.size()


func lowest() -> Bit:
	return bits[0] if bits.size() else null


func top_row() -> float:
	return bits[-1].row if bits.size() else -1.0


func is_settled(i: int) -> bool:
	return not bits[i].incoming and bits[i].row == i


func is_moving() -> bool:
	for i in bits.size():
		if not bits[i].incoming and bits[i].row != i:
			return true
	return false


func describe() -> String:
	var s := ""
	for bit in bits:
		s += str(bit.value)
	return s


# ------------------------------------------------------------ stack editing

func stack(b: int, row: float, incoming := false, spare := false, locked := false) -> Bit:
	var bit: Bit = BitScene.instantiate()
	bits.append(bit.setup(b, row, incoming, spare, locked))
	add_child(bit)
	_place(bit)
	return bit


func push_under(b: int, row: float, incoming: bool) -> Bit:
	var bit: Bit = BitScene.instantiate()
	bits.push_front(bit.setup(b, row, incoming))
	add_child(bit)
	_place(bit)
	return bit


## Removes the bit at index i. It stays readable until freed at the end of the frame.
func take(i := 0) -> Bit:
	var bit: Bit = bits.pop_at(i)
	bit.queue_free()
	return bit


func clear() -> void:
	for bit in bits:
		bit.queue_free()
	bits.clear()


# ------------------------------------------------------------------ gravity

## Moves every bit, and emits landed when one comes to rest.
func tick(dt: float, incoming_speed: float) -> void:
	var did_land := false
	for i in bits.size():
		var bit := bits[i]
		var floor_row := 0.0 if i == 0 else bits[i - 1].row + 1.0
		if bit.incoming:
			bit.row -= incoming_speed * dt
		elif bit.row > floor_row:
			bit.fall_speed += GRAVITY * dt
			bit.row -= bit.fall_speed * dt
		if bit.row <= floor_row and (bit.row != floor_row or bit.incoming or bit.fall_speed != 0.0):
			# Rests on the bit below. It counts as landed once that bit has landed too.
			var rested := i == 0 or is_settled(i - 1)
			if rested and (bit.incoming or bit.fall_speed != 0.0):
				did_land = true
				bit.lift = -0.08 if bit.fall_speed != 0.0 else 0.0
				bit.incoming = false
			bit.row = floor_row
			bit.fall_speed = 0.0
		bit.lift += (0.0 - bit.lift) * minf(1.0, dt * 22.0)
		if bit.flash > 0.0:
			bit.flash = maxf(0.0, bit.flash - dt * 4.0)
		_place(bit)
	if did_land:
		landed.emit()


func _place(bit: Bit) -> void:
	bit.position = Vector2(Lay.col_x(index) + 2, Lay.row_px(bit.row + bit.lift) + 1)
	bit.visible = bit.position.y <= Lay.FLOOR + 2


# --------------------------------------------------------------------- hits

## Resolves a bullet of value b reaching the lowest bit.
func take_shot(b: int) -> void:
	var t := lowest()
	var cx := Lay.col_x(index) + Lay.CW / 2
	if t.value == b and t.locked:
		# First matching shot on a locked bit: the lock breaks and the bit stays.
		t.locked = false
		t.cracked = true
		t.flash = 1.0
		Events.burst.emit(Vector2(cx, Lay.row_px(t.row) + Lay.ROW_H / 2), 16, Pal.STEEL, 220.0, false)
		Events.shake.emit(0.12)
		Events.sound(&"crack")
		Events.log_event("Lock broken in column %d: one more shot" % index)
		lock_cracked.emit()
		return
	if t.value == b:
		take(0)
		Events.shatter.emit(index, t.row, t.value)
		bit_shot.emit(t)
		changed.emit()
		return
	# Misfire: the shot sticks under the column and the pile grows by one.
	var stuck := push_under(b, maxf(0.0, t.row - 1.0), t.incoming)
	stuck.flash = 1.0
	for i in range(1, bits.size()):
		var lowest_row := bits[i - 1].row + 1.0
		if bits[i].row < lowest_row:
			bits[i].lift = bits[i].row - lowest_row
			bits[i].row = lowest_row
	Events.shake.emit(0.18)
	Events.sound(&"misfire")
	Events.burst.emit(Vector2(cx, Lay.row_px(stuck.row) + Lay.ROW_H), 8, Pal.FAULT, 180.0, true)
	Events.log_event("Misfire: a %d stuck under column %d" % [b, index])
	misfired.emit()
	changed.emit()


## A piercing laser: takes up to three bits off the bottom.
func laser() -> void:
	var count := mini(LASER_DEPTH, bits.size())
	for i in count:
		var bit := take(0)
		Events.shatter.emit(index, bit.row, bit.value)
	if count:
		changed.emit()
	lasered.emit(count)
	Events.beam.emit(index, Pal.WHITE, 18.0, 0.2)
	Events.shake.emit(0.2)
	Events.sound(&"laser")
	Events.log_event("Piercing laser hit %d in column %d" % [count, index])


## A flipper shot: inverts every bit in the column.
func flip() -> void:
	for bit in bits:
		bit.value = 1 - bit.value
		bit.flash = 1.0
	if bits.size():
		changed.emit()
	Events.beam.emit(index, Pal.FLIP, 12.0, 0.24)
	Events.sound(&"flip")
	Events.log_event("Flipper shot inverted %d in column %d" % [bits.size(), index])
