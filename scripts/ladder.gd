@tool
extends Area2D
## Верёвочная лестница. Висит свёрнутой у верхнего края и разворачивается вниз по событию (activate).
## Начало координат — точка крепления сверху.

@export var length := 840.0:
	set(value):
		length = value
		queue_redraw()
@export var rolled_length := 24.0
@export var start_unrolled := false

var _current := 0.0
var _shape: RectangleShape2D
var _collision: CollisionShape2D


func _ready() -> void:
	_current = length if start_unrolled or Engine.is_editor_hint() else rolled_length
	if Engine.is_editor_hint():
		return
	add_to_group("ladder")
	_collision = CollisionShape2D.new()
	_shape = RectangleShape2D.new()
	_collision.shape = _shape
	add_child(_collision)
	_update_shape()


## Эффект события: развернуть лестницу до земли.
func activate() -> void:
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_method(func(v: float) -> void:
		_current = v
		_update_shape()
		queue_redraw(), _current, length, 1.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Верхняя точка, до которой можно долезть (ступни героя).
func top_y() -> float:
	return global_position.y - 12.0


func _update_shape() -> void:
	# Зона лазания: от чуть выше крепления до низа лестницы.
	_shape.size = Vector2(14, _current + 14)
	_collision.position = Vector2(0, _current / 2 - 7)


func _draw() -> void:
	var rope := Color("b08850")
	draw_line(Vector2(-6, 0), Vector2(-6, _current), rope, 1.5)
	draw_line(Vector2(6, 0), Vector2(6, _current), rope, 1.5)
	var y := 6.0
	while y < _current:
		draw_line(Vector2(-6, y), Vector2(6, y), Color("8a6a43"), 2.0)
		y += 10.0
	if _current <= rolled_length + 1.0 and not Engine.is_editor_hint():
		draw_circle(Vector2(0, _current), 8.0, Color("8a6a43"))  # свёрнутый моток
