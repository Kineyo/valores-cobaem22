extends RefCounted
class_name AssetLoader

## Utilidad centralizada para carga resiliente de texturas desde res:// o archivos externos sin .import.

static func load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path)
		if res is Texture2D:
			return res
	var global_path := ProjectSettings.globalize_path(path)
	var candidate := ""
	if FileAccess.file_exists(path):
		candidate = path
	elif not global_path.is_empty() and FileAccess.file_exists(global_path):
		candidate = global_path
	if not candidate.is_empty():
		var img := Image.load_from_file(candidate)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

static func load_first_texture(paths: Array) -> Texture2D:
	for raw_path in paths:
		var tex := load_texture(str(raw_path))
		if tex != null:
			return tex
	return null
