@tool
extends Node2D
## Мост из тени. Под потолком по рейке ездит факел (палец тащит его), над пропастью висит балка.
## Тень балки ложится на уровень пола; над пропастью по тени можно ходить, по свету — нет.
## Начало координат — левый край пропасти на уровне пола.

const RUNE_COLOR := Color("5fd3ff")
const Art := preload("res://scripts/art.gd")

## Ширина пропасти.
@export var gap := 160.0:
	set(value):
		gap = value
		queue_redraw()
## Рейка с факелом: высота (относительно пола, вверх — минус) и пределы по x.
@export var rail_y := -190.0
@export var rail_from := -200.0
@export var rail_to := 360.0
@export var torch_x := -130.0:
	set(value):
		torch_x = clampf(value, rail_from, rail_to)
		queue_redraw()
## Балка над пропастью (относительно начала координат).
@export var beam := Rect2(30, -100, 100, 10):
	set(value):
		beam = value
		queue_redraw()
## Высота потолка (для цепей балки).
@export var ceiling_y := -220.0

var _shape: CollisionShape2D
var _light: PointLight2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("rune")
	var body := StaticBody2D.new()
	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	body.add_child(_shape)
	add_child(body)
	_light = PointLight2D.new()
	_light.texture = Art.light_texture()
	_light.texture_scale = 1.6
	_light.energy = 1.1
	_light.color = Color(1.0, 0.75, 0.45)
	add_child(_light)
	_update()


func _torch() -> Vector2:
	return Vector2(torch_x, rail_y)


func contains_world_point(point: Vector2) -> bool:
	return (global_position + _torch() + Vector2(0, 8)).distance_to(point) < 26.0


func hand_tap() -> void:
	Game.hand_used.emit("tap")


func hand_drag(world_delta: Vector2) -> void:
	torch_x += world_delta.x
	Game.hand_used.emit("drag")
	_update()


## Где тень балки ложится на уровень пола: [левый x, правый x].
func shadow_span() -> Vector2:
	var t := _torch()
	var k := (0.0 - t.y) / (beam.end.y - t.y)
	return Vector2(t.x + (beam.position.x - t.x) * k, t.x + (beam.end.x - t.x) * k)


func _update() -> void:
	var s := shadow_span()
	var a := maxf(s.x, 0.0)
	var b := minf(s.y, gap)
	_shape.disabled = b - a < 2.0
	(_shape.shape as RectangleShape2D).size = Vector2(maxf(b - a, 1.0), 8.0)
	_shape.position = Vector2((a + b) / 2.0, 4.0)
	_light.position = _torch() + Vector2(0, 10)


func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		_update()


func _draw() -> void:
	var t := _torch() + Vector2(0, 10)
	var s := shadow_span()
	# Свет факела над пропастью и тень балки: тёмный клин от балки к полу.
	draw_colored_polygon(PackedVector2Array([t, Vector2(-120, 0), Vector2(gap + 120, 0)]), Color(1, 0.85, 0.5, 0.07))
	draw_colored_polygon(PackedVector2Array([Vector2(beam.position.x, beam.end.y), Vector2(beam.end.x, beam.end.y), Vector2(s.y, 0), Vector2(s.x, 0)]), Color(0.05, 0.03, 0.08, 0.55))
	# Сама тень на уровне пола: над пропастью — тёмная тропа.
	var a := maxf(s.x, 0.0)
	var b := minf(s.y, gap)
	if b > a:
		draw_rect(Rect2(a, 0, b - a, 8), Color(0.08, 0.05, 0.14, 0.92))
		draw_line(Vector2(a, 0.5), Vector2(b, 0.5), Color(0.45, 0.4, 0.7, 0.8), 1.0)
	# Балка на двух цепях.
	for cx in [beam.position.x + 8.0, beam.end.x - 8.0]:
		var y := ceiling_y
		var k := 0
		while y < beam.position.y:
			if k % 2 == 0:
				draw_rect(Rect2(cx - 2, y, 4, 6), Color("4a4642"), false, 1.0)
			else:
				draw_rect(Rect2(cx - 0.5, y, 1, 6), Color("5e5a55"))
			y += 5.0
			k += 1
	draw_rect(beam, Color("6e5236"))
	draw_line(beam.position + Vector2(0, 0.5), Vector2(beam.end.x, beam.position.y + 0.5), Color("8a6a43"), 1.0)
	draw_line(Vector2(beam.position.x, beam.end.y - 0.5), beam.end - Vector2(0, 0.5), Color("3a2616"), 1.0)
	# Рейка под потолком и факел на каретке.
	draw_line(Vector2(rail_from - 10, rail_y - 6), Vector2(rail_to + 10, rail_y - 6), Color("3a2616"), 3.0)
	var c := _torch()
	draw_rect(Rect2(c.x - 6, c.y - 9, 12, 5), Color("5e4630"))
	draw_rect(Rect2(c.x - 1, c.y - 4, 2, 10), Color("3a2616"))
	draw_rect(Rect2(c.x - 4, c.y + 5, 8, 3), Color("5e4630"))
	var f := int(Time.get_ticks_msec() / 100) % 3 if not Engine.is_editor_hint() else 0
	var h: float = [9.0, 11.0, 10.0][f]
	draw_circle(c + Vector2(0, 0), 10.0, Color(1, 0.7, 0.3, 0.15))
	draw_rect(Rect2(c.x - 3, c.y + 5 - h * 0.6, 6, h * 0.6), Color("ff9a3c"))
	draw_rect(Rect2(c.x - 1, c.y + 5 - h, 2, h * 0.5), Color("ffe08a"))
	if not Engine.is_editor_hint():
		var glow := 0.45 + 0.3 * sin(Time.get_ticks_msec() / 300.0)
		draw_arc(c + Vector2(0, -2), 14.0, 0.0, TAU, 24, Color(RUNE_COLOR, glow), 1.0)
