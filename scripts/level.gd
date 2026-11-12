extends Node2D
class_name Level

## Controlador de escenario individual en perspectiva 3/4.
## Carga la imagen de fondo, genera límites perimetrales y obstáculos,
## e instancia al jugador, enemigos y la meta con ordenamiento Y-Sort.

signal player_health_changed(current: int, max_hp: int)
signal player_died
signal enemy_defeated(enemy: Enemy)
signal boss_spawned(boss: CharacterBody2D)
signal boss_health_changed(current: int, max_hp: int)
signal boss_redeemed(boss: CharacterBody2D)
signal quota_updated(defeated: int, quota: int)
signal enter_classroom_requested(classroom_idx: int)
signal level_completed

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const GOAL_SCENE := preload("res://scenes/goal.tscn")
const BossClass := preload("res://scripts/boss.gd")
const StudentClass := preload("res://scripts/student.gd")
const ClassroomDoorClass := preload("res://scripts/classroom_door.gd")
const FogOverlayClass := preload("res://scripts/fog_overlay.gd")

@onready var background: Sprite2D = $Background
@onready var world_boundaries: StaticBody2D = $WorldBoundaries
@onready var obstacles: StaticBody2D = $Obstacles
@onready var entities: Node2D = $Entities
@onready var enemies_container: Node2D = $Entities/Enemies

var player: Player = null
var goal: Goal = null
var boss: CharacterBody2D = null
var classroom_door: Area2D = null
var fog_overlay: Node2D = null
var students: Array = []
var map_size: Vector2 = Vector2(800, 450)
var level_data: Dictionary = {}

var quota_to_boss: int = 3
var defeated_in_level: int = 0
var boss_defeated: bool = false
var has_classroom: bool = false
var is_classroom_cleared: bool = false
var is_hard_mode: bool = false

var _hard_enemy_templates: Array = []
var _hard_enemies_spawned: int = 0
var _hard_wave_active_count: int = 0
var _boss_battle_timer: float = 0.0
var _fog_triggered_by_timeout: bool = false

func _ensure_nodes() -> void:
	if background == null:
		background = get_node_or_null("Background")
	if world_boundaries == null:
		world_boundaries = get_node_or_null("WorldBoundaries")
	if obstacles == null:
		obstacles = get_node_or_null("Obstacles")
	if entities == null:
		entities = get_node_or_null("Entities")
	if enemies_container == null and entities != null:
		enemies_container = entities.get_node_or_null("Enemies")

## Configura el escenario a partir de un diccionario de definición de nivel
func setup_level(data: Dictionary) -> void:
	_ensure_nodes()
	level_data = data

	if entities:
		entities.y_sort_enabled = true
	if enemies_container:
		enemies_container.y_sort_enabled = true

	# 1. Cargar imagen de fondo del escenario
	var image_path: String = data.get("scenario_image", "")
	var tex: Texture2D = null
	if ResourceLoader.exists(image_path):
		tex = load(image_path)
	elif FileAccess.file_exists(image_path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(image_path))
		if img:
			tex = ImageTexture.create_from_image(img)
	elif ResourceLoader.exists("res://assets/background/fondo.png"):
		tex = load("res://assets/background/fondo.png")

	if tex:
		if background:
			background.texture = tex
		map_size = Vector2(tex.get_width(), tex.get_height())
	else:
		map_size = Vector2(1200, 800)

	# 2. Configurar colisiones de frontera exterior
	_build_boundary_walls(map_size)

	# 3. Construir obstáculos sólidos del escenario
	_build_obstacles(data.get("obstacles", []))

	# 4. Instanciar al jugador
	player = PLAYER_SCENE.instantiate()
	player.position = data.get("player_spawn", Vector2(90.0, map_size.y * 0.5))
	if entities:
		entities.add_child(player)

	player.health_changed.connect(func(c, m): player_health_changed.emit(c, m))
	player.died.connect(func(): player_died.emit())

	# Ajustar límites de cámara a las dimensiones del mapa
	if player.camera:
		player.camera.limit_left = 0
		player.camera.limit_top = 0
		player.camera.limit_right = int(map_size.x)
		player.camera.limit_bottom = int(map_size.y)
		player.camera.reset_smoothing()

	# 5. Instanciar la meta de salida (inicia bloqueada hasta vencer al jefe)
	goal = GOAL_SCENE.instantiate()
	goal.position = data.get("goal_position", Vector2(map_size.x - 90.0, map_size.y * 0.5))
	goal.level_ref = self
	if entities:
		entities.add_child(goal)
	goal.set_goal_text(data.get("goal_label", "META"))
	goal.set_locked(true)
	goal.player_reached_goal.connect(_on_goal_reached)

	# 5.5. Instanciar entrada al salón de clases en el exterior si aplica
	has_classroom = data.has("classroom_entrance_pos") and not data.get("is_classroom", false)
	is_classroom_cleared = data.get("is_classroom_cleared", false)
	if has_classroom:
		classroom_door = ClassroomDoorClass.new()
		classroom_door.position = data.get("classroom_entrance_pos")
		classroom_door.classroom_index = int(data.get("classroom_index", 0))
		classroom_door.classroom_name = str(data.get("classroom_name", "Salón de Clases"))
		classroom_door.is_cleared = is_classroom_cleared
		classroom_door.player_entered_classroom.connect(func(idx: int): enter_classroom_requested.emit(idx))
		if entities:
			entities.add_child(classroom_door)

	# 6. Instanciar estudiantes secundarios (alumnos del CEMSaD 22)
	students.clear()
	var student_list: Array = data.get("students", [])
	for s_info in student_list:
		var student = StudentClass.new()
		student.position = s_info.get("pos", Vector2(map_size.x * 0.5, map_size.y * 0.5))
		student.student_name = s_info.get("name", "Estudiante")
		student.gender = s_info.get("gender", 0)
		student.initial_state = s_info.get("initial_state", 0)
		student.player = player
		if entities:
			entities.add_child(student)
		students.append(student)

	# 7. Configuración de dificultad, niebla y cuota de antivalores
	var gs: Node = null
	if is_inside_tree():
		gs = get_node_or_null("/root/GameSettings")
	if gs == null:
		var p := get_parent()
		while p != null and gs == null:
			gs = p.get_node_or_null("GameSettings")
			p = p.get_parent()
	is_hard_mode = (gs != null and gs.get("difficulty") == 2)
	var is_classroom: bool = data.get("is_classroom", false)

	defeated_in_level = 0
	boss_defeated = false
	boss = null
	_boss_battle_timer = 0.0
	_fog_triggered_by_timeout = false
	_hard_enemies_spawned = 0
	_hard_wave_active_count = 0

	# Instanciar Niebla del Desinterés (activa en salones o en modo difícil)
	if is_classroom or is_hard_mode:
		fog_overlay = FogOverlayClass.new()
		fog_overlay.map_size = map_size
		fog_overlay.light_sources = [player]
		for s in students:
			if is_instance_valid(s):
				fog_overlay.light_sources.append(s)
		fog_overlay.enemies_container = enemies_container
		add_child(fog_overlay)
		if is_hard_mode:
			fog_overlay.set_fog(true, true)
		else:
			fog_overlay.set_fog(false, true)

	# 8. Instanciar grupo de enemigos
	var enemy_list: Array = data.get("enemies", [])
	if is_hard_mode:
		# En Modo Difícil: 10 enemigos que aparecen de 3 en 3 con niebla inicial
		quota_to_boss = 10
		_hard_enemy_templates = enemy_list.duplicate()
		if _hard_enemy_templates.is_empty():
			_hard_enemy_templates = [
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(map_size.x * 0.5, map_size.y * 0.4) },
				{ "type": Enemy.Type.BULLYING, "pos": Vector2(map_size.x * 0.6, map_size.y * 0.55) },
				{ "type": Enemy.Type.ACOSO, "pos": Vector2(map_size.x * 0.4, map_size.y * 0.55) },
			]
		_spawn_hard_wave(3)
	else:
		quota_to_boss = data.get("quota_to_boss", 3)
		for e_info in enemy_list:
			var enemy: Enemy = ENEMY_SCENE.instantiate()
			enemy.enemy_type = e_info.get("type", Enemy.Type.GROSERIA)
			enemy.position = e_info.get("pos", Vector2(map_size.x * 0.5, map_size.y * 0.5))
			enemy.player = player
			if is_classroom:
				# En el salón de clases, rodean al alumno y atacan de inmediato al ver al héroe
				enemy.wander_radius = 25.0
				enemy.detection_range = 360.0
			enemy.defeated.connect(_on_enemy_defeated)
			if enemies_container:
				enemies_container.add_child(enemy)

func _spawn_hard_wave(count: int) -> void:
	if _hard_enemy_templates.is_empty():
		return
	var is_classroom: bool = level_data.get("is_classroom", false)
	var to_spawn := mini(count, 10 - _hard_enemies_spawned)
	for i in range(to_spawn):
		var tpl: Dictionary = _hard_enemy_templates[_hard_enemies_spawned % _hard_enemy_templates.size()]
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.enemy_type = tpl.get("type", Enemy.Type.GROSERIA)
		var base_pos: Vector2 = tpl.get("pos", Vector2(map_size.x * 0.5, map_size.y * 0.5))
		var offset := Vector2.ZERO
		if _hard_enemies_spawned >= _hard_enemy_templates.size():
			offset = Vector2(float((i - 1) * 26), float(((i % 2) * 2 - 1) * 18))
		enemy.position = Vector2(
			clampf(base_pos.x + offset.x, 60.0, map_size.x - 60.0),
			clampf(base_pos.y + offset.y, 95.0, map_size.y - 60.0)
		)
		enemy.player = player
		enemy.allow_respawn = false
		if is_classroom:
			enemy.wander_radius = 25.0
			enemy.detection_range = 380.0
		enemy.defeated.connect(_on_enemy_defeated)
		if enemies_container:
			enemies_container.add_child(enemy)
		_hard_enemies_spawned += 1
		_hard_wave_active_count += 1

func _physics_process(delta: float) -> void:
	# En Fácil/Normal: si la batalla contra el Maestro tarda 1 minuto (60s) o más, aparece la Niebla del Desinterés
	if not is_hard_mode and boss != null and is_instance_valid(boss) and not boss_defeated:
		_boss_battle_timer += delta
		if _boss_battle_timer >= 60.0 and not _fog_triggered_by_timeout:
			_fog_triggered_by_timeout = true
			if fog_overlay == null:
				fog_overlay = FogOverlayClass.new()
				fog_overlay.map_size = map_size
				fog_overlay.light_sources = [player]
				for s in students:
					if is_instance_valid(s):
						fog_overlay.light_sources.append(s)
				fog_overlay.enemies_container = enemies_container
				add_child(fog_overlay)
			fog_overlay.boss_node = boss
			fog_overlay.set_fog(true)
			if boss.has_method("set_fog_active"):
				boss.set_fog_active(true)
			var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
			if fx:
				fx.shake(4.0, 0.35)
				fx.floating_text(self, boss.global_position + Vector2(0, -65), "¡LA NIEBLA DEL DESINTERÉS CUBRE EL SALÓN!", Color(1.0, 0.25, 0.35), 14)

func set_classroom_cleared(cleared: bool) -> void:
	is_classroom_cleared = cleared
	if classroom_door and is_instance_valid(classroom_door):
		classroom_door.update_state(cleared)

func _on_enemy_defeated(enemy: Node2D) -> void:
	defeated_in_level += 1
	if enemy is Enemy:
		enemy_defeated.emit(enemy)
	quota_updated.emit(defeated_in_level, quota_to_boss)

	# Aliviar a alumnos en la zona de influencia del antivalor redimido
	for s in students:
		if is_instance_valid(s):
			s.cheer_up_area(enemy.global_position, 280.0)

	# Control de oleadas de 3 en 3 y disipación de niebla en Modo Difícil
	if is_hard_mode:
		_hard_wave_active_count = maxi(0, _hard_wave_active_count - 1)
		if defeated_in_level < quota_to_boss:
			if _hard_wave_active_count == 0 and _hard_enemies_spawned < 10:
				var next_batch := mini(3, 10 - _hard_enemies_spawned)
				_spawn_hard_wave(next_batch)
				var fx_w = get_node_or_null("/root/Fx") if is_inside_tree() else null
				if fx_w and player and is_instance_valid(player):
					fx_w.floating_text(self, player.global_position + Vector2(0, -48), "¡Oleada de antivalores (%d/10)!" % _hard_enemies_spawned, Color(1.0, 0.55, 0.3), 13)
		elif defeated_in_level >= quota_to_boss:
			if fog_overlay and is_instance_valid(fog_overlay):
				fog_overlay.set_fog(false)
			var fx_f = get_node_or_null("/root/Fx") if is_inside_tree() else null
			if fx_f and player and is_instance_valid(player):
				fx_f.floating_text(self, player.global_position + Vector2(0, -55), "¡La niebla del desinterés desaparece!", Color(0.45, 1.0, 0.7), 15)

	# Si es un salón de clases y se liberó al alumno acorralado
	if level_data.get("is_classroom", false) and defeated_in_level >= quota_to_boss:
		for s in students:
			if is_instance_valid(s):
				s.cheer_up()
				var fx_s = get_node_or_null("/root/Fx") if is_inside_tree() else null
				if fx_s:
					fx_s.floating_text(self, s.global_position + Vector2(0, -55), "¡Gracias por defenderme!", Color(1.0, 0.95, 0.4), 14)

	# Si se cumple la cuota requerida y aún no hay jefe, invocar al Jefe de Escenario
	if defeated_in_level >= quota_to_boss and boss == null and not boss_defeated:
		_spawn_boss()

func _spawn_boss() -> void:
	# Detener reaparición de enemigos normales para enfocar el combate en el jefe
	if enemies_container:
		for e in enemies_container.get_children():
			if e is Enemy:
				e.stop_respawns()

	boss = BossClass.new()
	boss.boss_type = level_data.get("boss_type", 0)
	boss.classroom_index = int(level_data.get("classroom_index", 0))
	boss.position = level_data.get("boss_spawn", level_data.get("goal_position", Vector2(500, 400)))
	boss.player = player
	boss.health_changed.connect(func(c, m): boss_health_changed.emit(c, m))
	boss.redeemed.connect(_on_boss_redeemed)
	if entities:
		entities.add_child(boss)
	if fog_overlay and is_instance_valid(fog_overlay):
		fog_overlay.boss_node = boss
	boss_spawned.emit(boss)

	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx:
		var boss_title := "¡APARECIÓ EL JEFE!"
		if level_data.get("boss_type", 0) == 6: # Boss.BossType.DESINTERES
			boss_title = "¡MAESTRO DESINTERÉS CONFRONTADO!"
		fx.shake(5.0, 0.45)
		fx.floating_text(self, boss.position + Vector2(0, -50), boss_title, Color(1.0, 0.35, 0.45), 16)

func _on_boss_redeemed(b: CharacterBody2D) -> void:
	boss_defeated = true
	if fog_overlay and is_instance_valid(fog_overlay):
		fog_overlay.set_fog(false)
	if b and b.has_method("set_fog_active"):
		b.set_fog_active(false)
	boss_redeemed.emit(b)

	# Desbloquear meta de salida
	if goal and is_instance_valid(goal):
		goal.unlock()

	# Transicionar a TODOS los estudiantes del escenario al estado alegre
	for s in students:
		if is_instance_valid(s):
			s.cheer_up()

	# Detener a todos los enemigos restantes
	stop_enemies()

	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx:
		var banner_text := "¡ANTIVALOR MAYOR REDIMIDO!"
		if level_data.get("boss_type", 0) == 6:
			banner_text = "¡MAESTRO DESINTERÉS REDIMIDO!"
		fx.floating_text(self, b.position + Vector2(0, -60), banner_text, Color(1.0, 0.95, 0.40), 16)
		fx.shake(4.0, 0.3)

func _on_goal_reached() -> void:
	if player and is_instance_valid(player):
		player.celebrate()
	stop_enemies()
	level_completed.emit()

## Detiene el movimiento de todos los enemigos en el escenario
func stop_enemies() -> void:
	if enemies_container:
		for enemy in enemies_container.get_children():
			if enemy is Enemy:
				enemy.stop()

## Construye cuatro muros de colisión perimetrales para delimitar el mapa
func _build_boundary_walls(size: Vector2) -> void:
	if world_boundaries == null:
		return
	for child in world_boundaries.get_children():
		child.queue_free()

	var wall_thickness := 50.0

	# Muro Superior
	_add_wall_box(Vector2(size.x * 0.5, -wall_thickness * 0.5), Vector2(size.x + wall_thickness * 2, wall_thickness))
	# Muro Inferior
	_add_wall_box(Vector2(size.x * 0.5, size.y + wall_thickness * 0.5), Vector2(size.x + wall_thickness * 2, wall_thickness))
	# Muro Izquierdo
	_add_wall_box(Vector2(-wall_thickness * 0.5, size.y * 0.5), Vector2(wall_thickness, size.y + wall_thickness * 2))
	# Muro Derecho
	_add_wall_box(Vector2(size.x + wall_thickness * 0.5, size.y * 0.5), Vector2(wall_thickness, size.y + wall_thickness * 2))

func _add_wall_box(center: Vector2, box_size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = box_size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = center
	world_boundaries.add_child(col)

## Instancia las cajas de colisión para los obstáculos declarados en el nivel
func _build_obstacles(obs_list: Array) -> void:
	if obstacles == null:
		return
	for child in obstacles.get_children():
		child.queue_free()

	for obs in obs_list:
		var rect: Rect2 = obs if obs is Rect2 else Rect2(obs.get("x", 0), obs.get("y", 0), obs.get("w", 0), obs.get("h", 0))
		if rect.size.x > 0 and rect.size.y > 0:
			var shape := RectangleShape2D.new()
			shape.size = rect.size
			var col := CollisionShape2D.new()
			col.shape = shape
			col.position = rect.position + rect.size * 0.5
			obstacles.add_child(col)
