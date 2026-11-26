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
signal boss_undertale_climax_requested(boss: CharacterBody2D)
signal quota_updated(defeated: int, quota: int)
signal enter_classroom_requested(classroom_idx: int)
signal level_completed
signal player_inventory_changed(item_id: String, item_info: Dictionary)
signal esperanza_timer_updated(remaining: float, duration: float)

const ESPERANZA_DURATION: float = 15.0

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const GOAL_SCENE := preload("res://scenes/goal.tscn")
const BossClass := preload("res://scripts/boss.gd")
const StudentClass := preload("res://scripts/student.gd")
const ClassroomDoorClass := preload("res://scripts/classroom_door.gd")
const FogOverlayClass := preload("res://scripts/fog_overlay.gd")
const ScenarioDecorClass := preload("res://scripts/scenario_decor.gd")
const FINAL_BOSS_CELEBRATION_DURATION: float = 7.0
const FINAL_VICTORY_STUDENT_PHRASE: String = "Finalmente lo logramos en equipo."

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
var scenario_decor: Node2D = null
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
var _redeemed_count: int = 0
var esperanza_timer: float = 0.0
var _titanor_esperanza_drop_timer: float = 0.0

var is_final_boss_celebrating: bool = false
var final_boss_celebration_completed: bool = false
var _final_boss_celebration_timer: float = 0.0
var _final_celebration_elapsed: float = 0.0
var _final_celebration_step: int = 0
var _last_celebration_sec: int = -1
var celebration_students: Array[Node2D] = []
var last_boss_banner_text: String = ""

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
	_redeemed_count = 0

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

	# 1.5. Instanciar capa ambiental decorativa sobre el suelo y debajo de Entities
	if scenario_decor and is_instance_valid(scenario_decor):
		scenario_decor.queue_free()
	scenario_decor = ScenarioDecorClass.new()
	add_child(scenario_decor)
	if background and is_instance_valid(background):
		move_child(scenario_decor, background.get_index() + 1)
	scenario_decor.setup_decor(data, map_size)

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
	if player.has_signal("inventory_changed"):
		player.inventory_changed.connect(func(id, info): player_inventory_changed.emit(id, info))
	if player.has_signal("esperanza_activated"):
		player.esperanza_activated.connect(_on_esperanza_activated)

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
		student.level_ref = self
		if entities:
			entities.add_child(student)
		students.append(student)

	# 7. Configuración de dificultad, estado guardado al salir de un salón, niebla y cuota de antivalores
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
	var returning_from_classroom: bool = data.get("returning_from_classroom", false)
	var exterior_already_cleared: bool = data.get("exterior_boss_defeated", false)
	var saved_defeated: int = int(data.get("saved_defeated_in_level", 0))

	if returning_from_classroom and player and player.has_method("grant_spawn_protection"):
		player.grant_spawn_protection(2.0)

	quota_to_boss = 10 if is_hard_mode else int(data.get("quota_to_boss", 3))
	defeated_in_level = clampi(saved_defeated, 0, quota_to_boss) if not exterior_already_cleared else quota_to_boss
	boss_defeated = exterior_already_cleared
	boss = null
	_boss_battle_timer = 0.0
	_fog_triggered_by_timeout = false
	_hard_enemies_spawned = clampi(defeated_in_level, 0, 10) if is_hard_mode else 0
	_hard_wave_active_count = 0

	# Instanciar Niebla del Desinterés (activa en salones o en modo difícil cuando aún no se limpia la zona)
	if is_classroom or is_hard_mode:
		fog_overlay = FogOverlayClass.new()
		fog_overlay.map_size = map_size
		fog_overlay.light_sources = [player]
		for s in students:
			if is_instance_valid(s):
				fog_overlay.light_sources.append(s)
		fog_overlay.enemies_container = enemies_container
		add_child(fog_overlay)
		if is_hard_mode and not exterior_already_cleared and defeated_in_level < quota_to_boss:
			fog_overlay.set_fog(true, true)
		else:
			fog_overlay.set_fog(false, true)

	if exterior_already_cleared:
		# Si la zona exterior ya fue limpiada antes de entrar al salón, no reaparecer enemigos inmóviles
		if goal and is_instance_valid(goal):
			goal.unlock()
		for s in students:
			if is_instance_valid(s):
				s.cheer_up()
	else:
		# 8. Instanciar grupo de enemigos en posiciones seguras respecto a la salida del jugador
		var enemy_list: Array = data.get("enemies", [])
		var grace_sec: float = 1.2 if returning_from_classroom else 0.0
		if is_hard_mode:
			_hard_enemy_templates = enemy_list.duplicate()
			if _hard_enemy_templates.is_empty():
				_hard_enemy_templates = [
					{ "type": Enemy.Type.GROSERIA, "pos": Vector2(map_size.x * 0.5, map_size.y * 0.4) },
					{ "type": Enemy.Type.BULLYING, "pos": Vector2(map_size.x * 0.6, map_size.y * 0.55) },
					{ "type": Enemy.Type.ACOSO, "pos": Vector2(map_size.x * 0.4, map_size.y * 0.55) },
				]
			if _hard_enemies_spawned < 10:
				_spawn_hard_wave(3, grace_sec)
		else:
			if defeated_in_level < quota_to_boss:
				for e_info in enemy_list:
					var enemy: Enemy = ENEMY_SCENE.instantiate()
					enemy.enemy_type = e_info.get("type", Enemy.Type.GROSERIA)
					var raw_pos: Vector2 = e_info.get("pos", Vector2(map_size.x * 0.5, map_size.y * 0.5))
					enemy.position = _ensure_safe_enemy_spawn_pos(raw_pos)
					enemy.player = player
					enemy.spawn_grace_timer = grace_sec
					if is_classroom:
						# En el salón de clases, rodean al alumno y atacan de inmediato al ver al héroe
						enemy.wander_radius = 25.0
						enemy.detection_range = 360.0
					enemy.defeated.connect(_on_enemy_defeated, CONNECT_DEFERRED)
					if enemies_container:
						enemies_container.add_child(enemy)

		if defeated_in_level >= quota_to_boss and boss == null and not boss_defeated:
			_spawn_boss()

func _is_point_blocked_by_obstacle(pos: Vector2, pad: float = 20.0) -> bool:
	var obs_list: Array = level_data.get("obstacles", [])
	for obs in obs_list:
		var rect: Rect2 = obs if obs is Rect2 else Rect2(obs.get("x", 0), obs.get("y", 0), obs.get("w", 0), obs.get("h", 0))
		if rect.grow(pad).has_point(pos):
			return true
	return false

func _ensure_safe_enemy_spawn_pos(desired_pos: Vector2) -> Vector2:
	if player == null or not is_instance_valid(player):
		return desired_pos
	var min_dist: float = 210.0
	var min_dist_sq: float = min_dist * min_dist
	if desired_pos.distance_squared_to(player.position) >= min_dist_sq and not _is_point_blocked_by_obstacle(desired_pos, 14.0):
		return desired_pos

	var p_pos := player.position
	var angles: Array[float] = [0.0, PI, PI * 0.25, -PI * 0.25, PI * 0.75, -PI * 0.75, PI * 0.5, -PI * 0.5]
	var radii: Array[float] = [230.0, 280.0, 340.0, 420.0]
	for r: float in radii:
		for ang: float in angles:
			var cand: Vector2 = p_pos + Vector2(cos(ang), sin(ang)) * r
			if cand.x < 60.0 or cand.x > map_size.x - 60.0 or cand.y < 75.0 or cand.y > map_size.y - 60.0:
				continue
			if not _is_point_blocked_by_obstacle(cand, 20.0) and cand.distance_squared_to(p_pos) >= min_dist_sq:
				return cand

	var fxs: Array[float] = [0.75, 0.25, 0.60, 0.40, 0.85, 0.15]
	var fys: Array[float] = [0.50, 0.35, 0.65, 0.25, 0.75]
	for fx: float in fxs:
		for fy: float in fys:
			var fallback: Vector2 = Vector2(map_size.x * fx, map_size.y * fy)
			if not _is_point_blocked_by_obstacle(fallback, 20.0) and fallback.distance_squared_to(p_pos) >= min_dist_sq:
				return fallback

	return desired_pos

func _spawn_hard_wave(count: int, grace_sec: float = 0.0) -> void:
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
		var raw_pos := Vector2(
			clampf(base_pos.x + offset.x, 60.0, map_size.x - 60.0),
			clampf(base_pos.y + offset.y, 95.0, map_size.y - 60.0)
		)
		enemy.position = _ensure_safe_enemy_spawn_pos(raw_pos)
		enemy.player = player
		enemy.allow_respawn = false
		enemy.spawn_grace_timer = grace_sec
		if is_classroom:
			enemy.wander_radius = 25.0
			enemy.detection_range = 380.0
		enemy.defeated.connect(_on_enemy_defeated, CONNECT_DEFERRED)
		if enemies_container:
			enemies_container.add_child(enemy)
		_hard_enemies_spawned += 1
		_hard_wave_active_count += 1

func _physics_process(delta: float) -> void:
	if is_final_boss_celebrating:
		_update_final_boss_celebration(delta)

	if esperanza_timer > 0.0:
		esperanza_timer = maxf(0.0, esperanza_timer - delta)
		esperanza_timer_updated.emit(esperanza_timer, ESPERANZA_DURATION)
		if fog_overlay and is_instance_valid(fog_overlay) and fog_overlay.is_fog_active:
			fog_overlay.set_fog(false, false)

	if boss != null and is_instance_valid(boss) and not boss_defeated and boss.boss_type == BossClass.BossType.BULLYING and esperanza_timer <= 0.0:
		_titanor_esperanza_drop_timer -= delta
		if _titanor_esperanza_drop_timer <= 0.0:
			_titanor_esperanza_drop_timer = 42.0 if is_hard_mode else 30.0
			_ensure_esperanza_pickup_available()

	# En Fácil/Normal: si la batalla contra el Maestro Desinterés tarda 1 minuto (60s) o más, aparece la Niebla del Desinterés
	if not is_hard_mode and esperanza_timer <= 0.0 and boss != null and is_instance_valid(boss) and not boss_defeated and boss.boss_type == BossClass.BossType.DESINTERES:
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
				fx.floating_text(self, boss.global_position + Vector2(0, -65), "La niebla del desinterés cubre el salón.", Color(1.0, 0.25, 0.35), 14)

func set_classroom_cleared(cleared: bool) -> void:
	is_classroom_cleared = cleared
	if classroom_door and is_instance_valid(classroom_door):
		classroom_door.update_state(cleared)

func _on_enemy_defeated(enemy: Node2D) -> void:
	defeated_in_level += 1
	_redeemed_count += 1
	if enemy is Enemy:
		enemy_defeated.emit(enemy)
	quota_updated.emit(defeated_in_level, quota_to_boss)

	if _redeemed_count % 4 == 0:
		var drop_pos := enemy.global_position if is_instance_valid(enemy) else (player.global_position + Vector2(32.0, 0.0) if player and is_instance_valid(player) else map_size * 0.5)
		_spawn_virtue_pickup(drop_pos)

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
					fx_w.floating_text(self, player.global_position + Vector2(0, -48), "Oleada de antivalores (%d/10)" % _hard_enemies_spawned, Color(1.0, 0.55, 0.3), 13)
		elif defeated_in_level >= quota_to_boss:
			if fog_overlay and is_instance_valid(fog_overlay):
				fog_overlay.set_fog(false)
			var fx_f = get_node_or_null("/root/Fx") if is_inside_tree() else null
			if fx_f and player and is_instance_valid(player):
				fx_f.floating_text(self, player.global_position + Vector2(0, -55), "La niebla del desinterés desaparece.", Color(0.45, 1.0, 0.7), 15)

	# Si es un salón de clases y se liberó al alumno acorralado
	if level_data.get("is_classroom", false) and defeated_in_level >= quota_to_boss:
		var gs_cls = get_node_or_null("/root/GameSettings") if is_inside_tree() else null
		var is_fem_cls := gs_cls != null and int(gs_cls.get("selected_character")) == 1
		var thank_msg := "Gracias por defenderme, compañera." if is_fem_cls else "Gracias por defenderme, compañero."
		for s in students:
			if is_instance_valid(s):
				s.cheer_up()
				var fx_s = get_node_or_null("/root/Fx") if is_inside_tree() else null
				if fx_s:
					fx_s.floating_text(self, s.global_position + Vector2(0, -55), thank_msg, Color(1.0, 0.95, 0.4), 14)

	# Si se cumple la cuota requerida y aún no hay jefe, invocar al Jefe de Escenario
	if defeated_in_level >= quota_to_boss and boss == null and not boss_defeated:
		_spawn_boss()

## Genera un ítem pacífico de virtud (Corazón de Esperanza o Escudo de Respeto)
func _spawn_virtue_pickup(pos: Vector2, kind: String = "") -> Area2D:
	var pickup_kind := kind.strip_edges().to_lower()
	if pickup_kind.is_empty():
		if player and is_instance_valid(player) and player.health < player.max_health:
			pickup_kind = "heart"
		else:
			pickup_kind = "shield"

	var pickup := Area2D.new()
	pickup.name = "VirtuePickup_%s" % pickup_kind
	pickup.position = pos
	pickup.collision_layer = 0
	pickup.collision_mask = 2
	pickup.add_to_group("virtue_pickups")
	pickup.set_meta("pickup_kind", pickup_kind)
	pickup.set_meta("collected", false)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	pickup.add_child(shape)

	var visual_root := Node2D.new()
	visual_root.name = "PickupVisual"
	if pickup_kind == "esperanza":
		var star_pts := PackedVector2Array()
		for i in range(10):
			var ang := -PI * 0.5 + float(i) * (TAU / 10.0)
			var r := 13.0 if (i % 2 == 0) else 6.0
			star_pts.append(Vector2(cos(ang), sin(ang)) * r)
		var star := Polygon2D.new()
		star.polygon = star_pts
		star.color = Color(1.0, 0.90, 0.26, 0.98)
		visual_root.add_child(star)
		var core := Polygon2D.new()
		core.polygon = PackedVector2Array([Vector2(0, -5), Vector2(5, 0), Vector2(0, 5), Vector2(-5, 0)])
		core.color = Color(1.0, 0.98, 0.86, 1.0)
		visual_root.add_child(core)
		var halo := Line2D.new()
		halo.points = star_pts
		halo.closed = true
		halo.width = 1.6
		halo.default_color = Color(1.0, 0.96, 0.70, 0.92)
		visual_root.add_child(halo)
	elif pickup_kind == "heart":
		var heart_spr := Sprite2D.new()
		var htex: Texture2D = load("res://assets/sprites/corazon_lleno.png")
		if htex:
			heart_spr.texture = htex
			heart_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			heart_spr.scale = Vector2(0.75, 0.75)
		visual_root.add_child(heart_spr)
		var halo_pts := PackedVector2Array()
		for i in range(16):
			var a := float(i) * (TAU / 16.0)
			halo_pts.append(Vector2(cos(a), sin(a)) * 13.5)
		var halo := Line2D.new()
		halo.points = halo_pts
		halo.closed = true
		halo.width = 1.3
		halo.default_color = Color(1.0, 0.62, 0.74, 0.75)
		visual_root.add_child(halo)
	else:
		var shield_pts := PackedVector2Array([
			Vector2(0, -11), Vector2(9, -7), Vector2(8, 3), Vector2(0, 11), Vector2(-8, 3), Vector2(-9, -7)
		])
		var sh := Polygon2D.new()
		sh.polygon = shield_pts
		sh.color = Color(0.24, 0.68, 0.98, 0.96)
		visual_root.add_child(sh)
		var crest := Polygon2D.new()
		crest.polygon = PackedVector2Array([Vector2(0, -6), Vector2(4, 0), Vector2(0, 6), Vector2(-4, 0)])
		crest.color = Color(0.98, 0.92, 0.45, 0.98)
		visual_root.add_child(crest)
		var ring := Line2D.new()
		ring.points = shield_pts
		ring.closed = true
		ring.width = 1.8
		ring.default_color = Color(1.0, 0.88, 0.36, 0.95)
		visual_root.add_child(ring)
	pickup.add_child(visual_root)

	var parent_node: Node = entities if entities else self
	parent_node.add_child(pickup)

	var bob_tw := pickup.create_tween().set_loops()
	bob_tw.tween_property(visual_root, "position:y", -4.0, 0.65).set_trans(Tween.TRANS_SINE)
	bob_tw.tween_property(visual_root, "position:y", 0.0, 0.65).set_trans(Tween.TRANS_SINE)

	pickup.body_entered.connect(func(body: Node2D):
		if not is_instance_valid(pickup) or pickup.get_meta("collected", false):
			return
		if body is Player and body.can_control and body.health > 0:
			var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
			if pickup_kind == "esperanza":
				if body.has_method("pickup_item") and body.pickup_item("esperanza"):
					pickup.set_meta("collected", true)
					if fx:
						fx.burst(parent_node, pickup.global_position, Color(1.0, 0.90, 0.30), 14, 140.0)
					pickup.queue_free()
				return
			pickup.set_meta("collected", true)
			if pickup_kind == "heart":
				if body.health < body.max_health:
					body.health = mini(body.max_health, body.health + 1)
					body.health_changed.emit(body.health, body.max_health)
					if fx:
						fx.burst(parent_node, pickup.global_position, Color(1.0, 0.45, 0.65), 10, 110.0)
						fx.floating_text(parent_node, pickup.global_position + Vector2(0, -18), "+1 Esperanza", Color(1.0, 0.55, 0.72), 14)
				elif body.has_method("pickup_item") and str(body.get("held_item")).is_empty():
					body.pickup_item("heart")
			else:
				if body.has_method("pickup_item") and str(body.get("held_item")).is_empty():
					body.pickup_item("shield")
				else:
					body.grant_spawn_protection(2.5)
					if fx:
						fx.burst(parent_node, pickup.global_position, Color(0.45, 0.95, 1.0), 10, 110.0)
						fx.floating_text(parent_node, pickup.global_position + Vector2(0, -18), "Escudo de Respeto", Color(0.45, 0.95, 1.0), 14)
			pickup.queue_free()
	)
	return pickup

func _on_esperanza_activated(duration: float = ESPERANZA_DURATION) -> void:
	esperanza_timer = maxf(esperanza_timer, duration)
	esperanza_timer_updated.emit(esperanza_timer, ESPERANZA_DURATION)
	set_boss_desperation_fog(false)
	if fog_overlay and is_instance_valid(fog_overlay):
		fog_overlay.set_desperation_darkness(false)
		fog_overlay.set_fog(false, false)
	if boss and is_instance_valid(boss) and boss.has_method("apply_esperanza_debuff"):
		boss.apply_esperanza_debuff(duration)

func _ensure_esperanza_pickup_available() -> void:
	if player and is_instance_valid(player) and str(player.get("held_item")) == "esperanza":
		return
	if is_inside_tree() and get_tree():
		for pk in get_tree().get_nodes_in_group("virtue_pickups"):
			if is_instance_valid(pk) and str(pk.get_meta("pickup_kind", "")) == "esperanza" and not bool(pk.get_meta("collected", false)):
				return
	var spawn_pos := map_size * 0.5
	if player and is_instance_valid(player):
		spawn_pos = player.position + Vector2(56.0, -32.0)
	spawn_pos.x = clampf(spawn_pos.x, 75.0, map_size.x - 75.0)
	spawn_pos.y = clampf(spawn_pos.y, 95.0, map_size.y - 75.0)
	if _is_point_blocked_by_obstacle(spawn_pos, 14.0):
		spawn_pos = map_size * 0.5
	_spawn_virtue_pickup(spawn_pos, "esperanza")

func set_boss_desperation_fog(active: bool) -> void:
	if active and esperanza_timer > 0.0:
		return
	if active:
		if fog_overlay == null or not is_instance_valid(fog_overlay):
			fog_overlay = FogOverlayClass.new()
			fog_overlay.map_size = map_size
			fog_overlay.light_sources = [player] if player and is_instance_valid(player) else []
			for s in students:
				if is_instance_valid(s):
					fog_overlay.light_sources.append(s)
			fog_overlay.enemies_container = enemies_container
			add_child(fog_overlay)
		if boss and is_instance_valid(boss):
			fog_overlay.boss_node = boss
		if fog_overlay.has_method("set_desperation_darkness"):
			fog_overlay.set_desperation_darkness(true)
		fog_overlay.set_fog(true, true)
		if background:
			background.modulate = Color(0.42, 0.38, 0.50)
	else:
		if fog_overlay and is_instance_valid(fog_overlay):
			if fog_overlay.has_method("set_desperation_darkness"):
				fog_overlay.set_desperation_darkness(false)
			fog_overlay.set_fog(false, true)
		if background:
			background.modulate = Color.WHITE

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
	if boss.has_signal("undertale_climax_requested"):
		boss.undertale_climax_requested.connect(func(b): boss_undertale_climax_requested.emit(b))
	if entities:
		entities.add_child(boss)
	if not boss.is_node_ready():
		boss.setup_boss_type(boss.boss_type)
	if fog_overlay and is_instance_valid(fog_overlay):
		fog_overlay.boss_node = boss
	if esperanza_timer > 0.0 and boss.has_method("apply_esperanza_debuff"):
		boss.apply_esperanza_debuff(esperanza_timer)
	if boss.boss_type == BossClass.BossType.BULLYING:
		_summon_titanor_campaign_allies()
		_titanor_esperanza_drop_timer = 26.0 if is_hard_mode else 18.0
		_ensure_esperanza_pickup_available()

	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	var boss_info: Dictionary = BossClass.BOSS_DATA.get(boss.boss_type, {})
	var boss_name_str := str(boss_info.get("name", "JEFE")).to_upper()
	var boss_title := "%s ha aparecido" % boss_name_str
	if int(level_data.get("boss_type", 0)) == BossClass.BossType.DESINTERES:
		boss_title = "Maestro Desinterés confrontado"
	last_boss_banner_text = boss_title
	if fx:
		fx.shake(5.0, 0.45)
		fx.floating_text(self, boss.global_position + Vector2(0, -50), boss_title, Color(1.0, 0.35, 0.45), 16)
	boss_spawned.emit(boss)

func _summon_titanor_campaign_allies() -> void:
	var existing_names: Dictionary = {}
	for s in students:
		if is_instance_valid(s):
			existing_names[StudentClass.normalize_name(str(s.student_name))] = true
			if s.has_method("cheer_up"):
				s.cheer_up()
	var allies_to_summon := [
		{ "name": "Mateo", "gender": 0, "offset": Vector2(-58.0, -44.0) },
		{ "name": "Valeria", "gender": 1, "offset": Vector2(58.0, -44.0) },
		{ "name": "Sofía", "gender": 1, "offset": Vector2(0.0, 56.0) },
	]
	var anchor := player.position if (player and is_instance_valid(player)) else map_size * 0.35
	var summoned_any := false
	for info: Dictionary in allies_to_summon:
		var cname := StudentClass.normalize_name(str(info["name"]))
		if existing_names.has(cname):
			continue
		var spawn_pos: Vector2 = anchor + info["offset"]
		spawn_pos.x = clampf(spawn_pos.x, 70.0, map_size.x - 70.0)
		spawn_pos.y = clampf(spawn_pos.y, 90.0, map_size.y - 70.0)
		if _is_point_blocked_by_obstacle(spawn_pos, 12.0):
			spawn_pos = anchor
		var ally = StudentClass.new()
		ally.position = spawn_pos
		ally.student_name = str(info["name"])
		ally.gender = int(info["gender"])
		ally.initial_state = StudentClass.State.HAPPY
		ally.player = player
		ally.level_ref = self
		if entities:
			entities.add_child(ally)
		students.append(ally)
		if fog_overlay and is_instance_valid(fog_overlay):
			fog_overlay.light_sources.append(ally)
		summoned_any = true
	if summoned_any:
		var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
		if fx and is_inside_tree():
			fx.floating_text(self, anchor + Vector2(0, -68), "Tus compañeros del CEMSaD 22 acuden a ayudarte.", Color(0.45, 0.95, 1.0), 14)

func _on_boss_redeemed(b: CharacterBody2D) -> void:
	boss_defeated = true
	set_boss_desperation_fog(false)
	if b and b.has_method("set_fog_active"):
		b.set_fog_active(false)

	var is_final_titanor := (int(b.get("boss_type")) == 5) if (b != null and is_instance_valid(b)) else (int(level_data.get("boss_type", -1)) == 5)

	# Transicionar a TODOS los estudiantes del escenario al estado alegre
	for s in students:
		if is_instance_valid(s):
			s.cheer_up()

	# Detener a todos los enemigos restantes
	stop_enemies()

	if is_final_titanor:
		set_classroom_cleared(true)
		if goal and is_instance_valid(goal):
			goal.set_locked(true)
			goal.set_goal_text("Celebrando (7s)")
		_start_final_boss_celebration(b)
	else:
		# Desbloquear meta de salida
		if goal and is_instance_valid(goal):
			goal.unlock()

	boss_redeemed.emit(b)

	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx:
		var banner_text := "Antivalor mayor redimido"
		if int(level_data.get("boss_type", -1)) == 6:
			banner_text = "Maestro Desinterés redimido"
		elif is_final_titanor:
			banner_text = "Titanor en calma · Escuela en paz"
		var banner_pos := b.global_position if (b != null and is_instance_valid(b)) else (player.global_position if (player != null and is_instance_valid(player)) else map_size * 0.5)
		fx.floating_text(self, banner_pos + Vector2(0, -60), banner_text, Color(1.0, 0.95, 0.40), 16)
		fx.shake(4.0, 0.3)

func _load_level_texture(path: String) -> Texture2D:
	return AssetLoader.load_texture(path)

func _start_final_boss_celebration(boss_node: Node2D) -> void:
	for old_s in celebration_students:
		if is_instance_valid(old_s):
			old_s.queue_free()
	celebration_students.clear()

	is_final_boss_celebrating = true
	final_boss_celebration_completed = false
	_final_boss_celebration_timer = FINAL_BOSS_CELEBRATION_DURATION
	_final_celebration_elapsed = 0.0
	_final_celebration_step = 0
	_last_celebration_sec = ceili(FINAL_BOSS_CELEBRATION_DURATION)

	var rescue_infos: Array = BossClass.RESCUE_STUDENTS_DATA

	var rescue_positions: Array[Vector2] = []
	if boss_node != null and is_instance_valid(boss_node):
		var raw_nodes: Variant = boss_node.get("rescued_attack_students")
		if raw_nodes is Array:
			for rs in raw_nodes:
				if is_instance_valid(rs) and rs is Node2D:
					rescue_positions.append((rs as Node2D).position)
					rs.visible = false
					rs.queue_free()
				else:
					rescue_positions.append(Vector2.ZERO)
			raw_nodes.clear()

	# Ocultar estudiantes previos del escenario/aliados para que solo brillen los 7 campeones únicos sin duplicados
	for s in students:
		if not is_instance_valid(s):
			continue
		s.visible = false
		s.set_physics_process(false)
		s.set_process(false)
		var old_lbl := s.get_node_or_null("SpeechLabel") as Label
		if old_lbl:
			old_lbl.visible = false

	var center := boss_node.position if (boss_node != null and is_instance_valid(boss_node)) else (player.position if (player != null and is_instance_valid(player)) else map_size * 0.5)
	var parent_target: Node2D = entities if entities else self
	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null

	for i in range(rescue_infos.size()):
		var info: Dictionary = rescue_infos[i]
		var pos := Vector2.ZERO
		if i < rescue_positions.size() and rescue_positions[i] != Vector2.ZERO:
			pos = rescue_positions[i]
		else:
			var ang := -PI * 0.85 + float(i) * (PI * 1.70 / float(maxi(1, rescue_infos.size() - 1)))
			pos = center + Vector2(cos(ang), sin(ang)) * 135.0
		pos.x = clampf(pos.x, 70.0, map_size.x - 70.0)
		pos.y = clampf(pos.y, 90.0, map_size.y - 70.0)

		var node := Node2D.new()
		node.name = "CelebrationStudent_%s" % str(info["name"])
		node.position = pos
		node.y_sort_enabled = true
		node.z_index = 25

		var tex := _load_level_texture(str(info["tex"]))
		if tex:
			var spr := Sprite2D.new()
			spr.name = "Sprite2D"
			spr.texture = tex
			var max_dim := float(maxi(1, maxi(tex.get_width(), tex.get_height())))
			var s_scale := 51.2 / max_dim
			spr.scale = Vector2(s_scale, s_scale)
			spr.position = Vector2(0, -22)
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			node.add_child(spr)

		var name_lbl := Label.new()
		name_lbl.name = "NameLabel"
		name_lbl.text = str(info["name"])
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.position = Vector2(-46, -56)
		name_lbl.size = Vector2(92, 18)
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.72))
		name_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.12))
		name_lbl.add_theme_constant_override("outline_size", 4)
		node.add_child(name_lbl)

		_attach_celebration_speech_label(node, -76.0)
		node.set_meta("phase_offset", float(i) * 0.8)
		node.set_meta("celebration_color", info.get("color", Color(0.45, 0.95, 0.55)))
		parent_target.add_child(node)
		celebration_students.append(node)

		if fx:
			fx.burst(self, pos + Vector2(0, -20), info.get("color", Color(0.45, 0.95, 0.55)), 10, 100.0)

func _attach_celebration_speech_label(target_node: Node2D, y_offset: float) -> void:
	if target_node == null or not is_instance_valid(target_node):
		return
	var existing := target_node.get_node_or_null("SpeechLabel") as Label
	if existing:
		existing.text = FINAL_VICTORY_STUDENT_PHRASE
		existing.visible = true
		return
	var speech_lbl := Label.new()
	speech_lbl.name = "SpeechLabel"
	speech_lbl.text = FINAL_VICTORY_STUDENT_PHRASE
	speech_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech_lbl.position = Vector2(-95, y_offset)
	speech_lbl.size = Vector2(190, 20)
	speech_lbl.add_theme_font_size_override("font_size", 10)
	speech_lbl.add_theme_color_override("font_color", Color(0.92, 1.0, 0.70))
	speech_lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.12, 0.08))
	speech_lbl.add_theme_constant_override("outline_size", 4)
	target_node.add_child(speech_lbl)

func _update_final_boss_celebration(delta: float) -> void:
	_final_celebration_elapsed += delta
	_final_boss_celebration_timer = maxf(0.0, _final_boss_celebration_timer - delta)

	for actor in celebration_students:
		if not is_instance_valid(actor):
			continue
		var spr := actor.get_node_or_null("Sprite2D") as Sprite2D
		if spr:
			var offset := float(actor.get_meta("phase_offset", 0.0))
			spr.position.y = -22.0 - absf(sin(_final_celebration_elapsed * 8.0 + offset)) * 5.0

	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	var step := int(_final_celebration_elapsed / 0.85)
	if step > _final_celebration_step and not celebration_students.is_empty():
		_final_celebration_step = step
		var idx := step % celebration_students.size()
		var actor := celebration_students[idx]
		if is_instance_valid(actor) and fx:
			var col: Color = actor.get_meta("celebration_color", Color(0.95, 0.98, 0.55))
			fx.floating_text(self, actor.global_position + Vector2(0, -86), FINAL_VICTORY_STUDENT_PHRASE, col, 11)
			fx.burst(self, actor.global_position + Vector2(0, -24), col, 8, 90.0)

	var secs_left := maxi(1, ceili(_final_boss_celebration_timer))
	if secs_left != _last_celebration_sec and goal and is_instance_valid(goal):
		_last_celebration_sec = secs_left
		goal.set_goal_text("Meta en %ds" % secs_left)

	if _final_boss_celebration_timer <= 0.0:
		_finish_final_boss_celebration()

func _finish_final_boss_celebration() -> void:
	if not is_final_boss_celebrating:
		return
	is_final_boss_celebrating = false
	final_boss_celebration_completed = true

	if goal and is_instance_valid(goal):
		goal.set_goal_text(str(level_data.get("goal_label", "META")))
		goal.unlock()

	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx:
		var prompt_pos := player.position + Vector2(0, -56) if (player != null and is_instance_valid(player)) else map_size * 0.5
		fx.floating_text(self, prompt_pos, "Ve a la meta para la Ceremonia Final", Color(1.0, 0.95, 0.42), 14)

func _on_goal_reached() -> void:
	if player and is_instance_valid(player):
		player.celebrate()
	stop_enemies()
	level_completed.emit()

## Detiene y retira a todos los enemigos restantes del escenario tras limpiarlo o finalizar
func stop_enemies() -> void:
	if enemies_container:
		for enemy in enemies_container.get_children():
			if enemy is Enemy:
				enemy.stop_respawns()
				enemy.stop()
				enemy.queue_free()

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
