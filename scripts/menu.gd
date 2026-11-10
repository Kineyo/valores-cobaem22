extends Control

## Controlador del Menú de Inicio.
## Permite seleccionar la dificultad (Fácil, Normal, Difícil) e iniciar la partida.
## Atajos de teclado: Flechas / A-D / 1-2-3 cambian dificultad, ENTER inicia partida, ESC sale.

const GAME_SCENE := "res://scenes/main.tscn"

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

@onready var bg_scroller: Node2D = %BgScroller
@onready var panel: PanelContainer = %Panel
@onready var vbox: VBoxContainer = %VBox
@onready var btn_easy: Button = %BtnEasy
@onready var btn_normal: Button = %BtnNormal
@onready var btn_hard: Button = %BtnHard
@onready var info_label: Label = %DifficultyInfo
@onready var btn_play: Button = %BtnPlay
@onready var btn_quit: Button = %BtnQuit
@onready var game_icon: TextureRect = %GameIcon
@onready var sfx_select: AudioStreamPlayer = $SFXSelect

var _diff_buttons: Array[Button] = []
var _time: float = 0.0
var _bg_scroll: float = 0.0

func _ready() -> void:
	_diff_buttons = [btn_easy, btn_normal, btn_hard]
	for i in _diff_buttons.size():
		_diff_buttons[i].pressed.connect(_select_difficulty.bind(i))
		UiJuice.attach_button(_diff_buttons[i], sfx_select)

	btn_play.pressed.connect(_start_game)
	btn_quit.pressed.connect(_quit)
	UiJuice.attach_button(btn_play, sfx_select)
	UiJuice.attach_button(btn_quit, sfx_select)

	# En navegadores web se oculta el botón salir ya que la pestaña controla el cierre
	btn_quit.visible = not OS.has_feature("web")

	_refresh_difficulty(false)
	btn_play.grab_focus()
	GameSettings.play_menu_music()
	_animate_intro()

func _process(delta: float) -> void:
	_time += delta
	# Animación de flotación y balanceo del icono de trofeo
	game_icon.pivot_offset = game_icon.size * 0.5
	game_icon.position.y = roundf(sin(_time * 2.2) * 4.0)
	game_icon.rotation = sin(_time * 1.4) * 0.05

	# Desplazamiento panorámico continuo del fondo
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

func _input(event: InputEvent) -> void:
	if SceneTransition.is_busy:
		return
	# Se usa _input (no _unhandled_input) para que las flechas no se las "coma"
	# la navegación de foco de los botones.
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var handled := true
	match event.keycode:
		KEY_LEFT, KEY_A:
			_select_difficulty(maxi(0, GameSettings.difficulty - 1))
		KEY_RIGHT, KEY_D:
			_select_difficulty(mini(2, GameSettings.difficulty + 1))
		KEY_1:
			_select_difficulty(0)
		KEY_2:
			_select_difficulty(1)
		KEY_3:
			_select_difficulty(2)
		KEY_ENTER, KEY_KP_ENTER:
			_start_game()
		KEY_ESCAPE:
			_quit()
		_:
			handled = false
	if handled:
		get_viewport().set_input_as_handled()

func _select_difficulty(index: int) -> void:
	if index == GameSettings.difficulty:
		_diff_buttons[index].button_pressed = true
		return
	if sfx_select:
		sfx_select.pitch_scale = 0.95 + index * 0.1
		sfx_select.play()
	GameSettings.difficulty = index
	_refresh_difficulty(true)

func _refresh_difficulty(animate: bool = false) -> void:
	var d: int = GameSettings.difficulty
	for i in _diff_buttons.size():
		var btn := _diff_buttons[i]
		var selected := i == d
		btn.button_pressed = selected
		btn.modulate = DIFFICULTY_COLORS[i] if selected else Color(0.7, 0.72, 0.8)
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
	if SceneTransition.is_busy:
		return
	if sfx_select:
		sfx_select.pitch_scale = 1.15
		sfx_select.play()
	SceneTransition.change_scene(GAME_SCENE)

func _quit() -> void:
	if OS.has_feature("web") or SceneTransition.is_busy:
		return
	get_tree().quit()
