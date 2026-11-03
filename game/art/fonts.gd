extends RefCounted
## The instrument's typefaces, and baseline-anchored text for custom drawing.
## Families: &"display" (Doto 900), &"label" (Barlow 700), &"label_semi" (Barlow 600),
## &"mono" (Plex 700), &"mono_med" (Plex 500). Spacing is letter spacing in px.

enum Align { LEFT, CENTER, RIGHT }

const DOTO := preload("res://assets/fonts/Doto.ttf")
const BARLOW_BOLD := preload("res://assets/fonts/BarlowSemiCondensed-Bold.ttf")
const BARLOW_SEMI := preload("res://assets/fonts/BarlowSemiCondensed-SemiBold.ttf")
const PLEX_BOLD := preload("res://assets/fonts/IBMPlexMono-Bold.ttf")
const PLEX_MEDIUM := preload("res://assets/fonts/IBMPlexMono-Medium.ttf")

static var _cache: Dictionary[String, FontVariation] = {}


static func clear_cache() -> void:
	_cache.clear()


static func font(family: StringName, spacing := 0) -> Font:
	var key := "%s|%d" % [family, spacing]
	if _cache.has(key):
		return _cache[key]
	var fv := FontVariation.new()
	match family:
		&"display":
			fv.base_font = DOTO
			fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 900}
		&"label": fv.base_font = BARLOW_BOLD
		&"label_semi": fv.base_font = BARLOW_SEMI
		&"mono": fv.base_font = PLEX_BOLD
		_: fv.base_font = PLEX_MEDIUM
	fv.spacing_glyph = spacing
	_cache[key] = fv
	return fv


static func text_width(s: String, family: StringName, size: float, spacing := 0.0) -> float:
	return font(family, roundi(spacing)).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(1, roundi(size))).x


## Draws s with its baseline at y, like the canvas 'alphabetic' baseline.
static func text(ci: CanvasItem, s: String, x: float, y: float, family: StringName, size: float, color: Color, align := Align.LEFT, spacing := 0.0) -> void:
	var f := font(family, roundi(spacing))
	var px := maxi(1, roundi(size))
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	if align == Align.CENTER:
		x -= w / 2
	elif align == Align.RIGHT:
		x -= w
	ci.draw_string(f, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)


## Largest size up to `size` at which s fits in max_w.
static func fit_size(s: String, max_w: float, size: float, family: StringName) -> float:
	var w := text_width(s, family, size)
	return size * max_w / w if w > max_w else size
