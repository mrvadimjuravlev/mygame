extends Node
## Глобальное состояние: список уровней, переходы, ввод с клавиатуры.

signal hand_used(kind: String)

const LEVELS := [
	"res://levels/level_01.tscn",
	"res://levels/level_02.tscn",
	"res://levels/level_03.tscn",
	"res://levels/level_04.tscn",
	"res://levels/level_05.tscn",
	"res://levels/level_06.tscn",
	"res://levels/level_07.tscn",
	"res://levels/level_08.tscn",
	"res://levels/level_09.tscn",
	"res://levels/level_10.tscn",
	"res://levels/level_11.tscn",
	"res://levels/level_12.tscn",
]
const FINISH_SCENE := "res://ui/finish.tscn"
const MENU_SCENE := "res://ui/menu.tscn"


func _ready() -> void:
	_add_action("move_left", [KEY_LEFT, KEY_A])
	_add_action("move_right", [KEY_RIGHT, KEY_D])
	_add_action("jump", [KEY_SPACE, KEY_UP, KEY_W])
	_add_action("action", [KEY_E, KEY_ENTER])


func _add_action(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)


func current_index() -> int:
	var scene := get_tree().current_scene
	return LEVELS.find(scene.scene_file_path) if scene else -1


func next_level() -> void:
	var i := current_index() + 1
	var path: String = LEVELS[i] if i > 0 and i < LEVELS.size() else FINISH_SCENE
	get_tree().change_scene_to_file.call_deferred(path)


func start_over() -> void:
	get_tree().change_scene_to_file.call_deferred(MENU_SCENE)


func open_level(index: int) -> void:
	get_tree().change_scene_to_file.call_deferred(LEVELS[index])


## Запускает эффект у всех целей: так устроена система событий «триггер → эффект».
func fire(source: Node, targets: Array[NodePath], effect: StringName) -> void:
	for path in targets:
		var target := source.get_node_or_null(path)
		if target and target.has_method(effect):
			target.call(effect)
