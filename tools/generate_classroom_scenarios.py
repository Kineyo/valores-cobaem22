#!/usr/bin/env python3
"""
tools/generate_classroom_scenarios.py
Generador determinista de alta calidad de los 6 mapas de salones interiores (CEMSaD 22 ENTHAVI)
a escala real (1m = 40px) con dimensiones de 800x480 px (20m x 12m).

VERSIÓN CINEMATOGRÁFICA Y ARQUITECTÓNICA:
- Sombras arrojadas 3/4 multicapa (núcleo y penumbra).
- Oclusión ambiental perimetral y en esquinas.
- Haces de luz solar volumétrica desde las ventanas altas.
- Pisos de alta definición: parquet de madera con vetas, loseta vinílica con juntas y reflejos,
  duela deportiva con reflejos de barniz y líneas reglamentarias.
- Mobiliario con extrusión 3D (bisel, costados oscuros, patas metálicas con sombra).
- Microdetalles: relojes de pared, mochilas escolares colgadas, libros coloridos,
  monitores con código/datos, cables canaletas, matraces químicos con líquidos brillantes.
"""

import os
import math
from PIL import Image, ImageDraw

SALONES_DIR = "escenarios/salones"
os.makedirs(SALONES_DIR, exist_ok=True)
WIDTH = 800
HEIGHT = 480


def create_base_canvas():
    return Image.new("RGBA", (WIDTH, HEIGHT), (225, 228, 232, 255))


def apply_ambient_occlusion(img):
    """Aplica oclusión ambiental perimetral (esquinas oscuras y contacto con muros)."""
    ao = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    d = ImageDraw.Draw(ao)

    # Sombra superior bajo muro norte
    for y in range(80, 115):
        alpha = int(95 * (1.0 - (y - 80) / 35.0))
        d.line([(36, y), (WIDTH - 36, y)], fill=(8, 6, 12, alpha))

    # Sombra muro sur
    for y in range(HEIGHT - 65, HEIGHT - 36):
        alpha = int(75 * ((y - (HEIGHT - 65)) / 29.0))
        d.line([(36, y), (WIDTH - 36, y)], fill=(8, 6, 12, alpha))

    # Sombra muro poniente
    for x in range(36, 75):
        alpha = int(85 * (1.0 - (x - 36) / 39.0))
        d.line([(x, 80), (x, HEIGHT - 36)], fill=(8, 6, 12, alpha))

    # Sombra muro oriente
    for x in range(WIDTH - 75, WIDTH - 36):
        alpha = int(85 * ((x - (WIDTH - 75)) / 39.0))
        d.line([(x, 80), (x, HEIGHT - 36)], fill=(8, 6, 12, alpha))

    # Esquinas reforzadas (viñeta de penumbra)
    corners = [
        (36, 80, 80, 80),
        (WIDTH - 116, 80, 80, 80),
        (36, HEIGHT - 116, 80, 80),
        (WIDTH - 116, HEIGHT - 116, 80, 80)
    ]
    for cx, cy, cw, ch in corners:
        for r in range(40):
            d.ellipse([cx - r, cy - r, cx + cw + r, cy + ch + r], fill=(5, 4, 8, 3))

    return Image.alpha_composite(img, ao)


def apply_sunbeams(img, windows):
    """Proyecta haces de luz natural en diagonal desde las ventanas superiores."""
    beams = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    d = ImageDraw.Draw(beams)

    for wx0, wx1 in windows:
        # Trapecio de haz de luz proyectado hacia el sureste
        poly = [
            (wx0, 78),
            (wx1, 78),
            (wx1 + 160, HEIGHT - 60),
            (wx0 + 130, HEIGHT - 60)
        ]
        d.polygon(poly, fill=(255, 252, 235, 22))
        # Núcleo más brillante
        poly_core = [
            (wx0 + 15, 78),
            (wx1 - 15, 78),
            (wx1 + 120, HEIGHT - 120),
            (wx0 + 145, HEIGHT - 120)
        ]
        d.polygon(poly_core, fill=(255, 255, 245, 14))

    return Image.alpha_composite(img, beams)


def draw_room_walls(d, wall_col=(135, 28, 42), trim_col=(220, 185, 55)):
    """Dibuja muros perimetrales con zoclo dorado, puerta poniente y molduras."""
    wall_h = 80
    w = WIDTH
    h = HEIGHT

    # Muro norte
    d.rectangle([0, 0, w, wall_h], fill=wall_col)
    # Franja superior de techo con cornisa
    d.rectangle([0, 0, w, 8], fill=(min(255, wall_col[0] + 35), min(255, wall_col[1] + 20), min(255, wall_col[2] + 20)))
    d.line([(0, 8), (w, 8)], fill=(min(255, wall_col[0] + 55), min(255, wall_col[1] + 35), min(255, wall_col[2] + 35)), width=1)

    # Zoclo / Moldura dorada institucional
    d.rectangle([0, wall_h - 9, w, wall_h], fill=trim_col)
    d.line([(0, wall_h - 9), (w, wall_h - 9)], fill=(255, 240, 140), width=1)
    d.line([(0, wall_h), (w, wall_h)], fill=(130, 95, 20), width=1)

    # Muros laterales
    col_lat = (max(0, wall_col[0] - 25), max(0, wall_col[1] - 8), max(0, wall_col[2] - 8))
    d.rectangle([0, 0, 36, h], fill=col_lat)
    d.rectangle([w - 36, 0, w, h], fill=col_lat)

    # Muro sur con zoclo
    col_sur = (max(0, wall_col[0] - 35), max(0, wall_col[1] - 12), max(0, wall_col[2] - 12))
    d.rectangle([0, h - 36, w, h], fill=col_sur)
    d.rectangle([0, h - 42, w, h - 36], fill=trim_col)
    d.line([(0, h - 42), (w, h - 42)], fill=(255, 240, 140), width=1)

    # Puerta de entrada en pared poniente (y=330 a 430)
    d.rectangle([0, 330, 38, 432], fill=(45, 50, 60))
    d.rectangle([4, 334, 34, 428], fill=(135, 90, 55))
    d.line([(4, 334), (34, 334)], fill=(175, 125, 85), width=2)
    # Ventanilla de puerta con cristal
    d.rectangle([10, 348, 28, 382], fill=(160, 210, 240), outline=(50, 55, 65))
    d.line([(12, 352), (24, 376)], fill=(255, 255, 255), width=2)
    # Pomo de latón
    d.ellipse([26, 386, 31, 391], fill=(230, 190, 50), outline=(130, 95, 20))

    # Reloj escolar oficial en muro norte (x=195, y=22)
    d.ellipse([185, 18, 221, 54], fill=(245, 245, 250), outline=(180, 140, 60), width=2)
    d.ellipse([187, 20, 219, 52], outline=(140, 145, 155))
    d.point((203, 36), fill=(40, 45, 55))
    d.line([(203, 36), (203, 25)], fill=(30, 35, 45), width=2) # Horario a las 12
    d.line([(203, 36), (213, 36)], fill=(200, 30, 40), width=1) # Minutero


def draw_chalkboard(d, x=220, y=14, w=360, h=52, bg_col=(25, 60, 40)):
    """Pizarrón con marco 3D, sombra, lemas y bandeja de tizas."""
    # Sombra del pizarrón
    d.rectangle([x - 2, y + h + 3, x + w + 8, y + h + 8], fill=(15, 10, 16))
    # Marco de madera
    d.rectangle([x - 4, y - 4, x + w + 4, y + h + 4], fill=(170, 125, 70), outline=(95, 65, 30))
    d.line([(x - 4, y - 4), (x + w + 4, y - 4)], fill=(225, 180, 115), width=2)
    # Superficie
    d.rectangle([x, y, x + w, y + h], fill=bg_col)
    # Franja superior de iluminación
    d.line([(x + 2, y + 2), (x + w - 2, y + 2)], fill=(min(255, bg_col[0] + 30), min(255, bg_col[1] + 35), min(255, bg_col[2] + 30)), width=1)

    # Texto tiza blanca (Lema de Valores)
    d.line([(x + 20, y + 14), (x + 150, y + 14)], fill=(245, 248, 250), width=2)
    d.line([(x + 20, y + 22), (x + 110, y + 22)], fill=(245, 248, 250), width=1)
    d.line([(x + 20, y + 30), (x + 135, y + 30)], fill=(245, 248, 250), width=1)
    # Ecuación o esquema en tiza amarilla
    d.rectangle([x + 200, y + 12, x + 250, y + 38], outline=(255, 235, 110), width=1)
    d.line([(x + 200, y + 25), (x + 250, y + 25)], fill=(255, 235, 110))
    d.line([(x + 225, y + 12), (x + 225, y + 38)], fill=(255, 235, 110))

    # Bandeja inferior con borrador y tizas
    d.rectangle([x, y + h, x + w, y + h + 4], fill=(190, 150, 90), outline=(100, 70, 35))
    d.rectangle([x + 35, y + h - 2, x + 58, y + h + 3], fill=(70, 45, 25)) # Borrador
    d.rectangle([x + 65, y + h, x + 76, y + h + 2], fill=(255, 255, 255)) # Gis blanco
    d.rectangle([x + 80, y + h, x + 92, y + h + 2], fill=(255, 220, 80)) # Gis amarillo
    d.rectangle([x + 96, y + h, x + 108, y + h + 2], fill=(120, 210, 245)) # Gis azul


def draw_teacher_desk(d, x=340, y=105, w=120, h=50):
    """Escritorio del docente con sombra arrojada profunda, laptop, carpetas y taza."""
    # Sombra arrojada 3/4 profunda
    d.rectangle([x + 6, y + h, x + w + 14, y + h + 12], fill=(14, 12, 18))
    d.rectangle([x + 10, y + h + 12, x + w + 10, y + h + 16], fill=(28, 24, 32))

    # Extrusión 3D lateral derecha del escritorio
    d.rectangle([x + w, y + 3, x + w + 6, y + h + 2], fill=(75, 50, 30))
    # Cuerpo frontal del escritorio
    d.rectangle([x - 2, y - 2, x + w + 2, y + h + 2], fill=(55, 35, 20))
    d.rectangle([x, y, x + w, y + h], fill=(145, 95, 55))
    d.line([(x, y), (x + w, y)], fill=(195, 145, 95), width=2) # Bisel de luz superior

    # Cajonera derecha
    d.rectangle([x + w - 35, y + 6, x + w - 6, y + h - 6], fill=(115, 75, 40), outline=(65, 45, 25))
    d.line([(x + w - 24, y + 18), (x + w - 16, y + 18)], fill=(225, 185, 60), width=2)
    d.line([(x + w - 24, y + 32), (x + w - 16, y + 32)], fill=(225, 185, 60), width=2)

    # Laptop / Computadora del docente
    d.rectangle([x + 18, y + 10, x + 52, y + 36], fill=(45, 50, 60), outline=(25, 30, 40))
    d.rectangle([x + 20, y + 12, x + 50, y + 26], fill=(90, 195, 240)) # Pantalla encendida
    d.rectangle([x + 20, y + 28, x + 50, y + 34], fill=(175, 180, 190)) # Teclado

    # Carpetas de calificaciones guinda institucional COBAEM
    d.rectangle([x + 62, y + 10, x + 88, y + 38], fill=(245, 245, 250), outline=(175, 175, 185))
    d.rectangle([x + 92, y + 12, x + 110, y + 30], fill=(175, 25, 45), outline=(95, 15, 25)) # Carpeta oficial
    # Bolígrafo y taza escolar
    d.line([(x + 85, y + 15), (x + 85, y + 32)], fill=(220, 40, 50), width=2)
    d.ellipse([x + 58, y + 16, x + 66, y + 24], fill=(240, 240, 245), outline=(160, 160, 170))

    # Silla ergonómica del docente al norte con sombra
    d.ellipse([x + 44, y - 10, x + 76, y - 2], fill=(15, 12, 18))
    d.rectangle([x + 46, y - 22, x + 74, y - 6], fill=(45, 50, 60), outline=(25, 28, 35))
    d.rectangle([x + 50, y - 28, x + 70, y - 22], fill=(35, 40, 50))


def generate_salon_1():
    """Salón 1: Laboratorio de Usos Múltiples (Edificio D)."""
    img = create_base_canvas()
    d = ImageDraw.Draw(img)

    # Piso de loseta vinílica de laboratorio (gris perla y marfil con juntas biseladas)
    tile_size = 40
    for y in range(80, HEIGHT - 36, tile_size):
        for x in range(36, WIDTH - 36, tile_size):
            col = (222, 228, 234) if ((x // tile_size) + (y // tile_size)) % 2 == 0 else (210, 218, 226)
            d.rectangle([x, y, x + tile_size - 1, y + tile_size - 1], fill=col, outline=(185, 195, 205))
            if ((x * 11 + y * 7) % 19) == 0:
                d.point((x + 2, y + 2), fill=(255, 255, 255)) # Destellos de piso encerado

    draw_room_walls(d, (120, 25, 38), (225, 190, 55))
    draw_chalkboard(d, 220, 14, 360, 52, (25, 60, 40))

    # Carteles de laboratorio: Tabla periódica y normas de seguridad
    d.rectangle([75, 16, 180, 64], fill=(248, 250, 255), outline=(45, 120, 180), width=2)
    for px in range(80, 175, 9):
        for py in range(22, 60, 7):
            col_elem = (230, 120, 40) if px < 105 else ((45, 140, 215) if px < 145 else (50, 175, 90))
            d.rectangle([px, py, px + 7, py + 5], fill=col_elem)

    # Reglas de seguridad química (amarillo/negro)
    d.rectangle([620, 16, 725, 64], fill=(255, 235, 170), outline=(210, 130, 30), width=2)
    d.polygon([(670, 22), (660, 40), (680, 40)], fill=(220, 30, 40)) # Señal de precaución

    draw_teacher_desk(d, 340, 105, 120, 50)

    # 4 Mesas largas de laboratorio con tarjas, mecheros Bunsen, matraces y sombras
    benches = [
        (100, 180, 180, 55),
        (100, 275, 180, 55),
        (310, 275, 180, 55),
        (100, 365, 180, 50),
    ]
    for bx, by, bw, bh in benches:
        # Sombra arrojada 3/4 profunda
        d.rectangle([bx + 6, by + bh, bx + bw + 12, by + bh + 12], fill=(16, 20, 26))
        # Extrusión 3D
        d.rectangle([bx + bw, by + 3, bx + bw + 6, by + bh + 2], fill=(45, 50, 60))
        d.rectangle([bx - 2, by - 2, bx + bw + 2, by + bh + 2], fill=(40, 45, 55))
        d.rectangle([bx, by, bx + bw, by + bh], fill=(85, 95, 110))
        d.line([(bx, by), (bx + bw, by)], fill=(145, 160, 180), width=2) # Luz superior

        # Tarja de acero inoxidable
        d.rectangle([bx + 14, by + 10, bx + 48, by + 42], fill=(175, 185, 200), outline=(120, 130, 145))
        d.line([(bx + 22, by + 12), (bx + 22, by + 26)], fill=(110, 120, 130), width=2) # Grifo cuello de ganso
        d.ellipse([bx + 27, by + 23, bx + 35, by + 29], fill=(130, 140, 150)) # Desagüe

        # Mechero Bunsen y gradilla con tubos de ensayo
        d.rectangle([bx + 62, by + 28, bx + 72, by + 40], fill=(70, 75, 85)) # Mechero
        d.line([(bx + 67, by + 24), (bx + 67, by + 28)], fill=(60, 180, 250), width=3) # Llama azul
        d.rectangle([bx + 85, by + 14, bx + 115, by + 38], fill=(160, 115, 75), outline=(90, 60, 35)) # Gradilla
        for ty in range(bx + 88, bx + 114, 6):
            d.rectangle([ty, by + 12, ty + 3, by + 34], fill=(240, 120, 50) if ty % 12 == 0 else (60, 200, 220))

        # Matraces de fondo plano y probetas graduadas
        d.ellipse([bx + 130, by + 14, bx + 154, by + 38], fill=(50, 190, 240), outline=(20, 90, 150))
        d.point((bx + 136, by + 20), fill=(255, 255, 255))
        d.ellipse([bx + 158, by + 16, bx + 172, by + 36], fill=(140, 220, 60), outline=(60, 140, 20))

    # Círculo de área de confrontación escolar
    d.ellipse([510, 210, 690, 390], outline=(220, 180, 195), width=2)
    d.ellipse([516, 216, 684, 384], outline=(240, 210, 220), width=1)

    img = apply_ambient_occlusion(img)
    img = apply_sunbeams(img, [(75, 180), (620, 725)])
    return img.convert("RGB")


def generate_salon_2():
    """Salón 2: Aula 1 — Edificio A."""
    img = create_base_canvas()
    d = ImageDraw.Draw(img)

    # Piso de mosaico escolar beige y arena
    tile_size = 40
    for y in range(80, HEIGHT - 36, tile_size):
        for x in range(36, WIDTH - 36, tile_size):
            col = (235, 230, 220) if ((x // tile_size) + (y // tile_size)) % 2 == 0 else (224, 218, 208)
            d.rectangle([x, y, x + tile_size - 1, y + tile_size - 1], fill=col, outline=(198, 192, 182))

    draw_room_walls(d, (135, 28, 42), (220, 185, 55))
    draw_chalkboard(d, 220, 14, 360, 52, (248, 250, 252)) # Pizarrón blanco moderno

    # Ventanales panorámicos con vista al patio escolar y cielo
    windows = [(75, 185), (615, 725)]
    for wx0, wx1 in windows:
        d.rectangle([wx0, 14, wx1, 66], fill=(145, 205, 240), outline=(235, 235, 245), width=2)
        d.line([(wx0 + 15, 18), (wx0 + 45, 62)], fill=(255, 255, 255), width=2)
        d.line([(wx0 + 55, 14), (wx0 + 55, 66)], fill=(215, 215, 225), width=2)

    draw_teacher_desk(d, 340, 105, 120, 50)

    # 6 Pupitres dobles con mochilas colgadas, libretas y sombras 3D profundas
    desks = [
        (90, 185, 100, 48), (210, 185, 100, 48),
        (90, 265, 100, 48), (210, 265, 100, 48),
        (90, 345, 100, 48), (210, 345, 100, 48),
    ]
    for dx, dy, dw, dh in desks:
        # Sombra arrojada 3/4 profunda
        d.rectangle([dx + 6, dy + dh, dx + dw + 10, dy + dh + 10], fill=(18, 16, 22))
        # Extrusión 3D
        d.rectangle([dx + dw, dy + 2, dx + dw + 4, dy + dh + 1], fill=(85, 55, 35))
        d.rectangle([dx - 2, dy - 2, dx + dw + 2, dy + dh + 2], fill=(60, 40, 25))
        d.rectangle([dx, dy, dx + dw, dy + dh], fill=(175, 125, 75))
        d.line([(dx, dy), (dx + dw, dy)], fill=(225, 175, 120), width=2)

        # Libreta escolar abierta con renglones
        d.rectangle([dx + 12, dy + 8, dx + 38, dy + 32], fill=(250, 250, 255), outline=(160, 160, 170))
        d.line([(dx + 25, dy + 8), (dx + 25, dy + 32)], fill=(200, 60, 70), width=1) # Espiral
        for ly in range(dy + 12, dy + 30, 4):
            d.line([(dx + 14, ly), (dx + 23, ly)], fill=(70, 110, 180), width=1)
            d.line([(dx + 27, ly), (dx + 36, ly)], fill=(70, 110, 180), width=1)

        # Mochila colgada en la silla lateral
        d.rectangle([dx + 65, dy + 10, dx + 92, dy + 36], fill=(35, 85, 155), outline=(20, 50, 100))
        d.rectangle([dx + 70, dy + 14, dx + 87, dy + 24], fill=(220, 50, 60)) # Bolsillo exterior

    d.ellipse([510, 210, 690, 390], outline=(225, 195, 205), width=2)
    img = apply_ambient_occlusion(img)
    img = apply_sunbeams(img, windows)
    return img.convert("RGB")


def generate_salon_3():
    """Salón 3: Sala Cívica de Asambleas."""
    img = create_base_canvas()
    d = ImageDraw.Draw(img)

    # Piso de duela de madera pulida / caoba en espiga
    tile_size = 40
    for y in range(80, HEIGHT - 36, tile_size):
        for x in range(36, WIDTH - 36, tile_size):
            col = (195, 145, 95) if ((x // tile_size) + (y // tile_size)) % 2 == 0 else (180, 130, 82)
            d.rectangle([x, y, x + tile_size - 1, y + tile_size - 1], fill=col, outline=(155, 110, 68))
            # Veta de madera sutil
            d.line([(x + 2, y + 10), (x + tile_size - 4, y + 14)], fill=(160, 115, 70), width=1)
            d.line([(x + 2, y + 26), (x + tile_size - 4, y + 30)], fill=(160, 115, 70), width=1)

    draw_room_walls(d, (115, 24, 35), (230, 195, 55))

    # Estandarte central COBAEM con escudo bordado en oro
    d.rectangle([270, 10, 530, 70], fill=(135, 28, 42), outline=(230, 195, 55), width=3)
    d.ellipse([370, 14, 430, 66], fill=(230, 195, 55), outline=(140, 100, 20))
    d.line([(270, 66), (530, 66)], fill=(230, 195, 55), width=2)

    # Astas de bandera a los costados del presidium (Bandera de México y COBAEM)
    d.rectangle([95, 12, 135, 68], fill=(18, 115, 55))
    d.rectangle([135, 12, 175, 68], fill=(250, 250, 250))
    d.rectangle([175, 12, 215, 68], fill=(210, 28, 38))
    d.line([(93, 8), (93, 72)], fill=(215, 180, 50), width=3)

    # Estrado cívico elevado con moldura dorada y escalón
    d.rectangle([324, 155, 476, 168], fill=(16, 12, 18)) # Sombra del estrado
    d.rectangle([320, 92, 480, 155], fill=(115, 75, 45), outline=(65, 40, 20))
    d.line([(320, 92), (480, 92)], fill=(175, 125, 80), width=2)
    # Podio de orador central con escudo
    d.rectangle([380, 100, 420, 142], fill=(160, 115, 68), outline=(85, 55, 30))
    d.ellipse([392, 112, 408, 128], fill=(230, 190, 50))
    d.line([(398, 100), (402, 94)], fill=(180, 180, 190), width=2) # Micrófono

    # Bloques de butacas / sillas para asambleas
    for r in range(3):
        for c in range(2):
            sx = 90 + c * 115
            sy = 195 + r * 75
            d.rectangle([sx + 4, sy + 45, sx + 98, sy + 52], fill=(16, 14, 20))
            d.rectangle([sx, sy, sx + 95, sy + 45], fill=(65, 70, 80), outline=(38, 42, 50))
            d.rectangle([sx + 4, sy + 4, sx + 91, sy + 38], fill=(130, 30, 45), outline=(75, 18, 28)) # Tapizado vino

    d.ellipse([510, 210, 690, 390], outline=(225, 185, 150), width=2)
    img = apply_ambient_occlusion(img)
    return img.convert("RGB")


def generate_salon_4():
    """Salón 4: Biblioteca Escolar (Edificio B)."""
    img = create_base_canvas()
    d = ImageDraw.Draw(img)

    # Piso de madera noble cálida con vetas
    tile_size = 40
    for y in range(80, HEIGHT - 36, tile_size):
        for x in range(36, WIDTH - 36, tile_size):
            col = (210, 185, 150) if ((x // tile_size) + (y // tile_size)) % 2 == 0 else (195, 172, 138)
            d.rectangle([x, y, x + tile_size - 1, y + tile_size - 1], fill=col, outline=(170, 148, 115))

    draw_room_walls(d, (110, 35, 45), (215, 180, 60))

    # Estanterías altas empotradas en muro norte con libros de colores
    for i in range(5):
        bx = 70 + i * 135
        d.rectangle([bx, 10, bx + 120, 72], fill=(95, 55, 30), outline=(55, 30, 15), width=2)
        for shelf_y in [28, 44, 60]:
            d.line([bx + 4, shelf_y, bx + 116, shelf_y], fill=(155, 105, 60), width=2)
            # Lomos de libros
            for lx in range(bx + 6, bx + 114, 7):
                book_col = [(180, 50, 45), (45, 110, 175), (50, 150, 85), (220, 175, 45), (120, 65, 140)][(lx + shelf_y) % 5]
                d.rectangle([lx, shelf_y - 12, lx + 5, shelf_y - 1], fill=book_col)

    draw_teacher_desk(d, 340, 105, 120, 50)

    # 3 Estanterías dobles centrales con sombra arrojada profunda
    shelves = [
        (85, 180, 50, 210),
        (190, 180, 50, 210),
        (295, 180, 50, 210),
    ]
    for sx, sy, sw, sh in shelves:
        # Sombra profunda
        d.rectangle([sx + 6, sy + sh, sx + sw + 12, sy + sh + 12], fill=(16, 14, 20))
        d.rectangle([sx + sw, sy + 3, sx + sw + 6, sy + sh + 2], fill=(60, 35, 18))
        d.rectangle([sx - 2, sy - 2, sx + sw + 2, sy + sh + 2], fill=(50, 28, 14))
        d.rectangle([sx, sy, sx + sw, sy + sh], fill=(115, 70, 35))
        d.line([(sx, sy), (sx + sw, sy)], fill=(165, 115, 70), width=2)

        # Entrepaños con libros en ambas caras
        for by in range(sy + 8, sy + sh - 14, 18):
            d.rectangle([sx + 5, by, sx + sw - 5, by + 13], fill=(80, 45, 22))
            for kx in range(sx + 7, sx + sw - 7, 6):
                b_col = [(210, 65, 60), (55, 130, 200), (60, 175, 100), (235, 185, 50)][(kx + by) % 4]
                d.rectangle([kx, by + 1, kx + 4, by + 12], fill=b_col)

    # Zona de lectura oriente
    d.ellipse([510, 210, 690, 390], outline=(205, 165, 135), width=2)
    img = apply_ambient_occlusion(img)
    return img.convert("RGB")


def generate_salon_5():
    """Salón 5: Taller de Cómputo (Edificio C)."""
    img = create_base_canvas()
    d = ImageDraw.Draw(img)

    # Piso antiestático de baldosas gris frío / azul pizarra con cuadrícula técnica
    tile_size = 40
    for y in range(80, HEIGHT - 36, tile_size):
        for x in range(36, WIDTH - 36, tile_size):
            col = (195, 205, 218) if ((x // tile_size) + (y // tile_size)) % 2 == 0 else (182, 194, 208)
            d.rectangle([x, y, x + tile_size - 1, y + tile_size - 1], fill=col, outline=(155, 168, 185))

    draw_room_walls(d, (125, 25, 40), (220, 185, 50))
    draw_chalkboard(d, 220, 14, 360, 52, (20, 35, 55)) # Pizarrón digital

    # Racks de Servidores con indicadores LED parpadeantes
    d.rectangle([75, 12, 185, 72], fill=(32, 36, 44), outline=(55, 175, 220), width=2)
    for led_y in range(20, 64, 7):
        d.rectangle([85, led_y, 110, led_y + 3], fill=(45, 230, 130)) # LED verde
        d.rectangle([115, led_y, 135, led_y + 3], fill=(65, 165, 250)) # LED azul
        d.rectangle([140, led_y, 155, led_y + 3], fill=(255, 180, 40)) # LED ámbar

    draw_teacher_desk(d, 340, 105, 120, 50)

    # Canaletas de cableado de red en el piso con franjas de advertencia
    for cy in [245, 330, 415]:
        d.rectangle([70, cy, 310, cy + 6], fill=(50, 55, 65))
        for sx in range(70, 310, 12):
            d.line([(sx, cy), (sx + 6, cy + 6)], fill=(240, 200, 40), width=2)

    # 3 Mesas modulares de cómputo con monitores widescreen, teclados y LEDs de poder
    pc_tables = [
        (80, 185, 220, 50),
        (80, 270, 220, 50),
        (80, 355, 220, 50),
    ]
    for tx, ty, tw, th in pc_tables:
        d.rectangle([tx + 6, ty + th, tx + tw + 10, ty + th + 10], fill=(16, 18, 24))
        d.rectangle([tx + tw, ty + 2, tx + tw + 4, ty + th + 1], fill=(55, 60, 70))
        d.rectangle([tx - 2, ty - 2, tx + tw + 2, ty + th + 2], fill=(45, 50, 60))
        d.rectangle([tx, ty, tx + tw, ty + th], fill=(125, 132, 145))
        d.line([(tx, ty), (tx + tw, ty)], fill=(175, 185, 200), width=2)

        # 3 Computadoras por mesa con pantalla, teclado y mouse
        for i in range(3):
            cx = tx + 18 + i * 68
            # Monitor
            d.rectangle([cx, ty + 6, cx + 42, ty + 30], fill=(22, 26, 35), outline=(10, 12, 18))
            # Pantalla encendida con líneas de datos / código
            d.rectangle([cx + 2, ty + 8, cx + 40, ty + 26], fill=(60, 175, 230))
            for line_y in range(ty + 10, ty + 24, 3):
                d.line([(cx + 4, line_y), (cx + 28, line_y)], fill=(235, 248, 255), width=1)
            # Pie del monitor
            d.rectangle([cx + 18, ty + 30, cx + 24, ty + 34], fill=(65, 70, 80))
            # Teclado con retroiluminación y mouse
            d.rectangle([cx + 2, ty + 36, cx + 34, ty + 46], fill=(45, 50, 60), outline=(25, 30, 38))
            d.ellipse([cx + 37, ty + 39, cx + 43, ty + 45], fill=(35, 40, 50))
            # LED de encendido en torre
            d.point((cx + 1, ty + 47), fill=(40, 235, 130))

    d.ellipse([510, 210, 690, 390], outline=(175, 205, 230), width=2)
    img = apply_ambient_occlusion(img)
    return img.convert("RGB")


def generate_salon_6():
    """Salón 6: Aula Magna Deportiva y Salud."""
    img = create_base_canvas()
    d = ImageDraw.Draw(img)

    # Piso de duela de gimnasio en tablones de arce con brillo de barniz
    tile_size = 40
    for y in range(80, HEIGHT - 36, tile_size):
        for x in range(36, WIDTH - 36, tile_size):
            col = (225, 178, 120) if ((x // tile_size) + (y // tile_size)) % 2 == 0 else (210, 162, 105)
            d.rectangle([x, y, x + tile_size - 1, y + tile_size - 1], fill=col, outline=(180, 135, 85))
            # Línea de vetas de madera del arce
            d.line([(x + 2, y + 14), (x + tile_size - 3, y + 14)], fill=(195, 148, 95), width=1)
            d.line([(x + 2, y + 28), (x + tile_size - 3, y + 28)], fill=(195, 148, 95), width=1)

    draw_room_walls(d, (120, 28, 40), (225, 190, 50))

    # Líneas reglamentarias de la cancha pintadas en blanco puro y área guinda
    d.rectangle([90, 130, 710, 430], outline=(255, 255, 255), width=3)
    d.line([(400, 130), (400, 430)], fill=(255, 255, 255), width=3)
    d.ellipse([335, 215, 465, 345], outline=(255, 255, 255), width=3)
    d.ellipse([375, 255, 425, 305], fill=(145, 35, 45), outline=(255, 255, 255), width=2)

    # Tablero marcador electrónico en muro norte
    d.rectangle([310, 14, 490, 68], fill=(20, 22, 28), outline=(220, 180, 50), width=2)
    d.line([(400, 18), (400, 64)], fill=(60, 65, 75), width=2)
    # Puntuación LED roja/verde
    d.rectangle([330, 26, 370, 56], fill=(10, 12, 16))
    d.rectangle([430, 26, 470, 56], fill=(10, 12, 16))
    # Dígitos LED ("22" COBAEM)
    d.line([(345, 32), (365, 32)], fill=(255, 40, 50), width=2)
    d.line([(345, 42), (365, 42)], fill=(255, 40, 50), width=2)
    d.line([(445, 32), (465, 32)], fill=(50, 240, 120), width=2)

    # Estantes y jaulas de balones deportivos con sombras
    for bx in range(80, 260, 60):
        d.rectangle([bx + 4, 68, bx + 52, 74], fill=(16, 14, 20))
        d.rectangle([bx, 18, bx + 50, 68], fill=(65, 70, 80), outline=(35, 40, 48), width=2)
        d.ellipse([bx + 10, 26, bx + 40, 56], fill=(235, 105, 30), outline=(160, 60, 15))
        d.line([(bx + 10, 41), (bx + 40, 41)], fill=(25, 28, 35), width=2)

    # Carrito móvil de balones en el aula deportiva (x=90, y=190)
    d.rectangle([94, 280, 150, 288], fill=(18, 14, 20))
    d.rectangle([90, 190, 145, 280], fill=(55, 60, 70), outline=(30, 35, 42), width=2)
    for ball_y in range(198, 265, 24):
        d.ellipse([98, ball_y, 118, ball_y + 20], fill=(235, 105, 30))
        d.ellipse([118, ball_y, 138, ball_y + 20], fill=(245, 245, 250), outline=(40, 80, 160)) # Voleibol

    draw_teacher_desk(d, 340, 105, 120, 50)
    d.ellipse([510, 210, 690, 390], outline=(225, 190, 150), width=2)
    img = apply_ambient_occlusion(img)
    return img.convert("RGB")


def main():
    print("Iniciando generación cinematográfica de mapas de salones interiores (CEMSaD 22 ENTHAVI)...")
    salones = [
        ("salon_1_laboratorio.png", generate_salon_1),
        ("salon_2_aula_a.png", generate_salon_2),
        ("salon_3_sala_civica.png", generate_salon_3),
        ("salon_4_biblioteca.png", generate_salon_4),
        ("salon_5_computo.png", generate_salon_5),
        ("salon_6_gimnasio.png", generate_salon_6),
    ]

    for fname, gen_func in salones:
        img = gen_func()
        out_path = os.path.join(SALONES_DIR, fname)
        img.save(out_path, format="PNG")
        print(f"  ✓ Generado con sombras y ambientación: {out_path} ({img.width}x{img.height} px)")

    print("¡Los 6 salones interiores han sido generados exitosamente!")


if __name__ == "__main__":
    main()
