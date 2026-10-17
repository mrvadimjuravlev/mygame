@tool
extends Node2D
## Каменный пресс с шипами снизу: висит под потолком, в своём ритме падает вниз на travel и поднимается.
## Касание шипов — гибель. Сквозь сам пресс не пройти: внизу он упирается шипами в пол.
## Начало координат — середина крепления к потолку.
## С wait_trigger пресс стоит наверху, пока его не запустит эффект activate (вагонетка тронулась).

const Art := preload("res://scripts/art.gd")

@export var size := Vector2(48, 64):
	set(value):
		size = value
		queue_redraw()
@export var travel := 170.0
## Сколько стоит наверху, падает, стоит внизу и поднимается, секунды.
@export var up_time := 1.2
@export var slam_time := 0.2
@export var down_time := 0.4
@export var rise_time := 0.7
## Сдвиг по кругу, секунды.
@export var phase := 0.0
@export var wait_trigger := false

var _time := 0.0
var _running := true
var _offset := 0.0
var _spikes: Area2D
var _was_down := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("press")
	_spikes = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x - 6, 12)
	shape.shape = rect
	_spikes.add_child(shape)
	add_child(_spikes)
	_running = not wait_trigger
	_time = phase
	_update()


## Эффект события: пресс начинает свой ритм со сдвигом phase.
func activate() -> void:
	if _running:
		return
	_running = true
	_time = phase


func cycle() -> float:
	return up_time + slam_time + down_time + rise_time


## Насколько пресс опущен (0 — наверху, 1 — внизу) через t секунд хода.
func amount_at(t: float) -> float:
	var u := fposmod(t, cycle())
	if u < up_time:
		return 0.0
	u -= up_time
	if u < slam_time:
		var s := u / slam_time
		return s * s
	u -= slam_time
	if u < down_time:
		return 1.0
	u -= down_time
	return 1.0 - smoothstep(0.0, 1.0, u / rise_time)


## Низ шипов в мировых координатах через t секунд хода.
func bottom_at(t: float) -> float:
	return global_position.y + size.y + 12.0 + travel * amount_at(t)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _running:
		_time += delta
	_update()
	for body in _spikes.get_overlapping_bodies():
		if body.is_in_group("hero"):
			body.die()


func _update() -> void:
	var a := amount_at(_time) if _running else 0.0
	var offset := travel * a
	_spikes.position = Vector2(0, offset + size.y + 6.0)
	var down := a >= 1.0
	if down and not _was_down:
		Sfx.play("door", -14.0, 0.6)
	_was_down = down
	if not is_equal_approx(offset, _offset):
		_offset = offset
		queue_redraw()


func _draw() -> void:
	var half := size.x / 2
	# Шток из потолка и крепление.
	draw_rect(Rect2(-6, 0, 12, _offset + 4), Color("4a3524"))
	draw_rect(Rect2(-6, 0, 3, _offset + 4), Color("5e4630"))
	draw_rect(Rect2(-half + 4, 0, size.x - 8, 4), Color("3b2a1c"))
	# Каменная колода с бронзовой оковкой.
	var block := Rect2(-half, _offset, size.x, size.y)
	var poly := PackedVector2Array([block.position, Vector2(block.end.x, block.position.y), block.end, Vector2(block.position.x, block.end.y)])
	Art.draw_textured(self, poly, Art.wall_texture(self), Color(0.82, 0.78, 0.74), Vector2(51, 23))
	draw_rect(Rect2(-half, _offset + size.y - 6, size.x, 6), Color("8a6a30"))
	draw_rect(Rect2(-half, _offset + size.y - 6, size.x, 1), Color("c9a35b"))
	draw_rect(block, Color(0, 0, 0, 0.45), false, 1.0)
	Art.draw_spike_row(self, Vector2(-half + (size.x - floorf(size.x / 10.0) * 10.0) / 2.0, _offset + size.y), Vector2(half, _offset + size.y), Vector2.DOWN, 12.0)
