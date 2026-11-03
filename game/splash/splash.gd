extends CanvasLayer
## The first screen on launch: "Made by Mathusan Selvakumar" on the dotted
## mat. Fades in, holds, fades out to the start menu, then frees itself.
## Any key, click or tap skips it, and no input reaches the game meanwhile.

const Backdrop := preload("res://game/board/backdrop.gd")
const FADE_IN := 0.5
const HOLD := 2
const FADE_OUT := 0.5

@onready var _root: Control = $Root
@onready var _content: Control = $Root/Center

var _tween: Tween
var _leaving := false


func _ready() -> void:
	($Root/Mat as TextureRect).texture = Backdrop.make_texture()
	_content.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_content, "modulate:a", 1.0, FADE_IN)
	_tween.tween_interval(HOLD)
	_tween.tween_callback(_leave)


func _input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	var pressed := (event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed()
	if pressed:
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_root, "modulate:a", 0.0, FADE_OUT)
	_tween.tween_callback(queue_free)
