extends Control
class_name StoryData

## Guión oficial, perfiles humanos y actos del Modo Historia (CEMSaD 22 ENTHAVI).
## Sin signos de exclamación/interrogación ni muletillas artificiales.
## Cada compañero refleja sus hábitos reales, dudas cotidianas y su propio disparo de valor.

const PROLOGUE: Dictionary = {
	"title": "Prólogo: 6:30 a.m. en el Portón",
	"location": "Portón del CEMSaD 22 ENTHAVI — Amanecer frío en Temoaya",
	"synopsis": "La Bruma de Enthavi baja del cerro como un amplificador emocional: vuelve visibles los silencios y burlas que la escuela llevaba meses callando.",
	"dialogue_nodes": [
		{
			"speaker": "Narrador",
			"portrait": "narrator",
			"emotion": "calm",
			"text": "Son las 6:30 de la mañana en Temoaya. La neblina sube despacio desde las barrancas hasta el portón blanco y guinda del CEMSaD 22 ENTHAVI."
		},
		{
			"speaker": "Guardián de los Valores",
			"portrait": "player_neutral",
			"emotion": "curious",
			"text": "Hoy los pasillos suenan demasiado callados. Nadie se saluda cerca de la caseta y todos caminan mirando hacia el suelo.",
			"text_f": "Hoy los pasillos suenan demasiado callados. Nadie se saluda cerca de la caseta y todas y todos caminan mirando hacia el suelo."
		},
		{
			"speaker": "Mateo",
			"portrait": "mateo_sad",
			"emotion": "scared",
			"text": "Escuché que si preguntas algo en laboratorio, varios se ríen bajito desde atrás. Mejor guardo la bata hasta que pase el receso."
		},
		{
			"speaker": "Guardián de los Valores",
			"portrait": "player_neutral",
			"emotion": "calm",
			"text": "No hace falta pasar el día escondiendo lo que sabes o lo que sientes. Vamos paso a paso por cada edificio."
		},
		{
			"speaker": "Guardián de los Valores",
			"portrait": "player_brave",
			"emotion": "determined",
			"text": "Estoy decidido a abrir el diálogo desde el primer patio para que nadie vuelva a sentir miedo en su propia escuela.",
			"text_f": "Estoy decidida a abrir el diálogo desde el primer patio para que nadie vuelva a sentir miedo en su propia escuela."
		}
	]
}

const EPILOGUE: Dictionary = {
	"title": "Epílogo: Tarde Clara en la Cancha",
	"location": "Cancha de Usos Múltiples y Plaza Cívica — Atardecer en CEMSaD 22",
	"synopsis": "Los siete compañeros recuperan su voz en comunidad. La convivencia ya no depende de una sola persona, ahora la sostienen entre todos.",
	"dialogue_nodes": [
		{
			"speaker": "Narrador",
			"portrait": "narrator",
			"emotion": "joyful",
			"text": "La neblina se disipa por completo sobre el domo y las gradas. El rumor frío desaparece entre saludos reales y música de fondo."
		},
		{
			"speaker": "Mateo",
			"portrait": "mateo_happy",
			"emotion": "happy",
			"text": "En el laboratorio ya nadie se queda callado cuando tiene una duda. Hasta quienes llegamos caminando desde lejos compartimos mesa sin pena."
		},
		{
			"speaker": "María",
			"portrait": "maria_happy",
			"emotion": "happy",
			"text": "Las mesas del desayunador se limpian por turnos entre todos. Se siente distinto cuando el respeto deja de ser carga de uno solo."
		},
		{
			"speaker": "Valeria",
			"portrait": "valeria_happy",
			"emotion": "happy",
			"text": "Subimos la escalinata al mismo paso y sin etiquetas. Cada quien aporta su acento y su ritmo."
		},
		{
			"speaker": "Fernanda & Diego",
			"portrait": "diego_happy",
			"emotion": "happy",
			"text": "Entre apuntes reales en biblioteca y señales abiertas en cómputo, los rumores pierden fuerza antes de crecer."
		},
		{
			"speaker": "Sofía & Alejandro",
			"portrait": "alejandro_happy",
			"emotion": "happy",
			"text": "Organizamos turnos claros para estudiar y retas limpias donde también entran los de primer semestre."
		},
		{
			"speaker": "Coordinador del Plantel CEMSaD 22",
			"portrait": "coordinador",
			"emotion": "proud_firm",
			"text": "Hoy la cancha no celebra a un héroe aislado, sino a toda una generación que aprendió a escucharse con respeto."
		},
		{
			"speaker": "Guardián de los Valores",
			"portrait": "player_celebrate",
			"emotion": "joyful",
			"text": "Entendí que nunca estuve avanzando solo. La convivencia sana se cuida todos los días en cada saludo.",
			"text_f": "Entendí que nunca estuve avanzando sola. La convivencia sana se cuida todos los días en cada saludo."
		}
	]
}

const SECONDARY_CHARACTERS: Dictionary = {
	"mateo": {
		"id": "mateo",
		"name": "Mateo Hernández",
		"role": "1er Semestre — Nuevo Ingreso (Laboratorio D)",
		"portrait": "mateo_happy",
		"mood": "Curioso, paciente y observador",
		"mania": "Anota cada reacción química en márgenes pequeños y siempre lleva un frasco de semillas de estudio.",
		"flaw": "Se queda en silencio por temor a parecer lento cuando todo el grupo ya avanzó.",
		"bond": "María le aparta un vaso caliente en el desayunador cuando llega temprano después de caminar 40 minutos.",
		"special_attack": "Triple Reacción — Abanico de tres chispas de estudio; la central calma el paso de los antivalores.",
		"theme": "Curiosidad sin miedo",
		"state_afflicted": {
			"visual": "Acurrucado cerca de la jardinera, apretando su bata doblada.",
			"visual_f": "Acurrucado cerca de la jardinera, apretando su bata doblada.",
			"quotes": [
				"Prefiero no preguntar para que no se burlen.",
				"Ya todos entendieron la fórmula menos yo."
			]
		},
		"state_redeemed": {
			"visual": "Con paso firme y su Triple Reacción lista para apoyar al equipo.",
			"visual_f": "Con paso firme y su Triple Reacción lista para apoyar al equipo.",
			"quotes": [
				"Gracias por darme la palabra, compañero.",
				"Ahora sí me atrevo a preguntar frente al grupo."
			],
			"quotes_f": [
				"Gracias por darme la palabra, compañera.",
				"Ahora sí me atrevo a preguntar frente al grupo."
			]
		}
	},
	"maria": {
		"id": "maria",
		"name": "María López",
		"role": "2do Semestre — Brigada de Cafetería (Edificio A)",
		"portrait": "maria_happy",
		"mood": "Atenta, ordenada y directa",
		"mania": "Recuerda quién no desayunó antes de primera hora y siempre revisa que las bancas queden limpias.",
		"flaw": "Carga trabajo ajeno diciendo que no pasa nada hasta terminar agotada.",
		"bond": "Cuida que Mateo alcance mesa al llegar y aprende a pedir turnos compartidos sin sentirse culpable.",
		"special_attack": "Escudo Firme — Aro azul de respeto que barre proyectiles hostiles a su paso.",
		"theme": "Límites claros con respeto",
		"state_afflicted": {
			"visual": "Recogiendo charolas en silencio mientras suspira cansada.",
			"visual_f": "Recogiendo charolas en silencio mientras suspira cansada.",
			"quotes": [
				"Siempre dejan las mesas llenas y ni siquiera miran atrás.",
				"Me da pena pedir ayuda porque siento que van a molestarse."
			]
		},
		"state_redeemed": {
			"visual": "Con su mandil limpio y su Escudo Firme abriendo paso.",
			"visual_f": "Con su mandil limpio y su Escudo Firme abriendo paso.",
			"quotes": [
				"Juntos podemos cuidar mejor la cafetería y cada pasillo.",
				"Cuidar de los demás también significa poner límites sanos."
			],
			"quotes_f": [
				"Juntas podemos cuidar mejor la cafetería y cada pasillo.",
				"Cuidar de las demás personas también significa poner límites sanos."
			]
		}
	},
	"valeria": {
		"id": "valeria",
		"name": "Valeria Morales",
		"role": "3er Semestre — Comité Cívico (Plaza Cívica)",
		"portrait": "valeria_happy",
		"mood": "Expresiva, leal y firme",
		"mania": "Teje pulseras con diseños de Temoaya y ensaya el orden de las ceremonias antes del timbre.",
		"flaw": "Se vuelve seca y distante como defensa cuando alguien imita su manera de hablar.",
		"bond": "Reconoce al protagonista desde las primeras ceremonias y encuentra calma escuchando los chistes de Alejandro.",
		"special_attack": "Pulso Estéreo — Dos ondas sonoras curvas que convergen con equilibrio.",
		"theme": "Dignidad e inclusión",
		"state_afflicted": {
			"visual": "Detenida al pie de la escalinata sur, sujetando la correa de su mochila.",
			"visual_f": "Detenida al pie de la escalinata sur, sujetando la correa de su mochila.",
			"quotes": [
				"Se ríen de mi acento en cuanto tomo el micrófono.",
				"Para qué subo al frente si nadie va a escuchar."
			]
		},
		"state_redeemed": {
			"visual": "Erguida en la explanada con su Pulso Estéreo afinado.",
			"visual_f": "Erguida en la explanada con su Pulso Estéreo afinado.",
			"quotes": [
				"Nuestra historia de Temoaya camina al parejo de todo el grupo.",
				"Cuando hablamos en coro, nadie se queda atrás."
			],
			"quotes_f": [
				"Nuestra historia de Temoaya camina al parejo de todo el grupo.",
				"Cuando hablamos juntas, nadie se queda atrás."
			]
		}
	},
	"fernanda": {
		"id": "fernanda",
		"name": "Fernanda Ortiz",
		"role": "4to Semestre — Círculo de Lectura (Biblioteca B)",
		"portrait": "fernanda_biblioteca",
		"mood": "Reflexiva, irónica y protectora",
		"mania": "Deja notas breves entre capítulos prestados para animar a quien estudia antes de un examen.",
		"flaw": "Evitaba desmentir rumores en el grupo para no quedar señalada.",
		"bond": "Intercambia guías resumidas con Diego y verifica datos antes de que un chisme llegue a Dirección.",
		"special_attack": "Nota al Margen — Marcador de lectura que ubica y alcanza al origen del ruido.",
		"theme": "Honestidad y verificación",
		"state_afflicted": {
			"visual": "Detrás de un librero alto, doblando y desdoblando una hoja de apuntes.",
			"visual_f": "Detrás de un librero alto, doblando y desdoblando una hoja de apuntes.",
			"quotes": [
				"Prefiero no meterme en el chat aunque sepa que la captura es falsa.",
				"Cada día llega menos gente a leer por miedo a las burlas."
			]
		},
		"state_redeemed": {
			"visual": "Acompañando al equipo con sus Notas al Margen luminosas.",
			"visual_f": "Acompañando al equipo con sus Notas al Margen luminosas.",
			"quotes": [
				"Callar frente a un rumor injusto también lastima al grupo.",
				"Aclarar una fuente a tiempo devuelve tranquilidad al salón."
			]
		}
	},
	"diego": {
		"id": "diego",
		"name": "Diego Ramírez",
		"role": "5to Semestre — Taller de Cómputo (Edificio C)",
		"portrait": "diego_happy",
		"mood": "Ingenioso, directo y solidario",
		"mania": "Etiqueta cada equipo reparado con calcomanías de gatos y arma repositorios locales sin internet.",
		"flaw": "Responde cortante cuando está saturado y prefiere aislarse frente al monitor.",
		"bond": "Hace mancuerna con Sofía para convertir guías técnicas en sesiones claras para todo el semestre.",
		"special_attack": "Señal Abierta — Pulso compartido que limpia proyectiles hostiles alrededor.",
		"theme": "Tecnología ética y trabajo en equipo",
		"state_afflicted": {
			"visual": "Frente a una pantalla saturada de archivos repetidos sin autoría.",
			"visual_f": "Frente a una pantalla saturada de archivos repetidos sin autoría.",
			"quotes": [
				"Todos quieren el archivo resuelto en cinco minutos sin entender nada.",
				"Mejor trabajo solo y cierro la puerta del taller."
			]
		},
		"state_redeemed": {
			"visual": "Compartiendo su Señal Abierta desde el taller para cuidar al equipo.",
			"visual_f": "Compartiendo su Señal Abierta desde el taller para cuidar al equipo.",
			"quotes": [
				"Compartir conocimiento sirve más que guardarse los atajos.",
				"Cuando abrimos la guía al grupo, nadie necesita copiar."
			]
		}
	},
	"sofia": {
		"id": "sofia",
		"name": "Sofía Valdés",
		"role": "5to Semestre — Representante Estudiantil (Dirección)",
		"portrait": "sofia_direccion",
		"mood": "Organizada, perceptiva y justa",
		"mania": "Lleva una libreta ordenada por horarios y acuerdos de cada salón.",
		"flaw": "Intenta resolver todos los conflictos por su cuenta sin delegar ni escuchar primero.",
		"bond": "Coordina agendas con Diego y suelta la prisa para dar tiempo real a cada compañero.",
		"special_attack": "Turno Abierto — Acelera el ritmo de respuesta de todo el grupo.",
		"theme": "Escucha y coordinación justa",
		"state_afflicted": {
			"visual": "Frente a la puerta de Dirección, revisando una libreta llena de pendientes.",
			"visual_f": "Frente a la puerta de Dirección, revisando una libreta llena de pendientes.",
			"quotes": [
				"Si no anoto cada problema y lo resuelvo hoy, todo se va a desordenar.",
				"A veces siento que firmo acuerdos mientras nadie habla de frente."
			]
		},
		"state_redeemed": {
			"visual": "Serena y atenta, activando Turno Abierto para sincronizar al grupo.",
			"visual_f": "Serena y atenta, activando Turno Abierto para sincronizar al grupo.",
			"quotes": [
				"Organizar no es mandar solo, es abrir turnos para escuchar a todos.",
				"Cada integrante aporta algo indispensable en este equipo."
			]
		}
	},
	"alejandro": {
		"id": "alejandro",
		"name": "Alejandro Cruz",
		"role": "6to Semestre — Capitán de Básquetbol (Cancha)",
		"portrait": "alejandro_happy",
		"mood": "Ágil, sereno y fraterno",
		"mania": "Siempre trae un balón extra para incluir a quienes apenas aprenden en primer semestre.",
		"flaw": "Siente que debe aguantar todo sin mostrar cansancio ante el equipo.",
		"bond": "Incluye a Mateo en los entrenamientos suaves y anima a Valeria antes de los eventos cívicos.",
		"special_attack": "Pase de Rebote — Balón rápido que rebota en bordes buscando pase limpio.",
		"theme": "Juego limpio y fraternidad",
		"state_afflicted": {
			"visual": "Sentado en la orilla de las gradas deteniendo su balón en silencio.",
			"visual_f": "Sentado en la orilla de las gradas deteniendo su balón en silencio.",
			"quotes": [
				"Con tantos empujones, ya nadie quiere entrar a la cancha en el receso.",
				"Jugar fuerte sin respeto no es deporte ni compañerismo."
			]
		},
		"state_redeemed": {
			"visual": "En centro de cancha, enviando pases seguros con Pase de Rebote.",
			"visual_f": "En centro de cancha, enviando pases seguros con Pase de Rebote.",
			"quotes": [
				"Juego limpio significa abrir espacio también para quien va empezando.",
				"En esta cancha jugamos todos o no jugamos completos."
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
		"antivalue": "El miedo a intentar y quedar en ridículo",
		"redeeming_virtue": "Entusiasmo y Curiosidad",
		"pre_battle_quote": "Si preguntas otra vez, seguro nadie te hace caso.",
		"redemption_speech": "Tenía miedo de equivocarme frente al grupo. Hoy vuelvo a encender el mechero."
	},
	2: {
		"id": "desperdicius",
		"name": "Desperdicius, el Titán del Desperdicio",
		"scenario_id": 2,
		"location": "Cafetería y Desayunador del Edificio A",
		"antivalue": "La comodidad de desentenderse del espacio común",
		"redeeming_virtue": "Gratitud y Cuidado Comunitario",
		"pre_battle_quote": "Si dejo mi envoltura aquí, alguien más vendrá a levantarla luego.",
		"redemption_speech": "Nunca miré a quienes madrugan desde las cinco por nosotros. Yo recojo mi lugar."
	},
	3: {
		"id": "superbus",
		"name": "Superbus, el Heraldo de la Arrogancia",
		"scenario_id": 3,
		"location": "Plaza Cívica y Escalinata Sur (+4m)",
		"antivalue": "La arrogancia como disfraz de inseguridad",
		"redeeming_virtue": "Humildad y Fraternidad",
		"pre_battle_quote": "Estos escalones marcan distancia entre quienes saben y quienes sobran.",
		"redemption_speech": "Medir a otros por su apellido o acento solo me dejó más solo."
	},
	4: {
		"id": "murmullus",
		"name": "Ciber-Murmullus, el Espectro de la Difamación",
		"scenario_id": 4,
		"location": "Edificio B — Aulas 3-4 y Biblioteca",
		"antivalue": "El anonimato detrás de la pantalla",
		"redeeming_virtue": "Verdad y Ciudadanía Digital",
		"pre_battle_quote": "Solo reenvié una captura sin pensarlo, en el chat nadie sabe quién fue.",
		"redemption_speech": "Detrás de cada captura hay un compañero que mañana entra al mismo salón."
	},
	5: {
		"id": "plagiatrix",
		"name": "Plagiatrix, el Señor de la Falsedad",
		"scenario_id": 5,
		"location": "Edificio C — Dirección y Taller de Cómputo",
		"antivalue": "El temor a intentar con esfuerzo propio",
		"redeeming_virtue": "Honestidad Académica e Integridad",
		"pre_battle_quote": "Para qué desvelarse si puedes cambiar el nombre del archivo y entregar hoy.",
		"redemption_speech": "Una calificación prestada no sirve cuando toca resolver algo de verdad."
	},
	6: {
		"id": "titanor",
		"name": "Titanor, el Coloso del Bullying Escolar",
		"scenario_id": 6,
		"location": "Cancha de Usos Múltiples y Gradas",
		"antivalue": "El miedo disfrazado de fuerza bruta",
		"redeeming_virtue": "Solidaridad, Juego Limpio y Esperanza",
		"pre_battle_quote": "En esta cancha manda quien impone silencio y deja fuera a los nuevos.",
		"redemption_speech": "Empujaba para que nadie notara lo solo que llegaba cada mañana."
	}
}

const SCENARIO_CUTSCENES: Dictionary = {
	1: {
		"id": 1,
		"title": "Acto I: El Primer Paso en el Portón",
		"location": "Plaza de Acceso y Edificio D — Laboratorios",
		"dialogue_nodes": [
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_neutral",
				"emotion": "curious",
				"text": "Una bruma fría cubre el patio de acceso y la entrada al Laboratorio D. Nadie se anima a cruzar solo."
			},
			{
				"speaker": "Mateo",
				"portrait": "mateo_sad",
				"emotion": "scared",
				"text": "Cada vez que intento responder en clase, el eco repite risas desde las últimas mesas."
			},
			{
				"speaker": "Apatyx",
				"portrait": "boss_apatyx",
				"emotion": "mocking",
				"text": "Si te equivocas frente a todos vas a quedar en evidencia. Mejor quédate en silencio."
			},
			{
				"speaker": "Apatyx",
				"portrait": "boss_apatyx",
				"emotion": "cold",
				"text": "Escucha mi consejo, estudiante: la indiferencia cansa menos que intentarlo otra vez."
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_attack",
				"emotion": "determined",
				"text": "Equivocarse es parte de aprender. Vamos a devolverle la curiosidad y el respeto al laboratorio."
			}
		]
	},
	2: {
		"id": 2,
		"title": "Acto II: La Mesa Compartida",
		"location": "Edificio A — Cafetería y Aulas",
		"dialogue_nodes": [
			{
				"speaker": "María",
				"portrait": "maria_sad",
				"emotion": "tired",
				"text": "Otra vez dejaron las charolas amontonadas como si alguien más tuviera obligación de limpiar por ellos."
			},
			{
				"speaker": "Mateo",
				"portrait": "mateo_happy",
				"emotion": "warm",
				"text": "Hoy llegué temprano y vi cómo levantabas todo tú sola. Esta vez te ayudamos a organizar las mesas."
			},
			{
				"speaker": "Desperdicius",
				"portrait": "boss_desperdicius",
				"emotion": "smug",
				"text": "No te compliques, nadie agradece ese esfuerzo extra. Deja la mesa sucia y sigue caminando."
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_brave",
				"emotion": "calm",
				"text": "Cuidar los espacios comunes es respetar a quienes estudian y trabajan aquí desde temprano."
			}
		]
	},
	3: {
		"id": 3,
		"title": "Acto III: Cuatro Metros de Dignidad",
		"location": "Plaza Cívica y Escalinata Sur",
		"dialogue_nodes": [
			{
				"speaker": "Valeria",
				"portrait": "valeria_sad",
				"emotion": "hurt",
				"text": "Al pie de esta escalinata algunos murmuran cuando pronuncio palabras en otomí o hablo frente al patio."
			},
			{
				"speaker": "María",
				"portrait": "maria_happy",
				"emotion": "supportive",
				"text": "No tienes por qué bajar la voz. Si subimos juntos a la explanada, nadie va a callarte."
			},
			{
				"speaker": "Superbus",
				"portrait": "boss_superbus",
				"emotion": "arrogant",
				"text": "Solo unos cuantos merecen ocupar este podio y dirigir el saludo en la plaza."
			},
			{
				"speaker": "Valeria",
				"portrait": "valeria_brave",
				"emotion": "proud_firm",
				"text": "Guardián, caminemos al frente. Esta explanada es de todas y todos los que construyen el plantel.",
				"text_f": "Guardiana, caminemos al frente. Esta explanada es de todas y todos los que construyen el plantel."
			}
		]
	},
	4: {
		"id": 4,
		"title": "Acto IV: Detrás de la Pantalla",
		"location": "Edificio B — Aulas y Biblioteca",
		"dialogue_nodes": [
			{
				"speaker": "Fernanda",
				"portrait": "fernanda_sad",
				"emotion": "worried",
				"text": "Circulan capturas recortadas fuera de contexto en el chat escolar, y nadie pregunta de dónde salieron."
			},
			{
				"speaker": "Ciber-Murmullus",
				"portrait": "boss_murmullus",
				"emotion": "glitch",
				"text": "Es más fácil reenviar un rumor sin dar la cara. Mañana ya todos habrán olvidado quién empezó."
			},
			{
				"speaker": "Valeria",
				"portrait": "valeria_happy",
				"emotion": "firm",
				"text": "Quien recibe el mensaje sí lo recuerda toda la semana. Empecemos por pedir fuentes reales."
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_brave",
				"emotion": "determined",
				"text": "Cada pantalla comunica personas reales. Vamos a frenar el ruido con verdad y respeto."
			}
		]
	},
	5: {
		"id": 5,
		"title": "Acto V: Sin Atajos ni Silencios",
		"location": "Edificio C — Dirección y Taller de Cómputo",
		"dialogue_nodes": [
			{
				"speaker": "Diego",
				"portrait": "diego_sad",
				"emotion": "frustrated",
				"text": "Llenaron las carpetas del taller con trabajos copiados idénticos y luego culpan a la red cuando fallan."
			},
			{
				"speaker": "Sofía",
				"portrait": "sofia_sad",
				"emotion": "stressed",
				"text": "Yo intento tener cada acta al día, pero sin diálogo real en los grupos los mismos problemas regresan."
			},
			{
				"speaker": "Plagiatrix",
				"portrait": "boss_plagiatrix",
				"emotion": "smug",
				"text": "Entregar rápido importa más que comprender el tema. Toma el atajo y sal temprano."
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_brave",
				"emotion": "firm",
				"text": "Aprender con honestidad y escucharse en equipo vale mucho más que un archivo copiado."
			}
		]
	},
	6: {
		"id": 6,
		"title": "Acto VI: Toda la Escuela en la Cancha",
		"location": "Cancha de Usos Múltiples y Gradas",
		"dialogue_nodes": [
			{
				"speaker": "Alejandro",
				"portrait": "alejandro_sad",
				"emotion": "tense",
				"text": "La bruma se juntó en las gradas. Algunos impiden entrar a jugar a los grupos nuevos usando intimidación."
			},
			{
				"speaker": "Titanor",
				"portrait": "boss_titanor",
				"emotion": "menacing_fury",
				"text": "Aquí nadie entra sin permiso de la fuerza. El miedo mantiene el orden en este patio."
			},
			{
				"speaker": "Mateo & Valeria & Sofía",
				"portrait": "valeria_happy",
				"emotion": "determined",
				"text": "Ya no tienes frente a un solo estudiante. Toda la comunidad está lista para defender el juego limpio."
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_brave",
				"emotion": "determined",
				"text": "El respeto verdadero no necesita intimidar a nadie. Vamos a recuperar nuestra cancha en equipo."
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
