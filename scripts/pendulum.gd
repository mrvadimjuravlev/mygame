@tool
extends AnimatableBody2D
## Маятник: платформа на цепи качается под осью и везёт героя на себе. Сама платформа не наклоняется.
## Начало координат — середина верхней грани платформы в нижней точке качания.

const Art := preload("res://scripts/art.gd")

@export var size := Vector2(56, 10):
	set(value):
		size = value
		queue_redraw()
## Ось маятника относительно нижней точки платформы (вверх — отрицательный y).
@export var pivot := Vector2(0, -230)
## Наибольший угол отклонения, радианы.
@export var amplitude := 0.6
## Полный размах туда и обратно, секунды.
@export var period := 3.2
## Сдвиг по кругу, секунды.
@export var phase := 0.0

var _pivot := Vector2.ZERO
var _length := 0.0
var _time := 0.0
var _rope: Node2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_pivot = position + pivot
	_length = pivot.length()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(0, size.y / 2)
	add_child(shape)
	_rope = Node2D.new()
	_rope.top_level = true
	_rope.show_behind_parent = true
	_rope.draw.connect(_draw_rope)
	add_child(_rope)
	_time = phase
	position = place_at(_time)


func angle_at(t: float) -> float:
	return amplitude * sin(TAU * t / period)


## Где платформа (в координатах родителя) через t секунд от начала.
func place_at(t: float) -> Vector2:
	var a := angle_at(t)
	return _pivot + Vector2(sin(a), cos(a)) * _length


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	position = place_at(_time)
	_rope.queue_redraw()


func _draw_rope() -> void:
	var parent := get_parent() as Node2D
	var top: Vector2 = parent.to_global(_pivot) if parent else _pivot
	var bottom := global_position
	# Цепь от оси к середине платформы, две короткие оттяжки к её краям.
	var d := bottom - top
	var n := int(d.length() / 5.0)
	for k in n:
		var p := top + d * (float(k) / n)
		if k % 2 == 0:
			_rope.draw_circle(p, 1.6, Color("6b6156"))
		else:
			_rope.draw_line(p, top + d * (float(k + 1) / n), Color("4a4642"), 1.0)
	var hook := bottom + Vector2(0, -10)
	_rope.draw_line(hook, bottom + Vector2(-size.x / 2 + 3, 0), Color("4a4642"), 1.0)
	_rope.draw_line(hook, bottom + Vector2(size.x / 2 - 3, 0), Color("4a4642"), 1.0)
	_rope.draw_circle(top, 4.0, Color("8a6a30"))
	_rope.draw_circle(top, 2.0, Color("3b2a1c"))


func _draw() -> void:
	Art.draw_slab(self, Rect2(Vector2(-size.x / 2, 0), size))
