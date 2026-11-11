extends Node

## Autoload: Fx
## Sistema de efectos de retroalimentación ("game feel"):
## Sacudida de cámara (shake), hitstop, textos flotantes y partículas de impacto.

const FONT_OUTLINE := Color(0.07, 0.06, 0.13, 1.0)

var _shake_strength: float = 0.0
var _shake_decay: float = 0.0
var _camera: Camera2D
var _fade_gradient: Gradient
var _hitstop_id: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_gradient = Gradient.new()
	_fade_gradient.set_color(0, Color(1, 1, 1, 1))
	_fade_gradient.set_color(1, Color(1, 1, 1, 0))

func _process(delta: float) -> void:
	if _shake_strength <= 0.0:
		return
	if not is_instance_valid(_camera):
		_shake_strength = 0.0
		_camera = null
		return
	_shake_strength = maxf(0.0, _shake_strength - _shake_decay * delta)
	# Redondeo a píxeles enteros para mantener la coherencia del estilo pixel art
	_camera.offset = Vector2(
		randf_range(-_shake_strength, _shake_strength),
		randf_range(-_shake_strength, _shake_strength)
	).round()
	if _shake_strength <= 0.0:
		_camera.offset = Vector2.ZERO
		_camera = null

## Aplica sacudida sísmica a la cámara 2D activa
func shake(strength: float = 4.0, duration: float = 0.25) -> void:
	_camera = get_viewport().get_camera_2d()
	if _camera == null:
		return
	if strength >= _shake_strength:
		_shake_strength = strength
		_shake_decay = strength / maxf(duration, 0.01)

## Pausa brevemente la escala de tiempo para acentuar el impacto de un golpe
func hitstop(duration: float = 0.06, time_scale: float = 0.05) -> void:
	_hitstop_id += 1
	var current_id := _hitstop_id
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	if _hitstop_id == current_id:
		Engine.time_scale = 1.0

## Crea un texto flotante emergente con animación ascendente (ej. "¡Respeto!")
func floating_text(parent: Node, pos: Vector2, text: String, color: Color = Color.WHITE, size: int = 14) -> void:
	if parent == null:
		return
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", FONT_OUTLINE)
	label.add_theme_constant_override("outline_size", 5)
	label.z_index = 50
	parent.add_child(label)

	label.reset_size()
	label.pivot_offset = label.size * 0.5
	label.global_position = pos - label.size * 0.5
	label.scale = Vector2(0.4, 0.4)

	var start_y := label.global_position.y
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "global_position:y", start_y - 38.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.55)
	tw.chain().tween_callback(label.queue_free)

## Genera un estallido de partículas pixel art de un solo disparo
func burst(parent: Node, pos: Vector2, color: Color, amount: int = 14, speed: float = 140.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.55
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 420)
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = color
	p.color_ramp = _fade_gradient
	p.z_index = 40
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	# Respaldo seguro como tween hijo de p (se destruye automáticamente si p es liberado)
	p.create_tween().tween_interval(p.lifetime + 0.15).finished.connect(p.queue_free)
