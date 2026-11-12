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
@onready var main_view: VBoxContainer = %MainView
@onready var char_select_view: VBoxContainer = %CharSelectView
@onready var btn_mode_arcade: Button = %BtnModeArcade
@onready var btn_mode_story: Button = %BtnModeStory
@onready var mode_info: Label = %ModeInfo
@onready var btn_char_pantalon: Button = %BtnCharPantalon
@onready var btn_char_falda: Button = %BtnCharFalda
@onready var char_icon_pantalon: TextureRect = %CharIconPantalon
@onready var char_icon_falda: TextureRect = %CharIconFalda
@onready var lbl_status_p: Label = %LblStatusP
@onready var lbl_status_f: Label = %LblStatusF
@onready var char_info_label: Label = %CharacterInfo
@onready var btn_confirm_char: Button = %BtnConfirmChar
@onready var btn_back_to_menu: Button = %BtnBackToMenu
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
var _char_buttons: Array[Button] = []
var _time: float = 0.0
var _bg_scroll: float = 0.0
var _adapted_touch: bool = false

var _game_settings: Node:
	get:
		if get_parent() and get_parent().has_node("GameSettings"):
			return get_parent().get_node("GameSettings")
		if is_inside_tree() and get_tree() and get_tree().root:
			var gs = get_tree().root.get_node_or_null("GameSettings")
			if gs:
				return gs
		var ml = Engine.get_main_loop()
		if ml is SceneTree:
			var st: SceneTree = ml as SceneTree
			if st.root and st.root.has_node("GameSettings"):
				return st.root.get_node("GameSettings")
		if is_inside_tree():
			return get_node_or_null("/root/GameSettings")
		return null

var _scene_transition: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/SceneTransition")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if char_select_view and char_select_view.visible:
			_close_character_select()
		else:
			_quit()

func _ensure_nodes() -> void:
	if bg_scroller == null:
		bg_scroller = get_node_or_null("%BgScroller")
	if panel == null:
		panel = get_node_or_null("%Panel")
	if vbox == null:
		vbox = get_node_or_null("%VBox")
	if main_view == null:
		main_view = get_node_or_null("%MainView")
	if char_select_view == null:
		char_select_view = get_node_or_null("%CharSelectView")
	if btn_mode_arcade == null:
		btn_mode_arcade = get_node_or_null("%BtnModeArcade")
	if btn_mode_story == null:
		btn_mode_story = get_node_or_null("%BtnModeStory")
	if mode_info == null:
		mode_info = get_node_or_null("%ModeInfo")
	if btn_char_pantalon == null:
		btn_char_pantalon = get_node_or_null("%BtnCharPantalon")
	if btn_char_falda == null:
		btn_char_falda = get_node_or_null("%BtnCharFalda")
	if char_icon_pantalon == null:
		char_icon_pantalon = get_node_or_null("%CharIconPantalon")
	if char_icon_falda == null:
		char_icon_falda = get_node_or_null("%CharIconFalda")
	if lbl_status_p == null:
		lbl_status_p = get_node_or_null("%LblStatusP")
	if lbl_status_f == null:
		lbl_status_f = get_node_or_null("%LblStatusF")
	if char_info_label == null:
		char_info_label = get_node_or_null("%CharacterInfo")
	if btn_confirm_char == null:
		btn_confirm_char = get_node_or_null("%BtnConfirmChar")
	if btn_back_to_menu == null:
		btn_back_to_menu = get_node_or_null("%BtnBackToMenu")
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
	if is_inside_tree() and get_tree():
		get_tree().paused = false
	_ensure_nodes()

	# Configuración de botones de modo (Arcade vs Historia)
	_mode_buttons = [btn_mode_arcade, btn_mode_story]
	for i in _mode_buttons.size():
		var b := _mode_buttons[i]
		if b and not b.pressed.is_connected(_select_mode):
			b.pressed.connect(_select_mode.bind(i))
			UiJuice.attach_button(b, sfx_select)

	# Configuración de botones de personaje (Masculino vs Femenino)
	_char_buttons = [btn_char_pantalon, btn_char_falda]
	for i in _char_buttons.size():
		var b := _char_buttons[i]
		if b and not b.pressed.is_connected(_select_character):
			b.pressed.connect(_select_character.bind(i))
			UiJuice.attach_button(b, sfx_select)

	# Cargar portada frontal con fondo blanco con método resiliente
	if char_icon_pantalon:
		var tex_p = _load_texture_resilient("res://assets/characters/Masculino/portada.png")
		if tex_p:
			char_icon_pantalon.texture = tex_p
	if char_icon_falda:
		var tex_f = _load_texture_resilient("res://assets/characters/Femenino/portada.png")
		if tex_f:
			char_icon_falda.texture = tex_f

	# Configuración de botones de dificultad
	_diff_buttons = [btn_easy, btn_normal, btn_hard]
	for i in _diff_buttons.size():
		var b := _diff_buttons[i]
		if b and not b.pressed.is_connected(_select_difficulty):
			b.pressed.connect(_select_difficulty.bind(i))
			UiJuice.attach_button(b, sfx_select)

	if btn_play and not btn_play.pressed.is_connected(_open_character_select):
		btn_play.pressed.connect(_open_character_select)
		UiJuice.attach_button(btn_play, sfx_select)
	if btn_quit and not btn_quit.pressed.is_connected(_quit):
		btn_quit.pressed.connect(_quit)
		UiJuice.attach_button(btn_quit, sfx_select)
	if btn_confirm_char and not btn_confirm_char.pressed.is_connected(_start_game):
		btn_confirm_char.pressed.connect(_start_game)
		UiJuice.attach_button(btn_confirm_char, sfx_select)
	if btn_back_to_menu and not btn_back_to_menu.pressed.is_connected(_close_character_select):
		btn_back_to_menu.pressed.connect(_close_character_select)
		UiJuice.attach_button(btn_back_to_menu, sfx_select)

	if main_view:
		main_view.visible = true
	if char_select_view:
		char_select_view.visible = false

	# En navegadores web se oculta el botón salir ya que la pestaña controla el cierre
	btn_quit.visible = not OS.has_feature("web")

	_refresh_mode(false)
	_refresh_character(false)
	_refresh_difficulty(false)
	_adapt_ui_for_touch()
	if btn_play and btn_play.is_inside_tree():
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
	if btn_confirm_char:
		btn_confirm_char.text = "▶ COMENZAR AVENTURA"
	if btn_back_to_menu:
		btn_back_to_menu.text = "← Volver"
	if btn_quit:
		btn_quit.text = "Salir"
	var diff_title: Label = get_node_or_null("%DifficultyTitle")
	if diff_title:
		diff_title.text = "Selecciona la Dificultad"
	var char_title: Label = get_node_or_null("%CharacterTitle")
	if char_title:
		char_title.text = "Selecciona tu Personaje"
	var controls: Label = get_node_or_null("%Controls")
	if controls:
		controls.text = "Toca la pantalla para interactuar · CEMSaD 22 ENTHAVI"
	var char_controls: Label = get_node_or_null("%CharControls")
	if char_controls:
		char_controls.text = "Toca el personaje para elegirlo · CEMSaD 22 ENTHAVI"

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
	if not is_inside_tree() or get_tree() == null:
		return
	await get_tree().process_frame
	panel.modulate.a = 0.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.28)

	var idx := 0
	for child in vbox.get_children():
		if child is Control and child.visible:
			child.modulate.a = 0.0
			tw.tween_property(child, "modulate:a", 1.0, 0.22).set_delay(0.04 + idx * 0.03)
			idx += 1

func _unhandled_input(event: InputEvent) -> void:
	if _scene_transition and _scene_transition.is_busy:
		return

	var current_d: int = _game_settings.difficulty if _game_settings else 1
	var current_m: int = _game_settings.game_mode if _game_settings else 0
	var current_c: int = _game_settings.selected_character if _game_settings else 0
	var is_in_char_view: bool = char_select_view != null and char_select_view.visible
	var handled := false

	# 1. Teclado
	if event is InputEventKey and event.pressed and not event.echo:
		handled = true
		if is_in_char_view:
			match event.keycode:
				KEY_LEFT, KEY_A, KEY_1:
					_select_character(0)
				KEY_RIGHT, KEY_D, KEY_2:
					_select_character(1)
				KEY_Q, KEY_E, KEY_C, KEY_TAB:
					_select_character(1 if current_c == 0 else 0)
				KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
					_start_game()
				KEY_ESCAPE:
					_close_character_select()
				_:
					handled = false
		else:
			match event.keycode:
				KEY_LEFT, KEY_A:
					_select_difficulty(maxi(0, current_d - 1))
				KEY_RIGHT, KEY_D:
					_select_difficulty(mini(2, current_d + 1))
				KEY_UP, KEY_W, KEY_DOWN, KEY_S:
					_select_mode(1 if current_m == 0 else 0)
				KEY_C, KEY_P, KEY_TAB:
					_select_character(1 if current_c == 0 else 0)
				KEY_1:
					_select_difficulty(0)
				KEY_2:
					_select_difficulty(1)
				KEY_3:
					_select_difficulty(2)
				KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
					_open_character_select()
				KEY_ESCAPE:
					_quit()
				_:
					handled = false

	# 2. Gamepad / Mando
	elif event is InputEventJoypadButton and event.pressed:
		handled = true
		if is_in_char_view:
			match event.button_index:
				JOY_BUTTON_DPAD_LEFT:
					_select_character(0)
				JOY_BUTTON_DPAD_RIGHT:
					_select_character(1)
				JOY_BUTTON_X, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
					_select_character(1 if current_c == 0 else 0)
				JOY_BUTTON_A, JOY_BUTTON_START:
					_start_game()
				JOY_BUTTON_B, JOY_BUTTON_BACK:
					_close_character_select()
				_:
					handled = false
		else:
			match event.button_index:
				JOY_BUTTON_DPAD_LEFT:
					_select_difficulty(maxi(0, current_d - 1))
				JOY_BUTTON_DPAD_RIGHT:
					_select_difficulty(mini(2, current_d + 1))
				JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_Y:
					_select_mode(1 if current_m == 0 else 0)
				JOY_BUTTON_A, JOY_BUTTON_START:
					_open_character_select()
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
	if sfx_select and sfx_select.is_inside_tree():
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

func _select_character(index: int) -> void:
	var current_c: int = _game_settings.selected_character if _game_settings else 0
	if index == current_c:
		if _char_buttons.size() > index and _char_buttons[index]:
			_char_buttons[index].button_pressed = true
		return
	if sfx_select and sfx_select.is_inside_tree():
		sfx_select.pitch_scale = 1.02 + index * 0.12
		sfx_select.play()
	if _game_settings:
		_game_settings.selected_character = index
	_refresh_character(true)

func _refresh_character(animate: bool = false) -> void:
	var c: int = _game_settings.selected_character if _game_settings else 0
	for i in _char_buttons.size():
		var btn := _char_buttons[i]
		if btn == null:
			continue
		var selected := (i == c)
		btn.button_pressed = selected
		btn.modulate = Color(1.0, 0.95, 0.45) if selected else Color(0.80, 0.78, 0.72)
		if animate and selected and btn.is_inside_tree() and btn.get_tree():
			btn.pivot_offset = btn.size * 0.5
			btn.scale = Vector2(1.08, 1.08)
			btn.create_tween().tween_property(btn, "scale", Vector2.ONE, 0.2) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if lbl_status_p:
		lbl_status_p.text = "► ELEGIDO ◄" if c == 0 else "Seleccionar"
		lbl_status_p.modulate = Color(1.0, 0.90, 0.40) if c == 0 else Color(0.70, 0.68, 0.65)
	if lbl_status_f:
		lbl_status_f.text = "► ELEGIDA ◄" if c == 1 else "Seleccionar"
		lbl_status_f.modulate = Color(1.0, 0.90, 0.40) if c == 1 else Color(0.70, 0.68, 0.65)

	if char_info_label:
		if c == 0:
			char_info_label.text = "Personaje: Masculino · Carpeta: assets/characters/Masculino"
		else:
			char_info_label.text = "Personaje: Femenino · Carpeta: assets/characters/Femenino"
		char_info_label.modulate = Color(1.0, 0.92, 0.55)
		if animate and char_info_label.is_inside_tree() and char_info_label.get_tree():
			char_info_label.pivot_offset = char_info_label.size * 0.5
			char_info_label.scale = Vector2(1.05, 1.05)
			char_info_label.create_tween().tween_property(char_info_label, "scale", Vector2.ONE, 0.18) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _load_texture_resilient(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	var global_path := ProjectSettings.globalize_path(path)
	var check_path := global_path if not global_path.is_empty() else path
	if FileAccess.file_exists(check_path) or FileAccess.file_exists(path):
		var img := Image.new()
		var p := path if FileAccess.file_exists(path) else check_path
		if img.load(p) == OK:
			return ImageTexture.create_from_image(img)
	return null

func _select_difficulty(index: int) -> void:
	var current_d: int = _game_settings.difficulty if _game_settings else 1
	if index == current_d:
		_diff_buttons[index].button_pressed = true
		return
	if sfx_select and sfx_select.is_inside_tree():
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

func _open_character_select() -> void:
	if _scene_transition and _scene_transition.is_busy:
		return
	if sfx_select and sfx_select.is_inside_tree():
		sfx_select.pitch_scale = 1.08
		sfx_select.play()
	if main_view:
		main_view.visible = false
	if char_select_view:
		char_select_view.visible = true
	_refresh_character(false)
	if btn_confirm_char and btn_confirm_char.is_inside_tree():
		btn_confirm_char.grab_focus()

func _close_character_select() -> void:
	if _scene_transition and _scene_transition.is_busy:
		return
	if sfx_select and sfx_select.is_inside_tree():
		sfx_select.pitch_scale = 0.95
		sfx_select.play()
	if char_select_view:
		char_select_view.visible = false
	if main_view:
		main_view.visible = true
	if btn_play and btn_play.is_inside_tree():
		btn_play.grab_focus()

func _start_game() -> void:
	if _scene_transition and _scene_transition.is_busy:
		return
	if sfx_select and sfx_select.is_inside_tree():
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
