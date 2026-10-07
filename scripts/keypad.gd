@tool
extends Node2D
## Каменное табло с колёсиками цифр. Касание пальцем по колёсику листает цифру 0→9→0.
## Когда набран code, срабатывают targets. Начало координат — левый верхний угол табло.

const CELL := Vector2(26, 34)
const GAP := 6.0
const PAD := 8.0

@export var code := "0000":
	set(value):
		code = value
		queue_redraw()
@export var targets: Array[NodePath] = []
@export var effect: StringName = &"activate"

var digits := PackedInt32Array([0, 0, 0, 0])
var solved := false
var _hit := -1
var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("rune")


func size() -> Vector2:
	return Vector2(PAD * 2 + code.length() * CELL.x + (code.length() - 1) * GAP, PAD * 2 + CELL.y)


func _cell_rect(i: int) -> Rect2:
	return Rect2(Vector2(PAD + i * (CELL.x + GAP), PAD), CELL)


func contains_world_point(point: Vector2) -> bool:
	var local := to_local(point)
	_hit = -1
	for i in code.length():
		if _cell_rect(i).grow(3).has_point(local):
			_hit = i
			return true
	return false


func hand_tap() -> void:
	if _hit < 0 or solved:
		return
	digits[_hit] = (digits[_hit] + 1) % 10
	Game.hand_used.emit("tap")
	if _entered() == code:
		solved = true
		Sfx.play("key")
		Game.fire(self, targets, effect)


func hand_drag(_world_delta: Vector2) -> void:
	pass


func _entered() -> String:
	var s := ""
	for i in code.length():
		s += str(digits[i])
	return s


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size()), Color("6e5236"))
	draw_rect(Rect2(Vector2.ZERO, size()), Color("3a2a18"), false, 2.0)
	draw_rect(Rect2(2, 2, size().x - 4, 2), Color("8a6a43"))
	for i in code.length():
		var r := _cell_rect(i)
		draw_rect(r, Color("1e140c"))
		draw_rect(r, Color("b08a57"), false, 1.0)
		var glow := Color("ffd98a") if solved else Color("e2bf78")
		var text := str(digits[i]) if not Engine.is_editor_hint() else "0"
		draw_string(font, r.position + Vector2(0, 26), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 24, glow)
		# Насечки: колёсико крутится вниз.
		draw_rect(Rect2(r.position.x + 3, r.position.y + 2, r.size.x - 6, 1), Color(glow, 0.25))
		draw_rect(Rect2(r.position.x + 3, r.end.y - 3, r.size.x - 6, 1), Color(glow, 0.25))
