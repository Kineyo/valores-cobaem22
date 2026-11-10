extends Control
class_name MobileControls

## Controles táctiles virtuales optimizados para la versión móvil (Android / Web).
## Proporciona un joystick virtual analógico en 8 direcciones, botón de Virtud y botón de Pausa.

signal pause_requested

@export var joystick_radius: float = 50.0
@export var knob_radius: float = 24.0
@export var button_radius: float = 38.0
@export var deadzone: float = 0.15

var _joystick_touch_id: int = -1
var _button_touch_id: int = -1
var _pause_touch_id: int = -1

var _joystick_base: Vector2 = Vector2.ZERO
var _joystick_pos: Vector2 = Vector2.ZERO
var _button_pos: Vector2 = Vector2.ZERO
var _pause_pos: Vector2 = Vector2.ZERO
var _button_pressed: bool = false
var _pause_pressed: bool = false

func _ready() -> void:
	# Activar automáticamente en dispositivos móviles o con pantalla táctil
	var is_mobile := OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()
	visible = is_mobile
	mouse_filter = MOUSE_FILTER_PASS
	_update_positions()
	get_viewport().size_changed.connect(_update_positions)

func _update_positions() -> void:
	var vp_size := get_viewport_rect().size
	_joystick_base = Vector2(100.0, vp_size.y - 100.0)
	_joystick_pos = _joystick_base
	_button_pos = Vector2(vp_size.x - 100.0, vp_size.y - 100.0)
	_pause_pos = Vector2(vp_size.x - 38.0, 38.0)
	queue_redraw()

func _input(event: InputEvent) -> void:
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
	if pressed:
		# Botón de Pausa (esquina superior derecha)
		if pos.distance_to(_pause_pos) <= 30.0:
			_pause_touch_id = touch_id
			_pause_pressed = true
			pause_requested.emit()
			queue_redraw()
			return

		# Botón de Virtud / Disparo (esquina inferior derecha)
		if pos.distance_to(_button_pos) <= button_radius * 1.5:
			_button_touch_id = touch_id
			_button_pressed = true
			Input.action_press("attack")
			queue_redraw()
			return

		# Joystick virtual (mitad izquierda de la pantalla)
		var vp_width := get_viewport_rect().size.x
		if pos.x < vp_width * 0.5 and _joystick_touch_id == -1:
			_joystick_touch_id = touch_id
			# Si el toque es cercano a la base predeterminada, mover knob; si no, reubicar base
			if pos.distance_to(_joystick_base) <= joystick_radius * 2.2:
				_update_joystick(pos)
			else:
				_joystick_base = pos
				_update_joystick(pos)
			queue_redraw()
	else:
		if touch_id == _joystick_touch_id:
			_reset_joystick()
		if touch_id == _button_touch_id:
			_button_touch_id = -1
			_button_pressed = false
			Input.action_release("attack")
			queue_redraw()
		if touch_id == _pause_touch_id:
			_pause_touch_id = -1
			_pause_pressed = false
			queue_redraw()

func _handle_drag(touch_id: int, pos: Vector2) -> void:
	if touch_id == _joystick_touch_id:
		_update_joystick(pos)
		queue_redraw()
	elif touch_id == _button_touch_id:
		var is_on_btn := pos.distance_to(_button_pos) <= button_radius * 1.6
		if is_on_btn != _button_pressed:
			_button_pressed = is_on_btn
			if is_on_btn:
				Input.action_press("attack")
			else:
				Input.action_release("attack")
			queue_redraw()

func _update_joystick(pos: Vector2) -> void:
	var diff := pos - _joystick_base
	var dist := diff.length()
	if dist > joystick_radius:
		diff = diff.normalized() * joystick_radius
	_joystick_pos = _joystick_base + diff

	var norm := diff / joystick_radius
	_apply_input_axis("move_left", "move_right", norm.x)
	_apply_input_axis("move_up", "move_down", norm.y)

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

func _reset_joystick() -> void:
	_joystick_touch_id = -1
	_joystick_pos = _joystick_base
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
	queue_redraw()

func _draw() -> void:
	if not visible:
		return

	# 1. Base del Joystick (círculo exterior con reborde institucional)
	var base_bg := Color(0.06, 0.14, 0.08, 0.45)
	var base_border := Color(0.2, 0.65, 0.3, 0.78)
	draw_circle(_joystick_base, joystick_radius, base_bg)
	draw_arc(_joystick_base, joystick_radius, 0.0, TAU, 32, base_border, 2.5)

	# Cruzeta guía sutil en la base
	var guide_col := Color(1.0, 1.0, 1.0, 0.2)
	draw_line(_joystick_base + Vector2(-16, 0), _joystick_base + Vector2(16, 0), guide_col, 2.0)
	draw_line(_joystick_base + Vector2(0, -16), _joystick_base + Vector2(0, 16), guide_col, 2.0)

	# 2. Knob central móvil
	var knob_active := (_joystick_touch_id != -1)
	var knob_bg := Color(0.18, 0.78, 0.35, 0.88) if knob_active else Color(0.22, 0.62, 0.32, 0.65)
	var knob_border := Color(1.0, 1.0, 1.0, 0.95) if knob_active else Color(0.85, 0.95, 0.88, 0.75)
	draw_circle(_joystick_pos, knob_radius, knob_bg)
	draw_arc(_joystick_pos, knob_radius, 0.0, TAU, 24, knob_border, 2.0)
	draw_circle(_joystick_pos, 4.0, Color.WHITE)

	# 3. Botón de Ataque / Virtud
	var btn_r := button_radius * (0.92 if _button_pressed else 1.0)
	var btn_bg := Color(0.98, 0.62, 0.1, 0.9) if _button_pressed else Color(0.88, 0.5, 0.08, 0.6)
	var btn_border := Color(1.0, 0.92, 0.6, 0.98) if _button_pressed else Color(1.0, 0.76, 0.22, 0.8)
	draw_circle(_button_pos, btn_r, btn_bg)
	draw_arc(_button_pos, btn_r, 0.0, TAU, 32, btn_border, 2.5)

	# Texto institucional "VIRTUD"
	var font := ThemeDB.fallback_font
	var font_size := 13
	var label_text := "VIRTUD"
	var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, _button_pos + Vector2(-text_size.x * 0.5, text_size.y * 0.35), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

	# 4. Botón de Pausa (superior derecho)
	var pause_bg := Color(0.1, 0.1, 0.16, 0.7) if not _pause_pressed else Color(0.28, 0.28, 0.42, 0.9)
	draw_circle(_pause_pos, 18.0, pause_bg)
	draw_arc(_pause_pos, 18.0, 0.0, TAU, 20, Color(0.65, 0.75, 0.95, 0.75), 1.5)
	var bar_col := Color.WHITE
	draw_rect(Rect2(_pause_pos.x - 6.0, _pause_pos.y - 7.0, 3.0, 14.0), bar_col)
	draw_rect(Rect2(_pause_pos.x + 3.0, _pause_pos.y - 7.0, 3.0, 14.0), bar_col)
