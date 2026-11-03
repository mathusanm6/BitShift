class_name Gun
extends Node2D
## The cannon carriage under the field. Tracks which column it covers, slides
## and wraps, and springs its drawn position and recoil toward that. While it
## wraps it is drawn twice: leaving one edge and entering the other.

const Lay := preload("res://game/layout.gd")

## Leftmost column under the barrel.
var column := 1

var _x := 1.0
var _x_v := 0.0
var _kick := 0.0
var _kick_v := 0.0

@onready var barrel: Barrel = $Barrel
@onready var _views: Array[GunView] = [$View, $WrapView]


func _ready() -> void:
	for view in _views:
		view.barrel = barrel


## Moves straight to a column, with no slide animation.
func place(c: int) -> void:
	column = c
	_x = c
	_x_v = 0.0


## Slides one column left. Off the left edge it wraps to the right: returns true.
func slide_left() -> bool:
	if column > 0:
		column -= 1
		return false
	column = Lay.GUN_MAX
	_x += Lay.N
	return true


func at_right_wall() -> bool:
	return column >= Lay.GUN_MAX


func slide_right() -> void:
	column = mini(Lay.GUN_MAX, column + 1)


## Jumps up to n columns right, stopping at the wall. Returns columns moved.
func dash(n: int) -> int:
	var from := column
	column = mini(Lay.GUN_MAX, column + n)
	return column - from


func kick(impulse: float) -> void:
	_kick_v += impulse


## The column the carriage is drawn at, mid-slide.
func visual_column() -> float:
	return _x


func _process(delta: float) -> void:
	var dt := minf(0.033, delta)
	_x_v += (900 * (column - _x) - 48 * _x_v) * dt
	_x += _x_v * dt
	_kick_v += (700 * (0.0 - _kick) - 22 * _kick_v) * dt
	_kick += _kick_v * dt
	var copies: Array[float] = [_x]
	if _x > Lay.GUN_MAX + 0.01:
		copies.append(_x - Lay.N)
	elif _x < -0.01:
		copies.append(_x + Lay.N)
	for i in _views.size():
		var view := _views[i]
		view.visible = i < copies.size()
		if view.visible:
			view.position = Vector2(Lay.col_x(copies[i]), Lay.GUN_Y + _kick * 0.05)
			view.refresh()
