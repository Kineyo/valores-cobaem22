extends RefCounted
class_name BossData

## Catálogo de Jefes Finales, escalado de HP por dificultad y compañeros rescatados (CEMSaD 22 ENTHAVI).

enum BossType {
	APATIA,        ## Nivel 1: Sombra de la Apatía (Acceso / Lab. D)
	DESPERDICIO,   ## Nivel 2: Troll del Desperdicio (Edif. A - Cafetería)
	INTOLERANCIA,  ## Nivel 3: Sombra de la Intolerancia (Plaza Cívica)
	CIBERACOSO,    ## Nivel 4: Espectro del Ciberacoso (Edif. B - Biblioteca)
	PLAGIO,        ## Nivel 5: Titán del Plagio (Edif. C - Taller Cómputo)
	BULLYING,      ## Nivel 6: Coloso del Bullying (Cancha Usos Múltiples - Danmaku)
	DESINTERES     ## Jefe de Salón: Maestro Desinterés
}

const RESCUE_STUDENTS_DATA := [
	{ "name": "Mateo", "tex": "res://assets/characters/mateo_laboratorio/idle.png", "virtue": "Curiosidad", "color": Color(0.35, 0.90, 1.0) },
	{ "name": "María", "tex": "res://assets/characters/maria_cafeteria/idle.png", "virtue": "Empatía", "color": Color(1.0, 0.72, 0.35) },
	{ "name": "Valeria", "tex": "res://assets/characters/valeria_plaza/idle.png", "virtue": "Respeto", "color": Color(0.55, 0.95, 0.55) },
	{ "name": "Fernanda", "tex": "res://assets/characters/fernanda_biblioteca/idle.png", "virtue": "Claridad", "color": Color(0.75, 0.65, 1.0) },
	{ "name": "Diego", "tex": "res://assets/characters/diego_computo/idle.png", "virtue": "Honestidad", "color": Color(0.30, 0.95, 0.85) },
	{ "name": "Sofía", "tex": "res://assets/characters/sofia_direccion/idle.png", "virtue": "Escucha", "color": Color(1.0, 0.88, 0.35) },
	{ "name": "Alejandro", "tex": "res://assets/characters/alejandro_cancha/idle.png", "virtue": "Juego Limpio", "color": Color(1.0, 0.55, 0.45) },
]

const BOSS_DATA := {
	BossType.APATIA: {
		"name": "Apatyx, el Espectro del Desgano",
		"location": "Acceso y Laboratorio D (183 m²)",
		"max_hp": 32,
		"speed": 80.0,
		"color": Color(0.45, 0.40, 0.65),
		"accent_color": Color(0.70, 0.60, 0.95),
		"virtue": "Curiosidad",
		"intro_dialog": "Para qué participas si te vas a equivocar. Quedarte callado sale más barato.",
		"intro_dialog_f": "Para qué participas si te vas a equivocar. Quedarte callada sale más barato.",
		"mid_dialogs": [
			"Si preguntas en voz alta, luego se ríen en la salida.",
			"Tal vez no era flojera, sino miedo a quedar en evidencia."
		],
		"redeemed_dialog": "Me daba pena equivocarme frente al grupo. Vale la pena intentar aunque cueste al inicio.",
		"attack_names": ["Vórtice Espiral de Desgano", "Ráfaga Ciclónica del Desaliento", "Miasma Apatético"],
	},
	BossType.DESPERDICIO: {
		"name": "Desperdicius, el Titán del Desperdicio",
		"location": "Edificio A — Cafetería y Aulas (339 m²)",
		"max_hp": 40,
		"speed": 68.0,
		"color": Color(0.55, 0.50, 0.30),
		"accent_color": Color(0.85, 0.75, 0.40),
		"virtue": "Responsabilidad",
		"intro_dialog": "Si no dejo la envoltura aquí, de qué trabaja el de limpieza. Es su chamba.",
		"intro_dialog_f": "Si no dejo la envoltura aquí, de qué trabaja el de limpieza. Es su chamba.",
		"mid_dialogs": [
			"Una charola suelta ni se nota en toda la cafetería.",
			"Nunca pensé en que madrugan desde las cinco por esto."
		],
		"redeemed_dialog": "Cuidar lo que usamos cuesta diez segundos y respeta el trabajo de todos.",
		"attack_names": ["Lluvia de Desechos", "Pisotón de Descuido"],
	},
	BossType.INTOLERANCIA: {
		"name": "Superbus, el Heraldo de la Arrogancia",
		"location": "Plaza Cívica y Escalinata Sur (748 m²)",
		"max_hp": 48,
		"speed": 82.0,
		"color": Color(0.70, 0.25, 0.30),
		"accent_color": Color(1.0, 0.40, 0.45),
		"virtue": "Respeto",
		"intro_dialog": "Estos cuatro metros de piedra separan niveles, mejor baja la mirada.",
		"intro_dialog_f": "Estos cuatro metros de piedra separan niveles, mejor baja la mirada.",
		"mid_dialogs": [
			"Si no marco distancia, siento que pierdo mi lugar.",
			"Medir a otros por su acento solo me deja más aparte."
		],
		"redeemed_dialog": "Nadie vale menos por su origen o su apellido. En el plantel cabemos todos al parejo.",
		"attack_names": ["Onda de Rechazo", "Ráfaga de Prejuicios"],
	},
	BossType.CIBERACOSO: {
		"name": "Ciber-Murmullus, el Espectro de la Difamación",
		"location": "Edificio B — Biblioteca y Aulas (313 m²)",
		"max_hp": 56,
		"speed": 92.0,
		"color": Color(0.20, 0.55, 0.75),
		"accent_color": Color(0.40, 0.85, 1.0),
		"virtue": "Claridad Digital",
		"intro_dialog": "Solo le di reenviar una vez. En el grupo nadie sabe quién empezó.",
		"intro_dialog_f": "Solo le di reenviar una vez. En el grupo nadie sabe quién empezó.",
		"mid_dialogs": [
			"Si todos se ríen de la captura, entonces no es para tanto.",
			"No pensé que mañana tiene que entrar al salón con todo eso."
		],
		"redeemed_dialog": "Detrás de cada pantalla hay una persona real. Verificar antes de compartir evita herir.",
		"attack_names": ["Enjambre Teledirigido", "Salto Glitch", "Cadenas de Rumores"],
	},
	BossType.PLAGIO: {
		"name": "Plagiatrix, el Señor de la Falsedad",
		"location": "Edificio C — Cómputo y Dirección (625 m²)",
		"max_hp": 64,
		"speed": 72.0,
		"color": Color(0.35, 0.35, 0.45),
		"accent_color": Color(0.65, 0.75, 0.90),
		"virtue": "Integridad",
		"intro_dialog": "Para qué te desvelas estudiando. Clona la carpeta, cambia la portada y ya.",
		"intro_dialog_f": "Para qué te desvelas estudiando. Clona la carpeta, cambia la portada y ya.",
		"mid_dialogs": [
			"Tenía presión de reprobar si no entregaba algo a tiempo.",
			"Cuando me toca explicar mi archivo, no sé ni qué responde."
		],
		"redeemed_dialog": "Un diez copiado no sirve cuando toca resolver algo en serio. Prefiero pedir ayuda y aprender.",
		"attack_names": ["Copia Espejo", "Barrera de Atajos"],
	},
	BossType.BULLYING: {
		"name": "Titanor, el Coloso del Bullying Escolar",
		"location": "Cancha de Usos Múltiples y Gradas (540 m²)",
		"max_hp": 180,
		"speed": 88.0,
		"color": Color(0.50, 0.15, 0.35),
		"accent_color": Color(0.95, 0.30, 0.55),
		"virtue": "Fraternidad y Juego Limpio",
		"intro_dialog": "Esta cancha es mía. Aquí manda el que empuja más fuerte y calla al resto.",
		"intro_dialog_f": "Esta cancha es mía. Aquí manda el que empuja más fuerte y calla al resto.",
		"mid_dialogs": [
			"Si no impongo miedo, luego me dejan fuera a mí.",
			"Hace tiempo que nadie se sienta tranquilo conmigo en gradas."
		],
		"redeemed_dialog": "Empujaba para tapar lo solo que llegaba cada mañana. Hoy prefiero abrir la duela para todos.",
		"attack_names": [
			"Ruleta de Presión",
			"Doble Espiral",
			"Ruleta Cruzada",
			"Resplandor de Inclusión"
		],
	},
	BossType.DESINTERES: {
		"name": "Maestro Desinterés",
		"location": "Salón de Clases — Aula de Convivencia",
		"max_hp": 55,
		"speed": 85.0,
		"color": Color(0.55, 0.58, 0.62),
		"accent_color": Color(0.88, 0.92, 0.98),
		"virtue": "Escucha Presente",
		"intro_dialog": "No interrumpas, alumno, hoy tengo demasiadas actas y papeleo pendiente.",
		"intro_dialog_f": "No interrumpas, alumna, hoy tengo demasiadas actas y papeleo pendiente.",
		"mid_dialogs": [
			"Creí que era cosa pasajera entre estudiantes.",
			"Tener el escritorio limpio no sirve si el aula está tensa."
		],
		"redeemed_dialog": "Callar ante la burla también pesa. Desde hoy quien pida apoyo en clase será escuchado.",
		"attack_names": ["Mirada Distante", "Pila de Actas"],
	}
}

static func get_intro_dialog(boss_type: int, is_female: bool = false) -> String:
	var entry: Dictionary = BOSS_DATA.get(boss_type, {})
	if is_female and entry.has("intro_dialog_f"):
		return str(entry["intro_dialog_f"])
	return str(entry.get("intro_dialog", ""))

const BOSS_DIFFICULTY_HP := {
	BossType.APATIA: { 0: 16, 1: 32, 2: 65 },
	BossType.DESPERDICIO: { 0: 20, 1: 40, 2: 80 },
	BossType.INTOLERANCIA: { 0: 24, 1: 48, 2: 100 },
	BossType.CIBERACOSO: { 0: 28, 1: 56, 2: 120 },
	BossType.PLAGIO: { 0: 32, 1: 64, 2: 140 },
	BossType.BULLYING: { 0: 75, 1: 180, 2: 450 },
	BossType.DESINTERES: { 0: 25, 1: 55, 2: 120 },
}
