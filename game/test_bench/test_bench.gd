class_name TestBench
extends Node
## The test bench, in the Inspector. Select this node (in the Remote tree
## while the game runs) to tune speed and recharge, load a test board or
## refit the >> key. Setting a board before running boots straight into it.
## Player options (volumes, shake, start speed) live on the Settings node.

const Scenarios := preload("res://game/test_bench/scenarios.gd")

enum TestBoard { NONE, ROW_EXPLOSION, BROKEN_KEY_DASH, STACKED_SHOTS, SPARE_SWITCH, LOCKED_BITS }
enum KeyRefit { NONE, REFIT_3_USES, WORN_1_USE_LEFT }

const BOARD_IDS: Dictionary[TestBoard, StringName] = {
	TestBoard.ROW_EXPLOSION: &"row",
	TestBoard.BROKEN_KEY_DASH: &"loop",
	TestBoard.STACKED_SHOTS: &"stack",
	TestBoard.SPARE_SWITCH: &"spare",
	TestBoard.LOCKED_BITS: &"locked",
}

@export var game: Game

## Multiplies how fast waves fall and arrive. 0 holds the board still.
@export_range(0.0, 2.0, 0.25, "suffix:x") var enemy_speed := 1.0:
	set(v):
		enemy_speed = v
		if is_node_ready():
			game.spawner.speed_scale = v
## Seconds a slot stays locked after it is pasted. 0 turns recharge off.
@export_range(0.0, 10.0, 1.0, "suffix:s") var slot_recharge := 0.0:
	set(v):
		slot_recharge = v
		if is_node_ready():
			game.actions.recharge = v
## Pick a board to load it (starts a game if needed).
@export var test_board := TestBoard.NONE:
	set(v):
		test_board = v
		if v != TestBoard.NONE and is_node_ready():
			_apply_board.call_deferred()
## Sets the >> key's durability. Refit gives 3 uses; Worn leaves 1.
@export var key_refit := KeyRefit.NONE:
	set(v):
		key_refit = v
		if v != KeyRefit.NONE and is_node_ready():
			_apply_refit.call_deferred()
## Prints the event log to the Output panel.
@export var log_events := true:
	set(v):
		log_events = v
		Events.log_enabled = v


func _ready() -> void:
	# Game is ready after its children: apply once the whole tree is up.
	_apply_all.call_deferred()


func _apply_all() -> void:
	enemy_speed = enemy_speed
	slot_recharge = slot_recharge
	log_events = log_events
	_apply_board()
	_apply_refit()


## Loads a fixed board from scenarios.gd into a running game.
func load_board(id: StringName) -> void:
	var board: Dictionary = Scenarios.BOARDS[id]
	if game.mode != Game.Mode.PLAY:
		game.start_game()
	game.stage(board)
	Events.log_event(board.hint)


func _apply_board() -> void:
	if test_board == TestBoard.NONE:
		return
	load_board(BOARD_IDS[test_board])
	test_board = TestBoard.NONE


func _apply_refit() -> void:
	if key_refit == KeyRefit.NONE:
		return
	if game.mode != Game.Mode.PLAY:
		game.start_game()
	game.keyboard.right_key.set_durability(3 if key_refit == KeyRefit.REFIT_3_USES else 1)
	key_refit = KeyRefit.NONE
