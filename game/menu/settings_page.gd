class_name SettingsPage
extends VBoxContainer
## The settings page of the start menu. Each control edits the Settings node
## directly, which saves itself.

signal closed

const SPEEDS := PlayerSettings.SPEED_NAMES

var settings: PlayerSettings

@onready var _music: HSlider = $Grid/Music
@onready var _sound: HSlider = $Grid/Sound
@onready var _shake: Button = $Grid/Shake
@onready var _speed: Button = $Grid/Speed


func _ready() -> void:
	_music.value_changed.connect(func(v: float) -> void: settings.music_volume = v)
	_sound.value_changed.connect(_on_sound_changed)
	_shake.pressed.connect(_on_shake_pressed)
	_speed.pressed.connect(_on_speed_pressed)
	$Back.pressed.connect(closed.emit)


func open() -> void:
	visible = true
	_music.set_value_no_signal(settings.music_volume)
	_sound.set_value_no_signal(settings.sound_volume)
	_refresh()
	_music.grab_focus()


func _refresh() -> void:
	_shake.text = "ON" if settings.screen_shake else "OFF"
	_speed.text = SPEEDS[settings.start_speed]


func _on_sound_changed(v: float) -> void:
	settings.sound_volume = v
	Audio.play(&"key_down", 1.0)


func _on_shake_pressed() -> void:
	settings.screen_shake = not settings.screen_shake
	_refresh()
	Events.shake.emit(0.4)


func _on_speed_pressed() -> void:
	settings.start_speed = ((settings.start_speed + 1) % SPEEDS.size()) as PlayerSettings.Speed
	_refresh()
