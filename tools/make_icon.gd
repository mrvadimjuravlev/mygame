extends SceneTree
## Рисует иконку приложения (пиксель-арт 48x48, увеличенный до 192x192): пирамида и светящаяся дверь.
## Запуск: godot --headless --path . -s tools/make_icon.gd


func _initialize() -> void:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	# Ночное небо.
	for y in 48:
		var c := Color("1b1530").lerp(Color("3a2a3f"), y / 47.0)
		for x in 48:
			img.set_pixel(x, y, c)
	for p in [Vector2i(6, 6), Vector2i(40, 9), Vector2i(31, 4), Vector2i(12, 15), Vector2i(43, 18)]:
		img.set_pixel(p.x, p.y, Color("fff3cf"))
	# Пирамида ступенями.
	for y in range(12, 42):
		var half := (y - 12) + 1
		for x in range(24 - half, 24 + half):
			if x < 0 or x >= 48:
				continue
			var lit := x < 24
			var c := Color("d8b06c") if lit else Color("a37b4b")
			if (y - 12) % 4 == 0:
				c = c.darkened(0.2)
			img.set_pixel(x, y, c)
	# Песок.
	for y in range(42, 48):
		for x in 48:
			img.set_pixel(x, y, Color("c9a35b") if (x + y) % 5 else Color("b48e4e"))
	# Дверь со светом.
	for y in range(32, 42):
		for x in range(21, 27):
			img.set_pixel(x, y, Color("ffd98a") if x in [21, 26] or y == 32 else Color("fff3cf"))
	img.resize(192, 192, Image.INTERPOLATE_NEAREST)
	img.save_png("res://icon.png")
	print("Иконка сохранена")
	quit()
