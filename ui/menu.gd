extends Control
## Стартовый экран прототипа: название и выбор любого уровня.

const Art := preload("res://scripts/art.gd")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var back := TextureRect.new()
	back.texture = Art.back_wall()
	back.stretch_mode = TextureRect.STRETCH_TILE
	back.size = Vector2(640, 360)
	back.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(back)
	var title := Label.new()
	title.text = "Hidden Chambers"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(640, 40)
	title.position = Vector2(0, 28)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("e2bf78"))
	add_child(title)
	var sub := Label.new()
	sub.text = "Прототип · мир «Пирамида» · выбери уровень"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(640, 20)
	sub.position = Vector2(0, 72)
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color("b49c7c"))
	add_child(sub)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.position = Vector2(110, 120)
	add_child(grid)
	for i in Game.LEVELS.size():
		var b := Button.new()
		b.text = str(i + 1)
		b.custom_minimum_size = Vector2(64, 56)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(Game.open_level.bind(i))
		grid.add_child(b)
