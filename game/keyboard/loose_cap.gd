class_name LooseCap
extends RigidBody2D
## The >> cap after it breaks off: a rigid body that pops up, spins, bounces
## off the case walls and drops out of sight. Origin: the cap's centre.

const Lay := preload("res://game/layout.gd")
const Pal := preload("res://game/palette.gd")
const KeyArt := preload("res://game/art/key_art.gd")
const GRAVITY := 2100.0
const TICK_BOUNCES := 3

var _legend := ""
var _caption := ""
var _hint := ""
var _bounces := 0
var _floor_y := 0.0
var _floored := false


## Call right after adding to the tree. at is a global position.
func launch(at: Vector2, angle: float, legend: String, caption: String, hint: String) -> void:
	global_position = at
	rotation = angle
	_legend = legend
	_caption = caption
	_hint = hint
	linear_velocity = Vector2(randf_range(150, 280), randf_range(-760, -620))
	angular_velocity = randf_range(7, 11)
	queue_redraw()


func _ready() -> void:
	gravity_scale = GRAVITY / float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	_floor_y = at_board_bottom() + 90
	body_entered.connect(_on_wall_hit)


## The global y of the bottom of the case.
func at_board_bottom() -> float:
	return (get_parent() as Node2D).to_global(Vector2(0, Lay.H)).y


func _on_wall_hit(_body: Node) -> void:
	_bounces += 1
	if _bounces <= TICK_BOUNCES:
		Events.sound(&"tick", minf(1.0, absf(linear_velocity.x) / 300.0))


func _physics_process(_delta: float) -> void:
	if not _floored and global_position.y > _floor_y:
		_floored = true
		Events.sound(&"floor")
	if global_position.y > _floor_y + 310:
		queue_free()


func _draw() -> void:
	var r := Rect2(-Vector2(Lay.KW, Lay.MAIN_H) / 2, Vector2(Lay.KW, Lay.MAIN_H))
	var pal: Array = Pal.CAPS[&"graphite"]
	KeyArt.legend_face(self, KeyArt.cap(self, r, 0, pal), _legend, _caption, _hint, pal[3])
