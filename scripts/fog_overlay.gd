extends Node2D
class_name FogOverlay

## Niebla del Desinterés (CEMSaD 22 ENTHAVI).
## Representa la indiferencia y ceguera institucional ante el bullying y el acoso escolar.
## Envuelve el aula en densa oscuridad donde solo la verdad y la virtud del alumno irradian luz.
## En la oscuridad, el Maestro Desinterés se delata mediante ojos rojos ardientes y un corazón oscuro palpitante.

@export var is_fog_active: bool = false
@export var light_radius: float = 130.0

var light_sources: Array = []
var map_size: Vector2 = Vector2(800, 480)
var boss_node: Node2D = null

var _fog_alpha: float = 0.0
var _anim_time: float = 0.0

func _ready() -> void:
	z_index = 65
	visible = false

func set_fog(active: bool, instant: bool = false) -> void:
	is_fog_active = active
	if instant:
		_fog_alpha = 0.94 if active else 0.0
		visible = active
		queue_redraw()

func _process(delta: float) -> void:
	_anim_time += delta
	var target_alpha: float = 0.94 if is_fog_active else 0.0
	_fog_alpha = move_toward(_fog_alpha, target_alpha, delta * 1.2)

	if _fog_alpha > 0.01:
		visible = true
		queue_redraw()
	else:
		visible = false

func _draw() -> void:
	if _fog_alpha <= 0.01:
		return

	var fog_col := Color(0.04, 0.05, 0.08, _fog_alpha)
	var bounds := Rect2(-100, -100, map_size.x + 200, map_size.y + 200)

	# Filtrar fuentes de luz vivas
	var active_lights: Array[Vector2] = []
	for node in light_sources:
		if node != null and is_instance_valid(node):
			active_lights.append(to_local(node.global_position))

	if active_lights.is_empty():
		draw_rect(bounds, fog_col)
	else:
		# Dibujar polígono de niebla con orificios circulares para cada fuente de luz
		# Para cada fuente de luz, construimos una malla de 16 sectores
		var p_pos: Vector2 = active_lights[0] # Centro principal (héroe)

		# 1. Dibujar los 4 cuadrantes exteriores hacia los bordes del mapa
		var top_rect := Rect2(bounds.position.x, bounds.position.y, bounds.size.x, maxf(0.0, (p_pos.y - light_radius) - bounds.position.y))
		var bot_rect := Rect2(bounds.position.x, p_pos.y + light_radius, bounds.size.x, maxf(0.0, (bounds.position.y + bounds.size.y) - (p_pos.y + light_radius)))
		var left_rect := Rect2(bounds.position.x, p_pos.y - light_radius, maxf(0.0, (p_pos.x - light_radius) - bounds.position.x), light_radius * 2.0)
		var right_rect := Rect2(p_pos.x + light_radius, p_pos.y - light_radius, maxf(0.0, (bounds.position.x + bounds.size.x) - (p_pos.x + light_radius)), light_radius * 2.0)

		if top_rect.size.y > 0: draw_rect(top_rect, fog_col)
		if bot_rect.size.y > 0: draw_rect(bot_rect, fog_col)
		if left_rect.size.x > 0: draw_rect(left_rect, fog_col)
		if right_rect.size.x > 0: draw_rect(right_rect, fog_col)

		# 2. Rellenar las 4 esquinas del círculo con triángulos hacia los vértices del cuadrado circunscrito
		var n_segments := 20
		var circle_pts: PackedVector2Array = []
		for i in range(n_segments):
			var ang := float(i) * (TAU / float(n_segments))
			circle_pts.append(p_pos + Vector2(cos(ang), sin(ang)) * light_radius)

		# Esquina Norponiente
		draw_polygon(PackedVector2Array([
			Vector2(p_pos.x - light_radius, p_pos.y - light_radius),
			circle_pts[10], circle_pts[11], circle_pts[12], circle_pts[13], circle_pts[14], circle_pts[15]
		]), [fog_col])

		# Esquina Nororiente
		draw_polygon(PackedVector2Array([
			Vector2(p_pos.x + light_radius, p_pos.y - light_radius),
			circle_pts[15], circle_pts[16], circle_pts[17], circle_pts[18], circle_pts[19], circle_pts[0]
		]), [fog_col])

		# Esquina Suroriente
		draw_polygon(PackedVector2Array([
			Vector2(p_pos.x + light_radius, p_pos.y + light_radius),
			circle_pts[0], circle_pts[1], circle_pts[2], circle_pts[3], circle_pts[4], circle_pts[5]
		]), [fog_col])

		# Esquina Surponiente
		draw_polygon(PackedVector2Array([
			Vector2(p_pos.x - light_radius, p_pos.y + light_radius),
			circle_pts[5], circle_pts[6], circle_pts[7], circle_pts[8], circle_pts[9], circle_pts[10]
		]), [fog_col])

		# 3. Anillos de degradado suave de luz (difuminado cálido)
		for r_step in 5:
			var r := light_radius - float(r_step) * 6.0
			var step_alpha := _fog_alpha * (float(5 - r_step) / 6.0) * 0.4
			draw_arc(p_pos, r, 0, TAU, 24, Color(0.04, 0.05, 0.08, step_alpha), 6.0)

		# 4. Si hay una segunda fuente de luz (el estudiante secundario protegido)
		if active_lights.size() > 1:
			var s_pos: Vector2 = active_lights[1]
			# Aura de luz tenue sobre el alumno
			draw_circle(s_pos, 75.0, Color(1.0, 0.95, 0.75, 0.12 * (1.0 - _fog_alpha * 0.4)))
			draw_arc(s_pos, 75.0, 0, TAU, 20, Color(1.0, 0.9, 0.5, 0.25), 2.0)

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
		# Halo carmesí
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
