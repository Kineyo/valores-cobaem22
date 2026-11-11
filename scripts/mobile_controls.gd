extends Control
class_name MobileControls

## Controles táctiles virtuales dinámicos y transparentes (v1.2).
## Características:
## 1. Joystick Izquierdo Dinámico: Completamente invisible/transparente en reposo.
##    Al tocar y mover el dedo en la mitad izquierda, aparece suavemente bajo el dedo
##    y sigue el movimiento en 8D/360°. Al soltar, se desvanece de nuevo a 0.0 de opacidad.
## 2. Joystick Derecho Dinámico de Virtud: Invisible en reposo. Al tocar la mitad derecha,
##    aparece con halo dorado/guinda COBAEM, flecha de trayectoria y disparo continuo de virtud.
## 3. Manejo de Entrada con '_unhandled_input': NUNCA interfiere con botones de UI ("Reiniciar",
##    "Menú principal", etc.), ya que la UI consume los clics antes.
## 4. Desactivación instantánea cuando el juego está pausado o en paneles modales.

signal pause_requested
signal aim_vector_changed(aim_vec: Vector2)

@export var joystick_radius: float = 54.0
@export var knob_radius: float = 24.0
@export var deadzone: float = 0.15

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

var _left_alpha: float = 0.0
var _right_alpha: float = 0.0
var _target_left_alpha: float = 0.0
var _target_right_alpha: float = 0.0

var is_active: bool = true

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

func _get_safe_viewport_size() -> Vector2:
	if not is_inside_tree():
		return Vector2(800.0, 450.0)
	var vp := get_viewport_rect().size
	if vp.x <= 10.0 or vp.y <= 10.0:
		return Vector2(800.0, 450.0)
	return vp

func _update_positions() -> void:
	var vp_size := _get_safe_viewport_size()
	_pause_pos = Vector2(vp_size.x - 36.0, 34.0)
	queue_redraw()

func _process(delta: float) -> void:
	var changed := false
	if not is_equal_approx(_left_alpha, _target_left_alpha):
		_left_alpha = move_toward(_left_alpha, _target_left_alpha, delta * 8.0)
		changed = true
	if not is_equal_approx(_right_alpha, _target_right_alpha):
		_right_alpha = move_toward(_right_alpha, _target_right_alpha, delta * 8.0)
		changed = true
	if changed:
		queue_redraw()

## Desactiva los controles y libera cualquier acción en curso (llamado en pausa/game over/victoria)
func deactivate() -> void:
	is_active = false
	_target_left_alpha = 0.0
	_target_right_alpha = 0.0
	_left_alpha = 0.0
	_right_alpha = 0.0
	_reset_left_stick()
	_reset_right_stick()
	_pause_pressed = false
	_pause_touch_id = -1
	queue_redraw()

## Reactiva los controles para gameplay
func activate() -> void:
	is_active = true
	if is_touch_device() or _force_visible:
		visible = true
	queue_redraw()

## Usamos _unhandled_input para que NUNCA intercepte los clics de botones del HUD ni menús
func _unhandled_input(event: InputEvent) -> void:
	# Atajo de depuración en PC (F1 alterna los controles en pantalla)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_force_visible = not _force_visible
			visible = _force_visible
			queue_redraw()
			return

	# Si los controles están inactivos, ocultos o el juego está pausado, ignorar por completo
	if not is_active or not visible:
		return
	if is_inside_tree():
		var tree := get_tree()
		if tree and tree.paused:
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
	var vp_size := _get_safe_viewport_size()
	var vp_half_x := vp_size.x * 0.5

	if pressed:
		# 1. Botón de Pausa superior derecho (radio 24px)
		if pos.distance_squared_to(_pause_pos) <= 800.0:
			_pause_touch_id = touch_id
			_pause_pressed = true
			pause_requested.emit()
			queue_redraw()
			return

		# Ignorar toques sobre la franja superior del HUD (evitar interferir con botones/barra)
		if pos.y < 56.0:
			return

		# 2. Joystick Izquierdo (Moverse) — Mitad izquierda de pantalla
		if pos.x < vp_half_x and _left_touch_id == -1:
			_left_touch_id = touch_id
			_left_base = pos
			_left_pos = pos
			_target_left_alpha = 0.75
			_update_left_stick(pos)
			queue_redraw()
			return

		# 3. Joystick Derecho (Apuntar y Disparar Virtud) — Mitad derecha de pantalla
		if pos.x >= vp_half_x and _right_touch_id == -1:
			_right_touch_id = touch_id
			_right_base = pos
			_right_pos = pos
			_right_pressed = true
			_target_right_alpha = 0.80
			_update_right_stick(pos)
			queue_redraw()
			return
	else:
		# Soltar toque correspondiente
		if touch_id == _left_touch_id:
			_target_left_alpha = 0.0
			_reset_left_stick()
		if touch_id == _right_touch_id:
			_target_right_alpha = 0.0
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
		# Joystick flotante dinámico: la base sigue suavemente al pulgar si se aleja mucho
		if dist > joystick_radius * 1.35:
			_left_base = pos - diff.normalized() * (joystick_radius * 1.35)
			diff = pos - _left_base
		diff = diff.normalized() * joystick_radius
	_left_pos = _left_base + diff

	var norm := diff / joystick_radius
	_apply_input_axis("move_left", "move_right", norm.x)
	_apply_input_axis("move_up", "move_down", norm.y)

func _update_right_stick(pos: Vector2) -> void:
	var diff := pos - _right_base
	var dist := diff.length()
	if dist > joystick_radius:
		if dist > joystick_radius * 1.35:
			_right_base = pos - diff.normalized() * (joystick_radius * 1.35)
			diff = pos - _right_base
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
	if not visible or not is_active:
		return

	# ==========================================================
	# 1. JOYSTICK IZQUIERDO: MOVIMIENTO DINÁMICO (VERDE COBAEM)
	# ==========================================================
	if _left_alpha > 0.005:
		var la := _left_alpha
		var left_base_bg := Color(0.0, 0.38, 0.25, 0.40 * la)
		var left_border := Color(0.25, 0.92, 0.55, 0.92 * la)
		var left_border_inner := Color(1.0, 0.88, 0.35, 0.65 * la)

		draw_circle(_left_base, joystick_radius, left_base_bg)
		draw_arc(_left_base, joystick_radius, 0.0, TAU, 32, left_border, 2.5)
		draw_arc(_left_base, joystick_radius - 3.0, 0.0, TAU, 32, left_border_inner, 1.0)

		# Muescas cardinales pixel art en los 4 puntos cardinales
		var guide_col := Color(1.0, 1.0, 1.0, 0.40 * la)
		draw_line(_left_base + Vector2(-16, 0), _left_base + Vector2(16, 0), guide_col, 2.0)
		draw_line(_left_base + Vector2(0, -16), _left_base + Vector2(0, 16), guide_col, 2.0)

		# Línea conectora entre base y knob
		if _left_pos != _left_base:
			draw_line(_left_base, _left_pos, Color(0.3, 0.95, 0.6, 0.55 * la), 2.5)

		# Knob móvil con estética pixel art
		var left_knob_bg := Color(0.18, 0.82, 0.42, 0.95 * la)
		var left_knob_border := Color(1.0, 1.0, 1.0, 0.98 * la)
		draw_circle(_left_pos, knob_radius, left_knob_bg)
		draw_arc(_left_pos, knob_radius, 0.0, TAU, 24, left_knob_border, 2.0)
		draw_circle(_left_pos, 4.0, Color(1.0, 1.0, 1.0, la))

	# ==========================================================
	# 2. JOYSTICK DERECHO: VIRTUD / DISPARO DINÁMICO (GUINDA / ORO)
	# ==========================================================
	if _right_alpha > 0.005:
		var ra := _right_alpha
		var right_base_bg := Color(0.41, 0.11, 0.20, 0.45 * ra)
		var right_border := Color(1.0, 0.85, 0.35, 0.92 * ra)
		var right_border_inner := Color(0.9, 0.3, 0.45, 0.65 * ra)

		draw_circle(_right_base, joystick_radius, right_base_bg)
		draw_arc(_right_base, joystick_radius, 0.0, TAU, 32, right_border, 2.5)
		draw_arc(_right_base, joystick_radius - 3.0, 0.0, TAU, 32, right_border_inner, 1.0)

		# Flecha direccional de puntería cuando se arrastra el stick derecho
		if current_aim_vector != Vector2.ZERO:
			var arrow_start := _right_base + current_aim_vector * (joystick_radius * 0.35)
			var arrow_end := _right_base + current_aim_vector * (joystick_radius + 18.0)
			draw_line(arrow_start, arrow_end, Color(1.0, 0.92, 0.4, 0.95 * ra), 3.0)
			var perp := Vector2(-current_aim_vector.y, current_aim_vector.x) * 7.0
			var tip_left := arrow_end - current_aim_vector * 12.0 + perp
			var tip_right := arrow_end - current_aim_vector * 12.0 - perp
			draw_colored_polygon(PackedVector2Array([arrow_end, tip_left, tip_right]), Color(1.0, 0.95, 0.5, 0.95 * ra))

		# Línea conectora hacia el knob derecho
		if _right_pos != _right_base:
			draw_line(_right_base, _right_pos, Color(1.0, 0.8, 0.25, 0.55 * ra), 2.5)

		# Knob derecho móvil
		var right_knob_bg := Color(1.0, 0.72, 0.18, 0.95 * ra)
		var right_knob_border := Color(1.0, 0.96, 0.85, 0.98 * ra)
		draw_circle(_right_pos, knob_radius, right_knob_bg)
		draw_arc(_right_pos, knob_radius, 0.0, TAU, 24, right_knob_border, 2.0)

		# Texto "VIRTUD" pixel art en el knob
		var font := ThemeDB.fallback_font
		var font_size := 11
		var label_text := "VIRTUD"
		var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, _right_pos + Vector2(-text_size.x * 0.5, text_size.y * 0.32), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.35, 0.08, 0.12, ra))

	# ==========================================================
	# 3. BOTÓN DE PAUSA SUPERIOR DERECHO (PIXEL ART GUINDA/ORO)
	# ==========================================================
	if not get_tree().paused:
		var pause_bg := Color(0.41, 0.11, 0.20, 0.82) if not _pause_pressed else Color(0.65, 0.18, 0.30, 0.95)
		var pause_border := Color(1.0, 0.85, 0.35, 0.90)
		draw_circle(_pause_pos, 18.0, pause_bg)
		draw_arc(_pause_pos, 18.0, 0.0, TAU, 24, pause_border, 2.0)

		# Dos barras verticales de pausa en oro
		var bar_col := Color(1.0, 0.92, 0.75, 1.0)
		draw_rect(Rect2(_pause_pos.x - 5.5, _pause_pos.y - 6.0, 3.0, 12.0), bar_col)
		draw_rect(Rect2(_pause_pos.x + 2.5, _pause_pos.y - 6.0, 3.0, 12.0), bar_col)
