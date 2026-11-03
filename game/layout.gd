class_name BitShiftLayout
extends RefCounted
## Logical layout of the BS-5 instrument, in the 560x960 design space.

const W := 560.0
const H := 960.0
const N := 5
const ROWS := 11
const CHAMBERS := 4
const GUN_MAX := N - CHAMBERS
const DASH := 3

const GX := 68.0
const CW := 96.0
const TW := CW - 4.0
const GLASS := Rect2(12, 64, 540, 536)
const TOP := 90.0
const ROW_H := 38.0
const FLOOR := 508.0
const GUN_Y := 520.0
const CHAMBER_Y := 527.0
const CHAMBER_H := 52.0
const RAIL_Y := 590.0
const HP_X := 18.0
const HP_W := 42.0
const HP_PIP := 20.0
const HP_GAP := 3.0
const HP_BOTTOM := 592.0
const CLIP_Y := 620.0
const CLIP_H := 78.0
const MAIN_Y := 724.0
const MAIN_H := 112.0
const FIRE_Y := 846.0
const FIRE_H := 84.0
const KW := 126.5

const KEY_ORDER: Array[StringName] = [&"L", &"B0", &"B1", &"R", &"F", &"S0", &"S1", &"S2"]
const SLOT_KEYS: Array[StringName] = [&"S0", &"S1", &"S2"]


static func col_x(i: float) -> float:
	return GX + i * CW


static func row_px(y: float) -> float:
	return FLOOR - (y + 1.0) * ROW_H


static func kx(i: int) -> float:
	return 12.0 + i * (KW + 10.0)


static func key_rect(key: StringName) -> Rect2:
	match key:
		&"L": return Rect2(kx(0), MAIN_Y, KW, MAIN_H)
		&"B0": return Rect2(kx(1), MAIN_Y, KW, MAIN_H)
		&"B1": return Rect2(kx(2), MAIN_Y, KW, MAIN_H)
		&"R": return Rect2(kx(3), MAIN_Y, KW, MAIN_H)
		&"F": return Rect2(12, FIRE_Y, 536, FIRE_H)
		&"S0": return Rect2(12, CLIP_Y, 172, CLIP_H)
		&"S1": return Rect2(194, CLIP_Y, 172, CLIP_H)
		&"S2": return Rect2(376, CLIP_Y, 172, CLIP_H)
	return Rect2()


static func slot_of(key: StringName) -> int:
	return SLOT_KEYS.find(key)
