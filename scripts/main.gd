extends Node2D

## Escena Principal del Juego
## Gestiona la progresión multinivel en perspectiva 3/4 (estilo Pokémon),
## cargando dinámicamente escenarios desde la carpeta 'escenarios/'.

const MENU_SCENE := "res://scenes/menu.tscn"
const LEVEL_SCENE := preload("res://scenes/level.tscn")

@onready var level_container: Node2D = $LevelContainer
@onready var hud: HUD = $HUD

var current_level_index: int = 0
var levels: Array[Dictionary] = []
var active_level: Level = null

var game_finished: bool = false
var enemies_defeated: int = 0
var elapsed_time: float = 0.0

var _cached_start_x: float = 0.0
var _cached_total_dist: float = 1.0

func _ready() -> void:
	setup_inputs()
	GameSettings.play_game_music()

	levels = LevelManager.get_all_levels()

	hud.restart_game.connect(_on_restart_game)
	hud.go_to_menu.connect(_on_go_to_menu)
	hud.set_difficulty_text(GameSettings.difficulty_name())

	load_level(0)

func load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		return

	current_level_index = index

	# Limpiar nivel anterior
	for child in level_container.get_children():
		child.queue_free()

	# Instanciar el nuevo nivel/escenario
	active_level = LEVEL_SCENE.instantiate()
	level_container.add_child(active_level)
	active_level.setup_level(levels[current_level_index])

	# Conectar señales del nivel
	active_level.player_health_changed.connect(_on_player_health_changed)
	active_level.player_died.connect(_on_player_died)
	active_level.enemy_defeated.connect(_on_enemy_defeated)
	active_level.level_completed.connect(_on_level_completed)

	# Actualizar interfaz y variables cacheadas
	var lvl_data: Dictionary = levels[current_level_index]
	var p_spawn: Vector2 = lvl_data.get("player_spawn", Vector2(100, 400))
	var g_pos: Vector2 = lvl_data.get("goal_position", Vector2(1000, 400))
	_cached_start_x = p_spawn.x
	_cached_total_dist = maxf(1.0, absf(g_pos.x - _cached_start_x))

	var title: String = lvl_data.get("title", "Nivel %d" % (current_level_index + 1))
	hud.set_level_title(title)
	hud.reset_state()
	hud.update_hearts(active_level.player.health, active_level.player.max_health)
	hud.update_progress(0.0, _cached_total_dist)
	hud.show_intro(title, GameSettings.difficulty_name() if current_level_index == 0 else "")

func _process(delta: float) -> void:
	if not game_finished:
		elapsed_time += delta

	# Actualizar progreso hacia la meta del nivel actual (optimizado sin consultas a diccionarios)
	if active_level and active_level.player and is_instance_valid(active_level.player):
		var current_dist := clampf(active_level.player.position.x - _cached_start_x, 0.0, _cached_total_dist)
		hud.update_progress(current_dist, _cached_total_dist)

func _on_enemy_defeated(_enemy: Enemy) -> void:
	enemies_defeated += 1

func _on_player_health_changed(current: int, max_hp: int) -> void:
	hud.update_hearts(current, max_hp)

func _on_level_completed() -> void:
	if game_finished:
		return

	# Si aún quedan niveles por superar
	if current_level_index < levels.size() - 1:
		hud.show_level_complete(levels[current_level_index].get("title", ""))
		await get_tree().create_timer(1.2).timeout
		if is_inside_tree() and not game_finished:
			# Transición suave entre niveles con la cortinilla
			SceneTransition._run(func(): load_level(current_level_index + 1))
	else:
		# ¡Último nivel completado, victoria total!
		game_finished = true
		GameSettings.stop_music()
		await get_tree().create_timer(0.7).timeout
		if is_inside_tree():
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
	GameSettings.stop_music()

	var progress_pct := (float(current_level_index) / float(levels.size())) * 100.0
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		hud.show_game_over({
			"defeated": enemies_defeated,
			"progress": progress_pct,
		})

func _on_restart_game() -> void:
	game_finished = false
	GameSettings.play_game_music()
	load_level(current_level_index)

func _on_go_to_menu() -> void:
	SceneTransition.change_scene(MENU_SCENE)

func setup_inputs() -> void:
	var actions := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"attack": [KEY_SPACE],
		"restart": [KEY_R, KEY_ENTER],
	}
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in actions[action]:
			var exists := false
			for ev in InputMap.action_get_events(action):
				if ev is InputEventKey and ev.keycode == k:
					exists = true
					break
			if not exists:
				var ev := InputEventKey.new()
				ev.keycode = k
				InputMap.action_add_event(action, ev)
