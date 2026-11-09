extends RefCounted
class_name LevelManager

## Gestor multinivel y catálogo de escenarios.
## Define los niveles oficiales y detecta automáticamente cualquier
## nuevo escenario colocado en la carpeta 'res://escenarios/'.

const ESCENARIOS_DIR := "res://escenarios/"

static func get_default_levels() -> Array[Dictionary]:
	return [
		{
			"id": 1,
			"title": "Nivel 1: Patio Escolar de los Valores",
			"scenario_image": "res://escenarios/nivel_1_patio.png",
			"player_spawn": Vector2(110, 410),
			"goal_position": Vector2(1130, 410),
			"goal_label": "Pasillos ->",
			"enemies": [
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(400, 350) },
				{ "type": Enemy.Type.ACOSO, "pos": Vector2(600, 240) },
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(760, 470) },
				{ "type": Enemy.Type.BULLYING, "pos": Vector2(920, 410) },
			],
			"obstacles": [
				# Fachada y pared superior de la escuela
				Rect2(0, 0, 1200, 110),
				# Fuente central de la plaza
				Rect2(525, 355, 150, 110),
				# Bancas del patio
				Rect2(325, 320, 50, 25),
				Rect2(825, 320, 50, 25),
				Rect2(325, 470, 50, 25),
				Rect2(825, 470, 50, 25),
			]
		},
		{
			"id": 2,
			"title": "Nivel 2: Pasillos de la Escuela",
			"scenario_image": "res://escenarios/nivel_2_pasillo.png",
			"player_spawn": Vector2(110, 420),
			"goal_position": Vector2(1510, 420),
			"goal_label": "Gimnasio ->",
			"enemies": [
				{ "type": Enemy.Type.ACOSO, "pos": Vector2(420, 420) },
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(740, 330) },
				{ "type": Enemy.Type.ACOSO, "pos": Vector2(1060, 480) },
				{ "type": Enemy.Type.BULLYING, "pos": Vector2(1300, 420) },
			],
			"obstacles": [
				# Pared superior con taquillas
				Rect2(0, 0, 1600, 140),
				# Zócalo y pared inferior
				Rect2(0, 660, 1600, 40),
				# Bancas a lo largo del pasillo
				Rect2(370, 235, 60, 25),
				Rect2(670, 235, 60, 25),
				Rect2(970, 235, 60, 25),
				Rect2(1270, 235, 60, 25),
			]
		},
		{
			"id": 3,
			"title": "Nivel 3: Gimnasio y Auditorio de Campeones",
			"scenario_image": "res://escenarios/nivel_3_gimnasio.png",
			"player_spawn": Vector2(140, 450),
			"goal_position": Vector2(1060, 450),
			"goal_label": "¡GRAN COPA!",
			"enemies": [
				{ "type": Enemy.Type.BULLYING, "pos": Vector2(450, 450) },
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(600, 280) },
				{ "type": Enemy.Type.ACOSO, "pos": Vector2(600, 620) },
				{ "type": Enemy.Type.BULLYING, "pos": Vector2(820, 450) },
				{ "type": Enemy.Type.GROSERIA, "pos": Vector2(940, 360) },
			],
			"obstacles": [
				# Gradas superiores del estadio
				Rect2(0, 0, 1200, 120),
				# Pared inferior
				Rect2(0, 740, 1200, 60),
			]
		}
	]

## Obtiene todos los niveles, incluyendo cualquier escenario adicional detectado en 'escenarios/'
static func get_all_levels() -> Array[Dictionary]:
	var levels := get_default_levels()
	var known_images: Array[String] = []
	for lvl in levels:
		known_images.append(lvl.get("scenario_image", ""))

	# Explorar la carpeta 'escenarios/' en busca de nuevas imágenes añadidas por el usuario
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

## Genera una configuración jugable automática para cualquier imagen nueva que se coloque
static func _create_auto_level(id: int, image_path: String, title: String) -> Dictionary:
	var width := 1200.0
	var height := 800.0
	if ResourceLoader.exists(image_path):
		var tex: Texture2D = load(image_path)
		if tex:
			width = float(tex.get_width())
			height = float(tex.get_height())

	return {
		"id": id,
		"title": "Nivel %d: %s" % [id, title],
		"scenario_image": image_path,
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
