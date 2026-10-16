extends Control
## Фон экрана выбора уровней в стиле локации: свой оттенок камня и детали по краям экрана,
## чтобы не мешать сетке уровней в середине. Рисуется кодом, кое-что слегка движется.

const Art := preload("res://scripts/art.gd")

## Цвет камня локации: им заливается фон, а тёмная кладка ложится сверху полупрозрачной.
const STONE := {
	"pyramid": Color("6e5232"),
	"dungeon": Color("303844"),
	"castle": Color("43444f"),
	"temple": Color("22494a"),
}

var theme_id := "pyramid"
var _time := 0.0


func _ready() -> void:
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	# Рельефы пирамиды неподвижны — рисуем их один раз: перерисовка каждый кадр
	# тормозила листание уровней. В других локациях есть движение, там перерисовываем.
	if theme_id == "pyramid":
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), STONE.get(theme_id, Color("4a3828")))
	if theme_id == "pyramid":
		# В пирамиде гладкий тёсаный песчаник — в нём высечены рельефы.
		draw_rect(Rect2(Vector2.ZERO, size), SAND_WALL)
		draw_texture_rect(Art.plaster(), Rect2(Vector2.ZERO, size), true, Color(1, 1, 1, 0.22))
		# Стыки больших плит.
		for y in [120.0, 240.0]:
			draw_line(Vector2(0, y), Vector2(640, y), Color(CUT_SHADOW, 0.35), 1.0)
		for x in [210.0, 430.0]:
			draw_line(Vector2(x, 18), Vector2(x, 342), Color(CUT_SHADOW, 0.25), 1.0)
	else:
		draw_texture_rect(Art.back_wall(), Rect2(Vector2.ZERO, size), true, Color(1, 1, 1, 0.6))
	match theme_id:
		"pyramid":
			_draw_pyramid()
		"dungeon":
			_draw_dungeon()
		"castle":
			_draw_castle()
		"temple":
			_draw_temple()
	# Затемнение к краям: середина с уровнями светлее.
	for k in 6:
		var a := 0.07
		draw_rect(Rect2(0, 0, 14 + k * 12, 360), Color(0, 0, 0, a))
		draw_rect(Rect2(640 - 14 - k * 12, 0, 14 + k * 12, 360), Color(0, 0, 0, a))


# --- Пирамида: рельефы, высеченные в песчанике -------------------------------------
# Рисунки не нарисованы, а вырезаны в камне: углубление чуть темнее стены, свет падает
# сверху-слева — у верхнего-левого края выреза тень, у нижнего-правого светлый скол.

const SAND_WALL := Color("8a6e4c")
const CUT_FILL := Color("6b543a")
const CUT_SHADOW := Color("3e2f1f")
const CUT_LIGHT := Color("b89a70")
## Насколько видна тень и скол по краю выреза.
const CUT_EDGE := 1.2


func _draw_pyramid() -> void:
	# Полосы с иероглифами, высеченные вдоль верха и низа стены.
	for y in [4.0, 344.0]:
		_carve(func(_c: Color) -> void: pass, func(c: Color) -> void:
			draw_line(Vector2(0, y), Vector2(640, y), c, 1.0)
			draw_line(Vector2(0, y + 12), Vector2(640, y + 12), c, 1.0)
			for i in 32:
				_glyph(Vector2(10 + i * 20, y + 6), i % 4, c))
	# Рамки-ниши для рельефов по бокам.
	for r in [Rect2(8, 62, 82, 228), Rect2(550, 62, 82, 228)]:
		_carve(func(_c: Color) -> void: pass, func(c: Color) -> void:
			draw_rect(r, c, false, 1.5)
			draw_rect(r.grow(-4), c, false, 1.0))
	_carve(_cat_shape.bind(Vector2(49, 66)), _cat_lines.bind(Vector2(49, 66)))
	_carve(_horus_shape.bind(Vector2(591, 104)), _horus_lines.bind(Vector2(591, 104)))
	_carve(_scarab_shape.bind(Vector2(591, 182)), _scarab_lines.bind(Vector2(591, 182)))
	_carve(_ankh_shape.bind(Vector2(591, 256), 1.0), func(_c: Color) -> void: pass)
	_carve(_nile_shape, _nile_lines)


## Высечь рисунок: силуэт вырезом с тенью и сколом по краю, детали — процарапанными линиями.
func _carve(shape: Callable, lines: Callable) -> void:
	draw_set_transform(Vector2(-CUT_EDGE, -CUT_EDGE))
	shape.call(CUT_SHADOW)
	draw_set_transform(Vector2(CUT_EDGE, CUT_EDGE))
	shape.call(CUT_LIGHT)
	draw_set_transform(Vector2.ZERO)
	shape.call(CUT_FILL)
	# Процарапанная линия: светлый край снизу, тёмная борозда.
	draw_set_transform(Vector2(0.8, 0.8))
	lines.call(CUT_LIGHT)
	draw_set_transform(Vector2.ZERO)
	lines.call(CUT_SHADOW)


## Эллипс многоугольником (у CanvasItem нет готового).
func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 20:
		var a := TAU * k / 20.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)


## Кот-сфинкс анфас: лысый, с огромными ушами и морщинками на лбу, в ожерелье.
func _cat_shape(c: Color, top: Vector2) -> void:
	var cx := top.x
	draw_arc(Vector2(cx + 8, top.y + 192), 16.0, 0.1, PI * 0.95, 14, c, 4.0)  # хвост
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 15, top.y + 84), Vector2(cx + 15, top.y + 84),
		Vector2(cx + 30, top.y + 200), Vector2(cx - 30, top.y + 200),
	]), c)
	for s in [-1, 1]:
		_ellipse(Vector2(cx + s * 9, top.y + 199), 7.0, 4.0, c)
	_ellipse(Vector2(cx, top.y + 56), 18.0, 16.0, c)
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 10, top.y + 62), Vector2(cx + 10, top.y + 62), Vector2(cx, top.y + 76)]), c)
	draw_rect(Rect2(cx - 8, top.y + 68, 16, 18), c)  # шея
	for s in [-1, 1]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx + s * 6, top.y + 44), Vector2(cx + s * 28, top.y + 14), Vector2(cx + s * 18, top.y + 56),
		]), c)


func _cat_lines(c: Color, top: Vector2) -> void:
	var cx := top.x
	# Ожерелье в три ряда и подвеска-анх.
	for k in 3:
		draw_arc(Vector2(cx, top.y + 78), 15.0 + k * 4.0, 0.35 + k * 0.05, PI - 0.35 - k * 0.05, 12, c, 1.0)
	_ankh_lines(c, Vector2(cx, top.y + 108), 0.55)
	# Складки кожи на груди и лапы.
	for k in 2:
		draw_arc(Vector2(cx, top.y + 120 + k * 6), 7.0, 0.4, PI - 0.4, 8, c, 1.0)
	for s in [-1, 1]:
		draw_line(Vector2(cx + s * 4, top.y + 134), Vector2(cx + s * 4, top.y + 197), c, 1.0)
		draw_line(Vector2(cx + s * 14, top.y + 134), Vector2(cx + s * 15, top.y + 197), c, 1.0)
		for t in 2:
			draw_line(Vector2(cx + s * 9 - 2 + t * 4, top.y + 197), Vector2(cx + s * 9 - 2 + t * 4, top.y + 202), c, 1.0)
	# Внутренний контур ушей, морщинки на лбу.
	for s in [-1, 1]:
		draw_polyline(PackedVector2Array([Vector2(cx + s * 10, top.y + 44), Vector2(cx + s * 24, top.y + 22), Vector2(cx + s * 18, top.y + 50)]), c, 1.0)
	for k in 3:
		draw_line(Vector2(cx - 6 + k, top.y + 44 + k * 3), Vector2(cx + 6 - k, top.y + 44 + k * 3), c, 1.0)
	# Миндалевидные глаза с «египетской» стрелкой, зрачок-щель.
	for s in [-1, 1]:
		var e := Vector2(cx + s * 8, top.y + 56)
		draw_arc(e + Vector2(0, 2), 5.5, PI * 1.1, PI * 1.9, 8, c, 1.2)
		draw_arc(e - Vector2(0, 2), 5.5, PI * 0.1, PI * 0.9, 8, c, 1.2)
		draw_line(e + Vector2(0, -2.5), e + Vector2(0, 2.5), c, 1.5)
		draw_line(e + Vector2(s * 5, 0), e + Vector2(s * 9, -2), c, 1.2)
	# Нос, рот, усы.
	draw_polyline(PackedVector2Array([Vector2(cx - 3, top.y + 63), Vector2(cx + 3, top.y + 63), Vector2(cx, top.y + 66), Vector2(cx - 3, top.y + 63)]), c, 1.0)
	draw_line(Vector2(cx, top.y + 66), Vector2(cx, top.y + 69), c, 1.0)
	draw_arc(Vector2(cx - 2, top.y + 69), 2.0, 0.2, PI - 0.2, 6, c, 1.0)
	draw_arc(Vector2(cx + 2, top.y + 69), 2.0, 0.2, PI - 0.2, 6, c, 1.0)
	for s in [-1, 1]:
		draw_line(Vector2(cx + s * 7, top.y + 66), Vector2(cx + s * 16, top.y + 64), c, 1.0)
		draw_line(Vector2(cx + s * 7, top.y + 68), Vector2(cx + s * 16, top.y + 69), c, 1.0)


## Око Гора (уджат): высечены бровь и зрачок, остальное — глубокие борозды.
func _horus_shape(c: Color, at: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(-26, -14), at + Vector2(22, -16), at + Vector2(24, -11), at + Vector2(-24, -9)]), c)
	draw_circle(at + Vector2(2, 0), 6.0, c)


func _horus_lines(c: Color, at: Vector2) -> void:
	draw_arc(at + Vector2(0, 4), 19.0, PI * 1.08, PI * 1.92, 16, c, 2.0)
	draw_arc(at + Vector2(0, -6), 17.0, PI * 0.12, PI * 0.88, 16, c, 2.0)
	draw_line(at + Vector2(17, 0), at + Vector2(30, -1), c, 2.0)
	draw_line(at + Vector2(-2, 9), at + Vector2(-4, 26), c, 2.0)
	draw_line(at + Vector2(8, 8), at + Vector2(14, 20), c, 2.0)
	draw_arc(at + Vector2(20, 24), 6.0, PI, TAU + PI * 0.6, 12, c, 2.0)


## Скарабей, катящий солнечный диск, с расправленными крыльями.
func _scarab_shape(c: Color, at: Vector2) -> void:
	for s in [-1, 1]:
		draw_colored_polygon(PackedVector2Array([
			at + Vector2(s * 8, -4), at + Vector2(s * 36, -12), at + Vector2(s * 20, 10), at + Vector2(s * 8, 8),
		]), c)
	draw_circle(at + Vector2(0, -22), 8.0, c)
	_ellipse(at + Vector2(0, 6), 9.0, 12.0, c)
	_ellipse(at + Vector2(0, -9), 6.0, 4.0, c)


func _scarab_lines(c: Color, at: Vector2) -> void:
	# Перья крыльев.
	for s in [-1, 1]:
		for k in 3:
			draw_line(at + Vector2(s * 10, -2 + k * 3.5), at + Vector2(s * (32 - k * 5), -9 + k * 6), c, 1.0)
	draw_line(at + Vector2(0, -2), at + Vector2(0, 18), c, 1.0)
	draw_line(at + Vector2(-6, -5), at + Vector2(6, -5), c, 1.0)
	for s in [-1, 1]:
		for k in 3:
			draw_line(at + Vector2(s * 9, 2 + k * 6), at + Vector2(s * 15, 4 + k * 7), c, 1.0)


## Анх — знак жизни.
func _ankh_shape(c: Color, at: Vector2, k: float) -> void:
	draw_arc(at + Vector2(0, -12) * k, 6.0 * k, 0, TAU, 12, c, 3.5 * k)
	draw_rect(Rect2(at + Vector2(-2, -6) * k, Vector2(4, 26) * k), c)
	draw_rect(Rect2(at + Vector2(-10, -5) * k, Vector2(20, 4) * k), c)


func _ankh_lines(c: Color, at: Vector2, k: float) -> void:
	draw_arc(at + Vector2(0, -12) * k, 6.0 * k, 0, TAU, 12, c, 1.0)
	draw_line(at + Vector2(0, -6) * k, at + Vector2(0, 20) * k, c, 1.0)
	draw_line(at + Vector2(-10, -4) * k, at + Vector2(10, -4) * k, c, 1.0)


## Нил внизу стены: ладья с солнечным диском, волны, папирус по берегам.
func _nile_shape(c: Color) -> void:
	var y := 326.0
	var bx := 340.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(bx - 46, y - 10), Vector2(bx - 34, y + 2), Vector2(bx + 34, y + 2), Vector2(bx + 46, y - 10),
		Vector2(bx + 30, y - 4), Vector2(bx - 30, y - 4),
	]), c)
	draw_circle(Vector2(bx, y - 15), 8.0, c)
	for x in [156.0, 168.0, 180.0, 500.0, 512.0, 524.0]:
		var h := 20.0 + fmod(x, 7.0) * 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, y - h), Vector2(x - 6, y - h - 8), Vector2(x + 6, y - h - 8)]), c)


func _nile_lines(c: Color) -> void:
	var y := 326.0
	for row in 2:
		for x in range(144, 536, 10):
			draw_line(Vector2(x, y + 5 + row * 5), Vector2(x + 5, y + 3 + row * 5), c, 1.0)
			draw_line(Vector2(x + 5, y + 3 + row * 5), Vector2(x + 10, y + 5 + row * 5), c, 1.0)
	for x in [156.0, 168.0, 180.0, 500.0, 512.0, 524.0]:
		var h := 20.0 + fmod(x, 7.0) * 2.0
		draw_line(Vector2(x, y + 2), Vector2(x, y - h), c, 1.5)
	draw_line(Vector2(298, 322), Vector2(382, 322), c, 1.0)


## Простые иероглифы: анх, глаз, птица, волна.
func _glyph(c: Vector2, kind: int, col: Color) -> void:
	match kind:
		0:
			draw_arc(c + Vector2(0, -2), 2.0, 0, TAU, 8, col, 1.0)
			draw_line(c + Vector2(0, 0), c + Vector2(0, 4), col, 1.0)
			draw_line(c + Vector2(-2, 1), c + Vector2(2, 1), col, 1.0)
		1:
			draw_arc(c, 3.5, PI * 1.1, PI * 1.9, 6, col, 1.0)
			draw_arc(c, 3.5, PI * 0.1, PI * 0.9, 6, col, 1.0)
			draw_rect(Rect2(c - Vector2(1, 1), Vector2(2, 2)), col)
		2:
			draw_line(c + Vector2(-4, 2), c + Vector2(2, 2), col, 1.0)
			draw_line(c + Vector2(2, 2), c + Vector2(3, -3), col, 1.0)
			draw_line(c + Vector2(3, -3), c + Vector2(5, -2), col, 1.0)
		3:
			for k in 3:
				draw_line(c + Vector2(-4 + k * 3, 1), c + Vector2(-3 + k * 3, -1), col, 1.0)


# --- Подземелье: цепи, решётка, капли, лужа -------------------------------------

func _draw_dungeon() -> void:
	var iron := Color("4a4642")
	for chain in [[34.0, 120.0], [64.0, 70.0], [578.0, 90.0], [606.0, 140.0]]:
		var sway := sin(_time * 1.3 + chain[0]) * 1.5
		var n := int(chain[1] / 8.0)
		for k in n:
			var p := Vector2(chain[0] + sway * k / n, k * 8.0 + 4.0)
			if k % 2 == 0:
				draw_arc(p, 3.0, 0, TAU, 8, iron, 2.0)
			else:
				draw_rect(Rect2(p.x - 1, p.y - 4, 2, 8), iron)
		draw_circle(Vector2(chain[0] + sway, n * 8.0 + 6.0), 4.0, iron.lightened(0.15))
	# Окошко с решёткой, в нём холодный свет.
	var win := Rect2(18, 196, 56, 48)
	draw_rect(win, Color("0b0f16"))
	draw_rect(win.grow(-4), Color(0.45, 0.6, 0.85, 0.18))
	for k in 5:
		draw_rect(Rect2(win.position.x + 6 + k * 10, win.position.y, 3, win.size.y), iron)
	draw_rect(Rect2(win.position.x, win.position.y + 20, win.size.x, 3), iron)
	draw_rect(win, Color("2c2a28"), false, 3.0)
	_torch(Vector2(596, 220), Color("ff8a3a"))
	# Мох и капли по верхнему краю.
	var moss := Color(0.3, 0.42, 0.25, 0.8)
	for i in 20:
		var x := 8.0 + i * 33.0
		draw_rect(Rect2(x, 0, 14, 3 + (i * 7) % 6), moss)
	for i in 4:
		var x := 120.0 + i * 130.0
		var t := fmod(_time * 0.6 + i * 0.37, 1.0)
		draw_rect(Rect2(x, 4 + t * 330.0, 2, 3), Color(0.6, 0.75, 0.9, 0.7 * (1.0 - t)))
	# Лужа на полу.
	draw_rect(Rect2(500, 348, 130, 6), Color(0.3, 0.42, 0.55, 0.5))
	draw_rect(Rect2(520, 348, 60, 1), Color(0.7, 0.85, 1.0, 0.4))


# --- Замок: зубцы, знамёна, окна с луной ----------------------------------------

func _draw_castle() -> void:
	var stone := Color("8a8f9a")
	# Зубцы стены на фоне ночного неба.
	draw_rect(Rect2(0, 0, 640, 14), Color("141a2e"))
	for i in 20:
		draw_rect(Rect2(i * 34, 2, 20, 12), stone.darkened(0.3))
	draw_rect(Rect2(0, 14, 640, 4), stone.darkened(0.3))
	# Знамёна по бокам, слегка колышутся.
	_banner(Vector2(26, 70), Color("a83a36"))
	_banner(Vector2(568, 70), Color("a83a36"))
	# Стрельчатые окна с ночным небом.
	for x in [24.0, 576.0]:
		var r := Rect2(x, 248, 40, 52)
		draw_rect(Rect2(r.position.x, r.position.y + 14, r.size.x, r.size.y - 14), Color("141a2e"))
		draw_circle(Vector2(r.get_center().x, r.position.y + 16), 20.0, Color("141a2e"))
		draw_circle(Vector2(r.position.x + 26, r.position.y + 16), 5.0, Color("e8e4c8"))
		draw_rect(Rect2(r.get_center().x - 1, r.position.y, 2, r.size.y), stone.darkened(0.3))
		draw_rect(Rect2(r.position.x, r.position.y + 30, r.size.x, 2), stone.darkened(0.3))
	# Ковёр-дорожка вдоль низа.
	draw_rect(Rect2(0, 348, 640, 12), Color("6e2a28"))
	draw_rect(Rect2(0, 350, 640, 1), Color("e2bf78"))
	draw_rect(Rect2(0, 357, 640, 1), Color("e2bf78"))


func _banner(top_left: Vector2, col: Color) -> void:
	var w := 46.0
	var h := 150.0
	var sway := sin(_time * 1.5 + top_left.x) * 2.0
	draw_rect(Rect2(top_left.x - 4, top_left.y - 4, w + 8, 4), Color("5e4630"))
	draw_colored_polygon(PackedVector2Array([
		top_left, top_left + Vector2(w, 0),
		top_left + Vector2(w + sway, h), top_left + Vector2(w / 2 + sway, h - 18),
		top_left + Vector2(sway, h),
	]), col)
	draw_rect(Rect2(top_left.x + 4, top_left.y, 2, h - 20), Color("e2bf78"))
	draw_rect(Rect2(top_left.x + w - 6, top_left.y, 2, h - 20), Color("e2bf78"))
	var c := top_left + Vector2(w / 2 + sway * 0.5, 50)
	draw_circle(c, 11.0, Color("e2bf78"))
	draw_circle(c, 8.0, col.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(5, 3), c + Vector2(-5, 3)]), Color("e2bf78"))


# --- Затонувший храм: лучи сверху, вода, пузыри, водоросли ----------------------

func _draw_temple() -> void:
	for k in 4:
		var x := 60.0 + k * 150.0 + sin(_time * 0.4 + k) * 10.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 40, 0), Vector2(x - 20, 360), Vector2(x - 70, 360)]), Color(0.7, 0.95, 1.0, 0.05))
	# Колонны по бокам.
	var col := Color("6f968a")
	for x in [20.0, 590.0]:
		draw_rect(Rect2(x - 4, 64, 38, 10), col.lightened(0.1))
		draw_rect(Rect2(x, 74, 30, 270), col)
		for k in 4:
			draw_rect(Rect2(x + 4 + k * 7, 74, 2, 270), col.darkened(0.18))
	# Водоросли у основания.
	for base: Vector2 in [Vector2(70, 360), Vector2(84, 360), Vector2(560, 360), Vector2(574, 360)]:
		var pts := PackedVector2Array()
		for k in 9:
			var y := base.y - k * 9.0
			pts.append(Vector2(base.x + sin(_time * 1.6 + k * 0.6 + base.x) * (k * 0.8), y))
		draw_polyline(pts, Color(0.25, 0.55, 0.35, 0.9), 3.0)
	# Пузыри поднимаются по бокам.
	for i in 8:
		var x := (40.0 if i % 2 == 0 else 600.0) + sin(_time * 2.0 + i) * 4.0 + (i % 3) * 6.0
		var t := fmod(_time * 0.12 + i * 0.13, 1.0)
		draw_arc(Vector2(x, 360.0 - t * 360.0), 2.0 + (i % 3), 0, TAU, 10, Color(0.8, 0.95, 1.0, 0.6 * (1.0 - t)), 1.0)
	# Вода у пола с бегущими волнами.
	draw_rect(Rect2(0, 320, 640, 40), Color(0.15, 0.4, 0.55, 0.45))
	for row in 3:
		var y := 324.0 + row * 12.0
		var shift := fmod(_time * (10.0 + row * 4.0), 24.0)
		for x in range(-24, 664, 24):
			draw_line(Vector2(x + shift, y), Vector2(x + shift + 10, y - 2), Color(0.6, 0.85, 0.95, 0.5), 1.0)


# --- Общее ------------------------------------------------------------------------

## Факел на стене: держатель, мерцающее пламя и пятно света.
func _torch(at: Vector2, flame: Color) -> void:
	var flicker := 1.0 + 0.08 * sin(_time * 11.0 + at.x) + 0.05 * sin(_time * 17.0)
	for k in 4:
		draw_circle(at + Vector2(0, -12), (46.0 - k * 10.0) * flicker, Color(flame, 0.05))
	draw_rect(Rect2(at.x - 2, at.y - 6, 4, 18), Color("5e4630"))
	draw_rect(Rect2(at.x - 5, at.y - 8, 10, 4), Color("3a2a1a"))
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-5, -9), at + Vector2(5, -9), at + Vector2(1, -9 - 14 * flicker),
	]), flame)
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-2, -9), at + Vector2(2, -9), at + Vector2(0, -9 - 7 * flicker),
	]), Color("ffe7a3"))
