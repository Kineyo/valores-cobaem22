extends CharacterBody2D
class_name Boss

## Jefe Final de Escenario en perspectiva 3/4 para Campeones de los Valores (COBAEM CEMSaD 22).
## Implementa máquina de estados finitos, ataques telegrafiados adaptados a móvil/pantalla táctil,
## optimización de distancia euclidiana al cuadrado (sin sqrt en physics loop),
## y filosofía educativa de redención pacífica (cero violencia).

signal health_changed(current_hp: int, max_hp: int)
signal attack_telegraphed(attack_name: String, duration: float)
signal redeemed(boss: Boss)

enum BossType {
	APATIA,        ## Nivel 1: Sombra de la Apatía (Acceso / Lab. D)
	DESPERDICIO,   ## Nivel 2: Troll del Desperdicio (Edif. A - Cafetería)
	INTOLERANCIA,  ## Nivel 3: Sombra de la Intolerancia (Plaza Cívica)
	CIBERACOSO,    ## Nivel 4: Espectro del Ciberacoso (Edif. B - Biblioteca)
	PLAGIO,        ## Nivel 5: Titán del Plagio (Edif. C - Taller Cómputo)
	BULLYING       ## Nivel 6: Coloso del Bullying (Cancha Usos Múltiples)
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
		"max_hp": 6,
		"speed": 75.0,
		"color": Color(0.45, 0.40, 0.65),
		"accent_color": Color(0.70, 0.60, 0.95),
		"virtue": "¡Entusiasmo y Curiosidad!",
		"intro_dialog": "«Nada vale la pena... ¿para qué estudiar?»",
		"redeemed_dialog": "«¡Siento la chispa del conocimiento y el entusiasmo!»",
		"attack_names": ["Charco de Desgano", "Orbe Apático"],
	},
	BossType.DESPERDICIO: {
		"name": "Desperdicius, el Titán del Desperdicio",
		"location": "Edificio A — Cafetería y Aulas (339 m²)",
		"max_hp": 8,
		"speed": 65.0,
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
		"max_hp": 9,
		"speed": 80.0,
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
		"max_hp": 10,
		"speed": 90.0,
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
		"max_hp": 12,
		"speed": 70.0,
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
		"max_hp": 15,
		"speed": 85.0,
		"color": Color(0.50, 0.15, 0.35),
		"accent_color": Color(0.95, 0.30, 0.55),
		"virtue": "¡Fraternidad, Solidaridad y Fair Play!",
		"intro_dialog": "«¡El patio es mío y aquí manda el más fuerte!»",
		"redeemed_dialog": "«¡La verdadera fuerza protege, incluye y une a todos!»",
		"attack_names": ["Golpe Terrestre", "Embestida Ciclónica"],
	}
}

@export var boss_type: BossType = BossType.APATIA
@export var detection_range: float = 380.0
@export var attack_cooldown_range: Vector2 = Vector2(2.0, 3.5)

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

# Mecánicas RPG especiales por Jefe
var _puddle_active: bool = false
var _puddle_pos: Vector2 = Vector2.ZERO
var _puddle_radius: float = 65.0
var _puddle_timer: float = 0.0

var _barrier_active: bool = false
var _barrier_timer: float = 0.0

# Nodos visuales y áreas
var _hitbox: Area2D
var _collision_shape: CollisionShape2D
var _sprite_offset: Vector2 = Vector2(0, -28)

func _get_fx() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Fx")
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
	# Colisión de movimiento (Capa canónica 4: Enemigos, Mask 1: Obstáculos)
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

	# Hitbox para recibir virtudes y dañar al jugador (Layer 4 = 8, Mask = 6 -> Jugador 2 + Proyectil 4)
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
	health_changed.emit(current_hp, max_hp)
	queue_redraw()

func apply_difficulty() -> void:
	if not is_inside_tree():
		return
	var gs = get_node_or_null("/root/GameSettings")
	if gs:
		if gs.has_method("get_param"):
			move_speed *= gs.get_param("enemy_speed_mult")
		if "difficulty" in gs:
			if gs.difficulty == 2: # Dificultad difícil
				max_hp += 2
				current_hp = max_hp
			elif gs.difficulty == 0: # Dificultad fácil
				max_hp = maxi(3, max_hp - 2)
				current_hp = max_hp
		health_changed.emit(current_hp, max_hp)

func _physics_process(delta: float) -> void:
	_anim_time += delta
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			modulate = Color.WHITE

	# Actualizar mecánicas de área persistente (ej. Charco de Desgano)
	if _puddle_active:
		_puddle_timer -= delta
		if _puddle_timer <= 0.0:
			_puddle_active = false
		elif player and is_instance_valid(player) and player.can_control:
			if player.global_position.distance_squared_to(_puddle_pos) <= _puddle_radius * _puddle_radius:
				# Ralentiza suavemente al héroe si camina dentro del fango apático
				player.velocity *= 0.55

	# Actualizar barrera reflectante (Titán del Plagio)
	if _barrier_active:
		_barrier_timer -= delta
		if _barrier_timer <= 0.0 or current_state == State.STUNNED or current_state == State.REDEEMED:
			_barrier_active = false

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
				_state_timer = randf_range(attack_cooldown_range.x, attack_cooldown_range.y)

		State.STUNNED:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				current_state = State.IDLE
				_state_timer = 1.0

		State.REDEEMED:
			velocity = Vector2.ZERO

	if is_inside_tree() and PhysicsServer2D.body_get_space(get_rid()).is_valid():
		move_and_slide()
	queue_redraw()

## Movimiento de merodeo o aproximación cautelosa al jugador
func _update_idle_movement(delta: float) -> void:
	if player and is_instance_valid(player) and player.can_control:
		var dist_sq := global_position.distance_squared_to(player.global_position)
		if dist_sq <= _detection_range_sq:
			# Se posiciona a distancia táctica (120-180 px) sin encimarse bruscamente
			var diff := player.global_position - global_position
			var dir := diff.normalized()
			if dist_sq > 22500.0: # > 150 px
				velocity = velocity.move_toward(dir * move_speed, 400.0 * delta)
			elif dist_sq < 10000.0: # < 100 px (demasiado cerca, retrocede con prudencia)
				velocity = velocity.move_toward(-dir * (move_speed * 0.7), 400.0 * delta)
			else:
				# Maniobra orbital lateral para telegrafiar con dramatismo
				var perp := Vector2(-dir.y, dir.x)
				velocity = velocity.move_toward(perp * (move_speed * 0.6), 300.0 * delta)
			return
	velocity = velocity.move_toward(Vector2.ZERO, 350.0 * delta)

## Inicia el telegrafiado claro del ataque (anticipación de 0.95s adaptada a pantalla táctil)
func _start_telegraph() -> void:
	current_state = State.TELEGRAPHING
	_current_attack_idx = randi() % 2
	var attack_names: Array = BOSS_DATA[boss_type]["attack_names"]
	var atk_name: String = attack_names[_current_attack_idx]

	_state_timer = 0.95
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
		fx.floating_text(parent, global_position + Vector2(0, -60), "¡" + atk_name + "!", Color(1.0, 0.4, 0.4), 13)
		fx.shake(1.8, 0.18)

func _update_telegraph(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
	_hazard_pulse += delta * 8.0
	_state_timer -= delta
	if _state_timer <= 0.0:
		_execute_attack()

## Ejecuta la fase activa del ataque tras completarse el telegrafiado
func _execute_attack() -> void:
	current_state = State.ATTACKING
	match boss_type:
		BossType.APATIA:
			if _current_attack_idx == 0:
				_attack_area_hazard("Charco de Desgano", 65.0, 3.2)
			else:
				_attack_shoot_orbs(3, 140.0, 0.25)
		BossType.DESPERDICIO:
			if _current_attack_idx == 0:
				_attack_spread_projectiles(5, 170.0, PI * 0.35)
			else:
				_attack_dash_slam(280.0, 0.6)
		BossType.INTOLERANCIA:
			if _current_attack_idx == 0:
				_attack_expanding_ring(125.0, 1.0)
			else:
				_attack_cross_volley(180.0)
		BossType.CIBERACOSO:
			if _current_attack_idx == 0:
				_attack_targeted_burst(4, 160.0)
			else:
				_attack_glitch_teleport()
		BossType.PLAGIO:
			if _current_attack_idx == 0:
				_attack_mirror_volley(6, 190.0)
			else:
				_attack_rotating_barrier(1.8)
		BossType.BULLYING:
			if _current_attack_idx == 0:
				_attack_ground_slam(115.0)
			else:
				_attack_dash_slam(340.0, 0.8)

## Impactado por un disparo de virtudes o ataque cuerpo a cuerpo del héroe
func hit_by_attack(attacker_pos: Variant = null, damage: int = 1) -> void:
	if current_state == State.REDEEMED or current_state == State.APPEARING:
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
		fx.shake(4.0, 0.22)
		fx.burst(get_parent(), hit_pos, accent_col, 18, 170.0)
		fx.burst(get_parent(), hit_pos, Color.WHITE, 8, 120.0)

	# Destello luminoso de impacto
	modulate = Color(2.5, 2.2, 1.2, 1.0)
	_flash_timer = 0.14

	# Retroceso suave pero firme (física de jefe colosal)
	if attacker_pos != null and attacker_pos is Vector2:
		var push_dir: Vector2 = (global_position - (attacker_pos as Vector2)).normalized()
		velocity += push_dir * 110.0

	# Comprobar redención pacífica o interrupción en carga
	if current_hp <= 0:
		redeem()
	elif current_state == State.TELEGRAPHING and randf() < 0.35:
		# Ventana de interrupción táctica al impactar durante la carga del ataque
		current_state = State.STUNNED
		_state_timer = 0.85
		if fx:
			fx.floating_text(get_parent(), hit_pos + Vector2(0, -25), "¡INTERRUPCIÓN!", Color(1.0, 0.9, 0.3), 14)

## Redención pacífica (filosofía sin violencia): el antivalor mayor se transforma e ilumina
func redeem() -> void:
	current_state = State.REDEEMED
	velocity = Vector2.ZERO
	_puddle_active = false
	_barrier_active = false
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

	# Animación de transformación luminosa y ascensión pacífica
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
# MÉTODOS DE ATAQUE TELEGRAFIADO
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

func _attack_area_hazard(label_name: String, radius: float, duration: float) -> void:
	_state_timer = 0.45
	_puddle_active = true
	_puddle_pos = _attack_target_pos
	_puddle_radius = radius
	_puddle_timer = duration
	var fx = _get_fx()
	if fx:
		var parent = get_parent() if get_parent() else self
		fx.burst(parent, _attack_target_pos, BOSS_DATA[boss_type]["color"], 16, 90.0)

func _attack_shoot_orbs(count: int, orb_speed: float, spread_angle: float) -> void:
	_state_timer = 0.5
	var base_ang := _attack_dir.angle()
	var start_ang := base_ang - (spread_angle * 0.5 * (count - 1))
	for i in range(count):
		var ang := start_ang + spread_angle * i
		var dir := Vector2(cos(ang), sin(ang))
		_spawn_boss_projectile(dir, orb_speed)

func _attack_spread_projectiles(count: int, proj_speed: float, total_arc: float) -> void:
	_state_timer = 0.6
	var base_ang := _attack_dir.angle()
	var step := total_arc / float(maxi(1, count - 1))
	var start_ang := base_ang - total_arc * 0.5
	for i in range(count):
		var ang := start_ang + step * i
		var dir := Vector2(cos(ang), sin(ang))
		_spawn_boss_projectile(dir, proj_speed)

func _attack_cross_volley(spd: float) -> void:
	_state_timer = 0.5
	var dirs := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for d in dirs:
		_spawn_boss_projectile(d, spd)

func _attack_expanding_ring(radius: float, duration: float) -> void:
	_state_timer = duration
	_attack_cross_volley(160.0)
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
		_spawn_boss_projectile((_attack_dir + jitter).normalized(), spd + float(i) * 15.0)

func _attack_glitch_teleport() -> void:
	_state_timer = 0.5
	var fx = _get_fx()
	var parent = get_parent() if get_parent() else self
	if fx:
		fx.burst(parent, global_position, Color.CYAN, 14, 140.0)
	if player and is_instance_valid(player):
		var angles := [0.0, PI * 0.5, PI, PI * 1.5, PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]
		var chosen_angle: float = angles[randi() % angles.size()]
		var offset := Vector2(cos(chosen_angle), sin(chosen_angle)) * randf_range(120.0, 180.0)
		var candidate_pos := player.global_position + offset
		if parent and "map_size" in parent:
			var m_size: Vector2 = parent.map_size
			candidate_pos.x = clampf(candidate_pos.x, 80.0, m_size.x - 80.0)
			candidate_pos.y = clampf(candidate_pos.y, 80.0, m_size.y - 80.0)
		global_position = candidate_pos
		if fx:
			fx.burst(parent, global_position, Color.MAGENTA, 14, 140.0)
			fx.floating_text(parent, global_position + Vector2(0, -40), "¡GLITCH!", Color.CYAN, 12)

func _attack_mirror_volley(count: int, spd: float) -> void:
	_state_timer = 0.6
	_attack_shoot_orbs(count, spd, 0.3)

func _attack_rotating_barrier(duration: float) -> void:
	_state_timer = duration
	_barrier_active = true
	_barrier_timer = duration
	var fx = _get_fx()
	if fx:
		var parent = get_parent() if get_parent() else self
		fx.floating_text(parent, global_position + Vector2(0, -50), "¡Barrera de Atajos!", Color(0.6, 0.8, 1.0), 13)

func _spawn_boss_projectile(dir: Vector2, spd: float) -> void:
	var p = PROJECTILE_SCENE.instantiate()
	p.is_enemy_projectile = true
	p.position = global_position + Vector2(0, -20)
	p.direction = dir
	p.speed = spd
	p.modulate = BOSS_DATA[boss_type]["accent_color"]
	p.collision_layer = 8
	p.collision_mask = 3 # Capa 1: Obstáculos + Capa 2: Jugador
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
		_state_timer = randf_range(1.0, 1.8)

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
	# 0. Dibujar Charco de Desgano en suelo si está activo
	if _puddle_active:
		var local_puddle := to_local(_puddle_pos)
		var p_col := Color(0.35, 0.25, 0.55, 0.45 + sin(_anim_time * 4.0) * 0.15)
		draw_circle(local_puddle, _puddle_radius, p_col)
		draw_arc(local_puddle, _puddle_radius, 0, TAU, 24, Color(0.7, 0.5, 0.9, 0.7), 2.0)

	# 1. Sombra elíptica en perspectiva 3/4 para anclar el coloso al piso
	var shadow_col := Color(0.05, 0.06, 0.10, 0.40)
	draw_rect(Rect2(-24, -6, 48, 12), shadow_col)
	draw_rect(Rect2(-20, -10, 40, 20), shadow_col)

	var data: Dictionary = BOSS_DATA[boss_type]
	var base_col: Color = data["color"]
	var acc_col: Color = data["accent_color"]

	# 2. Dibujar telegrafiado en el suelo si está cargando ataque
	if current_state == State.TELEGRAPHING:
		var pulse_alpha := 0.35 + sin(_hazard_pulse) * 0.25
		var warn_col := Color(1.0, 0.25, 0.25, clampf(pulse_alpha, 0.15, 0.7))

		var is_radial: bool = (boss_type == BossType.BULLYING and _current_attack_idx == 0) \
			or (boss_type == BossType.INTOLERANCIA and _current_attack_idx == 0)

		if is_radial:
			# Círculo de advertencia en área de impacto radial centrada en el jefe
			var slam_r := 115.0 if boss_type == BossType.BULLYING else 125.0
			draw_circle(Vector2.ZERO, slam_r, warn_col)
			draw_arc(Vector2.ZERO, slam_r, 0, TAU, 32, Color(1.0, 0.95, 0.3, 0.85), 3.0)
		else:
			# Línea telegrafiada de trayectoria hacia el objetivo
			var local_target := to_local(_attack_target_pos)
			var to_target := local_target.normalized() * clampf(local_target.length(), 60.0, 240.0)
			draw_line(Vector2.ZERO, to_target, warn_col, 22.0)
			draw_line(Vector2.ZERO, to_target, Color(1.0, 0.9, 0.2, pulse_alpha * 0.8), 2.0)

			# Retícula circular de impacto en el punto objetivo
			draw_circle(to_target, 36.0, warn_col)
			draw_arc(to_target, 36.0, 0, TAU, 16, Color(1.0, 1.0, 0.3, 0.8), 2.0)

	# 3. Dibujar silueta pixel art del Jefe (escala 1.5x - 2.0x respecto a enemigos estándar)
	var breathe := sin(_anim_time * 4.0) * 2.0
	var body_rect := Rect2(-18, -48 + breathe, 36, 42)
	var head_rect := Rect2(-14, -66 + breathe, 28, 22)

	# Capa de aura / silueta externa
	draw_rect(body_rect.grow(2.0), base_col.darkened(0.4))
	draw_rect(head_rect.grow(2.0), base_col.darkened(0.4))

	# Cuerpo central
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

	# Detalles icónicos según el tipo de jefe
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

	# Corona / indicador de Jefe
	draw_polygon(PackedVector2Array([
		Vector2(-10, -70 + breathe), Vector2(-6, -76 + breathe),
		Vector2(0, -71 + breathe), Vector2(6, -76 + breathe),
		Vector2(10, -70 + breathe), Vector2(0, -67 + breathe)
	]), PackedColorArray([Color(1.0, 0.85, 0.3)]))
