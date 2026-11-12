shader_type canvas_item;

// Niebla del Desinterés (CEMSaD 22 ENTHAVI)
// Bruma densa y volumétrica con dispersión de luz de virtudes,
// vapor en movimiento armónico y ocultación de antivalores.

uniform vec2 rect_pos = vec2(-200.0, -200.0);
uniform vec2 rect_size = vec2(2000.0, 1400.0);

uniform vec2 light_pos_1 = vec2(-2000.0, -2000.0); // Héroe
uniform vec2 light_pos_2 = vec2(-2000.0, -2000.0); // Alumno 1
uniform vec2 light_pos_3 = vec2(-2000.0, -2000.0); // Alumno 2
uniform float light_radius_1 = 145.0;
uniform float light_radius_2 = 90.0;
uniform float light_radius_3 = 90.0;

uniform float fog_alpha : hint_range(0.0, 1.0) = 0.0;
// Tonos atmosféricos de la bruma fría matutina de Temoaya
uniform vec4 fog_color : source_color = vec4(0.07, 0.09, 0.15, 0.99);
uniform vec4 mist_color : source_color = vec4(0.15, 0.19, 0.28, 0.92);
uniform vec4 rim_glow_color : source_color = vec4(1.0, 0.92, 0.65, 0.38);
uniform float time = 0.0;

void fragment() {
	if (fog_alpha <= 0.001) {
		discard;
	}

	// 1. Coordenadas de mundo 2D exactas dentro del escenario
	vec2 world_pos = rect_pos + UV * rect_size;

	// 2. Distancia euclidiana hacia cada fuente de virtud (héroe y alumnos)
	float d1 = distance(world_pos, light_pos_1);
	float d2 = distance(world_pos, light_pos_2);
	float d3 = distance(world_pos, light_pos_3);

	// Gradiente de luz natural con caída suave (smoothstep sin cortes duros)
	float mask1 = smoothstep(light_radius_1 * 0.48, light_radius_1 * 1.05, d1);
	float mask2 = smoothstep(light_radius_2 * 0.45, light_radius_2 * 1.00, d2);
	float mask3 = smoothstep(light_radius_3 * 0.45, light_radius_3 * 1.00, d3);

	float base_mask = min(mask1, min(mask2, mask3));

	// 3. Vapor y remolinos de bruma volumétrica en movimiento continuo
	// Simulación armónica multifrecuencia optimizada para OpenGL ES 3 / WebGL
	float n1 = sin(world_pos.x * 0.007 + time * 0.38) * cos(world_pos.y * 0.008 + time * 0.22);
	float n2 = sin(world_pos.x * 0.015 - time * 0.25) * cos(world_pos.y * 0.013 + time * 0.32) * 0.5;
	float n3 = sin((world_pos.x + world_pos.y) * 0.021 + time * 0.45) * 0.25;
	float mist_cloud = clamp((n1 + n2 + n3) * 0.58 + 0.5, 0.0, 1.0);

	// Los jirones de niebla ondulan y difuminan la frontera de la luz
	float wisp = (mist_cloud - 0.5) * 0.24;
	float final_mask = clamp(base_mask + wisp * base_mask, 0.0, 1.0);

	// 4. Mezcla de color: niebla profunda de alta densidad con nubes de vapor flotante
	vec3 mist_rgb = mix(fog_color.rgb, mist_color.rgb, mist_cloud * 0.52);

	// 5. Halo cálido de virtud en el borde de disipación de la luz
	float rim1 = smoothstep(light_radius_1 * 0.35, light_radius_1 * 0.72, d1) * (1.0 - smoothstep(light_radius_1 * 0.72, light_radius_1 * 1.15, d1));
	float rim2 = smoothstep(light_radius_2 * 0.30, light_radius_2 * 0.68, d2) * (1.0 - smoothstep(light_radius_2 * 0.68, light_radius_2 * 1.10, d2));
	float rim_glow = max(rim1, rim2);

	vec3 final_rgb = mix(mist_rgb, rim_glow_color.rgb, rim_glow * rim_glow_color.a);
	float final_a = final_mask * fog_alpha * fog_color.a;

	COLOR = vec4(final_rgb, final_a);
}
