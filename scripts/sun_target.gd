@tool
extends Node2D
## Солнце, высеченное на стене. Когда в него попадает луч, оно загорается и срабатывают targets.

@export var targets: Array[NodePath] = []
@export var effect: StringName = &"activate"

const RADIUS := 12.0

var lit := false
var _time := 0.0
var _light: PointLight2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("sun_target")


func light() -> void:
	if lit:
		return
	lit = true
	Sfx.play("key", -4.0, 0.8)
	_light = PointLight2D.new()
	_light.texture = preload("res://scripts/art.gd").light_texture()
	_light.texture_scale = 0.5
	_light.energy = 1.2
	_light.color = Color("ffd98a")
	add_child(_light)
	Game.fire(self, targets, effect)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var gold := Color("ffd98a") if lit else Color("8a6a2c")
	var spin := _time * 0.6 if lit else 0.0
	for i in 12:
		var a := spin + i * TAU / 12
		var inner := Vector2.from_angle(a) * (RADIUS + 2)
		var outer := Vector2.from_angle(a) * (RADIUS + (8.0 if i % 2 == 0 else 5.0))
		draw_line(inner, outer, gold, 2.0)
	draw_circle(Vector2.ZERO, RADIUS, Color("3a2a18"))
	draw_circle(Vector2.ZERO, RADIUS - 2, gold)
	if lit:
		draw_circle(Vector2.ZERO, RADIUS - 5, Color("fff4d0"))
	else:
		# Пустые глаза и рот: солнце спит.
		draw_rect(Rect2(-5, -3, 3, 2), Color("3a2a18"))
		draw_rect(Rect2(2, -3, 3, 2), Color("3a2a18"))
		draw_rect(Rect2(-3, 4, 6, 1), Color("3a2a18"))
