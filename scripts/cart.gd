@tool
extends AnimatableBody2D
## Вагонетка на рельсах: стоит, пока на неё не встанет герой, потом катится вправо до stop_x и встаёт.
## Героя везёт на себе; прыгнувший с неё герой летит вместе с ней и приземляется обратно.
## Тронувшись, запускает эффект activate у targets (пресс над путём начинает свой ритм).
## Рельсы с опорами рисует сама — от rail_from до rail_to. Начало координат — середина верхней грани.

const Art := preload("res://scripts/art.gd")

@export var size := Vector2(48, 16):
	set(value):
		size = value
		queue_redraw()
@export var speed := 95.0
## Где (по x, в координатах родителя) встаёт середина вагонетки.
@export var stop_x := 900.0
## Рельсы: от и до (по x), низ опор (по y). Всё в координатах родителя.
@export var rail_from := 0.0
@export var rail_to := 1000.0
@export var post_bottom := 360.0
@export var targets: Array[NodePath] = []

var started := false
var stopped := false
var _speed_now := 0.0
var _wheel := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(0, size.y / 2)
	add_child(shape)
	var rails := Node2D.new()
	rails.top_level = true
	rails.show_behind_parent = true
	rails.draw.connect(_draw_rails.bind(rails))
	add_child(rails)


func rail_y() -> float:
	return position.y + size.y + 5.0


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or stopped:
		return
	if not started:
		for hero in get_tree().get_nodes_in_group("hero"):
			if hero.stands_on(global_position.x - size.x / 2, global_position.x + size.x / 2, global_position.y):
				started = true
				Sfx.play("lever", -4.0, 0.7)
				Game.fire(self, targets, &"activate")
		return
	_speed_now = minf(speed, _speed_now + speed * 2.0 * delta)
	position.x = minf(position.x + _speed_now * delta, stop_x)
	_wheel += _speed_now * delta / 5.0
	queue_redraw()
	if position.x >= stop_x:
		stopped = true
		Sfx.play("door", -4.0, 1.3)


func _draw_rails(rails: Node2D) -> void:
	var parent := get_parent() as Node2D
	var o := parent.global_position if parent else Vector2.ZERO
	var y := rail_y() + o.y
	var wood := Color("4a3524")
	var wood_light := Color("5e4630")
	# Деревянные опоры-козлы до дна пропасти.
	var x := rail_from + 40.0
	while x < rail_to - 20.0:
		var px := x + o.x
		rails.draw_rect(Rect2(px - 3, y, 6, post_bottom + o.y - y), wood)
		rails.draw_rect(Rect2(px - 3, y, 2, post_bottom + o.y - y), wood_light)
		rails.draw_line(Vector2(px - 3, y + 30), Vector2(px - 40, y + 4), wood, 3.0)
		rails.draw_line(Vector2(px + 3, y + 30), Vector2(px + 40, y + 4), wood, 3.0)
		x += 120.0
	# Брус под рельсом и сам рельс.
	rails.draw_rect(Rect2(rail_from + o.x, y + 2, rail_to - rail_from, 5), wood)
	rails.draw_rect(Rect2(rail_from + o.x, y + 2, rail_to - rail_from, 1), wood_light)
	rails.draw_rect(Rect2(rail_from + o.x, y - 1, rail_to - rail_from, 3), Color("6b6156"))
	rails.draw_rect(Rect2(rail_from + o.x, y - 1, rail_to - rail_from, 1), Color("a8a094"))


func _draw() -> void:
	var half := size.x / 2
	# Короб из досок с железной оковкой.
	var body := PackedVector2Array([Vector2(-half, 0), Vector2(half, 0), Vector2(half - 4, size.y), Vector2(-half + 4, size.y)])
	draw_colored_polygon(body, Color("6e4a2a"))
	for k in range(1, 3):
		draw_line(Vector2(-half + 1, k * size.y / 3.0), Vector2(half - 1, k * size.y / 3.0), Color("4f331c"), 1.0)
	draw_rect(Rect2(-half, 0, size.x, 3), Color("5f594f"))
	draw_rect(Rect2(-half, 0, size.x, 1), Color("a8a094"))
	draw_rect(Rect2(-half + 3, 3, 3, size.y - 3), Color("5f594f"))
	draw_rect(Rect2(half - 6, 3, 3, size.y - 3), Color("5f594f"))
	# Колёса со спицами.
	for wx in [-half + 11, half - 11]:
		var c := Vector2(wx, size.y + 1)
		draw_circle(c, 5.0, Color("3b3834"))
		draw_circle(c, 3.5, Color("6b6156"))
		var spoke := Vector2.RIGHT.rotated(_wheel) * 3.5
		draw_line(c - spoke, c + spoke, Color("3b3834"), 1.0)
		draw_line(c - spoke.orthogonal(), c + spoke.orthogonal(), Color("3b3834"), 1.0)
		draw_circle(c, 1.2, Color("a8a094"))
