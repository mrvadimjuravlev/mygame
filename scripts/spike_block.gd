@tool
extends Area2D
## Шипастый камень, висящий на цепи над путём: касание — гибель. Через него перепрыгивают.
## Начало координат — центр камня; цепь уходит вверх на chain.

const Art := preload("res://scripts/art.gd")

@export var size := Vector2(16, 12):
	set(value):
		size = value
		queue_redraw()
@export var chain := 120.0:
	set(value):
		chain = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size + Vector2(4, 4)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("hero"):
			body.die())


func _draw() -> void:
	var y := -size.y / 2 - chain
	var k := 0
	while y < -size.y / 2:
		if k % 2 == 0:
			draw_rect(Rect2(-2, y, 4, 5), Color("4a4642"), false, 1.0)
		else:
			draw_rect(Rect2(-0.5, y, 1, 5), Color("5e5a55"))
		y += 4.0
		k += 1
	var r := Rect2(-size / 2, size)
	# Шипы со всех сторон, кроме верха с цепью.
	Art.draw_spike_row(self, Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), Vector2.DOWN, 6.0)
	Art.draw_spike_row(self, Vector2(r.position.x, r.position.y + 1), Vector2(r.position.x, r.end.y), Vector2.LEFT, 6.0)
	Art.draw_spike_row(self, Vector2(r.end.x, r.position.y + 1), Vector2(r.end.x, r.end.y), Vector2.RIGHT, 6.0)
	draw_rect(r, Color("5f594f"))
	draw_rect(Rect2(r.position, Vector2(size.x, 2)), Color("8d8679"))
	draw_rect(r, Color("2e2a26"), false, 1.0)
