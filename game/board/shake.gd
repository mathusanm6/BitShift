extends Node2D
## Screen shake. Events.shake adds trauma; the shake is trauma squared, so
## small knocks stay subtle and big hits are violent. Decays on its own.

const Lay := preload("res://game/layout.gd")
const DECAY := 1.9
const MAX_OFFSET := 13.0
const MAX_ROLL := 0.012

## Off when the player turned screen shake off.
@export var settings: PlayerSettings

var _trauma := 0.0
var _t := 0.0


func _ready() -> void:
	Events.shake.connect(_on_shake)
	Events.reset.connect(func() -> void: _trauma = 0.0)


func _on_shake(amount: float) -> void:
	if settings == null or settings.screen_shake:
		_trauma = minf(1.0, _trauma + amount)


func _process(delta: float) -> void:
	var dt := minf(0.033, delta)
	_t += dt
	_trauma = maxf(0.0, _trauma - dt * DECAY)
	var s := _trauma * _trauma
	if s <= 0.001:
		# Only write when it changes: every write notifies the whole subtree.
		if transform != Transform2D.IDENTITY:
			transform = Transform2D.IDENTITY
		return
	var center := Vector2(Lay.W, Lay.H) / 2
	var jitter := Vector2(sin(_t * 97), cos(_t * 83)) * s * MAX_OFFSET
	transform = Transform2D(sin(_t * 71) * s * MAX_ROLL, center) * Transform2D(0, -center + jitter)
