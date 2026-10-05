@tool
extends Node2D
## Головоломка «плиты по порядку». Слушает дочерние цветные плиты.
## Когда последние нажатые плиты совпадают с порядком order, срабатывает эффект у целей
## (по умолчанию activate — открыть дверь). Ошибка ничем не показывается: просто дверь закрыта.

@export var order := PackedStringArray(["red", "blue", "green"])
@export var targets: Array[NodePath] = []
@export var effect: StringName = &"activate"

var solved := false
var _history: Array[String] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for plate in get_children():
		if plate.has_signal("stepped"):
			plate.stepped.connect(_on_stepped)


func _on_stepped(plate: Node) -> void:
	if solved:
		return
	_history.append(plate.color_name)
	if _history.size() > order.size():
		_history.pop_front()
	if PackedStringArray(_history) == order:
		solved = true
		Game.fire(self, targets, effect)
