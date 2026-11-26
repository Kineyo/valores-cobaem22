extends CanvasLayer
class_name UndertaleClimax

const BossRendererClass := preload("res://scripts/boss_renderer.gd")

## Escena Clímax estilo Undertale cuando Titanor alcanza 1 HP.
## Todo se detiene y Titanor se resquebraja mientras héroe y aliados se transforman en 8 corazones de valores.
## Reproduce música original inspirada en Finale antes de dar paso a la Ceremonia Final.

signal climax_finished

const BOSS_DIALOG := "Esta vez lograron detenerme, pero siempre habrá un momento donde falte diálogo, alguien ignore al grupo o el miedo calle al salón. Y ahí intentaré volver con más fuerza."
const STUDENTS_DIALOG := "Cuando eso pase, nosotros estaremos aquí para detenerte de nuevo, no permitiremos que el maltrato regrese a nuestra institución."

const VALUE_HEARTS := [
	{ "who": "Tú (Héroe)", "value": "Valentía", "color": Color(1.0, 0.17, 0.29) },
	{ "who": "Mateo", "value": "Curiosidad", "color": Color(0.22, 0.91, 1.0) },
	{ "who": "María", "value": "Empatía", "color": Color(1.0, 0.61, 0.22) },
	{ "who": "Valeria", "value": "Civismo", "color": Color(0.32, 0.95, 0.45) },
	{ "who": "Fernanda", "value": "Sabiduría", "color": Color(0.71, 0.49, 1.0) },
	{ "who": "Diego", "value": "Ciudadanía Digital", "color": Color(0.23, 0.51, 1.0) },
	{ "who": "Sofía", "value": "Respeto", "color": Color(1.0, 0.88, 0.26) },
	{ "who": "Alejandro", "value": "Juego Limpio", "color": Color(1.0, 0.42, 0.55) },
]

enum Phase { TRANSFORM, DIALOG_BOSS, DIALOG_STUDENTS, CONVERGENCE, DONE }

var current_phase: Phase = Phase.TRANSFORM
var _time: float = 0.0
var _phase_time: float = 0.0
var _char_reveal: float = 0.0
var _full_text: String = ""
var _speaker_text: String = ""
var _pointer_ready_ms: int = 0
var _emitted_done: bool = false

var _root_ctrl: Control
var _arena_draw: Control
var _dialog_panel: PanelContainer
var _speaker_lbl: Label
var _text_lbl: RichTextLabel
var _hint_lbl: Label

func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pointer_ready_ms = Time.get_ticks_msec() + 180
	_build_ui()
	_play_climax_music()
	_enter_phase(Phase.TRANSFORM)

	var vp := get_viewport()
	if vp and not vp.size_changed.is_connected(_update_layout):
		vp.size_changed.connect(_update_layout)
	_update_layout()

func _exit_tree() -> void:
	var vp := get_viewport()
	if vp and vp.size_changed.is_connected(_update_layout):
		vp.size_changed.disconnect(_update_layout)

func _play_climax_music() -> void:
	var gs := get_node_or_null("/root/GameSettings") if is_inside_tree() else null
	if gs and gs.has_method("play_finale_climax_music"):
		gs.play_finale_climax_music()

func _is_female_hero() -> bool:
	var gs := get_node_or_null("/root/GameSettings") if is_inside_tree() else null
	if gs and "selected_character" in gs:
		return int(gs.selected_character) == 1
	var ml := Engine.get_main_loop()
	if ml is SceneTree and (ml as SceneTree).root:
		var root_gs := (ml as SceneTree).root.get_node_or_null("GameSettings")
		if root_gs and "selected_character" in root_gs:
			return int(root_gs.selected_character) == 1
	return false

func get_hearts_data() -> Array:
	var arr := VALUE_HEARTS.duplicate(true)
	if not arr.is_empty() and arr[0] is Dictionary:
		arr[0]["who"] = "Tú (Heroína)" if _is_female_hero() else "Tú (Héroe)"
	return arr

func get_boss_dialogue() -> String:
	return BOSS_DIALOG

func get_students_dialogue() -> String:
	return STUDENTS_DIALOG

func force_finish_for_test() -> void:
	_finish_sequence()

func _build_ui() -> void:
	_root_ctrl = Control.new()
	_root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root_ctrl)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_ctrl.add_child(bg)

	_arena_draw = Control.new()
	_arena_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_arena_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena_draw.draw.connect(_on_arena_draw)
	_root_ctrl.add_child(_arena_draw)

	_dialog_panel = PanelContainer.new()
	_dialog_panel.name = "UndertaleDialogBox"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.96)
	sb.border_color = Color(1.0, 1.0, 1.0, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(0)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_dialog_panel.add_theme_stylebox_override("panel", sb)
	_root_ctrl.add_child(_dialog_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_dialog_panel.add_child(vbox)

	_speaker_lbl = Label.new()
	_speaker_lbl.add_theme_font_size_override("font_size", 13)
	_speaker_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	vbox.add_child(_speaker_lbl)

	_text_lbl = RichTextLabel.new()
	_text_lbl.bbcode_enabled = false
	_text_lbl.fit_content = false
	_text_lbl.scroll_active = false
	_text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_lbl.add_theme_font_size_override("normal_font_size", 15)
	_text_lbl.add_theme_color_override("default_color", Color.WHITE)
	vbox.add_child(_text_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_lbl.add_theme_font_size_override("font_size", 11)
	_hint_lbl.add_theme_color_override("font_color", Color(0.78, 0.80, 0.85))
	_hint_lbl.text = "* Espacio / Enter / Tocar para continuar"
	vbox.add_child(_hint_lbl)

func _update_layout() -> void:
	if _dialog_panel == null or not is_inside_tree() or get_viewport() == null:
		return
	var vp := get_viewport()
	var vp_sz := vp.get_visible_rect().size
	var insets := MobileControls.get_safe_insets_for_viewport(vp, 10.0)
	var box_w := clampf(vp_sz.x - insets.position.x - insets.size.x - 40.0, 320.0, 720.0)
	var box_h := clampf(vp_sz.y * 0.30, 118.0, 152.0)
	_dialog_panel.position = Vector2((vp_sz.x - box_w) * 0.5, vp_sz.y - insets.size.y - box_h - 8.0)
	_dialog_panel.size = Vector2(box_w, box_h)
	if _hint_lbl:
		if MobileControls.is_touch_device():
			_hint_lbl.text = "* Toca la pantalla para continuar"
		elif not Input.get_connected_joypads().is_empty():
			_hint_lbl.text = "* Botón A / Start para continuar"
		else:
			_hint_lbl.text = "* Espacio / Enter / Clic para continuar"

func _enter_phase(p: Phase) -> void:
	current_phase = p
	_phase_time = 0.0
	match p:
		Phase.TRANSFORM:
			_speaker_text = "* TITANOR — 1 HP (CORAZONES EN RESONANCIA)"
			var role_lbl := "Guardiana" if _is_female_hero() else "Guardián"
			_full_text = "* El Coloso del Bullying cede su postura. Tu valor de %s y el de tus compañeros se convierten en luz." % role_lbl
			_char_reveal = float(_full_text.length())
		Phase.DIALOG_BOSS:
			_speaker_text = "* TITANOR (Blanco y Negro)"
			_full_text = BOSS_DIALOG
			_char_reveal = 0.0
		Phase.DIALOG_STUDENTS:
			_speaker_text = "* LOS ALUMNOS DEL CEMSaD 22 (8 Corazones de los Valores)"
			_full_text = STUDENTS_DIALOG
			_char_reveal = 0.0
		Phase.CONVERGENCE:
			_speaker_text = "* UNIDAD ESCOLAR · FRATERNIDAD Y ESPERANZA"
			_full_text = "* Todos los corazones brillan unidos. La sombra de Titanor se disipa en armonía."
			_char_reveal = float(_full_text.length())
		Phase.DONE:
			_finish_sequence()
			return
	if _speaker_lbl:
		_speaker_lbl.text = _speaker_text
	if _text_lbl:
		_text_lbl.text = _full_text
		_text_lbl.visible_characters = int(_char_reveal)

func _process(delta: float) -> void:
	_time += delta
	_phase_time += delta

	match current_phase:
		Phase.TRANSFORM:
			if _phase_time >= 2.0:
				_enter_phase(Phase.DIALOG_BOSS)
		Phase.DIALOG_BOSS, Phase.DIALOG_STUDENTS:
			if int(_char_reveal) < _full_text.length():
				_char_reveal = minf(float(_full_text.length()), _char_reveal + 38.0 * delta)
				if _text_lbl:
					_text_lbl.visible_characters = int(_char_reveal)
		Phase.CONVERGENCE:
			if _phase_time >= 2.1:
				_enter_phase(Phase.DONE)

	if _arena_draw:
		_arena_draw.queue_redraw()

func _advance() -> void:
	var now := Time.get_ticks_msec()
	if now < _pointer_ready_ms:
		return
	_pointer_ready_ms = now + 130

	match current_phase:
		Phase.TRANSFORM:
			_enter_phase(Phase.DIALOG_BOSS)
		Phase.DIALOG_BOSS:
			if int(_char_reveal) < _full_text.length():
				_char_reveal = float(_full_text.length())
				if _text_lbl:
					_text_lbl.visible_characters = -1
			else:
				_enter_phase(Phase.DIALOG_STUDENTS)
		Phase.DIALOG_STUDENTS:
			if int(_char_reveal) < _full_text.length():
				_char_reveal = float(_full_text.length())
				if _text_lbl:
					_text_lbl.visible_characters = -1
			else:
				_enter_phase(Phase.CONVERGENCE)
		Phase.CONVERGENCE:
			if _phase_time > 0.6:
				_enter_phase(Phase.DONE)

func _unhandled_input(event: InputEvent) -> void:
	if current_phase == Phase.DONE:
		return
	var triggered := false
	if event is InputEventKey and event.pressed and not event.is_echo():
		var kc: int = event.keycode
		if kc in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_Z]:
			triggered = true
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and st.device != InputEvent.DEVICE_ID_EMULATION:
			triggered = true
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.device != InputEvent.DEVICE_ID_EMULATION:
			triggered = true
	elif event is InputEventJoypadButton and event.pressed and not event.is_echo():
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START, JOY_BUTTON_X]:
			triggered = true

	if triggered:
		_advance()
		if get_viewport():
			get_viewport().set_input_as_handled()

func _finish_sequence() -> void:
	if _emitted_done:
		return
	_emitted_done = true
	current_phase = Phase.DONE
	climax_finished.emit()
	queue_free()

func _on_arena_draw() -> void:
	if _arena_draw == null:
		return
	var sz := _arena_draw.size
	var cx := sz.x * 0.5
	var boss_pos := Vector2(cx, sz.y * 0.25)

	# 1. Estrellas sutiles de resonancia en el fondo negro Undertale
	for i in range(18):
		var sx := fposmod(float(i * 137 + 41) + _time * (8.0 + float(i % 4) * 3.0), maxf(1.0, sz.x))
		var sy := fposmod(float(i * 89 + 23), maxf(1.0, sz.y * 0.66))
		var sa := 0.20 + 0.25 * sin(_time * 3.0 + float(i))
		_arena_draw.draw_rect(Rect2(sx, sy, 2, 2), Color(1, 1, 1, sa))

	# 2. Dibujar a Titanor en Blanco y Negro resquebrajándose
	var boss_alpha := 1.0
	var boss_jitter := Vector2.ZERO
	if current_phase == Phase.DIALOG_BOSS:
		boss_jitter = Vector2(sin(_time * 42.0) * 1.6, cos(_time * 36.0) * 1.0)
	elif current_phase == Phase.CONVERGENCE:
		var c_prog := clampf(_phase_time / 2.1, 0.0, 1.0)
		boss_alpha = clampf(1.0 - maxf(0.0, (c_prog - 0.35) / 0.65), 0.0, 1.0)
		boss_jitter = Vector2(sin(_time * 60.0) * (2.0 + c_prog * 5.0), 0.0)
	_draw_monochrome_titanor(boss_pos + boss_jitter, boss_alpha)

	# 3. Dibujar los 8 corazones de colores (Héroe + 7 Aliados) en arco heroico
	var font := ThemeDB.fallback_font
	var n_hearts := VALUE_HEARTS.size()
	var arc_rx := minf(270.0, sz.x * 0.38)
	var dialog_top_y: float = _dialog_panel.position.y if _dialog_panel != null else sz.y * 0.66
	var arc_center_y := minf(sz.y * 0.48, dialog_top_y - 78.0)
	var transform_flash := clampf(1.0 - _phase_time / 1.1, 0.0, 1.0) if current_phase == Phase.TRANSFORM else 0.0

	for i in range(n_hearts):
		var h_info: Dictionary = VALUE_HEARTS[i]
		var t_ang: float = lerpf(-PI * 0.88, -PI * 0.12, float(i) / float(maxi(1, n_hearts - 1)))
		var bob := sin(_time * 3.8 + float(i) * 0.75) * 4.5
		var rise := -14.0 * clampf(_phase_time / 0.5, 0.0, 1.0) if current_phase in [Phase.DIALOG_STUDENTS, Phase.CONVERGENCE] else 0.0
		var h_pos := Vector2(cx + cos(t_ang) * arc_rx, arc_center_y - sin(t_ang) * 42.0 + bob + rise)
		var col: Color = h_info["color"]

		# Rayo convergente hacia Titanor en la fase final
		if current_phase == Phase.CONVERGENCE:
			var beam_w := 3.5 + 3.0 * sin(_time * 18.0 + float(i))
			_arena_draw.draw_line(h_pos, boss_pos + Vector2(0, -18), Color(col.r, col.g, col.b, 0.85), beam_w)
			_arena_draw.draw_line(h_pos, boss_pos + Vector2(0, -18), Color(1, 1, 1, 0.7), 1.2)

		var heart_scale := 1.0 + 0.10 * sin(_time * 5.0 + float(i))
		_draw_pixel_heart(h_pos, col, heart_scale)
		if transform_flash > 0.02:
			_arena_draw.draw_circle(h_pos, 18.0 * (1.2 - transform_flash * 0.4), Color(1, 1, 1, transform_flash * 0.75))

		if font:
			var val_txt := str(h_info["value"])
			_arena_draw.draw_string(font, h_pos + Vector2(-46, 22), val_txt, HORIZONTAL_ALIGNMENT_CENTER, 92, 10, col.lightened(0.25))

	# Destello blanco final al completarse la convergencia
	if current_phase == Phase.CONVERGENCE and _phase_time > 1.3:
		var white_a := clampf((_phase_time - 1.3) / 0.75, 0.0, 0.95)
		_arena_draw.draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 1, 1, white_a))

func _draw_monochrome_titanor(pos: Vector2, alpha: float) -> void:
	if alpha <= 0.01:
		return
	var w_col := Color(0.92, 0.92, 0.92, alpha)
	var g_col := Color(0.32, 0.32, 0.32, alpha)
	var b_col := Color(0.05, 0.05, 0.05, alpha)

	# Silueta oficial de Titanor renderizada en escala de grises estilo Undertale
	BossRendererClass.draw_boss_silhouette(_arena_draw, 5, pos + Vector2(0, 40), _time, g_col, w_col, false, false, 1.0)
	# Grietas negras/blancas de fractura visible
	var crack := Color(1, 1, 1, alpha)
	_arena_draw.draw_line(pos + Vector2(-4, -46), pos + Vector2(6, -24), b_col, 4.0)
	_arena_draw.draw_line(pos + Vector2(-4, -46), pos + Vector2(6, -24), crack, 2.0)
	_arena_draw.draw_line(pos + Vector2(6, -24), pos + Vector2(-8, 6), b_col, 4.0)
	_arena_draw.draw_line(pos + Vector2(6, -24), pos + Vector2(-8, 6), crack, 2.0)
	_arena_draw.draw_line(pos + Vector2(-24, -10), pos + Vector2(20, 22), b_col, 3.5)
	_arena_draw.draw_line(pos + Vector2(-24, -10), pos + Vector2(20, 22), crack, 1.6)

func _draw_pixel_heart(center: Vector2, col: Color, sc: float = 1.0) -> void:
	var px := 2.4 * sc
	# Mapa pixel-art simétrico de corazón estilo SOUL (9x8)
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
	var ox := center.x - 4.5 * px
	var oy := center.y - 4.0 * px
	_arena_draw.draw_circle(center, 13.0 * sc, Color(col.r, col.g, col.b, 0.22))
	for r in range(rows.size()):
		var row_str: String = rows[r]
		for c in range(row_str.length()):
			if row_str[c] == "1":
				_arena_draw.draw_rect(Rect2(ox + float(c) * px, oy + float(r) * px, px + 0.4, px + 0.4), col)
	# Brillo especular blanco superior izquierdo
	_arena_draw.draw_rect(Rect2(ox + 1.5 * px, oy + 1.2 * px, px * 1.1, px * 1.1), Color(1, 1, 1, 0.85))
