@tool
extends Area2D
## Зелье: герой выпивает его касанием. Эффект — переворот гравитации.
## Начало координат — поверхность, на которой стоит бутылка.

var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 20)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	add_child(shape)
	body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("hero"):
			body.flip_gravity()
			queue_free())


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var glow := 0.15 + 0.1 * sin(_time * 3.0)
	draw_circle(Vector2(0, -8), 12.0, Color(0.7, 0.4, 1.0, glow))
	draw_rect(Rect2(-5, -12, 10, 12), Color("8e5bd6"))       # колба
	draw_rect(Rect2(-5, -12, 10, 4), Color("b58cf0"))        # блик
	draw_rect(Rect2(-2, -17, 4, 5), Color("c9b48a"))         # горлышко
	draw_rect(Rect2(-3, -19, 6, 2), Color("6b4423"))         # пробка
	# Стрелки вверх-вниз: намёк на гравитацию.
	draw_line(Vector2(-9, -4), Vector2(-9, -14), Color(1, 1, 1, 0.5), 1.0)
	draw_line(Vector2(9, -4), Vector2(9, -14), Color(1, 1, 1, 0.5), 1.0)
