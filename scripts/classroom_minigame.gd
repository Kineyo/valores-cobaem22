extends CanvasLayer
class_name ClassroomMinigame

## Encuentros de Salón de Clases simples y ágiles estilo Undertale (PC y Móvil).
## 3 modos claros e intuitivos:
## 1) SHOOT_YELLOW: Disparar claridad (auto-disparo + Espacio/Toque) con el Alma Amarilla.
## 2) QUIZ_VALUES: Preguntas rápidas de respeto y convivencia escolar con 3 opciones.
## 3) DODGE_RED: Esquive clásico 8D con el Alma Roja atrapando notas/aros dorados.

signal minigame_finished(cleared: bool, classroom_index: int)

enum Phase { INTRO, MENU, SUB_ACT, VALOR_BAR, QUIZ, DIALOG, DODGING, DEFEAT, VICTORY }
enum SoulType {
	SHOOT_YELLOW,
	QUIZ_VALUES,
	DODGE_RED,
}

const MENU_BASE_LABELS: Array[String] = ["VALOR", "ACT", "ITEM", "PIEDAD"]
const WAVE_DURATION := 5.5

## Corazón pixel-art 9x8 clásico
const HEART_ROWS: Array[String] = [
	".XX...XX.",
	"XXXX.XXXX",
	"XXXXXXXXX",
	"XXXXXXXXX",
	".XXXXXXX.",
	"..XXXXX..",
	"...XXX...",
	"....X....",
]

const CLASSROOM_CONFIGS: Array[Dictionary] = [
	{
		"index": 0,
		"classroom_name": "Salón 1: Laboratorio D",
		"title": "Chispas de Curiosidad",
		"ally": "Mateo",
		"ally_attack": "Triple Reacción",
		"ally_tex": "res://assets/characters/mateo_laboratorio/idle.png",
		"special_tex": "",
		"ally_msg": "* Mateo lanza Triple Reacción. Preguntar en clase ya no da pena.",
		"eco_name": "Matraz Murmullo",
		"eco_sub": "Un matraz B&N que imita risitas cuando alguien pregunta.",
		"soul_type": SoulType.SHOOT_YELLOW,
		"soul_color": Color(1.0, 0.90, 0.20),
		"mode_badge": "DISPAROS",
		"box_size": Vector2(264.0, 160.0),
		"intro_text": "* Matraz Murmullo bloquea la mesa del laboratorio.\n* Despeja las burbujas de burla o responde con VALOR / ACT.",
		"dodge_hint": "WASD o Arrastre mueve · Disparo automático (o Espacio/Toque)",
		"pity_fail_quote": "Si preguntas otra vez, seguro alguien se burla.",
		"pity_win_quote": "Preguntar sin miedo sí aclaró el tema. Buena práctica.",
		"acts": [
			{
				"label": "Preguntar sin pena",
				"msg": "* Levantas la mano con calma. Medio salón tenía la misma duda.",
				"quote": "Vaya, nadie se rió esta vez.",
				"harmony": 45.0,
			},
			{
				"label": "Mezclar con Mateo",
				"msg": "* Sostienes el mechero mientras Mateo ajusta el reactivo.",
				"quote": "Esa reacción salió limpia.",
				"harmony": 45.0,
			},
		],
	},
	{
		"index": 1,
		"classroom_name": "Salón 2: Aula 1 / Cafetería",
		"title": "La Mesa del Respeto",
		"ally": "María",
		"ally_attack": "Escudo Firme",
		"ally_tex": "res://assets/characters/maria_cafeteria/idle.png",
		"special_tex": "",
		"ally_msg": "* María activa su Escudo Firme y ordena la mesa con respeto.",
		"eco_name": "Torre de Charolas",
		"eco_sub": "Pila tambaleante que evade responsabilidades.",
		"soul_type": SoulType.QUIZ_VALUES,
		"soul_color": Color(0.24, 0.86, 1.0),
		"mode_badge": "PREGUNTAS",
		"box_size": Vector2(560.0, 196.0),
		"intro_text": "* Torre de Charolas ocupa el desayunador.\n* Responde sus excusas con respeto o usa VALOR / ACT.",
		"dodge_hint": "Toca tu respuesta · PC: 1/2/3 o Flechas + Espacio",
		"pity_fail_quote": "Si dejo la basura aquí, alguien más vendrá a recogerla.",
		"pity_win_quote": "Limpieza madruga desde las cinco. Yo también recojo mi lugar.",
		"acts": [
			{
				"label": "Poner límite firme",
				"msg": "* Dices tranquilo y claro: «Cada quien limpia lo que usó».",
				"quote": "Qué directo. Está bien, no pesa recoger mi charola.",
				"harmony": 45.0,
			},
			{
				"label": "Turnar las mesas",
				"msg": "* Organizan turnos rápidos entre grupos para cuidar el espacio.",
				"quote": "Entre cuatro se limpia en diez segundos.",
				"harmony": 45.0,
			},
		],
		"questions": [
			{
				"prompt": "Tus amigos se levantan rápido y dejan envolturas en la mesa común.",
				"options": [
					{"label": "Dejarlas ahí porque ya sonó el timbre de clase", "good": false, "react": "* Salir con prisa deja el desorden al siguiente turno."},
					{"label": "Recoger lo de la mesa y avisarles para la próxima", "good": true, "react": "* Cuidar el espacio común empieza con el ejemplo."},
					{"label": "Mover la basura hacia otra mesa que parece vacía", "good": false, "react": "* Cambiar las cosas de lugar no resuelve nada."},
				],
			},
			{
				"prompt": "Un alumno nuevo tira su vaso en la fila y otros sacan el celular.",
				"options": [
					{"label": "Acercarle servilletas para evitar un resbalón", "good": true, "react": "* Apoyar a tiempo evita caídas y corta las burlas."},
					{"label": "Seguir de largo para no perder lugar en la fila", "good": false, "react": "* Ignorar el incidente deja solo a quien va llegando."},
					{"label": "Reírse un poco pensando que no pasa nada", "good": false, "react": "* Aunque parezca broma leve, incomoda a quien tropezó."},
				],
			},
			{
				"prompt": "Faltan lugares en el desayunador y un grupo aparta dos mesas libres.",
				"options": [
					{"label": "Sentarte aparte sin decir nada para evitar roce", "good": false, "react": "* Callar siempre deja bancas vacías y gente de pie."},
					{"label": "Tomar sillas de otra fila sin preguntar a nadie", "good": false, "react": "* Eso solo traslada la falta de lugar a otra mesa."},
					{"label": "Pedir compartir una banca libre para todos por turno", "good": true, "react": "* Dialogar con calma abre espacio en el mismo receso."},
				],
			},
		],
	},
	{
		"index": 2,
		"classroom_name": "Salón 3: Sala Cívica",
		"title": "El Eco de la Escalinata",
		"ally": "Valeria",
		"ally_attack": "Pulso Estéreo",
		"ally_tex": "res://assets/characters/valeria_plaza/idle.png",
		"special_tex": "",
		"ally_msg": "* Valeria lanza su Pulso Estéreo y equilibra la sala entera.",
		"eco_name": "Micrófono Acoplado",
		"eco_sub": "Pedestal que distorsiona voces en la asamblea.",
		"soul_type": SoulType.DODGE_RED,
		"soul_color": Color(1.0, 0.16, 0.22),
		"mode_badge": "ESQUIVAR",
		"box_size": Vector2(264.0, 160.0),
		"intro_text": "* Micrófono Acoplado interrumpe la Sala Cívica.\n* Esquiva ondas blancas y atrapa notas doradas con tu Corazón Rojo.",
		"dodge_hint": "WASD/Flechas o Arrastre libre · Atrapa notas doradas",
		"pity_fail_quote": "Bip. Aquí solo se escucha a quienes hablan más fuerte.",
		"pity_win_quote": "Qué claro suena cuando todos participan con respeto.",
		"acts": [
			{
				"label": "Hablar en coro",
				"msg": "* Respaldas a Valeria hasta que su voz deja de temblar.",
				"quote": "El acento de Temoaya suena firme cuando el grupo escucha.",
				"harmony": 45.0,
			},
			{
				"label": "Subir al parejo",
				"msg": "* Recuerdas que el patio y los escalones son para todo el plantel.",
				"quote": "Mi ecualizador no esperaba tanta calma.",
				"harmony": 45.0,
			},
		],
	},
	{
		"index": 3,
		"classroom_name": "Salón 4: Biblioteca Escolar",
		"title": "Foco de Verdades",
		"ally": "Fernanda",
		"ally_attack": "Nota al Margen",
		"ally_tex": "res://assets/characters/fernanda_biblioteca/idle.png",
		"special_tex": "",
		"ally_msg": "* Fernanda fija Notas al Margen que aclaran cada captura falsa.",
		"eco_name": "Hilo Viral",
		"eco_sub": "Pantalla llena de rumores exagerados que intenta clonarse.",
		"soul_type": SoulType.SHOOT_YELLOW,
		"soul_color": Color(1.0, 0.90, 0.20),
		"mode_badge": "DISPAROS",
		"box_size": Vector2(264.0, 160.0),
		"intro_text": "* Hilo Viral llena los estantes de Biblioteca.\n* Despeja los rumores rosas con el Alma Amarilla.",
		"dodge_hint": "WASD o Arrastre mueve · Disparo automático (o Espacio/Toque)",
		"pity_fail_quote": "Solo reenvié la captura por curiosidad, nadie sabe quién fue.",
		"pity_win_quote": "No verifiqué la fuente. Borro el rumor antes de dañar.",
		"acts": [
			{
				"label": "Pedir la fuente",
				"msg": "* Preguntas con calma si le consta o solo reenvió la imagen.",
				"quote": "En realidad me la mandó un conocido de otro grupo.",
				"harmony": 45.0,
			},
			{
				"label": "Pegar nota real",
				"msg": "* Fijas la guía de Fernanda justo encima del chisme.",
				"quote": "Esa nota breve y directa sí explica el tema.",
				"harmony": 45.0,
			},
		],
	},
	{
		"index": 4,
		"classroom_name": "Salón 5: Taller de Cómputo",
		"title": "Código Sin Atajos",
		"ally": "Diego y Sofía",
		"ally_attack": "Señal Abierta & Turno Abierto",
		"ally_tex": "res://assets/characters/diego_computo/idle.png",
		"special_tex": "res://assets/characters/diego_computo/ataque_senal.png",
		"ally_msg": "* Diego abre Señal Abierta y Sofía ordena el turno de estudio.",
		"eco_name": "Ventana Atajo.exe",
		"eco_sub": "Ventana emergente que ofrece copias rápidas y respuestas ajenas.",
		"soul_type": SoulType.QUIZ_VALUES,
		"soul_color": Color(0.32, 0.85, 1.0),
		"mode_badge": "PREGUNTAS",
		"box_size": Vector2(560.0, 196.0),
		"intro_text": "* Ventana Atajo.exe aparece en el taller de cómputo.\n* Descarta sus atajos con honestidad o usa VALOR / ACT.",
		"dodge_hint": "Toca tu respuesta · PC: 1/2/3 o Flechas + Espacio",
		"pity_fail_quote": "Clona la carpeta, cambia tu nombre y entrega sin revisar.",
		"pity_win_quote": "Proceso cerrado. Mejor armamos una guía paso a paso.",
		"acts": [
			{
				"label": "Escucha de Sofía",
				"msg": "* Sofía guarda su libreta y escucha las dudas reales del grupo.",
				"quote": "Expliquen desde cero con paciencia y sí me quedo a estudiar.",
				"harmony": 45.0,
			},
			{
				"label": "Señal Abierta de Diego",
				"msg": "* Diego abre el servidor local con apuntes libres y guías.",
				"quote": "Ese filtro bloqueó todas mis copias repetidas.",
				"harmony": 45.0,
			},
		],
		"questions": [
			{
				"prompt": "Falta media hora para entregar y te ofrecen copiar un proyecto.",
				"options": [
					{"label": "Pedir que te expliquen los pasos y entregar lo tuyo", "good": true, "react": "* Entender el proceso rinde más que entregar algo ajeno."},
					{"label": "Cambiar colores y nombres para ahorrar tiempo hoy", "good": false, "react": "* Cambiar la portada sigue siendo copiar trabajo ajeno."},
					{"label": "Pasar la carpeta al chat para que nadie repruebe", "good": false, "react": "* Compartir copias deja al grupo sin aprender la base."},
				],
			},
			{
				"prompt": "Alguien dejó abierta su cuenta escolar en la compu que te tocó.",
				"options": [
					{"label": "Dejarla abierta y abrir otra pestaña aparte", "good": false, "react": "* Si alguien usa el equipo después, su cuenta queda expuesta."},
					{"label": "Mirar rápido sus calificaciones por simple duda", "good": false, "react": "* Revisar información privada rompe la confianza digital."},
					{"label": "Cerrar la sesión de inmediato y avisarle con respeto", "good": true, "react": "* Cuidar la privacidad ajena construye confianza en el taller."},
				],
			},
			{
				"prompt": "El equipo choca entre avanzar rápido en código o mantener orden.",
				"options": [
					{"label": "Hacer tu parte aparte y juntar archivos al final", "good": false, "react": "* Trabajar por separado casi siempre duplica errores."},
					{"label": "Dividir roles combinando orden y prueba técnica", "good": true, "react": "* Coordinarse en red aprovecha lo mejor de cada integrante."},
					{"label": "Imponer la idea de quien tiene más experiencia", "good": false, "react": "* Descartar otras voces apaga la colaboración del equipo."},
				],
			},
		],
	},
	{
		"index": 5,
		"classroom_name": "Salón 6: Gimnasio / Aula Magna",
		"title": "Pase Limpio",
		"ally": "Alejandro",
		"ally_attack": "Pase de Rebote",
		"ally_tex": "res://assets/characters/alejandro_cancha/idle.png",
		"special_tex": "res://assets/characters/alejandro_cancha/ataque_balon.png",
		"ally_msg": "* Alejandro manda un Pase de Rebote y abre la cancha para todos.",
		"eco_name": "Sombras de la Grada",
		"eco_sub": "Siluetas tensas bloqueando la duela a los nuevos.",
		"soul_type": SoulType.DODGE_RED,
		"soul_color": Color(1.0, 0.16, 0.22),
		"mode_badge": "ESQUIVAR",
		"box_size": Vector2(264.0, 160.0),
		"intro_text": "* Sombras de la Grada cierran el paso en el Gimnasio.\n* Esquiva los balones blancos y toca el aro dorado de pase limpio.",
		"dodge_hint": "WASD/Flechas o Arrastre libre · Toca el aro dorado",
		"pity_fail_quote": "Aquí solo entran quienes ya dominan el juego rápido.",
		"pity_win_quote": "Se siente mejor jugar cuando nadie sale con miedo.",
		"acts": [
			{
				"label": "Pasar al nuevo",
				"msg": "* Alejandro da un pase limpio al de primero que miraba solo.",
				"quote": "Sí la controló. Se nota cuando juegan en equipo.",
				"harmony": 45.0,
			},
			{
				"label": "Armar reta mixta",
				"msg": "* Cero empujones y rotan todos cada cinco puntos.",
				"quote": "Así nadie se queda mirando desde las gradas.",
				"harmony": 45.0,
			},
		],
	},
]

var classroom_index: int = 0
var allow_standalone_exit: bool = false
var harmony: float = 0.0
var hp: int = 40
var max_hp: int = 40
var heal_uses_left: int = 2
var ally_cooldown: int = 0

var phase: Phase = Phase.INTRO
var _config: Dictionary = CLASSROOM_CONFIGS[0]
var _soul_type: SoulType = SoulType.SHOOT_YELLOW

var _menu_index: int = 0
var _sub_index: int = 0
var _quiz_index: int = 0
var _quiz_selected: int = 0
var _dialog_text: String = ""
var _eco_quote: String = ""
var _wave_calm_mult: float = 1.0

# Medidor elíptico de precisión (VALOR)
var _valor_cursor: float = -1.0
var _valor_dir: float = 1.0
var _valor_resolved: bool = false
var _valor_result_timer: float = 0.0

var _time: float = 0.0
var _wave_left: float = WAVE_DURATION
var _spawn_a: float = 0.0
var _spawn_b: float = 0.0
var _step_counter: int = 0
var _invuln_timer: float = 0.0
var _eco_shake: float = 0.0
var _emitted_finished: bool = false

# Geometría animada de la caja Undertale
var _current_box_rect: Rect2 = Rect2(120, 212, 560, 128)
var _target_box_rect: Rect2 = Rect2(120, 212, 560, 128)

# Estado del alma dentro de _current_box_rect
var _soul_pos: Vector2 = Vector2(400, 275)
var _shoot_cooldown: float = 0.0

var _hazards: Array[Dictionary] = []
var _good_items: Array[Dictionary] = []
var _pulses: Array[Dictionary] = []
var _pass_ring_pos: Vector2 = Vector2.ZERO
var _pass_ring_active: bool = false

# Táctil / arrastre 1 dedo + mouse PC
var _drag_touch_id: int = -1
var _last_touch_pos: Vector2 = Vector2.ZERO
var _mouse_dragging: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _pointer_cooldown_ms: int = 0

var _bg_canvas: Control
var _box_clip: Control
var _ally_tex: Texture2D = null
var _special_tex: Texture2D = null
var _sfx_select: AudioStreamPlayer
var _sfx_good: AudioStreamPlayer
var _sfx_hurt: AudioStreamPlayer

static func get_classroom_config(idx: int) -> Dictionary:
	var safe_idx := clampi(idx, 0, CLASSROOM_CONFIGS.size() - 1)
	return CLASSROOM_CONFIGS[safe_idx].duplicate(true)

func setup_classroom(idx: int) -> void:
	classroom_index = clampi(idx, 0, CLASSROOM_CONFIGS.size() - 1)
	_config = get_classroom_config(classroom_index)
	_soul_type = int(_config.get("soul_type", SoulType.SHOOT_YELLOW)) as SoulType
	harmony = 0.0
	hp = max_hp
	heal_uses_left = 2
	ally_cooldown = 0
	_wave_calm_mult = 1.0
	_menu_index = 0
	_sub_index = 0
	_quiz_index = 0
	_quiz_selected = 0
	_emitted_finished = false
	_dialog_text = str(_config.get("intro_text", ""))
	_eco_quote = str(_config.get("eco_sub", ""))
	_load_ally_textures()
	_reset_dodge_entities()
	phase = Phase.INTRO
	_sync_box_targets(true)
	_queue_redraw_all()

func force_complete_for_test(cleared: bool = true) -> void:
	if cleared:
		harmony = 100.0
		phase = Phase.VICTORY
	_finish(cleared)

func _load_ally_textures() -> void:
	var a_path := str(_config.get("ally_tex", ""))
	_ally_tex = AssetLoader.load_texture(a_path) if not a_path.is_empty() else null
	var s_path := str(_config.get("special_tex", ""))
	_special_tex = AssetLoader.load_texture(s_path) if not s_path.is_empty() else null

func _ready() -> void:
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_audio()
	_build_layers()
	setup_classroom(classroom_index)

func _exit_tree() -> void:
	for sfx in [_sfx_select, _sfx_good, _sfx_hurt]:
		if sfx and is_instance_valid(sfx):
			sfx.stop()
			sfx.stream = null

func _build_audio() -> void:
	_sfx_select = _make_sfx("res://assets/audio/ataque.wav", -6.0)
	_sfx_good = _make_sfx("res://assets/audio/victoria.wav", -5.0)
	_sfx_hurt = _make_sfx("res://assets/audio/herido.wav", -2.0)

func _make_sfx(path: String, vol_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	p.volume_db = vol_db
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(path):
		p.stream = ResourceLoader.load(path) as AudioStream
	add_child(p)
	return p

func _play_sfx(player_sfx: AudioStreamPlayer, pitch: float = 1.0) -> void:
	if player_sfx and player_sfx.stream:
		player_sfx.pitch_scale = pitch
		player_sfx.play()

func _build_layers() -> void:
	_bg_canvas = Control.new()
	_bg_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_bg_canvas.draw.connect(_on_bg_draw)
	add_child(_bg_canvas)

	_box_clip = Control.new()
	_box_clip.clip_contents = true
	_box_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box_clip.draw.connect(_on_box_draw)
	_bg_canvas.add_child(_box_clip)

func _queue_redraw_all() -> void:
	if _bg_canvas:
		_bg_canvas.queue_redraw()
	if _box_clip:
		_box_clip.queue_redraw()

func _get_vp_size() -> Vector2:
	if is_inside_tree() and get_viewport():
		var sz := get_viewport().get_visible_rect().size
		if sz.x > 10.0 and sz.y > 10.0:
			return sz
	return Vector2(800.0, 450.0)

func _get_safe_rect() -> Rect2:
	var vp := _get_vp_size()
	if not is_inside_tree() or get_viewport() == null:
		return Rect2(Vector2(16, 10), vp - Vector2(32, 20))
	var ins := MobileControls.get_safe_insets_for_viewport(get_viewport(), 12.0)
	return Rect2(ins.position.x, ins.position.y, maxf(300.0, vp.x - ins.position.x - ins.size.x), maxf(240.0, vp.y - ins.position.y - ins.size.y))

func _sync_box_targets(snap: bool = false) -> void:
	var sr := _get_safe_rect()
	var cx := sr.get_center().x
	var base_bottom := sr.end.y - 96.0
	if phase == Phase.DODGING:
		var sz: Vector2 = _config.get("box_size", Vector2(264.0, 160.0))
		var bw := minf(sz.x, sr.size.x - 24.0)
		var bh := minf(sz.y, sr.size.y - 210.0)
		_target_box_rect = Rect2(cx - bw * 0.5, base_bottom - bh, bw, bh)
	elif phase == Phase.QUIZ:
		var bw := minf(sr.size.x - 24.0, 560.0)
		var bh := minf(196.0, sr.size.y - 180.0)
		_target_box_rect = Rect2(cx - bw * 0.5, base_bottom - bh, bw, bh)
	else:
		var bw := minf(sr.size.x - 24.0, 560.0)
		var bh := clampf(sr.size.y * 0.28, 112.0, 130.0)
		_target_box_rect = Rect2(cx - bw * 0.5, base_bottom - bh, bw, bh)
	if snap:
		_current_box_rect = _target_box_rect
	_update_box_clip_geometry()

func _update_box_clip_geometry() -> void:
	if _box_clip == null:
		return
	var inner := _current_box_rect.grow(-4.0)
	_box_clip.position = inner.position
	_box_clip.size = Vector2(maxf(8.0, inner.size.x), maxf(8.0, inner.size.y))

func _get_menu_rects() -> Array[Rect2]:
	var sr := _get_safe_rect()
	var y := sr.end.y - 44.0
	var gap := 10.0
	var total_w := minf(sr.size.x - 16.0, 560.0)
	var btn_w := (total_w - gap * 3.0) * 0.25
	var x0 := sr.get_center().x - total_w * 0.5
	var rects: Array[Rect2] = []
	for i in range(4):
		rects.append(Rect2(x0 + float(i) * (btn_w + gap), y, btn_w, 38.0))
	return rects

func _get_sub_rects() -> Array[Rect2]:
	var b := _current_box_rect
	var rects: Array[Rect2] = []
	var w := (b.size.x - 42.0) * 0.5
	for i in range(2):
		rects.append(Rect2(b.position.x + 14.0 + float(i) * (w + 14.0), b.position.y + 42.0, w, 54.0))
	return rects

func _get_quiz_option_rects() -> Array[Rect2]:
	var b := _current_box_rect
	var rects: Array[Rect2] = []
	var top := b.position.y + 46.0
	var row_h := clampf((b.size.y - 50.0) / 3.0, 40.0, 48.0)
	for i in range(3):
		rects.append(Rect2(b.position.x + 14.0, top + float(i) * row_h, b.size.x - 28.0, row_h - 4.0))
	return rects

func _get_standalone_exit_rect() -> Rect2:
	var sr := _get_safe_rect()
	return Rect2(sr.end.x - 76.0, sr.position.y + 4.0, 70.0, 26.0)

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	_time += dt
	if _invuln_timer > 0.0:
		_invuln_timer = maxf(0.0, _invuln_timer - dt)
	if _eco_shake > 0.0:
		_eco_shake = maxf(0.0, _eco_shake - dt * 16.0)
	if _shoot_cooldown > 0.0:
		_shoot_cooldown = maxf(0.0, _shoot_cooldown - dt)

	_sync_box_targets(false)
	var t_lerp := clampf(dt * 14.0, 0.0, 1.0)
	_current_box_rect.position = _current_box_rect.position.lerp(_target_box_rect.position, t_lerp)
	_current_box_rect.size = _current_box_rect.size.lerp(_target_box_rect.size, t_lerp)
	_update_box_clip_geometry()

	if phase == Phase.VALOR_BAR:
		if not _valor_resolved:
			_valor_cursor += _valor_dir * 1.75 * dt
			if _valor_cursor >= 1.0:
				_valor_cursor = 1.0
				_valor_dir = -1.0
			elif _valor_cursor <= -1.0:
				_valor_cursor = -1.0
				_valor_dir = 1.0
		else:
			_valor_result_timer -= dt
			if _valor_result_timer <= 0.0:
				if harmony >= 100.0:
					_enter_ready_menu()
				else:
					phase = Phase.DIALOG
	elif phase == Phase.DODGING:
		_update_dodging(dt)

	_queue_redraw_all()

func _reset_dodge_entities() -> void:
	_drag_touch_id = -1
	_mouse_dragging = false
	_sync_box_targets(true)
	var b := _target_box_rect
	_soul_pos = b.get_center()
	_shoot_cooldown = 0.0
	_hazards.clear()
	_good_items.clear()
	_pulses.clear()
	_spawn_a = 0.0
	_spawn_b = 0.0
	_step_counter = 0
	_pass_ring_active = false

	match _soul_type:
		SoulType.SHOOT_YELLOW:
			_soul_pos = Vector2(b.get_center().x, b.end.y - 22.0)
		SoulType.DODGE_RED:
			if classroom_index == 5:
				_pass_ring_active = true
				_pass_ring_pos = Vector2(b.end.x - 34.0, b.position.y + 34.0)
				_hazards.append({"pos": Vector2(b.position.x + 36.0, b.get_center().y), "vel": Vector2(78.0, 62.0), "r": 9.0, "kind": "ball", "life": 15.0})
				_hazards.append({"pos": Vector2(b.end.x - 36.0, b.get_center().y), "vel": Vector2(-72.0, -64.0), "r": 9.0, "kind": "ball", "life": 15.0})

func _start_dodging_wave() -> void:
	if _soul_type == SoulType.QUIZ_VALUES:
		phase = Phase.QUIZ
		_quiz_selected = 0
		_sync_box_targets(false)
		return
	_reset_dodge_entities()
	_wave_left = WAVE_DURATION
	phase = Phase.DODGING

func _enter_ready_menu() -> void:
	_drag_touch_id = -1
	_mouse_dragging = false
	_dialog_text = "* 100% de Armonía. El botón PIEDAD brilla en dorado."
	_eco_quote = str(_config.get("pity_win_quote", ""))
	phase = Phase.MENU
	_menu_index = 3

func _add_harmony(amount: float) -> void:
	harmony = clampf(harmony + amount, 0.0, 100.0)

func _update_dodging(dt: float) -> void:
	var b := _target_box_rect
	_wave_left -= dt
	if _wave_left <= 0.0:
		_drag_touch_id = -1
		_mouse_dragging = false
		_wave_calm_mult = 1.0
		if harmony >= 100.0:
			_enter_ready_menu()
		else:
			_dialog_text = "* %s baja el tono. (Armonía: %d%%)" % [str(_config.get("eco_name", "El Eco")), int(round(harmony))]
			phase = Phase.MENU
		return

	_update_soul_movement(dt, b)
	_spawn_soul_entities(dt, b)
	_update_soul_entities(dt, b)

	if hp <= 0:
		phase = Phase.DEFEAT
		_dialog_text = "* Respira hondo. Aquí nadie pierde para siempre; inténtalo de nuevo."

func _read_directional_input() -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v.length_squared() > 0.01:
		return v
	var dx := 0.0
	var dy := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dx -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dx += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dy -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dy += 1.0
	var out := Vector2(dx, dy)
	return out.normalized() if out.length_squared() > 1.0 else out

func _update_soul_movement(dt: float, b: Rect2) -> void:
	var pad := 12.0
	var inp := _read_directional_input()
	var spd := 190.0 if not Input.is_key_pressed(KEY_SHIFT) else 108.0
	_soul_pos += inp * spd * dt
	_soul_pos.x = clampf(_soul_pos.x, b.position.x + pad, b.end.x - pad)
	if _soul_type == SoulType.SHOOT_YELLOW:
		_soul_pos.y = clampf(_soul_pos.y, b.get_center().y - 10.0, b.end.y - pad)
		if _shoot_cooldown <= 0.0:
			_fire_lantern_pulse()
	else:
		_soul_pos.y = clampf(_soul_pos.y, b.position.y + pad, b.end.y - pad)

func _fire_lantern_pulse() -> void:
	if _shoot_cooldown > 0.0 or phase != Phase.DODGING:
		return
	_shoot_cooldown = 0.30
	_pulses.append({"pos": _soul_pos + Vector2(0, -10.0), "vel": Vector2(0, -320.0), "life": 1.1})
	_play_sfx(_sfx_select, 1.35)

func _spawn_soul_entities(dt: float, b: Rect2) -> void:
	var sp := _wave_calm_mult * (0.86 if MobileControls.is_touch_device() else 1.0)
	_spawn_a += dt
	_spawn_b += dt

	match _soul_type:
		SoulType.SHOOT_YELLOW:
			if _spawn_a >= 0.78:
				_spawn_a = 0.0
				_step_counter += 1
				var rx := lerpf(b.position.x + 24.0, b.end.x - 24.0, fmod(float(_step_counter) * 0.31 + 0.15, 1.0))
				var kind_str := "bubble" if classroom_index == 0 else "rumor"
				_hazards.append({"pos": Vector2(rx, b.position.y + 8.0), "vel": Vector2(sin(float(_step_counter)) * 20.0, 56.0 * sp), "r": 10.5, "kind": kind_str, "life": 4.2})
		SoulType.DODGE_RED:
			if classroom_index == 2:
				if _spawn_a >= 0.72:
					_spawn_a = 0.0
					_step_counter += 1
					var from_l := (_step_counter % 2 == 0)
					var sx := (b.position.x - 8.0) if from_l else (b.end.x + 8.0)
					var vx := (140.0 if from_l else -140.0) * sp
					var ry := lerpf(b.position.y + 22.0, b.end.y - 22.0, fmod(float(_step_counter) * 0.37 + 0.1, 1.0))
					_hazards.append({"pos": Vector2(sx, ry), "vel": Vector2(vx, 0.0), "r": 7.5, "kind": "wave", "life": 3.2})
				if _spawn_b >= 1.55:
					_spawn_b = 0.0
					var gx := randf_range(b.position.x + 28.0, b.end.x - 28.0)
					var gy := randf_range(b.position.y + 26.0, b.end.y - 26.0)
					_good_items.append({"pos": Vector2(gx, gy), "vel": Vector2.ZERO, "life": 4.0})
			else:
				if _spawn_a >= 1.15:
					_spawn_a = 0.0
					_step_counter += 1
					var rx := randf_range(b.position.x + 24.0, b.end.x - 24.0)
					_hazards.append({"pos": Vector2(rx, b.position.y + 8.0), "vel": Vector2(0.0, 88.0 * sp), "r": 6.5, "kind": "wave", "life": 3.0})

func _update_soul_entities(dt: float, b: Rect2) -> void:
	for pi in range(_pulses.size() - 1, -1, -1):
		var pl: Dictionary = _pulses[pi]
		pl["pos"] = (pl["pos"] as Vector2) + (pl["vel"] as Vector2) * dt
		pl["life"] = float(pl["life"]) - dt
		var ppos := pl["pos"] as Vector2
		if float(pl["life"]) <= 0.0 or ppos.y < b.position.y:
			_pulses.remove_at(pi)
			continue
		var consumed := false
		for hi in range(_hazards.size() - 1, -1, -1):
			var hz: Dictionary = _hazards[hi]
			if ppos.distance_squared_to(hz["pos"] as Vector2) <= 324.0:
				_hazards.remove_at(hi)
				_add_harmony(12.0)
				_play_sfx(_sfx_good, 1.25)
				consumed = true
				break
		if consumed:
			_pulses.remove_at(pi)

	for gi in range(_good_items.size() - 1, -1, -1):
		var g: Dictionary = _good_items[gi]
		g["pos"] = (g["pos"] as Vector2) + (g["vel"] as Vector2) * dt
		g["life"] = float(g["life"]) - dt
		var gpos := g["pos"] as Vector2
		if float(g["life"]) <= 0.0:
			_good_items.remove_at(gi)
			continue
		if gpos.distance_squared_to(_soul_pos) <= 361.0:
			_add_harmony(16.0)
			_play_sfx(_sfx_good, 1.25)
			_good_items.remove_at(gi)

	if _pass_ring_active:
		if _soul_pos.distance_squared_to(_pass_ring_pos) <= 400.0:
			_add_harmony(18.0)
			_play_sfx(_sfx_good, 1.25)
			var corners: Array[Vector2] = [
				Vector2(b.position.x + 34.0, b.position.y + 34.0),
				Vector2(b.end.x - 34.0, b.end.y - 34.0),
				Vector2(b.position.x + 34.0, b.end.y - 34.0),
				Vector2(b.end.x - 34.0, b.position.y + 34.0),
			]
			_step_counter += 1
			_pass_ring_pos = corners[_step_counter % corners.size()]

	var soul_r := 4.8
	for hi in range(_hazards.size() - 1, -1, -1):
		var hz: Dictionary = _hazards[hi]
		var hpos := (hz["pos"] as Vector2) + (hz["vel"] as Vector2) * dt
		var kind := str(hz.get("kind", "wave"))
		if kind == "ball":
			var hvel := hz["vel"] as Vector2
			if hpos.x < b.position.x + 12.0 or hpos.x > b.end.x - 12.0:
				hvel.x = -hvel.x
				hpos.x = clampf(hpos.x, b.position.x + 12.0, b.end.x - 12.0)
			if hpos.y < b.position.y + 12.0 or hpos.y > b.end.y - 12.0:
				hvel.y = -hvel.y
				hpos.y = clampf(hpos.y, b.position.y + 12.0, b.end.y - 12.0)
			hz["vel"] = hvel
		hz["pos"] = hpos
		hz["life"] = float(hz["life"]) - dt
		if float(hz["life"]) <= 0.0:
			_hazards.remove_at(hi)
			continue
		if _invuln_timer > 0.0:
			continue
		var r_sum := soul_r + float(hz.get("r", 7.0))
		if _soul_pos.distance_squared_to(hpos) <= r_sum * r_sum:
			_take_soul_damage(4)
			if kind != "ball":
				_hazards.remove_at(hi)

func _take_soul_damage(amount: int) -> void:
	if _invuln_timer > 0.0:
		return
	var dmg := maxi(1, amount - (1 if MobileControls.is_touch_device() else 0))
	hp = maxi(0, hp - dmg)
	_invuln_timer = 0.90
	_eco_shake = 4.0
	_play_sfx(_sfx_hurt, 1.0)

func _select_menu(visual_slot: int) -> void:
	_menu_index = clampi(visual_slot, 0, 3)
	_execute_logical_menu(_menu_index)

func _execute_logical_menu(logical_action: int) -> void:
	match logical_action:
		0: # VALOR
			_valor_cursor = -0.96
			_valor_dir = 1.0
			_valor_resolved = false
			phase = Phase.VALOR_BAR
			_play_sfx(_sfx_select, 1.15)
		1: # ACT
			_sub_index = 0
			phase = Phase.SUB_ACT
			_play_sfx(_sfx_select, 1.1)
		2: # ITEM
			if heal_uses_left <= 0:
				_dialog_text = "* Ya compartiste todos los termos de descanso."
				phase = Phase.DIALOG
			else:
				heal_uses_left -= 1
				hp = mini(max_hp, hp + 14)
				_dialog_text = "* Tomas un sorbo de atole caliente y respiras hondo. (+14 HP)"
				_play_sfx(_sfx_good, 1.1)
				phase = Phase.DIALOG
		3: # PIEDAD
			if harmony >= 100.0:
				_dialog_text = "* %s queda en paz.\n* «%s»" % [str(_config.get("eco_name", "El salón")), str(_config.get("pity_win_quote", ""))]
				_eco_quote = str(_config.get("pity_win_quote", ""))
				_play_sfx(_sfx_good, 1.35)
				phase = Phase.VICTORY
			else:
				_dialog_text = "* Aún falta armonía (%d%% / 100%%). Usa VALOR o ACT.\n* «%s»" % [int(round(harmony)), str(_config.get("pity_fail_quote", ""))]
				_play_sfx(_sfx_select, 0.9)
				phase = Phase.DIALOG

func _resolve_valor_bar() -> void:
	if _valor_resolved:
		return
	_valor_resolved = true
	_valor_result_timer = 0.50
	var dist := absf(_valor_cursor)
	var gain := 20.0
	var quality := "BUEN INTENTO"
	if dist <= 0.24:
		gain = 50.0
		quality = "PRECISIÓN PERFECTA"
	elif dist <= 0.56:
		gain = 35.0
		quality = "BUEN RITMO"
	_add_harmony(gain)
	_wave_calm_mult = 0.78
	_dialog_text = "%s\n%s (+%d%% Armonía)" % [quality, str(_config.get("ally_msg", "* Tu compañero apoya al equipo.")), int(round(gain))]
	_eco_quote = "Cuando nos apoyamos, el ambiente cambia por completo."
	_play_sfx(_sfx_good, 1.25 if gain >= 45.0 else 1.05)

func _activate_act(act_idx: int) -> void:
	var acts: Array = _config.get("acts", [])
	if act_idx < 0 or act_idx >= acts.size():
		return
	var a: Dictionary = acts[act_idx]
	_add_harmony(float(a.get("harmony", 45.0)))
	_wave_calm_mult = 0.80
	_dialog_text = str(a.get("msg", ""))
	_eco_quote = str(a.get("quote", ""))
	_play_sfx(_sfx_good, 1.15)
	if harmony >= 100.0:
		_enter_ready_menu()
	else:
		phase = Phase.DIALOG

func answer_quiz(opt_idx: int) -> void:
	var questions: Array = _config.get("questions", [])
	if questions.is_empty():
		_enter_ready_menu()
		return
	var q: Dictionary = questions[_quiz_index % questions.size()]
	var opts: Array = q.get("options", [])
	if opt_idx < 0 or opt_idx >= opts.size():
		return
	var chosen: Dictionary = opts[opt_idx]
	if bool(chosen.get("good", false)):
		_add_harmony(50.0)
		_play_sfx(_sfx_good, 1.25)
	else:
		hp = maxi(0, hp - 4)
		_eco_shake = 3.5
		_add_harmony(15.0)
		_play_sfx(_sfx_hurt, 1.0)
	_quiz_index += 1
	_dialog_text = str(chosen.get("react", ""))
	if hp <= 0:
		phase = Phase.DEFEAT
		_dialog_text = "* Respira hondo. Aquí nadie pierde para siempre; inténtalo de nuevo."
	elif harmony >= 100.0:
		_enter_ready_menu()
	else:
		phase = Phase.MENU

func _input(event: InputEvent) -> void:
	if _emitted_finished:
		return
	var is_real_mouse := event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION
	var is_real_touch := (event is InputEventScreenTouch or event is InputEventScreenDrag) and event.device != InputEvent.DEVICE_ID_EMULATION

	if allow_standalone_exit:
		var hit_exit := false
		if is_real_mouse and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			hit_exit = _get_standalone_exit_rect().has_point((event as InputEventMouseButton).position)
		elif event is InputEventScreenTouch and is_real_touch and (event as InputEventScreenTouch).pressed:
			hit_exit = _get_standalone_exit_rect().has_point((event as InputEventScreenTouch).position)
		if hit_exit:
			_finish(false)
			_mark_handled()
			return

	if phase == Phase.DODGING:
		_handle_dodging_input(event, is_real_mouse, is_real_touch)
		return

	var confirm := false
	var back := false
	var dx := 0
	var dy := 0

	if event is InputEventKey and event.pressed and not event.echo:
		if phase == Phase.QUIZ:
			match event.keycode:
				KEY_1:
					answer_quiz(0)
					_mark_handled()
					return
				KEY_2:
					answer_quiz(1)
					_mark_handled()
					return
				KEY_3:
					answer_quiz(2)
					_mark_handled()
					return
		match event.keycode:
			KEY_LEFT, KEY_A: dx = -1
			KEY_RIGHT, KEY_D: dx = 1
			KEY_UP, KEY_W: dy = -1
			KEY_DOWN, KEY_S: dy = 1
			KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_Z: confirm = true
			KEY_ESCAPE, KEY_X: back = true
	elif event is InputEventJoypadButton and event.pressed and not event.is_echo():
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT: dx = -1
			JOY_BUTTON_DPAD_RIGHT: dx = 1
			JOY_BUTTON_DPAD_UP: dy = -1
			JOY_BUTTON_DPAD_DOWN: dy = 1
			JOY_BUTTON_A, JOY_BUTTON_START: confirm = true
			JOY_BUTTON_B, JOY_BUTTON_X: back = true
	elif (is_real_mouse and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and is_real_touch and (event as InputEventScreenTouch).pressed):
		var pos: Vector2 = (event as InputEventMouseButton).position if event is InputEventMouseButton else (event as InputEventScreenTouch).position
		var now_ms := Time.get_ticks_msec()
		if now_ms - _pointer_cooldown_ms >= 90:
			_pointer_cooldown_ms = now_ms
			_handle_pointer_press(pos)
			_mark_handled()
		return

	match phase:
		Phase.INTRO:
			if confirm:
				phase = Phase.MENU
				_mark_handled()
		Phase.MENU:
			if dx != 0:
				_menu_index = posmod(_menu_index + dx, 4)
				_play_sfx(_sfx_select, 1.0)
				_mark_handled()
			elif confirm:
				_select_menu(_menu_index)
				_mark_handled()
		Phase.SUB_ACT:
			if dx != 0 or dy != 0:
				_sub_index = posmod(_sub_index + dx + dy, 2)
				_play_sfx(_sfx_select, 1.0)
				_mark_handled()
			elif back:
				phase = Phase.MENU
				_mark_handled()
			elif confirm:
				_activate_act(_sub_index)
				_mark_handled()
		Phase.QUIZ:
			if dy != 0:
				_quiz_selected = posmod(_quiz_selected + dy, 3)
				_play_sfx(_sfx_select, 1.0)
				_mark_handled()
			elif back:
				phase = Phase.MENU
				_mark_handled()
			elif confirm:
				answer_quiz(_quiz_selected)
				_mark_handled()
		Phase.VALOR_BAR:
			if confirm and not _valor_resolved:
				_resolve_valor_bar()
				_mark_handled()
		Phase.DIALOG:
			if confirm:
				if harmony >= 100.0:
					_enter_ready_menu()
				else:
					_start_dodging_wave()
				_mark_handled()
		Phase.DEFEAT:
			if confirm:
				setup_classroom(classroom_index)
				_mark_handled()
			elif back:
				_finish(false)
				_mark_handled()
		Phase.VICTORY:
			if confirm:
				_finish(true)
				_mark_handled()

func _handle_dodging_input(event: InputEvent, is_real_mouse: bool, is_real_touch: bool) -> void:
	if _soul_type == SoulType.SHOOT_YELLOW and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_Z, KEY_ENTER]:
			_fire_lantern_pulse()

	if is_real_mouse:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_mouse_dragging = mb.pressed
			_last_mouse_pos = mb.position
			if mb.pressed and _soul_type == SoulType.SHOOT_YELLOW:
				_fire_lantern_pulse()
			_mark_handled()
			return
	elif event is InputEventMouseMotion and _mouse_dragging and event.device != InputEvent.DEVICE_ID_EMULATION:
		var mm := event as InputEventMouseMotion
		_move_soul_by_delta((mm.position - _last_mouse_pos) * 1.15)
		_last_mouse_pos = mm.position
		_mark_handled()
		return

	if event is InputEventScreenTouch and is_real_touch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if _soul_type == SoulType.SHOOT_YELLOW:
				_fire_lantern_pulse()
			if _drag_touch_id == -1:
				_drag_touch_id = st.index
				_last_touch_pos = st.position
		elif st.index == _drag_touch_id:
			_drag_touch_id = -1
	elif event is InputEventScreenDrag and is_real_touch:
		var sd := event as InputEventScreenDrag
		if sd.index == _drag_touch_id:
			_move_soul_by_delta((sd.position - _last_touch_pos) * 1.15)
			_last_touch_pos = sd.position

func _move_soul_by_delta(delta_d: Vector2) -> void:
	var b := _target_box_rect
	_soul_pos.x = clampf(_soul_pos.x + delta_d.x, b.position.x + 12.0, b.end.x - 12.0)
	if _soul_type == SoulType.SHOOT_YELLOW:
		_soul_pos.y = clampf(_soul_pos.y + delta_d.y, b.get_center().y - 10.0, b.end.y - 12.0)
	else:
		_soul_pos.y = clampf(_soul_pos.y + delta_d.y, b.position.y + 12.0, b.end.y - 12.0)

func _handle_pointer_press(pos: Vector2) -> void:
	match phase:
		Phase.INTRO:
			phase = Phase.MENU
		Phase.MENU:
			var rects := _get_menu_rects()
			for i in range(rects.size()):
				if rects[i].has_point(pos):
					_select_menu(i)
					return
		Phase.SUB_ACT:
			var srects := _get_sub_rects()
			for i in range(srects.size()):
				if srects[i].has_point(pos):
					_activate_act(i)
					return
			var mrects := _get_menu_rects()
			for i in range(mrects.size()):
				if mrects[i].has_point(pos):
					phase = Phase.MENU
					return
		Phase.QUIZ:
			var qrects := _get_quiz_option_rects()
			for i in range(qrects.size()):
				if qrects[i].has_point(pos):
					answer_quiz(i)
					return
		Phase.VALOR_BAR:
			if not _valor_resolved:
				_resolve_valor_bar()
		Phase.DIALOG:
			if harmony >= 100.0:
				_enter_ready_menu()
			else:
				_start_dodging_wave()
		Phase.DEFEAT:
			setup_classroom(classroom_index)
		Phase.VICTORY:
			_finish(true)

func _mark_handled() -> void:
	if is_inside_tree() and get_viewport():
		get_viewport().set_input_as_handled()

func _finish(cleared: bool) -> void:
	if _emitted_finished:
		return
	_emitted_finished = true
	minigame_finished.emit(cleared, classroom_index)
	queue_free()

func _draw_pixel_heart(target: Control, center: Vector2, col: Color, px: float = 2.0, inverted: bool = false) -> void:
	var rows := HEART_ROWS
	var row_count := rows.size()
	for ry in range(row_count):
		var line: String = rows[row_count - 1 - ry] if inverted else rows[ry]
		for rx in range(line.length()):
			if line[rx] == "X":
				var pt := center + Vector2((float(rx) - 4.0) * px, (float(ry) - 3.5) * px)
				target.draw_rect(Rect2(pt, Vector2(px, px)), col)

func _on_bg_draw() -> void:
	var vp := _get_vp_size()
	var sr := _get_safe_rect()
	var font := ThemeDB.fallback_font

	# Fondo negro 100% opaco estilo Undertale
	_bg_canvas.draw_rect(Rect2(Vector2.ZERO, vp), Color.BLACK)

	# Cabecera limpia con retrato del aliado encuadrado (sin flotar en bordes)
	var title_x := sr.position.x + 8.0
	if _ally_tex != null:
		var icon_r := Rect2(title_x, sr.position.y + 4.0, 26.0, 26.0)
		_bg_canvas.draw_rect(icon_r, Color(0.08, 0.10, 0.16))
		_bg_canvas.draw_texture_rect(_ally_tex, icon_r.grow(-2.0), false)
		_bg_canvas.draw_rect(icon_r, Color(1.0, 0.65, 0.25), false, 1.5)
		title_x += 34.0
	_bg_canvas.draw_string(font, Vector2(title_x, sr.position.y + 15.0), str(_config.get("classroom_name", "Salón")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.82, 0.90, 1.0))
	_bg_canvas.draw_string(font, Vector2(title_x, sr.position.y + 29.0), "Aliado: %s" % str(_config.get("ally", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.86, 0.42))

	if phase == Phase.DODGING:
		var t_str := "TIEMPO: %.1fs" % maxf(0.0, _wave_left)
		_bg_canvas.draw_string(font, Vector2(sr.get_center().x - 42.0, sr.position.y + 20.0), t_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 0.96, 1.0))
	elif phase == Phase.QUIZ:
		var q_str := "PREGUNTA %d / 3" % mini(3, _quiz_index + 1)
		_bg_canvas.draw_string(font, Vector2(sr.get_center().x - 46.0, sr.position.y + 20.0), q_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 0.96, 1.0))

	var bar_w := 142.0
	var bar_x := sr.end.x - bar_w - (84.0 if allow_standalone_exit else 8.0)
	_bg_canvas.draw_string(font, Vector2(bar_x, sr.position.y + 14.0), "ARMONÍA %d%%" % int(round(harmony)), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.92, 0.35) if harmony >= 100.0 else Color.WHITE)
	_bg_canvas.draw_rect(Rect2(bar_x, sr.position.y + 19.0, bar_w, 10.0), Color(0.18, 0.18, 0.22))
	_bg_canvas.draw_rect(Rect2(bar_x, sr.position.y + 19.0, bar_w * (harmony / 100.0), 10.0), Color(0.24, 0.92, 0.48) if harmony < 100.0 else Color(1.0, 0.88, 0.22))
	_bg_canvas.draw_rect(Rect2(bar_x, sr.position.y + 19.0, bar_w, 10.0), Color.WHITE, false, 1.5)

	if allow_standalone_exit:
		var er := _get_standalone_exit_rect()
		_bg_canvas.draw_rect(er, Color.BLACK)
		_bg_canvas.draw_rect(er, Color(1.0, 0.55, 0.14), false, 2.0)
		_bg_canvas.draw_string(font, Vector2(er.position.x + 15.0, er.position.y + 17.0), "Salir", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

	# Eco Escolar B&N pixel-art arriba de la caja + globo de diálogo blanco
	var eco_y := maxf(sr.position.y + 84.0, _current_box_rect.position.y - 58.0)
	var eco_pos := Vector2(sr.get_center().x + randf_range(-_eco_shake, _eco_shake), eco_y + sin(_time * 2.2) * 2.0)
	_draw_eco_bw_sprite(eco_pos)
	if not _eco_quote.is_empty():
		var bubble := Rect2(eco_pos.x + 48.0, eco_pos.y - 34.0, minf(216.0, sr.end.x - (eco_pos.x + 54.0)), 50.0)
		if bubble.size.x >= 96.0:
			_bg_canvas.draw_rect(bubble, Color.WHITE)
			_bg_canvas.draw_polygon(PackedVector2Array([
				Vector2(bubble.position.x, bubble.position.y + 16.0),
				Vector2(bubble.position.x - 9.0, bubble.position.y + 22.0),
				Vector2(bubble.position.x, bubble.position.y + 28.0),
			]), [Color.WHITE])
			_draw_wrapped_text(_bg_canvas, font, Vector2(bubble.position.x + 8.0, bubble.position.y + 14.0), bubble.size.x - 14.0, _eco_quote, 10, Color.BLACK)

	if _special_tex != null and (phase == Phase.DIALOG or phase == Phase.VALOR_BAR):
		_bg_canvas.draw_texture_rect(_special_tex, Rect2(eco_pos + Vector2(-84, -22), Vector2(40, 40)), false)

	# Pista FUERA y ARRIBA de la caja blanca para que nada la tape
	if phase == Phase.DODGING or phase == Phase.QUIZ:
		var hint_s := str(_config.get("dodge_hint", ""))
		_bg_canvas.draw_string(font, Vector2(sr.position.x, _current_box_rect.position.y - 8.0), hint_s, HORIZONTAL_ALIGNMENT_CENTER, int(sr.size.x), 11, Color(0.76, 0.90, 1.0))

	# Borde blanco 4px clásico de la caja Undertale
	_bg_canvas.draw_rect(_current_box_rect, Color.BLACK)
	_bg_canvas.draw_rect(_current_box_rect, Color.WHITE, false, 4.0)

	# Barra inferior anclada al ancho fijo de los 4 botones (cero solapamiento con el cuadro)
	var mrects := _get_menu_rects()
	var row_left := mrects[0].position.x
	var row_right := mrects[3].end.x
	var hp_y := _current_box_rect.end.y + 22.0
	_bg_canvas.draw_string(font, Vector2(row_left, hp_y), "GUARDIÁN   LV 1   HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	var hp_bar := Rect2(row_left + 160.0, hp_y - 12.0, 96.0, 14.0)
	_bg_canvas.draw_rect(hp_bar, Color(0.85, 0.12, 0.14))
	_bg_canvas.draw_rect(Rect2(hp_bar.position, Vector2(hp_bar.size.x * (float(hp) / float(max_hp)), hp_bar.size.y)), Color(1.0, 0.92, 0.18))
	_bg_canvas.draw_string(font, Vector2(hp_bar.end.x + 10.0, hp_y), "%d / %d" % [hp, max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	var badge := str(_config.get("mode_badge", ""))
	_bg_canvas.draw_string(font, Vector2(row_right - 120.0, hp_y), badge, HORIZONTAL_ALIGNMENT_RIGHT, 120, 11, Color(0.75, 0.90, 1.0))

	# 4 botones naranjas clásicos de Undertale
	var icons: Array[String] = ["★", ")))", "♠", "×"]
	for slot in range(4):
		var r := mrects[slot]
		var sel := (phase == Phase.MENU and slot == _menu_index)
		var pity_ready := (slot == 3 and harmony >= 100.0)
		var col := Color(1.0, 0.92, 0.22) if (sel or pity_ready) else Color(1.0, 0.52, 0.12)
		_bg_canvas.draw_rect(r, Color.BLACK)
		_bg_canvas.draw_rect(r, col, false, 2.5 if (sel or pity_ready) else 2.0)
		if sel:
			_draw_pixel_heart(_bg_canvas, Vector2(r.position.x + 16.0, r.position.y + 19.0), Color(1.0, 0.15, 0.22), 1.6)
		else:
			_bg_canvas.draw_string(font, Vector2(r.position.x + 10.0, r.position.y + 24.0), icons[slot], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
		var lbl: String = str(MENU_BASE_LABELS[slot])
		if slot == 2:
			lbl = "ITEM(%d)" % heal_uses_left
		_bg_canvas.draw_string(font, Vector2(r.position.x + 32.0, r.position.y + 25.0), lbl, HORIZONTAL_ALIGNMENT_LEFT, int(r.size.x - 36.0), 13, col)

func _draw_eco_bw_sprite(center: Vector2) -> void:
	var happy := (harmony >= 70.0)
	match classroom_index:
		0: # Matraz Murmullo
			_bg_canvas.draw_rect(Rect2(center + Vector2(-8, -30), Vector2(16, 12)), Color.WHITE)
			_bg_canvas.draw_polygon(PackedVector2Array([
				center + Vector2(-8, -18), center + Vector2(8, -18),
				center + Vector2(24, 22), center + Vector2(-24, 22),
			]), [Color.WHITE])
			_draw_eco_face(center + Vector2(0, 4), happy)
		1: # Torre de Charolas
			for k in range(3):
				var ox := sin(_time * 2.5 + float(k)) * (1.0 if happy else 3.5)
				_bg_canvas.draw_rect(Rect2(center + Vector2(-24 + ox, -20 + float(k) * 14.0), Vector2(48, 11)), Color.WHITE)
			_draw_eco_face(center + Vector2(0, -2), happy)
		2: # Micrófono Acoplado
			_bg_canvas.draw_circle(center + Vector2(0, -14), 14.0, Color.WHITE)
			_bg_canvas.draw_rect(Rect2(center + Vector2(-4, 0), Vector2(8, 22)), Color.WHITE)
			_bg_canvas.draw_rect(Rect2(center + Vector2(-16, 20), Vector2(32, 6)), Color.WHITE)
			_draw_eco_face(center + Vector2(0, -14), happy)
		3: # Hilo Viral
			_bg_canvas.draw_rect(Rect2(center + Vector2(-22, -26), Vector2(44, 50)), Color.WHITE)
			_bg_canvas.draw_rect(Rect2(center + Vector2(-18, -20), Vector2(36, 36)), Color.BLACK)
			_bg_canvas.draw_circle(center + Vector2(-7, -6), 3.5, Color.WHITE)
			_bg_canvas.draw_circle(center + Vector2(7, -6), 3.5, Color.WHITE)
			if happy:
				_bg_canvas.draw_arc(center + Vector2(0, 2), 6.0, 0.2, PI - 0.2, 8, Color.WHITE, 2.0)
			else:
				_bg_canvas.draw_line(center + Vector2(-7, 5), center + Vector2(7, 5), Color.WHITE, 2.0)
		4: # Ventana Atajo.exe
			_bg_canvas.draw_rect(Rect2(center + Vector2(-28, -22), Vector2(56, 44)), Color.WHITE)
			_bg_canvas.draw_rect(Rect2(center + Vector2(-24, -10), Vector2(48, 28)), Color.BLACK)
			_bg_canvas.draw_rect(Rect2(center + Vector2(-11, -3), Vector2(5, 7)), Color.WHITE)
			_bg_canvas.draw_rect(Rect2(center + Vector2(6, -3), Vector2(5, 7)), Color.WHITE)
			if happy:
				_bg_canvas.draw_arc(center + Vector2(0, 5), 6.0, 0.2, PI - 0.2, 8, Color.WHITE, 2.0)
			else:
				_bg_canvas.draw_line(center + Vector2(-7, 9), center + Vector2(7, 9), Color.WHITE, 2.0)
		5, _: # Sombras de la Grada
			_bg_canvas.draw_circle(center + Vector2(0, -16), 14.0, Color.WHITE)
			_bg_canvas.draw_rect(Rect2(center + Vector2(-16, -2), Vector2(32, 26)), Color.WHITE)
			_draw_eco_face(center + Vector2(0, -16), happy)

func _draw_eco_face(pos: Vector2, happy: bool) -> void:
	if happy:
		_bg_canvas.draw_line(pos + Vector2(-10, -2), pos + Vector2(-6, -6), Color.BLACK, 2.0)
		_bg_canvas.draw_line(pos + Vector2(-6, -6), pos + Vector2(-2, -2), Color.BLACK, 2.0)
		_bg_canvas.draw_line(pos + Vector2(2, -2), pos + Vector2(6, -6), Color.BLACK, 2.0)
		_bg_canvas.draw_line(pos + Vector2(6, -6), pos + Vector2(10, -2), Color.BLACK, 2.0)
		_bg_canvas.draw_arc(pos + Vector2(0, 2), 6.0, 0.2, PI - 0.2, 8, Color.BLACK, 2.0)
	else:
		_bg_canvas.draw_rect(Rect2(pos + Vector2(-9, -4), Vector2(5, 5)), Color.BLACK)
		_bg_canvas.draw_rect(Rect2(pos + Vector2(4, -4), Vector2(5, 5)), Color.BLACK)
		_bg_canvas.draw_line(pos + Vector2(-6, 6), pos + Vector2(6, 6), Color.BLACK, 2.0)

func _on_box_draw() -> void:
	var off := _box_clip.position
	var bsz := _box_clip.size
	var font := ThemeDB.fallback_font
	var soul_col: Color = _config.get("soul_color", Color(1.0, 0.2, 0.25))

	if phase == Phase.VALOR_BAR:
		var c := bsz * 0.5
		var half_w := bsz.x * 0.44
		var half_h := bsz.y * 0.34
		var green_w := half_w * 0.24
		var yel_w := half_w * 0.56
		_box_clip.draw_rect(Rect2(c.x - half_w, c.y - half_h, half_w * 2.0, half_h * 2.0), Color(0.75, 0.16, 0.18))
		_box_clip.draw_rect(Rect2(c.x - yel_w, c.y - half_h, yel_w * 2.0, half_h * 2.0), Color(0.95, 0.85, 0.20))
		_box_clip.draw_rect(Rect2(c.x - green_w, c.y - half_h, green_w * 2.0, half_h * 2.0), Color(0.20, 0.90, 0.38))
		_box_clip.draw_rect(Rect2(c.x - half_w, c.y - half_h, half_w * 2.0, half_h * 2.0), Color.WHITE, false, 2.5)
		var cx := c.x + _valor_cursor * (half_w - 6.0)
		_box_clip.draw_rect(Rect2(cx - 4.0, c.y - half_h - 4.0, 8.0, half_h * 2.0 + 8.0), Color.WHITE)
		_box_clip.draw_string(font, Vector2(14.0, 18.0), "Pulsa Espacio o toca la zona VERDE para unir fuerzas con %s" % str(_config.get("ally", "")), HORIZONTAL_ALIGNMENT_LEFT, int(bsz.x - 24.0), 11, Color.WHITE)
		return

	if phase == Phase.SUB_ACT:
		_box_clip.draw_string(font, Vector2(14.0, 20.0), "Elige cómo responder con respeto:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.92, 0.35))
		var srects := _get_sub_rects()
		var acts: Array = _config.get("acts", [])
		for i in range(mini(2, acts.size())):
			var lr := Rect2(srects[i].position - off, srects[i].size)
			var sel := (i == _sub_index)
			_box_clip.draw_rect(lr, Color(0.10, 0.12, 0.18) if sel else Color.BLACK)
			_box_clip.draw_rect(lr, Color(1.0, 0.90, 0.25) if sel else Color(0.65, 0.65, 0.72), false, 2.0 if sel else 1.0)
			if sel:
				_draw_pixel_heart(_box_clip, Vector2(lr.position.x + 14.0, lr.position.y + 26.0), Color(1.0, 0.16, 0.22), 1.5)
			_box_clip.draw_string(font, Vector2(lr.position.x + 28.0, lr.position.y + 31.0), str(acts[i].get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, int(lr.size.x - 32.0), 12, Color.WHITE)
		return

	if phase == Phase.QUIZ:
		var questions: Array = _config.get("questions", [])
		if questions.is_empty():
			return
		var q: Dictionary = questions[_quiz_index % questions.size()]
		_draw_wrapped_text(_box_clip, font, Vector2(12.0, 18.0), bsz.x - 24.0, "* " + str(q.get("prompt", "")), 11, Color.WHITE)
		var qrects := _get_quiz_option_rects()
		var opts: Array = q.get("options", [])
		for i in range(mini(3, opts.size())):
			var lr := Rect2(qrects[i].position - off, qrects[i].size)
			var sel := (i == _quiz_selected)
			_box_clip.draw_rect(lr, Color(0.10, 0.12, 0.18) if sel else Color.BLACK)
			_box_clip.draw_rect(lr, Color(1.0, 0.90, 0.25) if sel else Color(1.0, 0.55, 0.14), false, 2.0 if sel else 1.5)
			if sel:
				_draw_pixel_heart(_box_clip, Vector2(lr.position.x + 14.0, lr.position.y + lr.size.y * 0.5), Color(1.0, 0.16, 0.22), 1.4)
			_draw_wrapped_text(_box_clip, font, Vector2(lr.position.x + 28.0, lr.position.y + 16.0), lr.size.x - 36.0, "%d) %s" % [i + 1, str(opts[i].get("label", ""))], 11, Color.WHITE)
		return

	if phase != Phase.DODGING:
		_draw_wrapped_text(_box_clip, font, Vector2(12.0, 22.0), bsz.x - 24.0, _dialog_text, 13, Color.WHITE)
		return

	# DODGING dentro de _box_clip (limpio, sin texto que estorbe)
	if _pass_ring_active:
		var rp := _pass_ring_pos - off
		_box_clip.draw_arc(rp, 14.0, 0.0, TAU, 18, Color(1.0, 0.88, 0.24), 2.5)
		_box_clip.draw_circle(rp, 5.0, Color(1.0, 0.94, 0.55))

	for g in _good_items:
		var gp := (g["pos"] as Vector2) - off
		_box_clip.draw_circle(gp, 7.0, Color(1.0, 0.90, 0.24))
		_box_clip.draw_circle(gp, 3.0, Color.WHITE)

	for pl in _pulses:
		var pp := (pl["pos"] as Vector2) - off
		_box_clip.draw_line(pp + Vector2(0, 8.0), pp + Vector2(0, -12.0), Color(1.0, 0.92, 0.24), 4.0)

	for hz in _hazards:
		var hp_pos := (hz["pos"] as Vector2) - off
		var kind := str(hz.get("kind", "wave"))
		var hcol := Color.WHITE
		if kind == "rumor" or kind == "bubble":
			hcol = Color(0.95, 0.36, 0.60)
		elif kind == "ball":
			hcol = Color(0.96, 0.58, 0.18)
		_box_clip.draw_circle(hp_pos, float(hz.get("r", 7.0)), hcol)

	var lsoul := _soul_pos - off
	if _invuln_timer <= 0.0 or int(Time.get_ticks_msec() / 80) % 2 == 0:
		_draw_pixel_heart(_box_clip, lsoul, soul_col, 1.8, _soul_type == SoulType.SHOOT_YELLOW)

func _draw_wrapped_text(target: Control, font: Font, pos: Vector2, max_w: float, text: String, sz: int, col: Color) -> void:
	var y := pos.y
	for para in text.split("\n"):
		var line := ""
		for word in para.split(" "):
			var cand := word if line.is_empty() else (line + " " + word)
			if font.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > max_w and not line.is_empty():
				target.draw_string(font, Vector2(pos.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
				y += float(sz) + 5.0
				line = word
			else:
				line = cand
		if not line.is_empty():
			target.draw_string(font, Vector2(pos.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
			y += float(sz) + 5.0
