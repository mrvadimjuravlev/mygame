@tool
extends Node2D
## Вода: полупрозрачная гладь с бегущей рябью. Только картинка — гибель даёт падение ниже fall_limit.
## Начало координат — левый край поверхности воды.

@export var size := Vector2(160, 60):
	set(value):
		size = value
		queue_redraw()

var _time := 0.0


func _ready() -> void:
	z_index = 1


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.18, 0.45, 0.55, 0.75))
	draw_rect(Rect2(0, 0, size.x, 2), Color(0.55, 0.85, 0.9, 0.8))
	var x := fmod(_time * 12.0, 16.0)
	for row in 3:
		var y := 6.0 + row * 9.0
		var off := x if row % 2 == 0 else 16.0 - x
		var px := -16.0 + off
		while px < size.x:
			if px >= 0.0 and px + 6.0 <= size.x:
				draw_line(Vector2(px, y), Vector2(px + 6, y - 1), Color(0.6, 0.9, 0.95, 0.5), 1.0)
			px += 16.0
