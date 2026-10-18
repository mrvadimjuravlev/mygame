@tool
extends Node2D
## Вода, которая слушается скрижали правил (word_rules): «ТОПИТ» — упал в неё — утонул,
## «ДЕРЖИТ» — гладь твёрдая, по ней можно идти, «ГОРИТ» — вода пылает и сжигает.
## Остальные слова воде безразличны: она снова топит. Начало координат — левый край поверхности.

@export var size := Vector2(240, 80):
	set(value):
		size = value
		queue_redraw()

var rule := "ТОПИТ"
var _time := 0.0
var _floor: StaticBody2D
var _area: Area2D


func _ready() -> void:
	z_index = 1
	if Engine.is_editor_hint():
		return
	_floor = StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x, 10)
	shape.shape = rect
	shape.position = Vector2(size.x / 2, 5)
	shape.disabled = true
	_floor.add_child(shape)
	add_child(_floor)
	_area = Area2D.new()
	var area_shape := CollisionShape2D.new()
	var area_rect := RectangleShape2D.new()
	area_rect.size = Vector2(size.x, size.y - 4)
	area_shape.shape = area_rect
	area_shape.position = Vector2(size.x / 2, size.y / 2 + 6)
	_area.add_child(area_shape)
	add_child(_area)


func set_rule(word: String, silent := false) -> void:
	var before := rule
	rule = word if word in ["ДЕРЖИТ", "ГОРИТ"] else "ТОПИТ"
	_floor.get_child(0).set_deferred("disabled", rule != "ДЕРЖИТ")
	if not silent and before != rule:
		Sfx.play("potion")


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for body in _area.get_overlapping_bodies():
		if body.is_in_group("hero") and rule != "ДЕРЖИТ":
			body.die()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	match rule:
		"ГОРИТ":
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.6, 0.15, 0.05, 0.85))
			for k in int(size.x / 12.0):
				var h := 10.0 + 8.0 * absf(sin(_time * 7.0 + k * 1.3))
				var x := k * 12.0 + 6.0
				draw_colored_polygon(PackedVector2Array([Vector2(x - 6, 2), Vector2(x + 6, 2), Vector2(x, -h)]), Color(1.0, 0.5 + 0.2 * sin(k + _time * 5.0), 0.1, 0.9))
				draw_colored_polygon(PackedVector2Array([Vector2(x - 3, 2), Vector2(x + 3, 2), Vector2(x, -h * 0.5)]), Color(1.0, 0.9, 0.4))
		"ДЕРЖИТ":
			# Вода застыла гладким стеклом: по нему можно идти.
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.78, 0.88, 0.9))
			draw_rect(Rect2(0, 0, size.x, 4), Color(0.9, 0.98, 1.0, 1.0))
			for k in int(size.x / 40.0):
				draw_line(Vector2(k * 40 + 8, 6), Vector2(k * 40 + 22, 14), Color(0.85, 0.97, 1.0, 0.5), 1.0)
		_:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.18, 0.45, 0.55, 0.75))
			draw_rect(Rect2(0, 0, size.x, 2), Color(0.55, 0.85, 0.9, 0.8))
			var x := fmod(_time * 12.0, 16.0)
			for row in 3:
				var y := 6.0 + row * 9.0
				var off := x if row % 2 == 0 else 16.0 - x
				var px := -16.0 + off
				while px < size.x:
					if px >= 0.0 and px + 6.0 <= size.x:
						draw_line(Vector2(px, y), Vector2(px + 6, y - 1), Color(0.6, 0.9, 0.95, 0.5), 1.0)
					px += 16.0
