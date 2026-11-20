extends Node2D
## The live readouts: level, combo and score in the top window, the CLK and
## BEAT lamps, the HP column and the danger band. Reads the run's numbers
## every frame and passes them to its children.

const HpBar := preload("res://game/panel/hp_bar.gd")
const DangerBand := preload("res://game/panel/danger_band.gd")
const Led := preload("res://game/panel/led.gd")
const ComboFx := preload("res://game/panel/combo_fx.gd")
const COMBO_BASELINE := Vector2(320, 51)

@export var scorekeeper: Scorekeeper
@export var field: Field

@onready var _level: PrintLabel = $Level
@onready var _combo: PrintLabel = $Combo
@onready var _combo_fx: ComboFx = $ComboFx
@onready var _score: PrintLabel = $Score
@onready var _hp_bar: HpBar = $HpBar
@onready var _danger: DangerBand = $DangerBand
@onready var _clock_led: Led = $ClockLed
@onready var _beat_led: Led = $BeatLed

var _combo_scale := 1.0
var _combo_kick_y := 0.0
var _combo_shake := 0.0
var _combo_hit_flash := 0.0
var _combo_lost_flash := 0.0


func _ready() -> void:
	_combo.pivot_offset = Vector2(18, 15)
	Events.clock_tick.connect(_clock_led.blink)
	Events.combo_hit.connect(_on_combo_hit)
	Events.combo_lost.connect(_on_combo_lost)
	Events.reset.connect(_on_reset)
	Audio.beat.connect(_beat_led.blink)


func _exit_tree() -> void:
	Audio.beat.disconnect(_beat_led.blink)


func _on_combo_hit(combo: int, _col: int) -> void:
	_combo_scale = 1.38 if combo >= 10 else (1.28 if combo >= 5 else 1.2)
	_combo_kick_y = -3.0
	_combo_shake = 0.0
	_combo_hit_flash = 1.0
	_combo_lost_flash = 0.0


func _on_combo_lost(prev_combo: int, _col: int) -> void:
	_combo_scale = 0.9
	_combo_kick_y = 6.0 if prev_combo >= 2 else 3.0
	_combo_shake = 1.0 if prev_combo >= 2 else 0.45
	_combo_hit_flash = 0.0
	_combo_lost_flash = 1.0


func _on_reset() -> void:
	_combo_scale = 1.0
	_combo_kick_y = 0.0
	_combo_shake = 0.0
	_combo_hit_flash = 0.0
	_combo_lost_flash = 0.0
	_combo.scale = Vector2.ONE
	_combo.baseline = COMBO_BASELINE


func _process(delta: float) -> void:
	var dt := minf(0.033, delta)
	_combo_scale = lerpf(_combo_scale, 1.0, minf(1.0, dt * 14.0))
	_combo_kick_y = lerpf(_combo_kick_y, 0.0, minf(1.0, dt * 14.0))
	_combo_shake = maxf(0.0, _combo_shake - dt * 3.4)
	_combo_hit_flash = maxf(0.0, _combo_hit_flash - dt * 5.5)
	_combo_lost_flash = maxf(0.0, _combo_lost_flash - dt * 2.8)

	_level.text = "%02d" % scorekeeper.level
	_combo_fx.combo = scorekeeper.combo
	_combo.text = "x%d" % scorekeeper.combo
	_combo.scale = Vector2.ONE * _combo_scale

	var t := Time.get_ticks_msec() * 0.001
	var s := _combo_shake * _combo_shake
	var jitter := Vector2(sin(t * 119.0), cos(t * 143.0)) * s * 4.0
	var target_baseline := COMBO_BASELINE + Vector2(jitter.x, _combo_kick_y + jitter.y)
	if _combo.baseline != target_baseline:
		_combo.baseline = target_baseline

	var combo_ink := ComboAura.tier_ink(scorekeeper.combo)
	if _combo_lost_flash > 0.15:
		combo_ink = &"FAULT"
	elif _combo_hit_flash > 0.35:
		combo_ink = &"WHITE"
	if _combo.ink != combo_ink:
		_combo.ink = combo_ink

	_score.text = "%07d" % scorekeeper.score
	_hp_bar.hp = scorekeeper.hp
	_danger.peak = field.peak_height()
