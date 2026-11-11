#!/usr/bin/env python3
"""
Generador de escenarios Pixel Art en perspectiva 3/4 a ESCALA REAL
para el juego "Campeones de los Valores" — Plantel CEMSaD 22 ENTHAVI (COBAEM).

Escala Arquitectónica Real (basada en plano_3d.html y planos_interactivos.html):
  - 1 metro real (100 cm) = 40 píxeles en el juego (20 texeles de arte píxel 2x2).
  - 1 píxel = 2.5 cm reales.
  - 1 baldosa modular (40 x 40 px) = 1.00 m x 1.00 m = 10,000 cm² (1.00 m²).
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
    "grass_base": (68, 148, 62),
    "grass_dark": (52, 122, 48),
    "grass_light": (92, 174, 78),
    "hedge_dark": (36, 98, 42),
    "hedge_mid": (54, 134, 56),
    "hedge_light": (88, 178, 74),
    "trunk": (102, 66, 40),
    "trunk_dark": (72, 44, 26),
    "concrete": (204, 208, 212),
    "concrete_light": (222, 226, 230),
    "concrete_dark": (168, 174, 180),
    "concrete_shadow": (146, 152, 160),
    "concrete_joint": (142, 148, 156),
    "curb_yellow": (248, 204, 28),
    "curb_yellow_dark": (206, 158, 14),
    "zebra_blue": (28, 126, 214),
    "zebra_white": (244, 248, 252),
    "stone_black": (42, 46, 54),
    "stone_dark": (28, 31, 38),
    "stone_mortar": (228, 232, 238),
    "guinda": (118, 28, 72),
    "guinda_dark": (84, 18, 50),
    "guinda_light": (148, 42, 92),
    "cobaem_purple": (88, 26, 78),
    "terracota": (196, 128, 82),
    "terracota_dark": (162, 98, 56),
    "ochre_wall": (214, 154, 96),
    "brick_red": (198, 86, 58),
    "brick_dark": (158, 62, 40),
    "brick_mortar": (224, 214, 204),
    "green_bldg": (132, 198, 92),
    "green_bldg_dark": (96, 158, 62),
    "green_bldg_light": (164, 222, 128),
    "green_mint_wall": (168, 218, 162),
    "green_mint_dark": (128, 178, 124),
    "mustard": (186, 156, 64),
    "mustard_dark": (148, 120, 44),
    "tile_cream": (232, 222, 198),
    "tile_cream_alt": (218, 206, 180),
    "tile_grid": (192, 178, 152),
    "white": (246, 248, 250),
    "silver": (185, 194, 204),
    "window_glass": (96, 168, 218),
    "window_dark": (48, 92, 132),
    "wood_desk": (168, 108, 56),
    "wood_mahogany": (128, 52, 38),
    "lab_blue": (32, 118, 178),
    "roof_red": (168, 48, 48),
    "gate_green": (28, 118, 74),
    "alfarda_rose": (176, 48, 92),
}

# Fuente bitmap 3x5 minimalista para letreros arquitectónicos pixel art
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
    """Dibuja un cartel/placa arquitectónica legible en pixel art."""
    text = text.upper()
    tw = len(text) * 4 + 3
    th = 9
    x1 = cx - tw // 2
    y1 = cy - th // 2
    draw.rectangle([x1, y1, x1 + tw, y1 + th], fill=bg, outline=border)
    ox = x1 + 2
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


def new_canvas(width_m: float, height_m: float, bg_color=(68, 148, 62)):
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


def fill_grass_texture(draw, x1, y1, x2, y2):
    draw.rectangle([x1, y1, x2, y2], fill=PAL["grass_base"])
    for y in range(y1, y2, 6):
        for x in range(x1, x2, 6):
            if ((x // 6) + (y // 6)) % 2 == 0:
                draw.rectangle([x, y, min(x + 5, x2), min(y + 5, y2)], fill=PAL["grass_dark"])
            if ((x * 7 + y * 13) % 11) == 0 and x + 2 < x2 and y + 2 < y2:
                draw.point((x + 2, y + 1), fill=PAL["grass_light"])
                draw.point((x + 3, y + 2), fill=PAL["grass_light"])


def fill_concrete_slabs(draw, x1, y1, x2, y2, slab_t=40):
    draw.rectangle([x1, y1, x2, y2], fill=PAL["concrete"])
    for y in range(y1, y2, 4):
        for x in range(x1, x2, 4):
            if ((x * 3 + y * 5) % 7) == 0:
                draw.point((x, y), fill=PAL["concrete_light"])
            elif ((x * 5 + y * 3) % 9) == 0:
                draw.point((x, y), fill=PAL["concrete_dark"])
    for y in range(y1, y2 + 1, slab_t):
        draw.line([(x1, y), (x2, y)], fill=PAL["concrete_joint"], width=1)
    for x in range(x1, x2 + 1, slab_t):
        draw.line([(x, y1), (x, y2)], fill=PAL["concrete_joint"], width=1)
    draw.rectangle([x1, y1, x2, y2], outline=PAL["concrete_dark"])


def fill_ceramic_tiles(draw, x1, y1, x2, y2, tile_t=8):
    for y in range(y1, y2, tile_t):
        for x in range(x1, x2, tile_t):
            c = PAL["tile_cream"] if ((x // tile_t + y // tile_t) % 2 == 0) else PAL["tile_cream_alt"]
            draw.rectangle([x, y, min(x + tile_t - 1, x2), min(y + tile_t - 1, y2)], fill=c)
    for y in range(y1, y2 + 1, tile_t):
        draw.line([(x1, y), (x2, y)], fill=PAL["tile_grid"])
    for x in range(x1, x2 + 1, tile_t):
        draw.line([(x, y1), (x, y2)], fill=PAL["tile_grid"])
    # Sombra interior superior 3/4 de los muros del salón
    draw.rectangle([x1, y1, x2, min(y2, y1 + 4)], fill=PAL["tile_grid"])


def draw_brick_wall_patch(draw, x1, y1, x2, y2):
    draw.rectangle([x1, y1, x2, y2], fill=PAL["brick_red"])
    for y in range(y1, y2, 3):
        draw.line([(x1, y), (x2, y)], fill=PAL["brick_mortar"])
        offset = 3 if ((y - y1) // 3) % 2 == 1 else 0
        for x in range(x1 + offset, x2, 6):
            draw.line([(x, y), (x, min(y + 3, y2))], fill=PAL["brick_mortar"])
    draw.rectangle([x1, y1, x2, y2], outline=PAL["outline"])


def draw_stone_retaining_wall(draw, x1, y1, x2, y2):
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
            draw.line([(x, y), (nx, min(y2, max(y1, y + jitter)))], fill=PAL["stone_mortar"])
            draw.line([(x, y), (min(x2, max(x1, x + jitter)), ny)], fill=PAL["stone_mortar"])
    draw.rectangle([x1, y1, x2, y2], outline=PAL["outline"])


def draw_white_railing(draw, x1, y, x2, height=12):
    draw.rectangle([x1, y - height, x2, y - height + 2], fill=PAL["white"], outline=PAL["outline"])
    draw.rectangle([x1, y - 2, x2, y], fill=PAL["silver"])
    for x in range(x1, x2 + 1, 8):
        draw.line([(x, y - height), (x, y)], fill=PAL["white"])
    for x in range(x1, x2 + 1, 32):
        draw.rectangle([x - 1, y - height - 2, x + 1, y], fill=PAL["green_bldg_light"], outline=PAL["outline"])


def draw_zebra_ramp(draw, x1, y1, x2, y2, horizontal=True):
    draw.rectangle([x1 - 3, y1 - 3, x2 + 3, y2 + 3], fill=PAL["curb_yellow"], outline=PAL["outline"])
    if horizontal:
        stripe_w = 6
        for i, x in enumerate(range(x1, x2, stripe_w)):
            c = PAL["zebra_blue"] if i % 2 == 0 else PAL["zebra_white"]
            draw.rectangle([x, y1, min(x + stripe_w - 1, x2), y2], fill=c)
    else:
        stripe_h = 6
        for i, y in enumerate(range(y1, y2, stripe_h)):
            c = PAL["zebra_blue"] if i % 2 == 0 else PAL["zebra_white"]
            draw.rectangle([x1, y, x2, min(y + stripe_h - 1, y2)], fill=c)
    draw.rectangle([x1, y1, x2, y2], outline=PAL["outline"])


def draw_window_grille(draw, x1, y1, x2, y2):
    draw.rectangle([x1, y1, x2, y2], fill=PAL["window_dark"], outline=PAL["outline"])
    draw.rectangle([x1 + 2, y1 + 2, x2 - 2, y2 - 2], fill=PAL["window_glass"])
    for y in range(y1 + 4, y2 - 2, 4):
        draw.line([(x1 + 1, y), (x2 - 1, y)], fill=PAL["white"])
    for x in range(x1 + 6, x2 - 2, 6):
        draw.line([(x, y1 + 1), (x, y2 - 1)], fill=PAL["white"])
    draw.rectangle([x1, y1, x2, y2], outline=PAL["white"])


def draw_door_3d(draw, x, y, w=18, h=26, color=PAL["white"]):
    draw.rectangle([x, y - h, x + w, y], fill=color, outline=PAL["outline"])
    draw.rectangle([x + 3, y - h + 3, x + w - 3, y - h // 2], fill=PAL["window_glass"], outline=PAL["outline"])
    for gx in range(x + 4, x + w - 3, 4):
        draw.line([(gx, y - h // 2 + 2), (gx, y - 2)], fill=PAL["silver"])
    draw.rectangle([x + w - 4, y - h // 2 - 1, x + w - 2, y - h // 2 + 2], fill=PAL["curb_yellow"])


def draw_pine_tree(draw, cx, cy, radius=18):
    draw.ellipse([cx - radius, cy + 4, cx + radius + 4, cy + radius // 2 + 8], fill=(24, 48, 28))
    draw.rectangle([cx - 3, cy - 6, cx + 3, cy + 10], fill=PAL["trunk"], outline=PAL["outline"])
    draw.line([(cx - 2, cy - 5), (cx - 2, cy + 9)], fill=PAL["trunk_dark"])
    for dy, r in [(0, radius), (-8, int(radius * 0.82)), (-16, int(radius * 0.62)), (-22, int(radius * 0.42))]:
        draw.ellipse([cx - r, cy + dy - r // 2, cx + r, cy + dy + r // 2], fill=PAL["hedge_dark"], outline=PAL["outline"])
        draw.ellipse([cx - r + 2, cy + dy - r // 2 + 1, cx + r - 2, cy + dy + r // 2 - 2], fill=PAL["hedge_mid"])
        draw.ellipse([cx - r // 2, cy + dy - r // 2 + 2, cx + r // 3, cy + dy], fill=PAL["hedge_light"])


def draw_spiral_topiary(draw, cx, cy):
    draw.ellipse([cx - 8, cy + 2, cx + 8, cy + 8], fill=(24, 48, 28))
    draw.rectangle([cx - 2, cy - 2, cx + 2, cy + 5], fill=PAL["trunk"], outline=PAL["outline"])
    for dy, rx, ry in [(0, 9, 5), (-6, 8, 4), (-12, 6, 4), (-17, 4, 3)]:
        draw.ellipse([cx - rx, cy + dy - ry, cx + rx, cy + dy + ry], fill=PAL["hedge_mid"], outline=PAL["outline"])
        draw.ellipse([cx - rx + 2, cy + dy - ry + 1, cx + rx - 3, cy + dy], fill=PAL["hedge_light"])


def draw_bear_topiary(draw, cx, cy):
    for zx in range(cx - 26, cx + 26, 6):
        draw.polygon([(zx, cy + 16), (zx + 3, cy + 11), (zx + 6, cy + 16)], fill=PAL["white"], outline=PAL["outline"])
    draw.ellipse([cx - 20, cy - 2, cx + 20, cy + 15], fill=PAL["hedge_dark"], outline=PAL["outline"])
    draw.ellipse([cx - 18, cy, cx + 18, cy + 13], fill=PAL["hedge_mid"])
    draw.ellipse([cx - 22, cy - 10, cx - 10, cy + 2], fill=PAL["hedge_mid"], outline=PAL["outline"])
    draw.ellipse([cx + 10, cy - 8, cx + 22, cy + 4], fill=PAL["hedge_mid"], outline=PAL["outline"])
    draw.ellipse([cx - 14, cy - 22, cx + 14, cy + 2], fill=PAL["hedge_mid"], outline=PAL["outline"])
    draw.ellipse([cx - 11, cy - 20, cx + 10, cy - 2], fill=PAL["hedge_light"])
    draw.ellipse([cx - 12, cy - 29, cx - 3, cy - 19], fill=PAL["hedge_mid"], outline=PAL["outline"])
    draw.ellipse([cx + 3, cy - 29, cx + 12, cy - 19], fill=PAL["hedge_mid"], outline=PAL["outline"])
    draw.ellipse([cx - 6, cy - 14, cx - 2, cy - 10], fill=PAL["white"], outline=PAL["outline"])
    draw.ellipse([cx + 2, cy - 14, cx + 6, cy - 10], fill=PAL["white"], outline=PAL["outline"])
    draw.point((cx - 4, cy - 12), fill=PAL["outline"])
    draw.point((cx + 4, cy - 12), fill=PAL["outline"])


def draw_car_3d(draw, cx, cy, body_color):
    """Dibuja un vehículo estacionado en perspectiva 3/4 (2.0m x 4.2m = 40 x 84 texeles)."""
    w, h = 34, 64
    x1, y1, x2, y2 = cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2
    # Sombra
    draw.rectangle([x1 + 2, y1 + 3, x2 + 3, y2 + 3], fill=PAL["concrete_shadow"])
    # Ruedas
    for wy in [y1 + 8, y2 - 14]:
        draw.rectangle([x1 - 2, wy, x1 + 2, wy + 10], fill=PAL["outline"])
        draw.rectangle([x2 - 2, wy, x2 + 2, wy + 10], fill=PAL["outline"])
    # Carrocería
    draw.rectangle([x1, y1, x2, y2], fill=body_color, outline=PAL["outline"])
    # Parabrisas y toldo 3/4
    draw.rectangle([x1 + 3, y1 + 12, x2 - 3, y2 - 12], fill=PAL["window_dark"], outline=PAL["outline"])
    draw.rectangle([x1 + 4, y1 + 20, x2 - 4, y2 - 18], fill=body_color, outline=PAL["outline"])
    # Faros
    draw.rectangle([x1 + 4, y1 + 1, x1 + 10, y1 + 4], fill=PAL["curb_yellow"])
    draw.rectangle([x2 - 10, y1 + 1, x2 - 4, y1 + 4], fill=PAL["curb_yellow"])


def draw_classroom_furniture(draw, rx1, ry1, rx2, ry2, board_top=True):
    mid_x = (rx1 + rx2) // 2
    if board_top:
        bw = min(60, (rx2 - rx1) - 20)
        draw.rectangle([mid_x - bw // 2, ry1 + 3, mid_x + bw // 2, ry1 + 10], fill=PAL["white"], outline=PAL["outline"])
        draw.line([(mid_x - bw // 2 + 2, ry1 + 9), (mid_x + bw // 2 - 2, ry1 + 9)], fill=PAL["silver"])
        draw.rectangle([rx1 + 10, ry1 + 14, rx1 + 30, ry1 + 25], fill=PAL["wood_mahogany"], outline=PAL["outline"])
    for py in range(ry1 + 32, ry2 - 14, 20):
        for px in range(rx1 + 14, rx2 - 18, 22):
            draw.rectangle([px + 3, py + 7, px + 11, py + 12], fill=PAL["green_bldg_dark"], outline=PAL["outline"])
            draw.rectangle([px, py, px + 14, py + 8], fill=PAL["wood_desk"], outline=PAL["outline"])
            draw.rectangle([px + 2, py + 2, px + 7, py + 6], fill=PAL["white"])


def draw_green_trash_drum(draw, cx, cy):
    draw.ellipse([cx - 6, cy + 4, cx + 6, cy + 9], fill=(30, 35, 40))
    draw.rectangle([cx - 5, cy - 8, cx + 5, cy + 6], fill=PAL["gate_green"], outline=PAL["outline"])
    draw.line([(cx - 5, cy - 3), (cx + 5, cy - 3)], fill=PAL["hedge_light"])
    draw.line([(cx - 5, cy + 2), (cx + 5, cy + 2)], fill=PAL["hedge_light"])
    draw.ellipse([cx - 5, cy - 10, cx + 5, cy - 6], fill=(40, 44, 50), outline=PAL["outline"])


def draw_warp_pad(draw, cx, cy, label_color=PAL["curb_yellow"]):
    draw.ellipse([cx - 18, cy - 12, cx + 18, cy + 12], fill=PAL["guinda"], outline=PAL["outline"])
    draw.ellipse([cx - 14, cy - 9, cx + 14, cy + 9], fill=label_color, outline=PAL["outline"])
    draw.ellipse([cx - 8, cy - 5, cx + 8, cy + 5], fill=PAL["white"])


# ==============================================================================
# ESCENARIO 1: ACCESO PRINCIPAL, ESTACIONAMIENTO Y EDIFICIO D (LABORATORIO)
# Dimensiones reales: 36.00 m x 22.00 m = 1440 x 880 px (720 x 440 texeles)
# ==============================================================================
def generate_scenario_1():
    img, draw, tw, th = new_canvas(36.0, 22.0)
    fill_grass_texture(draw, 0, 0, tw - 1, th - 1)

    # 1. Muro de contención al fondo norponiente (piedra braza negra con barandal blanco)
    draw_stone_retaining_wall(draw, 0, 0, 300, 42)
    draw_white_railing(draw, 4, 14, 296, height=10)

    # 2. Pasillo de salida hacia el Edificio A (dibujado antes del Osito para no taparlo)
    fill_concrete_slabs(draw, 20, 144, 140, 260, slab_t=32)

    # 3. Muro Institucional COBAEM Guinda/Púrpura + Osito Topiario (fotos 095254.jpg y 095304.jpg)
    mx1, my1, mx2, my2 = 16, 42, 276, 108
    draw.rectangle([mx1, my1, mx2, my2], fill=PAL["cobaem_purple"], outline=PAL["outline"])
    draw.rectangle([mx1, my1, mx2, my1 + 8], fill=PAL["roof_red"], outline=PAL["outline"])
    draw.rectangle([mx1, my1 + 8, mx2, my1 + 13], fill=PAL["white"])
    draw_pixel_sign(draw, (mx1 + mx2) // 2 + 12, my1 + 24, "COBAEM CEMSAD 22 ENTHAVI", bg=PAL["white"], fg=PAL["cobaem_purple"])
    # Colibrí dorado EDOMEX a la izquierda
    draw.polygon([(mx1 + 14, my1 + 22), (mx1 + 30, my1 + 30), (mx1 + 22, my1 + 46)], fill=PAL["curb_yellow"], outline=PAL["outline"])
    draw.rectangle([mx1, my2 - 6, mx2, my2 - 2], fill=PAL["white"])
    draw.rectangle([mx1, my2 - 2, mx2, my2 + 2], fill=PAL["curb_yellow"], outline=PAL["outline"])
    # Jardinera y el Osito Topiario frente al muro COBAEM (a la derecha de la salida para lucir completo)
    draw.rectangle([144, my2 + 2, mx2 - 4, my2 + 40], fill=PAL["hedge_dark"], outline=PAL["outline"])
    draw_bear_topiary(draw, 210, my2 + 20)

    # 4. Patio de Maniobras y Estacionamiento (22.00m x 12.00m = 440 x 240 texeles)
    px1, py1, px2, py2 = 120, 180, 560, 420
    fill_concrete_slabs(draw, px1, py1, px2, py2, slab_t=40)
    draw.rectangle([px1, py1, px2, py1 + 4], fill=PAL["curb_yellow"], outline=PAL["outline"])
    draw.rectangle([px1, py2 - 4, px2, py2], fill=PAL["curb_yellow"], outline=PAL["outline"])
    draw.rectangle([px2 - 4, py1, px2, py2], fill=PAL["curb_yellow"], outline=PAL["outline"])
    # Líneas amarillas de los cajones de estacionamiento y vehículos estacionados (fotos Estacionamiento y barda.jpg)
    for cx in range(px1 + 80, px1 + 335, 50):
        draw.rectangle([cx, py1 + 5, cx + 2, py1 + 92], fill=PAL["curb_yellow"])
    # 3 autos reales observados en las fotos de campo:
    draw_car_3d(draw, px1 + 205, py1 + 52, PAL["roof_red"])       # Sedán rojo tipo VW Vento
    draw_car_3d(draw, px1 + 255, py1 + 52, PAL["white"])          # Hatchback blanco tipo Mazda 2
    draw_car_3d(draw, px1 + 305, py1 + 52, PAL["concrete_light"]) # Utilitaria blanca tipo Renault Kangoo

    # 5. Plaza de Acceso Principal (14.00m x 8.00m = 280 x 160 texeles) y Caseta C.V. (3.00m x 2.50m = 60 x 50 texeles)
    ax1, ay1, ax2, ay2 = 20, 260, 300, 425
    fill_concrete_slabs(draw, ax1, ay1, ax2, ay2, slab_t=36)
    draw_zebra_ramp(draw, ax1 + 60, ay2 - 36, ax2 - 20, ay2 - 14, horizontal=True)
    for sy in range(ay1 + 48, ay1 + 72, 8):
        draw.rectangle([ax1 + 82, sy, ax1 + 135, sy + 7], fill=PAL["curb_yellow"], outline=PAL["outline"])

    # Caseta de Vigilancia C.V. (3.00m x 2.50m = 60 x 50 texeles, foto 095144.jpg)
    cv_x1, cv_y1, cv_x2, cv_y2 = 22, 268, 82, 326
    draw_stone_retaining_wall(draw, cv_x1 - 4, cv_y2, cv_x2 + 16, cv_y2 + 14)
    draw.rectangle([cv_x1, cv_y1, cv_x2, cv_y2], fill=PAL["terracota"], outline=PAL["outline"])
    draw.rectangle([cv_x1, cv_y1, cv_x2, cv_y1 + 5], fill=PAL["guinda"])
    draw.rectangle([cv_x1, cv_y2 - 6, cv_x2, cv_y2], fill=PAL["guinda"])
    draw.polygon([(cv_x1 - 6, cv_y1), (cv_x2 + 6, cv_y1), (cv_x2, cv_y1 - 12), (cv_x1, cv_y1 - 12)], fill=PAL["roof_red"], outline=PAL["outline"])
    draw.rectangle([cv_x1 + 18, cv_y1 - 24, cv_x1 + 42, cv_y1 - 12], fill=PAL["green_mint_dark"], outline=PAL["outline"])
    draw_window_grille(draw, cv_x1 + 4, cv_y1 + 10, cv_x1 + 20, cv_y1 + 34)
    draw_window_grille(draw, cv_x2 - 20, cv_y1 + 10, cv_x2 - 4, cv_y1 + 34)
    draw.rectangle([cv_x1 + 22, cv_y1 + 12, cv_x2 - 22, cv_y1 + 26], fill=PAL["white"], outline=PAL["outline"])
    draw.ellipse([cv_x2 - 28, cv_y1 + 14, cv_x2 - 23, cv_y1 + 19], fill=PAL["brick_red"])
    draw_spiral_topiary(draw, cv_x1 + 30, cv_y2 - 2)
    # Escalones amarillos de acceso junto a caseta (foto Caseta CV.jpg)
    for sy in range(cv_y1 + 14, cv_y1 + 36, 7):
        draw.rectangle([cv_x2 + 2, sy, cv_x2 + 18, sy + 6], fill=PAL["curb_yellow"], outline=PAL["outline"])
    draw_pixel_sign(draw, (cv_x1 + cv_x2) // 2, cv_y1 - 6, "CASETA C.V.", bg=PAL["guinda"], fg=PAL["white"])

    # Portón Triple Abatible verde con pilares color vino/guinda (foto 095144.jpg)
    gx1, gy1, gx2, gy2 = 24, 412, 260, 434
    draw.rectangle([gx1, gy1, gx2, gy2], fill=PAL["gate_green"], outline=PAL["outline"])
    for bx in range(gx1 + 4, gx2 - 2, 5):
        draw.line([(bx, gy1 + 2), (bx, gy2 - 2)], fill=PAL["hedge_light"])
    for px in [gx1, gx1 + 78, gx1 + 156, gx2 - 8]:
        draw.rectangle([px, gy1 - 4, px + 8, gy2 + 2], fill=PAL["guinda"], outline=PAL["outline"])

    # 6. EDIFICIO "D" • UNIDAD DE LABORATORIO (19.00m x 9.64m = 380 x 193 texeles, fotos 095153 y 095218)
    dx1, dy1 = 310, 18
    dw, dh = m_to_t(19.0), m_to_t(9.64)  # 380 x 193 texeles
    dx2, dy2 = dx1 + dw, dy1 + dh

    fill_concrete_slabs(draw, dx1 - 8, dy1, dx2 + 8, dy2 + 18, slab_t=24)
    draw.rectangle([dx1 - 8, dy2 + 14, dx2 + 8, dy2 + 18], fill=PAL["curb_yellow"], outline=PAL["outline"])

    # 6a. Laboratorio de Usos Múltiples (12.80m x 7.20m = 256 x 144 texeles)
    lab_x1, lab_y1 = dx1 + 4, dy1 + 6
    lab_x2, lab_y2 = lab_x1 + m_to_t(12.80), lab_y1 + m_to_t(7.20)
    fill_ceramic_tiles(draw, lab_x1, lab_y1, lab_x2, lab_y2, tile_t=8)

    for row_y in [lab_y1 + 28, lab_y1 + 78]:
        for col_x in [lab_x1 + 28, lab_x1 + 106, lab_x1 + 184]:
            draw.rectangle([col_x + 2, row_y + 2, col_x + 38, row_y + 22], fill=(160, 155, 145))
            draw.rectangle([col_x, row_y, col_x + 36, row_y + 20], fill=PAL["lab_blue"], outline=PAL["outline"])
            draw.rectangle([col_x + 14, row_y + 5, col_x + 22, row_y + 15], fill=PAL["silver"], outline=PAL["outline"])
            draw.rectangle([col_x + 5, row_y + 6, col_x + 10, row_y + 12], fill=PAL["white"])
            draw.rectangle([col_x + 26, row_y + 6, col_x + 31, row_y + 12], fill=PAL["curb_yellow"])
            for bx in [col_x + 6, col_x + 26]:
                draw.ellipse([bx - 3, row_y - 6, bx + 3, row_y - 1], fill=PAL["silver"], outline=PAL["outline"])
                draw.ellipse([bx - 3, row_y + 21, bx + 3, row_y + 26], fill=PAL["silver"], outline=PAL["outline"])

    # 6b. Cubículo de Reactivos (3.80m x 3.60m) y Almacén Lab (3.80m x 3.40m)
    reac_x1, reac_x2 = lab_x2 + 4, dx2 - 4
    reac_y1, reac_y2 = lab_y1, lab_y1 + m_to_t(3.60)
    alm_y1, alm_y2 = reac_y2 + 4, lab_y2
    fill_ceramic_tiles(draw, reac_x1, reac_y1, reac_x2, reac_y2, tile_t=8)
    fill_ceramic_tiles(draw, reac_x1, alm_y1, reac_x2, alm_y2, tile_t=8)
    draw.rectangle([reac_x1 + 8, reac_y1 + 8, reac_x2 - 8, reac_y1 + 20], fill=PAL["curb_yellow"], outline=PAL["outline"])
    draw.rectangle([reac_x1 + 8, alm_y1 + 8, reac_x2 - 8, alm_y1 + 20], fill=PAL["silver"], outline=PAL["outline"])

    # Muros perimetrales y fachada frontal 3/4 del Edificio D
    draw.rectangle([dx1, dy1, dx2, dy1 + 6], fill=PAL["guinda"], outline=PAL["outline"])
    draw.rectangle([lab_x2, dy1, lab_x2 + 4, lab_y2], fill=PAL["guinda"], outline=PAL["outline"])
    draw.rectangle([reac_x1, reac_y2, reac_x2, reac_y2 + 4], fill=PAL["guinda"], outline=PAL["outline"])

    fy1, fy2 = lab_y2, lab_y2 + 26
    draw.rectangle([dx1, fy1, dx2, fy1 + 6], fill=PAL["guinda"], outline=PAL["outline"])
    draw_window_grille(draw, dx1 + 8, fy1 + 6, dx1 + 78, fy1 + 15)
    draw_brick_wall_patch(draw, dx1 + 8, fy1 + 15, dx1 + 78, fy2)
    draw.rectangle([dx1 + 82, fy1 + 6, dx1 + 168, fy2], fill=PAL["ochre_wall"], outline=PAL["outline"])
    draw_green_trash_drum(draw, dx1 + 92, fy2 + 2)
    draw_window_grille(draw, dx1 + 174, fy1 + 6, dx1 + 236, fy1 + 15)
    draw_brick_wall_patch(draw, dx1 + 174, fy1 + 15, dx1 + 236, fy2)
    draw_door_3d(draw, dx1 + 238, fy2, w=20, h=20, color=PAL["white"])
    draw_window_grille(draw, dx1 + 264, fy1 + 6, dx2 - 8, fy1 + 15)
    draw_brick_wall_patch(draw, dx1 + 264, fy1 + 15, dx2 - 8, fy2)
    draw.rectangle([dx1 + 276, fy2 - 6, dx1 + 288, fy2 + 8], fill=PAL["zebra_blue"], outline=PAL["outline"])
    for cx in [dx1, dx1 + 80, dx1 + 170, dx1 + 260, dx2 - 6]:
        draw.rectangle([cx, fy1, cx + 6, fy2 + 2], fill=PAL["guinda"], outline=PAL["outline"])

    # Placas arquitectónicas del Edificio D
    draw_pixel_sign(draw, (lab_x1 + lab_x2) // 2, dy1 + 14, "EDIF D - LABORATORIO 12.8X7.2M", bg=PAL["guinda"], fg=PAL["white"])
    draw_pixel_sign(draw, (reac_x1 + reac_x2) // 2, reac_y1 + 36, "REACTIVOS", bg=PAL["white"], fg=PAL["outline"])
    draw_pixel_sign(draw, (reac_x1 + reac_x2) // 2, alm_y1 + 36, "ALMACEN", bg=PAL["white"], fg=PAL["outline"])

    # 7. Sistema Captador de Agua Pluvial (5.00m x 5.00m = 100 x 100 texeles)
    cap_x1, cap_y1 = 580, 260
    cap_x2, cap_y2 = cap_x1 + m_to_t(5.0), cap_y1 + m_to_t(5.0)
    draw.rectangle([cap_x1, cap_y1, cap_x2, cap_y2], fill=PAL["lab_blue"], outline=PAL["outline"])
    draw.rectangle([cap_x1 + 6, cap_y1 + 6, cap_x2 - 6, cap_y2 - 6], fill=PAL["window_glass"], outline=PAL["outline"])
    draw.rectangle([cap_x1 + 36, cap_y1 + 36, cap_x1 + 64, cap_y1 + 64], fill=PAL["silver"], outline=PAL["outline"])
    draw_pixel_sign(draw, (cap_x1 + cap_x2) // 2, cap_y1 + 16, "CAPTADOR 25M2", bg=PAL["white"], fg=PAL["outline"])

    # 8. Barda Perimetral Oriente
    draw.rectangle([tw - 16, 10, tw - 4, th - 10], fill=PAL["terracota"], outline=PAL["outline"])
    for by in range(10, th - 10, 60):
        draw.rectangle([tw - 18, by, tw - 2, by + 8], fill=PAL["guinda"], outline=PAL["outline"])

    draw_warp_pad(draw, 60, 165)
    draw_pine_tree(draw, 640, 390, radius=20)
    draw_pine_tree(draw, 590, 400, radius=18)

    save_pixel_art(img, "nivel_1_acceso_laboratorio.png")


# ==============================================================================
# ESCENARIO 2: EDIFICIO "A" (CAFETERÍA, ALMACÉN, AULAS 1-2 Y SANITARIOS)
# Dimensiones reales: 40.00 m x 20.00 m = 1600 x 800 px (800 x 400 texeles)
# ==============================================================================
def generate_scenario_2():
    img, draw, tw, th = new_canvas(40.0, 20.0)
    fill_grass_texture(draw, 0, 0, tw - 1, th - 1)

    fill_concrete_slabs(draw, 40, 0, tw - 40, 52, slab_t=40)
    draw.line([(40, 36), (tw - 40, 36)], fill=PAL["zebra_blue"], width=2)
    draw.rectangle([40, 56, tw - 40, 106], fill=PAL["hedge_dark"], outline=PAL["outline"])
    draw.rectangle([44, 60, tw - 44, 102], fill=PAL["hedge_mid"])
    for tx in range(90, tw - 80, 75):
        draw_spiral_topiary(draw, tx, 82)
    draw.rectangle([40, 106, tw - 40, 110], fill=PAL["curb_yellow"], outline=PAL["outline"])

    fill_concrete_slabs(draw, 25, 110, tw - 25, 184, slab_t=32)
    for mx in [180, 420, 680]:
        draw.ellipse([mx - 8, 114, mx + 8, 126], fill=PAL["white"], outline=PAL["outline"])
        draw.ellipse([mx - 6, 108, mx + 6, 120], fill=PAL["hedge_light"], outline=PAL["outline"])

    # EDIFICIO "A" ENVOLVENTE GENERAL (35.00m x 9.69m = 700 x 194 texeles)
    ax1, ay1 = 50, 184
    aw, ah = m_to_t(35.00), m_to_t(9.69)
    ax2, ay2 = ax1 + aw, ay1 + ah

    draw.rectangle([ax1, ay1, ax2, ay2], fill=PAL["guinda_dark"], outline=PAL["outline"])
    room_y1, room_y2 = ay1 + 24, ay1 + 24 + m_to_t(7.00)

    # 1. Desayunador y Cafetería Escolar (6.20m x 7.00m = 124 x 140 texeles)
    caf_x1, caf_x2 = ax1 + 8, ax1 + 8 + m_to_t(6.20)
    fill_concrete_slabs(draw, caf_x1, ay1, caf_x2, room_y2, slab_t=20)
    draw.rectangle([caf_x1 + 4, room_y2 - 52, caf_x2 - 4, room_y2 - 4], fill=PAL["green_mint_wall"], outline=PAL["outline"])
    draw.rectangle([caf_x1 + 8, room_y2 - 50, caf_x2 - 8, room_y2 - 40], fill=PAL["white"], outline=PAL["outline"])
    draw.rectangle([caf_x1 + 12, room_y2 - 40, caf_x2 - 12, room_y2 - 22], fill=PAL["wood_mahogany"], outline=PAL["outline"])
    draw.rectangle([caf_x1 + 8, room_y2 - 22, caf_x2 - 8, room_y2 - 16], fill=PAL["white"], outline=PAL["outline"])
    for tx, ty in [(caf_x1 + 36, ay1 + 46), (caf_x1 + 88, ay1 + 46)]:
        draw.rectangle([tx - 12, ty - 10, tx + 12, ty + 10], fill=PAL["white"], outline=PAL["outline"])
        draw.rectangle([tx - 18, ty - 4, tx - 13, ty + 4], fill=PAL["zebra_blue"], outline=PAL["outline"])
        draw.rectangle([tx + 13, ty - 4, tx + 18, ty + 4], fill=PAL["curb_yellow"], outline=PAL["outline"])
        draw.rectangle([tx - 4, ty - 16, tx + 4, ty - 11], fill=PAL["green_bldg"], outline=PAL["outline"])
        draw.rectangle([tx - 4, ty + 11, tx + 4, ty + 16], fill=PAL["zebra_blue"], outline=PAL["outline"])
    # Mesa picnic con mantel azul institucional y bancos oscuros (foto cafeteria.jpg)
    pic_x, pic_y = caf_x1 + 40, ay1 + 84
    draw.rectangle([pic_x - 18, pic_y - 8, pic_x + 18, pic_y + 8], fill=PAL["zebra_blue"], outline=PAL["outline"])
    draw.rectangle([pic_x - 16, pic_y - 6, pic_x + 16, pic_y + 6], fill=PAL["window_glass"])
    draw.rectangle([pic_x - 18, pic_y - 14, pic_x + 18, pic_y - 10], fill=PAL["stone_dark"], outline=PAL["outline"])
    draw.rectangle([pic_x - 18, pic_y + 10, pic_x + 18, pic_y + 14], fill=PAL["stone_dark"], outline=PAL["outline"])

    # 2. Almacén General (3.80m x 7.00m = 76 x 140 texeles)
    alm_x1, alm_x2 = caf_x2 + 8, caf_x2 + 8 + m_to_t(3.80)
    fill_ceramic_tiles(draw, alm_x1, room_y1, alm_x2, room_y2, tile_t=8)
    for sy in range(room_y1 + 16, room_y2 - 16, 26):
        draw.rectangle([alm_x1 + 8, sy, alm_x2 - 8, sy + 10], fill=PAL["silver"], outline=PAL["outline"])
        draw.rectangle([alm_x1 + 12, sy + 2, alm_x1 + 26, sy + 8], fill=PAL["terracota"])

    # 3. Aula 1 • Grupo 101 (8.00m x 7.00m = 160 x 140 texeles)
    a1_x1, a1_x2 = alm_x2 + 8, alm_x2 + 8 + m_to_t(8.00)
    fill_ceramic_tiles(draw, a1_x1, room_y1, a1_x2, room_y2, tile_t=8)
    draw_classroom_furniture(draw, a1_x1, room_y1, a1_x2, room_y2, board_top=False)
    draw.rectangle([a1_x1 + 40, room_y2 - 10, a1_x2 - 40, room_y2 - 3], fill=PAL["white"], outline=PAL["outline"])

    # 4. Aula 2 • Grupo 201 (8.00m x 7.00m = 160 x 140 texeles)
    a2_x1, a2_x2 = a1_x2 + 8, a1_x2 + 8 + m_to_t(8.00)
    fill_ceramic_tiles(draw, a2_x1, room_y1, a2_x2, room_y2, tile_t=8)
    draw_classroom_furniture(draw, a2_x1, room_y1, a2_x2, room_y2, board_top=False)
    draw.rectangle([a2_x1 + 40, room_y2 - 10, a2_x2 - 40, room_y2 - 3], fill=PAL["white"], outline=PAL["outline"])

    # 5. Módulo de Sanitarios H/M (6.00m x 7.00m = 120 x 140 texeles)
    san_x1, san_x2 = a2_x2 + 8, ax2 - 8
    fill_ceramic_tiles(draw, san_x1, room_y1, san_x2, room_y2, tile_t=6)
    mid_san = (san_x1 + san_x2) // 2
    draw.rectangle([mid_san - 3, room_y1 + 16, mid_san + 3, room_y2 - 6], fill=PAL["guinda"], outline=PAL["outline"])
    for cy in range(room_y1 + 24, room_y2 - 16, 26):
        draw.rectangle([san_x1 + 6, cy, san_x1 + 32, cy + 20], fill=PAL["tile_cream"], outline=PAL["outline"])
        draw.ellipse([san_x1 + 12, cy + 6, san_x1 + 22, cy + 14], fill=PAL["white"], outline=PAL["outline"])
        draw.rectangle([san_x2 - 32, cy, san_x2 - 6, cy + 20], fill=PAL["tile_cream"], outline=PAL["outline"])
        draw.ellipse([san_x2 - 22, cy + 6, san_x2 - 12, cy + 14], fill=PAL["white"], outline=PAL["outline"])

    # Fachada Norte 3/4 del Edificio A
    fy1, fy2 = ay1, room_y1
    draw.rectangle([alm_x1 - 4, fy1, ax2, fy2], fill=PAL["ochre_wall"], outline=PAL["outline"])
    draw.rectangle([ax1, fy1, ax2, fy1 + 6], fill=PAL["guinda"], outline=PAL["outline"])
    for rx1, rx2 in [(alm_x1, alm_x2), (a1_x1, a1_x2), (a2_x1, a2_x2), (san_x1, san_x2)]:
        draw_door_3d(draw, rx1 + 8, fy2, w=18, h=18, color=PAL["white"])
        if rx2 - rx1 > 90:
            draw_window_grille(draw, rx1 + 34, fy1 + 6, rx2 - 12, fy1 + 15)
            draw.rectangle([rx1 + 42, fy1 + 7, rx1 + 54, fy1 + 14], fill=PAL["curb_yellow"])
            draw.rectangle([rx1 + 56, fy1 + 7, rx1 + 68, fy1 + 14], fill=PAL["white"])

    for cx in range(ax1, ax2 + 1, 70):
        draw.rectangle([cx, fy1 - 6, cx + 8, fy2], fill=PAL["guinda"], outline=PAL["outline"])
    # Remate de módulo de tabique rojo en azotea (visible en fotos Pasillo Edificio A y arcotecho)
    draw.rectangle([ax1 + 220, fy1 - 18, ax1 + 265, fy1], fill=PAL["brick_red"], outline=PAL["outline"])
    draw.rectangle([ax1 + 220, fy1 - 18, ax1 + 265, fy1 - 15], fill=PAL["brick_dark"])

    # Placas arquitectónicas del Edificio A
    draw_pixel_sign(draw, (caf_x1 + caf_x2) // 2, fy1 + 3, "CAFETERIA 6.2X7M", bg=PAL["guinda"], fg=PAL["white"])
    draw_pixel_sign(draw, (alm_x1 + alm_x2) // 2, fy1 + 3, "ALMACEN", bg=PAL["guinda"], fg=PAL["white"])
    draw_pixel_sign(draw, (a1_x1 + a1_x2) // 2, fy1 + 3, "AULA 1 - 101 (8X7M)", bg=PAL["guinda"], fg=PAL["white"])
    draw_pixel_sign(draw, (a2_x1 + a2_x2) // 2, fy1 + 3, "AULA 2 - 201 (8X7M)", bg=PAL["guinda"], fg=PAL["white"])
    draw_pixel_sign(draw, (san_x1 + san_x2) // 2, fy1 + 3, "SANITARIOS H/M", bg=PAL["guinda"], fg=PAL["white"])

    draw.rectangle([a1_x1 - 6, fy2 - 4, a1_x1 + 16, fy2 + 8], fill=PAL["green_bldg"], outline=PAL["outline"])
    draw.rectangle([a1_x1 - 4, fy2 - 2, a1_x1 + 4, fy2 + 4], fill=PAL["zebra_blue"])
    draw.rectangle([8, 100, ax1 - 4, ay2], fill=PAL["green_mint_wall"], outline=PAL["outline"])

    draw_warp_pad(draw, 70, 130)

    save_pixel_art(img, "nivel_2_edificio_a_cafeteria.png")


# ==============================================================================
# ESCENARIO 3: PLAZA CÍVICA CON TECHUMBRE Y ESCALINATA MONUMENTAL "S"
# Dimensiones reales: 40.00 m x 22.50 m = 1600 x 900 px (800 x 450 texeles)
# ==============================================================================
def generate_scenario_3():
    img, draw, tw, th = new_canvas(40.0, 22.5)
    fill_grass_texture(draw, 0, 0, tw - 1, th - 1)

    sx1, sx2 = 18, 108
    sy1, sy2 = 36, 416
    draw.rectangle([4, 10, sx1, th - 10], fill=PAL["terracota"], outline=PAL["outline"])
    for by in range(16, th - 16, 48):
        draw.rectangle([3, by, sx1 + 1, by + 7], fill=PAL["guinda"], outline=PAL["outline"])

    for y in range(sy1, sy2, 8):
        if 150 <= y <= 174 or 280 <= y <= 304:
            c = PAL["zebra_blue"] if ((y // 8) % 2 == 0) else PAL["zebra_white"]
            draw.rectangle([sx1, y, sx2, y + 7], fill=c, outline=PAL["outline"])
        else:
            draw.rectangle([sx1, y, sx2, y + 5], fill=PAL["curb_yellow"], outline=PAL["outline"])
            draw.rectangle([sx1, y + 5, sx2, y + 8], fill=PAL["curb_yellow_dark"], outline=PAL["outline"])

    draw.rectangle([sx2, sy1, sx2 + 10, sy2 - 36], fill=PAL["alfarda_rose"], outline=PAL["outline"])
    draw.rectangle([sx2 + 2, sy1, sx2 + 8, sy2 - 38], fill=PAL["guinda_light"])
    # Puerta metálica corrediza de bodega bajo rampa (foto Escaleras a Edificio B.jpg)
    draw.rectangle([sx2 - 14, sy2 - 76, sx2 + 9, sy2 - 38], fill=PAL["white"], outline=PAL["outline"])
    for rx in range(sx2 - 11, sx2 + 8, 4):
        draw.line([(rx, sy2 - 74), (rx, sy2 - 40)], fill=PAL["silver"])
    draw_pixel_sign(draw, (sx1 + sx2) // 2, sy2 - 8, "ESCALINATA S +4M", bg=PAL["guinda"], fg=PAL["white"])

    # PLAZA CÍVICA CON TECHUMBRE METÁLICA (34.00m x 22.00m = 680 x 440 texeles)
    px1, py1 = 112, 10
    pw, ph = m_to_t(34.00), m_to_t(22.00)
    px2, py2 = px1 + pw, min(th - 6, py1 + ph)

    fill_concrete_slabs(draw, px1, py1 + 78, px2, py2, slab_t=40)

    court_x1, court_y1, court_x2, court_y2 = px1 + 50, py1 + 110, px2 - 50, py2 - 30
    draw.rectangle([court_x1, court_y1, court_x2, court_y2], outline=PAL["zebra_blue"], width=2)
    mid_cx = (court_x1 + court_x2) // 2
    mid_cy = (court_y1 + court_y2) // 2
    draw.line([(mid_cx, court_y1), (mid_cx, court_y2)], fill=PAL["zebra_blue"], width=2)
    draw.ellipse([mid_cx - 36, mid_cy - 36, mid_cx + 36, mid_cy + 36], outline=PAL["curb_yellow"], width=2)
    # Red de voleibol con postes anclados en llantas de concreto (foto arcotecho, edificio A y pared.jpg)
    for vx in [mid_cx - 70, mid_cx + 70]:
        draw.ellipse([vx - 7, mid_cy + 14, vx + 7, mid_cy + 22], fill=PAL["stone_black"], outline=PAL["outline"])
        draw.ellipse([vx - 5, mid_cy + 15, vx + 5, mid_cy + 20], fill=PAL["concrete_dark"])
        draw.line([(vx, mid_cy - 28), (vx, mid_cy + 16)], fill=PAL["silver"], width=2)
    for ny in range(mid_cy - 26, mid_cy - 8, 4):
        draw.line([(mid_cx - 70, ny), (mid_cx + 70, ny)], fill=PAL["white"], width=1)
    for nx in range(mid_cx - 66, mid_cx + 66, 8):
        draw.line([(nx, mid_cy - 26), (nx, mid_cy - 8)], fill=PAL["white"], width=1)

    # Muro de Contención Norte de Piedra Braza Negra con Juntas Blancas
    wall_y1, wall_y2 = py1 + 12, py1 + 88
    draw_stone_retaining_wall(draw, px1, wall_y1, px2, wall_y2)
    draw_white_railing(draw, px1, wall_y1, px2, height=11)

    # Mural Rojo del 20 Aniversario y Gran Lona Blanca Conmemorativa COBAEM 30 / CEMSaD 22
    draw.rectangle([px1 + 190, wall_y1 + 20, px1 + 275, wall_y2 - 14], fill=PAL["roof_red"], outline=PAL["outline"])
    for gy in range(wall_y1 + 24, wall_y2 - 18, 8):
        for gx in range(px1 + 194, px1 + 270, 12):
            draw.rectangle([gx, gy, gx + 9, gy + 5], fill=PAL["tile_cream"])
    draw.ellipse([px1 + 224, wall_y1 + 32, px1 + 242, wall_y1 + 48], fill=PAL["curb_yellow"], outline=PAL["outline"])

    ban_x1, ban_y1, ban_x2, ban_y2 = px1 + 350, wall_y1 + 16, px1 + 540, wall_y2 - 12
    draw.rectangle([ban_x1, ban_y1, ban_x2, ban_y2], fill=PAL["white"], outline=PAL["outline"])
    draw_pixel_sign(draw, (ban_x1 + ban_x2) // 2, ban_y1 + 10, "30 ANIV COBAEM", bg=PAL["white"], fg=PAL["brick_red"], border=PAL["white"])
    draw_pixel_sign(draw, (ban_x1 + ban_x2) // 2, ban_y1 + 22, "20 ANIV CEMSAD 22 ENTHAVI", bg=PAL["white"], fg=PAL["outline"], border=PAL["white"])

    # Bodega bajo rampa a la derecha
    bod_x1, bod_y1, bod_x2, bod_y2 = px2 - 115, wall_y1 + 18, px2 - 12, wall_y2 + 4
    draw.polygon([(bod_x1, bod_y2), (bod_x1 + 45, bod_y1), (bod_x2, bod_y1), (bod_x2, bod_y2)], fill=PAL["tile_cream"], outline=PAL["outline"])
    draw_door_3d(draw, bod_x2 - 38, bod_y2, w=20, h=38, color=PAL["white"])

    # 12 Columnas cilíndricas blancas con base color vino/guinda
    col_xs = [px1 + 20, px1 + 140, px1 + 260, px1 + 380, px1 + 500, px1 + 620]
    for cx in col_xs:
        draw.rectangle([cx - 5, wall_y1 + 4, cx + 5, wall_y2 + 4], fill=PAL["white"], outline=PAL["outline"])
        draw.rectangle([cx - 5, wall_y2 - 14, cx + 5, wall_y2 + 4], fill=PAL["guinda"], outline=PAL["outline"])
        draw.line([(cx - 5, wall_y2 - 16), (cx + 5, wall_y2 - 16)], fill=PAL["silver"], width=2)
        sy = py2 - 16
        draw.rectangle([cx - 5, sy - 18, cx + 5, sy + 4], fill=PAL["white"], outline=PAL["outline"])
        draw.rectangle([cx - 5, sy - 6, cx + 5, sy + 4], fill=PAL["guinda"], outline=PAL["outline"])

    draw_green_trash_drum(draw, px1 + 42, wall_y2 + 4)
    draw_green_trash_drum(draw, px1 + 522, wall_y2 + 4)
    draw.rectangle([px1, wall_y1, px2, wall_y1 + 6], fill=PAL["silver"], outline=PAL["outline"])
    draw_pixel_sign(draw, mid_cx, wall_y2 + 12, "PLAZA CIVICA TECHADA 34X22M (748 M2)", bg=PAL["guinda"], fg=PAL["white"])

    draw_warp_pad(draw, (sx1 + sx2) // 2, sy1 + 16)

    save_pixel_art(img, "nivel_3_plaza_civica_escalinata.png")


# ==============================================================================
# ESCENARIO 4: TERRAZA SUPERIOR PONIENTE — EDIFICIO "B" (NPT +4.00 m)
# Dimensiones reales: 36.00 m x 20.00 m = 1440 x 800 px (720 x 400 texeles)
# ==============================================================================
def generate_scenario_4():
    img, draw, tw, th = new_canvas(36.0, 20.0)
    fill_grass_texture(draw, 0, 0, tw - 1, th - 1)

    bx1, by1 = 40, 14
    bw, bh = m_to_t(32.00), m_to_t(9.78)
    bx2, by2 = bx1 + bw, by1 + bh

    draw.rectangle([bx1, by1, bx2, by2], fill=PAL["green_bldg_dark"], outline=PAL["outline"])
    room_y1, room_y2 = by1 + 8, by1 + 8 + m_to_t(7.20)

    # 1. Aula 3 • Grupo 301 (8.00m x 7.20m = 160 x 144 texeles)
    a3_x1, a3_x2 = bx1 + 8, bx1 + 8 + m_to_t(8.00)
    fill_ceramic_tiles(draw, a3_x1, room_y1, a3_x2, room_y2, tile_t=8)
    draw_classroom_furniture(draw, a3_x1, room_y1, a3_x2, room_y2, board_top=True)

    # 2. Aula 4 • Grupo 401 (8.00m x 7.20m = 160 x 144 texeles)
    a4_x1, a4_x2 = a3_x2 + 8, a3_x2 + 8 + m_to_t(8.00)
    fill_ceramic_tiles(draw, a4_x1, room_y1, a4_x2, room_y2, tile_t=8)
    draw_classroom_furniture(draw, a4_x1, room_y1, a4_x2, room_y2, board_top=True)

    # 3. Biblioteca Escolar y Acervo (5.20m x 7.20m = 104 x 144 texeles)
    bib_x1, bib_x2 = a4_x2 + 8, a4_x2 + 8 + m_to_t(5.20)
    fill_ceramic_tiles(draw, bib_x1, room_y1, bib_x2, room_y2, tile_t=8)
    acervo_y2 = room_y1 + m_to_t(2.70)
    draw.rectangle([bib_x1, acervo_y2 - 3, bib_x2, acervo_y2 + 2], fill=PAL["green_bldg"], outline=PAL["outline"])
    for sy in [room_y1 + 6, room_y1 + 24]:
        draw.rectangle([bib_x1 + 8, sy, bib_x2 - 8, sy + 10], fill=PAL["wood_mahogany"], outline=PAL["outline"])
        for lx in range(bib_x1 + 10, bib_x2 - 10, 4):
            c = PAL["zebra_blue"] if lx % 8 == 0 else (PAL["brick_red"] if lx % 6 == 0 else PAL["curb_yellow"])
            draw.rectangle([lx, sy + 2, lx + 2, sy + 8], fill=c)
    for my in [acervo_y2 + 16, acervo_y2 + 48]:
        draw.rectangle([bib_x1 + 22, my, bib_x2 - 22, my + 18], fill=PAL["wood_desk"], outline=PAL["outline"])

    # 4. Sala de Maestros (7.80m x 7.20m = 156 x 144 texeles + vestíbulo oriente)
    mae_x1, mae_x2 = bib_x2 + 8, bx2 - 8
    fill_ceramic_tiles(draw, mae_x1, room_y1, mae_x2, room_y2, tile_t=8)
    draw.rectangle([mae_x1 + 32, room_y1 + 36, mae_x2 - 32, room_y2 - 36], fill=PAL["wood_mahogany"], outline=PAL["outline"])
    for sx in range(mae_x1 + 38, mae_x2 - 36, 16):
        draw.rectangle([sx, room_y1 + 28, sx + 10, room_y1 + 35], fill=PAL["outline"])
        draw.rectangle([sx, room_y2 - 35, sx + 10, room_y2 - 28], fill=PAL["outline"])
    draw.rectangle([mae_x1 + 14, room_y1 + 4, mae_x2 - 14, room_y1 + 16], fill=PAL["silver"], outline=PAL["outline"])

    # Fachada Sur 3/4 del Edificio B
    fy1, fy2 = room_y2, by2
    draw.rectangle([bx1, fy1, bx2, fy2], fill=PAL["green_bldg"], outline=PAL["outline"])
    for rx1, rx2 in [(a3_x1, a3_x2), (a4_x1, a4_x2), (bib_x1, bib_x2), (mae_x1, mae_x2)]:
        draw_door_3d(draw, rx1 + 6, fy2, w=18, h=28, color=PAL["white"])
        wx1, wx2 = rx1 + 28, rx2 - 6
        draw_window_grille(draw, wx1, fy1 + 6, wx2, fy1 + 22)
        draw_brick_wall_patch(draw, wx1, fy1 + 22, wx2, fy2)

    for cx in [bx1, a3_x2 + 2, a4_x2 + 2, bib_x2 + 2, bx2 - 8]:
        draw.rectangle([cx, fy1 - 2, cx + 8, fy2 + 4], fill=PAL["green_bldg_light"], outline=PAL["outline"])
        draw.rectangle([cx + 1, fy1 + 10, cx + 7, fy1 + 24], fill=PAL["roof_red"], outline=PAL["outline"])

    # Placas arquitectónicas del Edificio B
    draw_pixel_sign(draw, (a3_x1 + a3_x2) // 2, fy1 + 2, "AULA 3 - 301 (8X7.2M)", bg=PAL["green_bldg_dark"], fg=PAL["white"])
    draw_pixel_sign(draw, (a4_x1 + a4_x2) // 2, fy1 + 2, "AULA 4 - 401 (8X7.2M)", bg=PAL["green_bldg_dark"], fg=PAL["white"])
    draw_pixel_sign(draw, (bib_x1 + bib_x2) // 2, fy1 + 2, "BIBLIOTECA", bg=PAL["green_bldg_dark"], fg=PAL["white"])
    draw_pixel_sign(draw, (mae_x1 + mae_x2) // 2, fy1 + 2, "SALA DE MAESTROS", bg=PAL["green_bldg_dark"], fg=PAL["white"])

    # Andador Sur del Edificio B con Guarnición Amarilla, Escalones Amarillos y Rampa Azul/Blanca
    walk_y1, walk_y2 = by2, by2 + 78
    fill_concrete_slabs(draw, 16, walk_y1, tw - 16, walk_y2, slab_t=32)
    draw.rectangle([16, walk_y2 - 4, tw - 16, walk_y2], fill=PAL["curb_yellow"], outline=PAL["outline"])
    draw_zebra_ramp(draw, bx2 - 90, walk_y2 - 26, bx2 - 10, walk_y2 - 4, horizontal=True)
    for sx in range(bx2 - 120, bx2 - 92, 8):
        draw.rectangle([sx, walk_y1 + 6, sx + 7, walk_y2 - 6], fill=PAL["curb_yellow"], outline=PAL["outline"])
    draw_green_trash_drum(draw, a4_x1 + 2, fy2 + 6)

    # Jardín Mirador Sur (+4.00 m) y Vista a la Techumbre Blanca de Plaza Cívica
    gar_y1 = walk_y2 + 2
    draw.rectangle([24, gar_y1 + 6, tw - 24, gar_y1 + 36], fill=PAL["hedge_dark"], outline=PAL["outline"])
    draw.rectangle([28, gar_y1 + 10, tw - 28, gar_y1 + 32], fill=PAL["hedge_mid"])
    for px in range(80, tw - 60, 95):
        draw_pine_tree(draw, px, gar_y1 + 32, radius=18)

    draw_stone_retaining_wall(draw, 0, th - 46, tw - 1, th - 1)
    draw_white_railing(draw, 8, th - 46, tw - 8, height=12)
    draw.ellipse([220, th - 36, tw - 20, th + 30], fill=PAL["white"], outline=PAL["outline"])
    for rx in range(240, tw - 30, 12):
        draw.line([(rx, th - 32), (rx - 8, th - 2)], fill=PAL["silver"])

    draw_warp_pad(draw, tw - 45, (walk_y1 + walk_y2) // 2)

    save_pixel_art(img, "nivel_4_edificio_b.png")


# ==============================================================================
# ESCENARIO 5: EDIFICIO "C" (PLANTA BAJA ADMINISTRATIVA + PLANTA ALTA CÓMPUTO)
# Dimensiones reales: 36.00 m x 22.00 m = 1440 x 880 px (720 x 440 texeles)
# ==============================================================================
def generate_scenario_5():
    img, draw, tw, th = new_canvas(36.0, 22.0)
    fill_grass_texture(draw, 0, 0, tw - 1, th - 1)

    cx1 = 24
    # Abarcamos los 27.80 m de salones interiores + muros = 584 texeles, dejando el extremo oriente para el murete y rampa
    cx2 = cx1 + 584

    # 1. FRANJA SUPERIOR: PLANTA ALTA DEL EDIFICIO C (NPT +7.10 m)
    pa_y1, pa_y2 = 10, 126
    draw.rectangle([cx1, pa_y1, cx2, pa_y2], fill=PAL["mustard_dark"], outline=PAL["outline"])

    # 1.1 Taller de Cómputo (16.00m = 320 texeles = 640 px, 115.20 m²)
    comp_x1, comp_x2 = cx1 + 6, cx1 + 6 + m_to_t(16.00)
    fill_ceramic_tiles(draw, comp_x1, pa_y1 + 6, comp_x2, pa_y2 - 14, tile_t=8)
    draw.rectangle([comp_x1, pa_y1 + 4, comp_x2, pa_y1 + 10], fill=PAL["mustard"], outline=PAL["outline"])
    for bx in range(comp_x1 + 64, comp_x2, 64):
        draw.rectangle([bx - 2, pa_y1 + 4, bx + 2, pa_y2 - 14], fill=PAL["mustard_dark"])
    for row_y in [pa_y1 + 22, pa_y1 + 52, pa_y1 + 80]:
        for desk_x in range(comp_x1 + 16, comp_x2 - 28, 36):
            draw.rectangle([desk_x, row_y, desk_x + 28, row_y + 12], fill=PAL["wood_mahogany"], outline=PAL["outline"])
            draw.rectangle([desk_x + 3, row_y + 2, desk_x + 11, row_y + 7], fill=PAL["white"], outline=PAL["outline"])
            draw.rectangle([desk_x + 17, row_y + 2, desk_x + 25, row_y + 7], fill=PAL["white"], outline=PAL["outline"])
    draw_pixel_sign(draw, (comp_x1 + comp_x2) // 2, pa_y1 + 12, "PA: TALLER DE COMPUTO 16X7.2M (115.2 M2)", bg=PAL["mustard"], fg=PAL["outline"])

    # 1.2 Desembarque de Escalera PA (3.80m = 76 texeles)
    esc_pa_x1, esc_pa_x2 = comp_x2 + 6, comp_x2 + 6 + m_to_t(3.80)
    fill_ceramic_tiles(draw, esc_pa_x1, pa_y1 + 6, esc_pa_x2, pa_y2 - 14, tile_t=8)
    draw.rectangle([esc_pa_x1 + 10, pa_y1 + 18, esc_pa_x2 - 10, pa_y2 - 22], fill=PAL["mustard_dark"], outline=PAL["white"])
    for sy in range(pa_y1 + 22, pa_y2 - 24, 6):
        draw.rectangle([esc_pa_x1 + 12, sy, esc_pa_x2 - 12, sy + 4], fill=PAL["green_bldg"], outline=PAL["outline"])

    # 1.3 Aula 6 • Grupo 601 PA (8.00m = 160 texeles)
    a6_x1, a6_x2 = esc_pa_x2 + 6, cx2 - 6
    fill_ceramic_tiles(draw, a6_x1, pa_y1 + 6, a6_x2, pa_y2 - 14, tile_t=8)
    draw_classroom_furniture(draw, a6_x1, pa_y1 + 6, a6_x2, pa_y2 - 14, board_top=True)
    draw_pixel_sign(draw, (a6_x1 + a6_x2) // 2, pa_y1 + 12, "PA: AULA 6 - 601", bg=PAL["mustard"], fg=PAL["outline"])

    draw_brick_wall_patch(draw, cx1, pa_y2 - 14, cx2, pa_y2 - 4)
    draw_white_railing(draw, cx1 + 2, pa_y2, cx2 - 2, height=8)

    # 2. FRANJA MEDIA: PLANTA BAJA DEL EDIFICIO C (NPT +4.00 m)
    pb_y1, pb_y2 = 132, 256
    draw.rectangle([cx1, pb_y1, cx2, pb_y2], fill=PAL["green_bldg_dark"], outline=PAL["outline"])

    adm_x1, adm_x2 = cx1 + 6, comp_x2
    fill_ceramic_tiles(draw, adm_x1, pb_y1 + 6, adm_x2, pb_y2 - 24, tile_t=8)
    mid_adm_y = (pb_y1 + 6 + pb_y2 - 24) // 2
    draw.line([(adm_x1, mid_adm_y), (adm_x2, mid_adm_y)], fill=PAL["green_bldg_dark"], width=3)

    x_enf = adm_x1 + m_to_t(3.80)
    x_arc = x_enf + m_to_t(3.40)
    x_ss = x_arc + m_to_t(2.20)
    x_dir = x_ss + m_to_t(4.80)
    for vx in [x_enf, x_arc, x_ss, x_dir]:
        draw.line([(vx, pb_y1 + 6), (vx, pb_y2 - 24)], fill=PAL["green_bldg_dark"], width=3)

    # Camilla en Enfermería, escritorios en Tutorías, Dirección y Fotocopiado
    draw.rectangle([adm_x1 + 12, pb_y1 + 14, adm_x1 + 48, pb_y1 + 28], fill=PAL["white"], outline=PAL["outline"])
    draw.line([(adm_x1 + 26, pb_y1 + 18), (adm_x1 + 34, pb_y1 + 18)], fill=PAL["brick_red"], width=2)
    draw.line([(adm_x1 + 30, pb_y1 + 15), (adm_x1 + 30, pb_y1 + 21)], fill=PAL["brick_red"], width=2)
    draw.rectangle([adm_x1 + 16, mid_adm_y + 10, adm_x1 + 46, mid_adm_y + 24], fill=PAL["wood_desk"], outline=PAL["outline"])
    draw.rectangle([x_ss + 16, mid_adm_y + 8, x_ss + 56, mid_adm_y + 22], fill=PAL["wood_mahogany"], outline=PAL["outline"])
    draw.rectangle([x_dir + 10, mid_adm_y + 8, adm_x2 - 10, mid_adm_y + 22], fill=PAL["silver"], outline=PAL["outline"])

    # Núcleo de Escalera Principal PB (3.80m x 7.20m)
    esc_pb_x1, esc_pb_x2 = esc_pa_x1, esc_pa_x2
    fill_ceramic_tiles(draw, esc_pb_x1, pb_y1 + 6, esc_pb_x2, pb_y2 - 4, tile_t=8)
    for i, sy in enumerate(range(pb_y1 + 14, pb_y2 - 14, 7)):
        c = PAL["green_bldg"] if i % 2 == 0 else PAL["curb_yellow"]
        draw.rectangle([esc_pb_x1 + 8, sy, esc_pb_x2 - 8, sy + 5], fill=c, outline=PAL["outline"])
    draw.rectangle([(esc_pb_x1 + esc_pb_x2) // 2 - 2, pb_y1 + 12, (esc_pb_x1 + esc_pb_x2) // 2 + 2, pb_y2 - 12], fill=PAL["white"], outline=PAL["outline"])

    # Aula 5 • Grupo 501 PB (8.00m x 7.20m)
    a5_x1, a5_x2 = a6_x1, a6_x2
    fill_ceramic_tiles(draw, a5_x1, pb_y1 + 6, a5_x2, pb_y2 - 24, tile_t=8)
    draw_classroom_furniture(draw, a5_x1, pb_y1 + 6, a5_x2, pb_y2 - 24, board_top=True)

    # Fachada Sur PB
    fy1, fy2 = pb_y2 - 24, pb_y2
    draw.rectangle([cx1, fy1, esc_pb_x1, fy2], fill=PAL["green_bldg"], outline=PAL["outline"])
    draw.rectangle([esc_pb_x2, fy1, cx2, fy2], fill=PAL["green_bldg"], outline=PAL["outline"])

    for wx1, wx2 in [(adm_x1 + 24, x_enf - 4), (x_enf + 6, x_ss - 4), (x_ss + 24, x_dir - 4), (x_dir + 24, adm_x2 - 6), (a5_x1 + 26, a5_x2 - 6)]:
        draw_window_grille(draw, wx1, fy1 + 4, wx2, fy1 + 14)
        draw_brick_wall_patch(draw, wx1, fy1 + 14, wx2, fy2)

    for dx in [adm_x1 + 4, x_ss + 4, x_dir + 4, a5_x1 + 4]:
        draw_door_3d(draw, dx, fy2, w=18, h=22, color=PAL["white"])

    # Placas arquitectónicas de Planta Baja
    draw_pixel_sign(draw, (adm_x1 + x_enf) // 2, pb_y1 + 8, "ENFERMERIA", bg=PAL["white"], fg=PAL["brick_red"])
    draw_pixel_sign(draw, (x_enf + x_arc) // 2, pb_y1 + 8, "ARCHIVO", bg=PAL["white"], fg=PAL["outline"])
    draw_pixel_sign(draw, (x_arc + x_ss) // 2, pb_y1 + 8, "S.S.", bg=PAL["white"], fg=PAL["outline"])
    draw_pixel_sign(draw, (adm_x1 + x_enf) // 2, fy1 - 2, "ORIENTACION", bg=PAL["white"], fg=PAL["outline"])
    draw_pixel_sign(draw, (x_ss + x_dir) // 2, fy1 - 2, "DIRECCION CEMSAD", bg=PAL["white"], fg=PAL["outline"])
    draw_pixel_sign(draw, (x_dir + adm_x2) // 2, fy1 - 2, "FOTOCOPIADO", bg=PAL["white"], fg=PAL["brick_red"])
    draw_pixel_sign(draw, (a5_x1 + a5_x2) // 2, fy1 - 2, "AULA 5 - 501", bg=PAL["green_bldg_dark"], fg=PAL["white"])

    draw.rectangle([x_ss + 4, fy2 + 2, x_ss + 22, fy2 + 10], fill=PAL["stone_black"], outline=PAL["outline"])
    # Vitrina / exhibidor de trofeos en andador (foto Edificio C exhibidor.jpg)
    exh_x = x_dir + 4
    draw.rectangle([exh_x, fy2 + 2, exh_x + 18, fy2 + 10], fill=PAL["white"], outline=PAL["outline"])
    draw.rectangle([exh_x + 2, fy2 + 3, exh_x + 16, fy2 + 8], fill=PAL["window_glass"])
    draw.point((exh_x + 6, fy2 + 5), fill=PAL["curb_yellow"])
    draw.point((exh_x + 12, fy2 + 5), fill=PAL["curb_yellow"])
    draw_green_trash_drum(draw, a5_x1 + 30, fy2 + 4)

    # 3. ANDADOR PRINCIPAL, JARDÍN DEL ASTA BANDERA Y RAMPA A LA CANCHA
    walk_y1, walk_y2 = pb_y2, pb_y2 + 68
    fill_concrete_slabs(draw, 16, walk_y1, tw - 16, walk_y2, slab_t=32)
    draw.rectangle([16, walk_y2 - 4, tw - 140, walk_y2], fill=PAL["curb_yellow"], outline=PAL["outline"])

    # Murete verde claro y Rampa de Enlace Edificio C — Cancha Deportiva (foto 095732.jpg y 095734.jpg)
    draw.rectangle([cx2 + 4, pb_y1 + 70, tw - 20, walk_y1 + 8], fill=PAL["green_mint_wall"], outline=PAL["outline"])
    draw_zebra_ramp(draw, tw - 150, walk_y1 + 12, tw - 18, walk_y2 + 24, horizontal=True)

    # Jardín del Asta Bandera (el mástil queda dentro del jardín sin cruzar el pasillo)
    asta_cx, asta_cy = 240, walk_y2 + 64
    draw.rectangle([asta_cx - 18, asta_cy - 6, asta_cx + 18, asta_cy + 12], fill=PAL["white"], outline=PAL["outline"])
    draw.rectangle([asta_cx - 13, asta_cy - 11, asta_cx + 13, asta_cy + 7], fill=PAL["silver"], outline=PAL["outline"])
    draw.rectangle([asta_cx - 8, asta_cy - 15, asta_cx + 8, asta_cy + 2], fill=PAL["white"], outline=PAL["outline"])
    draw.rectangle([asta_cx - 2, walk_y2 + 6, asta_cx + 2, asta_cy - 12], fill=PAL["white"], outline=PAL["outline"])

    draw_pine_tree(draw, asta_cx + 56, asta_cy - 10, radius=24)
    draw_pine_tree(draw, 110, asta_cy - 8, radius=18)
    draw_pine_tree(draw, 440, asta_cy - 8, radius=18)
    draw_stone_retaining_wall(draw, 0, th - 32, tw - 1, th - 1)
    draw_white_railing(draw, 8, th - 32, tw - 8, height=10)

    draw_warp_pad(draw, tw - 42, walk_y1 + 38)

    save_pixel_art(img, "nivel_5_edificio_c_computo.png")


# ==============================================================================
# ESCENARIO 6: CANCHA DE USOS MÚLTIPLES, ZONA DE BANCAS Y BARDA ESTE 52M
# Dimensiones reales: 36.00 m x 22.50 m = 1440 x 900 px (720 x 450 texeles)
# ==============================================================================
def generate_scenario_6():
    img, draw, tw, th = new_canvas(36.0, 22.5)
    fill_grass_texture(draw, 0, 0, tw - 1, th - 1)

    draw_zebra_ramp(draw, 8, 150, 68, 210, horizontal=True)

    cx1, cy1 = 68, 24
    cw, ch = m_to_t(30.00), m_to_t(16.00)
    cx2, cy2 = cx1 + cw, cy1 + ch

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

    draw.rectangle([in_x1, mid_y - 44, in_x1 + 85, mid_y + 44], outline=PAL["zebra_blue"], width=2)
    draw.rectangle([in_x2 - 85, mid_y - 44, in_x2, mid_y + 44], outline=PAL["zebra_blue"], width=2)

    for side, bx in [(-1, in_x1 + 8), (1, in_x2 - 8)]:
        draw.rectangle([bx - 4, mid_y - 24, bx + 4, mid_y + 24], fill=PAL["gate_green"], outline=PAL["outline"])
        tb_x = bx + (-6 if side == 1 else 2)
        draw.rectangle([tb_x - 6, mid_y - 18, tb_x + 8, mid_y + 8], fill=PAL["green_bldg"], outline=PAL["outline"])
        draw.rectangle([tb_x - 3, mid_y - 11, tb_x + 5, mid_y - 1], fill=PAL["curb_yellow"], outline=PAL["outline"])
        draw.ellipse([tb_x - 2, mid_y - 3, tb_x + 4, mid_y + 3], fill=PAL["brick_red"], outline=PAL["outline"])

    draw_pixel_sign(draw, mid_x, cy1 - 7, "CANCHA DE USOS MULTIPLES 30X18M (540 M2)", bg=PAL["green_bldg_dark"], fg=PAL["white"])

    # Podio Dorado de Victoria Final (Gran Copa CEMSaD 22 ENTHAVI)
    pod_x, pod_y = in_x2 - 55, mid_y
    draw.rectangle([pod_x - 32, pod_y - 24, pod_x + 28, pod_y + 24], fill=PAL["guinda"], outline=PAL["curb_yellow"])
    draw.ellipse([pod_x - 18, pod_y - 14, pod_x + 18, pod_y + 14], fill=PAL["curb_yellow"], outline=PAL["outline"])
    draw.ellipse([pod_x - 12, pod_y - 9, pod_x + 12, pod_y + 9], fill=PAL["white"])

    # ZONA DE BANCAS, MESAS DE ESTUDIO Y CONVIVENCIA (26.00m x 10.00m)
    conv_y1, conv_y2 = cy2 + 12, th - 14
    fill_concrete_slabs(draw, 90, conv_y1, 610, conv_y2, slab_t=36)
    draw.rectangle([90, conv_y1, 610, conv_y1 + 4], fill=PAL["curb_yellow"], outline=PAL["outline"])
    draw_pixel_sign(draw, 350, conv_y1 + 10, "ZONA DE BANCAS Y CONVIVENCIA (260 M2)", bg=PAL["guinda"], fg=PAL["white"])

    for mx in [160, 290]:
        draw.rectangle([mx - 22, conv_y1 + 22, mx + 22, conv_y1 + 30], fill=PAL["wood_desk"], outline=PAL["outline"])
        draw.rectangle([mx - 22, conv_y1 + 58, mx + 22, conv_y1 + 66], fill=PAL["wood_desk"], outline=PAL["outline"])
        draw.rectangle([mx - 24, conv_y1 + 34, mx + 24, conv_y1 + 54], fill=PAL["wood_mahogany"], outline=PAL["outline"])
    for cmx in [420, 535]:
        ccy = conv_y1 + 44
        for ang in [0, 90, 180, 270]:
            rad = math.radians(ang)
            bx = int(cmx + math.cos(rad) * 20)
            by = int(ccy + math.sin(rad) * 18)
            draw.ellipse([bx - 6, by - 5, bx + 6, by + 5], fill=PAL["zebra_blue"], outline=PAL["outline"])
        draw.ellipse([cmx - 13, ccy - 11, cmx + 13, ccy + 11], fill=PAL["white"], outline=PAL["outline"])

    draw_pine_tree(draw, 50, conv_y1 + 40, radius=18)
    draw_pine_tree(draw, 645, conv_y1 + 40, radius=18)

    # BARDA PERIMETRAL ORIENTE ACOTADA (52.00 m / 5,200 cm)
    draw.rectangle([tw - 22, 8, tw - 8, th - 8], fill=PAL["terracota"], outline=PAL["outline"])
    for by in range(12, th - 12, 52):
        draw.rectangle([tw - 24, by, tw - 6, by + 7], fill=PAL["guinda"], outline=PAL["outline"])
    draw.line([(tw - 30, 16), (tw - 30, th - 16)], fill=PAL["brick_red"], width=2)
    draw_pixel_sign(draw, tw - 48, mid_y, "52.00M", bg=PAL["brick_red"], fg=PAL["white"])

    save_pixel_art(img, "nivel_6_cancha_usos_multiples.png")


if __name__ == "__main__":
    generate_scenario_1()
    generate_scenario_2()
    generate_scenario_3()
    generate_scenario_4()
    generate_scenario_5()
    generate_scenario_6()
    print("¡Los 6 escenarios a escala real (1m = 40px) de CEMSaD 22 ENTHAVI fueron generados con éxito!")
