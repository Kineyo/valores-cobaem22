extends CharacterBody2D
class_name Boss

## Jefe Final de Escenario en perspectiva 3/4 para Campeones de los Valores (COBAEM CEMSaD 22).
## Implementa máquina de estados finitos, ataques telegrafiados adaptados a móvil/pantalla táctil,
## patrones Danmaku estilo Touhou (ruletas de balas, espirales curvas y nodos seguros de esquiva),
## micro-hitbox táctica, y filosofía educativa de redención pacífica (cero violencia).

signal health_changed(current_hp: int, max_hp: int)
signal attack_telegraphed(attack_name: String, duration: float)
signal redeemed(boss: Boss)
signal spell_card_changed(phase: int, spell_name: String)
signal special_phase_message(message: String)
signal hp_phase_animation_triggered(anim_name: String, hp_percent: int)
signal undertale_climax_requested(boss: Boss)

enum BossType {
	APATIA,        ## Nivel 1: Sombra de la Apatía (Acceso / Lab. D)
	DESPERDICIO,   ## Nivel 2: Troll del Desperdicio (Edif. A - Cafetería)
	INTOLERANCIA,  ## Nivel 3: Sombra de la Intolerancia (Plaza Cívica)
	CIBERACOSO,    ## Nivel 4: Espectro del Ciberacoso (Edif. B - Biblioteca)
	PLAGIO,        ## Nivel 5: Titán del Plagio (Edif. C - Taller Cómputo)
	BULLYING,      ## Nivel 6: Coloso del Bullying (Cancha Usos Múltiples - Danmaku Touhou)
	DESINTERES     ## Jefe de Salón: Maestro Desinterés (Inacción docente ante el bullying)
}

enum State {
	APPEARING,
	IDLE,
	TELEGRAPHING,
	ATTACKING,
	COOLDOWN,
	STUNNED,
	REDEEMED
}

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

const MAX_ACTIVE_CLONES := 3
const MAX_SUMMONED_ENEMIES := 5
const DANMAKU_CYCLE_PERIOD := 7.0
const DANMAKU_ACTIVE_WINDOW := 5.0
const COVER_VANISH_DURATION := 3.0
const CIBER_TELEPORT_INTERVAL := 10.0

## Umbrales porcentuales estandarizados (en vez de puntos fijos)
const PHASE_ENRAGED_RATIO := 0.50
const PHASE_CRITICAL_RATIO := 0.25
const TITANOR_PHASE2_RATIO := 0.75
const TITANOR_PHASE3_RATIO := 0.50
const TITANOR_PHASE4_RATIO := 0.30
const TITANOR_DESPERATION_RATIO := 0.18
const TITANOR_RESCUE_RATIO := 0.08
const ONE_HP_SHATTER_DURATION := 2.0

const BossDataClass := preload("res://scripts/boss_data.gd")
const BossFakeCloneClass := preload("res://scripts/boss_fake_clone.gd")
const BossRendererClass := preload("res://scripts/boss_renderer.gd")

const RESCUE_STUDENTS_DATA := BossDataClass.RESCUE_STUDENTS_DATA
const BOSS_DATA := BossDataClass.BOSS_DATA
const BOSS_DIFFICULTY_HP := BossDataClass.BOSS_DIFFICULTY_HP

@export var boss_type: BossType = BossType.APATIA
@export var detection_range: float = 400.0
@export var attack_cooldown_range: Vector2 = Vector2(1.8, 3.2)
@export var classroom_index: int = 0 ## Índice del aula (0: Lab, 1: Aula 1, 2: Cívica, 3: Biblioteca, 4: Cómputo, 5: Gimnasio)
var is_fog_active: bool = false

var current_state: State = State.APPEARING
var current_hp: int = 10
var max_hp: int = 10
var move_speed: float = 75.0
var player: CharacterBody2D = null

# Timers y parámetros internos
var _state_timer: float = 0.0
var _anim_time: float = 0.0
var _detection_range_sq: float = 0.0
var _current_attack_idx: int = 0
var _attack_dir: Vector2 = Vector2.DOWN
var _attack_target_pos: Vector2 = Vector2.ZERO
var _dash_velocity: Vector2 = Vector2.ZERO
var _flash_timer: float = 0.0
var _hazard_pulse: float = 0.0

# Sistema de Fases Danmaku Touhou (Titanor y Jefes mayores)
var _spell_phase: int = 1 ## Fases 1 a 4
var _is_spell_transition: bool = false
var _spell_transition_timer: float = 0.0
var _roulette_angle: float = 0.0

# Charcos múltiples de Apatía
var _puddles: Array[Dictionary] = []

# Barrera reflectante de Plagiatrix y Maestro Desinterés
var _barrier_active: bool = false
var _barrier_timer: float = 0.0

# Nodos visuales y áreas
var _hitbox: Area2D
var _collision_shape: CollisionShape2D
var _boss_texture: Texture2D = null

# Mecánicas progresivas y fases finales de Titanor (10 HP y 5 HP)
var last_special_message: String = ""
var teleport_count: int = 0
var active_clones: Array[Node2D] = []
var summoned_enemies_count: int = 0
var rescued_attack_students: Array[Node2D] = []
var desperation_fog_active: bool = false

var _summoned_enemies: Array[Node] = []
var _ten_hp_triggered: bool = false
var _five_hp_triggered: bool = false
var _teleport_timer: float = 4.5
var _ciber_teleport_timer: float = CIBER_TELEPORT_INTERVAL
var _clone_timer: float = 6.0
var _ten_hp_cycle_elapsed: float = 0.0
var _ten_hp_fire_cooldown: float = 0.0
var _is_covered_and_vanished: bool = false
var _cover_vanish_timer: float = 0.0
var _cover_cooldown_timer: float = 2.0
var _is_transforming: bool = false
var _climax_elapsed: float = 0.0
var _climax_hp_step: int = 0
var _climax_start_hp: int = 5
var _pause_banner_layer: CanvasLayer = null
var _pause_banner_active: bool = false
var _pause_banner_timer: float = 0.0
var _pause_owned_by_boss: bool = false
var esperanza_debuff_timer: float = 0.0
var is_esperanza_defenseless: bool = false

## Estados porcentuales de animación y secuencia 1 HP estilo Undertale
var _enraged_anim_triggered: bool = false
var _critical_anim_triggered: bool = false
var active_hp_anim_state: String = "normal"
var visual_crack_level: float = 0.0
var is_shattering_at_one_hp: bool = false
var shatter_progress: float = 0.0
var _shatter_shard_timer: float = 0.0
var _undertale_climax_emitted: bool = false
var _undertale_climax_completed: bool = false
var _difficulty_idx_cache: int = 1

func _get_fx() -> Node:
	if is_inside_tree():
		if get_tree() and get_tree().root:
			var fx_root = get_tree().root.get_node_or_null("Fx")
			if fx_root:
				return fx_root
		return get_node_or_null("/root/Fx")
	var p := get_parent()
	while p != null:
		var found = p.get_node_or_null("Fx")
		if found:
			return found
		p = p.get_parent()
	return null

func _ready() -> void:
	y_sort_enabled = true
	add_to_group("bosses")
	add_to_group("enemies")

	_setup_nodes()
	setup_boss_type(boss_type)
	apply_difficulty()

	# Estado inicial de entrada cinemática
	current_state = State.APPEARING
	_state_timer = 1.2
	modulate.a = 0.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.8)
	tw.tween_property(self, "scale", Vector2.ONE, 0.8).from(Vector2(0.2, 0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var fx = _get_fx()
	if fx:
		fx.shake(5.0, 0.4)

func _exit_tree() -> void:
	_dismiss_dramatic_pause()
	_clear_fake_clones()
	_clear_rescue_students()

func _setup_nodes() -> void:
	collision_layer = 8
	collision_mask = 1

	if get_node_or_null("CollisionShape2D") == null:
		_collision_shape = CollisionShape2D.new()
		var capsule := CapsuleShape2D.new()
		capsule.radius = 16.0
		capsule.height = 36.0
		_collision_shape.shape = capsule
		_collision_shape.position = Vector2(0, -8)
		add_child(_collision_shape)
	else:
		_collision_shape = $CollisionShape2D

	if get_node_or_null("Hitbox") == null:
		_hitbox = Area2D.new()
		_hitbox.name = "Hitbox"
		_hitbox.collision_layer = 8
		_hitbox.collision_mask = 2
		_hitbox.add_to_group("enemies")
		var hit_shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(44, 48)
		hit_shape.shape = rect
		hit_shape.position = Vector2(0, -20)
		_hitbox.add_child(hit_shape)
		_hitbox.body_entered.connect(_on_hitbox_body_entered)
		add_child(_hitbox)
	else:
		_hitbox = $Hitbox
		_hitbox.collision_layer = 8
		_hitbox.collision_mask = 2
		if not _hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			_hitbox.body_entered.connect(_on_hitbox_body_entered)

func _load_boss_texture(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var loaded = ResourceLoader.load(res_path)
		if loaded is Texture2D:
			return loaded
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

func setup_boss_type(type: BossType) -> void:
	boss_type = type
	var data: Dictionary = BOSS_DATA[boss_type]
	max_hp = data["max_hp"]
	current_hp = max_hp
	move_speed = data["speed"]
	if boss_type == BossType.CIBERACOSO:
		detection_range = 1400.0
		attack_cooldown_range = Vector2(1.1, 1.8)
	else:
		detection_range = 400.0
		attack_cooldown_range = Vector2(1.8, 3.2)
	_detection_range_sq = detection_range * detection_range
	_ciber_teleport_timer = CIBER_TELEPORT_INTERVAL
	_spell_phase = 1
	_is_spell_transition = false
	_ten_hp_triggered = false
	_five_hp_triggered = false
	_is_covered_and_vanished = false
	_is_transforming = false
	desperation_fog_active = false
	is_esperanza_defenseless = false
	esperanza_debuff_timer = 0.0
	_enraged_anim_triggered = false
	_critical_anim_triggered = false
	active_hp_anim_state = "normal"
	visual_crack_level = 0.0
	is_shattering_at_one_hp = false
	shatter_progress = 0.0
	_undertale_climax_emitted = false
	_undertale_climax_completed = false
	teleport_count = 0
	summoned_enemies_count = 0
	last_special_message = ""
	_clear_fake_clones()
	_clear_rescue_students()
	if boss_type == BossType.DESINTERES:
		_boss_texture = _load_boss_texture("res://assets/characters/maestro_desinteres/idle.png")
	else:
		_boss_texture = null
	apply_difficulty()
	health_changed.emit(current_hp, max_hp)
	queue_redraw()

func apply_difficulty() -> void:
	var gs: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		gs = get_tree().root.get_node_or_null("GameSettings")
	elif Engine.get_main_loop() is SceneTree and (Engine.get_main_loop() as SceneTree).root:
		gs = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GameSettings")
	if gs == null and is_inside_tree():
		gs = get_node_or_null("/root/GameSettings")
	if gs == null:
		var p := get_parent()
		while p != null and gs == null:
			gs = p.get_node_or_null("GameSettings")
			p = p.get_parent()

	var diff_idx: int = 1 # Normal por defecto
	if gs:
		if gs.has_method("get_param"):
			move_speed = BOSS_DATA[boss_type]["speed"] * gs.get_param("enemy_speed_mult")
		var diff_val = gs.get("difficulty")
		if diff_val != null:
			diff_idx = int(diff_val)
	_difficulty_idx_cache = clampi(diff_idx, 0, 2)

	if BOSS_DIFFICULTY_HP.has(boss_type) and BOSS_DIFFICULTY_HP[boss_type].has(diff_idx):
		max_hp = BOSS_DIFFICULTY_HP[boss_type][diff_idx]
	else:
		max_hp = BOSS_DATA[boss_type]["max_hp"]

	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)

func set_fog_active(active: bool) -> void:
	is_fog_active = active
	queue_redraw()

func _physics_process(delta: float) -> void:
	_anim_time += delta
	_roulette_angle += delta * (1.25 + 0.85 * get_missing_hp_ratio() if boss_type == BossType.BULLYING else 1.25)

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			modulate = Color.WHITE if not _is_covered_and_vanished else Color(1.0, 1.0, 1.0, 0.06)

	# Actualizar movimiento de clones falsos activos
	_update_fake_clones(delta)

	# Secuencia de pausa y fractura al llegar a 1 HP antes del clímax Undertale
	if is_shattering_at_one_hp:
		velocity = Vector2.ZERO
		_dash_velocity = Vector2.ZERO
		shatter_progress = clampf(shatter_progress + (delta / ONE_HP_SHATTER_DURATION), 0.0, 1.0)
		visual_crack_level = clampf(0.45 + shatter_progress * 0.55, 0.0, 1.0)
		var desat := 1.0 - shatter_progress * 0.85
		modulate = Color(desat, desat, desat, 1.0)
		scale = Vector2.ONE * (1.0 + sin(_anim_time * 42.0) * 0.04)
		_shatter_shard_timer -= delta
		if _shatter_shard_timer <= 0.0:
			_shatter_shard_timer = 0.16
			var fx_s := _get_fx()
			if fx_s and is_inside_tree():
				fx_s.shake(3.0 + shatter_progress * 4.0, 0.14)
				fx_s.burst(get_parent() if get_parent() else self, global_position + Vector2(randf_range(-14, 14), -26), Color.WHITE, 6, 130.0)
		if shatter_progress >= 1.0 and not _undertale_climax_emitted:
			_undertale_climax_emitted = true
			is_shattering_at_one_hp = false
			undertale_climax_requested.emit(self)
		queue_redraw()
		return

	# Clímax final al 8% de vida: intento de transformación e intervención de alumnos rescatados
	if _is_transforming:
		_update_five_hp_transformation_climax(delta)
		queue_redraw()
		return

	# Controlar ventaja ESPERANZA (15s: sin clones, sin niebla, jefe completamente indefenso)
	if is_esperanza_defenseless:
		esperanza_debuff_timer -= delta
		_barrier_active = false
		_dash_velocity = Vector2.ZERO
		velocity = Vector2.ZERO
		if _is_covered_and_vanished:
			_end_cover_and_vanish()
		if not active_clones.is_empty():
			_clear_fake_clones()
		if desperation_fog_active or is_fog_active:
			desperation_fog_active = false
			is_fog_active = false
			var lvl_esp := _get_level_node()
			if lvl_esp and lvl_esp.has_method("set_boss_desperation_fog"):
				lvl_esp.set_boss_desperation_fog(false)
		if current_state != State.APPEARING and current_state != State.REDEEMED:
			current_state = State.STUNNED
			_state_timer = maxf(0.2, esperanza_debuff_timer)
		if esperanza_debuff_timer <= 0.0:
			is_esperanza_defenseless = false
			esperanza_debuff_timer = 0.0
			if current_state == State.STUNNED:
				current_state = State.IDLE
				_state_timer = 0.8
			var fx_end := _get_fx()
			if fx_end and is_inside_tree():
				fx_end.floating_text(get_parent() if get_parent() else self, global_position + Vector2(0, -56), "¡Esperanza agotada! ¡Alerta!", Color(1.0, 0.72, 0.38), 13)
		if is_inside_tree() and PhysicsServer2D.body_get_space(get_rid()).is_valid():
			move_and_slide()
		queue_redraw()
		return

	# Controlar temporizador de cobertura + desaparición (3 segundos)
	if _is_covered_and_vanished:
		_cover_vanish_timer -= delta
		if _cover_vanish_timer <= 0.0:
			_end_cover_and_vanish()

	# Mecánicas progresivas y fase de 10 HP de Titanor (Jefe Final)
	if boss_type == BossType.BULLYING and current_state != State.APPEARING and current_state != State.REDEEMED and not is_esperanza_defenseless:
		if current_hp < max_hp and not _five_hp_triggered and not _is_covered_and_vanished and not _is_spell_transition:
			_teleport_timer -= delta
			if _teleport_timer <= 0.0:
				_teleport_timer = maxf(2.2, 5.2 - 2.8 * get_missing_hp_ratio())
				_perform_boss_teleport()

			_clone_timer -= delta
			if _clone_timer <= 0.0:
				_clone_timer = maxf(4.5, 8.5 - 3.5 * get_missing_hp_ratio())
				_spawn_fake_clones(2 if get_missing_hp_ratio() < 0.5 else 3)

		if _ten_hp_triggered and not _five_hp_triggered:
			_ten_hp_cycle_elapsed += delta
			# Danmaku esquivable durante 5 segundos cada 7 segundos
			if is_ten_hp_danmaku_window_active():
				_ten_hp_fire_cooldown -= delta
				if _ten_hp_fire_cooldown <= 0.0:
					_ten_hp_fire_cooldown = 0.55
					_fire_ten_hp_danmaku_pattern()
			if not _is_covered_and_vanished:
				_cover_cooldown_timer -= delta
				if _cover_cooldown_timer <= 0.0:
					_cover_cooldown_timer = 9.0
					trigger_cover_and_vanish(COVER_VANISH_DURATION)

	# Teletransporte periódico cada 10s para Ciber-Murmullus (Edificio B)
	if boss_type == BossType.CIBERACOSO and current_state != State.APPEARING and current_state != State.REDEEMED and not is_esperanza_defenseless:
		_ciber_teleport_timer -= delta
		if _ciber_teleport_timer <= 0.0:
			_ciber_teleport_timer = CIBER_TELEPORT_INTERVAL
			_perform_ciberacoso_teleport()

	# Actualizar charcos múltiples (Boss 1 y otros)
	if not _puddles.is_empty():
		var i := _puddles.size() - 1
		while i >= 0:
			var pud: Dictionary = _puddles[i]
			pud["time"] -= delta
			if pud["time"] <= 0.0:
				_puddles.remove_at(i)
			else:
				if player and is_instance_valid(player) and player.can_control:
					var p_pos: Vector2 = pud["pos"]
					var p_rad: float = pud["radius"]
					if player.global_position.distance_squared_to(p_pos) <= p_rad * p_rad:
						if player.has_method("apply_puddle_slow"):
							player.apply_puddle_slow(0.15)
						else:
							player.velocity *= 0.52 # Ralentización en fango apático
			i -= 1

	# Actualizar barrera reflectante (Plagiatrix / Maestro Desinterés)
	if _barrier_active:
		_barrier_timer -= delta
		if (_barrier_timer <= 0.0 and not _is_covered_and_vanished) or current_state == State.STUNNED or current_state == State.REDEEMED:
			_barrier_active = false

	# Transición entre Cartas de Hechizo Danmaku
	if _is_spell_transition:
		_spell_transition_timer -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
		if _spell_transition_timer <= 0.0:
			_is_spell_transition = false
			current_state = State.IDLE
			_state_timer = 0.5
		if is_inside_tree() and PhysicsServer2D.body_get_space(get_rid()).is_valid():
			move_and_slide()
		queue_redraw()
		return

	match current_state:
		State.APPEARING:
			_state_timer -= delta
			velocity = Vector2.ZERO
			if _state_timer <= 0.0:
				current_state = State.IDLE
				_state_timer = randf_range(attack_cooldown_range.x, attack_cooldown_range.y)
				var gs_intro := get_node_or_null("/root/GameSettings") if is_inside_tree() else null
				var is_fem_intro := gs_intro != null and int(gs_intro.get("selected_character")) == 1
				_proclaim_phrase(BossDataClass.get_intro_dialog(boss_type, is_fem_intro), Color(1.0, 0.8, 0.4))

		State.IDLE:
			_update_idle_movement(delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_start_telegraph()

		State.TELEGRAPHING:
			_update_telegraph(delta)

		State.ATTACKING:
			_update_attack(delta)

		State.COOLDOWN:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				current_state = State.IDLE
				# En Titanor, cadencia progresivamente más frenética estilo Touhou
				var cd_mult := 0.52 if (boss_type == BossType.BULLYING and _spell_phase >= 3) else (0.68 if boss_type == BossType.BULLYING else 0.85)
				var min_cd := attack_cooldown_range.x * cd_mult
				var max_cd := attack_cooldown_range.y * cd_mult
				_state_timer = randf_range(min_cd, max_cd)

		State.STUNNED:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				current_state = State.IDLE
				_state_timer = 0.9

		State.REDEEMED:
			velocity = Vector2.ZERO

	if is_inside_tree() and PhysicsServer2D.body_get_space(get_rid()).is_valid():
		move_and_slide()
	queue_redraw()

## Retorna la proporción de vida restante [0.0 .. 1.0]
func get_hp_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return clampf(float(current_hp) / float(max_hp), 0.0, 1.0)

## Retorna el porcentaje entero de vida restante [0 .. 100]
func get_hp_percent() -> int:
	if current_hp <= 0:
		return 0
	return clampi(int(round(get_hp_ratio() * 100.0)), 1, 100)

## Retorna la proporción de vida perdida [0.0 .. 1.0] para escalar dificultad progresiva
func get_missing_hp_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return clampf(1.0 - get_hp_ratio(), 0.0, 1.0)

## Velocidad efectiva que incrementa conforme Titanor pierde vida
func get_effective_speed() -> float:
	if boss_type == BossType.BULLYING:
		return move_speed * (1.0 + 0.75 * get_missing_hp_ratio())
	return move_speed

## Movimiento de merodeo o aproximación táctica
func _update_idle_movement(delta: float) -> void:
	var eff_speed := get_effective_speed()
	if player and is_instance_valid(player) and player.can_control:
		var dist_sq := global_position.distance_squared_to(player.global_position)
		if dist_sq <= _detection_range_sq:
			var diff := player.global_position - global_position
			var dir := diff.normalized()

			# En Fase 4 de Titanor (Last Spell), orbita suavemente cerca del centro de la cancha
			if boss_type == BossType.BULLYING and _spell_phase == 4:
				var arena_center := Vector2(720, 450)
				var to_center := (arena_center - global_position).normalized()
				velocity = velocity.move_toward(to_center * (eff_speed * 0.55), 320.0 * delta)
				return

			if dist_sq > 28900.0: # > 170 px
				velocity = velocity.move_toward(dir * eff_speed, 460.0 * delta)
			elif dist_sq < 10000.0: # < 100 px
				velocity = velocity.move_toward(-dir * (eff_speed * 0.75), 440.0 * delta)
			else:
				var perp := Vector2(-dir.y, dir.x)
				velocity = velocity.move_toward(perp * (eff_speed * 0.72), 360.0 * delta)
			return
	velocity = velocity.move_toward(Vector2.ZERO, 350.0 * delta)

## Inicia el telegrafiado claro del ataque (anticipación visual precisa)
func _start_telegraph() -> void:
	current_state = State.TELEGRAPHING
	var attack_names: Array = BOSS_DATA[boss_type]["attack_names"]

	# Selección de ataque según el tipo y la fase activa
	if boss_type == BossType.BULLYING:
		# Titanor desata la carta correspondiente a su fase y telegrafía más rápido con menos vida
		_current_attack_idx = mini(_spell_phase - 1, attack_names.size() - 1)
		_state_timer = maxf(0.45, 0.85 - 0.32 * get_missing_hp_ratio())
	elif boss_type == BossType.APATIA:
		# Boss 1: Apatía desbloquea su tercer patrón al 50% de vida o menos
		_current_attack_idx = randi() % (3 if get_hp_ratio() <= PHASE_ENRAGED_RATIO else 2)
		_state_timer = 0.72 # Telegrafiado ágil para exigir reflejos tempranos
	elif boss_type == BossType.CIBERACOSO:
		# Edificio B: ataques teledirigidos y teletransporte seguro
		_current_attack_idx = randi() % attack_names.size()
		_state_timer = 0.65
	else:
		_current_attack_idx = randi() % mini(2, attack_names.size())
		_state_timer = 0.90

	var atk_name: String = attack_names[_current_attack_idx]

	if player and is_instance_valid(player):
		_attack_target_pos = player.global_position
	else:
		_attack_target_pos = global_position + Vector2.DOWN * 160.0

	_attack_dir = (_attack_target_pos - global_position).normalized()
	if _attack_dir == Vector2.ZERO:
		_attack_dir = Vector2.DOWN

	attack_telegraphed.emit(atk_name, _state_timer)

	var fx = _get_fx()
	if fx:
		var parent = get_parent() if get_parent() else self
		fx.floating_text(parent, global_position + Vector2(0, -60), "¡" + atk_name + "!", Color(1.0, 0.35, 0.45), 13)
		fx.shake(2.0, 0.18)

func _update_telegraph(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
	_hazard_pulse += delta * 9.0
	_state_timer -= delta
	if _state_timer <= 0.0:
		_execute_attack()

## Ejecuta la fase activa del ataque tras completarse el telegrafiado
func _execute_attack() -> void:
	current_state = State.ATTACKING

	match boss_type:
		BossType.APATIA:
			# Boss 1: Ataques difíciles de desgano y fango
			if _current_attack_idx == 0:
				_attack_apathy_vortex()
			elif _current_attack_idx == 1:
				_attack_apathy_cyclone()
			else:
				_attack_apathy_miasma()

		BossType.DESPERDICIO:
			if _current_attack_idx == 0:
				_attack_spread_projectiles(7, 185.0, PI * 0.42)
			else:
				_attack_dash_slam(300.0, 0.65)

		BossType.INTOLERANCIA:
			if _current_attack_idx == 0:
				_attack_expanding_ring(130.0, 0.9)
			else:
				_attack_cross_volley_plus_aimed(190.0)

		BossType.CIBERACOSO:
			if _current_attack_idx == 0:
				_attack_ciber_homing_swarm()
			elif _current_attack_idx == 1:
				_attack_glitch_teleport_starburst()
			else:
				_attack_targeted_burst(6, 200.0)
				var ciber_origin := global_position + Vector2(0, -20)
				for k in [-1, 1]:
					_spawn_homing_boss_bullet(ciber_origin, _attack_dir.rotated(float(k) * 0.35), 205.0, Color(0.45, 0.95, 1.0), 3.1, 3.6)

		BossType.PLAGIO:
			if _current_attack_idx == 0:
				_attack_mirror_volley(8, 200.0)
			else:
				_attack_rotating_barrier(2.2)

		BossType.BULLYING:
			# Danmaku Touhou Multi-Fase: escapar continuamente es obligatorio (sin puntos ciegos)
			var roll := randf()
			match _spell_phase:
				1:
					if roll < 0.45:
						_attack_danmaku_roulette(2, _danmaku_scale_count(18), 175.0)
					elif roll < 0.80:
						_attack_danmaku_closing_cage(_danmaku_scale_count(14), 155.0)
					else:
						_attack_targeted_snipe_stream(6, 205.0)
				2:
					if roll < 0.40:
						_attack_danmaku_double_spiral(_danmaku_scale_count(16), 180.0, 1.15)
					elif roll < 0.80:
						_attack_danmaku_sweeping_curtains(_danmaku_scale_count(12), 185.0)
					else:
						_attack_danmaku_closing_cage(_danmaku_scale_count(16), 165.0)
				3:
					if roll < 0.35:
						_attack_danmaku_tri_roulette(3, _danmaku_scale_count(18), 175.0)
					elif roll < 0.70:
						_attack_danmaku_crisscross_grid(6, 178.0)
					else:
						_attack_targeted_snipe_stream(9, 210.0)
				_:
					# Fase 4: Último Hechizo (Clímax Danmaku con escapatoria activa)
					if roll < 0.35:
						_attack_danmaku_master_climax(_danmaku_scale_count(22), 182.0)
					elif roll < 0.70:
						_attack_danmaku_accelerating_lotus(_danmaku_scale_count(18), 165.0)
					else:
						_attack_danmaku_closing_cage(_danmaku_scale_count(18), 175.0)

		BossType.DESINTERES:
			match classroom_index:
				0:
					_attack_classroom_lab()
				1:
					_attack_classroom_papers()
				2:
					_attack_classroom_civic_shockwave()
				3:
					_attack_classroom_book_barrage()
				4:
					_attack_classroom_digital_glitch()
				_:
					_attack_classroom_sports_slam()

## Impactado por un disparo de virtudes o ataque cuerpo a cuerpo del héroe
func hit_by_attack(attacker_pos: Variant = null, damage: int = 1) -> void:
	if current_state == State.REDEEMED or current_state == State.APPEARING or _is_transforming:
		return

	if _is_covered_and_vanished:
		var fx_cov = _get_fx()
		if fx_cov:
			var parent_cov = get_parent() if get_parent() else self
			fx_cov.floating_text(parent_cov, global_position + Vector2(0, -40), "¡CUBIERTO EN LA NIEBLA!", Color(0.7, 0.75, 0.95), 12)
		return

	# Si está en transición entre cartas de hechizo, absorbe el golpe con cúpula dorada
	if _is_spell_transition:
		var fx_t = _get_fx()
		if fx_t:
			var parent_t = get_parent() if get_parent() else self
			fx_t.floating_text(parent_t, global_position + Vector2(0, -40), "¡CAMBIO DE FASE!", Color(1.0, 0.85, 0.2), 12)
			fx_t.burst(parent_t, global_position + Vector2(0, -24), Color.GOLD, 6, 80.0)
		return

	# Si la Barrera de Atajos está activa, repele el impacto
	if _barrier_active:
		var fx_b = _get_fx()
		if fx_b:
			var parent_b = get_parent() if get_parent() else self
			fx_b.floating_text(parent_b, global_position + Vector2(0, -40), "¡ATAJO BLOQUEADO!", Color(0.6, 0.85, 1.0), 12)
			fx_b.burst(parent_b, global_position + Vector2(0, -24), Color.CYAN, 8, 110.0)
		return

	# Interceptar umbrales porcentuales críticos y tope de 1 HP en Titanor (salvo test de daño total max_hp)
	if boss_type == BossType.BULLYING and damage < max_hp:
		var next_hp := maxi(0, current_hp - damage)
		var next_ratio := float(next_hp) / float(maxi(1, max_hp))
		if not _ten_hp_triggered and next_ratio <= TITANOR_DESPERATION_RATIO and next_ratio > TITANOR_RESCUE_RATIO:
			current_hp = maxi(2, int(floor(float(max_hp) * TITANOR_DESPERATION_RATIO)))
			health_changed.emit(current_hp, max_hp)
			_trigger_ten_hp_desperation_phase()
			return
		elif _ten_hp_triggered and not _five_hp_triggered and next_ratio <= TITANOR_RESCUE_RATIO and next_hp > 1:
			current_hp = maxi(2, int(floor(float(max_hp) * TITANOR_RESCUE_RATIO)))
			health_changed.emit(current_hp, max_hp)
			_trigger_five_hp_final_climax()
			return
		elif not _undertale_climax_completed and next_hp <= 1:
			current_hp = 1
			health_changed.emit(1, max_hp)
			_start_one_hp_shatter_sequence()
			return

	current_hp = maxi(0, current_hp - damage)
	health_changed.emit(current_hp, max_hp)

	var fx = _get_fx()
	var hit_pos := global_position + Vector2(0, -24)
	var accent_col: Color = BOSS_DATA[boss_type]["accent_color"]

	if fx:
		fx.hitstop(0.08, 0.05)
		fx.shake(3.8, 0.20)
		fx.burst(get_parent(), hit_pos, accent_col, 16, 170.0)
		fx.burst(get_parent(), hit_pos, Color.WHITE, 8, 120.0)

	# Destello luminoso de impacto
	modulate = Color(2.5, 2.2, 1.2, 1.0)
	_flash_timer = 0.12

	# Retroceso suave
	if attacker_pos != null and attacker_pos is Vector2:
		var push_dir: Vector2 = (global_position - (attacker_pos as Vector2)).normalized()
		velocity += push_dir * 95.0

	var hp_ratio := get_hp_ratio()
	var hp_pct := get_hp_percent()
	# Animaciones estandarizadas por porcentaje de vida (50% Enraged y 25% Critical) para cualquier jefe
	if current_hp > 0:
		if hp_ratio <= PHASE_ENRAGED_RATIO and not _enraged_anim_triggered:
			_enraged_anim_triggered = true
			active_hp_anim_state = "enraged"
			scale = Vector2(1.22, 0.82)
			create_tween().tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			if fx:
				fx.floating_text(get_parent(), hit_pos + Vector2(0, -34), "¡%d%% — FASE INTENSA!" % hp_pct, Color(1.0, 0.78, 0.28), 14)
				fx.burst(get_parent(), hit_pos, Color(1.0, 0.72, 0.25), 14, 150.0)
			hp_phase_animation_triggered.emit("enraged", hp_pct)
		if hp_ratio <= PHASE_CRITICAL_RATIO and not _critical_anim_triggered:
			_critical_anim_triggered = true
			active_hp_anim_state = "critical"
			visual_crack_level = maxf(visual_crack_level, 0.45)
			if fx:
				fx.shake(5.2, 0.30)
				fx.floating_text(get_parent(), hit_pos + Vector2(0, -48), "¡%d%% — RESISTENCIA CRÍTICA!" % hp_pct, Color(1.0, 0.35, 0.45), 14)
				fx.burst(get_parent(), hit_pos, Color(1.0, 0.35, 0.45), 18, 170.0)
			hp_phase_animation_triggered.emit("critical", hp_pct)

	# Comprobar progresión porcentual de Fases Danmaku para Titanor (antes de su fase 18%)
	if boss_type == BossType.BULLYING and hp_ratio > TITANOR_DESPERATION_RATIO and not _ten_hp_triggered:
		if hp_ratio <= TITANOR_PHASE4_RATIO and _spell_phase < 4:
			_trigger_spell_card_phase(4, "¡ÚLTIMO HECHIZO (30%): RESPLANDOR DE LA INCLUSIÓN!")
		elif hp_ratio <= TITANOR_PHASE3_RATIO and _spell_phase < 3:
			_trigger_spell_card_phase(3, "¡CARTA DE HECHIZO (50%): RULETA KALEIDOSCÓPICA CRUZADA!")
		elif hp_ratio <= TITANOR_PHASE2_RATIO and _spell_phase < 2:
			_trigger_spell_card_phase(2, "¡CARTA DE HECHIZO (75%): DOBLE ESPIRAL DE OPRESIÓN!")

	# Comprobar redención pacífica o interrupción en carga
	if current_hp <= 0:
		redeem()
	elif current_state == State.TELEGRAPHING and randf() < 0.25:
		current_state = State.STUNNED
		_state_timer = 0.75
		if fx:
			fx.floating_text(get_parent(), hit_pos + Vector2(0, -25), "¡INTERRUPCIÓN!", Color(1.0, 0.9, 0.3), 14)

## Dispara la transición cinemática a una nueva fase Danmaku
func _trigger_spell_card_phase(new_phase: int, spell_name: String) -> void:
	_spell_phase = new_phase
	_is_spell_transition = true
	_spell_transition_timer = 4.0
	current_state = State.COOLDOWN
	_state_timer = 4.0
	velocity = Vector2.ZERO

	# Ondas de choque que limpian el escenario de proyectiles enemigos
	_clear_all_enemy_projectiles()
	_grant_phase_clear_reward()

	var fx = _get_fx()
	if fx:
		fx.shake(7.0, 0.5)
		var parent = get_parent() if get_parent() else self
		fx.burst(parent, global_position + Vector2(0, -24), Color(1.0, 0.85, 0.3), 36, 240.0)
		fx.floating_text(parent, global_position + Vector2(0, -65), spell_name, Color(1.0, 0.9, 0.35), 16)

	spell_card_changed.emit(_spell_phase, spell_name)

## Limpia todas las balas enemigas activas con destellos pacíficos
func _clear_all_enemy_projectiles() -> void:
	if not is_inside_tree():
		return
	var shots := get_tree().get_nodes_in_group("enemy_projectiles")
	var fx = _get_fx()
	var parent = get_parent() if get_parent() else self
	for s in shots:
		if is_instance_valid(s):
			if fx:
				fx.burst(parent, s.global_position, Color(1.0, 0.95, 0.4, 0.8), 3, 50.0)
			s.queue_free()

## Otorga un corazón extra al héroe al superar una carta de hechizo
func _grant_phase_clear_reward() -> void:
	if player and is_instance_valid(player):
		if player.health < player.max_health:
			player.health = mini(player.max_health, player.health + 1)
			player.health_changed.emit(player.health, player.max_health)
			player._flash(Color(1.0, 2.0, 1.2))
		var fx = _get_fx()
		if fx:
			var parent = get_parent() if get_parent() else self
			fx.floating_text(parent, player.global_position + Vector2(0, -45), "¡FASE SUPERADA! +1 ❤️", Color(0.4, 1.0, 0.5), 14)
			fx.burst(parent, player.global_position, Color(0.3, 1.0, 0.5), 16, 120.0)

## Redención pacífica (filosofía sin violencia): el antivalor mayor se transforma e ilumina
func redeem() -> void:
	if current_state == State.REDEEMED:
		return
	current_state = State.REDEEMED
	velocity = Vector2.ZERO
	_puddles.clear()
	_barrier_active = false
	_is_covered_and_vanished = false
	_is_transforming = false
	desperation_fog_active = false
	is_fog_active = false
	modulate = Color.WHITE
	_dismiss_dramatic_pause()
	_clear_fake_clones()
	_stop_summoned_enemies()
	_clear_all_enemy_projectiles()

	var lvl := _get_level_node()
	if lvl and lvl.has_method("set_boss_desperation_fog"):
		lvl.set_boss_desperation_fog(false)

	if _hitbox:
		_hitbox.set_deferred("monitoring", false)
		_hitbox.set_deferred("monitorable", false)
	if _collision_shape:
		_collision_shape.set_deferred("disabled", true)

	var data: Dictionary = BOSS_DATA[boss_type]
	var virtue: String = data["virtue"]
	var final_dialog: String = data["redeemed_dialog"]

	var fx = _get_fx()
	var hit_pos := global_position + Vector2(0, -30)
	if fx:
		fx.shake(6.5, 0.5)
		fx.burst(get_parent(), hit_pos, Color(1.0, 0.85, 0.2), 32, 220.0)
		fx.burst(get_parent(), hit_pos, Color.WHITE, 20, 160.0)
		fx.floating_text(get_parent(), hit_pos + Vector2(0, -40), virtue, Color(1.0, 0.95, 0.4), 20)

	_proclaim_phrase(final_dialog, Color(0.9, 1.0, 0.9))
	if boss_type == BossType.BULLYING and rescued_attack_students.is_empty():
		_spawn_rescue_students()
	redeemed.emit(self)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.25, 1.25), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate", Color(2.0, 2.0, 1.5, 0.0), 1.5).set_delay(0.4)
	tw.chain().tween_callback(func():
		if boss_type != BossType.BULLYING:
			_clear_rescue_students()
		queue_free()
	)

# -----------------------------------------------------------------------------
# MECÁNICAS PROGRESIVAS DE TITANOR (TELETRANSPORTE, CLONES, 10 HP Y 5 HP)
# -----------------------------------------------------------------------------

func _get_level_node() -> Node:
	var p := get_parent()
	while p != null:
		if p.has_method("set_boss_desperation_fog"):
			return p
		p = p.get_parent()
	return null

func _get_arena_bounds() -> Vector2:
	var lvl := _get_level_node()
	if lvl and "map_size" in lvl:
		return lvl.map_size
	return Vector2(1440.0, 900.0)

func _is_pos_inside_obstacle(pos: Vector2, margin: float = 28.0) -> bool:
	var lvl := _get_level_node()
	if lvl == null or not ("level_data" in lvl):
		return false
	var obs_list: Array = lvl.level_data.get("obstacles", [])
	for obs in obs_list:
		var rect: Rect2 = obs if obs is Rect2 else Rect2(obs.get("x", 0), obs.get("y", 0), obs.get("w", 0), obs.get("h", 0))
		if rect.grow(margin).has_point(pos):
			return true
	return false

func _find_safe_boss_pos(desired_pos: Vector2, anchor_pos: Vector2) -> Vector2:
	var bounds := _get_arena_bounds()
	var cand := Vector2(
		clampf(desired_pos.x, 90.0, bounds.x - 90.0),
		clampf(desired_pos.y, 85.0, bounds.y - 85.0)
	)
	if not _is_pos_inside_obstacle(cand, 28.0):
		return cand

	var angles: Array[float] = [0.0, PI, 0.25, -0.25, PI - 0.25, -PI + 0.25, PI * 0.5, -PI * 0.5]
	var distances: Array[float] = [170.0, 215.0, 260.0, 320.0]
	for d: float in distances:
		for ang: float in angles:
			var alt: Vector2 = anchor_pos + Vector2(cos(ang), sin(ang)) * d
			alt.x = clampf(alt.x, 90.0, bounds.x - 90.0)
			alt.y = clampf(alt.y, 85.0, bounds.y - 85.0)
			if not _is_pos_inside_obstacle(alt, 28.0):
				return alt

	var y_probes: Array[float] = [anchor_pos.y, global_position.y, bounds.y * 0.62, bounds.y * 0.5, bounds.y * 0.38]
	var x_offs: Array[float] = [200.0, -200.0, 280.0, -280.0, 380.0, -380.0, 0.0]
	for y_probe: float in y_probes:
		for x_off: float in x_offs:
			var corridor: Vector2 = Vector2(
				clampf(anchor_pos.x + x_off, 100.0, bounds.x - 100.0),
				clampf(y_probe, 90.0, bounds.y - 90.0)
			)
			if not _is_pos_inside_obstacle(corridor, 24.0):
				return corridor

	return cand

## Teletransporte táctico de Titanor alrededor de la cancha
func _perform_boss_teleport() -> void:
	var parent_node: Node = get_parent() if get_parent() else self
	var fx := _get_fx()
	if fx:
		fx.burst(parent_node, global_position + Vector2(0, -24), Color(0.85, 0.35, 1.0), 16, 140.0)

	var anchor := player.global_position if (player and is_instance_valid(player)) else global_position
	var ang := randf() * TAU
	var dist := randf_range(160.0, 240.0)
	var dest := _find_safe_boss_pos(anchor + Vector2(cos(ang), sin(ang)) * dist, anchor)

	global_position = dest
	if has_method("reset_physics_interpolation"):
		call("reset_physics_interpolation")
	teleport_count += 1
	if fx:
		fx.burst(parent_node, global_position + Vector2(0, -24), Color(0.35, 0.90, 1.0), 18, 160.0)
		fx.floating_text(parent_node, global_position + Vector2(0, -56), "¡Teletransporte!", Color(0.75, 0.92, 1.0), 13)
	queue_redraw()

## Teletransporte periódico cada 10s del Jefe del Edificio B (evitando obstáculos del corredor)
func _perform_ciberacoso_teleport() -> void:
	var parent_node: Node = get_parent() if get_parent() else self
	var fx := _get_fx()
	if fx:
		fx.burst(parent_node, global_position + Vector2(0, -24), Color.CYAN, 16, 140.0)

	var anchor := player.global_position if (player and is_instance_valid(player)) else global_position
	var side := -1.0 if global_position.x > anchor.x else 1.0
	var desired := anchor + Vector2(side * randf_range(180.0, 250.0), randf_range(-24.0, 24.0))
	var dest := _find_safe_boss_pos(desired, anchor)

	global_position = dest
	if has_method("reset_physics_interpolation"):
		call("reset_physics_interpolation")
	teleport_count += 1
	if fx:
		fx.burst(parent_node, global_position + Vector2(0, -24), Color.MAGENTA, 16, 140.0)
		fx.floating_text(parent_node, global_position + Vector2(0, -52), "¡Ciber-Teletransporte!", Color.CYAN, 13)
	queue_redraw()

func _prune_clones() -> void:
	var idx := active_clones.size() - 1
	while idx >= 0:
		if not is_instance_valid(active_clones[idx]):
			active_clones.remove_at(idx)
		idx -= 1

func get_active_clone_count() -> int:
	_prune_clones()
	return active_clones.size()

## Duplica al jefe creando clones falsos (solo el Titanor original recibe daño real)
func _spawn_fake_clones(count: int = 2) -> void:
	if is_esperanza_defenseless:
		return
	_prune_clones()
	var can_add := mini(count, MAX_ACTIVE_CLONES - active_clones.size())
	if can_add <= 0:
		return

	var parent_node: Node = get_parent() if get_parent() else self
	var bounds := _get_arena_bounds()
	var data: Dictionary = BOSS_DATA[boss_type]
	var fx := _get_fx()

	for i in range(can_add):
		var ang := randf() * TAU
		var offset := Vector2(cos(ang), sin(ang)) * randf_range(90.0, 165.0)
		var spawn_pos := global_position + offset
		spawn_pos.x = clampf(spawn_pos.x, 100.0, bounds.x - 100.0)
		spawn_pos.y = clampf(spawn_pos.y, 100.0, bounds.y - 100.0)

		var clone := BossFakeCloneClass.new(self, data["color"], data["accent_color"], randf() * TAU)
		clone.position = spawn_pos
		parent_node.add_child(clone)
		active_clones.append(clone)
		if fx:
			fx.burst(parent_node, spawn_pos + Vector2(0, -24), Color(0.75, 0.45, 1.0), 10, 90.0)

	if fx:
		fx.floating_text(parent_node, global_position + Vector2(0, -64), "¡Clones de Sombra! ¡Encuentra al real!", Color(0.95, 0.65, 1.0), 13)

func _update_fake_clones(delta: float) -> void:
	_prune_clones()
	if active_clones.is_empty():
		return
	var target := player.global_position if (player and is_instance_valid(player)) else global_position
	var spd := get_effective_speed() * 0.82
	var bounds := _get_arena_bounds()
	for idx in range(active_clones.size()):
		var clone := active_clones[idx]
		var to_p := target - clone.global_position
		var dir := to_p.normalized() if to_p.length_squared() > 25.0 else Vector2.RIGHT
		var perp := Vector2(-dir.y, dir.x) * sin(_anim_time * 3.0 + float(idx) * 2.1) * 0.55
		var move_v := (dir + perp).normalized() * spd
		clone.global_position = Vector2(
			clampf(clone.global_position.x + move_v.x * delta, 80.0, bounds.x - 80.0),
			clampf(clone.global_position.y + move_v.y * delta, 90.0, bounds.y - 80.0)
		)

func _clear_fake_clones() -> void:
	for c in active_clones:
		if is_instance_valid(c):
			c.queue_free()
	active_clones.clear()

## Fase de Desesperación a los 10 de vida: Neblina oscura, pausa ("Aun me queda un ataque"), hasta 5 enemigos, Danmaku 5s/7s y cobertura 3s
func _trigger_ten_hp_desperation_phase() -> void:
	_ten_hp_triggered = true
	last_special_message = "Aun me queda un ataque"
	_ten_hp_cycle_elapsed = 0.0
	_ten_hp_fire_cooldown = 0.15
	_cover_cooldown_timer = 2.0
	_clear_all_enemy_projectiles()

	if not is_esperanza_defenseless:
		desperation_fog_active = true
		is_fog_active = true
		var lvl := _get_level_node()
		if lvl and lvl.has_method("set_boss_desperation_fog"):
			lvl.set_boss_desperation_fog(true)
		_summon_desperation_enemies(MAX_SUMMONED_ENEMIES)
		_fire_ten_hp_danmaku_pattern()

	special_phase_message.emit(last_special_message)
	_show_dramatic_pause(last_special_message, Color(0.95, 0.28, 0.48), 1.6)
	queue_redraw()

## Retorna true durante la ventana activa de 5 segundos dentro de cada ciclo de 7 segundos
func is_ten_hp_danmaku_window_active(sample_time: float = -1.0) -> bool:
	if not _ten_hp_triggered or _five_hp_triggered or _is_transforming:
		return false
	var t := _ten_hp_cycle_elapsed if sample_time < 0.0 else sample_time
	return fmod(maxf(0.0, t), DANMAKU_CYCLE_PERIOD) < DANMAKU_ACTIVE_WINDOW

func _fire_ten_hp_danmaku_pattern() -> void:
	var step := int(_ten_hp_cycle_elapsed * 2.0) % 3
	match step:
		0:
			_attack_danmaku_roulette(2, 16, 175.0)
		1:
			_attack_danmaku_double_spiral(16, 180.0, 1.15)
		_:
			_attack_danmaku_master_climax(20, 170.0)

## Invoca enemigos alrededor del jefe respetando el límite estricto de máximo 5 activos
func _summon_desperation_enemies(max_total: int = 5) -> void:
	var lvl := _get_level_node()
	var container: Node = null
	if lvl and "enemies_container" in lvl and lvl.enemies_container != null:
		container = lvl.enemies_container
	elif get_parent() != null:
		container = get_parent()
	else:
		container = self

	var active_count := 0
	for child in container.get_children():
		if child is Enemy and child.is_active:
			active_count += 1

	var cap := mini(MAX_SUMMONED_ENEMIES, max_total)
	var to_spawn := maxi(0, cap - active_count)
	var bounds := _get_arena_bounds()
	var types := [Enemy.Type.GROSERIA, Enemy.Type.ACOSO, Enemy.Type.BULLYING]

	for i in range(to_spawn):
		var e: Enemy = ENEMY_SCENE.instantiate()
		e.enemy_type = types[i % types.size()]
		var ang := float(i) * (TAU / float(maxi(1, to_spawn)))
		var pos := global_position + Vector2(cos(ang), sin(ang)) * 110.0
		pos.x = clampf(pos.x, 80.0, bounds.x - 80.0)
		pos.y = clampf(pos.y, 95.0, bounds.y - 80.0)
		e.position = pos
		e.player = player
		e.allow_respawn = false
		e.detection_range = 700.0
		e.is_alerted = true
		container.add_child(e)
		_summoned_enemies.append(e)

	summoned_enemies_count = mini(MAX_SUMMONED_ENEMIES, get_summoned_enemy_count())

func get_summoned_enemy_count() -> int:
	var count := 0
	var idx := _summoned_enemies.size() - 1
	while idx >= 0:
		var e = _summoned_enemies[idx]
		if not is_instance_valid(e):
			_summoned_enemies.remove_at(idx)
		elif "is_active" in e and e.is_active:
			count += 1
		idx -= 1
	return count

func _stop_summoned_enemies() -> void:
	for e in _summoned_enemies:
		if is_instance_valid(e):
			if e.has_method("stop_respawns"):
				e.stop_respawns()
			if e.has_method("stop"):
				e.stop()

## Cubre al jefe con escudo y lo oculta/desaparece durante exactamente `duration` segundos (3.0s)
func trigger_cover_and_vanish(duration: float = 3.0) -> void:
	if is_esperanza_defenseless:
		return
	_is_covered_and_vanished = true
	_barrier_active = true
	_barrier_timer = duration
	_cover_vanish_timer = duration
	modulate = Color(1.0, 1.0, 1.0, 0.05)
	if _hitbox:
		_hitbox.set_deferred("monitoring", false)
		_hitbox.set_deferred("monitorable", false)
	var fx := _get_fx()
	if fx:
		var parent_node: Node = get_parent() if get_parent() else self
		fx.burst(parent_node, global_position + Vector2(0, -24), Color(0.55, 0.78, 1.0), 16, 120.0)
		fx.floating_text(parent_node, global_position + Vector2(0, -52), "¡Cubierto y Oculto (3s)!", Color(0.65, 0.88, 1.0), 13)
	queue_redraw()

func _end_cover_and_vanish() -> void:
	_is_covered_and_vanished = false
	_barrier_active = false
	_cover_vanish_timer = 0.0
	modulate = Color.WHITE
	if _hitbox:
		_hitbox.set_deferred("monitoring", true)
		_hitbox.set_deferred("monitorable", true)
	var fx := _get_fx()
	if fx:
		var parent_node: Node = get_parent() if get_parent() else self
		fx.burst(parent_node, global_position + Vector2(0, -24), Color(1.0, 0.45, 0.7), 14, 110.0)
	queue_redraw()

## Muestra una pausa cinemática breve con el mensaje dramático del Jefe
func _show_dramatic_pause(message: String, accent: Color, duration: float) -> void:
	_dismiss_dramatic_pause()
	if not is_inside_tree() or get_tree() == null:
		return

	_pause_banner_active = true
	_pause_banner_timer = duration

	var layer := CanvasLayer.new()
	layer.name = "BossDramaticPauseOverlay"
	layer.layer = 96
	layer.process_mode = Node.PROCESS_MODE_ALWAYS

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.05, 0.72)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.14, 0.96)
	sb.border_color = accent
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 28.0
	sb.content_margin_top = 20.0
	sb.content_margin_right = 28.0
	sb.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var tag := Label.new()
	tag.text = "TITANOR — COLOSO DEL BULLYING"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", accent)
	vbox.add_child(tag)

	var msg_lbl := Label.new()
	msg_lbl.name = "DramaticPauseMessageLabel"
	msg_lbl.text = message
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_lbl.add_theme_font_size_override("font_size", 20)
	msg_lbl.add_theme_color_override("font_color", Color(0.98, 0.96, 1.0))
	vbox.add_child(msg_lbl)

	get_tree().root.add_child(layer)
	_pause_banner_layer = layer

	var is_headless := DisplayServer.get_name() == "headless"
	if not is_headless and not get_tree().paused:
		_pause_owned_by_boss = true
		get_tree().paused = true
	else:
		_pause_owned_by_boss = false
	var t := get_tree().create_timer(duration, true, false, false)
	t.timeout.connect(_dismiss_dramatic_pause, CONNECT_ONE_SHOT)

func _dismiss_dramatic_pause() -> void:
	_pause_banner_active = false
	_pause_banner_timer = 0.0
	if _pause_banner_layer and is_instance_valid(_pause_banner_layer):
		_pause_banner_layer.queue_free()
	_pause_banner_layer = null
	if _pause_owned_by_boss and is_inside_tree() and get_tree() and get_tree().paused:
		get_tree().paused = false
	_pause_owned_by_boss = false

## Activa la ventaja ESPERANZA: durante 15s el jefe no puede generar clones ni niebla y queda indefenso
func apply_esperanza_debuff(duration: float = 15.0) -> void:
	if current_state == State.REDEEMED:
		return
	esperanza_debuff_timer = maxf(esperanza_debuff_timer, duration)
	is_esperanza_defenseless = true
	_barrier_active = false
	_barrier_timer = 0.0
	_is_spell_transition = false
	_spell_transition_timer = 0.0
	_dash_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	if _is_covered_and_vanished:
		_end_cover_and_vanish()
	_clear_fake_clones()
	_clear_all_enemy_projectiles()
	desperation_fog_active = false
	is_fog_active = false
	var lvl := _get_level_node()
	if lvl and lvl.has_method("set_boss_desperation_fog"):
		lvl.set_boss_desperation_fog(false)
	if current_state != State.APPEARING:
		current_state = State.STUNNED
		_state_timer = maxf(_state_timer, esperanza_debuff_timer)
	last_special_message = "¡ESPERANZA ACTIVA! Jefe indefenso"
	special_phase_message.emit(last_special_message)
	var fx := _get_fx()
	if fx and is_inside_tree():
		var parent_node: Node = get_parent() if get_parent() else self
		fx.burst(parent_node, global_position + Vector2(0, -24), Color(1.0, 0.90, 0.35), 24, 180.0)
		fx.floating_text(parent_node, global_position + Vector2(0, -64), "¡ESPERANZA! Sin clones ni niebla (15s)", Color(1.0, 0.92, 0.38), 15)
	queue_redraw()

## Fase Clímax al 8% de vida: Pausa ("No dejare que liberes tan facil a la escuela"), intento de transformación y reducción a 1 HP
func _trigger_five_hp_final_climax() -> void:
	_five_hp_triggered = true
	current_hp = maxi(2, current_hp)
	_climax_start_hp = current_hp
	velocity = Vector2.ZERO
	_is_transforming = true
	_climax_elapsed = 0.0
	_climax_hp_step = 0
	_is_covered_and_vanished = false
	_barrier_active = true
	_barrier_timer = 10.0
	modulate = Color.WHITE
	last_special_message = "No dejare que liberes tan facil a la escuela"

	_clear_fake_clones()
	_clear_all_enemy_projectiles()
	_stop_summoned_enemies()

	special_phase_message.emit(last_special_message)
	_show_dramatic_pause(last_special_message, Color(1.0, 0.65, 0.25), 1.5)
	queue_redraw()

func _spawn_rescue_students() -> void:
	_clear_rescue_students()
	var parent_node: Node = get_parent() if get_parent() else self
	var bounds := _get_arena_bounds()
	var fx := _get_fx()

	for i in range(RESCUE_STUDENTS_DATA.size()):
		var info: Dictionary = RESCUE_STUDENTS_DATA[i]
		var ang := -PI * 0.85 + float(i) * (PI * 1.70 / float(maxi(1, RESCUE_STUDENTS_DATA.size() - 1)))
		var pos := global_position + Vector2(cos(ang), sin(ang)) * 135.0
		pos.x = clampf(pos.x, 70.0, bounds.x - 70.0)
		pos.y = clampf(pos.y, 90.0, bounds.y - 70.0)

		var node := Node2D.new()
		node.name = "RescuedAlly_%s" % str(info["name"])
		node.position = pos
		node.z_index = 25

		var tex := _load_boss_texture(str(info["tex"]))
		if tex:
			var spr := Sprite2D.new()
			spr.texture = tex
			var max_dim := float(maxi(1, maxi(tex.get_width(), tex.get_height())))
			var s := 51.2 / max_dim
			spr.scale = Vector2(s, s)
			spr.position = Vector2(0, -22)
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			node.add_child(spr)

		var lbl := Label.new()
		lbl.text = str(info["name"])
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(-42, -56)
		lbl.size = Vector2(84, 18)
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.72))
		lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.12))
		lbl.add_theme_constant_override("outline_size", 4)
		node.add_child(lbl)

		node.set_meta("virtue", str(info["virtue"]))
		node.set_meta("color", info["color"])
		parent_node.add_child(node)
		rescued_attack_students.append(node)
		if fx:
			fx.burst(parent_node, pos + Vector2(0, -20), info["color"], 12, 110.0)
			fx.floating_text(parent_node, pos + Vector2(0, -64), str(info["virtue"]), info["color"], 11)

	if fx:
		fx.floating_text(parent_node, global_position + Vector2(0, -82), "¡Toda la escuela unida en valores!", Color(1.0, 0.95, 0.45), 15)

func _clear_rescue_students() -> void:
	for s in rescued_attack_students:
		if is_instance_valid(s):
			s.queue_free()
	rescued_attack_students.clear()

func _update_five_hp_transformation_climax(delta: float) -> void:
	_climax_elapsed += delta
	velocity = Vector2.ZERO

	# Fase A (0.0s .. 1.2s): Titanor tiembla y crece como si se fuera a transformar
	if _climax_elapsed < 1.2:
		var t_norm := _climax_elapsed / 1.2
		var target_sc := lerpf(1.0, 1.38, t_norm)
		scale = Vector2(target_sc, target_sc)
		modulate = Color(1.0 + 0.55 * t_norm, 0.72, 1.0 + 0.45 * t_norm)
		return

	# Aparición de todos los alumnos rescatados en t >= 1.2s
	if rescued_attack_students.is_empty():
		_spawn_rescue_students()

	# Ataques pacíficos escalonados de los alumnos reduciendo HP proporcionalmente hasta dejarlo en 1 HP
	var total_steps := 5
	var target_step := mini(total_steps, int((_climax_elapsed - 1.2) / 0.28) + 1)
	if target_step > _climax_hp_step:
		var fx := _get_fx()
		var parent_node: Node = get_parent() if get_parent() else self
		while _climax_hp_step < target_step and current_hp > 1:
			var stu_idx := _climax_hp_step % maxi(1, rescued_attack_students.size())
			var ally := rescued_attack_students[stu_idx] if stu_idx < rescued_attack_students.size() else null
			var beam_col: Color = Color(1.0, 0.92, 0.4)
			if ally and is_instance_valid(ally):
				beam_col = ally.get_meta("color", beam_col)
			_climax_hp_step += 1
			var progress_frac := float(_climax_hp_step) / float(total_steps)
			current_hp = maxi(1, int(round(lerpf(float(_climax_start_hp), 1.0, progress_frac))))
			health_changed.emit(current_hp, max_hp)
			if fx:
				fx.burst(parent_node, global_position + Vector2(0, -24), beam_col, 14, 150.0)
				fx.shake(3.0, 0.12)
		scale = scale.lerp(Vector2.ONE, minf(1.0, delta * 5.0))

	# Al llegar a 1 HP tras la ofensiva escolar (t >= 2.8s), pausa todo y comienza a quebrarse para el clímax Undertale
	if current_hp <= 1 and _climax_elapsed >= 2.8:
		_start_one_hp_shatter_sequence()

## Inicia la pausa dramática y resquebrajamiento al llegar exactamente a 1 HP
func _start_one_hp_shatter_sequence() -> void:
	if is_shattering_at_one_hp or _undertale_climax_emitted or current_state == State.REDEEMED:
		return
	current_hp = 1
	health_changed.emit(1, max_hp)
	_is_transforming = false
	is_shattering_at_one_hp = true
	shatter_progress = 0.0
	_shatter_shard_timer = 0.0
	visual_crack_level = 0.55
	active_hp_anim_state = "shattering"
	velocity = Vector2.ZERO
	_dash_velocity = Vector2.ZERO
	_barrier_active = false
	_is_covered_and_vanished = false
	is_esperanza_defenseless = false
	desperation_fog_active = false
	is_fog_active = false
	current_state = State.STUNNED
	scale = Vector2.ONE
	_dismiss_dramatic_pause()
	_clear_fake_clones()
	_stop_summoned_enemies()
	_clear_all_enemy_projectiles()
	var lvl := _get_level_node()
	if lvl and lvl.has_method("set_boss_desperation_fog"):
		lvl.set_boss_desperation_fog(false)
	if player and is_instance_valid(player):
		player.can_control = false
		player.velocity = Vector2.ZERO
	if is_inside_tree() and get_tree() and get_tree().root:
		var gs = get_tree().root.get_node_or_null("GameSettings")
		if gs and gs.has_method("stop_music"):
			gs.stop_music(0.18)
	var fx := _get_fx()
	if fx and is_inside_tree():
		var parent_node: Node = get_parent() if get_parent() else self
		fx.shake(6.0, 0.4)
		fx.floating_text(parent_node, global_position + Vector2(0, -64), "¡SE QUIEBRA...!", Color(0.95, 0.95, 1.0), 15)
	queue_redraw()

## Finaliza el clímax Undertale (cuando los 8 corazones de valores completan el diálogo y rayo de luz)
func finish_undertale_climax() -> void:
	_undertale_climax_completed = true
	is_shattering_at_one_hp = false
	_is_transforming = false
	if player and is_instance_valid(player):
		player.can_control = true
	complete_student_rescue_climax()

## Completa inmediatamente la secuencia de rescate estudiantil para tests o fin de animación
func complete_student_rescue_climax() -> void:
	if current_state == State.REDEEMED:
		return
	if rescued_attack_students.is_empty():
		_spawn_rescue_students()
	current_hp = 0
	health_changed.emit(0, max_hp)
	scale = Vector2.ONE
	redeem()

func _proclaim_phrase(text: String, col: Color) -> void:
	var fx = _get_fx()
	if fx:
		var parent = get_parent() if get_parent() else self
		fx.floating_text(parent, global_position + Vector2(0, -50), text, col, 13)

# -----------------------------------------------------------------------------
# ATAQUES DEMANDANTES DE JEFE 1: APATYX
# -----------------------------------------------------------------------------

## Vórtice Espiral de Desgano: 2 charcos persistentes + espiral doble de 14 orbs con curvatura
func _attack_apathy_vortex() -> void:
	_state_timer = 0.55
	# 1. Engendrar 2 charcos de ralentización (en jugador y entremedio)
	_spawn_puddle(_attack_target_pos, 65.0, 4.5)
	var mid_pos := global_position.lerp(_attack_target_pos, 0.5)
	_spawn_puddle(mid_pos, 55.0, 4.5)

	# 2. Doble espiral curva de 14 orbes
	var count := 14
	var base_ang := _attack_dir.angle()
	for i in range(count):
		var ang := base_ang + float(i) * (TAU / float(count))
		var dir := Vector2(cos(ang), sin(ang))
		var curve := 0.75 if (i % 2 == 0) else -0.75
		var col := Color(0.72, 0.55, 0.95) if (i % 2 == 0) else Color(0.85, 0.70, 1.0)
		_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), dir, 175.0, col, curve, 0.8)

## Ráfaga Ciclónica del Desaliento: abanico de 7 orbes rápidos + 3 orbes dirigidos de seguimiento
func _attack_apathy_cyclone() -> void:
	_state_timer = 0.60
	# Abanico de 7 orbes a 215 px/s
	_attack_spread_projectiles(7, 215.0, PI * 0.44)

	# Rafaga dirigida 0.22s después
	if is_inside_tree() and get_tree():
		get_tree().create_timer(0.22).timeout.connect(func():
			if is_instance_valid(self) and is_inside_tree() and current_state != State.REDEEMED and player and is_instance_valid(player):
				var aim_dir := (player.global_position - global_position).normalized()
				for k in range(3):
					var offset_ang := float(k - 1) * 0.18
					var d := aim_dir.rotated(offset_ang)
					_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), d, 230.0, Color(0.9, 0.4, 0.6), 0.0, 0.75)
		)

## Miasma Apatético: anillo de 10 orbes rápidos + 4 orbes exteriores en órbita
func _attack_apathy_miasma() -> void:
	_state_timer = 0.50
	var count := 10
	for i in range(count):
		var ang := float(i) * (TAU / float(count))
		var dir := Vector2(cos(ang), sin(ang))
		_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), dir, 180.0, Color(0.65, 0.45, 0.85), 0.0, 0.8)

	for j in range(4):
		var ang2 := float(j) * (TAU / 4.0) + 0.35
		var dir2 := Vector2(cos(ang2), sin(ang2))
		_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), dir2, 150.0, Color(0.95, 0.6, 0.9), 1.1, 0.7)

func _spawn_puddle(pos: Vector2, radius: float, duration: float) -> void:
	_puddles.append({
		"pos": pos,
		"radius": radius,
		"time": duration,
		"max_time": duration
	})
	var fx = _get_fx()
	if fx:
		var parent = get_parent() if get_parent() else self
		fx.burst(parent, pos, BOSS_DATA[boss_type]["color"], 14, 80.0)

# -----------------------------------------------------------------------------
# PATRONES DANMAKU TOUHOU: TITANOR (COLOSO DEL BULLYING)
# -----------------------------------------------------------------------------

## Ruleta Danmaku Giratoria: 2 anillos concéntricos rotatorios con 3 corredores de escape simétricos
func _attack_danmaku_roulette(rings: int, count_per_ring: int, spd: float) -> void:
	_state_timer = 0.65
	var base_origin := global_position + Vector2(0, -20)

	for r in range(rings):
		var r_dir: float = 1.0 if (r % 2 == 0) else -1.0
		var r_offset := _roulette_angle * r_dir + float(r) * 0.35
		var r_spd := spd + float(r) * 20.0
		var r_col := Color(0.95, 0.30, 0.55) if (r % 2 == 0) else Color(0.40, 0.85, 1.0)

		for i in range(count_per_ring):
			# Huecos de escape tácticos cada 5 balas (aberturas de ruleta para esquivar)
			if i % 5 == 0:
				continue
			var ang := r_offset + float(i) * (TAU / float(count_per_ring))
			var dir := Vector2(cos(ang), sin(ang))
			_spawn_boss_danmaku_bullet(base_origin, dir, r_spd, r_col, 0.0, 0.72)

## Doble Espiral de Opresión: 2 flujos opuestos con curvatura continua que crean nodos seguros diamante
func _attack_danmaku_double_spiral(count: int, spd: float, curve: float) -> void:
	_state_timer = 0.60
	var base_origin := global_position + Vector2(0, -20)
	var base_ang := _roulette_angle * 0.8

	# Flujo horario (Cyan / Virtud emergente)
	for i in range(count):
		var ang := base_ang + float(i) * (TAU / float(count))
		var dir := Vector2(cos(ang), sin(ang))
		_spawn_boss_danmaku_bullet(base_origin, dir, spd, Color(0.35, 0.90, 1.0), curve, 0.75)

	# Flujo antihorario (Magenta / Presión del bullying)
	for j in range(count):
		var ang2 := -base_ang + float(j) * (TAU / float(count)) + 0.2
		var dir2 := Vector2(cos(ang2), sin(ang2))
		_spawn_boss_danmaku_bullet(base_origin, dir2, spd, Color(1.0, 0.35, 0.60), -curve, 0.75)

## Ruleta Kaleidoscópica Cruzada: 3 anillos rotatorios entrelazados a velocidades angulares alternas
func _attack_danmaku_tri_roulette(rings: int, count_per_ring: int, spd: float) -> void:
	_state_timer = 0.70
	var base_origin := global_position + Vector2(0, -20)

	for r in range(rings):
		var ang_mult := 1.2 if (r == 0) else (-1.2 if r == 1 else 0.8)
		var r_offset := _roulette_angle * ang_mult + float(r) * (TAU / 6.0)
		var r_spd := spd + float(r) * 18.0
		var r_col: Color
		match r:
			0: r_col = Color(1.0, 0.85, 0.30) # Oro
			1: r_col = Color(1.0, 0.35, 0.55) # Guinda
			_: r_col = Color(0.40, 0.90, 1.00) # Cyan

		for i in range(count_per_ring):
			if i % 6 == 0 or i % 6 == 1: # Ventanas tácticas amplias de paso
				continue
			var ang := r_offset + float(i) * (TAU / float(count_per_ring))
			var dir := Vector2(cos(ang), sin(ang))
			_spawn_boss_danmaku_bullet(base_origin, dir, r_spd, r_col, 0.0, 0.70)

## Ráfaga de Intimidación: corriente de balas dirigidas que exige desplazamiento continuo (stream-tapping)
func _attack_targeted_snipe_stream(stream_count: int, spd: float) -> void:
	_state_timer = 0.75
	var base_origin := global_position + Vector2(0, -20)
	if is_inside_tree() and get_tree():
		for i in range(stream_count):
			get_tree().create_timer(float(i) * 0.075).timeout.connect(func():
				if is_instance_valid(self) and is_inside_tree() and current_state != State.REDEEMED and player and is_instance_valid(player):
					var aim_dir := (player.global_position - base_origin).normalized()
					_spawn_boss_danmaku_bullet(base_origin, aim_dir, spd, Color(1.0, 0.4, 0.4), 0.0, 0.82)
			)

## Clímax Danmaku Touhou (Último Hechizo): Gran rueda de ruleta con 4 corredores cardinales y arcos curvos
func _attack_danmaku_master_climax(bullet_count: int, spd: float) -> void:
	_state_timer = 0.75
	var base_origin := global_position + Vector2(0, -20)
	var rot := _roulette_angle

	# 1. Rueda concéntrica con 4 amplios corredores cardinales de esquiva
	for i in range(bullet_count):
		# Dejar libres los 4 cuadrantes principales (45°, 135°, 225°, 315°)
		var step := TAU / float(bullet_count)
		var ang := rot + float(i) * step
		var norm_ang := fposmod(ang, TAU)
		var in_gap := false
		for g in [PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]:
			if absf(norm_ang - g) < 0.28:
				in_gap = true
				break
		if in_gap:
			continue

		var dir := Vector2(cos(ang), sin(ang))
		var col := Color(1.0, 0.90, 0.40) if (i % 2 == 0) else Color(1.0, 0.35, 0.65)
		_spawn_boss_danmaku_bullet(base_origin, dir, spd, col, 0.0, 0.72)

	# 2. Ráfaga orbital complementaria de 6 balas curvas exteriores
	for j in range(6):
		var ang2 := -rot * 0.7 + float(j) * (TAU / 6.0)
		var dir2 := Vector2(cos(ang2), sin(ang2))
		_spawn_boss_danmaku_bullet(base_origin, dir2, spd * 0.85, Color(0.4, 0.95, 1.0), 0.85, 0.70)

func _danmaku_scale_count(base_count: int) -> int:
	var mult := 1.0
	if _difficulty_idx_cache == 0:
		mult = 0.72
	elif _difficulty_idx_cache == 2:
		mult = 1.25
	return maxi(6, int(round(float(base_count) * mult)))

## Jaula Convergente Touhou: encierra al jugador dejando 2 pasillos rotatorios que exigen escapar
func _attack_danmaku_closing_cage(bullet_count: int, spd: float) -> void:
	_state_timer = 0.70
	var center := player.global_position if (player and is_instance_valid(player)) else global_position
	var cage_r := 185.0
	var gap_ang := randf() * TAU
	var bounds := _get_arena_bounds()
	for i in range(bullet_count):
		var ang := gap_ang + float(i) * (TAU / float(bullet_count))
		# Dejar 2 aberturas opuestas de escape para esquivar corriendo
		var rel := fposmod(ang - gap_ang, TAU)
		if rel < 0.48 or absf(rel - PI) < 0.48:
			continue
		var spawn_pt := center + Vector2(cos(ang), sin(ang)) * cage_r
		spawn_pt.x = clampf(spawn_pt.x, 48.0, bounds.x - 48.0)
		spawn_pt.y = clampf(spawn_pt.y, 64.0, bounds.y - 48.0)
		var inward_dir := (center - spawn_pt).normalized().rotated(0.18)
		_spawn_boss_danmaku_bullet(spawn_pt, inward_dir, spd, Color(1.0, 0.30, 0.55), 0.35, 0.72)

## Cortinas Barridas Touhou: dobles abanicos curvos opuestos + presión dirigida al jugador
func _attack_danmaku_sweeping_curtains(fan_count: int, spd: float) -> void:
	_state_timer = 0.75
	var origin := global_position + Vector2(0, -20)
	for wave in range(2):
		var delay := float(wave) * 0.24
		var run_wave := func():
			if not is_instance_valid(self) or not is_inside_tree() or current_state == State.REDEEMED:
				return
			var aim := (player.global_position - origin).normalized() if (player and is_instance_valid(player)) else _attack_dir
			var dir_sign := 1.0 if wave == 0 else -1.0
			for i in range(fan_count):
				var t := (float(i) / float(maxi(1, fan_count - 1))) - 0.5
				var d := Vector2.RIGHT.rotated(aim.angle() + t * 1.65)
				_spawn_boss_danmaku_bullet(origin, d, spd + float(wave) * 18.0, Color(0.95, 0.45, 0.90) if wave == 0 else Color(0.35, 0.90, 1.0), 0.75 * dir_sign, 0.70)
			# Tiro central directo para prohibir quedarse quieto
			_spawn_boss_danmaku_bullet(origin, aim, spd * 1.18, Color(1.0, 0.90, 0.35), 0.0, 0.80)
		if delay <= 0.0:
			run_wave.call()
		elif is_inside_tree() and get_tree():
			get_tree().create_timer(delay).timeout.connect(run_wave)

## Malla Cruzada Danmaku: ráfagas en cruz escalonadas que obligan a tejer en movimiento continuo
func _attack_danmaku_crisscross_grid(lanes: int, spd: float) -> void:
	_state_timer = 0.78
	var bounds := _get_arena_bounds()
	var anchor := player.global_position if (player and is_instance_valid(player)) else bounds * 0.5
	var spacing := 82.0
	for i in range(-lanes / 2, lanes / 2 + 1):
		if i == 0:
			continue
		var y_pt := clampf(anchor.y + float(i) * spacing, 85.0, bounds.y - 80.0)
		var from_left := Vector2(clampf(anchor.x - 280.0, 50.0, bounds.x - 50.0), y_pt)
		var from_right := Vector2(clampf(anchor.x + 280.0, 50.0, bounds.x - 50.0), y_pt + spacing * 0.5)
		_spawn_boss_danmaku_bullet(from_left, Vector2(1.0, 0.12).normalized(), spd, Color(0.35, 0.88, 1.0), 0.0, 0.72)
		_spawn_boss_danmaku_bullet(from_right, Vector2(-1.0, -0.12).normalized(), spd, Color(1.0, 0.40, 0.65), 0.0, 0.72)

## Loto Acelerado Touhou: doble anillo de pétalos curvos + descargas dirigidas
func _attack_danmaku_accelerating_lotus(petals: int, spd: float) -> void:
	_state_timer = 0.72
	var origin := global_position + Vector2(0, -20)
	for ring_idx in range(2):
		var c_dir := 1.0 if ring_idx == 0 else -1.0
		var col := Color(1.0, 0.85, 0.30) if ring_idx == 0 else Color(1.0, 0.32, 0.65)
		for i in range(petals):
			if i % 6 == 0:
				continue
			var ang := _roulette_angle * 0.9 * c_dir + float(i) * (TAU / float(petals))
			_spawn_boss_danmaku_bullet(origin, Vector2(cos(ang), sin(ang)), spd + float(ring_idx) * 28.0, col, 1.15 * c_dir, 0.72)
	if player and is_instance_valid(player):
		var aim := (player.global_position - origin).normalized()
		for off in [-0.18, 0.0, 0.18]:
			_spawn_boss_danmaku_bullet(origin, aim.rotated(off), spd * 1.25, Color.WHITE, 0.0, 0.78)

# -----------------------------------------------------------------------------
# ATAQUES ESTÁNDAR Y COMBINADOS
# -----------------------------------------------------------------------------

func _attack_dash_slam(dash_spd: float, duration: float) -> void:
	_dash_velocity = _attack_dir * dash_spd
	_state_timer = duration

func _attack_ground_slam(radius: float) -> void:
	_state_timer = 0.5
	var fx = _get_fx()
	if fx:
		fx.shake(5.5, 0.4)
		var parent = get_parent() if get_parent() else self
		fx.burst(parent, global_position, BOSS_DATA[boss_type]["accent_color"], 24, 180.0)
	if player and is_instance_valid(player):
		if global_position.distance_squared_to(player.global_position) <= radius * radius:
			player.take_damage(1, global_position)

func _attack_shoot_orbs(count: int, orb_speed: float, spread_angle: float) -> void:
	_state_timer = 0.5
	var base_ang := _attack_dir.angle()
	var start_ang := base_ang - (spread_angle * 0.5 * (count - 1))
	for i in range(count):
		var ang := start_ang + spread_angle * i
		var dir := Vector2(cos(ang), sin(ang))
		_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), dir, orb_speed, BOSS_DATA[boss_type]["accent_color"])

func _attack_spread_projectiles(count: int, proj_speed: float, total_arc: float) -> void:
	_state_timer = 0.6
	var base_ang := _attack_dir.angle()
	var step := total_arc / float(maxi(1, count - 1))
	var start_ang := base_ang - total_arc * 0.5
	for i in range(count):
		var ang := start_ang + step * i
		var dir := Vector2(cos(ang), sin(ang))
		_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), dir, proj_speed, BOSS_DATA[boss_type]["accent_color"])

func _attack_cross_volley_plus_aimed(spd: float) -> void:
	_state_timer = 0.55
	var dirs := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for d in dirs:
		_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), d, spd, BOSS_DATA[boss_type]["accent_color"])
	if player and is_instance_valid(player):
		var aim := (player.global_position - global_position).normalized()
		_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), aim, spd * 1.15, Color.WHITE)

func _attack_expanding_ring(radius: float, duration: float) -> void:
	_state_timer = duration
	for i in range(12):
		var ang := float(i) * (TAU / 12.0)
		var dir := Vector2(cos(ang), sin(ang))
		_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), dir, 160.0, BOSS_DATA[boss_type]["accent_color"])
	var fx = _get_fx()
	if fx:
		fx.shake(4.0, 0.3)
	if player and is_instance_valid(player):
		if global_position.distance_squared_to(player.global_position) <= radius * radius:
			player.take_damage(1, global_position)

func _attack_targeted_burst(burst_count: int, spd: float) -> void:
	_state_timer = 0.6
	for i in range(burst_count):
		var jitter := Vector2(randf_range(-0.15, 0.15), randf_range(-0.15, 0.15))
		_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), (_attack_dir + jitter).normalized(), spd + float(i) * 15.0, BOSS_DATA[boss_type]["accent_color"])

## Ataque exclusivo del Jefe del Edificio B: enjambre teledirigido + ráfaga directa
func _attack_ciber_homing_swarm() -> void:
	_state_timer = 0.65
	var base_origin := global_position + Vector2(0, -20)
	for offset_ang in [-0.45, -0.15, 0.15, 0.45]:
		var dir: Vector2 = _attack_dir.rotated(offset_ang)
		_spawn_homing_boss_bullet(base_origin, dir, 215.0, Color(0.35, 0.92, 1.0), 3.1, 3.6)
	for direct_off in [-0.22, 0.0, 0.22]:
		_spawn_boss_danmaku_bullet(base_origin, _attack_dir.rotated(direct_off), 235.0, Color(1.0, 0.45, 0.85), 0.0, 0.78)
	var fx := _get_fx()
	if fx:
		var parent = get_parent() if get_parent() else self
		fx.floating_text(parent, global_position + Vector2(0, -48), "¡Ciber-Rastreo!", Color(0.4, 0.95, 1.0), 13)

func _attack_glitch_teleport_starburst() -> void:
	_state_timer = 0.55
	var fx = _get_fx()
	var parent = get_parent() if get_parent() else self
	if fx:
		fx.burst(parent, global_position, Color.CYAN, 14, 140.0)
	var anchor := player.global_position if (player and is_instance_valid(player)) else global_position
	var angles := [0.0, PI, PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]
	var chosen_angle: float = angles[randi() % angles.size()]
	var offset := Vector2(cos(chosen_angle), sin(chosen_angle)) * randf_range(160.0, 220.0)
	var candidate_pos := anchor + offset
	global_position = _find_safe_boss_pos(candidate_pos, anchor)
	if has_method("reset_physics_interpolation"):
		call("reset_physics_interpolation")
	teleport_count += 1
	if fx:
		fx.burst(parent, global_position, Color.MAGENTA, 14, 140.0)
		fx.floating_text(parent, global_position + Vector2(0, -40), "¡GLITCH!", Color.CYAN, 12)
	# Ráfaga estelar de 8 balas + 2 proyectiles teledirigidos al materializarse
	for k in range(8):
		var ang := float(k) * (TAU / 8.0)
		_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), Vector2(cos(ang), sin(ang)), 175.0, Color.CYAN)
	var aim_dir := (anchor - global_position).normalized()
	if aim_dir == Vector2.ZERO:
		aim_dir = Vector2.LEFT
	for h_off in [-0.28, 0.28]:
		_spawn_homing_boss_bullet(global_position + Vector2(0, -20), aim_dir.rotated(h_off), 210.0, Color(0.55, 1.0, 0.9), 3.1, 3.6)

func _attack_mirror_volley(count: int, spd: float) -> void:
	_state_timer = 0.6
	_attack_shoot_orbs(count, spd, 0.3)

## Salón 1: Frascos químicos reactivos con trayectoria autodirigida hacia el héroe
func _attack_classroom_lab() -> void:
	_state_timer = 0.9
	var p_target = player
	for i in range(3):
		var ang: float = (-0.4 + float(i) * 0.4) + _attack_dir.angle()
		var dir := Vector2(cos(ang), sin(ang))
		var p = PROJECTILE_SCENE.instantiate()
		p.is_enemy_projectile = true
		p.position = global_position + Vector2(0, -20)
		p.direction = dir
		p.speed = 210.0
		p.modulate = Color(0.25, 0.95, 0.45) # Verde reactivo ácido
		p.is_homing = true
		p.homing_strength = 2.8
		p.homing_target = p_target
		p.scale = Vector2(0.9, 0.9)
		p.lifetime = 3.5
		p.collision_layer = 8
		p.collision_mask = 3
		var parent = get_parent() if get_parent() else self
		parent.add_child(p)
	var fx = _get_fx()
	if fx:
		fx.floating_text(get_parent() if get_parent() else self, global_position + Vector2(0, -45), "¡Reactivo Autodirigido!", Color(0.3, 1.0, 0.5), 12)

## Salón 2: Exámenes y hojas de calificaciones que rebotan en las paredes
func _attack_classroom_papers() -> void:
	_state_timer = 0.8
	for i in range(5):
		var ang: float = _attack_dir.angle() + randf_range(-0.6, 0.6)
		var dir := Vector2(cos(ang), sin(ang))
		var p = PROJECTILE_SCENE.instantiate()
		p.is_enemy_projectile = true
		p.position = global_position + Vector2(0, -20)
		p.direction = dir
		p.speed = 240.0 + float(i) * 15.0
		p.modulate = Color(0.95, 0.98, 1.0) # Blanco papel
		p.bounces_left = 3
		p.scale = Vector2(0.85, 0.85)
		p.lifetime = 4.0
		p.collision_layer = 8
		p.collision_mask = 3
		var parent = get_parent() if get_parent() else self
		parent.add_child(p)
	var fx = _get_fx()
	if fx:
		fx.floating_text(get_parent() if get_parent() else self, global_position + Vector2(0, -45), "¡Exámenes Voladores!", Color(0.9, 0.95, 1.0), 12)

## Salón 3: Ondas expansivas de apatía cívica desde el podio
func _attack_classroom_civic_shockwave() -> void:
	_state_timer = 1.1
	_attack_expanding_ring(130.0, 1.0)
	if is_inside_tree():
		get_tree().create_timer(0.35).timeout.connect(func():
			if is_instance_valid(self) and is_inside_tree() and current_state != State.REDEEMED:
				for i in range(10):
					var ang := float(i) * (TAU / 10.0) + 0.3
					_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), Vector2(cos(ang), sin(ang)), 170.0, Color(0.85, 0.70, 0.35))
		)
	var fx = _get_fx()
	if fx:
		fx.floating_text(get_parent() if get_parent() else self, global_position + Vector2(0, -45), "¡Onda de Indiferencia!", Color(1.0, 0.8, 0.4), 12)

## Salón 4: Ráfaga en abanico denso de libros pesados
func _attack_classroom_book_barrage() -> void:
	_state_timer = 0.9
	for i in range(7):
		var ang: float = _attack_dir.angle() - 0.5 + float(i) * (1.0 / 6.0)
		var dir := Vector2(cos(ang), sin(ang))
		_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), dir, 220.0, Color(0.85, 0.35, 0.30), 0.0, 0.9)
	var fx = _get_fx()
	if fx:
		fx.floating_text(get_parent() if get_parent() else self, global_position + Vector2(0, -45), "¡Ráfaga de Libros!", Color(1.0, 0.45, 0.4), 12)

## Salón 5: Glitch digital en cruz que se detiene y acelera
func _attack_classroom_digital_glitch() -> void:
	_state_timer = 1.0
	var dirs := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT,
				Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
				Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()]
	for d in dirs:
		var p = PROJECTILE_SCENE.instantiate()
		p.is_enemy_projectile = true
		p.position = global_position + Vector2(0, -20)
		p.direction = d
		p.speed = 120.0
		p.modulate = Color(0.2, 0.85, 1.0) # Cian digital
		p.lifetime = 3.5
		p.collision_layer = 8
		p.collision_mask = 3
		var parent = get_parent() if get_parent() else self
		parent.add_child(p)
		if is_inside_tree():
			get_tree().create_timer(0.4).timeout.connect(func():
				if is_instance_valid(self) and is_inside_tree() and current_state != State.REDEEMED and is_instance_valid(p) and player and is_instance_valid(player):
					p.set_direction((player.global_position - p.global_position).normalized())
					p.speed = 260.0
					p.modulate = Color(1.0, 0.3, 0.8)
			)
	var fx = _get_fx()
	if fx:
		fx.floating_text(get_parent() if get_parent() else self, global_position + Vector2(0, -45), "¡Sobrecarga de Datos!", Color(0.3, 0.9, 1.0), 12)

## Salón 6: Balones deportivos rebotantes y embestida veloz
func _attack_classroom_sports_slam() -> void:
	_state_timer = 1.0
	for i in range(4):
		var ang: float = float(i) * (TAU / 4.0) + randf_range(-0.3, 0.3)
		var dir := Vector2(cos(ang), sin(ang))
		var p = PROJECTILE_SCENE.instantiate()
		p.is_enemy_projectile = true
		p.position = global_position + Vector2(0, -20)
		p.direction = dir
		p.speed = 280.0
		p.modulate = Color(1.0, 0.55, 0.15) # Naranja básquetbol
		p.bounces_left = 4
		p.scale = Vector2(0.95, 0.95)
		p.lifetime = 4.2
		p.collision_layer = 8
		p.collision_mask = 3
		var parent = get_parent() if get_parent() else self
		parent.add_child(p)
	_dash_velocity = _attack_dir * 180.0
	var fx = _get_fx()
	if fx:
		fx.floating_text(get_parent() if get_parent() else self, global_position + Vector2(0, -45), "¡Balonazo Rápido!", Color(1.0, 0.6, 0.2), 12)

func _attack_rotating_barrier(duration: float) -> void:
	_state_timer = duration
	_barrier_active = true
	_barrier_timer = duration
	var fx = _get_fx()
	if fx:
		var parent = get_parent() if get_parent() else self
		fx.floating_text(parent, global_position + Vector2(0, -50), "¡Barrera Protectora!", Color(0.6, 0.8, 1.0), 13)

## Instancia un proyectil Danmaku hostil con parámetros Touhou
func _spawn_boss_danmaku_bullet(pos: Vector2, dir: Vector2, spd: float, col: Color, curve: float = 0.0, sz_scale: float = 0.75) -> void:
	var p = PROJECTILE_SCENE.instantiate()
	p.is_enemy_projectile = true
	p.position = pos
	p.direction = dir
	p.speed = spd
	p.modulate = col
	p.curve_speed = curve
	p.scale = Vector2(sz_scale, sz_scale)
	p.lifetime = 3.6
	p.collision_layer = 8
	p.collision_mask = 3
	p.remove_from_group("player_attack")
	p.add_to_group("enemy_projectiles")
	var target_parent = get_parent() if get_parent() else self
	target_parent.add_child(p)

## Instancia un proyectil enemigo teledirigido hacia el jugador
func _spawn_homing_boss_bullet(pos: Vector2, dir: Vector2, spd: float, col: Color, homing_str: float = 3.1, lifetime_sec: float = 3.6) -> void:
	var p = PROJECTILE_SCENE.instantiate()
	p.is_enemy_projectile = true
	p.position = pos
	p.direction = dir
	p.speed = spd
	p.modulate = col
	p.is_homing = true
	p.homing_strength = homing_str
	p.homing_target = player
	p.scale = Vector2(0.85, 0.85)
	p.lifetime = lifetime_sec
	p.collision_layer = 8
	p.collision_mask = 3
	p.remove_from_group("player_attack")
	p.add_to_group("enemy_projectiles")
	var target_parent = get_parent() if get_parent() else self
	target_parent.add_child(p)

func _update_attack(delta: float) -> void:
	_state_timer -= delta
	if _dash_velocity != Vector2.ZERO:
		velocity = _dash_velocity
		_dash_velocity = _dash_velocity.move_toward(Vector2.ZERO, 600.0 * delta)
	if _state_timer <= 0.0:
		_dash_velocity = Vector2.ZERO
		current_state = State.COOLDOWN
		_state_timer = randf_range(0.8, 1.5)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state != State.REDEEMED and current_state != State.APPEARING and not _is_covered_and_vanished and not _is_transforming:
		body.take_damage(1, global_position)

# -----------------------------------------------------------------------------
# DIBUJO PROCEDURAL PIXEL-ART Y TELEGRAFIADO EN 3/4 (BossRenderer)
# -----------------------------------------------------------------------------

func _draw() -> void:
	BossRendererClass.draw_boss(self)
