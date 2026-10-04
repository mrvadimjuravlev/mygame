extends RefCounted
## Общий вид кнопок меню: песчаник с тёмной обводкой.

const TEXT := Color("ffe7a3")
const TEXT_DIM := Color("b49c7c")


static func button(text: String, size: Vector2, font_size := 18) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("6e5a44"))
	b.add_theme_stylebox_override("normal", _box(Color("6e5236"), Color("2a1d12")))
	b.add_theme_stylebox_override("hover", _box(Color("80603f"), Color("2a1d12")))
	b.add_theme_stylebox_override("pressed", _box(Color("5a4229"), Color("e2bf78")))
	b.add_theme_stylebox_override("disabled", _box(Color("3b2d20"), Color("231910")))
	b.pressed.connect(func() -> void: Sfx.play("ui"))
	return b


static func label(text: String, pos: Vector2, width: float, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = pos
	l.size = Vector2(width, font_size + 12)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


static func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(2)
	s.border_width_top = 1
	s.border_width_bottom = 3
	s.set_content_margin_all(4)
	return s
