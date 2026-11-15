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
@onready var quota_label: Label = get_node_or_null("%QuotaLabel")
@onready var controls_label: Label = %ControlsLabel
@onready var intro_banner: Label = %IntroBanner
@onready var overlay: ColorRect = %Overlay
@onready var pause_panel: PanelContainer = %PausePanel
@onready var game_over_panel: PanelContainer = %GameOverPanel
@onready var victory_panel: PanelContainer = %VictoryPanel
@onready var boss_bar_container: PanelContainer = get_node_or_null("%BossBarContainer")
@onready var boss_name_label: Label = get_node_or_null("%BossNameLabel")
@onready var boss_hp_label: Label = get_node_or_null("%BossHpLabel")
@onready var boss_progress_bar: ProgressBar = get_node_or_null("%BossProgressBar")
@onready var game_over_stats: Label = %GameOverStats
@onready var victory_stats: Label = %VictoryStats
@onready var btn_resume: Button = %BtnResume
@onready var btn_pause_menu: Button = %BtnPauseMenu
@onready var btn_pause_retry: Button = get_node_or_null("%BtnPauseRetry")
@onready var btn_pause_hud: Button = get_node_or_null("%BtnPauseHud")
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
var _adapted_touch: bool = false
var _input_hint_mode: String = "keyboard"
var _modal_safe_scale: Vector2 = Vector2.ONE
var btn_pause_mute: Button = null

func _ensure_nodes() -> void:
	if hearts_container == null:
		hearts_container = get_node_or_null("%HeartsContainer")
	if title_label == null:
		title_label = get_node_or_null("%TitleLabel")
	if progress_bar == null:
		progress_bar = get_node_or_null("%ProgressBar")
	if runner_icon == null:
		runner_icon = get_node_or_null("%RunnerIcon")
	if difficulty_label == null:
		difficulty_label = get_node_or_null("%DifficultyLabel")
	if controls_label == null:
		controls_label = get_node_or_null("%ControlsLabel")
	if intro_banner == null:
		intro_banner = get_node_or_null("%IntroBanner")
	if quota_label == null:
		quota_label = get_node_or_null("%QuotaLabel")
	if boss_bar_container == null:
		boss_bar_container = get_node_or_null("%BossBarContainer")
	if boss_name_label == null:
		boss_name_label = get_node_or_null("%BossNameLabel")
	if boss_hp_label == null:
		boss_hp_label = get_node_or_null("%BossHpLabel")
	if boss_progress_bar == null:
		boss_progress_bar = get_node_or_null("%BossProgressBar")
	if overlay == null:
		overlay = get_node_or_null("%Overlay")
	if pause_panel == null:
		pause_panel = get_node_or_null("%PausePanel")
	if game_over_panel == null:
		game_over_panel = get_node_or_null("%GameOverPanel")
	if victory_panel == null:
		victory_panel = get_node_or_null("%VictoryPanel")
	if btn_pause_hud == null:
		btn_pause_hud = get_node_or_null("%BtnPauseHud")
	if btn_pause_retry == null:
		btn_pause_retry = get_node_or_null("%BtnPauseRetry")
	if btn_resume == null:
		btn_resume = get_node_or_null("%BtnResume")
	if btn_pause_menu == null:
		btn_pause_menu = get_node_or_null("%BtnPauseMenu")
	if btn_retry == null:
		btn_retry = get_node_or_null("%BtnRetry")
	if btn_menu_go == null:
		btn_menu_go = get_node_or_null("%BtnGameOverMenu")
	if btn_play_again == null:
		btn_play_again = get_node_or_null("%BtnPlayAgain")
	if btn_menu_vic == null:
		btn_menu_vic = get_node_or_null("%BtnVictoryMenu")
	if not _adapted_touch:
		_adapt_for_touch()

func _ready() -> void:
	_ensure_nodes()
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

	if btn_pause_hud:
		btn_pause_hud.pressed.connect(func(): set_paused(not is_paused))
		UiJuice.attach_button(btn_pause_hud, sfx_ui)
	if btn_pause_retry:
		btn_pause_retry.pressed.connect(_on_retry_pressed)
		UiJuice.attach_button(btn_pause_retry, sfx_ui)

	for btn in [btn_resume, btn_pause_menu, btn_retry, btn_menu_go, btn_play_again, btn_menu_vic]:
		UiJuice.attach_button(btn, sfx_ui)

	if pause_panel:
		var pause_vbox := pause_panel.get_node_or_null("VBoxContainer")
		if pause_vbox and pause_vbox.get_node_or_null("BtnPauseMute") == null:
			btn_pause_mute = Button.new()
			btn_pause_mute.name = "BtnPauseMute"
			btn_pause_mute.pressed.connect(_on_mute_toggle_pressed)
			pause_vbox.add_child(btn_pause_mute)
			if btn_pause_menu and btn_pause_menu.get_parent() == pause_vbox:
				pause_vbox.move_child(btn_pause_mute, btn_pause_menu.get_index())
			UiJuice.attach_button(btn_pause_mute, sfx_ui)
	_refresh_pause_mute_label()

	if mobile_controls:
		mobile_controls.pause_requested.connect(func(): set_paused(not is_paused))
		if mobile_controls.has_signal("touch_mode_changed"):
			mobile_controls.touch_mode_changed.connect(_on_touch_mode_changed)

	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)

	_adapt_for_touch()
	_update_safe_area()
	if is_inside_tree() and get_viewport():
		if not get_viewport().size_changed.is_connected(_update_safe_area):
			get_viewport().size_changed.connect(_update_safe_area)

func _exit_tree() -> void:
	if Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.disconnect(_on_joy_connection_changed)

func _process(delta: float) -> void:
	if progress_bar == null or runner_icon == null:
		_ensure_nodes()
	if progress_bar == null or runner_icon == null:
		return
	# La barra avanza con suavidad en vez de saltar
	if absf(progress_bar.value - _target_progress) > 0.05:
		progress_bar.value = lerpf(progress_bar.value, _target_progress, 1.0 - exp(-10.0 * delta))
	else:
		progress_bar.value = _target_progress
	var ratio := progress_bar.value / 100.0
	runner_icon.position.x = roundf(progress_bar.size.x * ratio - runner_icon.size.x * 0.5)
	if runner_icon.visible and is_inside_tree() and get_tree() and not get_tree().paused:
		runner_icon.position.y = -9.0

func _has_active_cutscene() -> bool:
	for child in get_children():
		if child is StoryCutscene and child.visible:
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if _has_active_cutscene():
		return
	var st = get_node_or_null("/root/SceneTransition")
	if st and st.is_busy:
		return

	var handled := false

	if event is InputEventKey and event.pressed and not event.is_echo():
		if not _is_touch_active():
			_set_input_hint_mode("keyboard")
		var key: int = event.keycode
		handled = true
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
			elif key == KEY_R:
				_on_retry_pressed()
			elif key == KEY_M:
				_on_menu_pressed()
			elif key == KEY_V:
				_on_mute_toggle_pressed()
			else:
				handled = false
		else:
			if key == KEY_ESCAPE or key == KEY_P:
				set_paused(true)
			else:
				handled = false

	elif event is InputEventJoypadButton and event.pressed and not event.is_echo():
		_set_input_hint_mode("gamepad")
		var btn_idx: int = event.button_index
		handled = true
		if is_game_finished:
			if btn_idx == JOY_BUTTON_A or btn_idx == JOY_BUTTON_START:
				_on_retry_pressed()
			elif btn_idx == JOY_BUTTON_B or btn_idx == JOY_BUTTON_BACK:
				_on_menu_pressed()
			else:
				handled = false
		elif is_paused:
			if btn_idx == JOY_BUTTON_B or btn_idx == JOY_BUTTON_START:
				set_paused(false)
			elif btn_idx == JOY_BUTTON_Y or btn_idx == JOY_BUTTON_BACK:
				_on_menu_pressed()
			else:
				handled = false
		else:
			if btn_idx == JOY_BUTTON_START:
				set_paused(true)
			else:
				handled = false

	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.45:
		_set_input_hint_mode("gamepad")

	if handled and get_viewport():
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	var is_transitioning := false
	if is_inside_tree():
		var st = get_node_or_null("/root/SceneTransition")
		is_transitioning = st.is_busy if st else false
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			if not is_game_finished and not is_paused and not is_transitioning:
				set_paused(true)
		NOTIFICATION_WM_GO_BACK_REQUEST:
			# Si hay una cinemática de historia activa como hijo del HUD, delegar a ella
			for child in get_children():
				if child is StoryCutscene or (child.has_method("has_method") and child.has_method("_skip_cutscene")):
					child._skip_cutscene()
					return
			if is_game_finished:
				_on_menu_pressed()
			elif is_paused:
				set_paused(false)
			else:
				set_paused(true)

## Ajusta posiciones y márgenes del HUD para respetar muescas (notches) y Safe Areas de Android
func _update_safe_area() -> void:
	if not is_inside_tree() or get_viewport() == null:
		return
	_ensure_nodes()
	var vp_size := get_viewport().get_visible_rect().size
	var insets := MobileControls.get_safe_insets_for_viewport(get_viewport(), 6.0)
	var avail_w := maxf(260.0, vp_size.x - insets.position.x - insets.size.x)
	var avail_h := maxf(200.0, vp_size.y - insets.position.y - insets.size.y)

	# 1. Botón de Pausa / Menú: respetar muesca derecha y margen superior
	var btn_w := 88.0
	if btn_pause_hud:
		btn_w = btn_pause_hud.custom_minimum_size.x if btn_pause_hud.custom_minimum_size.x > 0 else 88.0
		var btn_h := btn_pause_hud.custom_minimum_size.y if btn_pause_hud.custom_minimum_size.y > 0 else 44.0
		btn_pause_hud.offset_right = -insets.size.x
		btn_pause_hud.offset_left = -insets.size.x - btn_w
		btn_pause_hud.offset_top = insets.position.y
		btn_pause_hud.offset_bottom = insets.position.y + btn_h

	# 2. Panel Superior del HUD: respetar muesca izquierda y no traslapar con BtnPauseHud
	var top_panel: Control = get_node_or_null("%TopPanel")
	if top_panel:
		top_panel.offset_left = insets.position.x
		top_panel.offset_top = insets.position.y
		top_panel.offset_right = -(insets.size.x + btn_w + 8.0)
		top_panel.offset_bottom = insets.position.y + 44.0

	var top_bar_w := vp_size.x - insets.position.x - (insets.size.x + btn_w + 8.0)
	if progress_bar:
		progress_bar.custom_minimum_size.x = 74.0 if top_bar_w < 660.0 else 110.0
	if title_label:
		title_label.custom_minimum_size.x = 90.0 if top_bar_w < 660.0 else 140.0
	if difficulty_label:
		difficulty_label.visible = top_bar_w >= 580.0

	# 3. Barra de Jefe: centrada pero respetando el margen superior de la muesca y ancho disponible
	if boss_bar_container:
		var boss_half_w := minf(170.0, avail_w * 0.46)
		boss_bar_container.offset_left = -boss_half_w
		boss_bar_container.offset_right = boss_half_w
		boss_bar_container.offset_top = insets.position.y + 48.0
		boss_bar_container.offset_bottom = insets.position.y + 82.0

	# 4. Texto de controles / pie de pantalla: respetar muescas laterales y barra de gestos inferior
	if controls_label:
		var bottom_inset := maxf(6.0, insets.size.y)
		controls_label.offset_left = insets.position.x + 10.0
		controls_label.offset_right = -insets.size.x - 10.0
		controls_label.offset_bottom = -bottom_inset
		controls_label.offset_top = -bottom_inset - 34.0
		controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		controls_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

	# 5. Escala segura para modales en pantallas compactas o con notches amplios
	var modal_s := minf(1.0, minf((avail_w - 16.0) / 540.0, (avail_h - 16.0) / 330.0))
	_modal_safe_scale = Vector2(maxf(0.68, modal_s), maxf(0.68, modal_s))
	for panel in [pause_panel, game_over_panel, victory_panel]:
		if panel and panel.visible:
			panel.pivot_offset = panel.size * 0.5
			panel.scale = _modal_safe_scale

	_refresh_controls_footer(avail_w)

func _is_touch_active() -> bool:
	if mobile_controls and mobile_controls.visible:
		return true
	return MobileControls.is_touch_device()

func _on_touch_mode_changed(touch_active: bool) -> void:
	_adapted_touch = false
	_input_hint_mode = "touch" if touch_active else ("gamepad" if not Input.get_connected_joypads().is_empty() else "keyboard")
	_adapt_for_touch()

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	if _is_touch_active():
		return
	_input_hint_mode = "gamepad" if not Input.get_connected_joypads().is_empty() else "keyboard"
	_refresh_controls_footer()

func _set_input_hint_mode(mode: String) -> void:
	if _input_hint_mode == mode:
		return
	_input_hint_mode = mode
	_refresh_controls_footer()

func _refresh_controls_footer(avail_w: float = -1.0) -> void:
	if controls_label == null:
		return
	if avail_w < 0.0:
		if is_inside_tree() and get_viewport():
			var vp_size := get_viewport().get_visible_rect().size
			var insets := MobileControls.get_safe_insets_for_viewport(get_viewport(), 6.0)
			avail_w = maxf(260.0, vp_size.x - insets.position.x - insets.size.x)
		else:
			avail_w = 800.0

	var mode := "touch" if _is_touch_active() else _input_hint_mode
	match mode:
		"touch":
			if avail_w >= 640.0:
				controls_label.add_theme_font_size_override("font_size", 11)
				controls_label.text = "Izq: mover · Der: virtud · PULSO · FOCUS: precisión · Pausa ↗"
			else:
				controls_label.add_theme_font_size_override("font_size", 10)
				controls_label.text = "Izq: mover · Der: virtud · PULSO · FOCUS"
		"gamepad":
			if avail_w >= 640.0:
				controls_label.add_theme_font_size_override("font_size", 11)
				controls_label.text = "Stick Izq: mover · Der / A: virtud · X: pulso · LB: enfoque · Start: pausa"
			else:
				controls_label.add_theme_font_size_override("font_size", 10)
				controls_label.text = "Stick Izq: mover · A: virtud · X: pulso · Start: pausa"
		_:
			if avail_w >= 680.0:
				controls_label.add_theme_font_size_override("font_size", 12)
				controls_label.text = "WASD / Flechas: mover · Espacio: virtud · E: pulso · Shift: enfoque · Esc: pausa"
			else:
				controls_label.add_theme_font_size_override("font_size", 10)
				controls_label.text = "WASD: mover · Espacio: virtud · E: pulso · Esc: pausa"

## Adapta los textos de los botones modales e instrucciones según plataforma/táctil
func _adapt_for_touch() -> void:
	if _adapted_touch:
		return
	_adapted_touch = true
	var is_touch := _is_touch_active()
	if is_touch:
		_input_hint_mode = "touch"
		if btn_resume:
			btn_resume.text = "Continuar ▶"
		if btn_pause_retry:
			btn_pause_retry.text = "Reiniciar nivel ↺"
		if btn_pause_menu:
			btn_pause_menu.text = "Menú principal ⌂"
		if btn_retry:
			btn_retry.text = "Reintentar ↺"
		if btn_menu_go:
			btn_menu_go.text = "Menú principal ⌂"
		if btn_play_again:
			btn_play_again.text = "Jugar de nuevo ▶"
		if btn_menu_vic:
			btn_menu_vic.text = "Menú principal ⌂"
	else:
		if _input_hint_mode == "touch":
			_input_hint_mode = "gamepad" if not Input.get_connected_joypads().is_empty() else "keyboard"
		elif not Input.get_connected_joypads().is_empty():
			_input_hint_mode = "gamepad"
		if btn_resume:
			btn_resume.text = "Continuar (Esc)"
		if btn_pause_retry:
			btn_pause_retry.text = "Reiniciar nivel (R)"
		if btn_pause_menu:
			btn_pause_menu.text = "Menú principal (M)"
		if btn_retry:
			btn_retry.text = "Reintentar (Enter / R)"
		if btn_menu_go:
			btn_menu_go.text = "Menú principal (Esc)"
		if btn_play_again:
			btn_play_again.text = "Jugar de nuevo (Enter)"
		if btn_menu_vic:
			btn_menu_vic.text = "Menú principal (Esc)"
	_refresh_controls_footer()

func set_paused(paused: bool) -> void:
	if paused == is_paused or is_game_finished:
		return
	is_paused = paused
	if is_inside_tree() and get_tree():
		get_tree().paused = paused
	var gs = get_node_or_null("/root/GameSettings") if is_inside_tree() else null
	if gs and gs.has_method("duck_music"):
		gs.duck_music(paused)
	if paused:
		_refresh_pause_mute_label()
		if mobile_controls:
			mobile_controls.deactivate()
		_show_panel(pause_panel, btn_resume)
	else:
		_hide_panel(pause_panel)
		if mobile_controls:
			mobile_controls.activate()

func _on_mute_toggle_pressed() -> void:
	var gs = get_node_or_null("/root/GameSettings") if is_inside_tree() else null
	if gs and gs.has_method("toggle_mute"):
		gs.toggle_mute()
	_refresh_pause_mute_label()

func _refresh_pause_mute_label() -> void:
	if btn_pause_mute == null:
		return
	var gs = get_node_or_null("/root/GameSettings") if is_inside_tree() else null
	var is_muted := bool(gs.get("muted")) if gs else false
	btn_pause_mute.text = "Audio: Silencio (V)" if is_muted else "Audio: Activo (V)"

func set_difficulty_text(diff_name: String) -> void:
	_ensure_nodes()
	if difficulty_label:
		difficulty_label.text = "Dificultad: %s" % diff_name

func set_level_title(title: String) -> void:
	_ensure_nodes()
	if title_label:
		title_label.text = title

func reset_state() -> void:
	_ensure_nodes()
	is_game_finished = false
	is_paused = false
	_shown_hp = -1
	_target_progress = 0.0
	for panel in [pause_panel, game_over_panel, victory_panel]:
		if panel:
			panel.visible = false
	if overlay:
		overlay.visible = false
	if boss_bar_container:
		boss_bar_container.visible = false
	if quota_label:
		quota_label.text = ""
	if mobile_controls:
		mobile_controls.activate()

func update_quota(defeated: int, quota: int) -> void:
	_ensure_nodes()
	if quota_label:
		if defeated >= quota:
			quota_label.text = "Jefe en el área"
			quota_label.modulate = Color(0.92, 0.48, 0.52)
		else:
			quota_label.text = "Antivalores: %d/%d" % [defeated, quota]
			quota_label.modulate = Color(0.88, 0.9, 0.94)

func show_boss_bar(boss_name: String, current_hp: int, max_hp: int) -> void:
	_ensure_nodes()
	if boss_bar_container:
		boss_bar_container.visible = true
		boss_bar_container.modulate.a = 0.0
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(boss_bar_container, "modulate:a", 1.0, 0.3)
	if boss_name_label:
		boss_name_label.text = "JEFE: %s" % boss_name
	update_boss_bar(current_hp, max_hp)

func update_boss_bar(current_hp: int, max_hp: int) -> void:
	_ensure_nodes()
	if boss_progress_bar:
		boss_progress_bar.max_value = max_hp
		boss_progress_bar.value = current_hp
	if boss_hp_label:
		boss_hp_label.text = "%d / %d" % [maxi(0, current_hp), max_hp]

func hide_boss_bar(immediate: bool = false) -> void:
	_ensure_nodes()
	if boss_bar_container and boss_bar_container.visible:
		if immediate:
			boss_bar_container.modulate.a = 0.0
			boss_bar_container.visible = false
			return
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(boss_bar_container, "modulate:a", 0.0, 0.3)
		tw.tween_callback(func(): boss_bar_container.visible = false)

## Reutiliza los nodos de corazones (antes se destruían y creaban en cada golpe)
## y anima los que cambian.
func update_hearts(current: int, max_hp: int) -> void:
	_ensure_nodes()
	if hearts_container == null:
		return
	if _hearts.size() != max_hp:
		for child in hearts_container.get_children():
			hearts_container.remove_child(child)
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
	_ensure_nodes()
	if intro_banner == null:
		return
	if diff_name != "":
		intro_banner.text = "%s\nDificultad: %s" % [level_title, diff_name]
	else:
		intro_banner.text = level_title
	intro_banner.visible = true
	intro_banner.modulate.a = 0.0
	intro_banner.pivot_offset = intro_banner.size * 0.5
	intro_banner.scale = Vector2(0.96, 0.96)
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(0.25)
	tw.set_parallel(true)
	tw.tween_property(intro_banner, "modulate:a", 1.0, 0.22)
	tw.tween_property(intro_banner, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_interval(1.4)
	tw.set_parallel(true)
	tw.tween_property(intro_banner, "modulate:a", 0.0, 0.35)
	tw.tween_property(intro_banner, "position:y", intro_banner.position.y - 24.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.set_parallel(false)
	tw.tween_callback(intro_banner.hide)

	if controls_label:
		controls_label.modulate.a = 1.0
		var tw2 := create_tween()
		tw2.tween_interval(6.0)
		tw2.tween_property(controls_label, "modulate:a", 0.0, 1.0)

## Cartel de nivel superado
func show_level_complete(level_name: String) -> void:
	_ensure_nodes()
	if intro_banner == null:
		return
	intro_banner.text = "Zona completada\n%s" % level_name
	intro_banner.visible = true
	intro_banner.modulate.a = 0.0
	intro_banner.pivot_offset = intro_banner.size * 0.5
	intro_banner.scale = Vector2(0.96, 0.96)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(intro_banner, "modulate:a", 1.0, 0.22)
	tw.tween_property(intro_banner, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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
		mobile_controls.deactivate()
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
		mobile_controls.deactivate()
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
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
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
	panel.scale = _modal_safe_scale
	panel.modulate.a = 1.0

	var tw := panel.create_tween().set_parallel(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(panel, "scale", _modal_safe_scale, 0.2).from(_modal_safe_scale * 0.96).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.16).from(0.0)
	_panel_tweens[panel] = tw

	# Contenido con entrada suave pero visible de inmediato
	var box := panel.get_child(0)
	var i := 0
	for child in box.get_children():
		if child is Control:
			child.modulate.a = 1.0
			tw.tween_property(child, "modulate:a", 1.0, 0.18).from(0.0).set_delay(0.04 + i * 0.03)
			i += 1

	if focus_button and is_inside_tree():
		focus_button.grab_focus()

func _hide_panel(panel: Control) -> void:
	_fade_overlay(false)
	_kill_panel_tween(panel)
	panel.pivot_offset = panel.size * 0.5
	var tw := panel.create_tween().set_parallel(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
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
	_overlay_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if show:
		if not overlay.visible:
			overlay.color.a = 0.0
			overlay.visible = true
		_overlay_tween.tween_property(overlay, "color:a", _overlay_alpha, 0.2)
	else:
		_overlay_tween.tween_property(overlay, "color:a", 0.0, 0.12)
		_overlay_tween.tween_callback(overlay.hide)

func _on_retry_pressed() -> void:
	set_paused(false)
	if is_inside_tree() and get_tree():
		get_tree().paused = false
	restart_game.emit()

func _on_menu_pressed() -> void:
	set_paused(false)
	if is_inside_tree() and get_tree():
		get_tree().paused = false
	go_to_menu.emit()
