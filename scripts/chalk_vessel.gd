@tool
extends Area2D
## Сосуд, над которым бурлят цветные пузыри. Герой подходит, жмёт «Действие» —
## и получает мел: в инвентаре белый брусок с подписью «Мел», пальцем теперь можно рисовать платформы.
## Начало координат — у пола посередине сосуда.

const BUBBLES := [Color("ff6b6b"), Color("5fd3ff"), Color("f2c14e"), Color("8be36b"), Color("c38bff")]

var _time := 0.0
var taken := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44, 40)
	shape.shape = rect
	shape.position = Vector2(0, -20)
	add_child(shape)
	add_to_group("interactable")
	var glow := PointLight2D.new()
	glow.texture = preload("res://scripts/art.gd").light_texture()
	glow.texture_scale = 0.4
	glow.energy = 0.7
	glow.color = Color(0.7, 0.6, 1.0)
	glow.position = Vector2(0, -40)
	add_child(glow)


func can_use() -> bool:
	return not taken


func use() -> void:
	if taken:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("hero"):
			taken = true
			body.has_chalk = true
			Sfx.play("potion")
			_label(body)
			return


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	# Пузатый сосуд на треноге.
	var clay := Color("5a3a2a")
	var rim := Color("7a5236")
	draw_line(Vector2(-12, 0), Vector2(-8, -8), Color("3a2a1c"), 2.0)
	draw_line(Vector2(12, 0), Vector2(8, -8), Color("3a2a1c"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -28), Vector2(14, -28), Vector2(16, -18), Vector2(11, -8), Vector2(-11, -8), Vector2(-16, -18)]), clay)
	draw_rect(Rect2(-16, -30, 32, 3), rim)
	draw_rect(Rect2(-14, -20, 28, 1), clay.darkened(0.3))
	# Варево и цветные пузыри над ним.
	var brew := Color(0.25, 0.12, 0.35) if not taken else Color(0.12, 0.1, 0.1)
	draw_rect(Rect2(-13, -31, 26, 2), brew)
	var count := 7 if not taken else 2
	for i in count:
		var t := fmod(_time * 0.7 + i * 0.37, 1.0)
		var x := sin(i * 2.3 + _time * 1.5) * 9.0
		var y := -32.0 - t * 34.0
		var c: Color = BUBBLES[i % BUBBLES.size()]
		var r := 2.5 + 1.5 * sin(t * PI)
		draw_circle(Vector2(x, y), r, Color(c, 0.85 * (1.0 - t)))
		draw_circle(Vector2(x - r * 0.3, y - r * 0.3), r * 0.35, Color(1, 1, 1, 0.6 * (1.0 - t)))


## Над героем всплывает и тает надпись «Мел»: что он взял.
func _label(hero: Node2D) -> void:
	var label := Label.new()
	label.text = Game.t("Мел")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(80, 20)
	label.position = hero.global_position + Vector2(-40, -50)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.z_index = 10
	get_parent().add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 24, 1.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.8).set_delay(0.8)
	tween.tween_callback(label.queue_free)


## Мел в инвентаре: белый брусок с тенью снизу.
static func draw_chalk(canvas: CanvasItem, at: Vector2) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-8, 1), at + Vector2(4, -6), at + Vector2(8, -2), at + Vector2(-4, 5)]), Color("f2efe6"))
	canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-8, 1), at + Vector2(-4, 5), at + Vector2(-4, 6), at + Vector2(-8, 2)]), Color("b8b2a4"))
	canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-4, 5), at + Vector2(8, -2), at + Vector2(8, -1), at + Vector2(-4, 6)]), Color("cfc9bb"))
