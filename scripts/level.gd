extends Node2D
## Корень уровня: слоган, подсказки, камера, интерфейс.

@export var level_number := 1
@export var slogan := ""
@export var hints := PackedStringArray()
## Какую кнопку подсвечивать для обучения: left, right, jump, action или пусто.
@export var tutorial_button := ""
@export var level_width := 640.0
@export var level_height := 360.0
@export var fall_limit := 420.0
@export var restart_on_fall := false
## Ширина части уровня, видимой камерой в начале (0 — весь уровень). Остальное — другие комнаты, куда ведут порталы.
@export var view_width := 0.0
## Левый край вида на старте: левее него часть уровня сначала скрыта. Когда герой подходит
## к левому краю экрана, камера плавно открывает и эту часть. 0 — весь уровень виден как обычно.
@export var view_left := 0.0
## Героя можно поднять пальцем и перенести.
@export var hero_grab := false
## Уровень закольцован по горизонтали: левый и правый края экрана связаны.
@export var wrap_horizontal := false
## Полумрак: всё затемнено, светят факелы и фонарь героя.
@export var dark := false
## Пыль, висящая в воздухе.
@export var dust := false
## Локация: от неё зависит оттенок полумрака — камень пирамиды тёплый, подземелья холодный и т. д.
@export_enum("pyramid", "dungeon", "castle", "temple") var theme := "pyramid"
## Свой оттенок полумрака для зала (прозрачный — оттенок локации): у каждого зала стража свой антураж.
@export var shade := Color(0, 0, 0, 0)
## Размер фонаря героя в полумраке: в совсем тёмном зале он светит только себе под ноги.
@export var hero_lamp := 0.55

## Цвет полумрака по локациям: он перекрашивает песчаник в нужный камень.
const SHADE := {
	"pyramid": Color(0.5, 0.43, 0.4),
	"dungeon": Color(0.34, 0.37, 0.44),
	"castle": Color(0.46, 0.47, 0.54),
	"temple": Color(0.3, 0.46, 0.46),
}

const Art := preload("res://scripts/art.gd")

var _cam: Camera2D
var _hero: Node2D
var _view_opened := false
var _hud: CanvasLayer


func _ready() -> void:
	Game.last_level = scene_file_path
	var hero := get_node("Hero")
	hero.fall_limit = fall_limit
	hero.restart_on_fall = restart_on_fall
	hero.grabbable = hero_grab
	if wrap_horizontal:
		hero.wrap_width = level_width
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(view_width if view_width > 0.0 else level_width)
	cam.position_smoothing_enabled = true
	cam.limit_bottom = int(level_height)
	if view_left > 0.0:
		cam.limit_left = int(view_left)
	hero.add_child(cam)
	# На старте камера сразу на месте, без наезда.
	cam.reset_smoothing.call_deferred()
	_cam = cam
	_hero = hero
	var back := get_node_or_null("Back") as Polygon2D
	if back:
		back.texture = _back_texture()
		back.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		back.color = Color.WHITE
	# Фон других комнат (Back2, Back3…): та же кладка, свой оттенок (цвет задан в сцене).
	for child in get_children():
		if child is Polygon2D and child.name.begins_with("Back") and child.name != "Back":
			child.texture = _back_texture()
			child.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	if dark:
		var mod := CanvasModulate.new()
		mod.color = shade if shade.a > 0.0 else SHADE[theme]
		add_child(mod)
		var lamp := PointLight2D.new()
		lamp.texture = Art.light_texture()
		lamp.texture_scale = hero_lamp
		lamp.energy = 0.45
		lamp.color = Color(1.0, 0.85, 0.65)
		lamp.position = Vector2(0, -14)
		hero.add_child(lamp)
	if dust:
		_add_dust()
	var hud := preload("res://scripts/hud.gd").new()
	hud.level = self
	add_child(hud)
	_hud = hud


## Интерфейс уровня: кнопки, название зоны, подсказки.
func hud() -> CanvasLayer:
	return _hud


## Где сейчас пальцы игрока (рука, не кнопки), в координатах уровня.
func hand_points() -> Array[Vector2]:
	return _hud.hand_points() if _hud else ([] as Array[Vector2])


func _process(_delta: float) -> void:
	# Герой дошёл до левого края стартового вида — открываем скрытую часть слева.
	if _cam and not _view_opened and _cam.limit_left > 0 and _hero.global_position.x < view_left + 48.0:
		# Граница камеры уезжает влево за 0,8 с — камера плавно едет, а не прыгает.
		_view_opened = true
		create_tween().set_trans(Tween.TRANS_SINE).tween_property(_cam, "limit_left", 0, 0.8)


## Стена в глубине: в пирамиде — крупные тёмные блоки, в других локациях — прежняя кладка.
func _back_texture() -> Texture2D:
	return Art.back_blocks() if theme == "pyramid" else Art.back_wall()


func _add_dust() -> void:
	var p := CPUParticles2D.new()
	p.amount = int(level_width * level_height / 2500.0)
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(level_width, level_height) / 2.0
	p.position = Vector2(level_width, level_height) / 2.0
	p.gravity = Vector2(0, 2)
	p.direction = Vector2(1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 4.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 0.9, 0.7, 0.0))
	ramp.set_color(1, Color(1, 0.9, 0.7, 0.0))
	ramp.add_point(0.5, Color(1, 0.9, 0.7, 0.55))
	p.color_ramp = ramp
	p.z_index = 3
	add_child(p)
