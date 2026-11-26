extends Node2D

## Orquestador del ciclo de juego.
## Maneja la carga secuencial de niveles, cálculo del progreso hacia la meta,
## victorias, derrotas y transiciones con SceneTransition.

const MENU_SCENE := "res://scenes/menu.tscn"
const LEVEL_SCENE := preload("res://scenes/level.tscn")
const CUTSCENE_SCENE := preload("res://scenes/story_cutscene.tscn")
const StoryDataClass := preload("res://scripts/story_data.gd")
const FINAL_CEREMONY_SCENE := preload("res://scenes/final_ceremony.tscn")
const LOADING_SCREEN_SCENE := preload("res://scenes/loading_screen.tscn")
const UNDERTALE_CLIMAX_SCENE := preload("res://scenes/undertale_climax.tscn")
const UNDERTALE_BATTLE_SCENE := preload("res://scenes/undertale_battle.tscn")
const CLASSROOM_MINIGAME_SCENE := preload("res://scenes/classroom_minigame.tscn")
const INTERLUDE_MINIGAME_SCENE := preload("res://scenes/interlude_minigame.tscn")

@onready var level_container: Node2D = $LevelContainer
@onready var hud: HUD = $HUD

var current_level_index: int = 0
var levels: Array[Dictionary] = []
var active_level: Level = null
var active_ceremony: Node2D = null
var active_undertale_battle: CanvasLayer = null
var active_undertale_climax: CanvasLayer = null
var active_classroom_minigame: CanvasLayer = null
var active_interlude_minigame: CanvasLayer = null
var _final_loading_layer: CanvasLayer = null
var _pending_interlude_reward: Dictionary = {}
var _played_interludes: Array[int] = []

var game_finished: bool = false
var _campaign_completed: bool = false
var _is_stage_transitioning: bool = false
var _transition_epoch: int = 0
var enemies_defeated: int = 0
var elapsed_time: float = 0.0

var _cached_goal_pos: Vector2 = Vector2.ZERO
var _cached_total_dist: float = 1.0
var _max_reached_dist: float = 0.0

var _cleared_classrooms: Dictionary = {}
var _saved_exterior_boss_defeated: Dictionary = {}
var _saved_exterior_defeated_count: Dictionary = {}
var _saved_player_health: int = -1
var _in_classroom_from_door: bool = false
var _return_exterior_index: int = 0
var _returning_from_classroom: bool = false
var _saved_held_item: String = ""
var _stage_start_enemies_defeated: int = 0
var _in_retry_reload: bool = false

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
	if _game_settings and _game_settings.has_method("lock_initial_difficulty"):
		_game_settings.lock_initial_difficulty()
	if _game_settings and _game_settings.has_method("play_game_music"):
		_game_settings.play_game_music()

	levels = LevelManager.get_all_campaign_stages()

	hud.restart_game.connect(_on_restart_game)
	hud.go_to_menu.connect(_on_go_to_menu)
	if hud.has_signal("use_item_requested"):
		hud.use_item_requested.connect(_on_use_item_requested)
	if hud.mobile_controls and hud.mobile_controls.has_signal("aim_vector_changed"):
		if not hud.mobile_controls.aim_vector_changed.is_connected(_on_mobile_aim_changed):
			hud.mobile_controls.aim_vector_changed.connect(_on_mobile_aim_changed)
	var diff_str: String = _game_settings.difficulty_name() if _game_settings and _game_settings.has_method("difficulty_name") else "Normal"
	hud.set_difficulty_text(diff_str)

	if _is_story_mode():
		_start_story_mode()
	else:
		var start_stage := clampi(int(_game_settings.get("selected_start_stage")) if _game_settings else 0, 0, 5)
		var start_idx := clampi(start_stage * 2, 0, maxi(0, levels.size() - 1))
		load_level(start_idx)

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
	var prev_can_pause := hud.can_pause if hud else true
	if hud:
		hud.can_pause = false
		if hud.mobile_controls and hud.mobile_controls.has_method("deactivate"):
			hud.mobile_controls.deactivate()
	var cutscene = CUTSCENE_SCENE.instantiate()
	hud.add_child(cutscene)
	cutscene.setup_cutscene(cutscene_data)
	cutscene.cutscene_finished.connect(func():
		if hud and not game_finished:
			hud.can_pause = prev_can_pause
			if not hud.is_paused and active_ceremony == null and hud.mobile_controls and hud.mobile_controls.has_method("activate"):
				hud.mobile_controls.activate()
		on_complete.call()
	)

func _ensure_nodes() -> void:
	if level_container == null:
		level_container = get_node_or_null("LevelContainer")
	if hud == null:
		hud = get_node_or_null("HUD")

## Instancia y configura el escenario correspondiente al índice indicado
func load_level(index: int) -> void:
	_ensure_nodes()
	if levels.is_empty():
		levels = LevelManager.get_all_campaign_stages()
	if index < 0 or index >= levels.size():
		return

	current_level_index = index
	_is_stage_transitioning = false
	if not _in_classroom_from_door and not _returning_from_classroom and not _in_retry_reload:
		_stage_start_enemies_defeated = enemies_defeated
	_in_retry_reload = false

	# Liberar el nivel o ceremonia anterior para evitar fugas de memoria
	active_level = null
	active_ceremony = null
	_set_hud_gameplay_visible(true)
	for child in level_container.get_children():
		level_container.remove_child(child)
		child.queue_free()

	# Instanciar el nuevo escenario
	active_level = LEVEL_SCENE.instantiate()
	level_container.add_child(active_level)

	var lvl_data: Dictionary = levels[current_level_index].duplicate(true)
	var c_idx: int = int(lvl_data.get("classroom_index", -1))
	if not lvl_data.get("is_classroom", false) and c_idx >= 0 and _cleared_classrooms.get(c_idx, false):
		lvl_data["is_classroom_cleared"] = true
	var returning_flag := _returning_from_classroom
	if returning_flag:
		if lvl_data.has("classroom_exit_spawn"):
			lvl_data["player_spawn"] = lvl_data["classroom_exit_spawn"]
		elif lvl_data.has("classroom_entrance_pos"):
			lvl_data["player_spawn"] = lvl_data["classroom_entrance_pos"] + Vector2(0, 48)
		lvl_data["returning_from_classroom"] = true
		if c_idx >= 0:
			lvl_data["exterior_boss_defeated"] = _saved_exterior_boss_defeated.get(c_idx, false)
			lvl_data["saved_defeated_in_level"] = _saved_exterior_defeated_count.get(c_idx, 0)

	# Conectar señales antes de setup_level para capturar boss_spawned si reaparece al volver
	active_level.player_health_changed.connect(_on_player_health_changed)
	active_level.player_died.connect(_on_player_died)
	active_level.enemy_defeated.connect(_on_enemy_defeated)
	active_level.level_completed.connect(_on_level_completed)
	active_level.quota_updated.connect(_on_quota_updated)
	active_level.boss_spawned.connect(_on_boss_spawned)
	active_level.boss_health_changed.connect(_on_boss_health_changed)
	active_level.boss_redeemed.connect(_on_boss_redeemed)
	if active_level.has_signal("boss_undertale_climax_requested"):
		active_level.boss_undertale_climax_requested.connect(_on_boss_undertale_climax_requested)
	active_level.enter_classroom_requested.connect(_on_enter_classroom_requested)
	if active_level.has_signal("player_inventory_changed"):
		active_level.player_inventory_changed.connect(_on_player_inventory_changed)
	if active_level.has_signal("esperanza_timer_updated"):
		active_level.esperanza_timer_updated.connect(_on_esperanza_timer_updated)

	active_level.setup_level(lvl_data)

	if (_in_classroom_from_door or returning_flag) and _saved_player_health > 0 and active_level.player:
		active_level.player.health = mini(active_level.player.max_health, _saved_player_health)
		_saved_player_health = -1
	_returning_from_classroom = false
	if active_level.player and active_level.player.has_method("set_held_item_silently"):
		active_level.player.set_held_item_silently(_saved_held_item)

	if not _pending_interlude_reward.is_empty() and not bool(lvl_data.get("is_classroom", false)):
		var r_kind := str(_pending_interlude_reward.get("kind", ""))
		_pending_interlude_reward = {}
		if active_level.player and is_instance_valid(active_level.player):
			match r_kind:
				"heart":
					if active_level.player.health < active_level.player.max_health:
						active_level.player.health = mini(active_level.player.max_health, active_level.player.health + 1)
						active_level.player.health_changed.emit(active_level.player.health, active_level.player.max_health)
					else:
						active_level.player.empathy_cooldown_left = 0.0
				"shield":
					if active_level.player.has_method("grant_spawn_protection"):
						active_level.player.grant_spawn_protection(4.0)
				"quota_bonus":
					active_level.quota_to_boss = maxi(1, active_level.quota_to_boss - 1)
				"pulse_ready":
					active_level.player.empathy_cooldown_left = 0.0

	# Cachear la distancia 2D entre el punto de spawn y la meta para la barra de progreso
	var p_spawn: Vector2 = lvl_data.get("player_spawn", Vector2(100, 400))
	var g_pos: Vector2 = lvl_data.get("goal_position", Vector2(1000, 400))
	_cached_goal_pos = g_pos
	_cached_total_dist = maxf(1.0, p_spawn.distance_to(g_pos))
	_max_reached_dist = 0.0

	var title: String = lvl_data.get("title", "Nivel %d" % (current_level_index + 1))
	hud.can_pause = true
	hud.set_level_title(title)
	hud.reset_state()
	if _game_settings and _game_settings.has_method("play_stage_music"):
		var b_idx: int = clampi(int(lvl_data.get("building_id", (current_level_index / 2) + 1)) - 1, 0, 5)
		var is_cls: bool = bool(lvl_data.get("is_classroom", false))
		_game_settings.play_stage_music(b_idx, is_cls, false, false)
	if active_level.boss and is_instance_valid(active_level.boss):
		_on_boss_spawned(active_level.boss)
	hud.update_hearts(active_level.player.health, active_level.player.max_health)
	hud.update_progress(0.0, _cached_total_dist)
	var quota_val: int = active_level.quota_to_boss
	hud.update_quota(active_level.defeated_in_level, quota_val)
	if active_level.boss_defeated:
		hud.set_boss_defeated(active_level.has_classroom and not active_level.is_classroom_cleared)
	if returning_flag:
		hud.show_intro("Patio exterior — ¡Salida lista!", "")
	else:
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
		if hud and hud.has_method("update_pulse_cooldown"):
			hud.update_pulse_cooldown(active_level.player.empathy_cooldown_left, Player.EMPATHY_PULSE_COOLDOWN)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
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
	var b_type: int = -1
	var hp: int = 10
	var max_hp: int = 10
	if boss_inst is Boss:
		var typed_boss := boss_inst as Boss
		b_type = typed_boss.boss_type
		if Boss.BOSS_DATA.has(b_type):
			b_name = Boss.BOSS_DATA[b_type].get("name", b_name)
		hp = typed_boss.current_hp
		max_hp = typed_boss.max_hp
	elif "boss_type" in boss_inst:
		b_type = int(boss_inst.get("boss_type"))
		if "BOSS_DATA" in boss_inst and boss_inst.BOSS_DATA.has(b_type):
			b_name = boss_inst.BOSS_DATA[b_type].get("name", b_name)
		hp = int(boss_inst.get("current_hp") if "current_hp" in boss_inst else 10)
		max_hp = int(boss_inst.get("max_hp") if "max_hp" in boss_inst else 10)
	hud.show_boss_bar(b_name, hp, max_hp)
	if boss_inst != null and boss_inst.has_signal("special_phase_message"):
		var cb := Callable(self, "_on_boss_subtitle_message")
		if not boss_inst.special_phase_message.is_connected(cb):
			boss_inst.special_phase_message.connect(cb)
	if _game_settings and _game_settings.has_method("play_stage_music") and active_level:
		var lvl_data: Dictionary = active_level.level_data
		var b_idx: int = clampi(int(lvl_data.get("building_id", (current_level_index / 2) + 1)) - 1, 0, 5)
		var is_cls: bool = bool(lvl_data.get("is_classroom", false))
		var is_final: bool = (b_type == Boss.BossType.BULLYING)
		_game_settings.play_stage_music(b_idx, is_cls, true, is_final)

func _on_boss_health_changed(hp: int, max_hp: int) -> void:
	hud.update_boss_bar(hp, max_hp)

func _on_boss_subtitle_message(msg: String) -> void:
	if hud and hud.has_method("show_boss_subtitle"):
		hud.show_boss_subtitle(msg, 2.2)

func _on_boss_redeemed(boss_inst: CharacterBody2D) -> void:
	hud.hide_boss_bar()
	if hud and hud.has_method("set_boss_defeated"):
		hud.set_boss_defeated(active_level != null and active_level.has_classroom and not active_level.is_classroom_cleared)
	var is_titanor: bool = (boss_inst is Boss and (boss_inst as Boss).boss_type == Boss.BossType.BULLYING) or (boss_inst != null and int(boss_inst.get("boss_type")) == 5)
	if _game_settings and _game_settings.has_method("play_stage_music") and active_level and not is_titanor:
		var lvl_data: Dictionary = active_level.level_data
		var b_idx: int = clampi(int(lvl_data.get("building_id", (current_level_index / 2) + 1)) - 1, 0, 5)
		var is_cls: bool = bool(lvl_data.get("is_classroom", false))
		_game_settings.play_stage_music(b_idx, is_cls, false, false)
	# Al derrotar al Jefe Final (Titanor, BossType.BULLYING = 5), disipa la niebla y libera a los alumnos para la celebración de 7s antes de desbloquear la meta
	if is_titanor:
		if active_level:
			if active_level.has_method("set_boss_desperation_fog"):
				active_level.set_boss_desperation_fog(false)
			active_level.stop_enemies()
			active_level.set_classroom_cleared(true)
		_cleared_classrooms[5] = true

func _on_boss_undertale_climax_requested(boss_inst: CharacterBody2D) -> void:
	if game_finished or active_undertale_climax != null or active_undertale_battle != null:
		return
	var epoch := _transition_epoch
	if hud:
		hud.can_pause = false
		hud.hide_boss_bar(true)
		if hud.mobile_controls and hud.mobile_controls.has_method("deactivate"):
			hud.mobile_controls.deactivate()
	if _game_settings and _game_settings.has_method("request_pause"):
		_game_settings.request_pause(&"undertale_climax")
	elif get_tree():
		get_tree().paused = true
	if UndertaleBattle.should_trigger():
		active_undertale_battle = UNDERTALE_BATTLE_SCENE.instantiate()
		add_child(active_undertale_battle)
		active_undertale_battle.battle_finished.connect(func():
			active_undertale_battle = null
			if epoch != _transition_epoch or not is_inside_tree():
				return
			_launch_undertale_hearts_climax(boss_inst, epoch)
		, CONNECT_ONE_SHOT)
		return
	_launch_undertale_hearts_climax(boss_inst, epoch)

func _launch_undertale_hearts_climax(boss_inst: CharacterBody2D, epoch: int) -> void:
	active_undertale_climax = UNDERTALE_CLIMAX_SCENE.instantiate()
	add_child(active_undertale_climax)
	active_undertale_climax.climax_finished.connect(func():
		active_undertale_climax = null
		if _game_settings and _game_settings.has_method("release_pause"):
			_game_settings.release_pause(&"undertale_climax")
		elif is_inside_tree() and get_tree():
			get_tree().paused = false
		if epoch != _transition_epoch or not is_inside_tree():
			return
		if boss_inst != null and is_instance_valid(boss_inst) and boss_inst.has_method("finish_undertale_climax"):
			boss_inst.finish_undertale_climax()
		if hud and not game_finished:
			hud.can_pause = true
			if not hud.is_paused and hud.mobile_controls and hud.mobile_controls.has_method("activate") and MobileControls.is_touch_device():
				hud.mobile_controls.activate()
		# Permitir la celebración de 7s y la caminata a la meta; usar el epílogo directo solo como respaldo
		if active_level == null or not active_level.is_final_boss_celebrating:
			_complete_final_campaign_after_climax()
	)

func _complete_final_campaign_after_climax() -> void:
	if game_finished:
		return
	_is_stage_transitioning = true
	game_finished = true
	_campaign_completed = true
	var epoch := _transition_epoch
	if _game_settings:
		if _game_settings.has_method("unlock_stage"):
			_game_settings.unlock_stage(5)
		if _game_settings.has_method("record_campaign_completion"):
			var d_idx: int = int(_game_settings.get("initial_difficulty")) if _game_settings.get("initial_difficulty") != null else int(_game_settings.difficulty)
			_game_settings.record_campaign_completion(d_idx, elapsed_time, enemies_defeated)
	await get_tree().create_timer(0.8).timeout
	if is_inside_tree() and epoch == _transition_epoch:
		if _is_story_mode():
			_show_epilogue_and_victory()
		else:
			_show_final_loading_screen_then_ceremony()

func _on_player_health_changed(current: int, max_hp: int) -> void:
	hud.update_hearts(current, max_hp)

func _on_player_inventory_changed(item_id: String, item_info: Dictionary) -> void:
	_saved_held_item = item_id
	if hud and hud.has_method("update_inventory_slot"):
		hud.update_inventory_slot(item_id, item_info)

func _on_esperanza_timer_updated(remaining: float, duration: float) -> void:
	if hud and hud.has_method("update_esperanza_bar"):
		hud.update_esperanza_bar(remaining, duration)

func _on_use_item_requested() -> void:
	if active_level and active_level.player and is_instance_valid(active_level.player) and active_level.player.has_method("use_held_item"):
		active_level.player.use_held_item()

func _on_mobile_aim_changed(aim_vec: Vector2) -> void:
	if active_level and active_level.player and is_instance_valid(active_level.player):
		active_level.player.mobile_aim_vector = aim_vec

func _get_unlocked_ally_names(stage_count: int) -> Array[String]:
	var all_names: Array[String] = ["Mateo", "María", "Valeria", "Fernanda", "Diego", "Sofía", "Alejandro"]
	var res: Array[String] = []
	for i in range(mini(all_names.size(), maxi(1, stage_count + 1))):
		res.append(all_names[i])
	return res

func _on_enter_classroom_requested(classroom_idx: int) -> void:
	launch_classroom_minigame(classroom_idx, true)

func launch_classroom_minigame(classroom_idx: int, from_exterior_door: bool = true) -> void:
	if game_finished or _is_stage_transitioning or active_classroom_minigame != null or active_interlude_minigame != null:
		return
	var epoch := _transition_epoch
	if hud:
		hud.can_pause = false
		if hud.mobile_controls and hud.mobile_controls.has_method("deactivate"):
			hud.mobile_controls.deactivate()
	if _game_settings and _game_settings.has_method("request_pause"):
		_game_settings.request_pause(&"classroom_minigame")
	elif get_tree():
		get_tree().paused = true

	var mg := CLASSROOM_MINIGAME_SCENE.instantiate() as ClassroomMinigame
	active_classroom_minigame = mg
	add_child(mg)
	mg.setup_classroom(classroom_idx)
	mg.minigame_finished.connect(func(cleared: bool, c_idx: int):
		active_classroom_minigame = null
		if _game_settings and _game_settings.has_method("release_pause"):
			_game_settings.release_pause(&"classroom_minigame")
		elif is_inside_tree() and get_tree():
			get_tree().paused = false
		if epoch != _transition_epoch or not is_inside_tree():
			return
		if hud and not game_finished:
			hud.can_pause = true
			if not hud.is_paused and hud.mobile_controls and hud.mobile_controls.has_method("activate") and MobileControls.is_touch_device():
				hud.mobile_controls.activate()
		if from_exterior_door and active_level != null and is_instance_valid(active_level):
			if active_level.player != null and is_instance_valid(active_level.player):
				active_level.player.position = active_level.level_data.get("classroom_exit_spawn", active_level.player.position)
				active_level.player.velocity = Vector2.ZERO
				if active_level.player.has_method("grant_spawn_protection"):
					active_level.player.grant_spawn_protection(2.0)
		if cleared:
			_cleared_classrooms[c_idx] = true
			if from_exterior_door and active_level != null and is_instance_valid(active_level):
				active_level.set_classroom_cleared(true)
				if active_level.player and is_instance_valid(active_level.player) and active_level.player.health < active_level.player.max_health:
					active_level.player.health = mini(active_level.player.max_health, active_level.player.health + 1)
					active_level.player.health_changed.emit(active_level.player.health, active_level.player.max_health)
				if hud:
					hud.set_boss_defeated(false)
					hud.show_intro("¡Salón en Armonía!", "Meta del patio desbloqueada")
	, CONNECT_ONE_SHOT)

func launch_interlude_minigame(kind_override: int = -1, on_done: Callable = Callable()) -> void:
	if game_finished or active_interlude_minigame != null or active_classroom_minigame != null:
		if on_done.is_valid():
			on_done.call()
		return
	var epoch := _transition_epoch
	var chosen_kind := kind_override
	if chosen_kind < 0:
		var pool: Array[int] = []
		for k in [0, 1, 2]:
			if not _played_interludes.has(k):
				pool.append(k)
		if pool.is_empty():
			_played_interludes.clear()
			pool = [0, 1, 2]
		chosen_kind = pool[randi() % pool.size()]
	if not _played_interludes.has(chosen_kind):
		_played_interludes.append(chosen_kind)

	if hud:
		hud.can_pause = false
		if hud.mobile_controls and hud.mobile_controls.has_method("deactivate"):
			hud.mobile_controls.deactivate()
	if _game_settings and _game_settings.has_method("request_pause"):
		_game_settings.request_pause(&"interlude_minigame")
	elif get_tree():
		get_tree().paused = true

	var im := INTERLUDE_MINIGAME_SCENE.instantiate() as InterludeMinigame
	active_interlude_minigame = im
	add_child(im)
	im.setup_interlude(chosen_kind as InterludeMinigame.Kind, _get_unlocked_ally_names(current_level_index / 2))
	im.interlude_finished.connect(func(reward: Dictionary):
		active_interlude_minigame = null
		_pending_interlude_reward = reward
		if _game_settings and _game_settings.has_method("release_pause"):
			_game_settings.release_pause(&"interlude_minigame")
		elif is_inside_tree() and get_tree():
			get_tree().paused = false
		if epoch != _transition_epoch or not is_inside_tree():
			return
		if hud and not game_finished:
			hud.can_pause = true
			if not hud.is_paused and hud.mobile_controls and hud.mobile_controls.has_method("activate") and MobileControls.is_touch_device():
				hud.mobile_controls.activate()
		if on_done.is_valid():
			on_done.call()
	, CONNECT_ONE_SHOT)

func _on_level_completed() -> void:
	if game_finished or _is_stage_transitioning:
		return
	_is_stage_transitioning = true
	var epoch := _transition_epoch

	var cur_data: Dictionary = levels[current_level_index]
	var is_cur_classroom: bool = cur_data.get("is_classroom", false)
	var cur_c_idx: int = int(cur_data.get("classroom_index", -1))

	if is_cur_classroom and cur_c_idx >= 0:
		_cleared_classrooms[cur_c_idx] = true

	# Si el jugador entró al salón desde la puerta exterior, regresar al exterior con el salón ya limpio
	if is_cur_classroom and _in_classroom_from_door:
		_in_classroom_from_door = false
		if active_level and active_level.player:
			_saved_player_health = active_level.player.health
		hud.show_level_complete("¡Salón Limpiado! Regresando al patio...")
		await get_tree().create_timer(1.1).timeout
		if is_inside_tree() and not game_finished and epoch == _transition_epoch:
			_returning_from_classroom = true
			_transition_to_level(_return_exterior_index)
		return

	# Determinar el siguiente índice de nivel (saltando el salón si ya fue limpiado desde la puerta)
	var next_idx := current_level_index + 1
	if int(cur_data.get("boss_type", -1)) == 5:
		next_idx = levels.size()
	elif next_idx < levels.size() and levels[next_idx].get("is_classroom", false):
		var next_c_idx: int = int(levels[next_idx].get("classroom_index", -1))
		if _cleared_classrooms.get(next_c_idx, false):
			next_idx += 1

	# Si aún quedan escenarios pendientes en la campaña
	if next_idx < levels.size():
		if _game_settings and _game_settings.has_method("unlock_stage"):
			_game_settings.unlock_stage(next_idx / 2)
		hud.show_level_complete(cur_data.get("title", ""))
		await get_tree().create_timer(1.2).timeout
		if is_inside_tree() and not game_finished and epoch == _transition_epoch:
			var proceed_next := func():
				if not is_inside_tree() or epoch != _transition_epoch:
					return
				if _is_story_mode():
					if next_idx % 2 == 0:
						var act_id := (next_idx / 2) + 1
						_show_story_act(act_id, func():
							if is_inside_tree() and epoch == _transition_epoch:
								_transition_to_level(next_idx)
						)
					else:
						_transition_to_level(next_idx)
				else:
					_transition_to_level(next_idx)
			var is_test := bool(_game_settings.get("is_test_mode")) if (_game_settings and "is_test_mode" in _game_settings) else false
			if next_idx % 2 == 0 and not is_test and InterludeMinigame.should_trigger():
				launch_interlude_minigame(-1, proceed_next)
			else:
				proceed_next.call()
	else:
		# Campaña de los 6 escenarios completada
		game_finished = true
		_campaign_completed = true
		if _game_settings:
			if _game_settings.has_method("unlock_stage"):
				_game_settings.unlock_stage(5)
			if _game_settings.has_method("record_campaign_completion"):
				var d_idx: int = int(_game_settings.get("initial_difficulty")) if _game_settings.get("initial_difficulty") != null else int(_game_settings.difficulty)
				_game_settings.record_campaign_completion(d_idx, elapsed_time, enemies_defeated)
			if _game_settings.has_method("stop_music"):
				_game_settings.stop_music(0.5)
		await get_tree().create_timer(0.7).timeout
		if is_inside_tree() and epoch == _transition_epoch:
			if _is_story_mode():
				_show_epilogue_and_victory()
			else:
				_show_final_loading_screen_then_ceremony()

func _transition_to_level(next_index: int) -> void:
	var epoch := _transition_epoch
	if _scene_transition and _scene_transition.has_method("transition_call"):
		_scene_transition.transition_call(func():
			if is_inside_tree() and epoch == _transition_epoch:
				load_level(next_index)
		)
	else:
		load_level(next_index)

func _show_story_act(act_id: int, on_complete: Callable) -> void:
	_show_story_cutscene(StoryDataClass.get_scenario_cutscene(act_id), on_complete)

func _show_epilogue_and_victory() -> void:
	_show_story_cutscene(StoryDataClass.get_epilogue(), _show_final_loading_screen_then_ceremony)

func _show_final_loading_screen_then_ceremony() -> void:
	_ensure_nodes()
	if hud:
		hud.can_pause = false
	if _final_loading_layer and is_instance_valid(_final_loading_layer):
		_final_loading_layer.queue_free()
	_final_loading_layer = CanvasLayer.new()
	_final_loading_layer.name = "FinalLoadingLayer"
	_final_loading_layer.layer = 90
	add_child(_final_loading_layer)

	var ls := LOADING_SCREEN_SCENE.instantiate() as LoadingScreen
	ls.min_display_time = 2.0
	ls.custom_status_messages = [
		"La niebla se ha disipado por completo en CEMSaD 22...",
		"Reuniendo a los 7 alumnos rescatados y al Coordinador...",
		"Preparando el podio del Coordinador en la cancha de básquetbol...",
		"¡Escuela en paz y armonía! Iniciando Ceremonia de Agradecimiento..."
	]
	ls.on_complete_callback = _finish_final_loading_to_ceremony
	_final_loading_layer.add_child(ls)

func _finish_final_loading_to_ceremony() -> void:
	if _final_loading_layer and is_instance_valid(_final_loading_layer):
		_final_loading_layer.queue_free()
	_final_loading_layer = null
	_show_final_ceremony()

func _show_final_ceremony() -> void:
	_ensure_nodes()
	if hud:
		hud.can_pause = false
	active_level = null
	for child in level_container.get_children():
		level_container.remove_child(child)
		child.queue_free()

	_set_hud_gameplay_visible(false)

	active_ceremony = FINAL_CEREMONY_SCENE.instantiate()
	level_container.add_child(active_ceremony)
	if active_ceremony.has_method("setup_stats"):
		active_ceremony.setup_stats({
			"time": elapsed_time,
			"defeated": enemies_defeated,
		})
	if active_ceremony.has_signal("restart_requested"):
		active_ceremony.restart_requested.connect(_on_restart_game)
	if active_ceremony.has_signal("menu_requested"):
		active_ceremony.menu_requested.connect(_on_go_to_menu)

func _set_hud_gameplay_visible(visible_flag: bool) -> void:
	if hud == null:
		return
	var top_panel := hud.get_node_or_null("%TopPanel") as Control
	if top_panel:
		top_panel.visible = visible_flag
	var btn_pause := hud.get_node_or_null("%BtnPauseHud") as Control
	if btn_pause:
		btn_pause.visible = visible_flag
	var ctrl_label := hud.get_node_or_null("%ControlsLabel") as Control
	if ctrl_label:
		ctrl_label.visible = visible_flag
	if hud.has_method("set_gameplay_ui_visible"):
		hud.set_gameplay_ui_visible(visible_flag)
	if not visible_flag:
		hud.hide_boss_bar(true)
		if hud.mobile_controls and hud.mobile_controls.has_method("deactivate"):
			hud.mobile_controls.deactivate()
	elif hud.mobile_controls and MobileControls.is_touch_device() and hud.mobile_controls.has_method("activate"):
		hud.mobile_controls.activate()

func _on_player_died() -> void:
	if game_finished:
		return
	game_finished = true
	if active_level:
		active_level.stop_enemies()
	if _game_settings and _game_settings.has_method("stop_music"):
		_game_settings.stop_music()

	var stage_frac := clampf(_max_reached_dist / maxf(1.0, _cached_total_dist), 0.0, 1.0)
	var progress_pct := ((float(current_level_index) + stage_frac) / float(maxi(1, levels.size()))) * 100.0
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		hud.show_game_over({
			"defeated": enemies_defeated,
			"progress": progress_pct,
		})

func _on_restart_game() -> void:
	_transition_epoch += 1
	var finished_campaign := (active_ceremony != null) or _campaign_completed
	game_finished = false
	_campaign_completed = false
	_is_stage_transitioning = false
	active_ceremony = null
	if _final_loading_layer and is_instance_valid(_final_loading_layer):
		_final_loading_layer.queue_free()
	_final_loading_layer = null
	if active_undertale_battle and is_instance_valid(active_undertale_battle):
		active_undertale_battle.queue_free()
	active_undertale_battle = null
	if active_undertale_climax and is_instance_valid(active_undertale_climax):
		active_undertale_climax.queue_free()
	active_undertale_climax = null
	if active_classroom_minigame and is_instance_valid(active_classroom_minigame):
		active_classroom_minigame.queue_free()
	active_classroom_minigame = null
	if active_interlude_minigame and is_instance_valid(active_interlude_minigame):
		active_interlude_minigame.queue_free()
	active_interlude_minigame = null
	_set_hud_gameplay_visible(true)
	if finished_campaign:
		levels = LevelManager.get_all_campaign_stages()
		var restart_stage := 0 if _is_story_mode() else (clampi(int(_game_settings.get("selected_start_stage")) if _game_settings else 0, 0, 5))
		current_level_index = clampi(restart_stage * 2, 0, maxi(0, levels.size() - 1))
		elapsed_time = 0.0
		enemies_defeated = 0
		_stage_start_enemies_defeated = 0
		_cleared_classrooms.clear()
		_saved_exterior_boss_defeated.clear()
		_saved_exterior_defeated_count.clear()
		_saved_player_health = -1
		_saved_held_item = ""
		_pending_interlude_reward = {}
		_played_interludes.clear()
		_in_classroom_from_door = false
		_returning_from_classroom = false
	else:
		_in_retry_reload = true
		enemies_defeated = _stage_start_enemies_defeated
	load_level(current_level_index)

func _on_go_to_menu() -> void:
	_transition_epoch += 1
	if _final_loading_layer and is_instance_valid(_final_loading_layer):
		_final_loading_layer.queue_free()
	_final_loading_layer = null
	if active_undertale_battle and is_instance_valid(active_undertale_battle):
		active_undertale_battle.queue_free()
	active_undertale_battle = null
	if active_undertale_climax and is_instance_valid(active_undertale_climax):
		active_undertale_climax.queue_free()
	active_undertale_climax = null
	if active_classroom_minigame and is_instance_valid(active_classroom_minigame):
		active_classroom_minigame.queue_free()
	active_classroom_minigame = null
	if active_interlude_minigame and is_instance_valid(active_interlude_minigame):
		active_interlude_minigame.queue_free()
	active_interlude_minigame = null
	if _scene_transition and _scene_transition.has_method("change_scene"):
		_scene_transition.change_scene(MENU_SCENE)
	else:
		if _game_settings and _game_settings.has_method("clear_all_pauses"):
			_game_settings.clear_all_pauses()
		elif get_tree():
			get_tree().paused = false
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

	# Botones de disparo y Pulso de Empatía en gamepad
	_ensure_joy_button("attack", JOY_BUTTON_A)
	_ensure_joy_button("attack", JOY_BUTTON_RIGHT_SHOULDER)
	_ensure_joy_button("empathy_pulse", JOY_BUTTON_X)
	_ensure_joy_button("use_item", JOY_BUTTON_Y)

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
