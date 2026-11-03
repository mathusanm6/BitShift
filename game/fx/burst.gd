extends Node2D
## A burst of particles: sparks (streaks) or shards (spinning triangles), under
## gravity, slowed by hit-stop. Frees itself when the last one dies.

## Particles alive across every burst, capped to keep big chains cheap.
const MAX_LIVE := 600

static var live := 0

var _parts: Array[Dictionary] = []


func scatter(pos: Vector2, count: int, color: Color, speed: float, spark: bool) -> Node2D:
	for i in count:
		var a := randf() * TAU
		var s := randf_range(speed * 0.25, speed)
		_add(pos, Vector2(cos(a), sin(a)) * s + Vector2(0, -70), 900.0 if spark else 760.0,
			randf_range(0.22, 0.6), randf_range(1.5, 4), color, spark, randf_range(-14, 14))
	return self


## Chunks of a shattered bit tile, thrown upward from its centre.
func shards(center: Vector2, color: Color) -> Node2D:
	for i in 11:
		var a := randf_range(-PI, 0)
		var s := randf_range(70, 300)
		var at := center + Vector2(randf_range(-30, 30), randf_range(-10, 10))
		_add(at, Vector2(cos(a), sin(a)) * s, 960.0, randf_range(0.35, 0.8), randf_range(3, 8), color, false, randf_range(-16, 16))
	return self


func _add(pos: Vector2, vel: Vector2, gravity: float, life: float, size: float, color: Color, spark: bool, spin: float) -> void:
	if live >= MAX_LIVE:
		return
	live += 1
	_parts.append({pos = pos, vel = vel, g = gravity, age = 0.0, life = life, size = size, color = color, spark = spark, rot = randf() * 6, spin = spin})


func _process(delta: float) -> void:
	var dt := minf(0.033, delta) * Events.time_scale
	for i in range(_parts.size() - 1, -1, -1):
		var p := _parts[i]
		var vel: Vector2 = p.vel + Vector2(0, p.g * dt)
		p.vel = vel
		p.pos += vel * dt
		p.age += dt
		p.rot += p.spin * dt
		if p.age >= p.life:
			_parts.remove_at(i)
			live -= 1
	if _parts.is_empty():
		queue_free()
	queue_redraw()


func _exit_tree() -> void:
	live -= _parts.size()
	_parts.clear()


func _draw() -> void:
	for p in _parts:
		var color := Color(p.color, 1.0 - p.age / p.life)
		var pos: Vector2 = p.pos
		if p.spark:
			draw_line(pos, pos - p.vel * 0.025, color, 1.6, true)
		else:
			var s: float = p.size
			var pts := PackedVector2Array([Vector2(-s, -s * 0.7), Vector2(s, -s * 0.3), Vector2(-s * 0.2, s)])
			for i in 3:
				pts[i] = pos + pts[i].rotated(p.rot)
			draw_colored_polygon(pts, color)
