extends Node
## Turns the keyboard, mouse and touch into key presses on the instrument.
## Keyboard bindings are the bs_* actions in Project Settings > Input Map.
## Leaving the window releases every key and pauses a running game. The
## cards on the glass (menu, tutorial, pause) take their input as GUI first.

const ACTION_KEYS: Dictionary[StringName, StringName] = {
	&"bs_slide_left": &"L", &"bs_bit_0": &"B0", &"bs_bit_1": &"B1", &"bs_slide_right": &"R",
	&"bs_fire": &"F", &"bs_slot_1": &"S0", &"bs_slot_2": &"S1", &"bs_slot_3": &"S2",
}
## Touch index used for the mouse.
const MOUSE_POINTER := -1

@export var game: Game
@export var keyboard: Keyboard
@export var settings: PlayerSettings

## Which key each finger (or the mouse) is holding.
var _held: Dictionary[int, StringName] = {}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		_on_key(event)
	elif event is InputEventScreenTouch:
		_on_pointer(event.index, event.position, event.pressed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_on_pointer(MOUSE_POINTER, event.position, event.pressed)
	elif event is InputEventMouseMotion:
		var id := keyboard.key_at(_to_board(event.position))
		keyboard.set_hover(id)
		var pointing := id != &"" or game.mode != Game.Mode.PLAY
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if pointing else Input.CURSOR_ARROW)


func _on_key(event: InputEventKey) -> void:
	if event.is_action_pressed(&"bs_start"):
		game.primary_action()
	elif event.is_action_pressed(&"bs_pause"):
		game.back()
	elif event.is_action_pressed(&"bs_music"):
		settings.toggle_music()
	else:
		for action: StringName in ACTION_KEYS:
			if event.is_action_pressed(action):
				keyboard.key(ACTION_KEYS[action]).press(randf_range(-0.25, 0.25))
			elif event.is_action_released(action):
				keyboard.key(ACTION_KEYS[action]).release()


func _on_pointer(pointer: int, screen_pos: Vector2, is_down: bool) -> void:
	if not is_down:
		if _held.has(pointer):
			keyboard.key(_held[pointer]).release()
			_held.erase(pointer)
		return
	if game.mode in [Game.Mode.PAUSED, Game.Mode.OVER]:
		game.primary_action()
		return
	if game.mode != Game.Mode.PLAY:
		return
	var p := _to_board(screen_pos)
	var id := keyboard.key_at(p)
	if id == &"":
		return
	_held[pointer] = id
	var key := keyboard.key(id)
	# Hitting a key off-centre tilts it toward that side.
	key.press((p.x - key.rect.get_center().x) / key.rect.size.x * 0.5)


func _to_board(screen_pos: Vector2) -> Vector2:
	return keyboard.get_global_transform_with_canvas().affine_inverse() * screen_pos


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		game.focused = false
		keyboard.release_all()
		_held.clear()
		if game.mode == Game.Mode.PLAY:
			game.toggle_pause()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		game.focused = true
