class_name Scorekeeper
extends Node
## Score, HP, level, combo and chain for one run, plus the saved best score.
## The scoring rules live here, driven by the field's events.

signal died

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const SaveFile := preload("res://game/save_file.gd")
const MAX_HP := 10
const BITS_PER_LEVEL := 24

## Whose hits, misfires and row explosions score.
@export var field: Field

var hp := MAX_HP
var score := 0
var best := 0
var level := 1
var destroyed := 0
## Hits in a row without a misfire.
var combo := 0
## Rows exploded by one cascade.
var chain := 0
## True during a real run: points count and damage hurts. Off in the demo.
var live := false


func _ready() -> void:
	_load_best()
	field.row_cleared.connect(on_row_cleared)
	field.lock_cracked.connect(on_lock_cracked)
	field.bit_shot.connect(on_bit_shot)
	field.misfired.connect(on_misfired)
	field.lasered.connect(on_lasered)


func reset() -> void:
	hp = MAX_HP
	score = 0
	level = 1
	destroyed = 0
	combo = 0
	chain = 0


func award(points: int) -> void:
	if live:
		score += points
	_update_level()


func count_destroyed(n: int) -> void:
	destroyed += n
	_update_level()


func damage(n: int) -> void:
	if not live:
		return
	hp = maxi(0, hp - n)
	Events.hurt.emit()
	if hp <= 0:
		died.emit()


## Keeps the best score on disk. Call when a run ends.
func record_best() -> void:
	if score > best:
		best = score
		SaveFile.write("score", "best", best)


func _load_best() -> void:
	best = int(SaveFile.read("score", "best", 0))


func _update_level() -> void:
	var next := 1 + destroyed / BITS_PER_LEVEL
	if next != level:
		level = next
		Events.log_event("Level %d" % next)
		Events.popup.emit(Vector2(Lay.GX + 240, 280), "LEVEL %d" % next, Pal.ONE_HI)


# ---------------------------------------------------------------- scoring

func on_lock_cracked(_col: int) -> void:
	combo += 1
	award(5 * level)


func on_bit_shot(_bit: Bit, _col: int) -> void:
	combo += 1
	destroyed += 1
	award(roundi(10 * level * (1 + (combo - 1) * 0.1)))
	Events.sound(&"shatter", mini(10, combo))


func on_misfired(_col: int) -> void:
	combo = 0


func on_lasered(_col: int, count: int) -> void:
	if count == 0:
		return
	destroyed += count
	award(count * 15 * level)
	combo += count


func on_row_cleared(row: int) -> void:
	chain += 1
	destroyed += Lay.N
	var points := 300 * level * chain
	award(points)
	var label := "CHAIN x%d +%d" % [chain, points] if chain > 1 else "ROW CLEAR +%d" % points
	Events.popup.emit(Vector2(Lay.GX + 240, Lay.row_px(row) + 8), label, Pal.SPARE)
	Events.log_event("Chain x%d: row %d exploded" % [chain, row] if chain > 1 else "Row %d exploded" % row)
	Events.sound(&"row_clear", chain)


## A spare switch reached a >> key that was already fully seated.
func on_spare_wasted(at: Vector2) -> void:
	if live:
		score += 50 * level
		Events.popup.emit(at, "SPARE +%d" % (50 * level), Pal.SPARE)
