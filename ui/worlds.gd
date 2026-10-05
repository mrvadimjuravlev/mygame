extends Control
## Выбор локации: миры карточками в ленте, ленту листают пальцем (или колесом мыши).
## Список и уровни — Game.WORLDS; локация без уровней — «Скоро».

const Art := preload("res://scripts/art.gd")
const Style := preload("res://ui/style.gd")

const CARD := Vector2(136, 196)
const GOLD := Color("e2bf78")
const DARK := Color("1a120c")
const GAP := 16.0
const MARGIN := 24.0
## Сдвиг пальца, после которого касание считается прокруткой, а не нажатием карточки.
const DRAG_START := 8.0

var _strip: Control
var _bar: Control
var _scroll := 0.0
var _max_scroll := 0.0
var _velocity := 0.0
var _pressing := false
var _dragged := false
var _press_x := 0.0
var _last_x := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var back := TextureRect.new()
	back.texture = Art.back_wall()
	back.stretch_mode = TextureRect.STRETCH_TILE
	back.size = Vector2(640, 360)
	back.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	back.modulate = Color(0.75, 0.68, 0.62)
	add_child(back)
	add_child(Style.label(Game.t("Выбери локацию"), Vector2(0, 22), 640, 28, GOLD))
	var view := Control.new()
	view.clip_contents = true
	view.position = Vector2(0, 70)
	view.size = Vector2(640, 216)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)
	_strip = Control.new()
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(_strip)
	var count := Game.WORLDS.size()
	_max_scroll = maxf(0.0, MARGIN * 2 + count * CARD.x + (count - 1) * GAP - 640.0)
	for i in count:
		var w: Dictionary = Game.WORLDS[i]
		var open: bool = not w.levels.is_empty()
		var card := Style.button("", CARD)
		card.position = Vector2(MARGIN + i * (CARD.x + GAP), 8)
		card.disabled = not open
		if open:
			card.pressed.connect(func() -> void:
				Game.world = w.id
				Game.save()
				get_tree().change_scene_to_file.call_deferred(Game.MENU_SCENE))
		var face := Control.new()
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.size = CARD
		face.draw.connect(_draw_emblem.bind(face, w.id, open))
		card.add_child(face)
		var name_label := Style.label(Game.t(w.name), Vector2(0, 128), CARD.x, 15, Style.TEXT if open else Color("8a7458"))
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name_label)
		var note := Game.t("%d из %d пройдено") % [Game.passed_count(w.id), w.levels.size()] if open else Game.t("Скоро")
		var note_label := Style.label(note, Vector2(0, 166), CARD.x, 11, Style.TEXT_DIM if open else Color("6e5a44"))
		note_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(note_label)
		_strip.add_child(card)
	# Полоса прокрутки: показывает, что карточек больше, чем помещается.
	_bar = Control.new()
	_bar.position = Vector2(MARGIN, 292)
	_bar.size = Vector2(640 - MARGIN * 2, 4)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.draw.connect(_draw_bar)
	add_child(_bar)
	# Начать с выбранной локации.
	var selected := 0
	for i in count:
		if Game.WORLDS[i].id == Game.world:
			selected = i
	_set_scroll(selected * (CARD.x + GAP) - (640.0 - CARD.x) / 2 + MARGIN)
	var back_button := Style.button(Game.t("‹ Назад"), Vector2(110, 36), 16)
	back_button.position = Vector2(16, 308)
	back_button.pressed.connect(Game.go_title)
	add_child(back_button)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			_set_scroll(_scroll + 40.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			_set_scroll(_scroll - 40.0)
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
	# Касание вне ленты не листает.
	if down and (pos.y < 70 or pos.y > 286):
		return
	if down:
		_pressing = true
		_dragged = false
		_velocity = 0.0
		_press_x = pos.x
		_last_x = pos.x
	else:
		_pressing = false
		# _dragged сбрасывается на следующем касании: карточка проверяет его в pressed.


func _process(delta: float) -> void:
	# Лента продолжает катиться после броска пальцем и плавно останавливается.
	if not _pressing and absf(_velocity) > 1.0:
		_set_scroll(_scroll + _velocity * delta)
		_velocity *= exp(-5.0 * delta)


func _set_scroll(value: float) -> void:
	_scroll = clampf(value, 0.0, _max_scroll)
	if _scroll == 0.0 or _scroll == _max_scroll:
		_velocity = 0.0
	_strip.position.x = -_scroll
	_bar.queue_redraw()


func _draw_bar() -> void:
	if _max_scroll <= 0.0:
		return
	var w := _bar.size.x
	var view := 640.0
	var knob := w * view / (view + _max_scroll)
	var x := (w - knob) * _scroll / _max_scroll
	_bar.draw_rect(Rect2(0, 0, w, 4), Color(DARK, 0.6))
	_bar.draw_rect(Rect2(x, 0, knob, 4), Color(GOLD, 0.8))


## Рисунок локации в верхней части карточки. Закрытые — приглушённые, с замком.
func _draw_emblem(c: Control, emblem: String, open: bool) -> void:
	var a := 1.0 if open else 0.35
	var o := Vector2(CARD.x / 2, 74)
	# Окно-рамка под рисунок.
	c.draw_rect(Rect2(10, 10, CARD.x - 20, 110), Color(DARK, 0.6))
	match emblem:
		"pyramid":
			c.draw_circle(o + Vector2(30, -40), 9.0, Color(Color("ffd98a"), a))
			for i in 5:
				var w := 20.0 + i * 18.0
				c.draw_rect(Rect2(o.x - w / 2, o.y - 30 + i * 12, w, 12), Color(Color("c9a35b"), a))
				c.draw_rect(Rect2(o.x - w / 2, o.y - 30 + i * 12, w, 1), Color(GOLD.lightened(0.2), a))
			c.draw_rect(Rect2(o.x - 5, o.y + 14, 10, 16), Color(DARK, a))
			c.draw_rect(Rect2(14, o.y + 30, CARD.x - 28, 6), Color(Color("a8894f"), a))
		"dungeon":
			# Каменная арка с решёткой и факелом.
			var stone := Color(Color("6e6a64"), a)
			c.draw_rect(Rect2(o.x - 36, o.y - 30, 72, 66), stone)
			c.draw_circle(o + Vector2(0, -6), 22.0, Color(DARK, a))
			c.draw_rect(Rect2(o.x - 22, o.y - 6, 44, 42), Color(DARK, a))
			for k in 5:
				c.draw_rect(Rect2(o.x - 18 + k * 9, o.y - 24, 2, 60), Color(Color("4a4642"), a))
			c.draw_rect(Rect2(o.x - 22, o.y + 4, 44, 2), Color(Color("4a4642"), a))
			c.draw_rect(Rect2(o.x + 40, o.y - 22, 4, 10), Color(Color("5e4630"), a))
			c.draw_circle(o + Vector2(42, -26), 4.0, Color(Color("ff9a3c"), a))
		"castle":
			var wall := Color(Color("8a8f9a"), a)
			c.draw_rect(Rect2(o.x - 30, o.y - 14, 60, 50), wall)
			c.draw_rect(Rect2(o.x - 46, o.y - 34, 18, 70), wall)
			c.draw_rect(Rect2(o.x + 28, o.y - 34, 18, 70), wall)
			for k in 3:
				c.draw_rect(Rect2(o.x - 46 + k * 7, o.y - 40, 4, 6), wall)
				c.draw_rect(Rect2(o.x + 28 + k * 7, o.y - 40, 4, 6), wall)
				c.draw_rect(Rect2(o.x - 28 + k * 20, o.y - 20, 8, 6), wall)
			c.draw_rect(Rect2(o.x - 8, o.y + 14, 16, 22), Color(DARK, a))
			c.draw_line(o + Vector2(37, -40), o + Vector2(37, -56), Color(Color("5e4630"), a), 1.5)
			c.draw_colored_polygon(PackedVector2Array([o + Vector2(38, -56), o + Vector2(50, -52), o + Vector2(38, -48)]), Color(Color("d9534f"), a))
		"temple":
			# Колонны храма, наполовину в воде.
			var col := Color(Color("7fa89a"), a)
			c.draw_colored_polygon(PackedVector2Array([o + Vector2(-44, -24), o + Vector2(0, -42), o + Vector2(44, -24)]), col)
			c.draw_rect(Rect2(o.x - 44, o.y - 24, 88, 6), col)
			for k in 4:
				c.draw_rect(Rect2(o.x - 38 + k * 24, o.y - 18, 8, 50), col)
			c.draw_rect(Rect2(14, o.y + 8, CARD.x - 28, 30), Color(Color("2f6f8f"), 0.8 * a))
			for k in 3:
				var y := o.y + 12 + k * 8
				for x in range(18, int(CARD.x) - 22, 16):
					c.draw_line(Vector2(x, y), Vector2(x + 8, y - 2), Color(Color("8fd0e8"), a), 1.0)
		"ice":
			# Ледяная пещера: свод, сосульки и кристаллы на полу.
			var ice := Color(Color("a9d8ec"), a)
			c.draw_rect(Rect2(14, 14, CARD.x - 28, 14), Color(Color("5f8fa8"), a))
			for k in 7:
				var x := 18.0 + k * 15.0
				c.draw_colored_polygon(PackedVector2Array([Vector2(x, 28), Vector2(x + 10, 28), Vector2(x + 5, 40 + (k % 3) * 8)]), ice)
			c.draw_rect(Rect2(14, o.y + 30, CARD.x - 28, 6), Color(Color("5f8fa8"), a))
			for k in 3:
				var x := 30.0 + k * 34.0
				var h := 18.0 + (k % 2) * 12.0
				c.draw_colored_polygon(PackedVector2Array([Vector2(x - 7, o.y + 30), Vector2(x, o.y + 30 - h), Vector2(x + 7, o.y + 30)]), Color(Color("dff4fb"), a))
		"volcano":
			# Вулкан: конус, лава в жерле, дым и красное небо.
			c.draw_rect(Rect2(10, 10, CARD.x - 20, 110), Color(Color("3a1610"), 0.6 * a))
			c.draw_colored_polygon(PackedVector2Array([o + Vector2(-54, 36), o + Vector2(-14, -26), o + Vector2(14, -26), o + Vector2(54, 36)]), Color(Color("4a3a34"), a))
			c.draw_rect(Rect2(o.x - 14, o.y - 28, 28, 5), Color(Color("ff6a2a"), a))
			c.draw_colored_polygon(PackedVector2Array([o + Vector2(-4, -24), o + Vector2(4, -24), o + Vector2(10, 20), o + Vector2(2, 36), o + Vector2(-6, 10)]), Color(Color("ff8a3a"), a))
			for k in 3:
				c.draw_circle(o + Vector2(-6 + k * 9, -38 - k * 9), 6.0 + k * 2.0, Color(Color("6a5a56"), 0.8 * a))
			c.draw_rect(Rect2(14, o.y + 30, CARD.x - 28, 6), Color(Color("ff6a2a"), 0.7 * a))
	if not open:
		var lock := Color("b49c7c")
		c.draw_arc(o + Vector2(0, -4), 9.0, PI, TAU, 12, lock, 3.0)
		c.draw_rect(Rect2(o.x - 12, o.y - 4, 24, 18), lock)
		c.draw_rect(Rect2(o.x - 2, o.y + 1, 4, 7), DARK)
