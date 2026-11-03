extends PanelContainer
## The tutorial's card on the glass: lesson number, title, the rule, and
## Back / Next / Exit. Sits at the top of the glass, or at the bottom when
## the lesson needs the top rows visible. (Esc leaves too, via Game.back.)

signal back_requested
signal next_requested
signal exit_requested

## Top edge of the card, and the bottom edge when the lesson asks for it low.
const TOP_Y := 96.0
const BOTTOM_Y := 500.0

@onready var _step: Label = $Rows/Header/Step
@onready var _title: Label = $Rows/Header/Title
@onready var _text: Label = $Rows/Text
@onready var _back: Button = $Rows/Buttons/Back
@onready var _next: Button = $Rows/Buttons/Next


func _ready() -> void:
	_back.pressed.connect(back_requested.emit)
	_next.pressed.connect(next_requested.emit)
	$Rows/Buttons/Exit.pressed.connect(exit_requested.emit)


func show_lesson(index: int, count: int, lesson: Dictionary) -> void:
	_step.text = "%d / %d" % [index + 1, count]
	_title.text = lesson.title
	_text.text = lesson.text
	_back.disabled = index == 0
	_next.text = "DONE" if index == count - 1 else "NEXT"
	reset_size()
	position.y = BOTTOM_Y - size.y if lesson.get("low", false) else TOP_Y
	_next.grab_focus()
