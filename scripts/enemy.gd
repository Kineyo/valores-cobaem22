extends CharacterBody2D
class_name Enemy

## Antivalores escolares en perspectiva 3/4:
## - Grosería: Rápido e impulsivo, brinca agitado. Se redime proclamando ¡Amabilidad!
## - Acoso: Sombra acechante con amplio rango de visión. Se redime proclamando ¡Respeto!
## - Bullying: Pesado y territorial, embiste al entrar a su zona. Se redime proclamando ¡Empatía!

enum Type { GROSERIA, ACOSO, BULLYING }

const TYPE_DATA := {
	Type.GROSERIA: {
		"texture": preload("res://assets/sprites/enemigo_groseria.png"),
		"speed": 125.0, "name": "Grosería",
		"color": Color(1.0, 0.35, 0.35), "value": "¡Amabilidad!",
		"detection_range": 280.0,
	},
	Type.ACOSO: {
		"texture": preload("res://assets/sprites/enemigo_acoso.png"),
		"speed": 110.0, "name": "Acoso",
		"color": Color(1.0, 0.65, 0.25), "value": "¡Respeto!",
		"detection_range": 320.0,
	},
	Type.BULLYING: {
		"texture": preload("res://assets/sprites/enemigo_bullying.png"),
		"speed": 95.0, "name": "Bullying",
		"color": Color(0.85, 0.45, 0.95), "value": "¡Empatía!",
		"detection_range": 240.0,
	},
}

signal defeated(enemy: Enemy)

@export var enemy_type: Type = Type.GROSERIA
@export var speed: float = 110.0
@export var wander_radius: float = 140.0
@export var detection_range: float = 280.0
@export var respawn_delay: float = 3.2
@export var max_respawns: int = 2 ## Límite de reapariciones por nivel antes de descansar

var player: CharacterBody2D = null
var is_active: bool = true
var is_alerted: bool = false
var spawn_position: Vector2 = Vector2.ZERO
var current_respawns: int = 0
var allow_respawn: bool = true

var _anim_time: float = 0.0
var _value_text: String = ""
var _color: Color = Color.WHITE
var _spawn_tween: Tween
var _target_wander: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _respawn_timer: float = 0.0
var _detection_range_sq: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var label: Label = $Label
@onready var sfx_hit: AudioStreamPlayer = $SFXHit
@onready var _base_sprite_y: float = sprite.position.y

func _ready() -> void:
	y_sort_enabled = true
	collision_layer = 8
	collision_mask = 1
	if has_node("Hitbox"):
		$Hitbox.collision_layer = 8
		$Hitbox.collision_mask = 6
	spawn_position = global_position
	_target_wander = global_position
	hitbox.body_entered.connect(_on_body_entered)
	setup_type()
	var gs = get_node_or_null("/root/GameSettings") if is_inside_tree() else null
	if gs and gs.has_method("get_param"):
		speed *= gs.get_param("enemy_speed_mult")
	_anim_time = randf() * TAU
	_wander_timer = randf_range(0.5, 2.0)
	queue_redraw()

func _draw() -> void:
	# Sombra elíptica pixel-art para anclar al enemigo al suelo en perspectiva 3/4
	var shadow_col := Color(0.06, 0.08, 0.12, 0.32)
	draw_rect(Rect2(-12, -4, 24, 6), shadow_col)
	draw_rect(Rect2(-10, -6, 20, 10), shadow_col)

## Desactiva el movimiento y colisiones del enemigo
func stop() -> void:
	is_active = false
	_respawn_timer = 0.0
	velocity = Vector2.ZERO

## Configura textura, velocidad, color y virtud proclamada según el tipo
func setup_type() -> void:
	var data: Dictionary = TYPE_DATA[enemy_type]
	sprite.texture = data["texture"]
	speed = data["speed"]
	detection_range = data["detection_range"]
	_detection_range_sq = detection_range * detection_range
	label.text = data["name"]
	label.modulate = data["color"]
	_color = data["color"]
	_value_text = data["value"]

func _physics_process(delta: float) -> void:
	if not is_active:
		if allow_respawn and current_respawns < max_respawns and _respawn_timer > 0.0:
			_respawn_timer -= delta
			if _respawn_timer <= 0.0:
				respawn()
		return

	_animate(delta)
	_update_ai(delta)
	move_and_slide()

## Alerta a otros enemigos aliados cercanos para coordinar el ataque
func alert_allies(range_px: float = 340.0) -> void:
	is_alerted = true
	if not is_inside_tree():
		return
	var r_sq := range_px * range_px
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != self and e is Enemy and is_instance_valid(e) and e.is_inside_tree() and e.is_active:
			if global_position.distance_squared_to(e.global_position) <= r_sq:
				e.is_alerted = true

## Inteligencia artificial: persigue si el héroe está en rango; si no, patrulla
func _update_ai(delta: float) -> void:
	var move_dir := Vector2.ZERO

	# Persecución directa si el jugador entra al radio de detección o hay alerta de grupo
	if player and is_instance_valid(player) and player.can_control:
		var dist_sq := global_position.distance_squared_to(player.global_position)
		var should_chase := is_alerted or (dist_sq <= _detection_range_sq)

		if should_chase:
			if not is_alerted and dist_sq <= _detection_range_sq:
				alert_allies(340.0)

			# Desactivar alerta si el héroe escapó muy lejos (más del doble del rango)
			if dist_sq > _detection_range_sq * 2.25:
				is_alerted = false
			else:
				move_dir = (player.global_position - global_position).normalized()
				# Evasión inteligente de paredes y esquinas (context-steering antienquistes)
				if is_on_wall():
					var wall_n := get_wall_normal()
					var tangent := Vector2(-wall_n.y, wall_n.x)
					if tangent.dot(move_dir) < 0.0:
						tangent = -tangent
					move_dir = (move_dir * 0.3 + tangent * 0.85).normalized()

				velocity = velocity.move_toward(move_dir * speed, 600.0 * delta)
				if move_dir.x != 0.0:
					sprite.flip_h = move_dir.x < 0.0
				return

	# Patrullaje errante alrededor de la posición de spawn
	_wander_timer -= delta
	if is_on_wall():
		_wander_timer = 0.0 # Redirigir de inmediato si toca muro durante patrullaje

	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.5, 3.5)
		var offset := Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
		_target_wander = spawn_position + offset

	if global_position.distance_squared_to(_target_wander) > 400.0:
		move_dir = (_target_wander - global_position).normalized()
		if is_on_wall():
			var wall_n := get_wall_normal()
			var tangent := Vector2(-wall_n.y, wall_n.x)
			if tangent.dot(move_dir) < 0.0:
				tangent = -tangent
			move_dir = (move_dir * 0.3 + tangent * 0.85).normalized()

		velocity = velocity.move_toward(move_dir * (speed * 0.65), 400.0 * delta)
		if move_dir.x != 0.0:
			sprite.flip_h = move_dir.x < 0.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)

func _animate(delta: float) -> void:
	_anim_time += delta * 1.2
	match enemy_type:
		Type.GROSERIA:
			var hop := absf(sin(_anim_time * 6.5))
			sprite.position.y = _base_sprite_y - hop * 5.0
			sprite.scale = Vector2(1.0 + (1.0 - hop) * 0.1, 1.0 - (1.0 - hop) * 0.1)
		Type.ACOSO:
			sprite.position.y = _base_sprite_y - 4.0 + sin(_anim_time * 3.0) * 4.0
			sprite.self_modulate.a = 0.8 + sin(_anim_time * 4.5) * 0.2
		Type.BULLYING:
			var step := sin(_anim_time * 3.8)
			sprite.rotation = step * 0.05
			sprite.scale = Vector2(1.0 + absf(step) * 0.06, 1.0 - absf(step) * 0.06)
	label.position.y = -44.0 + sin(_anim_time * 2.5) * 1.5

## Invocado al ser impactado por un ataque o proyectil de valores
func hit_by_attack(attacker_pos: Variant = null) -> void:
	if not is_active:
		return
	alert_allies(400.0)
	if sfx_hit:
		sfx_hit.pitch_scale = randf_range(0.9, 1.1)
		sfx_hit.play()

	var fx_parent := get_parent()
	var hit_pos := global_position + Vector2(0, -16)
	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx:
		fx.burst(fx_parent, hit_pos, _color, 16, 160.0)
		fx.burst(fx_parent, hit_pos, Color.WHITE, 6, 110.0)
		fx.floating_text(fx_parent, hit_pos + Vector2(0, -20), _value_text, Color(1.0, 0.95, 0.55), 15)
		fx.shake(2.5, 0.12)
	defeated.emit(self)

	# Se oculta temporalmente y arranca el temporizador de reaparición
	is_active = false
	visible = false
	velocity = Vector2.ZERO
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	$CollisionShape2D.set_deferred("disabled", true)
	_respawn_timer = respawn_delay

## Reaparece en el punto de spawn con animación pop
func respawn() -> void:
	if not allow_respawn or current_respawns >= max_respawns:
		return
	current_respawns += 1
	global_position = spawn_position
	if has_method("reset_physics_interpolation"):
		call("reset_physics_interpolation")
	is_active = true
	visible = true
	hitbox.set_deferred("monitoring", true)
	hitbox.set_deferred("monitorable", true)
	$CollisionShape2D.set_deferred("disabled", false)
	modulate = Color.WHITE

	if _spawn_tween and _spawn_tween.is_valid():
		_spawn_tween.kill()
	scale = Vector2(0.2, 0.2)
	_spawn_tween = create_tween()
	_spawn_tween.tween_property(self, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Cesa cualquier reaparición futura de este enemigo
func stop_respawns() -> void:
	allow_respawn = false

func _on_body_entered(body: Node2D) -> void:
	if body is Player and is_active:
		body.take_damage(1, global_position)
