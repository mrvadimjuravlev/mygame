extends Node2D
## Зал, который поворачивается целиком на 90° (знаки-руны снаружи зала).
## Герой остаётся стоять прямо: зал поворачивается вместе с ним, а потом он падает на новый пол.
## Начало координат — центр зала. Дверь выхода работает, только когда зал стоит как в начале.

const Art := preload("res://scripts/art.gd")

## Внутренняя половина зала (от центра до стен).
@export var inner := 128.0
@export var exit_path: NodePath

var turns := 0
var busy := false
var _hero: Node2D
var _local := Vector2.ZERO
var _dir := 1


func _ready() -> void:
	var back := get_node_or_null("Back") as Polygon2D
	if back:
		back.texture = Art.back_wall()
		back.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


## dir: 1 — по часовой стрелке, -1 — против.
func turn(dir: int) -> void:
	if busy:
		return
	_hero = get_tree().get_first_node_in_group("hero") as Node2D
	busy = true
	_hero.frozen = true
	_hero.velocity = Vector2.ZERO
	_local = to_local(_hero.global_position + Vector2(0, -12))
	_dir = dir
	Sfx.play("door", -2.0, 0.6)
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_spin, rotation, rotation + dir * PI / 2.0, 0.8)
	tween.tween_callback(_done)


func _spin(a: float) -> void:
	rotation = a
	_hero.global_position = to_global(_local) + Vector2(0, 12)


func _done() -> void:
	turns = posmod(turns + _dir, 4)
	rotation = turns * PI / 2.0
	# Герой стоит прямо, а зал повернулся: не даём ему оказаться в стене.
	var c := _hero.global_position + Vector2(0, -12) - global_position
	c.x = clampf(c.x, -inner + 7.0, inner - 7.0)
	c.y = clampf(c.y, -inner + 13.0, inner - 13.0)
	_hero.global_position = global_position + c + Vector2(0, 12)
	_hero.frozen = false
	var exit := get_node_or_null(exit_path)
	if exit:
		exit.set_deferred("monitoring", turns == 0)
	busy = false
