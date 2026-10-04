@tool
extends Area2D
## Шипы: касание — гибель. Начало координат — левый край основания.

@export var width := 60.0:
	set(value):
		width = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 12)
	shape.shape = rect
	shape.position = Vector2(width / 2, -6)
	add_child(shape)
	body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("hero"):
			body.die())


func _draw() -> void:
	var x := 0.0
	while x < width:
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 5, -14), Vector2(x + 10, 0)]), Color("8d8679"))
		draw_colored_polygon(PackedVector2Array([Vector2(x + 5, 0), Vector2(x + 5, -14), Vector2(x + 10, 0)]), Color("5f594f"))
		draw_line(Vector2(x + 4.5, -13), Vector2(x + 2, -4), Color("d6d0c2"), 1.0)
		draw_rect(Rect2(x + 4, -14, 2, 4), Color("7a2a20"))
		x += 10.0
	draw_rect(Rect2(0, -2, width, 2), Color("3b2d20"))
