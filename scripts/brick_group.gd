@tool
extends Node2D
## Несколько кирпичей задней стены чуть другого цвета, в ряд. Касание пальцем нажимает группу.
## Начало координат — левый верхний угол первого кирпича в сетке кладки (32x16, как у фона).

signal tapped(group: Node)

const BRICK := Vector2(32, 16)

@export_range(1, 9) var count := 1:
	set(value):
		count = value
		queue_redraw()

var pressed := false:
	set(value):
		pressed = value
		queue_redraw()
var _glow := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("rune")


func contains_world_point(point: Vector2) -> bool:
	return Rect2(global_position, Vector2(BRICK.x * count, BRICK.y)).grow(4).has_point(point)


func hand_tap() -> void:
	Game.hand_used.emit("tap")
	tapped.emit(self)


func hand_drag(_world_delta: Vector2) -> void:
	pass


## Неверный порядок: кирпичи коротко вспыхивают красным и отжимаются.
func flash_wrong() -> void:
	pressed = false
	_glow = 1.0
	var tween := create_tween()
	tween.tween_property(self, "_glow", 0.0, 0.5)
	tween.tween_callback(queue_redraw)


func _process(_delta: float) -> void:
	if _glow > 0.0:
		queue_redraw()


func _draw() -> void:
	for i in count:
		var r := Rect2(Vector2(i * BRICK.x + 1, 1), BRICK - Vector2(1, 1))
		var c := Color("33261a")
		if pressed:
			c = Color("6a5232")
		draw_rect(r, c)
		if pressed:
			# Кирпич утоплен: тень сверху и слева, светлая кромка снизу.
			draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(0, 0, 0, 0.45))
			draw_rect(Rect2(r.position, Vector2(2, r.size.y)), Color(0, 0, 0, 0.35))
			draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), Color("e2bf78", 0.6))
			draw_rect(r, Color("e2bf78", 0.8), false, 1.0)
		else:
			draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), c.lightened(0.12))
		if _glow > 0.0:
			draw_rect(r, Color(0.85, 0.2, 0.15, 0.5 * _glow))
