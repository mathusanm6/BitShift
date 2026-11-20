extends Node2D
## Turns Events into short-lived effect nodes, each placed in the layer it
## belongs to so the glass and clips cover it correctly. Every effect frees
## itself when done. This node itself is the top layer, over the keys.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const Burst := preload("res://game/fx/burst.gd")
const ScorePopup := preload("res://game/fx/popup.gd")
const Ghost := preload("res://game/fx/ghost.gd")
const Beam := preload("res://game/fx/beam.gd")
const FlashRect := preload("res://game/fx/flash_rect.gd")
const SpareFlight := preload("res://game/fx/spare_flight.gd")
const ComboRing := preload("res://game/fx/combo_ring.gd")

## Row and tile flashes, inside the field clip.
@export var field_layer: Node2D
## Laser and flipper beams, inside the shot clip, under the bullets.
@export var beam_layer: Node2D
## Bits flying into the slots and out of the barrel, under the glass.
@export var ghost_layer: Node2D
## Where launched spare switches fly to.
@export var right_key: RightKey


func _ready() -> void:
	Events.burst.connect(_on_burst)
	Events.shatter.connect(_on_shatter)
	Events.popup.connect(_on_popup)
	Events.ghost.connect(_on_ghost)
	Events.beam.connect(_on_beam)
	Events.row_flash.connect(_on_row_flash)
	Events.spare_launched.connect(_on_spare_launched)
	Events.combo_hit.connect(_on_combo_hit)
	Events.combo_lost.connect(_on_combo_lost)
	Events.reset.connect(_clear)


func _clear() -> void:
	for layer: Node in [self, field_layer, beam_layer, ghost_layer]:
		for child in layer.get_children():
			child.queue_free()


func _on_burst(pos: Vector2, count: int, color: Color, speed: float, spark: bool) -> void:
	add_child(Burst.new().scatter(pos, count, color, speed, spark))


func _on_shatter(col: int, row: float, b: int) -> void:
	var y := Lay.row_px(row)
	add_child(Burst.new().shards(Vector2(Lay.col_x(col) + Lay.CW / 2, y + 18), Pal.ONE if b else Pal.ZERO))
	field_layer.add_child(FlashRect.new().setup(Rect2(Lay.col_x(col) + 2, y + 1, Lay.TW, 36), 4, 0.14))


func _on_popup(pos: Vector2, text: String, color: Color) -> void:
	add_child(ScorePopup.new().setup(pos, text, color))


func _on_ghost(b: int, from: Vector2, to: Vector2, height: float, duration: float) -> void:
	ghost_layer.add_child(Ghost.new().setup(b, from, to, height, duration))


func _on_beam(col: int, color: Color, width: float, duration: float) -> void:
	beam_layer.add_child(Beam.new().setup(col, color, width, duration))


func _on_row_flash(row: float) -> void:
	field_layer.add_child(FlashRect.new().setup(Rect2(Lay.GX, Lay.row_px(row), Lay.CW * Lay.N, Lay.ROW_H), 0, 0.3))


func _on_spare_launched(from: Vector2, duration: float) -> void:
	add_child(SpareFlight.new().setup(from, right_key.rect.get_center() + Vector2(0, -6), duration))


func _on_combo_hit(combo: int, col: int) -> void:
	var color := ComboAura.tier_color(combo)
	var readout := Vector2(342, 42)
	add_child(Burst.new().scatter(readout, 12 if combo >= 5 else 7, color, 130.0, true))
	if combo < 2:
		return
	var cx := Lay.col_x(col) + Lay.CW / 2
	var milestone := combo % 5 == 0
	field_layer.add_child(ComboRing.new().setup(Vector2(cx, Lay.FLOOR - 18), color, milestone))
	field_layer.add_child(FlashRect.new().setup(Rect2(Lay.col_x(col) + 2, Lay.FLOOR - Lay.ROW_H, Lay.TW, Lay.ROW_H), 4, 0.16, Color(color, 0.45)))
	add_child(Burst.new().scatter(Vector2(cx, Lay.FLOOR - 18), 18 if milestone else 8, color, 220.0 if milestone else 150.0, true))
	var label := "COMBO x%d!" % combo if milestone else "x%d" % combo
	add_child(ScorePopup.new().setup(Vector2(cx, Lay.FLOOR - 46), label, color))
	if milestone:
		Events.shake.emit(0.18)
		Events.slow_motion.emit(0.045)


func _on_combo_lost(prev_combo: int, col: int) -> void:
	var readout := Vector2(342, 42)
	add_child(Burst.new().scatter(readout, 18 if prev_combo >= 2 else 7, Pal.FAULT, 185.0, true))
	if prev_combo < 2:
		return
	var cx := Lay.col_x(col) + Lay.CW / 2
	Events.shake.emit(0.28)
	Events.slow_motion.emit(0.06)
	field_layer.add_child(FlashRect.new().setup(Rect2(Lay.col_x(col) + 2, Lay.FLOOR - Lay.ROW_H, Lay.TW, Lay.ROW_H), 4, 0.32, Color(Pal.FAULT, 0.7)))
	field_layer.add_child(FlashRect.new().setup(Rect2(Lay.GX, Lay.FLOOR - 10, Lay.CW * Lay.N, 10), 0, 0.32, Color(Pal.FAULT, 0.8)))
	add_child(Burst.new().scatter(Vector2(cx, Lay.FLOOR - 20), 24, Pal.FAULT, 230.0, true))
	add_child(ScorePopup.new().setup(Vector2(cx, Lay.FLOOR - 40), "COMBO LOST x%d" % prev_combo, Pal.FAULT))
