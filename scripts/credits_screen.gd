extends Control
class_name CreditsScreen

## Pantalla de Créditos en formato cinematográfico 3:4 basada en README.md.
## Reproduce `res://assets/video/creditos_readme_3x4.ogv` si está disponible, o bien ejecuta
## el roll en vivo de `README.md` (también usado para grabar dicho video 3:4).

signal closed
signal roll_finished

const VIDEO_OGV_PATH := "res://assets/video/creditos_readme_3x4.ogv"
const README_PATH := "res://README.md"
const RATIO_3_4 := 0.75

@export var use_video_file: bool = true
@export var auto_scroll_duration: float = 34.0

var _root_vbox: VBoxContainer
var _aspect_box: AspectRatioContainer
var _frame_panel: PanelContainer
var _stage_ctrl: Control
var _video_player: VideoStreamPlayer
var _roll_container: VBoxContainer
var _btn_play_pause: Button
var _btn_restart: Button
var _btn_fullscreen: Button
var _btn_exit_fullscreen: Button
var _btn_close: Button

var _is_live_rolling: bool = false
var _roll_elapsed: float = 0.0
var _roll_start_y: float = 0.0
var _roll_end_y: float = 0.0
var _roll_duration: float = 34.0
var _roll_done: bool = false
var _is_paused_video: bool = false
var _is_fullscreen_mode: bool = false
var _prev_window_mode: int = -1
var _closing: bool = false
var _parsed_entries: Array[Dictionary] = []
var _last_comb_h: float = 0.0

func _ready() -> void:
	name = "CreditsScreen"
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 125
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_parsed_entries = parse_readme_for_credits(load_readme_text())
	_build_ui()

	var vp := get_viewport()
	if vp and not vp.size_changed.is_connected(_update_safe_layout):
		vp.size_changed.connect(_update_safe_layout)
	_update_safe_layout()

	if use_video_file and _try_start_video():
		pass
	else:
		start_live_roll_for_recording(auto_scroll_duration)

func _exit_tree() -> void:
	_restore_window_mode()
	var vp := get_viewport()
	if vp and vp.size_changed.is_connected(_update_safe_layout):
		vp.size_changed.disconnect(_update_safe_layout)

static func load_readme_text() -> String:
	if FileAccess.file_exists(README_PATH):
		return FileAccess.get_file_as_string(README_PATH)
	return "# Campeones de los Valores\n## CEMSaD 22 ENTHAVI\nVideojuego educativo COBAEM."

static func _clean_md_inline(raw: String) -> String:
	var s := raw.strip_edges()
	# Convertir [texto](url) -> texto
	while true:
		var lb := s.find("[")
		if lb < 0:
			break
		var rb := s.find("]", lb)
		if rb < 0 or rb + 1 >= s.length() or s[rb + 1] != "(":
			break
		var rp := s.find(")", rb + 2)
		if rp < 0:
			break
		var label := s.substr(lb + 1, rb - lb - 1)
		s = s.substr(0, lb) + label + s.substr(rp + 1)
	s = s.replace("<kbd>", "[").replace("</kbd>", "]")
	s = s.replace("**", "").replace("__", "").replace("`", "").replace("*", "")
	s = s.replace("> [!TIP]", "CONSEJO:").replace("> [!NOTE]", "NOTA:").replace("> [!IMPORTANT]", "IMPORTANTE:")
	return s.strip_edges()

static func parse_readme_for_credits(raw_md: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var lines := raw_md.split("\n")
	var in_code_block := false
	for raw_line in lines:
		var line := str(raw_line).strip_edges()
		if line.begins_with("```"):
			in_code_block = not in_code_block
			continue
		if in_code_block or line.is_empty():
			continue
		if line.begins_with("<") or line.begins_with("[![") or line.begins_with("https://"):
			continue
		if line == "---" or line.begins_with("| :---") or line.begins_with("|:---"):
			continue

		if line.begins_with("# "):
			entries.append({ "kind": "title", "text": _clean_md_inline(line.substr(2)) })
		elif line.begins_with("## "):
			entries.append({ "kind": "section", "text": _clean_md_inline(line.substr(3)) })
		elif line.begins_with("### ") or line.begins_with("#### "):
			var txt := line.substr(4) if line.begins_with("### ") else line.substr(5)
			entries.append({ "kind": "sub", "text": _clean_md_inline(txt) })
		elif line.begins_with("|"):
			var cells := line.split("|", false)
			var clean_cells: Array[String] = []
			for c in cells:
				var ct := _clean_md_inline(c)
				if not ct.is_empty() and not ct.begins_with(":---") and not ct.begins_with("---"):
					clean_cells.append(ct)
			if not clean_cells.is_empty():
				entries.append({ "kind": "body", "text": " · ".join(clean_cells) })
		else:
			var clean := _clean_md_inline(line)
			if clean.begins_with("- ") or clean.begins_with("• "):
				clean = "• " + clean.substr(2).strip_edges()
			if not clean.is_empty() and clean != "---":
				entries.append({ "kind": "body", "text": clean })
	return entries

func get_parsed_entries() -> Array[Dictionary]:
	return _parsed_entries

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.05, 0.96)
	add_child(bg)

	_root_vbox = VBoxContainer.new()
	_root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_vbox.add_theme_constant_override("separation", 6)
	add_child(_root_vbox)

	# Barra superior compacta de controles (pausa/reinicio/cerrar)
	var top_bar := HBoxContainer.new()
	top_bar.name = "CreditsTopBar"
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_theme_constant_override("separation", 8)
	_root_vbox.add_child(top_bar)

	var lbl_badge := Label.new()
	lbl_badge.text = "CRÉDITOS OFICIALES · FORMATO 3:4 (README)"
	lbl_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_badge.add_theme_font_size_override("font_size", 12)
	lbl_badge.add_theme_color_override("font_color", Color(0.95, 0.84, 0.44))
	top_bar.add_child(lbl_badge)

	_btn_play_pause = Button.new()
	_btn_play_pause.text = "⏸ Pausa"
	_btn_play_pause.custom_minimum_size = Vector2(88, 34)
	_btn_play_pause.add_theme_font_size_override("font_size", 11)
	_btn_play_pause.pressed.connect(_toggle_play_pause)
	top_bar.add_child(_btn_play_pause)
	UiJuice.attach_button(_btn_play_pause)

	_btn_restart = Button.new()
	_btn_restart.text = "↺ Reiniciar"
	_btn_restart.custom_minimum_size = Vector2(92, 34)
	_btn_restart.add_theme_font_size_override("font_size", 11)
	_btn_restart.pressed.connect(_restart_credits)
	top_bar.add_child(_btn_restart)
	UiJuice.attach_button(_btn_restart)

	_btn_fullscreen = Button.new()
	_btn_fullscreen.name = "BtnCreditsFullscreen"
	_btn_fullscreen.text = "⛶ Pantalla Completa"
	_btn_fullscreen.custom_minimum_size = Vector2(142, 34)
	_btn_fullscreen.add_theme_font_size_override("font_size", 11)
	_btn_fullscreen.visible = not (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"))
	_btn_fullscreen.pressed.connect(toggle_fullscreen)
	top_bar.add_child(_btn_fullscreen)
	UiJuice.attach_button(_btn_fullscreen)

	_btn_close = Button.new()
	_btn_close.name = "BtnCreditsClose"
	_btn_close.text = "✕ Cerrar"
	_btn_close.custom_minimum_size = Vector2(88, 34)
	_btn_close.add_theme_font_size_override("font_size", 11)
	_btn_close.pressed.connect(_close)
	top_bar.add_child(_btn_close)
	UiJuice.attach_button(_btn_close)

	_btn_exit_fullscreen = Button.new()
	_btn_exit_fullscreen.name = "BtnCreditsExitFullscreen"
	_btn_exit_fullscreen.text = "✕ Salir Pantalla Completa"
	_btn_exit_fullscreen.visible = false
	_btn_exit_fullscreen.z_index = 20
	_btn_exit_fullscreen.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_btn_exit_fullscreen.anchor_left = 1.0
	_btn_exit_fullscreen.anchor_right = 1.0
	_btn_exit_fullscreen.offset_left = -196.0
	_btn_exit_fullscreen.offset_top = 10.0
	_btn_exit_fullscreen.offset_right = -10.0
	_btn_exit_fullscreen.offset_bottom = 44.0
	_btn_exit_fullscreen.add_theme_font_size_override("font_size", 11)
	_btn_exit_fullscreen.pressed.connect(toggle_fullscreen)
	add_child(_btn_exit_fullscreen)

	# Contenedor estricto 3:4 (ratio = 0.75)
	_aspect_box = AspectRatioContainer.new()
	_aspect_box.name = "CreditsAspect3x4"
	_aspect_box.ratio = RATIO_3_4
	_aspect_box.stretch_mode = AspectRatioContainer.STRETCH_FIT
	_aspect_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_aspect_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_vbox.add_child(_aspect_box)

	_frame_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.09, 1.0)
	sb.border_color = Color(0.86, 0.72, 0.34, 0.95)
	sb.set_border_width_all(2)
	sb.content_margin_left = 2
	sb.content_margin_right = 2
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	_frame_panel.add_theme_stylebox_override("panel", sb)
	_aspect_box.add_child(_frame_panel)

	_stage_ctrl = Control.new()
	_stage_ctrl.clip_contents = true
	_stage_ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage_ctrl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage_ctrl.resized.connect(_recompute_roll_bounds)
	_frame_panel.add_child(_stage_ctrl)

	_video_player = VideoStreamPlayer.new()
	_video_player.name = "CreditsVideoPlayer"
	_video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video_player.expand = true
	_video_player.visible = false
	_video_player.finished.connect(_on_video_finished)
	_stage_ctrl.add_child(_video_player)

func hide_chrome_for_recording() -> void:
	var tb := find_child("CreditsTopBar", true, false) as Control
	if tb:
		tb.visible = false

func _try_start_video() -> bool:
	if not ResourceLoader.exists(VIDEO_OGV_PATH) and not FileAccess.file_exists(VIDEO_OGV_PATH):
		return false
	var stream := ResourceLoader.load(VIDEO_OGV_PATH) as VideoStream
	if stream == null:
		return false
	var gs := get_node_or_null("/root/GameSettings") if is_inside_tree() else null
	if gs and gs.has_method("stop_music"):
		gs.stop_music(0.15)
	_is_live_rolling = false
	if _roll_container and is_instance_valid(_roll_container):
		_roll_container.visible = false
	_video_player.stream = stream
	_video_player.visible = true
	_video_player.paused = false
	_video_player.play()
	_is_paused_video = false
	if _btn_play_pause:
		_btn_play_pause.text = "⏸ Pausa"
	return true

func start_live_roll_for_recording(duration_sec: float = 34.0) -> void:
	_roll_duration = maxf(6.0, duration_sec)
	_roll_elapsed = 0.0
	_roll_done = false
	_is_paused_video = false
	_is_live_rolling = true
	if _video_player:
		_video_player.stop()
		_video_player.visible = false
	_build_live_roll_nodes()

func _build_live_roll_nodes() -> void:
	if _roll_container and is_instance_valid(_roll_container):
		_stage_ctrl.remove_child(_roll_container)
		_roll_container.queue_free()

	_roll_container = VBoxContainer.new()
	_roll_container.name = "CreditsRollContent"
	_roll_container.add_theme_constant_override("separation", 8)
	_roll_container.position = Vector2(18, 520)
	_stage_ctrl.add_child(_roll_container)

	# Cabecera con escudos institucionales
	var logos := HBoxContainer.new()
	logos.alignment = BoxContainer.ALIGNMENT_CENTER
	logos.add_theme_constant_override("separation", 18)
	_roll_container.add_child(logos)
	for logo_path in ["res://assets/logos/cobaem-logo.jpeg", "res://icon.jpeg"]:
		var logo_tex := AssetLoader.load_texture(logo_path)
		if logo_tex != null:
			var tr := TextureRect.new()
			tr.texture = logo_tex
			tr.custom_minimum_size = Vector2(72, 72)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			logos.add_child(tr)

	var sub_hdr := Label.new()
	sub_hdr.text = "COLEGIO DE BACHILLERES DEL ESTADO DE MÉXICO\nPLANTEL CEMSaD 22 ENTHAVI · TEMOAYA"
	sub_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_hdr.add_theme_font_size_override("font_size", 12)
	sub_hdr.add_theme_color_override("font_color", Color(0.95, 0.84, 0.45))
	_roll_container.add_child(sub_hdr)

	var max_items := mini(_parsed_entries.size(), 95)
	for i in range(max_items):
		var item: Dictionary = _parsed_entries[i]
		var kind := str(item.get("kind", "body"))
		var lbl := Label.new()
		lbl.text = str(item.get("text", ""))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.custom_minimum_size.x = 460.0
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if kind in ["title", "section", "sub"] else HORIZONTAL_ALIGNMENT_LEFT
		match kind:
			"title":
				lbl.add_theme_font_size_override("font_size", 18)
				lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.38))
			"section":
				lbl.add_theme_font_size_override("font_size", 14)
				lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.36))
			"sub":
				lbl.add_theme_font_size_override("font_size", 12)
				lbl.add_theme_color_override("font_color", Color(0.45, 0.92, 1.0))
			_:
				lbl.add_theme_font_size_override("font_size", 10)
				lbl.add_theme_color_override("font_color", Color(0.88, 0.90, 0.95))
		_roll_container.add_child(lbl)

	var end_lbl := Label.new()
	end_lbl.text = "\n★ CAMPEONES DE LOS VALORES ★\nRESPETO · EMPATÍA · SOLIDARIDAD\nCEMSaD 22 ENTHAVI — GRACIAS POR JUGAR\n"
	end_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_lbl.add_theme_font_size_override("font_size", 14)
	end_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	_roll_container.add_child(end_lbl)

	_recompute_roll_bounds()

func _recompute_roll_bounds() -> void:
	if _roll_container == null or _stage_ctrl == null:
		return
	var stage_sz := _stage_ctrl.size
	if stage_sz.x < 10.0:
		stage_sz = Vector2(540, 720)
	var target_w := maxf(220.0, stage_sz.x - 36.0)
	_roll_container.custom_minimum_size.x = target_w
	for child in _roll_container.get_children():
		if child is Label:
			(child as Label).custom_minimum_size.x = target_w
	var comb := _roll_container.get_combined_minimum_size()
	var comb_h := maxf(200.0, comb.y)
	_last_comb_h = comb_h
	_roll_container.size = Vector2(target_w, comb_h)
	_roll_start_y = stage_sz.y - 40.0
	_roll_end_y = -(comb_h + 24.0)
	if _roll_elapsed <= 0.05:
		_roll_container.position = Vector2(18.0, _roll_start_y)

func _update_safe_layout() -> void:
	if not is_inside_tree() or get_viewport() == null:
		return
	var ins := MobileControls.get_safe_insets_for_viewport(get_viewport(), 8.0)
	if _root_vbox and is_instance_valid(_root_vbox):
		_root_vbox.offset_left = ins.position.x
		_root_vbox.offset_top = ins.position.y
		_root_vbox.offset_right = -ins.size.x
		_root_vbox.offset_bottom = -ins.size.y
	if _btn_exit_fullscreen and is_instance_valid(_btn_exit_fullscreen):
		_btn_exit_fullscreen.offset_top = ins.position.y + 4.0
		_btn_exit_fullscreen.offset_right = -ins.size.x - 4.0
		_btn_exit_fullscreen.offset_left = -ins.size.x - 190.0
		_btn_exit_fullscreen.offset_bottom = ins.position.y + 38.0
	_recompute_roll_bounds()

func _process(delta: float) -> void:
	if not _is_live_rolling or _is_paused_video or _roll_container == null:
		return
	var cur_comb_h := _roll_container.get_combined_minimum_size().y
	if absf(cur_comb_h - _last_comb_h) > 4.0 or absf(_roll_end_y - _roll_start_y) < 10.0:
		_recompute_roll_bounds()
	_roll_elapsed += delta
	var frac := clampf(_roll_elapsed / _roll_duration, 0.0, 1.0)
	_roll_container.position.x = 18.0
	_roll_container.position.y = lerpf(_roll_start_y, _roll_end_y, frac)
	if frac >= 1.0 and not _roll_done:
		_roll_done = true
		roll_finished.emit()
		if use_video_file:
			_restart_credits()

func _toggle_play_pause() -> void:
	_is_paused_video = not _is_paused_video
	if _video_player and _video_player.visible:
		_video_player.paused = _is_paused_video
	if _btn_play_pause:
		_btn_play_pause.text = "▶ Reanudar" if _is_paused_video else "⏸ Pausa"

func _restart_credits() -> void:
	if _video_player and _video_player.visible:
		_video_player.stop()
		_video_player.play()
		_is_paused_video = false
		if _btn_play_pause:
			_btn_play_pause.text = "⏸ Pausa"
	else:
		start_live_roll_for_recording(_roll_duration)

func _on_video_finished() -> void:
	roll_finished.emit()
	if _video_player and _video_player.visible and not _closing:
		_video_player.play()

func toggle_fullscreen() -> void:
	set_fullscreen_mode(not _is_fullscreen_mode)

func _can_change_window_mode() -> bool:
	var gs := get_node_or_null("/root/GameSettings") if is_inside_tree() else null
	if gs and gs.has_method("should_skip_window_ops"):
		return not bool(gs.should_skip_window_ops())
	return DisplayServer.get_name() != "headless"

func set_fullscreen_mode(enabled: bool) -> void:
	_is_fullscreen_mode = enabled
	var tb := find_child("CreditsTopBar", true, false) as Control
	if tb:
		tb.visible = not enabled
	if _btn_exit_fullscreen:
		_btn_exit_fullscreen.visible = enabled
	if _btn_fullscreen:
		_btn_fullscreen.text = "🗗 Ventana" if enabled else "⛶ Pantalla Completa"
	if _can_change_window_mode():
		if enabled:
			_prev_window_mode = DisplayServer.window_get_mode()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			_restore_window_mode()
	call_deferred("_recompute_roll_bounds")

func _restore_window_mode() -> void:
	if _can_change_window_mode() and _prev_window_mode >= 0:
		DisplayServer.window_set_mode(_prev_window_mode)
		_prev_window_mode = -1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		match event.keycode:
			KEY_ESCAPE:
				if _is_fullscreen_mode:
					set_fullscreen_mode(false)
				else:
					_close()
				if get_viewport():
					get_viewport().set_input_as_handled()
			KEY_F11:
				toggle_fullscreen()
				if get_viewport():
					get_viewport().set_input_as_handled()
			KEY_SPACE:
				_toggle_play_pause()
				if get_viewport():
					get_viewport().set_input_as_handled()
			KEY_R:
				_restart_credits()
				if get_viewport():
					get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and not event.is_echo():
		if event.button_index == JOY_BUTTON_B:
			if _is_fullscreen_mode:
				set_fullscreen_mode(false)
			else:
				_close()
			if get_viewport():
				get_viewport().set_input_as_handled()

func _close() -> void:
	if _closing:
		return
	_closing = true
	if _is_fullscreen_mode:
		_is_fullscreen_mode = false
		_restore_window_mode()
	if _video_player:
		_video_player.stop()
	closed.emit()
	queue_free()
