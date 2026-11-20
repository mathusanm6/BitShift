extends RefCounted
## Fixed boards: the attract demo and the test bench's test boards.
## rows use the board_text.gd format, bottom row first. Optional keys:
## gun (its column, default 1), barrel (4 entries of 0, 1 or null),
## durability (the >> key's uses),
## waves (false holds new waves back), next_wave (seconds until one),
## hint (logged when loaded). Game.stage() applies them.

const ATTRACT := {
	rows = ["10[1]01", "0[1]010", "1_011", "__1_0"],
	barrel = [null, null, 1, 0],
	durability = 2,
}

const BOARDS := {
	&"row": {
		rows = ["11101", "___1_", "___0_"],
		gun = 0,
		hint = "Row test: press 0, then FIRE at column 3",
	},
	&"spare": {
		rows = ["___1*_", "___0_"],
		gun = 0,
		hint = "Spare test: press 1, then FIRE at column 3",
	},
	&"locked": {
		rows = ["[1]0[0]1_", "0110_"],
		gun = 0,
		hint = "Locked test: load 1 0 0 1, FIRE, load it again, FIRE",
	},
}
