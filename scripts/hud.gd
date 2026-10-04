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
const MENU_BUTTON := Rect2(558, 8, 34, 34)

var level: Node

var _finger_button := {}  # индекс пальца -> имя кнопки
var _finger_hand := {}    # индекс пальца -> {rune, last}
var _hint_index := -1
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

	var title := Label.new()
	title.text = "%d. %s" % [level.level_number, level.slogan]
	title.position = Vector2(10, 8)
	title.add_theme_font_size_override("font_size", 12)
	title.modulate = Color(1, 1, 1, 0.7)
	add_child(title)

	_slogan = Label.new()
	_slogan.text = level.slogan
	_slogan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slogan.size = Vector2(640, 40)
	_slogan.position = Vector2(0, 110)
	_slogan.add_theme_font_size_override("font_size", 28)
	_slogan.add_theme_color_override("font_color", Color("ffe7a3"))
	add_child(_slogan)
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(_slogan, "modulate:a", 0.0, 0.6)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hint_label.size = Vector2(440, 40)
	_hint_label.position = Vector2(100, 48)
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", Color("cfefff"))
	add_child(_hint_label)


func _process(delta: float) -> void:
	_time += delta
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
		get_tree().change_scene_to_file.call_deferred(Game.MENU_SCENE)
		return
	if HINT_BUTTON.grow(4).has_point(pos):
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
		data.last = world


func _touch_up(index: int) -> void:
	if _finger_button.has(index):
		Input.action_release(ACTIONS[_finger_button[index]])
		_finger_button.erase(index)
	_finger_hand.erase(index)


func _to_world(screen_pos: Vector2) -> Vector2:
	return level.get_viewport().get_canvas_transform().affine_inverse() * screen_pos


func _show_next_hint() -> void:
	if level.hints.is_empty():
		return
	_hint_index = mini(_hint_index + 1, level.hints.size() - 1)
	_hint_label.text = "Подсказка %d: %s" % [_hint_index + 1, level.hints[_hint_index]]


func _draw_pad() -> void:
	var font := ThemeDB.fallback_font
	for name in BUTTONS:
		var r: Rect2 = BUTTONS[name]
		var held := Input.is_action_pressed(ACTIONS[name])
		_pad.draw_rect(r, Color(1, 1, 1, 0.28 if held else 0.12))
		_pad.draw_rect(r, Color(1, 1, 1, 0.35), false, 1.0)
		_draw_icon(name, r.get_center(), Color(1, 1, 1, 0.8))
		if name == _tutorial:
			var t := fmod(_time, 1.2) / 1.2
			_pad.draw_rect(r.grow(4 + 8 * t), Color(1, 0.9, 0.5, 1.0 - t), false, 2.0)
	var hero := level.get_node_or_null("Hero")
	if hero and hero.has_key:
		_pad.draw_rect(Rect2(10, 28, 24, 18), Color(0, 0, 0, 0.3))
		preload("res://scripts/key_item.gd").draw_key(_pad, Vector2(22, 37))
	_pad.draw_rect(MENU_BUTTON, Color(1, 1, 1, 0.12))
	for k in 3:
		_pad.draw_rect(Rect2(MENU_BUTTON.position + Vector2(9, 10 + k * 6), Vector2(16, 2)), Color(1, 1, 1, 0.8))
	_pad.draw_rect(HINT_BUTTON, Color(0.4, 0.8, 1.0, 0.25))
	_pad.draw_string(font, HINT_BUTTON.position + Vector2(0, 25), "?", HORIZONTAL_ALIGNMENT_CENTER, HINT_BUTTON.size.x, 20, Color.WHITE)


func _draw_icon(name: String, c: Vector2, color: Color) -> void:
	match name:
		"left":
			_pad.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, 0), c + Vector2(8, -11), c + Vector2(8, 11)]), color)
		"right":
			_pad.draw_colored_polygon(PackedVector2Array([c + Vector2(10, 0), c + Vector2(-8, -11), c + Vector2(-8, 11)]), color)
		"jump":
			_pad.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -10), c + Vector2(11, 8), c + Vector2(-11, 8)]), color)
		"action":
			_pad.draw_circle(c, 9.0, color)
			_pad.draw_circle(c, 5.0, Color(0, 0, 0, 0.4))
