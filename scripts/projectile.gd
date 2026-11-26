extends Area2D
class_name Projectile

## Proyectil de valores disparado en perspectiva 3/4.
## Neutraliza antivalores, alegra a compañeros tristes o daña al héroe si es hostil.

@export var speed: float = 520.0
@export var lifetime: float = 1.1
@export var is_enemy_projectile: bool = false
@export var is_ally_projectile: bool = false
@export var curve_speed: float = 0.0
@export var is_homing: bool = false
@export var homing_strength: float = 3.2
@export var homing_target: Node2D = null
@export var bounces_left: int = 0
@export var pierce_left: int = 0
@export var wave_amp: float = 0.0
@export var wave_freq: float = 0.0
@export var boost_on_bounce: float = 1.0
@export var mark_target: bool = false
@export var custom_texture: Texture2D = null
@export var custom_visual_size: float = 24.0
@export var visual_style: StringName = &""
@export var apply_slow_on_hit: float = 0.0
@export var clear_enemy_bullets_radius: float = 0.0
@export var spin_speed: float = 12.0

const STANDARD_VISUAL_SIZE: float = 24.0
const FALLBACK_CORE_OFFSET := Vector2(0.0, -10.0)
const FALLBACK_CORE_RADIUS_SQ := 30.25

static var _tex_used_extent_cache: Dictionary = {}

var direction: Variant = Vector2.RIGHT
var _dir_vec: Vector2 = Vector2.RIGHT
var _time: float = 0.0
var _clear_scan_timer: float = 0.05
var _done: bool = false
var _has_grazed: bool = false
var _grazing_body: Node2D = null
var _custom_draw_active: bool = false
var _draw_pop_scale: float = 1.0
var _base_modulate_alpha: float = 1.0
var shared_hit_registry: Dictionary = {}
var _fx: Node = null

@onready var sprite: Sprite2D = $Sprite2D

func _get_fx() -> Node:
	if _fx == null or not is_instance_valid(_fx):
		_fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	return _fx

func _exit_tree() -> void:
	shared_hit_registry = {}
	_grazing_body = null

func _get_texture_visible_extent(tex: Texture2D) -> float:
	if tex == null:
		return STANDARD_VISUAL_SIZE
	var key := tex.resource_path if not tex.resource_path.is_empty() else str(tex.get_rid())
	if _tex_used_extent_cache.has(key):
		return float(_tex_used_extent_cache[key])
	var extent := float(maxi(1, maxi(tex.get_width(), tex.get_height())))
	var img := tex.get_image()
	if img != null:
		var used := img.get_used_rect()
		if used.size.x > 0 and used.size.y > 0:
			extent = float(maxi(used.size.x, used.size.y))
	_tex_used_extent_cache[key] = extent
	return extent

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
	_fx = _get_fx()
	area_entered.connect(_on_area_entered, CONNECT_DEFERRED)
	body_entered.connect(_on_body_entered, CONNECT_DEFERRED)

	if is_enemy_projectile or is_in_group("enemy_projectiles"):
		is_enemy_projectile = true
		z_index = 28
		if lifetime <= 1.2:
			lifetime = 3.4
		collision_layer = 8
		collision_mask = 3
		remove_from_group("player_attack")
		if not is_in_group("enemy_projectiles"):
			add_to_group("enemy_projectiles")
	elif is_ally_projectile:
		z_index = 22
		collision_layer = 4
		collision_mask = 9
		remove_from_group("player_attack")
		if not is_in_group("ally_attack"):
			add_to_group("ally_attack")
		var trail := get_node_or_null("Trail") as CPUParticles2D
		if trail:
			trail.amount = 4 if MobileControls.is_touch_device() else 6
			trail.color = Color(modulate.r, modulate.g, modulate.b, 0.72)
	else:
		z_index = 25
		collision_layer = 4
		collision_mask = 41
		if not is_in_group("player_attack"):
			add_to_group("player_attack")

	_base_modulate_alpha = modulate.a

	if direction is Vector2:
		_dir_vec = direction.normalized()
		if _dir_vec == Vector2.ZERO:
			_dir_vec = Vector2.RIGHT
	elif direction is int or direction is float:
		_dir_vec = Vector2.RIGHT if float(direction) >= 0.0 else Vector2.LEFT

	rotation = _dir_vec.angle()
	if sprite:
		sprite.flip_h = false

	if custom_texture != null and sprite != null:
		sprite.visible = true
		sprite.texture = custom_texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var vis_extent := _get_texture_visible_extent(custom_texture)
		sprite.scale = Vector2.ONE * (custom_visual_size / vis_extent)
	elif visual_style != &"" and not is_enemy_projectile:
		_custom_draw_active = true
		if sprite:
			sprite.visible = false
		queue_redraw()

	if sprite and sprite.visible:
		var target_scale := sprite.scale
		sprite.scale = target_scale * 0.45
		create_tween().tween_property(sprite, "scale", target_scale, 0.08)
	elif _custom_draw_active:
		_draw_pop_scale = 0.65
		create_tween().tween_method(func(v: float) -> void:
			_draw_pop_scale = v
			queue_redraw()
		, 0.65, 1.0, 0.07)

func _draw() -> void:
	if not _custom_draw_active:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_draw_pop_scale, _draw_pop_scale))
	match visual_style:
		&"pulso_guinda":
			var guinda := Color(0.62, 0.12, 0.28)
			var gold := Color(1.0, 0.90, 0.42)
			draw_colored_polygon(PackedVector2Array([
				Vector2(12, 0), Vector2(4, -4), Vector2(0, -12), Vector2(-4, -4),
				Vector2(-12, 0), Vector2(-4, 4), Vector2(0, 12), Vector2(4, 4)
			]), gold)
			draw_circle(Vector2.ZERO, 5.2, guinda)
			draw_circle(Vector2(2.2, 0), 2.2, Color.WHITE)
		&"destello_guinda":
			var cian := Color(0.32, 0.92, 1.0)
			var gold := Color(1.0, 0.86, 0.34)
			draw_colored_polygon(PackedVector2Array([
				Vector2(12, 0), Vector2(-1, -10), Vector2(-8, 0), Vector2(-1, 10)
			]), gold)
			draw_colored_polygon(PackedVector2Array([
				Vector2(7, 0), Vector2(-4, -6.5), Vector2(-12, 0), Vector2(-4, 6.5)
			]), cian)
			draw_circle(Vector2(3, 0), 2.5, Color.WHITE)
		&"triple_reaccion":
			var mint := Color(0.35, 0.96, 0.60)
			draw_circle(Vector2(5.0, 0.0), 7.0, mint)
			draw_circle(Vector2(-5.5, -5.5), 5.8, Color(0.75, 1.0, 0.55))
			draw_circle(Vector2(-5.5, 5.5), 5.8, Color(0.55, 0.95, 1.0))
			draw_circle(Vector2(6.5, -2.2), 2.2, Color.WHITE)
		&"escudo_firme":
			var rose := Color(1.0, 0.56, 0.78)
			draw_arc(Vector2(-1, 0), 10.2, -1.18, 1.18, 14, rose, 3.6)
			draw_arc(Vector2(1, 0), 7.2, -1.0, 1.0, 12, Color.WHITE, 2.2)
			draw_circle(Vector2(-6, 0), 3.0, Color(1.0, 0.80, 0.90))
		&"pulso_estereo":
			var cian := Color(0.28, 0.94, 1.0)
			draw_arc(Vector2(-2, 0), 10.5, -1.05, 1.05, 14, cian, 3.0)
			draw_arc(Vector2(3, 0), 7.5, -1.0, 1.0, 12, Color(1.0, 0.86, 0.36), 2.4)
			draw_circle(Vector2(-8.5, 0), 3.2, Color(1.0, 0.50, 0.76))
		&"nota_margen":
			var sky := Color(0.42, 0.76, 1.0)
			var amber := Color(1.0, 0.86, 0.32)
			draw_rect(Rect2(Vector2(-10, -11), Vector2(20, 22)), sky)
			draw_rect(Rect2(Vector2(2, -11), Vector2(8, 8)), amber)
			draw_line(Vector2(-6, -2), Vector2(6, -2), Color(1, 1, 1, 0.85), 1.6)
			draw_line(Vector2(-6, 3), Vector2(4, 3), Color(1, 1, 1, 0.85), 1.6)
			draw_rect(Rect2(Vector2(-10, -11), Vector2(20, 22)), Color.WHITE, false, 1.6)
		&"turno_abierto", _:
			var violet := Color(0.82, 0.54, 1.0)
			var gold := Color(1.0, 0.90, 0.36)
			draw_colored_polygon(PackedVector2Array([
				Vector2(12, 0), Vector2(0, -10), Vector2(-12, 0), Vector2(0, 10)
			]), violet)
			draw_colored_polygon(PackedVector2Array([
				Vector2(6.5, 0), Vector2(0, -5.5), Vector2(-6.5, 0), Vector2(0, 5.5)
			]), gold)
			draw_circle(Vector2.ZERO, 2.0, Color.WHITE)

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
	var step_delta := _dir_vec * speed * delta
	if wave_amp != 0.0 and wave_freq != 0.0:
		var perp := Vector2(-_dir_vec.y, _dir_vec.x)
		step_delta += perp * (cos(_time * wave_freq) * wave_amp * delta)
	position += step_delta

	if sprite and sprite.visible:
		sprite.rotation += spin_speed * delta
	_time += delta

	if not is_enemy_projectile and clear_enemy_bullets_radius > 0.0 and is_inside_tree() and get_tree():
		_clear_scan_timer += delta
		if _clear_scan_timer >= 0.05:
			_clear_scan_timer = 0.0
			var clr_r_sq := clear_enemy_bullets_radius * clear_enemy_bullets_radius
			for ep in get_tree().get_nodes_in_group("enemy_projectiles"):
				if ep != self and ep is Node2D and is_instance_valid(ep):
					if global_position.distance_squared_to((ep as Node2D).global_position) <= clr_r_sq:
						ep.queue_free()

	if _grazing_body != null and is_instance_valid(_grazing_body):
		var core_pos: Vector2 = _grazing_body.get_core_position() if _grazing_body.has_method("get_core_position") else (_grazing_body.global_position + FALLBACK_CORE_OFFSET)
		var core_r_sq: float = _grazing_body.get_core_radius_sq() if _grazing_body.has_method("get_core_radius_sq") else FALLBACK_CORE_RADIUS_SQ
		var closest_pt: Vector2 = Geometry2D.get_closest_point_to_segment(core_pos, prev_pos, global_position)
		if core_pos.distance_squared_to(closest_pt) <= core_r_sq:
			_done = true
			_spawn_impact_fx(Color(1.0, 0.35, 0.45), 10, 140.0)
			if _grazing_body.has_method("take_damage"):
				_grazing_body.take_damage(1, global_position)
			queue_free()
			return
		elif global_position.distance_squared_to(core_pos) > 784.0:
			_grazing_body = null

	if _time > lifetime * 0.75:
		var fade := clampf(1.0 - (_time - lifetime * 0.75) / (lifetime * 0.25), 0.0, 1.0)
		modulate.a = _base_modulate_alpha * fade
	if _time >= lifetime:
		queue_free()

func _bounce_off_wall() -> bool:
	if bounces_left <= 0:
		return false
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
	if boost_on_bounce > 1.0:
		speed *= boost_on_bounce
	position += _dir_vec * 4.0
	_spawn_impact_fx(Color(1.0, 0.9, 0.5), 4, 70.0)
	return true

func _apply_hit_effects(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		return
	target.hit_by_attack(global_position)
	if apply_slow_on_hit > 0.0 and target.has_method("apply_empathy_slow"):
		target.apply_empathy_slow(apply_slow_on_hit)
	if mark_target and target.has_method("apply_empathy_slow"):
		target.apply_empathy_slow(0.8)

func _handle_virtue_hit_target(target: Node) -> void:
	var tid := target.get_instance_id()
	if shared_hit_registry.has(tid):
		return
	shared_hit_registry[tid] = true
	_spawn_impact_fx()
	_apply_hit_effects(target)
	if pierce_left > 0:
		pierce_left -= 1
		return
	_done = true
	queue_free()

func _spawn_impact_fx(col: Color = Color(1.0, 0.92, 0.5), count: int = 8, vel: float = 120.0) -> void:
	var fx := _get_fx()
	if fx and get_parent():
		fx.burst(get_parent(), global_position, col, count, vel)

func _spawn_graze_fx() -> void:
	var fx := _get_fx()
	if fx and get_parent():
		fx.burst(get_parent(), global_position, Color(0.4, 0.9, 1.0, 0.8), 4, 60.0)

func _on_body_entered(body: Node2D) -> void:
	if _done or not is_instance_valid(body):
		return

	if is_enemy_projectile:
		if body.is_in_group("students"):
			return
		if body.is_in_group("player") or body.has_method("take_damage"):
			var core_pos: Vector2 = body.get_core_position() if body.has_method("get_core_position") else (body.global_position + FALLBACK_CORE_OFFSET)
			var core_r_sq: float = body.get_core_radius_sq() if body.has_method("get_core_radius_sq") else FALLBACK_CORE_RADIUS_SQ
			var dist_sq: float = global_position.distance_squared_to(core_pos)
			if dist_sq <= core_r_sq:
				_done = true
				_spawn_impact_fx(Color(1.0, 0.35, 0.45), 10, 140.0)
				if body.has_method("take_damage"):
					body.take_damage(1, global_position)
				queue_free()
				return
			else:
				_grazing_body = body
				if not _has_grazed and not bool(body.get("is_invulnerable")):
					_has_grazed = true
					if body.has_method("on_graze"):
						body.on_graze(global_position)
				return
		if body is StaticBody2D or body.is_in_group("obstacles") or (body.collision_layer & 1) != 0:
			if _bounce_off_wall():
				return
			_done = true
			_spawn_impact_fx(Color(0.85, 0.88, 0.95), 6, 90.0)
			queue_free()
			return
		return

	if not is_ally_projectile and body.is_in_group("students"):
		if body.has_method("is_sad") and body.is_sad():
			_done = true
			body.cheer_up()
			_spawn_impact_fx(Color(1.0, 0.92, 0.45), 12, 110.0)
			queue_free()
			return
		else:
			return

	if body.is_in_group("enemies") or body.has_method("hit_by_attack"):
		_handle_virtue_hit_target(body)
		return

	if body is StaticBody2D or body.is_in_group("obstacles") or (body.collision_layer & 1) != 0:
		if _time < 0.05 and is_inside_tree() and get_world_2d() and get_world_2d().direct_space_state:
			var forward_q := PhysicsRayQueryParameters2D.create(global_position, global_position + _dir_vec * 10.0, 1)
			if get_world_2d().direct_space_state.intersect_ray(forward_q).is_empty():
				return
		if _bounce_off_wall():
			return
		_done = true
		_spawn_impact_fx(Color(0.85, 0.88, 0.95), 6, 90.0)
		queue_free()
		return

func _on_area_entered(area: Area2D) -> void:
	if _done or is_enemy_projectile or not is_instance_valid(area):
		return
	if area.is_in_group("enemies"):
		if area.has_method("hit_by_attack"):
			_handle_virtue_hit_target(area)
			return
		var target_parent = area.get_parent()
		if target_parent and target_parent.has_method("hit_by_attack"):
			_handle_virtue_hit_target(target_parent)
