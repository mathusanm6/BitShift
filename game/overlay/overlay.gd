extends Node2D
## The cards on the glass, one per mode: the start menu, the tutorial card,
## the pause card and the game-over card. Shows the right one when the mode
## changes, moves keyboard focus onto it, and sends its buttons to the game.

const Fonts := preload("res://game/art/fonts.gd")
const Menu := preload("res://game/menu/menu.gd")
const TutorialCard := preload("res://game/tutorial/tutorial_card.gd")

@export var game: Game
@export var tutorial: Tutorial
@export var settings: PlayerSettings

@onready var _menu: Menu = $Menu
@onready var _lesson: TutorialCard = $TutorialCard
@onready var _paused: Control = $Paused
@onready var _over: Control = $GameOver
@onready var _over_buttons: Control = $GameOver/Buttons


func _ready() -> void:
	_menu.start_requested.connect(game.start_game)
	_menu.tutorial_requested.connect(game.start_tutorial)
	_lesson.back_requested.connect(tutorial.previous)
	_lesson.next_requested.connect(_on_next_lesson)
	_lesson.exit_requested.connect(game.start_attract)
	tutorial.lesson_changed.connect(_on_lesson_changed)
	$Paused/Rows/Buttons/Resume.pressed.connect(game.toggle_pause)
	$Paused/Rows/Buttons/Menu.pressed.connect(game.start_attract)
	$GameOver/Buttons/Again.pressed.connect(game.start_game)
	$GameOver/Buttons/Menu.pressed.connect(game.start_attract)
	# On every card, the mouse moves the selection: hover and focus look the same.
	for button: Button in find_children("*", "Button", true, false):
		button.mouse_entered.connect(button.grab_focus)
	game.mode_changed.connect(_on_mode_changed)
	_on_mode_changed(game.mode)


func _on_mode_changed(mode: Game.Mode) -> void:
	_menu.visible = mode == Game.Mode.ATTRACT
	_lesson.visible = mode == Game.Mode.TUTORIAL
	_paused.visible = mode == Game.Mode.PAUSED
	_over.visible = mode == Game.Mode.OVER
	match mode:
		Game.Mode.ATTRACT: _menu.open(settings)
		Game.Mode.PAUSED: $Paused/Rows/Buttons/Resume.grab_focus()
		Game.Mode.OVER: _show_results()


func _on_lesson_changed(index: int, lesson: Dictionary) -> void:
	_lesson.show_lesson(index, tutorial.count(), lesson)


func _on_next_lesson() -> void:
	if tutorial.is_last():
		game.start_attract()
	else:
		tutorial.next()


func _process(_delta: float) -> void:
	# The game-over buttons appear once a restart is allowed.
	if _over.visible and not _over_buttons.visible and game.over_time > Game.RESTART_DELAY:
		_over_buttons.visible = true
		$GameOver/Buttons/Again.grab_focus()


func _show_results() -> void:
	var stats := game.scorekeeper
	var title: PrintLabel = $GameOver/Title
	title.text = "STACK OVERFLOW" if game.reason == &"stack" else "REGISTER FAULT"
	title.font_px = Fonts.fit_size(title.text, _over.size.x - 40, 42, &"display")
	($GameOver/Score as Label).text = "%07d" % stats.score
	($GameOver/Best as Label).text = "%07d" % stats.best
	($GameOver/Summary as Label).text = "Reached level %d. Destroyed %d bits." % [stats.level, stats.destroyed]
	_over_buttons.visible = false
