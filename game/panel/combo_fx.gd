extends Node2D
## Visual feedback around the COMBO readout in the top window: active streak
## meter, hit glow, and a falling red ghost when a combo is lost.

const Pal := preload("res://game/palette.gd")
const Shapes := preload("res://game/art/shapes.gd")
const Fonts := preload("res://game/art/fonts.gd")

const SLOT_RECT := Rect2(315, 16, 86, 40)
const BAR_X := 320.0
const BAR_Y := 53.5
const BAR_W := 74.0
const LOST_DURATION := 0.45

var combo := 0

var _hit_flash := 0.0
var _lost_flash := 0.0
var _lost_text := ""
var _lost_t := 0.0


func _ready() -> void:
	Events.combo_hit.connect(_on_combo_hit)
	Events.combo_lost.connect(_on_combo_lost)
	Events.reset.connect(_on_reset)


func _on_combo_hit(new_combo: int, _col: int) -> void:
	combo = new_combo
	_hit_flash = 1.0
	_lost_flash = 0.0


func _on_combo_lost(prev_combo: int, _col: int) -> void:
	combo = 0
	_hit_flash = 0.0
	_lost_flash = 1.0
	if prev_combo >= 2:
		_lost_text = "x%d" % prev_combo
		_lost_t = LOST_DURATION


func _on_reset() -> void:
	combo = 0
	_hit_flash = 0.0
	_lost_flash = 0.0
	_lost_text = ""
	_lost_t = 0.0


func _process(delta: float) -> void:
	var dt := minf(0.033, delta)
	_hit_flash = maxf(0.0, _hit_flash - dt * 3.4)
	_lost_flash = maxf(0.0, _lost_flash - dt * 2.4)
	if _lost_t > 0.0:
		_lost_t = maxf(0.0, _lost_t - dt)
	if combo >= 2 or _hit_flash > 0.01 or _lost_flash > 0.01 or _lost_t > 0.0:
		queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() * 0.001
	if _lost_flash > 0.01:
		Shapes.fill_rr(self, SLOT_RECT, 4, Color(Pal.FAULT, _lost_flash * 0.24))
		Shapes.stroke_rr(self, SLOT_RECT, 4, Color(Pal.FAULT, _lost_flash * 0.75), 1.5)
	if _lost_t > 0.0 and not _lost_text.is_empty():
		var q := 1.0 - _lost_t / LOST_DURATION
		var y_off := q * 18.0
		var x_off := sin(q * 28.0) * (1.0 - q) * 3.0
		Fonts.text(self, _lost_text, 320.0 + x_off, 51.0 + y_off, &"display", 24, Color(Pal.FAULT, (1.0 - q) * 0.85), Fonts.Align.LEFT)
	if combo >= 2:
		var color := ComboAura.tier_color(combo)
		var pulse := 0.75 + 0.25 * sin(t * 7.0)
		var glow_a := 0.08 * pulse + _hit_flash * 0.22
		Shapes.fill_rr(self, SLOT_RECT, 4, Color(color, glow_a))
		if _hit_flash > 0.01:
			Shapes.stroke_rr(self, SLOT_RECT.grow(_hit_flash * 2.0), 4, Color(color, _hit_flash * 0.7), 1.5)
		# Active streak bar under the readout.
		Shapes.fill_rr(self, Rect2(BAR_X, BAR_Y, BAR_W, 2.5), 1.0, Pal.GHOST)
		var fill_frac := clampf(float(combo) / 10.0, 0.18, 1.0)
		var bar_color := color.lerp(Pal.WHITE, _hit_flash * 0.55)
		Shapes.fill_rr(self, Rect2(BAR_X, BAR_Y, BAR_W * fill_frac, 2.5), 1.0, Color(bar_color, clampf(0.75 * pulse + _hit_flash * 0.25, 0.0, 1.0)))
	elif _hit_flash > 0.01:
		# Subtle flash even on the first hit (x1) so the readout feels responsive.
		Shapes.fill_rr(self, SLOT_RECT, 4, Color(Pal.STEEL, _hit_flash * 0.1))
