extends RefCounted
class_name CertificateGenerator

## Generador puro en GDScript de certificados institucionales PDF 1.4.
## Produce archivos vectoriales en Tamaño Carta (8.5x11" = 612x792 pt) y Tamaño 5x7 (5x7" = 360x504 pt)
## con el texto oficial del COBAEM CEMSaD 22 ENTHAVI, campo de nombre vacío y dificultad inicial.

const LETTER_WIDTH_PT := 612.0
const LETTER_HEIGHT_PT := 792.0
const SIZE_5X7_WIDTH_PT := 360.0
const SIZE_5X7_HEIGHT_PT := 504.0

const FILENAME_CARTA := "Reconocimiento_COBAEM22_Carta.pdf"
const FILENAME_5X7 := "Reconocimiento_COBAEM22_5x7.pdf"

const LOGO_TOP_LEFT_PATH := "res://assets/logos/logo cobaem.png"
const LOGO_TOP_RIGHT_PATH := "res://assets/logos/nuevo_logo_cobaem.jpeg"
const LOGO_CENTER_PATH := "res://assets/logos/cobaem-logo.jpeg"

static var _logo_pdf_cache: Dictionary = {}

const HEL_REGULAR_WIDTHS := {
	" ": 278, "!": 278, "\"": 355, "(": 333, ")": 333, ",": 278, "-": 333, ".": 278, "/": 278,
	":": 278, ";": 278, "_": 556, "|": 260, "·": 278, "–": 556, "—": 1000,
	"0": 556, "1": 556, "2": 556, "3": 556, "4": 556, "5": 556, "6": 556, "7": 556, "8": 556, "9": 556,
	"A": 667, "B": 667, "C": 722, "D": 722, "E": 667, "F": 611, "G": 778, "H": 722, "I": 278, "J": 500,
	"K": 667, "L": 556, "M": 833, "N": 722, "O": 778, "P": 667, "Q": 778, "R": 722, "S": 667, "T": 611,
	"U": 722, "V": 667, "W": 944, "X": 667, "Y": 667, "Z": 611,
	"Á": 667, "É": 667, "Í": 278, "Ó": 778, "Ú": 722, "Ñ": 722, "Ü": 722,
	"a": 556, "b": 556, "c": 500, "d": 556, "e": 556, "f": 278, "g": 556, "h": 556, "i": 222, "j": 222,
	"k": 500, "l": 222, "m": 833, "n": 556, "o": 556, "p": 556, "q": 556, "r": 333, "s": 500, "t": 278,
	"u": 556, "v": 500, "w": 722, "x": 500, "y": 500, "z": 500,
	"á": 556, "é": 556, "í": 222, "ó": 556, "ú": 556, "ñ": 556, "ü": 556,
}

const HEL_BOLD_WIDTHS := {
	" ": 278, "!": 333, "\"": 474, "(": 333, ")": 333, ",": 278, "-": 333, ".": 278, "/": 278,
	":": 333, ";": 333, "_": 556, "|": 280, "·": 333, "–": 556, "—": 1000,
	"0": 556, "1": 556, "2": 556, "3": 556, "4": 556, "5": 556, "6": 556, "7": 556, "8": 556, "9": 556,
	"A": 722, "B": 722, "C": 722, "D": 722, "E": 667, "F": 611, "G": 778, "H": 722, "I": 278, "J": 556,
	"K": 722, "L": 611, "M": 833, "N": 722, "O": 778, "P": 667, "Q": 778, "R": 722, "S": 667, "T": 611,
	"U": 722, "V": 667, "W": 944, "X": 667, "Y": 667, "Z": 611,
	"Á": 722, "É": 667, "Í": 278, "Ó": 778, "Ú": 722, "Ñ": 722, "Ü": 722,
	"a": 556, "b": 611, "c": 556, "d": 611, "e": 556, "f": 333, "g": 611, "h": 611, "i": 278, "j": 278,
	"k": 556, "l": 278, "m": 889, "n": 611, "o": 611, "p": 611, "q": 611, "r": 389, "s": 556, "t": 333,
	"u": 611, "v": 556, "w": 778, "x": 556, "y": 556, "z": 500,
	"á": 556, "é": 556, "í": 278, "ó": 611, "ú": 611, "ñ": 611, "ü": 611,
}

const CP1252_EXTRA := {
	8364: 128, # €
	8220: 147, # “
	8221: 148, # ”
	8211: 150, # –
	8212: 151, # —
}

## Construye el texto oficial exacto usando la dificultad inicial (o la provista) y nombre opcional
static func build_certificate_text(difficulty_name: String = "", recipient_name: String = "") -> String:
	var diff := difficulty_name.strip_edges()
	if diff.is_empty():
		diff = resolve_initial_difficulty()
	var clean_name := recipient_name.strip_edges()
	var holder := ":%s" % (" " + clean_name if not clean_name.is_empty() else "_______")
	return "El alumno/Padre de familia/Maestro%s ha logrado completar el juego en modo: %s y es reconocido como un asesor de los valores en el Cobaem Cemsad Plantel 22 Enthavi. Felicidades por el logro!" % [holder, diff]

## Extrae la dificultad inicial desde GameSettings cuando está disponible en el árbol de escena
static func resolve_initial_difficulty() -> String:
	var ml := Engine.get_main_loop()
	if ml is SceneTree:
		var root := (ml as SceneTree).root
		if root:
			var gs := root.get_node_or_null("GameSettings")
			if gs:
				if gs.has_method("get_initial_difficulty_name"):
					return str(gs.get_initial_difficulty_name())
				if gs.has_method("difficulty_name"):
					return str(gs.difficulty_name())
	return "Normal"

## Genera ambos archivos PDF (Tamaño Carta y Tamaño 5x7) y los guarda en almacenamiento / galería
static func generate_certificates(difficulty_name: String = "", extra_dir: String = "", recipient_name: String = "") -> Dictionary:
	var diff := difficulty_name.strip_edges()
	if diff.is_empty():
		diff = resolve_initial_difficulty()

	var body_text := build_certificate_text(diff, recipient_name)
	var bytes_carta := build_pdf_bytes(LETTER_WIDTH_PT, LETTER_HEIGHT_PT, diff, body_text, "Tamaño Carta (8.5 x 11 in)")
	var bytes_5x7 := build_pdf_bytes(SIZE_5X7_WIDTH_PT, SIZE_5X7_HEIGHT_PT, diff, body_text, "Tamaño 5x7 (5 x 7 in)")

	var candidate_dirs: Array[String] = []
	if not extra_dir.strip_edges().is_empty():
		candidate_dirs.append(extra_dir.strip_edges())

	# Directorios de almacenamiento del sistema (Documentos, Imágenes/Galería, Descargas)
	for sys_dir_type in [OS.SYSTEM_DIR_DOCUMENTS, OS.SYSTEM_DIR_PICTURES, OS.SYSTEM_DIR_DOWNLOADS]:
		var base_dir := OS.get_system_dir(sys_dir_type)
		if not base_dir.is_empty() and DirAccess.dir_exists_absolute(base_dir):
			candidate_dirs.append(base_dir.path_join("COBAEM22_Certificados"))

	# Almacenamiento interno persistente de Godot y carpeta local del proyecto si es escribible
	candidate_dirs.append(ProjectSettings.globalize_path("user://certificados"))
	if not OS.has_feature("web") and (OS.has_feature("editor") or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://"))):
		var proj_cert_dir := ProjectSettings.globalize_path("res://certificados")
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://")):
			candidate_dirs.append(proj_cert_dir)

	var saved_dirs: Array[String] = []
	var carta_paths: Array[String] = []
	var size_5x7_paths: Array[String] = []
	var primary_carta := ""
	var primary_5x7 := ""

	var seen: Dictionary = {}
	for raw_dir in candidate_dirs:
		var norm_dir := raw_dir.simplify_path()
		if norm_dir.is_empty() or seen.has(norm_dir):
			continue
		seen[norm_dir] = true

		if DirAccess.make_dir_recursive_absolute(norm_dir) != OK:
			continue

		var path_c := norm_dir.path_join(FILENAME_CARTA)
		var path_57 := norm_dir.path_join(FILENAME_5X7)
		var ok_c := _write_bytes(path_c, bytes_carta)
		var ok_57 := _write_bytes(path_57, bytes_5x7)
		if ok_c and ok_57:
			saved_dirs.append(norm_dir)
			carta_paths.append(path_c)
			size_5x7_paths.append(path_57)
			if primary_carta.is_empty():
				primary_carta = path_c
				primary_5x7 = path_57

	return {
		"success": not saved_dirs.is_empty(),
		"difficulty": diff,
		"body_text": body_text,
		"carta_path": primary_carta,
		"size_5x7_path": primary_5x7,
		"carta_paths": carta_paths,
		"size_5x7_paths": size_5x7_paths,
		"saved_dirs": saved_dirs,
	}

static func _write_bytes(abs_path: String, bytes: PackedByteArray) -> bool:
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(bytes)
	f.flush()
	f.close()
	return FileAccess.file_exists(abs_path)

## Construye los bytes completos de un documento PDF 1.4 de 1 página con tabla xref exacta e imágenes incrustadas
static func build_pdf_bytes(width_pt: float, height_pt: float, difficulty_name: String, body_text: String, format_label: String) -> PackedByteArray:
	var left_logo := _get_logo_pdf_data(LOGO_TOP_LEFT_PATH, 240)
	var right_logo := _get_logo_pdf_data(LOGO_TOP_RIGHT_PATH, 240)
	var center_logo := _get_logo_pdf_data(LOGO_CENTER_PATH, 240)
	var logo_dims := {
		"ImLeft": Vector2(float(left_logo.get("width", 1)), float(left_logo.get("height", 1))),
		"ImRight": Vector2(float(right_logo.get("width", 1)), float(right_logo.get("height", 1))),
		"ImCenter": Vector2(float(center_logo.get("width", 1)), float(center_logo.get("height", 1))),
	}

	var stream := _build_page_stream(width_pt, height_pt, difficulty_name, body_text, format_label, logo_dims)
	var subject_enc := _encode_pdf_winansi(body_text)

	var obj1 := "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
	var obj2 := "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"
	var obj3 := "3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %d %d] /Resources << /Font << /F1 4 0 R /F2 5 0 R >> /XObject << /ImLeft 8 0 R /ImRight 9 0 R /ImCenter 10 0 R >> >> /Contents 6 0 R >>\nendobj\n" % [int(roundf(width_pt)), int(roundf(height_pt))]
	var obj4 := "4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n"
	var obj5 := "5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\nendobj\n"
	var obj6 := "6 0 obj\n<< /Length %d >>\nstream\n%s\nendstream\nendobj\n" % [stream.length(), stream]
	var obj7 := "7 0 obj\n<< /Title (Reconocimiento COBAEM CEMSaD 22 Enthavi) /Subject (%s) >>\nendobj\n" % subject_enc
	var obj8 := _build_image_xobject(8, left_logo)
	var obj9 := _build_image_xobject(9, right_logo)
	var obj10 := _build_image_xobject(10, center_logo)

	var header := "%PDF-1.4\n"
	var objects := [obj1, obj2, obj3, obj4, obj5, obj6, obj7, obj8, obj9, obj10]
	var offsets: Array[int] = []
	var body := header
	for obj_str in objects:
		offsets.append(body.length())
		body += obj_str

	var xref_offset := body.length()
	var xref := "xref\n0 %d\n0000000000 65535 f \n" % (objects.size() + 1)
	for off in offsets:
		xref += "%010d 00000 n \n" % off

	var trailer := "trailer\n<< /Size %d /Root 1 0 R /Info 7 0 R >>\nstartxref\n%d\n%%%%EOF\n" % [objects.size() + 1, xref_offset]
	var full_pdf_ascii := body + xref + trailer
	return full_pdf_ascii.to_ascii_buffer()

## Carga una imagen de logo desde res:// (sin alterar archivos en disco) y la codifica para XObject /Image
static func _get_logo_pdf_data(res_path: String, max_dim: int = 240) -> Dictionary:
	var cache_key := "%s_%d" % [res_path, max_dim]
	if _logo_pdf_cache.has(cache_key):
		return _logo_pdf_cache[cache_key]

	var img: Image = null
	if ResourceLoader.exists(res_path):
		var res := ResourceLoader.load(res_path)
		if res is Texture2D:
			var tex_img := (res as Texture2D).get_image()
			if tex_img:
				img = tex_img.duplicate() as Image
	if img == null or img.is_empty():
		var abs_path := ProjectSettings.globalize_path(res_path)
		if FileAccess.file_exists(abs_path):
			img = Image.load_from_file(abs_path)

	if img == null or img.is_empty():
		push_warning("CertificateGenerator: No se pudo cargar el logo '%s'" % res_path)
		return {}

	if img.is_compressed():
		img.decompress()

	if img.detect_alpha() != Image.ALPHA_NONE:
		img.convert(Image.FORMAT_RGBA8)
		var iw := img.get_width()
		var ih := img.get_height()
		for py in range(ih):
			for px in range(iw):
				var c := img.get_pixel(px, py)
				var a := c.a
				img.set_pixel(px, py, Color(
					c.r * a + (1.0 - a),
					c.g * a + (1.0 - a),
					c.b * a + (1.0 - a),
					1.0
				))

	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)

	var orig_w := img.get_width()
	var orig_h := img.get_height()
	if orig_w > max_dim or orig_h > max_dim:
		var scale_f := float(max_dim) / float(maxi(orig_w, orig_h))
		var nw := maxi(1, int(roundf(float(orig_w) * scale_f)))
		var nh := maxi(1, int(roundf(float(orig_h) * scale_f)))
		img.resize(nw, nh, Image.INTERPOLATE_LANCZOS)

	var raw_rgb: PackedByteArray = img.get_data()
	var compressed: PackedByteArray = raw_rgb.compress(FileAccess.COMPRESSION_DEFLATE)
	var hex_stream := compressed.hex_encode() + ">"
	var data := {
		"width": img.get_width(),
		"height": img.get_height(),
		"hex": hex_stream,
	}
	_logo_pdf_cache[cache_key] = data
	return data

static func _build_image_xobject(obj_num: int, data: Dictionary) -> String:
	var w := int(data.get("width", 1))
	var h := int(data.get("height", 1))
	var hex_str := str(data.get("hex", "789c63f8ffff3f030005fe02fe>"))
	if data.is_empty():
		# Imagen blanca 1x1 de respaldo si el recurso faltase
		var empty_px := PackedByteArray([255, 255, 255])
		hex_str = empty_px.compress(FileAccess.COMPRESSION_DEFLATE).hex_encode() + ">"
		w = 1
		h = 1
	return "%d 0 obj\n<< /Type /XObject /Subtype /Image /Width %d /Height %d /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter [/ASCIIHexDecode /FlateDecode] /Length %d >>\nstream\n%s\nendstream\nendobj\n" % [obj_num, w, h, hex_str.length(), hex_str]

## Construye el stream de dibujo vectorial, logos y tipografía ajustada sin desbordamientos
static func _build_page_stream(w: float, h: float, difficulty_name: String, _body_text: String, format_label: String, logo_dims: Dictionary = {}) -> String:
	var compact := w < 450.0
	var margin := 20.0 if compact else 36.0
	var inner_m := margin + (7.0 if compact else 10.0)
	var cw := w - margin * 2.0
	var ch := h - margin * 2.0
	var icw := w - inner_m * 2.0
	var ich := h - inner_m * 2.0
	var cx := w * 0.5

	var header_h := 62.0 if compact else 84.0
	var header_y := h - inner_m - header_h

	var lines: Array[String] = []
	# Fondo crema pergamino
	lines.append("0.985 0.975 0.945 rg")
	lines.append("%.2f %.2f %.2f %.2f re f" % [margin, margin, cw, ch])

	# Marco exterior guinda institucional y marco interior dorado
	lines.append("0.42 0.11 0.18 RG")
	lines.append("%.2f w" % (2.8 if compact else 4.2))
	lines.append("%.2f %.2f %.2f %.2f re S" % [margin, margin, cw, ch])

	lines.append("0.78 0.63 0.28 RG")
	lines.append("%.2f w" % (1.2 if compact else 1.8))
	lines.append("%.2f %.2f %.2f %.2f re S" % [inner_m, inner_m, icw, ich])

	# Remates dorados en las esquinas inferiores
	var sq := 8.0 if compact else 12.0
	lines.append("0.78 0.63 0.28 rg")
	lines.append("%.2f %.2f %.2f %.2f re f" % [inner_m, inner_m, sq, sq])
	lines.append("%.2f %.2f %.2f %.2f re f" % [w - inner_m - sq, inner_m, sq, sq])

	# Encabezado oficial guinda
	lines.append("0.42 0.11 0.18 rg")
	lines.append("%.2f %.2f %.2f %.2f re f" % [inner_m, header_y, icw, header_h])

	lines.append("0.78 0.63 0.28 RG")
	lines.append("1.5 w")
	lines.append("%.2f %.2f m %.2f %.2f l S" % [inner_m, header_y, w - inner_m, header_y])

	# Logos en las esquinas superiores izquierda ('logo cobaem.png') y derecha ('nuevo_logo_cobaem.jpeg')
	var top_logo_box := 48.0 if compact else 68.0
	var top_side_pad := 6.0 if compact else 10.0
	var top_box_y := header_y + (header_h - top_logo_box) * 0.5
	var left_box_x := inner_m + top_side_pad
	var right_box_x := w - inner_m - top_side_pad - top_logo_box
	var logo_inner_pad := 2.5 if compact else 3.5

	for bx in [left_box_x, right_box_x]:
		lines.append("1.0 1.0 1.0 rg")
		lines.append("%.2f %.2f %.2f %.2f re f" % [bx, top_box_y, top_logo_box, top_logo_box])
		lines.append("0.78 0.63 0.28 RG 1.0 w")
		lines.append("%.2f %.2f %.2f %.2f re S" % [bx, top_box_y, top_logo_box, top_logo_box])

	var left_dim: Vector2 = logo_dims.get("ImLeft", Vector2.ONE)
	var right_dim: Vector2 = logo_dims.get("ImRight", Vector2.ONE)
	lines.append(_pdf_draw_image_fit("ImLeft", left_box_x + logo_inner_pad, top_box_y + logo_inner_pad, top_logo_box - logo_inner_pad * 2.0, top_logo_box - logo_inner_pad * 2.0, left_dim.x, left_dim.y))
	lines.append(_pdf_draw_image_fit("ImRight", right_box_x + logo_inner_pad, top_box_y + logo_inner_pad, top_logo_box - logo_inner_pad * 2.0, top_logo_box - logo_inner_pad * 2.0, right_dim.x, right_dim.y))

	# Texto del encabezado estrictamente confinado al área central entre ambos logos
	var header_text_max_w := icw - 2.0 * (top_side_pad + top_logo_box + (8.0 if compact else 12.0))
	lines.append(_pdf_centered_text(cx, header_y + header_h * 0.68, "COLEGIO DE BACHILLERES", "F2", 9.2 if compact else 14.2, "0.99 0.94 0.78", header_text_max_w))
	lines.append(_pdf_centered_text(cx, header_y + header_h * 0.46, "DEL ESTADO DE MÉXICO", "F2", 8.5 if compact else 12.6, "0.99 0.94 0.78", header_text_max_w))
	lines.append(_pdf_centered_text(cx, header_y + header_h * 0.20, "PLANTEL CEMSaD 22 ENTHAVI", "F2", 7.8 if compact else 11.4, "0.94 0.80 0.42", header_text_max_w))

	# Título y subtítulo restringidos dentro del ancho interno
	var content_max_w := icw - (20.0 if compact else 36.0)
	var title_y := header_y - (26.0 if compact else 44.0)
	lines.append(_pdf_centered_text(cx, title_y, "CONSTANCIA Y RECONOCIMIENTO", "F2", 13.5 if compact else 20.0, "0.35 0.09 0.15", content_max_w))

	var sub_y := title_y - (16.0 if compact else 24.0)
	lines.append(_pdf_centered_text(cx, sub_y, "CAMPEONES DE LOS VALORES · CULTURA DE PAZ ESCOLAR", "F1", 8.2 if compact else 11.5, "0.28 0.30 0.36", content_max_w))

	# Línea dorada separadora
	var sep_y := sub_y - (10.0 if compact else 15.0)
	var sep_half := icw * 0.36
	lines.append("0.78 0.63 0.28 RG 1.2 w")
	lines.append("%.2f %.2f m %.2f %.2f l S" % [cx - sep_half, sep_y, cx + sep_half, sep_y])

	# Cuadro central del cuerpo del certificado con autoajuste para evitar desbordamientos
	var f_body := 9.4 if compact else 13.6
	var line_step := 18.0 if compact else 26.0
	var wrapped: Array[String] = [
		"El alumno/Padre de familia/Maestro:_______",
		"ha logrado completar el juego en modo: %s" % difficulty_name,
		"y es reconocido como un asesor de los valores",
		"en el Cobaem Cemsad Plantel 22 Enthavi.",
		"Felicidades por el logro!"
	]

	var body_start_y := sep_y - (26.0 if compact else 44.0)
	for i in range(wrapped.size()):
		var font_choice := "F2" if (i == 0 or i == wrapped.size() - 1) else "F1"
		lines.append(_pdf_centered_text(cx, body_start_y - float(i) * line_step, wrapped[i], font_choice, f_body, "0.10 0.12 0.16", content_max_w))

	# Recuadro destacado de dificultad con ancho adaptado al texto interno
	var badge_y := body_start_y - float(wrapped.size()) * line_step - (14.0 if compact else 26.0)
	var badge_w := icw * (0.90 if compact else 0.84)
	var badge_h := 26.0 if compact else 36.0
	var badge_text := "Nivel Completado: %s   |   Asesor de Valores CEMSaD 22" % difficulty_name
	lines.append("0.93 0.91 0.85 rg")
	lines.append("%.2f %.2f %.2f %.2f re f" % [cx - badge_w * 0.5, badge_y - badge_h * 0.5, badge_w, badge_h])
	lines.append("0.78 0.63 0.28 RG 1.0 w")
	lines.append("%.2f %.2f %.2f %.2f re S" % [cx - badge_w * 0.5, badge_y - badge_h * 0.5, badge_w, badge_h])
	lines.append(_pdf_centered_text(cx, badge_y - (3.0 if compact else 4.0), badge_text, "F2", 8.2 if compact else 11.4, "0.42 0.11 0.18", badge_w - (14.0 if compact else 24.0)))

	# Logo central institucional ('cobaem-logo.jpeg') en reemplazo del texto 'COBAEM'
	var seal_size := 76.0 if compact else 112.0
	var seal_center_y := inner_m + (116.0 if compact else 182.0)
	var seal_x := cx - seal_size * 0.5
	var seal_y := seal_center_y - seal_size * 0.5
	var seal_pad := 3.5 if compact else 5.0
	lines.append("1.0 1.0 1.0 rg")
	lines.append("%.2f %.2f %.2f %.2f re f" % [seal_x, seal_y, seal_size, seal_size])
	lines.append("0.78 0.63 0.28 RG %.2f w" % (1.4 if compact else 1.8))
	lines.append("%.2f %.2f %.2f %.2f re S" % [seal_x, seal_y, seal_size, seal_size])
	lines.append("0.42 0.11 0.18 RG %.2f w" % (0.8 if compact else 1.0))
	lines.append("%.2f %.2f %.2f %.2f re S" % [seal_x + 2.0, seal_y + 2.0, seal_size - 4.0, seal_size - 4.0])

	var center_dim: Vector2 = logo_dims.get("ImCenter", Vector2.ONE)
	lines.append(_pdf_draw_image_fit("ImCenter", seal_x + seal_pad, seal_y + seal_pad, seal_size - seal_pad * 2.0, seal_size - seal_pad * 2.0, center_dim.x, center_dim.y))

	# Firmas al pie del certificado
	var sig_y := inner_m + (42.0 if compact else 64.0)
	var sig_w := 106.0 if compact else 170.0
	var left_sig_x := inner_m + (66.0 if compact else 118.0)
	var right_sig_x := w - inner_m - (66.0 if compact else 118.0)

	lines.append("0.25 0.25 0.30 RG 0.9 w")
	lines.append("%.2f %.2f m %.2f %.2f l S" % [left_sig_x - sig_w * 0.5, sig_y, left_sig_x + sig_w * 0.5, sig_y])
	lines.append("%.2f %.2f m %.2f %.2f l S" % [right_sig_x - sig_w * 0.5, sig_y, right_sig_x + sig_w * 0.5, sig_y])

	var f_sig := 7.0 if compact else 9.5
	lines.append(_pdf_centered_text(left_sig_x, sig_y - 12.0, "Dirección del Plantel", "F2", f_sig, "0.20 0.22 0.28", sig_w))
	lines.append(_pdf_centered_text(right_sig_x, sig_y - 12.0, "Coordinación de Valores", "F2", f_sig, "0.20 0.22 0.28", sig_w))

	# Pie técnico de formato
	var date_dict := Time.get_date_dict_from_system()
	var date_str := "%04d-%02d-%02d" % [int(date_dict.get("year", 2026)), int(date_dict.get("month", 1)), int(date_dict.get("day", 1))]
	lines.append(_pdf_centered_text(cx, inner_m + 7.0, "Temoaya, Estado de México · %s · Formato %s" % [date_str, format_label], "F1", 6.0 if compact else 8.0, "0.45 0.45 0.50", icw - 14.0))

	return "\n".join(lines)

static func _pdf_draw_image_fit(im_name: String, bx: float, by: float, bw: float, bh: float, img_w: float, img_h: float) -> String:
	var iw := maxf(1.0, img_w)
	var ih := maxf(1.0, img_h)
	var aspect := iw / ih
	var box_aspect := bw / bh
	var dw := bw
	var dh := bh
	if aspect > box_aspect:
		dh = bw / aspect
	else:
		dw = bh * aspect
	var dx := bx + (bw - dw) * 0.5
	var dy := by + (bh - dh) * 0.5
	return "q\n%.2f 0 0 %.2f %.2f %.2f cm\n/%s Do\nQ" % [dw, dh, dx, dy, im_name]

static func _pdf_centered_text(cx: float, y: float, text: String, font_id: String, font_size: float, rgb: String, max_width: float = 0.0) -> String:
	var is_bold := font_id == "F2"
	var eff_size := font_size
	var est_w := _estimate_text_width(text, eff_size, is_bold)
	if max_width > 0.0 and est_w > max_width:
		eff_size = maxf(4.5, eff_size * (max_width / est_w))
		est_w = _estimate_text_width(text, eff_size, is_bold)
	var x := maxf(8.0, cx - est_w * 0.5)
	var encoded := _encode_pdf_winansi(text)
	return "BT /%s %.2f Tf %s rg 1 0 0 1 %.2f %.2f Tm (%s) Tj ET" % [font_id, eff_size, rgb, x, y, encoded]

static func _estimate_text_width(text: String, font_size: float, is_bold: bool) -> float:
	var table: Dictionary = HEL_BOLD_WIDTHS if is_bold else HEL_REGULAR_WIDTHS
	var total := 0.0
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		if table.has(ch):
			total += float(table[ch]) / 1000.0
		elif ch == ch.to_upper() and ch != ch.to_lower():
			total += 0.68
		else:
			total += 0.55
	return total * font_size

static func _wrap_text(text: String, max_chars: int) -> Array[String]:
	var words := text.split(" ", false)
	var lines: Array[String] = []
	var cur := ""
	for w in words:
		if cur.is_empty():
			cur = w
		elif cur.length() + 1 + w.length() <= max_chars:
			cur += " " + w
		else:
			lines.append(cur)
			cur = w
	if not cur.is_empty():
		lines.append(cur)
	return lines

## Convierte Unicode a escapes octales WinAnsiEncoding (CP1252) de 7 bits para offset 1:1 en tabla xref
static func _encode_pdf_winansi(text: String) -> String:
	var out := ""
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		var code := text.unicode_at(i)
		if ch == "\\":
			out += "\\\\"
		elif ch == "(":
			out += "\\("
		elif ch == ")":
			out += "\\)"
		elif code >= 32 and code <= 126:
			out += ch
		elif CP1252_EXTRA.has(code):
			out += _to_octal_escape(int(CP1252_EXTRA[code]))
		elif code >= 160 and code <= 255:
			out += _to_octal_escape(code)
		else:
			out += " "
	return out

static func _to_octal_escape(val: int) -> String:
	var d2 := (val >> 6) & 7
	var d1 := (val >> 3) & 7
	var d0 := val & 7
	return "\\%d%d%d" % [d2, d1, d0]
