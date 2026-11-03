class_name Actions
extends Node
## The cannon's verbs: load a bit, slide, fire, and use a clip slot. Each one
## checks the rules (wear, walls, recharge) and moves bits between the field,
## the barrel and the slots. Game decides when a press is allowed at all.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")

@export var field: Field
@export var gun: Gun
@export var shots: Shots
@export var keyboard: Keyboard
@export var scorekeeper: Scorekeeper

## Seconds a slot stays locked after a paste. 0 turns recharge off.
var recharge := 0.0


func press(id: StringName) -> void:
	match id:
		&"B0": load_bit(0)
		&"B1": load_bit(1)
		&"L": slide_left()
		&"R": slide_right()
		&"F": fire()
		_:
			var slot := Lay.slot_of(id)
			if slot >= 0:
				use_slot(slot)


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
	# Off the left edge: the gun scrapes the wall and wraps around to the right.
	Events.wall_wrap.emit()
	Events.shake.emit(0.45)
	Events.burst.emit(Vector2(Lay.GX - 2, Lay.GUN_Y + 30), 26, Pal.ONE_HI, 420.0, true)
	Events.sound(&"scrape")
	if scorekeeper.live:
		scorekeeper.damage(1)
		Events.log_event("Wrapped the left wall: HP %d" % scorekeeper.hp)


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


func use_slot(i: int) -> void:
	var slot := keyboard.slots[i]
	if slot.cooldown > 0.0:
		Events.sound(&"dead")
		Events.log_event("Slot %d is recharging" % (i + 1))
	elif slot.is_loaded():
		_paste(slot)
	else:
		_siphon(slot)


## Vacuum siphon: pulls the lowest bit from each column above the gun.
func _siphon(slot: SlotKey) -> void:
	var cartridge := []
	cartridge.resize(Lay.CHAMBERS)
	var got := 0
	var held := 0
	for n in Lay.CHAMBERS:
		var col := field.column(gun.column + n)
		var bit := col.lowest()
		if bit == null:
			continue
		if bit.locked:
			held += 1
			bit.flash = 1.0
			continue
		col.take(0)
		cartridge[n] = bit.value
		got += 1
		var to := slot.rect.position + Vector2(6 + n * 38, 8)
		Events.ghost.emit(bit.value, Vector2(Lay.col_x(col.index) + 2, Lay.row_px(bit.row) + 1), to, 36.0, 0.26)
	if got == 0:
		Events.sound(&"dead")
		Events.log_event("Locked bits cannot be siphoned" if held else "Nothing above the gun to siphon")
		return
	slot.cartridge = cartridge
	slot.blink()
	scorekeeper.count_destroyed(got)
	field.dirty = true
	Events.sound(&"siphon")
	Events.log_event("Siphoned %d bits into slot %d" % [got, Lay.slot_of(slot.id) + 1])


## Paste and recoil dash: loads the cartridge, then jumps 3 columns right
## whatever state the >> key is in.
func _paste(slot: SlotKey) -> void:
	var made := gun.barrel.paste(slot.cartridge)
	slot.cartridge = []
	slot.cooldown = recharge
	var from := gun.column
	var moved := gun.dash(Lay.DASH)
	gun.kick(300.0)
	slot.blink()
	Events.clock_tick.emit()
	Events.shake.emit(0.26)
	Events.burst.emit(Vector2(Lay.col_x(from) - 2, Lay.GUN_Y + 34), 22, Pal.ONE_HI, 380.0, true)
	Events.sound(&"recoil")
	var extra := " (%d laser, %d flip)" % [made.x, made.y] if made != Vector2i.ZERO else ""
	Events.log_event("Pasted slot %d, dashed %d right%s" % [Lay.slot_of(slot.id) + 1, moved, extra])
