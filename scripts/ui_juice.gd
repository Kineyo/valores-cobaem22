extends RefCounted
class_name UiJuice

## Utilidad de microinteracciones ("juice") para botones de interfaz.
## Añade respuesta elástica al posar el ratón, cambiar el foco o pulsar.

static func attach_button(btn: Button, sfx: AudioStreamPlayer = null) -> void:
	if btn == null:
		return
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size * 0.5)
	btn.pivot_offset = btn.size * 0.5

	btn.mouse_entered.connect(func() -> void:
		_scale_to(btn, Vector2(1.06, 1.06), 0.14)
		if sfx:
			sfx.pitch_scale = randf_range(1.25, 1.4)
			sfx.play()
	)
	btn.mouse_exited.connect(func() -> void:
		_scale_to(btn, Vector2.ONE, 0.14)
	)
	btn.focus_entered.connect(func() -> void:
		_scale_to(btn, Vector2(1.05, 1.05), 0.14)
	)
	btn.focus_exited.connect(func() -> void:
		_scale_to(btn, Vector2.ONE, 0.14)
	)
	btn.button_down.connect(func() -> void:
		_scale_to(btn, Vector2(0.94, 0.94), 0.07)
	)
	btn.button_up.connect(func() -> void:
		_scale_to(btn, Vector2(1.06, 1.06), 0.16)
		if sfx:
			sfx.pitch_scale = randf_range(0.95, 1.1)
			sfx.play()
	)

static func _scale_to(control: Control, target: Vector2, duration: float) -> void:
	if not is_instance_valid(control) or not control.is_inside_tree():
		return
	if control.has_meta("_juice_tw"):
		var old_tw: Variant = control.get_meta("_juice_tw")
		if old_tw is Tween and old_tw.is_valid():
			old_tw.kill()
	control.pivot_offset = control.size * 0.5
	var tw := control.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	control.set_meta("_juice_tw", tw)
	tw.tween_property(control, "scale", target, duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
