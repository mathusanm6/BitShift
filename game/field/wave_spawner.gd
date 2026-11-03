class_name WaveSpawner
extends Node
## Generates the waves of bits that drop into the field, and decides how fast
## they fall and how often they come as the level rises.

const Lay := preload("res://game/layout.gd")

## Fall speed in the attract demo, in rows per second.
const ATTRACT_SPEED := 0.8

## Multiplies how fast waves fall and arrive. 0 holds the board still.
@export_range(0.0, 2.0, 0.25) var speed_scale := 1.0
## The player's start speed setting, another multiplier on the same.
var difficulty := 1.0
## False holds back new waves entirely (tutorial lessons).
var active := true

var rng := RandomNumberGenerator.new()
## Seconds until the next wave.
var countdown := 0.0


func _init() -> void:
	rng.randomize()


func fall_speed(level: int) -> float:
	return minf(3.2, 0.8 + (level - 1) * 0.12) * speed_scale * difficulty


func spawn_gap(level: int) -> float:
	return maxf(2.2, 6.0 - (level - 1) * 0.4)


## Counts down and drops a wave when due. An empty field is refilled quickly.
func tick(dt: float, speed: float, attract: bool, field: Field, level: int) -> void:
	if not active:
		return
	var empty := field.is_empty()
	if speed > 0.0:
		countdown -= dt * (1.0 if attract else speed_scale * difficulty)
	elif empty:
		countdown -= dt
	if empty and countdown > 0.5:
		countdown = 0.5
	if countdown <= 0.0:
		spawn(field, level)


func spawn(field: Field, level: int, kind := &"") -> void:
	if kind == &"":
		kind = pick_kind(level)
	var cells := gen_wave(kind, level)
	for i in Lay.N:
		var cell: Variant = cells[i]
		if cell:
			var c := field.column(i)
			c.stack(cell.b, maxf(Lay.ROWS, c.top_row() + 1), true, cell.get("spare", false), cell.get("locked", false))
	countdown = spawn_gap(level)


## The opening board: two full rows and a ragged third, one bit locked.
func seed_board(field: Field) -> void:
	field.clear()
	for row in 3:
		var bits := _bits(Lay.N)
		if bits.count(bits[0]) == bits.size():
			bits[rng.randi_range(0, Lay.N - 1)] = 1 - bits[0]
		for i in Lay.N:
			if row < 2 or rng.randf() < 0.6:
				var c := field.column(i)
				c.stack(bits[i], c.size())
	field.column(rng.randi_range(0, Lay.N - 1)).bits[1].locked = true
	field.dirty = true


func pick_kind(level: int) -> StringName:
	var r := rng.randf()
	if level >= 4 and r < 0.14:
		return &"bar"
	if level >= 2 and r < 0.45:
		return &"split"
	return &"cluster"


## Returns N entries: null or {b, spare?, locked?}.
func gen_wave(kind: StringName, level: int, force_spare := false) -> Array:
	var cells := []
	cells.resize(Lay.N)
	if kind == &"split":
		var a := rng.randi_range(1, 2)
		var b := rng.randi_range(1, 2)
		var gap := rng.randi_range(1, mini(2, Lay.N - a - b))
		var start := rng.randi_range(0, Lay.N - (a + b + gap))
		var bits := _bits(a + b)
		for i in a:
			cells[start + i] = {b = bits[i]}
		for i in b:
			cells[start + a + gap + i] = {b = bits[a + i]}
	elif kind == &"bar":
		var bits := _bits(Lay.N)
		for i in Lay.N:
			cells[i] = {b = bits[i]}
	else:
		var length := rng.randi_range(2, 3 if level < 3 else 4)
		var start := rng.randi_range(0, Lay.N - length)
		var bits := _bits(length)
		for i in length:
			cells[start + i] = {b = bits[i]}
	if force_spare or rng.randf() < 0.15:
		_add_spare(cells)
	# Locked bits appear from level 1 and get more common. They never carry a spare.
	if rng.randf() < minf(0.75, 0.35 + level * 0.05):
		_add_locks(cells, 2 if level >= 5 and rng.randf() < 0.3 else 1)
	return cells


func _add_spare(cells: Array) -> void:
	var ones := []
	for i in Lay.N:
		if cells[i] and cells[i].b == 1:
			ones.append(i)
	cells[ones[rng.randi_range(0, ones.size() - 1)]].spare = true


func _add_locks(cells: Array, count: int) -> void:
	var open := []
	for i in Lay.N:
		if cells[i] and not cells[i].get("spare", false):
			open.append(i)
	for i in count:
		if open.is_empty():
			break
		var pick: int = open.pop_at(rng.randi_range(0, open.size() - 1))
		cells[pick].locked = true


## A run of bits that leans toward one value, so solid rows can be built on purpose.
func _bits(length: int) -> Array[int]:
	var theme := rng.randi_range(0, 1)
	var a: Array[int] = []
	for i in length:
		a.append(theme if rng.randf() < 0.62 else 1 - theme)
	if not a.has(1):
		a[rng.randi_range(0, length - 1)] = 1
	return a
