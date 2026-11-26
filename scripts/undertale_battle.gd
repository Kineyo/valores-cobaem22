extends CanvasLayer
class_name UndertaleBattle

## Duelo Final interactivo estilo Undertale contra Titanor (previo al Clímax de Corazones).
## Incluye modo Alma Roja (8D), Alma Azul (gravedad + salto), láseres de advertencia,
## proyectiles celestes/naranjas, 10 oleadas (>= 126s de esquive) y controles táctiles cómodos.

signal battle_finished

const BossRendererClass := preload("res://scripts/boss_renderer.gd")

enum Phase {
	INTRO,
	MENU,
	SUB_ACT,
	SUB_ITEM,
	VALOR_MINIGAME,
	DIALOG_RESULT,
	BOSS_SPEECH,
	DODGING,
	DEFEAT,
	VICTORY,
}

enum SoulMode { RED, BLUE }

## Probabilidad [0.0 .. 1.0] de activar el duelo estilo Undertale antes de la escena de corazones.
## Configurada al 100% (1.0) para pruebas; puede ajustarse libremente según balance deseado.
static var trigger_probability: float = 1.0

static func should_trigger(rng_roll: float = -1.0) -> bool:
	var roll := rng_roll if rng_roll >= 0.0 else randf()
	return roll < clampf(trigger_probability, 0.0, 1.0)

const MAX_HP := 92
const MENU_LABELS := ["VALOR", "ACTUAR", "ÍTEM", "PIEDAD"]

## 10 oleadas diseñadas manualmente sumando 126.0 segundos (>= 2 minutos) de esquive activo.
const WAVES := [
	{
		"name": "Muro de Indiferencia",
		"duration": 11.0,
		"soul_mode": SoulMode.RED,
		"box_size": Vector2(248.0, 166.0),
		"pattern": "gap_bars",
		"quote": "Sigues de pie. Veamos cómo esquivas la indiferencia."
	},
	{
		"name": "Gravedad del Desánimo",
		"duration": 12.0,
		"soul_mode": SoulMode.BLUE,
		"box_size": Vector2(348.0, 142.0),
		"pattern": "blue_sweep",
		"quote": "El peso de las burlas jala al suelo. Salta a tiempo."
	},
	{
		"name": "Cañones de Desprecio",
		"duration": 12.0,
		"soul_mode": SoulMode.RED,
		"box_size": Vector2(240.0, 170.0),
		"pattern": "aimed_blasters",
		"quote": "Quien se queda quieto frente al miedo pierde espacio."
	},
	{
		"name": "Naranja y Celeste",
		"duration": 13.0,
		"soul_mode": SoulMode.RED,
		"box_size": Vector2(256.0, 162.0),
		"pattern": "cyan_orange",
		"quote": "Celeste pide pausa; Naranja pide movimiento."
	},
	{
		"name": "Lluvia de Rumores",
		"duration": 13.0,
		"soul_mode": SoulMode.RED,
		"box_size": Vector2(268.0, 166.0),
		"pattern": "rain_and_side_beams",
		"quote": "Cada comentario hiriente cae directo sobre la cancha."
	},
	{
		"name": "Salto en la Duela",
		"duration": 13.0,
		"soul_mode": SoulMode.BLUE,
		"box_size": Vector2(360.0, 146.0),
		"pattern": "blue_rhythm",
		"quote": "Salta al ritmo del silbato y no bajes el paso."
	},
	{
		"name": "Espiral del Aislamiento",
		"duration": 13.0,
		"soul_mode": SoulMode.RED,
		"box_size": Vector2(244.0, 172.0),
		"pattern": "spiral_and_pulse",
		"quote": "Nadie se acerca a cubrirte en medio de la espiral."
	},
	{
		"name": "Asalto Combinado",
		"duration": 13.0,
		"soul_mode": SoulMode.RED,
		"box_size": Vector2(252.0, 172.0),
		"pattern": "cross_blasters",
		"quote": "Izquierda, derecha, diagonal. Intenta seguir el ritmo."
	},
	{
		"name": "Ecos del Plantel",
		"duration": 12.0,
		"soul_mode": SoulMode.BLUE,
		"box_size": Vector2(336.0, 150.0),
		"pattern": "hybrid_switch",
		"quote": "Primero siente la presión y luego mantente al centro."
	},
	{
		"name": "Ráfaga Final de Titanor",
		"duration": 14.0,
		"soul_mode": SoulMode.RED,
		"box_size": Vector2(244.0, 174.0),
		"pattern": "final_carousel",
		"quote": "Este es mi último cierre. Sostén tu lugar si puedes."
	},
]

static func get_total_dodge_duration() -> float:
	var total := 0.0
	for w in WAVES:
		total += float(w.get("duration", 0.0))
	return total

const INITIAL_ITEMS := [
	{ "name": "Manzana Receso", "heal": 24, "msg": "* Comiste la Manzana del Receso. Recuperaste 24 HP." },
	{ "name": "Agua Fresca", "heal": 28, "msg": "* Bebiste Agua Fresca del plantel. Recuperaste 28 HP." },
	{ "name": "Torta Escolar", "heal": 36, "msg": "* Compartiste la Torta de Cafetería. Recuperaste 36 HP." },
	{ "name": "Estrella Valores", "heal": 50, "msg": "* La Estrella de los Valores te da calma. +50 HP." },
]

const ACT_OPTIONS := [
	{
		"label": "Escuchar",
		"msg": "* Escuchas el miedo detrás de la fuerza bruta de Titanor.\n* Sus ataques pierden velocidad.",
		"quote": "Escucharme. Nadie me escuchó cuando empecé."
	},
	{
		"label": "Hablar claro",
		"msg": "* Recuerdas la empatía y el respeto del CEMSaD 22.\n* Recuperas calma y reduces su prisa.",
		"quote": "Esos discursos no van a frenar lo que siento."
	},
	{
		"label": "Respaldar",
		"msg": "* Afirmas con serenidad que cuidarás a cada alumno.\n* El ritmo de Titanor flaquea.",
		"quote": "De verdad te importa tanto responder por los demás."
	},
]

var phase: Phase = Phase.INTRO
var soul_mode: SoulMode = SoulMode.RED
var hp: int = MAX_HP
var max_hp: int = MAX_HP
var current_wave: int = 0
var mercy_progress: float = 0.0
var items: Array[Dictionary] = []

var _time: float = 0.0
var _phase_timer: float = 0.0
var _wave_elapsed: float = 0.0
var _total_dodge_elapsed: float = 0.0
var _total_dodge_goal: float = 126.0
var _next_wave_speed_mult: float = 1.0
var _spawn_accum_a: float = 0.0
var _spawn_accum_b: float = 0.0
var _spawn_step: int = 0
var _hybrid_switched: bool = false

var _menu_index: int = 0
var _sub_index: int = 0
var _valor_cursor: float = 0.0 # -1.0 .. 1.0
var _valor_hit_done: bool = false
var _valor_flash_timer: float = 0.0
var _dialog_text: String = "* Titanor te desafía en un Duelo del Corazón."
var _boss_quote: String = ""
var _color_hint_text: String = ""
var _emitted_finished: bool = false
var allow_standalone_exit: bool = false

# Geometría del cuadro de batalla y posición del alma
var _current_box_rect: Rect2 = Rect2(170, 224, 460, 126)
var _target_box_rect: Rect2 = Rect2(170, 224, 460, 126)
var _soul_pos: Vector2 = Vector2(400, 290)
var _soul_vel: Vector2 = Vector2.ZERO
var _soul_prev_pos: Vector2 = Vector2(400, 290)
var _soul_speed_now: float = 0.0
var _soul_grounded: bool = false
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _invuln_timer: float = 0.0
var _boss_shake: float = 0.0
var _boss_flash: float = 0.0
var _screen_flash: float = 0.0

# Controles táctiles y ratón PC
var _drag_touch_id: int = -1
var _last_touch_pos: Vector2 = Vector2.ZERO
var _jump_touch_id: int = -1
var _mouse_dragging: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _pointer_cooldown_ms: int = 0

var _bullets: Array[Dictionary] = []
var _beams: Array[Dictionary] = []

var _canvas: Control
var _box_clip: Control
var _sfx_hit: AudioStreamPlayer
var _sfx_hurt: AudioStreamPlayer
var _sfx_select: AudioStreamPlayer
var _sfx_heal: AudioStreamPlayer

func _ready() -> void:
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	_total_dodge_goal = get_total_dodge_duration()
	items.clear()
	for it in INITIAL_ITEMS:
		items.append(it.duplicate(true))

	_build_audio()
	_build_canvas()
	_sync_box_targets()
	_current_box_rect = _target_box_rect
	_soul_pos = _current_box_rect.get_center()
	_soul_prev_pos = _soul_pos

	var gs := _get_game_settings()
	if gs and gs.has_method("play_undertale_battle_music"):
		gs.play_undertale_battle_music()

func _exit_tree() -> void:
	for sfx_p in [_sfx_hit, _sfx_hurt, _sfx_select, _sfx_heal]:
		if sfx_p != null and is_instance_valid(sfx_p):
			sfx_p.stop()
			sfx_p.stream = null

func _get_game_settings() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("GameSettings")
	return null

func _build_audio() -> void:
	_sfx_hit = _make_sfx("res://assets/audio/golpe_enemigo.wav", -3.0)
	_sfx_hurt = _make_sfx("res://assets/audio/herido.wav", -1.0)
	_sfx_select = _make_sfx("res://assets/audio/ataque.wav", -6.0)
	_sfx_heal = _make_sfx("res://assets/audio/victoria.wav", -5.0)

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

func _build_canvas() -> void:
	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_ctrl)

	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.draw.connect(_on_canvas_draw)
	root_ctrl.add_child(_canvas)

	_box_clip = Control.new()
	_box_clip.clip_contents = true
	_box_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box_clip.draw.connect(_on_box_draw)
	_canvas.add_child(_box_clip)

func _get_viewport_sz() -> Vector2:
	if _canvas and _canvas.size.x > 10.0 and _canvas.size.y > 10.0:
		return _canvas.size
	return Vector2(800.0, 450.0)

func _get_safe_rect() -> Rect2:
	var sz := _get_viewport_sz()
	if not is_inside_tree() or get_viewport() == null:
		return Rect2(Vector2(12, 8), sz - Vector2(24, 16))
	var ins := MobileControls.get_safe_insets_for_viewport(get_viewport(), 8.0)
	return Rect2(ins.position.x, ins.position.y, maxf(300.0, sz.x - ins.position.x - ins.size.x), maxf(240.0, sz.y - ins.position.y - ins.size.y))

func _get_blue_jump_rect() -> Rect2:
	var sr := _get_safe_rect()
	return Rect2(sr.end.x - 102.0, sr.end.y - 118.0, 92.0, 44.0)

func _sync_box_targets() -> void:
	var sr := _get_safe_rect()
	var cx := sr.get_center().x
	var center_y := sr.position.y + sr.size.y * 0.56
	var bsize := Vector2(minf(500.0, sr.size.x - 32.0), 120.0)
	if phase == Phase.DODGING:
		var w_idx := clampi(current_wave, 0, WAVES.size() - 1)
		bsize = WAVES[w_idx]["box_size"] as Vector2
		if _hybrid_switched and w_idx == 8:
			bsize = Vector2(246.0, 168.0)
		bsize.x = minf(bsize.x, sr.size.x - 28.0)
		bsize.y = minf(bsize.y, sr.size.y * 0.44)
	_target_box_rect = Rect2(Vector2(cx - bsize.x * 0.5, center_y - bsize.y * 0.5), bsize)
	_sync_box_clip_geometry()

func _sync_box_clip_geometry() -> void:
	if _box_clip == null:
		return
	var inner := _current_box_rect.grow(-3.5)
	_box_clip.position = inner.position
	_box_clip.size = Vector2(maxf(8.0, inner.size.x), maxf(8.0, inner.size.y))

func _get_menu_button_rects() -> Array[Rect2]:
	var sr := _get_safe_rect()
	var n := 4
	var gap := 12.0
	var total_w := minf(620.0, sr.size.x - 16.0)
	var btn_w := (total_w - gap * float(n - 1)) / float(n)
	var btn_h := 34.0
	var start_x := sr.get_center().x - total_w * 0.5
	var y := sr.end.y - 42.0
	var rects: Array[Rect2] = []
	for i in range(n):
		rects.append(Rect2(start_x + float(i) * (btn_w + gap), y, btn_w, btn_h))
	return rects

func _get_sub_option_rects(count: int) -> Array[Rect2]:
	var r := _current_box_rect
	var rects: Array[Rect2] = []
	for i in range(count):
		var col := i % 2
		var row := i / 2
		var rx := r.position.x + 22.0 + float(col) * (r.size.x * 0.47)
		var ry := r.position.y + 22.0 + float(row) * 42.0
		rects.append(Rect2(rx, ry, r.size.x * 0.43, 34.0))
	return rects

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	_time += dt
	_phase_timer += dt

	if _invuln_timer > 0.0:
		_invuln_timer = maxf(0.0, _invuln_timer - dt)
	if _boss_shake > 0.0:
		_boss_shake = maxf(0.0, _boss_shake - dt * 16.0)
	if _boss_flash > 0.0:
		_boss_flash = maxf(0.0, _boss_flash - dt)
	if _screen_flash > 0.0:
		_screen_flash = maxf(0.0, _screen_flash - dt * 2.5)
	if _valor_flash_timer > 0.0:
		_valor_flash_timer = maxf(0.0, _valor_flash_timer - dt)

	_sync_box_targets()
	_current_box_rect.position = _current_box_rect.position.lerp(_target_box_rect.position, minf(1.0, dt * 12.0))
	_current_box_rect.size = _current_box_rect.size.lerp(_target_box_rect.size, minf(1.0, dt * 12.0))
	_sync_box_clip_geometry()

	match phase:
		Phase.INTRO:
			if _phase_timer >= 1.15:
				_enter_menu()
		Phase.VALOR_MINIGAME:
			if not _valor_hit_done:
				_valor_cursor += dt * 1.45
				if _valor_cursor >= 1.05:
					_resolve_valor_strike(true)
			elif _phase_timer >= 0.72:
				if mercy_progress >= 100.0 or current_wave >= WAVES.size():
					_enter_menu()
				else:
					_begin_boss_speech()
		Phase.DIALOG_RESULT:
			if _phase_timer >= 1.25:
				if mercy_progress >= 100.0 or current_wave >= WAVES.size():
					_enter_menu()
				else:
					_begin_boss_speech()
		Phase.BOSS_SPEECH:
			if _phase_timer >= 1.05:
				_start_dodge_wave(current_wave)
		Phase.DODGING:
			_update_dodge_wave(dt)
		Phase.VICTORY:
			if _phase_timer >= 1.85:
				_complete_battle()

	if _canvas:
		_canvas.queue_redraw()
	if _box_clip:
		_box_clip.queue_redraw()

func _is_mercy_ready() -> bool:
	return current_wave >= WAVES.size() or mercy_progress >= 100.0

func _enter_menu() -> void:
	phase = Phase.MENU
	_phase_timer = 0.0
	_mouse_dragging = false
	_bullets.clear()
	_beams.clear()
	_color_hint_text = ""
	soul_mode = SoulMode.RED
	if _is_mercy_ready():
		_menu_index = 3
		_dialog_text = "* Titanor escucha tu postura. Usa PIEDAD para cerrar en calma."
	else:
		_dialog_text = "* Oleada %d/%d (%s) · Calma %d%%. Elige cómo responder." % [
			current_wave + 1,
			WAVES.size(),
			str(WAVES[current_wave]["name"]),
			int(round(mercy_progress))
		]

func _select_menu_action(idx: int) -> void:
	_menu_index = clampi(idx, 0, 3)
	_play_sfx(_sfx_select, 1.15)
	match _menu_index:
		0:
			# VALOR: barra de pulso luminoso (no violento)
			phase = Phase.VALOR_MINIGAME
			_phase_timer = 0.0
			_valor_cursor = -1.0
			_valor_hit_done = false
		1:
			phase = Phase.SUB_ACT
			_phase_timer = 0.0
			_sub_index = 0
		2:
			if items.is_empty():
				_dialog_text = "* Tu mochila escolar está vacía. Usa VALOR o ACTUAR."
				return
			phase = Phase.SUB_ITEM
			_phase_timer = 0.0
			_sub_index = 0
		3:
			if _is_mercy_ready():
				advance_to_victory()
			else:
				_dialog_text = "* Calma al %d%% (%d/%d oleadas). Sigue con VALOR o ACTUAR." % [int(round(mercy_progress)), current_wave, WAVES.size()]

func _resolve_valor_strike(missed: bool = false) -> void:
	if _valor_hit_done:
		return
	_valor_hit_done = true
	_phase_timer = 0.0
	if missed:
		_valor_flash_timer = 0.25
		mercy_progress = minf(100.0, mercy_progress + 10.0)
		_dialog_text = "* Tu señal rozó a Titanor."
	else:
		var acc := clampf(1.0 - absf(_valor_cursor), 0.15, 1.0)
		_valor_flash_timer = 0.55
		_boss_shake = 4.0 * acc
		_boss_flash = 0.35
		mercy_progress = minf(100.0, mercy_progress + 25.0)
		_play_sfx(_sfx_hit, 0.95 + acc * 0.35)
		if acc > 0.65 and hp < max_hp:
			hp = mini(max_hp, hp + 4)

func _activate_act_option(idx: int) -> void:
	var c_idx := clampi(idx, 0, ACT_OPTIONS.size() - 1)
	var opt: Dictionary = ACT_OPTIONS[c_idx]
	_next_wave_speed_mult = 0.88
	mercy_progress = minf(100.0, mercy_progress + 25.0)
	if hp < max_hp:
		hp = mini(max_hp, hp + 3)
	_boss_quote = str(opt["quote"])
	_dialog_text = str(opt["msg"])
	_play_sfx(_sfx_heal, 1.08)
	phase = Phase.DIALOG_RESULT
	_phase_timer = 0.0

func _use_item_at(idx: int) -> void:
	if idx < 0 or idx >= items.size():
		return
	var item: Dictionary = items[idx]
	items.remove_at(idx)
	var heal_amt := int(item.get("heal", 20))
	hp = mini(max_hp, hp + heal_amt)
	_dialog_text = str(item.get("msg", "* Recuperaste energía."))
	_play_sfx(_sfx_heal, 1.15)
	phase = Phase.DIALOG_RESULT
	_phase_timer = 0.0

func _begin_boss_speech() -> void:
	if current_wave >= WAVES.size():
		_enter_menu()
		return
	phase = Phase.BOSS_SPEECH
	_phase_timer = 0.0
	if _boss_quote.is_empty():
		_boss_quote = str(WAVES[current_wave]["quote"])

func _start_dodge_wave(wave_idx: int) -> void:
	current_wave = clampi(wave_idx, 0, WAVES.size() - 1)
	var w: Dictionary = WAVES[current_wave]
	phase = Phase.DODGING
	_phase_timer = 0.0
	_wave_elapsed = 0.0
	_spawn_accum_a = 0.0
	_spawn_accum_b = 0.0
	_spawn_step = 0
	_hybrid_switched = false
	_boss_quote = ""
	_color_hint_text = ""
	_bullets.clear()
	_beams.clear()
	_sync_box_targets()
	_current_box_rect = _target_box_rect
	soul_mode = int(w["soul_mode"]) as SoulMode
	if soul_mode == SoulMode.BLUE:
		_soul_pos = Vector2(_current_box_rect.get_center().x, _current_box_rect.end.y - 12.0)
		_soul_grounded = true
	else:
		_soul_pos = _current_box_rect.get_center()
		_soul_grounded = false
	_soul_vel = Vector2.ZERO
	_soul_prev_pos = _soul_pos

func advance_to_victory() -> void:
	if phase == Phase.VICTORY:
		return
	phase = Phase.VICTORY
	_phase_timer = 0.0
	_bullets.clear()
	_beams.clear()
	_screen_flash = 0.9
	_boss_quote = "Tal vez sí haya otra manera de estar aquí sin pelear."
	_dialog_text = "* Superaste el Duelo del Corazón. Titanor baja los brazos."
	_play_sfx(_sfx_heal, 1.0)

func _complete_battle() -> void:
	if _emitted_finished:
		return
	_emitted_finished = true
	battle_finished.emit()
	queue_free()

func _retry_current_wave() -> void:
	hp = max_hp
	_invuln_timer = 0.8
	_bullets.clear()
	_beams.clear()
	_next_wave_speed_mult = 0.90
	_enter_menu()

func _update_dodge_wave(dt: float) -> void:
	var w: Dictionary = WAVES[current_wave]
	var dur := float(w["duration"])
	_wave_elapsed += dt
	_update_soul(dt)
	_spawn_wave_patterns(str(w["pattern"]), dt)
	_update_bullets_and_beams(dt)
	if hp <= 0:
		hp = 0
		phase = Phase.DEFEAT
		_phase_timer = 0.0
		_bullets.clear()
		_beams.clear()
		_play_sfx(_sfx_hurt, 0.72)
		return
	if _wave_elapsed >= dur:
		_total_dodge_elapsed += dur
		_next_wave_speed_mult = 1.0
		current_wave += 1
		mercy_progress = minf(100.0, mercy_progress + 15.0)
		_enter_menu()

func _update_soul(dt: float) -> void:
	_soul_prev_pos = _soul_pos
	var move_x := 0.0
	var move_y := 0.0
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move_x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move_x += 1.0
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_y -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_y += 1.0

	var joy_v := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if joy_v.length_squared() > 0.09:
		move_x = joy_v.x
		move_y = joy_v.y

	var focus := Input.is_action_pressed("focus") or Input.is_key_pressed(KEY_SHIFT)
	var pad := 10.0
	var inner := Rect2(_current_box_rect.position + Vector2(pad, pad), _current_box_rect.size - Vector2(pad * 2.0, pad * 2.0))

	if soul_mode == SoulMode.RED:
		var v := Vector2(move_x, move_y)
		if v.length_squared() > 1.0:
			v = v.normalized()
		var spd := 125.0 if focus else 195.0
		_soul_pos += v * spd * dt
	else:
		# Azul (gravedad + salto con coyote time y jump buffer para comodidad en móvil/PC)
		var h_spd := 130.0 if focus else 190.0
		_soul_pos.x += clampf(move_x, -1.0, 1.0) * h_spd * dt
		if _coyote_timer > 0.0:
			_coyote_timer = maxf(0.0, _coyote_timer - dt)
		if _jump_buffer_timer > 0.0:
			_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - dt)

		var jump_held := move_y < -0.35 or Input.is_key_pressed(KEY_SPACE) or Input.is_joy_button_pressed(0, JOY_BUTTON_A) or (_jump_touch_id != -1)
		if jump_held and (_soul_grounded or _coyote_timer > 0.0):
			_soul_vel.y = -290.0
			_soul_grounded = false
			_coyote_timer = 0.0
			_jump_buffer_timer = 0.0
		elif _jump_buffer_timer > 0.0 and _soul_grounded:
			_soul_vel.y = -290.0
			_soul_grounded = false
			_jump_buffer_timer = 0.0

		if not jump_held and _soul_vel.y < -95.0:
			_soul_vel.y *= 0.55

		_soul_vel.y += 640.0 * dt
		_soul_pos.y += _soul_vel.y * dt
		if _soul_pos.y >= inner.end.y:
			_soul_pos.y = inner.end.y
			_soul_vel.y = 0.0
			_soul_grounded = true
			_coyote_timer = 0.09
		else:
			_soul_grounded = false
		if _soul_pos.y < inner.position.y:
			_soul_pos.y = inner.position.y
			_soul_vel.y = maxf(0.0, _soul_vel.y)

	_soul_pos.x = clampf(_soul_pos.x, inner.position.x, inner.end.x)
	_soul_pos.y = clampf(_soul_pos.y, inner.position.y, inner.end.y)
	_soul_speed_now = (_soul_pos - _soul_prev_pos).length() / maxf(0.001, dt)

func _spawn_wave_patterns(pattern: String, dt: float) -> void:
	var touch_comfort := 0.88 if MobileControls.is_touch_device() else 1.0
	var sp_mult := _next_wave_speed_mult * touch_comfort
	var b := _current_box_rect
	var c := b.get_center()

	match pattern:
		"gap_bars":
			_spawn_accum_a += dt
			if _spawn_accum_a >= 0.92:
				_spawn_accum_a = 0.0
				_spawn_step += 1
				var from_left := (_spawn_step % 2 == 0)
				var gap_y := b.position.y + 38.0 + float((_spawn_step * 47) % int(maxf(40.0, b.size.y - 76.0)))
				var gap_half := 26.0
				var x_pos := (b.position.x - 16.0) if from_left else (b.end.x + 16.0)
				var vx := (148.0 if from_left else -148.0) * sp_mult
				if gap_y - gap_half > b.position.y + 8.0:
					var h_top := (gap_y - gap_half) - b.position.y
					_add_rect_bullet(Vector2(x_pos, b.position.y + h_top * 0.5), Vector2(vx, 0), Vector2(14, h_top), "white")
				if b.end.y - (gap_y + gap_half) > 8.0:
					var h_bot := b.end.y - (gap_y + gap_half)
					_add_rect_bullet(Vector2(x_pos, gap_y + gap_half + h_bot * 0.5), Vector2(vx, 0), Vector2(14, h_bot), "white")
				if _spawn_step % 2 == 1:
					var dir_p := (_soul_pos - Vector2(c.x, b.position.y - 18.0)).normalized()
					_add_pellet(Vector2(c.x, b.position.y - 18.0), dir_p * 145.0 * sp_mult, 6.0, "white")

		"blue_sweep":
			_spawn_accum_a += dt
			if _spawn_accum_a >= 1.10:
				_spawn_accum_a = 0.0
				_spawn_step += 1
				var from_l := (_spawn_step % 2 == 0)
				var bar_h := 34.0 if _spawn_step % 3 != 0 else 44.0
				var bx := (b.position.x - 14.0) if from_l else (b.end.x + 14.0)
				var vx := (172.0 if from_l else -172.0) * sp_mult
				_add_rect_bullet(Vector2(bx, b.end.y - bar_h * 0.5), Vector2(vx, 0), Vector2(14, bar_h), "white")
				if _spawn_step % 3 == 0:
					# Barra superior decorativa/reto con hueco inferior claro para pasar por debajo
					_add_rect_bullet(Vector2(bx, b.position.y + 24.0), Vector2(vx, 0), Vector2(14, 48.0), "white")

		"aimed_blasters":
			_spawn_accum_a += dt
			if _spawn_accum_a >= 1.05:
				_spawn_accum_a = 0.0
				_spawn_step += 1
				var side := _spawn_step % 4
				var origin := c
				match side:
					0: origin = Vector2(b.position.x - 36.0, _soul_pos.y)
					1: origin = Vector2(b.end.x + 36.0, _soul_pos.y)
					2: origin = Vector2(_soul_pos.x, b.position.y - 34.0)
					_: origin = Vector2(c.x + randf_range(-90.0, 90.0), b.position.y - 34.0)
				var ang := (_soul_pos - origin).angle()
				_add_beam(origin, ang, 24.0, 420.0, 0.78 / touch_comfort, 0.30, "white")
			_spawn_accum_b += dt
			if _spawn_accum_b >= 0.75:
				_spawn_accum_b = 0.0
				var edge_x := randf_range(b.position.x + 18.0, b.end.x - 18.0)
				_add_pellet(Vector2(edge_x, b.position.y - 12.0), Vector2(0, 128.0 * sp_mult), 5.5, "white")

		"cyan_orange":
			_spawn_accum_a += dt
			if _spawn_accum_a >= 1.45:
				_spawn_accum_a = 0.0
				_spawn_step += 1
				var is_cyan := (_spawn_step % 2 == 1)
				var kind := "cyan" if is_cyan else "orange"
				_color_hint_text = "CELESTE: Quédate quieto" if is_cyan else "NARANJA: Muévete"
				var sweep_x := b.position.x - 24.0 if (_spawn_step % 4 < 2) else b.end.x + 24.0
				var vx := (175.0 if sweep_x < c.x else -175.0) * sp_mult
				_add_rect_bullet(Vector2(sweep_x, c.y), Vector2(vx, 0), Vector2(16, b.size.y - 4.0), kind)
			_spawn_accum_b += dt
			if _spawn_accum_b >= 0.70:
				_spawn_accum_b = 0.0
				var rx := randf_range(b.position.x + 16.0, b.end.x - 16.0)
				_add_pellet(Vector2(rx, b.position.y - 10.0), Vector2(randf_range(-20, 20), 125.0 * sp_mult), 5.0, "white")

		"rain_and_side_beams":
			_spawn_accum_a += dt
			if _spawn_accum_a >= 0.24:
				_spawn_accum_a = 0.0
				var sx := randf_range(b.position.x + 12.0, b.end.x - 12.0)
				_add_pellet(Vector2(sx, b.position.y - 14.0), Vector2(randf_range(-34.0, 34.0), 155.0 * sp_mult), 5.5, "white", "diamond")
			_spawn_accum_b += dt
			if _spawn_accum_b >= 1.85:
				_spawn_accum_b = 0.0
				_spawn_step += 1
				var left_s := (_spawn_step % 2 == 0)
				var oy := lerpf(b.position.y + 34.0, b.end.y - 34.0, fmod(float(_spawn_step) * 0.37, 1.0))
				var o := Vector2(b.position.x - 38.0, oy) if left_s else Vector2(b.end.x + 38.0, oy)
				_add_beam(o, 0.0 if left_s else PI, 22.0, 420.0, 0.80 / touch_comfort, 0.32, "white")

		"blue_rhythm":
			_spawn_accum_a += dt
			if _spawn_accum_a >= 0.95:
				_spawn_accum_a = 0.0
				_spawn_step += 1
				var from_l := (_spawn_step % 2 == 0)
				var bx := (b.position.x - 14.0) if from_l else (b.end.x + 14.0)
				var vx := (188.0 if from_l else -188.0) * sp_mult
				_add_rect_bullet(Vector2(bx, b.end.y - 18.0), Vector2(vx, 0), Vector2(14, 36.0), "white")
				_add_rect_bullet(Vector2(bx, b.position.y + 26.0), Vector2(vx, 0), Vector2(14, 46.0), "white")

		"spiral_and_pulse":
			_spawn_accum_a += dt
			if _spawn_accum_a >= 0.32:
				_spawn_accum_a = 0.0
				_spawn_step += 1
				var base_a := float(_spawn_step) * 0.42
				var emit_p := Vector2(c.x + cos(_time * 1.4) * 95.0, b.position.y - 26.0)
				for arm in range(4):
					var a := base_a + float(arm) * (TAU * 0.25)
					_add_pellet(emit_p, Vector2(cos(a), sin(a)) * 138.0 * sp_mult, 5.5, "white")
			_spawn_accum_b += dt
			if _spawn_accum_b >= 2.6:
				_spawn_accum_b = 0.0
				var is_o := (_spawn_step % 2 == 0)
				_color_hint_text = "NARANJA: Muévete" if is_o else "CELESTE: Quédate quieto"
				_add_beam(Vector2(b.position.x - 36.0, c.y), 0.0, b.size.y * 0.72, 420.0, 0.95 / touch_comfort, 0.35, "orange" if is_o else "cyan")

		"cross_blasters":
			_spawn_accum_a += dt
			if _spawn_accum_a >= 1.15:
				_spawn_accum_a = 0.0
				_spawn_step += 1
				if _spawn_step % 2 == 0:
					_add_beam(Vector2(b.position.x - 36.0, c.y), 0.0, 22.0, 420.0, 0.78 / touch_comfort, 0.28, "white")
					_add_beam(Vector2(c.x, b.position.y - 36.0), PI * 0.5, 22.0, 420.0, 0.78 / touch_comfort, 0.28, "white")
				else:
					var tl := Vector2(b.position.x - 28.0, b.position.y - 28.0)
					var tr := Vector2(b.end.x + 28.0, b.position.y - 28.0)
					_add_beam(tl, (c - tl).angle(), 22.0, 460.0, 0.80 / touch_comfort, 0.28, "white")
					_add_beam(tr, (c - tr).angle(), 22.0, 460.0, 0.80 / touch_comfort, 0.28, "white")
			_spawn_accum_b += dt
			if _spawn_accum_b >= 0.55:
				_spawn_accum_b = 0.0
				var side_x := b.position.x - 10.0 if randf() < 0.5 else b.end.x + 10.0
				var vx := 142.0 * sp_mult if side_x < c.x else -142.0 * sp_mult
				_add_pellet(Vector2(side_x, randf_range(b.position.y + 18.0, b.end.y - 18.0)), Vector2(vx, 0), 5.0, "white")

		"hybrid_switch":
			if _wave_elapsed >= 6.0 and not _hybrid_switched:
				_hybrid_switched = true
				soul_mode = SoulMode.RED
				_bullets.clear()
				_screen_flash = 0.65
				_play_sfx(_sfx_select, 1.35)
			if not _hybrid_switched:
				_spawn_accum_a += dt
				if _spawn_accum_a >= 0.92:
					_spawn_accum_a = 0.0
					_spawn_step += 1
					var from_l := (_spawn_step % 2 == 0)
					var bx := (b.position.x - 14.0) if from_l else (b.end.x + 14.0)
					var vx := (184.0 if from_l else -184.0) * sp_mult
					_add_rect_bullet(Vector2(bx, b.end.y - 17.0), Vector2(vx, 0), Vector2(14, 34.0), "white")
			else:
				_spawn_accum_b += dt
				if _spawn_accum_b >= 0.72:
					_spawn_accum_b = 0.0
					_spawn_step += 1
					var r_ang := float(_spawn_step) * 0.55
					var ring_p := Vector2(c.x + cos(r_ang) * 145.0, c.y + sin(r_ang) * 115.0)
					var to_p := (_soul_pos - ring_p).normalized()
					for d_off in [-0.24, 0.0, 0.24]:
						var d := to_p.rotated(d_off)
						_add_pellet(ring_p, d * 148.0 * sp_mult, 5.5, "white", "diamond")

		"final_carousel":
			_spawn_accum_a += dt
			if _spawn_accum_a >= 0.42:
				_spawn_accum_a = 0.0
				_spawn_step += 1
				var ang_pos := float(_spawn_step) * 0.52
				var radius_x := b.size.x * 0.5 + 42.0
				var radius_y := b.size.y * 0.5 + 42.0
				var origin := Vector2(c.x + cos(ang_pos) * radius_x, c.y + sin(ang_pos) * radius_y)
				var aim := (c + Vector2(sin(_time * 2.1) * 32.0, cos(_time * 1.7) * 26.0) - origin).angle()
				_add_beam(origin, aim, 20.0, 440.0, 0.76 / touch_comfort, 0.24, "white")
			_spawn_accum_b += dt
			if _spawn_accum_b >= 1.75:
				_spawn_accum_b = 0.0
				var kind := "orange" if (_spawn_step % 2 == 0) else "cyan"
				_color_hint_text = "NARANJA: Muévete" if kind == "orange" else "CELESTE: Quédate quieto"
				_add_rect_bullet(Vector2(b.position.x - 16.0, c.y), Vector2(185.0 * sp_mult, 0), Vector2(16, b.size.y - 6.0), kind)

func _add_pellet(pos: Vector2, vel: Vector2, radius: float, kind: String = "white", shape: String = "pellet") -> void:
	_bullets.append({
		"pos": pos,
		"vel": vel,
		"radius": radius,
		"size": Vector2(radius * 2.0, radius * 2.0),
		"kind": kind,
		"shape": shape,
		"life": 5.0,
	})

func _add_rect_bullet(pos: Vector2, vel: Vector2, sz: Vector2, kind: String = "white") -> void:
	_bullets.append({
		"pos": pos,
		"vel": vel,
		"radius": 0.0,
		"size": sz,
		"kind": kind,
		"shape": "bone",
		"life": 5.5,
	})

func _add_beam(pos: Vector2, angle: float, width: float, length: float, warn: float, active: float, kind: String = "white") -> void:
	_beams.append({
		"pos": pos,
		"angle": angle,
		"width": width,
		"length": length,
		"warn_left": warn,
		"active_left": active,
		"max_active": active,
		"kind": kind,
	})

func _can_hurt_by_color(kind: String) -> bool:
	if kind == "cyan":
		return _soul_speed_now > 24.0
	if kind == "orange":
		return _soul_speed_now < 20.0
	return true

func _damage_player(amount: int) -> void:
	if _invuln_timer > 0.0 or phase != Phase.DODGING:
		return
	var is_touch := MobileControls.is_touch_device()
	var dmg := maxi(1, amount - (1 if is_touch else 0))
	hp = maxi(0, hp - dmg)
	_invuln_timer = 1.20 if is_touch else 0.95
	_boss_shake = 4.0
	_play_sfx(_sfx_hurt, 1.0)

func _update_bullets_and_beams(dt: float) -> void:
	var soul_r := 4.5
	for i in range(_bullets.size() - 1, -1, -1):
		var b: Dictionary = _bullets[i]
		b["pos"] = (b["pos"] as Vector2) + (b["vel"] as Vector2) * dt
		b["life"] = float(b["life"]) - dt
		if float(b["life"]) <= 0.0:
			_bullets.remove_at(i)
			continue
		if _invuln_timer <= 0.0:
			var bpos := b["pos"] as Vector2
			var hit := false
			if str(b["shape"]) == "bone":
				var half := (b["size"] as Vector2) * 0.5
				var closest := Vector2(clampf(_soul_pos.x, bpos.x - half.x, bpos.x + half.x), clampf(_soul_pos.y, bpos.y - half.y, bpos.y + half.y))
				hit = _soul_pos.distance_squared_to(closest) <= soul_r * soul_r
			else:
				var r_sum := soul_r + float(b["radius"])
				hit = _soul_pos.distance_squared_to(bpos) <= r_sum * r_sum
			if hit and _can_hurt_by_color(str(b["kind"])):
				_damage_player(7)

	for i in range(_beams.size() - 1, -1, -1):
		var bm: Dictionary = _beams[i]
		var w_left := float(bm["warn_left"])
		if w_left > 0.0:
			bm["warn_left"] = maxf(0.0, w_left - dt)
			if float(bm["warn_left"]) <= 0.0:
				_play_sfx(_sfx_hit, 0.85)
			continue
		var a_left := float(bm["active_left"]) - dt
		bm["active_left"] = a_left
		if a_left <= 0.0:
			_beams.remove_at(i)
			continue
		if _invuln_timer <= 0.0 and _can_hurt_by_color(str(bm["kind"])):
			var p0 := bm["pos"] as Vector2
			var dir := Vector2(cos(float(bm["angle"])), sin(float(bm["angle"])))
			var p1 := p0 + dir * float(bm["length"])
			var closest := Geometry2D.get_closest_point_to_segment(_soul_pos, p0, p1)
			var half_w := float(bm["width"]) * 0.44 + soul_r
			if _soul_pos.distance_squared_to(closest) <= half_w * half_w:
				_damage_player(8)

func _get_standalone_exit_rect() -> Rect2:
	var sr := _get_safe_rect()
	return Rect2(sr.end.x - 80.0, sr.position.y + 4.0, 74.0, 26.0)

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
			_complete_battle()
			_mark_handled()
			return
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			if phase in [Phase.INTRO, Phase.MENU, Phase.DEFEAT]:
				_complete_battle()
				_mark_handled()
				return

	if phase == Phase.DODGING:
		if is_real_mouse:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed and soul_mode == SoulMode.BLUE and _get_blue_jump_rect().has_point(mb.position):
					_jump_buffer_timer = 0.14
					_mark_handled()
					return
				_mouse_dragging = mb.pressed
				_last_mouse_pos = mb.position
				_mark_handled()
				return
		elif event is InputEventMouseMotion and _mouse_dragging and event.device != InputEvent.DEVICE_ID_EMULATION:
			var mm := event as InputEventMouseMotion
			var d_m := (mm.position - _last_mouse_pos) * 1.15
			_last_mouse_pos = mm.position
			var pad_m := 10.0
			_soul_pos.x = clampf(_soul_pos.x + d_m.x, _current_box_rect.position.x + pad_m, _current_box_rect.end.x - pad_m)
			if soul_mode == SoulMode.RED:
				_soul_pos.y = clampf(_soul_pos.y + d_m.y, _current_box_rect.position.y + pad_m, _current_box_rect.end.y - pad_m)
			elif d_m.y < -12.0:
				_jump_buffer_timer = 0.14
			_mark_handled()
			return

		if event is InputEventScreenTouch and is_real_touch:
			var st := event as InputEventScreenTouch
			var sz := _get_viewport_sz()
			if st.pressed:
				if soul_mode == SoulMode.BLUE and (_get_blue_jump_rect().has_point(st.position) or st.position.x >= sz.x * 0.58) and _jump_touch_id == -1:
					_jump_touch_id = st.index
					_jump_buffer_timer = 0.14
				elif _drag_touch_id == -1:
					_drag_touch_id = st.index
					_last_touch_pos = st.position
			else:
				if st.index == _drag_touch_id:
					_drag_touch_id = -1
				if st.index == _jump_touch_id:
					_jump_touch_id = -1
		elif event is InputEventScreenDrag and is_real_touch:
			var sd := event as InputEventScreenDrag
			if sd.index == _drag_touch_id:
				var delta_drag := (sd.position - _last_touch_pos) * 1.15
				_last_touch_pos = sd.position
				var pad := 10.0
				_soul_pos.x = clampf(_soul_pos.x + delta_drag.x, _current_box_rect.position.x + pad, _current_box_rect.end.x - pad)
				if soul_mode == SoulMode.RED:
					_soul_pos.y = clampf(_soul_pos.y + delta_drag.y, _current_box_rect.position.y + pad, _current_box_rect.end.y - pad)
				elif delta_drag.y < -12.0:
					_jump_buffer_timer = 0.14
		elif event is InputEventKey and event.pressed and not event.echo:
			if soul_mode == SoulMode.BLUE and event.keycode in [KEY_UP, KEY_W, KEY_SPACE, KEY_Z]:
				_jump_buffer_timer = 0.14
		elif event is InputEventJoypadButton and event.pressed and soul_mode == SoulMode.BLUE:
			if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_DPAD_UP]:
				_jump_buffer_timer = 0.14
		return

	# Navegación de menú / submenú / diálogo / valor / derrota
	var trigger_confirm := false
	var trigger_back := false
	var nav_dx := 0
	var nav_dy := 0

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A: nav_dx = -1
			KEY_RIGHT, KEY_D: nav_dx = 1
			KEY_UP, KEY_W: nav_dy = -1
			KEY_DOWN, KEY_S: nav_dy = 1
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_Z: trigger_confirm = true
			KEY_ESCAPE, KEY_X: trigger_back = true
	elif event is InputEventJoypadButton and event.pressed and not event.is_echo():
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT: nav_dx = -1
			JOY_BUTTON_DPAD_RIGHT: nav_dx = 1
			JOY_BUTTON_DPAD_UP: nav_dy = -1
			JOY_BUTTON_DPAD_DOWN: nav_dy = 1
			JOY_BUTTON_A, JOY_BUTTON_START: trigger_confirm = true
			JOY_BUTTON_B, JOY_BUTTON_X: trigger_back = true
	elif (is_real_mouse and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and is_real_touch and (event as InputEventScreenTouch).pressed):
		var p_pos: Vector2 = (event as InputEventMouseButton).position if event is InputEventMouseButton else (event as InputEventScreenTouch).position
		var now_ms := Time.get_ticks_msec()
		if (now_ms - _pointer_cooldown_ms) >= 120:
			_pointer_cooldown_ms = now_ms
			_handle_pointer_press(p_pos)
			_mark_handled()
		return

	if phase == Phase.MENU:
		if nav_dx != 0:
			_menu_index = posmod(_menu_index + nav_dx, 4)
			_play_sfx(_sfx_select, 1.0)
			_mark_handled()
		elif trigger_confirm:
			_select_menu_action(_menu_index)
			_mark_handled()
	elif phase == Phase.SUB_ACT or phase == Phase.SUB_ITEM:
		var count := ACT_OPTIONS.size() if phase == Phase.SUB_ACT else items.size()
		if nav_dx != 0 or nav_dy != 0:
			var step := nav_dx + nav_dy * 2
			_sub_index = posmod(_sub_index + step, maxi(1, count))
			_play_sfx(_sfx_select, 1.0)
			_mark_handled()
		elif trigger_back:
			_enter_menu()
			_mark_handled()
		elif trigger_confirm:
			if phase == Phase.SUB_ACT:
				_activate_act_option(_sub_index)
			else:
				_use_item_at(_sub_index)
			_mark_handled()
	elif phase == Phase.VALOR_MINIGAME:
		if trigger_confirm and not _valor_hit_done:
			_resolve_valor_strike(false)
			_mark_handled()
	elif phase == Phase.INTRO and trigger_confirm:
		_enter_menu()
		_mark_handled()
	elif phase == Phase.DIALOG_RESULT and trigger_confirm:
		if _is_mercy_ready():
			_enter_menu()
		else:
			_begin_boss_speech()
		_mark_handled()
	elif phase == Phase.BOSS_SPEECH and trigger_confirm:
		_start_dodge_wave(current_wave)
		_mark_handled()
	elif phase == Phase.DEFEAT and trigger_confirm:
		_retry_current_wave()
		_mark_handled()

func _handle_pointer_press(pos: Vector2) -> void:
	match phase:
		Phase.INTRO:
			_enter_menu()
		Phase.MENU:
			var rects := _get_menu_button_rects()
			for i in range(rects.size()):
				if rects[i].has_point(pos):
					_select_menu_action(i)
					return
		Phase.SUB_ACT:
			var opts := _get_sub_option_rects(ACT_OPTIONS.size())
			for i in range(opts.size()):
				if opts[i].has_point(pos):
					_activate_act_option(i)
					return
			_enter_menu()
		Phase.SUB_ITEM:
			var opts_i := _get_sub_option_rects(items.size())
			for i in range(opts_i.size()):
				if opts_i[i].has_point(pos):
					_use_item_at(i)
					return
			_enter_menu()
		Phase.VALOR_MINIGAME:
			if not _valor_hit_done:
				_resolve_valor_strike(false)
		Phase.DIALOG_RESULT:
			if _is_mercy_ready():
				_enter_menu()
			else:
				_begin_boss_speech()
		Phase.BOSS_SPEECH:
			_start_dodge_wave(current_wave)
		Phase.DEFEAT:
			_retry_current_wave()

func _mark_handled() -> void:
	if is_inside_tree() and get_viewport():
		get_viewport().set_input_as_handled()

func _on_canvas_draw() -> void:
	if _canvas == null:
		return
	var sz := _get_viewport_sz()
	var sr := _get_safe_rect()
	var cx := sr.get_center().x
	var font := ThemeDB.fallback_font

	# 1. Fondo negro absoluto Undertale
	_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 1))

	# 2. Encabezado discreto de progreso dentro del safe area
	var hdr := "DUELO DEL CORAZÓN  ·  OLEADA %d/%d  ·  CALMA %d%%" % [
		mini(current_wave + 1, WAVES.size()), WAVES.size(),
		int(round(mercy_progress))
	]
	if font:
		_canvas.draw_string(font, Vector2(sr.position.x, sr.position.y + 18.0), hdr, HORIZONTAL_ALIGNMENT_CENTER, sr.size.x, 11, Color(0.75, 0.78, 0.85, 0.88))

	# 3. Jefe monocromo Titanor arriba del cuadro
	if phase != Phase.DEFEAT:
		var shake_off := Vector2(sin(_time * 48.0) * _boss_shake, cos(_time * 38.0) * _boss_shake * 0.5)
		var breath_y := sin(_time * 2.8) * 3.0
		var boss_pos := Vector2(cx, sr.position.y + sr.size.y * 0.34) + shake_off + Vector2(0.0, breath_y)
		var b_alpha := clampf(1.0 - (_phase_timer / 1.7), 0.0, 1.0) if phase == Phase.VICTORY else 1.0
		var g_col := Color(0.95, 0.90, 0.55, b_alpha) if _boss_flash > 0.0 else Color(0.30, 0.30, 0.34, b_alpha)
		var w_col := Color(0.94, 0.94, 0.96, b_alpha)
		BossRendererClass.draw_boss_silhouette(_canvas, 5, boss_pos, _time, g_col, w_col, false, false, 1.02)

		# Ojo brillante estilo Undertale (cian/dorado pulsante en oleadas intensas)
		if current_wave >= 2 and phase != Phase.VICTORY:
			var eye_col := Color(0.22, 0.92, 1.0, 0.92) if int(_time * 10.0) % 2 == 0 else Color(1.0, 0.90, 0.30, 0.92)
			_canvas.draw_circle(boss_pos + Vector2(-9.0, -54.0), 4.5, eye_col)
			_canvas.draw_circle(boss_pos + Vector2(-9.0, -54.0), 9.0, Color(eye_col.r, eye_col.g, eye_col.b, 0.25))

		# Destello dorado sobre Titanor en acción VALOR
		if _valor_flash_timer > 0.0:
			var va := clampf(_valor_flash_timer / 0.55, 0.0, 1.0)
			_canvas.draw_line(boss_pos + Vector2(-42, -78), boss_pos + Vector2(42, 4), Color(1.0, 0.92, 0.38, va), 4.0)
			_canvas.draw_line(boss_pos + Vector2(42, -78), boss_pos + Vector2(-42, 4), Color(1.0, 0.96, 0.65, va), 2.5)

		# Globo de diálogo blanco del jefe a la derecha
		if (phase == Phase.BOSS_SPEECH or phase == Phase.VICTORY) and not _boss_quote.is_empty():
			var bbl_x := minf(sr.end.x - 208.0, cx + 64.0)
			var bbl := Rect2(bbl_x, sr.position.y + 44.0, 200.0, 72.0)
			_canvas.draw_rect(bbl, Color.WHITE)
			_canvas.draw_rect(Rect2(bbl.position + Vector2(2, 2), bbl.size - Vector2(4, 4)), Color(0.97, 0.97, 0.99))
			if font:
				_canvas.draw_multiline_string(font, bbl.position + Vector2(10, 18), _boss_quote, HORIZONTAL_ALIGNMENT_LEFT, bbl.size.x - 18.0, 10, 4, Color(0.06, 0.06, 0.08))

	# 4. Cuadro de Batalla con borde blanco de 4px
	var br := _current_box_rect
	_canvas.draw_rect(br, Color(0, 0, 0, 1))
	_canvas.draw_rect(br, Color.WHITE, false, 3.5)

	# 5. Contenido interior según fase (hazards/soul de DODGING se dibujan en _box_clip)
	match phase:
		Phase.INTRO, Phase.MENU, Phase.DIALOG_RESULT, Phase.VICTORY:
			if font:
				_canvas.draw_multiline_string(font, br.position + Vector2(20, 34), _dialog_text, HORIZONTAL_ALIGNMENT_LEFT, br.size.x - 40.0, 14, 4, Color.WHITE)
		Phase.SUB_ACT:
			var act_rects := _get_sub_option_rects(ACT_OPTIONS.size())
			for i in range(ACT_OPTIONS.size()):
				var sel := (i == _sub_index)
				if font:
					var prefix := "♥ " if sel else "* "
					var col := Color(1.0, 0.90, 0.35) if sel else Color.WHITE
					_canvas.draw_string(font, act_rects[i].position + Vector2(8, 20), prefix + str(ACT_OPTIONS[i]["label"]), HORIZONTAL_ALIGNMENT_LEFT, act_rects[i].size.x, 14, col)
		Phase.SUB_ITEM:
			var item_rects := _get_sub_option_rects(items.size())
			for i in range(items.size()):
				var sel_i := (i == _sub_index)
				if font:
					var prefix_i := "♥ " if sel_i else "* "
					var col_i := Color(1.0, 0.90, 0.35) if sel_i else Color.WHITE
					_canvas.draw_string(font, item_rects[i].position + Vector2(8, 20), "%s%s (+%d)" % [prefix_i, str(items[i]["name"]), int(items[i]["heal"])], HORIZONTAL_ALIGNMENT_LEFT, item_rects[i].size.x, 12, col_i)
		Phase.VALOR_MINIGAME:
			_draw_valor_gauge(br, font)
		Phase.DODGING:
			if not _color_hint_text.is_empty() and font:
				var h_col := Color(0.32, 0.92, 1.0) if "CELESTE" in _color_hint_text else Color(1.0, 0.65, 0.22)
				_canvas.draw_string(font, Vector2(sr.position.x, br.position.y - 8.0), _color_hint_text, HORIZONTAL_ALIGNMENT_CENTER, sr.size.x, 11, h_col)
			if soul_mode == SoulMode.BLUE:
				var jr := _get_blue_jump_rect()
				_canvas.draw_rect(jr, Color(0.08, 0.16, 0.32, 0.9))
				_canvas.draw_rect(jr, Color(0.30, 0.65, 1.0), false, 2.0)
				if font:
					_canvas.draw_string(font, Vector2(jr.position.x, jr.position.y + 27.0), "SALTAR", HORIZONTAL_ALIGNMENT_CENTER, jr.size.x, 12, Color.WHITE)
		Phase.DEFEAT:
			if font:
				_canvas.draw_string(font, Vector2(sr.position.x, br.position.y + 42), "Tomaste un respiro", HORIZONTAL_ALIGNMENT_CENTER, sr.size.x, 18, Color(1.0, 0.86, 0.32))
				_canvas.draw_string(font, Vector2(sr.position.x, br.position.y + 82), "Toca o pulsa Espacio para reintentar esta oleada con 92 HP", HORIZONTAL_ALIGNMENT_CENTER, sr.size.x, 12, Color.WHITE)

	# 6. Barra inferior de HP y 4 botones Undertale
	_draw_bottom_hud(sz, font)

	if allow_standalone_exit:
		var er := _get_standalone_exit_rect()
		_canvas.draw_rect(er, Color(0, 0, 0, 0.92))
		_canvas.draw_rect(er, Color(0.96, 0.56, 0.16), false, 2.0)
		if font:
			_canvas.draw_string(font, er.position + Vector2(0, 18), "SALIR", HORIZONTAL_ALIGNMENT_CENTER, er.size.x, 11, Color(1.0, 0.90, 0.35))

	if _screen_flash > 0.01:
		_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 1, 1, _screen_flash * 0.75))

func _on_box_draw() -> void:
	if _box_clip == null:
		return
	if phase == Phase.DODGING:
		var off := _box_clip.position
		_draw_hazards(off)
		_draw_soul_heart(off)
	elif phase == Phase.DEFEAT:
		_draw_soul_heart(_box_clip.position)

func _draw_valor_gauge(br: Rect2, font: Font) -> void:
	var cy := br.get_center().y
	var left_x := br.position.x + 28.0
	var right_x := br.end.x - 28.0
	var mid_x := (left_x + right_x) * 0.5
	_canvas.draw_rect(Rect2(left_x, cy - 22.0, right_x - left_x, 44.0), Color(0.10, 0.14, 0.22), false, 2.0)
	# Zonas concéntricas verdes/doradas hacia el centro
	_canvas.draw_rect(Rect2(mid_x - 60.0, cy - 18.0, 120.0, 36.0), Color(0.18, 0.55, 0.28, 0.45))
	_canvas.draw_rect(Rect2(mid_x - 16.0, cy - 18.0, 32.0, 36.0), Color(0.95, 0.85, 0.25, 0.70))
	var bar_x := lerpf(left_x, right_x, clampf((_valor_cursor + 1.0) * 0.5, 0.0, 1.0))
	var bar_col := Color(1.0, 0.92, 0.32) if int(_time * 16.0) % 2 == 0 or not _valor_hit_done else Color.WHITE
	_canvas.draw_rect(Rect2(bar_x - 4.0, cy - 26.0, 8.0, 52.0), bar_col)
	if font:
		_canvas.draw_string(font, Vector2(br.position.x, br.end.y - 10.0), "Pulsa [Espacio] o toca el cuadro en el centro", HORIZONTAL_ALIGNMENT_CENTER, br.size.x, 11, Color(0.85, 0.92, 1.0))

func _draw_hazards(off: Vector2 = Vector2.ZERO) -> void:
	for bm in _beams:
		var p0 := (bm["pos"] as Vector2) - off
		var dir := Vector2(cos(float(bm["angle"])), sin(float(bm["angle"])))
		var p1 := p0 + dir * float(bm["length"])
		var kind := str(bm["kind"])
		var tint := Color.WHITE
		if kind == "cyan":
			tint = Color(0.28, 0.92, 1.0)
		elif kind == "orange":
			tint = Color(1.0, 0.62, 0.20)
		_box_clip.draw_circle(p0, 9.0, Color(0.88, 0.88, 0.94))
		_box_clip.draw_circle(p0, 5.0, tint)
		if float(bm["warn_left"]) > 0.0:
			var blink := 0.35 + 0.55 * absf(sin(_time * 24.0))
			_box_clip.draw_line(p0, p1, Color(tint.r, tint.g, tint.b, blink) if kind != "white" else Color(1.0, 0.25, 0.30, blink), 2.0)
		else:
			var frac := clampf(float(bm["active_left"]) / maxf(0.05, float(bm["max_active"])), 0.0, 1.0)
			var w := float(bm["width"]) * (0.4 + 0.6 * frac)
			_box_clip.draw_line(p0, p1, Color(tint.r, tint.g, tint.b, 0.50), w + 6.0)
			_box_clip.draw_line(p0, p1, Color(1, 1, 1, 0.95), w)

	for b in _bullets:
		var p := (b["pos"] as Vector2) - off
		var kind := str(b["kind"])
		var col := Color.WHITE
		if kind == "cyan":
			col = Color(0.28, 0.92, 1.0)
		elif kind == "orange":
			col = Color(1.0, 0.62, 0.20)
		if str(b["shape"]) == "bone":
			var bsz := b["size"] as Vector2
			_box_clip.draw_rect(Rect2(p - bsz * 0.5, bsz), col)
			_box_clip.draw_circle(Vector2(p.x - bsz.x * 0.3, p.y - bsz.y * 0.5), 4.0, col)
			_box_clip.draw_circle(Vector2(p.x + bsz.x * 0.3, p.y + bsz.y * 0.5), 4.0, col)
		elif str(b["shape"]) == "diamond":
			var r := float(b["radius"]) + 1.5
			var pts := PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)])
			_box_clip.draw_polygon(pts, [col])
		else:
			_box_clip.draw_circle(p, float(b["radius"]), col)

func _draw_soul_heart(off: Vector2 = Vector2.ZERO) -> void:
	if _invuln_timer > 0.0 and int(_time * 20.0) % 2 == 0:
		return
	var col := Color(0.18, 0.45, 1.0) if soul_mode == SoulMode.BLUE else Color(1.0, 0.14, 0.24)
	if phase == Phase.DEFEAT:
		col = Color(0.85, 0.18, 0.25)
	var px := 2.0
	var rows := [
		"011000110",
		"111101111",
		"111111111",
		"111111111",
		"011111110",
		"001111100",
		"000111000",
		"000010000",
	]
	var lsoul := _soul_pos - off
	var ox := lsoul.x - 4.5 * px
	var oy := lsoul.y - 4.0 * px
	for r in range(rows.size()):
		var row_str: String = rows[r]
		for c in range(row_str.length()):
			if row_str[c] == "1":
				_box_clip.draw_rect(Rect2(ox + float(c) * px, oy + float(r) * px, px + 0.3, px + 0.3), col)

func _draw_bottom_hud(sz: Vector2, font: Font) -> void:
	var sr := _get_safe_rect()
	var gs := _get_game_settings()
	var is_fem := gs != null and int(gs.get("selected_character")) == 1
	var hero_tag := "GUARDIANA" if is_fem else "GUARDIÁN"
	var status_y := sr.end.y - 62.0
	var bar_w := minf(160.0, sr.size.x * 0.24)
	var bar_x := sr.get_center().x - 30.0
	if font:
		_canvas.draw_string(font, Vector2(maxf(sr.position.x + 8.0, sr.get_center().x - 280.0), status_y + 12), "%s   NIVEL 19" % hero_tag, HORIZONTAL_ALIGNMENT_LEFT, 210, 12, Color.WHITE)
		_canvas.draw_string(font, Vector2(bar_x - 28.0, status_y + 12), "HP", HORIZONTAL_ALIGNMENT_LEFT, 26, 11, Color(1.0, 0.88, 0.25))
		_canvas.draw_string(font, Vector2(bar_x + bar_w + 10.0, status_y + 12), "%02d / %d" % [hp, max_hp], HORIZONTAL_ALIGNMENT_LEFT, 90, 12, Color.WHITE)
	_canvas.draw_rect(Rect2(bar_x, status_y, bar_w, 15.0), Color(0.82, 0.12, 0.14))
	var fill_w := bar_w * clampf(float(hp) / float(MAX_HP), 0.0, 1.0)
	if fill_w > 0.5:
		_canvas.draw_rect(Rect2(bar_x, status_y, fill_w, 15.0), Color(1.0, 0.88, 0.18))

	var rects := _get_menu_button_rects()
	var mercy_ready := _is_mercy_ready()
	for i in range(rects.size()):
		var r := rects[i]
		var selected := (phase == Phase.MENU and _menu_index == i)
		var is_mercy_glow := (i == 3 and mercy_ready)
		var border_col := Color(1.0, 0.90, 0.25) if (selected or is_mercy_glow) else Color(0.96, 0.50, 0.14)
		_canvas.draw_rect(r, Color(0, 0, 0, 1))
		_canvas.draw_rect(r, border_col, false, 2.5 if (selected or is_mercy_glow) else 2.0)
		if font:
			var label: String = str(MENU_LABELS[i])
			if selected:
				label = "♥ " + label
			_canvas.draw_string(font, r.position + Vector2(0, 22), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, border_col)
