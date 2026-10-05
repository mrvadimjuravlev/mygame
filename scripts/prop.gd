@tool
extends Node2D
## Украшения локаций: цепь (подземелье), знамя (замок), водоросли (храм). Чистая красота.
## Начало координат — точка крепления сверху (у водорослей — корень снизу).

@export_enum("chain", "banner", "weed") var kind := "chain":
	set(value):
		kind = value
		queue_redraw()
@export var length := 60.0:
	set(value):
		length = value
		queue_redraw()
@export var color := Color("8a2b2b"):
	set(value):
		color = value
		queue_redraw()

var _time := 0.0


func _process(delta: float) -> void:
	if kind == "weed" and not Engine.is_editor_hint():
		_time += delta
		queue_redraw()


func _draw() -> void:
	match kind:
		"chain":
			var y := 0.0
			var k := 0
			while y < length:
				if k % 2 == 0:
					draw_rect(Rect2(-2, y, 4, 6), Color("4a4642"), false, 1.0)
				else:
					draw_rect(Rect2(-0.5, y, 1, 6), Color("5e5a55"))
				y += 5.0
				k += 1
			draw_circle(Vector2(0, length + 3), 4.0, Color("3b3834"))
		"banner":
			draw_rect(Rect2(-14, -2, 28, 3), Color("5e4630"))
			var poly := PackedVector2Array([Vector2(-11, 1), Vector2(11, 1), Vector2(11, length), Vector2(0, length - 8), Vector2(-11, length)])
			draw_colored_polygon(poly, color)
			draw_rect(Rect2(-11, 1, 22, 2), color.lightened(0.25))
			# Герб: золотой ромб.
			var c := Vector2(0, length * 0.4)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(5, 0), c + Vector2(0, 6), c + Vector2(-5, 0)]), Color("e2bf78"))
		"weed":
			for i in 3:
				var base := Vector2(-6 + i * 6, 0)
				var pts := PackedVector2Array()
				for k in 7:
					var t := k / 6.0
					pts.append(base + Vector2(sin(_time * 1.5 + t * 4.0 + i) * 3.0 * t, -length * t * (0.7 + 0.15 * i)))
				draw_polyline(pts, Color("3f7a52"), 2.0)
