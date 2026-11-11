extends CharacterBody2D
class_name Student

## Alumno Secundario (NPC Estudiante) del plantel COBAEM CEMSaD 22 ENTHAVI.
## Provee ambientación viva, contexto narrativo escolar y retroalimentación emocional:
## - Estado 'sad': Afligido, encorvado, cabizbajo, afectado por los antivalores cercanos.
## - Estado 'happy': Alegre, erguido, con microanimaciones, uniforme COBAEM y corazones flotantes.
## Transiciona automáticamente cuando se redimen antivalores en su área o el jefe es superado.

signal cheered_up(student: Student)

enum State {
	SAD,        ## Afligido, intimidado por la sombra del antivalor
	RELIEVED,   ## Transición de alivio y asombro con squash & stretch
	HAPPY       ## Empoderado, alegre, emite corazones y anima al jugador
}

enum Gender {
	STUDENT_M,  ## Estudiante con pantalón escolar gris y suéter institucional
	STUDENT_F   ## Estudiante con falda tableada escolar y suéter institucional
}

const StoryDataClass := preload("res://scripts/story_data.gd")

const PHRASES_SAD := [
	"Tengo miedo de salir al receso...",
	"¿Por qué se burlan de nosotros?",
	"No me puedo concentrar en clase...",
	"Ojalá hubiera más respeto aquí...",
	"Siento un ambiente muy pesado..."
]

const PHRASES_HAPPY := [
	"¡Gracias por defendernos!",
	"¡El respeto nos une a todos!",
	"¡La empatía nos hace más fuertes!",
	"¡Vamos, tú puedes llegar a la meta!",
	"¡Orgullo COBAEM CEMSaD 22!"
]

@export var student_name: String = "Estudiante"
@export var gender: Gender = Gender.STUDENT_M
@export var initial_state: State = State.SAD
@export var influence_radius: float = 240.0 ## 6 metros lineales a escala 40 px/m
@export var can_heal_player: bool = true   ## Puede ofrecer 1 corazón de aliento al héroe herido

var current_state: State = State.SAD
var player: CharacterBody2D = null

var _anim_time: float = 0.0
var _influence_radius_sq: float = 0.0
var _has_healed: bool = false
var _has_threat: bool = false
var _dialog_cooldown: float = 0.0
var _tear_timer: float = 0.0
var _heart_timer: float = 0.0
var _squash_stretch: Vector2 = Vector2.ONE
var _speech_label: Label = null
var collision_shape: CollisionShape2D = null

func _ready() -> void:
	y_sort_enabled = true
	add_to_group("students")
	_influence_radius_sq = influence_radius * influence_radius
	current_state = initial_state
	_anim_time = randf() * TAU

	_setup_collision()
	_setup_speech_label()
	queue_redraw()

func _setup_collision() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		collision_shape = CollisionShape2D.new()
		var capsule := CapsuleShape2D.new()
		capsule.radius = 8.0
		capsule.height = 18.0
		collision_shape.shape = capsule
		collision_shape.position = Vector2(0, -4)
		add_child(collision_shape)
	collision_layer = 1
	collision_mask = 1

func _setup_speech_label() -> void:
	_speech_label = Label.new()
	_speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speech_label.add_theme_font_size_override("font_size", 10)
	_speech_label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.12))
	_speech_label.add_theme_constant_override("outline_size", 4)
	_speech_label.visible = false
	_speech_label.z_index = 45
	add_child(_speech_label)

func _physics_process(delta: float) -> void:
	_anim_time += delta
	if _dialog_cooldown > 0.0:
		_dialog_cooldown -= delta

	match current_state:
		State.SAD:
			_process_sad_state(delta)
		State.RELIEVED:
			pass
		State.HAPPY:
			_process_happy_state(delta)

	# Interacción de proximidad con el jugador
	_check_player_proximity()

	# Suavizar retorno de squash & stretch
	_squash_stretch = _squash_stretch.lerp(Vector2.ONE, 10.0 * delta)
	queue_redraw()

func _process_sad_state(delta: float) -> void:
	# Verificación de antivalores en el área de influencia
	_check_threats_around()

	# Efecto de lágrimas o desánimo
	_tear_timer -= delta
	if _tear_timer <= 0.0:
		_tear_timer = randf_range(2.0, 4.0)
		_spawn_tear_particle()

func _get_fx() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Fx")
	return null

func _process_relieved_state(_delta: float) -> void:
	pass

func _process_happy_state(delta: float) -> void:
	# Emisión periódica de corazones o chispas de entusiasmo
	_heart_timer -= delta
	if _heart_timer <= 0.0:
		_heart_timer = randf_range(3.0, 5.5)
		_spawn_happy_particle()

## Revisa si aún existen antivalores activos amenazando su entorno
func _check_threats_around() -> void:
	if not is_inside_tree():
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	var threat_found := false
	for e in enemies:
		if e is Node2D and e.is_inside_tree():
			var is_active = e.get("is_active") if "is_active" in e else true
			if is_active:
				var dist_sq := global_position.distance_squared_to(e.global_position)
				if dist_sq <= _influence_radius_sq:
					threat_found = true
					break
	_has_threat = threat_found

## Alerta de amenaza cercana (registra estado de alerta)
func has_threat_nearby() -> void:
	_has_threat = true

## Pasa al alumno a estado feliz de inmediato (ej. cuota completada, disparo de virtud o jefe redimido)
func cheer_up() -> void:
	if current_state == State.SAD:
		_start_relieved_transition()

func _start_relieved_transition() -> void:
	current_state = State.RELIEVED
	_squash_stretch = Vector2(1.3, 0.7)
	var fx = _get_fx()
	var parent = get_parent() if get_parent() else self
	if fx:
		fx.floating_text(parent, global_position + Vector2(0, -42), "¡Qué alivio!", Color(0.9, 1.0, 0.6), 13)
		fx.burst(parent, global_position + Vector2(0, -20), Color(1.0, 0.9, 0.4), 10, 100.0)

	var tw := create_tween()
	tw.tween_property(self, "_squash_stretch", Vector2(0.8, 1.25), 0.15)
	tw.tween_property(self, "_squash_stretch", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		current_state = State.HAPPY
		cheered_up.emit(self)
	)

## Alivia al estudiante si el antivalor redimido ocurrió en su proximidad
func cheer_up_area(epicenter: Vector2, radius: float = 240.0) -> void:
	if current_state != State.HAPPY:
		if global_position.distance_squared_to(epicenter) <= radius * radius:
			cheer_up()

## Detección del héroe al pasar cerca
func _check_player_proximity() -> void:
	if not player or not is_instance_valid(player):
		if not is_inside_tree():
			return
		var p_nodes := get_tree().get_nodes_in_group("player")
		if not p_nodes.is_empty():
			player = p_nodes[0]
		else:
			return

	var dist_sq := global_position.distance_squared_to(player.global_position)
	if dist_sq <= 4900.0: # Dentro de 70 px (~1.75 m)
		if _dialog_cooldown <= 0.0:
			_speak_proximity_dialog()
			_dialog_cooldown = 4.5

		# Ofrecer un corazón si el alumno está feliz y el jugador está herido
		if current_state == State.HAPPY and can_heal_player and not _has_healed:
			if player.health < player.max_health:
				_heal_player()

func _speak_proximity_dialog() -> void:
	var phrase := ""
	var col := Color.WHITE
	var s_name_clean := student_name.to_lower().strip_edges()
	var char_data: Dictionary = StoryDataClass.get_secondary_character(s_name_clean) if ResourceLoader.exists("res://scripts/story_data.gd") else {}

	if not char_data.is_empty():
		var state_key: String = "state_afflicted" if current_state == State.SAD else "state_redeemed"
		var state_info: Dictionary = char_data.get(state_key, {})
		var quotes: Array = state_info.get("quotes", [])
		if not quotes.is_empty():
			phrase = quotes[randi() % quotes.size()]
			col = char_data.get("color_theme", Color.WHITE)

	if phrase.is_empty():
		if current_state == State.SAD:
			phrase = PHRASES_SAD[randi() % PHRASES_SAD.size()]
			col = Color(0.7, 0.75, 0.95)
		else:
			phrase = PHRASES_HAPPY[randi() % PHRASES_HAPPY.size()]
			col = Color(1.0, 0.95, 0.5)

	var fx = _get_fx()
	var parent = get_parent() if get_parent() else self
	if fx:
		fx.floating_text(parent, global_position + Vector2(0, -45), phrase, col, 11)

func _heal_player() -> void:
	_has_healed = true
	player.health = mini(player.max_health, player.health + 1)
	player.health_changed.emit(player.health, player.max_health)

	var fx = _get_fx()
	var parent = get_parent() if get_parent() else self
	if fx:
		fx.floating_text(parent, global_position + Vector2(0, -50), "¡+1 Esperanza!", Color(0.4, 1.0, 0.5), 14)
		fx.burst(parent, player.global_position, Color(1.0, 0.3, 0.5), 12, 140.0)

func _spawn_tear_particle() -> void:
	var fx = _get_fx()
	var parent = get_parent() if get_parent() else self
	if fx:
		fx.burst(parent, global_position + Vector2(randf_range(-4, 4), -22), Color(0.4, 0.7, 1.0, 0.6), 3, 40.0)

func _spawn_happy_particle() -> void:
	var fx = _get_fx()
	var parent = get_parent() if get_parent() else self
	if fx:
		fx.burst(parent, global_position + Vector2(0, -32), Color(1.0, 0.45, 0.65), 5, 80.0)

# -----------------------------------------------------------------------------
# DIBUJO PROCEDURAL PIXEL-ART (UNIFORME OFICIAL COBAEM CEMSaD 22)
# -----------------------------------------------------------------------------

func _draw() -> void:
	# 1. Sombra elíptica en perspectiva 3/4
	var shadow_col := Color(0.06, 0.08, 0.12, 0.30)
	draw_rect(Rect2(-10, -4, 20, 6), shadow_col)
	draw_rect(Rect2(-8, -6, 16, 10), shadow_col)

	# 2. Paleta institucional COBAEM
	var col_vino := Color(0.45, 0.08, 0.16)     # Guinda institucional
	var col_blanco := Color(0.95, 0.95, 0.92)   # Camisa escolar
	var col_pantalon := Color(0.25, 0.25, 0.28) # Gris carbón
	var col_piel := Color(0.92, 0.75, 0.58)     # Tono de piel cálido
	var col_cabello := Color(0.18, 0.12, 0.10)  # Castaño / oscuro

	# Desaturación si está triste
	if current_state == State.SAD:
		col_vino = col_vino.lerp(Color(0.25, 0.22, 0.28), 0.45)
		col_piel = col_piel.lerp(Color(0.60, 0.65, 0.70), 0.35)

	# 3. Animación procedural según estado
	var bob_y := 0.0
	var head_tilt := 0.0
	var tremor_x := 0.0
	if current_state == State.SAD:
		# Postura encorvada, balanceo lento y decaído
		bob_y = sin(_anim_time * 2.0) * 1.0 + 2.0
		head_tilt = 2.0
		if _has_threat:
			tremor_x = sin(_anim_time * 22.0) * 1.4
	else:
		# Saltitos rítmicos y jubilosos
		bob_y = -absf(sin(_anim_time * 5.0)) * 3.5

	# Aplicar squash & stretch
	var base_y := -18.0 + bob_y

	# Piernas / Pantalón o Falda escolar
	if gender == Gender.STUDENT_M:
		draw_rect(Rect2(-6 + tremor_x, -8, 5, 8), col_pantalon)
		draw_rect(Rect2(1 + tremor_x, -8, 5, 8), col_pantalon)
	else:
		draw_rect(Rect2(-7 + tremor_x, -10, 14, 7), col_vino.darkened(0.2)) # Falda tableada
		draw_rect(Rect2(-5 + tremor_x, -3, 4, 4), col_piel)
		draw_rect(Rect2(1 + tremor_x, -3, 4, 4), col_piel)

	# Zapatos escolares negros
	draw_rect(Rect2(-7 + tremor_x, 0, 6, 2), Color(0.1, 0.1, 0.12))
	draw_rect(Rect2(1 + tremor_x, 0, 6, 2), Color(0.1, 0.1, 0.12))

	# Torso: Suéter guinda institucional COBAEM con cuello de camisa blanca
	var torso_rect := Rect2((-8 * _squash_stretch.x) + tremor_x, base_y, 16 * _squash_stretch.x, 14 * _squash_stretch.y)
	draw_rect(torso_rect, col_vino)
	# Cuello blanco escolar
	draw_rect(Rect2(-3 + tremor_x, base_y, 6, 3), col_blanco)
	# Escudo escolar COBAEM miniatura (dorado / verde)
	draw_rect(Rect2(-5 + tremor_x, base_y + 4, 3, 3), Color(0.85, 0.72, 0.25))

	# Cabeza y rostro
	var head_y := base_y - 12.0 * _squash_stretch.y + head_tilt
	draw_rect(Rect2(-6 + tremor_x, head_y, 12, 11), col_piel)
	# Cabello
	draw_rect(Rect2(-7 + tremor_x, head_y - 2, 14, 5), col_cabello)

	# Distintivos visuales de personajes canon del Modo Historia
	var s_canon := student_name.to_lower().strip_edges()
	if s_canon == "xochitl":
		# Listones otomíes tradicionales a los costados
		draw_rect(Rect2(-8 + tremor_x, head_y + 1, 2, 6), Color(0.95, 0.35, 0.55)) # Rosa mexicano
		draw_rect(Rect2(6 + tremor_x, head_y + 1, 2, 6), Color(1.0, 0.85, 0.30))  # Oro
	elif s_canon == "sofia":
		# Gafas cyan
		draw_rect(Rect2(-5 + tremor_x, head_y + 3, 3, 3), Color(0.20, 0.65, 0.85), false, 1.0)
		draw_rect(Rect2(2 + tremor_x, head_y + 3, 3, 3), Color(0.20, 0.65, 0.85), false, 1.0)
		draw_line(Vector2(-2 + tremor_x, head_y + 4), Vector2(2 + tremor_x, head_y + 4), Color(0.20, 0.65, 0.85), 1.0)
	elif s_canon == "emiliano":
		# Cinta deportiva roja en la frente
		draw_rect(Rect2(-7 + tremor_x, head_y, 14, 2), Color(0.90, 0.25, 0.25))
	elif s_canon == "mateo":
		# Chaleco escolar más azulado y gafete de nuevo ingreso
		draw_rect(Rect2(-6 + tremor_x, base_y + 2, 3, 4), Color(0.95, 0.95, 0.95))

	# Expresión facial pixel-art
	if current_state == State.SAD:
		# Ojos gachos y boca triste
		draw_rect(Rect2(-4 + tremor_x, head_y + 4, 2, 2), Color(0.15, 0.15, 0.2))
		draw_rect(Rect2(2 + tremor_x, head_y + 4, 2, 2), Color(0.15, 0.15, 0.2))
		draw_line(Vector2(-3 + tremor_x, head_y + 8), Vector2(3 + tremor_x, head_y + 8), Color(0.3, 0.2, 0.2), 1.0)
	else:
		# Ojos alegres (arcos de sonrisa) y mejillas sonrojadas
		draw_rect(Rect2(-4 + tremor_x, head_y + 3, 2, 2), Color(0.15, 0.15, 0.2))
		draw_rect(Rect2(2 + tremor_x, head_y + 3, 2, 2), Color(0.15, 0.15, 0.2))
		draw_rect(Rect2(-5 + tremor_x, head_y + 5, 2, 1), Color(1.0, 0.4, 0.5, 0.6))
		draw_rect(Rect2(3 + tremor_x, head_y + 5, 2, 1), Color(1.0, 0.4, 0.5, 0.6))
		draw_rect(Rect2(-2 + tremor_x, head_y + 7, 4, 2), Color(0.7, 0.1, 0.2))
