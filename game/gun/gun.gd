class_name Gun
extends Node2D
## The cannon carriage under the field. Tracks which column it covers, slides,
## and springs its drawn position and recoil toward that. Sliding past the left
## wall slams into the HP bar and bounces back to the right.

signal wall_impact

const Lay := preload("res://game/layout.gd")

## Leftmost column under the barrel.
var column := 1

var _x := 1.0
var _x_v := 0.0
var _kick := 0.0
var _kick_v := 0.0
var _hitting_wall := false

@onready var barrel: Barrel = $Barrel
@onready var _view: GunView = $View


func _ready() -> void:
	_view.barrel = barrel


## Moves straight to a column, with no slide animation.
func place(c: int) -> void:
	column = c
	_x = c
	_x_v = 0.0
	_hitting_wall = false


## Slides one column left. Off the left edge it bounces off the HP bar to the right: returns true.
func slide_left() -> bool:
	if column > 0:
		column -= 1
		return false
	column = Lay.GUN_MAX
	_hitting_wall = true
	_x_v = minf(_x_v, -10.0)
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
	if _hitting_wall:
		_x_v = move_toward(_x_v, -14.0, 220.0 * dt)
		_x += _x_v * dt
		if _x <= -0.15:
			_x = -0.15
			_x_v = 11.5
			_hitting_wall = false
			kick(120.0)
			wall_impact.emit()
	else:
		_x_v += (900 * (column - _x) - 48 * _x_v) * dt
		_x += _x_v * dt
	_kick_v += (700 * (0.0 - _kick) - 22 * _kick_v) * dt
	_kick += _kick_v * dt
	_view.position = Vector2(Lay.col_x(_x), Lay.GUN_Y + _kick * 0.05)
	_view.refresh()
