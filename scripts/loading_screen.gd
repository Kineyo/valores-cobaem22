extends Control
class_name LoadingScreen

## Pantalla de Carga Institucional (Loading Screen)
## Colegio de Bachilleres del Estado de México — CEMSaD 22 ENTHAVI
## Incluye barra de progreso reactiva, carrusel de frases formativas y logos oficiales.
## Compatible con dispositivos móviles (Android/iOS), navegadores web y escritorio.

@export var target_scene: String = "res://scenes/main.tscn"
@export var min_display_time: float = 2.2

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

var _loading_progress: Array = []
var _elapsed: float = 0.0
var _tip_timer: float = 0.0
var _tip_index: int = 0
var _is_loaded: bool = false
var _can_proceed: bool = false
var _target_progress: float = 0.0
var _current_progress: float = 0.0
var _transition_triggered: bool = false

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
	_start_loading()

func _setup_ui() -> void:
	if logo_rect:
		var logo_tex = load("res://assets/logos/cobaem-logo.png")
		if logo_tex:
			logo_rect.texture = logo_tex

	if progress_bar:
		progress_bar.value = 0.0
	if percent_label:
		percent_label.text = "0%"
	if prompt_label:
		prompt_label.visible = false

	_tip_index = randi() % TIPS.size()
	_update_tip_text(false)

func _start_loading() -> void:
	_loading_progress = [0.0]
	var has_threads := OS.has_feature("threads") and not OS.has_feature("web")

	if not has_threads:
		# En navegadores web o plataformas sin hilos en segundo plano, cargar directamente
		# para evitar bloqueos en 0% por falta de WorkerThreadPool
		var res = ResourceLoader.load(target_scene)
		if res != null:
			_is_loaded = true
			_target_progress = 100.0
	else:
		var err := ResourceLoader.load_threaded_request(target_scene)
		if err != OK:
			_is_loaded = true
			_target_progress = 100.0

func _process(delta: float) -> void:
	_elapsed += delta
	_tip_timer += delta

	# Rotación del carrusel de frases formativas cada 4.0 segundos
	if _tip_timer >= 4.0:
		_tip_timer = 0.0
		_tip_index = (_tip_index + 1) % TIPS.size()
		_update_tip_text(true)

	# Verificación de carga en segundo plano
	if not _is_loaded:
		var status := ResourceLoader.load_threaded_get_status(target_scene, _loading_progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED or status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_target_progress = 100.0
			_is_loaded = true
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if _loading_progress.size() > 0 and _loading_progress[0] > 0.0:
				_target_progress = maxf(_target_progress, _loading_progress[0] * 100.0)
			# Salvaguarda: si ha transcurrido más del 60% del tiempo mínimo o 1.2s, forzar resolución
			if _elapsed >= 1.2:
				var res = ResourceLoader.load_threaded_get(target_scene)
				if res != null:
					_target_progress = 100.0
					_is_loaded = true

	# Progreso fluido y continuo que garantiza tiempo de lectura de frases sin estancarse en 0%
	var time_progress := clampf((_elapsed / min_display_time) * 100.0, 0.0, 100.0)
	var max_allowed := 100.0 if _is_loaded else 92.0
	var simulated_target := minf(time_progress, max_allowed)
	var final_goal := maxf(simulated_target, _target_progress)
	if _is_loaded and _elapsed >= min_display_time:
		final_goal = 100.0

	_current_progress = move_toward(_current_progress, final_goal, delta * 80.0)
	if progress_bar:
		progress_bar.value = _current_progress
	if percent_label:
		percent_label.text = "%d%%" % int(_current_progress)

	# Mensajes de estado dinámicos
	var status_idx := clampi(int((_current_progress / 100.0) * (STATUS_MESSAGES.size() - 1)), 0, STATUS_MESSAGES.size() - 1)
	if status_label:
		status_label.text = STATUS_MESSAGES[status_idx]

	# Al completar el 100% y el tiempo mínimo de lectura
	if _current_progress >= 99.5 and _elapsed >= min_display_time and not _can_proceed:
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
		prompt_label.visible = true
		var tw := create_tween().set_loops()
		tw.tween_property(prompt_label, "modulate:a", 0.3, 0.5)
		tw.tween_property(prompt_label, "modulate:a", 1.0, 0.5)

	# Transición automática suave tras un breve instante si el nodo está en el árbol de escenas
	if is_inside_tree() and get_tree():
		get_tree().create_timer(0.35).timeout.connect(_transition_to_target)
	else:
		_transition_to_target()

func _unhandled_input(event: InputEvent) -> void:
	if _can_proceed and not _transition_triggered:
		if (event is InputEventKey and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
			_transition_to_target()

func _transition_to_target() -> void:
	if _transition_triggered:
		return
	_transition_triggered = true
	set_process(false)

	if is_inside_tree() and get_tree():
		var transition = get_node_or_null("/root/SceneTransition")
		if transition and transition.has_method("change_scene"):
			if transition.is_busy:
				await transition.transition_finished
			if is_inside_tree() and transition.is_inside_tree():
				transition.change_scene(target_scene)
				return
		get_tree().change_scene_to_file(target_scene)
