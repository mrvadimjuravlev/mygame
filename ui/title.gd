extends Node2D
## Главное меню: зал пирамиды в полумраке, герой у факела, кнопки «Играть», «Уровни», «Настройки».

const Art := preload("res://scripts/art.gd")
const Style := preload("res://ui/style.gd")


func _ready() -> void:
	var back := Polygon2D.new()
	back.polygon = PackedVector2Array([Vector2(0, 0), Vector2(640, 0), Vector2(640, 360), Vector2(0, 360)])
	back.texture = Art.back_wall()
	back.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(back)
	var floor := Node2D.new()
	floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor.draw.connect(func() -> void:
		var poly := PackedVector2Array([Vector2(0, 300), Vector2(640, 300), Vector2(640, 360), Vector2(0, 360)])
		Art.draw_textured(floor, poly, Art.plaster())
		Art.draw_crumbled(floor, poly, 4)
		floor.draw_rect(Rect2(0, 300, 640, 2), Color(1, 0.9, 0.7, 0.25)))
	add_child(floor)
	for i in 2:
		var g := Node2D.new()
		g.set_script(preload("res://scripts/glyphs.gd"))
		g.columns = 2
		g.signs = PackedStringArray(["eye", "sun", "ankh", "bird"] if i == 0 else ["reed", "wave", "bird", "eye"])
		g.position = Vector2(40 + i * 524, 170)
		add_child(g)
	for x in [100.0, 540.0]:
		var torch := Area2D.new()
		torch.set_script(preload("res://scripts/torch.gd"))
		torch.start_lit = true
		torch.position = Vector2(x, 150)
		add_child(torch)
	var hero := CharacterBody2D.new()
	hero.set_script(preload("res://scripts/hero.gd"))
	hero.position = Vector2(150, 300)
	hero.scale = Vector2(2, 2)
	add_child(hero)
	# Пол и стены по краям: героем можно побродить по залу стрелками.
	var walls := StaticBody2D.new()
	for r in [Rect2(-20, 300, 680, 40), Rect2(-20, 0, 20, 300), Rect2(640, 0, 20, 300)]:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = r.size
		shape.shape = rect
		shape.position = r.get_center()
		walls.add_child(shape)
	add_child(walls)
	var mod := CanvasModulate.new()
	mod.color = Color(0.5, 0.43, 0.4)
	add_child(mod)

	var ui := CanvasLayer.new()
	add_child(ui)
	ui.add_child(Style.label("Hidden Chambers", Vector2(0, 34), 640, 40, Color("e2bf78")))
	ui.add_child(Style.label(Game.t("Мир 1 · Пирамида"), Vector2(0, 86), 640, 15, Style.TEXT_DIM))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.position = Vector2(220, 136)
	ui.add_child(column)
	var play := Style.button(_play_text(), Vector2(200, 44), 20)
	play.pressed.connect(func() -> void: Game.open_level(Game.continue_index()))
	column.add_child(play)
	var levels := Style.button(Game.t("Уровни"), Vector2(200, 40))
	levels.pressed.connect(func() -> void: get_tree().change_scene_to_file.call_deferred(Game.MENU_SCENE))
	column.add_child(levels)
	var settings := Style.button(Game.t("Настройки"), Vector2(200, 40))
	settings.pressed.connect(func() -> void: get_tree().change_scene_to_file.call_deferred(Game.SETTINGS_SCENE))
	column.add_child(settings)
	ui.add_child(Style.label(Game.t("Прототип"), Vector2(0, 274), 640, 11, Color(1, 1, 1, 0.3)))


func _play_text() -> String:
	if Game.passed.is_empty():
		return Game.t("Играть")
	if Game.passed.size() >= Game.LEVELS.size():
		return Game.t("Играть с начала")
	return Game.t("Продолжить · %d") % (Game.continue_index() + 1)
