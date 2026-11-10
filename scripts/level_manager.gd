extends RefCounted
class_name LevelManager

## Catálogo de escenarios a ESCALA REAL (1 m = 40 px) del plantel CEMSaD 22 ENTHAVI (COBAEM).
## Gestiona la configuración métrica, spawns, metas, enemigos y obstáculos de cada nivel.
## Permite detectar automáticamente nuevos mapas PNG/JPG/WebP colocados en 'res://escenarios/'.

const ESCENARIOS_DIR := "res://escenarios/"
const SCALE_PX_PER_METER := 40.0

static func get_default_levels() -> Array[Dictionary]:
	return [
		{
			"id": 1,
			"title": "Escenario 1/6: Acceso, Caseta C.V. y Edif. D (Lab. 183 m²)",
			"scenario_image": "res://escenarios/nivel_1_acceso_laboratorio.png",
			"real_dimensions_m": Vector2(36.0, 22.0),
			"map_size": Vector2(1440, 880),
			"player_spawn": Vector2(280, 720),
			"goal_position": Vector2(120, 330),
			"goal_label": "Edificio A ->",
			"enemies": [
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(450, 700) },
				{ "type": Enemy.Type.ACOSO, "pos": Vector2(880, 660) },
				{ "type": Enemy.Type.BULLYING, "pos": Vector2(760, 405) },
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(260, 440) },
			],
			"obstacles": [
				# Muro de contención norte + Muro institucional COBAEM guinda
				Rect2(0, 0, 600, 220),
				# Jardinera del Osito Topiario
				Rect2(288, 220, 260, 80),
				# Edificio D: Laboratorio de Usos Múltiples (12.8x7.2m), Reactivos y Almacén
				Rect2(604, 0, 836, 360),
				# Autos estacionados en batería
				Rect2(490, 440, 210, 140),
				# Sistema Captador de Agua Pluvial (5.0x5.0m = 25 m²)
				Rect2(1150, 510, 220, 220),
				# Caseta de Vigilancia C.V. (3.0x2.5m = 7.5 m²)
				Rect2(36, 530, 140, 150),
				# Portón Triple Abatible sur
				Rect2(0, 820, 560, 60),
				# Barda Perimetral Oriente
				Rect2(1400, 0, 40, 880),
			]
		},
		{
			"id": 2,
			"title": "Escenario 2/6: Edificio A — Cafetería y Aulas 1-2 (339 m²)",
			"scenario_image": "res://escenarios/nivel_2_edificio_a_cafeteria.png",
			"real_dimensions_m": Vector2(40.0, 20.0),
			"map_size": Vector2(1600, 800),
			"player_spawn": Vector2(1480, 290),
			"goal_position": Vector2(140, 260),
			"goal_label": "Plaza Cívica ->",
			"enemies": [
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(1220, 295) },
				{ "type": Enemy.Type.ACOSO, "pos": Vector2(920, 295) },
				{ "type": Enemy.Type.BULLYING, "pos": Vector2(620, 295) },
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(230, 440) },
			],
			"obstacles": [
				# Jardinera norte con setos podados y pinos en espiral
				Rect2(0, 0, 1600, 220),
				# Edificio A: Almacén, Aula 1 (8x7m), Aula 2 (8x7m) y Sanitarios H/M (6x7m)
				Rect2(356, 368, 1150, 400),
				# Barra sur del Desayunador / Cafetería (deja abierta el área de mesas)
				Rect2(100, 550, 256, 220),
				# Muro verde menta poniente
				Rect2(0, 200, 96, 560),
			]
		},
		{
			"id": 3,
			"title": "Escenario 3/6: Plaza Cívica (748 m²) y Escalinata S (+4m)",
			"scenario_image": "res://escenarios/nivel_3_plaza_civica_escalinata.png",
			"real_dimensions_m": Vector2(40.0, 22.5),
			"map_size": Vector2(1600, 900),
			"player_spawn": Vector2(1440, 760),
			"goal_position": Vector2(126, 108),
			"goal_label": "Edificio B (+4m) ->",
			"enemies": [
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(1180, 560) },
				{ "type": Enemy.Type.ACOSO, "pos": Vector2(880, 380) },
				{ "type": Enemy.Type.BULLYING, "pos": Vector2(620, 620) },
				{ "type": Enemy.Type.ACOSO, "pos": Vector2(380, 440) },
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(126, 480) },
			],
			"obstacles": [
				# Muro de contención norte de piedra braza negra (4.00 m de altura) y bodega
				Rect2(224, 0, 1376, 196),
				# Barda colindante poniente
				Rect2(0, 0, 36, 900),
				# Muro lateral (alfarda color vino) entre Plaza Cívica y Escalinata S
				Rect2(216, 180, 20, 560),
			]
		},
		{
			"id": 4,
			"title": "Escenario 4/6: Edificio B — Aulas 3-4, Biblioteca y Maestros",
			"scenario_image": "res://escenarios/nivel_4_edificio_b.png",
			"real_dimensions_m": Vector2(36.0, 20.0),
			"map_size": Vector2(1440, 800),
			"player_spawn": Vector2(110, 490),
			"goal_position": Vector2(1350, 490),
			"goal_label": "Edificio C ->",
			"enemies": [
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(380, 495) },
				{ "type": Enemy.Type.ACOSO, "pos": Vector2(680, 495) },
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(920, 495) },
				{ "type": Enemy.Type.BULLYING, "pos": Vector2(1160, 495) },
			],
			"obstacles": [
				# Edificio B (32.00 x 9.78 m): Aulas 3 y 4, Biblioteca y Sala de Maestros
				Rect2(80, 0, 1280, 424),
				# Jardín mirador sur (+4.00 m) con setos, pinos y barandal blanco
				Rect2(0, 580, 1440, 220),
			]
		},
		{
			"id": 5,
			"title": "Escenario 5/6: Edificio C — Dirección, Aulas y Cómputo (625 m²)",
			"scenario_image": "res://escenarios/nivel_5_edificio_c_computo.png",
			"real_dimensions_m": Vector2(36.0, 22.0),
			"map_size": Vector2(1440, 880),
			"player_spawn": Vector2(100, 560),
			"goal_position": Vector2(1356, 588),
			"goal_label": "Cancha Deportiva ->",
			"enemies": [
				{ "type": Enemy.Type.ACOSO, "pos": Vector2(360, 575) },
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(620, 575) },
				{ "type": Enemy.Type.BULLYING, "pos": Vector2(860, 575) },
				{ "type": Enemy.Type.ACOSO, "pos": Vector2(1100, 575) },
			],
			"obstacles": [
				# Edificio C (Planta Alta Taller de Cómputo 115.2m² / Aula 6 + Planta Baja Admin / Aula 5)
				Rect2(48, 0, 1168, 512),
				# Murete verde claro oriente junto a la rampa
				Rect2(1220, 380, 180, 140),
				# Jardín sur del Asta Bandera y ciprés central
				Rect2(0, 650, 1130, 230),
			]
		},
		{
			"id": 6,
			"title": "Escenario 6/6: Cancha de Usos Múltiples (540 m²) y Bancas",
			"scenario_image": "res://escenarios/nivel_6_cancha_usos_multiples.png",
			"real_dimensions_m": Vector2(36.0, 22.5),
			"map_size": Vector2(1440, 900),
			"player_spawn": Vector2(100, 360),
			"goal_position": Vector2(1180, 368),
			"goal_label": "¡GRAN COPA CEMSaD 22!",
			"enemies": [
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(420, 240) },
				{ "type": Enemy.Type.ACOSO, "pos": Vector2(460, 500) },
				{ "type": Enemy.Type.BULLYING, "pos": Vector2(736, 368) },
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(960, 220) },
				{ "type": Enemy.Type.BULLYING, "pos": Vector2(1020, 480) },
			],
			"obstacles": [
				# Muro perimetral norte verde claro de la cancha
				Rect2(120, 0, 1220, 56),
				# Zona de Bancas y Mesas de Estudio al sur (260 m²)
				Rect2(0, 690, 1360, 210),
				# Barda Perimetral Oriente Acotada (52.00 m)
				Rect2(1350, 0, 90, 900),
			]
		}
	]

## Obtiene todos los niveles, incluyendo cualquier escenario adicional detectado en 'escenarios/'
static func get_all_levels() -> Array[Dictionary]:
	var levels := get_default_levels()
	var known_images: Array[String] = []
	for lvl in levels:
		known_images.append(lvl.get("scenario_image", ""))

	var dir := DirAccess.open(ESCENARIOS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		var extra_id := levels.size() + 1
		while file_name != "":
			if not dir.current_is_dir():
				var ext := file_name.get_extension().to_lower()
				if ext in ["png", "jpg", "jpeg", "webp"]:
					var full_path := ESCENARIOS_DIR + file_name
					if not (full_path in known_images):
						var clean_name := file_name.get_basename().replace("_", " ").capitalize()
						levels.append(_create_auto_level(extra_id, full_path, clean_name))
						extra_id += 1
			file_name = dir.get_next()
		dir.list_dir_end()

	return levels

static func _create_auto_level(id: int, image_path: String, title: String) -> Dictionary:
	var width := 1440.0
	var height := 880.0
	if ResourceLoader.exists(image_path):
		var tex: Texture2D = load(image_path)
		if tex:
			width = float(tex.get_width())
			height = float(tex.get_height())
	elif FileAccess.file_exists(image_path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(image_path))
		if img:
			width = float(img.get_width())
			height = float(img.get_height())

	return {
		"id": id,
		"title": "Escenario %d: %s" % [id, title],
		"scenario_image": image_path,
		"map_size": Vector2(width, height),
		"real_dimensions_m": Vector2(width / SCALE_PX_PER_METER, height / SCALE_PX_PER_METER),
		"player_spawn": Vector2(90.0, height * 0.5),
		"goal_position": Vector2(width - 90.0, height * 0.5),
		"goal_label": "Siguiente ->",
		"enemies": [
			{ "type": Enemy.Type.GROSERIA, "pos": Vector2(width * 0.35, height * 0.4) },
			{ "type": Enemy.Type.ACOSO, "pos": Vector2(width * 0.55, height * 0.6) },
			{ "type": Enemy.Type.BULLYING, "pos": Vector2(width * 0.75, height * 0.45) },
		],
		"obstacles": []
	}
