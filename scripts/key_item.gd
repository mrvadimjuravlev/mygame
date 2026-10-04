@tool
extends Area2D
## Ключ-артефакт: герой подбирает его касанием. Им открывается запертая дверь выхода.
## Начало координат — поверхность, на которой лежит ключ.

var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 20)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("hero"):
		body.has_key = true
		Sfx.play("key")
		queue_free()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var y := -10.0 + 2.0 * sin(_time * 3.0)
	draw_circle(Vector2(0, y), 9.0, Color(1, 0.85, 0.3, 0.15))
	draw_key(self, Vector2(0, y))


static func draw_key(canvas: CanvasItem, at: Vector2) -> void:
	var gold := Color("f2c14e")
	canvas.draw_arc(at + Vector2(-4, 0), 3.0, 0, TAU, 12, gold, 2.0)
	canvas.draw_line(at + Vector2(-1, 0), at + Vector2(6, 0), gold, 2.0)
	canvas.draw_line(at + Vector2(4, 0), at + Vector2(4, 3), gold, 2.0)
	canvas.draw_line(at + Vector2(6, 0), at + Vector2(6, 3), gold, 2.0)
