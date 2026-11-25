extends Area2D
class_name Projectile

## Proyectil de valores disparado en perspectiva 3/4 (Jugador o Jefes).
## Neutraliza antivalores, alegra a estudiantes tristes o daña al jugador si es proyectil hostil.

@export var speed: float = 520.0
@export var lifetime: float = 1.1
@export var is_enemy_projectile: bool = false
@export var is_ally_projectile: bool = false
@export var curve_speed: float = 0.0 ## Velocidad angular de curvatura estilo Danmaku Touhou
@export var is_homing: bool = false ## Proyectil químico / guiado
@export var homing_strength: float = 3.2
@export var homing_target: Node2D = null
@export var bounces_left: int = 0 ## Proyectil rebotante (exámenes, balones)

var direction: Variant = Vector2.RIGHT
var _dir_vec: Vector2 = Vector2.RIGHT
var _time: float = 0.0
var _done: bool = false
var _has_grazed: bool = false
var _grazing_body: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D

func set_direction(new_dir: Vector2) -> void:
	if new_dir.length_squared() > 0.0001:
		_dir_vec = new_dir.normalized()
		direction = _dir_vec
		rotation = _dir_vec.angle()
	else:
		direction = Vector2.RIGHT
		_dir_vec = Vector2.RIGHT
		rotation = 0.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	if is_enemy_projectile or is_in_group("enemy_projectiles"):
		is_enemy_projectile = true
		if lifetime <= 1.2:
			lifetime = 3.4 # Cobertura de pantalla completa para patrones Danmaku
		collision_layer = 8 # Capa 4: Enemigo
		collision_mask = 3  # Capa 1 (Obstaculos) + Capa 2 (Jugador)
		remove_from_group("player_attack")
		if not is_in_group("enemy_projectiles"):
			add_to_group("enemy_projectiles")
	elif is_ally_projectile:
		collision_layer = 4 # Capa 3: Proyectil
		collision_mask = 9  # Capa 1 (Obstaculos) + Capa 4 (Enemigos)
		remove_from_group("player_attack")
		if not is_in_group("ally_attack"):
			add_to_group("ally_attack")
	else:
		collision_layer = 4 # Capa 3: Proyectil
		collision_mask = 41 # Capa 1 (Obstaculos) + Capa 4 (Enemigos) + Capa 6 (Aliados/Estudiantes)
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
	if is_homing and homing_target != null and is_instance_valid(homing_target):
		var target_pos: Vector2 = homing_target.global_position
		if homing_target.has_method("get_core_position"):
			target_pos = homing_target.get_core_position()
		var to_target := target_pos - global_position
		if to_target.length_squared() > 0.01:
			var desired_dir := to_target.normalized()
			var max_turn := clampf(homing_strength * delta, 0.0, PI)
			var delta_ang := clampf(_dir_vec.angle_to(desired_dir), -max_turn, max_turn)
			_dir_vec = _dir_vec.rotated(delta_ang).normalized()
			rotation = _dir_vec.angle()
	elif curve_speed != 0.0:
		_dir_vec = _dir_vec.rotated(curve_speed * delta)
		rotation = _dir_vec.angle()

	var prev_pos: Vector2 = global_position
	position += _dir_vec * speed * delta
	if sprite:
		sprite.rotation += 12.0 * delta
	_time += delta

	# Comprobar de forma continua (anti-tunneling) si el proyectil penetra la micro-hitbox vital del jugador
	if _grazing_body != null and is_instance_valid(_grazing_body):
		var core_pos: Vector2 = _grazing_body.get_core_position() if _grazing_body.has_method("get_core_position") else (_grazing_body.global_position + Vector2(0, -10.0))
		var core_r_sq: float = _grazing_body.get_core_radius_sq() if _grazing_body.has_method("get_core_radius_sq") else 30.25
		var closest_pt: Vector2 = Geometry2D.get_closest_point_to_segment(core_pos, prev_pos, global_position)
		if core_pos.distance_squared_to(closest_pt) <= core_r_sq: # Micro-hitbox Touhou
			_done = true
			_spawn_impact_fx(Color(1.0, 0.35, 0.45), 10, 140.0)
			if _grazing_body.has_method("take_damage"):
				_grazing_body.take_damage(1, global_position)
			queue_free()
			return
		elif global_position.distance_squared_to(core_pos) > 784.0: # > 28 px: se alejó fuera del cuerpo
			_grazing_body = null

	# Desvanecimiento en el último cuarto de vida útil
	if _time > lifetime * 0.75:
		modulate.a = clampf(1.0 - (_time - lifetime * 0.75) / (lifetime * 0.25), 0.0, 1.0)
	if _time >= lifetime:
		queue_free()

func _spawn_impact_fx(col: Color = Color(1.0, 0.92, 0.5), count: int = 8, vel: float = 120.0) -> void:
	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx and get_parent():
		fx.burst(get_parent(), global_position, col, count, vel)

func _spawn_graze_fx() -> void:
	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx and get_parent():
		fx.burst(get_parent(), global_position, Color(0.4, 0.9, 1.0, 0.8), 4, 60.0)

func _on_body_entered(body: Node2D) -> void:
	if _done:
		return

	if is_enemy_projectile:
		if body.is_in_group("students"):
			return
		if body.is_in_group("player") or body.has_method("take_damage"):
			var core_pos: Vector2 = body.get_core_position() if body.has_method("get_core_position") else (body.global_position + Vector2(0, -10.0))
			var core_r_sq: float = body.get_core_radius_sq() if body.has_method("get_core_radius_sq") else 30.25
			var dist_sq: float = global_position.distance_squared_to(core_pos)
			if dist_sq <= core_r_sq: # Impacto directo a la micro-hitbox vital
				_done = true
				_spawn_impact_fx(Color(1.0, 0.35, 0.45), 10, 140.0)
				if body.has_method("take_damage"):
					body.take_damage(1, global_position)
				queue_free()
				return
			else:
				# Rozadura (Graze): bala roza el cuerpo pero no toca el núcleo vital
				if not _has_grazed:
					_has_grazed = true
					_grazing_body = body
					if body.has_method("on_graze"):
						body.on_graze(global_position)
				return
		if body is StaticBody2D or body.is_in_group("obstacles") or (body.collision_layer & 1) != 0:
			if bounces_left > 0:
				bounces_left -= 1
				var bounced := -_dir_vec
				if is_inside_tree() and get_world_2d():
					var space_state := get_world_2d().direct_space_state
					if space_state:
						var q := PhysicsRayQueryParameters2D.create(global_position - _dir_vec * 12.0, global_position + _dir_vec * 18.0, 1)
						var hit := space_state.intersect_ray(q)
						if hit and hit.normal != Vector2.ZERO:
							bounced = _dir_vec.bounce(hit.normal).normalized()
				_dir_vec = bounced
				rotation = _dir_vec.angle()
				position += _dir_vec * 4.0
				_spawn_impact_fx(Color(1.0, 0.9, 0.5), 4, 70.0)
				return
			_done = true
			_spawn_impact_fx(Color(0.85, 0.88, 0.95), 6, 90.0)
			queue_free()
			return
		return

	# Proyectil virtuoso del jugador:
	# 1. Alumnos secundarios: si está triste, lo alegra de inmediato con esperanza
	if not is_ally_projectile and (body.is_in_group("students") or body.has_method("cheer_up")):
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
	if body.is_in_group("enemies") or body.has_method("hit_by_attack"):
		_done = true
		_spawn_impact_fx()
		body.hit_by_attack(global_position)
		queue_free()
		return

	# 3. Obstáculos sólidos o paredes del escenario
	if body is StaticBody2D or body.is_in_group("obstacles") or (body.collision_layer & 1) != 0:
		if _time < 0.05 and is_inside_tree() and get_world_2d() and get_world_2d().direct_space_state:
			var forward_q := PhysicsRayQueryParameters2D.create(global_position, global_position + _dir_vec * 10.0, 1)
			if get_world_2d().direct_space_state.intersect_ray(forward_q).is_empty():
				return
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
		if area.has_method("hit_by_attack"):
			_done = true
			_spawn_impact_fx()
			area.hit_by_attack(global_position)
			queue_free()
			return
		var enemy = area.get_parent()
		if enemy and enemy.has_method("hit_by_attack"):
			_done = true
			_spawn_impact_fx()
			enemy.hit_by_attack(global_position)
			queue_free()
