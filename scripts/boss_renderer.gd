extends RefCounted
class_name BossRenderer

## Renderizador procedural pixel-art en perspectiva 3/4 para todos los Jefes Finales.
## Cada uno de los 6 jefes posee silueta, anatomía, accesorios y animación únicos.

static func _xform_pts(pts: Array, origin: Vector2, scale_f: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(origin + (p as Vector2) * scale_f)
	return out

static func _xform_rect(r: Rect2, origin: Vector2, scale_f: float) -> Rect2:
	return Rect2(origin + r.position * scale_f, r.size * scale_f)

static func draw_boss_silhouette(
	canvas: CanvasItem,
	boss_type: int,
	origin: Vector2,
	anim_time: float,
	base_col: Color,
	acc_col: Color,
	is_esperanza_defenseless: bool = false,
	is_shattering: bool = false,
	scale_f: float = 1.0
) -> void:
	var breathe := sin(anim_time * 4.0) * 2.0
	if is_esperanza_defenseless:
		breathe = sin(anim_time * 12.0) * 1.2
	var outline := Color(0.06, 0.05, 0.09, 0.96) if not is_shattering else Color(0.95, 0.95, 0.95, 0.95)
	var b := func(r: Rect2) -> Rect2:
		return _xform_rect(r, origin, scale_f)
	var pt := func(v: Vector2) -> Vector2:
		return origin + v * scale_f
	var ply := func(arr: Array) -> PackedVector2Array:
		return _xform_pts(arr, origin, scale_f)

	match boss_type:
		BossData.BossType.APATIA:
			# Apatyx: Espectro encapuchado flotante con jirones ondulantes y reloj de arena roto
			var hover := sin(anim_time * 2.8) * 3.5 + breathe * 0.5
			var cloak_pts := [
				Vector2(0, -76 + hover),
				Vector2(17, -60 + hover),
				Vector2(21, -24 + hover),
				Vector2(17, -8 + hover + sin(anim_time * 5.0) * 3.0),
				Vector2(8, -17 + hover),
				Vector2(2, -4 + hover + cos(anim_time * 4.5) * 3.5),
				Vector2(-5, -16 + hover),
				Vector2(-13, -5 + hover + sin(anim_time * 4.2 + 1.2) * 3.0),
				Vector2(-21, -22 + hover),
				Vector2(-17, -60 + hover),
			]
			canvas.draw_colored_polygon(ply.call(cloak_pts), base_col)
			canvas.draw_polyline(ply.call(cloak_pts + [cloak_pts[0]]), outline, 2.2 * scale_f)
			# Capucha picuda y cavidad sombría del rostro
			canvas.draw_colored_polygon(ply.call([
				Vector2(-15, -56 + hover), Vector2(0, -76 + hover), Vector2(15, -56 + hover), Vector2(10, -44 + hover), Vector2(-10, -44 + hover)
			]), base_col.darkened(0.28))
			canvas.draw_rect(b.call(Rect2(-9, -60 + hover, 18, 12)), Color(0.05, 0.04, 0.09))
			# Ojos somnolientos / apáticos
			var slit_col := acc_col if not is_shattering else Color(0.92, 0.92, 0.92)
			canvas.draw_rect(b.call(Rect2(-7, -56 + hover, 5, 2)), slit_col)
			canvas.draw_rect(b.call(Rect2(2, -56 + hover, 5, 2)), slit_col)
			# Mangas espectrales caídas
			canvas.draw_colored_polygon(ply.call([Vector2(-18, -44 + hover), Vector2(-26, -24 + hover), Vector2(-17, -20 + hover)]), base_col.darkened(0.18))
			canvas.draw_colored_polygon(ply.call([Vector2(18, -44 + hover), Vector2(26, -24 + hover), Vector2(17, -20 + hover)]), base_col.darkened(0.18))
			# Reloj de arena agrietado en el pecho
			canvas.draw_colored_polygon(ply.call([Vector2(-6, -38 + hover), Vector2(6, -38 + hover), Vector2(0, -30 + hover)]), Color(0.65, 0.88, 1.0, 0.85))
			canvas.draw_colored_polygon(ply.call([Vector2(0, -30 + hover), Vector2(6, -22 + hover), Vector2(-6, -22 + hover)]), Color(0.55, 0.45, 0.85, 0.85))

		BossData.BossType.DESPERDICIO:
			# Desperdicius: Golem ancho jorobado de desechos con tapa metálica y lata abollada
			var wobble := sin(anim_time * 3.4) * 1.5
			var mound := [
				Vector2(-15, -56 + breathe), Vector2(12, -58 + breathe),
				Vector2(24, -40 + breathe), Vector2(27, -14 + breathe),
				Vector2(21, -2), Vector2(-22, -2),
				Vector2(-27, -16 + breathe), Vector2(-22, -40 + breathe),
			]
			canvas.draw_colored_polygon(ply.call(mound), base_col)
			canvas.draw_polyline(ply.call(mound + [mound[0]]), outline, 2.4 * scale_f)
			# Sombras musgosas y manchas de residuo
			canvas.draw_rect(b.call(Rect2(-19, -24 + breathe, 38, 14)), base_col.darkened(0.26))
			canvas.draw_rect(b.call(Rect2(-12, -54 + breathe, 24, 16)), base_col.lightened(0.08))
			# Desechos en coronilla (cáscara amarilla + papel arrugado)
			canvas.draw_colored_polygon(ply.call([Vector2(-10, -58 + breathe), Vector2(-16, -69 + breathe), Vector2(-4, -60 + breathe)]), acc_col)
			canvas.draw_colored_polygon(ply.call([Vector2(4, -58 + breathe), Vector2(11, -68 + breathe), Vector2(15, -57 + breathe)]), Color(0.88, 0.90, 0.86))
			# Lata abollada en hombro derecho
			canvas.draw_rect(b.call(Rect2(16, -48 + breathe + wobble, 10, 12)), Color(0.62, 0.66, 0.72))
			canvas.draw_rect(b.call(Rect2(16, -44 + breathe + wobble, 10, 4)), Color(0.82, 0.25, 0.25))
			# Escudo tapa de bote metálico en brazo izquierdo
			canvas.draw_circle(pt.call(Vector2(-25, -24 + breathe - wobble)), 11.0 * scale_f, Color(0.45, 0.49, 0.54))
			canvas.draw_arc(pt.call(Vector2(-25, -24 + breathe - wobble)), 11.0 * scale_f, 0.0, TAU, 18, outline, 2.0 * scale_f)
			canvas.draw_rect(b.call(Rect2(-28, -26 + breathe - wobble, 6, 4)), Color(0.75, 0.78, 0.84))
			# Ojos asimétricos amarillos y boca dentada
			canvas.draw_rect(b.call(Rect2(-9, -49 + breathe, 6, 5)), Color(1.0, 0.88, 0.20))
			canvas.draw_rect(b.call(Rect2(3, -50 + breathe, 5, 6)), Color(1.0, 0.88, 0.20))
			canvas.draw_rect(b.call(Rect2(-10, -36 + breathe, 20, 6)), Color(0.16, 0.12, 0.08))
			canvas.draw_rect(b.call(Rect2(-7, -36 + breathe, 4, 3)), Color(0.92, 0.90, 0.78))
			canvas.draw_rect(b.call(Rect2(4, -33 + breathe, 4, 3)), Color(0.92, 0.90, 0.78))

		BossData.BossType.INTOLERANCIA:
			# Superbus: Aristócrata alto de diamante con cuello alzado, monóculo y cetro real
			var cape_pts := [
				Vector2(-20, -68 + breathe), Vector2(-10, -54 + breathe),
				Vector2(10, -54 + breathe), Vector2(20, -68 + breathe),
				Vector2(18, -32 + breathe), Vector2(24, -2),
				Vector2(-24, -2), Vector2(-18, -32 + breathe),
			]
			canvas.draw_colored_polygon(ply.call(cape_pts), base_col.darkened(0.32))
			canvas.draw_polyline(ply.call(cape_pts + [cape_pts[0]]), outline, 2.2 * scale_f)
			# Cuerpo en forma de reloj de arena / diamante afilado
			canvas.draw_colored_polygon(ply.call([
				Vector2(-14, -48 + breathe), Vector2(14, -48 + breathe),
				Vector2(6, -24 + breathe), Vector2(12, -4),
				Vector2(-12, -4), Vector2(-6, -24 + breathe),
			]), base_col)
			# Banda y broche dorado en pecho
			canvas.draw_line(pt.call(Vector2(-12, -46 + breathe)), pt.call(Vector2(8, -22 + breathe)), Color(1.0, 0.86, 0.34), 3.0 * scale_f)
			# Rostro altivo estrecho y corona picuda
			canvas.draw_rect(b.call(Rect2(-10, -68 + breathe, 20, 20)), Color(0.86, 0.72, 0.68))
			canvas.draw_rect(b.call(Rect2(-10, -68 + breathe, 20, 20)), outline, false, 1.6 * scale_f)
			canvas.draw_colored_polygon(ply.call([
				Vector2(-11, -68 + breathe), Vector2(-9, -82 + breathe), Vector2(-3, -72 + breathe),
				Vector2(0, -84 + breathe), Vector2(3, -72 + breathe), Vector2(9, -82 + breathe), Vector2(11, -68 + breathe),
			]), Color(1.0, 0.85, 0.28))
			# Cejas altivas y monóculo dorado en ojo derecho
			canvas.draw_line(pt.call(Vector2(-8, -62 + breathe)), pt.call(Vector2(-2, -59 + breathe)), outline, 2.0 * scale_f)
			canvas.draw_line(pt.call(Vector2(2, -59 + breathe)), pt.call(Vector2(8, -62 + breathe)), outline, 2.0 * scale_f)
			canvas.draw_rect(b.call(Rect2(-7, -58 + breathe, 4, 3)), Color(0.98, 0.96, 1.0))
			canvas.draw_circle(pt.call(Vector2(5, -56 + breathe)), 4.5 * scale_f, Color(1.0, 0.88, 0.32, 0.35))
			canvas.draw_arc(pt.call(Vector2(5, -56 + breathe)), 4.5 * scale_f, 0.0, TAU, 14, Color(1.0, 0.88, 0.32), 1.6 * scale_f)
			# Cetro flotante real a la derecha
			var scep_y := sin(anim_time * 3.6) * 3.0
			canvas.draw_line(pt.call(Vector2(26, -54 + scep_y)), pt.call(Vector2(26, -12 + scep_y)), Color(0.95, 0.80, 0.28), 3.0 * scale_f)
			canvas.draw_circle(pt.call(Vector2(26, -57 + scep_y)), 5.0 * scale_f, acc_col)

		BossData.BossType.CIBERACOSO:
			# Ciber-Murmullus: Monitor CRT flotante con antenas Wi-Fi y cubos digitales fragmentados
			var glitch_x := sin(anim_time * 18.0) * 1.4 if int(anim_time * 9.0) % 5 == 0 else 0.0
			# Cubos flotantes inferiores (sin torso sólido)
			var cubes := [Vector2(-10, -28), Vector2(4, -30), Vector2(-14, -14), Vector2(0, -16), Vector2(12, -20)]
			for idx in range(cubes.size()):
				var cp: Vector2 = cubes[idx]
				var bob := sin(anim_time * 5.0 + float(idx) * 1.3) * 3.0
				var c_col := Color(0.18, 0.85, 0.98) if (idx % 2 == 0) else Color(0.95, 0.26, 0.72)
				canvas.draw_rect(b.call(Rect2(cp.x - 4, cp.y + bob, 8, 8)), base_col)
				canvas.draw_rect(b.call(Rect2(cp.x - 4, cp.y + bob, 8, 8)), c_col, false, 1.4 * scale_f)
			# Antenas + ondas Wi-Fi
			canvas.draw_line(pt.call(Vector2(-8, -68 + breathe)), pt.call(Vector2(-14, -80 + breathe)), Color(0.75, 0.85, 0.95), 2.0 * scale_f)
			canvas.draw_line(pt.call(Vector2(8, -68 + breathe)), pt.call(Vector2(14, -80 + breathe)), Color(0.75, 0.85, 0.95), 2.0 * scale_f)
			canvas.draw_circle(pt.call(Vector2(-14, -80 + breathe)), 2.8 * scale_f, Color.CYAN)
			canvas.draw_circle(pt.call(Vector2(14, -80 + breathe)), 2.8 * scale_f, Color.MAGENTA)
			for w_i in range(2):
				var wr := (8.0 + float(w_i) * 5.0 + fmod(anim_time * 14.0, 6.0)) * scale_f
				canvas.draw_arc(pt.call(Vector2(0, -72 + breathe)), wr, -PI * 0.78, -PI * 0.22, 12, Color(0.35, 0.95, 1.0, 0.65), 1.5 * scale_f)
			# Carcasa CRT y pantalla oscura
			var bezel := Rect2(-20 + glitch_x, -68 + breathe, 40, 29)
			canvas.draw_rect(b.call(bezel), base_col.darkened(0.45))
			canvas.draw_rect(b.call(bezel), outline, false, 2.2 * scale_f)
			var screen := Rect2(-16 + glitch_x, -64 + breathe, 32, 21)
			canvas.draw_rect(b.call(screen), Color(0.05, 0.08, 0.16))
			# Líneas scan y ojos glitch asimétricos
			canvas.draw_line(pt.call(Vector2(-15 + glitch_x, -51 + breathe)), pt.call(Vector2(15 + glitch_x, -51 + breathe)), Color(0.2, 0.9, 1.0, 0.45), 1.5 * scale_f)
			canvas.draw_line(pt.call(Vector2(-12 + glitch_x, -60 + breathe)), pt.call(Vector2(-5 + glitch_x, -53 + breathe)), Color.CYAN, 2.2 * scale_f)
			canvas.draw_line(pt.call(Vector2(-5 + glitch_x, -60 + breathe)), pt.call(Vector2(-12 + glitch_x, -53 + breathe)), Color.CYAN, 2.2 * scale_f)
			canvas.draw_rect(b.call(Rect2(5 + glitch_x, -59 + breathe, 8, 5)), Color.MAGENTA)
			canvas.draw_rect(b.call(Rect2(-9 + glitch_x, -48 + breathe, 18, 2)), Color(1.0, 0.35, 0.55))

		BossData.BossType.PLAGIO:
			# Plagiatrix: Fantasma teatral dividido (tinta sombría vs hoja falsificada con doblez)
			var shear := sin(anim_time * 3.6) * 2.5
			# Mitad izquierda oscura (tinta)
			canvas.draw_colored_polygon(ply.call([
				Vector2(0, -68 + breathe - shear), Vector2(-17, -64 + breathe - shear),
				Vector2(-20, -10 - shear), Vector2(0, -4 - shear),
			]), Color(0.18, 0.19, 0.28))
			# Mitad derecha papel cuaderno con esquina doblada
			canvas.draw_colored_polygon(ply.call([
				Vector2(0, -68 + breathe + shear), Vector2(11, -66 + breathe + shear),
				Vector2(19, -56 + breathe + shear), Vector2(20, -10 + shear), Vector2(0, -4 + shear),
			]), Color(0.90, 0.91, 0.95))
			# Doblez de hoja arriba a la derecha
			canvas.draw_colored_polygon(ply.call([
				Vector2(11, -66 + breathe + shear), Vector2(11, -56 + breathe + shear), Vector2(19, -56 + breathe + shear),
			]), Color(0.68, 0.72, 0.82))
			# Renglones azules y margen rojo en mitad papel
			for l_y in [-46, -38, -30, -22]:
				canvas.draw_line(pt.call(Vector2(2, float(l_y) + breathe + shear)), pt.call(Vector2(17, float(l_y) + breathe + shear)), Color(0.40, 0.65, 0.92, 0.7), 1.3 * scale_f)
			canvas.draw_line(pt.call(Vector2(4, -64 + breathe + shear)), pt.call(Vector2(4, -8 + shear)), Color(0.90, 0.32, 0.36, 0.75), 1.4 * scale_f)
			# Línea de fractura central + ojos dispares
			canvas.draw_line(pt.call(Vector2(0, -68 + breathe)), pt.call(Vector2(0, -4)), outline, 2.2 * scale_f)
			canvas.draw_rect(b.call(Rect2(-12, -58 + breathe - shear, 7, 4)), Color(0.55, 0.85, 1.0))
			canvas.draw_arc(pt.call(Vector2(10, -56 + breathe + shear)), 3.6 * scale_f, 0.0, TAU, 12, Color(0.88, 0.24, 0.36), 1.8 * scale_f)
			# Sello rojo flotante de COPIA a la izquierda
			var stamp_y := cos(anim_time * 4.2) * 3.0
			canvas.draw_rect(b.call(Rect2(-31, -46 + stamp_y, 10, 12)), Color(0.75, 0.16, 0.24))
			canvas.draw_rect(b.call(Rect2(-33, -36 + stamp_y, 14, 4)), Color(0.94, 0.32, 0.38))

		BossData.BossType.BULLYING, _:
			# Titanor: Coloso acorazado con cuernos curvos, hombreras con picos y guanteletes
			var eye_col := Color(0.45, 0.92, 1.0) if is_esperanza_defenseless else Color(1.0, 0.20, 0.28)
			if is_shattering:
				eye_col = Color(0.96, 0.96, 0.96)
			# Halo rúnico trasero
			canvas.draw_arc(pt.call(Vector2(0, -40 + breathe)), 28.0 * scale_f, anim_time * 1.4, anim_time * 1.4 + PI, 16, Color(acc_col.r, acc_col.g, acc_col.b, 0.45), 2.2 * scale_f)
			# Piernas blindadas
			canvas.draw_rect(b.call(Rect2(-15, -18, 11, 16)), base_col.darkened(0.35))
			canvas.draw_rect(b.call(Rect2(4, -18, 11, 16)), base_col.darkened(0.35))
			# Torso ancho en V con armadura y cinturón con hebilla dorada
			var chest := [
				Vector2(-23, -52 + breathe), Vector2(23, -52 + breathe),
				Vector2(15, -18 + breathe), Vector2(-15, -18 + breathe),
			]
			canvas.draw_colored_polygon(ply.call(chest), base_col)
			canvas.draw_polyline(ply.call(chest + [chest[0]]), outline, 2.4 * scale_f)
			canvas.draw_rect(b.call(Rect2(-16, -24 + breathe, 32, 6)), Color(0.16, 0.08, 0.15))
			canvas.draw_rect(b.call(Rect2(-5, -25 + breathe, 10, 8)), Color(1.0, 0.85, 0.30))
			# Hombreras masivas con picos
			canvas.draw_colored_polygon(ply.call([Vector2(-30, -42 + breathe), Vector2(-28, -56 + breathe), Vector2(-15, -52 + breathe), Vector2(-18, -36 + breathe)]), acc_col)
			canvas.draw_colored_polygon(ply.call([Vector2(30, -42 + breathe), Vector2(28, -56 + breathe), Vector2(15, -52 + breathe), Vector2(18, -36 + breathe)]), acc_col)
			canvas.draw_colored_polygon(ply.call([Vector2(-28, -56 + breathe), Vector2(-34, -64 + breathe), Vector2(-21, -54 + breathe)]), Color(1.0, 0.86, 0.34))
			canvas.draw_colored_polygon(ply.call([Vector2(28, -56 + breathe), Vector2(34, -64 + breathe), Vector2(21, -54 + breathe)]), Color(1.0, 0.86, 0.34))
			# Guanteletes pesados
			canvas.draw_rect(b.call(Rect2(-31, -30 + breathe, 9, 13)), base_col.darkened(0.25))
			canvas.draw_rect(b.call(Rect2(22, -30 + breathe, 9, 13)), base_col.darkened(0.25))
			# Yelmo sombreado + cuernos curvos imponentes
			var helm := Rect2(-13, -70 + breathe, 26, 20)
			canvas.draw_rect(b.call(helm), base_col.darkened(0.22))
			canvas.draw_rect(b.call(helm), outline, false, 2.2 * scale_f)
			canvas.draw_rect(b.call(Rect2(-10, -63 + breathe, 20, 8)), Color(0.08, 0.04, 0.08))
			canvas.draw_rect(b.call(Rect2(-8, -61 + breathe, 6, 4)), eye_col)
			canvas.draw_rect(b.call(Rect2(2, -61 + breathe, 6, 4)), eye_col)
			canvas.draw_colored_polygon(ply.call([Vector2(-12, -66 + breathe), Vector2(-26, -80 + breathe), Vector2(-17, -79 + breathe), Vector2(-8, -70 + breathe)]), Color(0.95, 0.90, 0.80))
			canvas.draw_colored_polygon(ply.call([Vector2(12, -66 + breathe), Vector2(26, -80 + breathe), Vector2(17, -79 + breathe), Vector2(8, -70 + breathe)]), Color(0.95, 0.90, 0.80))

static func draw_boss(boss: Node2D) -> void:
	var anim_time: float = float(boss.get("_anim_time"))
	var boss_type: int = int(boss.get("boss_type"))
	var current_state: int = int(boss.get("current_state"))
	var puddles: Array = boss.get("_puddles")
	var is_spell_transition: bool = bool(boss.get("_is_spell_transition"))
	var hazard_pulse: float = float(boss.get("_hazard_pulse"))
	var current_attack_idx: int = int(boss.get("_current_attack_idx"))
	var attack_target_pos: Vector2 = boss.get("_attack_target_pos")
	var boss_texture: Texture2D = boss.get("_boss_texture")
	var barrier_active: bool = bool(boss.get("_barrier_active"))
	var is_covered: bool = bool(boss.get("_is_covered_and_vanished"))
	var is_transforming: bool = bool(boss.get("_is_transforming"))
	var rescued_students: Array = boss.get("rescued_attack_students")
	var is_esperanza_defenseless: bool = bool(boss.get("is_esperanza_defenseless"))
	var esperanza_timer: float = float(boss.get("esperanza_debuff_timer"))
	var max_hp_val: int = maxi(1, int(boss.get("max_hp")))
	var cur_hp_val: int = maxi(0, int(boss.get("current_hp")))
	var hp_ratio: float = clampf(float(cur_hp_val) / float(max_hp_val), 0.0, 1.0)
	var is_shattering: bool = bool(boss.get("is_shattering_at_one_hp"))
	var shatter_prog: float = clampf(float(boss.get("shatter_progress")), 0.0, 1.0)
	var crack_level: float = clampf(float(boss.get("visual_crack_level")), 0.0, 1.0)

	# 0. Charcos de Desgano múltiples
	for pud in puddles:
		var local_puddle := boss.to_local(pud["pos"])
		var pulse := 0.40 + sin(anim_time * 5.0) * 0.12
		var p_col := Color(0.35, 0.22, 0.55, pulse)
		boss.draw_circle(local_puddle, pud["radius"], p_col)
		boss.draw_arc(local_puddle, pud["radius"], 0, TAU, 24, Color(0.75, 0.55, 0.95, 0.75), 2.0)

	# 1. Sombra elíptica en perspectiva 3/4
	var shadow_col := Color(0.05, 0.06, 0.10, 0.42)
	if boss_type == BossData.BossType.DESINTERES:
		boss.draw_rect(Rect2(-14, -4, 28, 8), shadow_col)
	else:
		boss.draw_rect(Rect2(-24, -6, 48, 12), shadow_col)
		boss.draw_rect(Rect2(-20, -10, 40, 20), shadow_col)

	var data: Dictionary = BossData.BOSS_DATA[boss_type]
	var base_col: Color = data["color"]
	var acc_col: Color = data["accent_color"]
	if is_shattering:
		var mono_v := 0.35 + 0.15 * sin(anim_time * 36.0)
		base_col = Color(mono_v, mono_v, mono_v)
		acc_col = Color(0.88, 0.88, 0.88)

	# Aura porcentual de Fase Intensa (<= 50% de vida)
	if hp_ratio <= 0.50 and cur_hp_val > 0 and not is_shattering:
		var pulse_50 := 36.0 + sin(anim_time * 8.0) * 5.0
		boss.draw_arc(Vector2(0, -28), pulse_50, anim_time * 2.2, anim_time * 2.2 + TAU, 28, Color(acc_col.r, acc_col.g, acc_col.b, 0.48), 2.0)

	# Círculo Mágico de Carta de Hechizo Danmaku en suelo (Titanor)
	if boss_type == BossData.BossType.BULLYING:
		var circle_ang := anim_time * 0.8
		var circle_col := Color(1.0, 0.88, 0.32, 0.35) if is_esperanza_defenseless else Color(1.0, 0.35, 0.60, 0.24 + sin(anim_time * 3.0) * 0.08)
		boss.draw_arc(Vector2(0, -6), 46.0, circle_ang, circle_ang + TAU, 32, circle_col, 2.2)
		boss.draw_arc(Vector2(0, -6), 38.0, -circle_ang, -circle_ang + TAU, 24, circle_col * 0.8, 1.5)

	# Cúpula de protección durante transición de fase
	if is_spell_transition:
		var dome_alpha := 0.45 + sin(anim_time * 12.0) * 0.20
		boss.draw_circle(Vector2(0, -28), 54.0, Color(1.0, 0.85, 0.3, dome_alpha * 0.3))
		boss.draw_arc(Vector2(0, -28), 54.0, 0, TAU, 32, Color(1.0, 0.95, 0.5, dome_alpha), 2.5)

	# 2. Telegrafiado en el suelo alineado con el tipo real de ataque
	if current_state == 2: # State.TELEGRAPHING
		var pulse_alpha := 0.35 + sin(hazard_pulse) * 0.25
		var warn_col := Color(1.0, 0.25, 0.25, clampf(pulse_alpha, 0.15, 0.7))

		var is_radial: bool = (
			(boss_type == BossData.BossType.APATIA and current_attack_idx != 1)
			or (boss_type == BossData.BossType.INTOLERANCIA and current_attack_idx == 0)
			or (boss_type == BossData.BossType.CIBERACOSO and current_attack_idx == 1)
			or (boss_type == BossData.BossType.BULLYING)
			or (boss_type == BossData.BossType.DESINTERES)
		)

		if is_radial:
			var slam_r := 105.0 if boss_type != BossData.BossType.BULLYING else 124.0
			boss.draw_circle(Vector2.ZERO, slam_r, warn_col * Color(1, 1, 1, 0.45))
			boss.draw_arc(Vector2.ZERO, slam_r, 0, TAU, 32, Color(1.0, 0.95, 0.3, 0.85), 2.6)
		else:
			var local_target := boss.to_local(attack_target_pos)
			var to_target := local_target.normalized() * clampf(local_target.length(), 60.0, 240.0)
			boss.draw_line(Vector2.ZERO, to_target, warn_col, 18.0)
			boss.draw_line(Vector2.ZERO, to_target, Color(1.0, 0.9, 0.2, pulse_alpha * 0.8), 2.0)
			boss.draw_circle(to_target, 30.0, warn_col)
			boss.draw_arc(to_target, 30.0, 0, TAU, 16, Color(1.0, 1.0, 0.3, 0.8), 2.0)

	# 3. Silueta única por jefe o sprite oficial del Maestro Desinterés
	var breathe := sin(anim_time * 4.0) * 2.0
	if is_esperanza_defenseless:
		breathe = sin(anim_time * 12.0) * 1.2
	if boss_type == BossData.BossType.DESINTERES:
		if boss_texture != null:
			boss.draw_texture_rect(boss_texture, Rect2(-32, -68 + breathe, 64, 64), false)
		else:
			boss.draw_rect(Rect2(-12, -64 + breathe, 24, 18), Color(0.57, 0.60, 0.65))
			boss.draw_rect(Rect2(-8, -58 + breathe, 5, 4), Color.WHITE)
			boss.draw_rect(Rect2(3, -58 + breathe, 5, 4), Color.WHITE)
			boss.draw_rect(Rect2(-2, -44 + breathe, 4, 14), Color(0.47, 0.18, 0.22))
	else:
		draw_boss_silhouette(boss, boss_type, Vector2.ZERO, anim_time, base_col, acc_col, is_esperanza_defenseless, is_shattering, 1.0)

	# 4. Barrera de Atajos orbitante o escudo de ocultamiento
	if barrier_active or is_covered:
		for i in range(3):
			var ang := anim_time * 5.0 + float(i) * (TAU / 3.0)
			var shield_pos := Vector2(cos(ang), sin(ang) * 0.6) * 36.0 + Vector2(0, -26)
			boss.draw_circle(shield_pos, 7.0, Color(0.4, 0.85, 1.0, 0.85))
			boss.draw_arc(shield_pos, 7.0, 0, TAU, 12, Color.WHITE, 1.5)

	# 5. Aura dorada de ESPERANZA (15s: sin clones, sin niebla, jefe completamente indefenso)
	if is_esperanza_defenseless:
		var esp_r := 46.0 + sin(anim_time * 6.0) * 4.0
		boss.draw_circle(Vector2(0, -28), esp_r, Color(1.0, 0.90, 0.35, 0.16))
		boss.draw_arc(Vector2(0, -28), esp_r, anim_time * 1.8, anim_time * 1.8 + TAU, 36, Color(1.0, 0.92, 0.40, 0.92), 2.5)
		boss.draw_arc(Vector2(0, -28), esp_r * 0.72, -anim_time * 2.2, -anim_time * 2.2 + TAU, 24, Color(0.55, 0.96, 1.0, 0.75), 1.6)
		if esperanza_timer > 0.0:
			for i in range(4):
				var sa := anim_time * 3.0 + float(i) * (TAU / 4.0)
				var sp := Vector2(cos(sa) * 26.0, -78.0 + sin(sa) * 7.0)
				boss.draw_circle(sp, 3.2, Color(1.0, 0.95, 0.45))

	# 6. Aura de transformación y rayos de virtud de los alumnos (5 HP Clímax)
	if is_transforming:
		var aura_r := 52.0 + sin(anim_time * 14.0) * 8.0
		boss.draw_circle(Vector2(0, -28), aura_r, Color(0.65, 0.15, 0.85, 0.28))
		boss.draw_arc(Vector2(0, -28), aura_r, 0, TAU, 36, Color(1.0, 0.35, 0.75, 0.85), 3.0)
		for ally in rescued_students:
			if is_instance_valid(ally):
				var from_pt := boss.to_local(ally.global_position + Vector2(0, -22))
				var ray_col: Color = ally.get_meta("color", Color(1.0, 0.92, 0.45))
				boss.draw_line(from_pt, Vector2(0, -28), ray_col, 3.0)
				boss.draw_line(from_pt, Vector2(0, -28), Color(1.0, 1.0, 1.0, 0.8), 1.2)

	# 7. Estrellas de mareo en estado STUNNED
	if current_state == 5 and not is_esperanza_defenseless: # State.STUNNED
		for i in range(3):
			var star_ang := anim_time * 8.0 + float(i) * (TAU / 3.0)
			var star_pos := Vector2(cos(star_ang) * 16.0, -82.0 + sin(star_ang) * 5.0)
			boss.draw_circle(star_pos, 3.0, Color(1.0, 0.9, 0.2))

	# 8. Líneas procedurales de fractura por porcentaje crítico (<= 25%) o secuencia 1 HP
	if crack_level > 0.05 or hp_ratio <= 0.25 or is_shattering:
		var effective_crack := maxf(crack_level, (0.35 if hp_ratio <= 0.25 else 0.0) + shatter_prog * 0.65)
		_draw_fracture_cracks(boss, breathe, effective_crack, is_shattering)

static func _draw_fracture_cracks(boss: Node2D, breathe: float, crack_level: float, is_shattering: bool) -> void:
	var crack_col := Color(1.0, 1.0, 1.0, clampf(0.45 + crack_level * 0.55, 0.0, 1.0))
	var outline_col := Color(0.05, 0.05, 0.08, 0.9)
	var segments := [
		[Vector2(-2, -62 + breathe), Vector2(3, -52 + breathe), Vector2(-4, -40 + breathe), Vector2(2, -24 + breathe)],
		[Vector2(-12, -46 + breathe), Vector2(-4, -36 + breathe), Vector2(-10, -22 + breathe)],
		[Vector2(12, -42 + breathe), Vector2(5, -30 + breathe), Vector2(14, -18 + breathe)],
		[Vector2(0, -28 + breathe), Vector2(-8, -12 + breathe), Vector2(6, -8 + breathe)],
	]
	var count := clampi(int(ceil(crack_level * float(segments.size()))), 1, segments.size())
	for idx in range(count):
		var pts: Array = segments[idx]
		for j in range(pts.size() - 1):
			boss.draw_line(pts[j], pts[j + 1], outline_col, 3.2)
			boss.draw_line(pts[j], pts[j + 1], crack_col, 1.8 if is_shattering else 1.4)
