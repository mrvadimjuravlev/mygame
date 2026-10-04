@tool
extends Area2D
## Птица: летает горизонтально туда-обратно. Касание героя — гибель.

@export var from_x := 40.0
@export var to_x := 600.0
@export var speed := 120.0
@export var start_dir := 1.0

var dir := 1.0
var _time := 0.0


func _ready() -> void:
	dir = start_dir
	if Engine.is_editor_hint():
		return
	add_to_group("bird")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 10)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("hero"):
			body.die())


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	position.x += dir * speed * delta
	if position.x > to_x:
		position.x = to_x
		dir = -1.0
	elif position.x < from_x:
		position.x = from_x
		dir = 1.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# Светлая птица, чтобы её было хорошо видно на тёмном фоне пирамиды.
	var body := Color("e9dcc3")
	var edge := Color("5a4632")
	var d := dir
	var flap := 7.0 * sin(_time * 14.0)
	var wing_l := PackedVector2Array([Vector2(-3, -1), Vector2(-14, -6 - flap), Vector2(-6, 1)])
	var wing_r := PackedVector2Array([Vector2(3, -1), Vector2(14, -6 - flap), Vector2(6, 1)])
	draw_colored_polygon(wing_l, body.darkened(0.15))
	draw_colored_polygon(wing_r, body.darkened(0.15))
	var b := PackedVector2Array([Vector2(-10 * d, 0), Vector2(-4 * d, -4), Vector2(6 * d, -3), Vector2(10 * d, 0), Vector2(6 * d, 3), Vector2(-4 * d, 3)])
	draw_colored_polygon(b, body)
	var outline := b.duplicate()
	outline.append(b[0])
	draw_polyline(outline, edge, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(10 * d, -1), Vector2(14 * d, 0), Vector2(10 * d, 1)]), Color("e0a030"))
	draw_circle(Vector2(7 * d, -1), 1.2, Color.BLACK)
