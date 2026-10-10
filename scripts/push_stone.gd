@tool
extends CharacterBody2D
## Каменный блок. Герой толкает его, упираясь сбоку; на него можно залезть.
## Если hand_nudge включён, на камне горит голубая руна и его можно толкнуть пальцем (касание).
## Начало координат — середина нижней грани.

const RUNE_COLOR := Color("5fd3ff")
const GRAVITY := 900.0
const PUSH_SPEED := 55.0
const NUDGE_SPEED := 120.0

@export var size := Vector2(32, 32):
	set(value):
		size = value
		queue_redraw()
## Куда толкает касание пальца: 1 — вправо, -1 — влево.
@export var nudge_dir := 1.0
## Камень с руной: его можно толкнуть пальцем.
@export var hand_nudge := false:
	set(value):
		hand_nudge = value
		queue_redraw()

## Камень можно поднять пальцем и перенести; отпустишь — падает.
@export var hand_carry := false

var hand_used := false
var carried := false
var _carry_target := Vector2.ZERO
var _push := 0.0
var _nudge_time := 0.0
var _glow: PointLight2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("pushable")
	if hand_nudge or hand_carry:
		add_to_group("rune")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(0, -size.y / 2)
	add_child(shape)
	if not hand_nudge:
		return
	# Руна чуть светится в полумраке, пока камень ждёт пальца.
	_glow = PointLight2D.new()
	_glow.texture = preload("res://scripts/art.gd").light_texture()
	_glow.texture_scale = 0.25
	_glow.energy = 0.9
	_glow.color = RUNE_COLOR
	_glow.position = Vector2(0, -size.y / 2)
	add_child(_glow)


func contains_world_point(point: Vector2) -> bool:
	return Rect2(global_position + Vector2(-size.x / 2, -size.y), size).grow(10).has_point(point)


func hand_tap() -> void:
	if hand_carry:
		carried = true
		_carry_target = global_position
		Game.hand_used.emit("tap")
		return
	if hand_used:
		return
	hand_used = true
	_glow.enabled = false
	_nudge_time = 0.45
	Sfx.play("door", -6.0, 1.6)
	Game.hand_used.emit("tap")


func hand_drag(world_delta: Vector2) -> void:
	if carried:
		_carry_target += world_delta


func hand_release() -> void:
	carried = false
	velocity = Vector2.ZERO


## Герой упёрся в камень сбоку и идёт в его сторону.
func push(dir: float) -> void:
	_push = dir


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if carried:
		# Тянется за пальцем, но сквозь камень не проходит.
		velocity = ((_carry_target - global_position) / delta).limit_length(420.0)
		move_and_slide()
		return
	var was_on_floor := is_on_floor()
	velocity.y += GRAVITY * delta
	if _nudge_time > 0.0:
		_nudge_time -= delta
		velocity.x = NUDGE_SPEED * nudge_dir
	elif is_on_floor():
		velocity.x = _push * PUSH_SPEED
	_push = 0.0
	var falling := velocity.y > 250.0
	var impact := velocity.y
	move_and_slide()
	if falling and is_on_floor() and not was_on_floor:
		Sfx.play("land", 2.0, 0.6)
		# Упал на что-то с подвохом (доска-катапульта): сообщает, как сильно ударил.
		for i in get_slide_collision_count():
			var body := get_slide_collision(i).get_collider()
			if body and body.has_method("stone_landed"):
				body.stone_landed(self, impact)
				break


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2(-size.x / 2, -size.y), size)
	draw_rect(r, Color("8a6e4c"))
	draw_rect(Rect2(r.position, Vector2(size.x, 2)), Color("b49470"))
	draw_rect(Rect2(r.position, Vector2(2, size.y)), Color("9b7d58"))
	draw_rect(Rect2(r.position + Vector2(size.x - 2, 0), Vector2(2, size.y)), Color("5e4630"))
	draw_rect(Rect2(r.position + Vector2(0, size.y - 2), Vector2(size.x, 2)), Color("4a3524"))
	# Сколы по углам.
	draw_rect(Rect2(r.position + Vector2(size.x - 6, 0), Vector2(6, 3)), Color("5e4630"))
	draw_rect(Rect2(r.position + Vector2(3, size.y - 8), Vector2(4, 3)), Color("6e5236"))
	if carried:
		draw_rect(r.grow(3), Color(RUNE_COLOR, 0.5), false, 1.0)
	if hand_nudge and not hand_used and not Engine.is_editor_hint():
		var c := r.get_center()
		var glow := 0.55 + 0.35 * sin(Time.get_ticks_msec() / 300.0)
		var col := Color(RUNE_COLOR, glow)
		var d := nudge_dir
		draw_line(c + Vector2(-6 * d, 0), c + Vector2(6 * d, 0), col, 2.0)
		draw_line(c + Vector2(2 * d, -4), c + Vector2(6 * d, 0), col, 2.0)
		draw_line(c + Vector2(2 * d, 4), c + Vector2(6 * d, 0), col, 2.0)
	elif hand_nudge and Engine.is_editor_hint():
		draw_rect(r, Color(RUNE_COLOR, 0.6), false, 1.0)
