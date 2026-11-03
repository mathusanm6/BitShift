extends PanelContainer
## The start menu on the instrument's glass: start a game, open the tutorial,
## or change the settings. Arrow keys or the mouse move between items; Enter,
## Space or a tap picks one. Esc in the settings page goes back.

signal start_requested
signal tutorial_requested

@onready var _main: Control = $Main
@onready var _settings: SettingsPage = $SettingsPage
@onready var _start: Button = $Main/Start


func _ready() -> void:
	_start.pressed.connect(start_requested.emit)
	$Main/Tutorial.pressed.connect(tutorial_requested.emit)
	$Main/Settings.pressed.connect(show_settings)
	_settings.closed.connect(show_main)


func open(settings: PlayerSettings) -> void:
	_settings.settings = settings
	show_main()


func show_main() -> void:
	_settings.visible = false
	_main.visible = true
	reset_size()
	_start.grab_focus()


func show_settings() -> void:
	_main.visible = false
	_settings.open()
	reset_size()


func _unhandled_input(event: InputEvent) -> void:
	if visible and _settings.visible and event.is_action_pressed(&"ui_cancel"):
		show_main()
		get_viewport().set_input_as_handled()
