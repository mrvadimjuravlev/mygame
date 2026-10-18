extends CanvasLayer
## Интерфейс и разбор касаний.
## Касание кнопок по краям экрана управляет героем, касание в любом другом месте — это рука игрока.

const BUTTONS := {
	"left": Rect2(10, 292, 56, 56),
	"right": Rect2(74, 292, 56, 56),
	"action": Rect2(510, 292, 56, 56),
	"jump": Rect2(574, 292, 56, 56),
}
const ACTIONS := {"left": "move_left", "right": "move_right", "action": "action", "jump": "jump"}
const HINT_BUTTON := Rect2(598, 8, 34, 34)
const MENU_BUTTON := Rect2(8, 8, 34, 34)
const INVENTORY_SLOTS := 3
## Сколько секунд подсказка видна на экране после нажатия «?».
const HINT_SHOW_TIME := 8.0

var level: Node

var _finger_button := {}  # индекс пальца -> имя кнопки
var _finger_hand := {}    # индекс пальца -> {rune, last}
var _hint_index := -1
var _waiting_ad := false
## Сколько ещё секунд видна подсказка.
var _hint_left := 0.0
var _time := 0.0
var _tutorial := ""
var _pad: Node2D
var _slogan: Label
var _hint_label: Label


func _ready() -> void:
	_tutorial = level.tutorial_button
	_pad = Node2D.new()
	_pad.draw.connect(_draw_pad)
	add_child(_pad)

	# Название зоны: по центру сверху, всё время на экране.
	_slogan = Label.new()
	_slogan.text = Game.t(level.slogan)
	_slogan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slogan.size = Vector2(440, 30)
	_slogan.position = Vector2(100, 8)
	_slogan.add_theme_font_size_override("font_size", 18)
	_slogan.add_theme_color_override("font_color", Color("ffe7a3"))
	_slogan.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_slogan.add_theme_constant_override("shadow_offset_x", 1)
	_slogan.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_slogan)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hint_label.size = Vector2(440, 40)
	_hint_label.position = Vector2(100, 48)
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", Color("cfefff"))
	add_child(_hint_label)
	# Открытые раньше подсказки при старте не показываем: их можно бесплатно посмотреть снова по «?».


func _process(delta: float) -> void:
	_time += delta
	# Подсказка висит HINT_SHOW_TIME секунд, последнюю секунду гаснет.
	if _hint_left > 0.0:
		_hint_left -= delta
		_hint_label.modulate.a = clampf(_hint_left, 0.0, 1.0)
		if _hint_left <= 0.0:
			_hint_label.text = ""
	if _tutorial != "" and Input.is_action_just_pressed(ACTIONS[_tutorial]):
		_tutorial = ""
	_pad.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag:
		_touch_move(event.index, event.position)


func _button_at(pos: Vector2) -> String:
	for name in BUTTONS:
		if BUTTONS[name].grow(6).has_point(pos):
			return name
	return ""


func _touch_down(index: int, pos: Vector2) -> void:
	if MENU_BUTTON.grow(2).has_point(pos):
		Sfx.play("ui")
		get_tree().change_scene_to_file.call_deferred(Game.MENU_SCENE)
		return
	if HINT_BUTTON.grow(4).has_point(pos):
		Sfx.play("ui")
		_show_next_hint()
		return
	var button := _button_at(pos)
	if button != "":
		_finger_button[index] = button
		Input.action_press(ACTIONS[button])
		return
	var world := _to_world(pos)
	for rune in get_tree().get_nodes_in_group("rune"):
		if rune.contains_world_point(world):
			rune.hand_tap()
			_finger_hand[index] = {"rune": rune, "last": world}
			return
	var hero := level.get_node_or_null("Hero")
	if hero and hero.grab_contains(world):
		hero.carry_start(world)
		_finger_hand[index] = {"rune": null, "hero": hero, "last": world}
		return
	_finger_hand[index] = {"rune": null, "last": world}


func _touch_move(index: int, pos: Vector2) -> void:
	if _finger_button.has(index):
		# Палец можно вести с «влево» на «вправо», не отрывая.
		var button := _button_at(pos)
		if button != "" and button != _finger_button[index]:
			Input.action_release(ACTIONS[_finger_button[index]])
			_finger_button[index] = button
			Input.action_press(ACTIONS[button])
	elif _finger_hand.has(index):
		var world := _to_world(pos)
		var data: Dictionary = _finger_hand[index]
		if data.rune and is_instance_valid(data.rune):
			data.rune.hand_drag(world - data.last)
		elif data.has("hero") and is_instance_valid(data.hero):
			data.hero.carry_move(world)
		data.last = world


func _touch_up(index: int) -> void:
	if _finger_button.has(index):
		Input.action_release(ACTIONS[_finger_button[index]])
		_finger_button.erase(index)
	if _finger_hand.has(index) and _finger_hand[index].has("hero") and is_instance_valid(_finger_hand[index].hero):
		_finger_hand[index].hero.carry_end()
	# Палец отпустил предмет: ворот, камень в руке и т. п.
	if _finger_hand.has(index) and _finger_hand[index].rune and is_instance_valid(_finger_hand[index].rune) \
			and _finger_hand[index].rune.has_method("hand_release"):
		_finger_hand[index].rune.hand_release()
	_finger_hand.erase(index)


func _to_world(screen_pos: Vector2) -> Vector2:
	return level.get_viewport().get_canvas_transform().affine_inverse() * screen_pos


## Следующая подсказка открывается за просмотр рекламы; уже открытые показываются по кругу бесплатно.
func _show_next_hint() -> void:
	if level.hints.is_empty() or _waiting_ad:
		return
	var opened: int = Game.hints_opened.get(level.scene_file_path, 0)
	if _hint_index + 1 < opened:
		_show_hint(_hint_index + 1)
	elif opened < level.hints.size():
		_waiting_ad = true
		Ads.show_rewarded(_on_hint_reward.bind(opened), func() -> void: _waiting_ad = false)
	else:
		_show_hint((_hint_index + 1) % opened)


func _on_hint_reward(index: int) -> void:
	_waiting_ad = false
	if not is_inside_tree():
		return
	Game.hints_opened[level.scene_file_path] = index + 1
	Game.save()
	_show_hint(index)


func _show_hint(index: int) -> void:
	_hint_index = index
	_hint_label.text = Game.t("Подсказка %d: %s") % [index + 1, Game.t(level.hints[index])]
	_hint_left = HINT_SHOW_TIME
	_hint_label.modulate.a = 1.0


## Следующая подсказка будет за рекламу: на кнопке «?» значок ролика.
func _next_hint_needs_ad() -> bool:
	return Ads.rewarded_ready() and Game.hints_opened.get(level.scene_file_path, 0) < level.hints.size() \
			and _hint_index + 1 >= Game.hints_opened.get(level.scene_file_path, 0)


func _draw_pad() -> void:
	var font := ThemeDB.fallback_font
	var hero := level.get_node_or_null("Hero")
	for name in BUTTONS:
		var r: Rect2 = BUTTONS[name]
		var held := Input.is_action_pressed(ACTIONS[name])
		if name == "action" and not (hero and hero.can_act()):
			# Действию сейчас не к чему примениться: кнопка бледная.
			_pad.draw_rect(r, Color(1, 1, 1, 0.04))
			_pad.draw_rect(r, Color(1, 1, 1, 0.12), false, 1.0)
			_draw_icon(name, r.get_center(), Color(1, 1, 1, 0.22))
		elif name == "action":
			# Есть рычаг, портал или лестница: кнопка горит и мягко пульсирует.
			var glow := 0.5 + 0.5 * sin(_time * 5.0)
			_pad.draw_rect(r, Color(1, 0.85, 0.45, (0.4 if held else 0.22) + 0.06 * glow))
			_pad.draw_rect(r, Color(1, 0.9, 0.55, 0.7 + 0.3 * glow), false, 2.0)
			# На лестнице и у её верха кнопка значит «вниз» — так и рисуем.
			_draw_icon("down" if hero.action_is_down() else name, r.get_center(), Color(1, 0.97, 0.85, 1.0))
		else:
			_pad.draw_rect(r, Color(1, 1, 1, 0.28 if held else 0.12))
			_pad.draw_rect(r, Color(1, 1, 1, 0.35), false, 1.0)
			_draw_icon(name, r.get_center(), Color(1, 1, 1, 0.8))
		# Обучающая рамка у «Действия» — только когда его есть к чему применить.
		if name == _tutorial and (name != "action" or (hero and hero.can_act())):
			var t := fmod(_time, 1.2) / 1.2
			_pad.draw_rect(r.grow(4 + 8 * t), Color(1, 0.9, 0.5, 1.0 - t), false, 2.0)
	_draw_inventory()
	_pad.draw_rect(MENU_BUTTON, Color(1, 1, 1, 0.12))
	for k in 3:
		_pad.draw_rect(Rect2(MENU_BUTTON.position + Vector2(9, 10 + k * 6), Vector2(16, 2)), Color(1, 1, 1, 0.8))
	_pad.draw_rect(HINT_BUTTON, Color(0.4, 0.8, 1.0, 0.25))
	_pad.draw_string(font, HINT_BUTTON.position + Vector2(0, 25), "?", HORIZONTAL_ALIGNMENT_CENTER, HINT_BUTTON.size.x, 20, Color.WHITE)
	if _next_hint_needs_ad():
		# Значок «смотреть ролик»: треугольник в уголке кнопки.
		var c := HINT_BUTTON.position + Vector2(HINT_BUTTON.size.x - 6, HINT_BUTTON.size.y - 6)
		_pad.draw_circle(c, 6.0, Color(1, 0.75, 0.2))
		_pad.draw_colored_polygon(PackedVector2Array([c + Vector2(-2, -3), c + Vector2(3, 0), c + Vector2(-2, 3)]), Color(0.15, 0.1, 0.05))


## Артефакты героя: ячейки внизу между кнопками ходьбы и действия.
func _draw_inventory() -> void:
	var hero := level.get_node_or_null("Hero")
	var items: Array[String] = []
	if hero and hero.has_key:
		items.append("key")
	if hero and hero.has_coal:
		items.append("coal")
	var slot := Vector2(40, 40)
	var x0 := 320.0 - (INVENTORY_SLOTS * slot.x + (INVENTORY_SLOTS - 1) * 6.0) / 2.0
	for i in INVENTORY_SLOTS:
		var r := Rect2(Vector2(x0 + i * (slot.x + 6.0), 304), slot)
		_pad.draw_rect(r, Color(0, 0, 0, 0.35))
		_pad.draw_rect(r, Color(1, 0.9, 0.6, 0.25), false, 1.0)
		if i < items.size():
			_pad.draw_set_transform(r.get_center(), 0.0, Vector2(2, 2))
			_pad.draw_circle(Vector2.ZERO, 8.0, Color(1, 0.85, 0.3, 0.15))
			if items[i] == "coal":
				preload("res://scripts/coal_vessel.gd").draw_coal(_pad, Vector2.ZERO)
			else:
				preload("res://scripts/key_item.gd").draw_key(_pad, Vector2(-1, 0))
			_pad.draw_set_transform(Vector2.ZERO)


func _draw_icon(name: String, c: Vector2, color: Color) -> void:
	match name:
		"left":
			_pad.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, 0), c + Vector2(8, -11), c + Vector2(8, 11)]), color)
		"right":
			_pad.draw_colored_polygon(PackedVector2Array([c + Vector2(10, 0), c + Vector2(-8, -11), c + Vector2(-8, 11)]), color)
		"jump":
			_pad.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -10), c + Vector2(11, 8), c + Vector2(-11, 8)]), color)
		"down":
			# Вниз по лестнице: перевёрнутый треугольник, как у прыжка.
			_pad.draw_colored_polygon(PackedVector2Array([c + Vector2(0, 10), c + Vector2(11, -8), c + Vector2(-11, -8)]), color)
		"action":
			_pad.draw_circle(c, 9.0, color)
			_pad.draw_circle(c, 5.0, Color(0, 0, 0, 0.4))
