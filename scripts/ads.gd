extends Node
## Реклама AdMob: межстраничная между уровнями и за награду — за подсказки.
## Сейчас стоят тестовые ID от Google. Перед публикацией замените их на свои из кабинета AdMob,
## а App ID — в «Настройки проекта → admob/general/android/app_id».
## Где плагина нет (ПК, веб), реклама просто не показывается и игра идёт дальше без неё.

const INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"
const REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"
## Межстраничная не чаще, чем раз в столько секунд.
const INTERSTITIAL_COOLDOWN := 60.0
## Межстраничную не показываем, пока игрок не прошёл столько уровней: пусть сначала втянется.
const INTERSTITIAL_AFTER_PASSED := 2
## После неудачной загрузки пробуем снова через столько секунд.
const RETRY_DELAY := 30.0

var _ready_to_load := false
## SDK доложил, что инициализирован: с этого момента можно грузить рекламу.
var _sdk_ready := false
var _interstitial: InterstitialAd
var _rewarded: RewardedAd
var _interstitial_loading := false
var _rewarded_loading := false
## Время последнего показа межстраничной (мс с запуска). Отсчёт идёт и от старта игры.
var _last_interstitial_ms := 0


func _ready() -> void:
	if not _has_plugin():
		return
	_request_consent()


## Плагин есть на Android-сборке (и его заглушка в редакторе).
func _has_plugin() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	return OS.get_name() == "Android" or OS.has_feature("editor")


# --- Согласие и запуск --------------------------------------------------------

## Окно согласия на рекламу (GDPR). Оно появляется только там, где нужно, и только если
## настроено в кабинете AdMob («Конфиденциальность и сообщения»). Иначе сразу запускаем SDK.
func _request_consent() -> void:
	var info := UserMessagingPlatform.consent_information
	# Пустые отладочные настройки передаём явно: null Android-часть плагина может не пережить.
	var params := ConsentRequestParameters.new()
	params.consent_debug_settings = ConsentDebugSettings.new()
	info.update(params,
		func() -> void:
			if info.get_is_consent_form_available() \
					and info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
				UserMessagingPlatform.load_consent_form(
					func(form: ConsentForm) -> void: form.show(func(_e: FormError) -> void: _start()),
					func(_e: FormError) -> void: _start())
			else:
				_start(),
		func(_e: FormError) -> void: _start())


func _start() -> void:
	if _ready_to_load:
		return
	_ready_to_load = true
	# Рекламу можно грузить только после того, как SDK доложит о готовности, иначе Android-часть
	# бросает исключение и игра вылетает.
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_sdk_ready = true
		_load_interstitial()
		_load_rewarded()
	MobileAds.set_request_configuration(RequestConfiguration.new())
	MobileAds.initialize(listener)


# --- Межстраничная: между уровнями ----------------------------------------------

## Показывает межстраничную, если пора, и потом вызывает then. Нет рекламы — сразу then.
func between_levels(then: Callable) -> void:
	var passed_enough := Game.passed.size() > INTERSTITIAL_AFTER_PASSED
	var cooled := Time.get_ticks_msec() - _last_interstitial_ms >= INTERSTITIAL_COOLDOWN * 1000.0
	if not (_interstitial and passed_enough and cooled):
		then.call()
		return
	var ad := _interstitial
	_interstitial = null
	var done := func() -> void:
		ad.destroy()
		_last_interstitial_ms = Time.get_ticks_msec()
		_load_interstitial()
		then.call()
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = done
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_e: AdError) -> void: done.call()
	ad.show()


func _load_interstitial() -> void:
	if not _sdk_ready or _interstitial or _interstitial_loading:
		return
	_interstitial_loading = true
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial_loading = false
		_interstitial = ad
	callback.on_ad_failed_to_load = func(_e: LoadAdError) -> void:
		_interstitial_loading = false
		get_tree().create_timer(RETRY_DELAY).timeout.connect(_load_interstitial)
	InterstitialAdLoader.new().load(INTERSTITIAL_ID, AdRequest.new(), callback)


# --- За награду: подсказки ------------------------------------------------------

## Готов ли ролик за награду. Если нет, подсказку даём бесплатно: игрок не должен застревать
## из-за того, что нет интернета.
func rewarded_ready() -> bool:
	return _rewarded != null


## Показывает ролик; on_reward вызывается, только если игрок досмотрел его до награды,
## иначе — on_skip.
func show_rewarded(on_reward: Callable, on_skip := Callable()) -> void:
	if not _rewarded:
		on_reward.call()
		return
	var ad := _rewarded
	_rewarded = null
	var earned := [false]
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		earned[0] = true
	var done := func() -> void:
		ad.destroy()
		_load_rewarded()
		# Награду выдаём после закрытия ролика, когда игра снова на экране.
		if earned[0]:
			on_reward.call()
		elif on_skip.is_valid():
			on_skip.call()
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = done
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_e: AdError) -> void:
		ad.destroy()
		_load_rewarded()
		on_reward.call()
	ad.show(listener)


func _load_rewarded() -> void:
	if not _sdk_ready or _rewarded or _rewarded_loading:
		return
	_rewarded_loading = true
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded_loading = false
		_rewarded = ad
	callback.on_ad_failed_to_load = func(_e: LoadAdError) -> void:
		_rewarded_loading = false
		get_tree().create_timer(RETRY_DELAY).timeout.connect(_load_rewarded)
	RewardedAdLoader.new().load(REWARDED_ID, AdRequest.new(), callback)
