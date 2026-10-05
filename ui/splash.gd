extends Node2D
## Экран с логотипом при запуске: знак пирамиды с глазом и название проявляются из темноты,
## затем открывается главное меню. Касание или клавиша — сразу в меню.

const GOLD := Color("e2bf78")
const GOLD_DARK := Color("8a6a3f")
const SAND := Color("c9a35b")

var _alpha := 0.0
var _time := 0.0
var _leaving := false


func _ready() -> void:
	var title := Label.new()
	title.text = "HIDDEN CHAMBERS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(640, 50)
	title.position = Vector2(0, 236)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_constant_override("outline_size", 0)
	add_child(title)
	var tween := create_tween()
	tween.tween_property(self, "_alpha", 1.0, 0.8)
	tween.tween_interval(1.6)
	tween.tween_callback(_leave)


func _process(delta: float) -> void:
	_time += delta
	for child in get_children():
		if child is CanvasItem:
			child.modulate.a = _alpha
	queue_redraw()


func _input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventKey) and event.pressed:
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	var tween := create_tween()
	tween.tween_property(self, "_alpha", 0.0, 0.4)
	tween.tween_callback(Game.go_title)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("0f0b08"))
	var a := _alpha
	var c := Vector2(320, 140)
	# Мягкое сияние за знаком.
	for k in 6:
		draw_circle(c + Vector2(0, 10), 90.0 - k * 12.0, Color(1, 0.75, 0.4, 0.035 * a))
	# Ступенчатая пирамида из пиксельных уступов.
	var steps := 6
	for i in steps:
		var w := 32.0 + i * 24.0
		var y := c.y - 50.0 + i * 16.0
		var r := Rect2(c.x - w / 2, y, w, 16)
		draw_rect(r, Color(SAND, a))
		draw_rect(Rect2(r.position, Vector2(w, 2)), Color(GOLD.lightened(0.2), a))
		draw_rect(Rect2(r.position + Vector2(0, 14), Vector2(w, 2)), Color(GOLD_DARK, a))
	# Вход в пирамиду — тёмный проём со светом внутри.
	draw_rect(Rect2(c.x - 9, c.y + 18, 18, 28), Color(Color("1a120c"), a))
	var flicker := 0.7 + 0.3 * sin(_time * 7.0)
	draw_rect(Rect2(c.x - 5, c.y + 26, 10, 20), Color(1, 0.8, 0.45, 0.5 * a * flicker))
	# Глаз над пирамидой.
	var e := c + Vector2(0, -78)
	draw_colored_polygon(PackedVector2Array([e + Vector2(-22, 0), e + Vector2(-8, -9), e + Vector2(8, -9), e + Vector2(22, 0), e + Vector2(8, 9), e + Vector2(-8, 9)]), Color(GOLD, a))
	draw_circle(e, 6.0, Color(Color("1a120c"), a))
	draw_circle(e + Vector2(-2, -2), 2.0, Color(1, 0.95, 0.8, a))
	draw_line(e + Vector2(0, 9), e + Vector2(-4, 20), Color(GOLD, a), 2.0)
	draw_line(e + Vector2(-4, 20), e + Vector2(2, 22), Color(GOLD, a), 2.0)
	# Тонкая линия под названием.
	draw_rect(Rect2(210, 282, 220, 1), Color(GOLD_DARK, a))
