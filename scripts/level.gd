extends Node2D
class_name Level

## Controlador de escenario individual en perspectiva 3/4.
## Carga la imagen de fondo, genera límites perimetrales y obstáculos,
## e instancia al jugador, enemigos y la meta con ordenamiento Y-Sort.

signal player_health_changed(current: int, max_hp: int)
signal player_died
signal enemy_defeated(enemy: Enemy)
signal level_completed

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const GOAL_SCENE := preload("res://scenes/goal.tscn")

@onready var background: Sprite2D = $Background
@onready var world_boundaries: StaticBody2D = $WorldBoundaries
@onready var obstacles: StaticBody2D = $Obstacles
@onready var entities: Node2D = $Entities
@onready var enemies_container: Node2D = $Entities/Enemies

var player: CharacterBody2D = null
var goal: Area2D = null
var map_size: Vector2 = Vector2(800, 450)
var level_data: Dictionary = {}

func _ensure_nodes() -> void:
	if background == null:
		background = get_node_or_null("Background")
	if world_boundaries == null:
		world_boundaries = get_node_or_null("WorldBoundaries")
	if obstacles == null:
		obstacles = get_node_or_null("Obstacles")
	if entities == null:
		entities = get_node_or_null("Entities")
	if enemies_container == null and entities != null:
		enemies_container = entities.get_node_or_null("Enemies")

## Configura el escenario a partir de un diccionario de definición de nivel
func setup_level(data: Dictionary) -> void:
	_ensure_nodes()
	level_data = data

	if entities:
		entities.y_sort_enabled = true
	if enemies_container:
		enemies_container.y_sort_enabled = true

	# 1. Cargar imagen de fondo del escenario
	var image_path: String = data.get("scenario_image", "")
	var tex: Texture2D = null
	if ResourceLoader.exists(image_path):
		tex = load(image_path)
	elif FileAccess.file_exists(image_path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(image_path))
		if img:
			tex = ImageTexture.create_from_image(img)
	elif ResourceLoader.exists("res://assets/background/fondo.png"):
		tex = load("res://assets/background/fondo.png")

	if tex:
		if background:
			background.texture = tex
		map_size = Vector2(tex.get_width(), tex.get_height())
	else:
		map_size = Vector2(1200, 800)

	# 2. Configurar colisiones de frontera exterior
	_build_boundary_walls(map_size)

	# 3. Construir obstáculos sólidos del escenario
	_build_obstacles(data.get("obstacles", []))

	# 4. Instanciar al jugador
	player = PLAYER_SCENE.instantiate()
	player.position = data.get("player_spawn", Vector2(90.0, map_size.y * 0.5))
	if entities:
		entities.add_child(player)

	player.health_changed.connect(func(c, m): player_health_changed.emit(c, m))
	player.died.connect(func(): player_died.emit())

	# Ajustar límites de cámara a las dimensiones del mapa
	if player.camera:
		player.camera.limit_left = 0
		player.camera.limit_top = 0
		player.camera.limit_right = int(map_size.x)
		player.camera.limit_bottom = int(map_size.y)
		player.camera.reset_smoothing()

	# 5. Instanciar la meta de salida
	goal = GOAL_SCENE.instantiate()
	goal.position = data.get("goal_position", Vector2(map_size.x - 90.0, map_size.y * 0.5))
	if entities:
		entities.add_child(goal)
	goal.set_goal_text(data.get("goal_label", "META"))
	goal.player_reached_goal.connect(_on_goal_reached)

	# 6. Instanciar grupo de enemigos
	var enemy_list: Array = data.get("enemies", [])
	for e_info in enemy_list:
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.enemy_type = e_info.get("type", Enemy.Type.GROSERIA)
		enemy.position = e_info.get("pos", Vector2(map_size.x * 0.5, map_size.y * 0.5))
		enemy.player = player
		enemy.defeated.connect(func(e): enemy_defeated.emit(e))
		if enemies_container:
			enemies_container.add_child(enemy)

func _on_goal_reached() -> void:
	if player and is_instance_valid(player):
		player.celebrate()
	stop_enemies()
	level_completed.emit()

## Detiene el movimiento de todos los enemigos en el escenario
func stop_enemies() -> void:
	if enemies_container:
		for enemy in enemies_container.get_children():
			if enemy is Enemy:
				enemy.stop()

## Construye cuatro muros de colisión perimetrales para delimitar el mapa
func _build_boundary_walls(size: Vector2) -> void:
	if world_boundaries == null:
		return
	for child in world_boundaries.get_children():
		child.queue_free()

	var wall_thickness := 50.0

	# Muro Superior
	_add_wall_box(Vector2(size.x * 0.5, -wall_thickness * 0.5), Vector2(size.x + wall_thickness * 2, wall_thickness))
	# Muro Inferior
	_add_wall_box(Vector2(size.x * 0.5, size.y + wall_thickness * 0.5), Vector2(size.x + wall_thickness * 2, wall_thickness))
	# Muro Izquierdo
	_add_wall_box(Vector2(-wall_thickness * 0.5, size.y * 0.5), Vector2(wall_thickness, size.y + wall_thickness * 2))
	# Muro Derecho
	_add_wall_box(Vector2(size.x + wall_thickness * 0.5, size.y * 0.5), Vector2(wall_thickness, size.y + wall_thickness * 2))

func _add_wall_box(center: Vector2, box_size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = box_size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = center
	world_boundaries.add_child(col)

## Instancia las cajas de colisión para los obstáculos declarados en el nivel
func _build_obstacles(obs_list: Array) -> void:
	if obstacles == null:
		return
	for child in obstacles.get_children():
		child.queue_free()

	for obs in obs_list:
		var rect: Rect2 = obs if obs is Rect2 else Rect2(obs.get("x", 0), obs.get("y", 0), obs.get("w", 0), obs.get("h", 0))
		if rect.size.x > 0 and rect.size.y > 0:
			var shape := RectangleShape2D.new()
			shape.size = rect.size
			var col := CollisionShape2D.new()
			col.shape = shape
			col.position = rect.position + rect.size * 0.5
			obstacles.add_child(col)
