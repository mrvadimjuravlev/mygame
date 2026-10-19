@tool
extends Node2D
## «Пятнашки из комнат»: решётка 3 на 2 из плит-комнат (slide_tile) и одно пустое место.
## Коснулся плиты рядом с пустым местом — она съезжает туда. Плиту с героем внутри не сдвинуть.
## Начало координат — левый верхний угол решётки.

const COLS := 3
const ROWS := 2
const CELL := Vector2(160, 120)

## Плиты по местам слева направо, сверху вниз; "" — пустое место.
@export var layout := PackedStringArray(["H", "D", "C", "", "X", "H"])

## Какая плита на каком месте (null — пусто).
var cells: Array = []
var moving := false
var _hit := -1


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("rune")
	for i in COLS * ROWS:
		var kind: String = layout[i] if i < layout.size() else ""
		if kind == "":
			cells.append(null)
			continue
		var tile := StaticBody2D.new()
		tile.set_script(preload("res://scripts/slide_tile.gd"))
		tile.kind = kind
		tile.position = _cell_pos(i)
		add_child(tile)
		cells.append(tile)


func _cell_pos(i: int) -> Vector2:
	return Vector2(i % COLS, i / COLS) * CELL


func _cell_at(local: Vector2) -> int:
	if local.x < 0 or local.y < 0 or local.x >= COLS * CELL.x or local.y >= ROWS * CELL.y:
		return -1
	return int(local.y / CELL.y) * COLS + int(local.x / CELL.x)


func contains_world_point(point: Vector2) -> bool:
	_hit = _cell_at(to_local(point))
	return _hit >= 0 and cells[_hit] != null


func hand_tap() -> void:
	slide(_hit)


func hand_drag(_delta: Vector2) -> void:
	pass


## Сдвинуть плиту с места i на соседнее пустое. Вернёт, удалось ли.
func slide(i: int) -> bool:
	if moving or i < 0 or cells[i] == null:
		return false
	var empty := cells.find(null)
	var a := Vector2i(i % COLS, i / COLS)
	var b := Vector2i(empty % COLS, empty / COLS)
	if absi(a.x - b.x) + absi(a.y - b.y) != 1:
		Sfx.play("tap")
		return false
	var hero := get_tree().get_first_node_in_group("hero") as Node2D
	if hero and Rect2(global_position + _cell_pos(i), CELL).grow(6).has_point(hero.global_position + Vector2(0, -6)):
		Sfx.play("tap")
		return false
	var tile: Node2D = cells[i]
	cells[empty] = tile
	cells[i] = null
	moving = true
	Sfx.play("lever")
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(tile, "position", _cell_pos(empty), 0.25).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func() -> void: moving = false)
	return true


## Раскладка сейчас: виды плит по местам ("" — пусто).
func kinds() -> Array:
	return cells.map(func(t) -> String: return t.kind if t else "")


func _draw() -> void:
	# Рама решётки и тёмная пустота за плитами.
	draw_rect(Rect2(Vector2.ZERO, CELL * Vector2(COLS, ROWS)), Color("0c0906"))
	draw_rect(Rect2(Vector2(-3, -3), CELL * Vector2(COLS, ROWS) + Vector2(6, 6)), Color("5a4229"), false, 3.0)
