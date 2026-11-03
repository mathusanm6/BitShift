extends Node2D
## The instrument's 560x960 design space, centred in the window. Everything
## under it is laid out in board coordinates (see layout.gd).

const Lay := preload("res://game/layout.gd")


func _ready() -> void:
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	position = ((get_viewport_rect().size - Vector2(Lay.W, Lay.H)) / 2).floor()
