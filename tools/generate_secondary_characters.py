#!/usr/bin/env python3
"""
tools/generate_secondary_characters.py
Convierte a todos los personajes secundarios (alumnos del CEMSaD 22 y maestro redimido)
a la plantilla estándar en assets/plantillas/poses_pixel.png (pose frontal central idle).

Personajes procesados:
1. mateo_laboratorio (Recortado de assets/mateo_laboratorio.jpeg, pose frontal central con fondo transparente)
2. alejandro_cancha (Recortado de assets/alejandro cancha plantilla.jpeg, pose frontal central con fondo transparente)
3. maria_cafeteria (Adaptada a la pose frontal central de la plantilla con su peinado y uniforme de cafetería)
4. valeria_plaza (Adaptada a la pose frontal central de la plantilla con su peinado y uniforme de plaza cívica)
5. fernanda_biblioteca (Adaptada a la pose frontal central de la plantilla con sus lentes y diadema)
6. diego_computo (Adaptado a la pose frontal central de la plantilla con sus audífonos)
7. sofia_direccion (Adaptada a la pose frontal central de la plantilla con su uniforme formal)
8. maestro_desinteres_redeemed (Adaptado a la pose frontal central con su traje formal docente)

Formato de exportación:
- 512x512 píxeles RGBA con fondo transparente.
- Centrado horizontalmente (x = 256).
- Pies apoyados en la base (y = 464), alineados exactamente con Masculino/idle.png y Femenino/idle.png.
- Organizados por subcarpetas en assets/characters/<nombre>/idle.png
- Copiados en assets/<nombre>.png y assets/sprites/students/<nombre>.png para compatibilidad total con el motor.
"""

import os
import shutil
from collections import deque
from PIL import Image
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
CHARACTERS_DIR = os.path.join(ASSETS_DIR, "characters")
SPRITES_STUDENTS_DIR = os.path.join(ASSETS_DIR, "sprites", "students")
SPRITES_DIR = os.path.join(ASSETS_DIR, "sprites")


def extract_tight_clean_from_sheet(img_path, crop_box=(880, 880, 1160, 1310), bg_threshold=225):
    """
    Recorta la pose central de un sprite sheet JPEG de alta resolución,
    eliminando el fondo blanco mediante flood-fill desde los bordes para
    conservar batas, camisas u ojos blancos dentro del personaje.
    """
    im = Image.open(img_path).convert("RGB")
    sub = im.crop(crop_box)
    w, h = sub.size
    arr = np.array(sub)

    is_white = np.all(arr >= bg_threshold, axis=-1)
    visited = np.zeros((h, w), dtype=bool)
    q = deque()

    for x in range(w):
        if is_white[0, x]:
            visited[0, x] = True
            q.append((0, x))
        if is_white[h - 1, x]:
            visited[h - 1, x] = True
            q.append((h - 1, x))
    for y in range(h):
        if is_white[y, 0]:
            visited[y, 0] = True
            q.append((y, 0))
        if is_white[y, w - 1]:
            visited[y, w - 1] = True
            q.append((y, w - 1))

    while q:
        cy, cx = q.popleft()
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and is_white[ny, nx]:
                visited[ny, nx] = True
                q.append((ny, nx))

    alpha = np.where(visited, 0, 255).astype(np.uint8)

    # Limpieza anti-halo para píxeles de transición en bordes
    for y in range(h):
        for x in range(w):
            if not visited[y, x]:
                is_adj = any(
                    visited[y + dy, x + dx]
                    for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]
                    if 0 <= y + dy < h and 0 <= x + dx < w
                )
                if is_adj:
                    val = float(np.mean(arr[y, x]))
                    if val > 235:
                        alpha[y, x] = 0
                    elif val > 200:
                        alpha[y, x] = int(255 * (235 - val) / 35.0)

    out_arr = np.zeros((h, w, 4), dtype=np.uint8)
    out_arr[:, :, :3] = arr
    out_arr[:, :, 3] = alpha

    res = Image.fromarray(out_arr)
    bbox = res.getbbox()
    return res.crop(bbox)


def place_on_standard_canvas(tight_img, target_base_y=464):
    """
    Coloca el sprite recortado sobre un lienzo RGBA de 512x512 píxeles,
    centrado horizontalmente en x=256 y apoyando los pies en target_base_y=464.
    """
    canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    tw, th = tight_img.size
    ox = (512 - tw) // 2
    oy = target_base_y - th
    canvas.paste(tight_img, (ox, oy), tight_img)
    return canvas


def generate_mateo():
    """Mateo — Laboratorio Edificio D (Ciencia y Respeto)."""
    existing_idle = os.path.join(CHARACTERS_DIR, "mateo_laboratorio", "idle.png")
    if os.path.exists(existing_idle):
        return Image.open(existing_idle).convert("RGBA")
    src = os.path.join(ASSETS_DIR, "mateo_laboratorio.jpeg")
    if not os.path.exists(src):
        src = os.path.join(BASE_DIR, ".trash", "assets", "mateo_laboratorio.jpeg")
    tight = extract_tight_clean_from_sheet(src)
    return place_on_standard_canvas(tight)


def generate_alejandro():
    """Alejandro — Cancha de Usos Múltiples (Deporte y Valores)."""
    existing_idle = os.path.join(CHARACTERS_DIR, "alejandro_cancha", "idle.png")
    if os.path.exists(existing_idle):
        return Image.open(existing_idle).convert("RGBA")
    src = os.path.join(ASSETS_DIR, "alejandro cancha plantilla.jpeg")
    if not os.path.exists(src):
        src = os.path.join(BASE_DIR, ".trash", "assets", "alejandro cancha plantilla.jpeg")
    tight = extract_tight_clean_from_sheet(src)
    return place_on_standard_canvas(tight)


def generate_maria():
    """María — Cafetería y Aulas (Peinado ondulado, diadema rosa y mandil de cafetería)."""
    base_path = os.path.join(CHARACTERS_DIR, "Femenino", "idle.png")
    im = Image.open(base_path).convert("RGBA")
    arr = np.array(im)

    y_coords, x_coords = np.indices((512, 512))
    is_hair = (arr[:, :, 3] > 0) & (arr[:, :, 0] < 45) & (arr[:, :, 1] < 45) & (arr[:, :, 2] < 45) & (y_coords < 265)

    hair_base = np.array([115, 65, 35, 255], dtype=np.uint8)
    hair_light = np.array([145, 85, 45, 255], dtype=np.uint8)
    hair_dark = np.array([80, 42, 22, 255], dtype=np.uint8)

    shading = ((x_coords - 256) ** 2 + (y_coords - 160) ** 2) ** 0.5
    for y in range(107, 265):
        for x in range(142, 370):
            if is_hair[y, x]:
                is_border = False
                for dy, dx in [(-2, 0), (2, 0), (0, -2), (0, 2)]:
                    ny, nx = y + dy, x + dx
                    if not (0 <= ny < 512 and 0 <= nx < 512 and is_hair[ny, nx]):
                        is_border = True
                        break
                if not is_border:
                    if y < 150:
                        arr[y, x] = hair_light
                    elif shading[y, x] > 60:
                        arr[y, x] = hair_dark
                    else:
                        arr[y, x] = hair_base

    # Diadema rosa/coral en la coronilla
    for y in range(136, 146):
        for x in range(195, 317):
            if is_hair[y, x]:
                if y in [136, 145] or x in [195, 316]:
                    arr[y, x] = [180, 70, 90, 255]
                else:
                    arr[y, x] = [240, 120, 140, 255]

    # Tirantes del mandil escolar
    for y in range(252, 280):
        for x in list(range(218, 230)) + list(range(282, 294)):
            if arr[y, x, 3] > 0:
                if x in [218, 229, 282, 293]:
                    arr[y, x] = [180, 175, 165, 255]
                else:
                    arr[y, x] = [248, 245, 238, 255]

    # Cuerpo del mandil de cafetería sobre el suéter guinda
    for y in range(280, 372):
        for x in range(208, 304):
            if arr[y, x, 3] > 0:
                if y in [280, 371] or x in [208, 303]:
                    arr[y, x] = [180, 175, 165, 255]
                else:
                    if x in [230, 231, 280, 281] or y > 365:
                        arr[y, x] = [225, 220, 210, 255]
                    else:
                        arr[y, x] = [248, 245, 238, 255]

    # Bolsillo frontal para notas de pedidos
    for y in range(328, 356):
        for x in range(238, 274):
            if y in [328, 355] or x in [238, 273]:
                arr[y, x] = [170, 165, 155, 255]
            else:
                arr[y, x] = [240, 236, 228, 255]

    return Image.fromarray(arr)


def generate_valeria():
    """Valeria — Plaza Cívica (Tez cálida, peinado con raya lateral, broche esmeralda institucional COBAEM y uniforme de plaza cívica)."""
    base_path = os.path.join(CHARACTERS_DIR, "Femenino", "idle.png")
    im = Image.open(base_path).convert("RGBA")
    arr = np.array(im)

    y_coords, x_coords = np.indices((512, 512))

    # Tono de piel cálido natural
    is_skin = (arr[:, :, 3] > 0) & (arr[:, :, 0] > 180) & (arr[:, :, 1] > 130) & (arr[:, :, 2] > 100)
    is_face_skin = is_skin & (y_coords >= 165) & (y_coords <= 250) & (x_coords >= 195) & (x_coords <= 315)

    for y in range(165, 251):
        for x in range(195, 316):
            if is_face_skin[y, x]:
                if arr[y, x, 0] > 200 and arr[y, x, 1] < 150:
                    arr[y, x] = [235, 130, 120, 255]
                elif arr[y, x, 0] < 220:
                    arr[y, x] = [200, 160, 130, 255]
                else:
                    arr[y, x] = [240, 205, 175, 255]

    # Piel de piernas
    is_legs_skin = is_skin & (y_coords >= 415) & (y_coords <= 435)
    arr[is_legs_skin] = [240, 205, 175, 255]

    # Cabello castaño oscuro con raya y mechones estilizados
    CLR_HAIR = np.array([45, 30, 25, 255], dtype=np.uint8)
    CLR_HAIR_HIGHLIGHT = np.array([75, 50, 40, 255], dtype=np.uint8)
    CLR_OUTLINE = np.array([7, 1, 16, 255], dtype=np.uint8)
    CLR_EMERALD = np.array([20, 160, 95, 255], dtype=np.uint8)
    CLR_GOLD = np.array([230, 185, 40, 255], dtype=np.uint8)

    # Mechones laterales elegantes
    for side, (bx0, bx1) in enumerate([(160, 182), (330, 352)]):
        for y in range(190, 310):
            for x in range(bx0, bx1):
                if x in [bx0, bx1 - 1] or y == 309:
                    arr[y, x] = CLR_OUTLINE
                elif (y + x) % 12 < 3:
                    arr[y, x] = CLR_HAIR_HIGHLIGHT
                else:
                    arr[y, x] = CLR_HAIR

    # Broche esmeralda con ribete oro en el cabello (lado izquierdo)
    for y in range(185, 198):
        for x in range(188, 204):
            if y in [185, 197] or x in [188, 203]:
                arr[y, x] = CLR_GOLD
            else:
                arr[y, x] = CLR_EMERALD

    # Escudo cívico escolar en el pecho
    for y in range(306, 322):
        for x in range(226, 242):
            if y == 306 or y == 321 or x == 226 or x == 241:
                arr[y, x] = CLR_GOLD
            else:
                arr[y, x] = CLR_EMERALD

    return Image.fromarray(arr)


def generate_fernanda():
    """Fernanda — Biblioteca Edificio B (Lentes de lectura, diadema y uniforme pulcro)."""
    base_path = os.path.join(CHARACTERS_DIR, "Femenino", "idle.png")
    im = Image.open(base_path).convert("RGBA")
    arr = np.array(im)

    y_coords, x_coords = np.indices((512, 512))

    # Cabello ciruela oscuro / castaño sobrio
    is_hair = (arr[:, :, 3] > 0) & (arr[:, :, 0] < 45) & (arr[:, :, 1] < 45) & (arr[:, :, 2] < 45) & (y_coords < 265)
    for y in range(107, 265):
        for x in range(142, 370):
            if is_hair[y, x]:
                is_border = False
                for dy, dx in [(-2, 0), (2, 0), (0, -2), (0, 2)]:
                    ny, nx = y + dy, x + dx
                    if not (0 <= ny < 512 and 0 <= nx < 512 and is_hair[ny, nx]):
                        is_border = True
                        break
                if not is_border:
                    arr[y, x] = [50, 35, 45, 255]

    # Diadema azul zafiro en la cabeza
    for y in range(138, 146):
        for x in range(195, 317):
            if is_hair[y, x]:
                if y in [138, 145] or x in [195, 316]:
                    arr[y, x] = [20, 35, 60, 255]
                else:
                    arr[y, x] = [40, 90, 160, 255]

    # Gafas inteligentes de lectura
    CLR_FRAME = np.array([40, 120, 180, 255], dtype=np.uint8)
    CLR_FRAME_DARK = np.array([20, 60, 95, 255], dtype=np.uint8)

    for y in range(190, 217):
        for x in range(212, 247):
            if y in [190, 191, 215, 216] or x in [212, 213, 245, 246]:
                arr[y, x] = CLR_FRAME

    for y in range(190, 217):
        for x in range(266, 301):
            if y in [190, 191, 215, 216] or x in [266, 267, 299, 300]:
                arr[y, x] = CLR_FRAME

    for y in range(198, 203):
        for x in range(246, 267):
            arr[y, x] = CLR_FRAME

    for y in range(198, 203):
        for x in list(range(195, 212)) + list(range(300, 317)):
            if arr[y, x, 3] > 0:
                arr[y, x] = CLR_FRAME_DARK

    # Reflejo cristalino en las lentes
    arr[194:198, 216:220] = [220, 245, 255, 255]
    arr[194:198, 270:274] = [220, 245, 255, 255]

    return Image.fromarray(arr)


def generate_diego():
    """Diego — Cómputo Edificio C (Audífonos gamer cian alrededor del cuello y estilo tech)."""
    base_path = os.path.join(CHARACTERS_DIR, "Masculino", "idle.png")
    im = Image.open(base_path).convert("RGBA")
    arr = np.array(im)

    CLR_CYAN = np.array([30, 180, 220, 255], dtype=np.uint8)
    CLR_CYAN_DARK = np.array([15, 80, 105, 255], dtype=np.uint8)
    CLR_PAD = np.array([25, 30, 38, 255], dtype=np.uint8)
    CLR_OUTLINE = np.array([7, 1, 16, 255], dtype=np.uint8)

    # Auricular izquierdo (earcup)
    for y in range(168, 217):
        for x in range(156, 185):
            if x in [156, 184] or y in [168, 216]:
                arr[y, x] = CLR_OUTLINE
            elif x >= 174:
                arr[y, x] = CLR_PAD
            elif x <= 162:
                arr[y, x] = CLR_CYAN_DARK
            else:
                arr[y, x] = CLR_CYAN

    # Auricular derecho (earcup)
    for y in range(168, 217):
        for x in range(328, 357):
            if x in [328, 356] or y in [168, 216]:
                arr[y, x] = CLR_OUTLINE
            elif x <= 338:
                arr[y, x] = CLR_PAD
            elif x >= 350:
                arr[y, x] = CLR_CYAN_DARK
            else:
                arr[y, x] = CLR_CYAN

    # Diadema / arco curvado reposando en el cuello
    for y in range(228, 246):
        for x in range(180, 333):
            arch_y = 237 + int(6 * np.cos((x - 256) * np.pi / 160))
            if abs(y - arch_y) <= 4:
                if abs(y - arch_y) == 4:
                    arr[y, x] = CLR_CYAN_DARK
                else:
                    arr[y, x] = CLR_CYAN

    return Image.fromarray(arr)


def generate_sofia():
    """Sofía — Dirección Edificio C (Liderazgo estudiantil, coleta alta, gafas y porte formal)."""
    base_path = os.path.join(CHARACTERS_DIR, "Femenino", "idle.png")
    im = Image.open(base_path).convert("RGBA")
    arr = np.array(im)

    CLR_HAIR = np.array([25, 20, 30, 255], dtype=np.uint8)
    CLR_OUTLINE = np.array([7, 1, 16, 255], dtype=np.uint8)
    CLR_BLUE = np.array([40, 140, 200, 255], dtype=np.uint8)
    CLR_BLUE_DARK = np.array([20, 70, 120, 255], dtype=np.uint8)

    # Coletero azul cielo
    for y in range(124, 142):
        for x in range(334, 352):
            dist_sq = (y - 133) ** 2 + (x - 343) ** 2
            if dist_sq <= 64:
                if dist_sq >= 40:
                    arr[y, x] = CLR_BLUE_DARK
                else:
                    arr[y, x] = CLR_BLUE

    # Caída de la coleta alta
    for y in range(135, 230):
        width = int(24 - (y - 135) * 0.12)
        start_x = int(344 + (y - 135) * 0.1)
        for x in range(start_x, start_x + width):
            if x == start_x or x == start_x + width - 1 or y == 229:
                arr[y, x] = CLR_OUTLINE
            else:
                arr[y, x] = CLR_HAIR

    # Gafas elegantes
    CLR_FRAME = np.array([40, 120, 180, 255], dtype=np.uint8)
    for y in range(190, 217):
        for x in range(212, 247):
            if y in [190, 191, 215, 216] or x in [212, 213, 245, 246]:
                arr[y, x] = CLR_FRAME

    for y in range(190, 217):
        for x in range(266, 301):
            if y in [190, 191, 215, 216] or x in [266, 267, 299, 300]:
                arr[y, x] = CLR_FRAME

    for y in range(198, 203):
        for x in range(246, 267):
            arr[y, x] = CLR_FRAME

    # Cuello blanco y corbatín institucional
    for y in range(246, 264):
        for x in range(238, 274):
            if arr[y, x, 3] > 0 and (x - 256) ** 2 + (y - 255) ** 2 <= 140:
                arr[y, x] = [255, 255, 255, 255]

    for y in range(256, 292):
        w = max(2, int(8 - (y - 256) * 0.1))
        for x in range(256 - w, 256 + w + 1):
            if x in [256 - w, 256 + w] or y == 291:
                arr[y, x] = [100, 15, 20, 255]
            else:
                arr[y, x] = [185, 30, 40, 255]

    return Image.fromarray(arr)


def generate_maestro_redeemed():
    """Maestro Desinterés (Redimido) — Traje formal docente, corbata roja y calidez vocacional."""
    base_path = os.path.join(CHARACTERS_DIR, "Masculino", "idle.png")
    im = Image.open(base_path).convert("RGBA")
    arr = np.array(im)

    y_coords, x_coords = np.indices((512, 512))

    CLR_SKIN = np.array([245, 214, 180, 255], dtype=np.uint8)
    CLR_HAIR = np.array([75, 65, 60, 255], dtype=np.uint8)
    CLR_HAIR_LIGHT = np.array([105, 95, 90, 255], dtype=np.uint8)
    CLR_SUIT_DARK = np.array([48, 52, 60, 255], dtype=np.uint8)
    CLR_SUIT_LIGHT = np.array([65, 72, 84, 255], dtype=np.uint8)
    CLR_WHITE = np.array([255, 255, 255, 255], dtype=np.uint8)
    CLR_TIE = np.array([168, 30, 30, 255], dtype=np.uint8)
    CLR_TIE_DARK = np.array([90, 15, 15, 255], dtype=np.uint8)
    CLR_OUTLINE = np.array([7, 1, 16, 255], dtype=np.uint8)

    # Cabello grisáceo formal
    is_hair = (arr[:, :, 3] > 0) & (arr[:, :, 0] < 45) & (arr[:, :, 1] < 45) & (arr[:, :, 2] < 45) & (y_coords < 160)
    for y in range(64, 160):
        for x in range(128, 384):
            if is_hair[y, x]:
                is_border = False
                for dy, dx in [(-2, 0), (2, 0), (0, -2), (0, 2)]:
                    ny, nx = y + dy, x + dx
                    if not (0 <= ny < 512 and 0 <= nx < 512 and is_hair[ny, nx]):
                        is_border = True
                        break
                if not is_border:
                    arr[y, x] = CLR_HAIR_LIGHT if y < 90 else CLR_HAIR

    # Piel cálida recuperada (ya no es el gris pálido apático)
    is_face = (arr[:, :, 3] > 0) & (arr[:, :, 0] > 170) & (y_coords >= 120) & (y_coords <= 250) & (x_coords >= 170) & (x_coords <= 340)
    for y in range(120, 251):
        for x in range(170, 341):
            if is_face[y, x]:
                arr[y, x] = CLR_SKIN

    # Traje formal docente
    for y in range(256, 369):
        for x in range(150, 362):
            if arr[y, x, 3] > 0:
                if abs(x - 256) <= 24 and y <= 310:
                    if abs(x - 256) <= 8:
                        if abs(x - 256) == 8 or y == 310:
                            arr[y, x] = CLR_TIE_DARK
                        else:
                            arr[y, x] = CLR_TIE
                    elif abs(x - 256) <= 18 and y <= 290:
                        arr[y, x] = CLR_WHITE
                    else:
                        arr[y, x] = CLR_SUIT_LIGHT
                else:
                    is_jacket_border = False
                    for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < 512 and 0 <= nx < 512 and arr[ny, nx, 3] == 0:
                            is_jacket_border = True
                            break
                    if is_jacket_border:
                        arr[y, x] = CLR_OUTLINE
                    else:
                        arr[y, x] = CLR_SUIT_DARK

    # Pañuelo blanco de bolsillo
    for y in range(300, 310):
        for x in range(200, 222):
            if arr[y, x, 3] > 0:
                if y == 300 or y == 309 or x == 200 or x == 221:
                    arr[y, x] = CLR_SUIT_LIGHT
                elif y in [301, 302]:
                    arr[y, x] = CLR_WHITE

    return Image.fromarray(arr)


CHARACTER_GENERATORS = {
    "mateo_laboratorio": generate_mateo,
    "alejandro_cancha": generate_alejandro,
    "maria_cafeteria": generate_maria,
    "valeria_plaza": generate_valeria,
    "fernanda_biblioteca": generate_fernanda,
    "diego_computo": generate_diego,
    "sofia_direccion": generate_sofia,
    "maestro_desinteres_redeemed": generate_maestro_redeemed,
}


def generate_corrupted_maestro():
    """Genera sprite de cuerpo entero del Maestro Desinterés corrompido (traje grisáceo, ojos blancos)."""
    base_path = os.path.join(CHARACTERS_DIR, "maestro_desinteres_redeemed", "idle.png")
    if not os.path.exists(base_path):
        base_path = os.path.join(CHARACTERS_DIR, "Masculino", "idle.png")
    im = Image.open(base_path).convert("RGBA")
    arr = np.array(im)

    # Desaturar y oscurecer hacia tonos fríos / desinterés
    alpha = arr[:, :, 3] > 0
    # Grisáceo desvitalizado
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    grey = (0.299 * r + 0.587 * g + 0.114 * b).astype(np.uint8)
    arr[alpha, 0] = (grey[alpha] * 0.75 + 20).astype(np.uint8)
    arr[alpha, 1] = (grey[alpha] * 0.75 + 25).astype(np.uint8)
    arr[alpha, 2] = (grey[alpha] * 0.85 + 35).astype(np.uint8)

    # Ojos blancos brillantes / vacíos de desinterés
    y_coords, x_coords = np.indices((512, 512))
    eye_l = (y_coords >= 195) & (y_coords <= 208) & (x_coords >= 222) & (x_coords <= 236)
    eye_r = (y_coords >= 195) & (y_coords <= 208) & (x_coords >= 276) & (x_coords <= 290)
    arr[eye_l] = [255, 255, 255, 255]
    arr[eye_r] = [255, 255, 255, 255]

    return Image.fromarray(arr)


def export_portraits():
    """Exporta retratos de busto (256x256 RGBA) para todos los personajes, héroes y jefes."""
    portraits_dir = os.path.join(ASSETS_DIR, "portraits")
    os.makedirs(portraits_dir, exist_ok=True)

    bust_specs = [
        ("player_masculino", os.path.join(CHARACTERS_DIR, "Masculino", "idle.png"), 40, 296),
        ("player_femenino", os.path.join(CHARACTERS_DIR, "Femenino", "idle.png"), 80, 336),
        ("guardian", os.path.join(CHARACTERS_DIR, "Masculino", "idle.png"), 40, 296),
        ("mateo_laboratorio", os.path.join(CHARACTERS_DIR, "mateo_laboratorio", "idle.png"), 40, 296),
        ("alejandro_cancha", os.path.join(CHARACTERS_DIR, "alejandro_cancha", "idle.png"), 40, 296),
        ("diego_computo", os.path.join(CHARACTERS_DIR, "diego_computo", "idle.png"), 40, 296),
        ("maria_cafeteria", os.path.join(CHARACTERS_DIR, "maria_cafeteria", "idle.png"), 80, 336),
        ("valeria_plaza", os.path.join(CHARACTERS_DIR, "valeria_plaza", "idle.png"), 80, 336),
        ("fernanda_biblioteca", os.path.join(CHARACTERS_DIR, "fernanda_biblioteca", "idle.png"), 80, 336),
        ("sofia_direccion", os.path.join(CHARACTERS_DIR, "sofia_direccion", "idle.png"), 80, 336),
        ("maestro_desinteres_redeemed", os.path.join(CHARACTERS_DIR, "maestro_desinteres_redeemed", "idle.png"), 40, 296),
        ("maestro_desinteres", os.path.join(CHARACTERS_DIR, "maestro_desinteres", "idle.png"), 40, 296),
    ]

    for name, path, y0, y1 in bust_specs:
        if os.path.exists(path):
            im = Image.open(path).convert("RGBA")
            x0 = 256 - 128
            x1 = 256 + 128
            crop = im.crop((x0, y0, x1, y1))
            assert crop.size == (256, 256)
            out_p = os.path.join(portraits_dir, f"{name}.png")
            crop.save(out_p, format="PNG")
            print(f"   [PORTRAIT SAVED] {out_p}")


def main():
    print("=== PROCESANDO PERSONAJES SECUNDARIOS CON LA PLANTILLA ESTÁNDAR ===")

    for char_id, gen_fn in CHARACTER_GENERATORS.items():
        print(f"\n-> Generando personaje: {char_id}")
        img = gen_fn()

        # Validación estricta de salida
        assert img.size == (512, 512), f"Error de tamaño en {char_id}: {img.size}"
        assert img.mode == "RGBA", f"Error de modo en {char_id}: {img.mode}"
        bbox = img.getbbox()
        assert bbox is not None, f"Error: {char_id} está vacío"
        assert bbox[3] == 464, f"Error: los pies de {char_id} deben apoyarse en y=464 (obtenido: {bbox[3]})"
        center_x = (bbox[0] + bbox[2]) / 2.0
        assert abs(center_x - 256.0) <= 2.0, f"Error: {char_id} no está centrado en x=256 (obtenido: {center_x})"

        print(f"   [OK] Validado: size={img.size}, bbox={bbox}, center_x={center_x:.1f}, feet_y={bbox[3]}")

        # 1. Guardar en subcarpeta dedicada: assets/characters/<nombre>/idle.png
        char_dir = os.path.join(CHARACTERS_DIR, char_id)
        os.makedirs(char_dir, exist_ok=True)
        idle_path = os.path.join(char_dir, "idle.png")
        img.save(idle_path, format="PNG")
        print(f"   [SAVED] {idle_path}")

        # 2. Guardar en raíz de assets/<nombre>.png para compatibilidad directa
        root_path = os.path.join(ASSETS_DIR, f"{char_id}.png")
        img.save(root_path, format="PNG")
        print(f"   [SAVED] {root_path}")

        # 3. Guardar en assets/sprites/students/<nombre>.png
        os.makedirs(SPRITES_STUDENTS_DIR, exist_ok=True)
        student_path = os.path.join(SPRITES_STUDENTS_DIR, f"{char_id}.png")
        img.save(student_path, format="PNG")
        print(f"   [SAVED] {student_path}")

        # 4. Guardar en assets/sprites/<nombre>.png
        sprites_root_path = os.path.join(SPRITES_DIR, f"{char_id}.png")
        img.save(sprites_root_path, format="PNG")
        print(f"   [SAVED] {sprites_root_path}")

    # Generar también maestro_desinteres corrupto
    print("\n-> Generando Maestro Desinterés (Corrupto por Apatía)")
    corrupt_maestro = generate_corrupted_maestro()
    maestro_dir = os.path.join(CHARACTERS_DIR, "maestro_desinteres")
    os.makedirs(maestro_dir, exist_ok=True)
    corrupt_maestro.save(os.path.join(maestro_dir, "idle.png"), format="PNG")
    corrupt_maestro.save(os.path.join(ASSETS_DIR, "maestro_desinteres.png"), format="PNG")
    corrupt_maestro.save(os.path.join(ASSETS_DIR, "sprites", "bosses", "maestro_desinteres.png"), format="PNG")

    print("\n=== GENERANDO RETRATOS ENRIQUECIDOS (assets/portraits/) ===")
    export_portraits()

    print("\nTodos los personajes y retratos fueron generados y organizados exitosamente.")


if __name__ == "__main__":
    main()
