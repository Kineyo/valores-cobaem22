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
const AllyBrainClass := preload("res://scripts/ally_brain.gd")

const PHRASES_SAD := [
	"Tengo miedo de abrir la mochila y que se burlen...",
	"¿Por qué nadie dice nada cuando empujan en el pasillo?",
	"Siento un nudo en la garganta antes de entrar al salón...",
	"Ojalá alguien se sentara conmigo en el receso...",
	"El ambiente se siente helado y pesado..."
]

const PHRASES_HAPPY := [
	"¡Ya no estamos solos! ¡Estoy contigo en esta pelea!",
	"¡El respeto y la empatía rompen cualquier sombra!",
	"¡Cuidado con los proyectiles, compañero, yo cubro tu flanco!",
	"¡Vamos juntos hacia la meta, orgullo CEMSaD 22!",
	"¡La Esperanza nos devuelve la fuerza en equipo!"
]

const PHRASES_HAPPY_PLAYER_F_MIXED := [
	"¡Ya no estamos solos! ¡Estoy contigo en esta pelea, compañera!",
	"¡El respeto y la empatía rompen cualquier sombra!",
	"¡Cuidado con los proyectiles, compañera, yo cubro tu flanco!",
	"¡Vamos juntos hacia la meta, orgullo CEMSaD 22!",
	"¡La Esperanza nos devuelve la fuerza en equipo!"
]

const PHRASES_HAPPY_PLAYER_F_BOTH := [
	"¡Ya no estamos solas! ¡Estoy contigo en esta pelea, amiga!",
	"¡El respeto y la empatía rompen cualquier sombra!",
	"¡Cuidado con los proyectiles, compañera, yo cubro tu flanco!",
	"¡Vamos juntas hacia la meta, orgullo CEMSaD 22!",
	"¡La Esperanza nos devuelve la fuerza en equipo!"
]

@export var student_name: String = "Estudiante"
@export var gender: Gender = Gender.STUDENT_M
@export var initial_state: State = State.SAD
@export var influence_radius: float = 240.0 ## 6 metros lineales a escala 40 px/m
@export var can_heal_player: bool = true   ## Puede ofrecer 1 corazón de aliento al héroe herido
@export var can_assist_in_combat: bool = true ## Activa cerebro de combate aliado al pasar a HAPPY
@export var level_ref: Node2D = null

var current_state: State = State.SAD
var player: CharacterBody2D = null
var brain: AllyBrain = null
var is_combat_ally: bool = false

var _anim_time: float = 0.0
var _has_healed: bool = false
var _dialog_cooldown: float = 0.0
var _tear_timer: float = 0.0
var _heart_timer: float = 0.0
var _resist_timer: float = 0.0
var _pose_hold_timer: float = 0.0
var _squash_stretch: Vector2 = Vector2.ONE
var _base_sprite_scale: Vector2 = Vector2.ONE
var _tex_idle: Texture2D = null
var _tex_walk_right: Texture2D = null
var _tex_walk_left: Texture2D = null
var _tex_back: Texture2D = null
var _tex_attack: Texture2D = null
var _resolved_folder: String = ""
var collision_shape: CollisionShape2D = null
var sprite: Sprite2D = null

static func normalize_name(raw: String) -> String:
	var s := raw.to_lower().strip_edges()
	s = s.replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u").replace("ü", "u").replace("ñ", "n")
	return s

func _ready() -> void:
	y_sort_enabled = true
	add_to_group("students")
	current_state = initial_state
	_anim_time = randf() * TAU

	_setup_collision()
	_setup_sprite()
	if current_state == State.HAPPY and can_assist_in_combat:
		activate_combat_ally()
	queue_redraw()

func _load_tex_safe(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var res = ResourceLoader.load(path)
		if res is Texture2D:
			return res
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

func _setup_sprite() -> void:
	var s_canon := normalize_name(student_name)
	var folder_candidates: Array[String] = [
		"res://assets/characters/%s/" % s_canon,
	]
	if "mateo" in s_canon:
		folder_candidates.append("res://assets/characters/mateo_laboratorio/")
	elif "maria" in s_canon:
		folder_candidates.append("res://assets/characters/maria_cafeteria/")
	elif "valeria" in s_canon:
		folder_candidates.append("res://assets/characters/valeria_plaza/")
	elif "fernanda" in s_canon:
		folder_candidates.append("res://assets/characters/fernanda_biblioteca/")
	elif "diego" in s_canon:
		folder_candidates.append("res://assets/characters/diego_computo/")
	elif "sofia" in s_canon:
		folder_candidates.append("res://assets/characters/sofia_direccion/")
	elif "alejandro" in s_canon or "emiliano" in s_canon:
		folder_candidates.append("res://assets/characters/alejandro_cancha/")

	var extra_files: Array[String] = []
	if "maestro" in s_canon or "desinteres" in s_canon:
		extra_files.append("res://assets/characters/maestro_desinteres_redeemed/idle.png")
	elif "coordinador" in s_canon:
		extra_files.append("res://assets/characters/coordinador/normal_frente.png")
		extra_files.append("res://assets/characters/coordinador/hablando_frente.png")

	var name_hash := absi(s_canon.hash())
	if gender == Gender.STUDENT_F:
		var female_folders := [
			"res://assets/characters/valeria_plaza/",
			"res://assets/characters/maria_cafeteria/",
			"res://assets/characters/fernanda_biblioteca/",
			"res://assets/characters/sofia_direccion/"
		]
		folder_candidates.append(female_folders[name_hash % female_folders.size()])
	else:
		var male_folders := [
			"res://assets/characters/mateo_laboratorio/",
			"res://assets/characters/alejandro_cancha/",
			"res://assets/characters/diego_computo/"
		]
		folder_candidates.append(male_folders[name_hash % male_folders.size()])

	var tex: Texture2D = null
	for folder in folder_candidates:
		var candidate := _load_tex_safe(folder + "idle.png")
		if candidate != null:
			_resolved_folder = folder
			tex = candidate
			break
	if tex == null:
		for path in extra_files:
			tex = _load_tex_safe(path)
			if tex != null:
				break

	_tex_idle = tex
	if not _resolved_folder.is_empty():
		_tex_walk_right = _load_tex_safe(_resolved_folder + "walk_right.png")
		_tex_walk_left = _load_tex_safe(_resolved_folder + "walk_left.png")
		_tex_back = _load_tex_safe(_resolved_folder + "back.png")
		_tex_attack = _load_tex_safe(_resolved_folder + "attack.png")
	if _tex_walk_right == null: _tex_walk_right = _tex_idle
	if _tex_walk_left == null: _tex_walk_left = _tex_idle
	if _tex_back == null: _tex_back = _tex_idle
	if _tex_attack == null: _tex_attack = _tex_idle

	if tex:
		sprite = Sprite2D.new()
		sprite.texture = tex
		var max_dim := float(maxi(1, maxi(tex.get_width(), tex.get_height())))
		var s := 51.2 / max_dim
		_base_sprite_scale = Vector2(s, s)
		sprite.scale = _base_sprite_scale # Escala normalizada a 51.2 px sin importar resolución (512px o 2048px)
		sprite.position = Vector2(0, -22)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)

func activate_combat_ally() -> void:
	if not can_assist_in_combat:
		return
	if brain == null:
		brain = AllyBrainClass.new()
		brain.name = "AllyBrain"
		add_child(brain)
	brain.configure(self, level_ref, student_name)
	is_combat_ally = true

func take_ally_bump(hit_dir: Vector2) -> void:
	if _resist_timer > 0.0 or current_state != State.HAPPY:
		return
	_resist_timer = 0.8
	_squash_stretch = Vector2(1.25, 0.8)
	if hit_dir.length_squared() > 0.01:
		velocity = hit_dir.normalized() * 80.0
	var fx := _get_fx()
	var p = get_parent() if get_parent() else self
	if fx:
		fx.floating_text(p, global_position + Vector2(0, -44), "¡Resisto!", Color(0.55, 0.92, 1.0), 11)

func _setup_collision() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		collision_shape = CollisionShape2D.new()
		var capsule := CapsuleShape2D.new()
		capsule.radius = 10.0
		capsule.height = 24.0
		collision_shape.shape = capsule
		collision_shape.position = Vector2(0, -12)
		add_child(collision_shape)
	collision_layer = 32 # Capa 6: Aliados (no bloquea IA ni raycasts de paredes)
	collision_mask = 1

func _physics_process(delta: float) -> void:
	_anim_time += delta
	if _dialog_cooldown > 0.0:
		_dialog_cooldown -= delta
	if _resist_timer > 0.0:
		_resist_timer = maxf(0.0, _resist_timer - delta)

	match current_state:
		State.SAD:
			_process_sad_state(delta)
		State.RELIEVED:
			pass
		State.HAPPY:
			_process_happy_state(delta)

	# Interacción de proximidad con el jugador
	_check_player_proximity()

	if current_state != State.RELIEVED:
		_squash_stretch = _squash_stretch.lerp(Vector2.ONE, minf(1.0, 10.0 * delta))

	if sprite:
		var scale_tex := _base_sprite_scale
		if sprite.texture != null:
			var max_d := float(maxi(1, maxi(sprite.texture.get_width(), sprite.texture.get_height())))
			var ns := 51.2 / max_d
			scale_tex = Vector2(ns, ns)
		sprite.scale = scale_tex * _squash_stretch
		if current_state == State.SAD:
			sprite.modulate = Color(0.78, 0.78, 0.85)
			sprite.position.y = -18.0 + sin(_anim_time * 2.5) * 1.5
		elif current_state == State.HAPPY:
			sprite.modulate = Color(0.65, 0.92, 1.0) if _resist_timer > 0.0 else Color.WHITE
			var bob := absf(sin(_anim_time * 7.5)) * 3.5 if velocity.length_squared() > 225.0 else sin(_anim_time * 2.4) * 1.2
			sprite.position.y = -20.0 - bob
		else:
			sprite.position.y = -20.0

func _process_sad_state(delta: float) -> void:
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

	if not can_assist_in_combat:
		return
	if brain == null:
		activate_combat_ally()
	if brain != null and _resist_timer <= 0.0:
		if _pose_hold_timer > 0.0:
			_pose_hold_timer = maxf(0.0, _pose_hold_timer - delta)
		brain.level_ref = level_ref
		var act := brain.tick(delta)
		var target_vel: Vector2 = act.get("velocity", Vector2.ZERO)
		var accel := 720.0 if target_vel.length_squared() > velocity.length_squared() else 860.0
		velocity = velocity.move_toward(target_vel, accel * delta)
		if is_inside_tree() and PhysicsServer2D.body_get_space(get_rid()).is_valid():
			move_and_slide()
		else:
			position += velocity * delta
		_update_ally_pose_texture(act)

func _update_ally_pose_texture(act: Dictionary) -> void:
	if sprite == null:
		return
	var facing: Vector2 = act.get("facing", Vector2.DOWN)
	var is_attacking: bool = bool(act.get("attacking", false))
	if is_attacking and _tex_attack != null:
		sprite.texture = _tex_attack
		sprite.flip_h = (facing.x < -0.15)
		_pose_hold_timer = 0.08
		return

	if _pose_hold_timer > 0.0:
		return

	var next_tex: Texture2D = sprite.texture
	if velocity.length_squared() > 225.0:
		if absf(velocity.x) >= absf(velocity.y) * 1.25:
			next_tex = _tex_walk_right if velocity.x >= 0.0 else _tex_walk_left
		elif absf(velocity.y) >= absf(velocity.x) * 1.25:
			next_tex = _tex_back if velocity.y < 0.0 else _tex_idle
	elif facing.y < -0.55 and absf(facing.x) < 0.4:
		next_tex = _tex_back
	else:
		next_tex = _tex_idle

	if next_tex != null and next_tex != sprite.texture:
		sprite.flip_h = false
		sprite.texture = next_tex
		_pose_hold_timer = 0.12
	else:
		sprite.flip_h = false

## Pasa al alumno a estado feliz de inmediato (ej. cuota completada, disparo de virtud o jefe redimido)
func cheer_up() -> void:
	if current_state == State.SAD:
		_start_relieved_transition()
	elif current_state == State.HAPPY and can_assist_in_combat and not is_combat_ally:
		activate_combat_ally()

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
		activate_combat_ally()
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

func _is_female_player() -> bool:
	if is_inside_tree():
		var gs := get_node_or_null("/root/GameSettings")
		if gs and "selected_character" in gs:
			return int(gs.selected_character) == 1
	return false

func _speak_proximity_dialog() -> void:
	var phrase := ""
	var col := Color.WHITE
	var s_name_clean := normalize_name(student_name)
	var is_fem := _is_female_player()
	var char_data: Dictionary = StoryDataClass.get_secondary_character(s_name_clean, 1 if is_fem else 0) if ResourceLoader.exists("res://scripts/story_data.gd") else {}

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
			var pool: Array = PHRASES_HAPPY
			if is_fem:
				pool = PHRASES_HAPPY_PLAYER_F_BOTH if gender == Gender.STUDENT_F else PHRASES_HAPPY_PLAYER_F_MIXED
			phrase = pool[randi() % pool.size()]
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
# SOMBRA EN PERSPECTIVA 3/4 Y EFECTOS
# -----------------------------------------------------------------------------

func _draw() -> void:
	# Sombra elíptica en perspectiva 3/4 en la base de los pies
	var shadow_col := Color(0.06, 0.08, 0.12, 0.35)
	draw_rect(Rect2(-11, -4, 22, 6), shadow_col)
	draw_rect(Rect2(-9, -6, 18, 10), shadow_col)
