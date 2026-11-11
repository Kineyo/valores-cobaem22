extends Area2D
class_name Projectile

## Proyectil de valores disparado por el jugador en perspectiva 3/4.
## Se desplaza en línea recta y neutraliza al primer antivalor con el que colisiona.

@export var speed: float = 520.0
@export var lifetime: float = 1.1

var direction: Variant = Vector2.RIGHT
var _dir_vec: Vector2 = Vector2.RIGHT
var _time: float = 0.0
var _done: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	if direction is Vector2:
		_dir_vec = direction.normalized()
		if _dir_vec == Vector2.ZERO:
			_dir_vec = Vector2.RIGHT
	elif direction is int or direction is float:
		_dir_vec = Vector2.RIGHT if float(direction) >= 0.0 else Vector2.LEFT

	# Orientar el ángulo del nodo hacia la trayectoria de disparo
	rotation = _dir_vec.angle()
	sprite.flip_h = false

	# Animación pop de aparición
	var target_scale := sprite.scale
	sprite.scale = target_scale * 0.4
	create_tween().tween_property(sprite, "scale", target_scale, 0.08)

func _physics_process(delta: float) -> void:
	position += _dir_vec * speed * delta
	sprite.rotation += 12.0 * delta
	_time += delta

	# Desvanecimiento en el último cuarto de vida útil
	if _time > lifetime * 0.75:
		modulate.a = clampf(1.0 - (_time - lifetime * 0.75) / (lifetime * 0.25), 0.0, 1.0)
	if _time >= lifetime:
		queue_free()

func _spawn_impact_fx(col: Color = Color(1.0, 0.92, 0.5), count: int = 8, vel: float = 120.0) -> void:
	var fx = get_node_or_null("/root/Fx") if is_inside_tree() else null
	if fx and get_parent():
		fx.burst(get_parent(), global_position, col, count, vel)

func _on_body_entered(body: Node2D) -> void:
	if _done:
		return
	# Si impacta contra una pared u obstáculo sólido
	if body is StaticBody2D or body.is_in_group("obstacles") or (body.collision_layer & 1) != 0:
		_done = true
		_spawn_impact_fx(Color(0.85, 0.88, 0.95), 6, 90.0)
		queue_free()
		return
	# Si impacta directamente contra el CharacterBody2D del enemigo
	if body.has_method("hit_by_attack") and body.is_in_group("enemies"):
		_done = true
		_spawn_impact_fx()
		body.hit_by_attack(global_position)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if _done or not area.is_in_group("enemies"):
		return
	var enemy = area.get_parent()
	if enemy and enemy.has_method("hit_by_attack"):
		_done = true
		_spawn_impact_fx()
		enemy.hit_by_attack(global_position)
		queue_free()
