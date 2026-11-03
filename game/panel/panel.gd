extends Node2D
## The live readouts: level, combo and score in the top window, the CLK and
## BEAT lamps, the HP column and the danger band. Reads the run's numbers
## every frame and passes them to its children.

const HpBar := preload("res://game/panel/hp_bar.gd")
const DangerBand := preload("res://game/panel/danger_band.gd")
const Led := preload("res://game/panel/led.gd")

@export var scorekeeper: Scorekeeper
@export var field: Field

@onready var _level: PrintLabel = $Level
@onready var _combo: PrintLabel = $Combo
@onready var _score: PrintLabel = $Score
@onready var _hp_bar: HpBar = $HpBar
@onready var _danger: DangerBand = $DangerBand
@onready var _clock_led: Led = $ClockLed
@onready var _beat_led: Led = $BeatLed


func _ready() -> void:
	Events.clock_tick.connect(_clock_led.blink)
	Audio.beat.connect(_beat_led.blink)


func _exit_tree() -> void:
	Audio.beat.disconnect(_beat_led.blink)


func _process(_delta: float) -> void:
	_level.text = "%02d" % scorekeeper.level
	_combo.text = "x%d" % scorekeeper.combo
	var combo_ink := &"SPARE" if scorekeeper.combo > 1 else &"STEEL_LO"
	if _combo.ink != combo_ink:
		_combo.ink = combo_ink
	_score.text = "%07d" % scorekeeper.score
	_hp_bar.hp = scorekeeper.hp
	_danger.peak = field.peak_height()
