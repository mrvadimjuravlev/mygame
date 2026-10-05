extends Control
## Настройки: язык (русский / English) и звук. Выбор сохраняется сразу.

const Art := preload("res://scripts/art.gd")
const Style := preload("res://ui/style.gd")
const SELECTED := Color("8a6a3f")
const BORDER := Color("ffe7a3")


func _ready() -> void:
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var back := TextureRect.new()
	back.texture = Art.back_wall()
	back.stretch_mode = TextureRect.STRETCH_TILE
	back.size = Vector2(640, 360)
	back.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	back.modulate = Color(0.75, 0.68, 0.62)
	add_child(back)
	add_child(Style.label(Game.t("Настройки"), Vector2(0, 22), 640, 28, Color("e2bf78")))
	_row(Game.t("Язык"), 110, [["Русский", Game.lang == "ru", func() -> void: _set_lang("ru")], ["English", Game.lang == "en", func() -> void: _set_lang("en")]])
	_row(Game.t("Звук"), 180, [[Game.t("Вкл"), Sfx.enabled, func() -> void: _set_sound(true)], [Game.t("Выкл"), not Sfx.enabled, func() -> void: _set_sound(false)]])
	var back_button := Style.button(Game.t("‹ Назад"), Vector2(110, 36), 16)
	back_button.position = Vector2(16, 308)
	back_button.pressed.connect(Game.go_title)
	add_child(back_button)


## Строка настройки: подпись слева и кнопки выбора; выбранная подсвечена.
func _row(caption: String, y: float, options: Array) -> void:
	var label := Style.label(caption, Vector2(90, y + 8), 140, 18, Style.TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(label)
	for i in options.size():
		var opt: Array = options[i]
		var b := Style.button(opt[0], Vector2(130, 44), 18)
		b.position = Vector2(250 + i * 145, y)
		if opt[1]:
			b.add_theme_stylebox_override("normal", Style._box(SELECTED, BORDER))
			b.add_theme_stylebox_override("hover", Style._box(SELECTED, BORDER))
		b.pressed.connect(opt[2])
		add_child(b)


func _set_lang(value: String) -> void:
	Game.set_lang(value)
	_build.call_deferred()


func _set_sound(value: bool) -> void:
	Sfx.enabled = value
	Game.save()
	_build.call_deferred()
