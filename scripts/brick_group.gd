@tool
extends Node2D
## Несколько кирпичей задней стены чуть другого цвета, кучкой по кладке. Касание пальцем нажимает группу.
## Начало координат — левый верхний угол первого кирпича в сетке кладки (32x16, как у фона);
## bricks — левые верхние углы всех кирпичей группы относительно него.

signal tapped(group: Node)

const BRICK := Vector2(32, 16)

@export_range(1, 9) var count := 1:
	set(value):
		count = value
		queue_redraw()

@export var bricks := PackedVector2Array([Vector2.ZERO]):
	set(value):
		bricks = value
		queue_redraw()

## Группа засчитана в последовательности. На вид не влияет: камни не утапливаются.
var pressed := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("rune")


func contains_world_point(point: Vector2) -> bool:
	for b in bricks:
		if Rect2(global_position + b, BRICK).grow(3).has_point(point):
			return true
	return false


## Касание беззвучное: hand_used не шлём, иначе Sfx сыграет «тап».
func hand_tap() -> void:
	tapped.emit(self)


func hand_drag(_world_delta: Vector2) -> void:
	pass


func _draw() -> void:
	for b in bricks:
		var r := Rect2(b + Vector2(1, 1), BRICK - Vector2(1, 1))
		draw_rect(r, Color("33261a"))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color("33261a").lightened(0.12))
