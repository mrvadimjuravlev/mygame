@tool
extends Node2D
## Фонарь под потолком и глаз на стене под ним. Свет фонаря — конус до пола.
## Герой в свете и глаз его видит — глаз загорается и сжигает героя.
## Палец игрока на герое прячет его: в тени руки глаз героя не видит.
## Начало координат — крюк на потолке.

## Длина цепи до фонаря.
@export var chain := 40.0:
	set(value):
		chain = value
		queue_redraw()
## Где пол: туда доходит свет.
@export var floor_y := 280.0:
	set(value):
		floor_y = value
		queue_redraw()
## Половина ширины пятна света на полу.
@export var half_width := 90.0:
	set(value):
		half_width = value
		queue_redraw()
## Где нарисован глаз (от крюка).
@export var eye := Vector2(0, 110):
	set(value):
		eye = value
		queue_redraw()

## Сколько секунд глаз должен видеть героя, чтобы сжечь.
const BURN_TIME := 0.25
## Насколько близко к герою должен быть палец, чтобы спрятать его.
const COVER_RADIUS := 30.0

const Art := preload("res://scripts/art.gd")

var _time := 0.0
## Сколько секунд глаз уже видит героя.
var _seen := 0.0
## Глаз смотрит на героя (0 — дремлет, 1 — горит).
var _glare := 0.0
var _hidden_at := Vector2.INF
var _burn_at := Vector2.INF


func _ready() -> void:
	z_index = 2
	if Engine.is_editor_hint():
		return
	var light := PointLight2D.new()
	light.texture = Art.light_texture()
	light.color = Color(1.0, 0.85, 0.5)
	light.texture_scale = 1.2
	light.energy = 1.2
	light.position = Vector2(0, chain + 60)
	add_child(light)


func _top() -> Vector2:
	return Vector2(0, chain + 14)


## Точка (в координатах уровня) — в конусе света.
func in_light(point: Vector2) -> bool:
	var p := to_local(point)
	var top := _top()
	if p.y < top.y or p.y > floor_y - global_position.y:
		return false
	var k := (p.y - top.y) / (floor_y - global_position.y - top.y)
	return absf(p.x) < lerpf(6.0, half_width, k)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var hero := get_tree().get_first_node_in_group("hero") as Node2D
	_hidden_at = Vector2.INF
	var sees := false
	if hero and not hero._dead:
		var body := hero.global_position + Vector2(0, -12)
		var lit := in_light(body) or in_light(hero.global_position + Vector2(5, -2)) or in_light(hero.global_position + Vector2(-5, -2)) \
				or in_light(body + Vector2(0, -10))
		if lit:
			var covered := false
			for p in get_parent().hand_points():
				if p.distance_to(body) < COVER_RADIUS:
					covered = true
			if covered:
				_hidden_at = to_local(body)
			else:
				sees = true
	if sees:
		_seen += delta
		_glare = 1.0
		if _seen >= BURN_TIME:
			_burn_at = to_local(hero.global_position)
			hero.die()
	else:
		_seen = 0.0
		_glare = move_toward(_glare, 0.0, delta * 2.0)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var top := _top()
	var floor_local := floor_y - position.y
	# Конус света до пола.
	var flicker := 0.05 * sin(_time * 9.0) + 0.03 * sin(_time * 21.0)
	draw_colored_polygon(PackedVector2Array([top + Vector2(-6, 0), top + Vector2(6, 0), Vector2(half_width, floor_local), Vector2(-half_width, floor_local)]),
			Color(1.0, 0.85, 0.45, 0.16 + flicker + 0.12 * _glare))
	draw_colored_polygon(PackedVector2Array([top + Vector2(-3, 0), top + Vector2(3, 0), Vector2(half_width * 0.55, floor_local), Vector2(-half_width * 0.55, floor_local)]),
			Color(1.0, 0.9, 0.6, 0.08 + flicker))
	draw_rect(Rect2(-half_width, floor_local - 2, half_width * 2, 2), Color(1.0, 0.9, 0.55, 0.35))
	# Цепь и фонарь.
	var y := 0.0
	while y < chain:
		draw_rect(Rect2(-1, y, 2, 4), Color("3c3a38"))
		y += 6.0
	draw_rect(Rect2(-7, chain, 14, 3), Color("2e2a26"))
	draw_rect(Rect2(-6, chain + 3, 12, 10), Color("ffd86a"))
	draw_rect(Rect2(-3, chain + 4, 6, 8), Color("fff6c8"))
	draw_rect(Rect2(-6, chain + 3, 1, 10), Color("2e2a26"))
	draw_rect(Rect2(5, chain + 3, 1, 10), Color("2e2a26"))
	draw_rect(Rect2(-1, chain + 3, 2, 10), Color("2e2a26"))
	draw_rect(Rect2(-8, chain + 13, 16, 2), Color("2e2a26"))
	_draw_eye()
	# Тень руки над спрятанным героем.
	if _hidden_at != Vector2.INF:
		draw_circle(_hidden_at, 22.0, Color(0.02, 0.02, 0.05, 0.55))
		draw_circle(_hidden_at, 15.0, Color(0.02, 0.02, 0.05, 0.35))
	if _burn_at != Vector2.INF:
		# Герой сгорает: язычки пламени.
		for k in 5:
			var x := -8.0 + k * 4.0
			var h := 10.0 + 8.0 * absf(sin(_time * 14.0 + k))
			draw_colored_polygon(PackedVector2Array([_burn_at + Vector2(x - 3, 0), _burn_at + Vector2(x + 3, 0), _burn_at + Vector2(x, -h - 14)]), Color(1.0, 0.55 + 0.1 * k, 0.15, 0.9))


## Глаз, нарисованный на стене: веки, радужка следит за героем, горит, когда видит.
func _draw_eye() -> void:
	var c := eye
	var paint := Color("c9a35b")
	var open := 0.45 + 0.55 * _glare
	var w := 22.0
	var h := 9.0 * open
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for k in 13:
		var t := -1.0 + k / 6.0
		upper.append(c + Vector2(t * w, -h * (1.0 - t * t)))
		lower.append(c + Vector2(t * w, h * 0.8 * (1.0 - t * t)))
	var white := upper.duplicate()
	for k in range(lower.size() - 1, -1, -1):
		white.append(lower[k])
	draw_colored_polygon(white, Color(0.9, 0.85, 0.7, 0.25 + 0.5 * _glare))
	draw_polyline(upper, paint, 2.0)
	draw_polyline(lower, paint, 2.0)
	# Зрачок смотрит в сторону героя.
	var look := 0.0
	var hero := get_tree().get_first_node_in_group("hero") as Node2D if not Engine.is_editor_hint() else null
	if hero:
		look = clampf((to_local(hero.global_position).x - c.x) / 120.0, -1.0, 1.0) * 8.0
	var pupil := c + Vector2(look, 0)
	var glow := Color(1.0, 0.3 + 0.3 * (1.0 - _glare), 0.1, 0.6 + 0.4 * _glare)
	if _glare > 0.05:
		draw_circle(pupil, 10.0 + 4.0 * sin(_time * 20.0), Color(1.0, 0.4, 0.1, 0.25 * _glare))
	draw_circle(pupil, 5.0 * open + 1.0, glow if _glare > 0.05 else Color("6b5a3a"))
	draw_circle(pupil, 2.0, Color("1a120a"))
	# Египетский хвост-завиток под глазом.
	draw_line(c + Vector2(-4, h * 0.8), c + Vector2(-6, 14), paint, 2.0)
	draw_arc(c + Vector2(-10, 14), 4.0, 0.0, PI, 8, paint, 2.0)
	draw_line(c + Vector2(w, 0), c + Vector2(w + 8, 2), paint, 2.0)
	draw_line(c + Vector2(-w + 4, -h - 4), c + Vector2(w - 4, -h - 6), paint, 2.0)
