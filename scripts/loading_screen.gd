extends Control
class_name LoadingScreen

## Pantalla de Carga Institucional (Loading Screen)
## Colegio de Bachilleres del Estado de México — CEMSaD 22 ENTHAVI
## Incluye barra de progreso reactiva, carrusel de frases formativas y logos oficiales.
## 100% compatible con dispositivos móviles (Android/iOS), navegadores web y escritorio
## sin riesgos de interbloqueos (deadlocks) de hilos ni estancamientos.

@export var target_scene: String = "res://scenes/main.tscn"
@export var min_display_time: float = 1.2

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var percent_label: Label = %PercentLabel
@onready var status_label: Label = %StatusLabel
@onready var tip_label: Label = %TipLabel
@onready var tip_panel: PanelContainer = %TipPanel
@onready var logo_rect: TextureRect = %LogoRect
@onready var prompt_label: Label = %PromptLabel

const TIPS: Array[String] = [
	"«La educación es el arma más poderosa que puedes usar para cambiar el mundo.» — Nelson Mandela",
	"«K'öte m'ui (Respeto mutuo): El valor de escuchar y cuidar a quien comparte tu espacio escolar.» — Sabiduría Otomí de Temoaya",
	"«La empatía no es solo entender al otro, es actuar para transformar su realidad.» — Carl Rogers",
	"«Tlamatiliztli (Sabiduría y Rectitud): El conocimiento solo tiene sentido si construye una sociedad justa.» — Filosofía Náhuatl",
	"«En el COBAEM, la honestidad y el respeto mutuo son la base de nuestra convivencia cotidiana.» — CEMSaD 22 ENTHAVI",
	"«El juego limpio en la cancha de usos múltiples refleja nuestra integridad dentro y fuera del aula.» — Valores COBAEM",
	"«Cuidar los laboratorios, aulas y áreas verdes es valorar el esfuerzo de toda nuestra comunidad escolar.» — Identidad CEMSaD 22",
	"«El diálogo sereno y asertivo es la herramienta principal para la resolución pacífica de conflictos.» — Cultura de Paz",
	"«La responsabilidad de hoy forja a las y los líderes transformadores de nuestra entidad mexiquense.» — COBAEM"
]

const STATUS_MESSAGES: Array[String] = [
	"Cargando infraestructura del plantel CEMSaD 22...",
	"Generando baldosas a escala real (1 metro = 40 px)...",
	"Sincronizando cotas arquitectónicas del CAD escolar...",
	"Cargando virtudes cívicas y antivalores formativos...",
	"Optimizando controles táctiles y de escritorio...",
	"¡Entorno verificado! Ingresando al plantel..."
]

var _preloaded_scene: PackedScene = null
var _threaded_requested: bool = false
var _elapsed: float = 0.0
var _tip_timer: float = 0.0
var _tip_index: int = 0
var _can_proceed: bool = false
var _current_progress: float = 0.0
var _transition_triggered: bool = false
var _last_input_was_gamepad: bool = false
var _prompt_tween: Tween = null
var on_complete_callback: Callable = Callable()
var custom_status_messages: Array[String] = []

func _ensure_nodes() -> void:
	if progress_bar == null:
		progress_bar = get_node_or_null("%ProgressBar")
		if progress_bar == null:
			progress_bar = find_child("ProgressBar", true, false) as ProgressBar
	if percent_label == null:
		percent_label = get_node_or_null("%PercentLabel")
		if percent_label == null:
			percent_label = find_child("PercentLabel", true, false) as Label
	if status_label == null:
		status_label = get_node_or_null("%StatusLabel")
		if status_label == null:
			status_label = find_child("StatusLabel", true, false) as Label
	if tip_label == null:
		tip_label = get_node_or_null("%TipLabel")
		if tip_label == null:
			tip_label = find_child("TipLabel", true, false) as Label
	if tip_panel == null:
		tip_panel = get_node_or_null("%TipPanel")
		if tip_panel == null:
			tip_panel = find_child("TipPanel", true, false) as PanelContainer
	if logo_rect == null:
		logo_rect = get_node_or_null("%LogoRect")
		if logo_rect == null:
			logo_rect = find_child("LogoRect", true, false) as TextureRect
	if prompt_label == null:
		prompt_label = get_node_or_null("%PromptLabel")
		if prompt_label == null:
			prompt_label = find_child("PromptLabel", true, false) as Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_nodes()
	_setup_ui()
	_adjust_layout_for_viewport()
	if is_inside_tree() and get_viewport():
		if not get_viewport().size_changed.is_connected(_adjust_layout_for_viewport):
			get_viewport().size_changed.connect(_adjust_layout_for_viewport)
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_start_loading()

func _exit_tree() -> void:
	if Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.disconnect(_on_joy_connection_changed)
	if _prompt_tween and _prompt_tween.is_valid():
		_prompt_tween.kill()

func _setup_ui() -> void:
	# Evitar que el fondo ColorRect bloquee toques o clics para acelerar la carga
	var bg := get_node_or_null("Background") as Control
	if bg:
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := get_node_or_null("Center") as Control
	if center:
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if logo_rect:
		var logo_tex = load("res://assets/logos/cobaem-logo.jpeg")
		if logo_tex:
			logo_rect.texture = logo_tex

	if progress_bar:
		progress_bar.value = 0.0
	if percent_label:
		percent_label.text = "0%"
	if prompt_label:
		prompt_label.visible = false
		_update_prompt_text()

	_tip_index = randi() % TIPS.size()
	_update_tip_text(false)

func _adjust_layout_for_viewport() -> void:
	if not is_inside_tree() or get_viewport() == null:
		return
	var vp_size := get_viewport().get_visible_rect().size
	var insets := MobileControls.get_safe_insets_for_viewport(get_viewport(), 12.0)
	var avail_w := maxf(280.0, vp_size.x - insets.position.x - insets.size.x - 24.0)
	var vbox_node := get_node_or_null("Center/VBox") as Control
	if vbox_node:
		vbox_node.custom_minimum_size.x = minf(580.0, avail_w)
	if tip_panel:
		tip_panel.custom_minimum_size.x = minf(560.0, avail_w)
	if tip_label:
		tip_label.custom_minimum_size.x = minf(520.0, maxf(240.0, avail_w - 40.0))

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_update_prompt_text()

func _update_prompt_text() -> void:
	if prompt_label == null:
		return
	if _last_input_was_gamepad or (not MobileControls.is_touch_device() and not Input.get_connected_joypads().is_empty()):
		prompt_label.text = "Pulsa A o cualquier botón para continuar"
	elif MobileControls.is_touch_device():
		prompt_label.text = "Toca la pantalla para continuar"
	else:
		prompt_label.text = "¡Listo! Ingresando al plantel escolar..."

func _start_loading() -> void:
	if on_complete_callback.is_valid():
		return
	if ResourceLoader.exists(target_scene):
		var err := ResourceLoader.load_threaded_request(target_scene)
		if err == OK:
			_threaded_requested = true
		else:
			_preloaded_scene = load(target_scene) as PackedScene

func _process(delta: float) -> void:
	_elapsed += delta
	_tip_timer += delta

	# Rotación del carrusel de frases formativas cada 4.0 segundos
	if _tip_timer >= 4.0:
		_tip_timer = 0.0
		_tip_index = (_tip_index + 1) % TIPS.size()
		_update_tip_text(true)

	var real_ratio := 100.0
	if _threaded_requested and _preloaded_scene == null:
		var prog := []
		var status := ResourceLoader.load_threaded_get_status(target_scene, prog)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_preloaded_scene = ResourceLoader.load_threaded_get(target_scene) as PackedScene
			real_ratio = 100.0
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			real_ratio = clampf(float(prog[0]) * 100.0, 10.0, 95.0) if not prog.is_empty() else 50.0
		else:
			_threaded_requested = false
			if ResourceLoader.exists(target_scene):
				_preloaded_scene = load(target_scene) as PackedScene

	var time_ratio := clampf((_elapsed / maxf(0.2, min_display_time)) * 100.0, 0.0, 100.0)
	var target_pct := minf(time_ratio, real_ratio) if _threaded_requested and _preloaded_scene == null else time_ratio
	_current_progress = move_toward(_current_progress, target_pct, delta * 95.0)

	if progress_bar:
		progress_bar.value = _current_progress
	if percent_label:
		percent_label.text = "%d%%" % int(_current_progress)

	# Mensajes de estado dinámicos conforme avanza la barra
	var messages: Array[String] = custom_status_messages if not custom_status_messages.is_empty() else STATUS_MESSAGES
	var status_idx := clampi(int((_current_progress / 100.0) * (messages.size() - 1)), 0, messages.size() - 1)
	if status_label:
		status_label.text = messages[status_idx]

	var ready_in_mem := on_complete_callback.is_valid() or _preloaded_scene != null or not _threaded_requested
	# Al completar el 100% y el tiempo mínimo de lectura
	if ready_in_mem and _current_progress >= 99.5 and _elapsed >= min_display_time and not _can_proceed:
		_can_proceed = true
		_on_loading_completed()

func _update_tip_text(animate: bool) -> void:
	if not tip_label:
		return
	if animate:
		var tw := create_tween()
		tw.tween_property(tip_label, "modulate:a", 0.0, 0.2)
		tw.tween_callback(func() -> void:
			tip_label.text = TIPS[_tip_index]
		)
		tw.tween_property(tip_label, "modulate:a", 1.0, 0.3)
	else:
		tip_label.text = TIPS[_tip_index]

func _on_loading_completed() -> void:
	if prompt_label:
		_update_prompt_text()
		prompt_label.visible = true
		if _prompt_tween and _prompt_tween.is_valid():
			_prompt_tween.kill()
		_prompt_tween = create_tween().set_loops()
		_prompt_tween.tween_property(prompt_label, "modulate:a", 0.3, 0.5)
		_prompt_tween.tween_property(prompt_label, "modulate:a", 1.0, 0.5)

	# Transición automática suave tras un breve instante si el nodo está en el árbol de escenas
	if is_inside_tree() and get_tree():
		get_tree().create_timer(0.35).timeout.connect(_transition_to_target)
	else:
		_transition_to_target()

func _gui_input(event: InputEvent) -> void:
	if _can_proceed and not _transition_triggered:
		var is_real_mouse: bool = event is InputEventMouseButton and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION
		var is_real_touch: bool = event is InputEventScreenTouch and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION
		if is_real_mouse or is_real_touch:
			accept_event()
			_transition_to_target()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		_last_input_was_gamepad = true
		_update_prompt_text()
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		_last_input_was_gamepad = true
		_update_prompt_text()
	elif (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION):
		_last_input_was_gamepad = false
		_update_prompt_text()

	if _can_proceed and not _transition_triggered:
		var should_proceed: bool = (
			(event is InputEventKey and event.is_pressed() and not event.is_echo())
			or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed and event.device != InputEvent.DEVICE_ID_EMULATION)
			or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed and event.device != InputEvent.DEVICE_ID_EMULATION)
			or (event is InputEventJoypadButton and event.is_pressed() and not event.is_echo())
			or event.is_action_pressed("ui_accept")
			or event.is_action_pressed("attack")
		)
		if should_proceed:
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
			_transition_to_target()

func _transition_to_target() -> void:
	if _transition_triggered:
		return
	_transition_triggered = true
	set_process(false)

	if on_complete_callback.is_valid():
		var cb := on_complete_callback
		on_complete_callback = Callable()
		if is_inside_tree():
			var transition_cb = get_node_or_null("/root/SceneTransition")
			if transition_cb and transition_cb.has_method("transition_call"):
				if transition_cb.is_busy:
					await transition_cb.transition_finished
				if is_inside_tree() and transition_cb.is_inside_tree():
					transition_cb.transition_call(func():
						cb.call()
						if is_instance_valid(self):
							queue_free()
					)
					return
		cb.call()
		if is_instance_valid(self):
			queue_free()
		return

	if is_inside_tree() and get_tree():
		var transition = get_node_or_null("/root/SceneTransition")
		if transition and transition.has_method("change_scene"):
			if transition.is_busy:
				await transition.transition_finished
			if is_inside_tree() and transition.is_inside_tree():
				if _preloaded_scene != null and transition.has_method("transition_call"):
					transition.transition_call(func(): get_tree().change_scene_to_packed(_preloaded_scene))
				else:
					transition.change_scene(target_scene)
				return

		if _preloaded_scene != null:
			get_tree().change_scene_to_packed(_preloaded_scene)
		else:
			get_tree().change_scene_to_file(target_scene)
