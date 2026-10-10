@tool
extends Node2D
## Каменный диск со стрелкой: касание пальцем поворачивает зал (turning_room.gd) в свою сторону.

const RUNE_COLOR := Color("5fd3ff")
const RADIUS := 20.0

@export var room: NodePath
## 1 — по часовой стрелке, -1 — против.
@export var dir := 1:
	set(value):
		dir = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("rune")


func contains_world_point(point: Vector2) -> bool:
	return global_position.distance_to(point) < RADIUS + 8.0


func hand_tap() -> void:
	var r := get_node_or_null(room)
	if r and not r.busy:
		Game.hand_used.emit("tap")
		r.turn(dir)


func hand_drag(_world_delta: Vector2) -> void:
	pass


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color("6e5236"))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Color("3a2616"), 2.0)
	draw_arc(Vector2.ZERO, RADIUS - 3.0, 0.0, TAU, 32, Color("8a6a43"), 1.0)
	var glow := 0.6 + 0.3 * sin(Time.get_ticks_msec() / 300.0) if not Engine.is_editor_hint() else 0.8
	var col := Color(RUNE_COLOR, glow)
	# Дуга на три четверти круга и наконечник стрелки.
	var from := -PI / 2.0
	var to := from + dir * PI * 1.5
	draw_arc(Vector2.ZERO, 10.0, minf(from, to), maxf(from, to), 20, col, 2.0)
	var tip := Vector2.RIGHT.rotated(to) * 10.0
	var along := Vector2.RIGHT.rotated(to + dir * PI / 2.0)
	var out := tip.normalized()
	draw_colored_polygon(PackedVector2Array([tip + along * 5.0, tip + out * 4.0 - along * 1.0, tip - out * 4.0 - along * 1.0]), col)
