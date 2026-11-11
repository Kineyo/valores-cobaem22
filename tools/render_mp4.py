#!/usr/bin/env python3
"""Renderizador de video MP4 a 1080p para Campeones de los Valores.

Combina las diapositivas vectoriales/escenarios con la banda sonora original.
"""

import math
import os
import subprocess
from PIL import Image, ImageDraw, ImageFont

WIDTH, HEIGHT = 1920, 1080
FPS = 30
TOTAL_FRAMES = 600  # 20 segundos

# Paleta oficial COBAEM / Valores
BG_DARK = (7, 22, 14)
BG_MID = (19, 58, 36)
ACCENT_GREEN = (82, 183, 136)
ACCENT_EMERALD = (45, 106, 79)
ACCENT_GOLD = (245, 158, 11)
TEXT_WHITE = (255, 255, 255)
TEXT_MUTED = (183, 228, 199)


def get_font(size: int, bold: bool = False):
  try:
    name = (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
        if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    )
    if os.path.exists(name):
      return ImageFont.truetype(name, size)
    return ImageFont.load_default()
  except:
    return ImageFont.load_default()


font_title = get_font(72, True)
font_h1 = get_font(52, True)
font_h2 = get_font(34, True)
font_body = get_font(26, False)
font_badge = get_font(20, True)
font_small = get_font(18, False)


def create_base_frame():
  img = Image.new("RGB", (WIDTH, HEIGHT), BG_DARK)
  draw = ImageDraw.Draw(img)
  # Gradiente central
  for y in range(HEIGHT):
    factor = 1.0 - (abs(y - HEIGHT * 0.45) / (HEIGHT * 0.55))
    factor = max(0.0, min(1.0, factor))
    r = int(BG_DARK[0] + (BG_MID[0] - BG_DARK[0]) * factor * 0.7)
    g = int(BG_DARK[1] + (BG_MID[1] - BG_DARK[1]) * factor * 0.7)
    b = int(BG_DARK[2] + (BG_MID[2] - BG_DARK[2]) * factor * 0.7)
    draw.line([(0, y), (WIDTH, y)], fill=(r, g, b))

  # Cuadrícula tenue arquitectónica (1m = 40px)
  grid_col = (255, 255, 255, 12)
  for x in range(0, WIDTH, 40):
    draw.line([(x, 0), (x, HEIGHT)], fill=(20, 45, 30))
  for y in range(0, HEIGHT, 40):
    draw.line([(0, y), (WIDTH, y)], fill=(20, 45, 30))
  return img


def draw_centered_text(
    draw, y, text, font, fill=TEXT_WHITE, shadow=True, max_w=None
):
  bbox = draw.textbbox((0, 0), text, font=font)
  w = bbox[2] - bbox[0]
  x = (WIDTH - w) // 2
  if shadow:
    draw.text((x + 2, y + 2), text, font=font, fill=(0, 0, 0, 180))
  draw.text((x, y), text, font=font, fill=fill)
  return bbox[3] - bbox[1]


# Cargar escenarios para la escena 3
SCENARIO_PATHS = [
    (
        "escenarios/nivel_1_acceso_laboratorio.png",
        "Nivel 1: Acceso, Caseta y Lab. D (183 m²)",
    ),
    (
        "escenarios/nivel_2_edificio_a_cafeteria.png",
        "Nivel 2: Edificio A — Cafetería y Aulas (339 m²)",
    ),
    (
        "escenarios/nivel_3_plaza_civica_escalinata.png",
        "Nivel 3: Plaza Cívica y Escalinata +4m (748 m²)",
    ),
    (
        "escenarios/nivel_4_edificio_b.png",
        "Nivel 4: Edificio B — Biblioteca y Aulas (340 m²)",
    ),
    (
        "escenarios/nivel_5_edificio_c_computo.png",
        "Nivel 5: Edificio C — Dirección y Cómputo (625 m²)",
    ),
    (
        "escenarios/nivel_6_cancha_usos_multiples.png",
        "Nivel 6: Cancha Multideportiva (540 m²)",
    ),
]
loaded_scenarios = []
for p, t in SCENARIO_PATHS:
  if os.path.exists(p):
    im = Image.open(p).convert("RGB")
    loaded_scenarios.append((im, t))


def render_frame(f: int) -> Image.Image:
  base = create_base_frame()
  draw = ImageDraw.Draw(base, "RGBA")

  # --- ESCENA 1: INTRODUCCIÓN (0 a 105 frames / 0 a 3.5s) ---
  if f < 105:
    alpha = min(1.0, f / 15.0)

    # Badge superior
    badge_text = "🎮 PROYECTO EDUCATIVO OFICIAL · COBAEM CEMSaD 22"
    draw.rounded_rectangle(
        [(WIDTH // 2 - 320, 140), (WIDTH // 2 + 320, 190)],
        radius=25,
        fill=(46, 125, 50, 160),
        outline=ACCENT_GREEN,
        width=2,
    )
    draw_centered_text(draw, 152, badge_text, font_badge, fill=ACCENT_GREEN)

    # Título Principal
    float_y = int(math.sin(f * 0.1) * 6)
    draw_centered_text(
        draw, 240 + float_y, "CAMPEONES DE LOS VALORES", font_title, TEXT_WHITE
    )

    # Subtítulo
    draw_centered_text(
        draw,
        360,
        "Videojuego Educativo en Perspectiva 3/4 & Visor BIM 3D",
        font_h2,
        TEXT_MUTED,
    )
    draw_centered_text(
        draw,
        420,
        "Colegio de Bachilleres del Estado de México — Plantel CEMSaD 22"
        " ENTHAVI",
        font_body,
        ACCENT_GOLD,
    )

    # Cajas de características
    pills = [
        "⚡ Godot 4.7",
        "📐 Escala Real 1m = 40px",
        "💖 Cultura de No Violencia",
        "📱 Controles Táctiles Android",
    ]
    px = 300
    for pill in pills:
      draw.rounded_rectangle(
          [(px, 580), (px + 300, 640)],
          radius=16,
          fill=(20, 45, 30, 200),
          outline=(82, 183, 136, 180),
          width=2,
      )
      bbox = draw.textbbox((0, 0), pill, font=font_body)
      pw = bbox[2] - bbox[0]
      draw.text(
          (px + (300 - pw) // 2, 595), pill, font=font_body, fill=TEXT_WHITE
      )
      px += 340

    draw_centered_text(
        draw,
        780,
        "⭐ Disponible en GitHub: Kineyo/valores-cobaem22",
        font_body,
        (255, 255, 255, 200),
    )

  # --- ESCENA 2: FILOSOFÍA Y LECTURA DEL README (105 a 225 frames / 3.5 a 7.5s) ---
  elif f < 225:
    draw_centered_text(
        draw,
        100,
        "LECTURA DEL README · MISIÓN FORMATIVA",
        font_badge,
        ACCENT_GREEN,
    )
    draw_centered_text(
        draw, 140, "Resolución Pacífica de Conflictos", font_h1, TEXT_WHITE
    )
    draw_centered_text(
        draw,
        220,
        "En este juego no se destruye a nadie: ¡los antivalores son redimidos"
        " con virtudes!",
        font_body,
        TEXT_MUTED,
    )

    # 3 Tarjetas comparativas
    cards = [
        ("❌ Grosería & Hostilidad", "🤝 ¡Amabilidad & Diálogo!", ACCENT_GOLD),
        ("❌ Acoso Escolar", "💖 ¡Respeto y Dignidad!", (59, 130, 246)),
        ("❌ Bullying & Exclusión", "🌟 ¡Empatía e Inclusión!", (16, 185, 129)),
    ]
    cx = 240
    for bad, good, col in cards:
      draw.rounded_rectangle(
          [(cx, 340), (cx + 440, 720)],
          radius=24,
          fill=(16, 42, 28, 230),
          outline=col,
          width=3,
      )

      # Antivalor
      draw.rounded_rectangle(
          [(cx + 30, 390), (cx + 410, 460)],
          radius=16,
          fill=(239, 68, 68, 60),
          outline=(239, 68, 68, 160),
          width=2,
      )
      draw.text(
          (cx + 50, 410), bad, font=get_font(22, True), fill=(252, 165, 165)
      )

      # Flecha
      draw.text(
          (cx + 200, 490), "⬇️", font=get_font(36, True), fill=ACCENT_GREEN
      )

      # Virtud redimida
      draw.rounded_rectangle(
          [(cx + 30, 560), (cx + 410, 660)],
          radius=16,
          fill=(46, 125, 50, 120),
          outline=col,
          width=2,
      )
      draw.text(
          (cx + 50, 585), good, font=get_font(23, True), fill=(255, 255, 255)
      )
      draw.text(
          (cx + 100, 625),
          "REGENERACIÓN PACÍFICA",
          font=get_font(15, True),
          fill=col,
      )

      cx += 500

    draw_centered_text(
        draw,
        830,
        "💡 Refuerzo positivo constante para fortalecer la convivencia escolar"
        " armónica",
        font_body,
        ACCENT_GOLD,
    )

  # --- ESCENA 3: LOS 6 ESCENARIOS REALES (225 a 360 frames / 7.5 a 12s) ---
  elif f < 360:
    draw_centered_text(
        draw, 80, "ARQUITECTURA E INFRAESTRUCTURA ESCOLAR", font_badge, ACCENT_GOLD
    )
    draw_centered_text(
        draw,
        120,
        "Los 6 Escenarios Oficiales de CEMSaD 22 ENTHAVI",
        font_h1,
        TEXT_WHITE,
    )
    draw_centered_text(
        draw,
        190,
        "Modelado topográfico exacto a escala sagrada: 1 metro lineal = 40"
        " píxeles",
        font_body,
        TEXT_MUTED,
    )

    # Mostrar escenario en rotación (uno cada 22 frames aprox)
    scenario_idx = ((f - 225) // 22) % len(loaded_scenarios)
    sc_img, sc_title = loaded_scenarios[scenario_idx]

    # Renderizar imagen con marco
    thumb = sc_img.copy()
    thumb.thumbnail((1100, 550))
    tw, th = thumb.size
    tx = (WIDTH - tw) // 2
    ty = 260 + (550 - th) // 2

    # Sombra y marco
    draw.rounded_rectangle(
        [(tx - 12, ty - 12), (tx + tw + 12, ty + th + 12)],
        radius=18,
        fill=(10, 30, 20, 220),
        outline=ACCENT_GREEN,
        width=3,
    )
    base.paste(thumb, (tx, ty))

    # Título del mapa actual
    draw = ImageDraw.Draw(base, "RGBA")
    draw_centered_text(draw, 860, f"📍 {sc_title}", font_h2, ACCENT_GOLD)
    draw_centered_text(
        draw,
        920,
        "📐 Visores interactivos incluidos: 'planos_interactivos.html' (CAD 2D)"
        " y 'plano_3d.html' (BIM 3D Three.js)",
        font_small,
        TEXT_WHITE,
    )

  # --- ESCENA 4: NOVEDAD MÓVIL Y JOYSTICKS (360 a 480 frames / 12 a 16s) ---
  elif f < 480:
    draw_centered_text(
        draw, 90, "NOVEDAD OFICIAL DE LA VERSIÓN MÓVIL", font_badge, (16, 185, 129)
    )
    draw_centered_text(
        draw,
        130,
        "📱 Joysticks Analógicos & Controles Táctiles",
        font_h1,
        TEXT_WHITE,
    )
    draw_centered_text(
        draw,
        200,
        "Diseñados específicamente para celulares y tablets en la versión"
        " Android APK",
        font_body,
        TEXT_MUTED,
    )

    # Teléfono simulado
    phone_box = [(420, 280), (1500, 780)]
    draw.rounded_rectangle(
        phone_box,
        radius=40,
        fill=(10, 30, 20, 240),
        outline=ACCENT_EMERALD,
        width=4,
    )

    # Mini HUD en pantalla simulada
    draw.rounded_rectangle(
        [(800, 310), (1120, 350)], radius=15, fill=(0, 0, 0, 160)
    )
    draw.text(
        (825, 320),
        "❤️ ❤️ ❤️  ·  CEMSaD 22",
        font=font_small,
        fill=(255, 255, 255),
    )

    # Joystick simulado (izquierda)
    joy_center = (620, 560)
    draw.circle(joy_center, 70, fill=(6, 20, 12, 180), outline=ACCENT_GREEN)
    # Movimiento del knob
    knob_x = int(math.cos(f * 0.12) * 28)
    knob_y = int(math.sin(f * 0.12) * 28)
    draw.circle(
        (joy_center[0] + knob_x, joy_center[1] + knob_y),
        34,
        fill=ACCENT_EMERALD,
        outline=(255, 255, 255),
    )
    draw.text(
        (510, 680),
        "🕹️ Joystick 8 Direcciones",
        font=font_body,
        fill=ACCENT_GREEN,
    )

    # Botón de Virtud simulado (derecha)
    btn_center = (1300, 560)
    pulse = 1.0 + math.sin(f * 0.2) * 0.08
    btn_r = int(58 * pulse)
    draw.circle(btn_center, btn_r, fill=(217, 119, 6, 220), outline=ACCENT_GOLD)
    draw.text(
        (btn_center[0] - 45, btn_center[1] - 12),
        "VIRTUD",
        font=font_badge,
        fill=TEXT_WHITE,
    )
    draw.text(
        (1210, 680), "✨ Botón de Disparo", font=font_body, fill=ACCENT_GOLD
    )

    draw_centered_text(
        draw,
        830,
        "✨ Detección automática de pantalla táctil y respuesta instantánea",
        font_body,
        TEXT_WHITE,
    )

  # --- ESCENA 5: LANZAMIENTO RELEASE v1.0 Y CIERRE (480 a 600 frames / 16 a 20s) ---
  else:
    draw.rounded_rectangle(
        [(WIDTH // 2 - 250, 90), (WIDTH // 2 + 250, 140)],
        radius=20,
        fill=(5, 150, 105, 220),
        outline=TEXT_WHITE,
        width=2,
    )
    draw_centered_text(
        draw, 103, "🚀 LANZAMIENTO OFICIAL v1.0", font_badge, TEXT_WHITE
    )

    draw_centered_text(
        draw, 170, "¡Descarga y Juega Ahora Mismo!", font_title, TEXT_WHITE
    )
    draw_centered_text(
        draw,
        280,
        "Paquetes ejecutables generados y firmados automáticamente por GitHub"
        " Actions CI/CD",
        font_body,
        TEXT_MUTED,
    )

    # 3 Tarjetas de descarga
    downloads = [
        ("📱 Android", "campeones_valores.apk", "22.6 MB", (16, 185, 129)),
        (
            "🐧 Linux x86_64",
            "campeones_valores_linux_x86_64.zip",
            "23.6 MB",
            (59, 130, 246),
        ),
        (
            "🪟 Windows 64-bit",
            "campeones_valores_windows_x86_64.zip",
            "29.4 MB",
            ACCENT_GOLD,
        ),
    ]
    dx = 230
    for os_name, fname, fsize, col in downloads:
      draw.rounded_rectangle(
          [(dx, 380), (dx + 440, 680)],
          radius=24,
          fill=(16, 42, 28, 230),
          outline=col,
          width=3,
      )
      draw.text(
          (dx + 50, 420), os_name, font=get_font(34, True), fill=(255, 255, 255)
      )
      draw.text(
          (dx + 50, 500), fname, font=get_font(18, True), fill=ACCENT_GREEN
      )
      draw.text(
          (dx + 50, 580),
          f"Tamaño: {fsize}",
          font=get_font(24, True),
          fill=col,
      )
      draw.text(
          (dx + 50, 625),
          "✅ Verificado & Listo",
          font=font_small,
          fill=TEXT_MUTED,
      )
      dx += 500

    draw_centered_text(
        draw,
        780,
        "⭐ Repositorio Oficial en GitHub: github.com/Kineyo/valores-cobaem22",
        font_h2,
        ACCENT_GOLD,
    )
    draw_centered_text(
        draw,
        860,
        "Colegio de Bachilleres del Estado de México — Plantel CEMSaD 22"
        " ENTHAVI",
        font_body,
        TEXT_WHITE,
    )

  return base


def main():
  output_mp4 = "video_presentacion.mp4"
  audio_path = "assets/audio/music_game.wav"

  print(
      f"Renderizando {TOTAL_FRAMES} frames ({TOTAL_FRAMES//FPS} segundos) a"
      f" {WIDTH}x{HEIGHT}..."
  )

  # Comando ffmpeg con entrada rawvideo por tubería y audio integrado
  cmd = [
      "ffmpeg",
      "-y",
      "-f",
      "rawvideo",
      "-vcodec",
      "rawvideo",
      "-s",
      f"{WIDTH}x{HEIGHT}",
      "-pix_fmt",
      "rgb24",
      "-r",
      str(FPS),
      "-i",
      "-",  # Entrada de video por pipe
  ]

  if os.path.exists(audio_path):
    cmd.extend([
        "-i",
        audio_path,
        "-t",
        str(TOTAL_FRAMES / FPS),
        "-c:a",
        "aac",
        "-b:a",
        "192k",
        "-af",
        f"afade=t=out:st={TOTAL_FRAMES/FPS - 1.5}:d=1.5",
    ])

  cmd.extend([
      "-c:v",
      "libx264",
      "-preset",
      "fast",
      "-crf",
      "20",
      "-pix_fmt",
      "yuv420p",
      output_mp4,
  ])

  proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)

  for i in range(TOTAL_FRAMES):
    if i % 60 == 0:
      print(f"  Frame {i}/{TOTAL_FRAMES} ({(i/TOTAL_FRAMES)*100:.1f}%)...")
    frame_img = render_frame(i)
    proc.stdin.write(frame_img.tobytes())

  proc.stdin.close()
  proc.wait()

  if proc.returncode == 0:
    size_mb = os.path.getsize(output_mp4) / (1024 * 1024)
    print(f"¡Video generado con éxito: {output_mp4} ({size_mb:.2f} MB)!")
  else:
    print(f"Error generando video, código de salida: {proc.returncode}")


if __name__ == "__main__":
  main()
