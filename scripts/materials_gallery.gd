extends Control
class_name MaterialsGallery

## Galería / Enciclopedia de Materiales del Juego accesible desde el menú de tres puntos (⋮).
## Permite explorar sin jugar toda la campaña: Personajes, Canciones (Jukebox),
## Escenarios, Enemigos y Jefes, y Habilidades e Ítems, con descripción, ubicación y simbolismo.

signal closed

const GameSettingsScript := preload("res://scripts/game_settings.gd")
const BossRendererClass := preload("res://scripts/boss_renderer.gd")
const CATEGORY_ORDER := ["Personajes", "Canciones", "Escenarios", "Enemigos y Jefes", "Habilidades e Ítems", "Videos"]

const COLOR_MAP_PREVIEW := {
	"esperanza": Color(1.0, 0.88, 0.25),
	"virtue_shot": Color(0.35, 0.92, 1.0),
	"focus_graze": Color(1.0, 0.30, 0.45),
	"empathy_pulse": Color(0.45, 0.95, 1.0),
	"heart": Color(1.0, 0.35, 0.50),
	"shield": Color(0.35, 0.85, 1.0),
}

var _current_category: String = "Personajes"
var _current_index: int = 0
var _current_pose: String = "idle"
var _jukebox_char: int = 0
var _jukebox_diff: int = 1
var _is_preview_playing: bool = false
var _anim_time: float = 0.0
var _categories_cache: Dictionary = {}

var _panel: PanelContainer
var _tab_buttons: Dictionary = {}
var _item_list_vbox: VBoxContainer
var _list_buttons: Array[Button] = []
var _preview_tex: TextureRect
var _preview_custom: Control
var _pose_row: HBoxContainer
var _pose_buttons: Dictionary = {}
var _jukebox_row: VBoxContainer
var _btn_play_song: Button
var _btn_voice_toggle: Button
var _btn_diff_cycle: Button
var _preview_video: VideoStreamPlayer
var _video_row: HBoxContainer
var _btn_play_video: Button
var _btn_fullscreen_video: Button
var _is_video_playing: bool = false
var _video_fs_overlay: Control
var _video_fs_player: VideoStreamPlayer
var _video_fs_aspect: AspectRatioContainer
var _video_fs_btn_pause: Button
var _is_video_fullscreen: bool = false
var _prev_window_mode: int = -1
var _detail_title: Label
var _detail_rich: RichTextLabel
var _btn_close: Button

func _ready() -> void:
	name = "MaterialsGallery"
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 120
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var gs := _get_gs()
	if gs:
		_jukebox_char = clampi(int(gs.get("selected_character")), 0, 1)
		_jukebox_diff = clampi(int(gs.get("difficulty")), 0, 2)

	_categories_cache = get_all_categories()
	_build_ui()
	_select_category(CATEGORY_ORDER[0])

	var vp := get_viewport()
	if vp and not vp.size_changed.is_connected(_update_safe_layout):
		vp.size_changed.connect(_update_safe_layout)
	_update_safe_layout()

func _exit_tree() -> void:
	close_video_fullscreen()
	var vp := get_viewport()
	if vp and vp.size_changed.is_connected(_update_safe_layout):
		vp.size_changed.disconnect(_update_safe_layout)

func _get_gs() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/GameSettings")

static func get_all_categories() -> Dictionary:
	var chars := [
		{
			"name": "Héroe Escolar (Masculino)",
			"folder": "res://assets/characters/Masculino/",
			"portrait": "res://assets/portraits/player_masculino.png",
			"what": "Protagonista estudiante con uniforme oficial del COBAEM CEMSaD 22 (suéter guinda y pantalón gris).",
			"where": "Jugable desde el Menú Inicial en todos los escenarios exteriores y salones de clases (1 al 6).",
			"symbolizes": "La iniciativa personal, el coraje cotidiano y el compromiso juvenil para defender la paz escolar."
		},
		{
			"name": "Heroína Escolar (Femenino)",
			"folder": "res://assets/characters/Femenino/",
			"portrait": "res://assets/portraits/player_femenino.png",
			"what": "Protagonista estudiante con uniforme institucional femenino (suéter guinda y falda tableada).",
			"where": "Seleccionable en la pantalla de personaje; recorre toda la campaña escolar completa.",
			"symbolizes": "La igualdad de liderazgo, la valentía serena y la voz firme contra cualquier forma de exclusión."
		},
		{
			"name": "Mateo",
			"folder": "res://assets/characters/mateo_laboratorio/",
			"portrait": "res://assets/portraits/mateo_laboratorio.png",
			"what": "Alumno curioso del taller científico que sufre desaliento al inicio de la jornada.",
			"where": "Escenario 1 (Acceso / Edificio D) y Salón 1 (Laboratorio de Usos Múltiples); apoya como aliado en la Cancha.",
			"symbolizes": "La curiosidad académica, el rigor científico y el valor de atreverse a preguntar sin miedo a la burla."
		},
		{
			"name": "María",
			"folder": "res://assets/characters/maria_cafeteria/",
			"portrait": "res://assets/portraits/maria_cafeteria.png",
			"what": "Compañera solidaria de la cafetería escolar que comparte alimento y escucha.",
			"where": "Escenario 2 (Edificio A — Cafetería) y Salón 2 (Aula 1); asiste en el rescate final.",
			"symbolizes": "La empatía cotidiana, la hospitalidad y el apoyo silencioso hacia quien almuerza solo."
		},
		{
			"name": "Valeria",
			"folder": "res://assets/characters/valeria_plaza/",
			"portrait": "res://assets/portraits/valeria_plaza.png",
			"what": "Estudiante de escolta y oratoria con banda de liderazgo estudiantil.",
			"where": "Escenario 3 (Plaza Cívica y Escalinata Sur) y Salón 3 (Sala Cívica); combate como aliada.",
			"symbolizes": "El civismo, la inclusión y la igualdad de trato sin distinción de origen o estatus."
		},
		{
			"name": "Fernanda",
			"folder": "res://assets/characters/fernanda_biblioteca/",
			"portrait": "res://assets/portraits/fernanda_biblioteca.png",
			"what": "Alumna lectora de la biblioteca escolar víctima de rumores digitales.",
			"where": "Escenario 4 (Edificio B — Biblioteca) y Salón 4 (Biblioteca Escolar).",
			"symbolizes": "La sabiduría, la veracidad y el rechazo consciente a la difamación y el ciberacoso."
		},
		{
			"name": "Diego",
			"folder": "res://assets/characters/diego_computo/",
			"portrait": "res://assets/portraits/diego_computo.png",
			"what": "Estudiante de informática comprometido con proyectos auténticos y ética digital.",
			"where": "Escenario 5 (Edificio C — Cómputo y Dirección) y Salón 5 (Taller de Cómputo).",
			"symbolizes": "La ciudadanía digital responsable, la honestidad intelectual y el mérito del esfuerzo propio."
		},
		{
			"name": "Sofía",
			"folder": "res://assets/characters/sofia_direccion/",
			"portrait": "res://assets/portraits/sofia_direccion.png",
			"what": "Representante estudiantil organizada que coordina la respuesta pacífica del plantel.",
			"where": "Edificio C (Dirección), pasillos cívicos y escuadrón aliado frente a Titanor en Escenario 6.",
			"symbolizes": "El respeto institucional, la organización justa y el diálogo mediador en la comunidad."
		},
		{
			"name": "Alejandro",
			"folder": "res://assets/characters/alejandro_cancha/",
			"portrait": "res://assets/portraits/alejandro_cancha.png",
			"what": "Deportista de la cancha múltiple que defiende a los compañeros de menor grado.",
			"where": "Escenario 6 (Cancha de Usos Múltiples) y Salón 6 (Aula Magna Deportiva).",
			"symbolizes": "El juego limpio (Fair Play), la fraternidad deportiva y el usar la fuerza únicamente para proteger."
		},
		{
			"name": "Coordinador Escolar",
			"folder": "res://assets/characters/coordinador/",
			"custom_idle": "res://assets/characters/coordinador/normal_frente.png",
			"portrait": "res://assets/portraits/coordinador.png",
			"what": "Autoridad docente guía del CEMSaD 22 que encabeza los honores y reconoce el esfuerzo estudiantil.",
			"where": "Prólogo narrativo y Escena Final de Ceremonia en el podio de la cancha de básquetbol.",
			"symbolizes": "La mentoría responsable, el acompañamiento institucional y la unidad entre docentes y alumnos."
		},
		{
			"name": "Maestro Desinterés (Redimido)",
			"folder": "res://assets/characters/maestro_desinteres_redeemed/",
			"portrait": "res://assets/portraits/maestro_desinteres_redeemed.png",
			"what": "Docente que inicialmente ignoraba las señales de abuso y decide volver a escuchar a sus grupos.",
			"where": "Al redimirse dentro de cualquiera de los Salones Interiores (Salones 1 al 6).",
			"symbolizes": "La transformación de la indiferencia en escucha activa y vocación educativa presente."
		},
	]

	var songs := []
	for s_entry in GameSettingsScript.SOUNDTRACK_CATALOG:
		songs.append({
			"id": s_entry["id"],
			"name": s_entry["title"],
			"bpm": s_entry["bpm"],
			"what": s_entry["desc"] + " (%d BPM · Varía entre Masc/Fem y Fácil/Normal/Difícil)." % int(s_entry["bpm"]),
			"where": s_entry["where"],
			"symbolizes": "Ambientación musical escolar estilo Touhou/retro que refuerza el pulso emocional de cada etapa."
		})

	var stages := [
		{ "name": "1. Acceso, Caseta C.V. y Edif. D", "img": "res://escenarios/nivel_1_acceso_laboratorio.png", "what": "Acceso peatonal, plaza inicial y Laboratorio D a escala real (183 m², 1 m = 40 px).", "where": "Escenario Exterior 1/6 (Nivel inicial de campaña).", "symbolizes": "Cruzar el umbral del miedo hacia la participación activa." },
		{ "name": "Salón 1: Laboratorio de Usos Múltiples", "img": "res://escenarios/salones/salon_1_laboratorio.png", "what": "Laboratorio escolar con mesas de práctica, tabla periódica y equipo de ciencias (20×12 m).", "where": "Salón Interior 1/6 — Puerta en Edificio D.", "symbolizes": "El descubrimiento seguro donde equivocarse sirve para aprender." },
		{ "name": "2. Edificio A — Cafetería y Aulas", "img": "res://escenarios/nivel_2_edificio_a_cafeteria.png", "what": "Corredor principal, salones planta baja y cafetería escolar (339 m²).", "where": "Escenario Exterior 2/6.", "symbolizes": "Convivencia limpia, compartir la mesa y cuidar los espacios comunes." },
		{ "name": "Salón 2: Aula 1 — Edificio A", "img": "res://escenarios/salones/salon_2_aula_a.png", "what": "Salón de clases tradicional con pupitres organizados y pizarrón central (20×12 m).", "where": "Salón Interior 2/6 — Puerta en Edificio A.", "symbolizes": "El diálogo en clase frente al murmullo indiferente." },
		{ "name": "3. Plaza Cívica y Escalinata Sur", "img": "res://escenarios/nivel_3_plaza_civica_escalinata.png", "what": "Explanada cívica central con asta bandera y escalinatas (748 m²).", "where": "Escenario Exterior 3/6.", "symbolizes": "Igualdad cívica y orgullo comunitario de Temoaya y COBAEM." },
		{ "name": "Salón 3: Sala Cívica de Asambleas", "img": "res://escenarios/salones/salon_3_sala_civica.png", "what": "Auditorio de asambleas estudiantiles con podio central (20×12 m).", "where": "Salón Interior 3/6 — Puerta en Plaza Cívica.", "symbolizes": "La palabra respetuosa y la escucha en comunidad." },
		{ "name": "4. Edificio B — Biblioteca y Aulas", "img": "res://escenarios/nivel_4_edificio_b.png", "what": "Pasillo tecnológico y acceso al edificio de biblioteca (280 m²).", "where": "Escenario Exterior 4/6.", "symbolizes": "Información veraz frente a rumores anónimos." },
		{ "name": "Salón 4: Biblioteca Escolar", "img": "res://escenarios/salones/salon_4_biblioteca.png", "what": "Sala de lectura con estanterías y mesas de estudio (20×12 m).", "where": "Salón Interior 4/6 — Puerta en Edificio B.", "symbolizes": "Pensamiento crítico y paz intelectual." },
		{ "name": "5. Edificio C — Cómputo y Dirección", "img": "res://escenarios/nivel_5_edificio_c_computo.png", "what": "Área administrativa, talleres digitales y patio contiguo (625 m²).", "where": "Escenario Exterior 5/6.", "symbolizes": "Integridad académica y ética en el entorno digital." },
		{ "name": "Salón 5: Taller de Cómputo", "img": "res://escenarios/salones/salon_5_computo.png", "what": "Laboratorio equipado con mesas de cómputo (20×12 m).", "where": "Salón Interior 5/6 — Puerta en Edificio C.", "symbolizes": "Uso creativo y honesto de la tecnología." },
		{ "name": "6. Cancha de Usos Múltiples", "img": "res://escenarios/nivel_6_cancha_usos_multiples.png", "what": "Cancha techada de básquetbol y gradas de convivencia (540 m²).", "where": "Escenario Exterior 6/6 (Clímax Final).", "symbolizes": "Juego limpio, unión total y erradicación definitiva del bullying." },
		{ "name": "Salón 6: Aula Magna Deportiva", "img": "res://escenarios/salones/salon_6_gimnasio.png", "what": "Salón deportivo de activación física y salud escolar (20×12 m).", "where": "Salón Interior 6/6 — Puerta en Cancha Múltiple.", "symbolizes": "Trabajo en equipo y respeto corporal." },
	]

	var enemies := [
		{ "name": "Grosería (Antivalor Base)", "kind": "sprite", "tex": "res://assets/sprites/enemigo_groseria.png", "what": "Antivalor ágil e impulsivo que salta buscando intimidar en pasillos.", "where": "Todos los escenarios exteriores e interiores.", "symbolizes": "Faltas de respeto verbales; al redimirse proclama «¡Amabilidad!»." },
		{ "name": "Acoso (Antivalor Acechante)", "kind": "sprite", "tex": "res://assets/sprites/enemigo_acoso.png", "what": "Sombra vigilante con amplio rango de alerta en grupo.", "where": "Patios, bibliotecas y salones cerrados.", "symbolizes": "Hostigamiento persistente; al redimirse proclama «¡Respeto!»." },
		{ "name": "Bullying (Antivalor Pesado)", "kind": "sprite", "tex": "res://assets/sprites/enemigo_bullying.png", "what": "Antivalor territorial resistente (doble vida en Difícil).", "where": "Zonas de conflicto y rondas avanzadas.", "symbolizes": "Abuso físico o exclusión grupal; al redimirse proclama «¡Empatía!»." },
		{ "name": "Apatyx, Espectro del Desgano", "kind": "boss", "boss_type": BossData.BossType.APATIA, "what": "Jefe 1: genera charcos de desánimo y vórtices espirales.", "where": "Escenario 1 — Acceso y Laboratorio D.", "symbolizes": "La desmotivación escolar; al redimirse devuelve «¡Entusiasmo y Curiosidad!»." },
		{ "name": "Desperdicius, Titán del Desperdicio", "kind": "boss", "boss_type": BossData.BossType.DESPERDICIO, "what": "Jefe 2: lanza abanicos de desechos y pisotones.", "where": "Escenario 2 — Cafetería Edif. A.", "symbolizes": "El descuido ambiental y material; se redime en «¡Responsabilidad!»." },
		{ "name": "Superbus, Heraldo de Arrogancia", "kind": "boss", "boss_type": BossData.BossType.INTOLERANCIA, "what": "Jefe 3: emite anillos de rechazo y descargas cruzadas.", "where": "Escenario 3 — Plaza Cívica.", "symbolizes": "La discriminación por prejuicios; se redime en «¡Tolerancia!»." },
		{ "name": "Ciber-Murmullus", "kind": "boss", "boss_type": BossData.BossType.CIBERACOSO, "what": "Jefe 4: enjambres teledirigidos y teletransporte Glitch.", "where": "Escenario 4 — Edificio B y Biblioteca.", "symbolizes": "El ciberacoso anónimo; se redime en «¡Empatía Digital y Honestidad!»." },
		{ "name": "Plagiatrix, Señor de la Falsedad", "kind": "boss", "boss_type": BossData.BossType.PLAGIO, "what": "Jefe 5: copias espejo y barrera reflectante de atajos.", "where": "Escenario 5 — Edificio C y Cómputo.", "symbolizes": "La deshonestidad académica; se redime en «¡Integridad Académica!»." },
		{ "name": "Maestro Desinterés", "kind": "sprite", "tex": "res://assets/characters/maestro_desinteres/idle.png", "what": "Jefe de Salón: proyectiles temáticos por aula y niebla de inacción.", "where": "Salones Interiores 1 al 6.", "symbolizes": "La omisión adulta ante el conflicto; se redime en «¡Compromiso y Escucha!»." },
		{ "name": "Titanor, Coloso del Bullying", "kind": "boss", "boss_type": BossData.BossType.BULLYING, "what": "Jefe Final Touhou Danmaku: 4 cartas de hechizo, clones, jaulas convergentes y fase 1 HP.", "where": "Escenario 6 — Cancha de Usos Múltiples.", "symbolizes": "La suma del acoso escolar; al quebrarse a 1 HP enfrenta a los 8 Corazones de Valores." },
	]

	var skills := [
		{ "id": "virtue_shot", "name": "Disparo de Virtud (Espacio / Stick Der)", "what": "Proyectil luminoso de diálogo positivo que neutraliza antivalores y alegra alumnos tristes sin violencia.", "where": "Disponible desde el inicio en todos los niveles.", "symbolizes": "El poder de la palabra constructiva y el diálogo firme." },
		{ "id": "focus_graze", "name": "Modo Enfoque y Graze (Shift / FOCUS)", "what": "Reduce velocidad al 52% mostrando la micro-hitbox de 5.5 px; rozar balas suma Graze (impulso cada 12, vida cada 35).", "where": "Mecánica táctica estilo Touhou activa siempre, indispensable contra Titanor.", "symbolizes": "La serenidad y autocontrol bajo presión extrema." },
		{ "id": "empathy_pulse", "name": "Pulso de Empatía (E / PULSO)", "what": "Onda expansiva cada 10s que ralentiza antivalores cercanos y alivia a estudiantes en un radio de 140 px.", "where": "Habilidad equipada en todos los escenarios.", "symbolizes": "La escucha empática que desarma la agresividad." },
		{ "id": "esperanza", "name": "Ventaja Esperanza (Ítem Dorado [Q])", "what": "Durante 15 segundos limpia toda la niebla, elimina clones falsos y deja al Jefe Final indefenso.", "where": "Aparece en el campo al rescatar alumnos o durante el duelo contra Titanor.", "symbolizes": "La esperanza colectiva que disipa la intimidación y el miedo." },
		{ "id": "heart", "name": "Corazón de Aliento (Ítem [Q])", "what": "Restaura +1 corazón de salud cuando el jugador está herido.", "where": "Entregado por estudiantes alegres o recogido en zonas seguras.", "symbolizes": "La gratitud y apoyo recíproco entre compañeros." },
		{ "id": "shield", "name": "Escudo de Resiliencia (Ítem [Q])", "what": "Otorga 4 segundos de invulnerabilidad temporal frente a proyectiles hostiles.", "where": "Drops tácticos dentro de salones y patios difíciles.", "symbolizes": "La fortaleza emocional frente a ataques verbales o digitales." },
	]

	var videos := [
		{
			"name": "Escena Final: Batalla vs Titanor y Corazones",
			"video_ogv": "res://assets/video/escena_final_corazones.ogv",
			"video_mp4": "res://assets/video/escena_final_corazones.mp4",
			"what": "Grabación real del combate final contra Titanor, su quiebre a 1 HP y toda la escena estilo Undertale con los 8 corazones de colores y música Finale.",
			"where": "assets/video/escena_final_corazones.ogv y .mp4 (y en campaña al llevar a Titanor a 1 HP).",
			"symbolizes": "La victoria colectiva de los valores escolares sobre el bullying."
		},
		{
			"name": "Créditos Oficiales README (Video 3:4)",
			"video_ogv": "res://assets/video/creditos_readme_3x4.ogv",
			"video_mp4": "res://assets/video/creditos_readme_3x4.mp4",
			"what": "Video vertical en proporción exacta 3:4 (540×720) con toda la ficha del proyecto e historia extraída de README.md.",
			"where": "Botón 'Créditos' del Menú Inicial, Ceremonia Final y assets/video/creditos_readme_3x4.*",
			"symbolizes": "Reconocimiento técnico y comunitario del plantel CEMSaD 22 ENTHAVI."
		},
		{
			"name": "Video de Presentación del Proyecto",
			"video_ogv": "",
			"video_mp4": "res://assets/video/video_presentacion.mp4",
			"what": "Resumen audiovisual Full HD (1920×1080) del proyecto Campeones de los Valores.",
			"where": "assets/video/video_presentacion.mp4 y video_presentacion.html.",
			"symbolizes": "Difusión educativa institucional del Colegio de Bachilleres del Estado de México."
		}
	]

	return {
		"Personajes": chars,
		"Canciones": songs,
		"Escenarios": stages,
		"Enemigos y Jefes": enemies,
		"Habilidades e Ítems": skills,
		"Videos": videos,
	}

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.04, 0.08, 0.88)
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.name = "GalleryPanel"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	sb.border_color = Color(0.86, 0.72, 0.34, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(main_vbox)

	# Cabecera con título y botón Cerrar
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	main_vbox.add_child(header)

	var h_title := Label.new()
	h_title.text = "BIBLIOTECA DE MATERIALES · CEMSaD 22 ENTHAVI"
	h_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_title.add_theme_font_size_override("font_size", 14)
	h_title.add_theme_color_override("font_color", Color(0.96, 0.84, 0.44))
	header.add_child(h_title)

	_btn_close = Button.new()
	_btn_close.name = "BtnGalleryClose"
	_btn_close.text = "✕ Cerrar"
	_btn_close.custom_minimum_size = Vector2(92, 34)
	_btn_close.pressed.connect(_close_gallery)
	header.add_child(_btn_close)
	UiJuice.attach_button(_btn_close)

	# Pestañas de categorías
	var tabs_hbox := HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 4)
	main_vbox.add_child(tabs_hbox)
	for cat_name in CATEGORY_ORDER:
		var tb := Button.new()
		tb.text = cat_name
		tb.toggle_mode = true
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size = Vector2(60, 32)
		tb.add_theme_font_size_override("font_size", 11)
		tb.pressed.connect(_select_category.bind(cat_name))
		tabs_hbox.add_child(tb)
		UiJuice.attach_button(tb)
		_tab_buttons[cat_name] = tb

	# Contenido dividido: Lista izquierda + Panel de detalle derecho
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 10)
	main_vbox.add_child(split)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(215, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(scroll)

	_item_list_vbox = VBoxContainer.new()
	_item_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_list_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(_item_list_vbox)

	# Panel de detalle derecho
	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var dsb := StyleBoxFlat.new()
	dsb.bg_color = Color(0.05, 0.06, 0.11, 0.94)
	dsb.border_color = Color(0.28, 0.34, 0.48, 0.85)
	dsb.set_border_width_all(1)
	dsb.set_corner_radius_all(6)
	dsb.content_margin_left = 10
	dsb.content_margin_right = 10
	dsb.content_margin_top = 8
	dsb.content_margin_bottom = 8
	detail_panel.add_theme_stylebox_override("panel", dsb)
	split.add_child(detail_panel)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 6)
	detail_panel.add_child(detail_vbox)

	_detail_title = Label.new()
	_detail_title.add_theme_font_size_override("font_size", 15)
	_detail_title.add_theme_color_override("font_color", Color(0.98, 0.90, 0.50))
	detail_vbox.add_child(_detail_title)

	# Caja de vista previa (Textura o dibujo procedural)
	var preview_box := CenterContainer.new()
	preview_box.custom_minimum_size = Vector2(0, 132)
	detail_vbox.add_child(preview_box)

	_preview_tex = TextureRect.new()
	_preview_tex.custom_minimum_size = Vector2(220, 124)
	_preview_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview_box.add_child(_preview_tex)

	_preview_custom = Control.new()
	_preview_custom.custom_minimum_size = Vector2(220, 124)
	_preview_custom.visible = false
	_preview_custom.draw.connect(_on_custom_preview_draw)
	preview_box.add_child(_preview_custom)

	_preview_video = VideoStreamPlayer.new()
	_preview_video.custom_minimum_size = Vector2(220, 124)
	_preview_video.expand = true
	_preview_video.visible = false
	_preview_video.finished.connect(_on_preview_video_finished)
	preview_box.add_child(_preview_video)

	_video_row = HBoxContainer.new()
	_video_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_video_row.add_theme_constant_override("separation", 6)
	_video_row.visible = false
	detail_vbox.add_child(_video_row)

	_btn_play_video = Button.new()
	_btn_play_video.text = "▶ Reproducir Video"
	_btn_play_video.custom_minimum_size = Vector2(146, 30)
	_btn_play_video.add_theme_font_size_override("font_size", 11)
	_btn_play_video.pressed.connect(_on_video_play_pressed)
	_video_row.add_child(_btn_play_video)

	_btn_fullscreen_video = Button.new()
	_btn_fullscreen_video.name = "BtnFullscreenVideo"
	_btn_fullscreen_video.text = "⛶ Pantalla Completa"
	_btn_fullscreen_video.custom_minimum_size = Vector2(156, 30)
	_btn_fullscreen_video.add_theme_font_size_override("font_size", 11)
	_btn_fullscreen_video.pressed.connect(open_video_fullscreen)
	_video_row.add_child(_btn_fullscreen_video)
	UiJuice.attach_button(_btn_fullscreen_video)

	# Selector de poses para Personajes
	_pose_row = HBoxContainer.new()
	_pose_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_pose_row.add_theme_constant_override("separation", 4)
	detail_vbox.add_child(_pose_row)
	for pose_pair in [["idle", "Idle"], ["walk_right", "Caminar"], ["attack", "Ataque"], ["portrait", "Retrato"]]:
		var pb := Button.new()
		pb.text = pose_pair[1]
		pb.toggle_mode = true
		pb.custom_minimum_size = Vector2(64, 26)
		pb.add_theme_font_size_override("font_size", 10)
		pb.pressed.connect(_select_pose.bind(pose_pair[0]))
		_pose_row.add_child(pb)
		_pose_buttons[pose_pair[0]] = pb

	# Controles Jukebox para Canciones
	_jukebox_row = VBoxContainer.new()
	_jukebox_row.add_theme_constant_override("separation", 4)
	_jukebox_row.visible = false
	detail_vbox.add_child(_jukebox_row)

	var j_btns := HBoxContainer.new()
	j_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	j_btns.add_theme_constant_override("separation", 6)
	_jukebox_row.add_child(j_btns)

	_btn_play_song = Button.new()
	_btn_play_song.text = "▶ Reproducir"
	_btn_play_song.custom_minimum_size = Vector2(116, 30)
	_btn_play_song.add_theme_font_size_override("font_size", 11)
	_btn_play_song.pressed.connect(_on_jukebox_play_pressed)
	j_btns.add_child(_btn_play_song)

	_btn_voice_toggle = Button.new()
	_btn_voice_toggle.custom_minimum_size = Vector2(105, 30)
	_btn_voice_toggle.add_theme_font_size_override("font_size", 10)
	_btn_voice_toggle.pressed.connect(_on_jukebox_voice_toggle)
	j_btns.add_child(_btn_voice_toggle)

	_btn_diff_cycle = Button.new()
	_btn_diff_cycle.custom_minimum_size = Vector2(108, 30)
	_btn_diff_cycle.add_theme_font_size_override("font_size", 10)
	_btn_diff_cycle.pressed.connect(_on_jukebox_diff_cycle)
	j_btns.add_child(_btn_diff_cycle)

	_detail_rich = RichTextLabel.new()
	_detail_rich.bbcode_enabled = true
	_detail_rich.fit_content = false
	_detail_rich.scroll_active = true
	_detail_rich.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_rich.add_theme_font_size_override("normal_font_size", 12)
	_detail_rich.add_theme_font_size_override("bold_font_size", 12)
	detail_vbox.add_child(_detail_rich)

func _update_safe_layout() -> void:
	if _panel == null or not is_inside_tree() or get_viewport() == null:
		return
	var vp := get_viewport()
	var vp_sz := vp.get_visible_rect().size
	var insets := MobileControls.get_safe_insets_for_viewport(vp, 8.0)
	var x0 := insets.position.x + 8.0
	var y0 := insets.position.y + 8.0
	var w := maxf(320.0, vp_sz.x - insets.position.x - insets.size.x - 16.0)
	var h := maxf(240.0, vp_sz.y - insets.position.y - insets.size.y - 16.0)
	_panel.position = Vector2(x0, y0)
	_panel.size = Vector2(w, h)

func _process(delta: float) -> void:
	_anim_time += delta
	if _preview_custom and _preview_custom.visible:
		_preview_custom.queue_redraw()

func _select_category(cat_name: String) -> void:
	_current_category = cat_name
	_current_index = 0
	for c_key in _tab_buttons.keys():
		(_tab_buttons[c_key] as Button).button_pressed = (c_key == cat_name)
	_rebuild_item_list()
	_select_item(0)

func _rebuild_item_list() -> void:
	for child in _item_list_vbox.get_children():
		_item_list_vbox.remove_child(child)
		child.queue_free()
	_list_buttons.clear()

	var items: Array = _categories_cache.get(_current_category, [])
	for i in range(items.size()):
		var entry: Dictionary = items[i]
		var btn := Button.new()
		btn.text = str(entry.get("name", "Elemento %d" % i))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(0, 32)
		btn.add_theme_font_size_override("font_size", 11)
		btn.clip_text = true
		btn.pressed.connect(_select_item.bind(i))
		_item_list_vbox.add_child(btn)
		_list_buttons.append(btn)

func _select_item(idx: int) -> void:
	var items: Array = _categories_cache.get(_current_category, [])
	if items.is_empty():
		return
	_current_index = clampi(idx, 0, items.size() - 1)
	for i in range(_list_buttons.size()):
		_list_buttons[i].button_pressed = (i == _current_index)

	var entry: Dictionary = items[_current_index]
	_detail_title.text = str(entry.get("name", ""))
	_current_pose = "idle"
	_refresh_preview(entry)
	_refresh_description(entry)

func _select_pose(pose_key: String) -> void:
	_current_pose = pose_key
	var items: Array = _categories_cache.get(_current_category, [])
	if _current_index < items.size():
		_refresh_preview(items[_current_index])

func _load_tex_safe(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var r := ResourceLoader.load(path)
		if r is Texture2D:
			return r
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

func _resolve_character_pose_path(entry: Dictionary, pose_key: String) -> String:
	var folder := str(entry.get("folder", ""))
	if pose_key == "portrait":
		return str(entry.get("portrait", ""))
	if pose_key == "idle" and entry.has("custom_idle"):
		return str(entry.get("custom_idle"))
	var candidates := {
		"idle": ["idle.png"],
		"walk_right": ["walk_right.png", "Capa 3.png"],
		"attack": ["attack.png", "atack.png", "hablando_frente.png"],
	}
	for fname in candidates.get(pose_key, []):
		var p: String = folder + str(fname)
		if ResourceLoader.exists(p) or FileAccess.file_exists(p):
			return p
	return ""

func _stop_preview_video() -> void:
	_is_video_playing = false
	if _preview_video:
		_preview_video.stop()
	if _btn_play_video:
		_btn_play_video.text = "▶ Reproducir Video"

func _on_preview_video_finished() -> void:
	_stop_preview_video()

func _on_video_play_pressed() -> void:
	if _is_video_playing:
		_stop_preview_video()
		return
	var items: Array = _categories_cache.get("Videos", [])
	if _current_index >= items.size():
		return
	var ogv_path := str(items[_current_index].get("video_ogv", ""))
	if ogv_path.is_empty() or (not ResourceLoader.exists(ogv_path) and not FileAccess.file_exists(ogv_path)):
		return
	var vstream := ResourceLoader.load(ogv_path) as VideoStream
	if vstream == null:
		return
	var gs := _get_gs()
	if gs and gs.has_method("stop_music"):
		gs.stop_music(0.15)
	_preview_video.stream = vstream
	_preview_video.visible = true
	_preview_custom.visible = false
	_preview_video.play()
	_is_video_playing = true
	if _btn_play_video:
		_btn_play_video.text = "■ Detener Video"

func open_video_fullscreen() -> void:
	if _is_video_fullscreen:
		return
	var items: Array = _categories_cache.get("Videos", [])
	if _current_index >= items.size():
		return
	var ogv_path := str(items[_current_index].get("video_ogv", ""))
	if ogv_path.is_empty() or (not ResourceLoader.exists(ogv_path) and not FileAccess.file_exists(ogv_path)):
		return
	var vstream := ResourceLoader.load(ogv_path) as VideoStream
	if vstream == null:
		return
	_stop_preview_video()
	var gs := _get_gs()
	if gs and gs.has_method("stop_music"):
		gs.stop_music(0.15)

	if DisplayServer.get_name() != "headless":
		_prev_window_mode = DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	_video_fs_overlay = Control.new()
	_video_fs_overlay.name = "VideoFullscreenOverlay"
	_video_fs_overlay.z_index = 200
	_video_fs_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video_fs_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_video_fs_overlay)

	var fs_bg := ColorRect.new()
	fs_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	fs_bg.color = Color(0.01, 0.01, 0.03, 0.99)
	_video_fs_overlay.add_child(fs_bg)

	_video_fs_aspect = AspectRatioContainer.new()
	_video_fs_aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video_fs_aspect.ratio = 0.75 if ("3x4" in ogv_path) else (16.0 / 9.0)
	_video_fs_aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	_video_fs_overlay.add_child(_video_fs_aspect)

	_video_fs_player = VideoStreamPlayer.new()
	_video_fs_player.name = "FullscreenVideoPlayer"
	_video_fs_player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_video_fs_player.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_video_fs_player.expand = true
	_video_fs_player.stream = vstream
	_video_fs_player.finished.connect(func():
		if _video_fs_player and is_instance_valid(_video_fs_player) and _is_video_fullscreen:
			_video_fs_player.play()
	)
	_video_fs_aspect.add_child(_video_fs_player)
	_video_fs_player.play()

	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bar.anchor_left = 1.0
	bar.anchor_right = 1.0
	bar.offset_left = -310.0
	bar.offset_top = 10.0
	bar.offset_right = -10.0
	bar.offset_bottom = 44.0
	bar.alignment = BoxContainer.ALIGNMENT_END
	bar.add_theme_constant_override("separation", 6)
	_video_fs_overlay.add_child(bar)

	_video_fs_btn_pause = Button.new()
	_video_fs_btn_pause.text = "⏸ Pausa"
	_video_fs_btn_pause.custom_minimum_size = Vector2(90, 32)
	_video_fs_btn_pause.add_theme_font_size_override("font_size", 11)
	_video_fs_btn_pause.pressed.connect(func():
		if _video_fs_player and is_instance_valid(_video_fs_player):
			_video_fs_player.paused = not _video_fs_player.paused
			_video_fs_btn_pause.text = "▶ Reanudar" if _video_fs_player.paused else "⏸ Pausa"
	)
	bar.add_child(_video_fs_btn_pause)

	var btn_exit_fs := Button.new()
	btn_exit_fs.name = "BtnCloseVideoFullscreen"
	btn_exit_fs.text = "✕ Salir Pantalla Completa"
	btn_exit_fs.custom_minimum_size = Vector2(180, 32)
	btn_exit_fs.add_theme_font_size_override("font_size", 11)
	btn_exit_fs.pressed.connect(close_video_fullscreen)
	bar.add_child(btn_exit_fs)

	_is_video_fullscreen = true

func close_video_fullscreen() -> void:
	_is_video_fullscreen = false
	if _video_fs_player and is_instance_valid(_video_fs_player):
		_video_fs_player.stop()
	if _video_fs_overlay and is_instance_valid(_video_fs_overlay):
		_video_fs_overlay.queue_free()
	_video_fs_overlay = null
	_video_fs_player = null
	_video_fs_aspect = null
	_video_fs_btn_pause = null
	if DisplayServer.get_name() != "headless" and _prev_window_mode >= 0:
		DisplayServer.window_set_mode(_prev_window_mode)
		_prev_window_mode = -1

func _refresh_preview(entry: Dictionary) -> void:
	_stop_preview_video()
	_pose_row.visible = (_current_category == "Personajes")
	_jukebox_row.visible = (_current_category == "Canciones")
	if _video_row:
		_video_row.visible = (_current_category == "Videos")
	if _preview_video:
		_preview_video.visible = false

	if _current_category == "Personajes":
		var first_valid := ""
		for pkey in ["idle", "walk_right", "attack", "portrait"]:
			var ppath := _resolve_character_pose_path(entry, pkey)
			var btn := _pose_buttons.get(pkey) as Button
			if btn:
				btn.visible = not ppath.is_empty()
				btn.button_pressed = (pkey == _current_pose)
			if first_valid.is_empty() and not ppath.is_empty():
				first_valid = ppath
		var active_path := _resolve_character_pose_path(entry, _current_pose)
		if active_path.is_empty():
			active_path = first_valid
		_preview_tex.texture = _load_tex_safe(active_path)
		_preview_tex.visible = true
		_preview_custom.visible = false
	elif _current_category == "Escenarios":
		_preview_tex.texture = _load_tex_safe(str(entry.get("img", "")))
		_preview_tex.visible = true
		_preview_custom.visible = false
	elif _current_category == "Enemigos y Jefes" and str(entry.get("kind", "")) == "sprite":
		_preview_tex.texture = _load_tex_safe(str(entry.get("tex", "")))
		_preview_tex.visible = true
		_preview_custom.visible = false
	elif _current_category == "Videos":
		var has_ogv := not str(entry.get("video_ogv", "")).is_empty()
		if _btn_play_video:
			_btn_play_video.disabled = not has_ogv
			_btn_play_video.text = "▶ Reproducir Video" if has_ogv else "MP4 en assets/video/"
		if _btn_fullscreen_video:
			_btn_fullscreen_video.disabled = not has_ogv
		_preview_tex.visible = false
		_preview_custom.visible = true
	elif _current_category == "Canciones":
		_preview_tex.visible = false
		_preview_custom.visible = true
		_refresh_jukebox_buttons()
	else:
		_preview_tex.visible = false
		_preview_custom.visible = true

	if _preview_custom.visible:
		_preview_custom.queue_redraw()

func _refresh_description(entry: Dictionary) -> void:
	var bb := ""
	bb += "[color=#F5D76E][b]Qué es:[/b][/color]\n%s\n\n" % str(entry.get("what", ""))
	bb += "[color=#7AD7F0][b]Dónde se encuentra:[/b][/color]\n%s\n\n" % str(entry.get("where", ""))
	bb += "[color=#8CE99A][b]Qué simboliza:[/b][/color]\n%s" % str(entry.get("symbolizes", ""))
	_detail_rich.text = bb

func _refresh_jukebox_buttons() -> void:
	if _btn_play_song:
		_btn_play_song.text = "■ Detener" if _is_preview_playing else "▶ Reproducir"
	if _btn_voice_toggle:
		_btn_voice_toggle.text = "Voz: %s" % ("Femenino" if _jukebox_char == 1 else "Masculino")
	if _btn_diff_cycle:
		var dnames := ["Fácil", "Normal", "Difícil"]
		_btn_diff_cycle.text = "Dif: %s" % dnames[clampi(_jukebox_diff, 0, 2)]

func _on_jukebox_play_pressed() -> void:
	var items: Array = _categories_cache.get("Canciones", [])
	if _current_index >= items.size():
		return
	var song_id := str(items[_current_index].get("id", "menu"))
	var gs := _get_gs()
	if _is_preview_playing:
		_is_preview_playing = false
		if gs and gs.has_method("stop_music"):
			gs.stop_music(0.2)
	else:
		_is_preview_playing = true
		if gs and gs.has_method("play_track_by_id"):
			gs.play_track_by_id(song_id, _jukebox_char, _jukebox_diff)
	_refresh_jukebox_buttons()

func _on_jukebox_voice_toggle() -> void:
	_jukebox_char = 1 if _jukebox_char == 0 else 0
	if _is_preview_playing:
		_is_preview_playing = false
		_on_jukebox_play_pressed()
	else:
		_refresh_jukebox_buttons()

func _on_jukebox_diff_cycle() -> void:
	_jukebox_diff = (_jukebox_diff + 1) % 3
	if _is_preview_playing:
		_is_preview_playing = false
		_on_jukebox_play_pressed()
	else:
		_refresh_jukebox_buttons()

func _on_custom_preview_draw() -> void:
	if _preview_custom == null:
		return
	var sz := _preview_custom.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	var items: Array = _categories_cache.get(_current_category, [])
	if _current_index >= items.size():
		return
	var entry: Dictionary = items[_current_index]

	if _current_category == "Canciones":
		# Barras ecualizadoras escolares / Touhou
		var n_bars := 14
		var bw := 10.0
		var gap := 4.0
		var start_x := cx - float(n_bars) * (bw + gap) * 0.5
		var base_y := sz.y - 16.0
		for i in range(n_bars):
			var amp := 0.22 if not _is_preview_playing else (0.35 + 0.65 * absf(sin(_anim_time * (5.5 + float(i % 4)) + float(i) * 0.6)))
			var bh := amp * (sz.y - 36.0)
			var col := Color.from_hsv(fposmod(0.08 + float(i) * 0.055, 1.0), 0.72, 0.96)
			_preview_custom.draw_rect(Rect2(start_x + float(i) * (bw + gap), base_y - bh, bw, bh), col)
	elif _current_category == "Enemigos y Jefes":
		var b_type := int(entry.get("boss_type", 0))
		var b_data: Dictionary = BossData.BOSS_DATA.get(b_type, {})
		var base_col: Color = b_data.get("color", Color.PURPLE)
		var acc_col: Color = b_data.get("accent_color", Color.GOLD)
		BossRendererClass.draw_boss_silhouette(_preview_custom, b_type, Vector2(cx, cy + 44.0), _anim_time, base_col, acc_col, false, false, 1.12)
	elif _current_category == "Videos":
		_preview_custom.draw_rect(Rect2(cx - 56, cy - 36, 112, 72), Color(0.14, 0.17, 0.28))
		_preview_custom.draw_rect(Rect2(cx - 56, cy - 36, 112, 72), Color(0.95, 0.82, 0.36), false, 2.0)
		_preview_custom.draw_polygon(PackedVector2Array([Vector2(cx - 12, cy - 16), Vector2(cx + 18, cy), Vector2(cx - 12, cy + 16)]), [Color(1.0, 0.88, 0.35)])
	else:
		# Habilidades e Ítems con emblemas únicos animados
		var skill_id := str(entry.get("id", "virtue_shot"))
		draw_skill_emblem(_preview_custom, skill_id, Vector2(cx, cy), _anim_time, 1.0)

static func draw_skill_emblem(canvas: CanvasItem, skill_id: String, center: Vector2, anim_time: float, scale_f: float = 1.0) -> void:
	match skill_id:
		"virtue_shot":
			# Estrella radiante de 8 puntas dorado-turquesa con destellos en órbita
			var outer_pts := PackedVector2Array()
			var inner_pts := PackedVector2Array()
			var rot := anim_time * 0.9
			for i in range(16):
				var a := rot + float(i) * (TAU / 16.0)
				var r_out := (38.0 if (i % 4 == 0) else (28.0 if (i % 2 == 0) else 13.0)) * scale_f
				var r_in := (20.0 if (i % 2 == 0) else 8.0) * scale_f
				outer_pts.append(center + Vector2(cos(a), sin(a)) * r_out)
				inner_pts.append(center + Vector2(cos(a), sin(a)) * r_in)
			canvas.draw_colored_polygon(outer_pts, Color(0.22, 0.84, 0.96, 0.95))
			canvas.draw_colored_polygon(inner_pts, Color(1.0, 0.85, 0.28, 0.98))
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -10 * scale_f), center + Vector2(10 * scale_f, 0),
				center + Vector2(0, 10 * scale_f), center + Vector2(-10 * scale_f, 0),
			]), Color(1.0, 0.98, 0.90))
			for m in range(4):
				var ma := -rot * 1.4 + float(m) * (TAU / 4.0)
				canvas.draw_circle(center + Vector2(cos(ma), sin(ma)) * 42.0 * scale_f, 2.8 * scale_f, Color(1.0, 0.92, 0.45))

		"focus_graze":
			# Retícula Touhou de precisión: micro-hitbox romboidal + aros calibrados + rozadura cian
			canvas.draw_arc(center, 36.0 * scale_f, anim_time * 1.4, anim_time * 1.4 + PI * 1.4, 24, Color(0.95, 0.30, 0.45, 0.85), 2.4 * scale_f)
			canvas.draw_arc(center, 24.0 * scale_f, -anim_time * 2.1, -anim_time * 2.1 + PI * 1.3, 20, Color(1.0, 0.72, 0.78, 0.90), 2.0 * scale_f)
			for card in range(4):
				var ca := float(card) * (PI * 0.5)
				canvas.draw_line(center + Vector2(cos(ca), sin(ca)) * 16.0 * scale_f, center + Vector2(cos(ca), sin(ca)) * 42.0 * scale_f, Color(1.0, 0.92, 0.94), 2.0 * scale_f)
			# Chispas de graze rozando por fuera
			for g in range(3):
				var ga := anim_time * 2.6 + float(g) * (TAU / 3.0)
				var gp := center + Vector2(cos(ga), sin(ga)) * 31.0 * scale_f
				canvas.draw_circle(gp, 3.5 * scale_f, Color(0.35, 0.95, 1.0))
			# Núcleo micro-hitbox (5.5 px motivo)
			canvas.draw_circle(center, 9.0 * scale_f, Color(1.0, 0.22, 0.40, 0.95))
			canvas.draw_circle(center, 4.5 * scale_f, Color.WHITE)

		"empathy_pulse":
			# Corazón cálido central irradiando 3 ondas expansivas turquesa de empatía
			for w in range(3):
				var phase := fmod(anim_time * 0.85 + float(w) / 3.0, 1.0)
				var wr := (14.0 + phase * 32.0) * scale_f
				var wa := (1.0 - phase) * 0.85
				canvas.draw_arc(center, wr, 0.0, TAU, 32, Color(0.38, 0.94, 1.0, wa), 2.4 * scale_f)
			var h_pts := PackedVector2Array([
				center + Vector2(0, 13 * scale_f), center + Vector2(-14 * scale_f, -1 * scale_f),
				center + Vector2(-12 * scale_f, -11 * scale_f), center + Vector2(-5 * scale_f, -13 * scale_f),
				center + Vector2(0, -7 * scale_f), center + Vector2(5 * scale_f, -13 * scale_f),
				center + Vector2(12 * scale_f, -11 * scale_f), center + Vector2(14 * scale_f, -1 * scale_f),
			])
			canvas.draw_colored_polygon(h_pts, Color(1.0, 0.48, 0.62))
			canvas.draw_polyline(h_pts + PackedVector2Array([h_pts[0]]), Color(1.0, 0.92, 0.85), 1.6 * scale_f)

		"esperanza":
			# Sol dorado de 10 rayos + laureles esmeralda y llama interior de esperanza
			var pulse := 1.0 + sin(anim_time * 4.0) * 0.07
			var sun_pts := PackedVector2Array()
			for i in range(20):
				var sa := -PI * 0.5 + float(i) * (TAU / 20.0) + anim_time * 0.35
				var sr := (36.0 if (i % 2 == 0) else 18.0) * scale_f * pulse
				sun_pts.append(center + Vector2(cos(sa), sin(sa)) * sr)
			canvas.draw_colored_polygon(sun_pts, Color(1.0, 0.86, 0.22, 0.96))
			canvas.draw_circle(center, 13.0 * scale_f, Color(1.0, 0.96, 0.72))
			# Laurel verde esmeralda abrazando el emblema
			canvas.draw_arc(center + Vector2(0, 6 * scale_f), 34.0 * scale_f, PI * 0.15, PI * 0.85, 20, Color(0.24, 0.82, 0.48, 0.92), 3.4 * scale_f)
			canvas.draw_circle(center, 5.5 * scale_f, Color(0.35, 0.92, 1.0))

		"heart":
			# Corazón rubí pixelado en capas con destellos curativos (+) ascendentes
			var beat := 1.0 + maxf(0.0, sin(anim_time * 5.0)) * 0.10
			var hp := PackedVector2Array([
				center + Vector2(0, 22 * beat) * scale_f, center + Vector2(-24 * beat, -2 * beat) * scale_f,
				center + Vector2(-22 * beat, -17 * beat) * scale_f, center + Vector2(-9 * beat, -22 * beat) * scale_f,
				center + Vector2(0, -11 * beat) * scale_f, center + Vector2(9 * beat, -22 * beat) * scale_f,
				center + Vector2(22 * beat, -17 * beat) * scale_f, center + Vector2(24 * beat, -2 * beat) * scale_f,
			])
			canvas.draw_colored_polygon(hp, Color(0.95, 0.22, 0.38))
			canvas.draw_polyline(hp + PackedVector2Array([hp[0]]), Color(0.45, 0.08, 0.18), 2.2 * scale_f)
			canvas.draw_rect(Rect2(center + Vector2(-13, -14) * scale_f, Vector2(6, 6) * scale_f), Color(1.0, 0.86, 0.90))
			for idx in range(3):
				var py_off := -fmod(anim_time * 18.0 + float(idx) * 14.0, 36.0)
				var px_pos := center + Vector2((float(idx) - 1.0) * 20.0, py_off) * scale_f
				canvas.draw_line(px_pos + Vector2(-4, 0) * scale_f, px_pos + Vector2(4, 0) * scale_f, Color(0.45, 0.96, 0.62), 2.0 * scale_f)
				canvas.draw_line(px_pos + Vector2(0, -4) * scale_f, px_pos + Vector2(0, 4) * scale_f, Color(0.45, 0.96, 0.62), 2.0 * scale_f)

		"shield", _:
			# Escudo heráldico zafiro-dorado de resiliencia con chevron y halo hexagonal
			var sh_out := PackedVector2Array([
				center + Vector2(0, -34) * scale_f, center + Vector2(28, -22) * scale_f,
				center + Vector2(24, 12) * scale_f, center + Vector2(0, 36) * scale_f,
				center + Vector2(-24, 12) * scale_f, center + Vector2(-28, -22) * scale_f,
			])
			var sh_in := PackedVector2Array([
				center + Vector2(0, -27) * scale_f, center + Vector2(22, -17) * scale_f,
				center + Vector2(18, 9) * scale_f, center + Vector2(0, 29) * scale_f,
				center + Vector2(-18, 9) * scale_f, center + Vector2(-22, -17) * scale_f,
			])
			canvas.draw_colored_polygon(sh_out, Color(0.95, 0.78, 0.28))
			canvas.draw_colored_polygon(sh_in, Color(0.18, 0.54, 0.88))
			canvas.draw_polyline(sh_out + PackedVector2Array([sh_out[0]]), Color(0.08, 0.14, 0.28), 2.0 * scale_f)
			canvas.draw_polyline(PackedVector2Array([
				center + Vector2(-11, -4) * scale_f, center + Vector2(0, 9) * scale_f, center + Vector2(11, -4) * scale_f
			]), Color(1.0, 0.94, 0.60), 3.4 * scale_f)
			canvas.draw_arc(center, 42.0 * scale_f, anim_time, anim_time + TAU, 6, Color(0.45, 0.92, 1.0, 0.55), 1.8 * scale_f)

func _unhandled_input(event: InputEvent) -> void:
	if _is_video_fullscreen:
		if (event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and not event.is_echo() and event.button_index == JOY_BUTTON_B):
			close_video_fullscreen()
			if get_viewport():
				get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			_close_gallery()
			if get_viewport():
				get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and not event.is_echo():
		if event.button_index == JOY_BUTTON_B:
			_close_gallery()
			if get_viewport():
				get_viewport().set_input_as_handled()

func _close_gallery() -> void:
	close_video_fullscreen()
	closed.emit()
	queue_free()
