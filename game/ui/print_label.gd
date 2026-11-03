@tool
class_name PrintLabel
extends Label
## Text printed on the instrument. Placed by its baseline point and alignment,
## like canvas text in the web build, so the original coordinates carry over.
## Move it with `baseline`, not by dragging: position is derived from it.

const Fonts := preload("res://game/art/fonts.gd")
const Pal := preload("res://game/palette.gd")
const BOX_W := 600.0

enum Family { DISPLAY, LABEL, LABEL_SEMI, MONO, MONO_MED }

const FAMILIES: Array[StringName] = [&"display", &"label", &"label_semi", &"mono", &"mono_med"]

@export var family := Family.LABEL:
	set(v):
		family = v
		_refresh()
@export var font_px := 12.0:
	set(v):
		font_px = v
		_refresh()
## A colour name from palette.gd, such as INK or STEEL_LO.
@export var ink: StringName = &"INK":
	set(v):
		ink = v
		_refresh()
@export_range(0.0, 1.0) var alpha := 1.0:
	set(v):
		alpha = v
		_refresh()
@export var spacing := 0.0:
	set(v):
		spacing = v
		_refresh()
## Where the text's baseline starts (left), centres (center) or ends (right).
@export var baseline := Vector2.ZERO:
	set(v):
		baseline = v
		_refresh()
@export var align := HORIZONTAL_ALIGNMENT_LEFT:
	set(v):
		align = v
		_refresh()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh()


func _refresh() -> void:
	var f := Fonts.font(FAMILIES[family], roundi(spacing))
	var px := maxi(1, roundi(font_px))
	add_theme_font_override(&"font", f)
	add_theme_font_size_override(&"font_size", px)
	add_theme_color_override(&"font_color", Color(ink_color(ink), alpha))
	horizontal_alignment = align
	vertical_alignment = VERTICAL_ALIGNMENT_TOP
	size = Vector2(BOX_W, f.get_height(px))
	var shift := 0.0
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		shift = -BOX_W / 2
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		shift = -BOX_W
	position = baseline + Vector2(shift, -f.get_ascent(px)).rotated(rotation)


## Looks up a palette colour by its constant name. Unknown names show magenta.
static func ink_color(token: StringName) -> Color:
	var map := (Pal as Script).get_script_constant_map()
	return map.get(token, Color.MAGENTA)
