class_name Actions
extends Node
## The cannon's verbs: load a bit, slide, and fire. Each one checks the rules
## (wear, walls) and moves bits between the field and the barrel. Game decides
## when a press is allowed at all.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")

@export var field: Field
@export var gun: Gun
@export var shots: Shots
@export var keyboard: Keyboard
@export var scorekeeper: Scorekeeper


func _ready() -> void:
	if gun != null:
		gun.wall_impact.connect(_on_wall_impact)


func press(id: StringName) -> void:
	match id:
		&"B0": load_bit(0)
		&"B1": load_bit(1)
		&"L": slide_left()
		&"R": slide_right()
		&"F": fire()


func load_bit(b: int) -> void:
	var dropped := gun.barrel.load_bit(b)
	if dropped >= 0:
		var x := Lay.col_x(gun.column)
		Events.ghost.emit(dropped, Vector2(x + 2, Lay.GUN_Y + 7), Vector2(x - 24, Lay.GUN_Y + 44), Lay.CHAMBER_H, 0.2)
	Events.clock_tick.emit()
	Events.sound(&"load")


func slide_left() -> void:
	Events.clock_tick.emit()
	if not gun.slide_left():
		Events.sound(&"slide")
		return
	# Off the left edge: the gun slams into the HP bar and gets pushed back right.
	if scorekeeper.live:
		scorekeeper.damage(1)
		Events.log_event("Hit the HP bar: HP %d" % scorekeeper.hp)


func _on_wall_impact() -> void:
	Events.wall_wrap.emit()
	Events.shake.emit(0.5)
	Events.burst.emit(Vector2(Lay.GX - 6, Lay.GUN_Y + 30), 26, Pal.ONE_HI, 420.0, true)
	Events.sound(&"scrape")


func slide_right() -> void:
	var right_key := keyboard.right_key
	if right_key.durability <= 0:
		Events.sound(&"dead")
		Events.log_event(">> is broken: nothing happened")
		return
	if gun.at_right_wall():
		Events.sound(&"dead")
		gun.kick(40.0)
		Events.log_event("At the right wall: >> not used")
		return
	gun.slide_right()
	Events.clock_tick.emit()
	Events.sound(&"slide")
	right_key.wear()


func fire() -> void:
	if gun.barrel.is_empty():
		Events.sound(&"dead")
		return
	var loaded := gun.barrel.take_all()
	for n in loaded.size():
		var chamber := loaded[n]
		if chamber == null:
			continue
		var col := field.column(gun.column + n)
		match chamber.value:
			Barrel.LASER: col.laser()
			Barrel.FLIP: col.flip()
			_: shots.fire(col.index, chamber.value)
	gun.kick(230.0)
	Events.shake.emit(0.1)
	Events.clock_tick.emit()
	Events.sound(&"fire")
