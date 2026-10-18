@tool
extends StaticBody2D
## Мост из досок, который рушится в момент collapse_at по времени зала (time_glass).
## Перемотка назад поднимает доски обратно. Начало координат — левый край настила.

@export var width := 160.0:
	set(value):
		width = value
		queue_redraw()
## Когда (секунды времени зала) мост рушится.
@export var collapse_at := 1.8
const PLANK := 20.0
const GRAVITY := 700.0

var _t := 0.0
var _shapes: Array[CollisionShape2D] = []
var _cracked := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("timed")
	for i in _count():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(PLANK, 8)
		shape.shape = rect
		shape.position = Vector2(i * PLANK + PLANK / 2, 4)
		add_child(shape)
		_shapes.append(shape)


func _count() -> int:
	return int(width / PLANK)


## Доска i: насколько она упала и повернулась к моменту времени t.
func _fall(i: int, t: float) -> Vector2:
	var start := collapse_at + absf(i - _count() / 2.0) * 0.06
	var dt := t - start
	if dt <= 0.0:
		return Vector2.ZERO
	return Vector2(0.5 * GRAVITY * dt * dt, dt * (2.0 if i % 2 == 0 else -2.5))


func set_time(t: float) -> void:
	_t = t
	for i in _shapes.size():
		var f := _fall(i, t)
		_shapes[i].position.y = 4 + f.x
		_shapes[i].disabled = f.x > 3.0
	var cracked := t >= collapse_at
	if cracked and not _cracked:
		Sfx.play("land")
	_cracked = cracked
	queue_redraw()


func _draw() -> void:
	var wood := Color("7a5634")
	var dark := Color("4a3220")
	# Верёвки-перила, пока мост цел.
	if _t < collapse_at:
		draw_line(Vector2(0, -18), Vector2(width, -18), Color("9a7a50"), 1.0)
		for x in [0.0, width]:
			draw_rect(Rect2(x - 2, -20, 4, 20), dark)
	for i in _count():
		var f := _fall(i, _t) if not Engine.is_editor_hint() else Vector2.ZERO
		if f.x > 200.0:
			continue
		draw_set_transform(Vector2(i * PLANK + PLANK / 2, 4 + f.x), f.y, Vector2.ONE)
		draw_rect(Rect2(-PLANK / 2 + 1, -4, PLANK - 2, 8), wood)
		draw_rect(Rect2(-PLANK / 2 + 1, -4, PLANK - 2, 2), Color("9a7048"))
		draw_rect(Rect2(-PLANK / 2 + 1, 2, PLANK - 2, 2), dark)
	draw_set_transform(Vector2.ZERO)
