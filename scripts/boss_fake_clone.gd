extends Area2D
class_name BossFakeClone

## Clon falso de Titanor: parece idéntico visualmente y engaña al jugador,
## pero no daña la barra real del jefe y se disipa al recibir un impacto de virtud.

var owner_boss: Node2D = null
var base_color: Color = Color(0.50, 0.15, 0.35)
var accent_color: Color = Color(0.95, 0.30, 0.55)
var phase_offset: float = 0.0
var _anim_t: float = 0.0

func _init(p_owner: Node2D = null, p_base_col: Color = Color(0.50, 0.15, 0.35), p_acc_col: Color = Color(0.95, 0.30, 0.55), p_phase: float = 0.0) -> void:
	owner_boss = p_owner
	base_color = p_base_col
	accent_color = p_acc_col
	phase_offset = p_phase

func _ready() -> void:
	y_sort_enabled = true
	add_to_group("enemies")
	add_to_group("boss_clones")
	collision_layer = 8
	collision_mask = 6

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 44)
	col.shape = rect
	col.position = Vector2(0, -20)
	add_child(col)

	var lbl := Label.new()
	lbl.text = "Titanor"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-48, -86)
	lbl.size = Vector2(96, 20)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.88))
	lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.12))
	lbl.add_theme_constant_override("outline_size", 4)
	add_child(lbl)

func _process(delta: float) -> void:
	_anim_t += delta
	queue_redraw()

func _draw() -> void:
	var shadow_col := Color(0.05, 0.06, 0.10, 0.32)
	draw_rect(Rect2(-22, -6, 44, 10), shadow_col)
	BossRenderer.draw_boss_silhouette(
		self,
		BossData.BossType.BULLYING,
		Vector2.ZERO,
		_anim_t + phase_offset,
		base_color * Color(1.0, 1.0, 1.0, 0.85),
		accent_color * Color(1.0, 1.0, 1.0, 0.85),
		false,
		false,
		1.0
	)
	# Grieta sutil de sombra para distinguir clones en observación atenta
	var breathe := sin(_anim_t * 4.0 + phase_offset) * 2.0
	draw_line(Vector2(-10, -40 + breathe), Vector2(10, -24 + breathe), Color(0.12, 0.04, 0.16, 0.45), 1.5)

func hit_by_attack(_attacker_pos: Variant = null, _damage: int = 1) -> void:
	var fx: Node = owner_boss._get_fx() if owner_boss and is_instance_valid(owner_boss) and owner_boss.has_method("_get_fx") else null
	if fx and get_parent():
		fx.burst(get_parent(), global_position + Vector2(0, -24), Color(0.75, 0.45, 1.0), 12, 130.0)
		fx.floating_text(get_parent(), global_position + Vector2(0, -48), "¡Clon Falso!", Color(0.82, 0.72, 1.0), 13)
	if owner_boss and is_instance_valid(owner_boss) and "active_clones" in owner_boss:
		owner_boss.active_clones.erase(self)
	queue_free()
