@tool
extends StaticBody2D
## Рушащаяся плита: герой встал — она дрожит и через delay секунд обваливается. Назад не возвращается:
## целой она снова будет, когда уровень начнётся заново. Начало координат — середина верхней грани.

const Art := preload("res://scripts/art.gd")

@export var size := Vector2(48, 12):
	set(value):
		size = value
		queue_redraw()
## Сколько секунд держит героя.
@export var delay := 0.5

var _shape: CollisionShape2D
var _timer := -1.0
var _fall := 0.0
var _fall_speed := 0.0
var _gone := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = Vector2(0, size.y / 2)
	add_child(_shape)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _gone and _fall > 200.0:
		return
	if _timer < 0.0:
		for hero in get_tree().get_nodes_in_group("hero"):
			if hero.stands_on(global_position.x - size.x / 2, global_position.x + size.x / 2, global_position.y):
				_timer = 0.0
				Sfx.play("land", -6.0, 1.6)
		return
	if not _gone:
		_timer += delta
		queue_redraw()
		if _timer >= delay:
			_gone = true
			_shape.set_deferred("disabled", true)
			Sfx.play("door", -6.0, 1.7)
		return
	# Обломки падают вниз и тают.
	_fall_speed += 900.0 * delta
	_fall += _fall_speed * delta
	queue_redraw()


func _draw() -> void:
	var half := size.x / 2
	if not _gone:
		# Дрожит всё сильнее, по камню бегут трещины.
		var shake := Vector2.ZERO
		if _timer >= 0.0:
			var k := _timer / delay
			shake = Vector2(sin(_timer * 70.0) * (0.5 + k), 0).round()
		var rect := Rect2(Vector2(-half, 0) + shake, size)
		Art.draw_slab(self, rect)
		_draw_cracks(rect, 0.35 if _timer < 0.0 else 0.35 + 0.65 * _timer / delay)
		return
	# Две половинки разлетаются и падают.
	var a := clampf(1.0 - _fall / 200.0, 0.0, 1.0)
	for side in [-1.0, 1.0]:
		var piece := Rect2(Vector2(-half if side < 0 else 0.0, 0), Vector2(half - 1.0, size.y))
		draw_set_transform(Vector2(side * _fall * 0.15, _fall), side * _fall * 0.004, Vector2.ONE)
		Art.draw_slab(self, piece, Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO)


func _draw_cracks(rect: Rect2, amount: float) -> void:
	# Трещины видны и у целой плиты: так её можно отличить от обычного камня.
	var c := Color(0.16, 0.1, 0.06, clampf(amount, 0.0, 1.0))
	var x0 := rect.position.x
	var w := rect.size.x
	draw_polyline(PackedVector2Array([Vector2(x0 + w * 0.3, rect.position.y + 2), Vector2(x0 + w * 0.36, rect.position.y + 6), Vector2(x0 + w * 0.32, rect.end.y)]), c, 1.0)
	draw_polyline(PackedVector2Array([Vector2(x0 + w * 0.7, rect.position.y + 2), Vector2(x0 + w * 0.64, rect.position.y + 7), Vector2(x0 + w * 0.69, rect.end.y)]), c, 1.0)
	if amount > 0.6:
		draw_line(Vector2(x0 + w * 0.36, rect.position.y + 6), Vector2(x0 + w * 0.5, rect.position.y + 5), c, 1.0)
