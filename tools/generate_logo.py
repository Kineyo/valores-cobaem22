#!/usr/bin/env python3
"""
tools/generate_logo.py
Generador del nuevo escudo y logotipo institucional de
"Campeones de los Valores" — COBAEM Plantel CEMSaD 22 ENTHAVI.
Genera versiones en alta definición y optimizadas para interfaz:
  - assets/logos/cobaem-logo.png (512x512 RGBA)
  - assets/logos/nuevo_logo_cobaem.png (512x512 RGBA)
  - assets/logos/logo_cobaem_banner.png (1200x400 RGBA)
  - assets/sprites/cobaem_logo.png (128x128 RGBA pixel-crisp)
  - icon.png (256x256 RGBA)
"""

import math
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUTPUT_DIR = "assets/logos"
SPRITES_DIR = "assets/sprites"
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(SPRITES_DIR, exist_ok=True)

# Paleta Institucional COBAEM
GREEN_LIGHT = (46, 184, 98)
GREEN_CORE = (0, 132, 61)
GREEN_DARK = (0, 78, 36)

GUINDA_LIGHT = (217, 75, 104)
GUINDA_CORE = (166, 28, 60)
GUINDA_DARK = (94, 10, 30)
BURGUNDY_BG = (48, 8, 20)

GOLD_LIGHT = (255, 235, 140)
GOLD_CORE = (235, 175, 30)
GOLD_DARK = (150, 100, 10)
GOLD_SHADOW = (70, 45, 5)

WHITE = (255, 255, 255)
DARK_OUTLINE = (20, 16, 24)


def draw_cobaem_ribbon(draw, cx, cy, scale=1.0):
    """
    Dibuja con precisión vectorial las 3 cintas entrelazadas
    emblemáticas del COBAEM (verde superior, guinda central, verde inferior).
    """
    s = scale

    # Sombra arrojada de la cinta
    for ox, oy in [(3 * s, 4 * s), (2 * s, 3 * s)]:
        # Sombra loop superior
        draw.arc([cx - 42 * s + ox, cy - 80 * s + oy, cx + 38 * s + ox, cy - 10 * s + oy], 160, 360, fill=(20, 5, 10, 140), width=int(18 * s))
        # Sombra cinta media
        draw.arc([cx - 36 * s + ox, cy - 20 * s + oy, cx + 46 * s + ox, cy + 50 * s + oy], 180, 380, fill=(20, 5, 10, 140), width=int(18 * s))

    # 1. Cinta Superior Verde (Arco superior)
    # Capa base oscura
    draw.arc([cx - 44 * s, cy - 82 * s, cx + 36 * s, cy - 12 * s], 170, 370, fill=GREEN_DARK, width=int(22 * s))
    # Capa color corporativo
    draw.arc([cx - 42 * s, cy - 80 * s, cx + 38 * s, cy - 10 * s], 165, 365, fill=GREEN_CORE, width=int(18 * s))
    # Brillo superior
    draw.arc([cx - 40 * s, cy - 78 * s, cx + 40 * s, cy - 8 * s], 200, 330, fill=GREEN_LIGHT, width=int(6 * s))

    # 2. Cinta Central Guinda / Vino (Nudo intermedio doblado)
    draw.arc([cx - 38 * s, cy - 22 * s, cx + 44 * s, cy + 48 * s], 175, 375, fill=GUINDA_DARK, width=int(22 * s))
    draw.arc([cx - 36 * s, cy - 20 * s, cx + 46 * s, cy + 50 * s], 170, 370, fill=GUINDA_CORE, width=int(18 * s))
    draw.arc([cx - 34 * s, cy - 18 * s, cx + 48 * s, cy + 52 * s], 210, 330, fill=GUINDA_LIGHT, width=int(6 * s))

    # Remates y dobleces estilizados
    draw.polygon([
        (cx - 24 * s, cy - 12 * s),
        (cx + 10 * s, cy - 26 * s),
        (cx + 26 * s, cy - 10 * s),
        (cx - 8 * s, cy + 4 * s),
    ], fill=GUINDA_DARK)

    # 3. Cinta Inferior Verde (Cola envolvente y base)
    draw.arc([cx - 48 * s, cy + 20 * s, cx + 36 * s, cy + 90 * s], 90, 290, fill=GREEN_DARK, width=int(20 * s))
    draw.arc([cx - 46 * s, cy + 22 * s, cx + 38 * s, cy + 92 * s], 85, 285, fill=GREEN_CORE, width=int(16 * s))
    draw.arc([cx - 44 * s, cy + 24 * s, cx + 40 * s, cy + 94 * s], 110, 240, fill=GREEN_LIGHT, width=int(5 * s))

    # Terminal estilizada en punta de flecha / lazo
    draw.polygon([
        (cx + 22 * s, cy + 26 * s),
        (cx + 46 * s, cy + 34 * s),
        (cx + 34 * s, cy + 50 * s),
    ], fill=GREEN_CORE)
    draw.polygon([
        (cx + 25 * s, cy + 28 * s),
        (cx + 43 * s, cy + 34 * s),
        (cx + 33 * s, cy + 46 * s),
    ], fill=GREEN_LIGHT)


def draw_trophy_of_values(draw, cx, cy, scale=1.0):
    """Copa Dorada de la Excelencia y Virtudes Académicas."""
    s = scale
    # Sombra
    draw.ellipse([cx - 16 * s, cy + 24 * s, cx + 18 * s, cy + 32 * s], fill=(20, 5, 10, 160))
    # Pedestal
    draw.polygon([(cx - 14 * s, cy + 24 * s), (cx + 14 * s, cy + 24 * s), (cx + 10 * s, cy + 18 * s), (cx - 10 * s, cy + 18 * s)], fill=GOLD_DARK)
    draw.polygon([(cx - 12 * s, cy + 22 * s), (cx + 12 * s, cy + 22 * s), (cx + 8 * s, cy + 18 * s), (cx - 8 * s, cy + 18 * s)], fill=GOLD_CORE)
    draw.rectangle([cx - 4 * s, cy + 10 * s, cx + 4 * s, cy + 18 * s], fill=GOLD_CORE)
    draw.line([(cx - 2 * s, cy + 10 * s), (cx - 2 * s, cy + 18 * s)], fill=GOLD_LIGHT, width=max(1, int(2 * s)))

    # Copa
    draw.polygon([(cx - 16 * s, cy - 8 * s), (cx + 16 * s, cy - 8 * s), (cx + 10 * s, cy + 10 * s), (cx - 10 * s, cy + 10 * s)], fill=GOLD_DARK)
    draw.polygon([(cx - 14 * s, cy - 6 * s), (cx + 14 * s, cy - 6 * s), (cx + 8 * s, cy + 8 * s), (cx - 8 * s, cy + 8 * s)], fill=GOLD_CORE)
    draw.polygon([(cx - 12 * s, cy - 4 * s), (cx, cy - 4 * s), (cx - 2 * s, cy + 6 * s), (cx - 7 * s, cy + 6 * s)], fill=GOLD_LIGHT)

    # Asas de la copa
    draw.arc([cx - 22 * s, cy - 6 * s, cx - 12 * s, cy + 6 * s], 90, 270, fill=GOLD_CORE, width=max(1, int(3 * s)))
    draw.arc([cx + 12 * s, cy - 6 * s, cx + 22 * s, cy + 6 * s], 270, 90, fill=GOLD_CORE, width=max(1, int(3 * s)))

    # Gema central de la virtud (Rubí Guinda con brillo)
    draw.ellipse([cx - 4 * s, cy - 2 * s, cx + 4 * s, cy + 6 * s], fill=GUINDA_CORE, outline=GOLD_LIGHT)
    draw.point((int(cx - 1 * s), int(cy)), fill=WHITE)


def draw_star(draw, cx, cy, r_out, r_in, fill_color, outline_color=None):
    pts = []
    for i in range(10):
        angle = -math.pi / 2 + i * (math.pi / 5)
        r = r_out if i % 2 == 0 else r_in
        pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(pts, fill=fill_color, outline=outline_color)


def draw_laurel_leaf(draw, cx, cy, angle_rad, length, width, fill_c, outline_c):
    # Hoja de laurel curvada
    cos_a, sin_a = math.cos(angle_rad), math.sin(angle_rad)
    p0 = (cx, cy)
    p1 = (cx + length * cos_a - width * sin_a, cy + length * sin_a + width * cos_a)
    p2 = (cx + length * 1.5 * cos_a, cy + length * 1.5 * sin_a)
    p3 = (cx + length * cos_a + width * sin_a, cy + length * sin_a - width * cos_a)
    draw.polygon([p0, p1, p2, p3], fill=fill_c, outline=outline_c)
    draw.line([p0, p2], fill=GOLD_LIGHT, width=1)


def generate_emblem_logo(size=512):
    """Genera el escudo circular/medallón oficial de alta resolución."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = size // 2, size // 2 - 10
    radius = size * 0.43

    # Sombra exterior difusa del medallón
    for offset in range(12, 0, -2):
        alpha = int(12 * (13 - offset))
        draw.ellipse([cx - radius - offset + 6, cy - radius - offset + 12,
                      cx + radius + offset + 6, cy + radius + offset + 12],
                     fill=(10, 4, 8, alpha))

    # Anillo exterior dorado tallado
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=GOLD_SHADOW, outline=DARK_OUTLINE, width=2)
    draw.ellipse([cx - radius + 4, cy - radius + 4, cx + radius - 4, cy + radius - 4], fill=GOLD_DARK)
    draw.ellipse([cx - radius + 8, cy - radius + 8, cx + radius - 8, cy + radius - 8], fill=GOLD_CORE)
    draw.ellipse([cx - radius + 12, cy - radius + 12, cx + radius - 12, cy + radius - 12], fill=GOLD_LIGHT)
    draw.ellipse([cx - radius + 16, cy - radius + 16, cx + radius - 16, cy + radius - 16], fill=GOLD_DARK)

    # Campo interior guinda institucional con gradiente radial simulado
    inner_r = radius - 20
    draw.ellipse([cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r], fill=BURGUNDY_BG)
    for step in range(1, 16):
        r_step = inner_r * (1.0 - step * 0.055)
        alpha_tint = int(70 + step * 10)
        c = (GUINDA_DARK[0] + step * 3, GUINDA_DARK[1] + step, GUINDA_DARK[2] + step * 2)
        draw.ellipse([cx - r_step, cy - r_step - step * 2, cx + r_step, cy + r_step - step * 2], fill=c)

    # Patrón geométrico de rayos de virtud académica
    for deg in range(0, 360, 30):
        rad = math.radians(deg)
        x2 = cx + math.cos(rad) * (inner_r - 6)
        y2 = cy + math.sin(rad) * (inner_r - 6)
        draw.line([(cx, cy), (x2, y2)], fill=(255, 215, 120, 22), width=2)

    # Corona de Hojas de Laurel (Virtud, Esfuerzo y Triunfo Académico)
    for side in [-1, 1]:
        for i in range(7):
            theta = math.radians(110 + i * 22) if side == 1 else math.radians(70 - i * 22)
            lx = cx + math.cos(theta) * (inner_r - 18)
            ly = cy + math.sin(theta) * (inner_r - 18)
            leaf_angle = theta + (math.pi / 2 if side == 1 else -math.pi / 2) * 0.7
            draw_laurel_leaf(draw, lx, ly, leaf_angle, length=12, width=6, fill_c=GOLD_CORE, outline_c=GOLD_DARK)

    # 6 Estrellas Doradas representando los 6 Valores Fundamentales:
    # (Respeto, Responsabilidad, Empatía, Honestidad, Solidaridad, Perseverancia)
    star_angles = [-140, -112, -84, -56, -28, 0]  # Arco superior
    for ang in star_angles:
        rad = math.radians(ang - 20)
        sx = cx + math.cos(rad) * (inner_r - 16)
        sy = cy + math.sin(rad) * (inner_r - 16)
        draw_star(draw, sx, sy, r_out=7, r_in=3.5, fill_color=GOLD_LIGHT, outline_color=GOLD_SHADOW)

    # Cintas entrelazadas oficiales COBAEM en el centro del medallón
    draw_cobaem_ribbon(draw, cx - 2, cy - 22, scale=1.35)

    # Copa de la Excelencia y Virtudes en la base
    draw_trophy_of_values(draw, cx, cy + 96, scale=1.2)

    # Cintillo / Cinta de Pergamino Inferior Institucional
    bx1, by1 = cx - 180, cy + 155
    bx2, by2 = cx + 180, cy + 205

    # Sombra del listón
    draw.polygon([(bx1 + 4, by1 + 6), (bx2 + 4, by1 + 6), (bx2 + 16, by2 + 6), (bx1 - 8, by2 + 6)], fill=(15, 5, 10, 180))

    # Placas del listón en 3D
    draw.polygon([(bx1, by1), (bx2, by1), (bx2 + 10, by2), (bx1 - 10, by2)], fill=GOLD_CORE, outline=DARK_OUTLINE)
    draw.polygon([(bx1 + 3, by1 + 3), (bx2 - 3, by1 + 3), (bx2 + 7, by2 - 3), (bx1 - 7, by2 - 3)], fill=GOLD_LIGHT)
    draw.rectangle([bx1 + 10, by1 + 6, bx2 - 10, by2 - 6], fill=BURGUNDY_BG, outline=GOLD_CORE)

    # Textos institucionales dentro del listón
    # Usamos fuente básica limpia con dibujo manual de alta legibilidad
    draw_text_centered(draw, cx, by1 + 12, "COBAEM • CEMSAD 22", color=GOLD_LIGHT, size_px=15, bold=True)
    draw_text_centered(draw, cx, by1 + 28, "CAMPEONES DE LOS VALORES", color=WHITE, size_px=11, bold=True)

    return img


def draw_text_centered(draw, cx, y, text, color=WHITE, size_px=14, bold=False):
    """Dibuja texto institucional limpio y centrado."""
    # Intentamos cargar una fuente TrueType del sistema si está disponible, o usamos default
    font = None
    font_paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf" if bold else "/usr/share/fonts/truetype/freefont/FreeSans.ttf",
    ]
    for p in font_paths:
        if os.path.exists(p):
            try:
                font = ImageFont.truetype(p, size_px)
                break
            except Exception:
                pass
    if font is None:
        font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    # Sombra del texto
    draw.text((cx - w // 2 + 1, y + 1), text, fill=(10, 5, 8), font=font)
    draw.text((cx - w // 2, y), text, fill=color, font=font)


def generate_banner_logo():
    """Genera el banner horizontal institucional amplio (1200x400 px)."""
    banner = Image.new("RGBA", (1200, 400), (0, 0, 0, 0))
    draw = ImageDraw.Draw(banner)

    # Escudo a la izquierda
    emblem = generate_emblem_logo(360)
    banner.paste(emblem, (30, 20), emblem)

    # Tipografía a la derecha
    tx = 430
    draw_text_centered(draw, tx + 360, 60, "COLEGIO DE BACHILLERES DEL ESTADO DE MÉXICO", color=GOLD_CORE, size_px=26, bold=True)
    draw_text_centered(draw, tx + 360, 105, "PLANTEL CEMSaD 22 ENTHAVI", color=WHITE, size_px=34, bold=True)

    # Línea divisoria dorada con acentos verdes
    draw.line([(tx + 40, 160), (tx + 680, 160)], fill=GOLD_CORE, width=3)
    draw.line([(tx + 50, 162), (tx + 670, 162)], fill=GREEN_CORE, width=2)
    draw_star(draw, tx + 360, 160, 10, 5, fill_color=GOLD_LIGHT, outline_color=GOLD_SHADOW)

    draw_text_centered(draw, tx + 360, 185, "CAMPEONES DE LOS VALORES", color=GOLD_LIGHT, size_px=42, bold=True)
    draw_text_centered(draw, tx + 360, 250, "Videojuego Educativo & Visor Arquitectónico BIM a Escala Real", color=(210, 220, 230), size_px=18)
    draw_text_centered(draw, tx + 360, 285, "Honestidad · Respeto · Responsabilidad · Empatía · Solidaridad · Perseverancia", color=GOLD_CORE, size_px=14, bold=True)

    return banner


def main():
    print("Iniciando generación del nuevo logotipo y escudo institucional...")

    # 1. Escudo maestro en alta resolución (512x512)
    logo_512 = generate_emblem_logo(512)
    logo_512.save(os.path.join(OUTPUT_DIR, "nuevo_logo_cobaem.png"))
    logo_512.save(os.path.join(OUTPUT_DIR, "cobaem-logo.png"))
    print("  -> Generado: assets/logos/nuevo_logo_cobaem.png (512x512)")
    print("  -> Actualizado: assets/logos/cobaem-logo.png (512x512)")

    # 2. Icono del juego / ejecutable (256x256)
    icon_256 = logo_512.resize((256, 256), resample=Image.Resampling.LANCZOS)
    icon_256.save("icon.png")
    print("  -> Actualizado: icon.png (256x256)")

    # 3. Sprite pixel-crisp para el motor y HUD (128x128)
    sprite_128 = logo_512.resize((128, 128), resample=Image.Resampling.LANCZOS)
    sprite_128.save(os.path.join(SPRITES_DIR, "cobaem_logo.png"))
    print("  -> Actualizado: assets/sprites/cobaem_logo.png (128x128)")

    # 4. Banner institucional horizontal (1200x400)
    banner_img = generate_banner_logo()
    banner_img.save(os.path.join(OUTPUT_DIR, "logo_cobaem_banner.png"))
    print("  -> Generado: assets/logos/logo_cobaem_banner.png (1200x400)")

    print("¡Logotipos y escudos institucionales creados con éxito!")


if __name__ == "__main__":
    main()
