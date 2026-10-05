# Hidden Chambers — прототип (Пирамида, уровни 1–14)

Прототип по концепции из `docs/concept.md` и плану уровней `docs/levels-pyramid.md`.
Пиксель-арт и звуки рисуются и синтезируются в коде, готовых ассетов нет.

Экран старта → «Играть» продолжает с первого непройденного уровня, «Уровни» — выбор уровня.
Пройденные уровни сохраняются (`user://progress.cfg`): следующий открыт, дальше — замок.
Для проверки: пять касаний по заголовку «Пирамида» в выборе уровня открывают все уровни.

## Как запустить
1. Установи [Godot 4.3](https://godotengine.org/download) (обычная версия, не .NET).
2. В Godot: **Import** → выбери файл `project.godot` из этой папки → **Run** (F5).

Управление на ПК:
- **← →** или **A D** — ходьба, **пробел / ↑ / W** — прыжок, **E** — действие (рычаг);
- **мышь** работает как палец: клик — касание, зажать и вести — перетаскивание;
- экранные кнопки в нижних углах тоже нажимаются мышью; **?** справа вверху — подсказка.

## Что внутри
| Папка / файл | Что это |
|---|---|
| `levels/level_01..14.tscn` | уровни, их можно открыть и править в редакторе Godot |
| `ui/title.gd`, `ui/menu.gd`, `ui/finish.gd` | экран старта, выбор уровня, финальный экран |
| `scripts/game.gd` | список уровней, переходы, сохранение прогресса, система событий «триггер → эффект» (`Game.fire`) |
| `scripts/sfx.gd` | звуки: синтез при запуске (шаги, прыжок, приземление, ключ, дверь, выход, гибель, касание), `Sfx.play("jump")` |
| `scripts/hero.gd` | герой: ходьба, прыжок, действие; на этих уровнях смерти нет |
| `scripts/hud.gd` | экранные кнопки и разбор касаний: кнопки по краям — герой, остальное — рука |
| `scripts/rune_block.gd` | камень с голубой руной: касание (TAP) или перетаскивание (DRAG) |
| `scripts/door.gd`, `lever.gd`, `exit_door.gd` | дверь, рычаг, выход |
| `scripts/color_plate.gd`, `plate_sequence.gd` | цветные плиты в полу и головоломка «нажми по порядку» (уровень 13) |
| `scripts/push_stone.gd` | каменный блок: герой толкает его и залезает на него, руна — толчок пальцем (уровень 14) |
| `scripts/solid.gd` | векторная геометрия уровня: любой многоугольник без сетки |
| `scripts/tutorial_hint.gd` | обучающий значок без текста |
| `tools/build_levels.gd` | собирает сцены уровней из описаний (запускается один раз) |
| `tools/autoplay.gd` | автотест: проходит все 14 уровней касаниями и кнопками |

Связи событий задаются в инспекторе: у рычага или руны есть список `targets` (на какие объекты действует) и `effect` (что сделать: `activate`, `close`, `toggle`).

## Проверка из командной строки
```
godot --headless --path . -s tools/autoplay.gd
```
Ожидаемый результат: «Уровень 1…14: пройден».

## Сборка на Android
В Godot: **Editor → Manage Export Templates** (скачать шаблоны), затем **Project → Export → Add → Android**.
Нужны Android SDK и ключ подписи — Godot подскажет, что указать. Проще всего проверить на телефоне через **Remote Debug** с подключённым по USB устройством.

## Сборка APK для Android
Отладочный APK собирается без Gradle, из готового шаблона Godot:
1. Шаблоны экспорта Godot 4.3 (`Godot_v4.3-stable_export_templates.tpz` с GitHub) — `android_debug.apk`, `android_release.apk`, `version.txt` в `~/.local/share/godot/export_templates/4.3.stable/`.
2. Java 17+ и `apksigner` (в Ubuntu: `apt install apksigner zipalign`). Полный Android SDK не обязателен: Godot ищет `apksigner` в `<sdk>/build-tools/<версия>/`.
3. Отладочный ключ: `keytool -genkeypair -alias androiddebugkey -keypass android -storepass android -keystore debug.keystore -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -keyalg RSA`.
4. В настройках редактора указать `export/android/android_sdk_path` и `export/android/debug_keystore`.
5. `godot --headless --path . --export-debug "Android" ../builds/hidden-chambers.apk`

Иконка рисуется скриптом `tools/make_icon.gd`. Стартовый экран — выбор уровня (`ui/menu.tscn`).
