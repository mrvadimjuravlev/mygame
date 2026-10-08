extends Node
## Глобальное состояние: локации и их уровни, переходы, прогресс, ввод с клавиатуры.

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
	"res://levels/level_15.tscn",
	"res://levels/level_16.tscn",
	"res://levels/level_17.tscn",
	"res://levels/level_18.tscn",
]
## Локации по порядку: id, название (ключ перевода), уровни. Пустой список — «Скоро».
const WORLDS := [
	{"id": "pyramid", "name": "Пирамида", "levels": LEVELS},
	{"id": "dungeon", "name": "Подземелье", "levels": ["res://levels/dungeon_01.tscn", "res://levels/dungeon_02.tscn"]},
	{"id": "castle", "name": "Замок", "levels": ["res://levels/castle_01.tscn", "res://levels/castle_02.tscn"]},
	{"id": "temple", "name": "Затонувший храм", "levels": ["res://levels/temple_01.tscn", "res://levels/temple_02.tscn"]},
	{"id": "ice", "name": "Ледяные пещеры", "levels": []},
	{"id": "volcano", "name": "Вулкан", "levels": []},
]
const FINISH_SCENE := "res://ui/finish.tscn"
const MENU_SCENE := "res://ui/menu.tscn"
const TITLE_SCENE := "res://ui/title.tscn"
const SETTINGS_SCENE := "res://ui/settings.tscn"
const WORLDS_SCENE := "res://ui/worlds.tscn"
const I18n := preload("res://scripts/i18n.gd")
const SAVE_PATH := "user://progress.cfg"

## Пройденные уровни: пути сцен.
var passed: Array[String] = []
## Выбранная локация: из неё «Играть» и выбор уровня.
var world := "pyramid"
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


func world_info(id := "") -> Dictionary:
	for w in WORLDS:
		if w.id == (id if id != "" else world):
			return w
	return WORLDS[0]


## Уровни выбранной локации.
func levels() -> Array:
	return world_info().levels


## Локация, к которой относится сцена уровня.
func world_of(path: String) -> String:
	for w in WORLDS:
		if w.levels.has(path):
			return w.id
	return ""


func current_index() -> int:
	var scene := get_tree().current_scene
	if not scene:
		return -1
	return world_info(world_of(scene.scene_file_path)).levels.find(scene.scene_file_path)


func next_level() -> void:
	var path: String = get_tree().current_scene.scene_file_path
	mark_passed(path)
	world = world_of(path)
	var list := levels()
	var i := list.find(path) + 1
	var next: String
	if i > 0 and i < list.size():
		next = list[i]
	else:
		# Пирамида заканчивается финальным экраном, тестовые локации — выбором уровня.
		next = FINISH_SCENE if world == "pyramid" else MENU_SCENE
	get_tree().change_scene_to_file.call_deferred(next)


func start_over() -> void:
	get_tree().change_scene_to_file.call_deferred(MENU_SCENE)


func open_level(index: int) -> void:
	get_tree().change_scene_to_file.call_deferred(levels()[index])


## Текст на выбранном языке.
func t(text: String) -> String:
	return I18n.translate(text, lang)


func set_lang(value: String) -> void:
	lang = value
	save()


func go_title() -> void:
	get_tree().change_scene_to_file.call_deferred(TITLE_SCENE)


# --- Прогресс ----------------------------------------------------------------

func mark_passed(path: String) -> void:
	if path != "" and not passed.has(path):
		passed.append(path)
		save()


func is_passed(index: int) -> bool:
	return passed.has(levels()[index])


## Уровень открыт, если он первый в локации или пройден предыдущий.
func is_unlocked(index: int) -> bool:
	return unlock_all or index == 0 or is_passed(index - 1) or is_passed(index)


## Сколько уровней локации пройдено.
func passed_count(id := "") -> int:
	var n := 0
	for path in world_info(id).levels:
		if passed.has(path):
			n += 1
	return n


## Первый непройденный уровень локации — с него продолжает кнопка «Играть».
func continue_index() -> int:
	for i in levels().size():
		if not is_passed(i):
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
	cfg.set_value("progress", "world", world)
	cfg.set_value("settings", "sound", Sfx.enabled)
	cfg.set_value("settings", "lang", lang)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	passed.clear()
	for item in cfg.get_value("progress", "passed", []):
		# Старые сохранения хранили номера уровней Пирамиды.
		var path: String = LEVELS[int(item)] if typeof(item) == TYPE_INT and int(item) < LEVELS.size() else str(item)
		if not passed.has(path):
			passed.append(path)
	world = cfg.get_value("progress", "world", "pyramid")
	unlock_all = cfg.get_value("progress", "unlock_all", false)
	Sfx.enabled = cfg.get_value("settings", "sound", true)
	lang = cfg.get_value("settings", "lang", lang)


## Запускает эффект у всех целей: так устроена система событий «триггер → эффект».
func fire(source: Node, targets: Array[NodePath], effect: StringName) -> void:
	for path in targets:
		var target := source.get_node_or_null(path)
		if target and target.has_method(effect):
			target.call(effect)
