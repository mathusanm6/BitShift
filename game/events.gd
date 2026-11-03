extends Node
## Autoload "Events": the cosmetic event bus. Gameplay nodes announce what
## happened (in board coordinates); the board, effects and audio react.
## Nothing listening here changes game state, so the rules run without it.

signal shake(amount: float)
signal slow_motion(seconds: float)
signal burst(pos: Vector2, count: int, color: Color, speed: float, spark: bool)
signal shatter(col: int, row: float, b: int)
signal popup(pos: Vector2, text: String, color: Color)
signal ghost(b: int, from: Vector2, to: Vector2, height: float, duration: float)
signal beam(col: int, color: Color, width: float, duration: float)
signal row_flash(row: float)
signal spare_launched(from: Vector2, duration: float)
signal clock_tick
signal hurt
signal wall_wrap
## The board was reset: drop every transient effect.
signal reset

## True in attract mode: sounds and log lines are swallowed.
var quiet := false
## Prints the event log to the Output panel (set by the test bench).
var log_enabled := true
## Hit-stop factor for the current frame. Effects multiply their dt by it.
var time_scale := 1.0


func sound(sound_name: StringName, arg := 1.0) -> void:
	if not quiet:
		Audio.play(sound_name, arg)


func log_event(text: String) -> void:
	if log_enabled and not quiet and OS.is_debug_build():
		print("[BitShift] ", text)
