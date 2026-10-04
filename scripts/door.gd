@tool
extends AnimatableBody2D
## Каменная дверь. Эффекты: activate (открыть), close, toggle. Начало координат — центр.

@export var size := Vector2(16, 160):
	set(value):
		size = value
		queue_redraw()
@export var open_offset := Vector2(0, -160)

var is_open := false
var _closed_position := Vector2.ZERO


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_closed_position = position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	add_child(shape)


func activate() -> void:
	_move(true)


func close() -> void:
	_move(false)


func toggle() -> void:
	_move(not is_open)


func _move(open: bool) -> void:
	if open == is_open:
		return
	is_open = open
	Sfx.play("door", -3.0)
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", _closed_position + (open_offset if open else Vector2.ZERO), 0.7)


func _draw() -> void:
	var r := Rect2(-size / 2, size)
	draw_rect(r, Color("5e4630"))
	draw_rect(r, Color("3b2a1c"), false, 1.0)
	var y := -size.y / 2 + 12
	while y < size.y / 2:
		draw_line(Vector2(-size.x / 2 + 2, y), Vector2(size.x / 2 - 2, y), Color("4a3524"), 1.0)
		y += 16
