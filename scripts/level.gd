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

## Цвет полумрака по локациям: он перекрашивает песчаник в нужный камень.
const SHADE := {
	"pyramid": Color(0.5, 0.43, 0.4),
	"dungeon": Color(0.34, 0.37, 0.44),
	"castle": Color(0.46, 0.47, 0.54),
	"temple": Color(0.3, 0.46, 0.46),
}

const Art := preload("res://scripts/art.gd")


func _ready() -> void:
	var hero := get_node("Hero")
	hero.fall_limit = fall_limit
	hero.restart_on_fall = restart_on_fall
	hero.grabbable = hero_grab
	if wrap_horizontal:
		hero.wrap_width = level_width
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(level_width)
	cam.position_smoothing_enabled = true
	cam.limit_bottom = int(level_height)
	hero.add_child(cam)
	var back := get_node_or_null("Back") as Polygon2D
	if back:
		back.texture = Art.back_wall()
		back.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		back.color = Color.WHITE
	if dark:
		var mod := CanvasModulate.new()
		mod.color = SHADE[theme]
		add_child(mod)
		var lamp := PointLight2D.new()
		lamp.texture = Art.light_texture()
		lamp.texture_scale = 0.55
		lamp.energy = 0.45
		lamp.color = Color(1.0, 0.85, 0.65)
		lamp.position = Vector2(0, -14)
		hero.add_child(lamp)
	if dust:
		_add_dust()
	var hud := preload("res://scripts/hud.gd").new()
	hud.level = self
	add_child(hud)


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
