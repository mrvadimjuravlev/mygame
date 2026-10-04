@tool
extends Node2D
## Неприметные песочные часы под потолком. Их трогает рука игрока:
## касание переворачивает часы и останавливает время (событие для targets).
## Начало координат — центр часов; шнурок уходит на 20 px вверх.

@export var targets: Array[NodePath] = []
@export var effect: StringName = &"activate"

var used := false
var _time := 0.0
var _glass: Node2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("rune")


func contains_world_point(point: Vector2) -> bool:
	# Палец толще стекла: зона касания с запасом.
	return Rect2(global_position + Vector2(-14, -20), Vector2(28, 40)).has_point(point)


func hand_tap() -> void:
	if used:
		return
	used = true
	var tween := create_tween()
	tween.tween_method(func(a: float) -> void: rotation = a, 0.0, PI, 0.5)
	Game.fire(self, targets, effect)
	Game.hand_used.emit("tap")


func hand_drag(_world_delta: Vector2) -> void:
	pass


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# Цвета приглушены, чтобы часы сливались со стеной.
	var wood := Color("5e4630")
	var glass := Color(0.75, 0.65, 0.5, 0.35)
	var sand := Color("a8894f")
	var c := Vector2.ZERO
	# Шнурок не крутится вместе с часами.
	draw_set_transform(Vector2.ZERO, -rotation)
	draw_line(Vector2(0, -20), Vector2(0, -11), wood, 1.0)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(c + Vector2(-7, -11), Vector2(14, 2)), wood)
	draw_rect(Rect2(c + Vector2(-7, 9), Vector2(14, 2)), wood)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -9), c + Vector2(5, -9), c + Vector2(1, 0), c + Vector2(5, 9), c + Vector2(-5, 9), c + Vector2(-1, 0)]), glass)
	if not used:
		# Время идёт: песок сыплется вниз.
		draw_colored_polygon(PackedVector2Array([c + Vector2(-3, -6), c + Vector2(3, -6), c + Vector2(0, -1)]), sand)
		var drop := fmod(_time * 20.0, 8.0)
		draw_line(c + Vector2(0, 0), c + Vector2(0, drop), sand, 1.0)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-4, 9), c + Vector2(4, 9), c + Vector2(0, 5)]), sand)
	else:
		# Перевёрнуты и замерли: песок стоит.
		draw_colored_polygon(PackedVector2Array([c + Vector2(-4, 9), c + Vector2(4, 9), c + Vector2(0, 5)]), sand)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-3, -6), c + Vector2(3, -6), c + Vector2(0, -1)]), sand)
