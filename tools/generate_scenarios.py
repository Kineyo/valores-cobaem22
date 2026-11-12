#!/usr/bin/env python3
"""
Generador de escenarios Pixel Art en perspectiva 3/4 a ESCALA REAL
para el juego "Campeones de los Valores" — Plantel CEMSaD 22 ENTHAVI (COBAEM).

Escala Arquitectónica Real (basada en plano_3d.html y planos_interactivos.html):
  - 1 metro real (100 cm) = 40 píxeles en el juego (20 texeles de arte píxel 2x2).
  - 1 píxel = 2.5 cm reales.
  - 1 baldosa modular (40 x 40 px) = 1.00 m x 1.00 m = 10,000 cm² (1.00 m²).

VERSIÓN REFINADA: Sombras arrojadas 3/4, oclusión ambiental, biseles 3D,
texturas ricas de suelo, reflejos especulares y microdetalles arquitectónicos.
"""

import os
import math
from PIL import Image, ImageDraw

OUTPUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "escenarios"))
os.makedirs(OUTPUT_DIR, exist_ok=True)

SCALE_PX_PER_M = 40
TEXEL_PER_M = 20  # 1 texel = 2x2 px = 5 cm x 5 cm reales

PAL = {
    "outline": (22, 20, 30),
    "shadow_deep": (18, 22, 32, 110),
    "shadow_contact": (12, 14, 20, 160),
    "shadow_soft": (20, 26, 36, 60),
    "grass_base": (64, 144, 58),
    "grass_dark": (46, 114, 42),
    "grass_light": (88, 172, 74),
    "grass_highlight": (118, 198, 96),
    "flower_white": (252, 252, 254),
    "flower_yellow": (254, 228, 64),
    "flower_purple": (174, 108, 214),
    "dirt_patch": (116, 84, 54),
    "dirt_light": (142, 106, 70),
    "hedge_dark": (32, 88, 38),
    "hedge_mid": (48, 124, 50),
    "hedge_light": (82, 172, 68),
    "hedge_flower": (240, 120, 160),
    "trunk": (98, 62, 36),
    "trunk_dark": (68, 40, 22),
    "trunk_highlight": (132, 88, 54),
    "concrete": (200, 204, 210),
    "concrete_light": (224, 228, 234),
    "concrete_dark": (158, 164, 172),
    "concrete_shadow": (138, 144, 154),
    "concrete_joint": (132, 138, 148),
    "curb_yellow": (246, 202, 24),
    "curb_yellow_light": (255, 232, 88),
    "curb_yellow_dark": (186, 142, 12),
    "zebra_blue": (26, 118, 208),
    "zebra_blue_light": (56, 150, 244),
    "zebra_white": (244, 248, 252),
    "stone_black": (38, 42, 50),
    "stone_dark": (24, 27, 34),
    "stone_highlight": (62, 68, 80),
    "stone_mortar": (220, 226, 234),
    "guinda": (118, 24, 68),
    "guinda_dark": (78, 14, 44),
    "guinda_light": (152, 40, 92),
    "cobaem_purple": (84, 22, 74),
    "terracota": (192, 122, 78),
    "terracota_dark": (154, 92, 52),
    "terracota_light": (220, 148, 102),
    "ochre_wall": (210, 150, 92),
    "brick_red": (194, 82, 54),
    "brick_dark": (152, 58, 36),
    "brick_mortar": (224, 214, 204),
    "green_bldg": (128, 194, 88),
    "green_bldg_dark": (92, 152, 58),
    "green_bldg_light": (162, 220, 124),
    "green_mint_wall": (164, 214, 158),
    "green_mint_dark": (122, 172, 118),
    "mustard": (184, 152, 60),
    "mustard_dark": (144, 116, 40),
    "tile_cream": (234, 224, 200),
    "tile_cream_alt": (220, 208, 184),
    "tile_grid": (188, 174, 148),
    "white": (248, 250, 252),
    "silver": (180, 190, 200),
    "silver_light": (216, 224, 232),
    "window_glass": (92, 164, 216),
    "window_dark": (44, 88, 128),
    "wood_desk": (164, 104, 52),
    "wood_mahogany": (124, 48, 34),
    "lab_blue": (30, 114, 174),
    "roof_red": (164, 44, 44),
    "gate_green": (26, 114, 70),
    "alfarda_rose": (172, 44, 88),
}

TINY_FONT = {
    "A": ["010", "101", "111", "101", "101"],
    "B": ["110", "101", "110", "101", "110"],
    "C": ["011", "100", "100", "100", "011"],
    "D": ["110", "101", "101", "101", "110"],
    "E": ["111", "100", "110", "100", "111"],
    "F": ["111", "100", "110", "100", "100"],
    "G": ["011", "100", "101", "101", "011"],
    "H": ["101", "101", "111", "101", "101"],
    "I": ["111", "010", "010", "010", "111"],
    "J": ["001", "001", "001", "101", "010"],
    "K": ["101", "101", "110", "101", "101"],
    "L": ["100", "100", "100", "100", "111"],
    "M": ["101", "111", "111", "101", "101"],
    "N": ["101", "111", "111", "111", "101"],
    "O": ["010", "101", "101", "101", "010"],
    "P": ["110", "101", "110", "100", "100"],
    "Q": ["010", "101", "101", "111", "001"],
    "R": ["110", "101", "110", "101", "101"],
    "S": ["011", "100", "010", "001", "110"],
    "T": ["111", "010", "010", "010", "010"],
    "U": ["101", "101", "101", "101", "111"],
    "V": ["101", "101", "101", "101", "010"],
    "W": ["101", "101", "111", "111", "101"],
    "X": ["101", "101", "010", "101", "101"],
    "Y": ["101", "101", "010", "010", "010"],
    "Z": ["111", "001", "010", "100", "111"],
    "0": ["111", "101", "101", "101", "111"],
    "1": ["010", "110", "010", "010", "111"],
    "2": ["111", "001", "111", "100", "111"],
    "3": ["111", "001", "011", "001", "111"],
    "4": ["101", "101", "111", "001", "001"],
    "5": ["111", "100", "111", "001", "111"],
    "6": ["111", "100", "111", "101", "111"],
    "7": ["111", "001", "010", "010", "010"],
    "8": ["111", "101", "111", "101", "111"],
    "9": ["111", "101", "111", "001", "111"],
    ".": ["000", "000", "000", "000", "010"],
    "-": ["000", "000", "111", "000", "000"],
    "/": ["001", "001", "010", "100", "100"],
    " ": ["000", "000", "000", "000", "000"],
}


def draw_pixel_sign(draw, cx, cy, text: str, bg=PAL["white"], fg=PAL["outline"], border=PAL["outline"]):
    """Dibuja un cartel/placa arquitectónica con bisel y sombra."""
    text = text.upper()
    tw = len(text) * 4 + 5
    th = 10
    x1 = cx - tw // 2
    y1 = cy - th // 2
    # Sombra del letrero
    draw.rectangle([x1 + 1, y1 + 2, x1 + tw + 1, y1 + th + 2], fill=(15, 12, 18, 130))
    # Cuerpo y marco
    draw.rectangle([x1, y1, x1 + tw, y1 + th], fill=bg, outline=border)
    # Bisel superior claro
    draw.line([(x1 + 1, y1 + 1), (x1 + tw - 1, y1 + 1)], fill=PAL["white"])
    ox = x1 + 3
    oy = y1 + 2
    for ch in text:
        glyph = TINY_FONT.get(ch, TINY_FONT[" "])
        for ry, row in enumerate(glyph):
            for rx, bit in enumerate(row):
                if bit == "1":
                    draw.point((ox + rx, oy + ry), fill=fg)
        ox += 4


def m_to_t(meters: float) -> int:
    return int(round(meters * TEXEL_PER_M))


def new_canvas(width_m: float, height_m: float, bg_color=(64, 144, 58)):
    tw = m_to_t(width_m)
    th = m_to_t(height_m)
    img = Image.new("RGBA", (tw, th), bg_color + (255,))
    draw = ImageDraw.Draw(img)
    return img, draw, tw, th


def save_pixel_art(img: Image.Image, filename: str):
    final_w = img.width * 2
    final_h = img.height * 2
    out = img.resize((final_w, final_h), resample=Image.Resampling.NEAREST)
    path = os.path.join(OUTPUT_DIR, filename)
    out.save(path, "PNG")
    print(f"Generado: {filename} ({final_w} x {final_h} px = {final_w/40:.1f}m x {final_h/40:.1f}m)")


# ==============================================================================
# SISTEMA DE SOMBRAS Y DETALLES EN PERSPECTIVA 3/4
# ==============================================================================

def draw_cast_shadow_box(draw, x1, y1, x2, y2, depth=10, dx=6):
    """
    Dibuja la sombra arrojada en perspectiva 3/4 hacia el sur-sureste
    proyectada por volúmenes arquitectónicos (edificios, muros, bardas).
    """
    # Sombra en la base sur
    draw.polygon([
        (x1, y2),
        (x2, y2),
        (x2 + dx, y2 + depth),
        (x1 + dx, y2 + depth)
    ], fill=(16, 20, 28, 120))
    # Sombra en el costado oriente
    draw.polygon([
        (x2, y1),
        (x2 + dx, y1 + depth),
        (x2 + dx, y2 + depth),
        (x2, y2)
    ], fill=(16, 20, 28, 90))


def draw_roof_overhang_shadow(draw, x1, y, x2, height=5):
    """Sombra de alero de techumbre sobre la fachada inferior."""
    draw.rectangle([x1, y, x2, y + height], fill=(12, 10, 16, 140))
    draw.rectangle([x1, y + height, x2, y + height + 2], fill=(12, 10, 16, 60))


def draw_ambient_occlusion_line(draw, x1, y, x2, height=3):
    """Sombra de contacto en la unión suelo-muro."""
    draw.rectangle([x1, y - height, x2, y], fill=(10, 12, 16, 150))


def fill_grass_texture(draw, x1, y1, x2, y2):
    """Pasto multicapa con flores silvestres, mechones 3D y variación tonal."""
    draw.rectangle([x1, y1, x2, y2], fill=PAL["grass_base"])
    for y in range(y1, y2, 5):
        for x in range(x1, x2, 5):
            h = (x * 7 + y * 13) % 17
            if h < 5:
                draw.rectangle([x, y, min(x + 4, x2), min(y + 4, y2)], fill=PAL["grass_dark"])
            elif h > 13:
                draw.rectangle([x, y, min(x + 3, x2), min(y + 3, y2)], fill=PAL["grass_light"])

            # Mechones de pasto en relieve
            if h == 7 and x + 3 < x2 and y + 4 < y2:
                draw.line([(x + 1, y + 3), (x + 1, y)], fill=PAL["grass_highlight"])
                draw.line([(x + 2, y + 3), (x + 3, y + 1)], fill=PAL["grass_highlight"])
                draw.point((x + 1, y + 4), fill=PAL["grass_dark"])

            # Flores silvestres COBAEM (margaritas blancas, amarillas y flores lilas)
            elif h == 11 and x + 2 < x2 and y + 2 < y2:
                flower_col = PAL["flower_yellow"] if (x + y) % 3 == 0 else (PAL["flower_white"] if (x + y) % 3 == 1 else PAL["flower_purple"])
                draw.point((x + 1, y + 1), fill=flower_col)
                draw.point((x + 2, y + 1), fill=flower_col)
                draw.point((x + 1, y + 2), fill=PAL["grass_dark"])


def fill_concrete_slabs(draw, x1, y1, x2, y2, slab_t=40):
    """Pavimento de concreto con biseles de luz/sombra en cada losa."""
    draw.rectangle([x1, y1, x2, y2], fill=PAL["concrete"])
    # Textura de micro-grano de cemento
    for y in range(y1, y2, 4):
        for x in range(x1, x2, 4):
            val = (x * 3 + y * 5) % 11
            if val == 0:
                draw.point((x, y), fill=PAL["concrete_light"])
            elif val == 1:
                draw.point((x, y), fill=PAL["concrete_dark"])

    # Juntas de dilatación con luz superior y sombra inferior (Efecto biselado 3D)
    for y in range(y1, y2 + 1, slab_t):
        draw.line([(x1, y - 1), (x2, y - 1)], fill=PAL["concrete_light"], width=1)
        draw.line([(x1, y), (x2, y)], fill=PAL["concrete_joint"], width=1)
        draw.line([(x1, y + 1), (x2, y + 1)], fill=PAL["concrete_shadow"], width=1)
    for x in range(x1, x2 + 1, slab_t):
        draw.line([(x - 1, y1), (x - 1, y2)], fill=PAL["concrete_light"], width=1)
        draw.line([(x, y1), (x, y2)], fill=PAL["concrete_joint"], width=1)
        draw.line([(x + 1, y1), (x + 1, y2)], fill=PAL["concrete_shadow"], width=1)

    # Marco perimetral
    draw.rectangle([x1, y1, x2, y2], outline=PAL["concrete_dark"])


def draw_curb_3d(draw, x1, y1, x2, y2, horizontal=True):
    """Guarnición amarilla con bisel superior de luz y cara vertical de sombra."""
    draw.rectangle([x1, y1, x2, y2], fill=PAL["curb_yellow"], outline=PAL["outline"])
    if horizontal:
        draw.line([(x1 + 1, y1 + 1), (x2 - 1, y1 + 1)], fill=PAL["curb_yellow_light"], width=1)
        draw.line([(x1 + 1, y2 - 1), (x2 - 1, y2 - 1)], fill=PAL["curb_yellow_dark"], width=1)
        # Sombra de contacto inferior
        draw.line([(x1, y2 + 1), (x2, y2 + 1)], fill=(20, 20, 25, 120), width=1)
    else:
        draw.line([(x1 + 1, y1 + 1), (x1 + 1, y2 - 1)], fill=PAL["curb_yellow_light"], width=1)
        draw.line([(x2 - 1, y1 + 1), (x2 - 1, y2 - 1)], fill=PAL["curb_yellow_dark"], width=1)
        draw.line([(x2 + 1, y1), (x2 + 1, y2)], fill=(20, 20, 25, 120), width=1)


def fill_ceramic_tiles(draw, x1, y1, x2, y2, tile_t=8):
    """Piso de baldosas cerámicas con brillo y sombra perimetral."""
    for y in range(y1, y2, tile_t):
        for x in range(x1, x2, tile_t):
            c = PAL["tile_cream"] if ((x // tile_t + y // tile_t) % 2 == 0) else PAL["tile_cream_alt"]
            draw.rectangle([x, y, min(x + tile_t - 1, x2), min(y + tile_t - 1, y2)], fill=c)
            # Destello de brillo en esquinas de baldosas
            if ((x * 11 + y * 7) % 19) == 0:
                draw.point((x + 1, y + 1), fill=PAL["white"])

    for y in range(y1, y2 + 1, tile_t):
        draw.line([(x1, y), (x2, y)], fill=PAL["tile_grid"])
    for x in range(x1, x2 + 1, tile_t):
        draw.line([(x, y1), (x, y2)], fill=PAL["tile_grid"])

    # Sombra interior superior de los muros
    draw.rectangle([x1, y1, x2, min(y2, y1 + 5)], fill=(12, 10, 16, 110))
    draw.rectangle([x1, y1, min(x2, x1 + 4), y2], fill=(12, 10, 16, 80))


def draw_brick_wall_patch(draw, x1, y1, x2, y2):
    """Muro de tabique rojo con juntas biseladas y relieve."""
    draw.rectangle([x1, y1, x2, y2], fill=PAL["brick_red"])
    # Sombra superior del muro
    draw.line([(x1, y1), (x2, y1)], fill=PAL["brick_dark"], width=1)
    for y in range(y1 + 1, y2, 3):
        draw.line([(x1, y), (x2, y)], fill=PAL["brick_mortar"])
        offset = 3 if ((y - y1) // 3) % 2 == 1 else 0
        for x in range(x1 + offset, x2, 6):
            draw.line([(x, y), (x, min(y + 3, y2))], fill=PAL["brick_mortar"])
            # Sombra y luz de tabique
            if x + 1 < x2:
                draw.point((x + 1, y + 1), fill=PAL["brick_dark"])
    draw.rectangle([x1, y1, x2, y2], outline=PAL["outline"])


def draw_stone_retaining_wall(draw, x1, y1, x2, y2):
    """Muro de contención de piedra braza negra con juntas blancas y relieve 3D."""
    # Sombra arrojada al pie del muro
    draw_cast_shadow_box(draw, x1, y1, x2, y2, depth=8, dx=6)
    draw.rectangle([x1, y1, x2, y2], fill=PAL["stone_black"])
    step_y = 10
    step_x = 14
    for row, y in enumerate(range(y1, y2, step_y)):
        ny = min(y + step_y, y2)
        for col, x in enumerate(range(x1, x2, step_x)):
            nx = min(x + step_x, x2)
            jitter = ((row * 7 + col * 13) % 5) - 2
            shade = PAL["stone_dark"] if (row + col) % 2 == 0 else PAL["stone_black"]
            if nx - 1 >= x + 1 and ny - 1 >= y + 1:
                draw.rectangle([x + 1, y + 1, nx - 1, ny - 1], fill=shade)
                draw.point((x + 2, y + 2), fill=PAL["stone_highlight"])
            draw.line([(x, y), (nx, min(y2, max(y1, y + jitter)))], fill=PAL["stone_mortar"])
            draw.line([(x, y), (min(x2, max(x1, x + jitter)), ny)], fill=PAL["stone_mortar"])

    # Remate superior del muro de piedra
    draw.line([(x1, y1), (x2, y1)], fill=PAL["silver_light"], width=2)
    draw.rectangle([x1, y1, x2, y2], outline=PAL["outline"])


def draw_white_railing(draw, x1, y, x2, height=12):
    """Barandal blanco con postes de tubo estructural y sombra proyectada."""
    # Sombra del barandal en el suelo
    draw.line([(x1 + 4, y + 6), (x2 + 4, y + 6)], fill=(15, 20, 26, 100), width=2)
    for x in range(x1 + 8, x2, 16):
        draw.line([(x + 2, y), (x + 5, y + 6)], fill=(15, 20, 26, 80))

    # Barandal real
    draw.rectangle([x1, y - height, x2, y - height + 2], fill=PAL["white"], outline=PAL["outline"])
    draw.rectangle([x1, y - 2, x2, y], fill=PAL["silver"])
    for x in range(x1, x2 + 1, 8):
        draw.line([(x, y - height), (x, y)], fill=PAL["white"])
    for x in range(x1, x2 + 1, 32):
        draw.rectangle([x - 1, y - height - 2, x + 1, y], fill=PAL["green_bldg_light"], outline=PAL["outline"])


def draw_window_grille(draw, x1, y1, x2, y2):
    """Ventanal arquitectónico con sombra superior, cancelería y destellos de cristal."""
    draw.rectangle([x1, y1, x2, y2], fill=PAL["window_dark"], outline=PAL["outline"])
    draw.rectangle([x1 + 2, y1 + 2, x2 - 2, y2 - 2], fill=PAL["window_glass"])
    # Sombra superior del marco
    draw.rectangle([x1 + 2, y1 + 2, x2 - 2, y1 + 4], fill=(20, 45, 70))
    # Destellos diagonales de luz en el cristal (//)
    mid_w = (x2 - x1) // 3
    for ox in [x1 + 8, x1 + mid_w + 6]:
        draw.line([(ox, y1 + 3), (ox + 10, y2 - 3)], fill=(255, 255, 255, 160), width=1)
        draw.line([(ox + 3, y1 + 3), (ox + 13, y2 - 3)], fill=(255, 255, 255, 90), width=1)

    # Cancel de aluminio blanco
    for y in range(y1 + 4, y2 - 2, 5):
        draw.line([(x1 + 1, y), (x2 - 1, y)], fill=PAL["white"])
    for x in range(x1 + 6, x2 - 2, 8):
        draw.line([(x, y1 + 1), (x, y2 - 1)], fill=PAL["white"])

    # Alféizar / Repisa inferior
    draw.line([(x1 - 1, y2 + 1), (x2 + 1, y2 + 1)], fill=PAL["concrete_light"], width=1)
    draw.line([(x1, y2 + 2), (x2, y2 + 2)], fill=(15, 15, 20, 100), width=1)


def draw_door_3d(draw, x, y, w=18, h=26, color=PAL["white"]):
    """Puerta 3D con dintel sombreado, ventana superior y escalón de acceso."""
    # Sombra del dintel superior
    draw.rectangle([x, y - h, x + w, y - h + 3], fill=(20, 15, 22, 140))
    draw.rectangle([x, y - h, x + w, y], fill=color, outline=PAL["outline"])
    draw.rectangle([x + 3, y - h + 4, x + w - 3, y - h // 2], fill=PAL["window_glass"], outline=PAL["outline"])
    # Reflejo en cristal de la puerta
    draw.line([(x + 5, y - h + 6), (x + w - 5, y - h // 2 - 2)], fill=PAL["white"])
    # Manija dorada y cerradura
    draw.rectangle([x + w - 4, y - h // 2 - 1, x + w - 2, y - h // 2 + 2], fill=PAL["curb_yellow"])
    # Escalón / umbral de entrada
    draw.rectangle([x - 1, y, x + w + 1, y + 3], fill=PAL["curb_yellow"], outline=PAL["outline"])


def draw_pine_tree(draw, cx, cy, radius=18):
    """Pino frondoso con sombra elíptica arrojada en el suelo."""
    # Sombra proyectada hacia el sur-sureste
    draw.ellipse([cx - radius + 4, cy + 8, cx + radius + 12, cy + radius // 2 + 16], fill=(16, 28, 20, 150))
    # Tronco con luz y sombra
    draw.rectangle([cx - 3, cy - 6, cx + 3, cy + 10], fill=PAL["trunk"], outline=PAL["outline"])
    draw.line([(cx - 2, cy - 5), (cx - 2, cy + 9)], fill=PAL["trunk_highlight"])
    draw.line([(cx + 2, cy - 5), (cx + 2, cy + 9)], fill=PAL["trunk_dark"])

    # Foliación cónica en 4 niveles con sombras y luces volumétricas
    for dy, r in [(0, radius), (-8, int(radius * 0.82)), (-16, int(radius * 0.62)), (-22, int(radius * 0.42))]:
        draw.ellipse([cx - r, cy + dy - r // 2, cx + r, cy + dy + r // 2], fill=PAL["hedge_dark"], outline=PAL["outline"])
        draw.ellipse([cx - r + 2, cy + dy - r // 2 + 1, cx + r - 2, cy + dy + r // 2 - 2], fill=PAL["hedge_mid"])
        draw.ellipse([cx - r // 2, cy + dy - r // 2 + 2, cx + r // 3, cy + dy], fill=PAL["hedge_light"])
        # Destello de sol superior
        top_y0 = cy + dy - r // 2 + 1
        top_y1 = max(top_y0 + 1, cy + dy - r // 4)
        draw.ellipse([cx - r // 3, top_y0, cx, top_y1], fill=PAL["grass_highlight"])


def draw_spiral_topiary(draw, cx, cy):
    """Arbusto topiario espiral con sombra en el suelo."""
    draw.ellipse([cx - 8 + 3, cy + 4, cx + 11, cy + 12], fill=(16, 28, 20, 150))
    draw.rectangle([cx - 2, cy - 2, cx + 2, cy + 5], fill=PAL["trunk"], outline=PAL["outline"])
    for dy, rx, ry in [(0, 9, 5), (-6, 8, 4), (-12, 6, 4), (-17, 4, 3)]:
        draw.ellipse([cx - rx, cy + dy - ry, cx + rx, cy + dy + ry], fill=PAL["hedge_mid"], outline=PAL["outline"])
        draw.ellipse([cx - rx + 2, cy + dy - ry + 1, cx + rx - 3, cy + dy], fill=PAL["hedge_light"])
        draw.point((cx - 2, cy + dy - 1), fill=PAL["grass_highlight"])


def draw_car_3d(draw, cx, cy, body_color):
    """Vehículo 3/4 con sombra arrojada, llantas, parabrisas y luces."""
    w, h = 34, 64
    x1, y1, x2, y2 = cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2
    # Sombra densa bajo el chasis y proyectada a la derecha
    draw.polygon([
        (x1 + 2, y2),
        (x2 + 2, y2),
        (x2 + 12, y2 + 10),
        (x1 + 10, y2 + 10)
    ], fill=(18, 22, 28, 140))
    draw.rectangle([x1 + 2, y1 + 4, x2 + 4, y2 + 2], fill=PAL["concrete_shadow"])

    # Ruedas
    for wy in [y1 + 8, y2 - 14]:
        draw.rectangle([x1 - 3, wy, x1 + 2, wy + 10], fill=PAL["outline"])
        draw.rectangle([x2 - 2, wy, x2 + 3, wy + 10], fill=PAL["outline"])
        draw.rectangle([x1 - 1, wy + 2, x1 + 1, wy + 8], fill=PAL["silver"])
        draw.rectangle([x2 - 1, wy + 2, x2 + 1, wy + 8], fill=PAL["silver"])

    # Carrocería
    draw.rectangle([x1, y1, x2, y2], fill=body_color, outline=PAL["outline"])
    # Brillo lateral izquierdo de la carrocería
    draw.line([(x1 + 1, y1 + 4), (x1 + 1, y2 - 4)], fill=PAL["white"], width=1)

    # Parabrisas y toldo
    draw.rectangle([x1 + 3, y1 + 12, x2 - 3, y2 - 12], fill=PAL["window_dark"], outline=PAL["outline"])
    draw.line([(x1 + 5, y1 + 14), (x2 - 5, y1 + 22)], fill=PAL["window_glass"], width=2)
    draw.rectangle([x1 + 4, y1 + 20, x2 - 4, y2 - 18], fill=body_color, outline=PAL["outline"])

    # Faros delanteros y traseros
    draw.rectangle([x1 + 4, y1 + 1, x1 + 10, y1 + 4], fill=PAL["curb_yellow"])
    draw.rectangle([x2 - 10, y1 + 1, x2 - 4, y1 + 4], fill=PAL["curb_yellow"])
    draw.rectangle([x1 + 4, y2 - 4, x1 + 10, y2 - 1], fill=PAL["roof_red"])
    draw.rectangle([x2 - 10, y2 - 4, x2 - 4, y2 - 1], fill=PAL["roof_red"])


def draw_solar_streetlamp(draw, cx, cy):
    """Poste de luz solar institucional COBAEM con sombra en el suelo."""
    # Sombra del poste proyectada a 45°
    draw.line([(cx, cy), (cx + 14, cy + 8)], fill=(15, 20, 26, 110), width=2)
    draw.ellipse([cx + 10, cy + 6, cx + 18, cy + 10], fill=(15, 20, 26, 90))

    # Base de concreto del poste
    draw.rectangle([cx - 3, cy - 2, cx + 3, cy + 2], fill=PAL["concrete_dark"], outline=PAL["outline"])
    # Tubo metálico blanco
    draw.line([(cx, cy - 2), (cx, cy - 32)], fill=PAL["white"], width=2)
    draw.line([(cx - 1, cy - 2), (cx - 1, cy - 32)], fill=PAL["silver"], width=1)

    # Panel solar orientado
    draw.polygon([(cx - 8, cy - 36), (cx + 8, cy - 33), (cx + 6, cy - 30), (cx - 10, cy - 33)], fill=PAL["window_dark"], outline=PAL["outline"])
    # Luminaria LED con brillo
    draw.rectangle([cx - 4, cy - 31, cx + 4, cy - 27], fill=PAL["curb_yellow_light"], outline=PAL["outline"])
    draw.point((cx, cy - 29), fill=PAL["white"])


def draw_manhole_cover(draw, cx, cy, is_square=False):
    """Tapa de registro sanitario / agua pluvial de hierro fundido."""
    draw.ellipse([cx - 8 + 1, cy - 6 + 2, cx + 9, cy + 8], fill=(15, 18, 24, 120))
    if is_square:
        draw.rectangle([cx - 7, cy - 7, cx + 7, cy + 7], fill=PAL["stone_black"], outline=PAL["stone_dark"])
        draw.line([(cx - 5, cy), (cx + 5, cy)], fill=PAL["silver"])
        draw.line([(cx, cy - 5), (cx, cy + 5)], fill=PAL["silver"])
    else:
        draw.ellipse([cx - 7, cy - 5, cx + 7, cy + 5], fill=PAL["stone_black"], outline=PAL["stone_dark"])
        draw.ellipse([cx - 4, cy - 3, cx + 4, cy + 3], fill=PAL["stone_dark"], outline=PAL["silver"])


def draw_civil_protection_sign(draw, cx, cy):
    """Punto de Reunión Oficial de Protección Civil en suelo."""
    draw.ellipse([cx - 16, cy - 12, cx + 16, cy + 12], fill=PAL["gate_green"], outline=PAL["white"], width=2)
    draw.ellipse([cx - 12, cy - 9, cx + 12, cy + 9], fill=PAL["green_bldg"], outline=PAL["white"])
    # 4 flechas convergentes
    for ang in [0, 90, 180, 270]:
        rad = math.radians(ang)
        fx = cx + int(math.cos(rad) * 6)
        fy = cy + int(math.sin(rad) * 4)
        draw.point((fx, fy), fill=PAL["white"])


def draw_warp_pad(draw, cx, cy, label_color=PAL["curb_yellow"]):
    """Plataforma de meta / avance escolar con destellos y brillo."""
    draw.ellipse([cx - 20, cy - 8, cx + 24, cy + 16], fill=(15, 8, 12, 140))
    draw.ellipse([cx - 18, cy - 12, cx + 18, cy + 12], fill=PAL["guinda"], outline=PAL["outline"])
    draw.ellipse([cx - 14, cy - 9, cx + 14, cy + 9], fill=label_color, outline=PAL["outline"])
    draw.ellipse([cx - 8, cy - 5, cx + 8, cy + 5], fill=PAL["white"])
    # Destellos de virtud
    draw.point((cx - 10, cy - 7), fill=PAL["white"])
    draw.point((cx + 10, cy + 7), fill=PAL["white"])


def draw_zebra_ramp(draw, x1, y1, x2, y2, horizontal=True):
    """Rampa azul y blanca con guarniciones amarillas 3D."""
    # Sombra
    draw.rectangle([x1 + 2, y1 + 3, x2 + 3, y2 + 4], fill=(16, 20, 26, 110))
    draw.rectangle([x1 - 3, y1 - 3, x2 + 3, y2 + 3], fill=PAL["curb_yellow"], outline=PAL["outline"])
    draw.line([(x1 - 2, y1 - 2), (x2 + 2, y1 - 2)], fill=PAL["curb_yellow_light"])
    if horizontal:
        stripe_w = 6
        for i, x in enumerate(range(x1, x2, stripe_w)):
            c = PAL["zebra_blue"] if i % 2 == 0 else PAL["zebra_white"]
            draw.rectangle([x, y1, min(x + stripe_w - 1, x2), y2], fill=c)
            if c == PAL["zebra_blue"]:
                draw.line([(x, y1), (min(x + stripe_w - 1, x2), y1)], fill=PAL["zebra_blue_light"])
    else:
        stripe_h = 6
        for i, y in enumerate(range(y1, y2, stripe_h)):
            c = PAL["zebra_blue"] if i % 2 == 0 else PAL["zebra_white"]
            draw.rectangle([x1, y, x2, min(y + stripe_h - 1, y2)], fill=c)
            if c == PAL["zebra_blue"]:
                draw.line([(x1, y), (x2, y)], fill=PAL["zebra_blue_light"])
    draw.rectangle([x1, y1, x2, y2], outline=PAL["outline"])


def draw_classroom_furniture(draw, rx1, ry1, rx2, ry2, board_top=True):
    """Pupitres y escritorio con sombras de contacto individuales."""
    mid_x = (rx1 + rx2) // 2
    if board_top:
        bw = min(60, (rx2 - rx1) - 20)
        # Sombra del pizarrón
        draw.rectangle([mid_x - bw // 2 + 1, ry1 + 10, mid_x + bw // 2 + 1, ry1 + 12], fill=(12, 10, 16, 120))
        draw.rectangle([mid_x - bw // 2, ry1 + 3, mid_x + bw // 2, ry1 + 10], fill=PAL["white"], outline=PAL["outline"])
        draw.line([(mid_x - bw // 2 + 2, ry1 + 9), (mid_x + bw // 2 - 2, ry1 + 9)], fill=PAL["silver"])
        # Escritorio del profesor
        draw.rectangle([rx1 + 11, ry1 + 16, rx1 + 31, ry1 + 27], fill=(15, 12, 18, 120))
        draw.rectangle([rx1 + 10, ry1 + 14, rx1 + 30, ry1 + 25], fill=PAL["wood_mahogany"], outline=PAL["outline"])
        draw.rectangle([rx1 + 13, ry1 + 16, rx1 + 20, ry1 + 22], fill=PAL["white"]) # Examen/papel

    for py in range(ry1 + 32, ry2 - 14, 20):
        for px in range(rx1 + 14, rx2 - 18, 22):
            # Sombra del pupitre
            draw.rectangle([px + 1, py + 8, px + 15, py + 14], fill=(15, 12, 18, 110))
            draw.rectangle([px + 3, py + 7, px + 11, py + 12], fill=PAL["green_bldg_dark"], outline=PAL["outline"])
            draw.rectangle([px, py, px + 14, py + 8], fill=PAL["wood_desk"], outline=PAL["outline"])
            draw.line([(px + 1, py + 1), (px + 13, py + 1)], fill=(200, 140, 80)) # Bisel
            draw.rectangle([px + 2, py + 2, px + 7, py + 6], fill=PAL["white"]) # Cuaderno


def draw_green_trash_drum(draw, cx, cy):
    """Contenedor de basura verde con sombra arrojada."""
    draw.ellipse([cx - 5 + 3, cy + 3 + 4, cx + 7 + 3, cy + 9 + 4], fill=(18, 22, 28, 150))
    draw.rectangle([cx - 5, cy - 8, cx + 5, cy + 6], fill=PAL["gate_green"], outline=PAL["outline"])
    draw.line([(cx - 4, cy - 7), (cx - 4, cy + 5)], fill=PAL["hedge_light"])
    draw.line([(cx - 5, cy - 3), (cx + 5, cy - 3)], fill=PAL["hedge_light"])
    draw.line([(cx - 5, cy + 2), (cx + 5, cy + 2)], fill=PAL["hedge_light"])
    draw.ellipse([cx - 5, cy - 10, cx + 5, cy - 6], fill=(40, 44, 50), outline=PAL["outline"])


# ==============================================================================
# ESCENARIOS EXTERIORES A ESCALA REAL REFINADOS CON SOMBRAS Y DETALLES
# ==============================================================================

def generate_scenario_1():
    img, draw, tw, th = new_canvas(36.0, 22.0)
    fill_grass_texture(draw, 0, 0, tw - 1, th - 1)

    # 1. Muro de contención al fondo norponiente
    draw_stone_retaining_wall(draw, 0, 0, 300, 42)
    draw_white_railing(draw, 4, 14, 296, height=10)

    # 2. Pasillo de salida hacia el Edificio A
    fill_concrete_slabs(draw, 20, 144, 140, 260, slab_t=32)
    draw_manhole_cover(draw, 80, 200, is_square=False)

    # 3. Muro Institucional COBAEM Guinda/Púrpura + Osito Topiario
    mx1, my1, mx2, my2 = 16, 42, 276, 108
    draw_cast_shadow_box(draw, mx1, my1, mx2, my2, depth=14, dx=8)
    draw.rectangle([mx1, my1, mx2, my2], fill=PAL["cobaem_purple"], outline=PAL["outline"])
    draw.rectangle([mx1, my1, mx2, my1 + 8], fill=PAL["roof_red"], outline=PAL["outline"])
    draw.rectangle([mx1, my1 + 8, mx2, my1 + 13], fill=PAL["white"])
    draw_pixel_sign(draw, (mx1 + mx2) // 2 + 12, my1 + 24, "COBAEM CEMSAD 22 ENTHAVI", bg=PAL["white"], fg=PAL["cobaem_purple"])
    # Colibrí dorado EDOMEX
    draw.polygon([(mx1 + 14, my1 + 22), (mx1 + 30, my1 + 30), (mx1 + 22, my1 + 46)], fill=PAL["curb_yellow"], outline=PAL["outline"])
    draw.rectangle([mx1, my2 - 6, mx2, my2 - 2], fill=PAL["white"])
    draw.rectangle([mx1, my2 - 2, mx2, my2 + 2], fill=PAL["curb_yellow"], outline=PAL["outline"])

    # Jardinera y Osito Topiario
    draw.rectangle([144, my2 + 2, mx2 - 4, my2 + 40], fill=PAL["hedge_dark"], outline=PAL["outline"])
    for hx in range(148, mx2 - 8, 8):
        draw.point((hx, my2 + 6), fill=PAL["hedge_flower"])
    draw_spiral_topiary(draw, 210, my2 + 20)

    # 4. Patio de Maniobras y Estacionamiento (22.00m x 12.00m = 440 x 240 texeles)
    px1, py1, px2, py2 = 120, 180, 560, 420
    draw_cast_shadow_box(draw, px1, py1, px2, py2, depth=10, dx=6)
    fill_concrete_slabs(draw, px1, py1, px2, py2, slab_t=40)
    draw_curb_3d(draw, px1, py1, px2, py1 + 4, horizontal=True)
    draw_curb_3d(draw, px1, py2 - 4, px2, py2, horizontal=True)
    draw_curb_3d(draw, px2 - 4, py1, px2, py2, horizontal=False)

    # Cajones de estacionamiento con manchas de aceite y autos 3D
    for cx in range(px1 + 80, px1 + 335, 50):
        draw.rectangle([cx, py1 + 5, cx + 2, py1 + 92], fill=PAL["curb_yellow"])
        draw.ellipse([cx + 20, py1 + 40, cx + 32, py1 + 54], fill=(140, 144, 150)) # Mancha de uso

    draw_car_3d(draw, px1 + 205, py1 + 52, PAL["roof_red"])
    draw_car_3d(draw, px1 + 255, py1 + 52, PAL["white"])
    draw_car_3d(draw, px1 + 305, py1 + 52, PAL["concrete_light"])
    draw_solar_streetlamp(draw, px1 + 100, py1 + 10)
    draw_solar_streetlamp(draw, px2 - 20, py1 + 10)
    draw_manhole_cover(draw, px1 + 150, py2 - 30, is_square=True)

    # 5. Plaza de Acceso Principal y Caseta C.V.
    ax1, ay1, ax2, ay2 = 20, 260, 300, 425
    fill_concrete_slabs(draw, ax1, ay1, ax2, ay2, slab_t=36)
    draw_zebra_ramp(draw, ax1 + 60, ay2 - 36, ax2 - 20, ay2 - 14, horizontal=True)
    draw_civil_protection_sign(draw, ax1 + 160, ay1 + 70)

    # Caseta C.V. con sombras volumétricas
    cv_x1, cv_y1, cv_x2, cv_y2 = 22, 268, 82, 326
    draw_cast_shadow_box(draw, cv_x1, cv_y1, cv_x2, cv_y2, depth=14, dx=8)
    draw.rectangle([cv_x1, cv_y1, cv_x2, cv_y2], fill=PAL["terracota"], outline=PAL["outline"])
    draw.rectangle([cv_x1, cv_y1, cv_x2, cv_y1 + 5], fill=PAL["guinda"])
    draw.rectangle([cv_x1, cv_y2 - 6, cv_x2, cv_y2], fill=PAL["guinda"])
    draw.polygon([(cv_x1 - 6, cv_y1), (cv_x2 + 6, cv_y1), (cv_x2, cv_y1 - 12), (cv_x1, cv_y1 - 12)], fill=PAL["roof_red"], outline=PAL["outline"])
    draw_window_grille(draw, cv_x1 + 4, cv_y1 + 10, cv_x1 + 20, cv_y1 + 34)
    draw_window_grille(draw, cv_x2 - 20, cv_y1 + 10, cv_x2 - 4, cv_y1 + 34)
    draw_pixel_sign(draw, (cv_x1 + cv_x2) // 2, cv_y1 - 6, "CASETA C.V.", bg=PAL["guinda"], fg=PAL["white"])

    # Portón Triple Abatible verde
    gx1, gy1, gx2, gy2 = 24, 412, 260, 434
    draw.rectangle([gx1, gy1, gx2, gy2], fill=PAL["gate_green"], outline=PAL["outline"])
    for bx in range(gx1 + 4, gx2 - 2, 5):
        draw.line([(bx, gy1 + 2), (bx, gy2 - 2)], fill=PAL["hedge_light"])
    for px in [gx1, gx1 + 78, gx1 + 156, gx2 - 8]:
        draw.rectangle([px, gy1 - 4, px + 8, gy2 + 2], fill=PAL["guinda"], outline=PAL["outline"])

    # 6. EDIFICIO "D" • LABORATORIO (19.00m x 9.64m)
    dx1, dy1 = 310, 18
    dw, dh = m_to_t(19.0), m_to_t(9.64)
    dx2, dy2 = dx1 + dw, dy1 + dh

    # Sombra del edificio D proyectada sobre el andador
    draw_cast_shadow_box(draw, dx1, dy1, dx2, dy2 + 26, depth=18, dx=10)
    fill_concrete_slabs(draw, dx1 - 8, dy1, dx2 + 8, dy2 + 18, slab_t=24)
    draw_curb_3d(draw, dx1 - 8, dy2 + 14, dx2 + 8, dy2 + 18, horizontal=True)

    # 6a. Laboratorio de Usos Múltiples interior
    lab_x1, lab_y1 = dx1 + 4, dy1 + 6
    lab_x2, lab_y2 = lab_x1 + m_to_t(12.80), lab_y1 + m_to_t(7.20)
    fill_ceramic_tiles(draw, lab_x1, lab_y1, lab_x2, lab_y2, tile_t=8)

    for row_y in [lab_y1 + 28, lab_y1 + 78]:
        for col_x in [lab_x1 + 28, lab_x1 + 106, lab_x1 + 184]:
            draw.rectangle([col_x + 3, row_y + 4, col_x + 39, row_y + 24], fill=(14, 18, 24, 120)) # Sombra mesa lab
            draw.rectangle([col_x, row_y, col_x + 36, row_y + 20], fill=PAL["lab_blue"], outline=PAL["outline"])
            draw.rectangle([col_x + 14, row_y + 5, col_x + 22, row_y + 15], fill=PAL["silver"], outline=PAL["outline"])
            draw.rectangle([col_x + 5, row_y + 6, col_x + 10, row_y + 12], fill=PAL["white"])
            draw.rectangle([col_x + 26, row_y + 6, col_x + 31, row_y + 12], fill=PAL["curb_yellow"])

    # Fachada frontal 3/4 del Edificio D con alero y cancelería
    fy1, fy2 = lab_y2, lab_y2 + 26
    draw_roof_overhang_shadow(draw, dx1, fy1, dx2, height=5)
    draw.rectangle([dx1, fy1, dx2, fy1 + 6], fill=PAL["guinda"], outline=PAL["outline"])
    draw_window_grille(draw, dx1 + 8, fy1 + 6, dx1 + 78, fy1 + 15)
    draw_brick_wall_patch(draw, dx1 + 8, fy1 + 15, dx1 + 78, fy2)
    draw_door_3d(draw, dx1 + 238, fy2, w=20, h=20, color=PAL["white"])
    draw_window_grille(draw, dx1 + 264, fy1 + 6, dx2 - 8, fy1 + 15)
    draw_brick_wall_patch(draw, dx1 + 264, fy1 + 15, dx2 - 8, fy2)
    draw_green_trash_drum(draw, dx1 + 92, fy2 + 4)
    draw_solar_streetlamp(draw, dx1 - 4, dy2 + 10)

    # 7. Captador de Agua Pluvial
    cap_x1, cap_y1 = 580, 260
    cap_x2, cap_y2 = cap_x1 + m_to_t(5.0), cap_y1 + m_to_t(5.0)
    draw_cast_shadow_box(draw, cap_x1, cap_y1, cap_x2, cap_y2, depth=8, dx=6)
    draw.rectangle([cap_x1, cap_y1, cap_x2, cap_y2], fill=PAL["lab_blue"], outline=PAL["outline"])
    draw.rectangle([cap_x1 + 6, cap_y1 + 6, cap_x2 - 6, cap_y2 - 6], fill=PAL["window_glass"], outline=PAL["outline"])

    draw_warp_pad(draw, 60, 165)
    draw_pine_tree(draw, 640, 390, radius=20)
    draw_pine_tree(draw, 590, 400, radius=18)

    save_pixel_art(img, "nivel_1_acceso_laboratorio.png")


def generate_scenario_2():
    img, draw, tw, th = new_canvas(40.0, 20.0)
    fill_grass_texture(draw, 0, 0, tw - 1, th - 1)

    # Andador superior
    fill_concrete_slabs(draw, 40, 0, tw - 40, 52, slab_t=40)
    draw.line([(40, 36), (tw - 40, 36)], fill=PAL["zebra_blue"], width=2)

    # Jardinera central con flores y sombras
    draw_cast_shadow_box(draw, 40, 56, tw - 40, 106, depth=8, dx=6)
    draw.rectangle([40, 56, tw - 40, 106], fill=PAL["hedge_dark"], outline=PAL["outline"])
    draw.rectangle([44, 60, tw - 44, 102], fill=PAL["hedge_mid"])
    for tx in range(90, tw - 80, 75):
        draw_spiral_topiary(draw, tx, 82)
    draw_curb_3d(draw, 40, 106, tw - 40, 110, horizontal=True)

    # Andador principal
    fill_concrete_slabs(draw, 25, 110, tw - 25, 184, slab_t=32)
    draw_manhole_cover(draw, 200, 140, is_square=False)
    draw_manhole_cover(draw, 500, 140, is_square=True)
    draw_solar_streetlamp(draw, 140, 116)
    draw_solar_streetlamp(draw, 600, 116)

    # EDIFICIO "A" ENVOLVENTE GENERAL (35.00m x 9.69m)
    ax1, ay1 = 50, 184
    aw, ah = m_to_t(35.00), m_to_t(9.69)
    ax2, ay2 = ax1 + aw, ay1 + ah

    draw_cast_shadow_box(draw, ax1, ay1, ax2, ay2, depth=18, dx=10)
    draw.rectangle([ax1, ay1, ax2, ay2], fill=PAL["guinda_dark"], outline=PAL["outline"])
    room_y1, room_y2 = ay1 + 24, ay1 + 24 + m_to_t(7.00)

    # Cafetería, Almacén y Aulas 1-2
    caf_x1, caf_x2 = ax1 + 8, ax1 + 8 + m_to_t(6.20)
    fill_concrete_slabs(draw, caf_x1, ay1, caf_x2, room_y2, slab_t=20)

    alm_x1, alm_x2 = caf_x2 + 8, caf_x2 + 8 + m_to_t(3.80)
    fill_ceramic_tiles(draw, alm_x1, room_y1, alm_x2, room_y2, tile_t=8)

    a1_x1, a1_x2 = alm_x2 + 8, alm_x2 + 8 + m_to_t(8.00)
    fill_ceramic_tiles(draw, a1_x1, room_y1, a1_x2, room_y2, tile_t=8)
    draw_classroom_furniture(draw, a1_x1, room_y1, a1_x2, room_y2, board_top=False)

    a2_x1, a2_x2 = a1_x2 + 8, a1_x2 + 8 + m_to_t(8.00)
    fill_ceramic_tiles(draw, a2_x1, room_y1, a2_x2, room_y2, tile_t=8)
    draw_classroom_furniture(draw, a2_x1, room_y1, a2_x2, room_y2, board_top=False)

    san_x1, san_x2 = a2_x2 + 8, ax2 - 8
    fill_ceramic_tiles(draw, san_x1, room_y1, san_x2, room_y2, tile_t=6)

    # Fachada Norte con alero y puertas 3D
    fy1, fy2 = ay1, room_y1
    draw_roof_overhang_shadow(draw, alm_x1 - 4, fy1, ax2, height=6)
    draw.rectangle([alm_x1 - 4, fy1, ax2, fy2], fill=PAL["ochre_wall"], outline=PAL["outline"])
    draw.rectangle([ax1, fy1, ax2, fy1 + 6], fill=PAL["guinda"], outline=PAL["outline"])

    for rx1, rx2 in [(alm_x1, alm_x2), (a1_x1, a1_x2), (a2_x1, a2_x2), (san_x1, san_x2)]:
        draw_door_3d(draw, rx1 + 8, fy2, w=18, h=18, color=PAL["white"])
        if rx2 - rx1 > 90:
            draw_window_grille(draw, rx1 + 34, fy1 + 6, rx2 - 12, fy1 + 15)

    draw_warp_pad(draw, 70, 130)
    save_pixel_art(img, "nivel_2_edificio_a_cafeteria.png")


def generate_scenario_3():
    img, draw, tw, th = new_canvas(40.0, 22.5)
    fill_grass_texture(draw, 0, 0, tw - 1, th - 1)

    sx1, sx2 = 18, 108
    sy1, sy2 = 36, 416
    draw.rectangle([4, 10, sx1, th - 10], fill=PAL["terracota"], outline=PAL["outline"])

    # Escalinata Sur Monumental con huellas y contrahuellas sombreadas
    for y in range(sy1, sy2, 8):
        draw.line([(sx1, y), (sx2, y)], fill=(12, 10, 16, 120), width=1)
        if 150 <= y <= 174 or 280 <= y <= 304:
            c = PAL["zebra_blue"] if ((y // 8) % 2 == 0) else PAL["zebra_white"]
            draw.rectangle([sx1, y, sx2, y + 7], fill=c, outline=PAL["outline"])
        else:
            draw.rectangle([sx1, y, sx2, y + 5], fill=PAL["curb_yellow"], outline=PAL["outline"])
            draw.rectangle([sx1, y + 5, sx2, y + 8], fill=PAL["curb_yellow_dark"], outline=PAL["outline"])
            draw.line([(sx1, y + 1), (sx2, y + 1)], fill=PAL["curb_yellow_light"])

    draw.rectangle([sx2, sy1, sx2 + 10, sy2 - 36], fill=PAL["alfarda_rose"], outline=PAL["outline"])
    draw.rectangle([sx2 + 2, sy1, sx2 + 8, sy2 - 38], fill=PAL["guinda_light"])

    # PLAZA CÍVICA TECHADA CON ARCOTECHO (34.00m x 22.00m)
    px1, py1 = 112, 10
    pw, ph = m_to_t(34.00), m_to_t(22.00)
    px2, py2 = px1 + pw, min(th - 6, py1 + ph)

    # Sombra general suave arrojada por la monumental techumbre curva (Arcotecho)
    draw.rectangle([px1 + 20, py1 + 85, px2 - 20, py2 - 10], fill=(18, 22, 32, 55))
    fill_concrete_slabs(draw, px1, py1 + 78, px2, py2, slab_t=40)

    court_x1, court_y1, court_x2, court_y2 = px1 + 50, py1 + 110, px2 - 50, py2 - 30
    draw.rectangle([court_x1, court_y1, court_x2, court_y2], outline=PAL["zebra_blue"], width=2)
    mid_cx = (court_x1 + court_x2) // 2
    mid_cy = (court_y1 + court_y2) // 2
    draw.line([(mid_cx, court_y1), (mid_cx, court_y2)], fill=PAL["zebra_blue"], width=2)
    draw.ellipse([mid_cx - 36, mid_cy - 36, mid_cx + 36, mid_cy + 36], outline=PAL["curb_yellow"], width=2)

    # Punto de Reunión de Protección Civil en el centro de la plaza
    draw_civil_protection_sign(draw, mid_cx, mid_cy)

    # Muro de contención de piedra braza
    wall_y1, wall_y2 = py1 + 12, py1 + 88
    draw_stone_retaining_wall(draw, px1, wall_y1, px2, wall_y2)
    draw_white_railing(draw, px1, wall_y1, px2, height=11)

    # Estructura del Arcotecho: Arcos transversales con reflejo metálico
    for rx in range(px1 + 30, px2 - 20, 48):
        draw.line([(rx, py1 + 6), (rx + 10, py1 + 74)], fill=PAL["silver_light"], width=2)
        draw.line([(rx + 1, py1 + 8), (rx + 11, py1 + 76)], fill=(12, 15, 20, 100), width=1)

    # Columnas cilíndricas con sombra
    col_xs = [px1 + 20, px1 + 140, px1 + 260, px1 + 380, px1 + 500, px1 + 620]
    for cx in col_xs:
        # Sombra de columna
        draw.ellipse([cx - 4, wall_y2 + 4, cx + 8, wall_y2 + 9], fill=(15, 18, 25, 140))
        draw.rectangle([cx - 5, wall_y1 + 4, cx + 5, wall_y2 + 4], fill=PAL["white"], outline=PAL["outline"])
        draw.rectangle([cx - 5, wall_y2 - 14, cx + 5, wall_y2 + 4], fill=PAL["guinda"], outline=PAL["outline"])
        sy = py2 - 16
        draw.ellipse([cx - 4, sy + 4, cx + 8, sy + 9], fill=(15, 18, 25, 140))
        draw.rectangle([cx - 5, sy - 18, cx + 5, sy + 4], fill=PAL["white"], outline=PAL["outline"])
        draw.rectangle([cx - 5, sy - 6, cx + 5, sy + 4], fill=PAL["guinda"], outline=PAL["outline"])

    draw_warp_pad(draw, (sx1 + sx2) // 2, sy1 + 16)
    save_pixel_art(img, "nivel_3_plaza_civica_escalinata.png")


def generate_scenario_4():
    img, draw, tw, th = new_canvas(36.0, 20.0)
    fill_grass_texture(draw, 0, 0, tw - 1, th - 1)

    bx1, by1 = 40, 14
    bw, bh = m_to_t(32.00), m_to_t(9.78)
    bx2, by2 = bx1 + bw, by1 + bh

    draw_cast_shadow_box(draw, bx1, by1, bx2, by2, depth=18, dx=10)
    draw.rectangle([bx1, by1, bx2, by2], fill=PAL["green_bldg_dark"], outline=PAL["outline"])
    room_y1, room_y2 = by1 + 8, by1 + 8 + m_to_t(7.20)

    # Aulas 3-4, Biblioteca y Sala de Maestros
    a3_x1, a3_x2 = bx1 + 8, bx1 + 8 + m_to_t(8.00)
    fill_ceramic_tiles(draw, a3_x1, room_y1, a3_x2, room_y2, tile_t=8)
    draw_classroom_furniture(draw, a3_x1, room_y1, a3_x2, room_y2, board_top=True)

    a4_x1, a4_x2 = a3_x2 + 8, a3_x2 + 8 + m_to_t(8.00)
    fill_ceramic_tiles(draw, a4_x1, room_y1, a4_x2, room_y2, tile_t=8)
    draw_classroom_furniture(draw, a4_x1, room_y1, a4_x2, room_y2, board_top=True)

    bib_x1, bib_x2 = a4_x2 + 8, a4_x2 + 8 + m_to_t(5.20)
    fill_ceramic_tiles(draw, bib_x1, room_y1, bib_x2, room_y2, tile_t=8)

    mae_x1, mae_x2 = bib_x2 + 8, bx2 - 8
    fill_ceramic_tiles(draw, mae_x1, room_y1, mae_x2, room_y2, tile_t=8)

    # Fachada Sur con alero y cancelería
    fy1, fy2 = room_y2, by2
    draw_roof_overhang_shadow(draw, bx1, fy1, bx2, height=6)
    draw.rectangle([bx1, fy1, bx2, fy2], fill=PAL["green_bldg"], outline=PAL["outline"])
    for rx1, rx2 in [(a3_x1, a3_x2), (a4_x1, a4_x2), (bib_x1, bib_x2), (mae_x1, mae_x2)]:
        draw_door_3d(draw, rx1 + 6, fy2, w=18, h=28, color=PAL["white"])
        wx1, wx2 = rx1 + 28, rx2 - 6
        draw_window_grille(draw, wx1, fy1 + 6, wx2, fy1 + 22)
        draw_brick_wall_patch(draw, wx1, fy1 + 22, wx2, fy2)

    # Andador con guarnición 3D y rampa
    walk_y1, walk_y2 = by2, by2 + 78
    fill_concrete_slabs(draw, 16, walk_y1, tw - 16, walk_y2, slab_t=32)
    draw_curb_3d(draw, 16, walk_y2 - 4, tw - 16, walk_y2, horizontal=True)
    draw_zebra_ramp(draw, bx2 - 90, walk_y2 - 26, bx2 - 10, walk_y2 - 4, horizontal=True)
    draw_solar_streetlamp(draw, 100, walk_y1 + 10)
    draw_solar_streetlamp(draw, bx2 - 120, walk_y1 + 10)

    # Jardín Mirador y Pinos
    gar_y1 = walk_y2 + 2
    for px in range(80, tw - 60, 95):
        draw_pine_tree(draw, px, gar_y1 + 32, radius=18)

    draw_stone_retaining_wall(draw, 0, th - 46, tw - 1, th - 1)
    draw_white_railing(draw, 8, th - 46, tw - 8, height=12)
    draw_warp_pad(draw, tw - 45, (walk_y1 + walk_y2) // 2)

    save_pixel_art(img, "nivel_4_edificio_b.png")


def generate_scenario_5():
    img, draw, tw, th = new_canvas(36.0, 22.0)
    fill_grass_texture(draw, 0, 0, tw - 1, th - 1)

    cx1 = 24
    cx2 = cx1 + 584

    # PLANTA ALTA (Taller de Cómputo y Aula 6)
    pa_y1, pa_y2 = 10, 126
    draw_cast_shadow_box(draw, cx1, pa_y1, cx2, pa_y2, depth=14, dx=8)
    draw.rectangle([cx1, pa_y1, cx2, pa_y2], fill=PAL["mustard_dark"], outline=PAL["outline"])

    comp_x1, comp_x2 = cx1 + 6, cx1 + 6 + m_to_t(16.00)
    fill_ceramic_tiles(draw, comp_x1, pa_y1 + 6, comp_x2, pa_y2 - 14, tile_t=8)
    for row_y in [pa_y1 + 22, pa_y1 + 52, pa_y1 + 80]:
        for desk_x in range(comp_x1 + 16, comp_x2 - 28, 36):
            draw.rectangle([desk_x, row_y, desk_x + 28, row_y + 12], fill=PAL["wood_mahogany"], outline=PAL["outline"])
            draw.rectangle([desk_x + 3, row_y + 2, desk_x + 11, row_y + 7], fill=PAL["window_glass"], outline=PAL["outline"])
            draw.rectangle([desk_x + 17, row_y + 2, desk_x + 25, row_y + 7], fill=PAL["window_glass"], outline=PAL["outline"])

    # PLANTA BAJA (Dirección, Enfermería, Tutorías, Aula 5)
    pb_y1, pb_y2 = 132, 256
    draw_cast_shadow_box(draw, cx1, pb_y1, cx2, pb_y2, depth=16, dx=10)
    draw.rectangle([cx1, pb_y1, cx2, pb_y2], fill=PAL["green_bldg_dark"], outline=PAL["outline"])

    adm_x1, adm_x2 = cx1 + 6, comp_x2
    fill_ceramic_tiles(draw, adm_x1, pb_y1 + 6, adm_x2, pb_y2 - 24, tile_t=8)

    fy1, fy2 = pb_y2 - 24, pb_y2
    draw_roof_overhang_shadow(draw, cx1, fy1, cx2, height=5)
    for dx in [adm_x1 + 4, adm_x1 + 80, adm_x1 + 160, cx2 - 120]:
        draw_door_3d(draw, dx, fy2, w=18, h=22, color=PAL["white"])

    # Andador principal
    walk_y1, walk_y2 = pb_y2, pb_y2 + 68
    fill_concrete_slabs(draw, 16, walk_y1, tw - 16, walk_y2, slab_t=32)
    draw_curb_3d(draw, 16, walk_y2 - 4, tw - 140, walk_y2, horizontal=True)
    draw_zebra_ramp(draw, tw - 150, walk_y1 + 12, tw - 18, walk_y2 + 24, horizontal=True)
    draw_solar_streetlamp(draw, 80, walk_y1 + 8)
    draw_solar_streetlamp(draw, 420, walk_y1 + 8)

    # Jardín del Asta Bandera con sombra monumental
    asta_cx, asta_cy = 240, walk_y2 + 64
    # Sombra del mástil en el pasto a 45°
    draw.line([(asta_cx, asta_cy - 12), (asta_cx + 42, asta_cy + 18)], fill=(16, 28, 20, 140), width=3)
    draw.rectangle([asta_cx - 18, asta_cy - 6, asta_cx + 18, asta_cy + 12], fill=PAL["white"], outline=PAL["outline"])
    draw.rectangle([asta_cx - 13, asta_cy - 11, asta_cx + 13, asta_cy + 7], fill=PAL["silver"], outline=PAL["outline"])
    draw.rectangle([asta_cx - 2, walk_y2 + 6, asta_cx + 2, asta_cy - 12], fill=PAL["white"], outline=PAL["outline"])

    draw_pine_tree(draw, asta_cx + 56, asta_cy - 10, radius=24)
    draw_pine_tree(draw, 110, asta_cy - 8, radius=18)
    draw_pine_tree(draw, 440, asta_cy - 8, radius=18)
    draw_stone_retaining_wall(draw, 0, th - 32, tw - 1, th - 1)
    draw_white_railing(draw, 8, th - 32, tw - 8, height=10)

    draw_warp_pad(draw, tw - 42, walk_y1 + 38)
    save_pixel_art(img, "nivel_5_edificio_c_computo.png")


def generate_scenario_6():
    img, draw, tw, th = new_canvas(36.0, 22.5)
    fill_grass_texture(draw, 0, 0, tw - 1, th - 1)

    draw_zebra_ramp(draw, 8, 150, 68, 210, horizontal=True)

    cx1, cy1 = 68, 24
    cw, ch = m_to_t(30.00), m_to_t(16.00)
    cx2, cy2 = cx1 + cw, cy1 + ch

    # Murete perimetral y sombra de la cancha
    draw_cast_shadow_box(draw, cx1, cy1, cx2, cy2, depth=14, dx=8)
    draw.rectangle([cx1 - 6, cy1 - 14, cx2 + 6, cy1 + 4], fill=PAL["green_mint_wall"], outline=PAL["outline"])
    draw.rectangle([cx1 - 6, cy1 - 14, cx2 + 6, cy1 - 10], fill=PAL["green_mint_dark"])

    fill_concrete_slabs(draw, cx1, cy1, cx2, cy2, slab_t=40)

    in_x1, in_y1, in_x2, in_y2 = cx1 + 24, cy1 + 20, cx2 - 24, cy2 - 20
    draw.rectangle([in_x1, in_y1, in_x2, in_y2], outline=PAL["zebra_blue"], width=2)
    draw.rectangle([in_x1 + 2, in_y1 + 2, in_x2 - 2, in_y2 - 2], outline=PAL["white"], width=1)

    mid_x = (in_x1 + in_x2) // 2
    mid_y = (in_y1 + in_y2) // 2
    draw.line([(mid_x, in_y1), (mid_x, in_y2)], fill=PAL["zebra_blue"], width=2)
    draw.ellipse([mid_x - 42, mid_y - 42, mid_x + 42, mid_y + 42], outline=PAL["zebra_blue"], width=2)
    draw.ellipse([mid_x - 32, mid_y - 32, mid_x + 32, mid_y + 32], fill=PAL["cobaem_purple"], outline=PAL["curb_yellow"])
    draw.ellipse([mid_x - 20, mid_y - 20, mid_x + 20, mid_y + 20], fill=PAL["curb_yellow"], outline=PAL["outline"])

    # Tableros de Básquetbol con sombra
    for side, bx in [(-1, in_x1 + 8), (1, in_x2 - 8)]:
        # Sombra del poste
        draw.line([(bx, mid_y + 24), (bx + 12, mid_y + 32)], fill=(16, 20, 26, 120), width=3)
        draw.rectangle([bx - 4, mid_y - 24, bx + 4, mid_y + 24], fill=PAL["gate_green"], outline=PAL["outline"])
        tb_x = bx + (-6 if side == 1 else 2)
        draw.rectangle([tb_x - 6, mid_y - 18, tb_x + 8, mid_y + 8], fill=PAL["green_bldg"], outline=PAL["outline"])
        draw.rectangle([tb_x - 3, mid_y - 11, tb_x + 5, mid_y - 1], fill=PAL["curb_yellow"], outline=PAL["outline"])
        draw.ellipse([tb_x - 2, mid_y - 3, tb_x + 4, mid_y + 3], fill=PAL["brick_red"], outline=PAL["outline"])

    # Podio Dorado de Victoria Final
    pod_x, pod_y = in_x2 - 55, mid_y
    draw_cast_shadow_box(draw, pod_x - 32, pod_y - 24, pod_x + 28, pod_y + 24, depth=10, dx=6)
    draw.rectangle([pod_x - 32, pod_y - 24, pod_x + 28, pod_y + 24], fill=PAL["guinda"], outline=PAL["curb_yellow"])
    draw.ellipse([pod_x - 18, pod_y - 14, pod_x + 18, pod_y + 14], fill=PAL["curb_yellow"], outline=PAL["outline"])
    draw.ellipse([pod_x - 12, pod_y - 9, pod_x + 12, pod_y + 9], fill=PAL["white"])

    # ZONA DE BANCAS Y CONVIVENCIA
    conv_y1, conv_y2 = cy2 + 12, th - 14
    draw_cast_shadow_box(draw, 90, conv_y1, 610, conv_y2, depth=8, dx=6)
    fill_concrete_slabs(draw, 90, conv_y1, 610, conv_y2, slab_t=36)
    draw_curb_3d(draw, 90, conv_y1, 610, conv_y1 + 4, horizontal=True)

    for mx in [160, 290]:
        # Sombras de bancas
        draw.rectangle([mx - 20, conv_y1 + 30, mx + 24, conv_y1 + 34], fill=(16, 20, 26, 110))
        draw.rectangle([mx - 22, conv_y1 + 22, mx + 22, conv_y1 + 30], fill=PAL["wood_desk"], outline=PAL["outline"])
        draw.rectangle([mx - 22, conv_y1 + 58, mx + 22, conv_y1 + 66], fill=PAL["wood_desk"], outline=PAL["outline"])
        draw.rectangle([mx - 24, conv_y1 + 34, mx + 24, conv_y1 + 54], fill=PAL["wood_mahogany"], outline=PAL["outline"])

    draw_pine_tree(draw, 50, conv_y1 + 40, radius=18)
    draw_pine_tree(draw, 645, conv_y1 + 40, radius=18)
    draw_solar_streetlamp(draw, 80, conv_y1 + 10)
    draw_solar_streetlamp(draw, 620, conv_y1 + 10)

    # Barda perimetral oriente con sombra
    draw_cast_shadow_box(draw, tw - 22, 8, tw - 8, th - 8, depth=10, dx=6)
    draw.rectangle([tw - 22, 8, tw - 8, th - 8], fill=PAL["terracota"], outline=PAL["outline"])
    for by in range(12, th - 12, 52):
        draw.rectangle([tw - 24, by, tw - 6, by + 7], fill=PAL["guinda"], outline=PAL["outline"])

    save_pixel_art(img, "nivel_6_cancha_usos_multiples.png")


if __name__ == "__main__":
    generate_scenario_1()
    generate_scenario_2()
    generate_scenario_3()
    generate_scenario_4()
    generate_scenario_5()
    generate_scenario_6()
    print("¡Los 6 escenarios a escala real (1m = 40px) de CEMSaD 22 ENTHAVI fueron generados con éxito!")
