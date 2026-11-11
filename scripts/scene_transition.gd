extends CanvasLayer

## Autoload: SceneTransition
## Transición de pantalla tipo pixel-art usando shaders/pixel_transition.gdshader.
## Permite cambiar o recargar escenas sin cortes secos:
##   SceneTransition.change_scene("res://scenes/main.tscn")
##   SceneTransition.reload_scene()

signal transition_midpoint
signal transition_finished

const SHADER := preload("res://shaders/pixel_transition.gdshader")

@export var cover_time: float = 0.42
@export var reveal_time: float = 0.42

var is_busy: bool = false

var _rect: ColorRect
var _mat: ShaderMaterial

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_mat = ShaderMaterial.new()
	_mat.shader = SHADER

	_rect = ColorRect.new()
	_rect.material = _mat
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)

	get_viewport().size_changed.connect(_update_screen_size)
	_update_screen_size()

	# Al iniciar el juego, descubre la primera escena con la animación de revelado
	_set_progress(1.0)
	_reveal()

## Inicia la transición y cambia a la escena indicada por ruta
func change_scene(path: String) -> void:
	_run(func() -> void: get_tree().change_scene_to_file(path))

## Inicia la transición y recarga la escena actual
func reload_scene() -> void:
	_run(func() -> void: get_tree().reload_current_scene())

## Ejecuta un callback arbitrario con transición de pantalla
func transition_call(action: Callable) -> void:
	_run(action)

## Cubre la pantalla con el shader, ejecuta la acción (callback) y luego revela la escena
func _run(action: Callable) -> void:
	if is_busy:
		return
	is_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	_mat.set_shader_parameter("reverse", false)
	var tw := create_tween()
	tw.tween_method(_set_progress, 0.0, 1.0, cover_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished

	get_tree().paused = false
	transition_midpoint.emit()
	action.call()
	# Espera dos frames para garantizar que la nueva escena esté renderizada antes de revelar
	await get_tree().process_frame
	await get_tree().process_frame
	_reveal()

## Anima la apertura/destapado del shader
func _reveal() -> void:
	is_busy = true
	_rect.visible = true
	_mat.set_shader_parameter("reverse", true)
	var tw := create_tween()
	tw.tween_method(_set_progress, 1.0, 0.0, reveal_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	_rect.visible = false
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_busy = false
	transition_finished.emit()

func _set_progress(value: float) -> void:
	_rect.visible = value > 0.0
	_mat.set_shader_parameter("progress", value)

func _update_screen_size() -> void:
	_mat.set_shader_parameter("screen_size", get_viewport().get_visible_rect().size)
