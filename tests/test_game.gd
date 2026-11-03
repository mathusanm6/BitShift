extends Node
## Headless rule checks, mirroring the web build's test bench boards.
## Each check runs on a fresh copy of main.tscn, stepped by hand at 60 Hz.
## Run: godot --headless res://tests/test_game.tscn

const Main := preload("res://main/main.tscn")
const STEP := 1.0 / 60

var _failed := 0


func _ready() -> void:
	for check: Callable in [_row_explosion, _locked_bits, _stacked_shots, _broken_key_dash,
			_wall_wrap, _right_key_wear, _overflow, _spare_switch, _waves, _tutorial]:
		var game := _new_game()
		print(check.get_method().trim_prefix("_").replace("_", " "))
		check.call(game)
		game.free()
	print("FAILED %d" % _failed if _failed else "ALL PASSED")
	get_tree().quit(1 if _failed else 0)


func _new_game() -> Game:
	var game: Game = Main.instantiate()
	add_child(game)
	game.set_process(false)
	return game


func _check(label: String, got: Variant, want: Variant) -> void:
	if got == want:
		print("  ok   %s" % label)
	else:
		_failed += 1
		print("  FAIL %s: got %s, want %s" % [label, got, want])


func _run(game: Game, seconds: float) -> void:
	for i in int(seconds * 60):
		game.step(STEP)


func _tap(game: Game, keys: Array[StringName]) -> void:
	for k in keys:
		game.act(k)


func _load(game: Game, board: StringName) -> void:
	(game.get_node("TestBench") as TestBench).load_board(board)


func _row_explosion(game: Game) -> void:
	_load(game, &"row")
	_tap(game, [&"B0"])
	_check("barrel", game.gun.barrel.describe(), "___0")
	_tap(game, [&"F"])
	_run(game, 1.5)
	_check("row 0 exploded, column 3 keeps one bit", [game.field.column(0).describe(), game.field.column(3).describe()], ["", "0"])
	_check("score", game.scorekeeper.score, 10 + 300)


func _locked_bits(game: Game) -> void:
	_load(game, &"locked")
	_tap(game, [&"B1", &"B0", &"B0", &"B1", &"F"])
	_run(game, 1.0)
	var bit := game.field.column(0).lowest()
	_check("lock cracked, bit stays", [bit.locked, bit.cracked, bit.value], [false, true, 1])
	_check("unlocked columns lost a bit", [game.field.column(1).describe(), game.field.column(3).describe()], ["1", "0"])
	_tap(game, [&"S0"])
	_check("siphon pulls the next bits", game.keyboard.slots[0].describe(), "1100")


func _stacked_shots(game: Game) -> void:
	_load(game, &"stack")
	_tap(game, [&"S0"])
	_check("paste makes laser and flips", game.gun.barrel.describe(), "2**2")
	_check("dash is capped at the right wall", game.gun.column, 1)
	_tap(game, [&"F"])
	_check("laser takes 3 from column 1", game.field.column(1).describe(), "01")
	_check("flip inverts column 2", game.field.column(2).describe(), "00101")


func _broken_key_dash(game: Game) -> void:
	_load(game, &"loop")
	_tap(game, [&"R"])
	_check(">> does nothing when broken", game.gun.column, 0)
	_tap(game, [&"S0"])
	_check("siphon 4 bits", game.keyboard.slots[0].describe(), "1011")
	_tap(game, [&"S0"])
	_check("paste dashes right", game.gun.column, 1)


func _wall_wrap(game: Game) -> void:
	game.start_game()
	game.gun.place(0)
	_tap(game, [&"L"])
	_check("wraps to the right", game.gun.column, 1)
	_check("costs 1 HP", game.scorekeeper.hp, 9)


func _right_key_wear(game: Game) -> void:
	game.start_game()
	var worn: Array[int] = []
	game.keyboard.right_key.worn.connect(func(d: int) -> void: worn.append(d))
	for i in 3:
		game.gun.place(0)
		_tap(game, [&"R"])
	_check("three uses then broken", worn, [2, 1, 0])
	game.keyboard.right_key.repair()
	_check("spare repairs by 2", game.keyboard.right_key.durability, 2)


func _overflow(game: Game) -> void:
	game.start_game()
	game.field.set_board(["1", "0", "1", "0", "1", "0", "1", "0", "1", "0", "1", "0"])
	_run(game, 0.1)
	_check("dying on stack overflow", [game.mode, game.reason], [Game.Mode.DYING, &"stack"])
	_run(game, 1.0)
	_check("game over", game.mode, Game.Mode.OVER)


func _spare_switch(game: Game) -> void:
	_load(game, &"spare")
	game.keyboard.right_key.set_durability(1, true)
	_tap(game, [&"B1", &"F"])
	_run(game, 1.0)
	_check("spare refits >>", game.keyboard.right_key.durability, 3)


func _waves(game: Game) -> void:
	var spawner := game.spawner
	spawner.rng.seed = 7
	var ok := true
	for i in 200:
		var cells := spawner.gen_wave(spawner.pick_kind(6), 6)
		var count := 0
		for c: Variant in cells:
			if c:
				count += 1
				if c.get("spare", false) and c.get("locked", false):
					ok = false
		ok = ok and count >= 2
	_check("waves have 2+ bits and never a locked spare", ok, true)


## Plays every lesson until it ends and checks it showed its rule.
func _tutorial(game: Game) -> void:
	var tutorial := game.tutorial
	var expect: Array[Callable] = [
		func() -> Array: return [game.field.is_empty(), true],
		func() -> Array: return [[game.field.column(0).describe(), game.scorekeeper.combo], ["101", 0]],
		func() -> Array: return [game.field.is_empty(), true],
		func() -> Array: return [game.field.is_empty(), true],
		func() -> Array: return [[game.gun.column, game.scorekeeper.hp], [1, 9]],
		func() -> Array: return [game.keyboard.right_key.durability, 2],
		func() -> Array: return [game.keyboard.slots[0].describe(), "0_10"],
		func() -> Array: return [[game.gun.column, game.field.column(1).describe(), game.field.column(2).describe()], [1, "0", "0010"]],
		func() -> Array: return [game.mode, Game.Mode.TUTORIAL],
	]
	_check("one check per lesson", expect.size(), tutorial.count())
	game.start_tutorial()
	for i in tutorial.count():
		tutorial.show_lesson(i)
		var t := 0.0
		while not tutorial.ended and t < 20.0:
			game.step(STEP)
			t += STEP
		_run(game, 1.0)
		var result: Array = expect[i].call()
		_check("lesson %d: %s" % [i + 1, tutorial.lesson().title.to_lower()], result[0], result[1])
