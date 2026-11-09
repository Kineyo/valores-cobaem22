# 🏆 Campeones de los Valores

> Videojuego educativo de aventura en perspectiva 3/4 (estilo RPG retro) desarrollado en **Godot Engine 4**, enfocado en la promoción de los valores escolares y la superación de conductas dañinas (antivalores).

---

## 🎮 Controles de Juego

| Acción | Teclado |
| :--- | :--- |
| **Moverse (8 direcciones)** | `W`, `A`, `S`, `D` o `Flechas de dirección` |
| **Disparo de Valores** | `Barra Espaciadora` (mantener para disparo continuo) |
| **Pausar / Menú** | `Escape` o `P` |
| **Reiniciar partida** | `R` o `Enter` |

---

## 🌟 Dinámica y Mecánicas

- **Héroe (Pixel):** Controlas al estudiante escolar que recorre la institución promoviendo valores.
- **Perspectiva 3/4:** Movimiento libre en el plano 2D con ordenamiento en profundidad (Y-sort) y retroalimentación de pisadas y polvo.
- **Ataque de Valores:** Lanza proyectiles de energía positiva en la dirección cardinal hacia donde mira el personaje, neutralizando los antivalores y transformándolos en virtudes.
- **Antivalores (Enemigos):**
  - **Grosería (Rojo):** Enemigo impulsivo que salta agitado. Al ser neutralizado proclama: *¡Amabilidad!*
  - **Acoso (Naranja):** Sombra acechante con mayor rango de visión que persigue al jugador. Al ser derrotado proclama: *¡Respeto!*
  - **Bullying (Morado):** Enemigo pesado e imponente que patrulla y embiste con fuerza. Al ser vencido proclama: *¡Empatía!*

---

## 🗺️ Niveles y Campaña

El juego cuenta con un sistema modular multinivel cargado dinámicamente:

1. **Nivel 1: Patio Escolar de los Valores:** Área verde al aire libre con jardineras, bancas, árboles y la fuente central.
2. **Nivel 2: Pasillos de la Escuela:** Salones temáticos (Empatía, Diálogo, Tolerancia, Cooperación), taquillas y periódicos murales.
3. **Nivel 3: Gimnasio y Auditorio de Campeones:** Cancha reglamentaria con banderines de valores y el podio final de la Gran Copa.

### ➕ Añadir nuevos escenarios
Puedes crear o importar nuevos escenarios guardando una imagen (`.png`, `.jpg`, `.webp`) en la carpeta `escenarios/`. El gestor `LevelManager` detectará automáticamente el archivo y configurará un nivel jugable con sus límites y metas.

---

## ⚙️ Modos de Dificultad

Configurables desde el menú principal con el ratón o con las teclas `1`, `2`, `3` o `← / →`:

| Dificultad | Vidas | Velocidad Enemiga | Frecuencia de Disparo | Escala de Disparo |
| :--- | :---: | :---: | :---: | :---: |
| **Fácil** | 5 ♥ | 75% | 0.22 s | Grande (1.6x) |
| **Normal** | 3 ♥ | 100% | 0.35 s | Media (1.3x) |
| **Difícil** | 2 ♥ | 140% | 0.55 s | Estándar (1.0x) |

---

## ⚡ Optimizaciones Técnicas

- **Renderizado GL Compatibility:** Configurado para bajo consumo de VRAM y compatibilidad universal (PC de bajos recursos, móvil y Web).
- **Pixel Snap 2D:** Ajuste de transformaciones y vértices al píxel exacto para evitar temblor o distorsión en movimiento.
- **Audio Chiptune Suave:** Loops de música en formato WAV generados proceduralmente sin dependencias pesadas.
- **Física 2D Optimizada:** Distancias al cuadrado en la IA enemiga para eliminar raíces cuadradas en cada frame, y caché de variables de progreso.
- **Assets Comprimidos:** Texturas PNG optimizadas sin pérdida de fidelidad visual.

---

## 🚀 Cómo Ejecutar en Godot 4

1. Clona o descarga este repositorio:
   ```bash
   git clone https://github.com/Kineyo/valores-cobaem22.git
   ```
2. Abre **Godot Engine 4.x** (compatible con 4.2 o superior).
3. Haz clic en **Importar** y selecciona el archivo `project.godot`.
4. Pulsa **F5** (o el botón de reproducción ▶) para iniciar el juego desde el menú principal.
