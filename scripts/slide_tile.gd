@tool
extends StaticBody2D
## Плита-комната для «Пятнашек» (slide_grid): 160 на 120, внутри коридор.
## H — проход насквозь, D — слева вход, справа в полу дыра вниз и стена,
## C — слева стена, сверху открыто (сюда падают из D), справа выход, X — глухая.
## Начало координат — левый верхний угол плиты.

const SIZE := Vector2(160, 120)
const Art := preload("res://scripts/art.gd")

@export_enum("H", "D", "C", "X") var kind := "H":
	set(value):
		kind = value
		queue_redraw()


func _ready() -> void:
	# Плиты освещены сами по себе: полумрак подземелья не должен прятать проходы.
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat
	if Engine.is_editor_hint():
		return
	for r in _solids():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = r.size
		shape.shape = rect
		shape.position = r.get_center()
		add_child(shape)


## Камень внутри плиты: пол и стены.
func _solids() -> Array[Rect2]:
	var list: Array[Rect2] = []
	match kind:
		"D":
			list.append(Rect2(0, 108, 104, 12))
			list.append(Rect2(148, 0, 12, 120))
		"C":
			list.append(Rect2(0, 108, 160, 12))
			list.append(Rect2(0, 0, 12, 108))
		"X":
			list.append(Rect2(0, 108, 160, 12))
			list.append(Rect2(0, 0, 12, 108))
			list.append(Rect2(148, 0, 12, 108))
		_:
			list.append(Rect2(0, 108, 160, 12))
	return list


func _draw() -> void:
	# Ниша: тёмная стена с рамкой, чтобы плиты читались как отдельные комнаты.
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("1e1712"))
	for k in 4:
		draw_line(Vector2(0, 26 + k * 26), Vector2(SIZE.x, 26 + k * 26), Color("2e241c"), 1.0)
	for r in _solids():
		draw_rect(r, Color("6e5236"))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color("c9a35b"))
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("c9a35b"), false, 2.0)
	if kind == "D":
		# Дыра в полу: тёмный провал со стрелкой вниз.
		draw_colored_polygon(PackedVector2Array([Vector2(118, 96), Vector2(134, 96), Vector2(126, 106)]), Color(0.9, 0.75, 0.4, 0.6))
