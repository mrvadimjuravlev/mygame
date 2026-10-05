@tool
extends Node2D
## Головоломка «плиты по порядку». Слушает дочерние цветные плиты.
## Верный порядок — эффект у целей (по умолчанию activate), неверная плита — все плиты поднимаются.
## Табличка на стене показывает, сколько плит уже нажато верно. Начало координат — центр таблички.

@export var order := PackedStringArray(["red", "blue", "green"])
@export var targets: Array[NodePath] = []
@export var effect: StringName = &"activate"

var solved := false
var _progress := 0
var _flash := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for plate in _plates():
		plate.stepped.connect(_on_stepped)


func _plates() -> Array:
	return get_children().filter(func(n: Node) -> bool: return n.has_signal("stepped"))


func _on_stepped(plate: Node) -> void:
	if solved or plate.pressed:
		return
	if plate.color_name == order[_progress]:
		plate.set_pressed(true)
		_progress += 1
		Sfx.play("lever", 0.0, 0.9 + 0.15 * _progress)
		if _progress == order.size():
			solved = true
			Game.fire(self, targets, effect)
	else:
		# Ошибка: плита щёлкает и всё сбрасывается.
		_progress = 0
		_flash = 1.0
		Sfx.play("flee", 0.0, 0.6)
		for p in _plates():
			p.set_pressed(false)
	queue_redraw()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 2.0)
		queue_redraw()


func _draw() -> void:
	# Каменная табличка с гнёздами: загорается по гнезду на каждую верную плиту.
	var w := order.size() * 22.0 + 8.0
	var panel := Rect2(-w / 2, -14, w, 28)
	draw_rect(panel, Color("3b2d20"))
	draw_rect(panel, Color("17110c"), false, 1.0)
	for i in order.size():
		var c := Vector2(-w / 2 + 15 + i * 22, 0)
		draw_circle(c, 7.0, Color("17110c"))
		if i < _progress or solved:
			var col: Color = preload("res://scripts/color_plate.gd").COLORS[order[i]]
			draw_circle(c, 6.0, col)
			draw_circle(c + Vector2(-2, -2), 2.0, col.lightened(0.5))
	if _flash > 0.0:
		draw_rect(panel.grow(2), Color(0.85, 0.3, 0.25, _flash), false, 2.0)
