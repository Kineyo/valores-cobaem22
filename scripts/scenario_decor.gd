extends Node2D
class_name ScenarioDecor

## Capa de vida ambiental sutil en perspectiva 3/4 para escenarios exteriores y salones.
## Renderiza sobre el fondo y debajo de Entities y FogOverlay sin obstruir la jugabilidad
## ni utilizar shaders incompatibles con gl_compatibility.

@export var scenario_id: int = 1
@export var is_classroom: bool = false
@export var classroom_index: int = 0
@export var map_size: Vector2 = Vector2(1440, 880)
@export var ambient_light_color: Color = Color(1.0, 0.96, 0.82)

var _time: float = 0.0
var _particles: Array[Dictionary] = []
var _accents: Array[Dictionary] = []
var _sun_zones: Array[Dictionary] = []

func _ready() -> void:
	# Se posiciona justo después de Background en z_index = 0 para dibujar encima del fondo
	# y siempre debajo de Entities (z_index = 0 posterior) y FogOverlay (z_index = 65).
	z_index = 0
	_align_above_background()
	if _particles.is_empty():
		_rebuild_decor()

func _align_above_background() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var bg := parent_node.get_node_or_null("Background")
	if bg != null and get_index() != bg.get_index() + 1:
		parent_node.move_child.call_deferred(self, bg.get_index() + 1)

## Configura la ambientación de partículas y destellos a partir del diccionario del nivel.
func setup_decor(data: Dictionary, p_map_size: Vector2 = Vector2.ZERO) -> void:
	scenario_id = int(data.get("id", scenario_id))
	is_classroom = bool(data.get("is_classroom", false))
	classroom_index = int(data.get("classroom_index", 0))
	if p_map_size != Vector2.ZERO:
		map_size = p_map_size
	else:
		var raw_size: Variant = data.get("map_size", map_size)
		if raw_size is Vector2 and raw_size != Vector2.ZERO:
			map_size = raw_size

	ambient_light_color = _resolve_ambient_color()
	_rebuild_decor()
	if is_inside_tree():
		_align_above_background()
	queue_redraw()

func _resolve_ambient_color() -> Color:
	if is_classroom:
		match classroom_index:
			0: return Color(0.92, 0.98, 1.0)
			1: return Color(1.0, 0.96, 0.84)
			2: return Color(1.0, 0.94, 0.78)
			3: return Color(1.0, 0.90, 0.70)
			4: return Color(0.78, 0.93, 1.0)
			_: return Color(1.0, 0.95, 0.80)
	match scenario_id:
		1: return Color(1.0, 0.96, 0.82)
		2: return Color(1.0, 0.97, 0.86)
		3: return Color(0.92, 0.96, 1.0)
		4: return Color(0.98, 0.98, 0.84)
		5: return Color(1.0, 0.94, 0.78)
		_: return Color(1.0, 0.95, 0.76)

func _rebuild_decor() -> void:
	_particles.clear()
	_accents.clear()
	_sun_zones.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(scenario_id * 131 + classroom_index * 17 + (1000 if is_classroom else 0))

	if is_classroom:
		_build_classroom_decor(rng)
	else:
		_build_exterior_decor(rng)

func _build_exterior_decor(rng: RandomNumberGenerator) -> void:
	# Hojas y pétalos ligeros flotando con la brisa de Temoaya (12 partículas suaves)
	var leaf_palette: Array[Color] = [
		Color(0.55, 0.88, 0.45, 0.55),
		Color(0.98, 0.94, 0.65, 0.50),
		Color(0.95, 0.72, 0.82, 0.52),
		Color(0.98, 0.98, 0.98, 0.45),
	]
	var count := 12
	for i in range(count):
		_particles.append({
			"pos": Vector2(rng.randf_range(20.0, maxf(100.0, map_size.x - 20.0)), rng.randf_range(20.0, maxf(100.0, map_size.y - 20.0))),
			"vel": Vector2(rng.randf_range(12.0, 24.0), rng.randf_range(5.0, 13.0)),
			"size": rng.randf_range(2.0, 3.4),
			"phase": rng.randf_range(0.0, TAU),
			"freq": rng.randf_range(1.2, 2.4),
			"sway": rng.randf_range(6.0, 14.0),
			"color": leaf_palette[i % leaf_palette.size()],
			"is_leaf": true,
		})

	# Zonas de destello solar y pulsos dorados sobre puntos emblemáticos de cada escenario
	match scenario_id:
		1:
			# Osito topiario, captador de agua y luminarias
			_accents.append({ "pos": Vector2(416, 260), "radius": 28.0, "color": Color(1.0, 0.88, 0.42), "speed": 1.6 })
			_accents.append({ "pos": Vector2(1260, 620), "radius": 44.0, "color": Color(0.55, 0.88, 1.0), "speed": 1.8 })
			_sun_zones.append({ "rect": Rect2(140, 480, 140, 240), "angle": 0.18 })
		2:
			# Jardinera norte y patio de cafetería
			for jx in [280.0, 640.0, 1020.0, 1340.0]:
				_accents.append({ "pos": Vector2(jx, 160.0), "radius": 24.0, "color": Color(0.98, 0.90, 0.46), "speed": 1.5 })
			_sun_zones.append({ "rect": Rect2(460, 220, 220, 140), "angle": 0.20 })
		3:
			# Destellos del Arcotecho y Punto de Reunión en Plaza Cívica
			_accents.append({ "pos": Vector2(860, 500), "radius": 46.0, "color": Color(0.45, 0.95, 0.62), "speed": 1.7 })
			for ax in range(320, 1450, 240):
				_sun_zones.append({ "rect": Rect2(float(ax), 210.0, 52.0, 560.0), "angle": 0.14 })
		4:
			# Pinos del Jardín Mirador y andador
			for px in [160.0, 540.0, 920.0, 1280.0]:
				_accents.append({ "pos": Vector2(px, 640.0), "radius": 28.0, "color": Color(0.98, 0.92, 0.50), "speed": 1.4 })
			_sun_zones.append({ "rect": Rect2(260, 424, 160, 150), "angle": 0.22 })
			_sun_zones.append({ "rect": Rect2(920, 424, 160, 150), "angle": 0.22 })
		5:
			# Asta Bandera y rampa oriente
			_accents.append({ "pos": Vector2(480, 770), "radius": 36.0, "color": Color(1.0, 0.90, 0.44), "speed": 1.5 })
			_sun_zones.append({ "rect": Rect2(1140, 535, 190, 140), "angle": 0.18 })
		_:
			# Destellos solares en Cancha de Usos Múltiples y copa
			_accents.append({ "pos": Vector2(736, 368), "radius": 52.0, "color": Color(1.0, 0.88, 0.38), "speed": 1.8 })
			_accents.append({ "pos": Vector2(1180, 368), "radius": 34.0, "color": Color(1.0, 0.94, 0.50), "speed": 2.2 })
			_sun_zones.append({ "rect": Rect2(290, 80, 140, 520), "angle": 0.20 })
			_sun_zones.append({ "rect": Rect2(960, 80, 140, 520), "angle": 0.20 })

func _build_classroom_decor(rng: RandomNumberGenerator) -> void:
	# Motas de polvo iluminadas derivando lentamente en haces solares o iluminación del aula
	var x_windows: Array[Vector2] = []
	match classroom_index:
		0: x_windows = [Vector2(660, 760)]
		1: x_windows = [Vector2(60, 210), Vector2(610, 760)]
		2: x_windows = [Vector2(560, 750)]
		3: x_windows = [Vector2(280, 540)]
		4: x_windows = [Vector2(90, 320), Vector2(460, 700)]
		_: x_windows = [Vector2(180, 620)]

	var count := 14
	for i in range(count):
		var win_span: Vector2 = x_windows[i % x_windows.size()]
		_particles.append({
			"pos": Vector2(rng.randf_range(win_span.x, win_span.y), rng.randf_range(95.0, maxf(140.0, map_size.y - 60.0))),
			"vel": Vector2(rng.randf_range(2.5, 6.5), rng.randf_range(-3.0, 2.5)),
			"size": rng.randf_range(1.2, 2.2),
			"phase": rng.randf_range(0.0, TAU),
			"freq": rng.randf_range(1.4, 2.8),
			"sway": rng.randf_range(2.5, 5.5),
			"color": Color(ambient_light_color.r, ambient_light_color.g, ambient_light_color.b, 0.45),
			"is_leaf": false,
			"span": win_span,
		})

	# Brillo tenue en pizarrones, lámparas o monitores según el salón
	match classroom_index:
		0:
			# Matraces luminosos y pizarrón en Laboratorio
			_accents.append({ "pos": Vector2(248, 208), "radius": 20.0, "color": Color(0.35, 0.85, 1.0), "speed": 2.0 })
			_accents.append({ "pos": Vector2(458, 302), "radius": 20.0, "color": Color(0.50, 0.95, 0.45), "speed": 2.2 })
		1:
			# Pizarrón y haces de aula
			_sun_zones.append({ "rect": Rect2(70, 90, 115, 290), "angle": 0.24 })
			_sun_zones.append({ "rect": Rect2(640, 90, 110, 290), "angle": 0.24 })
		2:
			# Estrado cívico y estandarte
			_accents.append({ "pos": Vector2(400, 125), "radius": 32.0, "color": Color(1.0, 0.88, 0.40), "speed": 1.5 })
		3:
			# Lámparas cálidas de biblioteca
			for lx in [351.0, 110.0, 215.0, 320.0]:
				var ly := 112.0 if lx > 340.0 else 184.0
				_accents.append({ "pos": Vector2(lx, ly), "radius": 22.0, "color": Color(1.0, 0.86, 0.42), "speed": 1.6 })
		4:
			# Brillo tenue de pantallas de cómputo y pizarrón digital
			for ty in [204.0, 289.0]:
				for cx in [117.0, 185.0, 253.0]:
					_accents.append({ "pos": Vector2(cx, ty), "radius": 18.0, "color": Color(0.35, 0.82, 1.0), "speed": 2.4 })
		_:
			# Reflejo del centro de la duela deportiva y marcador
			_accents.append({ "pos": Vector2(400, 277), "radius": 42.0, "color": Color(1.0, 0.90, 0.55), "speed": 1.4 })

func _process(delta: float) -> void:
	_time += delta
	var w := maxf(64.0, map_size.x)
	var h := maxf(64.0, map_size.y)

	for p in _particles:
		var pos: Vector2 = p["pos"]
		var vel: Vector2 = p["vel"]
		pos += vel * delta
		pos.y += sin(_time * float(p["freq"]) + float(p["phase"])) * float(p["sway"]) * delta

		if p["is_leaf"]:
			if pos.x > w + 16.0:
				pos.x = -12.0
			if pos.y > h + 16.0:
				pos.y = -12.0
		else:
			var span: Vector2 = p.get("span", Vector2(40.0, w - 40.0))
			if pos.x > span.y:
				pos.x = span.x
			elif pos.x < span.x:
				pos.x = span.y
			if pos.y < 85.0:
				pos.y = h - 55.0
			elif pos.y > h - 55.0:
				pos.y = 85.0

		p["pos"] = pos

	queue_redraw()

func _draw() -> void:
	# 1. Bandas sutiles de luz solar diagonal
	for sz in _sun_zones:
		var r: Rect2 = sz["rect"]
		var skew: float = r.size.y * float(sz.get("angle", 0.2))
		var pulse := 0.85 + 0.15 * sin(_time * 0.9 + r.position.x * 0.01)
		var c := Color(ambient_light_color.r, ambient_light_color.g, ambient_light_color.b, 0.045 * pulse)
		var poly := PackedVector2Array([
			r.position,
			Vector2(r.end.x, r.position.y),
			Vector2(r.end.x + skew, r.end.y),
			Vector2(r.position.x + skew, r.end.y),
		])
		draw_colored_polygon(poly, c)

	# 2. Pulsos suaves sobre puntos de interés / lámparas / jardineras
	for ac in _accents:
		var ap: Vector2 = ac["pos"]
		var rad: float = float(ac["radius"])
		var col: Color = ac["color"]
		var spd: float = float(ac.get("speed", 1.5))
		var wave := 0.5 + 0.5 * sin(_time * spd + ap.x * 0.02)
		draw_circle(ap, rad * (0.92 + 0.12 * wave), Color(col.r, col.g, col.b, 0.06 + 0.05 * wave))
		draw_circle(ap, rad * 0.45, Color(col.r, col.g, col.b, 0.07 + 0.06 * wave))

	# 3. Hojas en exterior o motas de polvo iluminadas en salones
	for p in _particles:
		var pos: Vector2 = p["pos"]
		var sz: float = float(p["size"])
		var col: Color = p["color"]
		if p["is_leaf"]:
			var ang := _time * 1.8 + float(p["phase"])
			var dx := cos(ang) * sz
			var dy := sin(ang) * sz * 0.65
			var leaf_poly := PackedVector2Array([
				pos + Vector2(-dx, -dy),
				pos + Vector2(dy * 0.6, -dx * 0.6),
				pos + Vector2(dx, dy),
				pos + Vector2(-dy * 0.6, dx * 0.6),
			])
			draw_colored_polygon(leaf_poly, col)
		else:
			var twinkle := 0.45 + 0.55 * (0.5 + 0.5 * sin(_time * float(p["freq"]) * 1.4 + float(p["phase"])))
			draw_circle(pos, sz, Color(col.r, col.g, col.b, col.a * twinkle))
			draw_circle(pos, sz * 0.45, Color(1.0, 1.0, 1.0, 0.35 * twinkle))
