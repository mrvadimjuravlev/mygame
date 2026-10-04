@tool
extends StaticBody2D
## Векторная геометрия уровня: произвольный многоугольник без сетки.
## Рисуется старым камнем, местами осыпавшимся до кладки; грани, смотрящие вверх, — песчаный край, вниз — тень.

const Art := preload("res://scripts/art.gd")

@export var polygon := PackedVector2Array():
	set(value):
		polygon = value
		queue_redraw()
@export var color := Color("8a6a43"):
	set(value):
		color = value
		queue_redraw()


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	if Engine.is_editor_hint():
		return
	add_to_group("solid")
	var shape := CollisionPolygon2D.new()
	shape.polygon = polygon
	add_child(shape)


## Точка не внутри другого камня: значит, грань здесь смотрит в воздух.
## Так стыки соседних камней не видны — стена выглядит цельной.
func _exposed(point: Vector2) -> bool:
	if Engine.is_editor_hint():
		return true
	for other in get_tree().get_nodes_in_group("solid"):
		if other != self and Geometry2D.is_point_in_polygon(point, other.polygon):
			return false
	# Ложная стена, пока закрыта, тоже камень: кромки у тайника не рисуем.
	for wall in get_tree().get_nodes_in_group("false_wall"):
		if not wall.opened and wall.covers(point):
			return false
	return true


func _draw() -> void:
	if polygon.size() < 3:
		return
	Art.draw_textured(self, polygon, Art.plaster())
	# Пятна не заходят под ложную стену: иначе на её краю пятно обрежется и выдаст тайник.
	var avoid := []
	if not Engine.is_editor_hint():
		for wall in get_tree().get_nodes_in_group("false_wall"):
			avoid.append(Rect2(wall.global_position, wall.size))
	Art.draw_crumbled(self, polygon, hash(polygon), 1.0, avoid)
	var area := 0.0
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		area += a.x * b.y - b.x * a.y
	var sign := 1.0 if area > 0.0 else -1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(polygon) + 1
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		var length := a.distance_to(b)
		var d := (b - a) / maxf(length, 0.001)
		var normal := Vector2(d.y, -d.x) * sign  # наружу
		var next_rubble := rng.randf_range(8.0, 40.0)
		var t := 0.0
		while t < length:
			var step := minf(2.0, length - t)
			var p := a + d * t
			var q := a + d * (t + step)
			if _exposed((p + q) / 2.0 + normal * 2.0):
				if normal.y < -0.7:
					# Верхняя грань: песок на кромке, осыпавшиеся камешки.
					draw_line(p + Vector2(0, 0.5), q + Vector2(0, 0.5), Art.SAND_LIGHT, 1.0)
					draw_line(p + Vector2(0, 1.5), q + Vector2(0, 1.5), Art.SAND, 1.0)
					draw_line(p + Vector2(0, 2.5), q + Vector2(0, 2.5), Color(0, 0, 0, 0.15), 1.0)
					if t >= next_rubble and t < length - 6.0:
						_pebble(p.round(), rng)
						next_rubble = t + rng.randf_range(25.0, 70.0)
				elif normal.y > 0.7:
					draw_line(p + Vector2(0, -0.5), q + Vector2(0, -0.5), Color(0, 0, 0, 0.35), 1.0)
				else:
					var shift := Vector2(-0.5 * normal.x, 0)
					draw_line(p + shift, q + shift, Color(0, 0, 0, 0.25), 1.0)
			t += step


func _pebble(at: Vector2, rng: RandomNumberGenerator) -> void:
	var big := rng.randf() < 0.35
	var w := 4.0 if big else 2.0
	var h := 2.0 if big else 1.0
	draw_rect(Rect2(at.x, at.y - h, w, h), Color("b08a57"))
	draw_rect(Rect2(at.x, at.y - h, w, 1), Art.SAND_LIGHT)
	if big:
		draw_rect(Rect2(at.x + 4, at.y - 1, 2, 1), Color("8d6c43"))
