class_name DemoBot
extends Node
## Plays the attract-mode demo. It picks the busiest stretch of columns,
## walks the gun there, loads bits matching the lowest ones and fires. Every
## fifth plan it siphons and pastes a slot instead. It refits a broken >> key.

## Emitted for each key the bot plays. Game connects it to Game.act.
signal pressed(id: StringName)

const Lay := preload("res://game/layout.gd")
## Seconds with a broken >> key before the bot fits a spare.
const REFIT_DELAY := 7.0

@export var field: Field
@export var gun: Gun
@export var keyboard: Keyboard

var rng := RandomNumberGenerator.new()

var _wait := 0.0
## Keys still to play: StringNames, or {aim = column} to load matching bits.
var _plan: Array[Variant] = []
var _plans_made := 0
var _refit_t := 0.0


func _init() -> void:
	rng.randomize()


func reset() -> void:
	_wait = 1.1
	_plan = [&"B0", &"B1", &"F"]
	_refit_t = 0.0


func tick(dt: float) -> void:
	_tick_refit(dt)
	_wait -= dt
	if _wait > 0.0:
		return
	_wait = rng.randf_range(0.16, 0.26)
	if _plan.is_empty():
		_plan = _next_plan()
		_wait = 0.45
		return
	var next: Variant = _plan.pop_front()
	if next is Dictionary:
		var keys := _matching_keys(next.aim)
		for j in range(keys.size() - 1, 0, -1):
			_plan.push_front(keys[j])
		next = keys[0]
	keyboard.key(next).tap()
	pressed.emit(next)


func _tick_refit(dt: float) -> void:
	var right_key := keyboard.right_key
	if right_key.durability == 0 and _refit_t == 0.0:
		_refit_t = REFIT_DELAY
	if _refit_t > 0.0:
		_refit_t -= dt
		if _refit_t <= 0.0:
			_refit_t = 0.0
			right_key.repair()


func _next_plan() -> Array[Variant]:
	_plans_made += 1
	if _plans_made % 5 == 0 and not field.is_empty():
		return [&"S0", &"S0", &"F"]
	var target := _busiest_aim()
	var plan: Array[Variant] = []
	var at := gun.column
	if keyboard.right_key.durability > 0:
		while at > target:
			plan.append(&"L")
			at -= 1
		while at < target:
			plan.append(&"R")
			at += 1
	else:
		# With >> broken, go round the long way through the left wall.
		for i in (at - target + Lay.GUN_MAX + 1) % (Lay.GUN_MAX + 1):
			plan.append(&"L")
	plan.append({aim = target})
	plan.append(&"F")
	return plan


## The gun position with the most bits above it, with a little randomness.
func _busiest_aim() -> int:
	var best_x := 0
	var best := -1.0
	for x in Lay.GUN_MAX + 1:
		var s := rng.randf() * 2
		for i in Lay.CHAMBERS:
			s += field.column(x + i).size()
		if s > best:
			best = s
			best_x = x
	return best_x


## Load keys that match each column's lowest bit (random over empty columns).
func _matching_keys(aim: int) -> Array[StringName]:
	var keys: Array[StringName] = []
	for i in Lay.CHAMBERS:
		var bit := field.column(aim + i).lowest()
		var one := bit.value == 1 if bit else rng.randf() < 0.5
		keys.append(&"B1" if one else &"B0")
	return keys
