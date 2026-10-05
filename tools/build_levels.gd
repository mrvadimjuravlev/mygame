extends SceneTree
## Собирает сцены уровней из описаний ниже и сохраняет их в res://levels/.
## Запуск: godot --headless --path . -s tools/build_levels.gd
## После сборки уровни можно править в редакторе Godot как обычные сцены.

const SAND := Color("c9a35b")
const STONE := Color("8a6a43")
const BACK := Color("2a1f17")

var _root: Node2D


func _initialize() -> void:
	_level_01()
	_level_02()
	_level_03()
	_level_04()
	_level_05()
	_level_06()
	_level_07()
	_level_08()
	_level_09()
	_level_10()
	_level_11()
	_level_12()
	_level_13()
	_level_14()
	print("Уровни собраны")
	quit()


# --- Уровни ---------------------------------------------------------------

func _level_01() -> void:
	_begin(1, "Вперёд", 960, "right", ["Иди к свету.", "Нажимай кнопку «вправо».", "Дверь в конце коридора справа."])
	_back(960)
	_box(0, 280, 960, 360)       # пол
	_box(0, 0, 960, 150)         # потолок
	_box(0, 0, 16, 360)          # стены
	_box(944, 0, 960, 360)
	_exit(900, 280, true)
	_decor([[220, 200], [420, 200], [620, 200], [820, 200]], [[300, 180, 3, ["eye", "bird", "sun", "reed", "ankh", "wave"]], [690, 180, 2, ["ankh", "eye", "bird", "reed"]]], false)
	_hero(60, 280)
	_save(1)


func _level_02() -> void:
	_begin(2, "Выше", 640, "jump", ["Не все пути ровные.", "Нажми прыжок рядом с уступом.", "Прыгни на два уступа подряд, затем к двери."])
	_back(640)
	_box(0, 280, 380, 360)       # пол слева
	_box(0, 0, 640, 60)          # потолок
	_box(0, 0, 16, 360)
	_box(624, 0, 640, 360)
	_box(200, 266, 260, 280)     # низкий уступ
	_box(300, 240, 380, 280)     # высокий уступ
	_box(380, 285, 440, 360, SAND)  # неглубокая ямка с песком
	_box(440, 240, 640, 360)     # возвышение с дверью
	_box(20, 110, 90, 122)       # недоступный уступ (задел под рывок)
	_add("Sparkle", Node2D.new(), "sparkle.gd", Vector2(55, 102))
	_exit(580, 240, true)
	_decor([[120, 200], [500, 180]], [[150, 140, 3, ["sun", "ankh", "eye", "wave", "reed", "bird"]]], true)
	_hero(60, 280)
	_save(2)


func _level_03() -> void:
	_begin(3, "Нажми", 640, "action", ["Дверь не откроется сама.", "Рядом с дверью есть рычаг.", "Поднимись к рычагу и нажми кнопку действия."])
	_back(640)
	_box(0, 280, 640, 360)
	_box(0, 0, 640, 120)
	_box(0, 0, 16, 360)
	_box(624, 0, 640, 360)
	_box(240, 255, 300, 280)     # ступенька
	_box(300, 225, 400, 280)     # уступ с рычагом
	var exit := _exit(560, 280)
	_lever("Lever", Vector2(370, 225), [exit])
	_decor([[150, 210], [470, 210]], [[450, 135, 3, ["eye", "ankh", "bird", "reed", "sun", "wave"]]], true)
	_hero(60, 280)
	_save(3)


func _level_04() -> void:
	_begin(4, "Коснись", 640, "", ["Герою здесь не справиться одному.", "Голубые руны откликаются на прикосновение.", "Коснись пальцем руны на плите."])
	_back(640)
	var slab := _rune("Slab", Vector2(336, 225), Vector2(32, 110))
	slab.tap_offset = Vector2(0, 110)
	_box(0, 280, 640, 360)       # пол рисуется поверх уехавшей плиты
	_box(0, 0, 640, 170)         # низкий потолок: плиту не перепрыгнуть
	_box(0, 0, 16, 360)
	_box(624, 0, 640, 360)
	_tutorial(Vector2(336, 225), &"tap")
	var exit := _exit(560, 280)
	_link(slab, [exit])
	_decor([[200, 230], [470, 230]], [[90, 180, 2, ["eye", "sun", "ankh", "reed"]]], true)
	_hero(60, 280)
	_save(4)


func _level_05() -> void:
	_begin(5, "Сдвинь", 640, "", ["Мост можно построить.", "Камень с руной можно двигать пальцем.", "Перетащи камень с руной вниз на яму и перейди по нему."])
	_back(640)
	_box(0, 280, 240, 360)       # пол слева
	_box(240, 345, 400, 360, SAND)  # дно ямы
	_box(240, 315, 265, 345)     # ступенька в яме: выбраться можно только назад
	_box(400, 280, 640, 360)     # пол справа
	_box(0, 0, 640, 40)
	_box(0, 0, 16, 360)
	_box(624, 0, 640, 360)
	var bridge := _rune("Bridge", Vector2(320, 120), Vector2(160, 14))
	bridge.mode = 1  # DRAG
	bridge.drag_axis = Vector2(0, 1)
	bridge.drag_min = 0.0
	bridge.drag_max = 167.0  # верх камня встаёт вровень с полом
	_add("Sparkle", Node2D.new(), "sparkle.gd", Vector2(520, 70))  # щель под потолком (задел под рывок)
	_tutorial(Vector2(320, 120), &"drag", Vector2(0, 160))
	var exit := _exit(580, 280)
	_link(bridge, [exit])
	_decor([[90, 200], [560, 200]], [[40, 70, 3, ["bird", "eye", "reed", "wave", "ankh", "sun"]]], true)
	_hero(60, 280)
	_save(5)


func _level_06() -> void:
	_begin(6, "Вдвоём", 640, "", ["Одному не дотянуться.", "Рука может подготовить герою путь.", "Сдвинь камень к стене под рычагом, запрыгни на него и нажми рычаг."])
	_back(640)
	_box(0, 280, 640, 360)
	_box(0, 0, 640, 100)
	_box(0, 0, 16, 360)
	_box(624, 0, 640, 360)
	var block := _rune("Block", Vector2(150, 260), Vector2(40, 40))
	block.mode = 1  # DRAG
	block.drag_axis = Vector2(1, 0)
	block.drag_min = -114.0
	block.drag_max = 410.0
	block.idle_blink_after = 20.0
	var exit := _exit(590, 280)
	_lever("Lever", Vector2(470, 190), [exit])
	_decor([[90, 200], [330, 170]], [[180, 125, 3, ["ankh", "bird", "eye", "sun", "reed", "wave"]]], true)
	_hero(60, 280)
	_save(6)


func _level_07() -> void:
	_begin(7, "Ключ", 640, "", ["Дверь заперта, а к ней не перепрыгнуть.", "Каменная плита в полу опускает камень с ключом над пропастью.", "Встань на плиту, запрыгни на опустившийся камень, возьми ключ и прыгай к двери."])
	_root.restart_on_fall = true
	_back(640)
	_box(0, 280, 240, 360)       # пол слева
	_box(400, 280, 640, 360)     # пол справа
	_box(0, 0, 640, 60)          # потолок
	_box(0, 0, 16, 360)
	_box(624, 0, 640, 360)
	# Камень с ключом висит высоко над пропастью и опускается по кнопке.
	var platform := _door("Platform", Vector2(320, 137), Vector2(60, 14), Vector2(0, 140))
	var key := Area2D.new()
	key.name = "Key"
	key.set_script(load("res://scripts/key_item.gd"))
	key.position = Vector2(0, -7)
	platform.add_child(key)
	key.owner = _root
	var button := _lever("Button", Vector2(150, 280), [platform])
	button.style = "button"
	var exit := _exit(580, 280)
	exit.needs_key = true
	_decor([[90, 200], [560, 200]], [[180, 90, 3, ["eye", "wave", "bird", "ankh", "sun", "reed"]], [420, 90, 2, ["reed", "eye", "ankh", "bird"]]], true)
	_hero(60, 280)
	_save(7)


func _level_08() -> void:
	_begin(8, "Шаг в пустоту", 640, "", ["Ключ высоко, но путь к нему есть.", "Между камнями не пустота — попробуй прыгнуть туда, где камня не видно.", "С первого камня прыгай вправо и вверх: там невидимый камень, с него — на третий и к ключу."])
	_back(640)
	_box(0, 280, 640, 360)       # пол
	_box(0, 0, 640, 60)          # потолок
	_box(0, 0, 16, 360)
	_box(624, 0, 640, 360)
	_box(140, 240, 190, 254)     # камень 1
	var hidden := _add("HiddenBlock", StaticBody2D.new(), "hidden_block.gd", Vector2(255, 202))  # камень 2, невидимый
	hidden.size = Vector2(50, 14)
	_box(320, 150, 370, 164)     # камень 3
	_add("Key", Area2D.new(), "key_item.gd", Vector2(415, 120))  # ключ висит в воздухе
	var exit := _exit(580, 280)
	exit.needs_key = true
	_decor([[60, 200], [540, 180]], [[450, 190, 2, ["eye", "ankh", "sun", "bird"]]], true)
	_hero(60, 280)
	_save(8)


func _level_09() -> void:
	_begin(9, "Выше птиц", 640, "", ["Лестницу можно опустить.", "Птицы летают по одним и тем же линиям — пережди их, остановившись на лестнице.", "Дёрни рычаг, лезь вверх (▲), замирай под птицей, пока она не пролетит. Ключ на платформе наверху, вниз — кнопкой действия."])
	_root.level_height = 1080.0
	_root.fall_limit = 1200.0
	_root.restart_on_fall = true
	var back := Polygon2D.new()
	back.color = BACK
	back.polygon = PackedVector2Array([Vector2(0, 0), Vector2(640, 0), Vector2(640, 1080), Vector2(0, 1080)])
	_add("Back", back, "", Vector2.ZERO)
	_box(0, 1040, 640, 1080)     # пол
	_box(0, 0, 640, 40)          # потолок
	_box(0, 0, 16, 1080)
	_box(624, 0, 640, 1080)
	_box(340, 200, 500, 214)     # платформа с ключом высоко наверху
	_add("Key", Area2D.new(), "key_item.gd", Vector2(450, 200))
	var ladder := _add("Ladder", Area2D.new(), "ladder.gd", Vector2(326, 200))
	ladder.length = 840.0
	_lever("Lever", Vector2(240, 1040), [ladder])
	# Три птицы на разных высотах, с разной скоростью.
	var birds := [[860.0, 100.0, 1.0, 120.0], [640.0, 130.0, -1.0, 520.0], [420.0, 160.0, 1.0, 200.0]]
	for i in birds.size():
		var b: Array = birds[i]
		var bird := _add("Bird%d" % (i + 1), Area2D.new(), "bird.gd", Vector2(b[3], b[0]))
		bird.speed = b[1]
		bird.start_dir = b[2]
	var exit := _exit(590, 1040)
	exit.needs_key = true
	_decor([[100, 1000], [560, 980], [560, 700], [100, 600], [560, 400], [100, 250], [560, 140]], [[60, 880, 3, ["bird", "bird", "eye", "wave", "reed", "ankh"]], [480, 520, 3, ["sun", "eye", "ankh", "bird", "wave", "reed"]], [60, 300, 2, ["eye", "bird", "ankh", "sun"]]], true)
	_hero(60, 1040)
	_save(9)


func _level_10() -> void:
	_begin(10, "Верх — это низ, лево — это право", 640, "", ["Обрыв не перепрыгнуть. Но край экрана — не стена.", "Уйди за левый край экрана — выйдешь справа.", "Иди налево за край, появишься справа. Выпей зелье: гравитация перевернётся, и по потолку дойдёшь до двери у левого края."])
	_root.restart_on_fall = true
	_root.wrap_horizontal = true
	_back(640)
	_box(0, 280, 240, 360)       # пол слева
	_box(400, 280, 640, 360)     # пол справа, за обрывом
	_box(0, 0, 640, 60)          # потолок по всей ширине
	# Стен по краям нет: уровень закольцован.
	_add("Potion", Area2D.new(), "potion.gd", Vector2(540, 280))
	var exit := _exit(40, 60, true)
	exit.upside_down = true
	_decor([[180, 200], [470, 200]], [[280, 120, 2, ["sun", "wave", "eye", "reed"]]], true)
	_hero(120, 280)
	_save(10)


func _level_11() -> void:
	_begin(11, "Останови время", 640, "", ["Ключ не даётся, пока идёт время.", "Где-то на уровне сыплется песок.", "Под потолком справа висят песочные часы. Переверни их пальцем — и ключ больше не убежит."])
	_root.restart_on_fall = false
	_back(640)
	_box(0, 280, 640, 360)       # пол
	_box(0, 0, 640, 60)          # потолок
	_box(0, 0, 16, 360)
	_box(624, 0, 640, 360)
	_box(80, 230, 160, 244)      # платформа 1
	_box(200, 180, 280, 194)     # платформа 2
	_box(360, 230, 440, 244)     # платформа 3
	_box(480, 180, 560, 194)     # платформа 4
	var key := _add("Key", Area2D.new(), "elusive_key.gd", Vector2(400, 230))
	key.spots = PackedVector2Array([Vector2(400, 230), Vector2(520, 180), Vector2(120, 230), Vector2(240, 180)])
	var hourglass := _add("Hourglass", Node2D.new(), "hourglass.gd", Vector2(600, 80))
	_link(hourglass, [key])
	var exit := _exit(600, 280)
	exit.needs_key = true
	_decor([[60, 180], [320, 140]], [[30, 80, 3, ["reed", "sun", "eye", "wave", "ankh", "bird"]]], true)
	_hero(40, 280)
	_save(11)


func _level_12() -> void:
	_begin(12, "Не та яма", 640, "", ["Обе ямы можно перепрыгнуть, но не всё нужно перепрыгивать.", "Одна яма смертельна, в другой лежит то, что нужно.", "Прыгни во вторую яму за ключом, потом иди вправо прямо в стену: там потайной ход и лестница наверх. Потом по ступенькам к двери."])
	_root.level_height = 720.0
	_root.fall_limit = 800.0
	_root.restart_on_fall = true
	var back := Polygon2D.new()
	back.color = BACK
	back.polygon = PackedVector2Array([Vector2(0, 0), Vector2(640, 0), Vector2(640, 720), Vector2(0, 720)])
	_add("Back", back, "", Vector2.ZERO)
	_box(0, 0, 640, 40)          # потолок
	_box(0, 0, 16, 720)          # стены
	_box(624, 0, 640, 720)
	_box(16, 280, 160, 720)      # пол слева
	_box(220, 280, 340, 720)     # пол между ямами
	_box(160, 660, 220, 720)     # дно первой ямы — на экран ниже
	var spikes := _add("Spikes", Area2D.new(), "spikes.gd", Vector2(160, 660))
	spikes.width = 60.0
	_box(400, 280, 465, 520)     # пол справа и толща камня над залом с ключом
	var hatch := _add("Hatch", StaticBody2D.new(), "hatch.gd", Vector2(465, 280))
	hatch.size = Vector2(30, 12)  # люк над лестницей: снизу пролезаешь, сверху стоишь
	_box(495, 280, 624, 600)     # камень под ступеньками, стена потайного хода
	# Три ступеньки по нарастающей, на третьей — запертая дверь выхода.
	_box(500, 240, 540, 280)     # ступенька 1
	_box(540, 200, 580, 280)     # ступенька 2
	_box(580, 160, 624, 280)     # ступенька 3
	_box(340, 600, 624, 720)     # дно второй ямы и зала
	_add("Key", Area2D.new(), "key_item.gd", Vector2(420, 600))
	var ladder := _add("Ladder", Area2D.new(), "ladder.gd", Vector2(480, 280))
	ladder.length = 320.0
	ladder.start_unrolled = true
	var exit := _exit(602, 160)  # запертая дверь на третьей ступеньке
	exit.needs_key = true
	# Ложная стена закрывает потайной ход и лестницу из ямы наверх.
	var wall := _add("FalseWall", Node2D.new(), "false_wall.gd", Vector2(440, 292))
	wall.size = Vector2(55, 308)
	wall.sensor = Rect2(0, 228, 20, 80)
	wall.crack_at = Vector2(10, 268)
	_decor([[90, 210], [290, 210], [420, 545], [555, 150]], [[150, 120, 3, ["eye", "ankh", "bird", "sun", "wave", "reed"]], [380, 100, 2, ["bird", "eye", "reed", "ankh"]]], true)
	_hero(60, 280)
	_save(12)


func _level_13() -> void:
	_begin(13, "Вишня, небо, солнце, трава", 640, "", ["Название зоны — это порядок.", "Вишня — красная, небо — синее, солнце — жёлтое, трава — зелёная.", "Встань на красную, синюю, жёлтую и зелёную плиты по очереди, и чтобы между ними не было других плит: через лишние перепрыгивай."])
	_back(640)
	_box(0, 280, 640, 360)       # пол
	_box(0, 0, 640, 60)          # потолок
	_box(0, 0, 16, 360)
	_box(624, 0, 640, 360)
	var exit := _exit(580, 280)
	# Четыре плиты не в том порядке, что в названии: между нужными приходится перепрыгивать.
	var seq := _add("Plates", Node2D.new(), "plate_sequence.gd", Vector2(320, 150))
	seq.order = PackedStringArray(["red", "blue", "yellow", "green"])
	_link(seq, [exit])
	var plates := [["yellow", 160.0], ["red", 250.0], ["green", 340.0], ["blue", 430.0]]
	for p in plates:
		var plate := Area2D.new()
		plate.name = "Plate_" + p[0]
		plate.set_script(load("res://scripts/color_plate.gd"))
		plate.color_name = p[0]
		plate.position = Vector2(p[1] - 320.0, 130.0)
		seq.add_child(plate)
		plate.owner = _root
	_decor([[90, 200], [550, 200]], [[200, 100, 3, ["eye", "sun", "wave", "reed", "bird", "ankh"]], [400, 100, 2, ["sun", "wave", "reed", "eye"]]], true)
	_hero(60, 280)
	_save(13)


func _level_14() -> void:
	_begin(14, "Толкай", 640, "", ["Камень можно толкать.", "Столкни камень с уступа. В самом уступе есть тайник, но вход в него высоко.", "Подтолкни камень к уступу, залезь на него и прыгни влево в стену уступа: там потайной ход и ключ."])
	_back(640)
	_box(0, 280, 640, 360)       # пол
	_box(0, 0, 640, 60)          # потолок
	_box(0, 0, 16, 360)
	_box(624, 0, 640, 360)
	# Высокий уступ, внутри него тайник; вход в тайник с пола не достать.
	_box(16, 150, 150, 166)      # верх уступа
	_box(16, 166, 70, 214)       # задняя стенка тайника
	_box(16, 214, 150, 280)      # основание уступа и пол тайника
	var stone := _add("Stone", CharacterBody2D.new(), "push_stone.gd", Vector2(110, 150))
	stone.size = Vector2(32, 32)
	_add("Key", Area2D.new(), "key_item.gd", Vector2(96, 214))  # ключ в тайнике
	# Ложная стена закрывает тайник; открывается, когда герой влезает в проём.
	var wall := _add("FalseWall", Node2D.new(), "false_wall.gd", Vector2(70, 166))
	wall.size = Vector2(80, 48)
	wall.sensor = Rect2(56, 0, 24, 48)
	wall.crack_at = Vector2(72, 24)
	var exit := _exit(580, 280)
	exit.needs_key = true
	_decor([[250, 200], [470, 200]], [[330, 110, 3, ["eye", "ankh", "sun", "bird", "wave", "reed"]]], true)
	_hero(40, 150)
	_save(14)


# --- Помощники ------------------------------------------------------------

## Оформление пирамиды: полумрак, пыль, факелы и панели с иероглифами.
## torches: [[x, y], ...]; glyphs: [[x, y, колонки, [знаки...]], ...];
## lit: факелы горят сразу (false — загораются, когда герой проходит мимо).
func _decor(torches: Array, glyphs: Array, lit: bool) -> void:
	_root.dark = true
	_root.dust = true
	for t in torches:
		var torch := _add("Torch%d_%d" % [t[0], t[1]], Area2D.new(), "torch.gd", Vector2(t[0], t[1]))
		torch.start_lit = lit
	for i in glyphs.size():
		var g: Array = glyphs[i]
		var panel := _add("Glyphs%d" % (i + 1), Node2D.new(), "glyphs.gd", Vector2(g[0], g[1]))
		panel.columns = g[2]
		panel.signs = PackedStringArray(g[3])


func _begin(number: int, slogan: String, width: float, tutorial: String, hints: Array) -> void:
	_root = Node2D.new()
	_root.name = "Level%02d" % number
	_root.set_script(load("res://scripts/level.gd"))
	_root.level_number = number
	_root.slogan = slogan
	_root.level_width = width
	_root.tutorial_button = tutorial
	_root.hints = PackedStringArray(hints)


func _add(node_name: String, node: Node, script: String, pos: Vector2) -> Node:
	node.name = node_name
	if script != "":
		node.set_script(load("res://scripts/" + script))
	if node is Node2D:
		node.position = pos
	_root.add_child(node)
	node.owner = _root
	return node


func _back(width: float) -> void:
	var back := Polygon2D.new()
	back.color = BACK
	back.polygon = PackedVector2Array([Vector2(0, 0), Vector2(width, 0), Vector2(width, 360), Vector2(0, 360)])
	_add("Back", back, "", Vector2.ZERO)


func _box(x1: float, y1: float, x2: float, y2: float, color := STONE) -> Node:
	var solid := _add("Solid%d" % _root.get_child_count(), StaticBody2D.new(), "solid.gd", Vector2.ZERO)
	solid.polygon = PackedVector2Array([Vector2(x1, y1), Vector2(x2, y1), Vector2(x2, y2), Vector2(x1, y2)])
	solid.color = color
	return solid


func _door(node_name: String, pos: Vector2, size: Vector2, open_offset: Vector2) -> Node:
	var door := _add(node_name, AnimatableBody2D.new(), "door.gd", pos)
	door.size = size
	door.open_offset = open_offset
	return door


func _lever(node_name: String, pos: Vector2, targets: Array) -> Node:
	var lever := _add(node_name, Area2D.new(), "lever.gd", pos)
	_link(lever, targets)
	return lever


## Связь события: триггер source действует на targets.
func _link(source: Node, targets: Array) -> void:
	var paths: Array[NodePath] = []
	for t in targets:
		paths.append(source.get_path_to(t))
	source.targets = paths


func _rune(node_name: String, pos: Vector2, size: Vector2) -> Node:
	var rune := _add(node_name, AnimatableBody2D.new(), "rune_block.gd", pos)
	rune.size = size
	return rune


func _tutorial(pos: Vector2, wait_for: StringName, move_to := Vector2.ZERO) -> void:
	var hint := _add("TutorialHint", Node2D.new(), "tutorial_hint.gd", pos)
	hint.wait_for = wait_for
	hint.move_to = move_to


func _exit(x: float, y: float, start_open := false) -> Node:
	var exit := _add("Exit", Area2D.new(), "exit_door.gd", Vector2(x, y))
	exit.start_open = start_open
	return exit


func _hero(x: float, y: float) -> void:
	_add("Hero", CharacterBody2D.new(), "hero.gd", Vector2(x, y))


func _save(number: int) -> void:
	var scene := PackedScene.new()
	var err := scene.pack(_root)
	assert(err == OK)
	var path := "res://levels/level_%02d.tscn" % number
	err = ResourceSaver.save(scene, path)
	if err != OK:
		push_error("Не удалось сохранить " + path)
	_root.free()
