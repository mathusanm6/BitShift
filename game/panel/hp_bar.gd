extends Node2D
## The HP column left of the field: ten pips and the number above them. It
## turns red and pulses at 3 HP or less, and jolts when the gun wraps the wall.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const Shapes := preload("res://game/art/shapes.gd")
const Fonts := preload("res://game/art/fonts.gd")
const PIPS := 10
const LOW := 3

var hp := PIPS

var _kick := 0.0
var _kick_v := 0.0


func _ready() -> void:
	Events.wall_wrap.connect(func() -> void: _kick_v -= 150.0)


func _process(delta: float) -> void:
	var dt := minf(0.033, delta)
	_kick_v += (420 * (0.0 - _kick) - 16 * _kick_v) * dt
	_kick += _kick_v * dt
	queue_redraw()


func _draw() -> void:
	var low := hp <= LOW
	var t := Time.get_ticks_msec() * 0.001
	var x := Lay.HP_X + _kick * 0.08
	for i in PIPS:
		var y := Lay.HP_BOTTOM - (i + 1) * Lay.HP_PIP - i * Lay.HP_GAP
		var r := Rect2(x, y, Lay.HP_W, Lay.HP_PIP)
		if i < hp:
			var a := 0.75 + 0.25 * sin(t * 10) if low else 1.0
			Shapes.fill_rr(self, r, 2, Color(Pal.FAULT if low else Pal.ONE, a))
		else:
			Shapes.fill_rr(self, r, 2, Pal.GHOST)
	var top := Lay.HP_BOTTOM - PIPS * Lay.HP_PIP - (PIPS - 1) * Lay.HP_GAP - 8
	Fonts.text(self, str(maxi(0, hp)), Lay.HP_X + Lay.HP_W / 2, top, &"display", 28, Pal.FAULT if low else Pal.ONE, Fonts.Align.CENTER)
