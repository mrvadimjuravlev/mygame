@tool
extends Node2D
## Песок, медленно поднимающийся снизу: коснулся — гибель, уровень заново.
## Начало координат — левый край поверхности песка; песок уходит вниз на depth.

@export var width := 640.0:
	set(value):
		width = value
		queue_redraw()
@export var depth := 1200.0
## Скорость подъёма, пикселей в секунду, и пауза перед началом.
@export var speed := 9.0
@export var delay := 3.0
## Выше этой высоты (y в координатах родителя) песок не поднимается.
@export var stop_y := 0.0

var _time := 0.0
var _start_y := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_start_y = position.y
	z_index = 2


## Поверхность песка (y в координатах родителя) через t секунд от начала уровня.
func surface_at(t: float) -> float:
	return maxf(_start_y - maxf(t - delay, 0.0) * speed, stop_y)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	position.y = surface_at(_time)
	for hero in get_tree().get_nodes_in_group("hero"):
		if hero.global_position.y > global_position.y + 2.0:
			hero.die()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	var t := _time
	# Волнистая поверхность струится, ниже — плотный песок с полосами.
	var top := PackedVector2Array()
	var x := 0.0
	while x <= width:
		top.append(Vector2(x, sin(x * 0.07 + t * 2.0) * 1.5 + sin(x * 0.023 - t * 1.3) * 1.5))
		x += 8.0
	var poly := top.duplicate()
	poly.append(Vector2(width, depth))
	poly.append(Vector2(0, depth))
	draw_colored_polygon(poly, Color("c9a35b"))
	draw_polyline(top, Color("e2bf78"), 2.0)
	for k in range(1, 6):
		var y := k * 14.0
		draw_line(Vector2(0, y), Vector2(width, y), Color(0.55, 0.4, 0.2, 0.25), 2.0)
	# Струйки песчинок над поверхностью.
	for i in int(width / 24.0):
		var px := fposmod(i * 37.0 + t * 20.0 * (1 if i % 2 == 0 else -1), width)
		draw_rect(Rect2(px, -3.0 - fposmod(t * 6.0 + i, 4.0), 1, 1), Color("f0d79a"))
