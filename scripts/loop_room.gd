extends Node2D
## «Та же комната»: из комнаты две двери, и обе ведут обратно в неё же.
## Каждый раз в комнате может появиться одна странность (дочерние узлы Odd*: лишний кувшин,
## другие знаки…; у странности может быть пара Normal* — то, что она заменяет).
## Заметил странность — иди назад (левая дверь), всё как было — вперёд (правая).
## GOAL верных дверей подряд — и последняя выводит из уровня. Ошибка — счёт с нуля.
## Начало координат — левый верхний угол уровня.

const GOAL := 4
const Art := preload("res://scripts/art.gd")

## Куда встаёт герой, войдя в комнату.
@export var start := Vector2(320, 280)
## Где на стене табличка со счётом шагов.
@export var plaque := Vector2(320, 96)

var stage := 0
## Какая странность сейчас в комнате ("" — никакой).
var anomaly := ""
var _names: Array[String] = []
var _fade: ColorRect
var _busy := false
var _bag := []


func _ready() -> void:
	for child in get_children():
		if child.name.begins_with("Odd"):
			_names.append(child.name.trim_prefix("Odd"))
	var layer := CanvasLayer.new()
	layer.layer = 6
	_fade = ColorRect.new()
	_fade.size = Vector2(640, 360)
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	add_child(layer)
	_new_round(true)


func _new_round(first: bool) -> void:
	# Первая комната всегда обычная: её надо запомнить. Дальше — странность примерно через раз,
	# и каждая странность не повторяется, пока не покажутся все.
	anomaly = ""
	if not first and randf() < 0.55:
		if _bag.is_empty():
			_bag = _names.duplicate()
			_bag.shuffle()
		anomaly = _bag.pop_back()
	for n in _names:
		var odd := get_node("Odd" + n) as CanvasItem
		odd.visible = n == anomaly
		var normal := get_node_or_null("Normal" + n) as CanvasItem
		if normal:
			normal.visible = n != anomaly
	queue_redraw()


## Герой вошёл в дверь: back — левая («назад»), иначе правая («вперёд»).
func choose(back: bool) -> void:
	if _busy:
		return
	var right := back == (anomaly != "")
	if right and stage + 1 >= GOAL:
		Sfx.play("exit")
		Game.next_level()
		return
	_busy = true
	stage = stage + 1 if right else 0
	Sfx.play("door" if right else "flee")
	var hero := get_tree().get_first_node_in_group("hero") as Node2D
	hero.frozen = true
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.35)
	tween.tween_callback(func() -> void:
		hero.global_position = start
		hero.velocity = Vector2.ZERO
		_new_round(false))
	tween.tween_property(_fade, "color:a", 0.0, 0.35)
	tween.tween_callback(func() -> void:
		hero.frozen = false
		_busy = false)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, plaque + Vector2(-200, 36), Game.t("Странное — назад. Всё как было — вперёд."), HORIZONTAL_ALIGNMENT_CENTER, 400, 12, Color(0.85, 0.78, 0.6, 0.85))
	# Табличка со счётом: зажжённые глаза — сколько комнат пройдено верно.
	var p := plaque
	draw_rect(Rect2(p + Vector2(-48, -14), Vector2(96, 28)), Color("3a3430"))
	draw_rect(Rect2(p + Vector2(-48, -14), Vector2(96, 28)), Color("6a5e50"), false, 1.0)
	for i in GOAL:
		var c := p + Vector2(-33 + i * 22, 0)
		draw_circle(c, 7.0, Color("1c1916"))
		draw_circle(c, 5.0, Color(1.0, 0.8, 0.3) if i < stage else Color("4a4038"))
