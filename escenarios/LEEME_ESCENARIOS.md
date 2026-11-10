# 🗺️ Escenarios a Escala Real — CEMSaD 22 ENTHAVI (Perspectiva 3/4 Pixel Art)

Esta carpeta (`res://escenarios/`) contiene los **6 escenarios a escala arquitectónica real** del plantel **CEMSaD 22 ENTHAVI (COBAEM)**, diseñados a partir del levantamiento en `plano_3d.html` / `planos_interactivos.html` y las 52 fotografías reales en `assets/planos/`.

---

## 📏 Escala Arquitectónica Unificada (`1 metro = 40 píxeles`)

Para que el personaje principal (`32 × 42 px` en pantalla ≈ `1.05 m` de alto estilizado 3/4 y `22 × 14 px` de huella de pies ≈ `55 × 35 cm`) y el mobiliario escolar (puertas de `0.90 m = 36 px`, bancas, autos y jardineras) coincidan con las cotas reales del plano:

- **`1 metro lineal = 40 píxeles`** (`20 texeles` base reescalados `2×` con filtro `Nearest`).
- **`1 píxel = 2.5 cm`** (`1 texel de 2×2 px = 5.0 cm`).
- **`1 baldosa (tile) de 40 × 40 px = 1.00 m²` (`10,000 cm²`)**.

---

## 🏫 División del Plantel en 6 Escenarios Secuenciales (Ahorro de Recursos)

El plantel completo (`~4,472 m²`) está dividido en **6 zonas independientes** que se cargan de una en una en memoria (`LevelManager` + `Main.load_level()`) y avanzan automáticamente al llegar a la meta de cada escenario:

| # | Archivo en `res://escenarios/` | Dimensiones (px) | Escala Real (m) | Edificios y Espacios Incluidos (`SPACES_DB`) |
| :-: | :--- | :---: | :---: | :--- |
| **1** | `nivel_1_acceso_laboratorio.png` | `1440 × 880 px` | `36.0 × 22.0 m` | **Plaza de Acceso** (`14×8 m`, `112 m²`), **Caseta C.V.** (`3.0×2.5 m`, `7.5 m²`), **Muro COBAEM** con Colibrí EDOMEX y Osito Topiario, **Estacionamiento** (`22×12 m`, `264 m²`), **Captador Pluvial** (`5×5 m`, `25 m²`) y **Edificio D: Laboratorio** (`19.0×9.64 m`, `183.07 m²`: Lab `12.8×7.2 m`, Reactivos `3.8×3.6 m`, Almacén `3.8×3.4 m`). |
| **2** | `nivel_2_edificio_a_cafeteria.png` | `1600 × 800 px` | `40.0 × 20.0 m` | **Edificio A** (`35.00×9.69 m`, `339.19 m²`): **Cafetería** (`6.2×7.0 m`, `43.4 m²`), **Almacén** (`3.8×7.0 m`, `26.6 m²`), **Aula 1** (`8.0×7.0 m`, `56 m²`), **Aula 2** (`8.0×7.0 m`, `56 m²`), **Sanitarios H/M** (`3.0×7.0 m` c/u), Andador Norte con columnas guinda y pinos en espiral. |
| **3** | `nivel_3_plaza_civica_escalinata.png` | `1600 × 900 px` | `40.0 × 22.5 m` | **Plaza Cívica Techada** (`34.0×22.0 m`, `748.00 m²`, arco techo blanco a `9.5 m`), Muro de contención norte de piedra braza (`4.00 m` de desnivel), Lona del 20 Aniversario CEMSaD 22 / 30 Aniversario COBAEM y **Escalinata Monumental Poniente "S"** (`18.0×4.5 m`, `81.00 m²`) amarilla con alfardas guinda. |
| **4** | `nivel_4_edificio_b.png` | `1440 × 800 px` | `36.0 × 20.0 m` | **Terraza Superior (`+4.00 m`) — Edificio B** (`32.00×9.78 m`, `312.85 m²`): **Aula 3** (`8.0×7.2 m`, `57.6 m²`), **Aula 4** (`8.0×7.2 m`, `57.6 m²`), **Biblioteca** (`5.2×7.2 m`, `37.44 m²`), **Sala de Maestros** (`7.8×7.2 m`, `56.16 m²`), faldón de ladrillo rojo aparente y vista superior del domo blanco. |
| **5** | `nivel_5_edificio_c_computo.png` | `1440 × 880 px` | `36.0 × 22.0 m` | **Edificio C de 2 Niveles** (`32.00×9.78 m`, `625.70 m²`): **Planta Alta** con **Taller de Cómputo** (`16.0×7.2 m`, `115.2 m²`, trabes mostaza y mesas caoba), Escalera PA y **Aula 6** (`8.0×7.2 m`); **Planta Baja** con Enfermería (`3.8×3.6 m`), Orientación (`3.8×3.6 m`), Archivo (`3.8×3.6 m`), S.S. (`3.8×3.6 m`), **Dirección CEMSaD** (`4.2×7.2 m`), Fotocopiado (`3.8×3.6 m`), Escalera Principal (`3.8×3.6 m`), **Aula 5** (`8.0×7.2 m`) y **Asta Bandera**. |
| **6** | `nivel_6_cancha_usos_multiples.png` | `1440 × 900 px` | `36.0 × 22.5 m` | **Cancha de Usos Múltiples** (`30.0×18.0 m`, `540.00 m²`, concreto pulido con pintura deportiva azul/amarilla y tableros verdes con cuadro amarillo), **Zona de Bancas y Convivencia** (`26.0×10.0 m`, `260.00 m²`), **Barda Perimetral Oriente Acotada** (`52.00 m`) y Podio Dorado de la Gran Copa. |

---

## 🛠️ Regeneración de Escenarios

Todos los escenarios se generan de forma determinista mediante el script:

```bash
python3 tools/generate_scenarios.py
```
