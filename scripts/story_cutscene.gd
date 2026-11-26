extends Control
class_name StoryCutscene

const BossRendererClass := preload("res://scripts/boss_renderer.gd")

## Controlador Cinemático para el Modo Historia de "Campeones de los Valores".
## Despliega diálogos educativos, retratos pixel-art y trasfondo del CEMSaD 22 ENTHAVI.
## Optimizado para pantalla táctil, ratón, teclado y mando (multiplataforma).

signal cutscene_finished

@onready var chapter_title_label: Label = %ChapterTitleLabel
@onready var scenario_label: Label = %ScenarioLabel
@onready var speaker_name_label: Label = %SpeakerNameLabel
@onready var dialogue_label: RichTextLabel = %DialogueLabel
@onready var portrait_canvas: Control = %PortraitCanvas
@onready var btn_next: Button = %BtnNext
@onready var btn_skip: Button = %BtnSkip
@onready var progress_label: Label = %ProgressLabel
@onready var center_box: CenterContainer = get_node_or_null("%CenterBox")
@onready var dialog_panel: PanelContainer = get_node_or_null("%DialogPanel")
@onready var sfx_blip: AudioStreamPlayer = $SFXBlip

var _dialogue_nodes: Array = []
var _current_index: int = 0
var _cutscene_data: Dictionary = {}

var _is_typing: bool = false
var _full_text: String = ""
var _visible_chars: float = 0.0
var _chars_per_second: float = 38.0
var _current_portrait_id: String = ""
var _last_input_was_gamepad: bool = false
var _finishing: bool = false
var _last_pointer_advance_ms: int = -1000
var _portrait_draw_offset: Vector2 = Vector2.ZERO
var _portrait_tween: Tween = null
var _portrait_tex_cache: Dictionary = {}
var _base_blip_pitch: float = 1.25
var _skip_confirm_until_ms: int = 0

var _game_settings: Node:
	get:
		if not is_inside_tree():
			return null
		return get_node_or_null("/root/GameSettings")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP

	btn_next.pressed.connect(_advance_dialogue)
	btn_skip.pressed.connect(_skip_cutscene)
	UiJuice.attach_button(btn_next, sfx_blip)
	UiJuice.attach_button(btn_skip, sfx_blip)

	if portrait_canvas:
		portrait_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait_canvas.clip_contents = true
		portrait_canvas.draw.connect(_on_portrait_draw)

	get_viewport().size_changed.connect(_adjust_layout_for_viewport)
	_adjust_layout_for_viewport()

	if _game_settings and _game_settings.has_method("duck_music"):
		_game_settings.duck_music(true)

	if not _cutscene_data.is_empty():
		_start_display()

func _exit_tree() -> void:
	if _game_settings and _game_settings.has_method("duck_music"):
		_game_settings.duck_music(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_skip_cutscene()

func _adjust_layout_for_viewport() -> void:
	if not is_inside_tree():
		return
	var vp_size := get_viewport_rect().size
	var insets := MobileControls.get_safe_insets_for_viewport(get_viewport(), 16.0)

	var header: Control = get_node_or_null("HeaderContainer")
	if header:
		header.offset_left = insets.position.x
		header.offset_right = -insets.size.x
		header.offset_top = insets.position.y

	if center_box:
		center_box.offset_left = insets.position.x
		center_box.offset_right = -insets.size.x
		center_box.offset_bottom = -insets.size.y

	if dialog_panel:
		var avail_w := vp_size.x - insets.position.x - insets.size.x
		var max_panel_width := minf(avail_w - 16.0, 760.0)
		dialog_panel.custom_minimum_size.x = clampf(avail_w - 24.0, 320.0, max_panel_width)

func setup_cutscene(data: Dictionary) -> void:
	_cutscene_data = data
	_dialogue_nodes = data.get("dialogue_nodes", [])
	_current_index = 0
	if is_inside_tree() and btn_next != null:
		_start_display()

func _start_display() -> void:
	if _dialogue_nodes.is_empty():
		_finish()
		return

	var title: String = _cutscene_data.get("title", "Modo Historia")
	var loc: String = _cutscene_data.get("scenario_name", _cutscene_data.get("location", "CEMSaD 22 ENTHAVI"))
	if chapter_title_label:
		chapter_title_label.text = title
	if scenario_label:
		scenario_label.text = loc

	_show_node(0)

func _is_female_selected() -> bool:
	var gs := _game_settings
	if gs and "selected_character" in gs:
		return int(gs.selected_character) == 1
	var ml := Engine.get_main_loop()
	if ml is SceneTree and (ml as SceneTree).root:
		var root_gs := (ml as SceneTree).root.get_node_or_null("GameSettings")
		if root_gs and "selected_character" in root_gs:
			return int(root_gs.selected_character) == 1
	return false

func _show_node(idx: int) -> void:
	if idx < 0 or idx >= _dialogue_nodes.size():
		_finish()
		return

	_current_index = idx
	var node_data: Dictionary = _dialogue_nodes[_current_index]
	var is_fem := _is_female_selected()

	var speaker: String = node_data.get("speaker", "Voz Escolar")
	_full_text = node_data.get("text", "")
	if is_fem:
		if speaker == "Guardián de los Valores":
			speaker = "Guardiana de los Valores"
		elif speaker == "Guardián":
			speaker = "Guardiana"
		if node_data.has("text_f"):
			_full_text = str(node_data.get("text_f", _full_text))
	_current_portrait_id = node_data.get("portrait", "narrator")

	if speaker_name_label:
		speaker_name_label.text = speaker
		# Color temático según el orador
		if "Guardián" in speaker or "Guardiana" in speaker:
			speaker_name_label.modulate = Color(1.0, 0.90, 0.40)
		elif "Narrador" in speaker:
			speaker_name_label.modulate = Color(0.85, 0.85, 0.95)
		elif "Voz Ancestral" in speaker or "Otomí" in speaker:
			speaker_name_label.modulate = Color(1.0, 0.75, 0.35)
		elif "Coordinador" in speaker:
			speaker_name_label.modulate = Color(0.95, 0.85, 0.65)
		elif "Apatyx" in speaker or "Desperdicius" in speaker or "Superbus" in speaker or "Murmullus" in speaker or "Plagiatrix" in speaker or "Titanor" in speaker:
			speaker_name_label.modulate = Color(1.0, 0.45, 0.50)
		else:
			speaker_name_label.modulate = Color(0.45, 0.95, 0.75) # Alumnos secundarios

	if progress_label:
		progress_label.text = "%d / %d" % [_current_index + 1, _dialogue_nodes.size()]

	_update_button_prompts()

	_visible_chars = 0.0
	_is_typing = true
	if dialogue_label:
		dialogue_label.text = _full_text
		dialogue_label.visible_characters = 0
		var v_scroll := dialogue_label.get_v_scroll_bar()
		if v_scroll:
			v_scroll.value = 0.0

	if portrait_canvas:
		portrait_canvas.queue_redraw()
		_animate_portrait_emotion(str(node_data.get("emotion", "neutral")), str(node_data.get("sfx", "")))

func _animate_portrait_emotion(emotion: String, sfx_cue: String = "") -> void:
	if portrait_canvas == null or not is_inside_tree():
		return
	if _portrait_tween and _portrait_tween.is_valid():
		_portrait_tween.kill()
	_portrait_draw_offset = Vector2.ZERO
	portrait_canvas.queue_redraw()
	var emo := emotion.to_lower()
	if emo in ["scared", "angry", "fearful", "menacing_fury"]:
		_portrait_tween = portrait_canvas.create_tween()
		_portrait_tween.tween_method(_set_portrait_offset, Vector2(-4.0, 0.0), Vector2(4.0, 0.0), 0.06)
		_portrait_tween.tween_method(_set_portrait_offset, Vector2(4.0, 0.0), Vector2(-3.0, 0.0), 0.05)
		_portrait_tween.tween_method(_set_portrait_offset, Vector2(-3.0, 0.0), Vector2.ZERO, 0.05)
	elif emo in ["happy", "joyful", "proud_firm", "determined"]:
		_portrait_tween = portrait_canvas.create_tween()
		_portrait_tween.tween_method(_set_portrait_offset, Vector2.ZERO, Vector2(0.0, -5.0), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_portrait_tween.tween_method(_set_portrait_offset, Vector2(0.0, -5.0), Vector2.ZERO, 0.12)
	var cue := sfx_cue.to_lower()
	if emo in ["angry", "menacing_fury", "solemn"] or cue in ["ominous", "rumble", "boss"]:
		_base_blip_pitch = 0.85
	elif emo in ["happy", "joyful"] or cue in ["triumphant", "hopeful", "cheer"]:
		_base_blip_pitch = 1.42
	elif cue in ["alert", "warning"]:
		_base_blip_pitch = 1.12
	else:
		_base_blip_pitch = 1.25
	if sfx_blip:
		sfx_blip.pitch_scale = _base_blip_pitch

func _set_portrait_offset(off: Vector2) -> void:
	_portrait_draw_offset = off
	if portrait_canvas and is_instance_valid(portrait_canvas):
		portrait_canvas.queue_redraw()

func _update_button_prompts() -> void:
	var is_mobile := MobileControls.is_touch_device()
	var is_last := _current_index >= _dialogue_nodes.size() - 1

	if is_mobile:
		if btn_next:
			btn_next.text = "Finalizar" if is_last else "Continuar"
		if btn_skip:
			btn_skip.text = "Saltar"
	elif _last_input_was_gamepad:
		if btn_next:
			btn_next.text = "Finalizar (A)" if is_last else "Continuar (A)"
		if btn_skip:
			btn_skip.text = "Saltar (B)"
	else:
		if btn_next:
			btn_next.text = "Finalizar (Espacio)" if is_last else "Continuar (Espacio)"
		if btn_skip:
			btn_skip.text = "Saltar (Esc)"

func _process(delta: float) -> void:
	if _is_typing and dialogue_label:
		_visible_chars += _chars_per_second * delta
		var char_count: int = int(_visible_chars)
		if char_count != dialogue_label.visible_characters:
			dialogue_label.visible_characters = char_count
			if char_count % 3 == 0 and sfx_blip and char_count < _full_text.length():
				sfx_blip.pitch_scale = clampf(_base_blip_pitch + randf_range(-0.08, 0.08), 0.65, 1.75)
				sfx_blip.play()
			# Asegurar que el scroll vertical acompañe al texto mecanografiado
			var v_scroll := dialogue_label.get_v_scroll_bar()
			if v_scroll:
				v_scroll.value = v_scroll.max_value

		if char_count >= _full_text.length():
			dialogue_label.visible_characters = -1
			_is_typing = false

func _gui_input(event: InputEvent) -> void:
	# 1. Teclado / Clic / Toque físico en panel (filtrando emulación de ratón desde toque)
	var is_real_mouse: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION
	var is_real_touch: bool = event is InputEventScreenTouch and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION
	if is_real_mouse or is_real_touch:
		_last_input_was_gamepad = false
		_advance_dialogue(true)
		accept_event()

func _mark_input_handled() -> void:
	if is_inside_tree() and get_viewport():
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	# 1. Teclado
	if event is InputEventKey and event.pressed and not event.echo:
		_last_input_was_gamepad = false
		_update_button_prompts()
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_advance_dialogue()
			_mark_input_handled()
			return
		elif event.keycode == KEY_ESCAPE:
			_request_confirm_skip()
			_mark_input_handled()
			return

	# 2. Gamepad / Mando
	if event is InputEventJoypadButton and event.pressed:
		_last_input_was_gamepad = true
		_update_button_prompts()
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_X, JOY_BUTTON_RIGHT_SHOULDER]:
			_advance_dialogue()
			_mark_input_handled()
			return
		elif event.button_index in [JOY_BUTTON_B, JOY_BUTTON_BACK, JOY_BUTTON_START, JOY_BUTTON_Y]:
			_request_confirm_skip()
			_mark_input_handled()
			return

	# 3. Mapeos de acción comunes
	if event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		_advance_dialogue()
		_mark_input_handled()
		return
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_request_confirm_skip()
		_mark_input_handled()
		return

	# 4. Toque / Ratón genérico no capturado por botones (filtrando emulación touch->mouse)
	var is_real_mouse: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION
	var is_real_touch: bool = event is InputEventScreenTouch and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION
	if is_real_mouse or is_real_touch:
		_last_input_was_gamepad = false
		_advance_dialogue(true)
		_mark_input_handled()
		return

func _advance_dialogue(from_pointer: bool = false) -> void:
	if _finishing:
		return
	if from_pointer:
		var now_ms := Time.get_ticks_msec()
		if (now_ms - _last_pointer_advance_ms) < 120:
			return
		_last_pointer_advance_ms = now_ms
	if _is_typing:
		# Completar inmediatamente el texto en pantalla
		_is_typing = false
		if dialogue_label:
			dialogue_label.visible_characters = -1
	else:
		if _current_index + 1 < _dialogue_nodes.size():
			_show_node(_current_index + 1)
		else:
			_finish()

func _request_confirm_skip() -> void:
	if _finishing:
		return
	var now_ms := Time.get_ticks_msec()
	if now_ms <= _skip_confirm_until_ms:
		_skip_confirm_until_ms = 0
		_skip_cutscene()
		return
	_skip_confirm_until_ms = now_ms + 1800
	if btn_skip:
		btn_skip.text = "Confirmar Saltar"

func _skip_cutscene() -> void:
	if _finishing:
		return
	_finish()

func _finish() -> void:
	if _finishing:
		return
	_finishing = true
	set_process(false)
	if btn_next:
		btn_next.disabled = true
	if btn_skip:
		btn_skip.disabled = true
	if _game_settings and _game_settings.has_method("duck_music"):
		_game_settings.duck_music(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.22)
	await tw.finished
	if is_instance_valid(self):
		cutscene_finished.emit()
		queue_free()

func _get_portrait_texture(p: String) -> Texture2D:
	var path := ""
	if "guardian" in p or "guardiana" in p or "player" in p or "heroe" in p or "heroina" in p or "protagonista" in p:
		var is_fem := _is_female_selected()
		path = "res://assets/portraits/player_femenino.png" if is_fem else "res://assets/portraits/player_masculino.png"
	elif "mateo" in p:
		path = "res://assets/portraits/mateo_laboratorio.png"
	elif "maria" in p:
		path = "res://assets/portraits/maria_cafeteria.png"
	elif "valeria" in p:
		path = "res://assets/portraits/valeria_plaza.png"
	elif "fernanda" in p:
		path = "res://assets/portraits/fernanda_biblioteca.png"
	elif "diego" in p:
		path = "res://assets/portraits/diego_computo.png"
	elif "sofia" in p:
		path = "res://assets/portraits/sofia_direccion.png"
	elif "alejandro" in p or "emiliano" in p:
		path = "res://assets/portraits/alejandro_cancha.png"
	elif "desinteres" in p or "maestro" in p:
		if "redeem" in p:
			path = "res://assets/portraits/maestro_desinteres_redeemed.png"
		else:
			path = "res://assets/portraits/maestro_desinteres.png"
	elif "coordinador" in p:
		path = "res://assets/portraits/coordinador.png"

	if path != "":
		if _portrait_tex_cache.has(path):
			return _portrait_tex_cache[path] as Texture2D
		var loaded_tex := AssetLoader.load_texture(path)
		if loaded_tex != null:
			_portrait_tex_cache[path] = loaded_tex
			return loaded_tex
		if "guardian" in p or "player" in p or "heroe" in p or "protagonista" in p:
			var fallback_guardian := "res://assets/portraits/guardian.png"
			var fb_tex := AssetLoader.load_texture(fallback_guardian)
			if fb_tex != null:
				_portrait_tex_cache[fallback_guardian] = fb_tex
				return fb_tex
	return null

## Renderizado pixel-art de los retratos de personajes y antivalores
func _on_portrait_draw() -> void:
	if portrait_canvas == null:
		return
	var size: Vector2 = portrait_canvas.size
	var cx: float = size.x * 0.5
	var cy: float = size.y * 0.5

	# Fondo pizarra claro institucional para que cabellos negros y trazos pixel-art contrasten nítidos
	portrait_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(0.24, 0.27, 0.36, 1.0))
	portrait_canvas.draw_rect(Rect2(Vector2(0.0, size.y * 0.58), Vector2(size.x, size.y * 0.42)), Color(0.18, 0.20, 0.28, 1.0))
	portrait_canvas.draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0.84, 0.69, 0.36), false, 2.0)
	portrait_canvas.draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), Color(0.48, 0.14, 0.22, 0.85), false, 1.0)

	var p := _current_portrait_id.to_lower()

	# 0. Si existe un archivo PNG de retrato pixel art en assets/portraits/, dibujarlo centrado conservando proporción
	var portrait_png := _get_portrait_texture(p)
	if portrait_png:
		var inner_pad := 6.0
		var box_w := maxf(8.0, size.x - inner_pad * 2.0)
		var box_h := maxf(8.0, size.y - inner_pad * 2.0)
		var tex_sz := portrait_png.get_size()
		var tw := maxf(1.0, tex_sz.x)
		var th := maxf(1.0, tex_sz.y)
		var sc := minf(box_w / tw, box_h / th)
		var draw_w := tw * sc
		var draw_h := th * sc
		var dst_x := (size.x - draw_w) * 0.5 + _portrait_draw_offset.x
		var dst_y := size.y - inner_pad - draw_h + _portrait_draw_offset.y
		portrait_canvas.draw_texture_rect(portrait_png, Rect2(dst_x, dst_y, draw_w, draw_h), false)
		return

	# -------------------------------------------------------------------------
	# 1. HÉROE / HEROÍNA COBAEM (Guardián / Guardiana de los Valores)
	# -------------------------------------------------------------------------
	if "player" in p or "guardian" in p or "guardiana" in p:
		var is_fem_draw := _is_female_selected()
		# Hombros y suéter guinda institucional
		portrait_canvas.draw_rect(Rect2(cx - 30, size.y - 32, 60, 30), Color(0.48, 0.12, 0.20))
		# Cuello camisa blanca y corbata / moño escolar oro
		portrait_canvas.draw_polygon(PackedVector2Array([Vector2(cx - 10, size.y - 32), Vector2(cx + 10, size.y - 32), Vector2(cx, size.y - 18)]), [Color(0.95, 0.95, 0.95)])
		if is_fem_draw:
			portrait_canvas.draw_rect(Rect2(cx - 8, size.y - 28, 16, 6), Color(0.90, 0.75, 0.25))
		else:
			portrait_canvas.draw_rect(Rect2(cx - 3, size.y - 28, 6, 18), Color(0.90, 0.75, 0.25))
		# Rostro
		portrait_canvas.draw_rect(Rect2(cx - 20, cy - 24, 40, 38), Color(0.95, 0.78, 0.62))
		# Cabello castaño (mechones largos si es femenino)
		portrait_canvas.draw_rect(Rect2(cx - 24, cy - 36, 48, 18), Color(0.28, 0.16, 0.10))
		var lock_h := 34.0 if is_fem_draw else 20.0
		portrait_canvas.draw_rect(Rect2(cx - 24, cy - 24, 8, lock_h), Color(0.28, 0.16, 0.10))
		portrait_canvas.draw_rect(Rect2(cx + 16, cy - 24, 8, lock_h), Color(0.28, 0.16, 0.10))
		# Ojos y expresión según emoción
		if "celebrate" in p:
			# Ojos de arco jubiloso
			portrait_canvas.draw_line(Vector2(cx - 12, cy - 8), Vector2(cx - 6, cy - 10), Color(0.15, 0.10, 0.08), 2.0)
			portrait_canvas.draw_line(Vector2(cx + 6, cy - 10), Vector2(cx + 12, cy - 8), Color(0.15, 0.10, 0.08), 2.0)
			portrait_canvas.draw_line(Vector2(cx - 8, cy + 6), Vector2(cx + 8, cy + 6), Color(0.75, 0.20, 0.25), 3.0)
			# Estrellitas de júbilo
			portrait_canvas.draw_rect(Rect2(cx - 28, cy - 26, 4, 4), Color(1.0, 0.90, 0.30))
			portrait_canvas.draw_rect(Rect2(cx + 24, cy - 26, 4, 4), Color(1.0, 0.90, 0.30))
		elif "attack" in p or "brave" in p:
			portrait_canvas.draw_rect(Rect2(cx - 12, cy - 10, 6, 6), Color(0.15, 0.10, 0.08))
			portrait_canvas.draw_rect(Rect2(cx + 6, cy - 10, 6, 6), Color(0.15, 0.10, 0.08))
			# Cejas decididas
			portrait_canvas.draw_line(Vector2(cx - 14, cy - 14), Vector2(cx - 6, cy - 11), Color(0.25, 0.12, 0.08), 2.0)
			portrait_canvas.draw_line(Vector2(cx + 6, cy - 11), Vector2(cx + 14, cy - 14), Color(0.25, 0.12, 0.08), 2.0)
			portrait_canvas.draw_line(Vector2(cx - 7, cy + 6), Vector2(cx + 7, cy + 6), Color(0.65, 0.25, 0.25), 2.0)
			portrait_canvas.draw_rect(Rect2(cx + 22, cy - 32, 5, 5), Color(1.0, 0.85, 0.30))
		else:
			portrait_canvas.draw_rect(Rect2(cx - 12, cy - 10, 6, 6), Color(0.15, 0.10, 0.08))
			portrait_canvas.draw_rect(Rect2(cx + 6, cy - 10, 6, 6), Color(0.15, 0.10, 0.08))
			portrait_canvas.draw_line(Vector2(cx - 8, cy + 6), Vector2(cx + 8, cy + 6), Color(0.65, 0.25, 0.25), 2.0)

	# -------------------------------------------------------------------------
	# 2. MATEO HERNÁNDEZ (Primer Semestre)
	# -------------------------------------------------------------------------
	elif "mateo" in p:
		portrait_canvas.draw_rect(Rect2(cx - 28, size.y - 30, 56, 28), Color(0.35, 0.45, 0.60)) # Chaleco escolar
		portrait_canvas.draw_rect(Rect2(cx - 18, cy - 22, 36, 36), Color(0.92, 0.75, 0.60))
		portrait_canvas.draw_rect(Rect2(cx - 20, cy - 34, 40, 16), Color(0.20, 0.15, 0.12)) # Raya de lado
		portrait_canvas.draw_rect(Rect2(cx - 10, cy - 8, 5, 5), Color(0.12, 0.12, 0.15))
		portrait_canvas.draw_rect(Rect2(cx + 5, cy - 8, 5, 5), Color(0.12, 0.12, 0.15))
		if "sad" in p:
			portrait_canvas.draw_line(Vector2(cx - 6, cy + 8), Vector2(cx + 6, cy + 8), Color(0.5, 0.3, 0.3), 2.0)
			portrait_canvas.draw_rect(Rect2(cx - 12, cy - 1, 3, 5), Color(0.4, 0.8, 1.0)) # Lágrima
		elif "support" in p:
			portrait_canvas.draw_line(Vector2(cx - 6, cy + 5), Vector2(cx + 6, cy + 5), Color(0.65, 0.25, 0.25), 2.0)
			# Libreta pequeña al hombro
			portrait_canvas.draw_rect(Rect2(cx - 26, size.y - 20, 10, 12), Color(0.95, 0.90, 0.75))
		else:
			portrait_canvas.draw_line(Vector2(cx - 7, cy + 6), Vector2(cx + 7, cy + 6), Color(0.70, 0.25, 0.25), 2.0)
			portrait_canvas.draw_rect(Rect2(cx - 12, cy + 2, 4, 2), Color(0.95, 0.60, 0.65, 0.8)) # Rubor
			portrait_canvas.draw_rect(Rect2(cx + 8, cy + 2, 4, 2), Color(0.95, 0.60, 0.65, 0.8))

	# -------------------------------------------------------------------------
	# 3. VALERIA MORALES PEÑA (Tercer Semestre — Plaza Cívica)
	# -------------------------------------------------------------------------
	elif "valeria" in p:
		portrait_canvas.draw_rect(Rect2(cx - 30, size.y - 30, 60, 28), Color(0.20, 0.55, 0.35))
		portrait_canvas.draw_rect(Rect2(cx - 18, cy - 22, 36, 36), Color(0.95, 0.80, 0.65))
		# Cabello castaño oscuro con broche esmeralda
		portrait_canvas.draw_rect(Rect2(cx - 22, cy - 34, 44, 16), Color(0.18, 0.12, 0.10))
		portrait_canvas.draw_rect(Rect2(cx - 24, cy - 18, 6, 26), Color(0.18, 0.12, 0.10))
		portrait_canvas.draw_rect(Rect2(cx + 18, cy - 18, 6, 26), Color(0.18, 0.12, 0.10))
		portrait_canvas.draw_rect(Rect2(cx - 24, cy - 26, 6, 6), Color(0.15, 0.75, 0.40)) # Broche esmeralda
		portrait_canvas.draw_rect(Rect2(cx - 10, cy - 8, 5, 5), Color(0.10, 0.08, 0.08))
		portrait_canvas.draw_rect(Rect2(cx + 5, cy - 8, 5, 5), Color(0.10, 0.08, 0.08))
		if "sad" in p:
			portrait_canvas.draw_line(Vector2(cx - 6, cy + 8), Vector2(cx + 6, cy + 8), Color(0.5, 0.3, 0.3), 2.0)
		elif "brave" in p:
			portrait_canvas.draw_line(Vector2(cx - 8, cy + 5), Vector2(cx + 8, cy + 5), Color(0.70, 0.25, 0.25), 2.5)
		else:
			portrait_canvas.draw_line(Vector2(cx - 7, cy + 6), Vector2(cx + 7, cy + 6), Color(0.75, 0.25, 0.25), 2.0)
			portrait_canvas.draw_rect(Rect2(cx - 12, cy + 2, 4, 2), Color(0.95, 0.55, 0.60, 0.7))
			portrait_canvas.draw_rect(Rect2(cx + 8, cy + 2, 4, 2), Color(0.95, 0.55, 0.60, 0.7))

	# -------------------------------------------------------------------------
	# 4. EMILIANO "MILO" CRUZ (Quinto Semestre — Baloncesto y Fair Play)
	# -------------------------------------------------------------------------
	elif "emiliano" in p:
		portrait_canvas.draw_rect(Rect2(cx - 30, size.y - 30, 60, 28), Color(0.20, 0.50, 0.35))
		portrait_canvas.draw_rect(Rect2(cx - 20, cy - 24, 40, 38), Color(0.90, 0.72, 0.55))
		portrait_canvas.draw_rect(Rect2(cx - 22, cy - 36, 44, 16), Color(0.25, 0.18, 0.12))
		# Cinta deportiva roja
		portrait_canvas.draw_rect(Rect2(cx - 22, cy - 24, 44, 6), Color(0.90, 0.25, 0.25))
		portrait_canvas.draw_rect(Rect2(cx - 11, cy - 8, 5, 5), Color(0.15, 0.12, 0.10))
		portrait_canvas.draw_rect(Rect2(cx + 6, cy - 8, 5, 5), Color(0.15, 0.12, 0.10))
		if "sad" in p:
			portrait_canvas.draw_line(Vector2(cx - 8, cy + 8), Vector2(cx + 8, cy + 8), Color(0.5, 0.25, 0.25), 2.0)
		else:
			portrait_canvas.draw_line(Vector2(cx - 8, cy + 6), Vector2(cx + 8, cy + 6), Color(0.65, 0.25, 0.25), 2.0)
			# Balón de básquetbol icónico al hombro
			portrait_canvas.draw_circle(Vector2(cx + 26, size.y - 18), 10.0, Color(0.95, 0.45, 0.15))
			portrait_canvas.draw_line(Vector2(cx + 16, size.y - 18), Vector2(cx + 36, size.y - 18), Color(0.15, 0.10, 0.08), 1.5)

	# -------------------------------------------------------------------------
	# 5. SOFÍA VALDÉS (Quinto Semestre — Ciencias y Robótica)
	# -------------------------------------------------------------------------
	elif "sofia" in p:
		portrait_canvas.draw_rect(Rect2(cx - 28, size.y - 30, 56, 28), Color(0.30, 0.45, 0.55))
		portrait_canvas.draw_rect(Rect2(cx - 18, cy - 22, 36, 36), Color(0.95, 0.78, 0.62))
		portrait_canvas.draw_rect(Rect2(cx - 22, cy - 34, 44, 18), Color(0.35, 0.22, 0.15))
		portrait_canvas.draw_rect(Rect2(cx + 18, cy - 38, 12, 14), Color(0.35, 0.22, 0.15)) # Coleta
		# Gafas cuadradas características
		portrait_canvas.draw_rect(Rect2(cx - 14, cy - 12, 10, 8), Color(0.20, 0.65, 0.85), false, 2.0)
		portrait_canvas.draw_rect(Rect2(cx + 4, cy - 12, 10, 8), Color(0.20, 0.65, 0.85), false, 2.0)
		portrait_canvas.draw_line(Vector2(cx - 4, cy - 8), Vector2(cx + 4, cy - 8), Color(0.20, 0.65, 0.85), 2.0)
		if "sad" in p:
			portrait_canvas.draw_line(Vector2(cx - 6, cy + 8), Vector2(cx + 6, cy + 8), Color(0.5, 0.25, 0.25), 2.0)
		else:
			portrait_canvas.draw_line(Vector2(cx - 6, cy + 6), Vector2(cx + 6, cy + 6), Color(0.65, 0.25, 0.25), 2.0)
			# Reflejo tecnológico en las gafas
			portrait_canvas.draw_rect(Rect2(cx - 12, cy - 10, 3, 3), Color(0.85, 0.95, 1.0))
			portrait_canvas.draw_rect(Rect2(cx + 6, cy - 10, 3, 3), Color(0.85, 0.95, 1.0))

	# -------------------------------------------------------------------------
	# 6. ALIANZA ESTUDIANTIL UNIDA (Acto VI: Mateo & Valeria & Sofía)
	# -------------------------------------------------------------------------
	elif "allies" in p or "united" in p:
		# Fondo resplandeciente dorado de unión
		portrait_canvas.draw_circle(Vector2(cx, cy - 4), 36.0, Color(1.0, 0.88, 0.40, 0.25))
		# Silueta 1 (Izquierda: Mateo)
		portrait_canvas.draw_rect(Rect2(cx - 36, cy - 6, 22, 28), Color(0.35, 0.45, 0.60))
		portrait_canvas.draw_rect(Rect2(cx - 32, cy - 20, 16, 16), Color(0.92, 0.75, 0.60))
		portrait_canvas.draw_rect(Rect2(cx - 34, cy - 26, 18, 8), Color(0.20, 0.15, 0.12))
		portrait_canvas.draw_rect(Rect2(cx - 28, cy - 13, 3, 3), Color(0.1, 0.1, 0.1))
		# Silueta 2 (Centro: Valeria)
		portrait_canvas.draw_rect(Rect2(cx - 14, cy - 10, 28, 32), Color(0.20, 0.55, 0.35))
		portrait_canvas.draw_rect(Rect2(cx - 11, cy - 24, 22, 20), Color(0.95, 0.80, 0.65))
		portrait_canvas.draw_rect(Rect2(cx - 13, cy - 30, 26, 8), Color(0.18, 0.12, 0.10))
		portrait_canvas.draw_rect(Rect2(cx - 15, cy - 18, 4, 18), Color(0.95, 0.35, 0.55)) # Listón
		portrait_canvas.draw_rect(Rect2(cx + 11, cy - 18, 4, 18), Color(1.0, 0.85, 0.30))
		portrait_canvas.draw_rect(Rect2(cx - 6, cy - 16, 3, 3), Color(0.1, 0.1, 0.1))
		portrait_canvas.draw_rect(Rect2(cx + 3, cy - 16, 3, 3), Color(0.1, 0.1, 0.1))
		# Silueta 3 (Derecha: Sofía)
		portrait_canvas.draw_rect(Rect2(cx + 14, cy - 6, 22, 28), Color(0.30, 0.45, 0.55))
		portrait_canvas.draw_rect(Rect2(cx + 16, cy - 20, 16, 16), Color(0.95, 0.78, 0.62))
		portrait_canvas.draw_rect(Rect2(cx + 14, cy - 26, 18, 8), Color(0.35, 0.22, 0.15))
		portrait_canvas.draw_rect(Rect2(cx + 19, cy - 14, 5, 4), Color(0.20, 0.65, 0.85), false, 1.5) # Gafas

	# -------------------------------------------------------------------------
	# 7. JEFES ANTIVALORES (Siluetas temáticas personalizadas)
	# -------------------------------------------------------------------------
	elif "boss" in p or "apatyx" in p or "desperdicius" in p or "superbus" in p or "murmullus" in p or "plagiatrix" in p or "titanor" in p:
		var b_type := 5
		var col_boss := Color(0.52, 0.14, 0.32)
		var accent := Color(1.0, 0.35, 0.45)
		if "apatyx" in p:
			b_type = 0
			col_boss = Color(0.38, 0.34, 0.55)
			accent = Color(0.65, 0.60, 0.85)
		elif "desperdicius" in p:
			b_type = 1
			col_boss = Color(0.48, 0.44, 0.24)
			accent = Color(0.85, 0.75, 0.30)
		elif "superbus" in p:
			b_type = 2
			col_boss = Color(0.58, 0.16, 0.28)
			accent = Color(1.0, 0.85, 0.35)
		elif "murmullus" in p:
			b_type = 3
			col_boss = Color(0.18, 0.45, 0.65)
			accent = Color(0.30, 0.90, 1.0)
		elif "plagiatrix" in p:
			b_type = 4
			col_boss = Color(0.32, 0.36, 0.44)
			accent = Color(0.70, 0.75, 0.85)
		var boss_origin := Vector2(cx, size.y - 12.0) + _portrait_draw_offset
		BossRendererClass.draw_boss_silhouette(portrait_canvas, b_type, boss_origin, 0.0, col_boss, accent, false, false, 1.05)

	# -------------------------------------------------------------------------
	# 8. VOZ ANCESTRAL OTOMÍ DE TEMOAYA
	# -------------------------------------------------------------------------
	elif "spirit" in p or "otomi" in p:
		# Sol sagrado de Temoaya con ocho rayos radiantes
		portrait_canvas.draw_circle(Vector2(cx, cy), 32.0, Color(1.0, 0.85, 0.35, 0.25))
		portrait_canvas.draw_circle(Vector2(cx, cy), 22.0, Color(1.0, 0.85, 0.35))
		portrait_canvas.draw_circle(Vector2(cx, cy), 16.0, Color(0.85, 0.55, 0.15))
		for a in 8:
			var ang := a * TAU / 8.0
			var p1 := Vector2(cx, cy) + Vector2(cos(ang), sin(ang)) * 24.0
			var p2 := Vector2(cx, cy) + Vector2(cos(ang), sin(ang)) * 36.0
			portrait_canvas.draw_line(p1, p2, Color(1.0, 0.90, 0.45), 3.0)

	# -------------------------------------------------------------------------
	# 9. COORDINADOR INSTITUCIONAL COBAEM
	# -------------------------------------------------------------------------
	elif "coordinador" in p:
		portrait_canvas.draw_rect(Rect2(cx - 30, size.y - 32, 60, 30), Color(0.20, 0.15, 0.22))
		portrait_canvas.draw_polygon(PackedVector2Array([Vector2(cx - 10, size.y - 32), Vector2(cx + 10, size.y - 32), Vector2(cx, size.y - 18)]), [Color(1.0, 1.0, 1.0)])
		portrait_canvas.draw_rect(Rect2(cx - 3, size.y - 28, 6, 20), Color(0.55, 0.10, 0.18)) # Corbata guinda
		portrait_canvas.draw_rect(Rect2(cx - 20, cy - 24, 40, 38), Color(0.92, 0.75, 0.62))
		portrait_canvas.draw_rect(Rect2(cx - 22, cy - 36, 44, 16), Color(0.40, 0.40, 0.45)) # Pelo cano
		portrait_canvas.draw_rect(Rect2(cx - 12, cy - 10, 5, 5), Color(0.15, 0.15, 0.15))
		portrait_canvas.draw_rect(Rect2(cx + 7, cy - 10, 5, 5), Color(0.15, 0.15, 0.15))
		portrait_canvas.draw_line(Vector2(cx - 8, cy + 6), Vector2(cx + 8, cy + 6), Color(0.60, 0.30, 0.30), 2.0)

	# -------------------------------------------------------------------------
	# 10. NARRADOR / PERGAMINO ESCOLAR
	# -------------------------------------------------------------------------
	else:
		portrait_canvas.draw_rect(Rect2(cx - 24, cy - 28, 48, 56), Color(0.92, 0.88, 0.72))
		portrait_canvas.draw_rect(Rect2(cx - 24, cy - 28, 48, 56), Color(0.70, 0.58, 0.35), false, 2.0)
		for l in 5:
			portrait_canvas.draw_line(Vector2(cx - 16, cy - 18 + l * 8), Vector2(cx + 16, cy - 18 + l * 8), Color(0.45, 0.38, 0.28), 2.0)
