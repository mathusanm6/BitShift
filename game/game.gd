class_name Game
extends Node2D
## Root of BitShift. Owns the mode (menu demo, tutorial, play, dying, over,
## paused) and the clock: each frame it advances the gameplay systems in a
## fixed order, so the rules stay deterministic.

signal mode_changed(mode: Mode)

## ATTRACT is the start menu, with the demo bot playing behind it.
enum Mode { ATTRACT, TUTORIAL, PLAY, DYING, OVER, PAUSED }

const Lay := preload("res://game/layout.gd")
const Fonts := preload("res://game/art/fonts.gd")
const Scenarios := preload("res://game/test_bench/scenarios.gd")
## Seconds between the run ending and the game-over card.
const DYING_TIME := 0.75
## Seconds on the game-over card before it accepts a restart.
const RESTART_DELAY := 0.6
## Speed of everything during hit-stop.
const HIT_STOP_SCALE := 0.2

var mode := Mode.ATTRACT:
	set(v):
		mode = v
		Events.quiet = v == Mode.ATTRACT
		scorekeeper.live = v == Mode.PLAY or v == Mode.TUTORIAL
		keyboard.live = v == Mode.PLAY
		mode_changed.emit(v)
## Why the last run ended: &"stack" (a column hit the ceiling) or &"hp".
var reason := &""
var over_time := 0.0
## False while the window is in the background.
var focused := true

var _dying_t := 0.0
var _hit_stop_t := 0.0

@onready var settings: PlayerSettings = %Settings
@onready var scorekeeper: Scorekeeper = %Scorekeeper
@onready var actions: Actions = %Actions
@onready var spawner: WaveSpawner = %WaveSpawner
@onready var bot: DemoBot = %DemoBot
@onready var tutorial: Tutorial = %Tutorial
@onready var field: Field = %Field
@onready var gun: Gun = %Gun
@onready var shots: Shots = %Shots
@onready var keyboard: Keyboard = %Keyboard


func _ready() -> void:
	Events.slow_motion.connect(func(seconds: float) -> void: _hit_stop_t = seconds)
	scorekeeper.died.connect(_on_died)
	keyboard.key_pressed.connect(act)
	keyboard.right_key.repaired.connect(_on_key_repaired)
	bot.pressed.connect(act)
	start_attract()


func _exit_tree() -> void:
	Fonts.clear_cache()


func _process(delta: float) -> void:
	step(minf(0.033, delta))
	Audio.wanted = mode == Mode.PLAY and focused
	Audio.heat = _danger()
	Audio.level = scorekeeper.level


## Advances the game by dt_real seconds of wall time.
func step(dt_real: float) -> void:
	_hit_stop_t = maxf(0.0, _hit_stop_t - dt_real)
	Events.time_scale = HIT_STOP_SCALE if _hit_stop_t > 0.0 else 1.0
	var dt := dt_real * Events.time_scale
	keyboard.tick(dt_real)
	match mode:
		Mode.ATTRACT:
			bot.tick(dt_real)
			_advance_board(dt)
		Mode.TUTORIAL:
			tutorial.tick(dt_real)
			_advance_board(dt)
		Mode.PLAY:
			_advance_board(dt)
		Mode.DYING:
			_dying_t -= dt_real
			if _dying_t <= 0.0:
				_end_run()
		Mode.OVER:
			over_time += dt_real


func _advance_board(dt: float) -> void:
	var demo := mode != Mode.PLAY
	var speed := WaveSpawner.ATTRACT_SPEED if demo else spawner.fall_speed(scorekeeper.level)
	field.tick(dt, speed)
	shots.tick(dt, field)
	spawner.tick(dt, speed, demo, field, scorekeeper.level)
	if field.dirty:
		field.dirty = false
		field.clear_full_rows()
		if field.overflowed():
			_on_overflow()
			return
	if scorekeeper.chain and not field.is_moving() and not field.dirty:
		scorekeeper.chain = 0


## Heat for the music: how close the tallest column is to the ceiling.
func _danger() -> float:
	const BY_HEIGHT: Dictionary[int, float] = {7: 0.2, 8: 0.45, 9: 0.72, 10: 0.92}
	var peak := field.peak_height()
	return 1.0 if peak >= 11 else BY_HEIGHT.get(peak, 0.0)


# --------------------------------------------------------------------- flow

func start_game() -> void:
	_reset()
	mode = Mode.PLAY
	spawner.difficulty = settings.speed_factor()
	spawner.seed_board(field)
	spawner.countdown = 2.5
	Audio.music_reset()
	Events.log_event("Game started")


## The start menu: a fixed board played by the demo bot behind the menu card.
func start_attract() -> void:
	_reset()
	mode = Mode.ATTRACT
	stage(Scenarios.ATTRACT)
	spawner.spawn(field, scorekeeper.level, &"cluster")
	field.hold_incoming_at(7.4)
	spawner.countdown = 5.0
	bot.reset()


func start_tutorial() -> void:
	mode = Mode.TUTORIAL
	tutorial.begin()


## Clears the board and sets it up from a scenario dictionary (see scenarios.gd).
## The mode, score and HP are left alone.
func stage(board: Dictionary) -> void:
	shots.clear()
	keyboard.empty_slots()
	if board.has("durability"):
		keyboard.right_key.set_durability(board.durability, true)
	field.set_board(board.rows)
	gun.place(board.get("gun", 1))
	gun.barrel.fill(board.get("barrel", []))
	if board.has("slot"):
		keyboard.slots[0].cartridge = board.slot.duplicate()
	spawner.active = board.get("waves", true)
	spawner.countdown = board.get("next_wave", 14.0)


## Starts a lesson from scratch: fresh score, HP and keys, then its board.
func stage_lesson(board: Dictionary) -> void:
	_reset()
	stage(board)


## Enter or a tap: restart or resume, depending on the mode.
func primary_action() -> void:
	if mode == Mode.OVER and over_time > RESTART_DELAY:
		start_game()
	elif mode == Mode.PAUSED:
		toggle_pause()


## Esc: pause or resume a run, or leave the tutorial or game-over card for the menu.
func back() -> void:
	match mode:
		Mode.PLAY, Mode.PAUSED: toggle_pause()
		Mode.TUTORIAL, Mode.OVER: start_attract()


func toggle_pause() -> void:
	if mode == Mode.PLAY:
		mode = Mode.PAUSED
		Events.log_event("Paused")
	elif mode == Mode.PAUSED:
		mode = Mode.PLAY
		Events.log_event("Resumed")


## A key action, from the player or a bot. Only acts while the board runs.
func act(id: StringName) -> void:
	if mode in [Mode.PLAY, Mode.ATTRACT, Mode.TUTORIAL]:
		actions.press(id)


## A key the tutorial plays for the player: pressed visibly and audibly.
func demo_press(id: StringName) -> void:
	keyboard.demo_press(id)
	act(id)


func _reset() -> void:
	scorekeeper.reset()
	reason = &""
	field.clear()
	shots.clear()
	gun.place(1)
	gun.barrel.clear()
	keyboard.reset()
	spawner.active = true
	spawner.difficulty = 1.0
	spawner.countdown = 0.0
	_hit_stop_t = 0.0
	Events.reset.emit()


func _die(why: StringName) -> void:
	reason = why
	mode = Mode.DYING
	_dying_t = DYING_TIME


func _end_run() -> void:
	mode = Mode.OVER
	over_time = 0.0
	scorekeeper.record_best()
	Events.sound(&"over")


# ------------------------------------------------------------------- events

func _on_overflow() -> void:
	match mode:
		Mode.ATTRACT:
			start_attract()
		Mode.TUTORIAL:
			spawner.active = false
			Events.hurt.emit()
			Events.sound(&"hit")
			tutorial.lesson_ended()
		Mode.PLAY:
			_die(&"stack")
			Events.shake.emit(1.0)
			Events.hurt.emit()
			Events.sound(&"hit")
			Events.log_event("A column hit the ceiling")


func _on_died() -> void:
	if mode == Mode.PLAY:
		_die(&"hp")


func _on_key_repaired(before: int) -> void:
	if before == RightKey.MAX_DURABILITY:
		var k := keyboard.right_key.rect
		scorekeeper.on_spare_wasted(Vector2(k.position.x + Lay.KW / 2, k.position.y - 8))
