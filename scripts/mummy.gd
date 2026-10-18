@tool
extends Node2D
## Мумия: бредёт к герою по полу между left и right. Коснётся — герой гибнет.
## В свете пальца (finger_light) замирает каменной статуей — тогда через неё можно перепрыгнуть.
## Начало координат — у ног.

@export var left := 0.0
@export var right := 640.0
@export var speed := 55.0

var frozen := false
var _time := 0.0
var _facing := -1.0
var _step := 0.0
var _eyes: PointLight2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Глаза светятся зелёным даже в темноте: мумию видно издалека.
	_eyes = PointLight2D.new()
	_eyes.texture = preload("res://scripts/art.gd").light_texture(64)
	_eyes.color = Color(0.4, 1.0, 0.4)
	_eyes.texture_scale = 0.35
	_eyes.energy = 0.7
	_eyes.position = Vector2(0, -30)
	add_child(_eyes)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	var hero := get_tree().get_first_node_in_group("hero") as Node2D
	var light := get_tree().get_first_node_in_group("finger_light")
	frozen = light != null and (light.lit_at(global_position + Vector2(0, -14)) or light.lit_at(global_position + Vector2(0, -28)))
	_eyes.enabled = not frozen
	if not hero or hero._dead:
		return
	var d := hero.global_position - global_position
	if not frozen:
		# Видит героя только на своём полу.
		if hero.global_position.x > left - 40.0 and hero.global_position.x < right + 40.0 and absf(d.y) < 80.0:
			_facing = signf(d.x) if absf(d.x) > 2.0 else _facing
			position.x = clampf(position.x + _facing * speed * delta, left, right)
			_step += delta
	# Касание: тело мумии 16x30, тело героя 12x24.
	if absf(d.x) < 12.0 and d.y > -30.0 and d.y < 22.0:
		hero.die()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var cloth := Color("8c8270") if frozen else Color("b8ad92")
	var dark := Color("5e5648") if frozen else Color("7a705c")
	var sway := 0.0 if frozen else sin(_step * 8.0) * 1.5
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_facing, 1))
	# Ноги.
	draw_rect(Rect2(-5, -10, 4, 10 + (sway if sway > 0 else 0)), cloth)
	draw_rect(Rect2(1, -10, 4, 10 - (sway if sway < 0 else 0)), cloth)
	# Тело и бинты.
	draw_rect(Rect2(-7, -26, 14, 17), cloth)
	for k in 5:
		draw_line(Vector2(-7, -24 + k * 3.5), Vector2(7, -22 + k * 3.5), dark, 1.0)
	# Голова.
	draw_rect(Rect2(-5, -34, 10, 9), cloth)
	draw_line(Vector2(-5, -31), Vector2(5, -29), dark, 1.0)
	# Вытянутые руки.
	draw_rect(Rect2(4, -24 + sway * 0.5, 10, 3), cloth)
	draw_rect(Rect2(4, -20 - sway * 0.5, 9, 3), cloth)
	# Глаза: горят, пока мумия идёт; в свете гаснут.
	if not frozen:
		var glow := 0.7 + 0.3 * sin(_time * 6.0)
		draw_rect(Rect2(1, -31, 2, 2), Color(0.5, 1.0, 0.5, glow))
		draw_rect(Rect2(-3, -31, 2, 2), Color(0.5, 1.0, 0.5, glow * 0.7))
	# Обрывок бинта.
	draw_line(Vector2(-7, -14), Vector2(-11, -8 + sway), dark, 1.0)
	draw_set_transform(Vector2.ZERO)
