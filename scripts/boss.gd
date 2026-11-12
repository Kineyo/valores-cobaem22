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

const BOSS_DATA := {
	BossType.APATIA: {
		"name": "Apatyx, el Espectro del Desgano",
		"location": "Acceso y Laboratorio D (183 m²)",
		"max_hp": 32,
		"speed": 80.0,
		"color": Color(0.45, 0.40, 0.65),
		"accent_color": Color(0.70, 0.60, 0.95),
		"virtue": "¡Entusiasmo y Curiosidad!",
		"intro_dialog": "«Nada vale la pena... ¿para qué estudiar?»",
		"redeemed_dialog": "«¡Siento la chispa del conocimiento y el entusiasmo!»",
		"attack_names": ["Vórtice Espiral de Desgano", "Ráfaga Ciclónica del Desaliento", "Miasma Apatético"],
	},
	BossType.DESPERDICIO: {
		"name": "Desperdicius, el Titán del Desperdicio",
		"location": "Edificio A — Cafetería y Aulas (339 m²)",
		"max_hp": 40,
		"speed": 68.0,
		"color": Color(0.55, 0.50, 0.30),
		"accent_color": Color(0.85, 0.75, 0.40),
		"virtue": "¡Responsabilidad y Cuidado Ambiental!",
		"intro_dialog": "«¡Tira todo al suelo, alguien más lo limpiará!»",
		"redeemed_dialog": "«¡Cuidemos nuestro entorno y valoremos los recursos!»",
		"attack_names": ["Lluvia de Desechos", "Pisotón de Basura"],
	},
	BossType.INTOLERANCIA: {
		"name": "Superbus, el Heraldo de la Arrogancia",
		"location": "Plaza Cívica y Escalinata Sur (748 m²)",
		"max_hp": 48,
		"speed": 82.0,
		"color": Color(0.70, 0.25, 0.30),
		"accent_color": Color(1.0, 0.40, 0.45),
		"virtue": "¡Tolerancia y Respeto a la Diversidad!",
		"intro_dialog": "«¡Aquí solo cuentan los que piensan como yo!»",
		"redeemed_dialog": "«¡La diversidad de ideas enriquece a nuestra comunidad!»",
		"attack_names": ["Onda de Rechazo", "Ráfaga de Prejuicios"],
	},
	BossType.CIBERACOSO: {
		"name": "Ciber-Murmullus, el Espectro de la Difamación",
		"location": "Edificio B — Biblioteca y Aulas (280 m²)",
		"max_hp": 56,
		"speed": 92.0,
		"color": Color(0.20, 0.55, 0.75),
		"accent_color": Color(0.40, 0.85, 1.0),
		"virtue": "¡Empatía Digital y Honestidad!",
		"intro_dialog": "«Un mensaje anónimo no le hace daño a nadie...»",
		"redeemed_dialog": "«¡Las palabras en pantalla también tienen corazón!»",
		"attack_names": ["Cadenas de Rumores", "Falla Espectral"],
	},
	BossType.PLAGIO: {
		"name": "Plagiatrix, el Señor de la Falsedad",
		"location": "Edificio C — Cómputo y Dirección (625 m²)",
		"max_hp": 64,
		"speed": 72.0,
		"color": Color(0.35, 0.35, 0.45),
		"accent_color": Color(0.65, 0.75, 0.90),
		"virtue": "¡Autenticidad e Integridad Académica!",
		"intro_dialog": "«Copiar y pegar es más fácil que crear...»",
		"redeemed_dialog": "«¡Mi propio esfuerzo y aprendizaje es lo que vale!»",
		"attack_names": ["Copia Espejo", "Barrera de Atajos"],
	},
	BossType.BULLYING: {
		"name": "Titanor, el Coloso del Bullying Escolar",
		"location": "Cancha de Usos Múltiples y Gradas (540 m²)",
		"max_hp": 180,
		"speed": 88.0,
		"color": Color(0.50, 0.15, 0.35),
		"accent_color": Color(0.95, 0.30, 0.55),
		"virtue": "¡Fraternidad, Solidaridad y Fair Play!",
		"intro_dialog": "«¡El patio es mío y aquí manda el más fuerte!»",
		"redeemed_dialog": "«¡La verdadera fuerza protege, incluye y une a todos!»",
		"attack_names": [
			"Ruleta Danmaku Escolar",
			"Doble Espiral de Opresión",
			"Ruleta Kaleidoscópica Cruzada",
			"Último Hechizo: Resplandor de la Inclusión"
		],
	},
	BossType.DESINTERES: {
		"name": "Maestro Desinterés (Docente Indiferente)",
		"location": "Salón de Clases — Aula de Convivencia",
		"max_hp": 55,
		"speed": 85.0,
		"color": Color(0.55, 0.58, 0.62),
		"accent_color": Color(0.88, 0.92, 0.98),
		"virtue": "¡Compromiso, Escucha y Empatía Docente!",
		"intro_dialog": "«No es para tanto... resuélvanlo entre ustedes... yo tengo que calificar exámenes.»",
		"redeemed_dialog": "«¡Perdónenme! Ignorar el acoso escolar es ser cómplice. Mi deber como maestro es proteger a cada estudiante.»",
		"attack_names": ["Mirada Indiferente", "Burocracia Inmóvil"],
	}
}

## Tabla de Salud por Dificultad (Fácil, Normal, Difícil).
## En Difícil, Titanor cuenta con 450 HP: a 0.40s de cooldown por tiro continuo perfecto = 180.0s (3 minutos exactos)
## más 12s de transiciones de cartas de hechizo = 192s de duración mínima garantizada bajo ataque perfecto.
const BOSS_DIFFICULTY_HP := {
	BossType.APATIA: { 0: 16, 1: 32, 2: 65 },
	BossType.DESPERDICIO: { 0: 20, 1: 40, 2: 80 },
	BossType.INTOLERANCIA: { 0: 24, 1: 48, 2: 100 },
	BossType.CIBERACOSO: { 0: 28, 1: 56, 2: 120 },
	BossType.PLAGIO: { 0: 32, 1: 64, 2: 140 },
	BossType.BULLYING: { 0: 75, 1: 180, 2: 450 },
	BossType.DESINTERES: { 0: 25, 1: 55, 2: 120 },
}

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
		_hitbox.collision_mask = 6
		_hitbox.add_to_group("enemies")
		var hit_shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(44, 52)
		hit_shape.shape = rect
		hit_shape.position = Vector2(0, -26)
		_hitbox.add_child(hit_shape)
		_hitbox.body_entered.connect(_on_hitbox_body_entered)
		_hitbox.area_entered.connect(_on_hitbox_area_entered)
		add_child(_hitbox)
	else:
		_hitbox = $Hitbox
		_hitbox.collision_layer = 8
		_hitbox.collision_mask = 6
		if not _hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			_hitbox.body_entered.connect(_on_hitbox_body_entered)
		if not _hitbox.area_entered.is_connected(_on_hitbox_area_entered):
			_hitbox.area_entered.connect(_on_hitbox_area_entered)

func setup_boss_type(type: BossType) -> void:
	boss_type = type
	var data: Dictionary = BOSS_DATA[boss_type]
	max_hp = data["max_hp"]
	current_hp = max_hp
	move_speed = data["speed"]
	_detection_range_sq = detection_range * detection_range
	_spell_phase = 1
	_is_spell_transition = false
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
	_roulette_angle += delta * 1.25

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			modulate = Color.WHITE

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
						player.velocity *= 0.52 # Ralentización en fango apático
			i -= 1

	# Actualizar barrera reflectante (Plagiatrix / Maestro Desinterés)
	if _barrier_active:
		_barrier_timer -= delta
		if _barrier_timer <= 0.0 or current_state == State.STUNNED or current_state == State.REDEEMED:
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
				_proclaim_phrase(BOSS_DATA[boss_type]["intro_dialog"], Color(1.0, 0.8, 0.4))

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
				# En fases avanzadas de Titanor, cadencia más frenética
				var min_cd := attack_cooldown_range.x * (0.65 if _spell_phase >= 3 else 0.85)
				var max_cd := attack_cooldown_range.y * (0.65 if _spell_phase >= 3 else 0.85)
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

## Movimiento de merodeo o aproximación táctica
func _update_idle_movement(delta: float) -> void:
	if player and is_instance_valid(player) and player.can_control:
		var dist_sq := global_position.distance_squared_to(player.global_position)
		if dist_sq <= _detection_range_sq:
			var diff := player.global_position - global_position
			var dir := diff.normalized()

			# En Fase 4 de Titanor (Last Spell), orbita suavemente cerca del centro de la cancha
			if boss_type == BossType.BULLYING and _spell_phase == 4:
				var arena_center := Vector2(720, 450)
				var to_center := (arena_center - global_position).normalized()
				velocity = velocity.move_toward(to_center * (move_speed * 0.45), 250.0 * delta)
				return

			if dist_sq > 28900.0: # > 170 px
				velocity = velocity.move_toward(dir * move_speed, 400.0 * delta)
			elif dist_sq < 10000.0: # < 100 px
				velocity = velocity.move_toward(-dir * (move_speed * 0.75), 400.0 * delta)
			else:
				var perp := Vector2(-dir.y, dir.x)
				velocity = velocity.move_toward(perp * (move_speed * 0.65), 320.0 * delta)
			return
	velocity = velocity.move_toward(Vector2.ZERO, 350.0 * delta)

## Inicia el telegrafiado claro del ataque (anticipación visual precisa)
func _start_telegraph() -> void:
	current_state = State.TELEGRAPHING
	var attack_names: Array = BOSS_DATA[boss_type]["attack_names"]

	# Selección de ataque según el tipo y la fase activa
	if boss_type == BossType.BULLYING:
		# Titanor desata la carta correspondiente a su fase
		_current_attack_idx = mini(_spell_phase - 1, attack_names.size() - 1)
		_state_timer = 0.85
	elif boss_type == BossType.APATIA:
		# Boss 1: Apatía tiene 3 ataques demandantes y rápidos
		_current_attack_idx = randi() % (3 if current_hp < (max_hp / 2) else 2)
		_state_timer = 0.72 # Telegrafiado ágil para exigir reflejos tempranos
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
				_attack_targeted_burst(6, 180.0)
			else:
				_attack_glitch_teleport_starburst()

		BossType.PLAGIO:
			if _current_attack_idx == 0:
				_attack_mirror_volley(8, 200.0)
			else:
				_attack_rotating_barrier(2.2)

		BossType.BULLYING:
			# Danmaku Touhou Multi-Fase con Ruletas de Balas y Micro-Hitbox
			match _spell_phase:
				1:
					if randf() < 0.60:
						_attack_danmaku_roulette(2, 16, 170.0)
					else:
						_attack_dash_slam(330.0, 0.70)
				2:
					if randf() < 0.65:
						_attack_danmaku_double_spiral(16, 175.0, 1.15)
					else:
						_attack_ground_slam(120.0)
				3:
					if randf() < 0.70:
						_attack_danmaku_tri_roulette(3, 18, 160.0)
					else:
						_attack_targeted_snipe_stream(8, 195.0)
				_:
					# Fase 4: Último Hechizo (Clímax Danmaku)
					if randf() < 0.55:
						_attack_danmaku_master_climax(20, 165.0)
					else:
						_attack_danmaku_double_spiral(20, 185.0, 1.25)

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
	if current_state == State.REDEEMED or current_state == State.APPEARING:
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

	# Comprobar progresión de Fases Danmaku para Titanor
	if boss_type == BossType.BULLYING and current_hp > 0:
		var hp_ratio := float(current_hp) / float(max_hp)
		if hp_ratio <= 0.25 and _spell_phase < 4:
			_trigger_spell_card_phase(4, "¡ÚLTIMO HECHIZO: RESPLANDOR DE LA INCLUSIÓN Y FAIR PLAY!")
		elif hp_ratio <= 0.50 and _spell_phase < 3:
			_trigger_spell_card_phase(3, "¡CARTA DE HECHIZO: RULETA KALEIDOSCÓPICA CRUZADA!")
		elif hp_ratio <= 0.75 and _spell_phase < 2:
			_trigger_spell_card_phase(2, "¡CARTA DE HECHIZO: DOBLE ESPIRAL DE OPRESIÓN!")

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
	current_state = State.REDEEMED
	velocity = Vector2.ZERO
	_puddles.clear()
	_barrier_active = false
	_clear_all_enemy_projectiles()

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
	redeemed.emit(self)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.25, 1.25), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate", Color(2.0, 2.0, 1.5, 0.0), 1.5).set_delay(0.4)
	tw.chain().tween_callback(func():
		queue_free()
	)

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
			if is_inside_tree() and current_state != State.REDEEMED and player and is_instance_valid(player):
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
				if is_inside_tree() and current_state != State.REDEEMED and player and is_instance_valid(player):
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

func _attack_glitch_teleport_starburst() -> void:
	_state_timer = 0.5
	var fx = _get_fx()
	var parent = get_parent() if get_parent() else self
	if fx:
		fx.burst(parent, global_position, Color.CYAN, 14, 140.0)
	if player and is_instance_valid(player):
		var angles := [0.0, PI * 0.5, PI, PI * 1.5, PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]
		var chosen_angle: float = angles[randi() % angles.size()]
		var offset := Vector2(cos(chosen_angle), sin(chosen_angle)) * randf_range(130.0, 190.0)
		var candidate_pos := player.global_position + offset
		if parent and "map_size" in parent:
			var m_size: Vector2 = parent.map_size
			candidate_pos.x = clampf(candidate_pos.x, 80.0, m_size.x - 80.0)
			candidate_pos.y = clampf(candidate_pos.y, 80.0, m_size.y - 80.0)
		global_position = candidate_pos
		if fx:
			fx.burst(parent, global_position, Color.MAGENTA, 14, 140.0)
			fx.floating_text(parent, global_position + Vector2(0, -40), "¡GLITCH!", Color.CYAN, 12)
		# Ráfaga estelar de 8 balas al materializarse
		for k in range(8):
			var ang := float(k) * (TAU / 8.0)
			_spawn_boss_danmaku_bullet(global_position + Vector2(0, -20), Vector2(cos(ang), sin(ang)), 170.0, Color.CYAN)

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
			if is_instance_valid(self) and current_state != State.REDEEMED:
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
				if is_instance_valid(p) and player and is_instance_valid(player):
					p.direction = (player.global_position - p.global_position).normalized()
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
	if body is Player and current_state != State.REDEEMED and current_state != State.APPEARING:
		body.take_damage(1, global_position)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if current_state == State.REDEEMED or current_state == State.APPEARING:
		return
	if area.is_in_group("player_attack"):
		hit_by_attack(area.global_position)

# -----------------------------------------------------------------------------
# DIBUJO PROCEDURAL PIXEL-ART Y TELEGRAFIADO EN 3/4
# -----------------------------------------------------------------------------

func _draw() -> void:
	# 0. Dibujar Charcos de Desgano múltiples si están activos
	for pud in _puddles:
		var local_puddle := to_local(pud["pos"])
		var pulse := 0.40 + sin(_anim_time * 5.0) * 0.12
		var p_col := Color(0.35, 0.22, 0.55, pulse)
		draw_circle(local_puddle, pud["radius"], p_col)
		draw_arc(local_puddle, pud["radius"], 0, TAU, 24, Color(0.75, 0.55, 0.95, 0.75), 2.0)

	# 1. Sombra elíptica en perspectiva 3/4 para anclar el coloso al piso
	var shadow_col := Color(0.05, 0.06, 0.10, 0.40)
	draw_rect(Rect2(-24, -6, 48, 12), shadow_col)
	draw_rect(Rect2(-20, -10, 40, 20), shadow_col)

	var data: Dictionary = BOSS_DATA[boss_type]
	var base_col: Color = data["color"]
	var acc_col: Color = data["accent_color"]

	# Círculo Mágico de Carta de Hechizo Danmaku en suelo (Titanor)
	if boss_type == BossType.BULLYING:
		var circle_ang := _anim_time * 0.8
		var circle_col := Color(1.0, 0.35, 0.60, 0.22 + sin(_anim_time * 3.0) * 0.08)
		draw_arc(Vector2(0, -6), 46.0, circle_ang, circle_ang + TAU, 32, circle_col, 2.0)
		draw_arc(Vector2(0, -6), 38.0, -circle_ang, -circle_ang + TAU, 24, circle_col * 0.8, 1.5)

	# Cúpula de protección durante transición de fase
	if _is_spell_transition:
		var dome_alpha := 0.45 + sin(_anim_time * 12.0) * 0.20
		draw_circle(Vector2(0, -28), 54.0, Color(1.0, 0.85, 0.3, dome_alpha * 0.3))
		draw_arc(Vector2(0, -28), 54.0, 0, TAU, 32, Color(1.0, 0.95, 0.5, dome_alpha), 2.5)

	# 2. Dibujar telegrafiado en el suelo si está cargando ataque
	if current_state == State.TELEGRAPHING:
		var pulse_alpha := 0.35 + sin(_hazard_pulse) * 0.25
		var warn_col := Color(1.0, 0.25, 0.25, clampf(pulse_alpha, 0.15, 0.7))

		var is_radial: bool = (boss_type == BossType.BULLYING and _current_attack_idx == 1) \
			or (boss_type == BossType.INTOLERANCIA and _current_attack_idx == 0)

		if is_radial:
			var slam_r := 120.0
			draw_circle(Vector2.ZERO, slam_r, warn_col)
			draw_arc(Vector2.ZERO, slam_r, 0, TAU, 32, Color(1.0, 0.95, 0.3, 0.85), 3.0)
		else:
			var local_target := to_local(_attack_target_pos)
			var to_target := local_target.normalized() * clampf(local_target.length(), 60.0, 240.0)
			draw_line(Vector2.ZERO, to_target, warn_col, 20.0)
			draw_line(Vector2.ZERO, to_target, Color(1.0, 0.9, 0.2, pulse_alpha * 0.8), 2.0)
			draw_circle(to_target, 34.0, warn_col)
			draw_arc(to_target, 34.0, 0, TAU, 16, Color(1.0, 1.0, 0.3, 0.8), 2.0)

	# 3. Dibujar silueta pixel art del Jefe
	var breathe := sin(_anim_time * 4.0) * 2.0
	var body_rect := Rect2(-18, -48 + breathe, 36, 42)
	var head_rect := Rect2(-14, -66 + breathe, 28, 22)

	draw_rect(body_rect.grow(2.0), base_col.darkened(0.4))
	draw_rect(head_rect.grow(2.0), base_col.darkened(0.4))

	draw_rect(body_rect, base_col)
	draw_rect(head_rect, base_col.lightened(0.1))

	# Barrera de Atajos orbitante si está activa
	if _barrier_active:
		for i in range(3):
			var ang := _anim_time * 5.0 + float(i) * (TAU / 3.0)
			var shield_pos := Vector2(cos(ang), sin(ang) * 0.6) * 36.0 + Vector2(0, -26)
			draw_circle(shield_pos, 7.0, Color(0.4, 0.85, 1.0, 0.85))
			draw_arc(shield_pos, 7.0, 0, TAU, 12, Color.WHITE, 1.5)

	# Estrellas de mareo en estado STUNNED
	if current_state == State.STUNNED:
		for i in range(3):
			var star_ang := _anim_time * 8.0 + float(i) * (TAU / 3.0)
			var star_pos := Vector2(cos(star_ang) * 16.0, -82.0 + sin(star_ang) * 5.0)
			draw_circle(star_pos, 3.0, Color(1.0, 0.9, 0.2))

	# Rasgos característicos
	match boss_type:
		BossType.APATIA:
			draw_rect(Rect2(-8, -60 + breathe, 6, 4), Color.DARK_GRAY)
			draw_rect(Rect2(2, -60 + breathe, 6, 4), Color.DARK_GRAY)
		BossType.DESPERDICIO:
			draw_rect(Rect2(-12, -72 + breathe, 6, 8), acc_col)
			draw_rect(Rect2(6, -72 + breathe, 6, 8), acc_col)
			draw_rect(Rect2(-8, -60 + breathe, 5, 5), Color.YELLOW)
			draw_rect(Rect2(3, -60 + breathe, 5, 5), Color.YELLOW)
		BossType.INTOLERANCIA:
			draw_rect(Rect2(-10, -62 + breathe, 20, 4), Color.BLACK)
			draw_rect(Rect2(-8, -58 + breathe, 4, 4), Color.WHITE)
			draw_rect(Rect2(4, -58 + breathe, 4, 4), Color.WHITE)
		BossType.CIBERACOSO:
			draw_line(Vector2(-16, -55 + breathe), Vector2(16, -55 + breathe), Color.CYAN, 2.0)
			draw_line(Vector2(-12, -42 + breathe), Vector2(12, -42 + breathe), Color.MAGENTA, 2.0)
		BossType.PLAGIO:
			draw_rect(Rect2(-10, -62 + breathe, 9, 10), Color(0.2, 0.2, 0.3))
			draw_rect(Rect2(1, -62 + breathe, 9, 10), Color(0.7, 0.7, 0.8))
		BossType.BULLYING:
			draw_rect(Rect2(-24, -46 + breathe, 10, 14), acc_col)
			draw_rect(Rect2(14, -46 + breathe, 10, 14), acc_col)
			draw_rect(Rect2(-8, -62 + breathe, 5, 5), Color(1.0, 0.2, 0.2))
			draw_rect(Rect2(3, -62 + breathe, 5, 5), Color(1.0, 0.2, 0.2))
		BossType.DESINTERES:
			draw_rect(Rect2(-12, -64 + breathe, 24, 18), Color(0.57, 0.60, 0.65))
			if is_fog_active:
				draw_rect(Rect2(-8, -58 + breathe, 5, 4), Color(1.0, 0.1, 0.15))
				draw_rect(Rect2(3, -58 + breathe, 5, 4), Color(1.0, 0.1, 0.15))
				var heart_pulse := 1.0 + sin(_anim_time * 6.0) * 0.2
				draw_circle(Vector2(-3, -38 + breathe), 5.0 * heart_pulse, Color(0.95, 0.15, 0.25))
				draw_circle(Vector2(3, -38 + breathe), 5.0 * heart_pulse, Color(0.95, 0.15, 0.25))
				draw_polygon(PackedVector2Array([
					Vector2(-7, -38 + breathe), Vector2(7, -38 + breathe), Vector2(0, -28 + breathe)
				]), [Color(0.95, 0.15, 0.25)])
				draw_circle(Vector2(-3, -38 + breathe), 3.5 * heart_pulse, Color(0.06, 0.04, 0.08))
				draw_circle(Vector2(3, -38 + breathe), 3.5 * heart_pulse, Color(0.06, 0.04, 0.08))
			else:
				draw_rect(Rect2(-8, -58 + breathe, 5, 4), Color.WHITE)
				draw_rect(Rect2(3, -58 + breathe, 5, 4), Color.WHITE)
			draw_rect(Rect2(-5, -50 + breathe, 10, 2), Color(0.35, 0.38, 0.42))
			draw_rect(Rect2(-2, -44 + breathe, 4, 14), Color(0.47, 0.18, 0.22))
			draw_rect(Rect2(14, -40 + breathe, 8, 12), Color(0.62, 0.55, 0.45))

	# Corona / indicador de Jefe
	draw_polygon(PackedVector2Array([
		Vector2(-10, -70 + breathe), Vector2(-6, -76 + breathe),
		Vector2(0, -71 + breathe), Vector2(6, -76 + breathe),
		Vector2(10, -70 + breathe), Vector2(0, -67 + breathe)
	]), PackedColorArray([Color(1.0, 0.85, 0.3)]))
