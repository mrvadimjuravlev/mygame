@tool
extends StaticBody2D
## Люк в полу: снизу сквозь него можно пролезть (по лестнице), сверху по нему ходят.
## Выглядит как обычный пол. Начало координат — левый верхний угол.

const Art := preload("res://scripts/art.gd")

@export var size := Vector2(30, 12):
	set(value):
		size = value
		queue_redraw()


func _ready() -> void:
	z_index = 1  # поверх лестницы: сверху люк не выдаёт себя
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size / 2
	shape.one_way_collision = true
	add_child(shape)


func _draw() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	Art.draw_textured(self, PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]), Art.plaster())
	draw_line(Vector2(0, 0.5), Vector2(size.x, 0.5), Art.SAND_LIGHT, 1.0)
	draw_line(Vector2(0, 1.5), Vector2(size.x, 1.5), Art.SAND, 1.0)
