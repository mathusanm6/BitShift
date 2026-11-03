class_name BitShiftPalette
extends RefCounted
## Colour tokens from the web build's :root, one constant per CSS variable.

const MAT := Color("1b2d31")
const MAT_LINE := Color("2e4449")
const CHASSIS := Color("93a6aa")
const CHASSIS_HI := Color("b1c0c3")
const CHASSIS_LO := Color("748a8f")
const INK := Color("0f1f25")
const GLASS := Color("060e11")
const GLASS_HI := Color("0e1d22")
const SOCKET := Color("0b171b")
const GHOST := Color("13262c")
const ONE := Color("ffb42e")
const ONE_HI := Color("ffd27a")
const ONE_DEEP := Color("3c2400")
const ZERO := Color("63d8ea")
const ZERO_DEEP := Color("0a3039")
const FAULT := Color("ff4f3d")
const SPARE := Color("86e28f")
const SPARE_DEEP := Color("143a1d")
const FLIP := Color("e39bff")
const FLIP_DEEP := Color("33123f")
const STEEL := Color("c3cdd0")
const STEEL_LO := Color("566469")
const WHITE := Color("f4f8f8")
const STEM := Color("d9412f")
const HOUSING := Color("14191b")
const PUTTY := Color("ddd7c7")
const PUTTY_HI := Color("f0ebdd")
const PUTTY_LO := Color("a29c8c")
const GRAPHITE := Color("3f4c52")
const GRAPHITE_HI := Color("566369")
const GRAPHITE_LO := Color("222b2f")
const CAP_ONE := Color("e9a32a")
const CAP_ONE_HI := Color("f6c35c")
const CAP_ONE_LO := Color("9d6a12")
const CAP_ZERO := Color("46a7bb")
const CAP_ZERO_HI := Color("6dc4d5")
const CAP_ZERO_LO := Color("236a7a")
const CAP_FIRE := Color("c9402f")
const CAP_FIRE_HI := Color("e4604d")
const CAP_FIRE_LO := Color("7f2318")
const PANEL_FG := Color("d8e3e4")
const PANEL_DIM := Color("94aaad")

## Key-cap palettes: base, hi, lo, ink.
const CAPS: Dictionary[StringName, Array] = {
	&"graphite": [GRAPHITE, GRAPHITE_HI, GRAPHITE_LO, PUTTY],
	&"putty": [PUTTY, PUTTY_HI, PUTTY_LO, INK],
	&"one": [CAP_ONE, CAP_ONE_HI, CAP_ONE_LO, ONE_DEEP],
	&"zero": [CAP_ZERO, CAP_ZERO_HI, CAP_ZERO_LO, ZERO_DEEP],
	&"fire": [CAP_FIRE, CAP_FIRE_HI, CAP_FIRE_LO, WHITE],
}
