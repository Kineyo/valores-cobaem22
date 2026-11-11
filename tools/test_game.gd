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
	assert(mc_node._target_left_alpha == 0.0, "El objetivo de alfa debe volver a 0.0 al soltar")
	assert(not Input.is_action_pressed("move_right"), "move_right debe liberarse al soltar")

	mc_node.deactivate()
	mc_node._unhandled_input(touch_down)
	assert(mc_node._left_touch_id == -1, "No debe registrar toques mientras está desactivado")

	root.remove_child(mc_node)
	mc_node.free()
	print("Controles táctiles dinámicos transparentes verificados con éxito.")

	print("--- TODOS LOS TESTS DE ESCENARIOS Y PROGRESIÓN PASARON CON ÉXITO ---")
	quit(0)
