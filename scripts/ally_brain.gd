extends Node
class_name AllyBrain

## Cerebro de combate y acompañamiento táctico para estudiantes aliados rescatados.
## Máquina de estados estable (FOLLOW, POSITION, HOLD_AND_FIRE, DODGE, UNSTUCK).
## Invariante AGENTS.md: cero distance_to()/sqrt() en física; usa únicamente distance_squared_to().

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")

enum AllyState {
	FOLLOW,
	POSITION,
	HOLD_AND_FIRE,
	DODGE,
	UNSTUCK
}

const FOLLOW_START_DIST_SQ: float = 84.0 * 84.0
const FOLLOW_STOP_DIST_SQ: float = 48.0 * 48.0
const FOLLOW_RECOVER_DIST_SQ: float = 420.0 * 420.0
const PREFERRED_MIN_DIST_SQ: float = 160.0 * 160.0
const PREFERRED_MAX_DIST_SQ: float = 255.0 * 255.0
const ATTACK_RANGE_SQ: float = 540.0 * 540.0
const DODGE_RADIUS_SQ: float = 78.0 * 78.0
const SEPARATION_DIST_SQ: float = 54.0 * 54.0
const ATTACK_POSE_DURATION: float = 0.32

const ALLY_TINTS := {
	"mateo": Color(0.45, 1.0, 0.65),
	"maria": Color(1.0, 0.65, 0.85),
	"valeria": Color(0.45, 0.95, 1.0),
	"fernanda": Color(0.55, 0.85, 1.0),
	"diego": Color(0.50, 0.72, 1.0),
	"sofia": Color(0.88, 0.65, 1.0),
	"alejandro": Color(1.0, 0.75, 0.35),
}

var host: CharacterBody2D = null
var level_ref: Node2D = null
var ally_name: String = ""
var move_speed: float = 155.0
var follow_speed: float = 135.0
var attack_cooldown: float = 1.45
var active_combat: bool = false
var last_target: Node2D = null
var shots_fired: int = 0
var state: AllyState = AllyState.FOLLOW

var _cooldown_timer: float = 0.45
var _attack_anim_timer: float = 0.0
var _hold_timer: float = 0.0
var _dodge_check_timer: float = 0.0
var _dodge_timer: float = 0.0
var _dodge_cooldown: float = 0.0
var _dodge_dir: Vector2 = Vector2.ZERO
var _unstuck_timer: float = 0.0
var _unstuck_dir: Vector2 = Vector2.ZERO
var _stuck_accum: float = 0.0
var _far_stuck_accum: float = 0.0
var _whisker_timer: float = 0.0
var _cached_whisker_dir: Vector2 = Vector2.ZERO
var _has_prev_pos: bool = false
var _prev_pos: Vector2 = Vector2.ZERO
var _last_intent_vel: Vector2 = Vector2.ZERO
var _is_following_move: bool = false
var _orbit_sign: float = 1.0
var _last_facing: Vector2 = Vector2.DOWN

func configure(p_host: CharacterBody2D, p_level: Node2D, p_name: String) -> void:
	host = p_host
	level_ref = p_level
	ally_name = p_name
	_orbit_sign = 1.0 if (absi(p_name.hash()) % 2 == 0) else -1.0
	var gs := _get_game_settings()
	if gs != null and int(gs.get("difficulty")) == 2:
		attack_cooldown = 1.75
	else:
		attack_cooldown = 1.45
	if host != null and is_instance_valid(host):
		_prev_pos = host.global_position
		_has_prev_pos = true

func _get_game_settings() -> Node:
	if host != null and host.is_inside_tree() and host.get_tree() and host.get_tree().root:
		return host.get_tree().root.get_node_or_null("GameSettings")
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("GameSettings")
	return null

func tick(delta: float) -> Dictionary:
	var result := {
		"velocity": Vector2.ZERO,
		"facing": _last_facing,
		"attacking": false,
		"fired": false,
		"state": state,
	}
	if host == null or not is_instance_valid(host):
		return result

	_cooldown_timer = maxf(0.0, _cooldown_timer - delta)
	_attack_anim_timer = maxf(0.0, _attack_anim_timer - delta)
	_dodge_cooldown = maxf(0.0, _dodge_cooldown - delta)

	# 1. Detección de atascamiento físico vs frame previo
	if not _has_prev_pos:
		_prev_pos = host.global_position
		_has_prev_pos = true

	var moved_sq := host.global_position.distance_squared_to(_prev_pos)
	var was_trying_move := _last_intent_vel.length_squared() > 900.0 and host.velocity.length_squared() > 900.0
	var touching_wall := host.is_inside_tree() and host.is_on_wall()
	if state != AllyState.UNSTUCK and state != AllyState.HOLD_AND_FIRE and was_trying_move and (touching_wall or moved_sq < 1.0):
		_stuck_accum += delta
		if _stuck_accum >= 0.25:
			_enter_unstuck_state()
	else:
		_stuck_accum = maxf(0.0, _stuck_accum - delta * 2.0)
	_prev_pos = host.global_position

	# 2. Objetivo prioritario
	var target := _find_best_target()
	last_target = target
	active_combat = (target != null)
	if state == AllyState.FOLLOW and target != null:
		state = AllyState.POSITION

	# 3. Revisión de esquive de proyectiles que realmente vienen hacia el aliado
	if state != AllyState.UNSTUCK and state != AllyState.DODGE and _dodge_cooldown <= 0.0:
		_dodge_check_timer -= delta
		if _dodge_check_timer <= 0.0:
			_dodge_check_timer = 0.06
			var dodge_cand := _compute_incoming_projectile_dodge()
			if dodge_cand != Vector2.ZERO:
				state = AllyState.DODGE
				_dodge_dir = dodge_cand
				_dodge_timer = 0.32

	var desired_vel := Vector2.ZERO

	# 4. Ejecución de FSM estable
	match state:
		AllyState.UNSTUCK:
			_unstuck_timer -= delta
			desired_vel = _unstuck_dir * (move_speed * 0.95)
			if _unstuck_dir != Vector2.ZERO:
				_last_facing = _unstuck_dir
			if _unstuck_timer <= 0.0:
				state = AllyState.POSITION if target != null else AllyState.FOLLOW

		AllyState.DODGE:
			_dodge_timer -= delta
			desired_vel = _dodge_dir * (move_speed * 1.25)
			if target != null:
				var dt := target.global_position - host.global_position
				if dt.length_squared() > 1.0:
					_last_facing = dt.normalized()
			elif _dodge_dir != Vector2.ZERO:
				_last_facing = _dodge_dir
			if _dodge_timer <= 0.0:
				_dodge_cooldown = 0.45
				state = AllyState.POSITION if target != null else AllyState.FOLLOW

		AllyState.HOLD_AND_FIRE:
			if target == null:
				state = AllyState.FOLLOW
			else:
				_hold_timer -= delta
				var to_t := target.global_position - host.global_position
				var dist_sq := to_t.length_squared()
				var dir_t := to_t.normalized() if dist_sq > 0.001 else Vector2.RIGHT
				_last_facing = dir_t
				# Quieto o micro-ajuste mínimo si el objetivo se pega demasiado
				if dist_sq < PREFERRED_MIN_DIST_SQ * 0.50:
					desired_vel = -dir_t * 25.0
				else:
					desired_vel = Vector2.ZERO

				if _cooldown_timer <= 0.0 and dist_sq <= ATTACK_RANGE_SQ and _has_clear_los(target.global_position):
					if _fire_virtue_projectile(dir_t):
						_cooldown_timer = attack_cooldown
						_attack_anim_timer = ATTACK_POSE_DURATION
						result["fired"] = true
						_hold_timer = 0.34

				if _hold_timer <= 0.0 and _attack_anim_timer <= 0.0:
					state = AllyState.POSITION

		AllyState.POSITION:
			if target == null:
				state = AllyState.FOLLOW
			else:
				var to_t := target.global_position - host.global_position
				var dist_sq := to_t.length_squared()
				var dir_t := to_t.normalized() if dist_sq > 0.001 else Vector2.RIGHT
				_last_facing = dir_t

				var form_idx := _get_formation_index()
				var slot_angle := float(form_idx) * (TAU / 4.0) + _orbit_sign * 0.45
				var anchor := target.global_position + Vector2(cos(slot_angle), sin(slot_angle)) * 205.0
				var to_anchor := anchor - host.global_position

				var radial := Vector2.ZERO
				if dist_sq < PREFERRED_MIN_DIST_SQ:
					radial = -dir_t * 0.90
				elif dist_sq > PREFERRED_MAX_DIST_SQ:
					radial = dir_t * 0.90
				elif to_anchor.length_squared() > 1600.0:
					radial = to_anchor.normalized() * 0.55

				var tangent := Vector2(-dir_t.y, dir_t.x) * _orbit_sign * 0.32
				var comb := radial + tangent
				if comb.length_squared() > 0.01:
					desired_vel = comb.normalized() * move_speed

				if _cooldown_timer <= 0.0 and dist_sq <= ATTACK_RANGE_SQ and _has_clear_los(target.global_position):
					if _fire_virtue_projectile(dir_t):
						_cooldown_timer = attack_cooldown
						_attack_anim_timer = ATTACK_POSE_DURATION
						result["fired"] = true
						desired_vel = Vector2.ZERO
						state = AllyState.HOLD_AND_FIRE
						_hold_timer = 0.34

		AllyState.FOLLOW:
			if target != null:
				state = AllyState.POSITION
			else:
				var player_node := _get_player()
				if player_node != null:
					var form_idx := _get_formation_index()
					var angle_offset := float(form_idx) * (TAU / 6.0) + PI * 0.75
					var anchor := player_node.global_position + Vector2(cos(angle_offset), sin(angle_offset)) * 76.0
					var to_anchor := anchor - host.global_position
					var d_sq := to_anchor.length_squared()

					if _is_following_move:
						if d_sq <= FOLLOW_STOP_DIST_SQ:
							_is_following_move = false
					else:
						if d_sq >= FOLLOW_START_DIST_SQ:
							_is_following_move = true

					if _is_following_move and d_sq > 4.0:
						desired_vel = to_anchor.normalized() * follow_speed
						_last_facing = desired_vel.normalized()

					# Recuperación si queda rezagado o atrapado detrás de paredes lejos del jugador
					var p_dist_sq := host.global_position.distance_squared_to(player_node.global_position)
					if p_dist_sq > FOLLOW_RECOVER_DIST_SQ and moved_sq < 4.0:
						_far_stuck_accum += delta
						if _far_stuck_accum >= 1.5:
							_recover_near_player(player_node)
							_far_stuck_accum = 0.0
					else:
						_far_stuck_accum = 0.0

	# 5. Separación suave entre aliados + bigotes evasores de obstáculos + límites del mapa
	if state != AllyState.HOLD_AND_FIRE and desired_vel.length_squared() > 100.0:
		desired_vel = _apply_obstacle_whiskers(desired_vel, delta)
	if state != AllyState.HOLD_AND_FIRE:
		desired_vel += _compute_ally_separation() * 75.0
	desired_vel = _steer_inside_map(desired_vel)

	var max_spd := move_speed * 1.25 if state == AllyState.DODGE else move_speed
	if desired_vel.length_squared() > max_spd * max_spd:
		desired_vel = desired_vel.normalized() * max_spd

	_last_intent_vel = desired_vel
	result["velocity"] = desired_vel
	result["facing"] = _last_facing
	result["attacking"] = (_attack_anim_timer > 0.0)
	result["state"] = state
	return result

func _get_formation_index() -> int:
	if level_ref != null and is_instance_valid(level_ref):
		var students_arr = level_ref.get("students")
		if students_arr is Array:
			var idx := (students_arr as Array).find(host)
			if idx >= 0:
				return idx
	return absi(ally_name.hash()) % 6

func _enter_unstuck_state() -> void:
	_stuck_accum = 0.0
	_orbit_sign = -_orbit_sign
	state = AllyState.UNSTUCK
	_unstuck_timer = 0.45
	var base_dir := _last_intent_vel.normalized() if _last_intent_vel.length_squared() > 1.0 else _last_facing
	if base_dir.length_squared() < 0.01:
		base_dir = Vector2.RIGHT
	_unstuck_dir = _pick_free_angle(base_dir)

func _pick_free_angle(base_dir: Vector2) -> Vector2:
	var candidates := [
		PI * 0.25, -PI * 0.25,
		PI * 0.50, -PI * 0.50,
		PI * 0.75, -PI * 0.75,
		PI
	]
	if not host.is_inside_tree() or host.get_world_2d() == null:
		return base_dir.rotated(PI * 0.5 * _orbit_sign).normalized()
	var space_state := host.get_world_2d().direct_space_state
	if space_state == null:
		return base_dir.rotated(PI * 0.5 * _orbit_sign).normalized()

	var origin := host.global_position + Vector2(0.0, -14.0)
	var best_dir := base_dir.rotated(PI * 0.5 * _orbit_sign).normalized()
	var best_dist_sq := -1.0
	for ang_off: float in candidates:
		var cand := base_dir.rotated(ang_off * _orbit_sign).normalized()
		var q := PhysicsRayQueryParameters2D.create(origin, origin + cand * 56.0, 1, [host.get_rid()])
		var hit := space_state.intersect_ray(q)
		if hit.is_empty():
			return cand
		var hit_pt: Vector2 = hit.get("position", origin)
		var d_sq := origin.distance_squared_to(hit_pt)
		if d_sq > best_dist_sq:
			best_dist_sq = d_sq
			best_dir = cand
	return best_dir

func _apply_obstacle_whiskers(vel: Vector2, delta: float) -> Vector2:
	_whisker_timer -= delta
	if _whisker_timer > 0.0:
		if _cached_whisker_dir != Vector2.ZERO:
			return _cached_whisker_dir * vel.length()
		return vel
	_whisker_timer = 0.10
	_cached_whisker_dir = Vector2.ZERO

	if not host.is_inside_tree() or host.get_world_2d() == null:
		return vel
	var space_state := host.get_world_2d().direct_space_state
	if space_state == null:
		return vel

	var spd_sq := vel.length_squared()
	if spd_sq < 1.0:
		return vel
	var dir := vel.normalized()
	var origin := host.global_position + Vector2(0.0, -14.0)
	var q_center := PhysicsRayQueryParameters2D.create(origin, origin + dir * 42.0, 1, [host.get_rid()])
	if space_state.intersect_ray(q_center).is_empty():
		return vel

	var left_dir := dir.rotated(-0.65).normalized()
	var right_dir := dir.rotated(0.65).normalized()
	var hit_l := space_state.intersect_ray(PhysicsRayQueryParameters2D.create(origin, origin + left_dir * 46.0, 1, [host.get_rid()]))
	var hit_r := space_state.intersect_ray(PhysicsRayQueryParameters2D.create(origin, origin + right_dir * 46.0, 1, [host.get_rid()]))

	if hit_l.is_empty() and not hit_r.is_empty():
		_cached_whisker_dir = left_dir
	elif hit_r.is_empty() and not hit_l.is_empty():
		_cached_whisker_dir = right_dir
	elif hit_l.is_empty() and hit_r.is_empty():
		_cached_whisker_dir = right_dir if _orbit_sign >= 0.0 else left_dir
	else:
		var dl := origin.distance_squared_to(hit_l.get("position", origin))
		var dr := origin.distance_squared_to(hit_r.get("position", origin))
		_cached_whisker_dir = left_dir if dl >= dr else right_dir

	return _cached_whisker_dir * vel.length()

func _recover_near_player(player_node: Node2D) -> void:
	var form_idx := _get_formation_index()
	var ang := float(form_idx) * (TAU / 6.0)
	var candidate := player_node.global_position + Vector2(cos(ang), sin(ang)) * 64.0
	if level_ref != null and is_instance_valid(level_ref):
		var map_sz_var = level_ref.get("map_size")
		if map_sz_var is Vector2:
			var map_sz: Vector2 = map_sz_var
			candidate.x = clampf(candidate.x, 56.0, map_sz.x - 56.0)
			candidate.y = clampf(candidate.y, 76.0, map_sz.y - 56.0)
	host.global_position = candidate
	_prev_pos = candidate

func _get_player() -> Node2D:
	var p = host.get("player")
	if p != null and is_instance_valid(p) and p is Node2D:
		return p as Node2D
	if level_ref != null and is_instance_valid(level_ref):
		var lp = level_ref.get("player")
		if lp != null and is_instance_valid(lp) and lp is Node2D:
			return lp as Node2D
	return null

func _find_best_target() -> Node2D:
	if level_ref == null or not is_instance_valid(level_ref):
		return null

	var boss_node = level_ref.get("boss")
	if boss_node != null and is_instance_valid(boss_node) and boss_node is Node2D:
		var state_val: int = int(boss_node.get("current_state"))
		var hp_val: int = int(boss_node.get("current_hp"))
		var vanished: bool = bool(boss_node.get("_is_covered_and_vanished"))
		if state_val != 0 and state_val != 6 and hp_val > 0 and not vanished:
			return boss_node as Node2D

	var enemies_cont = level_ref.get("enemies_container")
	if enemies_cont != null and is_instance_valid(enemies_cont):
		var best_enemy: Node2D = null
		var best_dist_sq := INF
		for e in enemies_cont.get_children():
			if not e.has_method("hit_by_attack") or e.get("is_active") != true:
				continue
			var d_sq := host.global_position.distance_squared_to((e as Node2D).global_position)
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_enemy = e as Node2D
		return best_enemy

	return null

func _compute_incoming_projectile_dodge() -> Vector2:
	if not host.is_inside_tree() or host.get_tree() == null:
		return Vector2.ZERO
	var projs := host.get_tree().get_nodes_in_group("enemy_projectiles")
	var best_proj: Node2D = null
	var best_p_dir: Vector2 = Vector2.RIGHT
	var best_d_sq := DODGE_RADIUS_SQ
	for p in projs:
		if p is Node2D and is_instance_valid(p):
			var to_host := host.global_position - (p as Node2D).global_position
			var d_sq := to_host.length_squared()
			if d_sq >= best_d_sq or d_sq < 0.01:
				continue
			var p_dir_var = p.get("direction")
			var p_dir: Vector2 = p_dir_var if p_dir_var is Vector2 else Vector2.ZERO
			if p_dir.length_squared() < 0.01:
				continue
			p_dir = p_dir.normalized()
			# Solo esquivar proyectiles que realmente vienen hacia el aliado (dot / |to_host| > 0.25 sin sqrt)
			var dot_val := p_dir.dot(to_host)
			if dot_val <= 0.0 or (dot_val * dot_val) <= 0.0625 * d_sq:
				continue
			best_d_sq = d_sq
			best_proj = p as Node2D
			best_p_dir = p_dir
	if best_proj == null:
		return Vector2.ZERO

	var perp := Vector2(-best_p_dir.y, best_p_dir.x)
	var rel := host.global_position - best_proj.global_position
	if perp.dot(rel) < 0.0:
		perp = -perp
	# Verificar si ese lado tiene muro y preferir el lado libre
	if host.is_inside_tree() and host.get_world_2d() and host.get_world_2d().direct_space_state:
		var sp := host.get_world_2d().direct_space_state
		var orig := host.global_position + Vector2(0.0, -14.0)
		if not sp.intersect_ray(PhysicsRayQueryParameters2D.create(orig, orig + perp * 44.0, 1, [host.get_rid()])).is_empty():
			if sp.intersect_ray(PhysicsRayQueryParameters2D.create(orig, orig - perp * 44.0, 1, [host.get_rid()])).is_empty():
				perp = -perp
	return perp.normalized()

func _compute_ally_separation() -> Vector2:
	if level_ref == null or not is_instance_valid(level_ref):
		return Vector2.ZERO
	var students_arr = level_ref.get("students")
	if not (students_arr is Array):
		return Vector2.ZERO
	var sep := Vector2.ZERO
	for s in students_arr:
		if s == host or not is_instance_valid(s) or not (s is Node2D):
			continue
		var diff := host.global_position - (s as Node2D).global_position
		var d_sq := diff.length_squared()
		if d_sq > 0.01 and d_sq < SEPARATION_DIST_SQ:
			sep += diff.normalized() * (1.0 - (d_sq / SEPARATION_DIST_SQ))
	return sep

func _steer_inside_map(vel: Vector2) -> Vector2:
	if level_ref == null or not is_instance_valid(level_ref):
		return vel
	var map_sz_var = level_ref.get("map_size")
	if not (map_sz_var is Vector2):
		return vel
	var map_sz: Vector2 = map_sz_var
	var margin := 54.0
	var out := vel
	if host.position.x < margin and out.x < 0.0:
		out.x = absf(out.x) + 55.0
	elif host.position.x > map_sz.x - margin and out.x > 0.0:
		out.x = -absf(out.x) - 55.0
	if host.position.y < margin + 18.0 and out.y < 0.0:
		out.y = absf(out.y) + 55.0
	elif host.position.y > map_sz.y - margin and out.y > 0.0:
		out.y = -absf(out.y) - 55.0
	return out

func _has_clear_los(target_pos: Vector2) -> bool:
	if not host.is_inside_tree() or host.get_world_2d() == null:
		return true
	var space_state := host.get_world_2d().direct_space_state
	if space_state == null:
		return true
	var from_pt := host.global_position + Vector2(0.0, -14.0)
	var to_pt := target_pos + Vector2(0.0, -14.0)
	var query := PhysicsRayQueryParameters2D.create(from_pt, to_pt, 1, [host.get_rid()])
	var hit := space_state.intersect_ray(query)
	return hit.is_empty()

func _fire_virtue_projectile(dir: Vector2) -> bool:
	if PROJECTILE_SCENE == null:
		return false
	var shoot_dir := dir.normalized() if dir.length_squared() > 0.001 else Vector2.RIGHT
	var origin := host.global_position + Vector2(0.0, -14.0)
	var spawn_offset := 10.0

	# Verificar espacio libre delante del aliado antes de instanciar el proyectil
	if host.is_inside_tree() and host.get_world_2d() and host.get_world_2d().direct_space_state:
		var sp := host.get_world_2d().direct_space_state
		var q := PhysicsRayQueryParameters2D.create(origin, origin + shoot_dir * 18.0, 1, [host.get_rid()])
		var hit := sp.intersect_ray(q)
		if not hit.is_empty():
			var hit_d_sq := origin.distance_squared_to(hit.get("position", origin))
			if hit_d_sq < 196.0: # < 14 px: ajustar spawn al centro para no rozar la pared
				spawn_offset = 0.0

	var proj = PROJECTILE_SCENE.instantiate()
	if proj == null:
		return false

	var parent_node: Node = null
	if level_ref != null and is_instance_valid(level_ref):
		parent_node = level_ref.get("entities")
		if parent_node == null:
			parent_node = level_ref
	if parent_node == null:
		parent_node = host.get_parent()
	if parent_node == null:
		proj.free()
		return false

	var world_spawn := origin + shoot_dir * spawn_offset
	var local_spawn: Vector2 = (parent_node as Node2D).to_local(world_spawn) if parent_node is Node2D else world_spawn

	# Configurar posición y dirección ANTES de add_child() para evitar colisión falsa en (0, 0)
	proj.set("is_ally_projectile", true)
	proj.set("speed", 460.0)
	proj.set("lifetime", 1.45)
	proj.z_index = 25
	proj.scale = Vector2(1.1, 1.1)
	proj.modulate = _get_virtue_tint()
	proj.position = local_spawn
	if proj.has_method("set_direction"):
		proj.set_direction(shoot_dir)

	parent_node.add_child(proj)
	shots_fired += 1
	return true

func _get_virtue_tint() -> Color:
	var low := ally_name.to_lower()
	for k: String in ALLY_TINTS.keys():
		if low.begins_with(k):
			return ALLY_TINTS[k]
	return Color(0.55, 0.92, 1.0)
