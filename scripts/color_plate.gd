@tool
extends Area2D
## Цветная каменная плита в полу. Проседает, пока на ней стоит герой, и сообщает о нажатии
## головоломке PlateSequence. Цвет и свечение не гаснут. Начало координат — уровень пола.

signal stepped(plate: Node)

const COLORS := {
	"red": Color("d9534f"),
	"blue": Color("4a90d9"),
	"green": Color("5cb85c"),
	"yellow": Color("e8c547"),
}

@export_enum("red", "blue", "green", "yellow") var color_name := "red":
	set(value):
		color_name = value
		queue_redraw()

var pressed := false
var _occupied := false
var _glow: PointLight2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36, 26)
	shape.shape = rect
	shape.position = Vector2(0, -13)
	add_child(shape)
	# Слабое цветное свечение, чтобы плиту было видно в полумраке.
	_glow = PointLight2D.new()
	_glow.texture = preload("res://scripts/art.gd").light_texture()
	_glow.texture_scale = 0.18
	_glow.energy = 0.9
	_glow.color = COLORS[color_name]
	_glow.position = Vector2(0, -4)
	add_child(_glow)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var on := false
	for body in get_overlapping_bodies():
		if body.is_in_group("hero") and body.is_on_floor() and absf(body.global_position.x - global_position.x) < 16.0:
			on = true
	# Срабатывает в момент, когда герой встал; стоять дальше — не повторное нажатие.
	if on and not _occupied:
		Sfx.play("lever")
		stepped.emit(self)
	if on != _occupied:
		pressed = on
		queue_redraw()
	_occupied = on


func _draw() -> void:
	var c: Color = COLORS[color_name]
	# Паз в полу и каменная рамка плиты.
	draw_rect(Rect2(-19, 0, 38, 2), Color("1a120c"))
	var h := 1.0 if pressed else 5.0
	var top := -h + 1.0
	draw_rect(Rect2(-18, top, 36, h + 1.0), Color("6e5236") if pressed else Color("8a6e4c"))
	draw_rect(Rect2(-18, top, 1, h + 1.0), Color("5a4229"))
	draw_rect(Rect2(17, top, 1, h + 1.0), Color("4a3524"))
	# Цветная вставка во всю плиту, горит всегда.
	draw_rect(Rect2(-15, top, 30, h), c)
	draw_rect(Rect2(-15, top, 30, 1), c.lightened(0.4))
	if h > 1.0:
		draw_rect(Rect2(-15, top + h - 1, 30, 1), c.darkened(0.3))
