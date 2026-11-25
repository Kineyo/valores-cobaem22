extends RefCounted
class_name StoryData

## Base de Datos Narrativa del Modo Historia — "Campeones de los Valores"
## Plantel CEMSaD 22 ENTHAVI — Colegio de Bachilleres del Estado de México (COBAEM)
## Contiene diálogos cinematográficos, perfiles de los 7 personajes secundarios y datos de jefes redimibles.

const PROLOGUE: Dictionary = {
	"title": "Prólogo: La Bruma sobre Enthavi",
	"location": "Portón del CEMSaD 22 ENTHAVI — Amanecer en Temoaya",
	"synopsis": "Una neblina fría y silenciosa envuelve el plantel al amanecer. No trae lluvia: trae indiferencia, miedo a participar y el peso de las palabras no dichas.",
	"dialogue_nodes": [
		{
			"speaker": "Narrador",
			"portrait": "narrator",
			"text": "Son las seis y media de la mañana en Enthavi. El viento que baja del monte trae olor a tierra mojada, pero frente al portón guinda nadie bromea ni comparte los audífonos como antes.",
			"emotion": "mystic",
			"sfx": "wind"
		},
		{
			"speaker": "Narrador",
			"portrait": "narrator",
			"text": "Una bruma espesa —hecha de burlas guardadas, chats anónimos y puertas que nadie se atreve a tocar— comienza a filtrarse por el laboratorio, la cafetería y la cancha.",
			"emotion": "somber",
			"sfx": "ominous_hum"
		},
		{
			"speaker": "Guardián de los Valores",
			"portrait": "player_neutral",
			"text": "Ayer Mateo casi se devuelve a su casa antes del timbre. Hoy María limpió sola las mesas mientras otros se reían. Si nos acostumbramos a callar, esta niebla nos va a tragar a todos.",
			"emotion": "determined",
			"sfx": "step"
		},
		{
			"speaker": "Voz Ancestral de Temoaya",
			"portrait": "spirit_otomi",
			"text": "¡K'a te ma m'e̱di, joven guardián! Ninguna sombra resiste a quienes deciden cuidarse mutuamente. Cuando liberes a tus compañeros, caminarán contigo. Y si la oscuridad aprieta, recuerda la estrella dorada de la Esperanza.",
			"text_f": "¡K'a te ma m'e̱di, joven guardiana! Ninguna sombra resiste a quienes deciden cuidarse mutuamente. Cuando liberes a tus compañeros, caminarán contigo. Y si la oscuridad aprieta, recuerda la estrella dorada de la Esperanza.",
			"emotion": "warm_divine",
			"sfx": "chime"
		},
		{
			"speaker": "Guardián de los Valores",
			"portrait": "player_brave",
			"text": "No vengo a humillar a nadie ni a devolver golpes. Vengo decidido a encender el respeto edificio por edificio hasta que ninguno de los nuestros vuelva a sentirse invisible.",
			"text_f": "No vengo a humillar a nadie ni a devolver golpes. Vengo decidida a encender el respeto edificio por edificio hasta que ninguno de los nuestros vuelva a sentirse invisible.",
			"emotion": "resolute",
			"sfx": "sparkle"
		}
	]
}

const EPILOGUE: Dictionary = {
	"title": "Epílogo: Cuando Toda la Escuela Responde",
	"location": "Cancha de Usos Múltiples y Plaza Cívica — Atardecer en CEMSaD 22",
	"synopsis": "Los siete compañeros vuelven a ocupar sus espacios con voz propia. La convivencia ya no depende de un solo Guardián: ahora es tarea compartida.",
	"synopsis_f": "Los siete compañeros vuelven a ocupar sus espacios con voz propia. La convivencia ya no depende de una sola Guardiana: ahora es tarea compartida.",
	"dialogue_nodes": [
		{
			"speaker": "Narrador",
			"portrait": "narrator",
			"text": "La tarde pinta de oro el arcotecho de la cancha y la escalinata de piedra braza. La bruma no desapareció por magia: se disipó porque siete voces dejaron de tener miedo.",
			"emotion": "triumphant",
			"sfx": "fanfare_soft"
		},
		{
			"speaker": "Mateo",
			"portrait": "mateo_happy",
			"text": "Antes entraba mirando mis agujetas para pasar inadvertido. Hoy armé la primera práctica de química con gente que ni sabía mi nombre. ¡Gracias por no soltarme desde el portón, amigo!",
			"text_f": "Antes entraba mirando mis agujetas para pasar inadvertido. Hoy armé la primera práctica de química con gente que ni sabía mi nombre. ¡Gracias por no soltarme desde el portón, amiga!",
			"emotion": "joyful",
			"sfx": "bell"
		},
		{
			"speaker": "María",
			"portrait": "maria_happy",
			"text": "En el desayunador dejamos una caja de reciclaje y turnos para recoger las mesas entre grupos. Ver que nadie come apartado en las esquinas vale todo el esfuerzo, ¡gracias, compañero!",
			"text_f": "En el desayunador dejamos una caja de reciclaje y turnos para recoger las mesas entre grupos. Ver que nadie come apartado en las esquinas vale todo el esfuerzo, ¡gracias, compañera!",
			"emotion": "happy",
			"sfx": "bell"
		},
		{
			"speaker": "Valeria",
			"portrait": "valeria_happy",
			"text": "La Plaza Cívica volvió a sentirse nuestra. Subir esos escalones sin que nadie te mida por tu apellido o tu ropa es la verdadera dignidad del bachillerato.",
			"emotion": "serene_proud",
			"sfx": "bell"
		},
		{
			"speaker": "Fernanda & Diego",
			"portrait": "diego_happy",
			"text": "Cerramos las cadenas de burlas en la red y abrimos un pizarrón de dudas en biblioteca y cómputo. Quien entiende un tema se queda diez minutos más a explicarlo.",
			"emotion": "enthusiastic",
			"sfx": "chime"
		},
		{
			"speaker": "Sofía & Alejandro",
			"portrait": "alejandro_happy",
			"text": "Hasta Titanor pidió entrar de defensa en la reta sin empujones. El balón no se disfruta igual cuando juegas para lastimar que cuando juegas para que todos regresen mañana.",
			"emotion": "energetic",
			"sfx": "cheer"
		},
		{
			"speaker": "Coordinador del Plantel CEMSaD 22",
			"portrait": "coordinador",
			"text": "Jóvenes del CEMSaD 22 ENTHAVI: la paz escolar no se decreta desde una oficina; se construye en cada banca, laboratorio y pase de balón. ¡Son ejemplo vivo de nuestra comunidad!",
			"emotion": "inspirational",
			"sfx": "applause"
		},
		{
			"speaker": "Guardián de los Valores",
			"portrait": "player_celebrate",
			"text": "La mejor victoria fue descubrir que nunca estuve peleando solo. Cada compañero rescatado encendió su propia luz... y ahora todo el plantel brilla junto.",
			"text_f": "La mejor victoria fue descubrir que nunca estuve peleando sola. Cada compañero rescatado encendió su propia luz... y ahora todo el plantel brilla junto.",
			"emotion": "grateful",
			"sfx": "victory_harp"
		}
	]
}

const SECONDARY_CHARACTERS: Dictionary = {
	"mateo": {
		"id": "mateo",
		"name": "Mateo Hernández",
		"role": "1er Semestre — Nuevo Ingreso (Laboratorio D)",
		"archetype": "El novato curioso que venció el miedo a participar",
		"location_appearance": "Escenario 1 (Acceso y Edificio D)",
		"bio": "Llega diario caminando cuarenta minutos desde su comunidad. Sueña con estudiar química agrícola, pero el temor a equivocarse frente al grupo lo volvía silencioso.",
		"color_theme": Color(0.35, 0.90, 0.60),
		"state_afflicted": {
			"visual": "Acurrucado cerca de la jardinera, abrazando su bata doblada.",
			"emotion_label": "Inseguro",
			"quotes": [
				"¿Y si pregunto algo en laboratorio y todos se ríen de mí?",
				"Prefiero no abrir el portón... allá adentro ya todos tienen su grupo.",
				"Me costó mucho juntar para la bata y ya me la quieren esconder."
			]
		},
		"state_redeemed": {
			"visual": "Con paso firme y orbe esmeralda de curiosidad listo para apoyar al equipo.",
			"emotion_label": "Decidido",
			"quotes": [
				"¡Nadie nace sabiendo! Si me acompañas, te cubro los flancos.",
				"¡Vamos a devolverle la vida al laboratorio!",
				"¡Aquí estoy, compañero! Disparemos luz de entusiasmo."
			],
			"quotes_f": [
				"¡Nadie nace sabiendo! Si me acompañas, te cubro los flancos.",
				"¡Vamos a devolverle la vida al laboratorio!",
				"¡Aquí estoy, compañera! Disparemos luz de entusiasmo."
			]
		}
	},
	"maria": {
		"id": "maria",
		"name": "María López",
		"role": "2do Semestre — Brigada de Cafetería (Edificio A)",
		"archetype": "La compañera servicial que aprendió a poner límites con respeto",
		"location_appearance": "Escenario 2 (Cafetería y Edificio A)",
		"bio": "Ayuda voluntariamente en el desayunador antes de entrar a clase. Se frustraba cuando dejaban basura tirada a propósito y nadie la ayudaba a cuidar el espacio.",
		"color_theme": Color(1.0, 0.56, 0.78),
		"state_afflicted": {
			"visual": "Recogiendo charolas en silencio mientras evita mirar las mesas ocupadas.",
			"emotion_label": "Agotada",
			"quotes": [
				"No cuesta nada poner la basura en su lugar, ¿por qué les da risa tirarla?",
				"Siempre me dejan las bancas pegajosas y nadie dice nada...",
				"Siento que cuidar la escuela solo nos importa a unos pocos."
			]
		},
		"state_redeemed": {
			"visual": "Con su mandil limpio y destellos cálidos de hospitalidad y firmeza.",
			"emotion_label": "Solidaria",
			"quotes": [
				"¡Cuidar nuestra mesa es respetar a quien madrugó para servir!",
				"¡Te respaldo, amigo! Ningún desperdicio va a apagar esta cafetería.",
				"¡Juntos mantenemos limpio cada rincón del Edificio A!"
			],
			"quotes_f": [
				"¡Cuidar nuestra mesa es respetar a quien madrugó para servir!",
				"¡Te respaldo, amiga! Ningún desperdicio va a apagar esta cafetería.",
				"¡Juntas mantenemos limpio cada rincón del Edificio A!"
			]
		}
	},
	"valeria": {
		"id": "valeria",
		"name": "Valeria Morales",
		"role": "3er Semestre — Comité Cívico (Plaza Cívica)",
		"archetype": "La voz firme de la igualdad y el orgullo otomí",
		"location_appearance": "Escenario 3 (Plaza Cívica y Escalinata Sur)",
		"bio": "Coordina los lunes cívicos y defiende la lengua e historia de Temoaya. No tolera que la escalinata se use para humillar a quien viene de abajo.",
		"color_theme": Color(0.38, 0.92, 1.0),
		"state_afflicted": {
			"visual": "Detenida al pie de la escalinata sur, sujetando su mochila con coraje contenido.",
			"emotion_label": "Indignada",
			"quotes": [
				"Bloquearon los escalones diciendo que 'este nivel no es para cualquiera'.",
				"Se burlan del acento de nuestros abuelos como si fuera motivo de vergüenza.",
				"¿Cómo vamos a honrar la plaza si nos miramos por encima del hombro?"
			]
		},
		"state_redeemed": {
			"visual": "Erguida en la explanada con brillo cívico, lista para combatir junto al Guardián.",
			"visual_f": "Erguida en la explanada con brillo cívico, lista para combatir junto a la Guardiana.",
			"emotion_label": "Valiente",
			"quotes": [
				"¡En el CEMSaD 22 nadie vale menos por su origen o su apellido!",
				"¡Caminemos hombro a hombro hacia arriba, la plaza es de todos!",
				"¡Aquí va mi respeto por delante, compañero!"
			],
			"quotes_f": [
				"¡En el CEMSaD 22 nadie vale menos por su origen o su apellido!",
				"¡Caminemos hombro a hombro hacia arriba, la plaza es de todos!",
				"¡Aquí va mi respeto por delante, compañera!"
			]
		}
	},
	"fernanda": {
		"id": "fernanda",
		"name": "Fernanda Ortiz",
		"role": "4to Semestre — Círculo de Lectura (Biblioteca B)",
		"archetype": "La lectora analítica que enfrenta la desinformación",
		"location_appearance": "Escenario 4 (Edificio B y Biblioteca)",
		"bio": "Cataloga libros usados en la biblioteca para que todos tengan guías de examen. Se indignó cuando los chismes digitales espantaron a sus compañeras de estudio.",
		"color_theme": Color(0.55, 0.80, 1.0),
		"state_afflicted": {
			"visual": "Escondida entre estantes vacíos, limpiándose los lentes con preocupación.",
			"emotion_label": "Preocupada",
			"quotes": [
				"Un rumor falso en diez segundos dañó la amistad de todo un semestre...",
				"Ya nadie viene a estudiar a la biblioteca por miedo a las fotos editadas.",
				"La verdad queda enterrada cuando nadie verifica antes de reenviar."
			]
		},
		"state_redeemed": {
			"visual": "Acompañando activamente al jugador con ráfagas de claridad y verdad.",
			"emotion_label": "Lúcida",
			"quotes": [
				"¡Pensar antes de compartir también es valentía!",
				"¡La biblioteca vuelve a ser un refugio seguro!",
				"¡Apuntando a la verdad, aquí tienes mi apoyo, compañero!"
			],
			"quotes_f": [
				"¡Pensar antes de compartir también es valentía!",
				"¡La biblioteca vuelve a ser un refugio seguro!",
				"¡Apuntando a la verdad, aquí tienes mi apoyo, compañera!"
			]
		}
	},
	"diego": {
		"id": "diego",
		"name": "Diego Ramírez",
		"role": "5to Semestre — Taller de Cómputo (Edificio C)",
		"archetype": "El programador ético que defiende el esfuerzo propio",
		"location_appearance": "Escenario 5 (Edificio C y Cómputo)",
		"bio": "Mantiene vivas las computadoras del taller con software libre. Se negó a vender respuestas de exámenes cuando Plagiatrix intentó corromper el aula.",
		"color_theme": Color(0.42, 0.65, 1.0),
		"state_afflicted": {
			"visual": "Con sus audífonos al cuello frente a pantallas bloqueadas por copias.",
			"emotion_label": "Frustrado",
			"quotes": [
				"Se burlan de mí por quedarme desvelado programando en vez de copiar...",
				"Hackearon la carpeta de proyectos para vender trabajos ajenos.",
				"Si todos aprobamos haciendo trampa, ¿quién va a saber hacer las cosas afuera?"
			]
		},
		"state_redeemed": {
			"visual": "Desplegando código limpio y proyectiles de integridad digital en batalla.",
			"emotion_label": "Íntegro",
			"quotes": [
				"¡Código limpio, mente limpia! Vamos por ese antivalor.",
				"¡Compartir apuntes sí; robar mérito jamás!",
				"¡Te cubro desde el flanco con ciudadanía digital, compañero!"
			],
			"quotes_f": [
				"¡Código limpio, mente limpia! Vamos por ese antivalor.",
				"¡Compartir apuntes sí; robar mérito jamás!",
				"¡Te cubro desde el flanco con ciudadanía digital, compañera!"
			]
		}
	},
	"sofia": {
		"id": "sofia",
		"name": "Sofía Valdés",
		"role": "5to Semestre — Representante Estudiantil (Dirección)",
		"archetype": "La mediadora que convirtió el papeleo en escucha real",
		"location_appearance": "Escenario 5 (Dirección y Aulas C)",
		"bio": "Lleva su portapapeles con reportes reales de convivencia. Aprendió que escuchar de frente vale más que archivar actas sin resolver los problemas.",
		"color_theme": Color(0.84, 0.58, 1.0),
		"state_afflicted": {
			"visual": "Sosteniendo un montón de solicitudes sin firmar frente a la puerta cerrada.",
			"emotion_label": "Impotente",
			"quotes": [
				"Llevo semanas entregando reportes de acoso y solo me dicen 'luego lo vemos'.",
				"De nada sirve un brazalete de representante si los pasillos siguen fríos.",
				"Necesitamos adultos y jóvenes dispuestos a actuar, no a mirar hacia otro lado."
			]
		},
		"state_redeemed": {
			"visual": "Determinada, coordinando el fuego cruzado aliado con empatía y liderazgo.",
			"emotion_label": "Firme",
			"quotes": [
				"¡Nuestras voces cuentan hoy, no hasta que termine el semestre!",
				"¡En equipo somos más fuertes que cualquier niebla!",
				"¡Avanza, Guardián! Nosotros mantenemos la línea contigo."
			],
			"quotes_f": [
				"¡Nuestras voces cuentan hoy, no hasta que termine el semestre!",
				"¡En equipo somos más fuertes que cualquier niebla!",
				"¡Avanza, Guardiana! Nosotros mantenemos la línea contigo."
			]
		}
	},
	"alejandro": {
		"id": "alejandro",
		"name": "Alejandro 'Ale' Cruz",
		"role": "6to Semestre — Capitán de Básquetbol (Cancha)",
		"archetype": "El deportista que eligió el juego limpio sobre la ley del más fuerte",
		"location_appearance": "Escenario 6 (Cancha de Usos Múltiples)",
		"bio": "Ama la cancha desde primer semestre. No soportó ver cómo Titanor convertía los partidos en un ring de humillaciones contra los más chicos.",
		"color_theme": Color(1.0, 0.68, 0.25),
		"state_afflicted": {
			"visual": "Apretando su balón junto a las gradas con una curita en la mejilla.",
			"emotion_label": "Desalentado",
			"quotes": [
				"La cancha era el único lugar donde todos éramos iguales... hasta que llegó el miedo.",
				"Me sacaron a empujones por defender a un compañero de primero.",
				"Un partido ganado a golpes no tiene honor ni alegría."
			]
		},
		"state_redeemed": {
			"visual": "Listo en la duela con pase preciso de luz solidaria hacia el jefe final.",
			"emotion_label": "Imparable",
			"quotes": [
				"¡Nadie juega solo en esta cancha, campeón! ¡Pase limpio y corazón valiente!",
				"¡Si Titanor lanza clones o niebla, busca la estrella de Esperanza!",
				"¡Todos al ataque fraterno! ¡Por el juego limpio del COBAEM!"
			],
			"quotes_f": [
				"¡Nadie juega sola en esta cancha, campeona! ¡Pase limpio y corazón valiente!",
				"¡Si Titanor lanza clones o niebla, busca la estrella de Esperanza!",
				"¡Todos al ataque fraterno! ¡Por el juego limpio del COBAEM!"
			]
		}
	}
}

const BOSSES: Dictionary = {
	1: {
		"id": "apatyx",
		"name": "Apatyx, el Espectro del Desgano",
		"scenario_id": 1,
		"location": "Plaza de Acceso y Edificio D (Laboratorio)",
		"antivalue": "La Apatía y la Desidia Escolar",
		"redeeming_virtue": "¡Entusiasmo, Compromiso y Esperanza!",
		"pre_battle_quote": "¿Para qué cruzar el portón? Nadie nota tu esfuerzo.",
		"redemption_speech": "Tenía miedo de intentarlo y fallar... ¡Vuelvo a encender el laboratorio!"
	},
	2: {
		"id": "desperdicius",
		"name": "Desperdicius, el Titán del Desperdicio",
		"scenario_id": 2,
		"location": "Cafetería y Desayunador del Edificio A",
		"antivalue": "El Desperdicio y la Desconsideración",
		"redeeming_virtue": "¡Gratitud y Cuidado Comunitario!",
		"pre_battle_quote": "Tira todo al piso, que alguien más limpie por ti.",
		"redemption_speech": "Olvidé cuánto cuesta cada plato servido aquí. ¡Cuidemos este espacio!"
	},
	3: {
		"id": "superbus",
		"name": "Superbus, el Heraldo de la Arrogancia",
		"scenario_id": 3,
		"location": "Plaza Cívica y Escalinata Sur (+4m)",
		"antivalue": "La Soberbia y la Exclusión",
		"redeeming_virtue": "¡Humildad y Fraternidad!",
		"pre_battle_quote": "Esta terraza tiene nivel; los de abajo no pertenecen aquí.",
		"redemption_speech": "Esta escalinata nos une, no nos divide. ¡Todos merecemos respeto!"
	},
	4: {
		"id": "murmullus",
		"name": "Ciber-Murmullus, el Espectro de la Difamación",
		"scenario_id": 4,
		"location": "Edificio B — Aulas 3-4 y Biblioteca",
		"antivalue": "El Ciberacoso y el Rumor Anónimo",
		"redeeming_virtue": "¡Verdad y Ciudadanía Digital!",
		"pre_battle_quote": "Un reenvío anónimo y nadie sabrá quién rompió su paz.",
		"redemption_speech": "Detrás de cada pantalla hay una persona real. ¡Basta de rumores crueles!"
	},
	5: {
		"id": "plagiatrix",
		"name": "Plagiatrix, el Señor de la Falsedad",
		"scenario_id": 5,
		"location": "Edificio C — Dirección y Taller de Cómputo",
		"antivalue": "El Plagio y el Atajo Deshonesto",
		"redeeming_virtue": "¡Honestidad Académica e Integridad!",
		"pre_battle_quote": "Copia y pega el trabajo ajeno; nadie premia el desvelo.",
		"redemption_speech": "Un diploma sin esfuerzo deja vacía el alma. ¡Defenderé mi propia voz!"
	},
	6: {
		"id": "titanor",
		"name": "Titanor, el Coloso del Bullying Escolar",
		"scenario_id": 6,
		"location": "Cancha de Usos Múltiples y Gradas",
		"antivalue": "La Intimidación y la Ley del Más Fuerte",
		"redeeming_virtue": "¡Solidaridad, Juego Limpio y Esperanza!",
		"pre_battle_quote": "¡En esta cancha manda el miedo y los golpes!",
		"redemption_speech": "Golpeaba para esconder mi propio temor... ¡Hoy protejo a mi plantel!"
	}
}

const SCENARIO_CUTSCENES: Dictionary = {
	1: {
		"id": 1,
		"title": "Acto I: El Primer Paso en el Portón",
		"scenario_name": "Acceso, Caseta C.V. y Edificio D",
		"real_space": "Portón Principal, Jardinera y Laboratorio de Usos Múltiples (183 m²)",
		"dialogue_nodes": [
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_neutral",
				"text": "El portón del CEMSaD 22 siempre fue bullicioso a esta hora... pero la niebla que baja hacia el laboratorio hace que los pies pesen el doble. Aun así, estoy listo para ayudar.",
				"text_f": "El portón del CEMSaD 22 siempre fue bullicioso a esta hora... pero la niebla que baja hacia el laboratorio hace que los pies pesen el doble. Aun así, estoy lista para ayudar.",
				"emotion": "attentive"
			},
			{
				"speaker": "Mateo",
				"portrait": "mateo_sad",
				"text": "Si doy un paso más, seguro me preguntan en clase y me equivoco... Todos parecen saber ya qué hacer menos yo. Quizá no debí inscribirme.",
				"emotion": "scared"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_brave",
				"text": "Escúchame bien, Mateo: nadie entra a la prepa sabiéndolo todo. Cuando disipemos esta apatía, tú también tendrás tu lugar... y lucharemos espalda con espalda.",
				"emotion": "determined"
			},
			{
				"speaker": "Apatyx",
				"portrait": "boss_apatyx",
				"text": "Qué discurso tan agotador, jovencito... Los matraces del laboratorio llevan días cubiertos de polvo. ¿Para qué esforzarse si da lo mismo aprobar que rendirse?",
				"text_f": "Qué discurso tan agotador, jovencita... Los matraces del laboratorio llevan días cubiertos de polvo. ¿Para qué esforzarse si da lo mismo aprobar que rendirse?",
				"emotion": "angry"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_attack",
				"text": "Porque cada pregunta honesta enciende una mente nueva. ¡Mateo, quédate detrás de mí hasta que despejemos la sombra de Apatyx!",
				"emotion": "determined"
			}
		]
	},
	2: {
		"id": 2,
		"title": "Acto II: La Mesa Compartida",
		"scenario_name": "Edificio A — Cafetería, Desayunador y Aulas 1-2",
		"real_space": "Pasillo de Aulas 1-2 y Mesas de Picnic bajo Arcotecho",
		"dialogue_nodes": [
			{
				"speaker": "María",
				"portrait": "maria_sad",
				"text": "¡Qué bueno que llegaste, compañero! Las señoras del desayunador prepararon comida caliente desde las cinco de la mañana, pero un grupo volcó los platos en la banca y se marchó riendo.",
				"text_f": "¡Qué bueno que llegaste, compañera! Las señoras del desayunador prepararon comida caliente desde las cinco de la mañana, pero un grupo volcó los platos en la banca y se marchó riendo.",
				"emotion": "scared"
			},
			{
				"speaker": "Desperdicius",
				"portrait": "boss_desperdicius",
				"text": "¡Ja! Si no quieren recoger envolturas, pongan menos mesas. Aquí manda el que consume sin mirar a quién deja limpiando atrás.",
				"emotion": "angry"
			},
			{
				"speaker": "Mateo",
				"portrait": "mateo_happy",
				"text": "¡Ya no te vamos a dejar sola, María! Cuando nos cuidamos entre compañeros, hasta el patio más sucio vuelve a brillar.",
				"emotion": "happy"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_brave",
				"text": "Respetar el alimento y a quien nos sirve no es opcional. ¡Desperdicius, hoy aprenderás el valor de compartir con gratitud!",
				"emotion": "determined"
			}
		]
	},
	3: {
		"id": 3,
		"title": "Acto III: Cuatro Metros de Dignidad",
		"scenario_name": "Plaza Cívica (748 m²) y Escalinata Sur (+4m)",
		"real_space": "Asta Bandera, Muro de Piedra Braza Negra y Escalinata Sur",
		"dialogue_nodes": [
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_neutral",
				"text": "Aquí cantamos el himno cada lunes frente al asta bandera. Pero alguien trazó una frontera invisible justo en la escalinata sur.",
				"emotion": "solemn"
			},
			{
				"speaker": "Valeria",
				"portrait": "valeria_sad",
				"text": "Dicen que quienes hablan con acento de comunidad o traen los zapatos gastados no deberían subir a la terraza superior. ¡Eso no es mi COBAEM!",
				"emotion": "angry"
			},
			{
				"speaker": "Superbus",
				"portrait": "boss_superbus",
				"text": "La altura existe para recordar quién está arriba y quién debe bajar la vista. No todos nacieron para pisar el primer escalón.",
				"emotion": "angry"
			},
			{
				"speaker": "Valeria",
				"portrait": "valeria_brave",
				"text": "¡Esta piedra braza la levantaron manos trabajadoras de Enthavi! Cuando me liberes, Guardián, mis chispas cívicas también pelearán a tu lado.",
				"text_f": "¡Esta piedra braza la levantaron manos trabajadoras de Enthavi! Cuando me liberes, Guardiana, mis chispas cívicas también pelearán a tu lado.",
				"emotion": "determined"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_attack",
				"text": "¡La soberbia pesa más de lo que protege! ¡Demostremos en la plaza que la dignidad no conoce escalones!",
				"emotion": "determined"
			}
		]
	},
	4: {
		"id": 4,
		"title": "Acto IV: Detrás de la Pantalla",
		"scenario_name": "Edificio B — Aulas 3-4 y Biblioteca Escolar",
		"real_space": "Terraza Superior (+4m), Barandal Blanco y Biblioteca",
		"dialogue_nodes": [
			{
				"speaker": "Fernanda",
				"portrait": "fernanda_sad",
				"text": "Mira la biblioteca, amigo... vacía. Alguien creó una página anónima para burlarse de las fotos de clase y ahora varios compañeros temen abrir su mochila.",
				"text_f": "Mira la biblioteca, amiga... vacía. Alguien creó una página anónima para burlarse de las fotos de clase y ahora varios compañeros temen abrir su mochila.",
				"emotion": "scared"
			},
			{
				"speaker": "Ciber-Murmullus",
				"portrait": "boss_murmullus",
				"text": "Qué frágiles son... Solo presioné 'reenviar' una vez y el rumor hizo el resto. En la red nadie tiene rostro ni culpa.",
				"emotion": "angry"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_brave",
				"text": "Herir desde el anonimato es doble cobardía. Las pantallas sirven para acercarnos y aprender, no para acorralar en silencio a un compañero.",
				"emotion": "determined"
			}
		]
	},
	5: {
		"id": 5,
		"title": "Acto V: Sin Atajos ni Silencios",
		"scenario_name": "Edificio C — Dirección y Taller de Cómputo",
		"real_space": "Dirección Escolar, Aula 5, Rampa Verde y Taller de Cómputo (115.2 m²)",
		"dialogue_nodes": [
			{
				"speaker": "Diego",
				"portrait": "diego_sad",
				"text": "¡Qué alivio verte, compañero! Plagiatrix metió archivos falsos en los equipos de cómputo y convenció a medio grupo de copiar los proyectos finales sin entender una sola línea.",
				"text_f": "¡Qué alivio verte, compañera! Plagiatrix metió archivos falsos en los equipos de cómputo y convenció a medio grupo de copiar los proyectos finales sin entender una sola línea.",
				"emotion": "scared"
			},
			{
				"speaker": "Sofía",
				"portrait": "sofia_sad",
				"text": "Y en el pasillo de Dirección nuestros reportes siguen esperando firma. Si los salones interiores siguen cerrados a la empatía, esta niebla nunca se irá.",
				"emotion": "determined"
			},
			{
				"speaker": "Plagiatrix",
				"portrait": "boss_plagiatrix",
				"text": "¿Para qué quemarse las pestañas estudiando? Clona la respuesta, entrega el papel y disfruta del premio sin esfuerzo.",
				"emotion": "angry"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_attack",
				"text": "Un logro robado se quiebra en la primera prueba real de la vida. ¡Diego, Sofía, recuperemos la honestidad y la escucha en el Edificio C!",
				"emotion": "determined"
			}
		]
	},
	6: {
		"id": 6,
		"title": "Acto VI: Toda la Escuela en la Cancha",
		"scenario_name": "Cancha de Usos Múltiples (540 m²) y Gradas",
		"real_space": "Pavimento Deportivo, Tableros de Básquetbol y Bancas de Estudio",
		"dialogue_nodes": [
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_neutral",
				"text": "La cancha de usos múltiples... Aquí convergen todos los caminos del CEMSaD 22. Y ahí al centro nos espera la raíz de todo este miedo.",
				"emotion": "solemn"
			},
			{
				"speaker": "Alejandro",
				"portrait": "alejandro_sad",
				"text": "¡Ten cuidado, campeón! Titanor se rodea de clones de sombra y oscurece la cancha entera con niebla. Pero si encuentras la estrella dorada de Esperanza [Q], ¡quedarán anulados por 15 segundos!",
				"text_f": "¡Ten cuidado, campeona! Titanor se rodea de clones de sombra y oscurece la cancha entera con niebla. Pero si encuentras la estrella dorada de Esperanza [Q], ¡quedarán anulados por 15 segundos!",
				"emotion": "determined"
			},
			{
				"speaker": "Titanor",
				"portrait": "boss_titanor",
				"text": "¿De verdad creyeron que unos cuantos valores iban a frenarme? En esta cancha solo sobrevive quien golpea primero y hace callar al resto!",
				"emotion": "angry"
			},
			{
				"speaker": "Mateo & Valeria & Sofía",
				"portrait": "allies_united",
				"text": "¡Se acabó el miedo, Titanor! Ya no tienes enfrente a alumnos aislados: hoy todo el plantel pelea unido en esta duela!",
				"emotion": "happy"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_attack",
				"text": "¡Compañeros, cubramos la cancha con luz de fraternidad! ¡Titanor, hoy soltarás esa armadura de rencor!",
				"emotion": "determined"
			}
		]
	}
}

static func is_female_selected(override_gender: int = -1) -> bool:
	if override_gender >= 0:
		return override_gender == 1
	var ml := Engine.get_main_loop()
	if ml is SceneTree:
		var root := (ml as SceneTree).root
		if root:
			var gs := root.get_node_or_null("GameSettings")
			if gs and "selected_character" in gs:
				return int(gs.selected_character) == 1
	return false

static func get_protagonist_speaker(override_gender: int = -1) -> String:
	return "Guardiana de los Valores" if is_female_selected(override_gender) else "Guardián de los Valores"

static func _adapt_cutscene_for_gender(raw_data: Dictionary, is_fem: bool) -> Dictionary:
	if raw_data.is_empty():
		return {}
	var adapted := raw_data.duplicate(true)
	if is_fem and adapted.has("synopsis_f"):
		adapted["synopsis"] = adapted["synopsis_f"]
	if adapted.has("dialogue_nodes") and adapted["dialogue_nodes"] is Array:
		var nodes: Array = adapted["dialogue_nodes"]
		for i in range(nodes.size()):
			if nodes[i] is Dictionary:
				var nd: Dictionary = nodes[i]
				if is_fem:
					if str(nd.get("speaker", "")) == "Guardián de los Valores":
						nd["speaker"] = "Guardiana de los Valores"
					elif str(nd.get("speaker", "")) == "Guardián":
						nd["speaker"] = "Guardiana"
					if nd.has("text_f"):
						nd["text"] = nd["text_f"]
	return adapted

static func get_prologue(override_gender: int = -1) -> Dictionary:
	return _adapt_cutscene_for_gender(PROLOGUE, is_female_selected(override_gender))

static func get_epilogue(override_gender: int = -1) -> Dictionary:
	return _adapt_cutscene_for_gender(EPILOGUE, is_female_selected(override_gender))

static func get_scenario_cutscene(scenario_id: int, override_gender: int = -1) -> Dictionary:
	var raw: Dictionary = SCENARIO_CUTSCENES.get(scenario_id, {})
	return _adapt_cutscene_for_gender(raw, is_female_selected(override_gender))

static func get_secondary_character(character_id: String, override_gender: int = -1) -> Dictionary:
	var key := character_id.to_lower().strip_edges()
	key = key.replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u").replace("ñ", "n")
	if key == "emiliano":
		key = "alejandro"
	var raw: Dictionary = SECONDARY_CHARACTERS.get(key, {})
	if raw.is_empty():
		return {}
	var adapted := raw.duplicate(true)
	if is_female_selected(override_gender):
		for st_key in ["state_afflicted", "state_redeemed"]:
			if adapted.has(st_key) and adapted[st_key] is Dictionary:
				var st_dict: Dictionary = adapted[st_key]
				if st_dict.has("visual_f"):
					st_dict["visual"] = st_dict["visual_f"]
				if st_dict.has("quotes_f"):
					st_dict["quotes"] = st_dict["quotes_f"]
	return adapted

static func get_boss(scenario_id: int) -> Dictionary:
	return BOSSES.get(scenario_id, {})
