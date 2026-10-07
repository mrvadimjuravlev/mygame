@tool
extends Node2D
## Украшения локаций: цепь (подземелье), знамя (замок), водоросли (храм), паутина, корни,
## кости, разбитый кувшин, цветной сосуд на подставке (urn, цвет — color). Чистая красота.
## Начало координат — точка крепления сверху (у водорослей, костей и кувшина — на полу).
## Паутина висит в углу: length — размер, color.a не важен; scale.x = -1 зеркалит её в правый угол.

@export_enum("chain", "banner", "weed", "web", "roots", "bones", "vase", "urn") var kind := "chain":
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
	if (kind == "weed" or kind == "web" or kind == "roots") and not Engine.is_editor_hint():
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
		"web":
			# Паутина в левом верхнем углу: лучи из угла и провисшие нити между ними.
			var silk := Color(0.86, 0.84, 0.78, 0.45)
			var sway := sin(_time * 0.8) * 0.6
			var rays := 5
			var ends := []
			for i in rays:
				var ang := PI / 2 * (i + 0.5) / rays
				ends.append(Vector2(cos(ang), sin(ang)) * length)
				draw_line(Vector2.ZERO, ends[i], silk, 1.0)
			for ring in range(1, 5):
				var t := ring / 4.5
				for i in rays - 1:
					var a: Vector2 = ends[i] * t
					var b: Vector2 = ends[i + 1] * t
					var mid := (a + b) / 2 * (0.9 + 0.02 * ring) + Vector2(sway, absf(sway))
					draw_polyline(PackedVector2Array([a, mid, b]), silk, 1.0)
			# Оборванная нить с паучком.
			var drop := Vector2(length * 0.55, length * 0.55)
			var hang := drop + Vector2(sway * 2.0, length * 0.5)
			draw_line(drop, hang, Color(silk, 0.3), 1.0)
			draw_circle(hang, 2.0, Color("2a201a"))
		"roots":
			# Корни пробились сквозь потолок.
			for i in 4:
				var base := Vector2(-9 + i * 6, 0)
				var pts := PackedVector2Array()
				var l := length * (0.55 + 0.15 * ((i * 7) % 4))
				for k in 6:
					var t := k / 5.0
					pts.append(base + Vector2(sin(t * 5.0 + i * 1.7) * 3.0 + sin(_time + i) * t * 1.0, l * t))
				draw_polyline(pts, Color("4a3524"), 2.0 - i * 0.3)
		"bones":
			# Череп и кости у стены: прежний искатель.
			var bone := Color("d8cdb2")
			var dim := Color("a89c80")
			draw_line(Vector2(-14, -2), Vector2(2, -4), bone, 2.0)
			draw_circle(Vector2(-14, -2), 1.6, bone)
			draw_circle(Vector2(2, -4), 1.6, bone)
			draw_line(Vector2(-8, -1), Vector2(6, -1), dim, 2.0)
			draw_rect(Rect2(8, -10, 9, 7), bone)
			draw_rect(Rect2(9, -4, 7, 4), bone)
			draw_rect(Rect2(10, -8, 2, 2), Color("1a120c"))
			draw_rect(Rect2(14, -8, 2, 2), Color("1a120c"))
			draw_rect(Rect2(10, -2, 1, 2), dim)
			draw_rect(Rect2(13, -2, 1, 2), dim)
		"vase":
			# Кувшин и черепки рядом.
			var clay := Color("9a5a34")
			var paint := Color("e2bf78")
			draw_colored_polygon(PackedVector2Array([Vector2(-5, -22), Vector2(5, -22), Vector2(4, -18), Vector2(9, -12), Vector2(8, -3), Vector2(4, 0), Vector2(-4, 0), Vector2(-8, -3), Vector2(-9, -12), Vector2(-4, -18)]), clay)
			draw_rect(Rect2(-8, -12, 16, 2), paint)
			draw_rect(Rect2(-6, -7, 2, 2), paint)
			draw_rect(Rect2(-1, -7, 2, 2), paint)
			draw_rect(Rect2(4, -7, 2, 2), paint)
			draw_rect(Rect2(-6, -22, 12, 2), clay.lightened(0.15))
			draw_colored_polygon(PackedVector2Array([Vector2(13, 0), Vector2(19, -4), Vector2(21, 0)]), clay.darkened(0.15))
			draw_colored_polygon(PackedVector2Array([Vector2(23, 0), Vector2(26, -2), Vector2(29, 0)]), clay)
		"urn":
			# Расписной сосуд на каменной подставке; цвет — подсказка.
			draw_rect(Rect2(-12, -8, 24, 8), Color("6e5236"))
			draw_rect(Rect2(-12, -8, 24, 1), Color("8a6a43"))
			var body := PackedVector2Array([Vector2(-5, -36), Vector2(5, -36), Vector2(4, -32), Vector2(10, -24), Vector2(9, -13), Vector2(5, -8), Vector2(-5, -8), Vector2(-9, -13), Vector2(-10, -24), Vector2(-4, -32)])
			draw_colored_polygon(body, color)
			draw_rect(Rect2(-9, -24, 18, 2), color.lightened(0.35))
			draw_rect(Rect2(-6, -36, 12, 2), color.lightened(0.2))
			draw_rect(Rect2(-8, -16, 3, 6), color.darkened(0.25))
