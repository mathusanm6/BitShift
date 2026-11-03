class_name Tutorial
extends Node
## Runs the tutorial: stages the current lesson, plays its steps through the
## instrument's keys at a readable pace, then replays it after a pause.
## The player moves between lessons; Game ticks this while in TUTORIAL mode.

signal lesson_changed(index: int, lesson: Dictionary)

const Lessons := preload("res://game/tutorial/lessons.gd")
## Seconds before the first step, between key presses, and after the last.
const LEAD_IN := 1.2
const STEP_GAP := 0.45
const LINGER := 2.6

@export var game: Game

var index := 0
## True once the lesson has played out, until it replays.
var ended := false

var _cursor := 0
var _wait := 0.0


func count() -> int:
	return Lessons.ALL.size()


func lesson() -> Dictionary:
	return Lessons.ALL[index]


func begin() -> void:
	show_lesson(0)


func next() -> void:
	show_lesson(mini(index + 1, count() - 1))


func previous() -> void:
	show_lesson(maxi(index - 1, 0))


func is_last() -> bool:
	return index == count() - 1


func show_lesson(i: int) -> void:
	index = i
	_replay()
	lesson_changed.emit(index, lesson())


## The lesson has played out (or overflowed): wait, then play it again.
func lesson_ended() -> void:
	if not ended:
		ended = true
		_wait = LINGER


func tick(dt: float) -> void:
	_wait -= dt
	if _wait > 0.0:
		return
	if ended:
		_replay()
		return
	var steps: Array = lesson().steps
	if _cursor >= steps.size():
		if not lesson().get("waves", false):
			lesson_ended()
		return
	var step: Variant = steps[_cursor]
	_cursor += 1
	if step is float:
		_wait = step
	else:
		game.demo_press(step)
		_wait = STEP_GAP


func _replay() -> void:
	game.stage_lesson(lesson())
	_cursor = 0
	_wait = LEAD_IN
	ended = false
