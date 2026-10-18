@tool
extends Node2D
## Песочные часы перемотки. Пока палец держит часы, время зала идёт назад (вдвое быстрее),
## отпустил — снова вперёд. Герой перемотке не подчиняется.
## Всё, что зависит от времени (группа "timed"), получает set_time(t) каждый кадр.
## Начало координат — середина часов на стене.

## Время зала в секундах с начала уровня.
var t := 0.0
var rewinding := false
var _anim := 0.0
var _overlay: CanvasLayer
var _tint: ColorRect


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("rune")
	_overlay = CanvasLayer.new()
	_overlay.layer = 5
	_tint = ColorRect.new()
	_tint.size = Vector2(640, 360)
	_tint.color = Color(0.75, 0.55, 0.25, 0.0)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_tint)
	add_child(_overlay)


func contains_world_point(point: Vector2) -> bool:
	return Rect2(global_position + Vector2(-22, -30), Vector2(44, 60)).has_point(point)


func hand_tap() -> void:
	rewinding = true
	Sfx.play("potion")


func hand_drag(_delta: Vector2) -> void:
	pass


func hand_release() -> void:
	rewinding = false


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if rewinding:
		t = maxf(0.0, t - delta * 2.0)
	else:
		t += delta
	for node in get_tree().get_nodes_in_group("timed"):
		node.set_time(t)


func _process(delta: float) -> void:
	_anim += delta
	if _tint:
		_tint.color.a = move_toward(_tint.color.a, 0.22 if rewinding else 0.0, delta * 1.5)
	queue_redraw()


func _draw() -> void:
	var wood := Color("6e4a2a")
	var glass := Color(0.75, 0.9, 1.0, 0.25)
	var sand := Color("e8c66e")
	# Рамка.
	draw_rect(Rect2(-16, -26, 32, 4), wood)
	draw_rect(Rect2(-16, 22, 32, 4), wood)
	draw_rect(Rect2(-14, -22, 3, 44), wood)
	draw_rect(Rect2(11, -22, 3, 44), wood)
	# Колбы.
	var top := PackedVector2Array([Vector2(-10, -22), Vector2(10, -22), Vector2(2, -1), Vector2(-2, -1)])
	var bottom := PackedVector2Array([Vector2(-2, 1), Vector2(2, 1), Vector2(10, 22), Vector2(-10, 22)])
	draw_colored_polygon(top, glass)
	draw_colored_polygon(bottom, glass)
	# Песок: за первые 8 секунд пересыпается вниз; при перемотке летит обратно вверх.
	var k := clampf(t / 8.0, 0.0, 1.0)
	var up_h := 18.0 * (1.0 - k)
	if up_h > 0.5:
		var w := up_h / 18.0 * 8.0 + 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(-w, -1 - up_h), Vector2(w, -1 - up_h), Vector2(2, -1), Vector2(-2, -1)]), sand)
	var down_h := 18.0 * k
	if down_h > 0.5:
		draw_colored_polygon(PackedVector2Array([Vector2(-10, 22), Vector2(10, 22), Vector2(2, 22 - down_h), Vector2(-2, 22 - down_h)]), sand)
	# Струйка: вниз, а при перемотке — вверх, с бегущими песчинками.
	if k < 1.0 or rewinding:
		draw_line(Vector2(0, -2), Vector2(0, 20), Color(sand, 0.8), 1.0)
		var dir := -1.0 if rewinding else 1.0
		for g in 3:
			var y := fposmod(_anim * 30.0 * dir + g * 7.0, 20.0)
			draw_rect(Rect2(-1, y, 2, 2), sand)
	# Подсветка: часы можно держать пальцем.
	var glow := 0.25 + 0.2 * sin(_anim * 3.0)
	draw_rect(Rect2(-18, -28, 36, 56), Color(1.0, 0.85, 0.5, glow if rewinding else glow * 0.4), false, 1.0)
