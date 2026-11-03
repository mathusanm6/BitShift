extends KeyCap
## The long FIRE bar: one wide-spaced legend and its hint.

const Fonts := preload("res://game/art/fonts.gd")


func _draw_face(face: Rect2) -> void:
	var x := face.position.x
	var y := face.position.y
	Fonts.text(self, legend, x + face.size.x / 2, y + face.size.y / 2 + 12, &"mono", 36, ink(), Fonts.Align.CENTER, 10.8)
	Fonts.text(self, hint, x + face.size.x - 10, y + 16, &"mono_med", 11, ink(), Fonts.Align.RIGHT)
