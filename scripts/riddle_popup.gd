extends CanvasLayer
## Всплывающее окно разговора со стражем: кто говорит, его слова и варианты ответа.
## Варианты — строки или знаки (glyph_mode). Перед знаками окно может показать их по одному (flash).
## Пока окно открыто, герой стоит, а касания не доходят до кнопок и руки.
## Выбор варианта — сигнал chosen(index); крестик закрывает окно — сигнал dismissed.

signal chosen(index: int)
signal dismissed

const GlyphsScript := preload("res://scripts/glyphs.gd")
const PANEL := Rect2(80, 34, 480, 292)
const CLOSE := Rect2(526, 40, 28, 28)
## Сколько секунд виден каждый знак, когда страж их показывает.
const FLASH_TIME := 0.9

var options: Array = []
var glyph_mode := false
## Знаки, которые игрок уже нажал (их видно под словами стража).
var picked := PackedStringArray()

var _speaker := ""
var _flash := PackedStringArray()
var _flash_time := 0.0
var _rects: Array[Rect2] = []
var _canvas: Control
var _speaker_label: Label
var _text_label: Label
var _icons: Node2D


func _ready() -> void:
	layer = 20
	visible = false
	_canvas = Control.new()
	_canvas.size = Vector2(640, 360)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_canvas)
	add_child(_canvas)
	_speaker_label = _label(16, Color("ffd98a"), Vector2(PANEL.position.x + 20, PANEL.position.y + 10), Vector2(400, 24))
	_text_label = _label(14, Color("f3e6c8"), Vector2(PANEL.position.x + 20, PANEL.position.y + 38), Vector2(440, 72))
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_icons = Node2D.new()
	add_child(_icons)


func _label(font_size: int, color: Color, pos: Vector2, size: Vector2) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


## Открыть окно: кто говорит, что говорит, варианты ответа. flash — знаки, которые сначала показываются по одному.
func open(speaker: String, text: String, choices: Array, glyphs := false, flash := PackedStringArray()) -> void:
	_speaker = speaker
	_speaker_label.text = Game.t(speaker)
	_text_label.text = Game.t(text)
	options = choices
	glyph_mode = glyphs
	picked = PackedStringArray()
	_flash = flash
	_flash_time = 0.0
	_layout()
	_set_hero_frozen(true)
	visible = true
	_refresh()


## Страж отвечает одной фразой; единственная кнопка «Дальше».
func say(text: String) -> void:
	_text_label.text = Game.t(text)
	options = ["Дальше"]
	glyph_mode = false
	_flash = PackedStringArray()
	_layout()
	_refresh()


func close() -> void:
	visible = false
	_set_hero_frozen(false)


## Сейчас показываются знаки: отвечать ещё нельзя.
func flashing() -> bool:
	return _flash_time < _flash.size() * FLASH_TIME


func _set_hero_frozen(value: bool) -> void:
	var hero := get_tree().get_first_node_in_group("hero")
	if hero:
		hero.frozen = value
		if value:
			hero.velocity = Vector2.ZERO
	for action in ["move_left", "move_right", "jump", "action"]:
		Input.action_release(action)


func _layout() -> void:
	_rects.clear()
	if glyph_mode:
		var size := Vector2(52, 56)
		var gap := 14.0
		var x0 := 320.0 - (options.size() * size.x + (options.size() - 1) * gap) / 2.0
		for i in options.size():
			_rects.append(Rect2(Vector2(x0 + i * (size.x + gap), PANEL.end.y - 76), size))
	else:
		var y := PANEL.end.y - 12 - options.size() * 36
		for i in options.size():
			_rects.append(Rect2(Vector2(PANEL.position.x + 24, y + i * 36), Vector2(PANEL.size.x - 48, 30)))


func _process(delta: float) -> void:
	if not visible:
		return
	if flashing():
		_flash_time += delta
		_refresh()


## Перерисовать окно и знаки на нём.
func _refresh() -> void:
	for child in _icons.get_children():
		child.queue_free()
	if flashing():
		# Страж показывает знак: крупно, посередине.
		var i := int(_flash_time / FLASH_TIME)
		var t := fmod(_flash_time, FLASH_TIME) / FLASH_TIME
		if t < 0.8:
			_icon(_flash[i], Vector2(320, 196), 3.0)
	else:
		for k in picked.size():
			_icon(picked[k], Vector2(320 - (picked.size() - 1) * 18 + k * 36, 160), 1.4)
		if glyph_mode:
			for k in options.size():
				_icon(options[k], _rects[k].get_center(), 2.0)
	_canvas.queue_redraw()


func _icon(sign: String, center: Vector2, scale: float) -> void:
	var g := Node2D.new()
	g.set_script(GlyphsScript)
	g.columns = 1
	g.signs = PackedStringArray([sign])
	g.scale = Vector2(scale, scale)
	g.position = center - Vector2(10, 11) * scale
	_icons.add_child(g)


func _draw_canvas() -> void:
	var font := ThemeDB.fallback_font
	_canvas.draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.55))
	_canvas.draw_rect(PANEL, Color("1d140d"))
	_canvas.draw_rect(PANEL, Color("b08a57"), false, 2.0)
	_canvas.draw_rect(PANEL.grow(-4), Color("5a4229"), false, 1.0)
	# Крестик: уйти, не отвечая (например, сначала поискать ответ).
	_canvas.draw_rect(CLOSE, Color(1, 1, 1, 0.08))
	_canvas.draw_line(CLOSE.position + Vector2(8, 8), CLOSE.end - Vector2(8, 8), Color("e2bf78"), 2.0)
	_canvas.draw_line(CLOSE.position + Vector2(CLOSE.size.x - 8, 8), CLOSE.position + Vector2(8, CLOSE.size.y - 8), Color("e2bf78"), 2.0)
	if flashing():
		return
	for i in _rects.size():
		var r := _rects[i]
		_canvas.draw_rect(r, Color("3b2a1a"))
		_canvas.draw_rect(r, Color("c9a35b"), false, 1.0)
		if not glyph_mode:
			_canvas.draw_string(font, r.position + Vector2(10, 20), "%d. %s" % [i + 1, Game.t(str(options[i]))] if options.size() > 1 else Game.t(str(options[i])), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, 14, Color("f3e6c8"))


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()
		if event is InputEventScreenTouch and event.pressed:
			_touch(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		var n: int = event.physical_keycode - KEY_1
		if n >= 0 and n < options.size() and not flashing():
			_choose(n)
		elif event.physical_keycode == KEY_ESCAPE:
			_dismiss()
		elif options.size() == 1 and event.physical_keycode in [KEY_ENTER, KEY_E, KEY_SPACE]:
			_choose(0)


func _touch(pos: Vector2) -> void:
	if CLOSE.grow(4).has_point(pos):
		_dismiss()
		return
	if flashing():
		return
	for i in _rects.size():
		if _rects[i].grow(2).has_point(pos):
			_choose(i)
			return


func _choose(i: int) -> void:
	Sfx.play("ui")
	chosen.emit(i)


func _dismiss() -> void:
	Sfx.play("ui")
	close()
	dismissed.emit()
