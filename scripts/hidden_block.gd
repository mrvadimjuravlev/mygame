@tool
extends StaticBody2D
## Невидимый блок: его не видно, пока герой не приземлится на него сверху.
## Снизу блок проницаем: прыжок снизу проходит сквозь него и не выдаёт его.
## После приземления блок проявляется навсегда. Начало координат — центр.

@export var size := Vector2(50, 14):
	set(value):
		size = value
		queue_redraw()

var revealed := false
var _reveal := 0.0
var _sensor: Area2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("hidden_block")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.one_way_collision = true
	add_child(shape)
	# Датчик над верхней гранью: герой встал на блок.
	_sensor = Area2D.new()
	var sensor := _sensor
	var sensor_shape := CollisionShape2D.new()
	var sensor_rect := RectangleShape2D.new()
	sensor_rect.size = Vector2(size.x, 6)
	sensor_shape.shape = sensor_rect
	sensor_shape.position = Vector2(0, -size.y / 2 - 3)
	sensor.add_child(sensor_shape)
	add_child(sensor)


func _physics_process(_delta: float) -> void:
	if revealed or Engine.is_editor_hint():
		return
	# Проявляется, только когда герой стоит на верхней грани, а не пролетает сквозь неё снизу.
	var top := global_position.y - size.y / 2
	for body in _sensor.get_overlapping_bodies():
		if body.is_in_group("hero") and body.is_on_floor() and absf(body.global_position.y - top) < 2.0:
			reveal()


func reveal() -> void:
	if revealed:
		return
	revealed = true
	create_tween().tween_property(self, "_reveal", 1.0, 0.4)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var r := Rect2(-size / 2, size)
	if Engine.is_editor_hint():
		# В редакторе блок виден пунктиром, чтобы его можно было расставлять.
		draw_rect(r, Color(0.37, 0.83, 1.0, 0.5), false, 1.0)
		return
	if _reveal <= 0.0:
		return
	draw_rect(r, Color(Color("9b7b52"), _reveal))
	draw_rect(r, Color(Color("5e4630"), _reveal), false, 1.0)
	# Вспышка пыли при появлении.
	if _reveal < 1.0:
		draw_rect(r.grow(6.0 * (1.0 - _reveal)), Color(1, 0.9, 0.6, 1.0 - _reveal), false, 1.0)
