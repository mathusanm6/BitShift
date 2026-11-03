extends Node2D
## Floating score text: rises 44px and fades out.

const Fonts := preload("res://game/art/fonts.gd")
const DURATION := 0.9

var _text := ""
var _color := Color.WHITE
var _t := 0.0


func setup(pos: Vector2, text: String, color: Color) -> Node2D:
	position = pos
	_text = text
	_color = color
	return self


func _process(delta: float) -> void:
	_t += minf(0.033, delta)
	if _t >= DURATION:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var q := _t / DURATION
	Fonts.text(self, _text, 0, -q * 44, &"mono", 20, Color(_color, 1 - q * q), Fonts.Align.CENTER)
