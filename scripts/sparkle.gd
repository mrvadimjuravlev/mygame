@tool
extends Node2D
## Блеск в недоступном месте: задел под секрет, который откроется с рывком.

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var a := 0.4 + 0.6 * absf(sin(_time * 2.0))
	var c := Color(1, 0.95, 0.6, a)
	draw_line(Vector2(-4, 0), Vector2(4, 0), c, 1.0)
	draw_line(Vector2(0, -4), Vector2(0, 4), c, 1.0)
	draw_circle(Vector2.ZERO, 1.5, c)
