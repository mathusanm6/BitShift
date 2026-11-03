extends Node2D
## The dotted cutting mat the instrument sits on, filling the whole window.

const Pal := preload("res://game/palette.gd")
const DOT_PITCH := 22

var _texture: ImageTexture


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_texture = make_texture()
	get_viewport().size_changed.connect(queue_redraw)


func _draw() -> void:
	draw_texture_rect(_texture, get_viewport_rect(), true)


## One tile of the mat, to draw repeated. Also used by the splash screen.
static func make_texture() -> ImageTexture:
	var img := Image.create(DOT_PITCH, DOT_PITCH, false, Image.FORMAT_RGBA8)
	img.fill(Pal.MAT)
	var last := DOT_PITCH - 1
	for p: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(last, 0), Vector2i(0, last)]:
		img.set_pixelv(p, Pal.MAT_LINE.lerp(Pal.MAT, 0.0 if p == Vector2i.ZERO else 0.6))
	return ImageTexture.create_from_image(img)
