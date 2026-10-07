@tool
extends StaticBody2D
## Векторная геометрия уровня: произвольный многоугольник без сетки.
## Рисуется старым камнем, местами осыпавшимся до кладки; грани, смотрящие вверх, — песчаный край, вниз — тень.
## Форма задаётся дочерним CollisionPolygon2D «Shape»: в редакторе выдели его и двигай точки мышью
## или весь «Shape» целиком, камень перерисуется сразу.

const Art := preload("res://scripts/art.gd")

@export var polygon := PackedVector2Array():
	set(value):
		polygon = value
		# Правка polygon в инспекторе доходит до «Shape», если тот не сдвинут.
		var shape := _shape()
		if shape and shape.position == Vector2.ZERO and shape.polygon != value:
			shape.polygon = value
		queue_redraw()
@export var color := Color("8a6a43"):
	set(value):
		color = value
		queue_redraw()


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var shape := _shape()
	if shape == null:
		# Старые сцены без «Shape»: форма только в polygon.
		shape = CollisionPolygon2D.new()
		shape.name = "Shape"
		shape.polygon = polygon
		add_child(shape)
	_sync()
	set_process(Engine.is_editor_hint())
	if Engine.is_editor_hint():
		return
	add_to_group("solid")


func _shape() -> CollisionPolygon2D:
	return get_node_or_null("Shape") as CollisionPolygon2D


## Форма берётся из «Shape» с учётом его сдвига. Сам «Shape» здесь не трогаем: редактор, пока тянет
## узел мышью, каждый кадр ставит ему положение от точки захвата, и любая наша правка складывалась бы с ней.
func _sync() -> void:
	var shape := _shape()
	if shape == null:
		return
	var points := PackedVector2Array()
	for p in shape.polygon:
		points.append(p + shape.position)
	if points != polygon:
		polygon = points


func _process(_delta: float) -> void:
	# В редакторе следим за точками «Shape», чтобы камень перерисовывался во время правки.
	if Engine.is_editor_hint():
		_sync()


## Точка не внутри другого камня: значит, грань здесь смотрит в воздух.
## Так стыки соседних камней не видны — стена выглядит цельной.
func _exposed(point: Vector2) -> bool:
	if Engine.is_editor_hint():
		return true
	for other in get_tree().get_nodes_in_group("solid"):
		if other != self and Geometry2D.is_point_in_polygon(other.to_local(to_global(point)), other.polygon):
			return false
	# Ложная стена, пока закрыта, тоже камень: кромки у тайника не рисуем.
	for wall in get_tree().get_nodes_in_group("false_wall"):
		if not wall.opened and wall.covers(point):
			return false
	return true


func _draw() -> void:
	# Рисуем форму «Shape» в его собственных координатах и сдвигаем целиком: так кладка, пятна и камешки
	# едут вместе с камнем, когда его тянут в редакторе, а не остаются на месте и не перескакивают.
	var shape := _shape()
	var base: PackedVector2Array = shape.polygon if shape else polygon
	var offset: Vector2 = shape.position if shape else Vector2.ZERO
	if base.size() < 3:
		return
	draw_set_transform(offset)
	Art.draw_textured(self, base, Art.plaster(), Color.WHITE, Vector2.ZERO)
	# Пятна не заходят под ложную стену: иначе на её краю пятно обрежется и выдаст тайник.
	var avoid := []
	if not Engine.is_editor_hint():
		for wall in get_tree().get_nodes_in_group("false_wall"):
			avoid.append(Rect2(wall.global_position - offset, wall.size))
	Art.draw_crumbled(self, base, hash(base), 1.0, avoid, Vector2.ZERO)
	var area := 0.0
	for i in base.size():
		var a := base[i]
		var b := base[(i + 1) % base.size()]
		area += a.x * b.y - b.x * a.y
	var sign := 1.0 if area > 0.0 else -1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(base) + 1
	for i in base.size():
		var a := base[i]
		var b := base[(i + 1) % base.size()]
		var length := a.distance_to(b)
		var d := (b - a) / maxf(length, 0.001)
		var normal := Vector2(d.y, -d.x) * sign  # наружу
		var next_rubble := rng.randf_range(8.0, 40.0)
		var t := 0.0
		while t < length:
			var step := minf(2.0, length - t)
			var p := a + d * t
			var q := a + d * (t + step)
			if _exposed((p + q) / 2.0 + normal * 2.0 + offset):
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
	draw_set_transform(Vector2.ZERO)


func _pebble(at: Vector2, rng: RandomNumberGenerator) -> void:
	var big := rng.randf() < 0.35
	var w := 4.0 if big else 2.0
	var h := 2.0 if big else 1.0
	draw_rect(Rect2(at.x, at.y - h, w, h), Color("b08a57"))
	draw_rect(Rect2(at.x, at.y - h, w, 1), Art.SAND_LIGHT)
	if big:
		draw_rect(Rect2(at.x + 4, at.y - 1, 2, 1), Color("8d6c43"))
