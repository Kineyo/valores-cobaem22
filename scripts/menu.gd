extends Control

## Controlador del Menú de Inicio.
## Permite seleccionar modo, dificultad (Fácil, Normal, Difícil) y personaje en PC, táctil, Web y mando.
## Soporta teclado, ratón, pantallas táctiles y gamepad (D-Pad + stick analógico izquierdo con antirrebote).

const GAME_SCENE := "res://scenes/main.tscn"
const LOADING_SCENE := "res://scenes/loading_screen.tscn"
const BG_TILE_WIDTH := 800.0
const BG_TILE_HEIGHT := 450.0
const STICK_NAV_DEADZONE := 0.55
const STICK_NAV_RELEASE := 0.30
const STICK_NAV_REPEAT_MS := 240

const DIFFICULTY_INFO := [
	"5 vidas · Ritmo pausado · Ideal para conocer el plantel",
	"3 vidas · Ritmo estándar · Equilibrio recomendado",
	"2 vidas · Ritmo exigente · Mayor desafío escolar",
]
const DIFFICULTY_COLORS := [
	Color(0.55, 0.82, 0.65),
	Color(0.72, 0.80, 0.88),
	Color(0.90, 0.62, 0.62),
]

const MODE_INFO := [
	"Modo Arcade: Partida directa y acción continua superando los 6 escenarios.",
	"Modo Historia: Cinemáticas, diálogos escolares y trasfondo narrativo en CEMSaD 22.",
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
var _bg_tiles: Array[Sprite2D] = []
var _time: float = 0.0
var _bg_scroll: float = 0.0
var _bg_tile_width: float = BG_TILE_WIDTH
var _adapted_touch: bool = false
var _ui_hints_initialized: bool = false
var _last_input_was_gamepad: bool = false
var _last_input_was_touch: bool = false
var _stick_dir_x: int = 0
var _stick_dir_y: int = 0
var _stick_next_ms_x: int = 0
var _stick_next_ms_y: int = 0
var _last_vp_size: Vector2 = Vector2.ZERO
var _ambient_particles: CPUParticles2D = null

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

func _exit_tree() -> void:
	if Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.disconnect(_on_joy_connection_changed)
	var vp: Viewport = get_viewport()
	if vp and vp.size_changed.is_connected(_on_viewport_resized):
		vp.size_changed.disconnect(_on_viewport_resized)

func _ensure_nodes() -> void:
	if bg_scroller == null:
		bg_scroller = get_node_or_null("%BgScroller")
	if _ambient_particles == null:
		_ambient_particles = get_node_or_null("AmbientParticles") as CPUParticles2D
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
	if not _ui_hints_initialized:
		_ui_hints_initialized = true
		_adapt_ui_for_touch()
		_refresh_control_hints()

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

	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	var vp: Viewport = get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_resized):
		vp.size_changed.connect(_on_viewport_resized)

	_last_input_was_touch = MobileControls.is_touch_device()
	_last_input_was_gamepad = not _last_input_was_touch and not Input.get_connected_joypads().is_empty()

	_refresh_mode(false)
	_refresh_character(false)
	_refresh_difficulty(false)
	_adapt_ui_for_touch()
	_refresh_control_hints()
	_ensure_background_tiles()
	_update_safe_layout()
	if btn_play and btn_play.is_inside_tree():
		btn_play.grab_focus()
	if _game_settings and _game_settings.has_method("play_menu_music"):
		_game_settings.play_menu_music()
	_animate_intro()

func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if connected:
		_last_input_was_gamepad = true
		_last_input_was_touch = false
	elif Input.get_connected_joypads().is_empty():
		_last_input_was_gamepad = false
	_refresh_control_hints()

func _on_viewport_resized() -> void:
	_ensure_background_tiles()
	_update_safe_layout()

func _adapt_ui_for_touch() -> void:
	if not MobileControls.is_touch_device():
		return
	_adapted_touch = true
	_last_input_was_touch = true
	if btn_play:
		btn_play.text = "Iniciar partida"
	if btn_confirm_char:
		btn_confirm_char.text = "Comenzar aventura"
	if btn_back_to_menu:
		btn_back_to_menu.text = "Volver"
	if btn_quit:
		btn_quit.text = "Salir"
	var diff_title: Label = get_node_or_null("%DifficultyTitle") as Label
	if diff_title:
		diff_title.text = "DIFICULTAD"
	var char_title: Label = get_node_or_null("%CharSelectTitle") as Label
	if char_title:
		char_title.text = "SELECCIÓN DE PERSONAJE"
	_refresh_control_hints()

func _refresh_control_hints() -> void:
	var controls: Label = get_node_or_null("%Controls") as Label
	var char_controls: Label = get_node_or_null("%CharControls") as Label
	var use_touch: bool = (_last_input_was_touch or MobileControls.is_touch_device()) and not _last_input_was_gamepad
	var use_gamepad: bool = _last_input_was_gamepad or (not use_touch and not Input.get_connected_joypads().is_empty())
	if use_touch:
		if controls:
			controls.text = "Toca una opción para continuar · CEMSaD 22 ENTHAVI"
		if char_controls:
			char_controls.text = "Toca el personaje para elegirlo · CEMSaD 22 ENTHAVI"
	elif use_gamepad:
		if controls:
			controls.text = "Stick Izq / D-Pad: navegar · A: continuar · B: salir"
		if char_controls:
			char_controls.text = "Stick Izq / D-Pad: elegir · A: comenzar · B: volver"
	else:
		if controls:
			controls.text = "Flechas / WASD: navegar · Enter: continuar · Esc: salir"
		if char_controls:
			char_controls.text = "Flechas / A-D: elegir · Enter: comenzar · Esc: volver"

func _ensure_background_tiles() -> void:
	if bg_scroller == null:
		return
	var bg_a: Sprite2D = bg_scroller.get_node_or_null("BgA") as Sprite2D
	if bg_a == null and bg_scroller.get_child_count() > 0:
		var first_child: Node = bg_scroller.get_child(0)
		if first_child is Sprite2D:
			bg_a = first_child as Sprite2D
	if bg_a == null or bg_a.texture == null:
		_bg_tile_width = BG_TILE_WIDTH
		return

	var vp: Viewport = get_viewport() if is_inside_tree() else null
	var vp_size: Vector2 = get_viewport_rect().size if vp else Vector2(BG_TILE_WIDTH, BG_TILE_HEIGHT)
	if vp_size.x <= 1.0 or vp_size.y <= 1.0:
		vp_size = Vector2(BG_TILE_WIDTH, BG_TILE_HEIGHT)

	var tex_size: Vector2 = bg_a.texture.get_size()
	var base_w: float = maxf(1.0, tex_size.x)
	var base_h: float = maxf(1.0, tex_size.y)
	# Escala uniforme vertical para que pantallas 4:3 o altas no muestren franjas negras inferiores
	var tile_scale: float = maxf(1.0, vp_size.y / base_h)
	_bg_tile_width = base_w * tile_scale

	var needed: int = maxi(2, int(ceil((vp_size.x + _bg_tile_width) / _bg_tile_width)))
	_bg_tiles = [bg_a]
	for child in bg_scroller.get_children():
		if child is Sprite2D and child != bg_a:
			_bg_tiles.append(child as Sprite2D)

	while _bg_tiles.size() < needed:
		var clone := Sprite2D.new()
		clone.name = "BgTile_%d" % _bg_tiles.size()
		clone.texture = bg_a.texture
		clone.centered = bg_a.centered
		bg_scroller.add_child(clone)
		_bg_tiles.append(clone)

	for i in _bg_tiles.size():
		var tile: Sprite2D = _bg_tiles[i]
		tile.visible = i < needed
		tile.position = Vector2(float(i) * _bg_tile_width, 0.0)
		tile.scale = Vector2(tile_scale, tile_scale)

func _update_safe_layout() -> void:
	var vp: Viewport = get_viewport() if is_inside_tree() else null
	var vp_size: Vector2 = get_viewport_rect().size if vp else Vector2(BG_TILE_WIDTH, BG_TILE_HEIGHT)
	if vp_size.x <= 1.0 or vp_size.y <= 1.0:
		return
	_last_vp_size = vp_size

	var insets: Rect2 = MobileControls.get_safe_insets_for_viewport(vp, 8.0) if vp else Rect2(8.0, 8.0, 8.0, 8.0)
	if panel:
		var avail_w: float = maxf(240.0, vp_size.x - insets.position.x - insets.size.x)
		var avail_h: float = maxf(200.0, vp_size.y - insets.position.y - insets.size.y)
		var base_w: float = maxf(560.0, panel.size.x)
		var base_h: float = maxf(416.0, panel.size.y)
		var safe_scale: float = clampf(minf(avail_w / base_w, avail_h / base_h), 0.55, 1.0)
		panel.pivot_offset = panel.size * 0.5
		panel.scale = Vector2(safe_scale, safe_scale)
		var shift_x: float = (insets.position.x - insets.size.x) * 0.5
		var shift_y: float = (insets.position.y - insets.size.y) * 0.5
		panel.offset_left = -280.0 + shift_x
		panel.offset_right = 280.0 + shift_x
		panel.offset_top = -208.0 + shift_y
		panel.offset_bottom = 208.0 + shift_y

	if _ambient_particles:
		_ambient_particles.position = Vector2(vp_size.x * 0.5, vp_size.y - 10.0)
		_ambient_particles.emission_rect_extents = Vector2(vp_size.x * 0.5, 10.0)

func _process(delta: float) -> void:
	_ensure_nodes()
	if is_inside_tree() and get_viewport():
		var cur_sz: Vector2 = get_viewport_rect().size
		if cur_sz != _last_vp_size and cur_sz.x > 1.0:
			_on_viewport_resized()
	_time += delta

	# Desplazamiento panorámico suave del fondo con cobertura multi-aspecto
	if bg_scroller:
		_bg_scroll = fposmod(_bg_scroll + 12.0 * delta, maxf(1.0, _bg_tile_width))
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

func _set_input_mode(is_gamepad: bool, is_touch: bool) -> void:
	if _last_input_was_gamepad == is_gamepad and _last_input_was_touch == is_touch:
		return
	_last_input_was_gamepad = is_gamepad
	_last_input_was_touch = is_touch
	_refresh_control_hints()

func _update_input_mode(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if jb.pressed and not jb.is_echo():
			_set_input_mode(true, false)
	elif event is InputEventJoypadMotion:
		var jm := event as InputEventJoypadMotion
		if (jm.axis == JOY_AXIS_LEFT_X or jm.axis == JOY_AXIS_LEFT_Y) and absf(jm.axis_value) >= STICK_NAV_DEADZONE:
			_set_input_mode(true, false)
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and touch.device != InputEvent.DEVICE_ID_EMULATION:
			_set_input_mode(false, true)
	elif event is InputEventKey:
		var key_ev := event as InputEventKey
		if key_ev.pressed:
			_set_input_mode(false, false)

func _navigate_horizontal(step: int, is_in_char_view: bool) -> void:
	if is_in_char_view:
		_select_character(0 if step < 0 else 1)
	else:
		var current_d: int = _game_settings.difficulty if _game_settings else 1
		_select_difficulty(clampi(current_d + step, 0, 2))

func _navigate_vertical(step: int, is_in_char_view: bool) -> void:
	if is_in_char_view:
		if step < 0 and btn_confirm_char and btn_confirm_char.is_inside_tree():
			btn_confirm_char.grab_focus()
		elif step > 0 and btn_back_to_menu and btn_back_to_menu.is_inside_tree():
			btn_back_to_menu.grab_focus()
	else:
		var current_m: int = _game_settings.game_mode if _game_settings else 0
		_select_mode(1 if current_m == 0 else 0)

func _handle_directional_event(event: InputEvent, from_input_phase: bool) -> bool:
	var is_in_char_view: bool = char_select_view != null and char_select_view.visible

	if event is InputEventKey:
		var key_ev := event as InputEventKey
		if key_ev.pressed and not key_ev.echo:
			match key_ev.keycode:
				KEY_LEFT:
					_navigate_horizontal(-1, is_in_char_view)
					return true
				KEY_RIGHT:
					_navigate_horizontal(1, is_in_char_view)
					return true
				KEY_UP:
					_navigate_vertical(-1, is_in_char_view)
					return true
				KEY_DOWN:
					_navigate_vertical(1, is_in_char_view)
					return true

	elif event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if jb.pressed and not jb.is_echo():
			match jb.button_index:
				JOY_BUTTON_DPAD_LEFT:
					_navigate_horizontal(-1, is_in_char_view)
					return true
				JOY_BUTTON_DPAD_RIGHT:
					_navigate_horizontal(1, is_in_char_view)
					return true
				JOY_BUTTON_DPAD_UP:
					_navigate_vertical(-1, is_in_char_view)
					return true
				JOY_BUTTON_DPAD_DOWN:
					_navigate_vertical(1, is_in_char_view)
					return true

	elif event is InputEventJoypadMotion:
		var jm := event as InputEventJoypadMotion
		if jm.axis == JOY_AXIS_LEFT_X:
			var val_x: float = jm.axis_value
			if absf(val_x) < STICK_NAV_RELEASE:
				_stick_dir_x = 0
				_stick_next_ms_x = 0
				return false
			if absf(val_x) >= STICK_NAV_DEADZONE:
				var dir_x: int = 1 if val_x > 0.0 else -1
				var now_ms_x: int = Time.get_ticks_msec()
				if dir_x != _stick_dir_x or now_ms_x >= _stick_next_ms_x:
					_stick_dir_x = dir_x
					_stick_next_ms_x = now_ms_x + STICK_NAV_REPEAT_MS
					_navigate_horizontal(dir_x, is_in_char_view)
				return true
			return from_input_phase and absf(val_x) >= 0.45
		elif jm.axis == JOY_AXIS_LEFT_Y:
			var val_y: float = jm.axis_value
			if absf(val_y) < STICK_NAV_RELEASE:
				_stick_dir_y = 0
				_stick_next_ms_y = 0
				return false
			if absf(val_y) >= STICK_NAV_DEADZONE:
				var dir_y: int = 1 if val_y > 0.0 else -1
				var now_ms_y: int = Time.get_ticks_msec()
				if dir_y != _stick_dir_y or now_ms_y >= _stick_next_ms_y:
					_stick_dir_y = dir_y
					_stick_next_ms_y = now_ms_y + STICK_NAV_REPEAT_MS
					_navigate_vertical(dir_y, is_in_char_view)
				return true
			return from_input_phase and absf(val_y) >= 0.45

	return false

func _input(event: InputEvent) -> void:
	if _scene_transition and _scene_transition.is_busy:
		return
	_update_input_mode(event)
	# Intercepta flechas, D-Pad y stick izquierdo antes de que FocusManager entre BtnPlay/BtnQuit los capture
	if _handle_directional_event(event, true):
		var vp: Viewport = get_viewport()
		if vp:
			vp.set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _scene_transition and _scene_transition.is_busy:
		return
	_update_input_mode(event)

	var current_m: int = _game_settings.game_mode if _game_settings else 0
	var current_c: int = _game_settings.selected_character if _game_settings else 0
	var is_in_char_view: bool = char_select_view != null and char_select_view.visible
	var handled: bool = false

	if _handle_directional_event(event, false):
		handled = true
	# 1. Teclado (no direccional / alias WASD y atajos)
	elif event is InputEventKey:
		var key_ev := event as InputEventKey
		if key_ev.pressed and not key_ev.echo:
			handled = true
			if is_in_char_view:
				match key_ev.keycode:
					KEY_A, KEY_1:
						_select_character(0)
					KEY_D, KEY_2:
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
				match key_ev.keycode:
					KEY_A:
						_navigate_horizontal(-1, false)
					KEY_D:
						_navigate_horizontal(1, false)
					KEY_W, KEY_S:
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
					KEY_F11:
						if not OS.has_feature("web"):
							var mode: int = DisplayServer.window_get_mode()
							var is_fs: bool = mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
							DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
						else:
							handled = false
					_:
						handled = false

	# 2. Gamepad / Mando (botones de acción)
	elif event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if jb.pressed and not jb.is_echo():
			handled = true
			if is_in_char_view:
				match jb.button_index:
					JOY_BUTTON_X, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
						_select_character(1 if current_c == 0 else 0)
					JOY_BUTTON_A, JOY_BUTTON_START:
						_start_game()
					JOY_BUTTON_B, JOY_BUTTON_BACK:
						_close_character_select()
					_:
						handled = false
			else:
				match jb.button_index:
					JOY_BUTTON_Y:
						_select_mode(1 if current_m == 0 else 0)
					JOY_BUTTON_X, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
						_select_character(1 if current_c == 0 else 0)
					JOY_BUTTON_A, JOY_BUTTON_START:
						_open_character_select()
					JOY_BUTTON_B, JOY_BUTTON_BACK:
						_quit()
					_:
						handled = false

	if handled:
		var vp: Viewport = get_viewport()
		if vp:
			vp.set_input_as_handled()

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

func _refresh_mode(_animate: bool = false) -> void:
	var m: int = _game_settings.game_mode if _game_settings else 0
	var titles := ["Modo Arcade", "Modo Historia"]
	for i in _mode_buttons.size():
		var btn := _mode_buttons[i]
		if btn == null:
			continue
		var selected := i == m
		btn.button_pressed = selected
		btn.text = titles[i]
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if selected else Color(0.75, 0.78, 0.82, 0.85)

	if mode_info:
		mode_info.text = MODE_INFO[m]
		mode_info.modulate = Color(0.76, 0.79, 0.84)

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

func _refresh_character(_animate: bool = false) -> void:
	var c: int = _game_settings.selected_character if _game_settings else 0
	for i in _char_buttons.size():
		var btn := _char_buttons[i]
		if btn == null:
			continue
		var selected := (i == c)
		btn.button_pressed = selected
		btn.modulate = Color.WHITE

	if lbl_status_p:
		lbl_status_p.text = "Seleccionado" if c == 0 else "Disponible"
		lbl_status_p.modulate = Color(0.88, 0.78, 0.50) if c == 0 else Color(0.60, 0.64, 0.70)
	if lbl_status_f:
		lbl_status_f.text = "Seleccionado" if c == 1 else "Disponible"
		lbl_status_f.modulate = Color(0.88, 0.78, 0.50) if c == 1 else Color(0.60, 0.64, 0.70)

	if char_info_label:
		if c == 0:
			char_info_label.text = "Uniforme escolar masculino · CEMSaD 22"
		else:
			char_info_label.text = "Uniforme escolar femenino · CEMSaD 22"
		char_info_label.modulate = Color(0.84, 0.78, 0.62)

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
		if _game_settings.has_method("set_difficulty"):
			_game_settings.set_difficulty(index)
		else:
			_game_settings.difficulty = index
	_refresh_difficulty(true)

func _refresh_difficulty(_animate: bool = false) -> void:
	var d: int = _game_settings.difficulty if _game_settings else 1
	var names := ["Fácil", "Normal", "Difícil"]
	for i in _diff_buttons.size():
		var btn := _diff_buttons[i]
		var selected := i == d
		btn.button_pressed = selected
		btn.text = names[i]
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if selected else Color(0.75, 0.78, 0.82, 0.85)

	info_label.text = DIFFICULTY_INFO[d]
	info_label.modulate = DIFFICULTY_COLORS[d]

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
	if _game_settings and _game_settings.has_method("lock_initial_difficulty"):
		_game_settings.lock_initial_difficulty()
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
