@tool
extends CharacterBody2D
## Герой-искатель: ходьба, прыжок, кнопка действия. Начало координат — у ног.

const SIZE := Vector2(12, 24)
const SPEED := 110.0
const JUMP_VELOCITY := -330.0
const GRAVITY := 900.0
const CLIMB_SPEED := 80.0

var fall_limit := 420.0
## Если true, падение в пропасть — гибель: уровень начинается заново.
var restart_on_fall := false
var has_key := false
var spawn_point := Vector2.ZERO
var facing := 1.0
var _dead := false
## Герой висит на лестнице: ▲ (прыжок) — вверх, кнопка действия — вниз, ◀ ▶ — спрыгнуть.
var climbing := false
var _ladder: Node = null
## Направление силы тяжести: 1 — вниз, -1 — вверх (после зелья).
var gravity_dir := 1.0
## Ширина закольцованного уровня: ушёл за левый край — появился справа. 0 — без кольца.
var wrap_width := 0.0
var _shape: CollisionShape2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("hero")
	spawn_point = global_position
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	_shape.shape = rect
	_shape.position = Vector2(0, -SIZE.y / 2)
	add_child(_shape)


## Зелье: гравитация переворачивается, герой падает на потолок и ходит по нему.
func flip_gravity() -> void:
	gravity_dir = -gravity_dir
	# Тело остаётся на месте: «ноги» теперь там, где была голова.
	global_position.y += SIZE.y * gravity_dir
	up_direction = Vector2(0, -gravity_dir)
	_shape.position = Vector2(0, -SIZE.y / 2 * gravity_dir)
	climbing = false


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _dead:
		return
	var dir := Input.get_axis("move_left", "move_right")
	var ladder := _find_ladder()
	# За лестницу хватается ниже её верха: стоя наверху, ▲ — обычный прыжок.
	if not climbing and ladder and ((Input.is_action_pressed("jump") and global_position.y > ladder.global_position.y + 4.0) or (Input.is_action_pressed("action") and not is_on_floor())):
		climbing = true
		_ladder = ladder
	elif not climbing and is_on_floor() and Input.is_action_just_pressed("action"):
		# Стоит у верха лестницы над пустотой: спускается на неё.
		var below := _ladder_below()
		if below:
			climbing = true
			_ladder = below
			global_position.y = below.global_position.y + 2.0
	if climbing and (ladder == null or dir != 0.0):
		climbing = false
	if climbing:
		_climb()
	else:
		if not is_on_floor():
			velocity.y += GRAVITY * gravity_dir * delta
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY * gravity_dir
			Sfx.play("jump")
		velocity.x = dir * SPEED
		if Input.is_action_just_pressed("action"):
			_try_interact()
	if dir != 0.0 and signf(dir) != facing:
		facing = signf(dir)
	queue_redraw()
	var falling := absf(velocity.y) > 200.0
	move_and_slide()
	if falling and is_on_floor() and not climbing:
		Sfx.play("land", -4.0)
	if wrap_width > 0.0:
		if global_position.x < -6.0:
			global_position.x += wrap_width + 12.0
		elif global_position.x > wrap_width + 6.0:
			global_position.x -= wrap_width + 12.0
	if global_position.y > fall_limit:
		if restart_on_fall:
			die()
		else:
			# На обучающих уровнях смерти нет: упал — вернулся к началу.
			global_position = spawn_point
			velocity = Vector2.ZERO


func _climb() -> void:
	velocity.x = 0.0
	global_position.x = _ladder.global_position.x
	velocity.y = 0.0
	if Input.is_action_pressed("jump"):
		velocity.y = -CLIMB_SPEED
	elif Input.is_action_pressed("action"):
		velocity.y = CLIMB_SPEED
	# Долез до верха: выбирается на площадку рядом, а не висит над лестницей.
	if velocity.y < 0.0 and global_position.y <= _ladder.global_position.y + 1.0:
		_climb_out()


func _climb_out() -> void:
	var top: float = _ladder.global_position.y
	for dx in [0.0, 16.0, -16.0, 24.0, -24.0]:
		var x: float = _ladder.global_position.x + dx
		if _solid_at(Vector2(x, top + 3.0)):
			global_position = Vector2(x, top - 0.5)
			velocity = Vector2.ZERO
			climbing = false
			if dx != 0.0:
				facing = signf(dx)
			return
	# Площадки рядом нет: выше верхней перекладины не залезть.
	if global_position.y <= _ladder.top_y():
		velocity.y = 0.0


func _solid_at(point: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()


func _ladder_below() -> Node:
	for node in get_tree().get_nodes_in_group("ladder"):
		var top: float = node.global_position.y
		if absf(global_position.y - top) < 6.0 and absf(global_position.x - node.global_position.x) < 22.0 \
				and not _solid_at(Vector2(node.global_position.x, top + 3.0)):
			global_position.x = node.global_position.x
			return node
	return null


func _find_ladder() -> Node:
	for node in get_tree().get_nodes_in_group("ladder"):
		if node.overlaps_body(self):
			return node
	return null


## Гибель: уровень начинается заново.
func die() -> void:
	if _dead:
		return
	_dead = true
	Sfx.play("die")
	modulate = Color(1, 0.4, 0.4)
	get_tree().create_timer(0.4).timeout.connect(get_tree().reload_current_scene)


func _try_interact() -> void:
	for node in get_tree().get_nodes_in_group("interactable"):
		if node.overlaps_body(self):
			node.use()
			return


const C_HAT := Color("5b3a1e")
const C_HAT_BAND := Color("2e1d10")
const C_SKIN := Color("e8b98a")
const C_SKIN_SHADE := Color("c48e63")
const C_SHIRT := Color("d9c08c")
const C_SHIRT_SHADE := Color("b39a68")
const C_PANTS := Color("6d5a3a")
const C_PANTS_SHADE := Color("564630")
const C_BOOTS := Color("3a2616")
const C_BAG := Color("8a5a2b")
const C_BELT := Color("4a3020")

var _anim := 0.0
var _step_frame := -1


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if absf(velocity.x) > 1.0 and is_on_floor() or (climbing and absf(velocity.y) > 1.0):
		_anim += delta
		# Шаг слышен на кадрах 1 и 3, когда ступня касается пола.
		var frame := int(_anim * (8.0 if climbing else 10.0)) % 4
		if frame != _step_frame and frame % 2 == 1:
			Sfx.play("step", -8.0, randf_range(0.85, 1.15))
		_step_frame = frame
	else:
		_anim = 0.0
		_step_frame = -1


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)


func _draw() -> void:
	# Вверх ногами, если гравитация перевёрнута; зеркально, если смотрит влево.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, gravity_dir))
	if climbing:
		_draw_climbing()
		return
	var frame := int(_anim * 10.0) % 4
	var airborne := not is_on_floor() and not Engine.is_editor_hint()
	var bob := 1.0 if frame % 2 == 1 else 0.0
	# Ноги: шаг вперёд-назад.
	var front: float = [0.0, 2.0, 0.0, -2.0][frame]
	if airborne:
		front = 2.0
	_px(-4 + front, -8, 3, 5, C_PANTS)
	_px(-4 + front, -3, 4, 3, C_BOOTS)
	_px(1 - front, -8, 3, 5, C_PANTS_SHADE)
	_px(1 - front, -3, 4, 3, C_BOOTS)
	var y := -bob
	# Туловище, ремень, сумка через плечо.
	_px(-5, -17 + y, 10, 9, C_SHIRT)
	_px(-5, -17 + y, 2, 9, C_SHIRT_SHADE)
	_px(-5, -10 + y, 10, 2, C_BELT)
	_px(-4, -16 + y, 1, 1, C_BAG)
	_px(-3, -15 + y, 1, 1, C_BAG)
	_px(-2, -14 + y, 1, 1, C_BAG)
	_px(-1, -13 + y, 1, 1, C_BAG)
	_px(-7, -12 + y, 4, 5, C_BAG)
	_px(-7, -12 + y, 4, 1, C_BAG.lightened(0.2))
	# Рука: машет при ходьбе.
	var arm: float = [0.0, 1.0, 0.0, -1.0][frame]
	_px(3 + arm, -16 + y, 2, 6, C_SHIRT_SHADE)
	_px(3 + arm, -10 + y, 2, 2, C_SKIN)
	# Голова, глаз, нос.
	_px(-4, -23 + y, 8, 6, C_SKIN)
	_px(-4, -23 + y, 2, 6, C_SKIN_SHADE)
	_px(2, -21 + y, 1, 2, Color("1a120c"))
	_px(4, -20 + y, 1, 2, C_SKIN_SHADE)
	# Шляпа искателя: широкие поля, лента.
	_px(-7, -24 + y, 14, 2, C_HAT)
	_px(-4, -28 + y, 8, 4, C_HAT)
	_px(-4, -25 + y, 8, 1, C_HAT_BAND)
	_px(-3, -28 + y, 6, 1, C_HAT.lightened(0.15))


func _draw_climbing() -> void:
	# Спиной к игроку: руки на перекладинах, перебирает ими по очереди.
	var frame := int(_anim * 8.0) % 2
	_px(-4, -8, 3, 5, C_PANTS)
	_px(1, -8, 3, 5, C_PANTS_SHADE)
	_px(-4, -3 - frame * 2, 3, 3, C_BOOTS)
	_px(1, -5 + frame * 2, 3, 3, C_BOOTS)
	_px(-5, -17, 10, 9, C_SHIRT_SHADE)
	_px(-4, -15, 5, 5, C_BAG)
	_px(-5, -10, 10, 2, C_BELT)
	_px(-8, -21 + frame * 2, 3, 3, C_SKIN)
	_px(5, -19 - frame * 2, 3, 3, C_SKIN)
	_px(-4, -23, 8, 6, C_HAT_BAND)
	_px(-7, -24, 14, 2, C_HAT)
	_px(-4, -28, 8, 4, C_HAT)
