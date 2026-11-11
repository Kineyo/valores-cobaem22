extends RefCounted
class_name StoryData

## Base de Datos Narrativa del Modo Historia — "Campeones de los Valores"
## Plantel CEMSaD 22 ENTHAVI — Colegio de Bachilleres del Estado de México (COBAEM)
## Contiene diálogos cinematográficos, perfiles de personajes secundarios y datos de jefes redimibles.

const PROLOGUE: Dictionary = {
	"title": "Prólogo: La Bruma sobre el Valle de Temoaya",
	"location": "Entorno del CEMSaD 22 ENTHAVI — Amanecer",
	"synopsis": "Una extraña niebla grisácea desciende desde las faldas montañosas de Temoaya, amortiguando las risas juveniles e infiltrando sombras de desánimo, burlas y desunión en las instalaciones del plantel.",
	"dialogue_nodes": [
		{
			"speaker": "Narrador",
			"portrait": "narrator",
			"text": "Temoaya despierta con el canto de los pinos y la caricia del viento frío de la sierra mexiquense. En lo alto del poblado de Enthavi, las puertas guindas del CEMSaD 22 se abren para un nuevo ciclo escolar...",
			"emotion": "mystic",
			"sfx": "wind"
		},
		{
			"speaker": "Narrador",
			"portrait": "narrator",
			"text": "Sin embargo, algo ha cambiado en la atmósfera matutina. Una penumbra invisible y pesada —nacida de la apatía, el individualismo y el desgaste de la convivencia diaria— se ha instalado en los pasillos de la escuela.",
			"emotion": "somber",
			"sfx": "ominous_hum"
		},
		{
			"speaker": "Guardián de los Valores",
			"portrait": "player_neutral",
			"text": "Puedo sentir el desánimo en el aire. Mis compañeros caminan cabizbajos, mirando sus teléfonos con frialdad o empujándose en la entrada... Esta escuela no nació para ser un campo de hostilidad, sino un templo de comunidad y crecimiento.",
			"emotion": "determined",
			"sfx": "step"
		},
		{
			"speaker": "Voz Ancestral de Temoaya",
			"portrait": "spirit_otomi",
			"text": "¡K'a te ma m'e̱di! (¡Despierta, corazón bondadoso!). El escudo guinda y oro no es un simple metal; guarda la luz del respeto, la fraternidad y el trabajo honesto. Recorre cada edificio, disipa los rencores y recuerda a cada joven quién es en verdad.",
			"emotion": "warm_divine",
			"sfx": "chime"
		},
		{
			"speaker": "Guardián de los Valores",
			"portrait": "player_brave",
			"text": "No usaré la fuerza para someter a nadie. Nuestra arma es la virtud activa: la amabilidad, el respeto y la empatía. ¡Es momento de devolverle el color a nuestro plantel!",
			"emotion": "resolute",
			"sfx": "sparkle"
		}
	]
}

const EPILOGUE: Dictionary = {
	"title": "Epílogo: La Gran Fiesta de los Valores del CEMSaD 22",
	"location": "Plaza Cívica y Cancha de Usos Múltiples — Atardecer Dorado",
	"synopsis": "Con los seis antivalores mayores redimidos y reconciliados con el cuerpo estudiantil, el plantel CEMSaD 22 celebra la feria de la paz, la identidad otomí y la excelencia académica.",
	"dialogue_nodes": [
		{
			"speaker": "Narrador",
			"portrait": "narrator",
			"text": "El sol de la tarde baña con un resplandor dorado el arcotecho de la Plaza Cívica y el pavimento deportivo de la cancha. La niebla del egoísmo se ha disipado por completo.",
			"emotion": "triumphant",
			"sfx": "fanfare_soft"
		},
		{
			"speaker": "Mateo",
			"portrait": "mateo_happy",
			"text": "¡Miren a todos! Ya nadie camina solo con la cabeza gacha. Hoy dos compañeros de sexto semestre me invitaron a almorzar en la cafetería. ¡Por fin siento que pertenezco aquí!",
			"emotion": "joyful",
			"sfx": "bell"
		},
		{
			"speaker": "Xóchitl",
			"portrait": "xochitl_happy",
			"text": "Häxäje, ma zi kuya. En nuestra lengua otomí no existe una palabra para descartar al otro; somos ramas de un mismo ahuehuete. Hoy nuestras raíces se entrelazan con orgullo mexiquense.",
			"emotion": "serene_proud",
			"sfx": "flute_harmonic"
		},
		{
			"speaker": "Emiliano",
			"portrait": "emiliano_happy",
			"text": "¡Miren a Titanor anotando canastas con los de primer ingreso! El verdadero básquetbol se juega hombro a hombro, compartiendo el pase y celebrando el esfuerzo de todos.",
			"emotion": "energetic",
			"sfx": "cheer"
		},
		{
			"speaker": "Sofía",
			"portrait": "sofia_happy",
			"text": "En el taller de cómputo y el laboratorio ya no hay trampas ni códigos ocultos. Abrimos una red de tutorías solidarias. Cuando compartes tu conocimiento, todos crecemos juntos.",
			"emotion": "enthusiastic",
			"sfx": "chime"
		},
		{
			"speaker": "Director Institucional COBAEM",
			"portrait": "director",
			"text": "Jóvenes del CEMSaD 22 ENTHAVI: ustedes han demostrado que la educación media superior no solo forma profesionistas competentes, sino seres humanos íntegros, solidarios y de corazón noble. ¡Son auténticos Campeones de los Valores!",
			"emotion": "inspirational",
			"sfx": "applause"
		},
		{
			"speaker": "Guardián de los Valores",
			"portrait": "player_celebrate",
			"text": "La batalla nunca fue contra las personas, sino contra el dolor que las distanciaba. Mientras mantengamos viva la luz de la empatía, el CEMSaD 22 siempre será un hogar de paz.",
			"emotion": "grateful",
			"sfx": "victory_harp"
		}
	]
}

const SECONDARY_CHARACTERS: Dictionary = {
	"mateo": {
		"id": "mateo",
		"name": "Mateo Hernández",
		"role": "Alumno de Primer Semestre (Nuevo Ingreso)",
		"archetype": "El novato tímido de noble corazón",
		"location_appearance": "Escenario 1 (Acceso y Caseta C.V.)",
		"bio": "Mateo acaba de graduarse de la secundaria técnica de una comunidad cercana. Es reservado, lleva siempre sus útiles impecables y sueña con ser biólogo marino o químico agrónomo. Sin embargo, el tamaño de la preparatoria y los rumores de 'novatadas' lo tienen paralizado de angustia.",
		"color_theme": Color(0.35, 0.65, 0.95),
		"state_afflicted": {
			"visual": "Acurrucado detrás de la jardinera del osito topiario, con los hombros encogidos y la mochila apretada al pecho.",
			"emotion_label": "Afligido / Inseguro",
			"quotes": [
				"¿Y si se burlan de mis zapatos viejos al cruzar el portón?",
				"Escuché que a los de nuevo ingreso nos van a esconder las libretas en el laboratorio...",
				"Tal vez fue un error venir a estudiar aquí... No encajo con nadie."
			]
		},
		"state_redeemed": {
			"visual": "Erguido, sonriente, con su gafete de estudiante visible y una libreta de notas abierta con entusiasmo.",
			"emotion_label": "Seguro / Agradecido",
			"quotes": [
				"¡Gracias por escucharme cuando más temblaba de miedo!",
				"Me di cuenta de que todos fuimos nuevos alguna vez. ¡No tengo por qué esconderme!",
				"¡Te prometo que cuando lleguen otros compañeros nuevos, seré el primero en tenderles la mano!"
			]
		}
	},
	"xochitl": {
		"id": "xochitl",
		"name": "Xóchitl Morales Peña",
		"role": "Alumna de Tercer Semestre (Excelencia Académica y Cultura Otomí)",
		"archetype": "La guardiana de las raíces y la dignidad comunitaria",
		"location_appearance": "Escenario 3 (Plaza Cívica y Escalinata Sur)",
		"bio": "Habitante de la comunidad otomí de San Pedro Arriba / Enthavi. Es la primera de su familia en cursar el bachillerato con promedio perfecto. Teje tenangos y fajas tradicionales con su abuela y lidera el grupo de debate estudiantil. Sufre en silencio cuando algunos compañeros se avergüenzan de las raíces originarias.",
		"color_theme": Color(0.85, 0.35, 0.55),
		"state_afflicted": {
			"visual": "Junto a la alfarda de la escalinata sur (+4m), ocultando su bolso de telar otomí detrás de su chamarra escolar.",
			"emotion_label": "Herida / Desalentada",
			"quotes": [
				"Murmuraron que mi acento y los bordados de mi madre son 'anticuados'...",
				"¿Por qué en la plaza cívica se ríen de las ceremonias que nos dieron identidad?",
				"Duele ver a compañeros de nuestra propia tierra renegar de quienes somos."
			]
		},
		"state_redeemed": {
			"visual": "Brillante, portando con elegancia su reboso artesanal sobre el uniforme guinda, con paso firme sobre la escalinata.",
			"emotion_label": "Orgullosa / Fraterna",
			"quotes": [
				"¡Di jamädi! (¡Mil gracias de corazón!). Me devolviste la fuerza para cantar en nuestra lengua.",
				"Nuestra herencia otomí no es el pasado; es la raíz firme que sostiene nuestros sueños de bachilleres.",
				"¡Mira cómo retumba el eco en la sierra! La verdadera identidad es fuente inagotable de paz y dignidad."
			]
		}
	},
	"emiliano": {
		"id": "emiliano",
		"name": "Emiliano 'Milo' Cruz",
		"role": "Alumno de Quinto Semestre (Capitán de Baloncesto)",
		"archetype": "El deportista apasionado del Juego Limpio (Fair Play)",
		"location_appearance": "Escenario 6 (Cancha de Usos Múltiples)",
		"bio": "Alto, carismático y con una energía inagotable. Pasa cada receso en la cancha de usos múltiples organizando retas. Su filosofía deportiva es el compañerismo, pero se siente impotente ante la agresividad y el resentimiento de grupos que expulsan a los más pequeños del juego.",
		"color_theme": Color(0.95, 0.55, 0.20),
		"state_afflicted": {
			"visual": "Sentado en las gradas de cemento al sur de la cancha, con un balón pinchado entre sus manos y la mirada perdida.",
			"emotion_label": "Frustrado / Desesperanzado",
			"quotes": [
				"El deporte solía unirnos... Ahora solo hay gritos, faltas malintencionadas y burlas en las bancas.",
				"Ya nadie quiere entrar a la cancha por miedo a ser humillado por los más fuertes.",
				"Si jugar significa pisotear la dignidad del rival, prefiero no volver a botar un balón."
			]
		},
		"state_redeemed": {
			"visual": "De pie en el centro de la cancha, haciendo rebotar el balón con ritmo alegre y una sonrisa de oreja a oreja.",
			"emotion_label": "Inspirador / Eufórico",
			"quotes": [
				"¡Ese es el verdadero espíritu del COBAEM! ¡Aquí todos tocan el balón, todos anotan y todos aprenden!",
				"Gracias, amigo Guardián. Me enseñaste que el mejor tiro libre es el que levanta a un rival caído.",
				"¡Vengan todos a la cancha! ¡El juego limpio acaba de comenzar y las puertas están abiertas para todos!"
			]
		}
	},
	"sofia": {
		"id": "sofia",
		"name": "Sofía Valdés",
		"role": "Alumna de Quinto Semestre (Club de Robótica y Ciencias)",
		"archetype": "La mente brillante de la tecnología con vocación solidaria",
		"location_appearance": "Escenario 5 (Edificio C — Cómputo y Dirección)",
		"bio": "Pasa horas en la planta alta del Edificio C optimizando software libre y reparando computadoras viejas para que sus compañeros puedan hacer tareas. Su gran dilema moral surgió cuando una red de alumnos comenzó a piratear proyectos y a ofrecer pagar por exámenes resueltos.",
		"color_theme": Color(0.20, 0.80, 0.60),
		"state_afflicted": {
			"visual": "Frente a la puerta del aula de cómputo, con los brazos cruzados, mirando con tristeza los monitores apagados.",
			"emotion_label": "Decepcionada / Desilusionada",
			"quotes": [
				"¿De qué sirve pasar noches enteras programando si al final premian al que copió y pegó sin entender nada?",
				"El plagio se normalizó como si fuera 'viveza'... y a los honestos nos llaman tontos.",
				"Las computadoras deberían conectar mentes, no ser máquinas de trampas y atajos vacíos."
			]
		},
		"state_redeemed": {
			"visual": "Frente a un monitor encendido que despliega código limpio y colaborativo, rodeada de alumnos atentos.",
			"emotion_label": "Radiante / Comprometida",
			"quotes": [
				"¡La verdad y el mérito propio ganaron la partida! ¡Gracias por no dejarme tirar la toalla!",
				"Creé una plataforma escolar comunitaria donde los que sabemos más apoyamos a quienes se les dificulta.",
				"El verdadero hacker escolar no es el que copia, sino el que comparte su luz para que todos avancen."
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
		"personality": "Una figura espectral envuelta en jirones grises y hojas de examen arrugadas. Habla con un bostezo eterno y una voz arrastrada que intenta convencer a los recién llegados de que estudiar no tiene sentido en la vida moderna.",
		"pre_battle_quote": "¿Para qué esforzarte en cruzar este portón? Afuera hace frío y adentro solo hay tareas interminables. Mejor quédate dormido, deja pasar los días... Nada de lo que hagas aquí cambiará tu destino.",
		"phase_dialogue": "¡No me molestes con tus discursos de superación! El desinterés es más cómodo que intentar y fracasar...",
		"redemption_speech": "Espera... esa chispa de calidez que disparas... la reconozco. Es la emoción que sentí el primer día que miré a través del microscopio en el laboratorio... Creí que el desgano me protegía de decepcionarme, pero solo me estaba robando la vida. ¡Abre las puertas de par en par! ¡Volveré a intentar con todo mi corazón!",
		"virtue_reward": "Medalla del Fuego Interior (Compromiso Activo)"
	},
	2: {
		"id": "desperdicius",
		"name": "Desperdicius, el Titán del Desperdicio",
		"scenario_id": 2,
		"location": "Cafetería y Desayunador del Edificio A",
		"antivalue": "El Desperdicio, la Gula y el Descuido del Entorno",
		"redeeming_virtue": "¡Templanza, Generosidad y Cuidado Comunitario!",
		"personality": "Una criatura hinchada hecha de envoltorios plásticos de chatarra, bandejas volteadas y restos de comida tirados en las bancas de picnic. Se burla de quienes traen comida sencilla de sus casas campesinas y empuja para ser siempre el primero.",
		"pre_battle_quote": "¡Esta mesa es mía y de nadie más! Si no te gusta el ruido, vete al patio. Y si se me cae el almuerzo al suelo, ¡que lo limpie otro! ¡Aquí manda quien gasta más y aplasta al vecino!",
		"phase_dialogue": "¿Quieres que comparta? ¿Que respete la fila? ¡El mundo es de los voraces!",
		"redemption_speech": "¡Basta de lanzar esa luz tan dulce! Huele a... pan caliente de pueblo compartido con amigos. Mi abuela me enseñó que la comida es sagrada y que la mesa es un santuario de hospitalidad. Olvidé el valor del sudor campesino que cosecha lo que tiraba... Dejaré este desayunador limpio y me aseguraré de que nadie coma en soledad jamás.",
		"virtue_reward": "Medalla del Pan Compartido (Respeto y Cuidado del Entorno)"
	},
	3: {
		"id": "superbus",
		"name": "Superbus, el Heraldo de la Arrogancia",
		"scenario_id": 3,
		"location": "Plaza Cívica, Asta Bandera y Escalinata Sur (+4m)",
		"antivalue": "La Soberbia, el Clasismo y el Menosprecio Cultural",
		"redeeming_virtue": "¡Humildad, Dignidad y Fraternidad Otomí!",
		"personality": "Una entidad alta y reluciente con manto púrpura desgastado que flota sobre la alfarda de la escalinata. Mira a todos por encima del hombro, vanagloriándose de marcas superficiales y despreciando las raíces indígenas de Temoaya.",
		"pre_battle_quote": "¡Mírenme desde el foso, mediocres! Yo estoy en la cima del desnivel de cuatro metros. Sus tradiciones son polvo viejo y sus dialectos no caben en mi futuro brillante. ¡Ríndanse ante mi linaje superior!",
		"phase_dialogue": "¡Ningún proyectil moral puede alcanzar la altura de mi ego intocable!",
		"redemption_speech": "¿Por qué... por qué me siento tan ligero al caer sobre las rodillas? Llevaba años cargando esta corona oxidada de apariencias, temiendo que descubrieran que vengo del mismo barro fértil de Enthavi que todos ustedes. Las piedras de esta escalinata fueron labradas por las manos de nuestros abuelos... La humildad no nos hace pequeños; nos hace invencibles. ¡Viva el pueblo otomí y viva el COBAEM!",
		"virtue_reward": "Medalla del Corazón de Maíz (Humildad y Raíces)"
	},
	4: {
		"id": "murmullus",
		"name": "Ciber-Murmullus, el Espectro de la Difamación",
		"scenario_id": 4,
		"location": "Edificio B — Aulas 3-4 y Biblioteca Escolar",
		"antivalue": "El Ciberacoso, el Chisme Venenoso y la Calumnia Digital",
		"redeeming_virtue": "¡Verdad, Prudencia e Integridad Digital!",
		"personality": "Una maraña de cables luminosos que proyectan capturas de pantalla mutiladas, audios fuera de contexto y perfiles falsos. Se desliza como sombra entre los estantes de libros susurrando medias verdades para destruir amistades.",
		"pre_battle_quote": "¿Viste lo que publicaron en el grupo anónimo sobre esa chica de tercero? Jajaja, ¡un solo click y arruiné su reputación para siempre! Nadie sabrá quién fui... La pantalla es mi escudo y el veneno es mi juego favorito.",
		"phase_dialogue": "¡Reenvía el rumor! ¡Hazlo viral! ¡La mentira viaja más rápido que tu patética honestidad!",
		"redemption_speech": "¡Mis pantallas se sobrecalientan con esa luz de verdad! Veo las lágrimas que causé detrás de la pantalla... Vi a esa persona llorando en el rincón de la biblioteca por una broma cruel que yo inventé en cinco minutos. ¿Cómo pude ser tan cobarde amparándome en el anonimato? Prometo borrar cada canal de odio, pedir disculpas públicas y usar la tecnología únicamente para tender puentes de amistad y rescate.",
		"virtue_reward": "Medalla del Escudo de la Verdad (Ciudadanía Digital Ética)"
	},
	5: {
		"id": "plagiatrix",
		"name": "Plagiatrix, el Señor de la Falsedad",
		"scenario_id": 5,
		"location": "Edificio C — Dirección y Taller de Cómputo",
		"antivalue": "El Plagio Intelectual, la Corrupción y la Ley del Mínimo Esfuerzo",
		"redeeming_virtue": "¡Honestidad Académica, Mérito y Perseverancia!",
		"personality": "Un autómata de silueta impecable pero con el rostro hecho de sellos falsificados, memorias USB pirateadas e informes robados a otros estudiantes. Pretende convencer a todos de que graduarse con trampa es el camino del triunfador.",
		"pre_battle_quote": "¿Para qué pasar noches estudiando y quemándote las pestañas si puedes comprar el proyecto por internet? 'El que no tranza no avanza', ese es el lema del éxito. ¡Ustedes los honestos son fósiles ingenuos!",
		"phase_dialogue": "¡Control+C, Control+V! ¡Mi castillo de mentiras es perfecto y ningún maestro lo notará!",
		"redemption_speech": "¡Mi código fuente se desmorona! No... no es una falla técnica, es el vacío de mi propio engaño. Cuando me miro al espejo, no tengo rostro propio; solo soy un collage de ideas ajenas. ¿De qué sirve un diploma de papel si tu mente está hueca y tu dignidad vendida? Tienes razón, hermano: el conocimiento que vale es el que duele, el que cuesta sudor y desvelo. ¡Desde hoy, cada letra que escriba será mía, honesta y transparente!",
		"virtue_reward": "Medalla de la Pluma Íntegra (Excelencia Auténtica)"
	},
	6: {
		"id": "titanor",
		"name": "Titanor, el Coloso del Bullying Escolar",
		"scenario_id": 6,
		"location": "Cancha de Usos Múltiples y Gradas Perimetrales",
		"antivalue": "La Intimidación Sistemática, la Violencia Física y la Exclusión Grupal",
		"redeeming_virtue": "¡Amor Incondicional, Solidaridad y Reconciliación Escolar!",
		"personality": "Un gigante imponente compuesto por cadenas oxidadas, balones ponchados y pupilas incandescentes de furia. Ocupa todo el centro de la cancha de usos múltiples, pisoteando las líneas de cal e imponiendo su ley del más fuerte a golpes y amenazas.",
		"pre_battle_quote": "¡Llegaste al final de tu absurdo paseo, 'paladín de los valores'! Esta cancha me pertenece. Aquí los débiles bajan la mirada y me entregan su dinero o se van con un golpe. ¡Nadie me dice qué hacer! ¡La violencia es la única regla que todos entienden!",
		"phase_dialogue": "¡Grita todo lo que quieras! ¡Nadie vendrá a salvarte! ¡Yo soy la fuerza bruta que reina en los pasillos!",
		"redemption_speech": "¿Por qué no me devolviste el golpe? Tenías la oportunidad de derribarme frente a toda la escuela... y en lugar de humillarme, me envolviste en un abrazo de luz y perdón... (Sus ojos de fuego se apagan, transformándose en lágrimas). Nadie en mi casa me preguntó nunca cómo me sentía. Yo... yo solo golpeaba para que nadie viera lo roto que estoy por dentro, para que nadie me hiciera daño primero. Perdónenme, compañeros... Perdóname, Milo, perdónenme todos los que hicieron llorar en este patio. ¡No volveré a levantar la mano contra nadie! Si esta fuerza sirve de algo, será para ser el muro que proteja a los indefensos y para limpiar cada rincón de nuestra querida escuela.",
		"virtue_reward": "Copa Magna CEMSaD 22 ENTHAVI (Campeón de la Convivencia Escolar)"
	}
}

const SCENARIO_CUTSCENES: Dictionary = {
	1: {
		"id": 1,
		"title": "Acto I: Cruzar el Umbral",
		"scenario_name": "Acceso, Caseta C.V. y Edificio D",
		"real_space": "Caseta C.V., Portón Triple, Jardinera del Osito Topiario y Laboratorio de Usos Múltiples (183 m²)",
		"dialogue_nodes": [
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_neutral",
				"text": "Aquí comienza todo. El portón de acceso del CEMSaD 22. Pero miren esa neblina gris sobre los autos del estacionamiento y la jardinera...",
				"emotion": "attentive"
			},
			{
				"speaker": "Mateo",
				"portrait": "mateo_sad",
				"text": "¡Ayuda...! Por favor, no dejen que me acerquen esas sombras. Dicen que no sirvo para el bachillerato, que mejor me regrese a mi pueblo...",
				"emotion": "fearful"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_brave",
				"text": "Tranquilo, Mateo. Estás en tu escuela. Este portón se abre para recibir el talento de todos los jóvenes de Temoaya, sin importar de dónde vengan. ¡Acompáñame!",
				"emotion": "protective"
			},
			{
				"speaker": "Apatyx",
				"portrait": "boss_apatyx",
				"text": "¿Más optimistas ilusos? Los experimentos de este laboratorio se van a pudrir antes de que aprendan algo útil. ¡Vuelvan a casa mientras puedan!",
				"emotion": "mocking"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_attack",
				"text": "El laboratorio del Edificio D fue construido con el esfuerzo de la comunidad para despertar la ciencia. ¡Disipemos la apatía con la fuerza del compromiso!",
				"emotion": "battle_ready"
			}
		]
	},
	2: {
		"id": 2,
		"title": "Acto II: El Pan de Cada Día",
		"scenario_name": "Edificio A — Cafetería, Desayunador y Aulas 1-2",
		"real_space": "Pasillo de Aulas 1-2, Sanitarios y Mesas de Picnic bajo Arcotecho",
		"dialogue_nodes": [
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_neutral",
				"text": "Llegamos a la cafetería del Edificio A. Huele a comida deliciosa, pero el suelo está tapizado de platos desechables y bolsas de plástico tiradas.",
				"emotion": "concerned"
			},
			{
				"speaker": "Desperdicius",
				"portrait": "boss_desperdicius",
				"text": "¡Traguen rápido y lárguense! Las bancas bajo la sombra del arcotecho son solo para mi grupo. Los demás que coman de pie bajo el sol.",
				"emotion": "bullying"
			},
			{
				"speaker": "Mateo",
				"portrait": "mateo_support",
				"text": "¡Eso no es justo! Las cocineras del desayunador se levantaron a las cinco de la mañana para preparar los guisados calientes. ¡El alimento y el espacio son de todos!",
				"emotion": "brave_small"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_brave",
				"text": "El respeto comienza en cómo tratamos a quienes nos alimentan y cómo cuidamos los espacios comunes. ¡Desperdicius, aprenderás el valor de la gratitud!",
				"emotion": "battle_ready"
			}
		]
	},
	3: {
		"id": 3,
		"title": "Acto III: La Escalinata del Respeto",
		"scenario_name": "Plaza Cívica (748 m²) y Escalinata Sur (+4m)",
		"real_space": "Asta Bandera, Muro de Piedra Braza Negra, Alfarda Guinda y Escalinata Sur",
		"dialogue_nodes": [
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_neutral",
				"text": "La Plaza Cívica... el corazón del plantel. Aquí nos formamos los lunes para rendir honores a la bandera y cantar el himno nacional.",
				"emotion": "reverent"
			},
			{
				"speaker": "Xóchitl",
				"portrait": "xochitl_sad",
				"text": "Ese gigante púrpura se ha adueñado de la escalinata sur. Dice que quienes venimos de comunidades hablantes de hñähñu no tenemos derecho a subir al Edificio B.",
				"emotion": "deep_hurt"
			},
			{
				"speaker": "Superbus",
				"portrait": "boss_superbus",
				"text": "¡Exacto! El desnivel de cuatro metros separa a los 'elegantes' de los rústicos. ¡Esta alfarda solo la pisan los que tienen estatus!",
				"emotion": "condescending"
			},
			{
				"speaker": "Xóchitl",
				"portrait": "xochitl_brave",
				"text": "¡Te equivocas! El muro de contención de piedra braza lo levantaron los albañiles de Temoaya. La sangre otomí corre con dignidad por nuestras venas.",
				"emotion": "proud_firm"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_attack",
				"text": "La soberbia solo ciega el alma. ¡Hoy demostraremos que el único honor verdadero es el respeto fraterno entre iguales!",
				"emotion": "battle_ready"
			}
		]
	},
	4: {
		"id": 4,
		"title": "Acto IV: Las Palabras que Sanan",
		"scenario_name": "Edificio B — Aulas 3-4, Biblioteca y Sala de Maestros",
		"real_space": "Terraza Superior (+4m), Pasillo con Barandal Blanco y Jardín Mirador",
		"dialogue_nodes": [
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_neutral",
				"text": "Arriba en la terraza del Edificio B la vista del valle es hermosa, pero el silencio de la biblioteca se siente tenso y sofocante.",
				"emotion": "attentive"
			},
			{
				"speaker": "Ciber-Murmullus",
				"portrait": "boss_murmullus",
				"text": "Psst... ¿ya leyeron el hilo en redes sociales? Dicen que varios alumnos reprobarán por culpa de un chisme que inventé. ¡La paranoia es deliciosa!",
				"emotion": "sneaky_malice"
			},
			{
				"speaker": "Sofía",
				"portrait": "sofia_sad",
				"text": "Están acosando a compañeras de segundo semestre por mensajes privados. Tienen miedo de venir a clases por culpa de capturas manipuladas con inteligencia artificial...",
				"emotion": "frustrated_indignant"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_brave",
				"text": "La pantalla de un teléfono no es un cheque en blanco para destruir vidas. Las palabras deben usarse para alentar, enseñar y construir. ¡Desenmascaremos la difamación!",
				"emotion": "battle_ready"
			}
		]
	},
	5: {
		"id": 5,
		"title": "Acto V: El Código de la Honestidad",
		"scenario_name": "Edificio C — Dirección, Control Escolar y Cómputo",
		"real_space": "Planta Baja Dirección / Aula 5, Rampa Verde Claro, Planta Alta Taller de Cómputo (115.2 m²)",
		"dialogue_nodes": [
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_neutral",
				"text": "El Edificio C. En la planta baja está la Dirección donde se toman las decisiones de nuestra escuela, y arriba, el laboratorio con más de treinta computadoras.",
				"emotion": "thoughtful"
			},
			{
				"speaker": "Sofía",
				"portrait": "sofia_sad",
				"text": "Plagiatrix hackeó los servidores de tareas. Está cobrando dinero por enviar exámenes resueltos y proyectos copiados a quienes no quieren estudiar.",
				"emotion": "bitter_disappointment"
			},
			{
				"speaker": "Plagiatrix",
				"portrait": "boss_plagiatrix",
				"text": "¿Por qué complicarse la vida aprendiendo lógica cuando un robot puede hacer tu tarea en cinco segundos? Sean prácticos: engañen al maestro y festejen.",
				"emotion": "cynical"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_brave",
				"text": "La trampa es un robo a tu propio futuro. El título profesional no tiene valor si no sabes resolver la vida real. ¡Sofía, defendamos la verdad académica!",
				"emotion": "battle_ready"
			}
		]
	},
	6: {
		"id": 6,
		"title": "Acto VI: El Gran Partido de la Paz",
		"scenario_name": "Cancha de Usos Múltiples (540 m²) y Bancas",
		"real_space": "Pavimento Deportivo, Tableros de Básquetbol Poniente y Oriente, Bancas de Estudio al Sur",
		"dialogue_nodes": [
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_neutral",
				"text": "La última frontera del plantel: la gran cancha de usos múltiples. Pero el tablero está torcido y un rugido ensordecedor sacude las láminas perimetrales.",
				"emotion": "solemn"
			},
			{
				"speaker": "Emiliano",
				"portrait": "emiliano_sad",
				"text": "¡Cuidado! Es Titanor. Encarna todo el acoso, la burla pesada y el miedo que los alumnos han sufrido durante años en silencio...",
				"emotion": "warning"
			},
			{
				"speaker": "Titanor",
				"portrait": "boss_titanor",
				"text": "¡Por fin llegaron los salvadores de pacotilla! Esta cancha es la jungla de la prepa. Aquí manda el que empuja más fuerte y al que no le guste, ¡que se largue del CEMSaD 22!",
				"emotion": "menacing_fury"
			},
			{
				"speaker": "Mateo & Xóchitl & Sofía",
				"portrait": "allies_united",
				"text": "¡Ya no estamos solos, Titanor! No te tenemos miedo porque ya no guardamos rencor. ¡Todos nosotros formamos un solo equipo escolar!",
				"emotion": "unshakable_unity"
			},
			{
				"speaker": "Guardián de los Valores",
				"portrait": "player_attack",
				"text": "Esta cancha no es para dividirnos, sino para unirnos en un solo abrazo deportivo y fraterno. ¡Titanor, es hora de liberarte del rencor y redimir tu corazón!",
				"emotion": "final_resolve"
			}
		]
	}
}

static func get_prologue() -> Dictionary:
	return PROLOGUE

static func get_epilogue() -> Dictionary:
	return EPILOGUE

static func get_scenario_cutscene(scenario_id: int) -> Dictionary:
	return SCENARIO_CUTSCENES.get(scenario_id, {})

static func get_secondary_character(character_id: String) -> Dictionary:
	return SECONDARY_CHARACTERS.get(character_id, {})

static func get_boss(scenario_id: int) -> Dictionary:
	return BOSSES.get(scenario_id, {})
