extends Control

## Controlador del Menú de Inicio.
## Permite seleccionar la dificultad (Fácil, Normal, Difícil) e iniciar la partida.
## Atajos de teclado: Flechas / A-D / 1-2-3 cambian dificultad, ENTER inicia partida, ESC sale.

const GAME_SCENE := "res://scenes/main.tscn"
const LOADING_SCENE := "res://scenes/loading_screen.tscn"

const DIFFICULTY_INFO := [
	"♥ 5 corazones · enemigos lentos · disparo grande y rápido",
	"♥ 3 corazones · enemigos normales · disparo mediano",
	"♥ 2 corazones · enemigos veloces · disparo pequeño y lento",
]
const DIFFICULTY_COLORS := [
	Color(0.35, 0.92, 0.48),
	Color(0.45, 0.78, 1.0),
	Color(1.0, 0.42, 0.42),
]

const MODE_INFO := [
	"Modo Arcade: Partida directa y acción continua superando los 6 escenarios.",
	"📖 Modo Historia: Cinemáticas, diálogos escolares y trasfondo narrativo en CEMSaD 22.",
]

@onready var bg_scroller: Node2D = %BgScroller
@onready var panel: PanelContainer = %Panel
@onready var vbox: VBoxContainer = %VBox
@onready var btn_mode_arcade: Button = %BtnModeArcade
@onready var btn_mode_story: Button = %BtnModeStory
@onready var mode_info: Label = %ModeInfo
@onready var btn_easy: Button = %BtnEasy
@onready var btn_normal: Button = %BtnNormal
@onready var btn_hard: Button = %BtnHard
@onready var info_label: Label = %DifficultyInfo
@onready var btn_play: Button = %BtnPlay
@onready var btn_quit: Button = %BtnQuit
@onready var game_icon: TextureRect = %GameIcon
@onready var sfx_select: AudioStreamPlayer = $SFXSelect

var _diff_buttons: Array[Button] = []
var _mode_buttons: Array[Button] = []
var _time: float = 0.0
var _bg_scroll: float = 0.0
var _adapted_touch: bool = false

var _game_settings: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/GameSettings")

var _scene_transition: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/SceneTransition")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_quit()

func _ensure_nodes() -> void:
	if bg_scroller == null:
		bg_scroller = get_node_or_null("%BgScroller")
	if panel == null:
		panel = get_node_or_null("%Panel")
	if vbox == null:
		vbox = get_node_or_null("%VBox")
	if btn_mode_arcade == null:
		btn_mode_arcade = get_node_or_null("%BtnModeArcade")
	if btn_mode_story == null:
		btn_mode_story = get_node_or_null("%BtnModeStory")
	if mode_info == null:
		mode_info = get_node_or_null("%ModeInfo")
	if btn_easy == null:
		btn_easy = get_node_or_null("%BtnEasy")
	if btn_normal == null:
		btn_normal = get_node_or_null("%BtnNormal")
	if btn_hard == null:
		btn_hard = get_node_or_null("%BtnHard")
	if info_label == null:
		info_label = get_node_or_null("%DifficultyInfo")
	if btn_play == null:
		btn_play = get_node_or_null("%BtnPlay")
	if btn_quit == null:
		btn_quit = get_node_or_null("%BtnQuit")
	if game_icon == null:
		game_icon = get_node_or_null("%GameIcon")
	if sfx_select == null:
		sfx_select = get_node_or_null("SFXSelect")
	if not _adapted_touch:
		_adapt_ui_for_touch()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_ensure_nodes()

	# Configuración de botones de modo (Arcade vs Historia)
	_mode_buttons = [btn_mode_arcade, btn_mode_story]
	for i in _mode_buttons.size():
		if _mode_buttons[i]:
			_mode_buttons[i].pressed.connect(_select_mode.bind(i))
			UiJuice.attach_button(_mode_buttons[i], sfx_select)

	_diff_buttons = [btn_easy, btn_normal, btn_hard]
	for i in _diff_buttons.size():
		if _diff_buttons[i]:
			_diff_buttons[i].pressed.connect(_select_difficulty.bind(i))
			UiJuice.attach_button(_diff_buttons[i], sfx_select)

	btn_play.pressed.connect(_start_game)
	btn_quit.pressed.connect(_quit)
	UiJuice.attach_button(btn_play, sfx_select)
	UiJuice.attach_button(btn_quit, sfx_select)

	# En navegadores web se oculta el botón salir ya que la pestaña controla el cierre
	btn_quit.visible = not OS.has_feature("web")

	_refresh_mode(false)
	_refresh_difficulty(false)
	_adapt_ui_for_touch()
	btn_play.grab_focus()
	if _game_settings and _game_settings.has_method("play_menu_music"):
		_game_settings.play_menu_music()
	_animate_intro()

func _adapt_ui_for_touch() -> void:
	if not MobileControls.is_touch_device():
		return
	_adapted_touch = true
	if btn_play:
		btn_play.text = "▶ INICIAR PARTIDA"
	if btn_quit:
		btn_quit.text = "Salir"
	var diff_title: Label = get_node_or_null("%DifficultyTitle")
	if diff_title:
		diff_title.text = "Selecciona la Dificultad"
	var controls: Label = get_node_or_null("%Controls")
	if controls:
		controls.text = "Toca la pantalla para interactuar · CEMSaD 22 ENTHAVI"

func _process(delta: float) -> void:
	_ensure_nodes()
	_time += delta
	# Animación de flotación y balanceo del icono de trofeo
	if game_icon:
		game_icon.pivot_offset = game_icon.size * 0.5
		game_icon.position.y = roundf(sin(_time * 2.2) * 4.0)
		game_icon.rotation = sin(_time * 1.4) * 0.05

	# Desplazamiento panorámico continuo del fondo
	if bg_scroller:
		_bg_scroll = fposmod(_bg_scroll + 22.0 * delta, 800.0)
		bg_scroller.position.x = -roundf(_bg_scroll)

func _animate_intro() -> void:
	await get_tree().process_frame
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.85, 0.85)
	panel.modulate.a = 0.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)

	var idx := 0
	for child in vbox.get_children():
		if child is Control and child.visible:
			child.modulate.a = 0.0
			tw.tween_property(child, "modulate:a", 1.0, 0.22).set_delay(0.08 + idx * 0.04)
			idx += 1

func _unhandled_input(event: InputEvent) -> void:
	if _scene_transition and _scene_transition.is_busy:
		return

	var current_d: int = _game_settings.difficulty if _game_settings else 1
	var current_m: int = _game_settings.game_mode if _game_settings else 0
	var handled := false

	# 1. Teclado
	if event is InputEventKey and event.pressed and not event.echo:
		handled = true
		match event.keycode:
			KEY_LEFT, KEY_A:
				_select_difficulty(maxi(0, current_d - 1))
			KEY_RIGHT, KEY_D:
				_select_difficulty(mini(2, current_d + 1))
			KEY_UP, KEY_W, KEY_DOWN, KEY_S, KEY_M, KEY_H:
				_select_mode(1 if current_m == 0 else 0)
			KEY_1:
				_select_difficulty(0)
			KEY_2:
				_select_difficulty(1)
			KEY_3:
				_select_difficulty(2)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_start_game()
			KEY_ESCAPE:
				_quit()
			_:
				handled = false

	# 2. Gamepad / Mando
	elif event is InputEventJoypadButton and event.pressed:
		handled = true
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				_select_difficulty(maxi(0, current_d - 1))
			JOY_BUTTON_DPAD_RIGHT:
				_select_difficulty(mini(2, current_d + 1))
			JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
				_select_mode(1 if current_m == 0 else 0)
			JOY_BUTTON_A, JOY_BUTTON_START:
				_start_game()
			JOY_BUTTON_B, JOY_BUTTON_BACK:
				_quit()
			_:
				handled = false

	if handled:
		get_viewport().set_input_as_handled()

func _select_mode(index: int) -> void:
	var current_m: int = _game_settings.game_mode if _game_settings else 0
	if index == current_m:
		if _mode_buttons.size() > index and _mode_buttons[index]:
			_mode_buttons[index].button_pressed = true
		return
	if sfx_select:
		sfx_select.pitch_scale = 1.05 + index * 0.15
		sfx_select.play()
	if _game_settings:
		_game_settings.game_mode = index
	_refresh_mode(true)

func _refresh_mode(animate: bool = false) -> void:
	var m: int = _game_settings.game_mode if _game_settings else 0
	var titles := ["Modo Arcade", "📖 Modo Historia"]
	for i in _mode_buttons.size():
		var btn := _mode_buttons[i]
		if btn == null:
			continue
		var selected := i == m
		btn.button_pressed = selected
		btn.text = "► %s ◄" % titles[i] if selected else titles[i]
		btn.modulate = Color(1.0, 0.90, 0.40) if selected else Color(0.78, 0.75, 0.70)
		if animate and selected:
			btn.pivot_offset = btn.size * 0.5
			btn.scale = Vector2(1.10, 1.10)
			btn.create_tween().tween_property(btn, "scale", Vector2.ONE, 0.2) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if mode_info:
		mode_info.text = MODE_INFO[m]
		mode_info.modulate = Color(1.0, 0.92, 0.55) if m == 1 else Color(0.85, 0.82, 0.75)
		if animate:
			mode_info.pivot_offset = mode_info.size * 0.5
			mode_info.scale = Vector2(1.05, 1.05)
			mode_info.create_tween().tween_property(mode_info, "scale", Vector2.ONE, 0.18) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _select_difficulty(index: int) -> void:
	var current_d: int = _game_settings.difficulty if _game_settings else 1
	if index == current_d:
		_diff_buttons[index].button_pressed = true
		return
	if sfx_select:
		sfx_select.pitch_scale = 0.95 + index * 0.1
		sfx_select.play()
	if _game_settings:
		_game_settings.difficulty = index
	_refresh_difficulty(true)

func _refresh_difficulty(animate: bool = false) -> void:
	var d: int = _game_settings.difficulty if _game_settings else 1
	var names := ["Fácil", "Normal", "Difícil"]
	for i in _diff_buttons.size():
		var btn := _diff_buttons[i]
		var selected := i == d
		btn.button_pressed = selected
		btn.text = "► %s ◄" % names[i] if selected else names[i]
		btn.modulate = DIFFICULTY_COLORS[i] if selected else Color(0.85, 0.82, 0.75)
		if animate and selected:
			btn.pivot_offset = btn.size * 0.5
			btn.scale = Vector2(1.14, 1.14)
			btn.create_tween().tween_property(btn, "scale", Vector2.ONE, 0.22) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	info_label.text = DIFFICULTY_INFO[d]
	info_label.modulate = DIFFICULTY_COLORS[d]
	if animate:
		info_label.pivot_offset = info_label.size * 0.5
		info_label.scale = Vector2(1.06, 1.06)
		info_label.create_tween().tween_property(info_label, "scale", Vector2.ONE, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_game() -> void:
	if _scene_transition and _scene_transition.is_busy:
		return
	if sfx_select:
		sfx_select.pitch_scale = 1.15
		sfx_select.play()
	if _scene_transition and _scene_transition.has_method("change_scene"):
		_scene_transition.change_scene(LOADING_SCENE)
	else:
		get_tree().change_scene_to_file(LOADING_SCENE)

func _quit() -> void:
	if OS.has_feature("web"):
		return
	if _scene_transition and _scene_transition.is_busy:
		return
	get_tree().quit()
