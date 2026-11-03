class_name KeyCap
extends Node2D
## One key on the instrument. It springs down when pressed and overshoots on
## release, tilts toward where it was hit, and can flash. It only reports
## presses; the game decides what they do. Origin: the key's centre.

signal pressed(id: StringName)
signal released(id: StringName)

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const KeyArt := preload("res://game/art/key_art.gd")
const Shapes := preload("res://game/art/shapes.gd")

## L, B0, B1, R, F, S0, S1 or S2. Picks the key's place from layout.gd.
@export var id: StringName
## Cap colours from palette.gd CAPS: graphite, putty, one, zero or fire.
@export var palette: StringName = &"graphite"
@export var legend := ""
@export var caption := ""
## The corner hint: this prefix, then the label of hint_key on the player's layout.
@export var hint_prefix := ""
@export var hint_key: Key = KEY_NONE
## Pitch of the click when pressed and released.
@export var click_pitch := 0.8
@export var release_pitch := 1.0
## How much of the press tilt shows. The long FIRE bar barely rocks.
@export_range(0.0, 1.0) var tilt_scale := 1.0

var rect: Rect2
var hint := ""
var down := false
var hover := false
var flash := 0.0
## 0 at rest, 1 bottomed out. Overshoots both ways.
var travel := 0.0
var spin := 0.0

var _travel_v := 0.0
var _spin_v := 0.0


func _ready() -> void:
	rect = Lay.key_rect(id)
	position = rect.get_center()
	hint = hint_prefix + (key_label(hint_key) if hint_key != KEY_NONE else "")


func press(tilt := 0.0) -> void:
	if down:
		return
	down = true
	_travel_v += 9.0
	_spin_v += tilt * 1.2 + randf_range(-0.12, 0.12)
	pressed.emit(id)


func release() -> void:
	if not down:
		return
	down = false
	released.emit(id)


## A visible press with no input behind it, used by the attract-mode bot.
func tap() -> void:
	_travel_v += 12.0
	_spin_v += randf_range(-0.6, 0.6)


func blink() -> void:
	flash = 1.0


func hit_test(board_point: Vector2) -> bool:
	return rect.grow(2).has_point(board_point)


## True when pressing does nothing at all, so it makes no click (a broken key).
func is_dead() -> bool:
	return false


func ink() -> Color:
	return Pal.CAPS[palette][3]


## The printed label of a physical key on the player's layout (AZERTY shows Q as A).
static func key_label(physical: Key) -> String:
	if DisplayServer.get_name() == "headless":
		return OS.get_keycode_string(physical).to_upper()
	var label := DisplayServer.keyboard_get_label_from_physical(physical)
	return OS.get_keycode_string(label if label != KEY_NONE else physical).to_upper()


func _process(delta: float) -> void:
	var dt := minf(0.033, delta)
	# The fast press stops hard, the release overshoots upward.
	if down:
		_travel_v += (1500 * (1.0 - travel) - 56 * _travel_v) * dt
	else:
		_travel_v += (640 * (0.0 - travel) - 19 * _travel_v) * dt
	travel = clampf(travel + _travel_v * dt, -0.4, 1.12)
	_spin_v += (260 * (0.0 - spin) - 11 * _spin_v) * dt
	spin += _spin_v * dt
	flash = maxf(0.0, flash - dt * 2.6)
	_pose()
	queue_redraw()


func _pose() -> void:
	rotation = spin * tilt_scale


func _draw() -> void:
	var r := Rect2(-rect.size / 2, rect.size)
	_draw_face(KeyArt.cap(self, r, travel, Pal.CAPS[palette]))
	if flash > 0.01:
		Shapes.stroke_rr(self, r.grow(2), 11, Color(Pal.WHITE, flash), 3)


func _draw_face(face: Rect2) -> void:
	KeyArt.legend_face(self, face, legend, caption, hint, ink())
