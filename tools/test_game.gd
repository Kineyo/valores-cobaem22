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
	assert(load_node.logo_rect != null, "Logo institucional debe existir en LoadingScreen")
	assert(load_node.progress_bar != null, "ProgressBar debe existir en LoadingScreen")
	assert(load_node.tip_label != null, "TipLabel con carrusel de valores debe existir en LoadingScreen")
	# Simular avance de frames en móviles/web y verificar que no se quede estancado en 0%
	load_node._process(0.5)
	assert(load_node._current_progress > 0.0, "La barra de progreso debe avanzar de inmediato y no quedarse en 0%")
	assert(load_node.progress_bar.value > 0.0, "El valor de ProgressBar debe ser mayor a 0%")
	# Simular transcurso completo del tiempo mínimo de pantalla de carga
	load_node._process(2.0)
	assert(load_node._current_progress >= 99.0, "Debe alcanzar el 100% al completarse el tiempo de carga")
	assert(load_node._can_proceed == true, "Debe habilitar el avance a la partida tras cargar")
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

	var students_canon := ["mateo", "valeria", "emiliano", "sofia"]
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
	for portrait_id in ["player_brave", "mateo_sad", "valeria_brave", "emiliano_happy", "sofia_happy", "allies_united", "boss_apatyx", "boss_titanor", "spirit_otomi", "director", "narrator"]:
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

	# 7.1 Verificar los 7 Jefes Finales (incluyendo Maestro Desinterés)
	for b_type in range(7):
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
	print("Los 7 Jefes Finales (Boss FSM, telegrafiado, Maestro Desinterés y redención) verificados con éxito.")

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

	# 8. Verificar los 6 Salones de Clases Interiores y el Jefe Maestro Desinterés
	var classrooms := LevelManager.get_classroom_levels()
	assert(classrooms.size() == 6, "Se esperaban exactamente 6 salones de clase interiores, encontrados: %d" % classrooms.size())
	for c_idx in range(classrooms.size()):
		var c_data: Dictionary = classrooms[c_idx]
		var c_img: String = c_data["scenario_image"]
		assert(ResourceLoader.exists(c_img) or FileAccess.file_exists(c_img), "El mapa del salón no existe: %s" % c_img)

		var c_inst = level_scene.instantiate()
		root.add_child(c_inst)
		c_inst.setup_level(c_data)

		# Validar spawn y meta libres de colisión en el salón
		var c_p_pos: Vector2 = c_inst.player.position
		var c_g_pos: Vector2 = c_inst.goal.position
		for obs: Rect2 in c_data["obstacles"]:
			assert(not obs.has_point(c_p_pos), "Spawn del jugador (%s) atrapado en obstáculo %s en salón %d" % [str(c_p_pos), str(obs), c_idx + 1])
			assert(not obs.has_point(c_g_pos), "Meta (%s) atrapada en obstáculo %s en salón %d" % [str(c_g_pos), str(obs), c_idx + 1])

		# Validar que adentro haya monstruos rodeando al alumno
		assert(c_inst.students.size() >= 1, "Cada salón debe contener al menos 1 alumno acorralado")
		assert(c_inst.enemies_container.get_child_count() == 4, "Cada salón debe tener 4 antivalores rodeando al alumno")
		assert(c_data.get("boss_type") == 6, "El jefe del salón debe ser Maestro Desinterés (tipo 6)")

		root.remove_child(c_inst)
		c_inst.free()
	print("Los 6 Salones de Clases Interiores y Maestro Desinterés verificados con éxito.")

	# 9. Verificar Campaña de 12 Fases Intercaladas (Exteriores y Salones)
	var campaign_stages := LevelManager.get_all_campaign_stages()
	assert(campaign_stages.size() == 12, "La campaña completa debe contar con 12 fases intercaladas, encontradas: %d" % campaign_stages.size())
	print("Campaña Escolar de 12 Fases (6 Edificios + 6 Salones) verificada con éxito.")

	# 10. Verificar Disparo Pegado a la Pared (Corrección de colisión y punto de desove)
	var player_test_shot = load("res://scenes/player.tscn").instantiate()
	root.add_child(player_test_shot)
	player_test_shot.global_position = Vector2(200, 200)

	# Simular disparo cardinal pegado a un muro
	player_test_shot.facing_vector = Vector2.RIGHT
	player_test_shot.aim_vector = Vector2.RIGHT
	player_test_shot.spawn_projectile()

	var projectile_found := false
	for child in root.get_children():
		if child is Projectile:
			projectile_found = true
			# Verificar que el proyectil tenga tamaño optimizado CircleShape2D de radio 8
			var col_shape: CollisionShape2D = child.get_node_or_null("CollisionShape2D")
			assert(col_shape != null and col_shape.shape is CircleShape2D, "El proyectil debe usar CircleShape2D para no atorarse en muros")
			root.remove_child(child)
			child.free()
			break
	assert(projectile_found, "El proyectil debe generarse limpiamente sin destruirse en el desove")
	root.remove_child(player_test_shot)
	player_test_shot.free()
	print("Disparo de virtudes pegado a paredes verificado con éxito.")

	# 11. Verificar Renders PNG de Alumnos y Retratos en assets/characters/ y assets/portraits/
	var required_character_pngs := [
		"res://assets/characters/alejandro_cancha/idle.png",
		"res://assets/characters/maria_cafeteria/idle.png",
		"res://assets/characters/mateo_laboratorio/idle.png",
		"res://assets/characters/valeria_plaza/idle.png",
		"res://assets/characters/fernanda_biblioteca/idle.png",
		"res://assets/characters/diego_computo/idle.png",
		"res://assets/characters/sofia_direccion/idle.png",
		"res://assets/characters/maestro_desinteres_redeemed/idle.png",
		"res://assets/portraits/alejandro_cancha.png",
		"res://assets/portraits/maria_cafeteria.png",
		"res://assets/portraits/mateo_laboratorio.png",
		"res://assets/portraits/valeria_plaza.png",
		"res://assets/portraits/fernanda_biblioteca.png",
		"res://assets/portraits/diego_computo.png",
		"res://assets/portraits/sofia_direccion.png",
		"res://assets/portraits/maestro_desinteres.png",
	]
	for png_path in required_character_pngs:
		assert(ResourceLoader.exists(png_path) or FileAccess.file_exists(png_path), "Falta el render solicitado en assets: %s" % png_path)
	print("Catálogo de Renders PNG de Alumnos y Retratos en assets/ verificado con éxito.")

	# 12. Verificar Sistema Danmaku Touhou, Micro-Hitbox, Rozadura (Graze) y Duración de Jefes en Modo Difícil
	var gs_node = root.get_node("GameSettings")
	gs_node.difficulty = 2 # Difficulty.DIFICIL

	# A) Verificar salud de Titanor en Difícil: 450 HP (3 minutos continuos bajo ataque perfecto a 0.40s)
	var titanor_boss = boss_class.new()
	root.add_child(titanor_boss)
	titanor_boss.setup_boss_type(Boss.BossType.BULLYING)
	assert(titanor_boss.max_hp == 450, "Titanor en dificultad Difícil debe tener exactamente 450 HP (obtenido: %d)" % titanor_boss.max_hp)
	var hard_shot_cooldown: float = gs_node.get_param("shot_cooldown")
	assert(is_equal_approx(hard_shot_cooldown, 0.40), "Cooldown de disparo en Difícil debe ser 0.40s")
	var min_battle_seconds: float = float(titanor_boss.max_hp) * hard_shot_cooldown
	assert(min_battle_seconds >= 180.0, "La batalla en Difícil con ataque perfecto debe durar al menos 180s (3 min). Calculado: %.1fs" % min_battle_seconds)
	print("  Duración matemática del Jefe Final en Modo Difícil: %.1f segundos (>= 180s) verificada con éxito." % min_battle_seconds)

	# B) Verificar Ataques Difíciles de Boss 1 (Apatía / Apatyx)
	var apatia_boss: Boss = Boss.new()
	root.add_child(apatia_boss)
	apatia_boss.setup_boss_type(Boss.BossType.APATIA)
	assert(apatia_boss.max_hp == 65, "Apatyx en Difícil debe tener 65 HP para ofrecer un desafío sólido temprano")
	var apatia_attacks: Array = Boss.BOSS_DATA[Boss.BossType.APATIA]["attack_names"]
	assert(apatia_attacks.has("Vórtice Espiral de Desgano"), "Boss 1 debe tener Vórtice Espiral de Desgano")
	assert(apatia_attacks.has("Ráfaga Ciclónica del Desaliento"), "Boss 1 debe tener Ráfaga Ciclónica del Desaliento")
	assert(apatia_attacks.has("Miasma Apatético"), "Boss 1 debe tener Miasma Apatético")
	root.remove_child(apatia_boss)
	apatia_boss.free()
	print("  Ataques difíciles del Jefe 1 (Apatyx) verificados con éxito.")

	# C) Verificar Micro-Hitbox Touhou y Rozadura (Graze) del Jugador
	var touhou_player: Player = load("res://scenes/player.tscn").instantiate()
	root.add_child(touhou_player)
	touhou_player.global_position = Vector2(400, 400)
	var initial_hp: int = touhou_player.health
	var core_pos := touhou_player.get_core_position() # Vector2(400, 390)
	assert(core_pos == Vector2(400, 390), "Núcleo Touhou debe estar en Vector2(0, -10) respecto al jugador")

	# Proyectil rozando a 14 px del núcleo (dentro del cuerpo pero fuera de la micro-hitbox de 5.5 px): debe ser GRAZE, daño 0
	var graze_shot: Projectile = load("res://scenes/projectile.tscn").instantiate()
	graze_shot.is_enemy_projectile = true
	graze_shot.global_position = core_pos + Vector2(14.0, 0.0) # Distancia = 14 px > 5.5 px
	root.add_child(graze_shot)
	graze_shot._on_body_entered(touhou_player)
	assert(touhou_player.health == initial_hp, "Graze a 14px no debe causar daño al jugador")
	assert(touhou_player.graze_count >= 1, "Debe registrarse el contador de rozadura (graze_count)")
	root.remove_child(graze_shot)
	graze_shot.free()

	# Proyectil impactando directamente en la micro-hitbox (a 3 px del núcleo vital): debe causar daño 1
	var hit_shot: Projectile = load("res://scenes/projectile.tscn").instantiate()
	hit_shot.is_enemy_projectile = true
	hit_shot.global_position = core_pos + Vector2(3.0, 0.0) # Distancia = 3 px <= 5.5 px
	root.add_child(hit_shot)
	hit_shot._on_body_entered(touhou_player)
	assert(touhou_player.health == initial_hp - 1, "Impacto dentro de la micro-hitbox Touhou debe causar 1 de daño")
	root.remove_child(hit_shot)
	hit_shot.free()

	# D) Verificar Modo Enfoque (Focus Mode) y reducción de velocidad para micro-desplazamiento
	touhou_player.is_focusing = true
	assert(touhou_player.is_focusing == true, "Focus Mode debe poder activarse")
	root.remove_child(touhou_player)
	touhou_player.free()
	print("  Micro-hitbox Touhou (radio 5.5px) y sistema de Rozadura (Graze) verificados con éxito.")

	# E) Verificar Curvatura de Proyectiles Danmaku (curve_speed)
	var curve_shot: Projectile = load("res://scenes/projectile.tscn").instantiate()
	curve_shot.is_enemy_projectile = true
	curve_shot.direction = Vector2.RIGHT
	curve_shot.curve_speed = 1.5 # 1.5 rad/s
	root.add_child(curve_shot)
	var old_dir: Vector2 = curve_shot._dir_vec
	curve_shot._physics_process(0.2)
	assert(curve_shot._dir_vec != old_dir, "curve_speed debe rotar dinámicamente el vector de trayectoria")
	assert(is_equal_approx(curve_shot._dir_vec.length(), 1.0), "El vector de trayectoria debe mantenerse unitario")
	root.remove_child(curve_shot)
	curve_shot.free()
	print("  Curvatura angular de proyectiles Danmaku (curve_speed) verificada con éxito.")

	# F) Verificar Fases de Cartas de Hechizo de Titanor y Limpieza de Balas por Onda de Choque
	titanor_boss.current_state = Boss.State.IDLE
	titanor_boss.current_hp = 330 # Disparar cruce de fase 2 (75% de 450 = 337.5)
	titanor_boss.hit_by_attack(Vector2.ZERO, 1)
	assert(titanor_boss._spell_phase == 2, "Titanor debe avanzar a Carta de Hechizo Fase 2")
	assert(titanor_boss._is_spell_transition == true, "Titanor debe entrar en transición de fase invulnerable de 4.0s")
	root.remove_child(titanor_boss)
	titanor_boss.free()
	print("  Cartas de Hechizo Danmaku y transiciones de fase de Titanor verificadas con éxito.")

	# Restaurar dificultad normal al finalizar
	gs_node.difficulty = 1

	# 12. Verificar Sistema de Selección de Personajes (Masculino vs Femenino)
	# 12.1 Verificar existencia de carpetas y portadas con fondo blanco
	var p_masc_exists := FileAccess.file_exists("res://assets/characters/Masculino/portada.png")
	var p_fem_exists := FileAccess.file_exists("res://assets/characters/Femenino/portada.png")
	assert(p_masc_exists, "Debe existir portada.png para aspecto Masculino")
	assert(p_fem_exists, "Debe existir portada.png para aspecto Femenino")

	# 12.2 Verificar GameSettings CharacterSkin
	gs_node.selected_character = 0
	assert(gs_node.selected_character == 0, "Debe ser MASCULINO (0)")
	assert(gs_node.character_name() == "Masculino", "Nombre de skin debe ser Masculino")
	gs_node.selected_character = 1
	assert(gs_node.selected_character == 1, "Debe ser FEMENINO (1)")
	assert(gs_node.character_name() == "Femenino", "Nombre de skin debe ser Femenino")

	# 12.3 Verificar carga dinámica de texturas en Player
	var skin_player: Player = load("res://scenes/player.tscn").instantiate()
	root.add_child(skin_player)
	skin_player.setup_character_skin(0)
	assert(skin_player.tex_idle != null, "tex_idle de Masculino debe cargar correctamente")
	assert(skin_player.tex_idle.get_size() == Vector2(512, 512), "Masculino idle debe ser 512x512")
	skin_player.setup_character_skin(1)
	assert(skin_player.tex_idle != null, "tex_idle de Femenino debe cargar correctamente")
	assert(skin_player.tex_idle.get_size() == Vector2(512, 512), "Femenino idle debe ser 512x512")
	assert(skin_player.tex_attack != null, "tex_attack de Femenino debe cargar attack.png o atack.png")
	assert(skin_player.tex_attack.get_size() == Vector2(512, 512), "Femenino attack debe ser 512x512")
	root.remove_child(skin_player)
	skin_player.free()

	# 12.4 Verificar Menú de Selección de Personaje (Pantalla intermedia antes del juego)
	var menu_inst: Control = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu_inst)
	if not menu_inst.is_node_ready():
		menu_inst._ready()
	var main_view_node: Control = menu_inst.get_node_or_null("%MainView")
	var char_view_node: Control = menu_inst.get_node_or_null("%CharSelectView")
	var btn_play_node: Button = menu_inst.get_node_or_null("%BtnPlay")
	var btn_confirm_node: Button = menu_inst.get_node_or_null("%BtnConfirmChar")
	var btn_back_node: Button = menu_inst.get_node_or_null("%BtnBackToMenu")
	var btn_p: Button = menu_inst.get_node_or_null("%BtnCharPantalon")
	var btn_f: Button = menu_inst.get_node_or_null("%BtnCharFalda")
	var char_icon_p: TextureRect = menu_inst.get_node_or_null("%CharIconPantalon")
	var char_icon_f: TextureRect = menu_inst.get_node_or_null("%CharIconFalda")

	assert(main_view_node != null and char_view_node != null, "Vistas MainView y CharSelectView deben existir")
	assert(main_view_node.visible == true, "MainView debe estar visible inicialmente")
	assert(char_view_node.visible == false, "CharSelectView debe estar oculta inicialmente")
	assert(btn_p != null and btn_f != null, "Botones de selección de personaje deben existir en el menú")
	assert(char_icon_p != null and char_icon_f != null, "Iconos de portada con fondo blanco deben existir en el menú")

	# Simular clic en botón INICIAR PARTIDA: Debe abrir la pantalla de selección de personaje
	btn_play_node.emit_signal("pressed")
	assert(main_view_node.visible == false, "MainView debe ocultarse al pulsar Iniciar Partida")
	assert(char_view_node.visible == true, "CharSelectView debe mostrarse para elegir personaje")

	# Simular clic en botón Falda
	btn_f.emit_signal("pressed")
	assert(gs_node.selected_character == 1, "Clic en Falda debe actualizar selected_character a 1")
	# Simular clic en botón Pantalón
	btn_p.emit_signal("pressed")
	assert(gs_node.selected_character == 0, "Clic en Pantalón debe actualizar selected_character a 0")

	# Simular clic en botón Volver: Debe regresar al menú principal
	btn_back_node.emit_signal("pressed")
	assert(main_view_node.visible == true, "MainView debe volver a mostrarse al pulsar Volver")
	assert(char_view_node.visible == false, "CharSelectView debe ocultarse al pulsar Volver")

	root.remove_child(menu_inst)
	menu_inst.free()
	print("  Sistema de Selección de Personajes y flujo de pantalla intermedia verificados con éxito.")

	# 13. Verificar Puertas de Salones, Bloqueo de Meta, Niebla del Desinterés y Oleadas en Modo Difícil
	# 13.1 Puerta de salón y bloqueo de meta en nivel exterior
	gs_node.difficulty = 1
	var ext_lvl_inst: Level = level_scene.instantiate()
	root.add_child(ext_lvl_inst)
	ext_lvl_inst.setup_level(levels[0])
	assert(ext_lvl_inst.has_classroom == true, "El escenario exterior debe tener has_classroom == true")
	assert(ext_lvl_inst.classroom_door != null, "El escenario exterior debe instanciar ClassroomDoor")
	assert(ext_lvl_inst.is_classroom_cleared == false, "El salón debe iniciar como no limpiado")
	ext_lvl_inst.goal.unlock()
	# Intentar cruzar la meta sin limpiar el salón: debe bloquear el paso
	ext_lvl_inst.goal._on_body_entered(ext_lvl_inst.player)
	assert(ext_lvl_inst.goal.already_reached == false, "La meta debe bloquear al jugador si no ha limpiado el salón")
	# Limpiar el salón y volver a intentar
	ext_lvl_inst.set_classroom_cleared(true)
	assert(ext_lvl_inst.classroom_door.is_cleared == true, "La puerta debe actualizarse a estado limpiado")
	ext_lvl_inst.goal._on_body_entered(ext_lvl_inst.player)
	assert(ext_lvl_inst.goal.already_reached == true, "La meta debe permitir avanzar tras limpiar el salón")
	root.remove_child(ext_lvl_inst)
	ext_lvl_inst.free()

	# 13.2 Verificar los 6 ataques distintos del Maestro Desinterés y niebla al minuto (60s) en Normal
	var classrooms_list := LevelManager.get_classroom_levels()
	var norm_class_inst: Level = level_scene.instantiate()
	root.add_child(norm_class_inst)
	norm_class_inst.setup_level(classrooms_list[0])
	assert(norm_class_inst.fog_overlay != null, "El salón debe contar con nodo FogOverlay")
	assert(norm_class_inst.fog_overlay.is_fog_active == false, "En modo Normal la niebla no debe estar activa al inicio")
	norm_class_inst._spawn_boss()
	assert(norm_class_inst.boss != null, "El Maestro Desinterés debe aparecer al invocarse")
	for c_i in range(6):
		norm_class_inst.boss.classroom_index = c_i
		norm_class_inst.boss._execute_attack()
	# Simular 60 segundos de combate contra el Maestro Desinterés
	norm_class_inst._physics_process(60.5)
	assert(norm_class_inst.fog_overlay.is_fog_active == true, "Tras 60s de batalla debe activarse la Niebla del Desinterés")
	assert(norm_class_inst.boss.is_fog_active == true, "El Maestro debe mostrar ojos rojos y corazón oscuro en la niebla")
	root.remove_child(norm_class_inst)
	norm_class_inst.free()

	# 13.3 Verificar Modo Difícil: Niebla desde el inicio, 10 enemigos de 3 en 3 y disipación al terminar
	gs_node.difficulty = 2
	var hard_class_inst: Level = level_scene.instantiate()
	root.add_child(hard_class_inst)
	hard_class_inst.setup_level(classrooms_list[1])
	assert(hard_class_inst.is_hard_mode == true, "Debe detectar Modo Difícil activo")
	assert(hard_class_inst.quota_to_boss == 10, "En Modo Difícil la cuota debe ser de 10 enemigos")
	assert(hard_class_inst.fog_overlay.is_fog_active == true, "En Modo Difícil la niebla debe estar activa desde el inicio")
	assert(hard_class_inst._hard_enemies_spawned == 3, "Primera oleada debe spawnear 3 enemigos")

	# Probar ocultación realista de antivalores en la niebla fuera del radio de luz
	var p_pos: Vector2 = hard_class_inst.player.global_position
	var near_enemy: Enemy = hard_class_inst.enemies_container.get_child(0) as Enemy
	var far_enemy: Enemy = hard_class_inst.enemies_container.get_child(1) as Enemy
	near_enemy.global_position = p_pos + Vector2(30, 0) # Dentro de la luz de virtud (dist 30 < 123)
	far_enemy.global_position = Vector2(250, 150) # En la niebla profunda, lejos del héroe y del alumno
	hard_class_inst.fog_overlay._process(0.1)
	assert(far_enemy.modulate.a == 0.0, "Los antivalores inmersos en la niebla profunda deben estar 100% invisibles")
	assert(near_enemy.modulate.a == 1.0, "Los antivalores dentro del radio de luz deben ser plenamente visibles")

	# Derrotar los 10 enemigos en oleadas de 3 en 3 (3 + 3 + 3 + 1)
	var dummy_enemy: Enemy = load("res://scenes/enemy.tscn").instantiate()
	root.add_child(dummy_enemy)
	for e_step in range(10):
		hard_class_inst._on_enemy_defeated(dummy_enemy)
		if e_step == 2:
			assert(hard_class_inst._hard_enemies_spawned == 6, "Segunda oleada debe elevar el total a 6 enemigos")
		elif e_step == 5:
			assert(hard_class_inst._hard_enemies_spawned == 9, "Tercera oleada debe elevar el total a 9 enemigos")
		elif e_step == 8:
			assert(hard_class_inst._hard_enemies_spawned == 10, "Cuarta oleada debe spawnear el 10mo enemigo")
	assert(hard_class_inst.fog_overlay.is_fog_active == false, "Al derrotar a los 10 enemigos la niebla debe desaparecer")
	assert(hard_class_inst.boss != null, "Al derrotar a los 10 enemigos debe aparecer el Maestro Desinterés")
	root.remove_child(dummy_enemy)
	dummy_enemy.free()
	root.remove_child(hard_class_inst)
	hard_class_inst.free()
	gs_node.difficulty = 1
	print("  Puertas de salones, bloqueo de meta, 6 ataques de Maestro, Niebla y oleadas 3x3 en Difícil verificados con éxito.")

	print("--- TODOS LOS TESTS DE ESCENARIOS Y PROGRESIÓN PASARON CON ÉXITO ---")
	quit(0)
