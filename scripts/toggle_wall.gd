@tool
extends StaticBody2D
## Цветная стена лабиринта: красная или синяя. Рычаг (через wall_switch) переключает цвета:
## стоят то красные стены, то синие. Ушедшая стена — пунктирный контур, сквозь неё проходят.
## Начало координат — левый верхний угол.

@export var size := Vector2(16, 154):
	set(value):
		size = value
		queue_redraw()
@export_enum("red", "blue") var color := "red":
	set(value):
		color = value
		queue_redraw()

var solid := true
var _shape: CollisionShape2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("toggle_wall")
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = size / 2
	add_child(_shape)


## Красные стоят (red_on) или синие.
func set_red(red_on: bool) -> void:
	solid = red_on == (color == "red")
	_shape.set_deferred("disabled", not solid)
	queue_redraw()


func _draw() -> void:
	var c := Color("c0392b") if color == "red" else Color("2e6fd8")
	if solid:
		draw_rect(Rect2(Vector2.ZERO, size), c.darkened(0.25))
		var y := 0.0
		while y < size.y:
			draw_rect(Rect2(1, y + 1, size.x - 2, 14), c)
			draw_rect(Rect2(1, y + 1, size.x - 2, 2), c.lightened(0.3))
			y += 16.0
	else:
		var y := 0.0
		while y < size.y:
			draw_line(Vector2(0, y), Vector2(0, minf(y + 6, size.y)), Color(c, 0.6), 1.0)
			draw_line(Vector2(size.x, y), Vector2(size.x, minf(y + 6, size.y)), Color(c, 0.6), 1.0)
			y += 12.0
