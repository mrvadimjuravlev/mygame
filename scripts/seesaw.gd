@tool
extends StaticBody2D
## Доска-катапульта, замаскированная под плиту пола: на вид обычный камень, только тонкие швы по краям.
## Камень, упавший на один край, подбрасывает того, кто стоит на другом. Чем выше падал камень, тем сильнее бросок.
## Начало координат — середина верхней грани (там ось).

const Art := preload("res://scripts/art.gd")

@export var size := Vector2(96, 12):
	set(value):
		size = value
		queue_redraw()
## Самый сильный бросок (скорость вверх).
@export var max_throw := 520.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(0, size.y / 2)
	add_child(shape)


func stone_landed(stone: Node2D, speed: float) -> void:
	var side := signf(stone.global_position.x - global_position.x)
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "rotation", 0.22 * side, 0.08)
	tween.tween_interval(0.35)
	tween.tween_property(self, "rotation", 0.0, 0.4)
	Sfx.play("door", 0.0, 1.5)
	for hero in get_tree().get_nodes_in_group("hero"):
		var dx: float = hero.global_position.x - global_position.x
		var on_board: bool = absf(dx) <= size.x / 2 + 4.0 and absf(hero.global_position.y - global_position.y) < 4.0
		if on_board and dx * side < -6.0 and hero.is_on_floor():
			var vy := minf(absf(speed) * 0.85, max_throw)
			hero.launch(Vector2(-side * vy * 0.53, -vy))


func _draw() -> void:
	var poly := PackedVector2Array([Vector2(-size.x / 2, 0), Vector2(size.x / 2, 0), Vector2(size.x / 2, size.y), Vector2(-size.x / 2, size.y)])
	Art.draw_textured(self, poly, Art.plaster())
	# Кромка как у пола: песок на верхней грани.
	draw_line(Vector2(-size.x / 2, 0.5), Vector2(size.x / 2, 0.5), Art.SAND_LIGHT, 1.0)
	draw_line(Vector2(-size.x / 2, 1.5), Vector2(size.x / 2, 1.5), Art.SAND, 1.0)
	draw_line(Vector2(-size.x / 2, 2.5), Vector2(size.x / 2, 2.5), Color(0, 0, 0, 0.15), 1.0)
	# Единственная подсказка — тонкие швы по краям.
	for x in [-size.x / 2 + 0.5, size.x / 2 - 0.5]:
		draw_line(Vector2(x, 3), Vector2(x, size.y), Color(0, 0, 0, 0.3), 1.0)
	draw_line(Vector2(-size.x / 2, size.y - 0.5), Vector2(size.x / 2, size.y - 0.5), Color(0, 0, 0, 0.35), 1.0)
