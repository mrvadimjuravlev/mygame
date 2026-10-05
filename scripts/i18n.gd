extends RefCounted
## Переводы. Ключ — русский текст в том виде, в каком он записан в коде и сценах уровней.
## Нет перевода — показывается русский текст. Вызов: Game.t("Уровни").

const EN := {
	# Меню и экраны
	"Играть": "Play",
	"Играть с начала": "Play again",
	"Продолжить · %d": "Continue · %d",
	"Уровни": "Levels",
	"Настройки": "Settings",
	"Мир 1 · Пирамида": "World 1 · Pyramid",
	"Прототип": "Prototype",
	"Пирамида": "Pyramid",
	"%d из %d пройдено": "%d of %d completed",
	"‹ Назад": "‹ Back",
	"Сбросить прогресс": "Reset progress",
	"Точно сбросить?": "Really reset?",
	"Язык": "Language",
	"Звук": "Sound",
	"Вкл": "On",
	"Выкл": "Off",
	"Коснитесь, чтобы продолжить": "Tap to continue",
	"Прототип пройден!\nУровни 1–%d мира «Пирамида»": "Prototype complete!\nLevels 1–%d of the Pyramid world",
	"К уровням": "To levels",
	"Подсказка %d: %s": "Hint %d: %s",
	"Выбери локацию": "Choose a location",
	"Подземелье": "Dungeon",
	"Замок": "Castle",
	"Затонувший храм": "Sunken Temple",
	"Скоро": "Coming soon",

	# Уровень 1
	"Вперёд": "Forward",
	"Иди к свету.": "Walk towards the light.",
	"Нажимай кнопку «вправо».": "Hold the “right” button.",
	"Дверь в конце коридора справа.": "The door is at the right end of the corridor.",
	# Уровень 2
	"Выше": "Higher",
	"Не все пути ровные.": "Not every path is flat.",
	"Нажми прыжок рядом с уступом.": "Press jump next to the ledge.",
	"Прыгни на два уступа подряд, затем к двери.": "Jump onto both ledges, then go to the door.",
	# Уровень 3
	"Нажми": "Press",
	"Дверь не откроется сама.": "The door won't open by itself.",
	"Рядом с дверью есть рычаг.": "There is a lever near the door.",
	"Поднимись к рычагу и нажми кнопку действия.": "Climb up to the lever and press the action button.",
	# Уровень 4
	"Коснись": "Touch",
	"Герою здесь не справиться одному.": "The hero can't do this alone.",
	"Голубые руны откликаются на прикосновение.": "Blue runes respond to a touch.",
	"Коснись пальцем руны на плите.": "Touch the rune on the slab with your finger.",
	# Уровень 5
	"Сдвинь": "Slide",
	"Мост можно построить.": "A bridge can be built.",
	"Камень с руной можно двигать пальцем.": "A stone with a rune can be moved with your finger.",
	"Перетащи камень с руной вниз на яму и перейди по нему.": "Drag the rune stone down into the pit and walk across it.",
	# Уровень 6
	"Вдвоём": "Together",
	"Одному не дотянуться.": "Too high to reach alone.",
	"Рука может подготовить герою путь.": "Your hand can prepare the way for the hero.",
	"Сдвинь камень к стене под рычагом, запрыгни на него и нажми рычаг.": "Slide the stone to the wall under the lever, jump onto it and pull the lever.",
	# Уровень 7
	"Ключ": "The Key",
	"Дверь заперта, а к ней не перепрыгнуть.": "The door is locked and too far to jump to.",
	"Каменная плита в полу опускает камень с ключом над пропастью.": "A stone plate in the floor lowers the block with the key over the chasm.",
	"Встань на плиту, запрыгни на опустившийся камень, возьми ключ и прыгай к двери.": "Step on the plate, jump onto the lowered block, take the key and jump to the door.",
	# Уровень 8
	"Шаг в пустоту": "Step into Nothing",
	"Ключ высоко, но путь к нему есть.": "The key is high up, but there is a way.",
	"Между камнями не пустота — попробуй прыгнуть туда, где камня не видно.": "The gap between the stones isn't empty: try jumping where you can't see a stone.",
	"С первого камня прыгай вправо и вверх: там невидимый камень, с него — на третий и к ключу.": "From the first stone jump up and to the right: there is an invisible stone. From it, jump to the third one and on to the key.",
	# Уровень 9
	"Выше птиц": "Above the Birds",
	"Лестницу можно опустить.": "The ladder can be lowered.",
	"Птицы летают по одним и тем же линиям — пережди их, остановившись на лестнице.": "The birds always fly along the same lines: stop on the ladder and wait for them to pass.",
	"Дёрни рычаг, лезь вверх (▲), замирай под птицей, пока она не пролетит. Ключ на платформе наверху, вниз — кнопкой действия.": "Pull the lever, climb up (▲) and freeze under each bird until it flies by. The key is on the top platform; climb down with the action button.",
	# Уровень 10
	"Верх — это низ, лево — это право": "Up is down, left is right",
	"Обрыв не перепрыгнуть. Но край экрана — не стена.": "The chasm is too wide to jump. But the edge of the screen is not a wall.",
	"Уйди за левый край экрана — выйдешь справа.": "Walk off the left edge of the screen and you come back on the right.",
	"Иди налево за край, появишься справа. Выпей зелье: гравитация перевернётся, и по потолку дойдёшь до двери у левого края.": "Walk off the left edge to appear on the right. Drink the potion: gravity flips and you can walk along the ceiling to the door at the left edge.",
	# Уровень 11
	"Останови время": "Stop Time",
	"Ключ не даётся, пока идёт время.": "The key won't let you catch it while time runs.",
	"Где-то на уровне сыплется песок.": "Somewhere on this level, sand is running.",
	"Под потолком справа висят песочные часы. Переверни их пальцем — и ключ больше не убежит.": "An hourglass hangs under the ceiling on the right. Flip it with your finger and the key will stop running away.",
	# Уровень 12
	"Не та яма": "The Wrong Pit",
	"Обе ямы можно перепрыгнуть, но не всё нужно перепрыгивать.": "You can jump over both pits, but not everything should be jumped over.",
	"Одна яма смертельна, в другой лежит то, что нужно.": "One pit is deadly; the other holds what you need.",
	"Прыгни во вторую яму за ключом, потом иди вправо прямо в стену: там потайной ход и лестница наверх. Потом по ступенькам к двери.": "Drop into the second pit for the key, then walk right straight into the wall: there is a secret passage and a ladder up. Then climb the steps to the door.",
	# Уровень 13
	"Вишня, небо, солнце, трава": "Cherry, sky, sun, grass",
	"Название зоны — это порядок.": "The name of the zone is the order.",
	"Вишня — красная, небо — синее, солнце — жёлтое, трава — зелёная.": "Cherry is red, sky is blue, sun is yellow, grass is green.",
	"Встань на красную, синюю, жёлтую и зелёную плиты по очереди, и чтобы между ними не было других плит: через лишние перепрыгивай.": "Step on the red, blue, yellow and green plates in turn, with no other plate in between: jump over the ones you don't need.",
	# Уровень 14
	"Толкай": "Push",
	"Камень можно толкать.": "The stone can be pushed.",
	"Столкни камень с уступа. В самом уступе есть тайник, но вход в него высоко.": "Push the stone off the ledge. There is a hidden chamber inside the ledge, but its entrance is high up.",
	"Подтолкни камень к уступу, залезь на него и прыгни влево в стену уступа: там потайной ход и ключ.": "Push the stone against the ledge, climb onto it and jump left into the ledge wall: there is a secret passage with the key.",
}


static func translate(text: String, lang: String) -> String:
	if lang == "en":
		return EN.get(text, text)
	return text
