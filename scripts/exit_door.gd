@tool
extends Area2D
## Дверь выхода — цель уровня. Уровень пройден, когда дверь открыта и герой вошёл в неё.
## Дверь открывает решение загадки (эффект activate) или, на первых уровнях, она открыта сразу.
## Начало координат — у пола.

@export var start_open := false:
	set(value):
		start_open = value
		_open_amount = 1.0 if value else 0.0
		queue_redraw()

## Дверь заперта на ключ: открывается, когда герой подходит к ней с ключом.
@export var needs_key := false:
	set(value):
		needs_key = value
		queue_redraw()

## Дверь на потолке: висит вверх ногами, в неё входят, когда гравитация перевёрнута.
@export var upside_down := false:
	set(value):
		upside_down = value
		queue_redraw()

var is_open := false
var _open_amount := 0.0


func _ready() -> void:
	_open_amount = 1.0 if start_open else 0.0
	if Engine.is_editor_hint():
		return
	add_to_group("exit")
	is_open = start_open
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 40)
	shape.shape = rect
	shape.position = Vector2(0, 20 if upside_down else -20)
	add_child(shape)
	body_entered.connect(_on_body_entered)


## Эффект события: открыть дверь выхода.
func activate() -> void:
	if is_open:
		return
	is_open = true
	Sfx.play("door")
	var tween := create_tween()
	tween.tween_property(self, "_open_amount", 1.0, 0.8).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(_check_hero_inside)


func _process(_delta: float) -> void:
	queue_redraw()


func _check_hero_inside() -> void:
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func _on_body_entered(body: Node) -> void:
	if not is_open and needs_key and body.is_in_group("hero") and body.has_key:
		body.has_key = false
		activate()
		return
	if is_open and _open_amount >= 1.0 and body.is_in_group("hero"):
		set_deferred("monitoring", false)
		Sfx.play("exit")
		Game.next_level()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, -1 if upside_down else 1))
	var stone := Color("b08a57")
	var shade := Color("7a5c38")
	var dark := Color("2a1d12")
	# Проём со светом изнутри.
	draw_rect(Rect2(-12, -42, 24, 42), Color("ffd98a"))
	draw_rect(Rect2(-9, -39, 18, 39), Color("fff3cf"))
	# Каменная плита уезжает вверх по мере открытия.
	var h := 42.0 * (1.0 - _open_amount)
	if h > 0.5:
		var slab := Rect2(-12, -42, 24, h)
		draw_rect(slab, Color("6e5236"))
		draw_rect(Rect2(-12, -42, 3, h), Color("5a4229"))
		for k in range(1, 4):
			var y := -42.0 + k * 10.0
			if y < -42.0 + h:
				draw_line(Vector2(-12, y), Vector2(12, y), Color("5a4229"), 1.0)
		if _open_amount < 0.01:
			if needs_key:
				# Замочная скважина в золотой оправе.
				draw_rect(Rect2(-5, -28, 10, 12), Color("f2c14e"), false, 1.0)
			draw_circle(Vector2(0, -23), 2.5, dark)
			draw_rect(Rect2(-1, -23, 2, 6), dark)
	# Колонны и притолока с глазом.
	draw_rect(Rect2(-17, -46, 5, 46), stone)
	draw_rect(Rect2(12, -46, 5, 46), stone)
	draw_rect(Rect2(-17, -46, 1, 46), shade)
	draw_rect(Rect2(16, -46, 1, 46), shade)
	draw_rect(Rect2(-19, -52, 38, 7), stone)
	draw_rect(Rect2(-19, -46, 38, 1), shade)
	draw_rect(Rect2(-19, -52, 38, 1), Color("e2bf78"))
	draw_rect(Rect2(-4, -50, 8, 1), dark)
	draw_rect(Rect2(-5, -49, 10, 1), dark)
	draw_rect(Rect2(-1, -50, 2, 2), Color("f2c14e"))
