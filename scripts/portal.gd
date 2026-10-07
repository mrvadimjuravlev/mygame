@tool
extends Area2D
## Дверь-портал: герой входит в неё и оказывается в другом месте уровня (в другой локации).
## Камера переключается на границы той комнаты, куда он попал. Начало координат — у пола.

## Куда попадает герой (мировые координаты, точка у ног).
@export var destination := Vector2.ZERO
## Границы комнаты назначения для камеры: слева и справа.
@export var room_left := 0.0
@export var room_right := 640.0
@export var color := Color("7a5cff"):
	set(value):
		color = value
		queue_redraw()

var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 36)
	shape.shape = rect
	shape.position = Vector2(0, -18)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	var glow := PointLight2D.new()
	glow.texture = preload("res://scripts/art.gd").light_texture()
	glow.texture_scale = 0.25
	glow.energy = 0.8
	glow.color = color
	glow.position = Vector2(0, -20)
	add_child(glow)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("hero"):
		return
	_go.call_deferred(body)


func _go(hero: Node2D) -> void:
	Sfx.play("potion", -2.0, 0.7)
	hero.global_position = destination
	hero.velocity = Vector2.ZERO
	for cam in hero.get_children():
		if cam is Camera2D:
			cam.limit_left = int(room_left)
			cam.limit_right = int(room_right)
			cam.reset_smoothing()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var stone := Color("b08a57")
	var shade := Color("7a5c38")
	# Проём с медленно кружащейся тьмой.
	draw_rect(Rect2(-12, -40, 24, 40), Color("120c1e"))
	for i in 5:
		var r := 4.0 + i * 3.0
		var a := _time * (1.5 - i * 0.2) + i
		var c := Vector2(0, -20) + Vector2.from_angle(a) * 2.0
		draw_arc(c, r, a, a + PI * 1.3, 12, Color(color, 0.55 - i * 0.08), 1.5)
	# Колонны и притолока.
	draw_rect(Rect2(-17, -44, 5, 44), stone)
	draw_rect(Rect2(12, -44, 5, 44), stone)
	draw_rect(Rect2(-17, -44, 1, 44), shade)
	draw_rect(Rect2(16, -44, 1, 44), shade)
	draw_rect(Rect2(-19, -50, 38, 7), stone)
	draw_rect(Rect2(-19, -44, 38, 1), shade)
	draw_rect(Rect2(-19, -50, 38, 1), Color("e2bf78"))
	draw_circle(Vector2(0, -47), 2.0, color)
