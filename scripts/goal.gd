extends Area2D
class_name Goal

## Meta / Salida del nivel en perspectiva 3/4.
## Detecta la llegada del jugador y emite la señal player_reached_goal para avanzar.

signal player_reached_goal

@onready var sfx_victory: AudioStreamPlayer = $SFXVictory
@onready var particles: CPUParticles2D = $ConfettiParticles
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var _base_sprite_y: float = sprite.position.y

var already_reached: bool = false
var is_locked: bool = false
var level_ref: Node2D = null
const LOCKED_MSG_COOLDOWN: float = 2.0

var _time: float = 0.0
var _last_locked_msg_time: float = -10.0

func _ready() -> void:
	y_sort_enabled = true
	body_entered.connect(_on_body_entered, CONNECT_DEFERRED)

func set_goal_text(txt: String) -> void:
	if label:
		label.text = txt

func set_locked(locked: bool) -> void:
	is_locked = locked
	if sprite:
		sprite.modulate = Color(0.6, 0.6, 0.75, 0.65) if is_locked else Color.WHITE

func unlock() -> void:
	if not is_locked:
		return
	is_locked = false
	if sprite:
		sprite.modulate = Color(2.0, 2.0, 1.4)
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.5)
	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx:
		fx.floating_text(get_parent() if get_parent() else self, global_position + Vector2(0, -32), "SALIDA DESBLOQUEADA", Color(1.0, 0.92, 0.45), 14)
		fx.burst(get_parent() if get_parent() else self, global_position, Color(1.0, 0.85, 0.35), 14, 120.0)
	if is_inside_tree():
		for body in get_overlapping_bodies():
			if body is Player:
				_on_body_entered(body)
				break

func _process(delta: float) -> void:
	_time += delta
	# Flotación rítmica sutil del icono de meta
	sprite.position.y = _base_sprite_y + roundf(sin(_time * 2.2) * 3.0)

func _on_body_entered(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	if body is Player:
		if level_ref != null and "has_classroom" in level_ref and level_ref.has_classroom and not level_ref.is_classroom_cleared:
			if _time - _last_locked_msg_time >= LOCKED_MSG_COOLDOWN:
				_last_locked_msg_time = _time
				var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
				if fx:
					fx.shake(2.5, 0.2)
					fx.floating_text(get_parent() if get_parent() else self, body.global_position + Vector2(0, -32), "Debemos limpiar los salones de antivalores antes de continuar", Color(1.0, 0.35, 0.35), 13)
			var push_dir: Vector2 = (body.global_position - global_position).normalized()
			if push_dir == Vector2.ZERO:
				push_dir = Vector2.LEFT
			if body is CharacterBody2D and body.is_inside_tree() and PhysicsServer2D.body_get_space(body.get_rid()).is_valid():
				(body as CharacterBody2D).move_and_collide(push_dir * 32.0)
			else:
				body.position += push_dir * 32.0
			return

		if is_locked:
			if _time - _last_locked_msg_time >= LOCKED_MSG_COOLDOWN:
				_last_locked_msg_time = _time
				var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
				if fx:
					var celebrating: bool = (level_ref != null and bool(level_ref.get("is_final_boss_celebrating")))
					var locked_msg := "Los alumnos celebran: Finalmente lo derrotamos" if celebrating else "Vence al antivalor jefe primero"
					var locked_color := Color(1.0, 0.92, 0.45) if celebrating else Color(1.0, 0.45, 0.45)
					fx.floating_text(get_parent() if get_parent() else self, global_position + Vector2(0, -28), locked_msg, locked_color, 11)
			return
		trigger(body)

## Activa la meta, emite efectos visuales/sonoros y notifica la victoria del nivel
func trigger(body: Node2D) -> void:
	if already_reached or not (body is Player) or not body.can_control:
		return
	already_reached = true
	if sfx_victory:
		sfx_victory.play()
	if particles:
		particles.restart()
		particles.emitting = true

	if sprite:
		sprite.modulate = Color(2.2, 2.2, 1.6)
		sprite.scale = Vector2(1.35, 1.35)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.6)
		tw.tween_property(sprite, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx:
		fx.shake(4.0, 0.3)
	player_reached_goal.emit()
