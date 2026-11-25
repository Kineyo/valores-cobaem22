extends Node2D
class_name FinalCeremony

## Escena Final de Ceremonia en la Cancha de Usos Múltiples (CEMSaD 22 ENTHAVI).
## Reúne a los alumnos rescatados y al Coordinador en el podio mientras
## suena el himno institucional, culminando con la entrega de medalla y el mensaje final.

signal restart_requested
signal menu_requested
signal ceremony_completed

enum Phase {
	SPEECH,
	WALKING,
	MEDAL,
	FINAL_MESSAGE
}

const COURT_MAP_PATH := "res://escenarios/nivel_6_cancha_usos_multiples.png"
const HIMNO_OGG_PATH := "res://assets/audio/himno.ogg"
const SFX_VICTORY_PATH := "res://assets/audio/victoria.wav"
const SFX_BLIP_PATH := "res://assets/audio/ataque.wav"
const THEME_PATH := "res://themes/pixel_theme.tres"

const FINAL_EXEMPLARY_TEXT := "Felicidades, ahora eres un alumno ejemplar. Gracias por jugar!"
const FINAL_EXEMPLARY_TEXT_F := "Felicidades, ahora eres una alumna ejemplar. Gracias por jugar!"

const PODIUM_POS := Vector2(1144, 368)
const COORDINATOR_POS := Vector2(1180, 360)
const HERO_START_POS := Vector2(260, 368)
const HERO_TARGET_POS := Vector2(1095, 368)
const SPEECH_CAMERA_POS := Vector2(940, 368)
const HERO_WALK_SPEED := 165.0

const COORDINATOR_SPEECH: Array[String] = [
	"Estimados estudiantes y docentes del CEMSaD 22 Enthavi: como su Coordinador, hoy nos reunimos en nuestra cancha con el corazón lleno de gratitud.",
	"Gracias a su valentía y apoyo mutuo, nuestra escuela es hoy un lugar de paz, respeto y armonía entre todos los alumnos.",
	"Donde antes el desgano, los rumores o el miedo apagaban los pasillos, hoy brillan la amistad sincera, la escucha y el juego limpio.",
	"Cada compañero aquí de pie recuerda que tender la mano a tiempo transforma una escuela entera en un hogar digno.",
	"Por defender nuestros valores y unir al plantel como verdadero campeón solidario, pasa al podio para recibir el reconocimiento del CEMSaD 22."
]
const COORDINATOR_SPEECH_F: Array[String] = [
	"Estimados estudiantes y docentes del CEMSaD 22 Enthavi: como su Coordinador, hoy nos reunimos en nuestra cancha con el corazón lleno de gratitud.",
	"Gracias a su valentía y apoyo mutuo, nuestra escuela es hoy un lugar de paz, respeto y armonía entre todos los alumnos.",
	"Donde antes el desgano, los rumores o el miedo apagaban los pasillos, hoy brillan la amistad sincera, la escucha y el juego limpio.",
	"Cada compañero aquí de pie recuerda que tender la mano a tiempo transforma una escuela entera en un hogar digno.",
	"Por defender nuestros valores y unir al plantel como verdadera campeona solidaria, pasa al podio para recibir el reconocimiento del CEMSaD 22."
]
const DIRECTOR_SPEECH: Array[String] = COORDINATOR_SPEECH

const RESCUED_STUDENTS_DATA: Array[Dictionary] = [
	{ "name": "Mateo", "primary": "res://assets/characters/mateo_laboratorio/idle.png", "fallback": "res://assets/characters/mateo_laboratorio/idle.png", "pos": Vector2(700, 285), "cheer": "¡Gracias por ayudarnos, amigo!", "cheer_f": "¡Gracias por ayudarnos, amiga!" },
	{ "name": "María", "primary": "res://assets/characters/maria_cafeteria/idle.png", "fallback": "res://assets/characters/maria_cafeteria/idle.png", "pos": Vector2(780, 285), "cheer": "¡Paz en todo el plantel!", "cheer_f": "¡Paz en todo el plantel!" },
	{ "name": "Valeria", "primary": "res://assets/characters/valeria_plaza/idle.png", "fallback": "res://assets/characters/valeria_plaza/idle.png", "pos": Vector2(860, 285), "cheer": "¡Orgullo CEMSaD 22!", "cheer_f": "¡Orgullo CEMSaD 22!" },
	{ "name": "Fernanda", "primary": "res://assets/characters/fernanda_biblioteca/idle.png", "fallback": "res://assets/characters/fernanda_biblioteca/idle.png", "pos": Vector2(940, 285), "cheer": "¡Bravo, campeón!", "cheer_f": "¡Bravo, campeona!" },
	{ "name": "Diego", "primary": "res://assets/characters/diego_computo/idle.png", "fallback": "res://assets/characters/diego_computo/idle.png", "pos": Vector2(700, 452), "cheer": "¡Compañerismo siempre!", "cheer_f": "¡Compañerismo siempre!" },
	{ "name": "Sofía", "primary": "res://assets/characters/sofia_direccion/idle.png", "fallback": "res://assets/characters/sofia_direccion/idle.png", "pos": Vector2(780, 452), "cheer": "¡Gracias por unirnos, compañero!", "cheer_f": "¡Gracias por unirnos, compañera!" },
	{ "name": "Alejandro", "primary": "res://assets/characters/alejandro_cancha/idle.png", "fallback": "res://assets/characters/alejandro_cancha/idle.png", "pos": Vector2(860, 452), "cheer": "¡Juego limpio en la cancha!", "cheer_f": "¡Juego limpio en la cancha!" },
]

const TEACHER_DATA: Dictionary = {
	"name": "Maestro",
	"primary": "res://assets/characters/maestro_desinteres_redeemed/idle.png",
	"fallback": "res://assets/characters/maestro_desinteres_redeemed/idle.png",
	"pos": Vector2(940, 452),
	"cheer": "¡Digno ejemplo estudiantil!",
	"cheer_f": "¡Digna representante estudiantil!"
}

const COORDINATOR_SPRITES: Dictionary = {
	"normal_frente": "res://assets/characters/coordinador/normal_frente.png",
	"hablando_frente": "res://assets/characters/coordinador/hablando_frente.png",
	"normal_izquierda": "res://assets/characters/coordinador/normal_izquierda.png",
	"hablando_izquierda": "res://assets/characters/coordinador/hablando_izquierda.png",
	"normal_derecha": "res://assets/characters/coordinador/normal_derecha.png",
	"hablando_derecha": "res://assets/characters/coordinador/hablando_derecha.png"
}

var current_phase: Phase = Phase.SPEECH
var stats_data: Dictionary = {}

var map_size: Vector2 = Vector2(1440, 900)
var background: Sprite2D = null
var entities_layer: Node2D = null
var camera: Camera2D = null

var director_node: Node2D = null
var coordinator_node: Node2D = null
var _coordinator_textures: Dictionary = {}
var teacher_node: Node2D = null
var rescued_student_nodes: Array[Node2D] = []
var crowd_nodes: Array[Node2D] = []

var hero_node: Node2D = null
var hero_sprite: Sprite2D = null
var _hero_tex_idle: Texture2D = null
var _hero_tex_walk_right: Texture2D = null
var _medal_node: Node2D = null

var _speech_index: int = 0
var _visible_chars: float = 0.0
var _is_typing: bool = false
var _chars_per_second: float = 42.0
var _anim_time: float = 0.0
var _phase_timer: float = 0.0
var _medal_tween: Tween = null
var _next_cheer_x: float = 460.0
var _cheer_idx: int = 0

var _ui_layer: CanvasLayer = null
var _speech_panel: PanelContainer = null
var _portrait_rect: TextureRect = null
var _speaker_label: Label = null
var _cert_status_label: Label = null
var _btn_export_pdf: Button = null
var generated_pdf_result: Dictionary = {}
const CertificateGeneratorClass := preload("res://scripts/certificate_generator.gd")
var _speech_text_label: RichTextLabel = null
var _speech_progress_label: Label = null
var _btn_next: Button = null
var _btn_skip: Button = null

var _final_overlay: ColorRect = null
var _final_center: CenterContainer = null
var _final_panel: PanelContainer = null
var _final_message_label: Label = null
var _final_stats_label: Label = null
var _btn_play_again: Button = null
var _btn_menu: Button = null
var _recipient_name_input: LineEdit = null
var _last_pointer_advance_ms: int = -1000

var _himno_player: AudioStreamPlayer = null
var _sfx_victory: AudioStreamPlayer = null
var _sfx_blip: AudioStreamPlayer = null
var _himno_started: bool = false

class PodiumProp extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(-24, -10, 48, 16), Color(0.06, 0.08, 0.12, 0.36))
		# Tarima y atril institucional
		draw_rect(Rect2(-18, -32, 36, 30), Color(0.32, 0.19, 0.12))
		draw_rect(Rect2(-18, -32, 36, 30), Color(0.14, 0.08, 0.05), false, 2.0)
		draw_rect(Rect2(-21, -36, 42, 6), Color(0.44, 0.27, 0.16))
		# Paño guinda y borde dorado
		draw_rect(Rect2(-13, -27, 26, 20), Color(0.48, 0.11, 0.19))
		draw_rect(Rect2(-13, -27, 26, 20), Color(0.84, 0.70, 0.34), false, 1.5)
		draw_circle(Vector2(0, -17), 4.0, Color(0.90, 0.78, 0.36))
		# Micrófono sobre el atril
		draw_line(Vector2(-8, -36), Vector2(-14, -44), Color(0.22, 0.24, 0.28), 2.0)
		draw_circle(Vector2(-15, -45), 2.5, Color(0.82, 0.85, 0.90))

class MedalProp extends Node2D:
	@export var radius: float = 8.0
	func _draw() -> void:
		draw_polygon(PackedVector2Array([
			Vector2(-radius * 0.55, -radius * 1.45),
			Vector2(radius * 0.55, -radius * 1.45),
			Vector2(radius * 0.35, -radius * 0.2),
			Vector2(-radius * 0.35, -radius * 0.2)
		]), [Color(0.56, 0.12, 0.22)])
		draw_circle(Vector2(0, 1.0), radius + 1.5, Color(0.55, 0.38, 0.08))
		draw_circle(Vector2(0, 0), radius, Color(0.96, 0.79, 0.24))
		draw_circle(Vector2(0, 0), radius * 0.72, Color(0.86, 0.64, 0.14))
		draw_circle(Vector2(-radius * 0.22, -radius * 0.24), radius * 0.26, Color(1.0, 0.96, 0.72, 0.9))

class MedalBadgeControl extends Control:
	func _draw() -> void:
		var c := size * 0.5
		# Cinta guinda y medalla dorada institucional
		draw_polygon(PackedVector2Array([
			c + Vector2(-13, -24), c + Vector2(13, -24),
			c + Vector2(8, -2), c + Vector2(-8, -2)
		]), [Color(0.54, 0.12, 0.22)])
		draw_line(c + Vector2(-4, -24), c + Vector2(-2, -4), Color(0.88, 0.74, 0.32), 2.0)
		draw_line(c + Vector2(4, -24), c + Vector2(2, -4), Color(0.88, 0.74, 0.32), 2.0)
		draw_circle(c + Vector2(0, 7), 17.0, Color(0.60, 0.42, 0.10))
		draw_circle(c + Vector2(0, 6), 15.0, Color(0.95, 0.78, 0.25))
		draw_circle(c + Vector2(0, 6), 11.0, Color(0.84, 0.62, 0.15))
		draw_circle(c + Vector2(-4, 2), 3.5, Color(1.0, 0.96, 0.75, 0.85))

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_world()
	_build_audio()
	_build_ui()
	_start_himno()
	_start_speech_phase()

func _exit_tree() -> void:
	if is_inside_tree() and get_viewport() and get_viewport().size_changed.is_connected(_adjust_mobile_layout):
		get_viewport().size_changed.disconnect(_adjust_mobile_layout)
	if _medal_tween and _medal_tween.is_valid():
		_medal_tween.kill()
	if _himno_player:
		if _himno_player.finished.is_connected(_on_local_himno_finished):
			_himno_player.finished.disconnect(_on_local_himno_finished)
		_himno_player.stop()
		_himno_player.stream = null

func setup_stats(data: Dictionary) -> void:
	stats_data = data.duplicate()
	_refresh_stats_label()

func _build_world() -> void:
	background = Sprite2D.new()
	background.name = "CourtBackground"
	background.centered = false
	var court_tex := _load_texture_direct(COURT_MAP_PATH)
	if court_tex:
		background.texture = court_tex
		map_size = Vector2(court_tex.get_width(), court_tex.get_height())
	add_child(background)

	entities_layer = Node2D.new()
	entities_layer.name = "Entities"
	entities_layer.y_sort_enabled = true
	add_child(entities_layer)

	var podium := PodiumProp.new()
	podium.name = "Podium"
	podium.position = PODIUM_POS
	entities_layer.add_child(podium)

	director_node = null

	_coordinator_textures.clear()
	for coord_key: String in COORDINATOR_SPRITES:
		var coord_tex := _load_texture_direct(str(COORDINATOR_SPRITES[coord_key]))
		if coord_tex:
			_coordinator_textures[coord_key] = coord_tex

	coordinator_node = _create_actor_node(
		"Coordinator",
		"Coordinador",
		COORDINATOR_POS,
		str(COORDINATOR_SPRITES["normal_frente"]),
		str(COORDINATOR_SPRITES["hablando_frente"]),
		54.0,
		Color(0.78, 0.88, 0.98)
	)
	entities_layer.add_child(coordinator_node)

	var is_fem_crowd := is_female_hero()
	for s_info: Dictionary in RESCUED_STUDENTS_DATA:
		var actor := _create_actor_node(
			str(s_info["name"]),
			str(s_info["name"]),
			s_info["pos"],
			str(s_info["primary"]),
			str(s_info["fallback"]),
			51.2,
			Color(0.90, 0.95, 1.0)
		)
		var s_cheer := str(s_info.get("cheer_f", s_info["cheer"])) if is_fem_crowd else str(s_info["cheer"])
		actor.set_meta("cheer_text", s_cheer)
		entities_layer.add_child(actor)
		rescued_student_nodes.append(actor)
		crowd_nodes.append(actor)

	teacher_node = _create_actor_node(
		str(TEACHER_DATA["name"]),
		str(TEACHER_DATA["name"]),
		TEACHER_DATA["pos"],
		str(TEACHER_DATA["primary"]),
		str(TEACHER_DATA["fallback"]),
		53.0,
		Color(0.84, 0.94, 0.82)
	)
	var t_cheer := str(TEACHER_DATA.get("cheer_f", TEACHER_DATA["cheer"])) if is_fem_crowd else str(TEACHER_DATA["cheer"])
	teacher_node.set_meta("cheer_text", t_cheer)
	entities_layer.add_child(teacher_node)
	crowd_nodes.append(teacher_node)

	_build_hero()

	_medal_node = MedalProp.new()
	_medal_node.name = "AwardMedal"
	_medal_node.visible = false
	_medal_node.z_index = 40
	entities_layer.add_child(_medal_node)

	camera = Camera2D.new()
	camera.name = "CeremonyCamera"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(map_size.x)
	camera.limit_bottom = int(map_size.y)
	camera.position = SPEECH_CAMERA_POS
	camera.enabled = true
	add_child(camera)
	if camera.is_inside_tree():
		camera.make_current()

func _build_hero() -> void:
	hero_node = Node2D.new()
	hero_node.name = "HeroCeremony"
	hero_node.position = HERO_START_POS
	hero_node.visible = false
	entities_layer.add_child(hero_node)

	var gs := _get_game_settings()
	var is_fem: bool = gs != null and gs.get("selected_character") == 1
	var folder := "res://assets/characters/Femenino/" if is_fem else "res://assets/characters/Masculino/"
	_hero_tex_idle = _load_first_valid([
		folder + "idle.png",
		folder + "frente.png",
		folder + "Capa 1.png",
		"res://assets/sprites/player_idle.png"
	])
	_hero_tex_walk_right = _load_first_valid([
		folder + "walk_right.png",
		folder + "walk_r.png",
		folder + "caminata_derecha.png",
		folder + "Capa 3.png",
		"res://assets/sprites/player_walk_right.png"
	])

	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-12, -2), Vector2(12, -2), Vector2(10, 4), Vector2(-10, 4)
	])
	shadow.color = Color(0.06, 0.08, 0.12, 0.34)
	hero_node.add_child(shadow)

	hero_sprite = Sprite2D.new()
	hero_sprite.name = "Sprite2D"
	hero_sprite.texture = _hero_tex_walk_right if _hero_tex_walk_right else _hero_tex_idle
	hero_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if hero_sprite.texture:
		var max_dim := float(maxi(1, maxi(hero_sprite.texture.get_width(), hero_sprite.texture.get_height())))
		var scale_f := 52.0 / max_dim
		hero_sprite.scale = Vector2(scale_f, scale_f)
	hero_sprite.position = Vector2(0, -22)
	hero_node.add_child(hero_sprite)

func _create_actor_node(
	node_name: String,
	display_label: String,
	pos: Vector2,
	primary_path: String,
	fallback_path: String,
	target_px: float,
	label_color: Color
) -> Node2D:
	var actor := Node2D.new()
	actor.name = node_name
	actor.position = pos
	actor.set_meta("base_pos", pos)
	actor.set_meta("phase_offset", randf() * TAU)

	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-11, -2), Vector2(11, -2), Vector2(9, 4), Vector2(-9, 4)
	])
	shadow.color = Color(0.06, 0.08, 0.12, 0.32)
	actor.add_child(shadow)

	var tex := _load_newest_texture(primary_path, fallback_path)
	var spr := Sprite2D.new()
	spr.name = "Sprite2D"
	spr.texture = tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if tex:
		var max_dim := float(maxi(1, maxi(tex.get_width(), tex.get_height())))
		var s := target_px / max_dim
		spr.scale = Vector2(s, s)
	spr.position = Vector2(0, -22)
	actor.add_child(spr)

	var lbl := Label.new()
	lbl.name = "NameLabel"
	lbl.text = display_label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-56, -58)
	lbl.custom_minimum_size = Vector2(112, 16)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", label_color)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.1, 0.95))
	lbl.add_theme_constant_override("outline_size", 2)
	actor.add_child(lbl)

	return actor

func _build_audio() -> void:
	_himno_player = AudioStreamPlayer.new()
	_himno_player.name = "HimnoPlayer"
	_himno_player.bus = "Music"
	_himno_player.volume_db = 0.0
	_himno_player.finished.connect(_on_local_himno_finished)
	add_child(_himno_player)

	_sfx_victory = AudioStreamPlayer.new()
	_sfx_victory.name = "SFXVictory"
	_sfx_victory.bus = "SFX"
	if ResourceLoader.exists(SFX_VICTORY_PATH):
		_sfx_victory.stream = load(SFX_VICTORY_PATH)
	_sfx_victory.volume_db = -4.0
	add_child(_sfx_victory)

	_sfx_blip = AudioStreamPlayer.new()
	_sfx_blip.name = "SFXBlip"
	_sfx_blip.bus = "SFX"
	if ResourceLoader.exists(SFX_BLIP_PATH):
		_sfx_blip.stream = load(SFX_BLIP_PATH)
	_sfx_blip.volume_db = -14.0
	add_child(_sfx_blip)

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "CeremonyUI"
	_ui_layer.layer = 15
	add_child(_ui_layer)

	var ui_root := Control.new()
	ui_root.name = "Root"
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(THEME_PATH):
		ui_root.theme = load(THEME_PATH)
	_ui_layer.add_child(ui_root)

	# Panel de discurso del Coordinador en la parte inferior
	_speech_panel = PanelContainer.new()
	_speech_panel.name = "SpeechPanel"
	_speech_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_speech_panel.offset_left = 40.0
	_speech_panel.offset_top = -156.0
	_speech_panel.offset_right = -40.0
	_speech_panel.offset_bottom = -16.0
	var panel_sb := _make_slate_panel_style(Color(0.09, 0.11, 0.15, 0.95), Color(0.68, 0.58, 0.36, 0.72), 6)
	_speech_panel.add_theme_stylebox_override("panel", panel_sb)
	_speech_panel.gui_input.connect(_on_speech_panel_gui_input)
	ui_root.add_child(_speech_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	_speech_panel.add_child(hbox)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(96, 96)
	portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_frame.add_theme_stylebox_override("panel", _make_slate_panel_style(Color(0.12, 0.15, 0.20, 1.0), Color(0.68, 0.58, 0.36, 0.7), 4))
	hbox.add_child(portrait_frame)

	_portrait_rect = TextureRect.new()
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait_rect.texture = _load_newest_texture("res://assets/characters/coordinador/hablando_frente.png", "res://assets/portraits/coordinador.png")
	portrait_frame.add_child(_portrait_rect)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 6)
	hbox.add_child(text_col)

	var header_row := HBoxContainer.new()
	text_col.add_child(header_row)

	_speaker_label = Label.new()
	_speaker_label.text = "Coordinador del Plantel CEMSaD 22 ENTHAVI"
	_speaker_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speaker_label.add_theme_font_size_override("font_size", 14)
	_speaker_label.add_theme_color_override("font_color", Color(0.92, 0.80, 0.44))
	header_row.add_child(_speaker_label)

	_speech_progress_label = Label.new()
	_speech_progress_label.text = "1 / 5"
	_speech_progress_label.add_theme_font_size_override("font_size", 11)
	_speech_progress_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.84))
	header_row.add_child(_speech_progress_label)

	_speech_text_label = RichTextLabel.new()
	_speech_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_speech_text_label.fit_content = false
	_speech_text_label.add_theme_font_size_override("normal_font_size", 14)
	_speech_text_label.add_theme_color_override("default_color", Color(0.94, 0.96, 0.99))
	text_col.add_child(_speech_text_label)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 8)
	text_col.add_child(btn_row)

	_btn_skip = Button.new()
	_btn_skip.text = "Saltar discurso"
	_btn_skip.custom_minimum_size = Vector2(124, 38)
	_btn_skip.pressed.connect(_start_walking_phase)
	UiJuice.attach_button(_btn_skip, _sfx_blip)
	btn_row.add_child(_btn_skip)

	_btn_next = Button.new()
	_btn_next.text = "Continuar" if MobileControls.is_touch_device() else "Continuar (Espacio)"
	_btn_next.custom_minimum_size = Vector2(158, 38)
	_btn_next.pressed.connect(_advance_speech)
	UiJuice.attach_button(_btn_next, _sfx_blip)
	btn_row.add_child(_btn_next)

	# Panel final centrado con la medalla y el mensaje de cierre
	_final_overlay = ColorRect.new()
	_final_overlay.name = "FinalOverlay"
	_final_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_final_overlay.color = Color(0.04, 0.06, 0.09, 0.56)
	_final_overlay.visible = false
	ui_root.add_child(_final_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_final_overlay.add_child(center)
	_final_center = center

	_final_panel = PanelContainer.new()
	_final_panel.name = "FinalPanel"
	_final_panel.custom_minimum_size = Vector2(520, 290)
	_final_panel.add_theme_stylebox_override("panel", _make_slate_panel_style(Color(0.09, 0.11, 0.15, 0.96), Color(0.84, 0.70, 0.36, 0.85), 8))
	center.add_child(_final_panel)

	var f_vbox := VBoxContainer.new()
	f_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	f_vbox.add_theme_constant_override("separation", 12)
	_final_panel.add_child(f_vbox)

	var badge_holder := CenterContainer.new()
	f_vbox.add_child(badge_holder)
	var medal_badge := MedalBadgeControl.new()
	medal_badge.custom_minimum_size = Vector2(56, 56)
	badge_holder.add_child(medal_badge)

	var inst_title := Label.new()
	inst_title.text = "CEREMONIA DE RECONOCIMIENTO · CEMSaD 22 ENTHAVI"
	inst_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inst_title.add_theme_font_size_override("font_size", 11)
	inst_title.add_theme_color_override("font_color", Color(0.82, 0.72, 0.44))
	f_vbox.add_child(inst_title)

	_final_message_label = Label.new()
	_final_message_label.name = "FinalMessageLabel"
	_final_message_label.text = get_final_exemplary_text()
	_final_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_final_message_label.custom_minimum_size = Vector2(460, 0)
	_final_message_label.add_theme_font_size_override("font_size", 18)
	_final_message_label.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0))
	f_vbox.add_child(_final_message_label)

	_final_stats_label = Label.new()
	_final_stats_label.name = "FinalStatsLabel"
	_final_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final_stats_label.add_theme_font_size_override("font_size", 12)
	_final_stats_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90))
	f_vbox.add_child(_final_stats_label)
	_refresh_stats_label()

	_cert_status_label = Label.new()
	_cert_status_label.name = "CertStatusLabel"
	_cert_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cert_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cert_status_label.custom_minimum_size = Vector2(460, 0)
	_cert_status_label.add_theme_font_size_override("font_size", 11)
	_cert_status_label.add_theme_color_override("font_color", Color(0.70, 0.92, 0.78))
	_cert_status_label.text = "Escribe tu nombre (opcional) y pulsa Guardar para generar tus PDFs (Carta y 5x7)."
	f_vbox.add_child(_cert_status_label)

	_recipient_name_input = LineEdit.new()
	_recipient_name_input.name = "RecipientNameInput"
	_recipient_name_input.placeholder_text = "Escribe tu nombre para el certificado (opcional)"
	_recipient_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recipient_name_input.custom_minimum_size = Vector2(360, 32)
	_recipient_name_input.max_length = 64
	f_vbox.add_child(_recipient_name_input)

	_btn_export_pdf = Button.new()
	_btn_export_pdf.name = "BtnExportCertPdf"
	_btn_export_pdf.text = "Guardar Certificado PDF (Carta y 5x7)"
	_btn_export_pdf.custom_minimum_size = Vector2(280, 38)
	_btn_export_pdf.pressed.connect(_generate_completion_pdfs)
	UiJuice.attach_button(_btn_export_pdf, _sfx_blip)
	f_vbox.add_child(_btn_export_pdf)

	var f_btns := HBoxContainer.new()
	f_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	f_btns.add_theme_constant_override("separation", 12)
	f_vbox.add_child(f_btns)

	_btn_play_again = Button.new()
	_btn_play_again.name = "BtnPlayAgainCeremony"
	_btn_play_again.text = "Jugar de nuevo"
	_btn_play_again.custom_minimum_size = Vector2(138, 38)
	_btn_play_again.pressed.connect(_on_restart_pressed)
	UiJuice.attach_button(_btn_play_again, _sfx_blip)
	f_btns.add_child(_btn_play_again)

	var btn_credits_cer := Button.new()
	btn_credits_cer.name = "BtnCreditsCeremony"
	btn_credits_cer.text = "Créditos (3:4)"
	btn_credits_cer.custom_minimum_size = Vector2(130, 38)
	btn_credits_cer.pressed.connect(_open_credits_overlay)
	UiJuice.attach_button(btn_credits_cer, _sfx_blip)
	f_btns.add_child(btn_credits_cer)

	_btn_menu = Button.new()
	_btn_menu.name = "BtnMenuCeremony"
	_btn_menu.text = "Menú principal"
	_btn_menu.custom_minimum_size = Vector2(138, 38)
	_btn_menu.pressed.connect(_on_menu_pressed)
	UiJuice.attach_button(_btn_menu, _sfx_blip)
	f_btns.add_child(_btn_menu)

	if is_inside_tree() and get_viewport():
		if not get_viewport().size_changed.is_connected(_adjust_mobile_layout):
			get_viewport().size_changed.connect(_adjust_mobile_layout)
	_adjust_mobile_layout()

func _open_credits_overlay() -> void:
	var cs_res := load("res://scenes/credits_screen.tscn") as PackedScene
	if cs_res == null:
		return
	var cs := cs_res.instantiate()
	var layer := CanvasLayer.new()
	layer.layer = 125
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(cs)
	cs.closed.connect(func():
		layer.queue_free()
		_start_himno()
	)
	add_child(layer)

func _adjust_mobile_layout() -> void:
	if not is_inside_tree() or get_viewport() == null:
		return
	var vp_size := get_viewport().get_visible_rect().size
	var insets := MobileControls.get_safe_insets_for_viewport(get_viewport(), 10.0)
	var avail_w := maxf(280.0, vp_size.x - insets.position.x - insets.size.x)
	var avail_h := maxf(220.0, vp_size.y - insets.position.y - insets.size.y)

	if _speech_panel:
		_speech_panel.offset_left = maxf(24.0, insets.position.x)
		_speech_panel.offset_right = -maxf(24.0, insets.size.x)
		_speech_panel.offset_bottom = -maxf(12.0, insets.size.y)
		_speech_panel.offset_top = -maxf(12.0, insets.size.y) - 144.0

	if _final_panel:
		var safe_s := clampf(minf(avail_w / 540.0, avail_h / 410.0), 0.62, 1.0)
		_final_panel.pivot_offset = _final_panel.size * 0.5
		_final_panel.scale = Vector2(safe_s, safe_s)

func _make_slate_panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 2
	sb.border_color = border
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	sb.content_margin_left = 16.0
	sb.content_margin_top = 12.0
	sb.content_margin_right = 16.0
	sb.content_margin_bottom = 12.0
	return sb

func _refresh_stats_label() -> void:
	if _final_stats_label == null:
		return
	var sec := int(stats_data.get("time", 0.0))
	var defeated := int(stats_data.get("defeated", 0))
	var time_str := "%d:%02d" % [sec / 60, sec % 60]
	_final_stats_label.text = "Antivalores redimidos: %d   ·   Alumnos reunidos: %d   ·   Tiempo: %s" % [defeated, rescued_student_nodes.size(), time_str]

func _start_himno() -> void:
	var gs := _get_game_settings()
	if gs and gs.has_method("play_himno_music"):
		gs.play_himno_music()
		_himno_started = true
		return
	var stream := _load_himno_stream()
	if stream and _himno_player:
		_himno_player.stream = stream
		_himno_player.play()
		_himno_started = true

func _on_local_himno_finished() -> void:
	if is_inside_tree() and _himno_player and _himno_player.stream:
		_himno_player.play()

func is_himno_playing() -> bool:
	var gs := _get_game_settings()
	if gs and "_music" in gs and gs._music and gs._music.playing:
		var himno_stream: Variant = gs.get("MUSIC_HIMNO")
		if himno_stream != null and gs._music.stream == himno_stream:
			return true
	return _himno_player != null and _himno_player.playing

func _start_speech_phase() -> void:
	current_phase = Phase.SPEECH
	_speech_index = 0
	if _speech_panel:
		_speech_panel.visible = true
	if _final_overlay:
		_final_overlay.visible = false
	if camera:
		camera.position = SPEECH_CAMERA_POS
	_show_speech_node(0)

func is_female_hero() -> bool:
	var gs := _get_game_settings()
	if gs != null and "selected_character" in gs:
		return int(gs.selected_character) == 1
	var ml := Engine.get_main_loop()
	if ml is SceneTree and (ml as SceneTree).root:
		var root_gs := (ml as SceneTree).root.get_node_or_null("GameSettings")
		if root_gs != null and "selected_character" in root_gs:
			return int(root_gs.selected_character) == 1
	return false

func get_final_exemplary_text() -> String:
	return FINAL_EXEMPLARY_TEXT_F if is_female_hero() else FINAL_EXEMPLARY_TEXT

func get_active_coordinator_speech() -> Array[String]:
	return COORDINATOR_SPEECH_F if is_female_hero() else COORDINATOR_SPEECH

func _show_speech_node(idx: int) -> void:
	_speech_index = idx
	var speech_lines := get_active_coordinator_speech()
	if _speech_index >= speech_lines.size():
		_start_walking_phase()
		return
	var line := speech_lines[_speech_index]
	_visible_chars = 0.0
	_is_typing = true
	if _speech_text_label:
		_speech_text_label.text = line
		_speech_text_label.visible_characters = 0
	if _speech_progress_label:
		_speech_progress_label.text = "%d / %d" % [_speech_index + 1, speech_lines.size()]
	if _btn_next:
		if MobileControls.is_touch_device():
			_btn_next.text = "Ir al podio" if _speech_index == speech_lines.size() - 1 else "Continuar"
		else:
			_btn_next.text = "Ir al podio (Espacio)" if _speech_index == speech_lines.size() - 1 else "Continuar (Espacio)"

func _advance_speech(from_pointer: bool = false) -> void:
	if current_phase != Phase.SPEECH:
		return
	if from_pointer:
		var now_ms := Time.get_ticks_msec()
		if (now_ms - _last_pointer_advance_ms) < 120:
			return
		_last_pointer_advance_ms = now_ms
	if _is_typing and _speech_text_label:
		_is_typing = false
		_speech_text_label.visible_characters = -1
		return
	_show_speech_node(_speech_index + 1)

func _start_walking_phase() -> void:
	if current_phase == Phase.WALKING or current_phase == Phase.MEDAL or current_phase == Phase.FINAL_MESSAGE:
		return
	current_phase = Phase.WALKING
	if _speech_panel:
		_speech_panel.visible = false
	if hero_sprite and _hero_tex_walk_right:
		hero_sprite.texture = _hero_tex_walk_right
	if hero_node:
		hero_node.position = HERO_START_POS
		hero_node.visible = true
	_next_cheer_x = 460.0
	_cheer_idx = 0
	var fx := _get_fx()
	if fx and coordinator_node:
		var rep_applause := "¡Un aplauso para nuestra representante!" if is_female_hero() else "¡Un aplauso para nuestro representante!"
		fx.floating_text(entities_layer, coordinator_node.position + Vector2(0, -64), rep_applause, Color(0.88, 0.94, 1.0), 12)

func _start_medal_phase() -> void:
	if current_phase == Phase.MEDAL or current_phase == Phase.FINAL_MESSAGE:
		return
	current_phase = Phase.MEDAL
	_phase_timer = 0.0
	if hero_sprite:
		if _hero_tex_walk_right:
			hero_sprite.texture = _hero_tex_walk_right
		elif _hero_tex_idle:
			hero_sprite.texture = _hero_tex_idle
		hero_sprite.position.y = -22.0
	if coordinator_node:
		coordinator_node.position = Vector2(1162, 362)
	if _medal_node and hero_node:
		var start_pos := PODIUM_POS + Vector2(6, -30)
		var target_pos := hero_node.position + Vector2(4, -18)
		_medal_node.position = start_pos
		_medal_node.scale = Vector2(1.2, 1.2)
		_medal_node.visible = true
		if _medal_tween and _medal_tween.is_valid():
			_medal_tween.kill()
		_medal_tween = create_tween()
		_medal_tween.tween_property(_medal_node, "position", (start_pos + target_pos) * 0.5 + Vector2(0, -28), 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_medal_tween.tween_property(_medal_node, "position", target_pos, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_medal_tween.parallel().tween_property(_medal_node, "scale", Vector2.ONE, 0.42)
	if _sfx_victory and _sfx_victory.stream:
		_sfx_victory.play()
	var fx := _get_fx()
	if fx and hero_node:
		fx.floating_text(entities_layer, hero_node.position + Vector2(0, -56), "¡Medalla al Mérito Escolar!", Color(1.0, 0.90, 0.36), 15)
		fx.burst(entities_layer, hero_node.position + Vector2(0, -22), Color(1.0, 0.88, 0.32), 18, 130.0)

func _show_final_message_phase() -> void:
	if current_phase == Phase.FINAL_MESSAGE:
		return
	current_phase = Phase.FINAL_MESSAGE
	if _final_message_label:
		_final_message_label.text = get_final_exemplary_text()
	_refresh_stats_label()
	if _cert_status_label:
		_cert_status_label.text = "Escribe tu nombre (opcional) y pulsa Guardar para generar tus PDFs (Carta y 5x7)."
	if _final_overlay:
		_final_overlay.visible = true
		_final_overlay.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_final_overlay, "modulate:a", 1.0, 0.35)
	if _btn_play_again and is_inside_tree():
		_btn_play_again.grab_focus()
	ceremony_completed.emit()

func _generate_completion_pdfs() -> void:
	var gs := _get_game_settings()
	var diff_str := "Normal"
	if gs:
		if gs.has_method("get_initial_difficulty_name"):
			diff_str = str(gs.get_initial_difficulty_name())
		elif gs.has_method("difficulty_name"):
			diff_str = str(gs.difficulty_name())
	var recipient_name := _recipient_name_input.text.strip_edges() if _recipient_name_input else ""
	generated_pdf_result = CertificateGeneratorClass.generate_certificates(diff_str, "", recipient_name)
	if _cert_status_label:
		if generated_pdf_result.get("success", false):
			_cert_status_label.text = "PDFs guardados (Carta y 5x7 · Modo %s):\n%s" % [diff_str, str(generated_pdf_result.get("carta_path", "")).get_base_dir()]
		else:
			_cert_status_label.text = "No se pudieron guardar los archivos PDF en el almacenamiento local."

func _process(delta: float) -> void:
	_anim_time += delta
	_animate_crowd()

	match current_phase:
		Phase.SPEECH:
			if _is_typing and _speech_text_label:
				var speech_lines := get_active_coordinator_speech()
				var line := speech_lines[_speech_index]
				_visible_chars += _chars_per_second * delta
				var count := int(_visible_chars)
				if count != _speech_text_label.visible_characters:
					_speech_text_label.visible_characters = count
					if count % 4 == 0 and count < line.length() and _sfx_blip and _sfx_blip.stream:
						_sfx_blip.pitch_scale = randf_range(1.15, 1.3)
						_sfx_blip.play()
				if count >= line.length():
					_speech_text_label.visible_characters = -1
					_is_typing = false
			if camera:
				camera.position = camera.position.lerp(SPEECH_CAMERA_POS, minf(1.0, 4.0 * delta))

		Phase.WALKING:
			if hero_node:
				hero_node.position.x = minf(HERO_TARGET_POS.x, hero_node.position.x + HERO_WALK_SPEED * delta)
				if hero_sprite:
					var step_wave := sin(_anim_time * 12.0)
					hero_sprite.position.y = -22.0 - absf(step_wave) * 3.0
					if _hero_tex_walk_right and hero_sprite.texture != _hero_tex_walk_right:
						hero_sprite.texture = _hero_tex_walk_right
				if camera:
					var cam_target := Vector2(clampf(hero_node.position.x + 120.0, 400.0, 1040.0), 368.0)
					camera.position = camera.position.lerp(cam_target, minf(1.0, 4.5 * delta))
				if hero_node.position.x >= _next_cheer_x and _cheer_idx < crowd_nodes.size():
					var cheer_actor := crowd_nodes[_cheer_idx]
					var cheer_msg: String = str(cheer_actor.get_meta("cheer_text", "¡Felicidades!"))
					var fx := _get_fx()
					if fx:
						fx.floating_text(entities_layer, cheer_actor.position + Vector2(0, -64), cheer_msg, Color(0.95, 0.98, 0.72), 11)
					_cheer_idx += 1
					_next_cheer_x += 75.0
				if hero_node.position.x >= HERO_TARGET_POS.x - 0.5:
					_start_medal_phase()

		Phase.MEDAL:
			_phase_timer += delta
			if camera:
				camera.position = camera.position.lerp(Vector2(1040.0, 368.0), minf(1.0, 4.0 * delta))
			if _phase_timer >= 2.2:
				_show_final_message_phase()

		Phase.FINAL_MESSAGE:
			if _final_center != null and _recipient_name_input != null:
				var kb_h := DisplayServer.virtual_keyboard_get_height() if DisplayServer.has_method("virtual_keyboard_get_height") else 0
				if _recipient_name_input.has_focus() and kb_h > 0:
					_final_center.position.y = -minf(120.0, float(kb_h) * 0.35)
				else:
					_final_center.position.y = 0.0

func _animate_crowd() -> void:
	_update_coordinator_sprite()
	var amp := 2.8 if (current_phase == Phase.WALKING or current_phase == Phase.MEDAL) else 1.1
	var freq := 6.5 if (current_phase == Phase.WALKING or current_phase == Phase.MEDAL) else 2.6
	for actor in crowd_nodes:
		if not is_instance_valid(actor):
			continue
		var spr := actor.get_node_or_null("Sprite2D") as Sprite2D
		if spr:
			var offset := float(actor.get_meta("phase_offset", 0.0))
			spr.position.y = -22.0 - absf(sin(_anim_time * freq + offset)) * amp

func _update_coordinator_sprite() -> void:
	if coordinator_node == null or not is_instance_valid(coordinator_node) or _coordinator_textures.is_empty():
		return
	var spr := coordinator_node.get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		return

	var facing := "frente"
	var talking := false

	match current_phase:
		Phase.SPEECH:
			facing = "frente" if _speech_index == 0 else "izquierda"
			talking = _is_typing or (sin(_anim_time * 5.0) > 0.0)
		Phase.WALKING:
			facing = "izquierda"
			talking = sin(_anim_time * 7.5) >= 0.0
		Phase.MEDAL:
			facing = "izquierda"
			talking = sin(_anim_time * 8.0) >= -0.2
		Phase.FINAL_MESSAGE:
			facing = "frente"
			talking = sin(_anim_time * 4.5) >= 0.0

	var pose_key := ("hablando_" if talking else "normal_") + facing
	if not _coordinator_textures.has(pose_key):
		pose_key = "normal_" + facing
	if not _coordinator_textures.has(pose_key):
		return

	var next_tex := _coordinator_textures[pose_key] as Texture2D
	if next_tex and spr.texture != next_tex:
		spr.texture = next_tex
		var max_dim := float(maxi(1, maxi(next_tex.get_width(), next_tex.get_height())))
		var s := 54.0 / max_dim
		spr.scale = Vector2(s, s)

func _on_speech_panel_gui_input(event: InputEvent) -> void:
	if current_phase != Phase.SPEECH:
		return
	var is_real_mouse: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION
	var is_real_touch: bool = event is InputEventScreenTouch and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION
	if is_real_mouse or is_real_touch:
		_advance_speech(true)
		_speech_panel.accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if current_phase != Phase.SPEECH:
		return
	var accept_pressed := false
	var from_pointer := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			accept_pressed = true
		elif event.keycode == KEY_ESCAPE:
			_start_walking_phase()
			get_viewport().set_input_as_handled()
			return
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_X]:
			accept_pressed = true
		elif event.button_index == JOY_BUTTON_B:
			_start_walking_phase()
			get_viewport().set_input_as_handled()
			return
	elif (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION) or (event is InputEventScreenTouch and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION):
		accept_pressed = true
		from_pointer = true

	if accept_pressed:
		_advance_speech(from_pointer)
		if is_inside_tree() and get_viewport():
			get_viewport().set_input_as_handled()

func _on_restart_pressed() -> void:
	restart_requested.emit()

func _on_menu_pressed() -> void:
	menu_requested.emit()

func _get_game_settings() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameSettings")
	return null

func _get_fx() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Fx")
	return null

func _load_himno_stream() -> AudioStream:
	if ResourceLoader.exists(HIMNO_OGG_PATH):
		var ogg_stream := load(HIMNO_OGG_PATH) as AudioStream
		if ogg_stream != null:
			return ogg_stream
	if FileAccess.file_exists(HIMNO_OGG_PATH):
		return AudioStreamOggVorbis.load_from_file(ProjectSettings.globalize_path(HIMNO_OGG_PATH))
	return null

func _load_first_valid(paths: Array) -> Texture2D:
	for raw_path in paths:
		var tex := _load_texture_direct(str(raw_path))
		if tex != null:
			return tex
	return null

func _load_newest_texture(primary_path: String, fallback_path: String) -> Texture2D:
	var best_path := primary_path
	var p_global := ProjectSettings.globalize_path(primary_path)
	var f_global := ProjectSettings.globalize_path(fallback_path)
	var p_exists := FileAccess.file_exists(p_global)
	var f_exists := FileAccess.file_exists(f_global)

	if p_exists and f_exists:
		if FileAccess.get_modified_time(f_global) > FileAccess.get_modified_time(p_global):
			best_path = fallback_path
	elif not p_exists and f_exists:
		best_path = fallback_path

	var tex := _load_texture_direct(best_path)
	if tex == null:
		var other_path := fallback_path if best_path == primary_path else primary_path
		tex = _load_texture_direct(other_path)
	return tex

func _load_texture_direct(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res := load(path)
		if res is Texture2D:
			return res
	var global_p := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_p):
		var img := Image.load_from_file(global_p)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null
