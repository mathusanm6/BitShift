extends RefCounted
## Key caps: the shadowed body, the lit top face, and the standard face
## printing (big legend, caption underneath, key hint in the corner).

const Shapes := preload("res://game/art/shapes.gd")
const Fonts := preload("res://game/art/fonts.gd")


## Draws a cap in r pushed down by travel (0 up, 1 bottomed out).
## pal: [base, hi, lo, ink]. Returns the top face rect, for printing on.
static func cap(ci: CanvasItem, r: Rect2, travel: float, pal: Array) -> Rect2:
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var h := r.size.y
	var top := y + travel * 10
	Shapes.fill_rr(ci, Rect2(x + 1, y + 5, w - 2, h - 3), 10, Color(0, 0, 0, 0.34))
	Shapes.grad_rr(ci, Rect2(x, top, w, maxf(14, y + h - top)), 10, pal[0], pal[2])
	var face := Rect2(x + 6, top + 3, w - 12, h - 20)
	Shapes.grad_rr(ci, face, 8, pal[1], pal[0])
	Shapes.stroke_rr(ci, face, 8, Color(1, 1, 1, 0.22), 1)
	return face


static func legend_face(ci: CanvasItem, face: Rect2, legend: String, caption: String, hint: String, ink: Color) -> void:
	var x := face.position.x
	var y := face.position.y
	var w := face.size.x
	var h := face.size.y
	var wide := legend.length() > 1
	Fonts.text(ci, legend, x + w / 2, y + h / 2 + (8 if wide else 12), &"mono", 42 if wide else 52, ink, Fonts.Align.CENTER)
	Fonts.text(ci, caption, x + w / 2, y + h - 7, &"label", 11, ink, Fonts.Align.CENTER, 1.1)
	Fonts.text(ci, hint, x + w - 7, y + 14, &"mono_med", 11, ink, Fonts.Align.RIGHT)
