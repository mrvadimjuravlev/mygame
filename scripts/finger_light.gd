extends Node2D
## Палец-фонарь: в тёмном зале светит там, где палец касается экрана.
## Мумии в этом свете замирают (lit_at). Без пальца зал почти не видно.

const Art := preload("res://scripts/art.gd")
## Радиус, в котором свет пальца останавливает мумий.
const RADIUS := 80.0

var _light: PointLight2D
var _time := 0.0
var _points: Array[Vector2] = []


func _ready() -> void:
	add_to_group("finger_light")
	z_index = 4
	_light = PointLight2D.new()
	_light.texture = Art.light_texture()
	_light.color = Color(1.0, 0.9, 0.7)
	_light.texture_scale = 0.9
	_light.energy = 1.4
	_light.enabled = false
	add_child(_light)


## Точка (в координатах уровня) в свете пальца.
func lit_at(point: Vector2) -> bool:
	for p in _points:
		if p.distance_to(point) < RADIUS:
			return true
	return false


func _process(delta: float) -> void:
	_time += delta
	_points = get_parent().hand_points()
	_light.enabled = not _points.is_empty()
	if _light.enabled:
		_light.global_position = _points[0]
		_light.energy = 1.4 + 0.08 * sin(_time * 13.0)
	queue_redraw()


func _draw() -> void:
	# Огонёк на кончике пальца.
	for p in _points:
		var c := to_local(p)
		draw_circle(c, 7.0 + sin(_time * 12.0), Color(1.0, 0.85, 0.5, 0.25))
		draw_circle(c, 3.0, Color(1.0, 0.95, 0.75, 0.9))
