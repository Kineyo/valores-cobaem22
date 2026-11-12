#!/usr/bin/env python3
"""
tools/generate_character_assets.py
Generador determinista de sprites y retratos pixel art para estudiantes y docentes del CEMSaD 22.
Crea tanto los sprites de cuerpo entero (512x512 en grilla 32x32 escalada 16x para coincidir con player_idle.png)
como los retratos de rostro (256x256 en grilla 32x32 escalada 8x) para cinemáticas y epílogos.

Archivos generados en assets/:
  - alejandro_cancha.png
  - maria_cafeteria.png
  - mateo_laboratorio.png
  - valeria_plaza.png
  - fernanda_biblioteca.png
  - diego_computo.png
  - sofia_direccion.png
  - maestro_desinteres.png

Y también en subcarpetas estructuradas:
  - assets/portraits/*.png
  - assets/sprites/students/*.png
  - assets/sprites/bosses/*.png
"""

import os
from PIL import Image

OUT_DIRS = [
    "assets",
    "assets/portraits",
    "assets/sprites/students",
    "assets/sprites/bosses",
]

# Paleta base COBAEM y tonos escolares
CLR_CLEAR = (0, 0, 0, 0)
CLR_OUTLINE = (7, 1, 16, 255)
CLR_WHITE = (255, 255, 255, 255)
CLR_SHIRT_SHADOW = (200, 204, 210, 255)
CLR_VINO_BASE = (168, 30, 30, 255)       # Guinda institucional COBAEM
CLR_VINO_DARK = (84, 15, 15, 255)
CLR_VINO_LIGHT = (210, 50, 50, 255)
CLR_GOLD = (230, 185, 40, 255)
CLR_GREEN_EMBLEM = (92, 212, 7, 255)
CLR_PANTS_GRAY = (68, 65, 72, 255)
CLR_PANTS_DARK = (45, 43, 48, 255)
CLR_SKIN_WARM = (245, 214, 180, 255)
CLR_SKIN_SHADOW = (215, 175, 140, 255)
CLR_SKIN_INDIGENOUS = (218, 168, 130, 255)
CLR_SKIN_IND_SHADOW = (185, 135, 95, 255)
CLR_BLUSH = (235, 130, 150, 255)

# Paleta especial: Maestro Desinterés (Corrompido por la Apatía)
CLR_TEACHER_GREY_SKIN = (145, 152, 162, 255)
CLR_TEACHER_GREY_SHADOW = (110, 116, 126, 255)
CLR_TEACHER_WHITE_EYES = (255, 255, 255, 255)
CLR_TEACHER_SUIT_DARK = (48, 52, 60, 255)
CLR_TEACHER_SUIT_LIGHT = (72, 78, 90, 255)
CLR_TEACHER_HAIR_GREY = (90, 94, 102, 255)
CLR_TEACHER_TIE_DULL = (120, 45, 55, 255)


def create_pixel_grid(w=32, h=32):
    return [[CLR_CLEAR for _ in range(w)] for _ in range(h)]


def draw_rect(grid, x, y, w, h, color):
    for r in range(y, y + h):
        for c in range(x, x + w):
            if 0 <= r < len(grid) and 0 <= c < len(grid[0]):
                grid[r][c] = color


def draw_pixel(grid, x, y, color):
    if 0 <= y < len(grid) and 0 <= x < len(grid[0]):
        grid[y][x] = color


def grid_to_image(grid, scale=16):
    h = len(grid)
    w = len(grid[0])
    img = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    for r in range(h):
        for c in range(w):
            col = grid[r][c]
            if col[3] > 0:
                for py in range(scale):
                    for px in range(scale):
                        img.putpixel((c * scale + px, r * scale + py), col)
    return img


# =============================================================================
# GENERADORES DE SPRITES DE CUERPO ENTERO (32x32 -> 512x512)
# =============================================================================

def make_student_body(char_id):
    """Genera sprite de cuerpo completo estilo player_idle.png para cada alumno/maestro."""
    g = create_pixel_grid(32, 32)

    # Identificar colores específicos
    skin = CLR_SKIN_WARM
    skin_dark = CLR_SKIN_SHADOW
    hair_col = (40, 25, 20, 255)
    is_skirt = False
    is_teacher = (char_id == "maestro_desinteres")

    if char_id == "valeria_plaza":
        skin = CLR_SKIN_WARM
        skin_dark = CLR_SKIN_SHADOW
        hair_col = (45, 30, 25, 255)
        is_skirt = True
    elif char_id == "maria_cafeteria":
        hair_col = (115, 65, 35, 255)
        is_skirt = True
    elif char_id == "fernanda_biblioteca":
        hair_col = (50, 35, 45, 255)
        is_skirt = True
    elif char_id == "sofia_direccion":
        hair_col = (30, 25, 35, 255)
        is_skirt = True
    elif char_id == "alejandro_cancha":
        hair_col = (25, 25, 28, 255)
    elif char_id == "diego_computo":
        hair_col = (35, 40, 50, 255)
    elif char_id == "mateo_laboratorio":
        hair_col = (55, 38, 25, 255)
    elif char_id == "maestro_desinteres_redeemed":
        skin = CLR_SKIN_WARM
        skin_dark = CLR_SKIN_SHADOW
        hair_col = (75, 65, 60, 255)
    elif is_teacher:
        skin = CLR_TEACHER_GREY_SKIN
        skin_dark = CLR_TEACHER_GREY_SHADOW
        hair_col = CLR_TEACHER_HAIR_GREY

    # 1. Cabello base (Filas 4 a 10)
    draw_rect(g, 11, 4, 10, 3, hair_col)
    draw_rect(g, 10, 6, 12, 4, hair_col)

    if char_id == "valeria_plaza":
        # Broche esmeralda y mechones elegantes
        draw_rect(g, 9, 8, 2, 7, hair_col)
        draw_rect(g, 21, 8, 2, 7, hair_col)
        draw_rect(g, 10, 6, 2, 2, (20, 160, 95, 255)) # Broche esmeralda
    elif char_id == "sofia_direccion":
        # Coleta alta ordenada
        draw_rect(g, 21, 5, 4, 7, hair_col)
        draw_pixel(g, 21, 6, (40, 140, 200, 255))  # Coletero azul
    elif char_id == "maria_cafeteria":
        # Mechones ondulados y diadema
        draw_rect(g, 9, 8, 2, 7, hair_col)
        draw_rect(g, 21, 8, 2, 7, hair_col)
        draw_rect(g, 11, 5, 10, 1, (240, 120, 140, 255))  # Diadema
    elif char_id == "alejandro_cancha":
        # Cinta deportiva roja en la frente
        draw_rect(g, 10, 7, 12, 1, (220, 40, 40, 255))
    elif char_id == "diego_computo":
        # Auriculares / Headset alrededor del cuello
        draw_pixel(g, 9, 14, (30, 180, 220, 255))
        draw_pixel(g, 22, 14, (30, 180, 220, 255))

    # 2. Cabeza y Rostro (Filas 7 a 14)
    draw_rect(g, 11, 7, 10, 7, skin)
    # Contorno mandíbula
    draw_rect(g, 12, 14, 8, 1, skin_dark)

    # 3. Ojos
    if is_teacher:
        # Maestro Desinterés: Ojos blancos vacíos y fríos, sin pupila
        draw_rect(g, 12, 10, 2, 2, CLR_TEACHER_WHITE_EYES)
        draw_rect(g, 18, 10, 2, 2, CLR_TEACHER_WHITE_EYES)
        draw_pixel(g, 12, 9, CLR_OUTLINE)  # Ceja caída indiferente
        draw_pixel(g, 13, 9, CLR_OUTLINE)
        draw_pixel(g, 18, 9, CLR_OUTLINE)
        draw_pixel(g, 19, 9, CLR_OUTLINE)
        # Boca recta fría
        draw_rect(g, 14, 13, 4, 1, (80, 85, 95, 255))
    else:
        # Ojos expresivos juveniles
        draw_pixel(g, 12, 10, CLR_OUTLINE)
        draw_pixel(g, 13, 10, CLR_OUTLINE)
        draw_pixel(g, 18, 10, CLR_OUTLINE)
        draw_pixel(g, 19, 10, CLR_OUTLINE)
        draw_pixel(g, 12, 11, hair_col)
        draw_pixel(g, 13, 11, hair_col)
        draw_pixel(g, 18, 11, hair_col)
        draw_pixel(g, 19, 11, hair_col)

        # Rubor juvenil en mejillas
        draw_pixel(g, 11, 12, CLR_BLUSH)
        draw_pixel(g, 20, 12, CLR_BLUSH)
        # Sonrisa
        draw_rect(g, 14, 13, 4, 1, (180, 60, 70, 255))

    if char_id in ["sofia_direccion", "fernanda_biblioteca"]:
        # Gafas inteligentes
        draw_rect(g, 12, 10, 3, 2, CLR_CLEAR)
        draw_rect(g, 17, 10, 3, 2, CLR_CLEAR)
        # Marco gafas
        draw_rect(g, 11, 9, 4, 3, (40, 120, 180, 255))
        draw_rect(g, 17, 9, 4, 3, (40, 120, 180, 255))
        draw_pixel(g, 15, 10, (40, 120, 180, 255))
        draw_pixel(g, 16, 10, (40, 120, 180, 255))
        # Ojos dentro del lente
        draw_pixel(g, 12, 10, hair_col)
        draw_pixel(g, 18, 10, hair_col)

    # 4. Cuello y Cuello de Camisa Escolar (Filas 14 a 16)
    draw_rect(g, 14, 15, 4, 2, CLR_WHITE)
    if is_teacher:
        # Corbata floja y torcida
        draw_rect(g, 15, 16, 2, 4, CLR_TEACHER_TIE_DULL)
        draw_pixel(g, 16, 20, CLR_TEACHER_TIE_DULL)
    else:
        # Cuello institucional COBAEM
        draw_pixel(g, 14, 15, CLR_SHIRT_SHADOW)
        draw_pixel(g, 17, 15, CLR_SHIRT_SHADOW)

    # 5. Torso / Uniforme COBAEM (Filas 16 a 22)
    if is_teacher:
        # Traje de docente grisáceo oscuro
        draw_rect(g, 10, 17, 12, 6, CLR_TEACHER_SUIT_DARK)
        draw_rect(g, 12, 17, 8, 5, CLR_TEACHER_SUIT_LIGHT)
        draw_rect(g, 14, 17, 4, 3, CLR_WHITE)  # Camisa interior
        # Portafolios / libreta de indiferencia en la mano izquierda
        draw_rect(g, 7, 19, 4, 5, (160, 140, 110, 255))
        draw_rect(g, 8, 18, 2, 1, CLR_OUTLINE)
    elif char_id == "mateo_laboratorio":
        # Bata blanca de laboratorio sobre el uniforme guinda
        draw_rect(g, 10, 17, 12, 6, CLR_WHITE)
        draw_rect(g, 13, 17, 6, 5, CLR_VINO_BASE)
        draw_rect(g, 10, 21, 12, 2, CLR_WHITE)
    elif char_id == "maria_cafeteria":
        # Suéter guinda con mandil limpio escolar
        draw_rect(g, 10, 17, 12, 6, CLR_VINO_BASE)
        draw_rect(g, 12, 18, 8, 5, (245, 235, 220, 255))  # Mandil
    else:
        # Suéter Guinda Institucional oficial
        draw_rect(g, 10, 17, 12, 6, CLR_VINO_BASE)
        draw_rect(g, 10, 21, 12, 2, CLR_VINO_DARK)
        # Escudo escolar COBAEM en el pecho (verde y dorado)
        draw_pixel(g, 12, 18, CLR_GOLD)
        draw_pixel(g, 12, 19, CLR_GREEN_EMBLEM)

    # Manos
    draw_rect(g, 8, 21, 2, 2, skin)
    draw_rect(g, 22, 21, 2, 2, skin)

    # 6. Parte Inferior: Pantalón o Falda escolar (Filas 23 a 27)
    if is_teacher:
        # Pantalón formal gris oscuro
        draw_rect(g, 11, 23, 10, 5, CLR_TEACHER_SUIT_DARK)
        draw_rect(g, 15, 24, 2, 4, CLR_OUTLINE)  # Separación piernas
    elif is_skirt:
        # Falda tableada escolar guinda/gris
        draw_rect(g, 10, 23, 12, 4, CLR_VINO_DARK)
        # Piernas con calcetas blancas escolares
        draw_rect(g, 12, 26, 3, 2, CLR_WHITE)
        draw_rect(g, 17, 26, 3, 2, CLR_WHITE)
    else:
        # Pantalón gris carbón oficial COBAEM
        draw_rect(g, 11, 23, 10, 5, CLR_PANTS_GRAY)
        draw_rect(g, 15, 24, 2, 4, CLR_PANTS_DARK)

    # 7. Zapatos escolares (Filas 28 a 29)
    draw_rect(g, 11, 28, 4, 2, CLR_OUTLINE)
    draw_rect(g, 17, 28, 4, 2, CLR_OUTLINE)

    # Delineado suave estilo pixel art
    for c in range(11, 21):
        if g[3][c] == CLR_CLEAR and g[4][c] != CLR_CLEAR:
            g[3][c] = CLR_OUTLINE
    for r in range(4, 29):
        # bordes laterales
        for c in range(5, 27):
            if g[r][c] != CLR_CLEAR:
                if c > 0 and g[r][c - 1] == CLR_CLEAR:
                    g[r][c - 1] = CLR_OUTLINE
                break
        for c in range(26, 4, -1):
            if g[r][c] != CLR_CLEAR:
                if c < 31 and g[r][c + 1] == CLR_CLEAR:
                    g[r][c + 1] = CLR_OUTLINE
                break

    return g


# =============================================================================
# GENERADORES DE RETRATOS DE ROSTRO (32x32 -> 256x256)
# =============================================================================

def make_character_portrait(char_id, variant="neutral"):
    """Genera retrato primer plano para cinemáticas del Modo Historia."""
    g = create_pixel_grid(32, 32)

    skin = CLR_SKIN_WARM
    skin_dark = CLR_SKIN_SHADOW
    hair_col = (40, 25, 20, 255)
    is_teacher = (char_id == "maestro_desinteres")

    if char_id == "valeria_plaza":
        skin = CLR_SKIN_WARM
        skin_dark = CLR_SKIN_SHADOW
        hair_col = (45, 30, 25, 255)
    elif char_id == "maria_cafeteria":
        hair_col = (115, 65, 35, 255)
    elif char_id == "fernanda_biblioteca":
        hair_col = (50, 35, 45, 255)
    elif char_id == "sofia_direccion":
        hair_col = (30, 25, 35, 255)
    elif char_id == "alejandro_cancha":
        hair_col = (25, 25, 28, 255)
    elif char_id == "diego_computo":
        hair_col = (35, 40, 50, 255)
    elif char_id == "mateo_laboratorio":
        hair_col = (55, 38, 25, 255)
    elif char_id == "maestro_desinteres_redeemed":
        skin = CLR_SKIN_WARM
        skin_dark = CLR_SKIN_SHADOW
        hair_col = (75, 65, 60, 255)
    elif is_teacher:
        skin = CLR_TEACHER_GREY_SKIN
        skin_dark = CLR_TEACHER_GREY_SHADOW
        hair_col = CLR_TEACHER_HAIR_GREY

    # Marco o fondo suave institucional
    bg_circle_col = (235, 240, 245, 255) if not is_teacher else (70, 75, 85, 255)
    for r in range(2, 30):
        for c in range(2, 30):
            dist_sq = (r - 16) ** 2 + (c - 16) ** 2
            if dist_sq <= 14 * 14:
                g[r][c] = bg_circle_col

    # Cuello y hombros (Filas 22 a 31)
    if is_teacher:
        draw_rect(g, 6, 23, 20, 9, CLR_TEACHER_SUIT_DARK)
        draw_rect(g, 12, 23, 8, 9, CLR_TEACHER_SUIT_LIGHT)
        draw_rect(g, 14, 21, 4, 5, CLR_WHITE)
        draw_rect(g, 15, 24, 2, 7, CLR_TEACHER_TIE_DULL)
    else:
        draw_rect(g, 6, 24, 20, 8, CLR_VINO_BASE)
        draw_rect(g, 13, 21, 6, 4, CLR_WHITE)
        draw_rect(g, 14, 24, 4, 3, CLR_VINO_DARK)
        # Escudo COBAEM
        draw_rect(g, 8, 25, 3, 3, CLR_GOLD)
        draw_pixel(g, 9, 26, CLR_GREEN_EMBLEM)

    # Cuello piel
    draw_rect(g, 13, 19, 6, 4, skin_dark)

    # Rostro base (Filas 7 a 20)
    draw_rect(g, 8, 8, 16, 12, skin)
    draw_rect(g, 9, 18, 14, 3, skin)
    draw_rect(g, 11, 20, 10, 1, skin_dark)

    # Cabello
    draw_rect(g, 7, 5, 18, 5, hair_col)
    draw_rect(g, 6, 8, 4, 8, hair_col)
    draw_rect(g, 22, 8, 4, 8, hair_col)

    if char_id == "valeria_plaza":
        # Broche esmeralda en el cabello
        draw_rect(g, 6, 8, 3, 3, (20, 160, 95, 255))
        draw_pixel(g, 7, 9, CLR_GOLD)
    elif char_id == "alejandro_cancha":
        # Cinta deportiva roja
        draw_rect(g, 7, 7, 18, 2, (220, 35, 35, 255))
    elif char_id == "sofia_direccion":
        # Diadema azul y gafas
        draw_rect(g, 8, 5, 16, 2, (40, 140, 200, 255))
    elif char_id == "diego_computo":
        # Auricular gamer cian
        draw_rect(g, 4, 11, 3, 7, (30, 180, 220, 255))
        draw_rect(g, 25, 11, 3, 7, (30, 180, 220, 255))
        draw_rect(g, 6, 5, 20, 1, (30, 180, 220, 255))

    # Ojos y Cejas
    if is_teacher:
        # Ojos blancos brillantes de Apatía / Desinterés
        draw_rect(g, 10, 12, 4, 3, CLR_TEACHER_WHITE_EYES)
        draw_rect(g, 18, 12, 4, 3, CLR_TEACHER_WHITE_EYES)
        # Cejas caídas
        draw_rect(g, 9, 10, 5, 1, (60, 65, 75, 255))
        draw_rect(g, 18, 10, 5, 1, (60, 65, 75, 255))
        # Ojeras profundas de fatiga e indiferencia
        draw_rect(g, 10, 15, 4, 1, (85, 90, 100, 255))
        draw_rect(g, 18, 15, 4, 1, (85, 90, 100, 255))
        # Boca indiferente
        draw_rect(g, 13, 18, 6, 1, (60, 65, 75, 255))
    else:
        # Cejas juveniles
        draw_rect(g, 10, 11, 4, 1, hair_col)
        draw_rect(g, 18, 11, 4, 1, hair_col)
        # Ojos con brillo blanco de esperanza
        draw_rect(g, 11, 13, 3, 3, CLR_OUTLINE)
        draw_rect(g, 18, 13, 3, 3, CLR_OUTLINE)
        draw_pixel(g, 12, 13, CLR_WHITE)
        draw_pixel(g, 19, 13, CLR_WHITE)
        # Rubor
        draw_rect(g, 9, 15, 3, 2, CLR_BLUSH)
        draw_rect(g, 20, 15, 3, 2, CLR_BLUSH)
        # Sonrisa
        draw_rect(g, 13, 17, 6, 2, (180, 50, 65, 255))
        draw_pixel(g, 14, 18, CLR_WHITE)
        draw_pixel(g, 17, 18, CLR_WHITE)

    if char_id in ["sofia_direccion", "fernanda_biblioteca"]:
        # Gafas grandes en primer plano
        draw_rect(g, 9, 12, 6, 5, (40, 120, 180, 255))
        draw_rect(g, 17, 12, 6, 5, (40, 120, 180, 255))
        draw_rect(g, 10, 13, 4, 3, skin)
        draw_rect(g, 18, 13, 4, 3, skin)
        draw_pixel(g, 15, 13, (40, 120, 180, 255))
        draw_pixel(g, 16, 13, (40, 120, 180, 255))
        # Ojos dentro
        draw_pixel(g, 12, 14, CLR_OUTLINE)
        draw_pixel(g, 19, 14, CLR_OUTLINE)
        draw_pixel(g, 11, 13, (200, 240, 255, 255))
        draw_pixel(g, 18, 13, (200, 240, 255, 255))

    return g


# =============================================================================
# MAIN RUNNER
# =============================================================================

CHARACTERS = [
    ("alejandro_cancha", "Alejandro — Cancha de Usos Múltiples (Deporte y Valores)"),
    ("maria_cafeteria", "María — Cafetería y Aulas (Empatía y Solidaridad)"),
    ("mateo_laboratorio", "Mateo — Laboratorio Edif. D (Ciencia y Respeto)"),
    ("valeria_plaza", "Valeria — Plaza Cívica (Liderazgo Cívico y Valores)"),
    ("fernanda_biblioteca", "Fernanda — Biblioteca Edif. B (Lectura y Honestidad)"),
    ("diego_computo", "Diego — Cómputo Edif. C (Tecnología y Compañerismo)"),
    ("sofia_direccion", "Sofía — Dirección Edif. C (Liderazgo Estudiantil)"),
    ("maestro_desinteres", "Maestro Desinterés — Jefe de Salón (Inacción ante Bullying)"),
    ("maestro_desinteres_redeemed", "Maestro Desinterés (Redimido) — Compromiso Docente y Escucha Activa"),
]

def main():
    print("=== GENERANDO RENDERS Y SPRITES PIXEL ART DE ALUMNOS Y MAESTRO DESINTERÉS ===")

    for d in OUT_DIRS:
        os.makedirs(d, exist_ok=True)

    for char_id, desc in CHARACTERS:
        print(f"-> Procesando: {desc}")

        # 1. Sprite de cuerpo completo (512x512, grilla 32x32 x16)
        body_grid = make_student_body(char_id)
        body_img = grid_to_image(body_grid, scale=16)

        # 2. Retrato de rostro para cinemáticas (256x256, grilla 32x32 x8)
        portrait_grid = make_character_portrait(char_id)
        portrait_img = grid_to_image(portrait_grid, scale=8)

        # Guardar en raíz de assets/ para acceso directo del usuario
        # (El usuario solicitó explícitamente: "ponlos dentro de assets y nombralos segun su nombre del juego y rol")
        body_img.save(f"assets/{char_id}.png")
        print(f"   [OK] assets/{char_id}.png (512x512)")

        # Guardar en subcarpetas del motor
        if char_id == "maestro_desinteres":
            body_img.save(f"assets/sprites/bosses/{char_id}.png")
        else:
            body_img.save(f"assets/sprites/students/{char_id}.png")
        body_img.save(f"assets/sprites/{char_id}.png")

        portrait_img.save(f"assets/portraits/{char_id}.png")
        print(f"   [OK] assets/portraits/{char_id}.png (256x256)")

    # Sincronizar personajes secundarios con la plantilla estándar
    try:
        import sys
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        if base_dir not in sys.path:
            sys.path.insert(0, base_dir)
        from tools.generate_secondary_characters import main as sync_secondary
        sync_secondary()
    except Exception as e:
        print(f"Aviso al sincronizar personajes secundarios: {e}")

    print("\nTodos los sprites y retratos pixel art fueron generados exitosamente en assets/.")


if __name__ == "__main__":
    main()
