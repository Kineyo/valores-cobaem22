extends Node2D
class_name FogOverlay

## Niebla del Desinterés (CEMSaD 22 ENTHAVI).
## Representa la indiferencia y ceguera institucional ante el acoso escolar.
## Envuelve el escenario en bruma atmosférica realista con vapor volumétrico en movimiento
## donde solo la verdad y la virtud del alumno irradian luz.
## Los antivalores (enemigos) quedan completamente ocultos en la niebla fuera del radio de luz.
## En la oscuridad, el Maestro Desinterés se delata mediante ojos rojos ardientes y corazón oscuro palpitante.

const FOG_SHADER := preload("res://shaders/fog_of_war.gdshader")

@export var is_fog_active: bool = false
@export var light_radius: float = 145.0

var light_sources: Array = []
var map_size: Vector2 = Vector2(800, 480)
var boss_node: Node2D = null
var enemies_container: Node2D = null

var _fog_alpha: float = 0.0
var _anim_time: float = 0.0

var _color_rect: ColorRect
var _shader_mat: ShaderMaterial

func _ready() -> void:
	z_index = 65
	visible = false

	# Capa visual de shader con vapor atmosférico y corte dinámico de luz
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = FOG_SHADER

	_color_rect = ColorRect.new()
	_color_rect.material = _shader_mat
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_color_rect)
	_update_rect_geometry()

func set_fog(active: bool, instant: bool = false) -> void:
	is_fog_active = active
	if instant:
		_fog_alpha = 1.0 if active else 0.0
		visible = active
		if _shader_mat:
			_shader_mat.set_shader_parameter("fog_alpha", _fog_alpha)
		_update_enemies_visibility()
		queue_redraw()

func _update_rect_geometry() -> void:
	if not _color_rect:
		return
	var margin := 300.0
	_color_rect.position = Vector2(-margin, -margin)
	_color_rect.size = map_size + Vector2(margin * 2.0, margin * 2.0)
	if _shader_mat:
		_shader_mat.set_shader_parameter("rect_pos", _color_rect.position)
		_shader_mat.set_shader_parameter("rect_size", _color_rect.size)

func _process(delta: float) -> void:
	_anim_time += delta
	var target_alpha: float = 1.0 if is_fog_active else 0.0
	_fog_alpha = move_toward(_fog_alpha, target_alpha, delta * (2.2 if is_fog_active else 1.6))

	if _fog_alpha > 0.001:
		visible = true
		_update_shader_uniforms()
		_update_enemies_visibility()
		if boss_node != null and is_instance_valid(boss_node):
			queue_redraw()
	else:
		visible = false
		_restore_all_enemies_visibility()

func _update_shader_uniforms() -> void:
	if not _shader_mat:
		return

	_shader_mat.set_shader_parameter("fog_alpha", _fog_alpha)
	_shader_mat.set_shader_parameter("time", _anim_time)
	_shader_mat.set_shader_parameter("light_radius_1", light_radius)

	# Asignar posiciones globales de las fuentes de luz
	var active_positions: Array[Vector2] = []
	for node in light_sources:
		if node != null and is_instance_valid(node):
			active_positions.append(node.global_position)

	if active_positions.size() > 0:
		_shader_mat.set_shader_parameter("light_pos_1", active_positions[0])
	else:
		_shader_mat.set_shader_parameter("light_pos_1", Vector2(-2000, -2000))

	if active_positions.size() > 1:
		_shader_mat.set_shader_parameter("light_pos_2", active_positions[1])
		_shader_mat.set_shader_parameter("light_radius_2", 90.0)
	else:
		_shader_mat.set_shader_parameter("light_pos_2", Vector2(-2000, -2000))

	if active_positions.size() > 2:
		_shader_mat.set_shader_parameter("light_pos_3", active_positions[2])
		_shader_mat.set_shader_parameter("light_radius_3", 90.0)
	else:
		_shader_mat.set_shader_parameter("light_pos_3", Vector2(-2000, -2000))

## Oculta a los antivalores que se encuentran inmersos en la niebla profunda
func _update_enemies_visibility() -> void:
	var container: Node2D = enemies_container
	if container == null and get_parent() != null:
		container = get_parent().get_node_or_null("Entities/Enemies")
	if container == null or not is_instance_valid(container):
		return

	var active_lights: Array[Dictionary] = []
	for i in range(light_sources.size()):
		var node = light_sources[i]
		if node != null and is_instance_valid(node):
			var r: float = light_radius if i == 0 else 80.0
			active_lights.append({ "pos": (node as Node2D).global_position, "radius": r })

	if active_lights.is_empty():
		return

	for child in container.get_children():
		if not (child is Node2D):
			continue

		if not is_fog_active or _fog_alpha <= 0.01:
			child.modulate.a = move_toward(child.modulate.a, 1.0, 0.1)
			continue

		var best_vis: float = 0.0
		var e_pos: Vector2 = (child as Node2D).global_position
		for l_data in active_lights:
			var l_pos: Vector2 = l_data["pos"]
			var l_rad: float = l_data["radius"]
			var d: float = e_pos.distance_to(l_pos)
			var inner: float = l_rad - 22.0
			var outer: float = l_rad + 18.0
			var v: float = 0.0
			if d <= inner:
				v = 1.0
			elif d < outer:
				v = 1.0 - ((d - inner) / (outer - inner))
			if v > best_vis:
				best_vis = v

		var target_a := lerpf(1.0, best_vis, _fog_alpha)
		child.modulate.a = target_a

## Restaura la opacidad al 100% de todos los enemigos cuando la niebla se disipa
func _restore_all_enemies_visibility() -> void:
	var container: Node2D = enemies_container
	if container == null and get_parent() != null:
		container = get_parent().get_node_or_null("Entities/Enemies")
	if container == null or not is_instance_valid(container):
		return
	for child in container.get_children():
		if child is Node2D:
			child.modulate.a = 1.0

func _draw() -> void:
	if _fog_alpha <= 0.05:
		return

	# -------------------------------------------------------------------------
	# SIMBOLOGÍA VISIBLE EN LA NIEBLA: OJOS ROJOS Y CORAZÓN OSCURO DEL MAESTRO
	# -------------------------------------------------------------------------
	if boss_node != null and is_instance_valid(boss_node):
		var b_pos := to_local(boss_node.global_position)
		var pulse := 1.0 + sin(_anim_time * 6.0) * 0.18

		# Ojos rojos ardientes atravesando la bruma
		var eye_glow := Color(1.0, 0.15, 0.20, _fog_alpha)
		draw_circle(b_pos + Vector2(-6, -58), 3.5 * pulse, eye_glow)
		draw_circle(b_pos + Vector2(6, -58), 3.5 * pulse, eye_glow)
		draw_circle(b_pos + Vector2(-6, -58), 1.8, Color(1.0, 0.9, 0.9, _fog_alpha))
		draw_circle(b_pos + Vector2(6, -58), 1.8, Color(1.0, 0.9, 0.9, _fog_alpha))

		# Corazón negro con resplandor carmesí pulsante
		var heart_y := -40.0
		var r_h := 7.0 * pulse
		draw_circle(b_pos + Vector2(-4, heart_y), r_h, Color(0.9, 0.12, 0.25, 0.85 * _fog_alpha))
		draw_circle(b_pos + Vector2(4, heart_y), r_h, Color(0.9, 0.12, 0.25, 0.85 * _fog_alpha))
		draw_polygon(PackedVector2Array([
			b_pos + Vector2(-10, heart_y),
			b_pos + Vector2(10, heart_y),
			b_pos + Vector2(0, heart_y + 12.0 * pulse)
		]), [Color(0.9, 0.12, 0.25, 0.85 * _fog_alpha)])

		# Núcleo negro de indiferencia
		draw_circle(b_pos + Vector2(-4, heart_y), r_h * 0.7, Color(0.06, 0.04, 0.08, 0.95 * _fog_alpha))
		draw_circle(b_pos + Vector2(4, heart_y), r_h * 0.7, Color(0.06, 0.04, 0.08, 0.95 * _fog_alpha))
		draw_polygon(PackedVector2Array([
			b_pos + Vector2(-7, heart_y),
			b_pos + Vector2(7, heart_y),
			b_pos + Vector2(0, heart_y + 9.0 * pulse)
		]), [Color(0.06, 0.04, 0.08, 0.95 * _fog_alpha)])
