extends CharacterBody2D
class_name Player

## Personaje principal (Pixel) en perspectiva 3/4.
## Control en 8 direcciones (WASD / Flechas) y disparo de proyectiles de virtudes.

signal health_changed(current_health: int, max_health: int)
signal died
signal reached_goal

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")

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

var shot_scale: float = 1.3
var shot_speed: float = 520.0
var invulnerable_time: float = 1.0
var _shot_cooldown_left: float = 0.0

var _knockback_left: float = 0.0
var _walk_time: float = 0.0
var _dust_timer: float = 0.0
var _squash_tween: Tween
var _flash_tween: Tween

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_sprite: Sprite2D = $AttackArea/AttackFX
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var invulnerable_timer: Timer = $InvulnerableTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var sfx_attack: AudioStreamPlayer = $SFXAttack
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

	if not attack_area.area_entered.is_connected(_on_attack_area_entered):
		attack_area.area_entered.connect(_on_attack_area_entered)
	if not invulnerable_timer.timeout.is_connected(_on_invulnerable_timer_timeout):
		invulnerable_timer.timeout.connect(_on_invulnerable_timer_timeout)
	if not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
		attack_timer.timeout.connect(_on_attack_timer_timeout)

	# Emitir estado inicial de salud
	health_changed.emit(health, max_health)
	_update_texture(Vector2.ZERO)
	queue_redraw()

func get_core_position() -> Vector2:
	return global_position + Vector2(0, -10.0)

func get_core_radius_sq() -> float:
	return 30.25 # Radio 5.5 px (Micro-hitbox estilo Touhou)

func on_graze(bullet_pos: Vector2) -> void:
	graze_count += 1
	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx and get_parent():
		fx.burst(get_parent(), bullet_pos, Color(0.4, 0.9, 1.0, 0.8), 4, 60.0)
		if graze_count % 10 == 0:
			fx.floating_text(get_parent(), global_position + Vector2(0, -32), "¡GRAZE x%d!" % graze_count, Color(0.5, 0.9, 1.0), 11)
	# Recompensa táctica por maestría: cada 35 rozaduras recupera un corazón si está herido
	if graze_count % 35 == 0 and health < max_health:
		health = mini(max_health, health + 1)
		health_changed.emit(health, max_health)
		_flash(Color(1.2, 2.0, 1.5))
		if fx and get_parent():
			fx.floating_text(get_parent(), global_position + Vector2(0, -42), "¡VALOR RESTAURADO!", Color(0.4, 1.0, 0.6), 13)

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
		shot_scale = 1.3
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
		var p: String = folder + str(fname)
		if ResourceLoader.exists(p):
			var res = load(p)
			if res is Texture2D:
				return res
		var global_p: String = ProjectSettings.globalize_path(p)
		var actual_path: String = global_p if FileAccess.file_exists(global_p) else p
		if FileAccess.file_exists(actual_path):
			var img := Image.new()
			var err := img.load(actual_path)
			if err == OK:
				return ImageTexture.create_from_image(img)
	return fallback_tex

func _physics_process(delta: float) -> void:
	if not can_control:
		velocity = velocity.move_toward(Vector2.ZERO, friction * 0.5 * delta)
		move_and_slide()
		return

	_shot_cooldown_left = maxf(0.0, _shot_cooldown_left - delta)
	_knockback_left = maxf(0.0, _knockback_left - delta)

	# Modo Enfoque Touhou (Precisión micrométrica con Shift, acción focus o controles móviles)
	is_focusing = Input.is_key_pressed(KEY_SHIFT) or (InputMap.has_action("focus") and Input.is_action_pressed("focus"))
	var effective_speed: float = speed * 0.52 if is_focusing else speed

	var enemy_shots: Array = get_tree().get_nodes_in_group("enemy_projectiles") if is_inside_tree() else []
	_danmaku_mode = is_focusing or (enemy_shots.size() > 6)
	if is_focusing or _danmaku_mode:
		queue_redraw()

	# Entrada direccional en 8 direcciones (WASD, Flechas o Joystick Izquierdo)
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Puntería direccional (Joystick Derecho táctil o stick derecho de Gamepad)
	var joy_aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if joy_aim.length_squared() > 0.08:
		aim_vector = joy_aim
	elif not Input.is_action_pressed("attack"):
		aim_vector = Vector2.ZERO

	# Si se apunta con joystick derecho, orientar al personaje hacia ese ángulo; si no, por movimiento
	if aim_vector != Vector2.ZERO:
		_update_facing(aim_vector)
	elif input_vector != Vector2.ZERO and _knockback_left <= 0.0:
		_update_facing(input_vector)

	# Disparo de valores continuo si se mantiene ataque o se apunta con el joystick derecho
	var wants_attack := Input.is_action_pressed("attack") or aim_vector != Vector2.ZERO
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
		# Posicionar el área de ataque cuerpo a cuerpo frente al jugador
		attack_area.position = facing_vector * 24.0

func _update_texture(_input_vector: Vector2) -> void:
	if is_attacking:
		if sprite and sprite.texture != tex_attack:
			sprite.texture = tex_attack
		var need_flip := (facing_vector == Vector2.LEFT)
		if sprite and sprite.flip_h != need_flip:
			sprite.flip_h = need_flip
		return

	if is_invulnerable and health <= 0:
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
	_shot_cooldown_left = shot_cooldown
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

## Instancia un proyectil radiante hacia la dirección cardinal de mira o puntería de joystick
func spawn_projectile() -> void:
	var shot_dir: Vector2 = aim_vector.normalized() if aim_vector != Vector2.ZERO else facing_vector
	if shot_dir.length_squared() < 0.001:
		shot_dir = Vector2.DOWN
	var shot: Projectile = PROJECTILE_SCENE.instantiate()
	shot.direction = shot_dir
	shot.speed = shot_speed
	shot.scale = Vector2(shot_scale, shot_scale)

	# Origen centrado en el pecho/manos del personaje
	var origin := global_position + Vector2(0, -10.0)
	var desired_dist := 14.0

	# Consulta física por raycast para evitar que el proyectil se engendre dentro de un muro u obstáculo
	if is_inside_tree() and get_world_2d():
		var space_state := get_world_2d().direct_space_state
		if space_state:
			var query := PhysicsRayQueryParameters2D.create(origin, origin + shot_dir * (desired_dist + 6.0), 1) # Capa 1: Obstáculos
			query.exclude = [self.get_rid()]
			var hit := space_state.intersect_ray(query)
			if hit:
				var hit_dist: float = origin.distance_to(hit.position)
				desired_dist = maxf(2.0, hit_dist - 4.0)

	shot.global_position = origin + shot_dir * desired_dist

	var target_parent: Node = get_parent()
	if target_parent == null and is_inside_tree() and get_tree():
		target_parent = get_tree().current_scene
	if target_parent:
		target_parent.add_child(shot)

func check_attack_hits() -> void:
	if not is_attacking:
		return
	for area in attack_area.get_overlapping_areas():
		_hit_enemy_area(area)
	for body in attack_area.get_overlapping_bodies():
		if (body.is_in_group("enemies") or body is Enemy) and body.has_method("hit_by_attack"):
			body.hit_by_attack(global_position)

func _hit_enemy_area(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		var enemy = area.get_parent()
		if enemy and enemy.has_method("hit_by_attack"):
			enemy.hit_by_attack(global_position)

func _on_attack_timer_timeout() -> void:
	is_attacking = false
	if attack_sprite:
		attack_sprite.visible = false
	if attack_collision:
		attack_collision.disabled = true
	sprite.flip_h = false

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
	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx:
		fx.shake(5.0, 0.25)
		fx.hitstop(0.06)

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
	_hit_enemy_area(area)
