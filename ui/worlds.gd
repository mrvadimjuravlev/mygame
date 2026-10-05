extends Control
## Выбор локации: четыре мира карточками. Список и уровни — Game.WORLDS; локация без уровней — «Скоро».

const Art := preload("res://scripts/art.gd")
const Style := preload("res://ui/style.gd")

const CARD := Vector2(136, 196)
const GOLD := Color("e2bf78")
const DARK := Color("1a120c")


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
	for i in Game.WORLDS.size():
		var w: Dictionary = Game.WORLDS[i]
		var open: bool = not w.levels.is_empty()
		var card := Style.button("", CARD)
		card.position = Vector2(24 + i * (CARD.x + 16), 78)
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
		add_child(card)
	var back_button := Style.button(Game.t("‹ Назад"), Vector2(110, 36), 16)
	back_button.position = Vector2(16, 308)
	back_button.pressed.connect(Game.go_title)
	add_child(back_button)


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
	if not open:
		var lock := Color("b49c7c")
		c.draw_arc(o + Vector2(0, -4), 9.0, PI, TAU, 12, lock, 3.0)
		c.draw_rect(Rect2(o.x - 12, o.y - 4, 24, 18), lock)
		c.draw_rect(Rect2(o.x - 2, o.y + 1, 4, 7), DARK)
