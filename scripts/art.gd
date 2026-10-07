extends RefCounted
## Пиксель-арт пирамиды, нарисованный кодом: текстуры песчаника и стены фона.
## Текстуры собираются один раз и кэшируются. Один пиксель текстуры = один пиксель игры.

const SAND_LIGHT := Color("e2bf78")
const SAND := Color("c9a35b")
const MORTAR := Color("5a4129")

static var _bricks: ImageTexture
static var _back: ImageTexture
static var _plaster: ImageTexture


## Кладка из песчаника для стен, пола и платформ (64x32, бесшовно).
static func bricks() -> ImageTexture:
	if _bricks:
		return _bricks
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var img := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	img.fill(MORTAR)
	var bases := [Color("c39a5e"), Color("b88f55"), Color("cca466"), Color("b08750"), Color("c79e60")]
	for row in 4:
		var offset := 8 if row % 2 == 1 else 0
		for col in 5:
			var x0 := col * 16 - offset
			var base: Color = bases[rng.randi() % bases.size()]
			for y in range(1, 8):
				for x in range(1, 16):
					var px := posmod(x0 + x, 64)
					var c := base
					if y == 1:
						c = base.lightened(0.14)       # верхняя грань кирпича светлее
					elif y == 7:
						c = base.darkened(0.16)        # нижняя — в тени
					var n := rng.randf()
					if n < 0.12:
						c = c.darkened(0.08)
					elif n < 0.2:
						c = c.lightened(0.06)
					img.set_pixel(px, row * 8 + y, c)
			# Изредка — трещина или выщербина.
			if rng.randf() < 0.3:
				var cx := rng.randi_range(3, 12)
				var cy := rng.randi_range(2, 5)
				for k in 3:
					img.set_pixel(posmod(x0 + cx + (k % 2), 64), row * 8 + cy + k, base.darkened(0.3))
	_bricks = ImageTexture.create_from_image(img)
	return _bricks


## Тёмная стена в глубине: крупные блоки, низкий контраст (64x64, бесшовно).
static func back_wall() -> ImageTexture:
	if _back:
		return _back
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color("140e0a"))
	for row in 4:
		var offset := 16 if row % 2 == 1 else 0
		for col in 3:
			var x0 := col * 32 - offset
			var base := Color("241a12").lerp(Color("1c140e"), rng.randf())
			for y in range(1, 16):
				for x in range(1, 32):
					var c := base
					if y == 1:
						c = base.lightened(0.07)
					var n := rng.randf()
					if n < 0.1:
						c = c.darkened(0.12)
					elif n < 0.14:
						c = c.lightened(0.05)
					img.set_pixel(posmod(x0 + x, 64), row * 16 + y, c)
	_back = ImageTexture.create_from_image(img)
	return _back


## Залить прямоугольник кладкой так, чтобы швы совпали с соседними стенами
## (координаты текстуры берутся мировые). Для люков и ложных стен.
static func draw_bricks_rect(canvas: CanvasItem, rect: Rect2, modulate := Color.WHITE) -> void:
	var tex := bricks()
	var pts := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var uvs := PackedVector2Array()
	var origin := canvas.get_global_transform().origin
	for p in pts:
		uvs.append((p + origin) / Vector2(tex.get_size()))
	canvas.draw_colored_polygon(pts, modulate, uvs, tex)


## Мягкое круглое пятно света для факелов и героя.
static func light_texture(size := 256) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.45))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	return t


## Гладкий старый камень (штукатурка по кладке): пятнистый, с мелкими крапинками (128x128, бесшовно).
static func plaster() -> ImageTexture:
	if _plaster:
		return _plaster
	var noise := FastNoiseLite.new()
	noise.seed = 3
	noise.frequency = 0.035
	noise.fractal_octaves = 3
	var img := noise.get_seamless_image(128, 128)
	img.convert(Image.FORMAT_RGBA8)
	var tones := [Color("a98457"), Color("b8915f"), Color("c39c67"), Color("cca46d")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for y in 128:
		for x in 128:
			var v := img.get_pixel(x, y).r
			var i := clampi(int(v * 4.0), 0, 3)  # 4 тона: пиксельная ступенчатость
			var c: Color = tones[i]
			var n := rng.randf()
			if n < 0.06:
				c = c.darkened(0.12)
			elif n < 0.09:
				c = c.lightened(0.08)
			img.set_pixel(x, y, c)
	_plaster = ImageTexture.create_from_image(img)
	return _plaster


## Залить многоугольник текстурой в мировых координатах (швы и пятна совпадают у соседей).
## Текстура привязана к миру, чтобы соседние камни сходились без шва. uv_origin задаёт привязку
## вручную (камень рисует свою текстуру в своих координатах, чтобы она ехала вместе с ним).
static func draw_textured(canvas: CanvasItem, polygon: PackedVector2Array, tex: Texture2D, modulate := Color.WHITE, uv_origin = null) -> void:
	var origin: Vector2 = canvas.get_global_transform().origin if uv_origin == null else uv_origin
	var uvs := PackedVector2Array()
	for p in polygon:
		uvs.append((p + origin) / Vector2(tex.get_size()))
	canvas.draw_colored_polygon(polygon, modulate, uvs, tex)


## Старина: местами штукатурка осыпалась неровными пятнами, под ней видна кладка.
## Пятна целиком внутри камня (inner — многоугольник, в котором им можно быть).
## Расположение случайное, но одинаковое при каждом запуске (seed).
## avoid — прямоугольники (в координатах canvas), куда пятна заходить не должны.
static func draw_crumbled(canvas: CanvasItem, polygon: PackedVector2Array, seed: int, alpha := 1.0, avoid: Array = [], uv_origin = null) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var box := Rect2(polygon[0], Vector2.ZERO)
	for p in polygon:
		box = box.expand(p)
	var shrunk := Geometry2D.offset_polygon(polygon, -4.0)
	if shrunk.is_empty():
		return
	var inner: PackedVector2Array = shrunk[0]
	var count := int(box.get_area() / 9000.0) + 1
	for i in count:
		for attempt in 12:
			# Крупные пятна; если не влезает — пробуем меньше.
			var scale := 1.0 - attempt * 0.06
			var rx := rng.randf_range(24.0, 46.0) * scale
			var ry := clampf(rx * rng.randf_range(0.55, 0.8), 12.0, 30.0)
			var center := Vector2(rng.randf_range(box.position.x, box.end.x), rng.randf_range(box.position.y + 10.0, box.end.y))
			var blob := _blob(center, rx, ry, rng)
			if not _poly_inside(blob, inner) or _touches(blob, avoid):
				continue
			_patch(canvas, blob, alpha, uv_origin)
			break


static func _blob(center: Vector2, rx: float, ry: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	# Неровное пятно, вершины на пиксельной сетке через 2 px — рваный пиксельный край.
	var pts := PackedVector2Array()
	var n := rng.randi_range(12, 18)
	for k in n:
		var a := TAU * k / n + rng.randf_range(-0.12, 0.12)
		var r := rng.randf_range(0.8, 1.08)
		var p := center + Vector2(cos(a) * rx, sin(a) * ry) * r
		pts.append((p / 2.0).round() * 2.0)
	return pts


static func _touches(poly: PackedVector2Array, rects: Array) -> bool:
	var box := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		box = box.expand(p)
	for r in rects:
		if (r as Rect2).grow(3.0).intersects(box):
			return true
	return false


static func _poly_inside(poly: PackedVector2Array, container: PackedVector2Array) -> bool:
	for p in poly:
		if not Geometry2D.is_point_in_polygon(p, container):
			return false
	return true


static func _patch(canvas: CanvasItem, blob: PackedVector2Array, alpha: float, uv_origin = null) -> void:
	# Край штукатурки: светлый скол снизу-справа, тёмная тень сверху-слева, внутри кладка.
	var rim := Geometry2D.offset_polygon(blob, 2.0)
	if not rim.is_empty():
		var lit: PackedVector2Array = rim[0]
		var moved := PackedVector2Array()
		for p in lit:
			moved.append(p + Vector2(1, 1))
		canvas.draw_colored_polygon(moved, Color(SAND_LIGHT, alpha))
	var edge := Geometry2D.offset_polygon(blob, 1.0)
	if not edge.is_empty():
		canvas.draw_colored_polygon(edge[0], Color("4a3420", alpha))
	draw_textured(canvas, blob, bricks(), Color(0.86, 0.8, 0.76, alpha), uv_origin)
	# Тень от верхнего края штукатурки на кирпичах.
	var shade := PackedVector2Array()
	for p in blob:
		shade.append(p + Vector2(0, 2))
	var clip := Geometry2D.clip_polygons(blob, shade)
	for c in clip:
		canvas.draw_colored_polygon(c, Color(0.1, 0.06, 0.03, 0.45 * alpha))
