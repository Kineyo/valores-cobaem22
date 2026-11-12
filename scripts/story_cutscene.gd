extends Control
class_name StoryCutscene

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
		center_box.size.x = vp_size.x - insets.position.x - insets.size.x

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
		scenario_label.text = "📍 " + loc

	_show_node(0)

func _show_node(idx: int) -> void:
	if idx < 0 or idx >= _dialogue_nodes.size():
		_finish()
		return

	_current_index = idx
	var node_data: Dictionary = _dialogue_nodes[_current_index]

	var speaker: String = node_data.get("speaker", "Voz Escolar")
	_full_text = node_data.get("text", "")
	_current_portrait_id = node_data.get("portrait", "narrator")

	if speaker_name_label:
		speaker_name_label.text = speaker
		# Color temático según el orador
		if "Guardián" in speaker:
			speaker_name_label.modulate = Color(1.0, 0.90, 0.40)
		elif "Narrador" in speaker:
			speaker_name_label.modulate = Color(0.85, 0.85, 0.95)
		elif "Voz Ancestral" in speaker or "Otomí" in speaker:
			speaker_name_label.modulate = Color(1.0, 0.75, 0.35)
		elif "Director" in speaker:
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

func _update_button_prompts() -> void:
	var is_mobile := MobileControls.is_touch_device()
	var is_last := _current_index >= _dialogue_nodes.size() - 1

	if is_mobile:
		if btn_next:
			btn_next.text = "Finalizar ▶" if is_last else "Continuar ▶"
		if btn_skip:
			btn_skip.text = "Saltar ⏭"
	elif _last_input_was_gamepad:
		if btn_next:
			btn_next.text = "Finalizar (A) ▶" if is_last else "Continuar (A) ▶"
		if btn_skip:
			btn_skip.text = "Saltar (B) ⏭"
	else:
		if btn_next:
			btn_next.text = "Finalizar ▶ (Espacio)" if is_last else "Continuar ▶ (Espacio)"
		if btn_skip:
			btn_skip.text = "Saltar ⏭ (Esc)"

func _process(delta: float) -> void:
	if _is_typing and dialogue_label:
		_visible_chars += _chars_per_second * delta
		var char_count: int = int(_visible_chars)
		if char_count != dialogue_label.visible_characters:
			dialogue_label.visible_characters = char_count
			if char_count % 3 == 0 and sfx_blip and char_count < _full_text.length():
				sfx_blip.pitch_scale = randf_range(1.2, 1.4)
				sfx_blip.play()
			# Asegurar que el scroll vertical acompañe al texto mecanografiado
			var v_scroll := dialogue_label.get_v_scroll_bar()
			if v_scroll:
				v_scroll.value = v_scroll.max_value

		if char_count >= _full_text.length():
			dialogue_label.visible_characters = -1
			_is_typing = false

func _gui_input(event: InputEvent) -> void:
	# Clic o toque en el fondo para avanzar
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_last_input_was_gamepad = false
		_advance_dialogue()
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
			_skip_cutscene()
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
			_skip_cutscene()
			_mark_input_handled()
			return

	# 3. Mapeos de acción comunes
	if event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		_advance_dialogue()
		_mark_input_handled()
		return
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_skip_cutscene()
		_mark_input_handled()
		return

	# 4. Toque / Ratón genérico no capturado por botones
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_last_input_was_gamepad = false
		_advance_dialogue()
		_mark_input_handled()
		return

func _advance_dialogue() -> void:
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

func _skip_cutscene() -> void:
	_finish()

func _finish() -> void:
	set_process(false)
	if _game_settings and _game_settings.has_method("duck_music"):
		_game_settings.duck_music(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.22)
	await tw.finished
	cutscene_finished.emit()
	queue_free()

func _get_portrait_texture(p: String) -> Texture2D:
	var path := ""
	if "guardian" in p or "player" in p or "heroe" in p or "protagonista" in p:
		var is_fem: bool = false
		if _game_settings and _game_settings.get("selected_character") == 1:
			is_fem = true
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

	if path != "":
		if ResourceLoader.exists(path):
			return load(path)
		elif FileAccess.file_exists(path):
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))
			if img:
				return ImageTexture.create_from_image(img)
	return null

## Renderizado pixel-art de los retratos de personajes y antivalores
func _on_portrait_draw() -> void:
	if portrait_canvas == null:
		return
	var size: Vector2 = portrait_canvas.size
	var cx: float = size.x * 0.5
	var cy: float = size.y * 0.5

	# Marco base oscuro con borde guinda y oro
	portrait_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.06, 0.09, 0.95))
	portrait_canvas.draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0.77, 0.63, 0.35), false, 2.0)

	var p := _current_portrait_id.to_lower()

	# 0. Si existe un archivo PNG de retrato pixel art en assets/portraits/, dibujarlo directamente
	var portrait_png := _get_portrait_texture(p)
	if portrait_png == null:
		# Respaldo por defecto a retrato de alta resolución del guardián
		var fallback_path: String = "res://assets/portraits/guardian.png"
		if ResourceLoader.exists(fallback_path):
			portrait_png = load(fallback_path)
		elif FileAccess.file_exists(fallback_path):
			var img := Image.load_from_file(ProjectSettings.globalize_path(fallback_path))
			if img:
				portrait_png = ImageTexture.create_from_image(img)

	if portrait_png:
		portrait_canvas.draw_texture_rect(portrait_png, Rect2(4, 4, size.x - 8, size.y - 8), false)
		return

	# -------------------------------------------------------------------------
	# 1. HÉROE COBAEM (Guardián de los Valores)
	# -------------------------------------------------------------------------
	if "player" in p or "guardian" in p:
		# Hombros y suéter guinda institucional
		portrait_canvas.draw_rect(Rect2(cx - 30, size.y - 32, 60, 30), Color(0.48, 0.12, 0.20))
		# Cuello camisa blanca y corbata oro
		portrait_canvas.draw_polygon(PackedVector2Array([Vector2(cx - 10, size.y - 32), Vector2(cx + 10, size.y - 32), Vector2(cx, size.y - 18)]), [Color(0.95, 0.95, 0.95)])
		portrait_canvas.draw_rect(Rect2(cx - 3, size.y - 28, 6, 18), Color(0.90, 0.75, 0.25))
		# Rostro
		portrait_canvas.draw_rect(Rect2(cx - 20, cy - 24, 40, 38), Color(0.95, 0.78, 0.62))
		# Cabello castaño
		portrait_canvas.draw_rect(Rect2(cx - 24, cy - 36, 48, 18), Color(0.28, 0.16, 0.10))
		portrait_canvas.draw_rect(Rect2(cx - 24, cy - 24, 8, 20), Color(0.28, 0.16, 0.10))
		portrait_canvas.draw_rect(Rect2(cx + 16, cy - 24, 8, 20), Color(0.28, 0.16, 0.10))
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
		var col_boss := Color(0.45, 0.20, 0.35)
		var accent := Color(1.0, 0.4, 0.4)

		if "apatyx" in p:
			# Apatyx: Espectro encapuchado de la desidia con jirones de niebla
			col_boss = Color(0.38, 0.34, 0.55)
			accent = Color(0.65, 0.60, 0.85)
			portrait_canvas.draw_rect(Rect2(cx - 30, size.y - 34, 60, 34), col_boss.darkened(0.3))
			portrait_canvas.draw_circle(Vector2(cx, cy - 6), 24.0, col_boss)
			# Capucha caída
			portrait_canvas.draw_polygon(PackedVector2Array([Vector2(cx - 24, cy - 10), Vector2(cx, cy - 32), Vector2(cx + 24, cy - 10)]), [col_boss.darkened(0.2)])
			# Ojos pesados y somnolientos
			portrait_canvas.draw_line(Vector2(cx - 12, cy - 4), Vector2(cx - 4, cy - 2), accent, 2.5)
			portrait_canvas.draw_line(Vector2(cx + 4, cy - 2), Vector2(cx + 12, cy - 4), accent, 2.5)

		elif "desperdicius" in p:
			# Desperdicius: Titán del desperdicio con envoltorios plásticos y corona de basura
			col_boss = Color(0.48, 0.44, 0.24)
			accent = Color(0.85, 0.75, 0.30)
			portrait_canvas.draw_rect(Rect2(cx - 34, size.y - 34, 68, 34), col_boss.darkened(0.3))
			portrait_canvas.draw_circle(Vector2(cx, cy - 4), 26.0, col_boss)
			# Corona de basura dentada
			portrait_canvas.draw_polygon(PackedVector2Array([Vector2(cx - 20, cy - 24), Vector2(cx - 12, cy - 36), Vector2(cx, cy - 24), Vector2(cx + 12, cy - 36), Vector2(cx + 20, cy - 24)]), [accent])
			# Ojos glotones
			portrait_canvas.draw_rect(Rect2(cx - 14, cy - 8, 8, 6), Color(0.95, 0.30, 0.25))
			portrait_canvas.draw_rect(Rect2(cx + 6, cy - 8, 8, 6), Color(0.95, 0.30, 0.25))

		elif "superbus" in p:
			# Superbus: Heraldo de la arrogancia con manto púrpura y corona orgullosa
			col_boss = Color(0.58, 0.16, 0.28)
			accent = Color(1.0, 0.85, 0.35)
			portrait_canvas.draw_rect(Rect2(cx - 30, size.y - 34, 60, 34), col_boss.darkened(0.25))
			portrait_canvas.draw_circle(Vector2(cx, cy - 6), 24.0, col_boss)
			# Diadema dorada de soberbia
			portrait_canvas.draw_line(Vector2(cx - 18, cy - 24), Vector2(cx + 18, cy - 24), accent, 3.0)
			portrait_canvas.draw_rect(Rect2(cx - 3, cy - 32, 6, 8), accent)
			# Mirada altanera y desdeñosa
			portrait_canvas.draw_line(Vector2(cx - 14, cy - 8), Vector2(cx - 4, cy - 11), Color(1.0, 0.30, 0.35), 2.5)
			portrait_canvas.draw_line(Vector2(cx + 4, cy - 11), Vector2(cx + 14, cy - 8), Color(1.0, 0.30, 0.35), 2.5)

		elif "murmullus" in p:
			# Ciber-Murmullus: Espectro de cables, difamación digital y glitch
			col_boss = Color(0.18, 0.45, 0.65)
			accent = Color(0.30, 0.90, 1.0)
			portrait_canvas.draw_rect(Rect2(cx - 30, size.y - 34, 60, 34), col_boss.darkened(0.3))
			portrait_canvas.draw_rect(Rect2(cx - 24, cy - 28, 48, 44), col_boss)
			# Antena cibernética
			portrait_canvas.draw_line(Vector2(cx, cy - 28), Vector2(cx, cy - 38), accent, 2.0)
			portrait_canvas.draw_rect(Rect2(cx - 3, cy - 42, 6, 6), Color(1.0, 0.3, 0.4))
			# Líneas de scanline / glitch horizontal
			portrait_canvas.draw_line(Vector2(cx - 20, cy - 14), Vector2(cx + 20, cy - 14), accent, 1.5)
			portrait_canvas.draw_line(Vector2(cx - 16, cy + 4), Vector2(cx + 16, cy + 4), accent, 1.5)
			portrait_canvas.draw_rect(Rect2(cx - 14, cy - 8, 8, 4), accent)
			portrait_canvas.draw_rect(Rect2(cx + 6, cy - 8, 8, 4), accent)

		elif "plagiatrix" in p:
			# Plagiatrix: Autómata de la copia y falsificación con rostro dividido
			col_boss = Color(0.32, 0.36, 0.44)
			accent = Color(0.70, 0.75, 0.85)
			portrait_canvas.draw_rect(Rect2(cx - 30, size.y - 34, 60, 34), col_boss.darkened(0.3))
			portrait_canvas.draw_rect(Rect2(cx - 24, cy - 28, 24, 46), col_boss)
			portrait_canvas.draw_rect(Rect2(cx, cy - 28, 24, 46), col_boss.lightened(0.2)) # Rostro dividido
			portrait_canvas.draw_line(Vector2(cx, cy - 30), Vector2(cx, cy + 18), Color(0.1, 0.1, 0.15), 2.0)
			# Código de barras / sellos falsificados
			for b in 4:
				portrait_canvas.draw_line(Vector2(cx - 16 + b * 4, cy + 6), Vector2(cx - 16 + b * 4, cy + 14), accent, 1.5)
			portrait_canvas.draw_rect(Rect2(cx - 14, cy - 8, 8, 4), Color(1.0, 0.35, 0.35))
			portrait_canvas.draw_rect(Rect2(cx + 6, cy - 8, 8, 4), Color(0.35, 0.95, 0.85))

		else:
			# Titanor: Coloso de fuerza bruta con cuernos metálicos y cadenas
			col_boss = Color(0.52, 0.14, 0.32)
			accent = Color(1.0, 0.35, 0.45)
			portrait_canvas.draw_rect(Rect2(cx - 34, size.y - 36, 68, 36), col_boss.darkened(0.3))
			portrait_canvas.draw_circle(Vector2(cx, cy - 4), 28.0, col_boss)
			# Cuernos amenazantes
			portrait_canvas.draw_polygon(PackedVector2Array([Vector2(cx - 24, cy - 14), Vector2(cx - 36, cy - 38), Vector2(cx - 16, cy - 26)]), [col_boss.darkened(0.4)])
			portrait_canvas.draw_polygon(PackedVector2Array([Vector2(cx + 24, cy - 14), Vector2(cx + 36, cy - 38), Vector2(cx + 16, cy - 26)]), [col_boss.darkened(0.4)])
			# Ojos llameantes
			portrait_canvas.draw_rect(Rect2(cx - 14, cy - 8, 9, 5), accent)
			portrait_canvas.draw_rect(Rect2(cx + 5, cy - 8, 9, 5), accent)
			portrait_canvas.draw_line(Vector2(cx - 10, cy + 10), Vector2(cx + 10, cy + 10), Color(0.1, 0.05, 0.08), 3.0)

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
	# 9. DIRECTOR INSTITUCIONAL COBAEM
	# -------------------------------------------------------------------------
	elif "director" in p:
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
