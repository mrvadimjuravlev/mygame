extends Node2D
## Рисование мелом: когда у героя есть мел, палец рисует на экране белые линии,
## и каждая линия становится платформой (на неё можно запрыгнуть снизу сквозь неё).
## Линий не больше max_strokes: новая стирает самую старую. Длина линии ограничена max_length.

@export var max_strokes := 4
@export var max_length := 140.0

## Нарисованные линии: массивы точек в координатах уровня.
var strokes: Array[PackedVector2Array] = []
var _bodies: Array[StaticBody2D] = []
var _current := PackedVector2Array()
var _length := 0.0
var _point := Vector2.ZERO


func _ready() -> void:
	add_to_group("rune")
	z_index = 2


func _hero() -> Node:
	return get_tree().get_first_node_in_group("hero")


## Палец ловит рисование, только когда мел у героя.
func contains_world_point(point: Vector2) -> bool:
	var hero := _hero()
	if not hero or not hero.has_chalk:
		return false
	_point = point
	return true


func hand_tap() -> void:
	_current = PackedVector2Array([_point])
	_length = 0.0
	queue_redraw()


func hand_drag(world_delta: Vector2) -> void:
	if _current.is_empty():
		return
	var last := _current[_current.size() - 1]
	var next := _point + world_delta
	_point = next
	var step := last.distance_to(next)
	if step < 6.0 or _length >= max_length:
		return
	if _length + step > max_length:
		next = last + (next - last).normalized() * (max_length - _length)
		step = max_length - _length
	_current.append(next)
	_length += step
	Game.hand_used.emit("drag")
	queue_redraw()


func hand_release() -> void:
	if _current.size() >= 2 and _length >= 16.0:
		_add_stroke(_current)
	_current = PackedVector2Array()
	queue_redraw()


func _add_stroke(points: PackedVector2Array) -> void:
	if strokes.size() >= max_strokes:
		strokes.pop_front()
		_bodies.pop_front().queue_free()
	var body := StaticBody2D.new()
	for i in points.size() - 1:
		var shape := CollisionShape2D.new()
		var seg := SegmentShape2D.new()
		seg.a = points[i]
		seg.b = points[i + 1]
		shape.shape = seg
		shape.one_way_collision = true
		body.add_child(shape)
	add_child(body)
	strokes.append(points)
	_bodies.append(body)
	Sfx.play("land", -4.0, 0.8)
	queue_redraw()


func _draw() -> void:
	for s in strokes:
		_draw_stroke(s, 1.0)
	if _current.size() >= 2:
		_draw_stroke(_current, 0.6)


## Меловая линия: белая, с неровным краем и крошками мела.
func _draw_stroke(points: PackedVector2Array, alpha: float) -> void:
	draw_polyline(points, Color(0.85, 0.83, 0.78, 0.35 * alpha), 8.0, true)
	draw_polyline(points, Color(0.97, 0.96, 0.92, alpha), 4.0, true)
	for i in points.size():
		var p := points[i]
		draw_rect(Rect2(p + Vector2(-1, -4 - (i % 3)), Vector2(2, 1)), Color(1, 1, 1, 0.5 * alpha))
		draw_rect(Rect2(p + Vector2(1, 3 + (i % 2)), Vector2(1, 1)), Color(1, 1, 1, 0.4 * alpha))
	draw_circle(points[0], 2.2, Color(0.97, 0.96, 0.92, alpha))
	draw_circle(points[points.size() - 1], 2.2, Color(0.97, 0.96, 0.92, alpha))
