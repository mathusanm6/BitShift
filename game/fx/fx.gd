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
