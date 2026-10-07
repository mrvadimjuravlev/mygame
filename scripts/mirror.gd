@tool
extends Area2D
## Поворотное зеркало на бронзовой оси. Касание пальцем поворачивает его на 22,5°,
## поэтому луч уходит и под прямым углом, и наискосок (кратно 45°).
## Положения 0–7: 0 «—», 2 «\», 4 «|», 6 «/», нечётные — между ними. Отражает луч обеими сторонами.

const STEPS := 8
const TURN := PI / STEPS

const HALF := 12.0

@export_range(0, 7) var step := 0:
	set(value):
		step = posmod(value, STEPS)
		_shown = step * TURN
		queue_redraw()

var _shown := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("rune")
	add_to_group("mirror")


func contains_world_point(point: Vector2) -> bool:
	return global_position.distance_to(point) < HALF + 8.0


func hand_drag(_world_delta: Vector2) -> void:
	pass


func hand_tap() -> void:
	Game.hand_used.emit("tap")
	var from := _shown
	step += 1
	# Плавный поворот на глаз; луч считает новое положение сразу.
	_shown = from
	var tween := create_tween()
	tween.tween_property(self, "_shown", from + TURN, 0.12)
	tween.tween_callback(func() -> void: _shown = step * TURN)
	Sfx.play("lever", -2.0, 1.4)


## Отражающий отрезок в мировых координатах.
func segment() -> PackedVector2Array:
	var d := Vector2.from_angle(step * TURN) * HALF
	return PackedVector2Array([global_position - d, global_position + d])


func normal() -> Vector2:
	return Vector2.from_angle(step * TURN).orthogonal()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	# Ось и подставка.
	draw_circle(Vector2.ZERO, 5.0, Color("6b4a24"))
	draw_set_transform(Vector2.ZERO, _shown)
	draw_rect(Rect2(-HALF - 2, -3, HALF * 2 + 4, 6), Color("8a6a2c"))
	draw_rect(Rect2(-HALF, -1.5, HALF * 2, 3), Color("d8e6ea"))
	draw_rect(Rect2(-HALF, -1.5, HALF * 2, 1), Color("ffffff"))
	draw_set_transform(Vector2.ZERO, 0.0)
	draw_circle(Vector2.ZERO, 2.0, Color("e2bf78"))
