extends CanvasLayer
class_name InterludeMinigame

## Minijuegos breves aleatorios entre edificios (15-25s, sin Game Over) con estética Undertale.
## 1) El Termo del Receso: medidor elíptico clásico verde-amarillo-rojo (Imagen 4).
## 2) Apuntes en el Viento de Enthavi: caja blanca con corazón pixel-art 9x8 atrapando hojas.
## 3) El Chat del Grupo: caja de diálogo envuelta sin desbordes + corazón selector + reacciones.

signal interlude_finished(reward: Dictionary)

enum Kind { TERMO_RECESO, APUNTES_VIENTO, CHAT_GRUPO }

static var trigger_probability: float = 0.50

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

const KIND_INFO := {
	Kind.TERMO_RECESO: {
		"id": "interlude_termo",
		"title": "El Termo del Receso",
		"subtitle": "Sirve atole caliente en la zona verde del medidor",
		"hint": "PC: Espacio o Clic · Móvil: toca cualquier parte de la pantalla",
		"reward_desc": "+1 Corazón extra (o Pulso listo) al acertar 2 de 3",
	},
	Kind.APUNTES_VIENTO: {
		"id": "interlude_apuntes",
		"title": "Apuntes en el Viento de Enthavi",
		"subtitle": "Atrapa las hojas volando antes de que caigan del cuadro",
		"hint": "PC: WASD/Flechas o Arrastre · Móvil: arrastra tu corazón dentro del cuadro",
		"reward_desc": "Escudo de Respeto (4s) al atrapar 3 hojas",
	},
	Kind.CHAT_GRUPO: {
		"id": "interlude_chat",
		"title": "El Chat del Grupo",
		"subtitle": "Calma la tensión del grupo con claridad y respeto",
		"hint": "PC: Flechas+Espacio o 1/2/3 · Móvil: toca tu respuesta",
		"reward_desc": "Apoyo del grupo (-1 en cuota) con 2 buenas respuestas",
	},
}

const CHAT_ROUNDS: Array[Dictionary] = [
	{
		"sender": "Grupo 3°B",
		"msg": "Subieron una foto de Mateo dormido en la banca para hacer memes",
		"options": [
			{"label": "Enviar mensaje de Diego: Ya déjenlo, viaja 40 minutos", "good": true, "react": "Diego: Ese mensaje cortó la burla a tiempo."},
			{"label": "Preguntar con firmeza por qué comparten fotos sin permiso", "good": true, "react": "Valeria: Directo y sin rodeos, bien dicho."},
			{"label": "Dejar en visto aunque la sigan reenviando", "good": false, "react": "María: Conviene decir algo antes de que la compartan más."},
		],
	},
	{
		"sender": "Aviso sin fuente",
		"msg": "Dicen que van a reprobar a medio salón en Mate esta semana",
		"options": [
			{"label": "Preguntar quién lo confirmó antes de generar susto", "good": true, "react": "Fernanda: Regla de biblioteca, revisar siempre la fuente."},
			{"label": "Compartir la guía de apuntes para repasar en el descanso", "good": true, "react": "Sofía: Buena idea, armamos círculo de estudio."},
			{"label": "Reenviar el aviso a otro grupo por si acaso", "good": false, "react": "Diego: Sin verificar datos solo se esparce preocupación."},
		],
	},
	{
		"sender": "Primer semestre",
		"msg": "Alguien sabe si hoy se puede jugar reta o solo entran de sexto",
		"options": [
			{"label": "Invitarlo a la cancha porque hay balón extra para todos", "good": true, "react": "Alejandro: Esa es la actitud de juego limpio."},
			{"label": "Explicar que se juega por turnos y no por semestre", "good": true, "react": "Mateo: También me apunto si jugamos sin empujones."},
			{"label": "Decirle que aguante los empujones si quiere entrar", "good": false, "react": "Alejandro: Así nadie se siente bienvenido en la cancha."},
		],
	},
]

static func should_trigger(rng_roll: float = -1.0) -> bool:
	var roll := rng_roll if rng_roll >= 0.0 else randf()
	return roll < clampf(trigger_probability, 0.0, 1.0)

static func get_kind_info(target_kind: Kind) -> Dictionary:
	return KIND_INFO.get(target_kind, KIND_INFO[Kind.TERMO_RECESO]).duplicate(true)

var kind: Kind = Kind.TERMO_RECESO
var unlocked_allies: Array[String] = []
var allow_standalone_exit: bool = false

var _time: float = 0.0
var _score: int = 0
var _round_idx: int = 0
var _summary_mode: bool = false
var _summary_timer: float = 0.0
var _emitted_finished: bool = false

# Termo del Receso
var _bar_cursor: float = -1.0
var _bar_dir: float = 1.0
var _bar_feedback: String = "* Pulsa justo sobre la zona verde."

# Apuntes en el Viento
var _player_pos: Vector2 = Vector2(400, 260)
var _pages: Array[Dictionary] = []
var _gusts: Array[Dictionary] = []
var _wind_timer: float = 10.0
var _spawn_timer: float = 0.0
var _drag_touch_id: int = -1
var _last_touch_pos: Vector2 = Vector2.ZERO
var _mouse_dragging: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO

# Chat del Grupo
var _chat_selected: int = 0
var _chat_feedback: String = ""
var _chat_wait_next: bool = false

var _bg_canvas: Control
var _arena_clip: Control
var _sfx_good: AudioStreamPlayer
var _sfx_tick: AudioStreamPlayer

func setup_interlude(target_kind: Kind, allies: Array[String] = []) -> void:
	kind = target_kind
	unlocked_allies = allies.duplicate()
	_score = 0
	_round_idx = 0
	_summary_mode = false
	_summary_timer = 0.0
	_emitted_finished = false
	_bar_cursor = -0.95
	_bar_dir = 1.0
	_bar_feedback = "* Pulsa justo sobre la zona verde."
	var ar := _get_arena_rect()
	_player_pos = ar.get_center()
	_pages.clear()
	_gusts.clear()
	_wind_timer = 10.0
	_spawn_timer = 0.0
	_drag_touch_id = -1
	_mouse_dragging = false
	_chat_selected = 0
	_chat_feedback = ""
	_chat_wait_next = false
	if kind == Kind.APUNTES_VIENTO:
		_spawn_wind_entities(true)
	_sync_clip()
	_queue_redraw_all()

func force_finish_for_test() -> void:
	_emit_reward_and_close()

func _ready() -> void:
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx_good = _make_sfx("res://assets/audio/victoria.wav", -5.0)
	_sfx_tick = _make_sfx("res://assets/audio/ataque.wav", -6.0)
	_bg_canvas = Control.new()
	_bg_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_bg_canvas.draw.connect(_on_bg_draw)
	add_child(_bg_canvas)

	_arena_clip = Control.new()
	_arena_clip.clip_contents = true
	_arena_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena_clip.draw.connect(_on_arena_draw)
	_bg_canvas.add_child(_arena_clip)
	setup_interlude(kind, unlocked_allies)

func _exit_tree() -> void:
	for s in [_sfx_good, _sfx_tick]:
		if s and is_instance_valid(s):
			s.stop()
			s.stream = null

func _make_sfx(path: String, vol_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	p.volume_db = vol_db
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(path):
		p.stream = ResourceLoader.load(path) as AudioStream
	add_child(p)
	return p

func _play_sfx(p: AudioStreamPlayer, pitch: float = 1.0) -> void:
	if p and p.stream:
		p.pitch_scale = pitch
		p.play()

func _get_vp_size() -> Vector2:
	if is_inside_tree() and get_viewport():
		var sz := get_viewport().get_visible_rect().size
		if sz.x > 10.0 and sz.y > 10.0:
			return sz
	return Vector2(800.0, 450.0)

func _get_safe_rect() -> Rect2:
	var vp := _get_vp_size()
	if not is_inside_tree() or get_viewport() == null:
		return Rect2(Vector2(16, 12), vp - Vector2(32, 24))
	var ins := MobileControls.get_safe_insets_for_viewport(get_viewport(), 14.0)
	return Rect2(ins.position.x, ins.position.y, maxf(300.0, vp.x - ins.position.x - ins.size.x), maxf(240.0, vp.y - ins.position.y - ins.size.y))

func _get_arena_rect() -> Rect2:
	var sr := _get_safe_rect()
	var w := clampf(sr.size.x * 0.74, 300.0, 560.0)
	var h := clampf(sr.size.y * 0.58, 190.0, 268.0)
	return Rect2(sr.get_center().x - w * 0.5, sr.position.y + 80.0, w, h)

func _sync_clip() -> void:
	if _arena_clip == null:
		return
	var inner := _get_arena_rect().grow(-4.0)
	_arena_clip.position = inner.position
	_arena_clip.size = Vector2(maxf(8.0, inner.size.x), maxf(8.0, inner.size.y))

func _queue_redraw_all() -> void:
	if _bg_canvas:
		_bg_canvas.queue_redraw()
	if _arena_clip:
		_arena_clip.queue_redraw()

func _get_chat_option_rects() -> Array[Rect2]:
	var ar := _get_arena_rect()
	var rects: Array[Rect2] = []
	var y0 := ar.position.y + 92.0
	for i in range(3):
		rects.append(Rect2(ar.position.x + 14.0, y0 + float(i) * 48.0, ar.size.x - 28.0, 42.0))
	return rects

func _get_exit_rect() -> Rect2:
	var sr := _get_safe_rect()
	return Rect2(sr.end.x - 84.0, sr.position.y + 4.0, 78.0, 26.0)

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	_time += dt
	_sync_clip()

	if _summary_mode:
		_summary_timer -= dt
		if _summary_timer <= 0.0:
			_emit_reward_and_close()
		_queue_redraw_all()
		return

	match kind:
		Kind.TERMO_RECESO:
			_bar_cursor += _bar_dir * (1.45 + float(_round_idx) * 0.14) * dt
			if _bar_cursor >= 1.0:
				_bar_cursor = 1.0
				_bar_dir = -1.0
			elif _bar_cursor <= -1.0:
				_bar_cursor = -1.0
				_bar_dir = 1.0
		Kind.APUNTES_VIENTO:
			_update_wind_game(dt)

	_queue_redraw_all()

func _spawn_wind_entities(initial: bool = false) -> void:
	var ar := _get_arena_rect()
	var count := 4 if initial else 1
	for _i in range(count):
		_pages.append({
			"pos": Vector2(randf_range(ar.position.x + 26.0, ar.end.x - 26.0), ar.position.y + (randf_range(18.0, 62.0) if initial else -6.0)),
			"vel": Vector2(randf_range(-18.0, 18.0), randf_range(34.0, 52.0)),
		})
	if initial or _gusts.size() < 2:
		_gusts.append({
			"pos": Vector2(randf_range(ar.position.x + 42.0, ar.end.x - 42.0), randf_range(ar.position.y + 48.0, ar.end.y - 38.0)),
			"vel": Vector2(randf_range(-48.0, 48.0), randf_range(-24.0, 24.0)),
		})

func _read_dir_input() -> Vector2:
	var inp := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if inp.length_squared() > 0.01:
		return inp
	var dx := 0.0
	var dy := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): dx -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dx += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): dy -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): dy += 1.0
	var v := Vector2(dx, dy)
	return v.normalized() if v.length_squared() > 1.0 else v

func _update_wind_game(dt: float) -> void:
	var ar := _get_arena_rect()
	_wind_timer -= dt
	_spawn_timer += dt
	if _spawn_timer >= 1.20 and _pages.size() < 5:
		_spawn_timer = 0.0
		_spawn_wind_entities(false)

	var inp := _read_dir_input()
	_player_pos += inp * 215.0 * dt
	_player_pos.x = clampf(_player_pos.x, ar.position.x + 14.0, ar.end.x - 14.0)
	_player_pos.y = clampf(_player_pos.y, ar.position.y + 14.0, ar.end.y - 14.0)

	for g in _gusts:
		var gp := (g["pos"] as Vector2) + (g["vel"] as Vector2) * dt
		if gp.x < ar.position.x + 18.0 or gp.x > ar.end.x - 18.0:
			g["vel"] = Vector2(-(g["vel"] as Vector2).x, (g["vel"] as Vector2).y)
		if gp.y < ar.position.y + 18.0 or gp.y > ar.end.y - 18.0:
			g["vel"] = Vector2((g["vel"] as Vector2).x, -(g["vel"] as Vector2).y)
		g["pos"] = gp
		if _player_pos.distance_squared_to(gp) <= 400.0 and (inp.length_squared() > 0.01 or _drag_touch_id != -1 or _mouse_dragging):
			_player_pos += (_player_pos - gp).normalized() * 38.0 * dt

	for i in range(_pages.size() - 1, -1, -1):
		var pg: Dictionary = _pages[i]
		var ppos := (pg["pos"] as Vector2) + (pg["vel"] as Vector2) * dt
		pg["pos"] = ppos
		if _player_pos.distance_squared_to(ppos) <= 529.0:
			_score += 1
			_play_sfx(_sfx_good, 1.25)
			_pages.remove_at(i)
		elif ppos.y > ar.end.y - 6.0:
			_pages.remove_at(i)

	if _score >= 5 or _wind_timer <= 0.0:
		_enter_summary()

func _trigger_termo_tap() -> void:
	if _summary_mode:
		_emit_reward_and_close()
		return
	if absf(_bar_cursor) <= 0.34:
		_score += 1
		_bar_feedback = "* Justo en lo verde. Taza caliente y choque de manos (+1)."
		_play_sfx(_sfx_good, 1.25)
	else:
		_bar_feedback = "* Cerca de la marca. Un poco cargado, pero con buen ánimo."
		_play_sfx(_sfx_tick, 0.9)
	_round_idx += 1
	_bar_cursor = -0.95 if (_round_idx % 2 == 0) else 0.95
	_bar_dir = 1.0 if (_round_idx % 2 == 0) else -1.0
	if _round_idx >= 3:
		_enter_summary()

func _choose_chat_option(opt_idx: int) -> void:
	if _summary_mode:
		_emit_reward_and_close()
		return
	if _chat_wait_next:
		_chat_wait_next = false
		_chat_feedback = ""
		_chat_selected = 0
		_round_idx += 1
		if _round_idx >= CHAT_ROUNDS.size():
			_enter_summary()
		return
	var r_data: Dictionary = CHAT_ROUNDS[clampi(_round_idx, 0, CHAT_ROUNDS.size() - 1)]
	var opts: Array = r_data.get("options", [])
	if opt_idx < 0 or opt_idx >= opts.size():
		return
	var chosen: Dictionary = opts[opt_idx]
	if bool(chosen.get("good", false)):
		_score += 1
		_play_sfx(_sfx_good, 1.2)
	else:
		_play_sfx(_sfx_tick, 0.9)
	_chat_feedback = str(chosen.get("react", ""))
	if not unlocked_allies.is_empty():
		_chat_feedback += "\n[%s en línea]" % unlocked_allies[mini(_round_idx, unlocked_allies.size() - 1)]
	_chat_wait_next = true

func _enter_summary() -> void:
	_summary_mode = true
	_summary_timer = 1.6

func _build_reward_dict() -> Dictionary:
	match kind:
		Kind.TERMO_RECESO:
			if _score >= 2:
				return {"kind": "heart", "label": "+1 Corazón extra (o Pulso listo)", "score": _score, "max_score": 3}
			return {"kind": "pulse_ready", "label": "Respiro del receso", "score": _score, "max_score": 3}
		Kind.APUNTES_VIENTO:
			if _score >= 3:
				return {"kind": "shield", "label": "Escudo de Respeto (4s)", "score": _score, "max_score": 5}
			return {"kind": "pulse_ready", "label": "Apuntes ordenados", "score": _score, "max_score": 5}
		_:
			if _score >= 2:
				return {"kind": "quota_bonus", "label": "Apoyo del grupo (-1 en cuota)", "score": _score, "max_score": 3}
			return {"kind": "pulse_ready", "label": "Buen ánimo en el grupo", "score": _score, "max_score": 3}

func _emit_reward_and_close() -> void:
	if _emitted_finished:
		return
	_emitted_finished = true
	interlude_finished.emit(_build_reward_dict())
	queue_free()

func _input(event: InputEvent) -> void:
	if _emitted_finished:
		return
	var is_real_mouse := event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION
	var is_real_touch := (event is InputEventScreenTouch or event is InputEventScreenDrag) and event.device != InputEvent.DEVICE_ID_EMULATION

	if allow_standalone_exit:
		var hit_exit := false
		if is_real_mouse and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			hit_exit = _get_exit_rect().has_point((event as InputEventMouseButton).position)
		elif event is InputEventScreenTouch and is_real_touch and (event as InputEventScreenTouch).pressed:
			hit_exit = _get_exit_rect().has_point((event as InputEventScreenTouch).position)
		elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			hit_exit = true
		if hit_exit:
			_emit_reward_and_close()
			_mark_handled()
			return

	if _summary_mode:
		if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventJoypadButton and event.pressed and not event.is_echo()) or (is_real_mouse and (event as InputEventMouseButton).pressed) or (event is InputEventScreenTouch and is_real_touch and (event as InputEventScreenTouch).pressed):
			_emit_reward_and_close()
			_mark_handled()
		return

	if kind == Kind.TERMO_RECESO:
		var joy_confirm: bool = event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed and not event.is_echo() and (event as InputEventJoypadButton).button_index in [JOY_BUTTON_A, JOY_BUTTON_X, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_START]
		if (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_Z]) or joy_confirm or (is_real_mouse and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and is_real_touch and (event as InputEventScreenTouch).pressed):
			_trigger_termo_tap()
			_mark_handled()
	elif kind == Kind.APUNTES_VIENTO:
		if is_real_mouse:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				_mouse_dragging = mb.pressed
				_last_mouse_pos = mb.position
		elif event is InputEventMouseMotion and _mouse_dragging and event.device != InputEvent.DEVICE_ID_EMULATION:
			var mm := event as InputEventMouseMotion
			var ar := _get_arena_rect()
			_player_pos += (mm.position - _last_mouse_pos) * 1.15
			_last_mouse_pos = mm.position
			_player_pos.x = clampf(_player_pos.x, ar.position.x + 14.0, ar.end.x - 14.0)
			_player_pos.y = clampf(_player_pos.y, ar.position.y + 14.0, ar.end.y - 14.0)
		elif event is InputEventScreenTouch and is_real_touch:
			var st := event as InputEventScreenTouch
			if st.pressed and _drag_touch_id == -1:
				_drag_touch_id = st.index
				_last_touch_pos = st.position
			elif not st.pressed and st.index == _drag_touch_id:
				_drag_touch_id = -1
		elif event is InputEventScreenDrag and is_real_touch:
			var sd := event as InputEventScreenDrag
			if sd.index == _drag_touch_id:
				var ar := _get_arena_rect()
				_player_pos += (sd.position - _last_touch_pos) * 1.15
				_last_touch_pos = sd.position
				_player_pos.x = clampf(_player_pos.x, ar.position.x + 14.0, ar.end.x - 14.0)
				_player_pos.y = clampf(_player_pos.y, ar.position.y + 14.0, ar.end.y - 14.0)
	elif kind == Kind.CHAT_GRUPO:
		if event is InputEventKey and event.pressed and not event.echo:
			match event.keycode:
				KEY_UP, KEY_W:
					_chat_selected = posmod(_chat_selected - 1, 3)
					_mark_handled()
				KEY_DOWN, KEY_S:
					_chat_selected = posmod(_chat_selected + 1, 3)
					_mark_handled()
				KEY_1:
					_choose_chat_option(0)
					_mark_handled()
				KEY_2:
					_choose_chat_option(1)
					_mark_handled()
				KEY_3:
					_choose_chat_option(2)
					_mark_handled()
				KEY_SPACE, KEY_ENTER, KEY_Z:
					_choose_chat_option(_chat_selected)
					_mark_handled()
		elif event is InputEventJoypadButton and event.pressed and not event.is_echo():
			match event.button_index:
				JOY_BUTTON_DPAD_UP:
					_chat_selected = posmod(_chat_selected - 1, 3)
					_mark_handled()
				JOY_BUTTON_DPAD_DOWN:
					_chat_selected = posmod(_chat_selected + 1, 3)
					_mark_handled()
				JOY_BUTTON_A, JOY_BUTTON_START:
					_choose_chat_option(_chat_selected)
					_mark_handled()
		elif (is_real_mouse and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and is_real_touch and (event as InputEventScreenTouch).pressed):
			var p: Vector2 = (event as InputEventMouseButton).position if event is InputEventMouseButton else (event as InputEventScreenTouch).position
			if _chat_wait_next:
				_choose_chat_option(0)
				_mark_handled()
				return
			var orects := _get_chat_option_rects()
			for i in range(orects.size()):
				if orects[i].has_point(p):
					_choose_chat_option(i)
					_mark_handled()
					return

func _mark_handled() -> void:
	if is_inside_tree() and get_viewport():
		get_viewport().set_input_as_handled()

func _draw_pixel_heart(target: Control, center: Vector2, col: Color, px: float = 1.8) -> void:
	for ry in range(HEART_ROWS.size()):
		var line: String = HEART_ROWS[ry]
		for rx in range(line.length()):
			if line[rx] == "X":
				target.draw_rect(Rect2(center + Vector2((float(rx) - 4.0) * px, (float(ry) - 3.5) * px), Vector2(px, px)), col)

func _on_bg_draw() -> void:
	var vp := _get_vp_size()
	var sr := _get_safe_rect()
	var ar := _get_arena_rect()
	var font := ThemeDB.fallback_font
	var info := get_kind_info(kind)

	_bg_canvas.draw_rect(Rect2(Vector2.ZERO, vp), Color.BLACK)
	_bg_canvas.draw_string(font, Vector2(sr.position.x + 12.0, sr.position.y + 24.0), "RECESO — %s" % str(info["title"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.90, 0.30))
	_bg_canvas.draw_string(font, Vector2(sr.position.x + 12.0, sr.position.y + 44.0), str(info["subtitle"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.90, 0.98))
	_bg_canvas.draw_string(font, Vector2(sr.position.x + 12.0, sr.end.y - 14.0), str(info["hint"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.70, 0.85, 0.95))

	if allow_standalone_exit:
		var er := _get_exit_rect()
		_bg_canvas.draw_rect(er, Color.BLACK)
		_bg_canvas.draw_rect(er, Color(1.0, 0.55, 0.14), false, 2.0)
		_bg_canvas.draw_string(font, Vector2(er.position.x + 18.0, er.position.y + 17.0), "Salir", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

	_bg_canvas.draw_rect(ar, Color.BLACK)
	_bg_canvas.draw_rect(ar, Color.WHITE, false, 4.0)

func _on_arena_draw() -> void:
	var off := _arena_clip.position
	var sz := _arena_clip.size
	var font := ThemeDB.fallback_font

	if _summary_mode:
		var rew := _build_reward_dict()
		_arena_clip.draw_string(font, Vector2(20.0, sz.y * 0.42), "* Receso completado (%d / %d)" % [int(rew["score"]), int(rew["max_score"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.28, 0.94, 0.52))
		_arena_clip.draw_string(font, Vector2(20.0, sz.y * 0.58), "* Bono: %s" % str(rew["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.92, 0.30))
		return

	match kind:
		Kind.TERMO_RECESO:
			_arena_clip.draw_string(font, Vector2(14.0, 26.0), "Ronda %d / 3   ·   Aciertos: %d" % [mini(3, _round_idx + 1), _score], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
			var c := sz * 0.5
			var half_w := sz.x * 0.42
			var half_h := 30.0
			_arena_clip.draw_rect(Rect2(c.x - half_w, c.y - half_h, half_w * 2.0, half_h * 2.0), Color(0.75, 0.16, 0.18))
			_arena_clip.draw_rect(Rect2(c.x - half_w * 0.58, c.y - half_h, half_w * 1.16, half_h * 2.0), Color(0.95, 0.85, 0.20))
			_arena_clip.draw_rect(Rect2(c.x - half_w * 0.34, c.y - half_h, half_w * 0.68, half_h * 2.0), Color(0.20, 0.90, 0.38))
			_arena_clip.draw_rect(Rect2(c.x - half_w, c.y - half_h, half_w * 2.0, half_h * 2.0), Color.WHITE, false, 2.5)
			var cx := c.x + _bar_cursor * (half_w - 6.0)
			_arena_clip.draw_rect(Rect2(cx - 4.0, c.y - half_h - 6.0, 8.0, half_h * 2.0 + 12.0), Color.WHITE)
			_draw_wrapped_text(_arena_clip, font, Vector2(14.0, sz.y - 34.0), sz.x - 28.0, _bar_feedback, 12, Color(0.80, 0.95, 1.0))

		Kind.APUNTES_VIENTO:
			_arena_clip.draw_string(font, Vector2(12.0, 20.0), "Hojas salvadas: %d / 5   ·   %.1fs" % [_score, maxf(0.0, _wind_timer)], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			for g in _gusts:
				var gp := (g["pos"] as Vector2) - off
				_arena_clip.draw_arc(gp, 15.0, _time * 4.0, _time * 4.0 + PI * 1.4, 14, Color(0.28, 0.92, 1.0), 2.5)
			for pg in _pages:
				var pp := (pg["pos"] as Vector2) - off
				_arena_clip.draw_rect(Rect2(pp - Vector2(8, 10), Vector2(16, 20)), Color.WHITE)
				_arena_clip.draw_rect(Rect2(pp - Vector2(5, 6), Vector2(10, 2)), Color.BLACK)
				_arena_clip.draw_rect(Rect2(pp - Vector2(5, 1), Vector2(10, 2)), Color.BLACK)
			_draw_pixel_heart(_arena_clip, _player_pos - off, Color(1.0, 0.16, 0.22), 1.9)

		Kind.CHAT_GRUPO:
			var r_data: Dictionary = CHAT_ROUNDS[clampi(_round_idx, 0, CHAT_ROUNDS.size() - 1)]
			_arena_clip.draw_string(font, Vector2(12.0, 20.0), "%s  (%d / 3)" % [str(r_data.get("sender", "")), _round_idx + 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.32, 0.94, 0.62))
			_draw_wrapped_text(_arena_clip, font, Vector2(12.0, 40.0), sz.x - 24.0, "* «%s»" % str(r_data.get("msg", "")), 12, Color.WHITE)
			if _chat_wait_next:
				_arena_clip.draw_rect(Rect2(12.0, 86.0, sz.x - 24.0, 96.0), Color(0.06, 0.08, 0.12))
				_arena_clip.draw_rect(Rect2(12.0, 86.0, sz.x - 24.0, 96.0), Color(1.0, 0.90, 0.30), false, 2.0)
				_draw_wrapped_text(_arena_clip, font, Vector2(22.0, 110.0), sz.x - 44.0, _chat_feedback, 12, Color(1.0, 0.92, 0.45))
				_arena_clip.draw_string(font, Vector2(22.0, 168.0), "Toca o pulsa Espacio ->", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.75, 0.92, 1.0))
			else:
				var orects := _get_chat_option_rects()
				var opts: Array = r_data.get("options", [])
				for i in range(mini(3, opts.size())):
					var lr := Rect2(orects[i].position - off, orects[i].size)
					var sel := (i == _chat_selected)
					_arena_clip.draw_rect(lr, Color(0.10, 0.12, 0.18) if sel else Color.BLACK)
					_arena_clip.draw_rect(lr, Color(1.0, 0.88, 0.25) if sel else Color(1.0, 0.55, 0.14), false, 2.0 if sel else 1.5)
					if sel:
						_draw_pixel_heart(_arena_clip, Vector2(lr.position.x + 14.0, lr.position.y + 20.0), Color(1.0, 0.16, 0.22), 1.4)
					_draw_wrapped_text(_arena_clip, font, Vector2(lr.position.x + 28.0, lr.position.y + 17.0), lr.size.x - 36.0, "%d) %s" % [i + 1, str(opts[i].get("label", ""))], 10, Color.WHITE)

func _draw_wrapped_text(target: Control, font: Font, pos: Vector2, max_w: float, text: String, sz: int, col: Color) -> void:
	var y := pos.y
	for para in text.split("\n"):
		var line := ""
		for word in para.split(" "):
			var cand := word if line.is_empty() else (line + " " + word)
			if font.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > max_w and not line.is_empty():
				target.draw_string(font, Vector2(pos.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
				y += float(sz) + 4.0
				line = word
			else:
				line = cand
		if not line.is_empty():
			target.draw_string(font, Vector2(pos.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
			y += float(sz) + 4.0
