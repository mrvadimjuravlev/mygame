@tool
extends Area2D
## Дверь «Той же комнаты» (loop_room): тёмная арка. Герой встаёт в проём и жмёт «Действие».
## back — левая дверь «назад», иначе правая «вперёд». Начало координат — у пола.

@export var back := false:
	set(value):
		back = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("interactable")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 40)
	shape.shape = rect
	shape.position = Vector2(0, -20)
	add_child(shape)


func use() -> void:
	get_parent().choose(back)


func _draw() -> void:
	var stone := Color("8a7a64")
	var shade := Color("5a4e40")
	draw_rect(Rect2(-13, -44, 26, 44), Color("0c0a08"))
	draw_rect(Rect2(-18, -48, 5, 48), stone)
	draw_rect(Rect2(13, -48, 5, 48), stone)
	draw_rect(Rect2(-20, -54, 40, 7), stone)
	draw_rect(Rect2(-20, -48, 40, 1), shade)
	# Стрелка над дверью: назад или вперёд.
	var d := -1.0 if back else 1.0
	draw_colored_polygon(PackedVector2Array([Vector2(6 * d, -51), Vector2(-3 * d, -54), Vector2(-3 * d, -48)]), Color("e2bf78"))
