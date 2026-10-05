extends Control
## Выбор уровня. Пройденные отмечены галочкой, следующий открыт, дальше — замок.
## Для проверки прототипа: пять касаний по заголовку открывают все уровни.

const Art := preload("res://scripts/art.gd")
const Style := preload("res://ui/style.gd")

var _grid: GridContainer
var _title_taps := 0
var _reset: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var back := TextureRect.new()
	back.texture = Art.back_wall()
	back.stretch_mode = TextureRect.STRETCH_TILE
	back.size = Vector2(640, 360)
	back.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	back.modulate = Color(0.75, 0.68, 0.62)
	add_child(back)
	var title := Style.label("Пирамида", Vector2(0, 22), 640, 28, Color("e2bf78"))
	title.mouse_filter = Control.MOUSE_FILTER_STOP
	title.gui_input.connect(_on_title_input)
	add_child(title)
	add_child(Style.label("%d из %d пройдено" % [Game.passed.size(), Game.LEVELS.size()], Vector2(0, 62), 640, 13, Style.TEXT_DIM))
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.position = Vector2(110, 92)
	add_child(_grid)
	_fill()
	var back_button := Style.button("‹ Назад", Vector2(110, 36), 16)
	back_button.position = Vector2(16, 308)
	back_button.pressed.connect(Game.go_title)
	add_child(back_button)
	_reset = Style.button("Сбросить прогресс", Vector2(170, 36), 14)
	_reset.position = Vector2(454, 308)
	_reset.pressed.connect(_on_reset)
	add_child(_reset)


func _fill() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var next := Game.continue_index()
	for i in Game.LEVELS.size():
		var open := Game.is_unlocked(i)
		var done := Game.passed.has(i)
		var b := Style.button(str(i + 1) if open else "", Vector2(64, 56), 22)
		b.disabled = not open
		var mark := Control.new()
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.size = Vector2(64, 56)
		mark.draw.connect(_draw_mark.bind(mark, done, open))
		b.add_child(mark)
		if i == next and open and not done:
			b.add_theme_stylebox_override("normal", Style._box(Color("8a6a3f"), Color("ffe7a3")))
		b.pressed.connect(Game.open_level.bind(i))
		_grid.add_child(b)


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


func _on_reset() -> void:
	# Защита от случайного нажатия: сбрасывает второе касание.
	if _reset.text != "Точно сбросить?":
		_reset.text = "Точно сбросить?"
		return
	Game.reset_progress()
	get_tree().reload_current_scene()
