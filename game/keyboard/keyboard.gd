class_name Keyboard
extends Node2D
## The key bed. Finds keys by id or by board position, clicks, reports the
## player's presses while they count, and runs the slots' and the >> key's
## gameplay clocks. Shooting a spare bit in the field sends it to the >> key.

## A key the player pressed while presses count (see live).
signal key_pressed(id: StringName)

const Lay := preload("res://game/layout.gd")

## Where the >> key's cap falls when it breaks off.
@export var debris_layer: Node2D
## Whose spare bits, when shot, refit the >> key.
@export var field: Field

## True while the player's presses play the game. Set by Game per mode.
var live := false

var keys: Dictionary[StringName, KeyCap] = {}
## Slot 1 to 3, in order.
var slots: Array[SlotKey] = []

@onready var right_key: RightKey = $R


func _ready() -> void:
	for child in get_children():
		if child is KeyCap:
			keys[child.id] = child
			child.pressed.connect(_on_pressed)
			child.released.connect(_on_released)
	for id in Lay.SLOT_KEYS:
		slots.append(keys[id])
	right_key.debris_layer = debris_layer
	field.bit_shot.connect(_on_bit_shot)


func key(id: StringName) -> KeyCap:
	return keys[id]


## The key under a point in board coordinates, or &"" if none.
func key_at(board_point: Vector2) -> StringName:
	for id in Lay.KEY_ORDER:
		if keys[id].hit_test(board_point):
			return id
	return &""


func set_hover(id: StringName) -> void:
	for k: StringName in keys:
		keys[k].hover = k == id


func release_all() -> void:
	for k: StringName in keys:
		keys[k].release()


func empty_slots() -> void:
	for slot in slots:
		slot.empty()


func reset() -> void:
	empty_slots()
	right_key.reset()


func tick(dt: float) -> void:
	for slot in slots:
		slot.tick(dt)
	right_key.tick(dt)


## Presses a key on the player's behalf (the tutorial), click included.
func demo_press(id: StringName) -> void:
	keys[id].tap()
	_click(keys[id], keys[id].click_pitch)


func _on_pressed(id: StringName) -> void:
	if live:
		_click(keys[id], keys[id].click_pitch)
		key_pressed.emit(id)


func _on_released(id: StringName) -> void:
	_click(keys[id], keys[id].release_pitch, &"key_up")


## Dead keys (the broken >>) make no sound at all.
func _click(key: KeyCap, pitch: float, sound := &"key_down") -> void:
	if not key.is_dead():
		Events.sound(sound, pitch)


func _on_bit_shot(bit: Bit, col: int) -> void:
	if bit.spare:
		right_key.send_spare(Vector2(Lay.col_x(col) + Lay.CW - 8, Lay.row_px(bit.row) + 8))
