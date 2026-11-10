extends CanvasLayer
class_name HUD

## Capa de interfaz gráfica de usuario (HUD).
## Gestiona la visualización de corazones, barra de progreso con icono corredor,
## y los paneles modales de pausa, victoria y derrota.

signal restart_game
signal go_to_menu

const HEART_FULL := preload("res://assets/sprites/corazon_lleno.png")
const HEART_EMPTY := preload("res://assets/sprites/corazon_vacio.png")

@onready var title_label: Label = %TitleLabel
@onready var hearts_container: HBoxContainer = %HeartsContainer
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var runner_icon: TextureRect = %RunnerIcon
@onready var difficulty_label: Label = %DifficultyLabel
@onready var controls_label: Label = %ControlsLabel
@onready var intro_banner: Label = %IntroBanner
@onready var overlay: ColorRect = %Overlay
@onready var pause_panel: PanelContainer = %PausePanel
@onready var game_over_panel: PanelContainer = %GameOverPanel
@onready var victory_panel: PanelContainer = %VictoryPanel
@onready var game_over_stats: Label = %GameOverStats
@onready var victory_stats: Label = %VictoryStats
@onready var btn_resume: Button = %BtnResume
@onready var btn_pause_menu: Button = %BtnPauseMenu
@onready var btn_retry: Button = %BtnRetry
@onready var btn_menu_go: Button = %BtnGameOverMenu
@onready var btn_play_again: Button = %BtnPlayAgain
@onready var btn_menu_vic: Button = %BtnVictoryMenu
@onready var sfx_game_over: AudioStreamPlayer = $SFXGameOver
@onready var sfx_ui: AudioStreamPlayer = $SFXUi
@onready var mobile_controls: MobileControls = get_node_or_null("MobileControls")

var is_game_finished: bool = false
var is_paused: bool = false

var _hearts: Array[TextureRect] = []
var _shown_hp: int = -1
var _target_progress: float = 0.0
var _overlay_alpha: float = 0.6
var _panel_tweens: Dictionary = {}
var _overlay_tween: Tween

func _ready() -> void:
	_overlay_alpha = overlay.color.a
	for panel in [pause_panel, game_over_panel, victory_panel]:
		panel.visible = false
	overlay.visible = false

	btn_resume.pressed.connect(set_paused.bind(false))
	btn_pause_menu.pressed.connect(_on_menu_pressed)
	btn_retry.pressed.connect(_on_retry_pressed)
	btn_play_again.pressed.connect(_on_retry_pressed)
	btn_menu_go.pressed.connect(_on_menu_pressed)
	btn_menu_vic.pressed.connect(_on_menu_pressed)

	for btn in [btn_resume, btn_pause_menu, btn_retry, btn_menu_go, btn_play_again, btn_menu_vic]:
		UiJuice.attach_button(btn, sfx_ui)

	if mobile_controls:
		mobile_controls.pause_requested.connect(func(): set_paused(not is_paused))

func _process(delta: float) -> void:
	# La barra avanza con suavidad en vez de saltar
	if absf(progress_bar.value - _target_progress) > 0.05:
		progress_bar.value = lerpf(progress_bar.value, _target_progress, 1.0 - exp(-10.0 * delta))
	else:
		progress_bar.value = _target_progress
	var ratio := progress_bar.value / 100.0
	runner_icon.position.x = roundf(progress_bar.size.x * ratio - runner_icon.size.x * 0.5)
	if not get_tree().paused:
		runner_icon.position.y = -9.0 - roundf(absf(sin(Time.get_ticks_msec() * 0.012)) * 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if SceneTransition.is_busy:
		return
	var key: int = event.keycode
	var handled := true
	if is_game_finished:
		# Nota: ESPACIO no reinicia, para no reiniciar sin querer mientras se dispara
		if key == KEY_R or key == KEY_ENTER or key == KEY_KP_ENTER:
			_on_retry_pressed()
		elif key == KEY_ESCAPE:
			_on_menu_pressed()
		else:
			handled = false
	elif is_paused:
		if key == KEY_ESCAPE or key == KEY_P:
			set_paused(false)
		elif key == KEY_M:
			_on_menu_pressed()
		else:
			handled = false
	else:
		if key == KEY_ESCAPE or key == KEY_P:
			set_paused(true)
		else:
			handled = false
	if handled:
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	# Pausa automática si la ventana pierde el foco
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree():
		if not is_game_finished and not is_paused and not SceneTransition.is_busy:
			set_paused(true)

func set_paused(paused: bool) -> void:
	if paused == is_paused or is_game_finished:
		return
	is_paused = paused
	get_tree().paused = paused
	GameSettings.duck_music(paused)
	if paused:
		_show_panel(pause_panel, btn_resume)
		if mobile_controls:
			mobile_controls.visible = false
	else:
		_hide_panel(pause_panel)
		if mobile_controls:
			mobile_controls.visible = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()

func set_difficulty_text(diff_name: String) -> void:
	difficulty_label.text = "Dificultad: %s" % diff_name

func set_level_title(title: String) -> void:
	if title_label:
		title_label.text = title

func reset_state() -> void:
	is_game_finished = false
	is_paused = false
	_shown_hp = -1
	_target_progress = 0.0
	for panel in [pause_panel, game_over_panel, victory_panel]:
		panel.visible = false
	overlay.visible = false
	if mobile_controls:
		mobile_controls.visible = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()

## Reutiliza los nodos de corazones (antes se destruían y creaban en cada golpe)
## y anima los que cambian.
func update_hearts(current: int, max_hp: int) -> void:
	if _hearts.size() != max_hp:
		for child in hearts_container.get_children():
			child.queue_free()
		_hearts.clear()
		for i in range(max_hp):
			var tr := TextureRect.new()
			tr.custom_minimum_size = Vector2(22, 22)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.pivot_offset = Vector2(11, 11)
			hearts_container.add_child(tr)
			_hearts.append(tr)

	for i in range(max_hp):
		_hearts[i].texture = HEART_FULL if i < current else HEART_EMPTY

	if _shown_hp >= 0:
		if current < _shown_hp:
			for i in range(maxi(current, 0), mini(_shown_hp, max_hp)):
				_animate_heart_lost(_hearts[i])
			# Todos los corazones tiemblan un poco
			for i in range(max_hp):
				_wobble(_hearts[i])
		elif current > _shown_hp:
			for i in range(_shown_hp, mini(current, max_hp)):
				_pop(_hearts[i], 1.5)
	_shown_hp = current

func _animate_heart_lost(heart: TextureRect) -> void:
	heart.scale = Vector2(1.8, 1.8)
	heart.modulate = Color(3.0, 1.0, 1.0)
	var tw := heart.create_tween().set_parallel(true)
	tw.tween_property(heart, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(heart, "modulate", Color.WHITE, 0.35)

func _wobble(node: Control) -> void:
	var tw := node.create_tween()
	tw.tween_property(node, "rotation", 0.3, 0.05)
	tw.tween_property(node, "rotation", -0.25, 0.08)
	tw.tween_property(node, "rotation", 0.0, 0.1)

func _pop(node: Control, amount: float = 1.3) -> void:
	node.scale = Vector2(amount, amount)
	node.create_tween().tween_property(node, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func update_progress(current_x: float, max_x: float) -> void:
	_target_progress = clampf((current_x / max_x) * 100.0, 0.0, 100.0)

## Cartel de inicio de nivel y desvanecimiento de las instrucciones.
func show_intro(level_title: String, diff_name: String = "") -> void:
	if diff_name != "":
		intro_banner.text = "¡%s!\nDificultad: %s" % [level_title, diff_name]
	else:
		intro_banner.text = "¡%s!" % level_title
	intro_banner.visible = true
	intro_banner.modulate.a = 0.0
	intro_banner.pivot_offset = intro_banner.size * 0.5
	intro_banner.scale = Vector2(0.5, 0.5)
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.set_parallel(true)
	tw.tween_property(intro_banner, "modulate:a", 1.0, 0.2)
	tw.tween_property(intro_banner, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_interval(1.4)
	tw.set_parallel(true)
	tw.tween_property(intro_banner, "modulate:a", 0.0, 0.35)
	tw.tween_property(intro_banner, "position:y", intro_banner.position.y - 24.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.set_parallel(false)
	tw.tween_callback(intro_banner.hide)

	controls_label.modulate.a = 1.0
	var tw2 := create_tween()
	tw2.tween_interval(6.0)
	tw2.tween_property(controls_label, "modulate:a", 0.0, 1.0)

## Cartel de nivel superado
func show_level_complete(level_name: String) -> void:
	intro_banner.text = "¡NIVEL SUPERADO!\n%s" % level_name
	intro_banner.visible = true
	intro_banner.modulate.a = 0.0
	intro_banner.pivot_offset = intro_banner.size * 0.5
	intro_banner.scale = Vector2(0.5, 0.5)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(intro_banner, "modulate:a", 1.0, 0.25)
	tw.tween_property(intro_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_interval(1.2)
	tw.set_parallel(true)
	tw.tween_property(intro_banner, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(intro_banner.hide)

## `stats` = { "defeated": int, "progress": float }
func show_game_over(stats: Dictionary = {}) -> void:
	if is_game_finished:
		return
	is_game_finished = true
	if mobile_controls:
		mobile_controls.visible = false
	if sfx_game_over:
		sfx_game_over.play()
	game_over_stats.text = "Antivalores vencidos: %d  ·  Progreso: %d %%" % [
		stats.get("defeated", 0), int(stats.get("progress", _target_progress))]
	_show_panel(game_over_panel, btn_retry)

## `stats` = { "time": float, "defeated": int, "health": int, "max_health": int }
func show_victory(stats: Dictionary = {}) -> void:
	if is_game_finished:
		return
	is_game_finished = true
	if mobile_controls:
		mobile_controls.visible = false
	_target_progress = 100.0
	_show_panel(victory_panel, btn_play_again)

	# Las estadísticas "cuentan" hacia arriba
	var total_defeated: int = stats.get("defeated", 0)
	var time_s: float = stats.get("time", 0.0)
	var hp: int = stats.get("health", 0)
	var max_hp: int = stats.get("max_health", 0)
	var update := func(t: float) -> void:
		victory_stats.text = "Tiempo: %s  ·  Antivalores vencidos: %d  ·  Corazones: %d/%d" % [
			_format_time(time_s * t), roundi(total_defeated * t), hp, max_hp]
	update.call(0.0)
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_method(update, 0.0, 1.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_pop.bind(victory_stats, 1.15))

func _format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]

## Muestra un panel con fondo oscurecido, "pop" de escala y entrada escalonada de su contenido.
func _show_panel(panel: Control, focus_button: Button = null) -> void:
	_fade_overlay(true)
	_kill_panel_tween(panel)
	panel.visible = true
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.75, 0.75)
	panel.modulate.a = 0.0

	var tw := panel.create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)
	_panel_tweens[panel] = tw

	# Contenido entrando uno tras otro
	var box := panel.get_child(0)
	var i := 0
	for child in box.get_children():
		if child is Control:
			child.modulate.a = 0.0
			tw.tween_property(child, "modulate:a", 1.0, 0.2).set_delay(0.08 + i * 0.05)
			i += 1

	if focus_button:
		focus_button.grab_focus()

func _hide_panel(panel: Control) -> void:
	_fade_overlay(false)
	_kill_panel_tween(panel)
	panel.pivot_offset = panel.size * 0.5
	var tw := panel.create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(0.85, 0.85), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(panel, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(panel.hide)
	_panel_tweens[panel] = tw

func _kill_panel_tween(panel: Control) -> void:
	var old: Tween = _panel_tweens.get(panel)
	if old and old.is_valid():
		old.kill()

func _fade_overlay(show: bool) -> void:
	if _overlay_tween and _overlay_tween.is_valid():
		_overlay_tween.kill()
	_overlay_tween = create_tween()
	if show:
		if not overlay.visible:
			overlay.color.a = 0.0
			overlay.visible = true
		_overlay_tween.tween_property(overlay, "color:a", _overlay_alpha, 0.3)
	else:
		_overlay_tween.tween_property(overlay, "color:a", 0.0, 0.15)
		_overlay_tween.tween_callback(overlay.hide)

func _on_retry_pressed() -> void:
	restart_game.emit()

func _on_menu_pressed() -> void:
	go_to_menu.emit()
