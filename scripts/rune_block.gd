@tool
extends AnimatableBody2D
## Камень с голубой руной: его трогает рука игрока (палец или мышь).
## TAP — касание сдвигает камень на tap_offset. DRAG — камень тянут вдоль drag_axis.

enum Mode { TAP, DRAG }

const RUNE_COLOR := Color("5fd3ff")

@export var mode := Mode.TAP:
	set(value):
		mode = value
		queue_redraw()
@export var size := Vector2(32, 110):
	set(value):
		size = value
		queue_redraw()
@export var tap_offset := Vector2(0, 110)
@export var drag_axis := Vector2(1, 0)
@export var drag_min := 0.0
@export var drag_max := 200.0
## Если игрок долго не трогает камень, руна мягко мигает (подсказка без текста).
@export var idle_blink_after := 0.0
@export var targets: Array[NodePath] = []
@export var effect: StringName = &"activate"

var used := false
var _start := Vector2.ZERO
var _along := 0.0
var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("rune")
	_start = position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	add_child(shape)


func contains_world_point(point: Vector2) -> bool:
	return Rect2(global_position - size / 2, size).grow(8).has_point(point)


func hand_tap() -> void:
	if mode != Mode.TAP or used:
		return
	used = true
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", _start + tap_offset, 0.6)
	Game.fire(self, targets, effect)
	Game.hand_used.emit("tap")


func hand_drag(world_delta: Vector2) -> void:
	if mode != Mode.DRAG:
		return
	var axis := drag_axis.normalized()
	_along = clampf(_along + world_delta.dot(axis), drag_min, drag_max)
	if not used and is_equal_approx(_along, drag_max):
		used = true
		Game.fire(self, targets, effect)
	Game.hand_used.emit("drag")


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or mode != Mode.DRAG:
		return
	position = _start + drag_axis.normalized() * _along


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(-size / 2, size)
	if mode == Mode.DRAG and not Engine.is_editor_hint():
		# Направляющая: где камень может ехать.
		var axis := drag_axis.normalized()
		var a := _start - position + axis * drag_min
		var b := _start - position + axis * drag_max
		draw_line(a, b, Color(RUNE_COLOR, 0.25), 2.0)
	draw_rect(r, Color("9b7b52"))
	draw_rect(r, Color("5e4630"), false, 1.0)
	var glow := 0.75 + 0.25 * sin(_time * 3.0)
	if idle_blink_after > 0.0 and not used and _time > idle_blink_after:
		glow = 0.4 + 0.6 * absf(sin(_time * 5.0))
	if used and mode == Mode.TAP:
		glow = 0.3
	var c := Color(RUNE_COLOR, glow)
	var s := minf(minf(size.x, size.y) * 0.35, 10.0)
	# Руна: ромб с вертикальной чертой.
	draw_polyline(PackedVector2Array([Vector2(0, -s), Vector2(s, 0), Vector2(0, s), Vector2(-s, 0), Vector2(0, -s)]), c, 2.0)
	draw_line(Vector2(0, -s * 1.4), Vector2(0, s * 1.4), c, 1.0)
