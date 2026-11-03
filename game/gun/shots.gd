class_name Shots
extends Node2D
## Bullets in flight. Each Shot climbs its column and hits the column's lowest
## bit when it reaches it; a shot up an empty column leaves the top.

const Lay := preload("res://game/layout.gd")
const ShotScene := preload("res://game/gun/shot.tscn")
const SPEED := 1700.0

var _live: Array[Shot] = []


func fire(col: int, b: int) -> void:
	var shot: Shot = ShotScene.instantiate()
	add_child(shot.setup(col, b, Lay.CHAMBER_Y - 10))
	_live.append(shot)


func clear() -> void:
	for shot in _live:
		shot.queue_free()
	_live.clear()


func tick(dt: float, field: Field) -> void:
	for shot in _live.duplicate():
		shot.position.y -= SPEED * dt
		var target := field.column(shot.column)
		var bit := target.lowest()
		if bit and shot.position.y <= Lay.row_px(bit.row) + Lay.ROW_H:
			_remove(shot)
			target.take_shot(shot.value)
		elif shot.position.y <= Lay.TOP - 20:
			_remove(shot)


func _remove(shot: Shot) -> void:
	_live.erase(shot)
	shot.queue_free()
