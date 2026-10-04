@tool
extends Area2D
## Рычаг: герой нажимает кнопку действия рядом с ним. Начало координат — точка крепления снизу.

@export var targets: Array[NodePath] = []
@export var effect: StringName = &"activate"
@export var one_shot := true
## lever — рычаг на стене, button — кнопка на каменном столбике.
@export_enum("lever", "button") var style := "lever":
	set(value):
		style = value
		queue_redraw()

var pulled := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("interactable")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 26)
	shape.shape = rect
	shape.position = Vector2(0, -13)
	add_child(shape)


func use() -> void:
	if pulled and one_shot:
		return
	pulled = not pulled
	Sfx.play("lever")
	queue_redraw()
	Game.fire(self, targets, effect)


func _draw() -> void:
	if style == "button":
		draw_rect(Rect2(-6, -14, 12, 14), Color("6e5236"))
		draw_rect(Rect2(-6, -14, 12, 14), Color("3b2a1c"), false, 1.0)
		draw_rect(Rect2(-4, -17 if not pulled else -15, 8, 3), Color("d9534f"))
		return
	draw_rect(Rect2(-6, -6, 12, 6), Color("5e4630"))
	var tip := Vector2(7, -18) if pulled else Vector2(-7, -18)
	draw_line(Vector2(0, -4), tip, Color("b08850"), 3.0)
	draw_circle(tip, 3.0, Color("d9534f"))
