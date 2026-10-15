extends Control
## Выбор уровня. Пройденные отмечены галочкой, следующий открыт, дальше — замок.
## Уровни стоят страницами по 18 (три ряда по шесть); если их больше, страницы листают пальцем
## (или колесом мыши). Сброс прогресса — в настройках.
## Для проверки прототипа: пять касаний по заголовку открывают все уровни.

const Art := preload("res://scripts/art.gd")
const Style := preload("res://ui/style.gd")

const COLUMNS := 6
const ROWS := 3
const PER_PAGE := COLUMNS * ROWS
const CELL := Vector2(64, 56)
const H_SEP := 12.0
const V_SEP := 10.0
## Ширина сетки страницы. Шаг между страницами — во всю ширину экрана: ведёшь пальцем,
## текущие 18 уровней уезжают за край, следующие 18 въезжают на их место.
const PAGE_W := COLUMNS * CELL.x + (COLUMNS - 1) * H_SEP
const PAGE_STEP := 640.0
## Насколько сдвинуть страницу пальцем, чтобы она перелистнулась.
const FLIP_DISTANCE := 90.0
const VIEW_TOP := 88.0
const VIEW_H := ROWS * CELL.y + (ROWS - 1) * V_SEP + 8.0
const GOLD := Color("e2bf78")
const DARK := Color("1a120c")
## Сдвиг пальца, после которого касание считается прокруткой, а не нажатием уровня.
const DRAG_START := 8.0

var _strip: Control
var _bar: Control
var _title_taps := 0
var _scroll := 0.0
var _max_scroll := 0.0
var _velocity := 0.0
var _pressing := false
var _dragged := false
var _press_x := 0.0
var _last_x := 0.0
var _tween: Tween
## Страница, на которой было касание: от неё листаем на одну вперёд или назад.
var _start_page := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Фон в стиле локации: песчаник с иероглифами, сырое подземелье, замок, храм под водой.
	var back := preload("res://ui/world_backdrop.gd").new()
	back.theme_id = Game.world
	add_child(back)
	var title := Style.label(Game.t(Game.world_info().name), Vector2(0, 22), 640, 28, GOLD)
	title.mouse_filter = Control.MOUSE_FILTER_STOP
	title.gui_input.connect(_on_title_input)
	add_child(title)
	add_child(Style.label(Game.t("%d из %d пройдено") % [Game.passed_count(), Game.levels().size()], Vector2(0, 58), 640, 13, Style.TEXT_DIM))
	var view := Control.new()
	view.clip_contents = true
	view.position = Vector2(0, VIEW_TOP)
	view.size = Vector2(640, VIEW_H)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)
	_strip = Control.new()
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(_strip)
	# Полоса прокрутки: видна, только если страниц больше одной.
	_bar = Control.new()
	_bar.position = Vector2((640.0 - PAGE_W) / 2.0, VIEW_TOP + VIEW_H + 6)
	_bar.size = Vector2(PAGE_W, 4)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.draw.connect(_draw_bar)
	add_child(_bar)
	_fill()
	# Начать со страницы, где уровень, с которого продолжать.
	_set_scroll(int(Game.continue_index() / PER_PAGE) * PAGE_STEP)
	var back_button := Style.button(Game.t("‹ Назад"), Vector2(110, 36), 16)
	back_button.position = Vector2(16, 308)
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file.call_deferred(Game.WORLDS_SCENE))
	add_child(back_button)


func _fill() -> void:
	for child in _strip.get_children():
		child.queue_free()
	var count := Game.levels().size()
	var pages := maxi(1, ceili(count / float(PER_PAGE)))
	_max_scroll = (pages - 1) * PAGE_STEP
	var left := (640.0 - PAGE_W) / 2.0
	var next := Game.continue_index()
	for i in count:
		var open := Game.is_unlocked(i)
		var done := Game.is_passed(i)
		var b := Style.button(str(i + 1) if open else "", CELL, 22)
		var page := int(i / PER_PAGE)
		var cell := i % PER_PAGE
		b.position = Vector2(left + page * PAGE_STEP + (cell % COLUMNS) * (CELL.x + H_SEP),
				4 + int(cell / COLUMNS) * (CELL.y + V_SEP))
		b.disabled = not open
		var mark := Control.new()
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.size = CELL
		mark.draw.connect(_draw_mark.bind(mark, done, open))
		b.add_child(mark)
		if i == next and open and not done:
			b.add_theme_stylebox_override("normal", Style._box(Color("8a6a3f"), Color("ffe7a3")))
		b.pressed.connect(func() -> void:
			# Палец листал страницы, а не нажимал уровень.
			if not _dragged:
				Game.open_level(i))
		_strip.add_child(b)
	_bar.queue_redraw()


## Галочка у пройденного уровня, замок у закрытого (рисуем, шрифт может не знать значков).
func _draw_mark(c: Control, done: bool, open: bool) -> void:
	if done:
		var gold := Color("f2c14e")
		c.draw_polyline(PackedVector2Array([Vector2(46, 10), Vector2(50, 14), Vector2(57, 6)]), gold, 2.0)
	elif not open:
		var col := Color("6e5a44")
		c.draw_arc(Vector2(32, 24), 6.0, PI, TAU, 10, col, 2.0)
		c.draw_rect(Rect2(24, 24, 16, 12), col)
		c.draw_rect(Rect2(31, 28, 2, 4), Color("231910"))


func _on_title_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_title_taps += 1
		if _title_taps >= 5:
			_title_taps = 0
			Game.unlock_all = not Game.unlock_all
			Game.save()
			Sfx.play("key")
			_fill()


# --- Прокрутка страниц ----------------------------------------------------------

func _input(event: InputEvent) -> void:
	if _max_scroll <= 0.0:
		return
	if event is InputEventMouseButton:
		if event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT):
			_snap_to(_page() + 1)
		elif event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_LEFT):
			_snap_to(_page() - 1)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_press(event.pressed, event.position)
	elif event is InputEventScreenTouch and event.index == 0:
		_press(event.pressed, event.position)
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and _pressing:
		var x: float = event.position.x
		if not _dragged and absf(x - _press_x) > DRAG_START:
			_dragged = true
		if _dragged:
			_velocity = (_last_x - x) * 60.0
			_set_scroll(_scroll + _last_x - x)
		_last_x = x


func _press(down: bool, pos: Vector2) -> void:
	if down:
		# Касание вне страниц не листает.
		if pos.y < VIEW_TOP or pos.y > VIEW_TOP + VIEW_H:
			return
		if _tween:
			_tween.kill()
		_pressing = true
		_dragged = false
		_velocity = 0.0
		_start_page = _page()
		_press_x = pos.x
		_last_x = pos.x
	elif _pressing:
		_pressing = false
		# _dragged сбрасывается на следующем касании: кнопка уровня проверяет его в pressed.
		if _dragged:
			# Сдвинул заметно или бросил быстро — листаем на соседнюю страницу, иначе возвращаем.
			var shift := _scroll - _start_page * PAGE_STEP
			var target := _start_page
			if shift > FLIP_DISTANCE or _velocity > 400.0:
				target += 1
			elif shift < -FLIP_DISTANCE or _velocity < -400.0:
				target -= 1
			_snap_to(target)


func _page() -> int:
	return roundi(_scroll / PAGE_STEP)


func _snap_to(page: int) -> void:
	_velocity = 0.0
	var target := clampf(page * PAGE_STEP, 0.0, _max_scroll)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_scroll, _scroll, target, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_scroll(value: float) -> void:
	_scroll = clampf(value, 0.0, _max_scroll)
	_strip.position.x = -_scroll
	_bar.queue_redraw()


func _draw_bar() -> void:
	if _max_scroll <= 0.0:
		return
	var w := _bar.size.x
	var knob := w * PAGE_STEP / (PAGE_STEP + _max_scroll)
	var x := (w - knob) * _scroll / _max_scroll
	_bar.draw_rect(Rect2(0, 0, w, 4), Color(DARK, 0.6))
	_bar.draw_rect(Rect2(x, 0, knob, 4), Color(GOLD, 0.8))
