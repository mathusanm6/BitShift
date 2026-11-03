extends RefCounted
## The tutorial, one rule per lesson. Each lesson is a scenario (see
## scenarios.gd) plus a title, the rule in one or two sentences, and the
## steps the bot plays: key ids, or a number of seconds to wait.
## low = true puts the lesson card at the bottom of the glass.

const ALL: Array[Dictionary] = [
	{
		title = "LOAD AND FIRE",
		text = "0 and 1 load a bit into the right chamber; the others shift left. FIRE shoots all four chambers up. A shot that matches its column's lowest bit shatters it.",
		rows = ["0110_", "1001_"], gun = 0, waves = false,
		steps = [&"B0", &"B1", &"B1", &"B0", &"F", 1.0, &"B1", &"B0", &"B0", &"B1", &"F"],
	},
	{
		title = "MISFIRE",
		text = "A shot that doesn't match sticks under its column: the stack grows by one and your combo drops to zero.",
		rows = ["0110_", "1011_"], gun = 0, waves = false,
		steps = [&"B1", &"B1", &"B1", &"B1", &"F"],
	},
	{
		title = "LOCKED BITS",
		text = "Steel brackets lock a bit. The first matching shot breaks the lock; a second one shatters the bit.",
		rows = ["[1][0]01_"], gun = 0, waves = false,
		steps = [&"B1", &"B0", &"B0", &"B1", &"F", 1.0, &"B1", &"B0", &"B0", &"B1", &"F"],
	},
	{
		title = "ROW EXPLOSION",
		text = "A full row of settled 1s, or of 0s, explodes for 300 points per level. Rows that explode in a cascade multiply as a chain.",
		rows = ["11101", "___1_"], gun = 0, waves = false,
		steps = [&"B0", &"F"],
	},
	{
		title = "SLIDE AND WRAP",
		text = "<< and >> slide the gun one column. Sliding << past the left wall wraps it to the right side and costs 1 HP.",
		rows = ["01100", "1___1"], gun = 1, waves = false,
		steps = [&"L", 0.6, &"L"],
	},
	{
		title = "THE >> KEY WEARS OUT",
		text = ">> has 3 uses, then its cap breaks off. Shoot a bit with a green + badge: its spare switch flies in and restores 2 uses.",
		rows = ["___1*_", "___0_"], gun = 0, waves = false,
		steps = [&"R", &"L", &"R", &"L", &"R", 1.2, &"L", &"B1", &"F"],
	},
	{
		title = "SIPHON",
		text = "An empty slot (Q, W, E) siphons the lowest bit of each column above the gun. Locked bits stay put. It counts as destroying them.",
		rows = ["0[1]10_", "1001_"], gun = 0, waves = false,
		steps = [0.6, &"S0"],
	},
	{
		title = "PASTE AND DASH",
		text = "A loaded slot pastes into the barrel, then dashes the gun 3 columns right. A matching bit becomes a laser (pierces 3 bits), a different one a flipper (inverts the column).",
		rows = ["10101", "01101", "11010", "00110"], gun = 0, waves = false,
		barrel = [1, 1, 0, 0], slot = [1, 0, 1, 0],
		steps = [0.8, &"S0", 0.9, &"F"],
	},
	{
		title = "THE CEILING",
		text = "Waves keep falling, faster every 24 bits destroyed. When a stack settles above the top row, the run is over.",
		rows = ["01010", "10101", "01010", "10101", "01010", "10101", "01010", "10101", "01010", "10_01", "_1_0_"],
		gun = 0, waves = true, next_wave = 0.8, low = true,
		steps = [],
	},
]
