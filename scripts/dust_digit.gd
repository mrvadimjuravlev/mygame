@tool
extends Node2D
## Цифра, выцарапанная на стене и засыпанная пылью. Палец стирает пыль: чем дольше трёшь, тем виднее.
## Начало координат — центр цифры.

const RADIUS := 20.0

@export var digit := 0:
	set(value):
		digit = value
		queue_redraw()
@export var color := Color("d9534f"):
	set(value):
		color = value
		queue_redraw()
## Сколько пыли с самого начала: 1 — цифры не видно совсем.
@export_range(0.0, 1.0) var dust := 0.85:
	set(value):
		dust = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("rune")


func contains_world_point(point: Vector2) -> bool:
	return global_position.distance_to(point) < RADIUS + 6.0


func hand_tap() -> void:
	dust -= 0.08


func hand_drag(world_delta: Vector2) -> void:
	# Примерно три-четыре движения пальцем туда-обратно стирают пыль.
	var before := dust
	dust -= world_delta.length() * 0.006
	if before > 0.0:
		Game.hand_used.emit("drag")


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-RADIUS, 11), str(digit), HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2, 32, color)
	if dust <= 0.0:
		return
	# Пыль: пятна разной плотности, всегда одни и те же для этой цифры.
	var rng := RandomNumberGenerator.new()
	rng.seed = digit * 977 + int(color.r * 255.0)
	draw_circle(Vector2.ZERO, RADIUS, Color(0.42, 0.34, 0.25, dust * 0.75))
	for i in 26:
		var p := Vector2(rng.randf_range(-RADIUS, RADIUS), rng.randf_range(-RADIUS, RADIUS)) * 0.85
		var r := rng.randf_range(3.0, 7.0)
		var a := clampf(dust * rng.randf_range(0.4, 1.1), 0.0, 1.0)
		draw_circle(p, r, Color(0.5, 0.41, 0.3, a))
