extends Node
## Звуки игры. Все звуки синтезируются в коде при запуске: шум, тоны и огибающие.
## Вызов: Sfx.play("jump").

const RATE := 22050
const VOICES := 8

var enabled := true
var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_sounds = {
		"step": _step(),
		"jump": _jump(),
		"land": _land(),
		"key": _key(),
		"flee": _flee(),
		"door": _door(),
		"exit": _exit(),
		"die": _die(),
		"tap": _tap(),
		"potion": _potion(),
		"lever": _lever(),
		"ui": _ui(),
	}
	# Game загружается после Sfx, поэтому подписка — на следующем кадре.
	(func() -> void: Game.hand_used.connect(func(_kind: String) -> void: play("tap"))).call_deferred()


func play(sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not enabled or not _sounds.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _sounds[sound]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


# --- Синтез -----------------------------------------------------------------

func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = data
	return wav


## Шум через простой фильтр нижних частот: чем меньше cutoff (0..1), тем глуше.
func _noise(seconds: float, cutoff: float, decay: float, gain: float, seed := 1) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var n := int(seconds * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var y := 0.0
	for i in n:
		y += cutoff * (rng.randf_range(-1.0, 1.0) - y)
		out[i] = y * gain * exp(-decay * float(i) / RATE)
	return out


## Тон, частота плавно идёт от f0 к f1. shape: 0 — синус, 1 — квадрат, 2 — треугольник.
func _tone(seconds: float, f0: float, f1: float, shape: int, decay: float, gain: float, attack := 0.004) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		phase += lerpf(f0, f1, t) / RATE
		var p := fmod(phase, 1.0)
		var v: float
		match shape:
			1: v = 1.0 if p < 0.5 else -1.0
			2: v = 4.0 * absf(p - 0.5) - 1.0
			_: v = sin(TAU * p)
		var env := minf(1.0, float(i) / (attack * RATE)) * exp(-decay * float(i) / RATE)
		# Короткое затухание в конце, чтобы не щёлкало.
		env *= minf(1.0, float(n - i) / (0.005 * RATE))
		out[i] = v * env * gain
	return out


func _mix(a: PackedFloat32Array, b: PackedFloat32Array, offset_s := 0.0) -> PackedFloat32Array:
	var off := int(offset_s * RATE)
	var out := a.duplicate()
	if out.size() < off + b.size():
		out.resize(off + b.size())
	for i in b.size():
		out[off + i] += b[i]
	return out


func _step() -> AudioStreamWAV:
	# Мягкий шорох подошвы по камню.
	return _wav(_noise(0.06, 0.25, 70.0, 0.5, 3))


func _jump() -> AudioStreamWAV:
	return _wav(_tone(0.14, 220.0, 520.0, 2, 14.0, 0.35))


func _land() -> AudioStreamWAV:
	return _wav(_mix(_noise(0.09, 0.12, 45.0, 0.8, 7), _tone(0.08, 110.0, 60.0, 0, 40.0, 0.4)))


func _key() -> AudioStreamWAV:
	# Звон: две ноты с обертоном.
	var s := _tone(0.5, 1046.5, 1046.5, 0, 7.0, 0.25)
	s = _mix(s, _tone(0.5, 2093.0, 2093.0, 0, 10.0, 0.08))
	s = _mix(s, _tone(0.6, 1568.0, 1568.0, 0, 6.0, 0.25), 0.09)
	s = _mix(s, _tone(0.6, 3136.0, 3136.0, 0, 9.0, 0.06), 0.09)
	return _wav(s)


func _flee() -> AudioStreamWAV:
	# Ключ ускользнул: насмешливый «фьють».
	return _wav(_mix(_tone(0.18, 900.0, 1800.0, 0, 8.0, 0.25), _noise(0.15, 0.6, 20.0, 0.12, 11)))


func _door() -> AudioStreamWAV:
	# Каменная плита ползёт: глухой гул и скрежет.
	var s := _noise(0.8, 0.05, 2.5, 1.6, 5)
	s = _mix(s, _noise(0.8, 0.35, 4.0, 0.12, 9))
	s = _mix(s, _tone(0.8, 55.0, 48.0, 2, 3.0, 0.25, 0.08))
	return _wav(s)


func _exit() -> AudioStreamWAV:
	# Уровень пройден: восходящее арпеджио.
	var s := PackedFloat32Array()
	var notes := [523.3, 659.3, 784.0, 1046.5]
	for k in notes.size():
		s = _mix(s, _tone(0.45, notes[k], notes[k], 2, 6.0, 0.22), k * 0.09)
	return _wav(s)


func _die() -> AudioStreamWAV:
	return _wav(_mix(_tone(0.45, 420.0, 70.0, 1, 5.0, 0.18), _noise(0.25, 0.3, 15.0, 0.3, 13)))


func _tap() -> AudioStreamWAV:
	# Касание рукой: короткий каменный щелчок.
	return _wav(_mix(_noise(0.05, 0.5, 90.0, 0.5, 17), _tone(0.06, 700.0, 500.0, 0, 60.0, 0.25)))


func _potion() -> AudioStreamWAV:
	# Бульканье: несколько пузырей с растущей высотой.
	var s := PackedFloat32Array()
	for k in 4:
		s = _mix(s, _tone(0.08, 300.0 + k * 90.0, 600.0 + k * 120.0, 0, 30.0, 0.25), k * 0.07)
	return _wav(s)


func _lever() -> AudioStreamWAV:
	return _wav(_mix(_noise(0.12, 0.4, 30.0, 0.5, 19), _tone(0.1, 180.0, 120.0, 1, 30.0, 0.15)))


func _ui() -> AudioStreamWAV:
	return _wav(_tone(0.07, 660.0, 880.0, 2, 30.0, 0.25))
