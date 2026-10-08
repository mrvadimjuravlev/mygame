@tool
extends Node2D
## Головоломка «группы кирпичей по счёту». Дочерние группы (brick_group.gd) нажимают по порядку:
## сначала группу из одного кирпича, потом из двух и так далее. Ошибка — все группы отжимаются,
## счёт начинается заново. Когда нажаты все, срабатывает эффект у целей.

@export var targets: Array[NodePath] = []
@export var effect: StringName = &"activate"

var solved := false
var next := 1
var _total := 0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for group in get_children():
		if group.has_signal("tapped"):
			group.tapped.connect(_on_tapped)
			_total += 1


func _on_tapped(group: Node) -> void:
	if solved or group.pressed:
		return
	if group.count != next:
		Sfx.play("flee", -4.0, 0.7)
		for g in get_children():
			if g.has_signal("tapped"):
				g.flash_wrong()
		next = 1
		return
	group.pressed = true
	Sfx.play("lever", -2.0, 0.8 + next * 0.1)
	next += 1
	if next > _total:
		solved = true
		Game.fire(self, targets, effect)
