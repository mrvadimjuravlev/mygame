@tool
extends Node2D
## Луч света из щели в стене. Идёт по прямой, отражается от зеркал (группа mirror),
## упирается в камень; попав в солнце (группа sun_target), зажигает его.

@export var direction := Vector2.RIGHT:
	set(value):
		direction = value
		queue_redraw()

const MAX_BOUNCES := 12
const BEAM := Color(1.0, 0.93, 0.62)

var points := PackedVector2Array()
var _layer: CanvasLayer
var _ray: Node2D
var _lights: Array[PointLight2D] = []
var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Луч рисуется на своём слое, чтобы полумрак уровня его не гасил.
	_layer = CanvasLayer.new()
	_layer.follow_viewport_enabled = true
	add_child(_layer)
	_ray = Node2D.new()
	_ray.draw.connect(_draw_ray)
	_layer.add_child(_ray)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_trace()
	_ray.queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _trace() -> void:
	var space := get_world_2d().direct_space_state
	var hero := get_tree().get_first_node_in_group("hero")
	var pos := global_position
	var dir := direction.normalized()
	points = PackedVector2Array([pos])
	var last_mirror: Node = null
	var sun: Node = null
	for bounce in MAX_BOUNCES:
		var far := pos + dir * 2000.0
		var query := PhysicsRayQueryParameters2D.create(pos + dir, far)
		if hero:
			query.exclude = [hero.get_rid()]
		var hit := space.intersect_ray(query)
		var end: Vector2 = hit.position if hit else far
		var best := pos.distance_to(end)
		var mirror: Node = null
		sun = null
		for m in get_tree().get_nodes_in_group("mirror"):
			if m == last_mirror:
				continue
			var seg: PackedVector2Array = m.segment()
			var p = Geometry2D.segment_intersects_segment(pos, far, seg[0], seg[1])
			if p != null and pos.distance_to(p) < best:
				best = pos.distance_to(p)
				end = p
				mirror = m
		for s in get_tree().get_nodes_in_group("sun_target"):
			var t := Geometry2D.segment_intersects_circle(pos, far, s.global_position, s.RADIUS)
			if t >= 0.0 and pos.distance_to(far) * t < best:
				best = pos.distance_to(far) * t
				end = pos + dir * best
				mirror = null
				sun = s
		points.append(end)
		if mirror == null:
			break
		dir = dir.bounce(mirror.normal()).normalized()
		pos = end
		last_mirror = mirror
	if sun:
		sun.light()
	_place_lights()


## Тёплые отсветы в точках отражения и там, где луч упёрся.
func _place_lights() -> void:
	while _lights.size() < points.size() - 1:
		var l := PointLight2D.new()
		l.texture = preload("res://scripts/art.gd").light_texture()
		l.texture_scale = 0.22
		l.energy = 0.8
		l.color = BEAM
		add_child(l)
		_lights.append(l)
	for i in _lights.size():
		_lights[i].visible = i + 1 < points.size()
		if _lights[i].visible:
			_lights[i].global_position = points[i + 1]


func _draw_ray() -> void:
	if points.size() < 2:
		return
	var flicker := 0.85 + 0.15 * sin(_time * 7.0)
	draw_on(_ray, Color(BEAM, 0.18 * flicker), 7.0)
	draw_on(_ray, Color(BEAM, 0.45 * flicker), 3.0)
	draw_on(_ray, Color(1, 1, 0.92, 0.95), 1.0)


func draw_on(canvas: Node2D, color: Color, width: float) -> void:
	canvas.draw_polyline(points, color, width)


func _draw() -> void:
	# Щель в стене, откуда бьёт свет.
	var side := direction.normalized()
	var across := side.orthogonal()
	draw_colored_polygon(PackedVector2Array([-side * 6 + across * 7, side * 2 + across * 4, side * 2 - across * 4, -side * 6 - across * 7]), Color("fff0b8"))
	draw_circle(Vector2.ZERO, 3.0, Color(1, 1, 0.9))
