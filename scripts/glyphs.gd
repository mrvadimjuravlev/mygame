@tool
extends Node2D
## Панель с высеченными иероглифами на стене. Чистая красота.
## Начало координат — левый верхний угол панели.

@export var columns := 3
## Какие знаки и в каком порядке: eye, ankh, bird, wave, sun, reed.
@export var signs := PackedStringArray(["eye", "ankh", "bird", "wave", "sun", "reed"])

const CUT := Color("17110c")
const EDGE := Color("4a3a2a")
const PANEL := Color("3b2d20")


func _draw() -> void:
	var rows := ceili(float(signs.size()) / columns)
	var size := Vector2(columns * 16 + 4, rows * 18 + 4)
	draw_rect(Rect2(Vector2.ZERO, size), PANEL)
	draw_rect(Rect2(Vector2.ZERO, size), CUT, false, 1.0)
	for i in signs.size():
		var at := Vector2(4 + (i % columns) * 16, 4 + (i / columns) * 18)
		_sign(signs[i], at)


func _cut(at: Vector2, x: float, y: float, w: float, h: float) -> void:
	# Резьба: тёмная выемка и светлый нижний край.
	draw_rect(Rect2(at + Vector2(x, y), Vector2(w, h)), CUT)
	draw_rect(Rect2(at + Vector2(x, y + h), Vector2(w, 1)), EDGE)


func _sign(name: String, a: Vector2) -> void:
	match name:
		"eye":
			_cut(a, 1, 4, 10, 1); _cut(a, 0, 6, 12, 1); _cut(a, 4, 5, 3, 3); _cut(a, 3, 9, 1, 4); _cut(a, 6, 9, 4, 1)
		"ankh":
			_cut(a, 4, 0, 4, 1); _cut(a, 3, 1, 1, 4); _cut(a, 8, 1, 1, 4); _cut(a, 4, 5, 4, 1)
			_cut(a, 1, 7, 10, 1); _cut(a, 5, 6, 2, 8)
		"bird":
			_cut(a, 7, 1, 3, 3); _cut(a, 10, 2, 2, 1); _cut(a, 3, 4, 7, 4); _cut(a, 0, 6, 3, 1); _cut(a, 5, 8, 1, 4); _cut(a, 7, 8, 1, 4)
		"wave":
			for k in 3:
				_cut(a, 0, 2 + k * 4, 3, 1); _cut(a, 3, 1 + k * 4, 3, 1); _cut(a, 6, 2 + k * 4, 3, 1); _cut(a, 9, 1 + k * 4, 3, 1)
		"sun":
			_cut(a, 3, 3, 6, 6); _cut(a, 5, 0, 2, 1); _cut(a, 5, 11, 2, 1); _cut(a, 0, 5, 1, 2); _cut(a, 11, 5, 1, 2)
		"reed":
			_cut(a, 5, 2, 2, 11); _cut(a, 3, 1, 2, 3); _cut(a, 7, 4, 3, 2)
