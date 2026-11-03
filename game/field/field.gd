class_name Field
extends Node2D
## The play field: five columns of bits under the glass. Finds solid rows and
## stacks that reach the ceiling, and draws a guide under near-complete rows.
## Column events are re-emitted here with the column index.

signal row_cleared(row: int)
signal lock_cracked(col: int)
signal bit_shot(bit: Bit, col: int)
signal misfired(col: int)
signal lasered(col: int, count: int)

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const BoardText := preload("res://game/field/board_text.gd")

## Set when bits land or are removed; the game then checks rows and overflow.
var dirty := false
var columns: Array[Column] = []

var _landed := false


func _ready() -> void:
	for child in get_children():
		if child is Column:
			_adopt(child)


func _adopt(c: Column) -> void:
	columns.append(c)
	c.changed.connect(_mark_dirty)
	c.landed.connect(_on_landed)
	c.lock_cracked.connect(func() -> void: lock_cracked.emit(c.index))
	c.bit_shot.connect(func(bit: Bit) -> void: bit_shot.emit(bit, c.index))
	c.misfired.connect(func() -> void: misfired.emit(c.index))
	c.lasered.connect(func(count: int) -> void: lasered.emit(c.index, count))


func column(i: int) -> Column:
	return columns[i]


func _mark_dirty() -> void:
	dirty = true


func _on_landed() -> void:
	_landed = true


# -------------------------------------------------------------------- setup

func clear() -> void:
	for c in columns:
		c.clear()
	dirty = false


## Replaces the board with settled bits. See board_text.gd for the format.
func set_board(rows_bottom_first: Array) -> void:
	for c in columns:
		c.clear()
	for line: String in rows_bottom_first:
		var cells := BoardText.parse_line(line)
		for i in cells.size():
			var cell: Variant = cells[i]
			if cell:
				var c := columns[i]
				c.stack(cell.b, c.size(), false, cell.get("spare", false), cell.get("locked", false))
	dirty = true


## Parks every incoming bit at the given row (the attract screen's frozen wave).
func hold_incoming_at(row: float) -> void:
	for c in columns:
		for bit in c.bits:
			if bit.incoming:
				bit.row = row


# ------------------------------------------------------------------- update

func tick(dt: float, incoming_speed: float) -> void:
	_landed = false
	for c in columns:
		c.tick(dt, incoming_speed)
	if _landed:
		dirty = true
		Events.sound(&"land")


## Explodes every solid row of settled, same-value bits.
func clear_full_rows() -> void:
	var rows := _full_rows()
	if rows.is_empty():
		return
	rows.reverse()
	for r in rows:
		for c in columns:
			var bit := c.take(r)
			Events.shatter.emit(c.index, float(r), bit.value)
		Events.row_flash.emit(float(r))
		row_cleared.emit(r)
	Events.shake.emit(0.5)
	Events.slow_motion.emit(0.1)
	dirty = true


func _full_rows() -> Array[int]:
	var rows: Array[int] = []
	for r in Lay.ROWS + 1:
		if _row_value(r) >= 0:
			rows.append(r)
	return rows


## The value every settled bit in row r shares, or -1 when the row is not solid.
func _row_value(r: int) -> int:
	var first := -1
	for c in columns:
		if r >= c.size() or not c.is_settled(r):
			return -1
		if first < 0:
			first = c.bits[r].value
		elif c.bits[r].value != first:
			return -1
	return first


# ------------------------------------------------------------------ queries

## True once a settled bit sits above the top row.
func overflowed() -> bool:
	for c in columns:
		if c.size() > Lay.ROWS and c.is_settled(Lay.ROWS):
			return true
	return false


func is_moving() -> bool:
	return columns.any(func(c: Column) -> bool: return c.is_moving())


func is_empty() -> bool:
	return columns.all(func(c: Column) -> bool: return c.size() == 0)


## The tallest column, counting bits still falling.
func peak_height() -> int:
	var peak := 0
	for c in columns:
		peak = maxi(peak, c.size())
	return peak


# -------------------------------------------------------------------- guides

func _process(_delta: float) -> void:
	queue_redraw()


## Near-complete rows get a guide band, so a row explosion can be planned.
func _draw() -> void:
	for r in Lay.ROWS:
		var ones := 0
		var zeros := 0
		for c in columns:
			if r < c.size() and c.is_settled(r):
				if c.bits[r].value:
					ones += 1
				else:
					zeros += 1
		if maxi(ones, zeros) >= Lay.N - 1:
			draw_rect(Rect2(Lay.GX, Lay.row_px(r), Lay.CW * Lay.N, Lay.ROW_H), Color(Pal.ONE if ones >= zeros else Pal.ZERO, 0.2))
