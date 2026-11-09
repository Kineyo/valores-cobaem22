shader_type canvas_item;

// Transición pixel-art: rombos ("diamond wipe") que crecen en diagonal.
// progress = 0 -> pantalla visible, progress = 1 -> pantalla cubierta.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Tamaño de cada celda (en píxeles del viewport)
uniform float cell_size = 32.0;
// Tamaño del "píxel" dentro de cada rombo (da el borde escalonado)
uniform float pixel_step = 4.0;
// Tamaño del viewport (lo actualiza scene_transition.gd)
uniform vec2 screen_size = vec2(800.0, 450.0);
// Invierte la dirección del barrido (para que al destapar continúe hacia el mismo lado)
uniform bool reverse = false;
uniform vec4 color : source_color = vec4(0.07, 0.06, 0.13, 1.0);

void fragment() {
	vec2 frag = UV * screen_size;
	// Coordenada local dentro de la celda, cuantizada a "píxeles gordos"
	vec2 local_px = floor(mod(frag, cell_size) / pixel_step) * pixel_step + pixel_step * 0.5;
	vec2 local = local_px / cell_size - 0.5;
	float diamond = abs(local.x) + abs(local.y); // 0 en el centro, 1 en las esquinas

	// Barrido diagonal según la posición de la celda
	vec2 cell_center = (floor(frag / cell_size) + 0.5) * cell_size / screen_size;
	float sweep = clamp(cell_center.x * 0.75 + cell_center.y * 0.25, 0.0, 1.0);
	if (reverse) {
		sweep = 1.0 - sweep;
	}

	float t = clamp(progress * 2.1 - sweep, 0.0, 1.05);
	if (diamond >= t) {
		discard;
	}
	COLOR = color;
}
