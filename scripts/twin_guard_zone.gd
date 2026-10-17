extends Area2D
## Место перед стражем-шакалом: подойдёшь — он заговорит, потом — кнопкой действия.
## Когда вопрос уже задан, сам страж больше не окликает: напомнит ответ только по кнопке действия.

var guards: Node
var index := 0


func _ready() -> void:
	add_to_group("interactable")
	body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("hero") and not guards.asked:
			use.call_deferred())


func can_use() -> bool:
	return guards.can_talk()


func use() -> void:
	guards.talk(index)
