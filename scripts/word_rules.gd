@tool
extends Node2D
## Скрижаль правил: «ВОДА ТОПИТ», «ДВЕРЬ ЗАПЕРТА». Подлежащие высечены намертво,
## а слова-сказуемые — плитки: пальцем их можно перетащить в другое правило или в нишу запасных слов
## (плитки меняются местами). Как написано на стене, так и работает зал: каждое правило
## передаётся своей цели (targets[i]) через set_rule(слово).
## Начало координат — левый верхний угол скрижали.

@export var subjects := PackedStringArray(["ВОДА", "ДВЕРЬ"]):
	set(value):
		subjects = value
		queue_redraw()
## Слова в правилах, по порядку подлежащих.
@export var words := PackedStringArray(["ТОПИТ", "ЗАПЕРТА"]):
	set(value):
		words = value
		_slots = Array(words) + Array(spare)
		queue_redraw()
## Запасные плитки в нише под правилами.
@export var spare := PackedStringArray(["ДЕРЖИТ", "ГОРИТ", "ОТКРЫТА"]):
	set(value):
		spare = value
		_slots = Array(words) + Array(spare)
		queue_redraw()
@export var targets: Array[NodePath] = []

const TILE := Vector2(84, 22)
const ROW := 30.0
const RULE_X := 110.0
const SPARE_GAP := 10.0

## Что лежит в каждом гнезде: сначала гнёзда правил, потом ниши.
var _slots: Array = []
var _held := -1
var _held_pos := Vector2.ZERO
var _hit := -1
var _time := 0.0


func _ready() -> void:
	_slots = Array(words) + Array(spare)
	if Engine.is_editor_hint():
		return
	add_to_group("rune")
	z_index = 3
	_apply.call_deferred(true)


func _slot_rect(i: int) -> Rect2:
	if i < subjects.size():
		return Rect2(Vector2(RULE_X, i * ROW), TILE)
	var j := i - subjects.size()
	var y := subjects.size() * ROW + 16.0
	return Rect2(Vector2(j * (TILE.x + SPARE_GAP), y), TILE)


func _slot_at(local: Vector2) -> int:
	for i in _slots.size():
		if _slot_rect(i).grow(6).has_point(local):
			return i
	return -1


func contains_world_point(point: Vector2) -> bool:
	_hit = _slot_at(to_local(point))
	return _hit >= 0 and _slots[_hit] != ""


func hand_tap() -> void:
	_held = _hit
	_held_pos = _slot_rect(_held).position
	Sfx.play("tap")


func hand_drag(delta: Vector2) -> void:
	if _held >= 0:
		_held_pos += delta


func hand_release() -> void:
	if _held < 0:
		return
	var target := _slot_at(_held_pos + TILE / 2)
	if target >= 0 and target != _held:
		var w = _slots[target]
		_slots[target] = _slots[_held]
		_slots[_held] = w
		Sfx.play("lever")
		_apply(false)
	_held = -1


## Передать правила целям: что написано, то и происходит.
func _apply(silent: bool) -> void:
	for i in subjects.size():
		if i < targets.size():
			var target := get_node_or_null(targets[i])
			if target and target.has_method("set_rule"):
				target.set_rule(_slots[i], silent)


## Слово сейчас в правиле подлежащего (для автотеста и подсказок).
func rule_of(subject: String) -> String:
	var i := subjects.find(subject)
	return _slots[i] if i >= 0 else ""


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := RULE_X + TILE.x + 12.0
	var spare_w := maxf(0.0, (_slots.size() - subjects.size()) * (TILE.x + SPARE_GAP) - SPARE_GAP)
	# Скрижаль и ниша.
	var tablet := Rect2(Vector2(-10, -10), Vector2(maxf(w, spare_w) + 20.0, subjects.size() * ROW + 6.0))
	draw_rect(tablet, Color("3a3430"))
	draw_rect(tablet, Color("6a5e50"), false, 2.0)
	var niche := Rect2(Vector2(-6, subjects.size() * ROW + 10.0), Vector2(spare_w + 12.0, TILE.y + 12.0))
	draw_rect(niche, Color("1c1916"))
	draw_rect(niche, Color("4a4038"), false, 1.0)
	for i in subjects.size():
		draw_string(font, Vector2(4, i * ROW + 16), Game.t(subjects[i]) if not Engine.is_editor_hint() else subjects[i],
				HORIZONTAL_ALIGNMENT_LEFT, RULE_X - 8.0, 14, Color("d9c9a8"))
	for i in _slots.size():
		var r := _slot_rect(i)
		# Пустое гнездо — выемка в камне.
		draw_rect(r, Color("201c18"))
		if i == _held or _slots[i] == "":
			continue
		_draw_tile(r.position, _slots[i], i < subjects.size())
	if _held >= 0:
		_draw_tile(_held_pos + Vector2(0, -2), _slots[_held], false, true)


func _draw_tile(pos: Vector2, word: String, in_rule: bool, lifted := false) -> void:
	var font := ThemeDB.fallback_font
	var r := Rect2(pos, TILE)
	if lifted:
		draw_rect(Rect2(pos + Vector2(3, 4), TILE), Color(0, 0, 0, 0.4))
	var glow := 0.5 + 0.5 * sin(_time * 3.0)
	draw_rect(r, Color("c9a35b") if in_rule else Color("a8874e"))
	draw_rect(Rect2(pos, Vector2(TILE.x, 2)), Color("f0d590"))
	draw_rect(Rect2(pos + Vector2(0, TILE.y - 2), Vector2(TILE.x, 2)), Color("6e5236"))
	draw_rect(r, Color(1.0, 0.9, 0.5, 0.3 + 0.3 * glow) if lifted else Color("6e5236"), false, 1.0)
	var text := Game.t(word) if not Engine.is_editor_hint() else word
	draw_string(font, pos + Vector2(0, 16), text, HORIZONTAL_ALIGNMENT_CENTER, TILE.x, 13, Color("2a1d12"))
