@tool
extends Node2D
## Подъёмный мост с воротом. Палец крутит ворот (ведёт по нему) — мост опускается.
## Пока палец держит ворот, мост лежит; отпустишь — мост поднимается, и кто на нём, падает.
## Начало координат — ось моста у края обрыва (верх пола); мост ложится влево на length.

const RUNE_COLOR := Color("5fd3ff")
const WHEEL_RADIUS := 16.0
## Сколько пикселей провести пальцем по вороту, чтобы мост лёг.
const CRANK := 260.0
## Как быстро мост поднимается сам, если ворот отпустили (доля в секунду).
const RISE_SPEED := 0.7

@export var length := 160.0:
	set(value):
		length = value
		queue_redraw()
## Ворот и блок под потолком — относительно оси.
@export var winch := Vector2(80, -80):
	set(value):
		winch = value
		queue_redraw()
@export var pulley := Vector2(24, -170):
	set(value):
		pulley = value
		queue_redraw()

## 0 — мост поднят, 1 — лежит.
var lowered := 0.0
var held := false
var _crank_angle := 0.0
var _body: StaticBody2D
var _shape: CollisionShape2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("rune")
	_body = StaticBody2D.new()
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(length, 10)
	_shape.shape = rect
	_shape.position = Vector2(-length / 2, 5)
	_shape.disabled = true
	_body.add_child(_shape)
	add_child(_body)


func contains_world_point(point: Vector2) -> bool:
	return (global_position + winch).distance_to(point) < WHEEL_RADIUS + 12.0


func hand_tap() -> void:
	held = true
	Game.hand_used.emit("tap")


func hand_drag(world_delta: Vector2) -> void:
	if not held:
		return
	var before := lowered
	lowered = minf(lowered + world_delta.length() / CRANK, 1.0)
	_crank_angle += world_delta.length() / WHEEL_RADIUS
	if before < 1.0 and lowered >= 1.0:
		Sfx.play("door", -4.0, 1.3)
	Game.hand_used.emit("drag")


func hand_release() -> void:
	held = false


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not held and lowered > 0.0:
		lowered = maxf(lowered - RISE_SPEED * delta, 0.0)
		_crank_angle -= RISE_SPEED * delta * CRANK / WHEEL_RADIUS
	# По мосту можно идти, только когда он лёг целиком.
	_shape.disabled = lowered < 0.97
	queue_redraw()


func _tip() -> Vector2:
	var a := (1.0 - lowered) * PI / 2.0
	return Vector2(-length, 0).rotated(a)


func _draw() -> void:
	var a := (1.0 - lowered if not Engine.is_editor_hint() else 0.0) * PI / 2.0
	# Мост: доски, окованные по краям.
	var xf := Transform2D(a, Vector2.ZERO)
	var plank := PackedVector2Array([Vector2(-length, 0), Vector2(0, 0), Vector2(0, 10), Vector2(-length, 10)])
	draw_colored_polygon(xf * plank, Color("6e5236"))
	var x := -length + 16.0
	while x < 0.0:
		draw_line(xf * Vector2(x, 1), xf * Vector2(x, 9), Color("4a3524"), 1.0)
		x += 16.0
	draw_line(xf * Vector2(-length, 0.5), xf * Vector2(0, 0.5), Color("8a6a43"), 1.0)
	draw_line(xf * Vector2(-length, 9.5), xf * Vector2(0, 9.5), Color("3a2616"), 1.0)
	draw_circle(Vector2(0, 5).rotated(a), 3.0, Color("3b3834"))
	# Цепь: от края моста к блоку под потолком и вниз к вороту.
	var tip := xf * Vector2(-length + 4, 0)
	_chain(tip, pulley)
	_chain(pulley, winch + Vector2(0, -WHEEL_RADIUS))
	draw_circle(pulley, 5.0, Color("3b3834"))
	draw_circle(pulley, 2.0, Color("5e5a55"))
	# Ворот: колесо со спицами и ручкой, крутится вместе с мостом.
	draw_circle(winch, WHEEL_RADIUS, Color("5e4630"))
	draw_arc(winch, WHEEL_RADIUS, 0.0, TAU, 28, Color("3a2616"), 2.0)
	for k in 4:
		var d := Vector2.RIGHT.rotated(_crank_angle + k * PI / 2.0)
		draw_line(winch, winch + d * (WHEEL_RADIUS - 2.0), Color("8a6a43"), 2.0)
	draw_circle(winch, 3.0, Color("3a2616"))
	var handle := winch + Vector2.RIGHT.rotated(_crank_angle) * (WHEEL_RADIUS - 3.0)
	draw_circle(handle, 3.0, Color("b08a57"))
	if not Engine.is_editor_hint():
		var glow := 0.45 + 0.3 * sin(Time.get_ticks_msec() / 300.0)
		draw_arc(winch, WHEEL_RADIUS + 4.0, 0.0, TAU, 28, Color(RUNE_COLOR, 0.9 if held else glow), 1.0)


func _chain(from: Vector2, to: Vector2) -> void:
	var d := to - from
	var n := int(d.length() / 5.0)
	for i in n:
		var p := from + d * (float(i) / maxf(n, 1))
		if i % 2 == 0:
			draw_circle(p, 1.5, Color("5e5a55"))
		else:
			draw_line(p, p + d.normalized() * 4.0, Color("4a4642"), 1.0)
