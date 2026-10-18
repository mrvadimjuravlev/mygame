@tool
extends StaticBody2D
## Решётка, которая опускается по времени зала (time_glass): открыта до close_from,
## к close_at закрыта. Перемотка назад поднимает её. Придавит героя — гибель.
## Начало координат — середина низа решётки, когда она закрыта.

@export var size := Vector2(14, 220):
	set(value):
		size = value
		queue_redraw()
@export var close_from := 1.0
@export var close_at := 2.0

var _drop := 0.0
var _shape: CollisionShape2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("timed")
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	add_child(_shape)
	set_time(0.0)


func set_time(t: float) -> void:
	_drop = clampf((t - close_from) / (close_at - close_from), 0.0, 1.0)
	var lift := (1.0 - _drop) * (size.y - 6.0)
	_shape.position = Vector2(0, -size.y / 2 - lift)
	# Опускается на героя — давит.
	var hero := get_tree().get_first_node_in_group("hero") as Node2D
	if hero and _drop > 0.0 and absf(hero.global_position.x - global_position.x) < size.x / 2 + 5.0 \
			and hero.global_position.y - 24.0 < global_position.y - lift and hero.global_position.y > global_position.y - lift - size.y:
		hero.die()
	queue_redraw()


func _draw() -> void:
	var lift := (1.0 - _drop) * (size.y - 6.0)
	# Поднятая часть уходит в щель потолка: рисуем только то, что ниже него.
	var top := -size.y
	var h := size.y - lift
	var x := -size.x / 2
	while x < size.x / 2:
		draw_rect(Rect2(x, top, 3, h), Color("5e5a52"))
		draw_rect(Rect2(x, top, 1, h), Color("8a857a"))
		x += 5.0
	var y := top + 30.0 - fmod(lift, 30.0)
	while y < -lift:
		draw_rect(Rect2(-size.x / 2, y, size.x, 2), Color("4a4640"))
		y += 30.0
	# Зубья снизу.
	x = -size.x / 2
	while x < size.x / 2:
		draw_colored_polygon(PackedVector2Array([Vector2(x, -lift), Vector2(x + 3, -lift), Vector2(x + 1.5, -lift + 5)]), Color("8a857a"))
		x += 5.0
