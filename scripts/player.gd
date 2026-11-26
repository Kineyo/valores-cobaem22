extends CharacterBody2D
class_name Player

## Personaje principal (Pixel) en perspectiva 3/4.
## Control en 8 direcciones (WASD / Flechas) y disparo de proyectiles de virtudes.

signal health_changed(current_health: int, max_health: int)
signal died
signal reached_goal
signal empathy_pulse_triggered(cooldown: float)
signal inventory_changed(item_id: String, item_info: Dictionary)
signal esperanza_activated(duration: float)

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const ESPERANZA_DURATION: float = 15.0
const ITEM_DATA := {
	"esperanza": {
		"name": "Esperanza",
		"short": "ESPERANZA",
		"desc": "15s sin clones ni niebla; jefe indefenso",
		"color": Color(1.0, 0.88, 0.25),
	},
	"heart": {
		"name": "Corazón",
		"short": "CORAZÓN",
		"desc": "Restaura +1 vida",
		"color": Color(1.0, 0.35, 0.50),
	},
	"shield": {
		"name": "Escudo",
		"short": "ESCUDO",
		"desc": "Protección temporal 4s",
		"color": Color(0.35, 0.85, 1.0),
	},
}
const EMPATHY_PULSE_COOLDOWN: float = 10.0
const EMPATHY_PULSE_RADIUS: float = 140.0
const EMPATHY_PULSE_RADIUS_SQ: float = 19600.0
const EMPATHY_SLOW_RADIUS_SQ: float = 32400.0
const CORE_OFFSET := Vector2(0.0, -10.0)
const CORE_RADIUS := 5.5
const CORE_RADIUS_SQ := CORE_RADIUS * CORE_RADIUS

## Sprites del personaje según la dirección cardinal y estado
const DEFAULT_TEX_IDLE := preload("res://assets/sprites/player_idle.png")        # Vista frontal (Sur)
const DEFAULT_TEX_WALK_RIGHT := preload("res://assets/sprites/player_walk_right.png") # Vista derecha (Este)
const DEFAULT_TEX_WALK_LEFT := preload("res://assets/sprites/player_walk_left.png")   # Vista izquierda (Oeste)
const DEFAULT_TEX_BACK := preload("res://assets/sprites/player_back.png")        # Vista de espaldas (Norte)
const DEFAULT_TEX_ATTACK := preload("res://assets/sprites/player_attack.png")
const DEFAULT_TEX_HURT := preload("res://assets/sprites/player_hurt.png")

var tex_idle: Texture2D = DEFAULT_TEX_IDLE
var tex_walk_right: Texture2D = DEFAULT_TEX_WALK_RIGHT
var tex_walk_left: Texture2D = DEFAULT_TEX_WALK_LEFT
var tex_back: Texture2D = DEFAULT_TEX_BACK
var tex_attack: Texture2D = DEFAULT_TEX_ATTACK
var tex_hurt: Texture2D = DEFAULT_TEX_HURT

@export var speed: float = 230.0
@export var max_health: int = 3
@export var knockback_force: float = 340.0
## Cadencia entre disparos (ajustada dinámicamente por dificultad)
@export var shot_cooldown: float = 0.35
## Duración de la pose de ataque cuerpo a cuerpo
@export var attack_pose_time: float = 0.15

@export_group("Sensación de control")
@export var acceleration: float = 2200.0
@export var friction: float = 2600.0
## Desplazamiento anticipado de cámara hacia la dirección de avance
@export var camera_look_ahead: float = 48.0

var health: int = 3
var is_invulnerable: bool = false
var is_attacking: bool = false
## Vector cardinal actual de orientación: (0, 1) Abajo, (0, -1) Arriba, (1, 0) Der, (-1, 0) Izq
var facing_vector: Vector2 = Vector2.DOWN
## Vector de puntería para joystick derecho táctil o gamepad (360°)
var aim_vector: Vector2 = Vector2.ZERO
var can_control: bool = true
var is_focusing: bool = false
var graze_count: int = 0
var _danmaku_mode: bool = false

var shot_scale: float = 1.0
var shot_speed: float = 520.0
var invulnerable_time: float = 1.0
var _shot_cooldown_left: float = 0.0

var _knockback_left: float = 0.0
var _walk_time: float = 0.0
var _dust_timer: float = 0.0
var _squash_tween: Tween
var _flash_tween: Tween
var _hit_this_attack: Array[int] = []
var _current_attack_hits: Dictionary = {}
var empathy_cooldown_left: float = 0.0
var _empathy_wave_timer: float = 0.0
var _empathy_key_was_pressed: bool = false
var _use_item_key_was_pressed: bool = false
var _danmaku_check_timer: float = 0.0
var _puddle_slow_timer: float = 0.0
var _graze_boost_timer: float = 0.0
var mobile_aim_vector: Vector2 = Vector2.ZERO
var held_item: String = ""
var _fx: Node = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_sprite: Sprite2D = $AttackArea/AttackFX
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var invulnerable_timer: Timer = $InvulnerableTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var sfx_attack: AudioStreamPlayer = $SFXAttack

func _get_fx() -> Node:
	if _fx == null or not is_instance_valid(_fx):
		_fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	return _fx
@onready var sfx_hurt: AudioStreamPlayer = $SFXHurt
@onready var camera: Camera2D = $Camera2D
@onready var dust: CPUParticles2D = $DustParticles

@onready var _base_scale: Vector2 = sprite.scale
@onready var _base_sprite_y: float = sprite.position.y

func _ready() -> void:
	y_sort_enabled = true
	add_to_group("player")
	setup_character_skin()
	apply_difficulty()
	health = max_health

	if attack_sprite:
		attack_sprite.visible = false
	if attack_collision:
		attack_collision.disabled = true
	if attack_area:
		attack_area.position = Vector2(0.0, -14.0) + facing_vector * 22.0

	if not attack_area.area_entered.is_connected(_on_attack_area_entered):
		attack_area.area_entered.connect(_on_attack_area_entered, CONNECT_DEFERRED)
	if not attack_area.body_entered.is_connected(_on_attack_body_entered):
		attack_area.body_entered.connect(_on_attack_body_entered, CONNECT_DEFERRED)
	if not invulnerable_timer.timeout.is_connected(_on_invulnerable_timer_timeout):
		invulnerable_timer.timeout.connect(_on_invulnerable_timer_timeout)
	if not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
		attack_timer.timeout.connect(_on_attack_timer_timeout)

	# Emitir estado inicial de salud
	health_changed.emit(health, max_health)
	_update_texture(Vector2.ZERO)
	queue_redraw()

func get_core_position() -> Vector2:
	return global_position + CORE_OFFSET

func get_core_radius_sq() -> float:
	return CORE_RADIUS_SQ # Radio 5.5 px (Micro-hitbox estilo Touhou)

func on_graze(bullet_pos: Vector2) -> void:
	if is_invulnerable or not can_control or health <= 0:
		return
	graze_count += 1
	var fx := _get_fx()
	if fx and get_parent():
		fx.burst(get_parent(), bullet_pos, Color(0.4, 0.9, 1.0, 0.8), 4, 60.0)
		if graze_count % 12 == 0:
			_graze_boost_timer = 3.0
			fx.floating_text(get_parent(), global_position + Vector2(0, -32), "Impulso x%d" % graze_count, Color(0.5, 0.95, 1.0), 12)
	# Recompensa táctica por maestría: cada 35 rozaduras recupera un corazón si está herido
	if graze_count % 35 == 0 and health < max_health:
		health = mini(max_health, health + 1)
		health_changed.emit(health, max_health)
		_flash(Color(1.2, 2.0, 1.5))
		if fx and get_parent():
			fx.floating_text(get_parent(), global_position + Vector2(0, -42), "Calma restaurada", Color(0.4, 1.0, 0.6), 13)

func _draw() -> void:
	# Sombra elíptica pixel-art para anclar al personaje al suelo en perspectiva 3/4
	var shadow_col := Color(0.06, 0.08, 0.12, 0.34)
	draw_rect(Rect2(-12, -4, 24, 6), shadow_col)
	draw_rect(Rect2(-10, -6, 20, 10), shadow_col)

	# Indicador visual del núcleo Touhou (Micro-hitbox de 5.5 px) en Modo Enfoque / Danmaku
	if is_focusing or _danmaku_mode:
		var core_center := Vector2(0, -10.0)
		var t := Time.get_ticks_msec() * 0.005
		# Anillo exterior rotatorio con retícula
		draw_arc(core_center, 8.5, t, t + TAU, 16, Color(1.0, 0.3, 0.4, 0.85), 1.2)
		draw_line(core_center + Vector2(cos(t), sin(t)) * 6.0, core_center + Vector2(cos(t), sin(t)) * 12.0, Color.WHITE, 1.0)
		draw_line(core_center + Vector2(-cos(t), -sin(t)) * 6.0, core_center + Vector2(-cos(t), -sin(t)) * 12.0, Color.WHITE, 1.0)
		# Núcleo rojo brillante central de impacto vital
		draw_circle(core_center, 3.2, Color(1.0, 0.15, 0.25, 0.95))
		draw_circle(core_center, 1.5, Color.WHITE)

	# Anillo expansivo del Pulso de Empatía
	if _empathy_wave_timer > 0.0:
		var progress := 1.0 - (_empathy_wave_timer / 0.45)
		var ring_r := lerpf(16.0, EMPATHY_PULSE_RADIUS, progress)
		var ring_alpha := clampf(1.0 - progress, 0.0, 1.0)
		draw_arc(Vector2(0, -10.0), ring_r, 0.0, TAU, 36, Color(0.45, 0.95, 1.0, 0.85 * ring_alpha), 3.0)
		draw_arc(Vector2(0, -10.0), ring_r * 0.72, 0.0, TAU, 28, Color(1.0, 0.92, 0.45, 0.65 * ring_alpha), 1.8)

## Aplica los parámetros de balance configurados en GameSettings
func apply_difficulty() -> void:
	var gs: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		gs = get_tree().root.get_node_or_null("GameSettings")
	if gs == null and is_inside_tree():
		gs = get_node_or_null("/root/GameSettings")

	if gs and gs.has_method("get_param"):
		max_health = gs.get_param("max_health")
		shot_cooldown = gs.get_param("shot_cooldown")
		shot_scale = gs.get_param("shot_scale")
		shot_speed = gs.get_param("shot_speed")
		invulnerable_time = gs.get_param("invulnerable_time")
	else:
		max_health = 3
		shot_cooldown = 0.35
		shot_scale = 1.0
		shot_speed = 520.0
		invulnerable_time = 1.0

## Configura los sprites del personaje según el aspecto seleccionado (Pantalón vs Falda)
func setup_character_skin(skin_id: int = -1) -> void:
	if skin_id < 0:
		var gs: Node = null
		if is_inside_tree() and get_tree() and get_tree().root:
			gs = get_tree().root.get_node_or_null("GameSettings")
		if gs == null and is_inside_tree():
			gs = get_node_or_null("/root/GameSettings")
		if gs and "selected_character" in gs:
			skin_id = gs.selected_character
		else:
			skin_id = 0

	var is_fem := (skin_id == 1)
	var skin_folder := "res://assets/characters/Femenino/" if is_fem else "res://assets/characters/Masculino/"

	tex_idle = _load_skin_texture(skin_folder, ["idle.png", "frente.png", "Capa 1.png"], DEFAULT_TEX_IDLE)
	tex_walk_right = _load_skin_texture(skin_folder, ["walk_right.png", "walk_r.png", "caminata_derecha.png", "Capa 3.png"], DEFAULT_TEX_WALK_RIGHT)
	tex_walk_left = _load_skin_texture(skin_folder, ["walk_left.png", "walk_l.png", "caminata_izquierda.png", "Capa 2.png"], DEFAULT_TEX_WALK_LEFT)
	tex_back = _load_skin_texture(skin_folder, ["back.png", "espalda.png", "up.png", "Capa 5.png", "Capa 6.png"], DEFAULT_TEX_BACK)
	tex_attack = _load_skin_texture(skin_folder, ["attack.png", "atack.png", "ataque.png"], DEFAULT_TEX_ATTACK)
	tex_hurt = _load_skin_texture(skin_folder, ["hurt.png", "dano.png", "daño.png", "herido.png"], DEFAULT_TEX_HURT)

	if sprite:
		_update_texture(Vector2.ZERO)

func _load_skin_texture(folder: String, candidate_filenames: Array, fallback_tex: Texture2D) -> Texture2D:
	for fname in candidate_filenames:
		var tex := AssetLoader.load_texture(folder + str(fname))
		if tex != null:
			return tex
	return fallback_tex

func _physics_process(delta: float) -> void:
	if not can_control:
		velocity = velocity.move_toward(Vector2.ZERO, friction * 0.5 * delta)
		move_and_slide()
		return

	_shot_cooldown_left = maxf(0.0, _shot_cooldown_left - delta)
	_knockback_left = maxf(0.0, _knockback_left - delta)
	empathy_cooldown_left = maxf(0.0, empathy_cooldown_left - delta)
	if _graze_boost_timer > 0.0:
		_graze_boost_timer = maxf(0.0, _graze_boost_timer - delta)
	if _empathy_wave_timer > 0.0:
		_empathy_wave_timer = maxf(0.0, _empathy_wave_timer - delta)
		queue_redraw()

	var empathy_pressed_now: bool = (InputMap.has_action("empathy_pulse") and Input.is_action_pressed("empathy_pulse")) or Input.is_physical_key_pressed(KEY_E)
	if empathy_pressed_now and not _empathy_key_was_pressed:
		trigger_empathy_pulse()
	_empathy_key_was_pressed = empathy_pressed_now

	var use_item_now: bool = (InputMap.has_action("use_item") and Input.is_action_pressed("use_item")) or Input.is_physical_key_pressed(KEY_Q) or Input.is_physical_key_pressed(KEY_F)
	if use_item_now and not _use_item_key_was_pressed:
		use_held_item()
	_use_item_key_was_pressed = use_item_now

	# Modo Enfoque Touhou (Precisión micrométrica con Shift, L1 o controles móviles)
	is_focusing = (InputMap.has_action("focus") and Input.is_action_pressed("focus")) or Input.is_key_pressed(KEY_SHIFT)
	var effective_speed: float = speed * 0.52 if is_focusing else speed
	if _puddle_slow_timer > 0.0:
		_puddle_slow_timer = maxf(0.0, _puddle_slow_timer - delta)
		effective_speed *= 0.55

	_danmaku_check_timer -= delta
	if _danmaku_check_timer <= 0.0:
		_danmaku_check_timer = 0.2
		var shot_count := get_tree().get_nodes_in_group("enemy_projectiles").size() if is_inside_tree() else 0
		_danmaku_mode = is_focusing or (shot_count > 6)
	elif is_focusing:
		_danmaku_mode = true

	if is_focusing or _danmaku_mode:
		queue_redraw()

	# Entrada direccional en 8 direcciones (WASD, Flechas o Joystick Izquierdo)
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Puntería direccional (Joystick Derecho táctil, stick derecho / IJKL, o cursor ratón en PC)
	var joy_aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	var mouse_firing := (not MobileControls.is_touch_device()) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and is_inside_tree()
	if joy_aim.length_squared() > 0.08:
		aim_vector = joy_aim
	elif mobile_aim_vector.length_squared() > 0.08:
		aim_vector = mobile_aim_vector
	elif mouse_firing:
		var to_mouse := get_global_mouse_position() - (global_position + Vector2(0.0, -14.0))
		aim_vector = to_mouse.normalized() if to_mouse.length_squared() > 16.0 else Vector2.ZERO
	else:
		aim_vector = Vector2.ZERO

	# Si se apunta con joystick derecho o ratón, orientar al personaje hacia ese ángulo; si no, por movimiento
	if aim_vector != Vector2.ZERO:
		_update_facing(aim_vector)
	elif input_vector != Vector2.ZERO and _knockback_left <= 0.0:
		_update_facing(input_vector)

	# Disparo continuo si se mantiene ataque o se apunta con joystick/ratón
	var wants_attack := Input.is_action_pressed("attack") or aim_vector != Vector2.ZERO or mouse_firing
	if wants_attack and _shot_cooldown_left <= 0.0:
		perform_attack()

	# Movimiento en plano 2D con aceleración e inercia (velocidad adaptada en Modo Enfoque)
	if _knockback_left <= 0.0:
		if input_vector != Vector2.ZERO:
			velocity = velocity.move_toward(input_vector * effective_speed, acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		# Fricción durante retroceso por impacto para desaceleración natural
		velocity = velocity.move_toward(Vector2.ZERO, friction * 0.75 * delta)

	_update_texture(input_vector)
	move_and_slide()
	_animate_procedural(delta, input_vector)

	# Cámara con desplazamiento suave hacia la dirección de visión
	var target_cam_offset := facing_vector * camera_look_ahead
	camera.position = camera.position.lerp(target_cam_offset, 1.0 - exp(-4.0 * delta))

	# Parpadeo visual durante invulnerabilidad
	if is_invulnerable:
		sprite.modulate.a = 0.35 if (Time.get_ticks_msec() / 90) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0

func _update_facing(input_vector: Vector2) -> void:
	# Prioriza la dirección cardinal con mayor componente
	var new_facing: Vector2
	if absf(input_vector.y) > absf(input_vector.x):
		new_facing = Vector2.UP if input_vector.y < 0.0 else Vector2.DOWN
	else:
		new_facing = Vector2.LEFT if input_vector.x < 0.0 else Vector2.RIGHT

	if new_facing != facing_vector:
		facing_vector = new_facing
		# Posicionar el área de ataque cuerpo a cuerpo a la altura del torso frente al jugador
		attack_area.position = Vector2(0.0, -14.0) + facing_vector * 22.0

func _update_texture(_input_vector: Vector2) -> void:
	if is_attacking:
		if sprite and sprite.texture != tex_attack:
			sprite.texture = tex_attack
		var need_flip := (facing_vector == Vector2.LEFT)
		if sprite and sprite.flip_h != need_flip:
			sprite.flip_h = need_flip
		return

	# Seleccionar sprite según orientación cardinal
	var target_tex: Texture2D = tex_idle
	if facing_vector == Vector2.UP:
		target_tex = tex_back
	elif facing_vector == Vector2.DOWN:
		target_tex = tex_idle
	elif facing_vector == Vector2.LEFT:
		target_tex = tex_walk_left
	elif facing_vector == Vector2.RIGHT:
		target_tex = tex_walk_right

	if sprite and sprite.texture != target_tex:
		sprite.texture = target_tex
	if sprite and sprite.flip_h:
		sprite.flip_h = false

## Animación procedural de balanceo al caminar y partículas de polvo
func _animate_procedural(delta: float, input_vector: Vector2) -> void:
	if velocity.length_squared() > 100.0:
		_walk_time += delta * 14.0
		# Rebote vertical sutil al dar pasos
		sprite.position.y = _base_sprite_y - absf(sin(_walk_time)) * 2.5
		# Inclinación lateral
		sprite.rotation = sin(_walk_time) * 0.04

		# Emisión periódica de polvo
		_dust_timer -= delta
		if _dust_timer <= 0.0:
			_dust_timer = 0.22
			if dust:
				dust.restart()
	else:
		_walk_time = 0.0
		sprite.position.y = lerpf(sprite.position.y, _base_sprite_y, 1.0 - exp(-20.0 * delta))
		sprite.rotation = lerpf(sprite.rotation, 0.0, 1.0 - exp(-20.0 * delta))

func perform_attack() -> void:
	is_attacking = true
	_hit_this_attack.clear()
	_current_attack_hits = {}
	_shot_cooldown_left = shot_cooldown * (0.78 if _graze_boost_timer > 0.0 else 1.0)
	if sfx_attack:
		sfx_attack.pitch_scale = randf_range(0.94, 1.06)
		sfx_attack.play()

	if attack_sprite:
		attack_sprite.visible = true
	if attack_collision:
		attack_collision.disabled = false
	if attack_timer:
		attack_timer.start(attack_pose_time)

	check_attack_hits()
	spawn_projectile()
	_squash(Vector2(0.92, 1.06), 0.12)

## Resuelve el estilo de disparo activo (0 = Pulso Guinda, 1 = Destello Guinda)
func get_shot_style() -> int:
	var gs := get_node_or_null("/root/GameSettings") if is_inside_tree() else null
	if gs == null and is_inside_tree() and get_tree() and get_tree().root:
		gs = get_tree().root.get_node_or_null("GameSettings")
	if gs:
		if gs.has_method("get_effective_shot_style"):
			return int(gs.get_effective_shot_style())
		if "selected_character" in gs:
			return clampi(int(gs.selected_character), 0, 1)
	return 0

## Instancia proyectiles con identidad visual y mecánica propia según el estilo elegido
func spawn_projectile() -> void:
	var shot_dir: Vector2 = aim_vector.normalized() if aim_vector != Vector2.ZERO else facing_vector
	if shot_dir.length_squared() < 0.001:
		shot_dir = Vector2.DOWN

	var origin := global_position + Vector2(0, -10.0)
	var desired_dist := 14.0
	if is_inside_tree() and get_world_2d():
		var space_state := get_world_2d().direct_space_state
		if space_state:
			var query := PhysicsRayQueryParameters2D.create(origin, origin + shot_dir * (desired_dist + 6.0), 1)
			query.exclude = [self.get_rid()]
			var hit := space_state.intersect_ray(query)
			if hit:
				var hit_d_sq := origin.distance_squared_to(hit.position)
				if hit_d_sq < 144.0:
					desired_dist = 0.0
				else:
					desired_dist = 6.0

	var target_parent: Node = get_parent()
	if target_parent == null and is_inside_tree() and get_tree():
		target_parent = get_tree().current_scene
	if target_parent == null:
		return

	var world_spawn := origin + shot_dir * desired_dist
	var local_spawn: Vector2 = (target_parent as Node2D).to_local(world_spawn) if target_parent is Node2D else world_spawn
	var style := get_shot_style()

	if style == 1:
		# Destello Guinda: doble cometa dorado-cian convergente con registro compartido de impacto
		for pair in [[-0.11, 0.95], [0.11, -0.95]]:
			var shot: Projectile = PROJECTILE_SCENE.instantiate()
			shot.visual_style = &"destello_guinda"
			shot.speed = shot_speed * 0.98
			shot.curve_speed = float(pair[1])
			shot.pierce_left = 1 if is_focusing else 0
			shot.scale = Vector2(shot_scale, shot_scale)
			shot.modulate = Color(0.96, 0.98, 1.0)
			shot.z_index = 25
			shot.shared_hit_registry = _current_attack_hits
			shot.position = local_spawn
			shot.set_direction(shot_dir.rotated(float(pair[0])))
			target_parent.add_child(shot)
	else:
		# Pulso Guinda: haz recto veloz de precisión con calma leve
		var shot: Projectile = PROJECTILE_SCENE.instantiate()
		shot.visual_style = &"pulso_guinda"
		shot.speed = shot_speed * 1.04
		shot.apply_slow_on_hit = 0.25 if is_focusing else 0.15
		shot.scale = Vector2(shot_scale, shot_scale)
		shot.modulate = Color(1.0, 0.94, 0.80)
		shot.z_index = 25
		shot.shared_hit_registry = _current_attack_hits
		shot.position = local_spawn
		shot.set_direction(shot_dir)
		target_parent.add_child(shot)

func check_attack_hits() -> void:
	if not is_attacking:
		return
	for area in attack_area.get_overlapping_areas():
		_hit_enemy_area(area)
	for body in attack_area.get_overlapping_bodies():
		if body.has_method("hit_by_attack"):
			_register_melee_hit(body)

func _register_melee_hit(target: Object) -> void:
	if not is_instance_valid(target):
		return
	var target_id := target.get_instance_id()
	if target_id in _hit_this_attack or _current_attack_hits.has(target_id):
		return
	_hit_this_attack.append(target_id)
	_current_attack_hits[target_id] = true
	target.hit_by_attack(global_position)

func _hit_enemy_area(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("hit_by_attack"):
			_register_melee_hit(area)
			return
		var enemy = area.get_parent()
		if enemy and enemy.has_method("hit_by_attack"):
			_register_melee_hit(enemy)

func _on_attack_body_entered(body: Node2D) -> void:
	if not is_instance_valid(body) or not is_attacking:
		return
	if body.is_in_group("enemies") or body.has_method("hit_by_attack"):
		_register_melee_hit(body)

func _on_attack_timer_timeout() -> void:
	is_attacking = false
	if attack_sprite:
		attack_sprite.visible = false
	if attack_collision:
		attack_collision.disabled = true
	if attack_area:
		attack_area.position = Vector2(0.0, -14.0) + facing_vector * 22.0
	sprite.flip_h = false

## Concede protección temporal de aparición al salir de un salón para evitar daño sin defensa
func grant_spawn_protection(duration: float = 2.0) -> void:
	can_control = true
	is_invulnerable = true
	if invulnerable_timer:
		invulnerable_timer.start(duration)

func apply_puddle_slow(duration: float = 0.15) -> void:
	_puddle_slow_timer = maxf(_puddle_slow_timer, duration)

## Inventario de 1 solo espacio: recoge un ítem (si ya hay otro distinto, lo reemplaza)
func pickup_item(item_id: String) -> bool:
	var key := item_id.strip_edges().to_lower()
	if not ITEM_DATA.has(key):
		return false
	if held_item == key:
		return false
	var had_previous := not held_item.is_empty()
	held_item = key
	var info: Dictionary = ITEM_DATA[key]
	inventory_changed.emit(held_item, info)
	var fx := _get_fx()
	if fx and is_inside_tree():
		var p := get_parent() if get_parent() else self
		var msg := "%s equipado [Q]" % str(info["name"]) if not had_previous else "Cambiado a %s [Q]" % str(info["name"])
		fx.floating_text(p, global_position + Vector2(0, -48), msg, info["color"], 13)
	return true

func set_held_item_silently(item_id: String) -> void:
	var key := item_id.strip_edges().to_lower()
	if key.is_empty() or not ITEM_DATA.has(key):
		held_item = ""
		inventory_changed.emit("", {})
	else:
		held_item = key
		inventory_changed.emit(held_item, ITEM_DATA[held_item])

func use_held_item() -> bool:
	if not can_control or held_item.is_empty():
		return false
	var item := held_item
	var fx := _get_fx()
	var p := get_parent() if get_parent() else self
	match item:
		"esperanza":
			held_item = ""
			inventory_changed.emit("", {})
			esperanza_activated.emit(ESPERANZA_DURATION)
			if fx and is_inside_tree():
				fx.burst(p, global_position + Vector2(0, -16), Color(1.0, 0.90, 0.30), 20, 170.0)
				fx.floating_text(p, global_position + Vector2(0, -54), "Esperanza activa (15s)", Color(1.0, 0.92, 0.35), 15)
				if fx.has_method("vibrate_mobile"):
					fx.vibrate_mobile(22)
			return true
		"heart":
			if health >= max_health:
				if fx and is_inside_tree():
					fx.floating_text(p, global_position + Vector2(0, -44), "Salud al máximo", Color(1.0, 0.75, 0.8), 12)
				return false
			held_item = ""
			inventory_changed.emit("", {})
			health = mini(max_health, health + 1)
			health_changed.emit(health, max_health)
			if fx and is_inside_tree():
				fx.burst(p, global_position + Vector2(0, -16), Color(1.0, 0.4, 0.6), 12, 120.0)
				fx.floating_text(p, global_position + Vector2(0, -48), "+1 Vida", Color(1.0, 0.55, 0.72), 14)
				if fx.has_method("vibrate_mobile"):
					fx.vibrate_mobile(14)
			return true
		"shield":
			held_item = ""
			inventory_changed.emit("", {})
			grant_spawn_protection(4.0)
			if fx and is_inside_tree():
				fx.burst(p, global_position + Vector2(0, -16), Color(0.45, 0.95, 1.0), 14, 130.0)
				fx.floating_text(p, global_position + Vector2(0, -48), "Escudo de Respeto (4s)", Color(0.45, 0.95, 1.0), 14)
				if fx.has_method("vibrate_mobile"):
					fx.vibrate_mobile(14)
			return true
	return false

## Habilidad activa de apoyo: disipa proyectiles cercanos y ralentiza antivalores sin violencia
func trigger_empathy_pulse() -> bool:
	if empathy_cooldown_left > 0.0 or not can_control or health <= 0:
		return false
	empathy_cooldown_left = EMPATHY_PULSE_COOLDOWN
	_empathy_wave_timer = 0.45
	queue_redraw()

	var fx := _get_fx()
	var parent_node := get_parent()

	var slowed_ids: Dictionary = {}
	if is_inside_tree() and get_tree():
		for shot in get_tree().get_nodes_in_group("enemy_projectiles"):
			if is_instance_valid(shot) and shot is Node2D:
				if global_position.distance_squared_to(shot.global_position) <= EMPATHY_PULSE_RADIUS_SQ:
					if fx and parent_node:
						fx.burst(parent_node, shot.global_position, Color(0.55, 0.95, 1.0), 4, 70.0)
					shot.queue_free()

		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e is Node2D and e.has_method("apply_empathy_slow"):
				if global_position.distance_squared_to(e.global_position) <= EMPATHY_SLOW_RADIUS_SQ:
					slowed_ids[e.get_instance_id()] = true
					e.apply_empathy_slow(2.0)

		for s in get_tree().get_nodes_in_group("students"):
			if is_instance_valid(s) and s is Node2D and s.has_method("cheer_up_area"):
				s.cheer_up_area(global_position, EMPATHY_PULSE_RADIUS)

	if parent_node:
		for sib in parent_node.get_children():
			if sib != self and sib is Node2D and sib.has_method("apply_empathy_slow"):
				if not slowed_ids.has(sib.get_instance_id()) and global_position.distance_squared_to(sib.global_position) <= EMPATHY_SLOW_RADIUS_SQ:
					slowed_ids[sib.get_instance_id()] = true
					sib.apply_empathy_slow(2.0)
			elif sib.name == "Enemies":
				for e in sib.get_children():
					if e is Node2D and e.has_method("apply_empathy_slow"):
						if not slowed_ids.has(e.get_instance_id()) and global_position.distance_squared_to(e.global_position) <= EMPATHY_SLOW_RADIUS_SQ:
							slowed_ids[e.get_instance_id()] = true
							e.apply_empathy_slow(2.0)

	if fx and parent_node:
		fx.burst(parent_node, global_position + Vector2(0, -12), Color(0.45, 0.95, 1.0), 14, 150.0)
		fx.floating_text(parent_node, global_position + Vector2(0, -36), "Onda de Calma", Color(0.45, 0.95, 1.0), 14)
		if fx.has_method("vibrate_mobile"):
			fx.vibrate_mobile(20)
	if sfx_attack:
		sfx_attack.pitch_scale = 1.25
		sfx_attack.play()
	empathy_pulse_triggered.emit(EMPATHY_PULSE_COOLDOWN)
	return true

func take_damage(amount: int, from_pos: Variant = null) -> void:
	if is_invulnerable or health <= 0 or not can_control:
		return

	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)

	if sfx_hurt:
		sfx_hurt.play()

	# Empuje en 2D en dirección contraria al impacto
	var push_dir := Vector2.DOWN
	if from_pos is Vector2:
		var diff: Vector2 = global_position - from_pos
		push_dir = diff.normalized() if diff != Vector2.ZERO else Vector2.DOWN
	elif from_pos is float or from_pos is int:
		push_dir = Vector2.LEFT if position.x <= float(from_pos) else Vector2.RIGHT

	velocity = push_dir * knockback_force
	_knockback_left = 0.2

	if sprite:
		sprite.texture = tex_hurt
		sprite.flip_h = false
	_flash(Color(3.0, 1.2, 1.2))
	var fx := _get_fx()
	if fx:
		fx.shake(5.0, 0.25)
		fx.hitstop(0.06)
		if fx.has_method("vibrate_mobile"):
			fx.vibrate_mobile(28)

	if health <= 0:
		_die(push_dir)
	else:
		is_invulnerable = true
		if invulnerable_timer:
			invulnerable_timer.start(invulnerable_time)

func _die(push_dir: Vector2) -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	can_control = false
	is_attacking = false
	velocity = push_dir * (knockback_force * 0.4)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sprite, "rotation", 0.35 * signf(push_dir.x if push_dir.x != 0 else 1.0), 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "self_modulate", Color(0.55, 0.55, 0.65), 0.6).set_delay(0.2)
	died.emit()

## Pose de victoria: salta de alegría mirando hacia arriba/meta
func celebrate() -> void:
	can_control = false
	is_attacking = false
	is_invulnerable = false
	velocity = Vector2.ZERO
	if sprite:
		sprite.modulate = Color.WHITE
		sprite.flip_h = false
		sprite.texture = tex_back
	if attack_sprite:
		attack_sprite.visible = false
	reached_goal.emit()
	for i in 2:
		if not is_inside_tree():
			return
		_squash(Vector2(0.8, 1.25), 0.22)
		await get_tree().create_timer(0.45).timeout

func _squash(amount: Vector2, time: float) -> void:
	if sprite == null:
		return
	if _squash_tween and _squash_tween.is_valid():
		_squash_tween.kill()
	sprite.scale = _base_scale * amount
	_squash_tween = create_tween()
	_squash_tween.tween_property(sprite, "scale", _base_scale, time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _flash(color: Color) -> void:
	if sprite == null:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	sprite.self_modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.22)

func _on_invulnerable_timer_timeout() -> void:
	is_invulnerable = false
	if sprite:
		sprite.modulate = Color.WHITE

func _on_attack_area_entered(area: Area2D) -> void:
	if not is_instance_valid(area):
		return
	_hit_enemy_area(area)
