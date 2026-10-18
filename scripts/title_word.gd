extends Node
## Слово в названии зоны, которое меняется пальцем: «Дверь закрыта» — нажал на «закрыта»,
## стало «открыта», и названное сбывается: срабатывают targets.

@export var word := "закрыта"
@export var replacement := "открыта"
@export var targets: Array[NodePath] = []
@export var effect: StringName = &"activate"

var done := false


func _ready() -> void:
	add_to_group("rune")


## Касание пальцем приходит в координатах уровня: переводим в экранные, где висит название.
func contains_world_point(point: Vector2) -> bool:
	if done:
		return false
	var level := get_parent()
	var screen := level.get_viewport().get_canvas_transform() * point
	return level.hud().slogan_word_rect(Game.t(word)).grow(6).has_point(screen)


func hand_tap() -> void:
	if done:
		return
	done = true
	var level := get_parent()
	level.hud().set_slogan(Game.t(level.slogan).replace(Game.t(word), Game.t(replacement)))
	Sfx.play("lever")
	Game.fire(self, targets, effect)


func hand_drag(_delta: Vector2) -> void:
	pass
