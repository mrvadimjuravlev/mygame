@tool
extends Node2D
## Обучающий значок без текста: пульсирующий круг на месте, где нужно коснуться.
## Если задан move_to, круг показывает движение «перетащи». Исчезает после первого действия.

@export var wait_for: StringName = &"tap"
@export var move_to := Vector2.ZERO

var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	Game.hand_used.connect(func(kind: String) -> void:
		if kind == wait_for:
			queue_free())


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var t := fmod(_time, 1.6) / 1.6
	var p := move_to * t if move_to != Vector2.ZERO else Vector2.ZERO
	var c := Color(1, 1, 1, 0.9)
	draw_arc(p, 8.0 + 10.0 * t, 0, TAU, 32, Color(1, 1, 1, 1.0 - t), 2.0)
	draw_circle(p, 5.0, c)
