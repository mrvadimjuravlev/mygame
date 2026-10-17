@tool
extends Area2D
## Страж прохода: не пропускает героя, пока тот не ответит на загадку во всплывающем окне.
## Подходишь — страж заговаривает (потом — кнопкой действия). Ответ верный — страж уходит с дороги
## и запускает targets. Ошибка — отбрасывает героя назад, к reset_point.
## Два вида загадок: выбрать ответ из options (верный — answer) или повторить знаки
## (sequence_length > 0: страж показывает знаки по одному, их нужно нажать в том же порядке).
## Начало координат — у пола посередине стража; герой подходит слева.

const SIGNS := ["eye", "ankh", "bird", "wave", "sun", "reed"]
const PopupScript := preload("res://scripts/riddle_popup.gd")

@export_enum("shadow", "mask") var kind := "shadow":
	set(value):
		kind = value
		queue_redraw()
@export var speaker := "Тень"
@export_multiline var question := ""
@export var options := PackedStringArray()
@export var answer := 0
@export var sequence_length := 0
@export var reply_right := "Проходи."
@export var reply_wrong := "Неверно. Прочь!"
## Куда страж отбрасывает героя за неверный ответ.
@export var reset_point := Vector2.ZERO
## Невидимая стена стража: ширина и высота (до потолка — чтобы не перепрыгнуть).
@export var block := Vector2(24, 60):
	set(value):
		block = value
		queue_redraw()
@export var targets: Array[NodePath] = []
@export var effect: StringName = &"activate"

var solved := false
## Знаки, которые страж загадал в этот раз.
var sequence := PackedStringArray()
var _popup: CanvasLayer
var _barrier: StaticBody2D
var _state := ""
var _time := 0.0
## 1 — страж на месте, 0 — ушёл.
var _presence := 1.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Где страж заговаривает: перед ним и вплотную к нему.
	var zone := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(block.x + 36, 40)
	zone.shape = rect
	zone.position = Vector2(-18, -20)
	add_child(zone)
	_barrier = StaticBody2D.new()
	var wall := CollisionShape2D.new()
	var wall_rect := RectangleShape2D.new()
	wall_rect.size = block
	wall.shape = wall_rect
	wall.position = Vector2(0, -block.y / 2)
	_barrier.add_child(wall)
	add_child(_barrier)
	add_to_group("interactable")
	body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("hero"):
			use.call_deferred())
	_popup = PopupScript.new()
	_popup.chosen.connect(_on_chosen)
	# Окно добавляется в уровень после интерфейса: тогда касания сначала получает оно.
	get_parent().add_child.call_deferred(_popup)


func can_use() -> bool:
	return not solved and not (_popup and _popup.visible)


## Заговорить с героем.
func use() -> void:
	if solved or _popup.visible:
		return
	_state = "ask"
	if sequence_length > 0:
		sequence = PackedStringArray()
		var last := ""
		while sequence.size() < sequence_length:
			var s: String = SIGNS[randi() % SIGNS.size()]
			if s != last:
				sequence.append(s)
				last = s
		_popup.open(speaker, question, SIGNS, true, sequence)
	else:
		_popup.open(speaker, question, Array(options))


func _on_chosen(i: int) -> void:
	match _state:
		"ask":
			if sequence_length > 0:
				_popup.picked.append(SIGNS[i])
				_popup._refresh()
				var k: int = _popup.picked.size() - 1
				if _popup.picked[k] != sequence[k]:
					_answer(false)
				elif _popup.picked.size() == sequence.size():
					_answer(true)
			else:
				_answer(i == answer)
		"right":
			_popup.close()
			_solve()
		"wrong":
			_popup.close()
			_throw_back()


func _answer(right: bool) -> void:
	_state = "right" if right else "wrong"
	Sfx.play("key" if right else "flee")
	_popup.say(reply_right if right else reply_wrong)


func _solve() -> void:
	solved = true
	_barrier.get_child(0).set_deferred("disabled", true)
	create_tween().tween_property(self, "_presence", 0.0, 1.2)
	Sfx.play("door")
	Game.fire(self, targets, effect)


func _throw_back() -> void:
	var hero := get_tree().get_first_node_in_group("hero")
	if not hero:
		return
	hero.global_position = reset_point
	hero.velocity = Vector2.ZERO
	for cam in hero.get_children():
		if cam is Camera2D:
			cam.reset_smoothing()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	match kind:
		"shadow":
			_draw_shadow()
		"mask":
			_draw_mask()


## Тень: тёмная фигура в капюшоне, колышется, глаза горят. Уходя, тает и поднимается.
func _draw_shadow() -> void:
	if _presence <= 0.01:
		return
	var a := _presence
	var lift := (1.0 - _presence) * -30.0
	var body := PackedVector2Array()
	var h := 46.0
	for k in 9:
		var y := -h + k * (h / 8.0)
		var w := 7.0 + k * 1.4
		body.append(Vector2(-w + sin(_time * 3.0 + k) * 1.2, y + lift))
	for k in range(8, -1, -1):
		var y := -h + k * (h / 8.0)
		var w := 7.0 + k * 1.4
		body.append(Vector2(w + sin(_time * 3.0 + k + 2.0) * 1.2, y + lift))
	# Рваный подол.
	for k in 4:
		var x := -16.0 + k * 10.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, lift), Vector2(x + 10, lift), Vector2(x + 5, 6 + sin(_time * 4.0 + k) * 2.0 + lift)]), Color(0.04, 0.03, 0.06, 0.85 * a))
	draw_colored_polygon(body, Color(0.04, 0.03, 0.06, 0.92 * a))
	# Капюшон и пустота под ним.
	draw_circle(Vector2(0, -h + 6 + lift), 9.0, Color(0.06, 0.04, 0.09, a))
	draw_circle(Vector2(0, -h + 8 + lift), 6.0, Color(0, 0, 0, a))
	var glow := 0.75 + 0.25 * sin(_time * 2.0)
	draw_circle(Vector2(-2.5, -h + 8 + lift), 1.4, Color(1.0, 0.75, 0.2, glow * a))
	draw_circle(Vector2(2.5, -h + 8 + lift), 1.4, Color(1.0, 0.75, 0.2, glow * a))


## Каменная маска над решёткой прохода: глаза горят синим. Ответ верный — решётка уходит вверх.
func _draw_mask() -> void:
	var stone := Color("8a7a64")
	var dark := Color("4a4034")
	var lit := Color("b8a888")
	# Решётка во весь проход.
	var up := (1.0 - _presence) * block.y
	var top := -block.y
	var bars_h := block.y - up
	if bars_h > 1.0:
		draw_rect(Rect2(-block.x / 2, top, block.x, 4), dark)
		var x := -block.x / 2 + 2
		while x < block.x / 2:
			draw_rect(Rect2(x, top, 3, bars_h), Color("5e5a52"))
			draw_rect(Rect2(x, top, 1, bars_h), Color("8a857a"))
			x += 7
		for k in range(1, int(bars_h / 30.0) + 1):
			draw_rect(Rect2(-block.x / 2, top + bars_h - k * 30, block.x, 2), Color("4a4640"))
	# Лицо: над решёткой, у самого потолка, выступает из стены.
	var c := Vector2(0, top - 4)
	var face := PackedVector2Array([c + Vector2(-26, -70), c + Vector2(26, -70), c + Vector2(30, -40), c + Vector2(22, -6), c + Vector2(10, 4), c + Vector2(-10, 4), c + Vector2(-22, -6), c + Vector2(-30, -40)])
	draw_colored_polygon(face, stone)
	draw_polyline(face + PackedVector2Array([face[0]]), dark, 1.0)
	# Головной убор полосами.
	for k in 5:
		draw_rect(Rect2(c.x - 34 + k * 2, c.y - 74 + k * 10, 6, 9), lit if k % 2 == 0 else dark)
		draw_rect(Rect2(c.x + 28 - k * 2, c.y - 74 + k * 10, 6, 9), lit if k % 2 == 0 else dark)
	draw_rect(Rect2(c.x - 26, c.y - 74, 52, 6), Color("c9a35b"))
	draw_rect(Rect2(c.x - 26, c.y - 69, 52, 2), dark)
	# Брови, глаза, нос, губы.
	draw_rect(Rect2(c.x - 18, c.y - 50, 13, 2), dark)
	draw_rect(Rect2(c.x + 5, c.y - 50, 13, 2), dark)
	var glow := (0.6 + 0.4 * sin(_time * 2.5)) * _presence + 0.15
	var eye := Color(0.35, 0.8, 1.0, glow)
	draw_rect(Rect2(c.x - 17, c.y - 45, 11, 4), Color("1a1814"))
	draw_rect(Rect2(c.x + 6, c.y - 45, 11, 4), Color("1a1814"))
	draw_rect(Rect2(c.x - 14, c.y - 45, 5, 4), eye)
	draw_rect(Rect2(c.x + 9, c.y - 45, 5, 4), eye)
	draw_rect(Rect2(c.x - 2, c.y - 40, 4, 16), lit)
	draw_rect(Rect2(c.x - 5, c.y - 25, 10, 3), dark)
	draw_rect(Rect2(c.x - 9, c.y - 15, 18, 2), dark)
	draw_rect(Rect2(c.x - 7, c.y - 13, 14, 3), Color("7a6a54"))
	# Бородка фараона.
	draw_rect(Rect2(c.x - 4, c.y + 4, 8, 12), stone)
	for k in 3:
		draw_rect(Rect2(c.x - 4, c.y + 6 + k * 4, 8, 1), dark)
