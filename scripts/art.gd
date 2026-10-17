extends RefCounted
## Пиксель-арт пирамиды, нарисованный кодом: текстуры песчаника и стены фона.
## Текстуры собираются один раз и кэшируются. Один пиксель текстуры = один пиксель игры.

const SAND_LIGHT := Color("e2bf78")
const SAND := Color("c9a35b")
const MORTAR := Color("5a4129")

static var _bricks: ImageTexture
static var _back: ImageTexture
static var _plaster: ImageTexture
static var _blocks: ImageTexture
static var _back_blocks: ImageTexture

## Ряды кладки из больших блоков (128x128, бесшовно): длины блоков в ряду (в сумме 128) и сдвиг ряда.
const BLOCK_ROWS := [[[64, 64], 0], [[40, 88], 24], [[56, 72], 52], [[48, 80], 88]]
const BLOCK_H := 32


## Локация, к которой относится узел: по корню сцены уровня (у него есть theme). Вне уровня — пирамида.
static func theme_of(node: Node) -> String:
	var root: Node = node.owner
	if root == null and node.is_inside_tree():
		root = node.get_tree().current_scene
	if root and root is Node2D and "theme" in root:
		return str(root.theme)
	return "pyramid"


## Камень стен и пола для узла: в пирамиде — большие тёсаные блоки, в других локациях — старая штукатурка.
static func wall_texture(node: Node) -> Texture2D:
	return blocks() if theme_of(node) == "pyramid" else plaster()


## Стена в глубине для узла: в пирамиде — крупные тёмные блоки, в других локациях — прежняя кладка.
static func back_texture(node: Node) -> Texture2D:
	return back_blocks() if theme_of(node) == "pyramid" else back_wall()


## Большие тёсаные блоки песчаника для стен, пола и платформ пирамиды (128x128, бесшовно).
static func blocks() -> ImageTexture:
	if not _blocks:
		_blocks = _make_blocks(31, [Color("c39c67"), Color("b8915f"), Color("cca46d"), Color("b38a58"), Color("c8a16a")], Color("4f3a24"), 0.13, true)
	return _blocks


## Те же большие блоки, но тёмные и неконтрастные — стена в глубине зала пирамиды (128x128).
static func back_blocks() -> ImageTexture:
	if not _back_blocks:
		_back_blocks = _make_blocks(37, [Color("261b13"), Color("221811"), Color("2a1e15"), Color("1f160f")], Color("120c08"), 0.06, false)
	return _back_blocks


static func _make_blocks(seed: int, tones: Array, joint: Color, contrast: float, chips: bool) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 0.06
	noise.fractal_octaves = 3
	var grain := noise.get_seamless_image(128, 128)
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(joint)
	for row in BLOCK_ROWS.size():
		var widths: Array = BLOCK_ROWS[row][0]
		var x0: int = BLOCK_ROWS[row][1]
		var y0 := row * BLOCK_H
		for w: int in widths:
			var base: Color = tones[rng.randi() % tones.size()]
			for y in range(1, BLOCK_H):
				for x in range(1, w):
					var px := posmod(x0 + x, 128)
					var py := y0 + y
					# Зерно камня: 4 ступени яркости — пиксельная фактура, а не размытый шум.
					var g := grain.get_pixel(px, py).r
					var c := base.lightened(contrast * 0.6) if g > 0.62 else (base.darkened(contrast * 0.5) if g < 0.38 else base)
					if y == 1:
						c = base.lightened(contrast * 1.4)   # верх блока на свету
					elif y == 2:
						c = c.lightened(contrast * 0.5)
					elif y == BLOCK_H - 1:
						c = base.darkened(contrast * 2.0)    # низ в тени
					elif x == 1:
						c = c.lightened(contrast * 0.7)
					elif x == w - 1:
						c = c.darkened(contrast * 1.3)
					var n := rng.randf()
					if n < 0.025:
						c = c.darkened(contrast * 2.2)       # поры
					img.set_pixel(px, py, c)
			if chips:
				# Скол угла или трещина — у каждого третьего блока.
				var roll := rng.randf()
				if roll < 0.18:
					var cx := 1 if rng.randf() < 0.5 else w - 4
					var cy := 1 if rng.randf() < 0.5 else BLOCK_H - 4
					for k in 3:
						for m in 3 - k:
							img.set_pixel(posmod(x0 + cx + (m if cx == 1 else 2 - m), 128), y0 + cy + (k if cy == 1 else 2 - k), joint.lightened(0.15))
				elif roll < 0.33:
					var tx := rng.randi_range(6, w - 8)
					var ty := rng.randi_range(4, BLOCK_H - 12)
					for k in rng.randi_range(5, 9):
						img.set_pixel(posmod(x0 + tx + (k + rng.randi_range(0, 1)) / 2, 128), y0 + ty + k, base.darkened(contrast * 3.0))
			x0 += w
	return ImageTexture.create_from_image(img)


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


## Каменная плита платформы (рушащейся, исчезающей, движущейся): камень локации, песок на верхней
## кромке, тень снизу. Текстура в координатах плиты — едет вместе с ней.
static func draw_slab(canvas: CanvasItem, rect: Rect2, modulate := Color.WHITE) -> void:
	var poly := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	draw_textured(canvas, poly, wall_texture(canvas), modulate, Vector2(37, 11))
	var a := modulate.a
	var top := rect.position.y
	canvas.draw_line(Vector2(rect.position.x, top + 0.5), Vector2(rect.end.x, top + 0.5), Color(SAND_LIGHT, a), 1.0)
	canvas.draw_line(Vector2(rect.position.x, top + 1.5), Vector2(rect.end.x, top + 1.5), Color(SAND, a), 1.0)
	canvas.draw_line(Vector2(rect.position.x, rect.end.y - 0.5), Vector2(rect.end.x, rect.end.y - 0.5), Color(0, 0, 0, 0.4 * a), 1.0)
	for x in [rect.position.x + 0.5, rect.end.x - 0.5]:
		canvas.draw_line(Vector2(x, top + 2), Vector2(x, rect.end.y), Color(0, 0, 0, 0.3 * a), 1.0)


## Ряд шипов остриями в сторону dir (вниз — Vector2.DOWN) вдоль отрезка from–to.
static func draw_spike_row(canvas: CanvasItem, from: Vector2, to: Vector2, dir: Vector2, height := 12.0) -> void:
	var along := (to - from).normalized()
	var length := from.distance_to(to)
	var x := 0.0
	while x + 10.0 <= length + 0.5:
		var a := from + along * x
		var b := from + along * (x + 10.0)
		var tip := (a + b) / 2.0 + dir * height
		canvas.draw_colored_polygon(PackedVector2Array([a, tip, b]), Color("8d8679"))
		canvas.draw_colored_polygon(PackedVector2Array([(a + b) / 2.0, tip, b]), Color("5f594f"))
		canvas.draw_line(tip - dir * 1.0, tip - dir * 4.0, Color("7a2a20"), 2.0)
		x += 10.0


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
