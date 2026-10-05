@tool
extends Area2D
## Рычаг: герой нажимает кнопку действия рядом с ним. Начало координат — точка крепления снизу.
## В стиле button это каменная плита в полу: она чуть выступает и проседает, когда на неё встаёт герой.

@export var targets: Array[NodePath] = []
@export var effect: StringName = &"activate"
@export var one_shot := true
## lever — рычаг на стене, button — каменная плита в полу.
@export_enum("lever", "button") var style := "lever":
	set(value):
		style = value
		queue_redraw()

var pulled := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if style != "button":
		add_to_group("interactable")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 26)
	shape.shape = rect
	shape.position = Vector2(0, -13)
	add_child(shape)


func _physics_process(_delta: float) -> void:
	if style != "button" or Engine.is_editor_hint() or (pulled and one_shot):
		return
	# Плита нажимается, только когда герой стоит на ней, а не пролетает над ней.
	for body in get_overlapping_bodies():
		if body.is_in_group("hero") and body.is_on_floor() and absf(body.global_position.x - global_position.x) < 12.0:
			use()
			return


func use() -> void:
	if pulled and one_shot:
		return
	pulled = not pulled
	Sfx.play("lever")
	queue_redraw()
	Game.fire(self, targets, effect)


func _draw() -> void:
	if style == "button":
		_draw_plate()
		return
	draw_rect(Rect2(-6, -6, 12, 6), Color("5e4630"))
	var tip := Vector2(7, -18) if pulled else Vector2(-7, -18)
	draw_line(Vector2(0, -4), tip, Color("b08850"), 3.0)
	draw_circle(tip, 3.0, Color("d9534f"))


func _draw_plate() -> void:
	# Паз в полу, в который уходит плита.
	draw_rect(Rect2(-15, 0, 30, 2), Color("1a120c"))
	var h := 1.0 if pulled else 4.0
	var top := -h + 1.0
	var slab := Rect2(-14, top, 28, h + 1.0)
	draw_rect(slab, Color("6e5236") if pulled else Color("8a6e4c"))
	draw_rect(Rect2(-14, top, 28, 1), Color("5e4630") if pulled else Color("b49470"))
	draw_rect(Rect2(-14, top, 1, h + 1.0), Color("5a4229"))
	draw_rect(Rect2(13, top, 1, h + 1.0), Color("4a3524"))
	if not pulled:
		# Высеченный знак: глаз на лицевой грани плиты.
		draw_rect(Rect2(-3, top + 2, 6, 1), Color("3b2a1c"))
		draw_rect(Rect2(-1, top + 2, 2, 1), Color("d9a441"))
