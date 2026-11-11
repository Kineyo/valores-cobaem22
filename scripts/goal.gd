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
var _time: float = 0.0

func _ready() -> void:
	y_sort_enabled = true
	body_entered.connect(_on_body_entered)

func set_goal_text(txt: String) -> void:
	if label:
		label.text = txt

func _process(delta: float) -> void:
	_time += delta
	# Flotación rítmica sutil del icono de meta
	sprite.position.y = _base_sprite_y + roundf(sin(_time * 2.2) * 3.0)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
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

	sprite.modulate = Color(2.2, 2.2, 1.6)
	sprite.scale = Vector2(1.35, 1.35)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.6)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx:
		fx.shake(4.0, 0.3)
	player_reached_goal.emit()
