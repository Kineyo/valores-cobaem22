extends Node2D

## Orquestador del ciclo de juego.
## Maneja la carga secuencial de niveles, cálculo del progreso hacia la meta,
## victorias, derrotas y transiciones con SceneTransition.

const MENU_SCENE := "res://scenes/menu.tscn"
const LEVEL_SCENE := preload("res://scenes/level.tscn")
const CUTSCENE_SCENE := preload("res://scenes/story_cutscene.tscn")
const StoryDataClass := preload("res://scripts/story_data.gd")

@onready var level_container: Node2D = $LevelContainer
@onready var hud: HUD = $HUD

var current_level_index: int = 0
var levels: Array[Dictionary] = []
var active_level: Level = null

var game_finished: bool = false
var enemies_defeated: int = 0
var elapsed_time: float = 0.0

var _cached_goal_pos: Vector2 = Vector2.ZERO
var _cached_total_dist: float = 1.0
var _max_reached_dist: float = 0.0

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

func _ready() -> void:
	setup_inputs()
	if _game_settings and _game_settings.has_method("play_game_music"):
		_game_settings.play_game_music()

	levels = LevelManager.get_all_levels()

	hud.restart_game.connect(_on_restart_game)
	hud.go_to_menu.connect(_on_go_to_menu)
	var diff_str: String = _game_settings.difficulty_name() if _game_settings and _game_settings.has_method("difficulty_name") else "Normal"
	hud.set_difficulty_text(diff_str)

	if _is_story_mode():
		_start_story_mode()
	else:
		load_level(0)

func _is_story_mode() -> bool:
	return _game_settings != null and _game_settings.get("game_mode") == 1

func _start_story_mode() -> void:
	# Prólogo del Modo Historia: "La Bruma sobre el Valle de Temoaya"
	_show_story_cutscene(StoryDataClass.get_prologue(), func():
		# Acto I: "Cruzar el Umbral" (Acceso, Caseta C.V., Mateo y Apatyx)
		_show_story_act(1, func():
			load_level(0)
		)
	)

func _show_story_cutscene(cutscene_data: Dictionary, on_complete: Callable) -> void:
	if cutscene_data.is_empty():
		on_complete.call()
		return
	var cutscene = CUTSCENE_SCENE.instantiate()
	hud.add_child(cutscene)
	cutscene.setup_cutscene(cutscene_data)
	cutscene.cutscene_finished.connect(on_complete)

func _ensure_nodes() -> void:
	if level_container == null:
		level_container = get_node_or_null("LevelContainer")
	if hud == null:
		hud = get_node_or_null("HUD")

## Instancia y configura el escenario correspondiente al índice indicado
func load_level(index: int) -> void:
	_ensure_nodes()
	if levels.is_empty():
		levels = LevelManager.get_all_levels()
	if index < 0 or index >= levels.size():
		return

	current_level_index = index

	# Liberar el nivel anterior para evitar fugas de memoria
	for child in level_container.get_children():
		level_container.remove_child(child)
		child.queue_free()

	# Instanciar el nuevo escenario
	active_level = LEVEL_SCENE.instantiate()
	level_container.add_child(active_level)
	active_level.setup_level(levels[current_level_index])

	# Conectar señales del nivel activo
	active_level.player_health_changed.connect(_on_player_health_changed)
	active_level.player_died.connect(_on_player_died)
	active_level.enemy_defeated.connect(_on_enemy_defeated)
	active_level.level_completed.connect(_on_level_completed)
	active_level.quota_updated.connect(_on_quota_updated)
	active_level.boss_spawned.connect(_on_boss_spawned)
	active_level.boss_health_changed.connect(_on_boss_health_changed)
	active_level.boss_redeemed.connect(_on_boss_redeemed)

	# Cachear la distancia 2D entre el punto de spawn y la meta para la barra de progreso
	var lvl_data: Dictionary = levels[current_level_index]
	var p_spawn: Vector2 = lvl_data.get("player_spawn", Vector2(100, 400))
	var g_pos: Vector2 = lvl_data.get("goal_position", Vector2(1000, 400))
	_cached_goal_pos = g_pos
	_cached_total_dist = maxf(1.0, p_spawn.distance_to(g_pos))
	_max_reached_dist = 0.0

	var title: String = lvl_data.get("title", "Nivel %d" % (current_level_index + 1))
	hud.set_level_title(title)
	hud.reset_state()
	hud.update_hearts(active_level.player.health, active_level.player.max_health)
	hud.update_progress(0.0, _cached_total_dist)
	var quota_val: int = int(lvl_data.get("quota_to_boss", 3))
	hud.update_quota(0, quota_val)
	var diff_intro: String = _game_settings.difficulty_name() if _game_settings and _game_settings.has_method("difficulty_name") and current_level_index == 0 else ""
	hud.show_intro(title, diff_intro)

func _process(delta: float) -> void:
	if not game_finished:
		elapsed_time += delta

	# Actualizar la barra de progreso 2D hacia la meta según la distancia euclidiana remanente
	if active_level and active_level.player and is_instance_valid(active_level.player):
		var remaining_dist := active_level.player.position.distance_to(_cached_goal_pos)
		var current_dist := clampf(_cached_total_dist - remaining_dist, 0.0, _cached_total_dist)
		_max_reached_dist = maxf(_max_reached_dist, current_dist)
		hud.update_progress(_max_reached_dist, _cached_total_dist)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		if hud and hud.has_method("set_paused"):
			hud.set_paused(not hud.is_paused)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()

func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_enemy_defeated(_enemy: Enemy) -> void:
	enemies_defeated += 1

func _on_quota_updated(defeated: int, quota: int) -> void:
	hud.update_quota(defeated, quota)

func _on_boss_spawned(boss_inst: CharacterBody2D) -> void:
	var b_name: String = "Antivalor Mayor"
	if "boss_type" in boss_inst:
		var b_type: int = boss_inst.boss_type
		if "BOSS_DATA" in boss_inst and boss_inst.BOSS_DATA.has(b_type):
			b_name = boss_inst.BOSS_DATA[b_type].get("name", b_name)
	var hp: int = int(boss_inst.get("current_hp") if "current_hp" in boss_inst else 10)
	var max_hp: int = int(boss_inst.get("max_hp") if "max_hp" in boss_inst else 10)
	hud.show_boss_bar(b_name, hp, max_hp)

func _on_boss_health_changed(hp: int, max_hp: int) -> void:
	hud.update_boss_bar(hp, max_hp)

func _on_boss_redeemed(_boss_inst: CharacterBody2D) -> void:
	hud.hide_boss_bar()

func _on_player_health_changed(current: int, max_hp: int) -> void:
	hud.update_hearts(current, max_hp)

func _on_level_completed() -> void:
	if game_finished:
		return

	# Si aún quedan escenarios pendientes en la campaña
	if current_level_index < levels.size() - 1:
		hud.show_level_complete(levels[current_level_index].get("title", ""))
		await get_tree().create_timer(1.2).timeout
		if is_inside_tree() and not game_finished:
			if _is_story_mode():
				_show_story_act(current_level_index + 2, func():
					_transition_to_level(current_level_index + 1)
				)
			else:
				_transition_to_level(current_level_index + 1)
	else:
		# Campaña de los 6 escenarios completada
		game_finished = true
		if _game_settings and _game_settings.has_method("stop_music"):
			_game_settings.stop_music()
		await get_tree().create_timer(0.7).timeout
		if is_inside_tree():
			if _is_story_mode():
				_show_epilogue_and_victory()
			else:
				_show_victory_screen()

func _transition_to_level(next_index: int) -> void:
	if _scene_transition and _scene_transition.has_method("transition_call"):
		_scene_transition.transition_call(func(): load_level(next_index))
	else:
		load_level(next_index)

func _show_story_act(act_id: int, on_complete: Callable) -> void:
	_show_story_cutscene(StoryDataClass.get_scenario_cutscene(act_id), on_complete)

func _show_epilogue_and_victory() -> void:
	_show_story_cutscene(StoryDataClass.get_epilogue(), _show_victory_screen)

func _show_victory_screen() -> void:
	hud.show_victory({
		"time": elapsed_time,
		"defeated": enemies_defeated,
		"health": active_level.player.health if active_level and active_level.player else 3,
		"max_health": active_level.player.max_health if active_level and active_level.player else 3,
	})

func _on_player_died() -> void:
	if game_finished:
		return
	game_finished = true
	if active_level:
		active_level.stop_enemies()
	if _game_settings and _game_settings.has_method("stop_music"):
		_game_settings.stop_music()

	var progress_pct := (float(current_level_index) / float(levels.size())) * 100.0
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		hud.show_game_over({
			"defeated": enemies_defeated,
			"progress": progress_pct,
		})

func _on_restart_game() -> void:
	game_finished = false
	if current_level_index >= levels.size() - 1:
		current_level_index = 0
		elapsed_time = 0.0
		enemies_defeated = 0
	if _game_settings and _game_settings.has_method("play_game_music"):
		_game_settings.play_game_music()
	load_level(current_level_index)

func _on_go_to_menu() -> void:
	if _scene_transition and _scene_transition.has_method("change_scene"):
		_scene_transition.change_scene(MENU_SCENE)
	else:
		get_tree().change_scene_to_file(MENU_SCENE)

## Asegura mapeos de joypad y gamepad complementarios en tiempo de ejecución
func setup_inputs() -> void:
	# Ejes analógicos de mando / gamepad (Android y PC)
	_ensure_joy_motion("move_left", JOY_AXIS_LEFT_X, -1.0)
	_ensure_joy_motion("move_right", JOY_AXIS_LEFT_X, 1.0)
	_ensure_joy_motion("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_ensure_joy_motion("move_down", JOY_AXIS_LEFT_Y, 1.0)

	_ensure_joy_motion("aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_ensure_joy_motion("aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_ensure_joy_motion("aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_ensure_joy_motion("aim_down", JOY_AXIS_RIGHT_Y, 1.0)

	# Botones de disparo en gamepad
	_ensure_joy_button("attack", JOY_BUTTON_A)
	_ensure_joy_button("attack", JOY_BUTTON_RIGHT_SHOULDER)

	# Botones de navegación y menú en gamepad (Start para Pausa, B para Cancelar, A para Aceptar)
	_ensure_joy_button("pause", JOY_BUTTON_START)
	_ensure_joy_button("ui_cancel", JOY_BUTTON_B)
	_ensure_joy_button("ui_accept", JOY_BUTTON_A)

func _ensure_joy_motion(action: String, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadMotion and ev.axis == axis and signf(ev.axis_value) == signf(axis_value):
			return
	var motion := InputEventJoypadMotion.new()
	motion.axis = axis
	motion.axis_value = axis_value
	InputMap.action_add_event(action, motion)

func _ensure_joy_button(action: String, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton and ev.button_index == button:
			return
	var btn := InputEventJoypadButton.new()
	btn.button_index = button
	InputMap.action_add_event(action, btn)
