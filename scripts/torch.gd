@tool
extends Area2D
## Факел на стене: загорается, когда герой проходит мимо (или горит сразу).
## Даёт тёплый мерцающий свет. Начало координат — крепление к стене.

const Art := preload("res://scripts/art.gd")

@export var start_lit := false

var lit := false
var _time := 0.0
var _light: PointLight2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_time = randf() * 10.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 200)
	shape.shape = rect
	add_child(shape)
	_light = PointLight2D.new()
	_light.texture = Art.light_texture()
	_light.color = Color(1.0, 0.72, 0.42)
	_light.texture_scale = 1.1
	_light.position = Vector2(0, -6)
	_light.enabled = false
	add_child(_light)
	if start_lit:
		_set_lit()
	body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("hero"):
			_set_lit())


func _set_lit() -> void:
	lit = true
	_light.enabled = true


func _process(delta: float) -> void:
	_time += delta
	if _light and lit:
		_light.energy = 1.1 + 0.12 * sin(_time * 11.0) + 0.08 * sin(_time * 23.0)
	queue_redraw()


func _draw() -> void:
	# Кронштейн и чаша.
	draw_rect(Rect2(-1, -2, 2, 10), Color("3a2616"))
	draw_rect(Rect2(-4, -4, 8, 3), Color("5e4630"))
	draw_rect(Rect2(-3, -1, 6, 1), Color("3a2616"))
	if not lit:
		return
	# Пламя из пикселей, «дышит».
	var f := int(_time * 10.0) % 3
	var h: int = [9, 11, 10][f]
	draw_circle(Vector2(0, -8), 10.0, Color(1, 0.7, 0.3, 0.12))
	draw_rect(Rect2(-3, -4 - h + 4, 6, h - 4), Color("e2572b"))
	draw_rect(Rect2(-2, -4 - h + 2, 4, h - 3), Color("ff9a3c"))
	draw_rect(Rect2(-1, -4 - h + 4, 2, h - 6), Color("ffe08a"))
	draw_rect(Rect2(-1 + (f - 1), -4 - h, 2, 2), Color("ff9a3c"))
