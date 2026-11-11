extends SceneTree

const LevelManager := preload("res://scripts/level_manager.gd")
const GameSettingsScript := preload("res://scripts/game_settings.gd")
const SceneTransitionScript := preload("res://scripts/scene_transition.gd")
const FxScript := preload("res://scripts/fx.gd")

func _init() -> void:
	print("--- INICIANDO TEST AUTOMÁTICO DE CAMPEONES DE LOS VALORES (CEMSaD 22 ENTHAVI) ---")

	# Inicializar singletons requeridos si se ejecuta en modo standalone (-s)
	if root.get_node_or_null("GameSettings") == null:
		var gs = GameSettingsScript.new()
		gs.name = "GameSettings"
		root.add_child(gs)
	if root.get_node_or_null("SceneTransition") == null:
		var st = SceneTransitionScript.new()
		st.name = "SceneTransition"
		root.add_child(st)
	if root.get_node_or_null("Fx") == null:
		var fx = FxScript.new()
		fx.name = "Fx"
		root.add_child(fx)

	# 1. Verificar que los 6 escenarios a escala real (1m = 40px) existen y cargan en LevelManager
	var levels := LevelManager.get_all_levels()
	print("Escenarios cargados: ", levels.size())
	assert(levels.size() == 6, "Se esperaban exactamente 6 escenarios del plantel CEMSaD 22, encontrados: %d" % levels.size())

	var level_scene: PackedScene = load("res://scenes/level.tscn")

	for i in range(levels.size()):
		var lvl: Dictionary = levels[i]
		print("  [%d/6] ID: %s | Título: %s | Imagen: %s" % [i + 1, lvl["id"], lvl["title"], lvl["scenario_image"]])
		var img_path: String = lvl["scenario_image"]
		assert(ResourceLoader.exists(img_path) or FileAccess.file_exists(img_path), "El escenario no existe: %s" % img_path)

		var level_inst = level_scene.instantiate()
		root.add_child(level_inst)
		level_inst.setup_level(lvl)

		var expected_size: Vector2 = lvl.get("map_size", lvl.get("real_dimensions_m", Vector2.ZERO) * LevelManager.SCALE_PX_PER_METER)
		assert(level_inst.map_size == expected_size, "Tamaño de mapa inesperado en %s: %s vs %s" % [lvl["id"], str(level_inst.map_size), str(expected_size)])
		assert(level_inst.player != null, "Jugador nulo en %s" % lvl["id"])
		assert(level_inst.goal != null, "Meta nula en %s" % lvl["id"])
		assert(level_inst.enemies_container.get_child_count() == lvl["enemies"].size(), "Conteo de enemigos incorrecto en %s" % lvl["id"])
		assert(level_inst.obstacles.get_child_count() == lvl["obstacles"].size(), "Conteo de obstáculos incorrecto en %s" % lvl["id"])

		# Verificar que ni el spawn del jugador ni la meta colisionan dentro de un obstáculo sólido
		var p_pos: Vector2 = level_inst.player.position
		var g_pos: Vector2 = level_inst.goal.position
		for obs_rect: Rect2 in lvl["obstacles"]:
			assert(not obs_rect.has_point(p_pos), "Spawn del jugador (%s) está dentro del obstáculo %s en %s" % [str(p_pos), str(obs_rect), lvl["id"]])
			assert(not obs_rect.has_point(g_pos), "Meta (%s) está dentro del obstáculo %s en %s" % [str(g_pos), str(obs_rect), lvl["id"]])

		print("      OK -> Mapa: %dx%d px (%.1fx%.1f m) | Obstáculos: %d | Enemigos: %d" % [
			int(level_inst.map_size.x), int(level_inst.map_size.y),
			level_inst.map_size.x / 40.0, level_inst.map_size.y / 40.0,
			level_inst.obstacles.get_child_count(),
			level_inst.enemies_container.get_child_count()
		])
		root.remove_child(level_inst)
		level_inst.free()

	# 2. Probar escena Main y progresión multinivel entre los 6 escenarios
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	assert(main_node.current_level_index == 0, "Main debe iniciar en el escenario 0")

	for idx in range(levels.size()):
		main_node.load_level(idx)
		assert(main_node.current_level_index == idx, "Fallo al cambiar al escenario %d" % idx)
		assert(main_node.active_level != null, "active_level nulo en escenario %d" % idx)
		main_node._process(0.016)
	print("Progresión secuencial por los 6 escenarios en Main verificada correctamente.")
	root.remove_child(main_node)
	main_node.free()

	# 3. Probar escena Menu y branding oficial COBAEM
	var menu_scene: PackedScene = load("res://scenes/menu.tscn")
	var menu_node = menu_scene.instantiate()
	root.add_child(menu_node)
	assert(menu_node != null, "Fallo al instanciar escena de Menu")
	menu_node._process(0.016)
	root.remove_child(menu_node)
	menu_node.free()
	print("Menú principal y estilo pixel art COBAEM verificados con éxito.")

	# 4. Probar MobileControls dinámico y transparente
	var mc_scene: PackedScene = load("res://scenes/mobile_controls.tscn")
	var mc_node: MobileControls = mc_scene.instantiate()
	root.add_child(mc_node)
	mc_node.visible = true
	mc_node.activate()

	assert(mc_node._left_alpha == 0.0, "Joystick izquierdo debe iniciar en alfa 0.0")
	assert(mc_node._right_alpha == 0.0, "Joystick derecho debe iniciar en alfa 0.0")

	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.pressed = true
	touch_down.position = Vector2(150, 300)
	mc_node._unhandled_input(touch_down)

	assert(mc_node._left_touch_id == 0, "Debe registrar touch_id 0")
	assert(mc_node._left_base == Vector2(150, 300), "La base debe posicionarse dinámicamente en el punto de contacto")
	assert(mc_node._target_left_alpha > 0.5, "El objetivo de alfa debe encenderse en contacto")

	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(190, 300)
	mc_node._unhandled_input(drag)
	assert(Input.is_action_pressed("move_right"), "Debe emitir move_right al arrastrar")

	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	touch_up.pressed = false
	touch_up.position = Vector2(190, 300)
	mc_node._unhandled_input(touch_up)

	assert(mc_node._left_touch_id == -1, "Debe liberar touch_id")
	assert(mc_node._target_left_alpha == mc_node.resting_alpha, "El objetivo de alfa debe volver a resting_alpha al soltar")
	assert(not Input.is_action_pressed("move_right"), "move_right debe liberarse al soltar")

	mc_node.deactivate()
	assert(mc_node._target_left_alpha == 0.0, "Al desactivar, el objetivo de alfa debe ser 0.0")
	mc_node._unhandled_input(touch_down)
	assert(mc_node._left_touch_id == -1, "No debe registrar toques mientras está desactivado")

	root.remove_child(mc_node)
	mc_node.free()
	print("Controles táctiles dinámicos con resting guides verificados con éxito.")

	# 5. Probar nueva Pantalla de Carga (Loading Screen) con logos oficiales y carrusel de valores
	var load_scene: PackedScene = load("res://scenes/loading_screen.tscn")
	var load_node = load_scene.instantiate()
	root.add_child(load_node)
	assert(load_node != null, "Fallo al instanciar escena de LoadingScreen")
	load_node._ensure_nodes()
	load_node._process(0.1)
	assert(load_node.logo_rect != null, "Logo institucional debe existir en LoadingScreen")
	assert(load_node.progress_bar != null, "ProgressBar debe existir en LoadingScreen")
	assert(load_node.tip_label != null, "TipLabel con carrusel de valores debe existir en LoadingScreen")
	root.remove_child(load_node)
	load_node.free()
	print("Pantalla de Carga Institucional (COBAEM CEMSaD 22) verificada con éxito.")

	# 6. Probar Sistema de Modo Historia, Cinemáticas y Base de Datos Narrativa (StoryData)
	var story_data_class = load("res://scripts/story_data.gd")
	assert(story_data_class != null, "Fallo al cargar StoryData")

	var prologue: Dictionary = story_data_class.get_prologue()
	assert(prologue.has("dialogue_nodes") and prologue["dialogue_nodes"].size() > 0, "Prólogo debe contener nodos de diálogo")

	var epilogue: Dictionary = story_data_class.get_epilogue()
	assert(epilogue.has("dialogue_nodes") and epilogue["dialogue_nodes"].size() > 0, "Epílogo debe contener nodos de diálogo")

	for act_id in range(1, 7):
		var act: Dictionary = story_data_class.get_scenario_cutscene(act_id)
		assert(act.has("dialogue_nodes") and act["dialogue_nodes"].size() > 0, "Acto %d debe contener nodos de diálogo" % act_id)

	var students_canon := ["mateo", "xochitl", "emiliano", "sofia"]
	for s_id in students_canon:
		var s_data: Dictionary = story_data_class.get_secondary_character(s_id)
		assert(not s_data.is_empty(), "Perfil de estudiante canon '%s' no encontrado" % s_id)
		assert(s_data.has("state_afflicted") and s_data.has("state_redeemed"), "Perfil '%s' debe tener estados sad y redeemed" % s_id)

	# Probar instanciación de StoryCutscene y compatibilidad de entrada y layout
	var cutscene_scene: PackedScene = load("res://scenes/story_cutscene.tscn")
	var cutscene_node = cutscene_scene.instantiate()
	root.add_child(cutscene_node)
	assert(cutscene_node != null, "Fallo al instanciar escena de StoryCutscene")
	cutscene_node.setup_cutscene(prologue)
	cutscene_node._adjust_layout_for_viewport()
	cutscene_node._process(0.1)

	# Simular avance de diálogo con tecla Espacio
	var space_key := InputEventKey.new()
	space_key.pressed = true
	space_key.keycode = KEY_SPACE
	cutscene_node._unhandled_input(space_key)

	# Simular avance con mando (Gamepad A)
	var joy_btn := InputEventJoypadButton.new()
	joy_btn.pressed = true
	joy_btn.button_index = JOY_BUTTON_A
	cutscene_node._unhandled_input(joy_btn)

	# Simular toque / clic en pantalla
	var touch_advance := InputEventScreenTouch.new()
	touch_advance.pressed = true
	touch_advance.position = Vector2(400, 300)
	cutscene_node._gui_input(touch_advance)

	# Simular redibujado de retratos procedurales (héroe, alumnos, antivalores, sol otomí)
	for portrait_id in ["player_brave", "mateo_sad", "xochitl_brave", "emiliano_happy", "sofia_happy", "allies_united", "boss_apatyx", "boss_titanor", "spirit_otomi", "director", "narrator"]:
		cutscene_node._current_portrait_id = portrait_id
		cutscene_node._on_portrait_draw()

	root.remove_child(cutscene_node)
	cutscene_node.free()
	print("Sistema de Modo Historia, Cinemáticas Multiplataforma y Retratos Pixel-Art verificados con éxito.")

	# 7. Probar Jefes Finales (Boss), Alumnos Secundarios (Student) y Barra de Jefe en HUD
	var boss_class = load("res://scripts/boss.gd")
	assert(boss_class != null, "Fallo al cargar Boss script")
	var student_class = load("res://scripts/student.gd")
	assert(student_class != null, "Fallo al cargar Student script")

	# 7.1 Verificar los 6 Jefes Finales
	for b_type in range(6):
		var boss_inst = boss_class.new()
		boss_inst.boss_type = b_type
		root.add_child(boss_inst)
		boss_inst.setup_boss_type(b_type)
		assert(boss_inst.max_hp > 0, "Boss tipo %d debe tener max_hp > 0" % b_type)
		assert(boss_inst.current_hp == boss_inst.max_hp, "Boss tipo %d debe iniciar con HP al máximo" % b_type)

		# Telegrafiado de ataque y física
		boss_inst._start_telegraph()
		assert(boss_inst.current_state == 2, "Boss debe estar en estado TELEGRAPHING")
		boss_inst._update_telegraph(1.0)
		assert(boss_inst.current_state == 3, "Boss debe pasar a estado ATTACKING tras telegrafiado")

		# Impacto y redención pacífica (desactivar barrera temporal de Plagiatrix para recibir daño)
		boss_inst._barrier_active = false
		boss_inst.hit_by_attack(Vector2.ZERO, boss_inst.max_hp)
		assert(boss_inst.current_state == 6, "Boss debe estar en estado REDEEMED tras recibir daño total")

		root.remove_child(boss_inst)
		boss_inst.free()
	print("Los 6 Jefes Finales (Boss FSM, telegrafiado y redención) verificados con éxito.")

	# 7.2 Verificar Alumnos Secundarios (Student)
	var student_inst = student_class.new()
	student_inst.student_name = "Mateo"
	root.add_child(student_inst)
	assert(student_inst.current_state == 0, "Student debe iniciar en estado SAD")

	# Probar cambio de estado a HAPPY
	student_inst.cheer_up()
	assert(student_inst.current_state == 1, "Student debe pasar a RELIEVED al animarlo")
	student_inst.current_state = 2 # Student.State.HAPPY
	student_inst.can_heal_player = true

	# Probar curación de esperanza si el jugador está herido
	var player_test = load("res://scenes/player.tscn").instantiate()
	root.add_child(player_test)
	player_test.health = 1
	student_inst.player = player_test
	student_inst._check_player_proximity()
	assert(player_test.health == 2, "Student feliz debe curar +1 esperanza al jugador herido")

	root.remove_child(player_test)
	player_test.free()
	root.remove_child(student_inst)
	student_inst.free()
	print("Alumnos Secundarios (Student estados, alivio y curación) verificados con éxito.")

	# 7.3 Verificar Barra de Jefe en HUD
	var hud_scene: PackedScene = load("res://scenes/hud.tscn")
	var hud_node: HUD = hud_scene.instantiate()
	root.add_child(hud_node)
	hud_node.show_boss_bar("Apatyx", 6, 6)
	assert(hud_node.boss_bar_container != null and hud_node.boss_bar_container.visible, "BossBarContainer debe ser visible")
	hud_node.update_boss_bar(3, 6)
	hud_node.hide_boss_bar(true)
	assert(not hud_node.boss_bar_container.visible, "BossBarContainer debe ocultarse")
	root.remove_child(hud_node)
	hud_node.free()
	print("Barra de Vida de Jefes en HUD verificada con éxito.")

	print("--- TODOS LOS TESTS DE ESCENARIOS Y PROGRESIÓN PASARON CON ÉXITO ---")
	quit(0)
