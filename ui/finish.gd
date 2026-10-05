extends Control
## Экран после последнего уровня.


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var label := Label.new()
	label.text = Game.t("Прототип пройден!\nУровни 1–%d мира «Пирамида»") % Game.LEVELS.size()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(640, 80)
	label.position = Vector2(0, 120)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("ffe7a3"))
	add_child(label)
	var button := Button.new()
	button.text = Game.t("К уровням")
	button.size = Vector2(140, 40)
	button.position = Vector2(250, 230)
	button.pressed.connect(Game.start_over)
	Sfx.play("exit")
	add_child(button)
