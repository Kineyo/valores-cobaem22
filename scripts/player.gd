extends CharacterBody2D
class_name Player

## Personaje principal (Pixel) en perspectiva 3/4 estilo Pokémon.
## Representa al promotor de los buenos valores.
## Control en 4 y 8 direcciones (WASD / Flechas), disparo en la dirección a la que mira.

signal health_changed(current_health: int, max_health: int)
signal died
signal reached_goal

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")

## Texturas precargadas
const TEX_IDLE := preload("res://assets/sprites/player_idle.png")        # Vista frontal (Hacia abajo / Sur)
const TEX_WALK_RIGHT := preload("res://assets/sprites/player_walk_right.png") # Vista derecha (Este)
const TEX_WALK_LEFT := preload("res://assets/sprites/player_walk_left.png")   # Vista izquierda (Oeste)
const TEX_BACK := preload("res://assets/sprites/player_back.png")        # Vista de espaldas (Hacia arriba / Norte)
const TEX_ATTACK := preload("res://assets/sprites/player_attack.png")
const TEX_HURT := preload("res://assets/sprites/player_hurt.png")

@export var speed: float = 230.0
@export var max_health: int = 3
@export var knockback_force: float = 340.0
## Segundos entre disparos (se sobrescribe según la dificultad)
@export var shot_cooldown: float = 0.35
## Tiempo que se muestra la pose / golpe cuerpo a cuerpo
@export var attack_pose_time: float = 0.15

@export_group("Sensación de control")
@export var acceleration: float = 2200.0
@export var friction: float = 2600.0
## Desplazamiento de la cámara hacia donde mira el jugador
@export var camera_look_ahead: float = 48.0

var health: int = 3
var is_invulnerable: bool = false
var is_attacking: bool = false
## Vector cardinal al que mira: (0, 1) Abajo, (0, -1) Arriba, (1, 0) Der, (-1, 0) Izq
var facing_vector: Vector2 = Vector2.DOWN
var can_control: bool = true

var shot_scale: float = 1.3
var shot_speed: float = 520.0
var invulnerable_time: float = 1.0
var _shot_cooldown_left: float = 0.0

var _knockback_left: float = 0.0
var _walk_time: float = 0.0
var _dust_timer: float = 0.0
var _squash_tween: Tween

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
	apply_difficulty()
	health = max_health

	if attack_sprite:
		attack_sprite.visible = false
	if attack_collision:
		attack_collision.disabled = true

	attack_area.area_entered.connect(_on_attack_area_entered)
	invulnerable_timer.timeout.connect(_on_invulnerable_timer_timeout)
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	# Emitir vida inicial
	health_changed.emit(health, max_health)
	_update_texture(Vector2.ZERO)

## Lee los parámetros de la dificultad elegida en el menú de inicio.
func apply_difficulty() -> void:
	max_health = GameSettings.get_param("max_health")
	shot_cooldown = GameSettings.get_param("shot_cooldown")
	shot_scale = GameSettings.get_param("shot_scale")
	shot_speed = GameSettings.get_param("shot_speed")
	invulnerable_time = GameSettings.get_param("invulnerable_time")

func _physics_process(delta: float) -> void:
	if not can_control:
		velocity = velocity.move_toward(Vector2.ZERO, friction * 0.5 * delta)
		move_and_slide()
		return

	_shot_cooldown_left = maxf(0.0, _shot_cooldown_left - delta)
	_knockback_left = maxf(0.0, _knockback_left - delta)

	# Entrada en 4 u 8 direcciones (WASD o Flechas)
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Disparo de valores (mantener Espacio para auto-disparo con cooldown)
	if Input.is_action_pressed("attack") and _shot_cooldown_left <= 0.0:
		perform_attack()

	# Movimiento en el plano 2D (perspectiva 3/4 sin gravedad)
	if _knockback_left <= 0.0:
		if input_vector != Vector2.ZERO:
			velocity = velocity.move_toward(input_vector * speed, acceleration * delta)
			_update_facing(input_vector)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	_update_texture(input_vector)
	move_and_slide()
	_animate_procedural(delta, input_vector)

	# Cámara con suave look-ahead hacia la dirección de visión
	var target_cam_offset := facing_vector * camera_look_ahead
	camera.position = camera.position.lerp(target_cam_offset, 1.0 - exp(-4.0 * delta))

	# Parpadeo de invulnerabilidad
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
		if sprite.texture != TEX_ATTACK:
			sprite.texture = TEX_ATTACK
		var need_flip := (facing_vector == Vector2.LEFT)
		if sprite.flip_h != need_flip:
			sprite.flip_h = need_flip
		return

	if is_invulnerable and health <= 0:
		return

	# Seleccionar sprite según dirección estilo Pokémon 3/4
	var target_tex: Texture2D = TEX_IDLE
	if facing_vector == Vector2.UP:
		target_tex = TEX_BACK
	elif facing_vector == Vector2.DOWN:
		target_tex = TEX_IDLE
	elif facing_vector == Vector2.LEFT:
		target_tex = TEX_WALK_LEFT
	elif facing_vector == Vector2.RIGHT:
		target_tex = TEX_WALK_RIGHT

	if sprite.texture != target_tex:
		sprite.texture = target_tex
	if sprite.flip_h:
		sprite.flip_h = false

## Animación procedural de pasos (balanceo y rebote sutil estilo RPG)
func _animate_procedural(delta: float, input_vector: Vector2) -> void:
	if velocity.length_squared() > 100.0:
		_walk_time += delta * 14.0
		# Pequeño rebote vertical al dar pasos
		sprite.position.y = _base_sprite_y - absf(sin(_walk_time)) * 2.5
		# Sutil inclinación lateral
		sprite.rotation = sin(_walk_time) * 0.04

		# Partículas de polvo al caminar
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

## Lanza un disparo en la dirección 2D hacia la que mira el héroe
func spawn_projectile() -> void:
	var shot: Projectile = PROJECTILE_SCENE.instantiate()
	shot.direction = facing_vector
	shot.speed = shot_speed
	shot.scale = Vector2(shot_scale, shot_scale)
	shot.global_position = global_position + facing_vector * 24.0 + Vector2(0, -10.0)
	get_parent().add_child(shot)

func check_attack_hits() -> void:
	if not is_attacking:
		return
	for area in attack_area.get_overlapping_areas():
		_hit_enemy_area(area)

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

	health -= amount
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

	sprite.texture = TEX_HURT
	sprite.flip_h = false
	_flash(Color(3.0, 1.2, 1.2))
	Fx.shake(5.0, 0.25)
	Fx.hitstop(0.06)

	if health <= 0:
		_die(push_dir)
	else:
		is_invulnerable = true
		if invulnerable_timer:
			invulnerable_timer.start(invulnerable_time)

func _die(push_dir: Vector2) -> void:
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
	sprite.modulate = Color.WHITE
	sprite.flip_h = false
	sprite.texture = TEX_BACK
	if attack_sprite:
		attack_sprite.visible = false
	reached_goal.emit()
	for i in 2:
		if not is_inside_tree():
			return
		_squash(Vector2(0.8, 1.25), 0.22)
		await get_tree().create_timer(0.45).timeout

func _squash(amount: Vector2, time: float) -> void:
	if _squash_tween and _squash_tween.is_valid():
		_squash_tween.kill()
	sprite.scale = _base_scale * amount
	_squash_tween = create_tween()
	_squash_tween.tween_property(sprite, "scale", _base_scale, time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _flash(color: Color) -> void:
	sprite.self_modulate = color
	var tw := create_tween()
	tw.tween_property(sprite, "self_modulate", Color.WHITE, 0.22)

func _on_invulnerable_timer_timeout() -> void:
	is_invulnerable = false
	sprite.modulate = Color.WHITE

func _on_attack_area_entered(area: Area2D) -> void:
	_hit_enemy_area(area)
