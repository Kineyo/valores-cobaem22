extends Level
class_name ClassroomScene

## Controlador de Escena de Salón de Clases (CEMSaD 22 ENTHAVI).
## Permite ejecutar y probar cada salón de forma independiente en Godot (F6)
## o instanciarlo dinámicamente desde el orquestador principal.

@export var classroom_index: int = 0

func _ready() -> void:
	if level_data.is_empty():
		var classrooms := LevelManager.get_classroom_levels()
		if classroom_index >= 0 and classroom_index < classrooms.size():
			setup_level(classrooms[classroom_index])
