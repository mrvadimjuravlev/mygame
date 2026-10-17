@tool
extends StaticBody2D
## Исчезающая плита: по кругу видна, тает, пропадает и проявляется снова. Пока её нет, на ней не устоять;
## на месте плиты остаётся едва заметный контур. Начало координат — середина верхней грани.

const Art := preload("res://scripts/art.gd")

@export var size := Vector2(48, 12):
	set(value):
		size = value
		queue_redraw()
## Сколько секунд плита стоит целиком.
@export var on_time := 1.6
## Сколько её нет.
@export var off_time := 1.0
## Сколько она тает и сколько проявляется.
@export var fade := 0.4
## Сдвиг по кругу, секунды: соседние плиты пропадают по очереди.
@export var phase := 0.0

var _shape: CollisionShape2D
var _time := 0.0
var _alpha := 1.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = Vector2(0, size.y / 2)
	add_child(_shape)
	_time = phase
	_update()


func cycle() -> float:
	return on_time + off_time + fade * 2.0


## Плита держит героя (по времени t от начала уровня, со сдвигом phase).
func solid_at(t: float) -> bool:
	return fposmod(t + phase, cycle()) < on_time + fade * 0.5


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_update()


func _update() -> void:
	var t := fposmod(_time, cycle())
	var a := 1.0
	if t < on_time:
		a = 1.0
	elif t < on_time + fade:
		a = 1.0 - (t - on_time) / fade
	elif t < on_time + fade + off_time:
		a = 0.0
	else:
		a = (t - on_time - fade - off_time) / fade
	var solid := t < on_time + fade * 0.5
	if _shape.disabled == solid:
		_shape.set_deferred("disabled", not solid)
	if not is_equal_approx(a, _alpha):
		_alpha = a
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2(-size.x / 2, 0), size)
	# Контур, где плита появится.
	var ghost := Color(0.85, 0.75, 0.55, 0.22)
	var x := rect.position.x
	while x < rect.end.x:
		draw_line(Vector2(x, rect.position.y + 0.5), Vector2(minf(x + 3, rect.end.x), rect.position.y + 0.5), ghost, 1.0)
		draw_line(Vector2(x, rect.end.y - 0.5), Vector2(minf(x + 3, rect.end.x), rect.end.y - 0.5), ghost, 1.0)
		x += 6.0
	if _alpha > 0.01:
		Art.draw_slab(self, rect, Color(1, 1, 1, _alpha))
		# Голубоватые прожилки: камень волшебный, не обычный.
		draw_line(Vector2(rect.position.x + 6, rect.position.y + 6), Vector2(rect.end.x - 6, rect.position.y + 6), Color(0.37, 0.83, 1.0, 0.35 * _alpha), 1.0)
