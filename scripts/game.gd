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
	"res://levels/level_13.tscn",
	"res://levels/level_14.tscn",
]
const FINISH_SCENE := "res://ui/finish.tscn"
const MENU_SCENE := "res://ui/menu.tscn"
const TITLE_SCENE := "res://ui/title.tscn"
const SETTINGS_SCENE := "res://ui/settings.tscn"
const I18n := preload("res://scripts/i18n.gd")
const SAVE_PATH := "user://progress.cfg"

## Номера пройденных уровней (с нуля).
var passed: Array[int] = []
## Для проверки прототипа: все уровни открыты, даже непройденные.
var unlock_all := false
## Язык интерфейса и текстов уровней: "ru" или "en".
var lang := "ru"


func _ready() -> void:
	_add_action("move_left", [KEY_LEFT, KEY_A])
	_add_action("move_right", [KEY_RIGHT, KEY_D])
	_add_action("jump", [KEY_SPACE, KEY_UP, KEY_W])
	_add_action("action", [KEY_E, KEY_ENTER])
	# По умолчанию язык системы: русский для русской системы, иначе английский.
	lang = "ru" if OS.get_locale_language() == "ru" else "en"
	_load()


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
	mark_passed(current_index())
	var i := current_index() + 1
	var path: String = LEVELS[i] if i > 0 and i < LEVELS.size() else FINISH_SCENE
	get_tree().change_scene_to_file.call_deferred(path)


func start_over() -> void:
	get_tree().change_scene_to_file.call_deferred(MENU_SCENE)


func open_level(index: int) -> void:
	get_tree().change_scene_to_file.call_deferred(LEVELS[index])


## Текст на выбранном языке.
func t(text: String) -> String:
	return I18n.translate(text, lang)


func set_lang(value: String) -> void:
	lang = value
	save()


func go_title() -> void:
	get_tree().change_scene_to_file.call_deferred(TITLE_SCENE)


# --- Прогресс ----------------------------------------------------------------

func mark_passed(index: int) -> void:
	if index >= 0 and not passed.has(index):
		passed.append(index)
		passed.sort()
		save()


## Уровень открыт, если он первый или пройден предыдущий.
func is_unlocked(index: int) -> bool:
	return unlock_all or index == 0 or passed.has(index - 1) or passed.has(index)


## Первый непройденный уровень — с него продолжает кнопка «Играть».
func continue_index() -> int:
	for i in LEVELS.size():
		if not passed.has(i):
			return i
	return 0


func reset_progress() -> void:
	passed.clear()
	unlock_all = false
	save()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "passed", passed)
	cfg.set_value("progress", "unlock_all", unlock_all)
	cfg.set_value("settings", "sound", Sfx.enabled)
	cfg.set_value("settings", "lang", lang)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	passed.clear()
	for i in cfg.get_value("progress", "passed", []):
		passed.append(int(i))
	unlock_all = cfg.get_value("progress", "unlock_all", false)
	Sfx.enabled = cfg.get_value("settings", "sound", true)
	lang = cfg.get_value("settings", "lang", lang)


## Запускает эффект у всех целей: так устроена система событий «триггер → эффект».
func fire(source: Node, targets: Array[NodePath], effect: StringName) -> void:
	for path in targets:
		var target := source.get_node_or_null(path)
		if target and target.has_method(effect):
			target.call(effect)
