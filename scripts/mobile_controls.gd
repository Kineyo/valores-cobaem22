extends Control
class_name MobileControls

## Sistema de Controles Táctiles Virtuales de Alta Precisión (v2.0).
## Diseñado para Godot 4.7+ / 4.3+ (GL Compatibility) en Campeones de los Valores (COBAEM CEMSaD 22).
##
## Características principales:
## 1. Supresión total del conflicto de doble evento (Touch vs Mouse Emulation).
## 2. Aislamiento estricto de identificadores multitáctiles (Multi-Touch Index Isolation).
## 3. Zona muerta radial continua con compensación del deadzone de InputMap (respuesta 1:1).
## 4. Márgenes seguros automáticos (DisplayServer.get_display_safe_area) para notches y barras gestuales.
## 5. Guías sutiles en reposo (resting_alpha = 0.18) con estética institucional COBAEM (verde esmeralda y guinda/oro).
## 6. Detección automática de hardware y promoción dinámica en tiempo real.

signal pause_requested
signal aim_vector_changed(aim_vec: Vector2)
signal focus_toggled(enabled: bool)
signal touch_mode_changed(touch_active: bool)

# ==============================================================================
# PARÁMETROS CONFIGURABLES (INSPECTOR)
# ==============================================================================
@export_group("Dimensiones y Rango Dinámico")
## Radio exterior de la base del joystick en píxeles virtuales
@export var joystick_radius: float = 56.0
## Radio del cabezal móvil (knob) en píxeles virtuales
@export var knob_radius: float = 24.0
## Zona muerta radial normalizada (0.0 a 1.0) antes de registrar movimiento
@export var deadzone: float = 0.15
## Factor de arrastre máximo antes de que la base siga dinámicamente al pulgar
@export var max_drag_ratio: float = 1.35

@export_group("Ergonomía y Visuales COBAEM")
## Opacidad suave en reposo para indicar al jugador la posición recomendada de pulgares
@export var resting_alpha: float = 0.18
## Opacidad activa al tocar y operar los joysticks
@export var active_alpha: float = 0.82
## Velocidad de transición elástica de opacidad (lerp suave)
@export var transition_speed: float = 10.0
## Margen de seguridad base respecto a los bordes de la pantalla
@export var safe_margin: float = 24.0
## Si se debe renderizar el botón de pausa flotante dedicado en la esquina superior
@export var show_pause_button: bool = true
## Si se debe renderizar el botón táctil de Modo Enfoque (precisión Danmaku 52%)
@export var show_focus_button: bool = true

const FOCUS_BUTTON_RADIUS: float = 22.0
const FOCUS_HIT_RADIUS_SQ: float = 784.0 # Radio 28px (>= 44x44 dp ergonómico)
const FOCUS_HOLD_THRESHOLD_MS: int = 350
const PULSE_BUTTON_RADIUS: float = 20.0
const PULSE_HIT_RADIUS_SQ: float = 676.0

# ==============================================================================
# ESTADO INTERNO Y CONTROL DE TOQUES MULTITÁCTILES
# ==============================================================================
var _left_touch_id: int = -1
var _right_touch_id: int = -1
var _pause_touch_id: int = -1
var _focus_touch_id: int = -1
var _pulse_touch_id: int = -1

var _left_base: Vector2 = Vector2.ZERO
var _left_pos: Vector2 = Vector2.ZERO
var _right_base: Vector2 = Vector2.ZERO
var _right_pos: Vector2 = Vector2.ZERO
var _pause_pos: Vector2 = Vector2.ZERO
var _focus_pos: Vector2 = Vector2.ZERO
var _pulse_pos: Vector2 = Vector2.ZERO

var _pause_pressed: bool = false
var _right_pressed: bool = false
var _focus_pressed: bool = false
var _focus_toggled: bool = false
var _pulse_pressed: bool = false
var _focus_press_ms: int = 0
var _force_visible: bool = false

var _left_alpha: float = 0.0
var _right_alpha: float = 0.0
var _target_left_alpha: float = 0.0
var _target_right_alpha: float = 0.0

var is_active: bool = true

## Vector unitario de puntería 360° generado por el joystick derecho de Virtud
var current_aim_vector: Vector2 = Vector2.ZERO

var _has_native_touch: bool = false
var _emulate_touch_from_mouse: bool = false
var _inputmap_deadzone: float = 0.5

# ==============================================================================
# CICLO DE VIDA Y DETECCIÓN DE HARDWARE
# ==============================================================================
static func is_touch_device() -> bool:
	if OS.has_feature("mobile") \
		or OS.has_feature("android") \
		or OS.has_feature("ios") \
		or OS.has_feature("web_android") \
		or OS.has_feature("web_ios"):
		return true
	# En PC / Web de escritorio, DisplayServer.is_touchscreen_available() devuelve true
	# artificialmente cuando emulate_touch_from_mouse=true está activo en project.godot.
	if bool(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false)):
		return false
	return DisplayServer.is_touchscreen_available()

func _ready() -> void:
	_has_native_touch = is_touch_device()
	_emulate_touch_from_mouse = bool(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false))
	_cache_inputmap_deadzone()
	_ensure_focus_action()

	# En pantallas táctiles o Android, visible por defecto; en PC, oculto hasta F1 o primer toque físico
	visible = _has_native_touch or _force_visible
	mouse_filter = MOUSE_FILTER_PASS

	_update_positions()
	if is_inside_tree() and get_viewport():
		if not get_viewport().size_changed.is_connected(_update_positions):
			get_viewport().size_changed.connect(_update_positions)

	if visible:
		_target_left_alpha = resting_alpha
		_target_right_alpha = resting_alpha
	else:
		_target_left_alpha = 0.0
		_target_right_alpha = 0.0

func _cache_inputmap_deadzone() -> void:
	if InputMap.has_action("move_right"):
		_inputmap_deadzone = clampf(InputMap.action_get_deadzone("move_right"), 0.0, 0.9)
	else:
		_inputmap_deadzone = 0.5

func _ensure_focus_action() -> void:
	if not InputMap.has_action("focus"):
		InputMap.add_action("focus")

func _sync_focus_action() -> void:
	_ensure_focus_action()
	if _focus_toggled:
		if not Input.is_action_pressed("focus"):
			Input.action_press("focus")
	else:
		if Input.is_action_pressed("focus"):
			Input.action_release("focus")

func _release_focus_action() -> void:
	_focus_touch_id = -1
	_focus_pressed = false
	_focus_toggled = false
	if InputMap.has_action("focus"):
		Input.action_release("focus")

func _ensure_pulse_action() -> void:
	if not InputMap.has_action("empathy_pulse"):
		InputMap.add_action("empathy_pulse")

func _release_pulse_action() -> void:
	_pulse_touch_id = -1
	_pulse_pressed = false
	if InputMap.has_action("empathy_pulse") and Input.is_action_pressed("empathy_pulse"):
		Input.action_release("empathy_pulse")

func _get_safe_viewport_size() -> Vector2:
	if not is_inside_tree():
		return Vector2(800.0, 450.0)
	var vp := get_viewport_rect().size
	if vp.x <= 10.0 or vp.y <= 10.0:
		return Vector2(800.0, 450.0)
	return vp

## Calcula los márgenes de seguridad en coordenadas virtuales considerando el Safe Area real del dispositivo (muescas/notches)
static func get_safe_insets_for_viewport(vp: Viewport, min_margin: float = 6.0) -> Rect2:
	var vp_size: Vector2 = vp.get_visible_rect().size if (vp and vp.get_visible_rect().size.x > 10.0) else Vector2(800.0, 450.0)
	var left_m := min_margin
	var top_m := min_margin
	var right_m := min_margin
	var bottom_m := min_margin

	if DisplayServer.has_method("get_display_safe_area"):
		var safe_area := DisplayServer.get_display_safe_area()
		var win_size := DisplayServer.window_get_size()
		if win_size.x > 0 and win_size.y > 0 and safe_area.size.x > 0 and safe_area.size.y > 0:
			var sx := vp_size.x / float(win_size.x)
			var sy := vp_size.y / float(win_size.y)
			left_m = maxf(left_m, safe_area.position.x * sx)
			top_m = maxf(top_m, safe_area.position.y * sy)
			right_m = maxf(right_m, (win_size.x - (safe_area.position.x + safe_area.size.x)) * sx)
			bottom_m = maxf(bottom_m, (win_size.y - (safe_area.position.y + safe_area.size.y)) * sy)
	return Rect2(left_m, top_m, right_m, bottom_m)

## Calcula los márgenes de seguridad de esta instancia
func get_safe_insets() -> Rect2:
	return MobileControls.get_safe_insets_for_viewport(get_viewport(), safe_margin)

func _update_positions() -> void:
	var vp_size := _get_safe_viewport_size()
	var insets := get_safe_insets()
	var hud_insets := MobileControls.get_safe_insets_for_viewport(get_viewport(), 6.0) if is_inside_tree() else Rect2(6, 6, 6, 6)

	_pause_pos = Vector2(vp_size.x - insets.size.x - 24.0, maxf(insets.position.y + 16.0, 26.0))

	var default_left := Vector2(insets.position.x + joystick_radius + 20.0, vp_size.y - insets.size.y - joystick_radius - 16.0)
	var default_right := Vector2(vp_size.x - insets.size.x - joystick_radius - 20.0, vp_size.y - insets.size.y - joystick_radius - 16.0)

	# Botón táctil FOCUS ergonómico encima del joystick derecho (siempre en mitad derecha >= vp_size.x * 0.5)
	var focus_min_x := vp_size.x * 0.5 + FOCUS_BUTTON_RADIUS + 8.0
	var focus_max_x := vp_size.x - insets.size.x - FOCUS_BUTTON_RADIUS - 4.0
	var focus_x := clampf(default_right.x + joystick_radius * 0.35, minf(focus_min_x, focus_max_x), maxf(focus_min_x, focus_max_x))
	var focus_min_y := hud_insets.position.y + 46.0 + FOCUS_BUTTON_RADIUS + 8.0
	var focus_max_y := default_right.y - joystick_radius - FOCUS_BUTTON_RADIUS - 14.0
	var focus_y := clampf(default_right.y - joystick_radius - 48.0, minf(focus_min_y, focus_max_y), maxf(focus_min_y, focus_max_y))
	_focus_pos = Vector2(focus_x, focus_y)
	_pulse_pos = Vector2(maxf(vp_size.x * 0.5 + PULSE_BUTTON_RADIUS + 6.0, focus_x - 52.0), focus_y + 2.0)

	if _left_touch_id == -1:
		_left_base = default_left
		_left_pos = default_left
	if _right_touch_id == -1:
		_right_base = default_right
		_right_pos = default_right

	queue_redraw()

func _process(delta: float) -> void:
	var changed := false
	if not is_equal_approx(_left_alpha, _target_left_alpha):
		_left_alpha = move_toward(_left_alpha, _target_left_alpha, delta * transition_speed)
		changed = true
	if not is_equal_approx(_right_alpha, _target_right_alpha):
		_right_alpha = move_toward(_right_alpha, _target_right_alpha, delta * transition_speed)
		changed = true
	if changed:
		queue_redraw()

# ==============================================================================
# ACTIVACIÓN, DESACTIVACIÓN Y GESTIÓN DE MODALES
# ==============================================================================
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_PAUSED, NOTIFICATION_EXIT_TREE:
			_release_active_touches()
		NOTIFICATION_VISIBILITY_CHANGED:
			if not visible:
				_release_active_touches()

func _release_active_touches() -> void:
	var had_focus := _focus_toggled or (InputMap.has_action("focus") and Input.is_action_pressed("focus"))
	_reset_left_stick()
	_reset_right_stick()
	_release_focus_action()
	_release_pulse_action()
	if had_focus:
		focus_toggled.emit(false)
	_pause_pressed = false
	_pause_touch_id = -1
	if visible and is_active:
		_target_left_alpha = resting_alpha
		_target_right_alpha = resting_alpha
	queue_redraw()

func deactivate() -> void:
	is_active = false
	_target_left_alpha = 0.0
	_target_right_alpha = 0.0
	_left_alpha = 0.0
	_right_alpha = 0.0
	var had_focus := _focus_toggled
	_reset_left_stick()
	_reset_right_stick()
	_release_focus_action()
	_release_pulse_action()
	if had_focus:
		focus_toggled.emit(false)
	_pause_pressed = false
	_pause_touch_id = -1
	queue_redraw()

func activate() -> void:
	is_active = true
	if is_touch_device() or _force_visible:
		visible = true
	_target_left_alpha = resting_alpha if visible else 0.0
	_target_right_alpha = resting_alpha if visible else 0.0
	queue_redraw()

# ==============================================================================
# MANEJO DE ENTRADA CON COMPUERTA ESTRICTA ANTI-DOBLE EVENTO
# ==============================================================================
func _is_gameplay_key(keycode: int) -> bool:
	return keycode in [
		KEY_W, KEY_A, KEY_S, KEY_D,
		KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT,
		KEY_SPACE, KEY_SHIFT, KEY_I, KEY_J, KEY_K, KEY_L
	]

func _unhandled_input(event: InputEvent) -> void:
	# Atajo de depuración en PC (F1 conmuta visibilidad)
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_F1:
			_force_visible = not _force_visible
			visible = _force_visible
			if not visible:
				_release_active_touches()
			_target_left_alpha = resting_alpha if visible else 0.0
			_target_right_alpha = resting_alpha if visible else 0.0
			touch_mode_changed.emit(visible)
			queue_redraw()
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
			return

	if not is_active:
		return
	if is_inside_tree():
		var tree := get_tree()
		if tree and tree.paused:
			return

	# Auto-promoción dinámica solo ante toque físico real (ignora emulación de ratón en PC)
	if event is InputEventScreenTouch and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		if not visible or not _has_native_touch:
			_has_native_touch = true
			visible = true
			_target_left_alpha = resting_alpha
			_target_right_alpha = resting_alpha
			_update_positions()
			touch_mode_changed.emit(true)

	# Si un jugador en dispositivo híbrido o Android cambia a mando o teclado físico, ocultar joysticks virtuales
	if visible and not _force_visible:
		var switched_to_physical: bool = (
			(event is InputEventJoypadButton and event.is_pressed())
			or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.35)
			or (event is InputEventKey and event.is_pressed() and _is_gameplay_key((event as InputEventKey).keycode))
		)
		if switched_to_physical:
			_release_active_touches()
			visible = false
			_target_left_alpha = 0.0
			_target_right_alpha = 0.0
			touch_mode_changed.emit(false)
			queue_redraw()
			return

	if not visible:
		return

	# 1. Eventos Táctiles Nativos
	if event is InputEventScreenTouch:
		# Manejo de cancelaciones del SO (llamadas, notificaciones, gestos)
		if event.is_canceled():
			_cancel_touch(event.index)
			return
		_handle_touch(event.index, event.pressed, event.position)

	elif event is InputEventScreenDrag:
		_handle_drag(event.index, event.position)

	# 2. Eventos de Ratón (Solo permitidos en PC sin pantalla táctil y sin emulación activa)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _has_native_touch or _emulate_touch_from_mouse:
			return
		_handle_touch(0, event.pressed, event.position)

	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		if _has_native_touch or _emulate_touch_from_mouse:
			return
		_handle_drag(0, event.position)

func _cancel_touch(touch_id: int) -> void:
	if touch_id == _left_touch_id:
		_target_left_alpha = resting_alpha
		_reset_left_stick()
	elif touch_id == _right_touch_id:
		_target_right_alpha = resting_alpha
		_reset_right_stick()
	elif touch_id == _focus_touch_id:
		var had_focus := _focus_toggled
		_release_focus_action()
		if had_focus:
			focus_toggled.emit(false)
		queue_redraw()
	elif touch_id == _pulse_touch_id:
		_release_pulse_action()
		queue_redraw()
	elif touch_id == _pause_touch_id:
		_pause_touch_id = -1
		_pause_pressed = false
		queue_redraw()

func _handle_touch(touch_id: int, pressed: bool, pos: Vector2) -> void:
	var vp_size := _get_safe_viewport_size()
	var hud_insets := MobileControls.get_safe_insets_for_viewport(get_viewport(), 6.0) if is_inside_tree() else Rect2(6, 6, 6, 6)
	var vp_half_x := vp_size.x * 0.5

	if pressed:
		# 1. Botón de Pausa superior derecho (icono flotante o botón del HUD)
		var pause_hit := false
		if show_pause_button:
			pause_hit = pos.distance_squared_to(_pause_pos) <= 1600.0 # Radio 40px
		else:
			# Zona de respaldo táctil alineada exactamente con BtnPauseHud
			var hud_pause_rect := Rect2(vp_size.x - hud_insets.size.x - 104.0, hud_insets.position.y, 104.0 + hud_insets.size.x, 52.0)
			pause_hit = hud_pause_rect.has_point(pos)

		if pause_hit:
			_pause_touch_id = touch_id
			_pause_pressed = true
			pause_requested.emit()
			queue_redraw()
			return

		# Ignorar toques sobre la franja superior del HUD
		if pos.y < hud_insets.position.y + 46.0:
			return

		# 2. Botón táctil de Modo Enfoque y Botón Pulso de Empatía
		if show_focus_button and _focus_touch_id == -1 and pos.x >= vp_half_x and pos.distance_squared_to(_focus_pos) <= FOCUS_HIT_RADIUS_SQ:
			_focus_touch_id = touch_id
			_focus_pressed = true
			_focus_press_ms = Time.get_ticks_msec()
			_focus_toggled = not _focus_toggled
			_sync_focus_action()
			focus_toggled.emit(_focus_toggled)
			queue_redraw()
			return
		if show_focus_button and _pulse_touch_id == -1 and pos.x >= vp_half_x and pos.distance_squared_to(_pulse_pos) <= PULSE_HIT_RADIUS_SQ:
			_pulse_touch_id = touch_id
			_pulse_pressed = true
			_ensure_pulse_action()
			Input.action_press("empathy_pulse")
			queue_redraw()
			return

		# 3. Joystick Izquierdo (Mitad Izquierda)
		if pos.x < vp_half_x and _left_touch_id == -1:
			_left_touch_id = touch_id
			_left_base = _clamp_base_pos(pos, true)
			_left_pos = _left_base
			_target_left_alpha = active_alpha
			# En el primer contacto iniciamos en reposo neutral sin latigazos
			_apply_analog_vector("move_left", "move_right", "move_up", "move_down", Vector2.ZERO)
			queue_redraw()
			return

		# 4. Joystick Derecho (Mitad Derecha - Disparo y Puntería de Virtud)
		if pos.x >= vp_half_x and _right_touch_id == -1:
			_right_touch_id = touch_id
			_right_base = _clamp_base_pos(pos, false)
			_right_pos = _right_base
			_right_pressed = true
			_target_right_alpha = active_alpha
			current_aim_vector = Vector2.ZERO
			if not Input.is_action_pressed("attack"):
				Input.action_press("attack")
			queue_redraw()
			return
	else:
		# Soltar contacto según su índice exclusivo
		if touch_id == _left_touch_id:
			_target_left_alpha = resting_alpha
			_reset_left_stick()
		elif touch_id == _right_touch_id:
			_target_right_alpha = resting_alpha
			_reset_right_stick()
		elif touch_id == _focus_touch_id:
			_focus_touch_id = -1
			_focus_pressed = false
			if _focus_toggled and (Time.get_ticks_msec() - _focus_press_ms) >= FOCUS_HOLD_THRESHOLD_MS:
				_focus_toggled = false
				_sync_focus_action()
				focus_toggled.emit(false)
			queue_redraw()
		elif touch_id == _pulse_touch_id:
			_release_pulse_action()
			queue_redraw()
		elif touch_id == _pause_touch_id:
			_pause_touch_id = -1
			_pause_pressed = false
			queue_redraw()

func _clamp_base_pos(pos: Vector2, is_left: bool) -> Vector2:
	var vp_size := _get_safe_viewport_size()
	var insets := get_safe_insets()
	var hud_insets := MobileControls.get_safe_insets_for_viewport(get_viewport(), 6.0) if is_inside_tree() else Rect2(6, 6, 6, 6)
	var min_y := maxf(insets.position.y + 44.0, hud_insets.position.y + 46.0) + joystick_radius
	var max_y := vp_size.y - insets.size.y - joystick_radius
	var clamped_y := clampf(pos.y, minf(min_y, max_y), maxf(min_y, max_y))

	if is_left:
		var min_x := insets.position.x + joystick_radius
		var max_x := (vp_size.x * 0.5) - joystick_radius - 8.0
		return Vector2(clampf(pos.x, minf(min_x, max_x), maxf(min_x, max_x)), clamped_y)
	else:
		var min_x := (vp_size.x * 0.5) + joystick_radius + 8.0
		var max_x := vp_size.x - insets.size.x - joystick_radius
		return Vector2(clampf(pos.x, minf(min_x, max_x), maxf(min_x, max_x)), clamped_y)

func _handle_drag(touch_id: int, pos: Vector2) -> void:
	if touch_id == _left_touch_id:
		_update_left_stick(pos)
		queue_redraw()
	elif touch_id == _right_touch_id:
		_update_right_stick(pos)
		queue_redraw()

# ==============================================================================
# DINÁMICA ANALÓGICA Y COMPENSACIÓN RADIAL
# ==============================================================================
func _update_left_stick(pos: Vector2) -> void:
	var diff := pos - _left_base
	var dist := diff.length()
	if dist > joystick_radius:
		if dist > joystick_radius * max_drag_ratio:
			var new_base := pos - diff.normalized() * (joystick_radius * max_drag_ratio)
			_left_base = _clamp_base_pos(new_base, true)
			diff = pos - _left_base
		diff = diff.normalized() * joystick_radius
	_left_pos = _left_base + diff

	var raw_ratio := diff.length() / joystick_radius
	if raw_ratio < deadzone:
		_apply_analog_vector("move_left", "move_right", "move_up", "move_down", Vector2.ZERO)
	else:
		var remapped_mag := (raw_ratio - deadzone) / (1.0 - deadzone)
		var dir := diff.normalized()
		_apply_analog_vector("move_left", "move_right", "move_up", "move_down", dir * remapped_mag)

func _update_right_stick(pos: Vector2) -> void:
	var diff := pos - _right_base
	var dist := diff.length()
	if dist > joystick_radius:
		if dist > joystick_radius * max_drag_ratio:
			var new_base := pos - diff.normalized() * (joystick_radius * max_drag_ratio)
			_right_base = _clamp_base_pos(new_base, false)
			diff = pos - _right_base
		diff = diff.normalized() * joystick_radius
	_right_pos = _right_base + diff

	var raw_ratio := diff.length() / joystick_radius
	if raw_ratio >= deadzone:
		var remapped_mag := (raw_ratio - deadzone) / (1.0 - deadzone)
		var dir := diff.normalized()
		current_aim_vector = dir
		_apply_analog_vector("aim_left", "aim_right", "aim_up", "aim_down", dir * remapped_mag)
	else:
		current_aim_vector = Vector2.ZERO
		Input.action_release("aim_left")
		Input.action_release("aim_right")
		Input.action_release("aim_up")
		Input.action_release("aim_down")

	aim_vector_changed.emit(current_aim_vector)

	# Disparo continuo de virtudes mientras el pulgar esté en contacto
	if not Input.is_action_pressed("attack"):
		Input.action_press("attack")

func _apply_analog_vector(neg_x: String, pos_x: String, neg_y: String, pos_y: String, vec: Vector2) -> void:
	_apply_single_axis(neg_x, pos_x, vec.x)
	_apply_single_axis(neg_y, pos_y, vec.y)

func _apply_single_axis(neg_action: String, pos_action: String, strength: float) -> void:
	var abs_val := absf(strength)
	if abs_val <= 0.001:
		Input.action_release(neg_action)
		Input.action_release(pos_action)
		return

	# Remapeo compensatorio del deadzone interno de Godot (d = 0.5)
	# Permite una respuesta perfectamente lineal u -> [0, 1] en Player.gd
	var compensated_strength := clampf(_inputmap_deadzone + abs_val * (1.0 - _inputmap_deadzone), 0.0, 1.0)

	if strength < 0.0:
		Input.action_press(neg_action, compensated_strength)
		Input.action_release(pos_action)
	else:
		Input.action_press(pos_action, compensated_strength)
		Input.action_release(neg_action)

func _reset_left_stick() -> void:
	_left_touch_id = -1
	_left_pos = _left_base
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
	if not _focus_toggled and InputMap.has_action("focus"):
		Input.action_release("focus")
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

# ==============================================================================
# RENDERIZADO VECTORIAL 2D (ESTÉTICA COBAEM PIXEL-PERFECT)
# ==============================================================================
func _draw() -> void:
	if not visible or not is_active:
		return

	# 1. JOYSTICK IZQUIERDO: MOVIMIENTO (VERDE ESMERALDA COBAEM)
	if _left_alpha > 0.005:
		var la := _left_alpha
		var left_base_bg := Color(0.0, 0.38, 0.25, 0.40 * la)
		var left_border := Color(0.25, 0.92, 0.55, 0.92 * la)
		var left_border_inner := Color(1.0, 0.88, 0.35, 0.65 * la)

		draw_circle(_left_base, joystick_radius, left_base_bg)
		draw_arc(_left_base, joystick_radius, 0.0, TAU, 36, left_border, 2.5)
		draw_arc(_left_base, joystick_radius - 3.0, 0.0, TAU, 36, left_border_inner, 1.0)

		# Muescas cardinales en cruz
		var guide_col := Color(1.0, 1.0, 1.0, 0.45 * la)
		draw_line(_left_base + Vector2(-16, 0), _left_base + Vector2(-6, 0), guide_col, 2.0)
		draw_line(_left_base + Vector2(6, 0), _left_base + Vector2(16, 0), guide_col, 2.0)
		draw_line(_left_base + Vector2(0, -16), _left_base + Vector2(0, -6), guide_col, 2.0)
		draw_line(_left_base + Vector2(0, 6), _left_base + Vector2(0, 16), guide_col, 2.0)

		# Línea conectora entre base y knob
		if _left_pos != _left_base:
			draw_line(_left_base, _left_pos, Color(0.3, 0.95, 0.6, 0.55 * la), 2.5)

		# Knob móvil
		var left_knob_bg := Color(0.18, 0.82, 0.42, 0.95 * la)
		var left_knob_border := Color(1.0, 1.0, 1.0, 0.98 * la)
		draw_circle(_left_pos, knob_radius, left_knob_bg)
		draw_arc(_left_pos, knob_radius, 0.0, TAU, 28, left_knob_border, 2.0)
		draw_circle(_left_pos, 4.0, Color(1.0, 1.0, 1.0, la))

	# 2. JOYSTICK DERECHO: VIRTUD / DISPARO 360° (GUINDA / ORO COBAEM)
	if _right_alpha > 0.005:
		var ra := _right_alpha
		var right_base_bg := Color(0.41, 0.11, 0.20, 0.45 * ra)
		var right_border := Color(1.0, 0.85, 0.35, 0.92 * ra)
		var right_border_inner := Color(0.9, 0.3, 0.45, 0.65 * ra)

		draw_circle(_right_base, joystick_radius, right_base_bg)
		draw_arc(_right_base, joystick_radius, 0.0, TAU, 36, right_border, 2.5)
		draw_arc(_right_base, joystick_radius - 3.0, 0.0, TAU, 36, right_border_inner, 1.0)

		# Flecha de puntería direccional en 360°
		if current_aim_vector != Vector2.ZERO:
			var arrow_start := _right_base + current_aim_vector * (joystick_radius * 0.35)
			var arrow_end := _right_base + current_aim_vector * (joystick_radius + 20.0)
			draw_line(arrow_start, arrow_end, Color(1.0, 0.92, 0.4, 0.95 * ra), 3.5)
			var perp := Vector2(-current_aim_vector.y, current_aim_vector.x) * 7.5
			var tip_left := arrow_end - current_aim_vector * 12.0 + perp
			var tip_right := arrow_end - current_aim_vector * 12.0 - perp
			draw_colored_polygon(PackedVector2Array([arrow_end, tip_left, tip_right]), Color(1.0, 0.95, 0.5, 0.95 * ra))

		# Línea conectora hacia el knob
		if _right_pos != _right_base:
			draw_line(_right_base, _right_pos, Color(1.0, 0.8, 0.25, 0.55 * ra), 2.5)

		# Knob derecho
		var right_knob_bg := Color(1.0, 0.72, 0.18, 0.95 * ra)
		var right_knob_border := Color(1.0, 0.96, 0.85, 0.98 * ra)
		draw_circle(_right_pos, knob_radius, right_knob_bg)
		draw_arc(_right_pos, knob_radius, 0.0, TAU, 28, right_knob_border, 2.0)

		# Rótulo institucional "VIRTUD"
		var font := ThemeDB.fallback_font
		if font:
			var font_size := 11
			var label_text := "VIRTUD"
			var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			draw_string(font, _right_pos + Vector2(-text_size.x * 0.5, text_size.y * 0.32), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.35, 0.08, 0.12, ra))

	# 3. BOTÓN TÁCTIL DE MODO ENFOQUE (FOCUS / MICRO-DESPLAZAMIENTO DANMAKU)
	if show_focus_button and (_right_alpha > 0.005 or _focus_toggled or _focus_pressed):
		var fa := active_alpha if (_focus_toggled or _focus_pressed) else maxf(_right_alpha, resting_alpha)
		var focus_bg := Color(0.76, 0.16, 0.28, 0.90 * fa) if _focus_toggled else Color(0.18, 0.14, 0.24, 0.50 * fa)
		var focus_border := Color(1.0, 0.90, 0.42, 0.98 * fa) if _focus_toggled else Color(0.95, 0.72, 0.42, 0.85 * fa)
		draw_circle(_focus_pos, FOCUS_BUTTON_RADIUS, focus_bg)
		draw_arc(_focus_pos, FOCUS_BUTTON_RADIUS, 0.0, TAU, 32, focus_border, 2.2 if _focus_toggled else 1.5)
		if _focus_toggled:
			draw_arc(_focus_pos, FOCUS_BUTTON_RADIUS - 4.0, 0.0, TAU, 24, Color(1.0, 0.40, 0.50, 0.85 * fa), 1.2)
		var focus_font := ThemeDB.fallback_font
		if focus_font:
			var f_size := 9
			var f_txt := "FOCUS"
			var f_sz := focus_font.get_string_size(f_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, f_size)
			var f_col := Color(1.0, 0.96, 0.85, fa) if _focus_toggled else Color(1.0, 0.88, 0.68, fa)
			draw_string(focus_font, _focus_pos + Vector2(-f_sz.x * 0.5, f_sz.y * 0.30), f_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, f_size, f_col)

		# 3b. Botón táctil Pulso de Empatía ("PULSO")
		var pa := active_alpha if _pulse_pressed else maxf(_right_alpha, resting_alpha)
		var pulse_bg := Color(0.18, 0.58, 0.72, 0.90 * pa) if _pulse_pressed else Color(0.12, 0.24, 0.34, 0.55 * pa)
		var pulse_border := Color(0.55, 0.96, 1.0, 0.96 * pa)
		draw_circle(_pulse_pos, PULSE_BUTTON_RADIUS, pulse_bg)
		draw_arc(_pulse_pos, PULSE_BUTTON_RADIUS, 0.0, TAU, 28, pulse_border, 2.0 if _pulse_pressed else 1.5)
		if focus_font:
			var p_txt := "PULSO"
			var p_sz := focus_font.get_string_size(p_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 8)
			draw_string(focus_font, _pulse_pos + Vector2(-p_sz.x * 0.5, p_sz.y * 0.30), p_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(0.90, 0.98, 1.0, pa))

	# 4. BOTÓN DE PAUSA ERGONÓMICO SUPERIOR DERECHO (Mínimo 44x44 dp)
	if show_pause_button and is_inside_tree() and get_tree() and not get_tree().paused:
		var pause_bg := Color(0.41, 0.11, 0.20, 0.85) if not _pause_pressed else Color(0.68, 0.16, 0.28, 0.98)
		var pause_border := Color(1.0, 0.85, 0.35, 0.95)
		draw_circle(_pause_pos, 22.0, pause_bg)
		draw_arc(_pause_pos, 22.0, 0.0, TAU, 32, pause_border, 2.0)

		# Barras verticales doradas de pausa
		var bar_col := Color(1.0, 0.92, 0.75, 1.0)
		draw_rect(Rect2(_pause_pos.x - 6.0, _pause_pos.y - 7.0, 3.5, 14.0), bar_col)
		draw_rect(Rect2(_pause_pos.x + 2.5, _pause_pos.y - 7.0, 3.5, 14.0), bar_col)
