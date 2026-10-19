@tool
extends Node2D
## Сквозняк: пылинки тянутся по ходу от входа к выходу лабиринта. Видны и в темноте.
## path — точки пути в координатах уровня.

@export var path := PackedVector2Array()
@export var count := 160
const SPEED := 38.0

var _time := 0.0
var _length := 0.0
var _seeds: Array[Vector3] = []


func _ready() -> void:
	z_index = 4
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat
	_length = 0.0
	for i in range(1, path.size()):
		_length += path[i - 1].distance_to(path[i])
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in count:
		_seeds.append(Vector3(rng.randf() * _length, rng.randf_range(-10, 10), rng.randf() * TAU))


func _point_at(d: float) -> Vector2:
	for i in range(1, path.size()):
		var seg := path[i - 1].distance_to(path[i])
		if d <= seg:
			return path[i - 1].lerp(path[i], d / seg)
		d -= seg
	return path[path.size() - 1]


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if path.size() < 2 or _length <= 0.0:
		return
	for s in _seeds:
		var d := fmod(s.x + _time * SPEED, _length)
		var p := _point_at(d) + Vector2(sin(_time * 1.3 + s.z) * 4.0, s.y + sin(_time * 2.0 + s.z) * 3.0 - 14.0)
		var a := 0.55 + 0.3 * sin(_time * 3.0 + s.z)
		# Пылинка с коротким хвостиком по ходу ветра.
		var back := _point_at(maxf(0.0, d - 6.0)) - _point_at(d)
		draw_line(p, p + back, Color(1.0, 0.92, 0.75, a * 0.4), 1.0)
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.95, 0.8, a))
