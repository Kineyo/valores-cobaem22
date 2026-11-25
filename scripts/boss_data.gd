extends RefCounted
class_name BossData

## Catálogo de Jefes Finales, escalado de HP por dificultad y alumnos rescatados (CEMSaD 22 ENTHAVI).

enum BossType {
	APATIA,        ## Nivel 1: Sombra de la Apatía (Acceso / Lab. D)
	DESPERDICIO,   ## Nivel 2: Troll del Desperdicio (Edif. A - Cafetería)
	INTOLERANCIA,  ## Nivel 3: Sombra de la Intolerancia (Plaza Cívica)
	CIBERACOSO,    ## Nivel 4: Espectro del Ciberacoso (Edif. B - Biblioteca)
	PLAGIO,        ## Nivel 5: Titán del Plagio (Edif. C - Taller Cómputo)
	BULLYING,      ## Nivel 6: Coloso del Bullying (Cancha Usos Múltiples - Danmaku Touhou)
	DESINTERES     ## Jefe de Salón: Maestro Desinterés (Inacción docente ante el bullying)
}

const RESCUE_STUDENTS_DATA := [
	{ "name": "Mateo", "tex": "res://assets/characters/mateo_laboratorio/idle.png", "virtue": "¡Rigor Científico!", "color": Color(0.35, 0.90, 1.0) },
	{ "name": "María", "tex": "res://assets/characters/maria_cafeteria/idle.png", "virtue": "¡Empatía!", "color": Color(1.0, 0.72, 0.35) },
	{ "name": "Valeria", "tex": "res://assets/characters/valeria_plaza/idle.png", "virtue": "¡Civismo!", "color": Color(0.55, 0.95, 0.55) },
	{ "name": "Fernanda", "tex": "res://assets/characters/fernanda_biblioteca/idle.png", "virtue": "¡Sabiduría!", "color": Color(0.75, 0.65, 1.0) },
	{ "name": "Diego", "tex": "res://assets/characters/diego_computo/idle.png", "virtue": "¡Ciudadanía Digital!", "color": Color(0.30, 0.95, 0.85) },
	{ "name": "Sofía", "tex": "res://assets/characters/sofia_direccion/idle.png", "virtue": "¡Respeto!", "color": Color(1.0, 0.88, 0.35) },
	{ "name": "Alejandro", "tex": "res://assets/characters/alejandro_cancha/idle.png", "virtue": "¡Juego Limpio!", "color": Color(1.0, 0.55, 0.45) },
]

const BOSS_DATA := {
	BossType.APATIA: {
		"name": "Apatyx, el Espectro del Desgano",
		"location": "Acceso y Laboratorio D (183 m²)",
		"max_hp": 32,
		"speed": 80.0,
		"color": Color(0.45, 0.40, 0.65),
		"accent_color": Color(0.70, 0.60, 0.95),
		"virtue": "¡Entusiasmo y Curiosidad!",
		"intro_dialog": "«¿Cruzar el portón para qué, jovencito? Afuera nadie nota tu esfuerzo... quédate en la sombra.»",
		"intro_dialog_f": "«¿Cruzar el portón para qué, jovencita? Afuera nadie nota tu esfuerzo... quédate en la sombra.»",
		"redeemed_dialog": "«Apagué mis ganas por miedo a equivocarme frente al grupo. ¡Hoy vuelvo a encender el laboratorio!»",
		"attack_names": ["Vórtice Espiral de Desgano", "Ráfaga Ciclónica del Desaliento", "Miasma Apatético"],
	},
	BossType.DESPERDICIO: {
		"name": "Desperdicius, el Titán del Desperdicio",
		"location": "Edificio A — Cafetería y Aulas (339 m²)",
		"max_hp": 40,
		"speed": 68.0,
		"color": Color(0.55, 0.50, 0.30),
		"accent_color": Color(0.85, 0.75, 0.40),
		"virtue": "¡Responsabilidad y Cuidado Ambiental!",
		"intro_dialog": "«¡Esta mesa y esta sombra son mías, entrometido! ¡Que alguien más recoja lo que yo dejo tirado!»",
		"intro_dialog_f": "«¡Esta mesa y esta sombra son mías, entrometida! ¡Que alguien más recoja lo que yo dejo tirado!»",
		"redeemed_dialog": "«Olvidé cuántas manos madrugaron por cada plato servido. ¡Cuidemos cada mesa de nuestra cafetería!»",
		"attack_names": ["Lluvia de Desechos", "Pisotón de Basura"],
	},
	BossType.INTOLERANCIA: {
		"name": "Superbus, el Heraldo de la Arrogancia",
		"location": "Plaza Cívica y Escalinata Sur (748 m²)",
		"max_hp": 48,
		"speed": 82.0,
		"color": Color(0.70, 0.25, 0.30),
		"accent_color": Color(1.0, 0.40, 0.45),
		"virtue": "¡Tolerancia y Respeto a la Diversidad!",
		"intro_dialog": "«¡Esta escalinata separa a quienes importan, muchacho! ¡Baja la mirada!»",
		"intro_dialog_f": "«¡Esta escalinata separa a quienes importan, muchacha! ¡Baja la mirada!»",
		"redeemed_dialog": "«Medir a las personas por su apellido me dejó vacío. ¡Cada raíz de Temoaya merece respeto!»",
		"attack_names": ["Onda de Rechazo", "Ráfaga de Prejuicios"],
	},
	BossType.CIBERACOSO: {
		"name": "Ciber-Murmullus, el Espectro de la Difamación",
		"location": "Edificio B — Biblioteca y Aulas (280 m²)",
		"max_hp": 56,
		"speed": 92.0,
		"color": Color(0.20, 0.55, 0.75),
		"accent_color": Color(0.40, 0.85, 1.0),
		"virtue": "¡Empatía Digital y Honestidad!",
		"intro_dialog": "«Un reenvío anónimo, curioso, una captura fuera de lugar... y nadie sabrá quién rompió su paz.»",
		"intro_dialog_f": "«Un reenvío anónimo, curiosa, una captura fuera de lugar... y nadie sabrá quién rompió su paz.»",
		"redeemed_dialog": "«Detrás de cada pantalla late un compañero real. ¡Nunca más usaré la red para herir!»",
		"attack_names": ["Enjambre Ciber-Teledirigido", "Teletransporte Glitch + Ráfaga", "Cadenas de Rumores Teledirigidas"],
	},
	BossType.PLAGIO: {
		"name": "Plagiatrix, el Señor de la Falsedad",
		"location": "Edificio C — Cómputo y Dirección (625 m²)",
		"max_hp": 64,
		"speed": 72.0,
		"color": Color(0.35, 0.35, 0.45),
		"accent_color": Color(0.65, 0.75, 0.90),
		"virtue": "¡Autenticidad e Integridad Académica!",
		"intro_dialog": "«¿Desvelarte aprendiendo, ingenuo? ¡Copia el atajo, falsifica la entrega y presume el diez!»",
		"intro_dialog_f": "«¿Desvelarte aprendiendo, ingenua? ¡Copia el atajo, falsifica la entrega y presume el diez!»",
		"redeemed_dialog": "«Aprobar engañando deja hueca la mente. ¡El esfuerzo honesto es mi verdadera voz!»",
		"attack_names": ["Copia Espejo", "Barrera de Atajos"],
	},
	BossType.BULLYING: {
		"name": "Titanor, el Coloso del Bullying Escolar",
		"location": "Cancha de Usos Múltiples y Gradas (540 m²)",
		"max_hp": 180,
		"speed": 88.0,
		"color": Color(0.50, 0.15, 0.35),
		"accent_color": Color(0.95, 0.30, 0.55),
		"virtue": "¡Fraternidad, Solidaridad y Fair Play!",
		"intro_dialog": "«¡Esta duela es mía, novato! ¡Aquí mandan los empujones, el miedo y el silencio de los demás!»",
		"intro_dialog_f": "«¡Esta duela es mía, novata! ¡Aquí mandan los empujones, el miedo y el silencio de los demás!»",
		"redeemed_dialog": "«Intimidaba para ocultar lo solo que me sentía... ¡Hoy protejo a quienes antes lastimé!»",
		"attack_names": [
			"Ruleta Danmaku Escolar",
			"Doble Espiral de Opresión",
			"Ruleta Kaleidoscópica Cruzada",
			"Último Hechizo: Resplandor de la Inclusión"
		],
	},
	BossType.DESINTERES: {
		"name": "Maestro Desinterés (Docente Indiferente)",
		"location": "Salón de Clases — Aula de Convivencia",
		"max_hp": 55,
		"speed": 85.0,
		"color": Color(0.55, 0.58, 0.62),
		"accent_color": Color(0.88, 0.92, 0.98),
		"virtue": "¡Compromiso, Escucha y Empatía Docente!",
		"intro_dialog": "«No interrumpas, alumno... hoy tengo demasiadas actas y papeleo pendiente.»",
		"intro_dialog_f": "«No interrumpas, alumna... hoy tengo demasiadas actas y papeleo pendiente.»",
		"redeemed_dialog": "«Callar ante la burla también duele. ¡Desde hoy cada alumno que pida ayuda será escuchado!»",
		"attack_names": ["Mirada Indiferente", "Burocracia Inmóvil"],
	}
}

static func get_intro_dialog(boss_type: int, is_female: bool = false) -> String:
	var entry: Dictionary = BOSS_DATA.get(boss_type, {})
	if is_female and entry.has("intro_dialog_f"):
		return str(entry["intro_dialog_f"])
	return str(entry.get("intro_dialog", ""))

## Tabla de Salud por Dificultad (Fácil, Normal, Difícil).
## En Difícil, Titanor cuenta con 450 HP: a 0.40s de cooldown por tiro continuo perfecto = 180.0s (3 minutos exactos)
## más 12s de transiciones de cartas de hechizo = 192s de duración mínima garantizada bajo ataque perfecto.
const BOSS_DIFFICULTY_HP := {
	BossType.APATIA: { 0: 16, 1: 32, 2: 65 },
	BossType.DESPERDICIO: { 0: 20, 1: 40, 2: 80 },
	BossType.INTOLERANCIA: { 0: 24, 1: 48, 2: 100 },
	BossType.CIBERACOSO: { 0: 28, 1: 56, 2: 120 },
	BossType.PLAGIO: { 0: 32, 1: 64, 2: 140 },
	BossType.BULLYING: { 0: 75, 1: 180, 2: 450 },
	BossType.DESINTERES: { 0: 25, 1: 55, 2: 120 },
}
