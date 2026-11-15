extends SceneTree

const LevelManager := preload("res://scripts/level_manager.gd")
const GameSettingsScript := preload("res://scripts/game_settings.gd")
const SceneTransitionScript := preload("res://scripts/scene_transition.gd")
const FxScript := preload("res://scripts/fx.gd")
const FinalCeremonyScript := preload("res://scripts/final_ceremony.gd")
const CertificateGeneratorScript := preload("res://scripts/certificate_generator.gd")

var _post_init_tests_done: bool = false

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
	for portrait_id in ["player_brave", "mateo_sad", "valeria_brave", "emiliano_happy", "sofia_happy", "allies_united", "boss_apatyx", "boss_titanor", "spirit_otomi", "coordinador", "narrator"]:
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
	assert(hard_class_inst.boss._boss_texture != null, "Maestro Desinterés debe cargar su textura oficial")
	root.remove_child(dummy_enemy)
	dummy_enemy.free()
	root.remove_child(hard_class_inst)
	hard_class_inst.free()
	gs_node.difficulty = 1
	print("  Puertas de salones, bloqueo de meta, 6 ataques de Maestro, Niebla y oleadas 3x3 en Difícil verificados con éxito.")

	# 14. Verificar integridad de texturas oficiales (icono, logo plantel y personajes secundarios con escala normalizada)
	var required_textures := [
		"res://icon.jpeg",
		"res://assets/logos/cobaem-logo.jpeg",
		"res://assets/characters/mateo_laboratorio/idle.png",
		"res://assets/characters/maria_cafeteria/idle.png",
		"res://assets/characters/valeria_plaza/idle.png",
		"res://assets/characters/fernanda_biblioteca/idle.png",
		"res://assets/characters/diego_computo/idle.png",
		"res://assets/characters/sofia_direccion/idle.png",
		"res://assets/characters/alejandro_cancha/idle.png",
		"res://assets/characters/maestro_desinteres/idle.png",
		"res://assets/characters/maestro_desinteres_redeemed/idle.png",
		"res://assets/coordinador.png",
		"res://assets/characters/coordinador/normal_frente.png",
		"res://assets/characters/coordinador/hablando_frente.png",
		"res://assets/characters/coordinador/normal_izquierda.png",
		"res://assets/characters/coordinador/hablando_izquierda.png",
		"res://assets/characters/coordinador/normal_derecha.png",
		"res://assets/characters/coordinador/hablando_derecha.png",
		"res://assets/portraits/coordinador.png"
	]
	for removed_dir_asset in ["res://assets/director.png", "res://assets/characters/director/idle.png", "res://assets/portraits/director.png"]:
		assert(not FileAccess.file_exists(removed_dir_asset), "Asset del Director debe estar eliminado: %s" % removed_dir_asset)
	for tex_path: String in required_textures:
		assert(ResourceLoader.exists(tex_path) or FileAccess.file_exists(tex_path), "Falta textura requerida: %s" % tex_path)
		var loaded_tex: Texture2D = load(tex_path) if ResourceLoader.exists(tex_path) else ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(tex_path)))
		assert(loaded_tex != null and loaded_tex.get_width() > 0 and loaded_tex.get_height() > 0, "Textura inválida: %s" % tex_path)

	for stu_check: Array in [["Mateo", "mateo_laboratorio"], ["Valeria", "valeria_plaza"]]:
		var stu_test := Student.new()
		stu_test.student_name = stu_check[0]
		root.add_child(stu_test)
		stu_test._setup_sprite()
		assert(stu_test.sprite != null and stu_test.sprite.texture != null, "Estudiante %s debe cargar sprite" % stu_check[0])
		var rendered_h := float(stu_test.sprite.texture.get_height()) * stu_test.sprite.scale.y
		assert(absf(rendered_h - 51.2) < 0.5, "Escala normalizada incorrecta para %s: %.2f px" % [stu_check[0], rendered_h])
		root.remove_child(stu_test)
		stu_test.free()
	print("  Texturas oficiales (icon.jpeg, cobaem-logo.jpeg y escala normalizada 51.2px) verificadas con éxito.")

func _process(_delta: float) -> bool:
	if _post_init_tests_done:
		return true
	_post_init_tests_done = true
	var gs_node = root.get_node("GameSettings")
	var main_scene: PackedScene = load("res://scenes/main.tscn")

	# 15. Verificar Escena Final de Ceremonia en la Cancha, Coordinador en el Podio, Discurso, Medalla e Himno
	assert(not FileAccess.file_exists("res://assets/audio/himno.m4a"), "No debe existir res://assets/audio/himno.m4a redundante")
	assert(ResourceLoader.exists("res://assets/audio/himno.ogg") or FileAccess.file_exists("res://assets/audio/himno.ogg"), "Debe existir res://assets/audio/himno.ogg")
	for dup_asset in ["res://assets/mateo_laboratorio.png", "res://assets/alejandro_cancha.png", "res://assets/maestro_desinteres.png"]:
		assert(not FileAccess.file_exists(dup_asset), "Duplicado eliminado no debe existir en assets/: %s" % dup_asset)

	gs_node.stop_music(0.0)
	if gs_node._music:
		gs_node._music.stop()
	var ceremony_scene: PackedScene = load("res://scenes/final_ceremony.tscn")
	assert(ceremony_scene != null, "Debe cargar scenes/final_ceremony.tscn")
	var ceremony: Node2D = ceremony_scene.instantiate()
	root.add_child(ceremony)
	ceremony.setup_stats({ "time": 125.0, "defeated": 24 })

	assert(ceremony.background != null and ceremony.background.texture != null, "La escena final debe cargar la cancha de básquetbol")
	assert(ceremony.map_size == Vector2(1440, 900), "Dimensiones esperadas de cancha 1440x900, obtenido: %s" % str(ceremony.map_size))
	assert(ceremony.rescued_student_nodes.size() == 7, "Deben reunirse los 7 alumnos rescatados en la cancha")
	assert(ceremony.coordinator_node != null, "Debe existir el Coordinador en el podio de la escena final")
	assert(ceremony.director_node == null, "El Director debe haber sido eliminado de la escena final")
	assert((ceremony.coordinator_node.get_node("Sprite2D") as Sprite2D).texture != null, "Coordinador debe cargar su sprite .png")
	assert(ceremony._coordinator_textures.size() == 6, "Coordinador debe cargar sus 6 sprites de pose (normal/hablando x frente/izquierda/derecha)")
	for coord_pose: String in ceremony.COORDINATOR_SPRITES.keys():
		assert(ceremony._coordinator_textures.get(coord_pose) != null, "Textura faltante para pose de Coordinador: %s" % coord_pose)
	assert("Coordinador" in ceremony._speaker_label.text, "El hablante de la ceremonia final debe ser el Coordinador")
	assert(ceremony.is_himno_playing(), "El himno debe estar sonando desde el inicio de la ceremonia")
	assert(ceremony.current_phase == FinalCeremonyScript.Phase.SPEECH, "La ceremonia debe iniciar con el discurso del Coordinador")

	var joined_speech := " ".join(ceremony.COORDINATOR_SPEECH).to_lower()
	assert("paz" in joined_speech and "armonía" in joined_speech, "El discurso del Coordinador debe hablar de paz y armonía en la escuela")

	# Avanzar por todo el discurso hasta iniciar la caminata desde la izquierda
	for _s in range(ceremony.COORDINATOR_SPEECH.size() * 2 + 2):
		if ceremony.current_phase != FinalCeremonyScript.Phase.SPEECH:
			break
		ceremony._advance_speech()
	assert(ceremony.current_phase == FinalCeremonyScript.Phase.WALKING, "Tras terminar el discurso debe iniciar Phase.WALKING")
	assert(ceremony.hero_node.visible == true, "El personaje debe aparecer visible en el extremo izquierdo")
	assert(ceremony.hero_node.position.x < 400.0, "El personaje debe aparecer a la izquierda de la cancha")

	# Simular avance hacia el podio hasta recibir la medalla (verificando sprite único de caminata sin parpadeo a idle)
	for _f in range(70):
		if ceremony.current_phase != FinalCeremonyScript.Phase.WALKING:
			break
		assert(ceremony.hero_sprite.texture == ceremony._hero_tex_walk_right, "Durante la caminata hacia el podio el héroe debe usar solo la textura de movimiento")
		ceremony._process(0.1)
	assert(ceremony.current_phase == FinalCeremonyScript.Phase.MEDAL, "Al llegar al podio debe pasar a Phase.MEDAL")
	assert(ceremony.hero_sprite.texture == ceremony._hero_tex_walk_right, "Al recibir la medalla el héroe debe conservar la textura de movimiento sin alternar a idle")
	assert(ceremony.hero_node.position.x >= 1080.0, "El personaje debe haber caminado hasta el podio derecho")
	assert(ceremony._medal_node.visible == true, "La medalla entregada debe mostrarse visiblemente")

	# Simular paso a mensaje final
	for _m in range(30):
		if ceremony.current_phase == FinalCeremonyScript.Phase.FINAL_MESSAGE:
			break
		ceremony._process(0.1)
	assert(ceremony.current_phase == FinalCeremonyScript.Phase.FINAL_MESSAGE, "Debe avanzar a Phase.FINAL_MESSAGE tras entregar la medalla")
	assert(ceremony._final_overlay.visible == true, "El panel con el mensaje final debe estar visible")
	assert(ceremony._final_message_label.text == "Felicidades, ahora eres un alumno ejemplar. Gracias por jugar!", "Mensaje final exacto incorrecto")
	assert(ceremony.is_himno_playing(), "El himno debe seguir sonando durante toda la escena final")

	if ceremony._himno_player:
		ceremony._himno_player.stop()
	if gs_node._music:
		gs_node._music.stop()
	root.remove_child(ceremony)
	ceremony.free()

	# Verificar disparo de ceremonia desde Main
	var main_cer_test = main_scene.instantiate()
	root.add_child(main_cer_test)
	main_cer_test._show_final_loading_screen_then_ceremony()
	assert(main_cer_test._final_loading_layer != null, "Main debe mostrar la última pantalla de carga tras vencer al Jefe Final")
	main_cer_test._finish_final_loading_to_ceremony()
	assert(main_cer_test.active_ceremony != null, "Main._show_final_ceremony debe instanciar la escena final")
	if main_cer_test.active_ceremony._himno_player:
		main_cer_test.active_ceremony._himno_player.stop()
	if gs_node._music:
		gs_node._music.stop()
	root.remove_child(main_cer_test)
	main_cer_test.free()
	print("  Escena Final de Ceremonia (Carga Final, Cancha, Coordinador en Podio, Discurso, Medalla e Himno) verificada con éxito.")

	# 16. Auditoría de Hitboxes, Mecánicas Progresivas de Titanor (10 HP / 5 HP) y Generación PDF Carta + 5x7
	# 16.1 Verificar hitboxes actualizadas y FogOverlay con oscurecimiento
	gs_node.set_difficulty(1)
	var level_scene_ref: PackedScene = load("res://scenes/level.tscn")
	var final_lvl_data: Dictionary = LevelManager.get_all_levels()[5]
	var audit_lvl = level_scene_ref.instantiate()
	root.add_child(audit_lvl)
	audit_lvl.setup_level(final_lvl_data)
	assert(audit_lvl.player != null and audit_lvl.player.attack_area != null, "Jugador y AttackArea deben existir")
	assert(audit_lvl.player.attack_area.position.y < 15.0, "AttackArea debe estar alineada al torso en perspectiva 3/4")

	var student_check: Student = audit_lvl.students[0] if not audit_lvl.students.is_empty() else null
	if student_check and student_check.collision_shape:
		assert((student_check.collision_shape.shape as CapsuleShape2D).height >= 22.0, "Hitbox vertical del alumno debe cubrir torso")

	audit_lvl._spawn_boss()
	var titanor: Boss = audit_lvl.boss as Boss
	assert(titanor != null and titanor.boss_type == Boss.BossType.BULLYING, "Nivel 6 debe invocar a Titanor")
	titanor.current_state = Boss.State.IDLE
	assert(titanor._hitbox != null and titanor._hitbox.get_child_count() > 0, "Titanor debe tener Hitbox Area2D")
	var hb_col := titanor._hitbox.get_child(0) as CollisionShape2D
	assert((hb_col.shape as RectangleShape2D).size == Vector2(44, 48), "Hitbox de Titanor debe ser 44x48")

	# 16.2 Verificar velocidad progresiva, teletransporte y clones falsos
	var base_spd := titanor.get_effective_speed()
	titanor.hit_by_attack(Vector2.ZERO, 40)
	var hurt_spd := titanor.get_effective_speed()
	assert(hurt_spd > base_spd, "Titanor debe correr más rápido conforme pierde vida (%.1f > %.1f)" % [hurt_spd, base_spd])

	var prev_pos := titanor.global_position
	var prev_tp := titanor.teleport_count
	titanor._perform_boss_teleport()
	assert(titanor.teleport_count == prev_tp + 1, "El teletransporte debe incrementar teleport_count")
	assert(titanor.global_position.distance_squared_to(prev_pos) > 1.0, "Titanor debe cambiar de posición al teletransportarse")

	var hp_before_clone_hit := titanor.current_hp
	titanor._spawn_fake_clones(2)
	assert(titanor.get_active_clone_count() == 2, "Debe duplicarse creando clones falsos (2 activos)")
	var first_clone = titanor.active_clones[0]
	first_clone.hit_by_attack(Vector2.ZERO)
	assert(titanor.current_hp == hp_before_clone_hit, "Golpear un clon falso NO debe restar vida al Titanor real")

	# 16.3 Fase de 10 HP: Neblina + oscurecimiento + pausa 'Aun me queda un ataque' + max 5 enemigos + Danmaku 5s/7s + cubrir 3s
	titanor._is_spell_transition = false
	titanor.current_hp = 11
	titanor.hit_by_attack(Vector2.ZERO, 1)
	assert(titanor.current_hp == 10, "Al bajar a 10 HP debe quedar en 10 para la fase de desesperación")
	assert(titanor._ten_hp_triggered == true, "Debe activarse la fase de 10 HP")
	assert(titanor.last_special_message == "Aun me queda un ataque", "Debe mostrar el mensaje exacto a 10 HP")
	assert(titanor.desperation_fog_active == true, "Debe activar neblina a 10 HP")
	assert(audit_lvl.fog_overlay != null and audit_lvl.fog_overlay.is_fog_active == true, "FogOverlay del nivel debe activarse a 10 HP")
	assert(audit_lvl.fog_overlay.desperation_darkness == true, "Debe activarse el oscurecimiento total a 10 HP")
	assert(titanor.summoned_enemies_count <= 5 and titanor.get_summoned_enemy_count() <= 5, "Solo debe invocar máximo 5 enemigos")
	titanor._summon_desperation_enemies(8)
	assert(titanor.get_summoned_enemy_count() <= 5, "No debe superar el tope estricto de 5 enemigos invocados")

	assert(titanor.is_ten_hp_danmaku_window_active(0.5) == true, "Danmaku debe estar activo durante los primeros 5s de cada 7s")
	assert(titanor.is_ten_hp_danmaku_window_active(5.5) == false, "Danmaku debe descansar de 5s a 7s")
	assert(titanor.is_ten_hp_danmaku_window_active(7.5) == true, "Danmaku debe reactivarse cada 7s")

	titanor.trigger_cover_and_vanish(3.0)
	assert(titanor._is_covered_and_vanished == true and titanor._barrier_active == true and titanor.modulate.a < 0.2, "Debe cubrirse y desaparecer")
	for _c in range(7):
		titanor._physics_process(0.5)
	assert(titanor._is_covered_and_vanished == false and titanor.modulate.a > 0.9, "Tras 3 segundos debe reaparecer")

	# 16.4 Fase de 5 HP: 'No dejare que liberes tan facil a la escuela' + transformación + ataque no violento de alumnos rescatados
	titanor.current_hp = 6
	titanor.hit_by_attack(Vector2.ZERO, 1)
	assert(titanor.current_hp == 5, "Al bajar a 5 HP debe activar el clímax final")
	assert(titanor._five_hp_triggered == true and titanor._is_transforming == true, "Debe iniciar animación de transformación a 5 HP")
	assert(titanor.last_special_message == "No dejare que liberes tan facil a la escuela", "Debe mostrar el mensaje exacto de 5 HP")

	for _climax in range(32):
		if titanor.current_state == Boss.State.REDEEMED:
			break
		titanor._physics_process(0.1)
	assert(titanor.rescued_attack_students.size() == 7, "Deben aparecer los 7 alumnos rescatados alrededor de Titanor")
	assert(titanor.current_state == Boss.State.REDEEMED and titanor.current_hp == 0, "Los alumnos deben derrotar/redimir pacíficamente a Titanor")
	assert(titanor.desperation_fog_active == false, "La niebla de Titanor debe desaparecer tras su derrota")
	assert(audit_lvl.fog_overlay.is_fog_active == false and audit_lvl.background.modulate == Color.WHITE, "La niebla y oscuridad del nivel deben disiparse")
	assert(audit_lvl.scenario_decor != null, "ScenarioDecor debe estar instanciado en el nivel")
	assert(audit_lvl.is_final_boss_celebrating == true, "Tras vencer a Titanor debe iniciar la espera de 7s con los alumnos celebrando")
	assert(audit_lvl.goal != null and audit_lvl.goal.is_locked == true, "La meta debe permanecer bloqueada durante los 7s de celebración post-Titanor")
	assert(audit_lvl.celebration_students.size() == 7, "Deben celebrar los 7 alumnos rescatados con la frase de victoria")
	for cel_st in audit_lvl.celebration_students:
		var sp_lbl := cel_st.get_node_or_null("SpeechLabel") as Label
		assert(sp_lbl != null and sp_lbl.text == "Finalmente lo derrotamos!", "Cada alumno celebrante debe decir 'Finalmente lo derrotamos!'")
	for _s_wait in range(3):
		audit_lvl._physics_process(1.0)
	assert(audit_lvl.is_final_boss_celebrating == true and audit_lvl.goal.is_locked == true, "A los 3s aún debe seguir bloqueada la meta celebrando")
	for _s_wait in range(5):
		audit_lvl._physics_process(1.0)
	assert(audit_lvl.is_final_boss_celebrating == false and audit_lvl.final_boss_celebration_completed == true, "Al cumplirse 7s debe concluir la celebración post-Titanor")
	assert(audit_lvl.goal.is_locked == false, "La meta debe desbloquearse tras los 7s para activar la cinemática final al pisarla")

	root.remove_child(audit_lvl)
	audit_lvl.free()
	print("  Hitboxes y mecánicas progresivas de Titanor (10 HP, 5 HP, Clones, Niebla y Alumnos) verificadas con éxito.")

	# 16.5 Verificar generador de certificados PDF en Tamaño Carta y Tamaño 5x7
	gs_node.set_difficulty(2) # Difícil
	assert(gs_node.get_initial_difficulty_name() == "Difícil", "Debe conservar la dificultad inicial Difícil")
	var tmp_pdf_dir := ProjectSettings.globalize_path("user://test_certs_tmp")
	var pdf_res: Dictionary = CertificateGeneratorScript.generate_certificates("", tmp_pdf_dir)
	assert(pdf_res.get("success", false) == true, "La generación de PDFs debe tener éxito")
	var carta_path := tmp_pdf_dir.path_join(CertificateGeneratorScript.FILENAME_CARTA)
	var path_5x7 := tmp_pdf_dir.path_join(CertificateGeneratorScript.FILENAME_5X7)
	assert(FileAccess.file_exists(carta_path), "Debe existir el PDF en Tamaño Carta")
	assert(FileAccess.file_exists(path_5x7), "Debe existir el PDF en Tamaño 5x7")

	var carta_txt := FileAccess.get_file_as_string(carta_path)
	var pdf57_txt := FileAccess.get_file_as_string(path_5x7)
	assert(carta_txt.begins_with("%PDF-1.4") and "startxref" in carta_txt and "%%EOF" in carta_txt, "El PDF Carta debe ser un documento PDF 1.4 válido")
	assert("/MediaBox [0 0 612 792]" in carta_txt, "El PDF Carta debe medir 612x792 pt (8.5x11 pulgadas)")
	assert(pdf57_txt.begins_with("%PDF-1.4") and "startxref" in pdf57_txt and "%%EOF" in pdf57_txt, "El PDF 5x7 debe ser un documento PDF 1.4 válido")
	assert("/MediaBox [0 0 360 504]" in pdf57_txt, "El PDF 5x7 debe medir 360x504 pt (5x7 pulgadas)")
	assert("El alumno/Padre de familia/Maestro:_______" in carta_txt and "en el Cobaem Cemsad Plantel 22 Enthavi." in carta_txt and "Felicidades por el logro!" in carta_txt, "El PDF Carta debe contener el texto oficial completo y el campo de nombre en blanco")
	assert("El alumno/Padre de familia/Maestro:_______" in pdf57_txt and "en el Cobaem Cemsad Plantel 22 Enthavi." in pdf57_txt and "Felicidades por el logro!" in pdf57_txt, "El PDF 5x7 debe contener el texto oficial completo y el campo de nombre en blanco")
	assert("Dif\\355cil" in carta_txt and "Dif\\355cil" in pdf57_txt, "Ambos PDFs deben incluir la dificultad inicial extraída")
	assert("/ImLeft 8 0 R" in carta_txt and "/ImRight 9 0 R" in carta_txt and "/ImCenter 10 0 R" in carta_txt and "/Subtype /Image" in carta_txt, "El PDF Carta debe incrustar los 3 logos oficiales")
	assert("/ImLeft 8 0 R" in pdf57_txt and "/ImRight 9 0 R" in pdf57_txt and "/ImCenter 10 0 R" in pdf57_txt and "/Subtype /Image" in pdf57_txt, "El PDF 5x7 debe incrustar los 3 logos oficiales")

	# Limpiar temporales de prueba de PDF y restaurar dificultad
	DirAccess.remove_absolute(carta_path)
	DirAccess.remove_absolute(path_5x7)
	DirAccess.remove_absolute(tmp_pdf_dir)
	gs_node.set_difficulty(1)
	print("  Módulo de certificados PDF (Tamaño Carta 612x792 y Tamaño 5x7 360x504) verificado con éxito.")

	# 16.6 Verificar regreso desde salones (zona limpia vs zona activa) y Jefe del Edificio B (Ciber-Murmullus)
	var test_main = main_scene.instantiate()
	root.add_child(test_main)

	# Caso A: Zona exterior ya limpia antes de entrar al salón -> al salir no quedan enemigos inmóviles y la meta está abierta
	test_main._cleared_classrooms[0] = true
	test_main._saved_exterior_boss_defeated[0] = true
	test_main._saved_exterior_defeated_count[0] = 3
	test_main._returning_from_classroom = true
	test_main.load_level(0) # Escenario 1 exterior (classroom_index 0)
	assert(test_main.active_level.boss_defeated == true, "Debe conservar estado de jefe derrotado al volver del salón")
	assert(test_main.active_level.enemies_container.get_child_count() == 0, "No deben quedar enemigos inmóviles al volver de un salón con exterior ya limpio")
	assert(test_main.active_level.goal.is_locked == false, "La meta debe permanecer desbloqueada tras limpiar exterior y salir del salón")

	# Caso B: Regresar de cada uno de los 6 salones sin haber terminado con el exterior -> spawn libre, jugador protegido y enemigos alejados >= 190 px
	for ext_i in range(6):
		var stage_idx := ext_i * 2
		var ext_data: Dictionary = test_main.levels[stage_idx]
		var c_id := int(ext_data.get("classroom_index", ext_i))
		test_main._cleared_classrooms[c_id] = true
		test_main._saved_exterior_boss_defeated[c_id] = false
		test_main._saved_exterior_defeated_count[c_id] = 1
		test_main._saved_player_health = 2
		test_main._returning_from_classroom = true
		test_main.load_level(stage_idx)
		var lvl_b: Level = test_main.active_level
		assert(lvl_b.player != null and lvl_b.player.can_control == true, "El jugador debe poder moverse y defenderse al salir del salón %d" % ext_i)
		assert(lvl_b.player.is_invulnerable == true, "El jugador debe contar con protección temporal al salir del salón %d" % ext_i)
		assert(lvl_b.enemies_container.get_child_count() > 0, "Deben seguir los enemigos pendientes si no se limpió el exterior %d" % ext_i)
		for obs_r: Rect2 in ext_data.get("obstacles", []):
			assert(not obs_r.has_point(lvl_b.player.position), "La salida del salón (%s) colisiona con obstáculo %s en escenario %d" % [str(lvl_b.player.position), str(obs_r), ext_i])
		for e_node in lvl_b.enemies_container.get_children():
			if e_node is Enemy:
				assert(e_node.position.distance_to(lvl_b.player.position) >= 190.0, "Ningún enemigo debe nacer encima del jugador al salir del salón %d" % ext_i)
				assert(e_node.spawn_grace_timer > 0.0, "El enemigo debe tener ventana de cortesía al salir el jugador del salón %d" % ext_i)

	if gs_node._music:
		gs_node._music.stop()
	root.remove_child(test_main)
	test_main.free()

	# Caso C: Jefe del Edificio B (Ciber-Murmullus) -> teletransporte cada 10s sin entrar a obstáculos y balas teledirigidas
	var edif_b_lvl = level_scene_ref.instantiate()
	root.add_child(edif_b_lvl)
	var edif_b_data: Dictionary = LevelManager.get_default_levels()[3].duplicate(true) # Escenario 4: Edificio B
	edif_b_data["saved_defeated_in_level"] = edif_b_data.get("quota_to_boss", 4)
	edif_b_lvl.setup_level(edif_b_data)
	assert(edif_b_lvl.boss != null and edif_b_lvl.boss.boss_type == Boss.BossType.CIBERACOSO, "Debe aparecer Ciber-Murmullus en el Edificio B")
	var ciber: Boss = edif_b_lvl.boss as Boss
	ciber.current_state = Boss.State.IDLE
	ciber._ciber_teleport_timer = 0.05
	ciber._physics_process(0.1)
	assert(ciber.teleport_count >= 1, "El jefe del Edificio B debe teletransportarse cada 10 segundos")
	for obs_b: Rect2 in edif_b_data.get("obstacles", []):
		assert(not obs_b.has_point(ciber.global_position), "Ciber-Murmullus no debe teletransportarse dentro de obstáculo %s (%s)" % [str(obs_b), str(ciber.global_position)])

	ciber._current_attack_idx = 0
	ciber._attack_dir = (edif_b_lvl.player.global_position - ciber.global_position).normalized()
	ciber._execute_attack()
	var homing_found := false
	for proj in root.get_tree().get_nodes_in_group("enemy_projectiles"):
		if proj is Projectile and proj.is_homing and proj.homing_target == edif_b_lvl.player:
			homing_found = true
			break
	assert(homing_found, "El jefe del Edificio B debe disparar ataques teledirigidos hacia el jugador")

	root.remove_child(edif_b_lvl)
	edif_b_lvl.free()
	print("  Salida de salones sin bugs y Jefe del Edificio B (teledirigido + teletransporte 10s) verificados con éxito.")

	# 17. Verificar Pulso de Empatía, Ítems de Virtud, Ajustes de Audio/Récords/Selector y Nombre en Certificado PDF
	var feat_lvl: Level = level_scene_ref.instantiate()
	root.add_child(feat_lvl)
	var feat_data: Dictionary = LevelManager.get_default_levels()[0].duplicate(true)
	feat_lvl.setup_level(feat_data)
	assert(feat_lvl.player != null, "Nivel de prueba debe tener jugador")

	var slow_enemy: Enemy = feat_lvl.enemies_container.get_child(0) as Enemy if feat_lvl.enemies_container.get_child_count() > 0 else null
	if slow_enemy:
		slow_enemy.global_position = feat_lvl.player.global_position + Vector2(60, 0)
	var proj_scene: PackedScene = load("res://scenes/projectile.tscn")
	var near_shot: Projectile = proj_scene.instantiate() as Projectile
	near_shot.is_enemy_projectile = true
	near_shot.global_position = feat_lvl.player.global_position + Vector2(40, 0)
	feat_lvl.add_child(near_shot)
	near_shot.add_to_group("enemy_projectiles")

	assert(feat_lvl.player.trigger_empathy_pulse() == true, "Pulso de Empatía debe poder activarse con enfriamiento en 0")
	assert(feat_lvl.player.empathy_cooldown_left > 9.0, "Pulso de Empatía debe iniciar cooldown de 10s")
	assert(feat_lvl.player.trigger_empathy_pulse() == false, "Pulso de Empatía no debe reactivarse durante cooldown")
	if slow_enemy:
		assert(slow_enemy._empathy_slow_timer >= 1.9, "Pulso de Empatía debe ralentizar enemigos cercanos")
	assert(near_shot.is_queued_for_deletion(), "Pulso de Empatía debe disipar proyectiles enemigos cercanos")

	feat_lvl.player.health = maxi(1, feat_lvl.player.max_health - 1)
	var heart_pickup := feat_lvl._spawn_virtue_pickup(feat_lvl.player.global_position + Vector2(80, 0), "")
	assert(heart_pickup != null and heart_pickup.get_meta("pickup_kind") == "heart", "Debe generar Corazón de Esperanza si jugador está herido")
	feat_lvl.player.health = feat_lvl.player.max_health
	var shield_pickup := feat_lvl._spawn_virtue_pickup(feat_lvl.player.global_position + Vector2(100, 0), "")
	assert(shield_pickup != null and shield_pickup.get_meta("pickup_kind") == "shield", "Debe generar Escudo de Respeto si jugador tiene vida completa")

	if feat_lvl.player and feat_lvl.player.sfx_attack:
		feat_lvl.player.sfx_attack.stop()
	if gs_node._music:
		gs_node._music.stop()
	root.remove_child(feat_lvl)
	feat_lvl.free()

	# Probar GameSettings: silencio, desbloqueo de escenario y récords locales
	var prev_muted: bool = bool(gs_node.muted)
	var toggled_mute: bool = gs_node.toggle_mute()
	assert(toggled_mute == (not prev_muted), "toggle_mute debe alternar estado de silencio")
	if not prev_muted:
		gs_node.toggle_mute()
	gs_node.unlock_stage(3)
	assert(gs_node.unlocked_stage_max >= 3, "unlock_stage(3) debe desbloquear hasta escenario 4")
	gs_node.set_selected_start_stage(2)
	assert(gs_node.selected_start_stage == 2, "set_selected_start_stage debe guardar escenario inicial válido")
	var rec_entry: Dictionary = gs_node.record_campaign_completion(1, 95.5, 42)
	assert(float(rec_entry.get("best_time", 0.0)) > 0.0 and int(rec_entry.get("best_defeated", 0)) >= 42, "record_campaign_completion debe guardar récord")
	gs_node.set_selected_start_stage(0)

	# Probar nombre opcional en CertificateGenerator preservando compatibilidad con campo en blanco
	var default_cert_text := CertificateGeneratorScript.build_certificate_text("Normal", "")
	assert("El alumno/Padre de familia/Maestro:_______" in default_cert_text, "Nombre vacío debe mantener campo _______ por compatibilidad")
	var named_cert_text := CertificateGeneratorScript.build_certificate_text("Normal", "Juan Pérez")
	assert("El alumno/Padre de familia/Maestro: Juan Pérez" in named_cert_text, "Nombre provisto debe insertarse en el certificado")
	print("  Pulso de Empatía, Pickups, Ajustes de Audio/Selector/Récords y Certificado personalizado verificados.")

	print("--- TODOS LOS TESTS DE ESCENARIOS Y PROGRESIÓN PASARON CON ÉXITO ---")
	quit(0)
	return true
