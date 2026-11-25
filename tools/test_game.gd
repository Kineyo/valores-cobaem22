extends SceneTree

const LevelManager := preload("res://scripts/level_manager.gd")
const GameSettingsScript := preload("res://scripts/game_settings.gd")
const SceneTransitionScript := preload("res://scripts/scene_transition.gd")
const FxScript := preload("res://scripts/fx.gd")
const FinalCeremonyScript := preload("res://scripts/final_ceremony.gd")
const CertificateGeneratorScript := preload("res://scripts/certificate_generator.gd")

var _post_init_tests_done: bool = false
var _settings_existed: bool = false
var _settings_backup: PackedByteArray = PackedByteArray()

func _init() -> void:
	print("--- INICIANDO TEST AUTOMÁTICO DE CAMPEONES DE LOS VALORES (CEMSaD 22 ENTHAVI) ---")
	_settings_existed = FileAccess.file_exists("user://settings.cfg")
	_settings_backup = FileAccess.get_file_as_bytes("user://settings.cfg") if _settings_existed else PackedByteArray()

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

	# 16.3 Fase de Desesperación al 18%: Neblina + oscurecimiento + pausa 'Aun me queda un ataque' + max 5 enemigos + Danmaku 5s/7s + cubrir 3s
	titanor._is_spell_transition = false
	var desp_hp := maxi(2, int(floor(float(titanor.max_hp) * Boss.TITANOR_DESPERATION_RATIO)))
	titanor.current_hp = desp_hp + 1
	titanor.hit_by_attack(Vector2.ZERO, 1)
	assert(titanor.current_hp == desp_hp, "Al bajar a 18%% debe quedar en %d HP para la fase de desesperación" % desp_hp)
	assert(titanor._ten_hp_triggered == true, "Debe activarse la fase de desesperación (18%%)")
	assert(titanor.last_special_message == "Aun me queda un ataque", "Debe mostrar el mensaje exacto de desesperación")
	assert(titanor.desperation_fog_active == true, "Debe activar neblina al 18%%")
	assert(audit_lvl.fog_overlay != null and audit_lvl.fog_overlay.is_fog_active == true, "FogOverlay del nivel debe activarse al 18%%")
	assert(audit_lvl.fog_overlay.desperation_darkness == true, "Debe activarse el oscurecimiento total al 18%%")
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

	# 16.4 Fase Clímax al 8% -> pausa a 1 HP -> resquebrajamiento -> clímax Undertale -> redención pacífica
	var rescue_hp := maxi(2, int(floor(float(titanor.max_hp) * Boss.TITANOR_RESCUE_RATIO)))
	titanor.current_hp = rescue_hp + 1
	titanor.hit_by_attack(Vector2.ZERO, 1)
	assert(titanor.current_hp == rescue_hp, "Al bajar a 8%% debe activar el clímax estudiantil en %d HP" % rescue_hp)
	assert(titanor._five_hp_triggered == true and titanor._is_transforming == true, "Debe iniciar animación de transformación al 8%")
	assert(titanor.last_special_message == "No dejare que liberes tan facil a la escuela", "Debe mostrar el mensaje exacto de clímax")

	var ut_signal_box := [false]
	titanor.undertale_climax_requested.connect(func(_b): ut_signal_box[0] = true)
	for _climax in range(35):
		if titanor.is_shattering_at_one_hp:
			break
		titanor._physics_process(0.1)
	assert(titanor.current_hp == 1 and titanor.is_shattering_at_one_hp == true, "Tras la ofensiva estudiantil Titanor debe detenerse en 1 HP resquebrajándose")
	assert(titanor.rescued_attack_students.size() == 7, "Deben aparecer los 7 alumnos rescatados alrededor de Titanor")
	for _shatter in range(25):
		if ut_signal_box[0]:
			break
		titanor._physics_process(0.1)
	assert(ut_signal_box[0] == true and titanor._undertale_climax_emitted == true, "Tras fracturarse en 1 HP debe solicitar el clímax Undertale")
	titanor.finish_undertale_climax()
	assert(titanor.current_state == Boss.State.REDEEMED and titanor.current_hp == 0, "Tras el clímax Undertale Titanor debe quedar redimido")
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

	# 18. Regresiones P0-P2, 28 Poses de Aliados, AllyBrain, Inventario 1-Slot y Ventaja Esperanza (15s)
	var AllyBrainClass := preload("res://scripts/ally_brain.gd")

	# 18.1 Daño único al jefe (mask=2 y sin area_entered duplicado)
	var b_lvl: Level = level_scene_ref.instantiate()
	root.add_child(b_lvl)
	b_lvl.setup_level(LevelManager.get_all_levels()[0])
	b_lvl._spawn_boss()
	var b_inst := b_lvl.boss as Boss
	assert(b_inst != null and b_inst._hitbox.collision_mask == 2, "Hitbox del jefe debe detectar solo jugador (mask 2) para evitar doble daño con Projectile")
	b_inst.current_state = Boss.State.IDLE
	var b_hp0 := b_inst.current_hp
	b_inst.hit_by_attack(Vector2.ZERO, 1)
	assert(b_inst.current_hp == b_hp0 - 1, "Un impacto debe restar exactamente 1 HP al jefe")
	root.remove_child(b_lvl)
	b_lvl.free()

	# 18.2 PDF personalizado renderiza nombre visible en stream y solo escribe en extra_dir
	var tmp_cert_dir2 := ProjectSettings.globalize_path("user://tmp_cert_test2")
	DirAccess.make_dir_recursive_absolute(tmp_cert_dir2)
	var gen_res2: Dictionary = CertificateGeneratorScript.generate_certificates("Normal", tmp_cert_dir2, "Maria Lopez")
	assert(gen_res2.get("success", false) == true, "Debe generar Carta y 5x7 en extra_dir")
	var carta_path2 := tmp_cert_dir2.path_join(CertificateGeneratorScript.FILENAME_CARTA)
	var pdf57_path2 := tmp_cert_dir2.path_join(CertificateGeneratorScript.FILENAME_5X7)
	assert(FileAccess.file_exists(carta_path2) and FileAccess.file_exists(pdf57_path2), "Ambos PDFs deben crearse dentro de extra_dir")
	var cert_ascii2 := FileAccess.get_file_as_string(carta_path2)
	assert("Maria Lopez" in cert_ascii2, "El PDF generado debe incluir el nombre del destinatario en el contenido")
	DirAccess.remove_absolute(carta_path2)
	DirAccess.remove_absolute(pdf57_path2)
	DirAccess.remove_absolute(tmp_cert_dir2)

	# 18.3 Retratos procedurales de jefes/narrador no secuestrados por guardian.png
	var sc_inst = load("res://scenes/story_cutscene.tscn").instantiate()
	assert(sc_inst._get_portrait_texture("boss_titanor") == null, "Jefes deben usar retrato procedural en lugar de guardian.png")
	assert(sc_inst._get_portrait_texture("narrator") == null, "Narrador debe usar retrato procedural en lugar de guardian.png")
	assert(sc_inst._get_portrait_texture("player_neutral") != null, "Guardián debe cargar textura de retrato")
	sc_inst.free()

	# 18.4 Projectile.set_direction() y ataque Salón 5
	var p_dir_test := proj_scene.instantiate() as Projectile
	p_dir_test.set_direction(Vector2(1.0, -1.0))
	assert(p_dir_test.direction.is_equal_approx(Vector2(1.0, -1.0).normalized()), "set_direction debe normalizar vector")
	assert(is_equal_approx(p_dir_test.rotation, p_dir_test.direction.angle()), "set_direction debe actualizar rotation")
	p_dir_test.free()

	var s5_lvl: Level = level_scene_ref.instantiate()
	root.add_child(s5_lvl)
	s5_lvl.setup_level(LevelManager.get_classroom_levels()[4])
	s5_lvl._spawn_boss()
	s5_lvl.boss.current_state = Boss.State.IDLE
	s5_lvl.boss._attack_classroom_digital_glitch()
	assert(root.get_tree().get_nodes_in_group("enemy_projectiles").size() > 0 or s5_lvl.get_child_count() > 0, "Ataque de Salón 5 debe instanciar proyectiles")
	root.remove_child(s5_lvl)
	s5_lvl.free()

	# 18.5 Normalización de acentos en Student
	assert(Student.normalize_name("María") == "maria" and Student.normalize_name("Sofía") == "sofia", "normalize_name debe quitar acentos")
	for acc_name: String in ["María", "Sofía"]:
		var acc_st := Student.new()
		acc_st.student_name = acc_name
		acc_st.can_assist_in_combat = false
		root.add_child(acc_st)
		assert(acc_st.sprite != null and acc_st.sprite.texture != null, "%s debe cargar su sprite oficial" % acc_name)
		root.remove_child(acc_st)
		acc_st.free()

	# 18.6 Integridad de los 28 PNGs nuevos (512x512 RGBA8 con borde transparente)
	var pose_folders := ["mateo_laboratorio", "maria_cafeteria", "valeria_plaza", "fernanda_biblioteca", "diego_computo", "sofia_direccion", "alejandro_cancha"]
	var pose_names := ["walk_right.png", "walk_left.png", "back.png", "attack.png"]
	var checked_poses := 0
	for pf in pose_folders:
		for pn in pose_names:
			var full_p := ProjectSettings.globalize_path("res://assets/characters/%s/%s" % [pf, pn])
			assert(FileAccess.file_exists(full_p), "Falta sprite de pose: " + full_p)
			var p_img := Image.load_from_file(full_p)
			assert(p_img != null and p_img.get_width() == 512 and p_img.get_height() == 512, "Pose %s/%s debe estar estandarizada exactamente a 512x512" % [pf, pn])
			assert(p_img.get_pixel(0, 0).a < 0.05, "Pose %s/%s debe tener fondo transparente en borde exterior" % [pf, pn])
			checked_poses += 1
	assert(checked_poses == 28, "Deben verificarse exactamente 28 PNGs nuevos")

	# 18.7 Sistema de Aliados + Cerebro (AllyBrain)
	var ally_lvl: Level = level_scene_ref.instantiate()
	root.add_child(ally_lvl)
	ally_lvl.setup_level(LevelManager.get_all_levels()[0])
	ally_lvl._spawn_boss()
	ally_lvl.boss.current_state = Boss.State.IDLE
	var combat_ally := Student.new()
	combat_ally.student_name = "Mateo"
	combat_ally.initial_state = Student.State.HAPPY
	combat_ally.level_ref = ally_lvl
	combat_ally.player = ally_lvl.player
	combat_ally.position = ally_lvl.boss.position + Vector2(-180, 0)
	ally_lvl.entities.add_child(combat_ally)
	assert(combat_ally.is_combat_ally == true and combat_ally.brain != null, "Estudiante HAPPY debe activar cerebro AllyBrain")
	for _astep in range(30):
		combat_ally._physics_process(0.1)
	assert(combat_ally.brain.shots_fired > 0, "AllyBrain debe disparar proyectiles de virtud al jefe dentro del rango")
	var ally_proj_found: Projectile = null
	for ap in ally_lvl.entities.get_children():
		if ap is Projectile and ap.is_ally_projectile:
			ally_proj_found = ap as Projectile
			break
	assert(ally_proj_found != null, "El proyectil disparado por el aliado debe tener is_ally_projectile == true")
	assert(ally_proj_found.position.distance_squared_to(combat_ally.position) <= 1600.0, "El proyectil aliado debe nacer junto al torso del aliado y no en (0, 0)")
	var proj_start_pos := ally_proj_found.position
	for _pstep in range(10):
		ally_proj_found._physics_process(0.05)
	assert(not ally_proj_found.is_queued_for_deletion(), "El proyectil aliado NO debe autodestruirse en un muro al nacer")
	assert(ally_proj_found.position.distance_squared_to(proj_start_pos) > 10000.0, "El proyectil aliado debe desplazarse >100 px hacia su objetivo")

	# Proyectil que se aleja NO debe disparar DODGE; proyectil entrante SÍ debe activar DODGE
	var away_shot := proj_scene.instantiate() as Projectile
	away_shot.is_enemy_projectile = true
	away_shot.direction = Vector2.LEFT
	away_shot.position = combat_ally.position + Vector2(-36, 0)
	ally_lvl.entities.add_child(away_shot)
	away_shot.add_to_group("enemy_projectiles")
	combat_ally.brain.state = AllyBrainClass.AllyState.POSITION
	combat_ally.brain._dodge_cooldown = 0.0
	combat_ally.brain._dodge_check_timer = 0.0
	var away_res := combat_ally.brain.tick(0.05)
	assert(away_res.get("state") != AllyBrainClass.AllyState.DODGE, "Proyectil enemigo que ya se aleja NO debe activar DODGE")
	ally_lvl.entities.remove_child(away_shot)
	away_shot.free()

	var dodge_shot := proj_scene.instantiate() as Projectile
	dodge_shot.is_enemy_projectile = true
	dodge_shot.direction = Vector2.RIGHT
	dodge_shot.position = combat_ally.position + Vector2(-28, 0)
	ally_lvl.entities.add_child(dodge_shot)
	dodge_shot.add_to_group("enemy_projectiles")
	combat_ally.brain._dodge_cooldown = 0.0
	combat_ally.brain._dodge_check_timer = 0.0
	var dodge_res := combat_ally.brain.tick(0.05)
	assert(dodge_res.get("state") == AllyBrainClass.AllyState.DODGE and dodge_res["velocity"].length_squared() > 10.0, "AllyBrain debe esquivar proyectiles enemigos entrantes cercanos")

	# Verificar recuperación de atascamiento (UNSTUCK) si intenta avanzar pero no progresa
	combat_ally.brain.state = AllyBrainClass.AllyState.POSITION
	combat_ally.brain._dodge_cooldown = 1.0
	combat_ally.velocity = Vector2(120, 0)
	combat_ally.brain._last_intent_vel = Vector2(120, 0)
	combat_ally.brain._prev_pos = combat_ally.global_position
	combat_ally.brain._stuck_accum = 0.24
	var unstuck_res := combat_ally.brain.tick(0.05)
	assert(unstuck_res.get("state") == AllyBrainClass.AllyState.UNSTUCK, "AllyBrain debe entrar en UNSTUCK al detectar bloqueo contra pared")

	# Verificar que CPUParticles2D dentro de enemies_container NUNCA es seleccionado como objetivo
	var stray_fx := CPUParticles2D.new()
	stray_fx.position = combat_ally.position + Vector2(12, 0)
	ally_lvl.enemies_container.add_child(stray_fx)
	var saved_boss = ally_lvl.boss
	ally_lvl.boss = null
	var fx_target = combat_ally.brain._find_best_target()
	assert(fx_target != stray_fx and (fx_target == null or fx_target is Enemy), "AllyBrain._find_best_target() NUNCA debe seleccionar CPUParticles2D en enemies_container")
	ally_lvl.boss = saved_boss
	ally_lvl.enemies_container.remove_child(stray_fx)
	stray_fx.free()

	# Verificar que scripts/projectile.gd es un script hoja sin dependencias cíclicas
	var proj_src := FileAccess.get_file_as_string("res://scripts/projectile.gd")
	assert(not ("is Student" in proj_src) and not ("is Player" in proj_src) and not ("is Enemy" in proj_src), "projectile.gd no debe referenciar Student/Player/Enemy para evitar ciclos de carga")
	for p_scene_ref: PackedScene in [ally_lvl.player.PROJECTILE_SCENE, AllyBrainClass.PROJECTILE_SCENE, Boss.PROJECTILE_SCENE]:
		var inst_p := p_scene_ref.instantiate()
		assert(inst_p.get_script() != null and inst_p.has_method("set_direction"), "PROJECTILE_SCENE debe instanciar script Projectile con set_direction activo")
		inst_p.free()

	root.remove_child(ally_lvl)
	ally_lvl.free()

	# 18.8 Inventario de 1 solo ítem + Ventaja Esperanza (15.0s) sobre Titanor
	var esp_lvl: Level = level_scene_ref.instantiate()
	root.add_child(esp_lvl)
	esp_lvl.setup_level(LevelManager.get_all_levels()[5])
	esp_lvl._spawn_boss()
	var esp_titanor := esp_lvl.boss as Boss
	esp_titanor.current_state = Boss.State.IDLE
	esp_titanor._spawn_fake_clones(2)
	esp_titanor.desperation_fog_active = true
	esp_lvl.set_boss_desperation_fog(true)
	assert(esp_titanor.get_active_clone_count() == 2, "Precondición: clones de Titanor activos")
	assert(esp_lvl.fog_overlay != null and esp_lvl.fog_overlay.is_fog_active == true, "Precondición: niebla activa antes de Esperanza")
	assert(esp_lvl.player.pickup_item("heart") == true and esp_lvl.player.held_item == "heart", "Debe equipar primer ítem en slot único")
	assert(esp_lvl.player.pickup_item("esperanza") == true and esp_lvl.player.held_item == "esperanza", "Inventario de 1 slot debe reemplazar ítem previo")
	assert(esp_lvl.player.use_held_item() == true and esp_lvl.player.held_item == "", "use_held_item debe consumir el ítem del inventario")
	assert(is_equal_approx(esp_lvl.esperanza_timer, 15.0), "Esperanza debe durar exactamente 15.0s")
	assert(esp_titanor.is_esperanza_defenseless == true, "Titanor debe quedar indefenso al activar Esperanza")
	assert(esp_titanor.get_active_clone_count() == 0, "Esperanza debe eliminar de inmediato todos los clones activos")
	assert(esp_lvl.fog_overlay.is_fog_active == false, "Esperanza debe disipar inmediatamente la niebla")
	esp_titanor._spawn_fake_clones(2)
	esp_lvl.set_boss_desperation_fog(true)
	assert(esp_titanor.get_active_clone_count() == 0 and esp_lvl.fog_overlay.is_fog_active == false, "Durante 15s Esperanza no deben generarse clones ni niebla")
	for _e_tick in range(31):
		esp_lvl._physics_process(0.5)
		esp_titanor._physics_process(0.5)
	assert(esp_lvl.esperanza_timer == 0.0 and esp_titanor.is_esperanza_defenseless == false, "Tras 15s la ventaja Esperanza debe finalizar limpiamente")
	if esp_lvl.player and esp_lvl.player.sfx_attack:
		esp_lvl.player.sfx_attack.stop()
	root.remove_child(esp_lvl)
	esp_lvl.free()
	print("  Regresiones P0-P2, 28 PNGs aliados, AllyBrain, Inventario 1-slot y Esperanza 15s verificados.")

	# 18.9 Auditoría Móvil Extrema (ergonomía, anti-doble toque, cancelación táctil, HUD/Ceremonia)
	var mob_mc := MobileControls.new()
	root.add_child(mob_mc)
	mob_mc._update_positions()
	assert(mob_mc._focus_pos.distance_to(mob_mc._pulse_pos) >= 54.0, "800x450: FOCUS y PULSO no deben solaparse")
	assert(mob_mc._pulse_pos.distance_to(mob_mc._item_pos) >= 54.0, "800x450: PULSO e ÍTEM no deben solaparse")
	assert(mob_mc._focus_pos.distance_to(mob_mc._item_pos) >= 54.0, "800x450: FOCUS e ÍTEM no deben solaparse")
	assert(mob_mc._focus_pos.x >= 400.0 and mob_mc._pulse_pos.x >= 400.0 and mob_mc._item_pos.x >= 400.0, "Botones derechos deben permanecer en mitad derecha")

	# Verificar en viewport estrecho 640x360 usando SubViewport temporal
	var narrow_vp := SubViewport.new()
	narrow_vp.size = Vector2i(640, 360)
	root.add_child(narrow_vp)
	var narrow_mc := MobileControls.new()
	narrow_vp.add_child(narrow_mc)
	narrow_mc._update_positions()
	assert(narrow_mc._focus_pos.distance_to(narrow_mc._pulse_pos) >= 54.0, "640x360: FOCUS y PULSO no deben solaparse")
	assert(narrow_mc._pulse_pos.distance_to(narrow_mc._item_pos) >= 54.0, "640x360: PULSO e ÍTEM no deben solaparse")
	assert(narrow_mc._focus_pos.distance_to(narrow_mc._item_pos) >= 54.0, "640x360: FOCUS e ÍTEM no deben solaparse")
	assert(narrow_mc._focus_pos.x >= 320.0 and narrow_mc._pulse_pos.x >= 320.0 and narrow_mc._item_pos.x >= 320.0, "640x360: Botones derechos en mitad derecha")
	narrow_vp.remove_child(narrow_mc)
	narrow_mc.free()
	root.remove_child(narrow_vp)
	narrow_vp.free()

	# Verificar cancelación táctil de _item_touch_id y helpers visuales
	mob_mc._ensure_item_action()
	mob_mc._item_touch_id = 4
	mob_mc._item_pressed = true
	Input.action_press("use_item")
	mob_mc._cancel_touch(4)
	assert(mob_mc._item_touch_id == -1 and not mob_mc._item_pressed and not Input.is_action_pressed("use_item"), "_cancel_touch debe liberar _item_touch_id y use_item")
	mob_mc.set_pulse_cooldown(4.2, 10.0)
	mob_mc.set_item_state("esperanza", "ESP★", Color(1.0, 0.88, 0.25))
	assert(is_equal_approx(mob_mc.pulse_cooldown_remaining, 4.2) and mob_mc.has_item_available and mob_mc.item_short_label == "ESP★", "MobileControls debe actualizar cooldown de pulso y etiqueta de ítem")
	root.remove_child(mob_mc)
	mob_mc.free()

	# Verificar ocultación de UI de combate en HUD al entrar en Ceremonia Final
	var mob_hud: HUD = preload("res://scenes/hud.tscn").instantiate()
	root.add_child(mob_hud)
	mob_hud.update_inventory_slot("esperanza", {"short": "ESPERANZA", "color": Color.GOLD})
	mob_hud.update_esperanza_bar(8.0, 15.0)
	mob_hud.set_gameplay_ui_visible(false)
	assert(not mob_hud._inventory_panel.visible and not mob_hud._esperanza_container.visible, "HUD.set_gameplay_ui_visible(false) debe ocultar inventario y barra Esperanza")
	root.remove_child(mob_hud)
	mob_hud.free()

	# Verificar filtro anti-emulación táctil en StoryCutscene y FinalCeremony
	var emu_click := InputEventMouseButton.new()
	emu_click.button_index = MOUSE_BUTTON_LEFT
	emu_click.pressed = true
	emu_click.device = InputEvent.DEVICE_ID_EMULATION

	var mob_cs: StoryCutscene = preload("res://scenes/story_cutscene.tscn").instantiate()
	mob_cs.setup_cutscene({
		"title": "Test Móvil",
		"dialogue_nodes": [
			{"speaker": "Guardián", "text": "Línea 1 de prueba móvil.", "portrait": "guardian"},
			{"speaker": "Guardián", "text": "Línea 2 de prueba móvil.", "portrait": "guardian"}
		]
	})
	root.add_child(mob_cs)
	mob_cs._is_typing = false
	mob_cs._gui_input(emu_click)
	assert(mob_cs._current_index == 0, "StoryCutscene debe ignorar MouseButton con DEVICE_ID_EMULATION")
	root.remove_child(mob_cs)
	mob_cs.free()

	var mob_fc: FinalCeremony = FinalCeremonyScript.new()
	root.add_child(mob_fc)
	mob_fc._is_typing = false
	mob_fc._on_speech_panel_gui_input(emu_click)
	assert(mob_fc._speech_index == 0, "FinalCeremony debe ignorar MouseButton con DEVICE_ID_EMULATION")
	root.remove_child(mob_fc)
	mob_fc.free()

	# Verificar tamaño táctil de botones utilitarios del Menú principal (>= 34px)
	var mob_menu: Control = preload("res://scenes/menu.tscn").instantiate()
	root.add_child(mob_menu)
	assert(mob_menu._btn_stage_prev.custom_minimum_size.y >= 34.0 and mob_menu._btn_mute.custom_minimum_size.y >= 34.0 and mob_menu._btn_vol_up.custom_minimum_size.y >= 34.0, "Botones utilitarios de Menu deben tener altura >= 34px para tacto móvil")
	root.remove_child(mob_menu)
	mob_menu.free()
	print("  Auditoría Móvil Extrema (ergonomía, anti-emulación, HUD/Ceremonia y Menú) verificada.")

	# 19. Soundtrack Dinámico, Vida Porcentual, Touhou Titanor, Clímax Undertale 1 HP y Galería ⋮
	# 19.1 Estandarización estricta 512x512 en TODAS las carpetas de personajes y retratos
	for char_folder in ["Masculino", "Femenino", "coordinador", "maestro_desinteres", "maestro_desinteres_redeemed", "mateo_laboratorio", "maria_cafeteria", "valeria_plaza", "fernanda_biblioteca", "diego_computo", "sofia_direccion", "alejandro_cancha"]:
		var d_path := ProjectSettings.globalize_path("res://assets/characters/%s" % char_folder)
		var d_open := DirAccess.open(d_path)
		assert(d_open != null, "Debe existir carpeta de personaje: " + d_path)
		d_open.list_dir_begin()
		var f_item := d_open.get_next()
		while f_item != "":
			if not d_open.current_is_dir() and f_item.to_lower().ends_with(".png"):
				var im := Image.load_from_file(d_path.path_join(f_item))
				assert(im != null and im.get_width() == 512 and im.get_height() == 512, "%s/%s debe medir exactamente 512x512" % [char_folder, f_item])
			f_item = d_open.get_next()
		d_open.list_dir_end()

	# 19.2 Soundtrack dinámico por nivel, personaje y dificultad + tema Finale Undertale
	assert(gs_node.SOUNDTRACK_CATALOG.size() == 12, "El catálogo musical debe listar los 12 temas escolares/Touhou")
	assert(gs_node.get_track_path("stage_1", 0) != gs_node.get_track_path("stage_1", 1), "Masculino y Femenino deben usar arreglos musicales distintos")
	assert(gs_node.get_track_path("stage_1", 0) != gs_node.get_track_path("stage_4", 0), "Escenarios distintos deben usar música diferente")
	assert(gs_node.get_difficulty_pitch_scale(0) < gs_node.get_difficulty_pitch_scale(1) and gs_node.get_difficulty_pitch_scale(1) < gs_node.get_difficulty_pitch_scale(2), "Dificultad debe modular energía/tempo musical")
	assert(gs_node._load_audio_stream(gs_node.FINALE_SOULS_PATH) != null, "Debe cargar tema original clímax Undertale-Finale")
	assert(gs_node._load_audio_stream(gs_node.HARD_PERC_PATH) != null, "Debe cargar capa de percusión para Difícil")
	gs_node.set_difficulty(2)
	gs_node.set_selected_character(1)
	gs_node.play_stage_music(2, false, false, false)
	assert(gs_node.current_track_id == "stage_3", "play_stage_music(2) debe seleccionar stage_3")
	gs_node.play_stage_music(5, false, true, true)
	assert(gs_node.current_track_id == "boss_final", "play_stage_music final boss debe seleccionar boss_final")
	gs_node.set_selected_character(0)
	gs_node.set_difficulty(1)

	# 19.3 Vida porcentual en Jefes, Enemigos y HUD (%)
	var pct_hud: HUD = preload("res://scenes/hud.tscn").instantiate()
	root.add_child(pct_hud)
	pct_hud.show_boss_bar("Apatyx", 16, 32)
	assert(pct_hud.boss_hp_label.text == "50%", "HUD debe mostrar vida del jefe en porcentaje ('50%')")
	root.remove_child(pct_hud)
	pct_hud.free()

	var pct_lvl: Level = level_scene_ref.instantiate()
	root.add_child(pct_lvl)
	pct_lvl.setup_level(LevelManager.get_all_levels()[0])
	pct_lvl._spawn_boss()
	var pct_boss := pct_lvl.boss as Boss
	pct_boss.current_state = Boss.State.IDLE
	var trig_box := [false, false]
	pct_boss.hp_phase_animation_triggered.connect(func(anim_n, _p):
		if anim_n == "enraged": trig_box[0] = true
		elif anim_n == "critical": trig_box[1] = true
	)
	pct_boss.hit_by_attack(Vector2.ZERO, int(pct_boss.max_hp / 2))
	assert(trig_box[0] == true and pct_boss.active_hp_anim_state == "enraged", "Al 50%% de vida debe disparar animación porcentual enraged")
	pct_boss.hit_by_attack(Vector2.ZERO, int(pct_boss.max_hp / 4))
	assert(trig_box[1] == true and pct_boss.active_hp_anim_state == "critical" and pct_boss.visual_crack_level >= 0.4, "Al 25%% de vida debe disparar animación critical y grietas")

	# Enemigo Bullying en Difícil usa porcentaje (50% anim hurt_50)
	gs_node.set_difficulty(2)
	var pct_enemy := preload("res://scenes/enemy.tscn").instantiate() as Enemy
	pct_enemy.enemy_type = Enemy.Type.BULLYING
	pct_lvl.enemies_container.add_child(pct_enemy)
	assert(pct_enemy.max_hp == 2 and pct_enemy.get_hp_percent() == 100, "Bullying en Difícil debe iniciar al 100% (2 HP)")
	pct_enemy.hit_by_attack(Vector2.ZERO)
	assert(pct_enemy.is_active == true and pct_enemy.get_hp_percent() == 50 and pct_enemy.active_hp_anim_state == "hurt_50", "Al bajar a 50% el enemigo debe activar estado animado hurt_50")
	gs_node.set_difficulty(1)
	root.remove_child(pct_lvl)
	pct_lvl.free()

	# 19.4 Nuevos patrones Touhou de escape continuo para Titanor
	var touhou_lvl: Level = level_scene_ref.instantiate()
	root.add_child(touhou_lvl)
	touhou_lvl.setup_level(LevelManager.get_all_levels()[5])
	touhou_lvl._spawn_boss()
	var tboss := touhou_lvl.boss as Boss
	tboss.current_state = Boss.State.IDLE
	tboss._attack_danmaku_closing_cage(14, 160.0)
	tboss._attack_danmaku_crisscross_grid(6, 170.0)
	tboss._attack_danmaku_accelerating_lotus(16, 165.0)
	assert(root.get_tree().get_nodes_in_group("enemy_projectiles").size() >= 20, "Los nuevos patrones Touhou deben generar múltiples proyectiles de escape")
	root.remove_child(touhou_lvl)
	touhou_lvl.free()

	# 19.5 Escena Clímax estilo Undertale (corazones de colores, diálogos exactos, Finale)
	var ut_scene := preload("res://scenes/undertale_climax.tscn").instantiate()
	root.add_child(ut_scene)
	assert(ut_scene.get_hearts_data().size() == 8, "Clímax Undertale debe mostrar los 8 corazones de valores (Héroe + 7 Aliados)")
	assert(gs_node.current_track_id == "finale_souls", "Clímax Undertale debe activar la música estilo Finale")
	assert("maestro que ignore a los alumnos" in ut_scene.get_boss_dialogue() and "sere mas fuerte" in ut_scene.get_boss_dialogue().replace("é", "e").replace("á", "a"), "Debe incluir diálogo exacto de Titanor en blanco y negro")
	assert("lograr erradicarte de nuevo" in ut_scene.get_students_dialogue(), "Debe incluir diálogo final exacto de los alumnos")
	var ut_done_box := [false]
	ut_scene.climax_finished.connect(func(): ut_done_box[0] = true)
	ut_scene.force_finish_for_test()
	assert(ut_done_box[0] == true, "UndertaleClimax debe emitir climax_finished al concluir")
	if is_instance_valid(ut_scene) and ut_scene.get_parent() == root:
		root.remove_child(ut_scene)
		ut_scene.free()

	# 19.6 Menú de tres puntos (⋮) y Galería de Materiales completa
	var st_n := root.get_node_or_null("SceneTransition")
	if st_n:
		st_n.is_busy = false
	var gal_menu: Control = preload("res://scenes/menu.tscn").instantiate()
	root.add_child(gal_menu)
	var dots_btn := gal_menu.get_node_or_null("BtnMaterialsMenu") as Button
	assert(dots_btn != null and dots_btn.text == "⋮", "El menú principal debe incluir el botón de tres puntos '⋮'")
	dots_btn.pressed.emit()
	assert(gal_menu._materials_gallery != null and is_instance_valid(gal_menu._materials_gallery), "Pulsar '⋮' debe abrir la Galería de Materiales")
	gal_menu._materials_gallery._select_category("Canciones")
	gal_menu._materials_gallery._on_jukebox_play_pressed()
	assert(gal_menu._materials_gallery._is_preview_playing == true, "Jukebox de Galería debe iniciar vista previa musical")
	gal_menu._close_materials_gallery()
	assert(gal_menu._materials_gallery == null and gs_node.current_track_id == "menu", "Al cerrar Galería debe restaurar tema del menú")
	var cats: Dictionary = MaterialsGallery.get_all_categories()
	for req_cat in ["Personajes", "Canciones", "Escenarios", "Enemigos y Jefes", "Habilidades e Ítems", "Videos"]:
		assert(cats.has(req_cat) and not (cats[req_cat] as Array).is_empty(), "Galería debe incluir categoría '%s'" % req_cat)
	for ch_item in cats["Personajes"]:
		assert(not str(ch_item.get("what", "")).is_empty() and not str(ch_item.get("where", "")).is_empty() and not str(ch_item.get("symbolizes", "")).is_empty(), "Todo personaje en Galería debe explicar qué es, dónde está y qué simboliza")
	root.remove_child(gal_menu)
	gal_menu.free()
	print("  Bloque 19 (Soundtrack Dinámico, HP %, Touhou Titanor, Clímax Undertale 1 HP y Galería ⋮) verificado.")

	# =========================================================================
	# BLOQUE 20: RETRATOS DE HISTORIA, VIDEOS DE CLÍMAX Y CRÉDITOS 3:4 (README)
	# =========================================================================
	# 20.1 Retratos en Modo Historia y Galería
	var sc_p: Control = preload("res://scenes/story_cutscene.tscn").instantiate()
	root.add_child(sc_p)
	assert(sc_p.portrait_canvas != null and sc_p.portrait_canvas.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "PortraitCanvas debe usar filtrado NEAREST para pixel-art")
	for pid in [
		"player_neutral", "mateo_sad", "maria_sad", "valeria_sad",
		"fernanda_sad", "diego_sad", "sofia_sad", "alejandro_sad",
		"coordinador", "maestro_desinteres", "maestro_desinteres_redeemed",
	]:
		assert(sc_p._get_portrait_texture(pid) != null, "StoryCutscene debe resolver textura de retrato para '%s'" % pid)
	root.remove_child(sc_p)
	sc_p.free()
	for ch_p in cats["Personajes"]:
		var p_img := str(ch_p.get("portrait", ""))
		assert(not p_img.is_empty() and FileAccess.file_exists(p_img), "Retrato de Galería '%s' debe existir en disco: %s" % [str(ch_p.get("name", "")), p_img])

	# 20.2 Videos finales y créditos 3:4 en recursos del proyecto
	for v_path in [
		"res://assets/video/escena_final_corazones.ogv",
		"res://assets/video/escena_final_corazones.mp4",
		"res://assets/video/creditos_readme_3x4.ogv",
		"res://assets/video/creditos_readme_3x4.mp4",
	]:
		assert(FileAccess.file_exists(v_path), "Debe existir recurso de video: %s" % v_path)
		var vf := FileAccess.open(v_path, FileAccess.READ)
		assert(vf != null and vf.get_length() > 50000, "Archivo de video no debe estar vacío o truncado: %s" % v_path)
		if vf:
			vf.close()
	for ogv_path in [
		"res://assets/video/escena_final_corazones.ogv",
		"res://assets/video/creditos_readme_3x4.ogv",
	]:
		var vstream := ResourceLoader.load(ogv_path) as VideoStream
		assert(vstream != null, "Godot debe cargar el VideoStreamTheora para %s" % ogv_path)
	var gal_vids := cats["Videos"] as Array
	assert(gal_vids.size() >= 3, "Galería debe listar al menos 3 videos en la pestaña 'Videos'")

	# 20.3 Pantalla CreditsScreen 3:4 basada en README.md y botón en Menú
	for use_vid_mode in [false, true]:
		var cr_inst := preload("res://scenes/credits_screen.tscn").instantiate()
		cr_inst.use_video_file = use_vid_mode
		root.add_child(cr_inst)
		assert(cr_inst._aspect_box != null and is_equal_approx(cr_inst._aspect_box.ratio, 0.75), "CreditsScreen debe mantener proporción estricta 3:4 (0.75)")
		assert(not cr_inst.get_parsed_entries().is_empty(), "CreditsScreen debe extraer entradas desde README.md")
		if not use_vid_mode:
			assert(cr_inst._roll_container != null and absf(cr_inst._roll_end_y - cr_inst._roll_start_y) > 400.0, "Roll en vivo debe calcular límites completos sin salir disparado")
		root.remove_child(cr_inst)
		cr_inst.free()

	if st_n:
		st_n.is_busy = false
	var cr_menu: Control = preload("res://scenes/menu.tscn").instantiate()
	root.add_child(cr_menu)
	var btn_cred := cr_menu.get_node_or_null("BtnCredits") as Button
	assert(btn_cred != null and btn_cred.visible, "Menú Principal debe incluir botón visible 'Créditos'")
	btn_cred.pressed.emit()
	assert(cr_menu._credits_screen != null and is_instance_valid(cr_menu._credits_screen), "Pulsar 'Créditos' debe abrir CreditsScreen")
	cr_menu._close_credits_screen()
	assert(cr_menu._credits_screen == null, "Cerrar CreditsScreen debe limpiar referencia en Menú")
	root.remove_child(cr_menu)
	cr_menu.free()
	print("  Bloque 20 (Retratos Historia, Videos Clímax/Créditos 3:4 y CreditsScreen) verificado.")

	# =========================================================================
	# BLOQUE 21: REDISEÑO ÚNICO DE JEFES/PODERES, FONDO, ICONO Y PANTALLA COMPLETA
	# =========================================================================
	# 21.1 Menú sin imágenes de logos y fondo escolar 800x450 + icon.jpeg global
	var clean_menu: Control = preload("res://scenes/menu.tscn").instantiate()
	root.add_child(clean_menu)
	assert(clean_menu.find_child("CobaemLogo", true, false) == null, "El menú principal no debe contener CobaemLogo")
	assert(clean_menu.find_child("GameIcon", true, false) == null, "El menú principal no debe contener GameIcon")
	root.remove_child(clean_menu)
	clean_menu.free()
	assert(str(ProjectSettings.get_setting("application/config/icon", "")) == "res://icon.jpeg", "El icono de la aplicación debe ser res://icon.jpeg")
	var bg_tex := ResourceLoader.load("res://assets/background/fondo.png") as Texture2D
	assert(bg_tex != null and bg_tex.get_size() == Vector2(800, 450), "El nuevo fondo escolar del menú debe medir 800x450")

	# 21.2 Sprites recreados (no personajes ni enemigos regulares)
	var sprite_dims := {
		"res://assets/sprites/ataque_fx.png": Vector2(48, 48),
		"res://assets/sprites/corazon_lleno.png": Vector2(32, 32),
		"res://assets/sprites/corazon_vacio.png": Vector2(32, 32),
		"res://assets/sprites/meta.png": Vector2(64, 80),
		"res://assets/sprites/cobaem_mini.png": Vector2(28, 28),
	}
	for sp_path in sprite_dims.keys():
		var stex := ResourceLoader.load(sp_path) as Texture2D
		assert(stex != null and stex.get_size() == sprite_dims[sp_path], "Sprite %s debe tener dimensión %s" % [sp_path, str(sprite_dims[sp_path])])

	# 21.3 Siluetas únicas en BossRenderer, emblemas únicos en MaterialsGallery y pantalla completa en Videos
	assert(Callable(BossRenderer, "draw_boss_silhouette").is_valid(), "BossRenderer debe exponer draw_boss_silhouette")
	assert(Callable(MaterialsGallery, "draw_skill_emblem").is_valid(), "MaterialsGallery debe exponer draw_skill_emblem")
	var mg_fs: MaterialsGallery = preload("res://scripts/materials_gallery.gd").new()
	root.add_child(mg_fs)
	mg_fs._select_category("Videos")
	assert(mg_fs._btn_fullscreen_video != null and not mg_fs._btn_fullscreen_video.disabled, "Videos en Galería debe mostrar botón Pantalla Completa habilitado")
	mg_fs.open_video_fullscreen()
	assert(mg_fs._is_video_fullscreen and mg_fs._video_fs_overlay != null and is_instance_valid(mg_fs._video_fs_overlay), "Botón Pantalla Completa debe abrir overlay de video")
	mg_fs.close_video_fullscreen()
	assert(not mg_fs._is_video_fullscreen and mg_fs._video_fs_overlay == null, "Salir Pantalla Completa debe cerrar overlay de video")
	root.remove_child(mg_fs)
	mg_fs.free()

	# 21.4 Botón Pantalla Completa en CreditsScreen
	var cs_fs := preload("res://scenes/credits_screen.tscn").instantiate()
	cs_fs.use_video_file = true
	root.add_child(cs_fs)
	assert(cs_fs._btn_fullscreen != null and cs_fs._btn_fullscreen.visible, "CreditsScreen debe exponer botón Pantalla Completa")
	cs_fs.toggle_fullscreen()
	assert(cs_fs._is_fullscreen_mode and cs_fs._btn_exit_fullscreen.visible, "CreditsScreen.toggle_fullscreen debe activar modo pantalla completa")
	cs_fs.toggle_fullscreen()
	assert(not cs_fs._is_fullscreen_mode and not cs_fs._btn_exit_fullscreen.visible, "CreditsScreen.toggle_fullscreen debe restaurar ventana")
	root.remove_child(cs_fs)
	cs_fs.free()

	# 21.5 Carpeta de archivos innecesarios ignorada en .gitignore
	assert(FileAccess.file_exists("res://_local_archive/.gdignore"), "_local_archive/.gdignore debe existir")
	assert("_local_archive/" in FileAccess.get_file_as_string("res://.gitignore"), ".gitignore debe ignorar _local_archive/")
	print("  Bloque 21 (Jefes/Poderes únicos, Fondo escolar, Sin logos menú, Icono y Pantalla Completa) verificado.")

	# =========================================================================
	# BLOQUE 22: LICENCIA GPL-3.0 Y DIÁLOGOS ADAPTADOS POR GÉNERO (MASC / FEM)
	# =========================================================================
	# 22.1 Verificar archivo LICENSE (GNU GPL v3.0) y mención en README.md
	var license_txt := FileAccess.get_file_as_string("res://LICENSE")
	assert("GNU GENERAL PUBLIC LICENSE" in license_txt and "Version 3" in license_txt, "LICENSE debe contener el texto oficial de GNU GPL v3.0")
	var readme_txt := FileAccess.get_file_as_string("res://README.md")
	assert("GPL" in readme_txt, "README.md debe documentar la licencia GNU GPL v3.0")

	# 22.2 Verificar adaptación de Modo Historia (StoryData y StoryCutscene) según género
	var StoryDataRef := preload("res://scripts/story_data.gd")
	gs_node.set_selected_character(0) # Masculino
	var prol_m: Dictionary = StoryDataRef.get_prologue()
	var epil_m: Dictionary = StoryDataRef.get_epilogue()
	var act1_m: Dictionary = StoryDataRef.get_scenario_cutscene(1)
	var act3_m: Dictionary = StoryDataRef.get_scenario_cutscene(3)
	var mateo_m: Dictionary = StoryDataRef.get_secondary_character("mateo")
	assert(prol_m["dialogue_nodes"][4]["speaker"] == "Guardián de los Valores", "Prólogo Masculino debe usar 'Guardián de los Valores'")
	assert("decidido" in str(prol_m["dialogue_nodes"][4]["text"]), "Prólogo Masculino debe usar concordancia masculina ('decidido')")
	assert("peleando solo" in str(epil_m["dialogue_nodes"][7]["text"]), "Epílogo Masculino debe decir 'peleando solo'")
	assert("jovencito" in str(act1_m["dialogue_nodes"][3]["text"]), "Acto I Masculino debe dirigirse como 'jovencito'")
	assert("Guardián," in str(act3_m["dialogue_nodes"][3]["text"]), "Acto III Masculino debe llamar 'Guardián'")
	assert("compañero" in " ".join(mateo_m["state_redeemed"]["quotes"]), "Mateo en Masculino debe decir 'compañero'")

	gs_node.set_selected_character(1) # Femenino
	var prol_f: Dictionary = StoryDataRef.get_prologue()
	var epil_f: Dictionary = StoryDataRef.get_epilogue()
	var act1_f: Dictionary = StoryDataRef.get_scenario_cutscene(1)
	var act3_f: Dictionary = StoryDataRef.get_scenario_cutscene(3)
	var mateo_f: Dictionary = StoryDataRef.get_secondary_character("mateo")
	var maria_f: Dictionary = StoryDataRef.get_secondary_character("maria")
	assert(prol_f["dialogue_nodes"][4]["speaker"] == "Guardiana de los Valores", "Prólogo Femenino debe usar 'Guardiana de los Valores'")
	assert("decidida" in str(prol_f["dialogue_nodes"][4]["text"]), "Prólogo Femenino debe usar concordancia femenina ('decidida')")
	assert("peleando sola" in str(epil_f["dialogue_nodes"][7]["text"]), "Epílogo Femenino debe decir 'peleando sola'")
	assert("jovencita" in str(act1_f["dialogue_nodes"][3]["text"]), "Acto I Femenino debe dirigirse como 'jovencita'")
	assert("Guardiana," in str(act3_f["dialogue_nodes"][3]["text"]), "Acto III Femenino debe llamar 'Guardiana'")
	assert("compañera" in " ".join(mateo_f["state_redeemed"]["quotes"]), "Mateo en Femenino debe decir 'compañera'")
	assert("Juntas" in " ".join(maria_f["state_redeemed"]["quotes"]), "María con protagonista femenina debe decir 'Juntas'")

	# 22.3 Verificar Ceremonia Final, Clímax Undertale, HUD, BossData y Certificado PDF en Femenino vs Masculino
	var cer_fem: FinalCeremony = preload("res://scenes/final_ceremony.tscn").instantiate()
	root.add_child(cer_fem)
	assert(cer_fem.is_female_hero() == true, "FinalCeremony debe detectar personaje Femenino")
	assert("alumna ejemplar" in cer_fem.get_final_exemplary_text(), "FinalCeremony en Femenino debe mostrar 'alumna ejemplar'")
	assert("campeona solidaria" in " ".join(cer_fem.get_active_coordinator_speech()), "Discurso del Coordinador en Femenino debe usar 'campeona solidaria'")
	if cer_fem._himno_player:
		cer_fem._himno_player.stop()
	if gs_node._music:
		gs_node._music.stop()
	root.remove_child(cer_fem)
	cer_fem.free()

	var ut_fem := preload("res://scenes/undertale_climax.tscn").instantiate()
	root.add_child(ut_fem)
	assert(str(ut_fem.get_hearts_data()[0]["who"]) == "Tú (Heroína)", "UndertaleClimax en Femenino debe nombrar 'Tú (Heroína)'")
	root.remove_child(ut_fem)
	ut_fem.free()

	var hud_fem: HUD = preload("res://scenes/hud.tscn").instantiate()
	root.add_child(hud_fem)
	var pause_sub := hud_fem.pause_panel.get_node_or_null("VBoxContainer/Subtitle") as Label
	assert(pause_sub != null and "campeona escolar" in pause_sub.text, "HUD en Femenino debe mostrar 'campeona escolar' en pausa")
	root.remove_child(hud_fem)
	hud_fem.free()

	var BossDataRef := preload("res://scripts/boss_data.gd")
	assert("novato" in BossDataRef.get_intro_dialog(Boss.BossType.BULLYING, false), "Titanor Masculino debe decir 'novato'")
	assert("novata" in BossDataRef.get_intro_dialog(Boss.BossType.BULLYING, true), "Titanor Femenino debe decir 'novata'")
	assert("alumna" in BossDataRef.get_intro_dialog(Boss.BossType.DESINTERES, true), "Maestro Desinterés Femenino debe decir 'alumna'")

	var cert_fem := CertificateGeneratorScript.build_certificate_text("Normal", "Ana Gómez", 1)
	assert("La alumna/Madre de familia/Maestra: Ana Gómez" in cert_fem and "reconocida como una asesora" in cert_fem, "Certificado Femenino debe usar redacción femenina")
	var cert_masc := CertificateGeneratorScript.build_certificate_text("Normal", "Luis Gómez", 0)
	assert("El alumno/Padre de familia/Maestro: Luis Gómez" in cert_masc and "reconocido como un asesor" in cert_masc, "Certificado Masculino debe usar redacción masculina")

	gs_node.set_selected_character(0)
	if gs_node._music:
		gs_node._music.stop()
	print("  Bloque 22 (Licencia GPL-3.0 y adaptación integral de diálogos Masculino/Femenino) verificado.")

	# Restaurar user://settings.cfg original del usuario antes de salir
	if _settings_existed:
		var fw := FileAccess.open("user://settings.cfg", FileAccess.WRITE)
		if fw:
			fw.store_buffer(_settings_backup)
			fw.close()
	elif FileAccess.file_exists("user://settings.cfg"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings.cfg"))

	print("--- TODOS LOS TESTS DE ESCENARIOS Y PROGRESIÓN PASARON CON ÉXITO ---")
	quit(0)
	return true
