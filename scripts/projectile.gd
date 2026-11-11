extends Area2D
class_name Projectile

## Proyectil de valores disparado en perspectiva 3/4 (Jugador o Jefes).
## Neutraliza antivalores, alegra a estudiantes tristes o daña al jugador si es proyectil hostil.

@export var speed: float = 520.0
@export var lifetime: float = 1.1
@export var is_enemy_projectile: bool = false

var direction: Variant = Vector2.RIGHT
var _dir_vec: Vector2 = Vector2.RIGHT
var _time: float = 0.0
var _done: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	if is_enemy_projectile or is_in_group("enemy_projectiles"):
		is_enemy_projectile = true
		collision_layer = 8 # Capa 4: Enemigo
		collision_mask = 3  # Capa 1 (Obstaculos) + Capa 2 (Jugador)
		remove_from_group("player_attack")
		if not is_in_group("enemy_projectiles"):
			add_to_group("enemy_projectiles")
	else:
		collision_layer = 4 # Capa 3: Proyectil
		collision_mask = 9  # Capa 1 (Obstaculos) + Capa 4 (Enemigos)
		if not is_in_group("player_attack"):
			add_to_group("player_attack")

	if direction is Vector2:
		_dir_vec = direction.normalized()
		if _dir_vec == Vector2.ZERO:
			_dir_vec = Vector2.RIGHT
	elif direction is int or direction is float:
		_dir_vec = Vector2.RIGHT if float(direction) >= 0.0 else Vector2.LEFT

	# Orientar el ángulo del nodo hacia la trayectoria de disparo
	rotation = _dir_vec.angle()
	sprite.flip_h = false

	# Animación pop de aparición
	var target_scale := sprite.scale
	sprite.scale = target_scale * 0.4
	create_tween().tween_property(sprite, "scale", target_scale, 0.08)

func _physics_process(delta: float) -> void:
	position += _dir_vec * speed * delta
	sprite.rotation += 12.0 * delta
	_time += delta

	# Desvanecimiento en el último cuarto de vida útil
	if _time > lifetime * 0.75:
		modulate.a = clampf(1.0 - (_time - lifetime * 0.75) / (lifetime * 0.25), 0.0, 1.0)
	if _time >= lifetime:
		queue_free()

func _spawn_impact_fx(col: Color = Color(1.0, 0.92, 0.5), count: int = 8, vel: float = 120.0) -> void:
	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx and get_parent():
		fx.burst(get_parent(), global_position, col, count, vel)

func _on_body_entered(body: Node2D) -> void:
	if _done:
		return

	if is_enemy_projectile:
		if body is Player or body.has_method("take_damage"):
			_done = true
			_spawn_impact_fx(Color(1.0, 0.35, 0.45), 10, 140.0)
			if body.has_method("take_damage"):
				body.take_damage(1, global_position)
			queue_free()
			return
		if body is StaticBody2D or body.is_in_group("obstacles") or (body.collision_layer & 1) != 0:
			_done = true
			_spawn_impact_fx(Color(0.85, 0.88, 0.95), 6, 90.0)
			queue_free()
			return
		return

	# Proyectil virtuoso del jugador:
	# 1. Alumnos secundarios: si está triste, lo alegra de inmediato con esperanza
	if body is Student or body.has_method("cheer_up"):
		var s_state = body.get("current_state")
		if s_state == 0: # Student.State.SAD
			_done = true
			body.cheer_up()
			_spawn_impact_fx(Color(1.0, 0.92, 0.45), 12, 110.0)
			queue_free()
			return
		else:
			# Traspasa pacíficamente al alumno ya alegre
			return

	# 2. Antivalor o Jefe
	if body.is_in_group("enemies") or body is Enemy or body.has_method("hit_by_attack"):
		_done = true
		_spawn_impact_fx()
		body.hit_by_attack(global_position)
		queue_free()
		return

	# 3. Obstáculos sólidos o paredes del escenario
	if body is StaticBody2D or body.is_in_group("obstacles") or (body.collision_layer & 1) != 0:
		_done = true
		_spawn_impact_fx(Color(0.85, 0.88, 0.95), 6, 90.0)
		queue_free()
		return

func _on_area_entered(area: Area2D) -> void:
	if _done:
		return
	if is_enemy_projectile:
		return

	if area.is_in_group("enemies"):
		var enemy = area.get_parent()
		if enemy and enemy.has_method("hit_by_attack"):
			_done = true
			_spawn_impact_fx()
			enemy.hit_by_attack(global_position)
			queue_free()
