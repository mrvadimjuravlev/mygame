@tool
extends Area2D
## Стрела-ловушка: вылетает из щели в стене, летит по горизонтали до другой стены,
## после паузы вылетает снова. Касание героя — гибель. Позиция узла задаёт высоту линии полёта.

## Края полёта: щели в стенах слева и справа.
@export var from_x := 24.0
@export var to_x := 616.0
@export var speed := 170.0
## Откуда стреляет: 1 — из левой стены вправо, -1 — из правой влево.
@export var start_dir := 1.0
## Пауза между выстрелами, секунды.
@export var pause := 0.9
## Задержка до первого выстрела: чтобы стрелы на разных линиях не летели в такт.
@export var first_delay := 0.0

var dir := 1.0
## Стрела в полёте; в паузе её нет и она не ранит.
var flying := false
## Сколько ещё ждать до выстрела.
var wait := 0.0
var _shape: CollisionShape2D


func _ready() -> void:
	dir = start_dir
	position.x = _start_x()
	if Engine.is_editor_hint():
		return
	add_to_group("arrow")
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 4)
	_shape.shape = rect
	add_child(_shape)
	body_entered.connect(func(body: Node) -> void:
		if flying and body.is_in_group("hero"):
			body.die())
	wait = first_delay
	flying = wait <= 0.0
	_shape.disabled = not flying


func _start_x() -> float:
	return from_x if start_dir > 0.0 else to_x


func _end_x() -> float:
	return to_x if start_dir > 0.0 else from_x


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not flying:
		wait -= delta
		if wait <= 0.0:
			flying = true
			position.x = _start_x()
			_shape.set_deferred("disabled", false)
		queue_redraw()
		return
	position.x += dir * speed * delta
	if (dir > 0.0 and position.x >= _end_x()) or (dir < 0.0 and position.x <= _end_x()):
		# Вонзилась в стену напротив — исчезает до следующего выстрела.
		flying = false
		wait = pause
		_shape.set_deferred("disabled", true)
	queue_redraw()


## Через сколько секунд стрела окажется у точки x на своей линии (для автотеста).
func time_to_reach(x: float) -> float:
	var span := absf(_end_x() - _start_x())
	var from_start := absf(x - _start_x())
	if flying:
		var ahead := (x - position.x) * dir
		if ahead >= 0.0:
			return ahead / speed
		return (absf(_end_x() - position.x)) / speed + pause + from_start / speed
	return maxf(wait, 0.0) + from_start / speed


func _draw() -> void:
	# Щель в стене, откуда вылетают стрелы (рисуется на месте старта).
	var slot := Vector2(_start_x() - position.x - dir * 4.0, 0)
	draw_rect(Rect2(slot + Vector2(-4, -4), Vector2(8, 8)), Color("140e0a"))
	draw_rect(Rect2(slot + Vector2(-4, -4), Vector2(8, 1)), Color("5a4129"))
	if not flying and not Engine.is_editor_hint():
		return
	var d := dir
	var wood := Color("c9a46a")
	# Древко, наконечник, оперение.
	draw_line(Vector2(-11 * d, 0), Vector2(7 * d, 0), wood, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(7 * d, -3), Vector2(13 * d, 0), Vector2(7 * d, 3)]), Color("d8d8d0"))
	draw_colored_polygon(PackedVector2Array([Vector2(-11 * d, 0), Vector2(-15 * d, -4), Vector2(-8 * d, 0)]), Color("b4452f"))
	draw_colored_polygon(PackedVector2Array([Vector2(-11 * d, 0), Vector2(-15 * d, 4), Vector2(-8 * d, 0)]), Color("b4452f"))
	# Свистящий след за стрелой.
	draw_line(Vector2(-26 * d, 0), Vector2(-16 * d, 0), Color(1, 1, 1, 0.25), 1.0)
