extends Node
## Переключатель цветных стен (toggle_wall): каждый рычаг меняет, какие стоят — красные или синие.

@export var red_on := true


func _ready() -> void:
	_apply.call_deferred()


## Эффект рычага.
func activate() -> void:
	red_on = not red_on
	Sfx.play("door")
	_apply()


func _apply() -> void:
	for wall in get_tree().get_nodes_in_group("toggle_wall"):
		wall.set_red(red_on)
