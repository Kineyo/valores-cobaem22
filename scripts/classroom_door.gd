extends Area2D
class_name ClassroomDoor

## Puerta de acceso a salones interiores desde el exterior del plantel CEMSaD 22.
## Permite al jugador entrar al salón de clases correspondiente para limpiarlo de antivalores.

signal player_entered_classroom(classroom_idx: int)

@export var classroom_index: int = 0
@export var classroom_name: String = "Salón de Clases"
@export var is_cleared: bool = false

var _player_inside: bool = false
var _anim_time: float = 0.0

@onready var label: Label = $Label
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	y_sort_enabled = true
	collision_layer = 16
	collision_mask = 2 # Jugador
	if get_node_or_null("CollisionShape2D") == null:
		var col := CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = Vector2(48, 44)
		col.shape = rect_shape
		col.position = Vector2(0, -14)
		add_child(col)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_labels()
	update_state(is_cleared)

func _setup_labels() -> void:
	if label == null:
		label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.40))
		label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.06))
		label.add_theme_constant_override("outline_size", 4)
		label.position = Vector2(-75, -58)
		label.size = Vector2(150, 20)
		add_child(label)

	if status_label == null:
		status_label = Label.new()
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.add_theme_font_size_override("font_size", 9)
		status_label.add_theme_constant_override("outline_size", 3)
		status_label.position = Vector2(-75, -42)
		status_label.size = Vector2(150, 18)
		add_child(status_label)

func update_state(cleared: bool) -> void:
	is_cleared = cleared
	if label:
		label.text = classroom_name
	if status_label:
		if is_cleared:
			status_label.text = "✓ SALÓN LIMPIADO"
			status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
			status_label.add_theme_color_override("font_outline_color", Color(0.05, 0.2, 0.08))
		else:
			status_label.text = "▼ ENTRADA AL SALÓN"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
			status_label.add_theme_color_override("font_outline_color", Color(0.25, 0.05, 0.08))
	queue_redraw()

func _process(delta: float) -> void:
	_anim_time += delta
	if not is_cleared:
		if status_label:
			var pulse := 0.75 + sin(_anim_time * 5.0) * 0.25
			status_label.modulate.a = pulse
		queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true
		if not is_cleared:
			var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
			if fx:
				fx.floating_text(get_parent() if get_parent() else self, global_position + Vector2(0, -70), "¡Entrando al Salón!", Color(1.0, 0.85, 0.3), 13)
			player_entered_classroom.emit(classroom_index)
		else:
			var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
			if fx:
				fx.floating_text(get_parent() if get_parent() else self, global_position + Vector2(0, -60), "Este salón ya está libre de antivalores", Color(0.5, 1.0, 0.6), 11)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false

func _draw() -> void:
	# Marco arquitectónico de puerta institucional en perspectiva 3/4
	var frame_col := Color(0.48, 0.12, 0.20) # Guinda institucional
	var trim_col := Color(0.90, 0.78, 0.35) if not is_cleared else Color(0.35, 0.90, 0.55) # Oro o Verde
	var shadow_col := Color(0.06, 0.08, 0.12, 0.40)

	# Sombra en suelo
	draw_rect(Rect2(-24, 2, 48, 8), shadow_col)

	# Escalón de entrada
	draw_rect(Rect2(-22, -2, 44, 8), Color(0.75, 0.76, 0.80))
	draw_line(Vector2(-22, -2), Vector2(22, -2), Color(0.95, 0.96, 0.98), 1.0)

	# Marco de puerta
	draw_rect(Rect2(-20, -38, 40, 36), frame_col)
	draw_rect(Rect2(-20, -38, 40, 36), trim_col, false, 2.0)

	# Hueco de entrada / umbral oscuro
	var umbral_col := Color(0.10, 0.06, 0.12) if not is_cleared else Color(0.12, 0.25, 0.18)
	draw_rect(Rect2(-16, -34, 32, 32), umbral_col)

	# Flecha animada que señala la entrada si aún no ha sido limpiado
	if not is_cleared:
		var bounce := sin(_anim_time * 6.0) * 3.0
		var arrow_y := -48.0 + bounce
		draw_polygon(PackedVector2Array([
			Vector2(-7, arrow_y),
			Vector2(7, arrow_y),
			Vector2(0, arrow_y + 8)
		]), [Color(1.0, 0.85, 0.25)])
	else:
		# Brillos de estrellas pacíficas
		draw_circle(Vector2(0, -18), 3.0, Color(0.5, 1.0, 0.7, 0.8))
