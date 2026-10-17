@tool
extends Node2D
## Два стража-шакала у двух дверей. Одна дверь — выход, за другой ловушка.
## Один страж всегда лжёт, другой всегда говорит правду; кто есть кто и какая дверь верная,
## решается заново при каждом входе в зал. Задать можно только один вопрос одному стражу.
## Верный вопрос — «какую дверь назвал бы другой страж»: оба укажут на ловушку.
## doors — две двери (выход и ловушка) у краёв зала; стражи стоят перед ними, ближе к середине.
## Начало координат — не важно: всё привязано к дверям.

const PopupScript := preload("res://scripts/riddle_popup.gd")
const QUESTIONS := [
	"Ты говоришь правду?",
	"Твоя дверь ведёт дальше?",
	"Какую дверь назвал бы выходом другой страж?",
	"Кто из вас лжец?",
]
const INTRO := "Одна дверь ведёт дальше, за другой — смерть. Один из нас всегда лжёт, другой всегда говорит правду. Задай один вопрос — одному из нас."

## Выход и ложная дверь (в любом порядке): при входе в зал они случайно меняются местами.
@export var doors: Array[NodePath] = []
## На сколько ближе к середине зала, чем его дверь, стоит страж.
@export var offset := 44.0

## Какая дверь ведёт дальше: 0 — левая, 1 — правая.
var real_door := 0
## Кто лжёт: 0 — левый страж, 1 — правый.
var liar := 0
var asked := false
var answer_text := ""
## Какую дверь назвал страж на третий вопрос (0 — левая, 1 — правая), -1 — не спрашивали.
var answer_door := -1
var _speaking := 0
var _popup: CanvasLayer
var _time := 0.0
var _xs := [0.0, 0.0]
var _floor_y := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var a := get_node(doors[0]) as Node2D
	var b := get_node(doors[1]) as Node2D
	var left := a if a.global_position.x < b.global_position.x else b
	var right := b if left == a else a
	var lx := left.global_position.x
	var rx := right.global_position.x
	real_door = randi() % 2
	liar = randi() % 2
	var exit := a if not a.trap else b
	var trap := b if exit == a else a
	exit.global_position.x = lx if real_door == 0 else rx
	trap.global_position.x = rx if real_door == 0 else lx
	_floor_y = left.global_position.y
	_xs = [lx + offset, rx - offset]
	for i in 2:
		var zone := Area2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(30, 40)
		shape.shape = rect
		shape.position = Vector2(0, -20)
		zone.add_child(shape)
		zone.position = to_local(Vector2(_xs[i], _floor_y))
		zone.set_script(preload("res://scripts/twin_guard_zone.gd"))
		zone.guards = self
		zone.index = i
		add_child(zone)
	_popup = PopupScript.new()
	_popup.chosen.connect(_on_chosen)
	get_parent().add_child.call_deferred(_popup)


func can_talk() -> bool:
	return not (_popup and _popup.visible)


## Страж index (0 — левый, 1 — правый) заговаривает с героем.
func talk(index: int) -> void:
	if _popup.visible:
		return
	_speaking = index
	var name := "Левый страж" if index == 0 else "Правый страж"
	if asked:
		_popup.open(name, Game.t("Мы уже ответили: «%s» Больше ни слова.") % Game.t(answer_text), ["Дальше"])
	else:
		_popup.open(name, INTRO, QUESTIONS)


func _on_chosen(i: int) -> void:
	if asked:
		_popup.close()
		return
	asked = true
	var lies := _speaking == liar
	match i:
		0:
			answer_text = "Да."
		1:
			var mine_real := _speaking == real_door
			answer_text = "Да." if mine_real != lies else "Нет."
		2:
			# Правдивый честно передаёт ложь лжеца, лжец искажает правду: оба называют ловушку.
			answer_door = 1 - real_door
			answer_text = "Он назвал бы левую дверь." if answer_door == 0 else "Он назвал бы правую дверь."
		3:
			answer_text = "Он."
	Sfx.play("ui")
	_popup.say(answer_text)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint():
		return
	for i in 2:
		# Каждый страж смотрит на свою дверь: левый — влево.
		var p := to_local(Vector2(_xs[i], _floor_y))
		draw_set_transform(p, 0.0, Vector2(-1.6 if i == 0 else 1.6, 1.6))
		_draw_jackal(Vector2.ZERO, i)
	draw_set_transform(Vector2.ZERO)


## Сидящий шакал из чёрного камня с золотом, на постаменте.
func _draw_jackal(p: Vector2, i: int) -> void:
	var basalt := Color("2b2725")
	var edge := Color("4a443f")
	var gold := Color("d9a93a")
	var gold_lit := Color("ffe08a")
	draw_rect(Rect2(p + Vector2(-13, -10), Vector2(26, 10)), Color("6e5236"))
	draw_rect(Rect2(p + Vector2(-13, -10), Vector2(26, 2)), gold)
	# Туловище, передние лапы, хвост.
	draw_colored_polygon(PackedVector2Array([p + Vector2(-10, -10), p + Vector2(10, -10), p + Vector2(8, -30), p + Vector2(2, -38), p + Vector2(-6, -36), p + Vector2(-10, -24)]), basalt)
	draw_rect(Rect2(p + Vector2(4, -26), Vector2(4, 16)), edge)
	draw_line(p + Vector2(-10, -24), p + Vector2(-6, -36), gold, 1.0)
	draw_line(p + Vector2(8, -30), p + Vector2(10, -10), Color(gold, 0.6), 1.0)
	draw_rect(Rect2(p + Vector2(-12, -14), Vector2(4, 4)), basalt)
	# Голова с длинной мордой и острыми ушами.
	draw_colored_polygon(PackedVector2Array([p + Vector2(-2, -38), p + Vector2(6, -44), p + Vector2(15, -42), p + Vector2(15, -39), p + Vector2(6, -36)]), basalt)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-1, -42), p + Vector2(0, -54), p + Vector2(4, -44)]), basalt)
	draw_colored_polygon(PackedVector2Array([p + Vector2(3, -43), p + Vector2(5, -53), p + Vector2(7, -44)]), edge)
	# Золотой ошейник и полосы головного платка.
	draw_rect(Rect2(p + Vector2(-7, -34), Vector2(14, 3)), gold)
	draw_rect(Rect2(p + Vector2(-7, -34), Vector2(14, 1)), gold_lit)
	draw_rect(Rect2(p + Vector2(-4, -40), Vector2(2, 8)), gold)
	var glow := 0.6 + 0.4 * sin(_time * 2.0 + i * 1.7)
	draw_rect(Rect2(p + Vector2(7, -42), Vector2(2, 2)), Color(1.0, 0.85, 0.3, glow))
