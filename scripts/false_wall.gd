@tool
extends Node2D
## Ложная стена и потайной ход: каменная «заглушка» рисуется поверх хода.
## Герой входит в стену (зона sensor) — заглушка тает и открывает ход.
## Начало координат — левый верхний угол заглушки.

@export var size := Vector2(104, 240):
	set(value):
		size = value
		queue_redraw()
## Зона, войдя в которую герой открывает ход (в локальных координатах).
@export var sensor := Rect2(0, 160, 20, 80)
## Ход открывается, только если герой в зоне sensor летит вверх (прыжок вдоль стены),
## а не просто вошёл в неё или падает мимо.
@export var need_jump := false
## Где нарисовать трещину — едва заметный намёк (в локальных координатах).
@export var crack_at := Vector2(10, 190)

const Art := preload("res://scripts/art.gd")

var opened := false
var _area: Area2D
var _alpha := 1.0


func _ready() -> void:
	z_index = 2
	if Engine.is_editor_hint():
		return
	add_to_group("false_wall")
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = sensor.size
	shape.shape = rect
	shape.position = sensor.position + sensor.size / 2
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("hero") and not need_jump:
			open())
	_area = area


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or opened or not need_jump or _area == null:
		return
	for body in _area.get_overlapping_bodies():
		if body.is_in_group("hero") and body.velocity.y < -1.0:
			open()


func open() -> void:
	if opened:
		return
	opened = true
	# Теперь видно, где у камня края: перерисовать соседей.
	get_tree().call_group("solid", "queue_redraw")
	create_tween().tween_property(self, "_alpha", 0.0, 0.5)


func covers(point: Vector2) -> bool:
	return Rect2(global_position, size).has_point(point)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if _alpha <= 0.0:
		return
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	# Тот же камень, что у соседних стен, текстура совпадает — подмену не видно.
	var poly := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	Art.draw_textured(self, poly, Art.plaster(), Color(1, 1, 1, _alpha))
	Art.draw_crumbled(self, poly, 99, _alpha)
	var crack := Color(0.25, 0.18, 0.1, 0.6 * _alpha)
	var c := crack_at
	draw_polyline(PackedVector2Array([c + Vector2(0, -8), c + Vector2(2, -3), c + Vector2(-1, 2), c + Vector2(1, 8)]), crack, 1.0)
