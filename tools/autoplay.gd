extends SceneTree
## Автотест: проходит уровни 1–6 так, как это сделал бы игрок, — нажатиями кнопок и касаниями.
## Запуск: godot --headless --path . -s tools/autoplay.gd

var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file("res://levels/level_01.tscn")
	await _frames(5)
	var solvers := [_solve_01, _solve_02, _solve_03, _solve_04, _solve_05, _solve_06, _solve_07, _solve_08, _solve_09, _solve_10, _solve_11, _solve_12, _solve_13, _solve_14]
	for i in solvers.size():
		# Ждём, пока нужный уровень действительно загрузится.
		var expected: String = "res://levels/level_%02d.tscn" % (i + 1)
		for f in 120:
			if current_scene and current_scene.scene_file_path == expected:
				break
			await physics_frame
		await _frames(5)
		var start_path := current_scene.scene_file_path
		var label := "Уровень %d" % (i + 1)
		await solvers[i].call()
		var ok := await _wait_scene_change(start_path, 900)
		_release_all()
		print(label, ": ", "пройден" if ok else "НЕ ПРОЙДЕН")
		if not ok:
			var h := current_scene.get_node_or_null("Hero")
			if h: print("  герой ", h.global_position, " right=", Input.is_action_pressed("move_right"), " exit open=", current_scene.get_node("Exit").is_open, " amt=", current_scene.get_node("Exit")._open_amount, " bodies=", current_scene.get_node("Exit").get_overlapping_bodies())
			_failed = true
			break
		await _frames(5)
	if not _failed:
		print("Финальный экран: ", current_scene.scene_file_path)
	quit(1 if _failed else 0)


# --- Решения уровней ------------------------------------------------------

func _solve_01() -> void:
	Input.action_press("move_right")


func _solve_02() -> void:
	Input.action_press("move_right")
	_spam_jump()


func _solve_03() -> void:
	Input.action_press("move_right")
	await _until(func() -> bool: return _hero().global_position.x >= 365, true)
	Input.action_release("move_right")
	await _frames(10)
	_press("action")
	await _frames(60)
	Input.action_press("move_right")
	_spam_jump()


func _solve_04() -> void:
	await _tap(Vector2(336, 225))
	await _frames(50)
	Input.action_press("move_right")


func _solve_05() -> void:
	await _drag(Vector2(320, 120), Vector2(320, 300), 20)
	await _frames(10)
	Input.action_press("move_right")
	_spam_jump()


func _solve_06() -> void:
	await _drag(Vector2(150, 260), Vector2(470, 260), 30)
	await _frames(10)
	Input.action_press("move_right")
	await _until(func() -> bool:
		var p := _hero().global_position
		return p.x >= 458 and p.y <= 241 and _hero().is_on_floor(), true)
	Input.action_release("move_right")
	await _walk_to(470.0)
	Input.action_press("jump")
	await _frames(14)  # вершина прыжка — рядом с рычагом
	_press("action")
	Input.action_release("jump")
	await _frames(60)
	Input.action_press("move_right")


func _solve_07() -> void:
	await _walk_to(150.0)  # встал на плиту — она нажимается
	print("  плита нажата: ", current_scene.get_node("Button").pulled)
	await _frames(70)  # камень опускается
	await _walk_to(225.0)
	await _jump_right()  # на камень, ключ подбирается
	await _walk_to(320.0)
	print("  ключ у героя: ", _hero().has_key)
	await _walk_to(340.0)
	await _jump_right()  # на правый берег
	await _walk_to(580.0)  # к двери: ключ открывает её


func _solve_08() -> void:
	# Прыжок снизу проходит сквозь невидимый камень и не выдаёт его.
	await _walk_to(255.0)
	_press("jump")
	await _frames(90)
	print("  прыжок снизу: камень скрыт ", not current_scene.get_node("HiddenBlock").revealed, ", герой на полу ", _hero().is_on_floor())
	await _walk_to(120.0)
	await _jump_right()  # на камень 1
	await _walk_to(184.0)
	await _jump_right()  # на невидимый камень — он проявляется
	print("  невидимый камень проявился: ", current_scene.get_node("HiddenBlock").revealed)
	await _walk_to(276.0)
	await _jump_right()  # на камень 3
	await _walk_to(364.0)
	await _jump_right()  # за ключом, приземление на пол
	print("  ключ у героя: ", _hero().has_key)
	await _walk_to(580.0)


func _solve_09() -> void:
	await _walk_to(240.0)
	_press("action")  # лестница разворачивается
	await _frames(90)
	await _walk_to(326.0)
	await _climb(-1.0)  # вверх, пропуская птиц
	print("  наверху: ", _hero().global_position)
	await _walk_to(450.0)
	print("  ключ у героя: ", _hero().has_key)
	await _walk_to(344.0)  # край площадки у верха лестницы
	await _climb(1.0)   # вниз, пропуская птиц
	await _walk_to(590.0)


## Лезть по лестнице вверх (-1) или вниз (1), замирая, если птица вот-вот пересечёт лестницу.
func _climb(direction: float) -> void:
	var action := "jump" if direction < 0 else "action"
	for i in 3000:
		var hero := _hero()
		if not hero or hero._dead:
			print("  герой погиб на высоте ", hero.global_position.y if hero else -1.0)
			return
		var y := hero.global_position.y
		# Долез: выбрался на площадку наверху.
		if direction < 0 and not hero.climbing and hero.is_on_floor() and y < 210.0:
			break
		if direction > 0 and hero.is_on_floor() and y > 1000.0:
			break
		if _bird_danger(hero, direction):
			Input.action_release(action)
		else:
			Input.action_press(action)
		await physics_frame
	Input.action_release(action)
	await _frames(5)


func _bird_danger(hero: Node2D, direction: float) -> bool:
	var hx := hero.global_position.x
	var feet := hero.global_position.y
	var head := feet - 24.0
	for bird in current_scene.get_tree().get_nodes_in_group("bird"):
		var by: float = bird.global_position.y
		# Сколько лезть, чтобы целиком миновать линию полёта птицы (с запасом).
		var to_clear := (feet - (by - 8.0)) if direction < 0 else ((by + 8.0) - head)
		if to_clear <= 0.0 or to_clear > 24.0 + 16.0 + 40.0:
			continue  # линия уже позади или ещё далеко
		var t_clear := to_clear / 80.0 + 0.3
		var dx: float = hx - bird.global_position.x
		var gap := absf(dx) - 20.0
		var t_arrive: float
		if gap <= 0.0:
			t_arrive = 0.0
		elif signf(dx) == bird.dir:
			t_arrive = gap / bird.speed
		else:
			# Летит прочь: долетит до стены и вернётся.
			var wall: float = bird.to_x if bird.dir > 0 else bird.from_x
			t_arrive = (absf(wall - bird.global_position.x) * 2.0 + gap) / bird.speed
		if t_arrive < t_clear:
			return true
	return false


func _solve_10() -> void:
	Input.action_press("move_left")  # за левый край экрана
	await _until(func() -> bool: return _hero().global_position.x > 400.0)
	Input.action_release("move_left")
	print("  вышел справа: x=", _hero().global_position.x)
	await _walk_to(540.0)  # зелье
	await _frames(40)
	print("  гравитация: ", _hero().gravity_dir, " на потолке: ", _hero().is_on_floor(), " y=", _hero().global_position.y)
	await _walk_to(40.0)  # дверь на потолке у левого края


func _solve_11() -> void:
	var key: Node2D = current_scene.get_node("Key")
	var before := key.global_position
	await _walk_to(330.0)
	await _jump_right()  # к ключу на платформе 3 — он убегает
	print("  ключ убежал: ", key.global_position != before, " ключ у героя: ", _hero().has_key)
	await _tap(current_scene.get_node("Hourglass").global_position)
	await _frames(40)
	print("  часы перевёрнуты, ключ на месте: ", key.global_position)
	if _hero().global_position.y > 250.0:  # не попал на платформу 3
		await _walk_to(330.0)
		await _jump_right()
	await _walk_to(436.0)
	await _jump_right()  # на платформу 4
	await _walk_to(520.0)  # к ключу
	print("  ключ у героя: ", _hero().has_key)
	await _walk_to(600.0)


func _solve_12() -> void:
	await _walk_to(150.0)
	await _jump_right()  # через первую яму
	await _walk_to(372.0)  # шаг во вторую яму
	await _until(func() -> bool: return _hero().is_on_floor() and _hero().global_position.y > 590.0)
	await _walk_to(420.0)  # ключ
	print("  ключ у героя: ", _hero().has_key)
	await _walk_to(480.0)  # в ложную стену, к лестнице
	print("  ход открыт: ", current_scene.get_node("FalseWall").opened)
	Input.action_press("jump")
	await _until(func() -> bool: return not _hero().climbing and _hero().is_on_floor() and _hero().global_position.y < 285.0)
	Input.action_release("jump")
	await _walk_to(490.0)
	# По ступенькам к двери.
	Input.action_press("move_right")
	await _until(func() -> bool: return _hero().global_position.x > 590.0 and _hero().is_on_floor(), true)
	Input.action_release("move_right")
	await _walk_to(602.0)


func _jump_right() -> void:
	Input.action_press("move_right")
	Input.action_press("jump")
	await _frames(3)
	Input.action_release("jump")
	await _frames(5)
	await _until(func() -> bool: return _hero().is_on_floor())
	Input.action_release("move_right")
	await _frames(5)


func _solve_13() -> void:
	# Плиты на полу: жёлтая 160, красная 250, зелёная 340, синяя 430.
	var seq := current_scene.get_node("Plates")
	await _walk_to(470.0)  # прошёл по всем плитам слева направо — дверь закрыта
	await _walk_to(120.0)  # и обратно — тоже мимо
	print("  прошёл по всем плитам туда и обратно: решено ", seq.solved)
	await _walk_to(250.0)  # красная
	await _walk_to(290.0)
	await _hop("move_right")  # через зелёную
	await _walk_to(430.0)  # синяя
	await _walk_to(385.0)
	await _hop("move_left")  # через зелёную
	await _hop("move_left")  # через красную
	await _walk_to(160.0)  # жёлтая
	await _walk_to(200.0)
	await _hop("move_right")  # через красную
	await _walk_to(340.0)  # зелёная
	print("  порядок красная, синяя, жёлтая, зелёная: решено ", seq.solved, " ", seq._history)
	await _walk_to(580.0)


func _solve_14() -> void:
	var stone: Node2D = current_scene.get_node("Stone")
	await _tap(stone.global_position + Vector2(0, -16))
	await _frames(70)
	print("  камень сброшен: ", stone.global_position)
	await _walk_to(190.0)  # толкает камень влево до уступа
	print("  камень у уступа: ", stone.global_position)
	await _hop("move_left")  # на камень
	await _hop("move_left")  # с камня на уступ — открывается тайник
	print("  на уступе: ", _hero().global_position, " тайник открыт: ", current_scene.get_node("FalseWall").opened)
	await _walk_to(46.0)
	print("  ключ у героя: ", _hero().has_key)
	await _walk_to(580.0)


func _hop(action: String) -> void:
	Input.action_press(action)
	Input.action_press("jump")
	await _frames(3)
	Input.action_release("jump")
	await _frames(5)
	await _until(func() -> bool: return _hero().is_on_floor())
	Input.action_release(action)
	await _frames(5)


# --- Помощники ------------------------------------------------------------

func _walk_to(x: float) -> void:
	for i in 300:
		if not current_scene or not current_scene.has_node("Hero"):
			return  # уровень уже пройден
		var dx := x - _hero().global_position.x
		if absf(dx) < 3.0:
			break
		var action := "move_right" if dx > 0 else "move_left"
		Input.action_press(action)
		await physics_frame
		Input.action_release(action)
	if current_scene and current_scene.has_node("Hero"):
		await _frames(5)


func _hero() -> CharacterBody2D:
	return current_scene.get_node_or_null("Hero") if current_scene else null


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _until(cond: Callable, jump_while_waiting := false, limit := 900) -> void:
	for i in limit:
		if cond.call():
			return
		if jump_while_waiting and i % 25 == 0:
			_press("jump")
		await physics_frame


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)


func _spam_jump() -> void:
	var scene := current_scene
	while current_scene == scene and is_instance_valid(scene):
		_press("jump")
		await _frames(25)


func _to_window(p: Vector2) -> Vector2:
	return root.get_final_transform() * p


func _tap(p: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.position = _to_window(p)
	down.pressed = true
	Input.parse_input_event(down)
	await _frames(2)
	var up := down.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(2)


func _drag(from: Vector2, to: Vector2, steps: int) -> void:
	var down := InputEventScreenTouch.new()
	down.position = _to_window(from)
	down.pressed = true
	Input.parse_input_event(down)
	await _frames(2)
	for i in range(1, steps + 1):
		var drag := InputEventScreenDrag.new()
		drag.position = _to_window(from.lerp(to, float(i) / steps))
		Input.parse_input_event(drag)
		await _frames(2)
	var up := InputEventScreenTouch.new()
	up.position = _to_window(to)
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(2)


func _wait_scene_change(start_path: String, limit: int) -> bool:
	# Перезапуск того же уровня (гибель) — это не прохождение.
	for i in limit:
		if current_scene and current_scene.scene_file_path != start_path:
			return true
		await physics_frame
	return false


func _release_all() -> void:
	for a in ["move_left", "move_right", "jump", "action"]:
		Input.action_release(a)
