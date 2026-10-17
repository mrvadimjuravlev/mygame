@tool
extends AnimatableBody2D
## Движущаяся платформа (и лифт): ездит туда-обратно между начальным местом и сдвигом travel,
## на концах ждёт wait секунд. Героя везёт на себе. Начало координат — середина верхней грани.

const Art := preload("res://scripts/art.gd")

@export var size := Vector2(56, 12):
	set(value):
		size = value
		queue_redraw()
## Куда едет от начального места.
@export var travel := Vector2(200, 0)
@export var speed := 70.0
@export var wait := 0.5
## С какого места круга начинает, секунды.
@export var phase := 0.0

var _start := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_start = position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(0, size.y / 2)
	add_child(shape)
	_time = phase
	position = place_at(_time)


func move_time() -> float:
	return travel.length() / speed


func cycle() -> float:
	return (move_time() + wait) * 2.0


## Где платформа (в координатах родителя) через t секунд от начала.
func place_at(t: float) -> Vector2:
	var m := move_time()
	var u := fposmod(t, cycle())
	var s := 0.0
	if u < wait:
		s = 0.0
	elif u < wait + m:
		s = (u - wait) / m
	elif u < wait * 2.0 + m:
		s = 1.0
	else:
		s = 1.0 - (u - wait * 2.0 - m) / m
	return _start + travel * smoothstep(0.0, 1.0, s)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	position = place_at(_time)


func _draw() -> void:
	Art.draw_slab(self, Rect2(Vector2(-size.x / 2, 0), size))
	# Бронзовые накладки по краям: платформа механическая.
	for x in [-size.x / 2 + 2, size.x / 2 - 6]:
		draw_rect(Rect2(x, 3, 4, size.y - 6), Color("8a6a30"))
		draw_rect(Rect2(x, 3, 4, 1), Color("c9a35b"))
