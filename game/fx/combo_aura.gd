class_name ComboAura
extends Node2D
## Playfield-edge glow while a combo is active/kept, pulsing on each hit and
## flashing red when the combo is lost.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")

var _combo := 0
var _hit_pulse := 0.0
var _lost_pulse := 0.0


## Returns the palette color for a combo count.
static func tier_color(combo: int) -> Color:
	if combo >= 10:
		return Pal.FLIP
	if combo >= 5:
		return Pal.ONE
	if combo >= 2:
		return Pal.SPARE
	return Pal.STEEL_LO


## Returns the palette token name for a combo count.
static func tier_ink(combo: int) -> StringName:
	if combo >= 10:
		return &"FLIP"
	if combo >= 5:
		return &"ONE"
	if combo >= 2:
		return &"SPARE"
	return &"STEEL_LO"


func _ready() -> void:
	Events.combo_hit.connect(_on_combo_hit)
	Events.combo_lost.connect(_on_combo_lost)
	Events.reset.connect(_on_reset)


func _on_combo_hit(combo: int, _col: int) -> void:
	_combo = combo
	if combo >= 2:
		_hit_pulse = 1.0
		_lost_pulse = 0.0


func _on_combo_lost(_prev_combo: int, _col: int) -> void:
	_combo = 0
	_hit_pulse = 0.0
	_lost_pulse = 1.0


func _on_reset() -> void:
	_combo = 0
	_hit_pulse = 0.0
	_lost_pulse = 0.0


func _process(delta: float) -> void:
	var dt := minf(0.033, delta)
	_hit_pulse = maxf(0.0, _hit_pulse - dt * 3.2)
	_lost_pulse = maxf(0.0, _lost_pulse - dt * 2.6)
	if _combo >= 2 or _hit_pulse > 0.01 or _lost_pulse > 0.01:
		queue_redraw()


func _draw() -> void:
	var field_w := Lay.CW * Lay.N
	var field_h := Lay.FLOOR - Lay.TOP
	if _lost_pulse > 0.01:
		var a := _lost_pulse
		draw_rect(Rect2(Lay.GX, Lay.TOP, 4, field_h), Color(Pal.FAULT, a * 0.45))
		draw_rect(Rect2(Lay.GX + field_w - 4, Lay.TOP, 4, field_h), Color(Pal.FAULT, a * 0.45))
		draw_rect(Rect2(Lay.GX, Lay.FLOOR - 4, field_w, 4), Color(Pal.FAULT, a * 0.75))
		return
	if _combo < 2:
		return
	var color := tier_color(_combo)
	var t := Time.get_ticks_msec() * 0.001
	var tier_boost := 0.08 if _combo >= 10 else (0.04 if _combo >= 5 else 0.0)
	var breathe := 0.12 + tier_boost + 0.06 * sin(t * 6.0)
	var alpha := clampf(breathe + _hit_pulse * 0.42, 0.0, 0.85)
	var edge_w := 3.0 + _hit_pulse * 3.0
	# Soft side rails and floor rail inside the glass.
	draw_rect(Rect2(Lay.GX, Lay.TOP, edge_w, field_h), Color(color, alpha * 0.55))
	draw_rect(Rect2(Lay.GX + field_w - edge_w, Lay.TOP, edge_w, field_h), Color(color, alpha * 0.55))
	draw_rect(Rect2(Lay.GX, Lay.FLOOR - 3, field_w, 3), Color(color, alpha))
	if _hit_pulse > 0.01:
		draw_rect(Rect2(Lay.GX, Lay.FLOOR - 10, field_w, 10), Color(color, _hit_pulse * 0.16))
