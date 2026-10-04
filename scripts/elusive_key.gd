@tool
extends Area2D
## Ключ-беглец: стоит герою подойти, он исчезает и появляется на другой точке из spots.
## Событие activate (песочные часы) останавливает его, после этого ключ можно взять.
## Начало координат — поверхность, на которой лежит ключ.

## Точки, по которым прыгает ключ (в координатах уровня). Первая — стартовая.
@export var spots: PackedVector2Array = PackedVector2Array()
## На каком расстоянии от героя ключ убегает.
@export var flee_radius := 46.0

var frozen := false
var _index := 0
var _time := 0.0
var _appear := 1.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 20)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	if not spots.is_empty():
		global_position = spots[0]


## Песочные часы перевёрнуты: время остановилось, ключ больше не убегает.
func activate() -> void:
	frozen = true


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("hero"):
		return
	if frozen:
		body.has_key = true
		Sfx.play("key")
		queue_free()
	else:
		_flee(body)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or frozen or spots.size() < 2:
		return
	for hero in get_tree().get_nodes_in_group("hero"):
		var hero_center: Vector2 = hero.global_position + Vector2(0, -12)
		if hero_center.distance_to(global_position + Vector2(0, -10)) < flee_radius:
			_flee(hero)


func _flee(hero: Node2D) -> void:
	# Следующая точка по кругу, но не рядом с героем.
	for i in spots.size():
		_index = (_index + 1) % spots.size()
		if spots[_index].distance_to(hero.global_position) > 110.0:
			break
	global_position = spots[_index]
	_appear = 0.0
	Sfx.play("flee", -3.0)


func _process(delta: float) -> void:
	_time += delta
	_appear = minf(_appear + delta * 3.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var y := -10.0 + 2.0 * sin(_time * 3.0)
	modulate.a = _appear
	draw_circle(Vector2(0, y), 9.0 + 8.0 * (1.0 - _appear), Color(1, 0.85, 0.3, 0.15))
	preload("res://scripts/key_item.gd").draw_key(self, Vector2(0, y))
