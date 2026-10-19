extends Node2D
## Метки мелом: касание пальцем ставит на стене белый крестик, касание метки стирает её.
## Помогает не ходить по кругу в лабиринте. Не больше MAX меток: лишняя стирает самую старую.

const MAX := 16

var marks: Array[Vector2] = []
var _hit := Vector2.ZERO


func _ready() -> void:
	add_to_group("rune")
	z_index = 3


func contains_world_point(point: Vector2) -> bool:
	_hit = point
	return true


func hand_tap() -> void:
	for i in marks.size():
		if marks[i].distance_to(_hit) < 14.0:
			marks.remove_at(i)
			Sfx.play("tap")
			queue_redraw()
			return
	marks.append(_hit)
	if marks.size() > MAX:
		marks.remove_at(0)
	Sfx.play("tap")
	queue_redraw()


func hand_drag(_delta: Vector2) -> void:
	pass


func _draw() -> void:
	for m in marks:
		draw_line(m + Vector2(-6, -6), m + Vector2(6, 6), Color(0.95, 0.95, 0.9, 0.9), 2.0)
		draw_line(m + Vector2(6, -6), m + Vector2(-6, 6), Color(0.95, 0.95, 0.9, 0.9), 2.0)
		draw_circle(m, 9.0, Color(1, 1, 1, 0.08))
