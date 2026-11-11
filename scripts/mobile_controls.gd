extends Control
class_name MobileControls

## Controles táctiles virtuales dobles (Dual Joysticks) para Android / Táctil (v1.1).
## Proporciona:
## 1. Joystick Izquierdo (Mover): Desplazamiento fluido en 8D/360° con calibración de zona muerta.
## 2. Joystick Derecho (Virtud): Puntería dinámica en 360° con flecha de trayectoria y disparo continuo.
## 3. Botón de Pausa superior ergonómico.

signal pause_requested
signal aim_vector_changed(aim_vec: Vector2)

@export var joystick_radius: float = 54.0
@export var knob_radius: float = 25.0
@export var deadzone: float = 0.16

var _left_touch_id: int = -1
var _right_touch_id: int = -1
var _pause_touch_id: int = -1

var _left_base: Vector2 = Vector2.ZERO
var _left_pos: Vector2 = Vector2.ZERO
var _right_base: Vector2 = Vector2.ZERO
var _right_pos: Vector2 = Vector2.ZERO
var _pause_pos: Vector2 = Vector2.ZERO

var _pause_pressed: bool = false
var _right_pressed: bool = false
var _force_visible: bool = false

## Vector de puntería normalizado actual generado por el joystick derecho
var current_aim_vector: Vector2 = Vector2.ZERO

static func is_touch_device() -> bool:
	return OS.has_feature("mobile") \
		or OS.has_feature("android") \
		or OS.has_feature("web_android") \
		or OS.has_feature("web_ios") \
		or DisplayServer.is_touchscreen_available()

func _ready() -> void:
	visible = is_touch_device()
	mouse_filter = MOUSE_FILTER_PASS
	_update_positions()
	get_viewport().size_changed.connect(_update_positions)

func _update_positions() -> void:
	var vp_size := get_viewport_rect().size
	var margin_x: float = clampf(vp_size.x * 0.13, 85.0, 160.0)
	var margin_y: float = clampf(vp_size.y * 0.23, 80.0, 135.0)

	_left_base = Vector2(margin_x, vp_size.y - margin_y)
	_left_pos = _left_base

	_right_base = Vector2(vp_size.x - margin_x, vp_size.y - margin_y)
	_right_pos = _right_base

	_pause_pos = Vector2(vp_size.x - 38.0, 36.0)
	queue_redraw()

func _input(event: InputEvent) -> void:
	# Atajo de depuración en PC (F1 alterna los controles en pantalla)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_force_visible = not visible
			visible = _force_visible
			queue_redraw()
			return

	# Si se detecta un toque de pantalla en dispositivos táctiles, activamos controles táctiles
	if (event is InputEventScreenTouch or event is InputEventScreenDrag) and not visible:
		if DisplayServer.is_touchscreen_available() and not get_tree().paused:
			_force_visible = true
			visible = true

	if not is_visible_in_tree():
		return

	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.pressed, event.position)
	elif event is InputEventScreenDrag:
		_handle_drag(event.index, event.position)
	elif event is InputEventMouseButton:
		_handle_touch(0, event.pressed, event.position)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_handle_drag(0, event.position)

func _handle_touch(touch_id: int, pressed: bool, pos: Vector2) -> void:
	var vp_size := get_viewport_rect().size
	var vp_half_x := vp_size.x * 0.5

	if pressed:
		# 1. Botón de Pausa (esquina superior derecha, radio 34px -> radio^2 = 1156)
		if pos.distance_squared_to(_pause_pos) <= 1156.0:
			_pause_touch_id = touch_id
			_pause_pressed = true
			pause_requested.emit()
			queue_redraw()
			return

		# Evitar capturar toques sobre la barra superior del HUD
		if pos.y < 52.0:
			return

		var max_r_sq := (joystick_radius * 2.2) * (joystick_radius * 2.2)

		# 2. Joystick Izquierdo (Moverse) — Mitad izquierda de pantalla
		if pos.x < vp_half_x and _left_touch_id == -1:
			_left_touch_id = touch_id
			if pos.distance_squared_to(_left_base) <= max_r_sq:
				_update_left_stick(pos)
			else:
				_left_base = pos
				_update_left_stick(pos)
			queue_redraw()
			return

		# 3. Joystick Derecho (Apuntar y Disparar Virtud) — Mitad derecha de pantalla
		if pos.x >= vp_half_x and _right_touch_id == -1:
			_right_touch_id = touch_id
			_right_pressed = true
			if pos.distance_squared_to(_right_base) <= max_r_sq:
				_update_right_stick(pos)
			else:
				_right_base = pos
				_update_right_stick(pos)
			queue_redraw()
			return
	else:
		# Soltar toque correspondiente
		if touch_id == _left_touch_id:
			_reset_left_stick()
		if touch_id == _right_touch_id:
			_reset_right_stick()
		if touch_id == _pause_touch_id:
			_pause_touch_id = -1
			_pause_pressed = false
			queue_redraw()

func _handle_drag(touch_id: int, pos: Vector2) -> void:
	if touch_id == _left_touch_id:
		_update_left_stick(pos)
		queue_redraw()
	elif touch_id == _right_touch_id:
		_update_right_stick(pos)
		queue_redraw()

func _update_left_stick(pos: Vector2) -> void:
	var diff := pos - _left_base
	var dist := diff.length()
	if dist > joystick_radius:
		diff = diff.normalized() * joystick_radius
	_left_pos = _left_base + diff

	var norm := diff / joystick_radius
	_apply_input_axis("move_left", "move_right", norm.x)
	_apply_input_axis("move_up", "move_down", norm.y)

func _update_right_stick(pos: Vector2) -> void:
	var diff := pos - _right_base
	var dist := diff.length()
	if dist > joystick_radius:
		diff = diff.normalized() * joystick_radius
	_right_pos = _right_base + diff

	var norm := diff / joystick_radius
	if norm.length() >= deadzone:
		current_aim_vector = norm.normalized()
		_apply_input_axis("aim_left", "aim_right", norm.x)
		_apply_input_axis("aim_up", "aim_down", norm.y)
	else:
		current_aim_vector = Vector2.ZERO
		Input.action_release("aim_left")
		Input.action_release("aim_right")
		Input.action_release("aim_up")
		Input.action_release("aim_down")

	aim_vector_changed.emit(current_aim_vector)

	# Mantener disparo activo mientras se use el stick derecho
	if not Input.is_action_pressed("attack"):
		Input.action_press("attack")

func _apply_input_axis(neg_action: String, pos_action: String, val: float) -> void:
	if absf(val) < deadzone:
		Input.action_release(neg_action)
		Input.action_release(pos_action)
	elif val < 0.0:
		Input.action_press(neg_action, -val)
		Input.action_release(pos_action)
	else:
		Input.action_press(pos_action, val)
		Input.action_release(neg_action)

func _reset_left_stick() -> void:
	_left_touch_id = -1
	_left_pos = _left_base
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
	queue_redraw()

func _reset_right_stick() -> void:
	_right_touch_id = -1
	_right_pos = _right_base
	_right_pressed = false
	current_aim_vector = Vector2.ZERO
	Input.action_release("aim_left")
	Input.action_release("aim_right")
	Input.action_release("aim_up")
	Input.action_release("aim_down")
	Input.action_release("attack")
	aim_vector_changed.emit(Vector2.ZERO)
	queue_redraw()

func _draw() -> void:
	if not visible:
		return

	# ==========================================
	# 1. JOYSTICK IZQUIERDO: MOVIMIENTO (VERDE COBAEM)
	# ==========================================
	var left_active := (_left_touch_id != -1)
	var left_base_bg := Color(0.06, 0.16, 0.09, 0.50 if left_active else 0.38)
	var left_border := Color(0.25, 0.82, 0.42, 0.90 if left_active else 0.72)

	draw_circle(_left_base, joystick_radius, left_base_bg)
	draw_arc(_left_base, joystick_radius, 0.0, TAU, 36, left_border, 2.5)

	# Guías cardinales (Norte, Sur, Este, Oeste)
	var guide_col := Color(1.0, 1.0, 1.0, 0.28 if left_active else 0.18)
	draw_line(_left_base + Vector2(-18, 0), _left_base + Vector2(18, 0), guide_col, 2.0)
	draw_line(_left_base + Vector2(0, -18), _left_base + Vector2(0, 18), guide_col, 2.0)

	# Línea indicadora de desplazamiento hacia el knob
	if left_active and _left_pos != _left_base:
		draw_line(_left_base, _left_pos, Color(0.3, 0.9, 0.5, 0.5), 2.0)

	# Knob izquierdo móvil
	var left_knob_bg := Color(0.20, 0.85, 0.40, 0.92) if left_active else Color(0.22, 0.65, 0.34, 0.68)
	var left_knob_border := Color(1.0, 1.0, 1.0, 0.98) if left_active else Color(0.88, 0.96, 0.90, 0.80)
	draw_circle(_left_pos, knob_radius, left_knob_bg)
	draw_arc(_left_pos, knob_radius, 0.0, TAU, 28, left_knob_border, 2.0)
	draw_circle(_left_pos, 4.5, Color.WHITE)

	# ==========================================
	# 2. JOYSTICK DERECHO: VIRTUD / DISPARO (DORADO / ÁMBAR)
	# ==========================================
	var right_active := (_right_touch_id != -1)
	var right_base_bg := Color(0.24, 0.14, 0.04, 0.52 if right_active else 0.40)
	var right_border := Color(1.0, 0.78, 0.22, 0.92 if right_active else 0.75)

	draw_circle(_right_base, joystick_radius, right_base_bg)
	draw_arc(_right_base, joystick_radius, 0.0, TAU, 36, right_border, 2.5)

	# Marcas de energía radiante en la base derecha
	var spike_col := Color(1.0, 0.9, 0.5, 0.32 if right_active else 0.20)
	draw_line(_right_base + Vector2(-18, 0), _right_base + Vector2(18, 0), spike_col, 2.0)
	draw_line(_right_base + Vector2(0, -18), _right_base + Vector2(0, 18), spike_col, 2.0)

	# Flecha direccional de puntería cuando se arrastra el stick derecho
	if current_aim_vector != Vector2.ZERO:
		var arrow_start := _right_base + current_aim_vector * (joystick_radius * 0.4)
		var arrow_end := _right_base + current_aim_vector * (joystick_radius + 16.0)
		draw_line(arrow_start, arrow_end, Color(1.0, 0.92, 0.4, 0.9), 3.0)
		var perp := Vector2(-current_aim_vector.y, current_aim_vector.x) * 6.0
		var tip_left := arrow_end - current_aim_vector * 10.0 + perp
		var tip_right := arrow_end - current_aim_vector * 10.0 - perp
		draw_colored_polygon(PackedVector2Array([arrow_end, tip_left, tip_right]), Color(1.0, 0.95, 0.5, 0.95))

	# Línea indicadora de desplazamiento hacia el knob derecho
	if right_active and _right_pos != _right_base:
		draw_line(_right_base, _right_pos, Color(1.0, 0.75, 0.2, 0.5), 2.0)

	# Knob derecho móvil
	var right_knob_bg := Color(1.0, 0.65, 0.12, 0.95) if right_active else Color(0.90, 0.52, 0.10, 0.72)
	var right_knob_border := Color(1.0, 0.96, 0.75, 0.98) if right_active else Color(1.0, 0.82, 0.35, 0.82)
	draw_circle(_right_pos, knob_radius, right_knob_bg)
	draw_arc(_right_pos, knob_radius, 0.0, TAU, 28, right_knob_border, 2.0)

	# Símbolo / Texto "VIRTUD" en el knob
	var font := ThemeDB.fallback_font
	var font_size := 11
	var label_text := "VIRTUD"
	var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, _right_pos + Vector2(-text_size.x * 0.5, text_size.y * 0.32), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

	# ==========================================
	# 3. BOTÓN DE PAUSA (ESQUINA SUPERIOR DERECHA)
	# ==========================================
	var pause_bg := Color(0.12, 0.14, 0.22, 0.85) if not _pause_pressed else Color(0.32, 0.34, 0.50, 0.95)
	var pause_border := Color(0.70, 0.80, 1.0, 0.85)
	draw_circle(_pause_pos, 19.0, pause_bg)
	draw_arc(_pause_pos, 19.0, 0.0, TAU, 24, pause_border, 1.8)

	# Dos barras verticales de pausa
	var bar_col := Color.WHITE
	draw_rect(Rect2(_pause_pos.x - 6.0, _pause_pos.y - 7.0, 3.5, 14.0), bar_col)
	draw_rect(Rect2(_pause_pos.x + 2.5, _pause_pos.y - 7.0, 3.5, 14.0), bar_col)
