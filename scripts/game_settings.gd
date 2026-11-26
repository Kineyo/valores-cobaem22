extends Node

## Autoload: GameSettings
## Gestiona la dificultad global (vidas, velocidades, cooldowns) y la música de fondo persistente.

enum Difficulty { FACIL, NORMAL, DIFICIL }
enum GameMode { ARCADE, STORY }
enum CharacterSkin { MASCULINO = 0, FEMENINO = 1, PANTALON = 0, FALDA = 1 }

const DIFFICULTY_NAMES := ["Fácil", "Normal", "Difícil"]
const GAME_MODE_NAMES := ["Arcade", "Historia"]
const CHARACTER_NAMES := ["Masculino", "Femenino"]
const CHARACTER_FOLDERS := ["res://assets/characters/Masculino/", "res://assets/characters/Femenino/"]

## Parámetros de balance según el nivel de dificultad
const PRESETS := {
	Difficulty.FACIL: {
		"max_health": 5,
		"enemy_speed_mult": 0.85,
		"shot_cooldown": 0.28,
		"shot_scale": 1.0,
		"shot_speed": 540.0,
		"invulnerable_time": 1.3,
	},
	Difficulty.NORMAL: {
		"max_health": 3,
		"enemy_speed_mult": 1.25,
		"shot_cooldown": 0.32,
		"shot_scale": 1.0,
		"shot_speed": 500.0,
		"invulnerable_time": 0.85,
	},
	Difficulty.DIFICIL: {
		"max_health": 2,
		"enemy_speed_mult": 1.55,
		"shot_cooldown": 0.40,
		"shot_scale": 1.0,
		"shot_speed": 460.0,
		"invulnerable_time": 0.6,
	},
}

const HIMNO_OGG_PATH := "res://assets/audio/himno.ogg"
const UNDERTALE_BATTLE_PATH := "res://assets/audio/music_undertale_battle.wav"
const FINALE_SOULS_PATH := "res://assets/audio/music_finale_souls.wav"
const HARD_PERC_PATH := "res://assets/audio/music_hard_perc.wav"

const SOUNDTRACK_CATALOG := [
	{
		"id": "menu",
		"title": "Campana de Entrada (Menú Escolar)",
		"file_m": "res://assets/audio/music_menu_m.wav",
		"file_f": "res://assets/audio/music_menu_f.wav",
		"bpm": 126,
		"where": "Pantalla de Inicio y Selección de Personaje",
		"desc": "Motivo de campana Westminster escolar combinado con piano brillante y ritmo ágil."
	},
	{
		"id": "stage_1",
		"title": "Umbral del Plantel (Acceso y Edif. D)",
		"file_m": "res://assets/audio/music_stage_1_m.wav",
		"file_f": "res://assets/audio/music_stage_1_f.wav",
		"bpm": 142,
		"where": "Escenario 1 — Acceso, Caseta C.V. y Edificio D",
		"desc": "Tema Touhou escolar en Re menor con arpegios veloces y trompeta heroica (Masc) o flauta cristalina (Fem)."
	},
	{
		"id": "stage_2",
		"title": "Patio de Convivencia (Cafetería Edif. A)",
		"file_m": "res://assets/audio/music_stage_2_m.wav",
		"file_f": "res://assets/audio/music_stage_2_f.wav",
		"bpm": 146,
		"where": "Escenario 2 — Edificio A y Cafetería",
		"desc": "Ritmo alegre de receso escolar con líneas melódicas rápidas en Mi menor."
	},
	{
		"id": "stage_3",
		"title": "Marcha Cívica (Plaza de Honores)",
		"file_m": "res://assets/audio/music_stage_3_m.wav",
		"file_f": "res://assets/audio/music_stage_3_f.wav",
		"bpm": 150,
		"where": "Escenario 3 — Plaza Cívica y Escalinata Sur",
		"desc": "Marcha solemne pero enérgica en Do menor inspirada en ceremonias cívicas."
	},
	{
		"id": "stage_4",
		"title": "Silencio Conectado (Biblioteca Edif. B)",
		"file_m": "res://assets/audio/music_stage_4_m.wav",
		"file_f": "res://assets/audio/music_stage_4_f.wav",
		"bpm": 154,
		"where": "Escenario 4 — Edificio B y Biblioteca Digital",
		"desc": "Tema dinámico en La menor con semicorcheas digitales que evocan el combate contra el ciberacoso."
	},
	{
		"id": "stage_5",
		"title": "Código Íntegro (Taller de Cómputo Edif. C)",
		"file_m": "res://assets/audio/music_stage_5_m.wav",
		"file_f": "res://assets/audio/music_stage_5_f.wav",
		"bpm": 158,
		"where": "Escenario 5 — Edificio C, Cómputo y Dirección",
		"desc": "Compás veloz en Fa# menor con síncopas de teclado y bajo octavado Touhou."
	},
	{
		"id": "stage_6",
		"title": "Duela de Honor (Cancha Múltiple)",
		"file_m": "res://assets/audio/music_stage_6_m.wav",
		"file_f": "res://assets/audio/music_stage_6_f.wav",
		"bpm": 164,
		"where": "Escenario 6 — Cancha de Usos Múltiples",
		"desc": "Preludio deportivo de alta velocidad antes de enfrentar al Coloso Titanor."
	},
	{
		"id": "classroom",
		"title": "Tensión en el Aula (Salones Interiores)",
		"file_m": "res://assets/audio/music_classroom_m.wav",
		"file_f": "res://assets/audio/music_classroom_f.wav",
		"bpm": 148,
		"where": "Salones 1 al 6 — Laboratorio, Aulas, Biblioteca y Gimnasio",
		"desc": "Sonoridad cerrada de salón con timbre de cambio de clase y pulso urgente en Sol menor."
	},
	{
		"id": "boss",
		"title": "Choque de Antivalores (Jefes de Área)",
		"file_m": "res://assets/audio/music_boss_m.wav",
		"file_f": "res://assets/audio/music_boss_f.wav",
		"bpm": 168,
		"where": "Combate contra Apatyx, Desperdicius, Superbus, Ciber-Murmullus, Plagiatrix y Maestro Desinterés",
		"desc": "Tema frenético estilo ZUN con metales intensos, redobles de tarola y arpegios de tensión."
	},
	{
		"id": "boss_final",
		"title": "Último Hechizo: Coloso en la Duela (Titanor)",
		"file_m": "res://assets/audio/music_boss_final_m.wav",
		"file_f": "res://assets/audio/music_boss_final_f.wav",
		"bpm": 176,
		"where": "Batalla Danmaku Final contra Titanor (Cancha Múltiple)",
		"desc": "Duelo bullet-hell a 176 BPM con campanas escolares resonando entre ráfagas Danmaku."
	},
	{
		"id": "undertale_battle",
		"title": "Juicio del Corazón (Duelo Undertale)",
		"file_m": UNDERTALE_BATTLE_PATH,
		"file_f": UNDERTALE_BATTLE_PATH,
		"bpm": 148,
		"where": "Duelo especial estilo Undertale previo al Clímax de Corazones",
		"desc": "Tema original chiptune-rock en Re menor a 148 BPM compuesto para el duelo de esquive contra Titanor."
	},
	{
		"id": "finale_souls",
		"title": "Corazones de los Valores (Clímax 1 HP)",
		"file_m": FINALE_SOULS_PATH,
		"file_f": FINALE_SOULS_PATH,
		"bpm": 184,
		"where": "Escena clímax estilo Undertale cuando Titanor se quiebra a 1 HP",
		"desc": "Composición original heroica y emotiva a 184 BPM con cuerdas, arpegios y fanfarria de los 8 corazones."
	},
	{
		"id": "himno",
		"title": "Himno Institucional COBAEM",
		"file_m": HIMNO_OGG_PATH,
		"file_f": HIMNO_OGG_PATH,
		"bpm": 108,
		"where": "Ceremonia Final de Agradecimiento en la Cancha",
		"desc": "Himno oficial entonado al concluir la ceremonia y erradicar el bullying del plantel."
	}
]

var MUSIC_MENU: AudioStream
var MUSIC_GAME: AudioStream
var MUSIC_HIMNO: AudioStream
var MUSIC_UNDERTALE_BATTLE: AudioStream
var MUSIC_FINALE_SOULS: AudioStream
var MUSIC_HARD_PERC: AudioStream

const SILENT_DB := -80.0
const FADE_TIME := 0.6

var difficulty: int = Difficulty.NORMAL
var initial_difficulty: int = Difficulty.NORMAL
var game_mode: int = GameMode.ARCADE
var selected_character: int = CharacterSkin.MASCULINO
var selected_shot_style: int = -1 ## -1 = automático según personaje, 0 = Pulso Guinda, 1 = Destello Guinda
var _web_audio_unlocked: bool = false
var music_volume_db: float = -8.0
var sfx_volume_db: float = 0.0
var muted: bool = false
var unlocked_stage_max: int = 0
var selected_start_stage: int = 0
var best_records: Dictionary = {}
var current_track_id: String = "menu"

var _music: AudioStreamPlayer
var _music_perc_layer: AudioStreamPlayer
var _fade_tween: Tween
var _ducked: bool = false
var _stopping: bool = false
var _stream_cache: Dictionary = {}
var _stream_cache_order: Array[String] = []
var _active_allow_diff_fx: bool = true
var _active_track_bpm: float = 142.0

const MAX_STREAM_CACHE := 6
const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SCHEMA_VERSION := 2

var is_test_mode: bool = false
var last_save_error: Error = OK
var touch_controls_override: int = -1 ## -1 = automático, 0 = oculto, 1 = forzado visible
var _save_dirty: bool = false
var _save_debounce_left: float = 0.0
var _pause_owners: Dictionary = {}

static func is_headless_runtime() -> bool:
	return DisplayServer.get_name() == "headless"

func is_silent_headless() -> bool:
	return DisplayServer.get_name() == "headless" and not is_test_mode

func should_skip_window_ops() -> bool:
	return is_test_mode or DisplayServer.get_name() == "headless"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cmd_args := OS.get_cmdline_args()
	if cmd_args.has("-s") or cmd_args.has("--script"):
		is_test_mode = true
	load_settings()
	MUSIC_MENU = _load_audio_stream("res://assets/audio/music_menu.wav")
	MUSIC_GAME = _load_audio_stream("res://assets/audio/music_game.wav")
	MUSIC_FINALE_SOULS = _load_audio_stream(FINALE_SOULS_PATH)
	MUSIC_HARD_PERC = _load_audio_stream(HARD_PERC_PATH)

	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = 0.0
	add_child(_music)
	_music.finished.connect(_on_music_finished)

	_music_perc_layer = AudioStreamPlayer.new()
	_music_perc_layer.bus = "Music"
	_music_perc_layer.volume_db = -8.0
	add_child(_music_perc_layer)
	_music_perc_layer.finished.connect(_on_perc_finished)

	apply_audio_settings()
	_apply_app_icon()

func _process(delta: float) -> void:
	if _save_dirty:
		_save_debounce_left -= delta
		if _save_debounce_left <= 0.0:
			save_settings()

func _input(event: InputEvent) -> void:
	if _web_audio_unlocked or not OS.has_feature("web") or is_silent_headless():
		return
	var is_gesture := (event is InputEventKey and (event as InputEventKey).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if is_gesture:
		_web_audio_unlocked = true
		if _music and _music.stream and not _music.playing and not _stopping and not muted:
			_music.play()
		_sync_hard_perc_layer(difficulty)

func _apply_app_icon() -> void:
	if should_skip_window_ops():
		return
	var icon_path := "res://icon.jpeg"
	var img: Image = null
	if ResourceLoader.exists(icon_path):
		var tex := ResourceLoader.load(icon_path) as Texture2D
		if tex:
			img = tex.get_image()
	if img == null and FileAccess.file_exists(icon_path):
		img = Image.load_from_file(ProjectSettings.globalize_path(icon_path))
	if img == null or img.is_empty():
		return
	var copy_img: Image = img.duplicate()
	if copy_img.is_compressed():
		copy_img.decompress()
	if copy_img.get_width() > 256 or copy_img.get_height() > 256:
		copy_img.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	DisplayServer.window_set_icon(copy_img)

func _cache_audio_stream(path: String, stream: AudioStream) -> void:
	if _stream_cache.has(path):
		_stream_cache_order.erase(path)
	_stream_cache[path] = stream
	_stream_cache_order.append(path)
	while _stream_cache_order.size() > MAX_STREAM_CACHE:
		var evict_idx := 0
		var active_stream: AudioStream = _music.stream if _music else null
		var perc_stream: AudioStream = _music_perc_layer.stream if _music_perc_layer else null
		while evict_idx < _stream_cache_order.size() - 1:
			var candidate_key: String = _stream_cache_order[evict_idx]
			var candidate_stream: AudioStream = _stream_cache.get(candidate_key)
			if candidate_stream != active_stream and candidate_stream != perc_stream:
				break
			evict_idx += 1
		var evicted: String = _stream_cache_order[evict_idx]
		_stream_cache_order.remove_at(evict_idx)
		_stream_cache.erase(evicted)

func _load_audio_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if _stream_cache.has(path):
		_stream_cache_order.erase(path)
		_stream_cache_order.append(path)
		return _stream_cache[path] as AudioStream
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path) as AudioStream
		if res != null:
			_cache_audio_stream(path, res)
			return res
	if FileAccess.file_exists(path):
		var lower := path.to_lower()
		var loaded: AudioStream = null
		if lower.ends_with(".ogg"):
			loaded = AudioStreamOggVorbis.load_from_file(ProjectSettings.globalize_path(path))
		elif lower.ends_with(".wav"):
			loaded = AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(path))
		if loaded != null:
			_cache_audio_stream(path, loaded)
			return loaded
	return null

func _on_perc_finished() -> void:
	if _music_perc_layer and _music_perc_layer.stream and not _stopping and not muted and difficulty == Difficulty.DIFICIL and _active_allow_diff_fx and current_track_id != "menu":
		_music_perc_layer.play()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			save_settings()
			# Pausar stream musical en segundo plano para ahorrar batería y respetar el SO
			if _music and _music.playing:
				_music.stream_paused = true
			if _music_perc_layer and _music_perc_layer.playing:
				_music_perc_layer.stream_paused = true
		NOTIFICATION_APPLICATION_RESUMED:
			# Reanudar música suavemente al regresar a primer plano
			if _music and _music.stream_paused:
				_music.stream_paused = false
			if _music_perc_layer and _music_perc_layer.stream_paused:
				_music_perc_layer.stream_paused = false
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if OS.has_feature("mobile") or OS.has_feature("web"):
				save_settings()
				if _music and _music.playing:
					_music.stream_paused = true
				if _music_perc_layer and _music_perc_layer.playing:
					_music_perc_layer.stream_paused = true
		NOTIFICATION_APPLICATION_FOCUS_IN:
			if OS.has_feature("mobile") or OS.has_feature("web"):
				if _music and _music.stream_paused:
					_music.stream_paused = false
				if _music_perc_layer and _music_perc_layer.stream_paused:
					_music_perc_layer.stream_paused = false

func _exit_tree() -> void:
	save_settings()
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if _music:
		if _music.finished.is_connected(_on_music_finished):
			_music.finished.disconnect(_on_music_finished)
		_music.stop()
		_music.stream = null
		_music = null
	if _music_perc_layer:
		if _music_perc_layer.finished.is_connected(_on_perc_finished):
			_music_perc_layer.finished.disconnect(_on_perc_finished)
		_music_perc_layer.stop()
		_music_perc_layer.stream = null
		_music_perc_layer = null
	_stream_cache.clear()
	_stream_cache_order.clear()
	MUSIC_MENU = null
	MUSIC_GAME = null
	MUSIC_HIMNO = null
	MUSIC_UNDERTALE_BATTLE = null
	MUSIC_FINALE_SOULS = null
	MUSIC_HARD_PERC = null

static func sanitize_best_records(raw: Variant) -> Dictionary:
	var clean: Dictionary = {}
	if not (raw is Dictionary):
		return clean
	var src: Dictionary = raw as Dictionary
	for k in ["0", "1", "2"]:
		if not src.has(k):
			continue
		var entry = src[k]
		if not (entry is Dictionary):
			continue
		var d: Dictionary = entry as Dictionary
		var raw_time = d.get("best_time", -1.0)
		var b_time: float = -1.0
		if raw_time is int or raw_time is float:
			var t := float(raw_time)
			if not is_nan(t) and not is_inf(t) and t >= 0.0:
				b_time = t
		var raw_def = d.get("best_defeated", 0)
		var b_def: int = maxi(0, int(raw_def)) if (raw_def is int or raw_def is float) else 0
		var raw_comp = d.get("completions", 0)
		var comps: int = maxi(0, int(raw_comp)) if (raw_comp is int or raw_comp is float) else 0
		clean[k] = {
			"best_time": b_time,
			"best_defeated": b_def,
			"completions": comps,
		}
	return clean

func request_save_settings(delay: float = 0.35) -> void:
	_save_dirty = true
	_save_debounce_left = maxf(0.05, delay)

func save_settings() -> Error:
	_save_dirty = false
	_save_debounce_left = 0.0
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "schema_version", SETTINGS_SCHEMA_VERSION)
	cfg.set_value("game", "difficulty", difficulty)
	cfg.set_value("game", "game_mode", game_mode)
	cfg.set_value("game", "selected_character", selected_character)
	cfg.set_value("gameplay", "selected_shot_style", selected_shot_style)
	cfg.set_value("game", "unlocked_stage_max", unlocked_stage_max)
	cfg.set_value("game", "selected_start_stage", selected_start_stage)
	cfg.set_value("audio", "music_volume_db", music_volume_db)
	cfg.set_value("audio", "sfx_volume_db", sfx_volume_db)
	cfg.set_value("audio", "muted", muted)
	cfg.set_value("ui", "touch_controls_override", touch_controls_override)
	cfg.set_value("records", "best_records", best_records)
	var err := cfg.save(SETTINGS_PATH)
	last_save_error = err
	if err != OK:
		push_warning("GameSettings: error al guardar settings.cfg (%s)" % error_string(err))
	return err

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		var _schema_ver := int(cfg.get_value("meta", "schema_version", 1))
		difficulty = clampi(int(cfg.get_value("game", "difficulty", Difficulty.NORMAL)), 0, DIFFICULTY_NAMES.size() - 1)
		initial_difficulty = difficulty
		game_mode = clampi(int(cfg.get_value("game", "game_mode", GameMode.ARCADE)), 0, GAME_MODE_NAMES.size() - 1)
		selected_character = clampi(int(cfg.get_value("game", "selected_character", CharacterSkin.PANTALON)), 0, CHARACTER_NAMES.size() - 1)
		selected_shot_style = clampi(int(cfg.get_value("gameplay", "selected_shot_style", -1)), -1, 1)
		unlocked_stage_max = clampi(int(cfg.get_value("game", "unlocked_stage_max", 0)), 0, 5)
		selected_start_stage = clampi(int(cfg.get_value("game", "selected_start_stage", 0)), 0, unlocked_stage_max)
		music_volume_db = clampf(float(cfg.get_value("audio", "music_volume_db", -8.0)), -60.0, 6.0)
		sfx_volume_db = clampf(float(cfg.get_value("audio", "sfx_volume_db", 0.0)), -60.0, 6.0)
		muted = bool(cfg.get_value("audio", "muted", false))
		touch_controls_override = clampi(int(cfg.get_value("ui", "touch_controls_override", -1)), -1, 1)
		best_records = sanitize_best_records(cfg.get_value("records", "best_records", {}))
	apply_audio_settings()

func set_touch_controls_override(mode: int) -> void:
	touch_controls_override = clampi(mode, -1, 1)
	save_settings()

func request_pause(owner: StringName) -> void:
	_pause_owners[owner] = true
	_sync_tree_pause()

func release_pause(owner: StringName) -> void:
	_pause_owners.erase(owner)
	_sync_tree_pause()

func clear_all_pauses() -> void:
	_pause_owners.clear()
	_sync_tree_pause()

func has_pause_owner(owner: StringName) -> bool:
	return _pause_owners.has(owner)

func get_pause_owner_count() -> int:
	return _pause_owners.size()

func _sync_tree_pause() -> void:
	if is_inside_tree() and get_tree():
		get_tree().paused = not _pause_owners.is_empty()

func _on_music_finished() -> void:
	if _music and _music.stream and not _stopping:
		_music.play()

## Retorna un parámetro de configuración para la dificultad activa
func get_param(key: String) -> Variant:
	var safe_diff := clampi(difficulty, 0, DIFFICULTY_NAMES.size() - 1)
	return PRESETS[safe_diff][key]

## Establece la dificultad activa y actualiza la dificultad inicial registrada
func set_difficulty(value: int) -> void:
	difficulty = clampi(value, 0, DIFFICULTY_NAMES.size() - 1)
	initial_difficulty = difficulty
	_refresh_active_music_dynamics()
	save_settings()

## Establece el modo de juego activo (Arcade o Historia) y persiste la selección
func set_game_mode(mode: int) -> void:
	game_mode = clampi(mode, 0, GAME_MODE_NAMES.size() - 1)
	save_settings()

## Selecciona personaje (0 = Masculino, 1 = Femenino) y actualiza la variante musical si aplica
func set_selected_character(idx: int) -> void:
	selected_character = clampi(idx, 0, CHARACTER_NAMES.size() - 1)
	save_settings()
	if current_track_id == "menu":
		play_menu_music()

func set_selected_shot_style(style_idx: int) -> void:
	selected_shot_style = clampi(style_idx, -1, 1)
	save_settings()

func get_effective_shot_style() -> int:
	if selected_shot_style == 0 or selected_shot_style == 1:
		return selected_shot_style
	return clampi(selected_character, 0, 1)

## Retorna la escala de pitch/tempo según dificultad (Fácil pausado, Normal equilibrado, Difícil enérgico)
func get_difficulty_pitch_scale(diff_override: int = -1) -> float:
	var d := clampi(diff_override if diff_override >= 0 else difficulty, 0, 2)
	match d:
		Difficulty.FACIL:
			return 0.94
		Difficulty.DIFICIL:
			return 1.06
		_:
			return 1.00

func _get_track_entry(track_id: String) -> Dictionary:
	for entry in SOUNDTRACK_CATALOG:
		if entry["id"] == track_id:
			return entry
	return SOUNDTRACK_CATALOG[1]

func get_track_path(track_id: String, char_override: int = -1) -> String:
	var ch := clampi(char_override if char_override >= 0 else selected_character, 0, 1)
	var entry := _get_track_entry(track_id)
	return str(entry.get("file_f" if ch == 1 else "file_m", ""))

func _refresh_active_music_dynamics(diff_override: int = -1) -> void:
	var d := clampi(diff_override if diff_override >= 0 else difficulty, 0, 2)
	if _music:
		_music.pitch_scale = get_difficulty_pitch_scale(d) if _active_allow_diff_fx else 1.0
	_sync_hard_perc_layer(d)

func _sync_hard_perc_layer(d: int) -> void:
	if _music_perc_layer == null:
		return
	var should_play := _active_allow_diff_fx and d == Difficulty.DIFICIL and current_track_id != "menu" and not _stopping and not muted
	if should_play:
		if MUSIC_HARD_PERC == null:
			MUSIC_HARD_PERC = _load_audio_stream(HARD_PERC_PATH)
		if MUSIC_HARD_PERC != null:
			_music_perc_layer.stream = MUSIC_HARD_PERC
			_music_perc_layer.volume_db = -18.0 if _ducked else -8.0
			_music_perc_layer.pitch_scale = clampf((_active_track_bpm / 160.0) * get_difficulty_pitch_scale(d), 0.75, 1.35)
			if not is_silent_headless():
				if not _music_perc_layer.playing:
					_music_perc_layer.play()
	else:
		if _music_perc_layer.playing:
			_music_perc_layer.stop()

## Fija explícitamente la dificultad inicial al comenzar la campaña
func lock_initial_difficulty() -> void:
	initial_difficulty = clampi(difficulty, 0, DIFFICULTY_NAMES.size() - 1)

## Retorna el nombre legible de la dificultad activa
func difficulty_name() -> String:
	return DIFFICULTY_NAMES[clampi(difficulty, 0, DIFFICULTY_NAMES.size() - 1)]

## Retorna el nombre legible de la dificultad inicial con la que comenzó la partida
func get_initial_difficulty_name() -> String:
	return DIFFICULTY_NAMES[clampi(initial_difficulty, 0, DIFFICULTY_NAMES.size() - 1)]

## Retorna el nombre legible del modo de juego activo
func game_mode_name() -> String:
	return GAME_MODE_NAMES[clampi(game_mode, 0, GAME_MODE_NAMES.size() - 1)]

## Retorna el nombre legible del personaje/aspecto seleccionado
func character_name() -> String:
	return CHARACTER_NAMES[clampi(selected_character, 0, CHARACTER_NAMES.size() - 1)]

## Retorna true si el personaje seleccionado es femenino (CharacterSkin.FEMENINO)
func is_female_character() -> bool:
	return selected_character == CharacterSkin.FEMENINO

## Retorna la variante gramatical correspondiente al género del personaje seleccionado
func gender_text(male_text: String, female_text: String) -> String:
	return female_text if is_female_character() else male_text

## Retorna la ruta de la carpeta del personaje seleccionado
func character_folder() -> String:
	return CHARACTER_FOLDERS[clampi(selected_character, 0, CHARACTER_FOLDERS.size() - 1)]

func play_menu_music() -> void:
	play_track_by_id("menu")

func play_game_music() -> void:
	play_stage_music(selected_start_stage, false, false, false)

func play_stage_music(stage_index: int, is_classroom: bool = false, is_boss: bool = false, is_final_boss: bool = false) -> void:
	var track_id := "stage_%d" % clampi(stage_index + 1, 1, 6)
	if is_final_boss:
		track_id = "boss_final"
	elif is_boss:
		track_id = "boss"
	elif is_classroom:
		track_id = "classroom"
	play_track_by_id(track_id)

func play_undertale_battle_music() -> void:
	play_track_by_id("undertale_battle", -1, -1, false)

func play_finale_climax_music() -> void:
	play_track_by_id("finale_souls", -1, -1, false)

func play_himno_music() -> void:
	if MUSIC_HIMNO == null:
		MUSIC_HIMNO = _load_himno_stream()
	current_track_id = "himno"
	_active_allow_diff_fx = false
	if MUSIC_HIMNO != null:
		_play(MUSIC_HIMNO, false, 1)

func play_track_by_id(track_id: String, char_override: int = -1, diff_override: int = -1, allow_diff_fx: bool = true) -> void:
	current_track_id = track_id
	if track_id == "himno":
		_active_track_bpm = 108.0
		play_himno_music()
		return
	var entry := _get_track_entry(track_id)
	_active_track_bpm = float(entry.get("bpm", 142.0))
	var use_diff_fx := allow_diff_fx and (track_id != "finale_souls") and (track_id != "undertale_battle")
	var path := get_track_path(track_id, char_override)
	var st := _load_audio_stream(path)
	if st == null:
		st = MUSIC_MENU if track_id == "menu" else MUSIC_GAME
	if st != null:
		_play(st, use_diff_fx, diff_override)

func _load_himno_stream() -> AudioStream:
	if ResourceLoader.exists(HIMNO_OGG_PATH):
		var ogg_stream := load(HIMNO_OGG_PATH) as AudioStream
		if ogg_stream != null:
			return ogg_stream
	if FileAccess.file_exists(HIMNO_OGG_PATH):
		var loaded_ogg := AudioStreamOggVorbis.load_from_file(ProjectSettings.globalize_path(HIMNO_OGG_PATH))
		if loaded_ogg != null:
			return loaded_ogg
	return MUSIC_GAME

func apply_audio_settings() -> void:
	if AudioServer.get_bus_count() > 0:
		AudioServer.set_bus_mute(0, muted)
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, SILENT_DB if muted else music_volume_db)
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, SILENT_DB if muted else sfx_volume_db)
	if _music and (_fade_tween == null or not _fade_tween.is_valid()):
		_music.volume_db = (-10.0 if _ducked else 0.0)
	_sync_hard_perc_layer(difficulty)

func set_music_volume_db(db: float) -> void:
	music_volume_db = clampf(db, -60.0, 6.0)
	apply_audio_settings()
	request_save_settings()

func set_sfx_volume_db(db: float) -> void:
	sfx_volume_db = clampf(db, -60.0, 6.0)
	apply_audio_settings()
	request_save_settings()

func toggle_mute() -> bool:
	muted = not muted
	apply_audio_settings()
	save_settings()
	return muted

func unlock_stage(stage_idx: int) -> void:
	var clamped_idx := clampi(stage_idx, 0, 5)
	if clamped_idx > unlocked_stage_max:
		unlocked_stage_max = clamped_idx
		save_settings()

func set_selected_start_stage(stage_idx: int) -> void:
	selected_start_stage = clampi(stage_idx, 0, unlocked_stage_max)
	save_settings()

func record_campaign_completion(diff_idx: int, time_sec: float, defeated_count: int) -> Dictionary:
	var key := str(clampi(diff_idx, 0, DIFFICULTY_NAMES.size() - 1))
	var prev: Dictionary = {}
	if best_records.get(key) is Dictionary:
		prev = best_records[key]
	var prev_best_time := float(prev.get("best_time", -1.0))
	var prev_best_defeated := int(prev.get("best_defeated", 0))
	var new_best_time := time_sec if (prev_best_time < 0.0 or time_sec < prev_best_time) else prev_best_time
	var new_best_defeated := maxi(prev_best_defeated, defeated_count)
	var updated := {
		"best_time": new_best_time,
		"best_defeated": new_best_defeated,
		"completions": int(prev.get("completions", 0)) + 1
	}
	best_records[key] = updated
	save_settings()
	return updated

func get_record_for_difficulty(diff_idx: int) -> Dictionary:
	var key := str(clampi(diff_idx, 0, DIFFICULTY_NAMES.size() - 1))
	var rec = best_records.get(key, {})
	return rec if rec is Dictionary else {}

## Detiene la música aplicando un fundido suave
func stop_music(fade: float = FADE_TIME) -> void:
	if _music_perc_layer and _music_perc_layer.playing:
		_music_perc_layer.stop()
	if not _music or not _music.playing:
		return
	_stopping = true
	_ducked = false
	var tw := _fade_to(SILENT_DB, fade)
	tw.tween_callback(func() -> void:
		if _music:
			_music.stop()
		_stopping = false
	)

## Reduce temporalmente el volumen de la música (ej. al pausar el juego)
func duck_music(enabled: bool) -> void:
	if enabled == _ducked or _music == null or not _music.playing:
		return
	_ducked = enabled
	_fade_to(-10.0 if enabled else 0.0, 0.25)
	if _music_perc_layer and _music_perc_layer.playing:
		_music_perc_layer.volume_db = -18.0 if enabled else -8.0

## Reproduce un stream de audio con fundido cruzado si ya había música sonando
func _play(stream: AudioStream, allow_diff_fx: bool = true, diff_override: int = -1) -> void:
	_ducked = false
	_stopping = false
	_active_allow_diff_fx = allow_diff_fx
	if _music == null:
		return
	_refresh_active_music_dynamics(diff_override)
	if _music.stream == stream and _music.playing:
		_fade_to(0.0, 0.3)
		return
	if _music.playing:
		var tw := _fade_to(SILENT_DB, FADE_TIME * 0.5)
		tw.tween_callback(_start_stream.bind(stream, allow_diff_fx, diff_override))
		tw.tween_property(_music, "volume_db", 0.0, FADE_TIME)
	else:
		_start_stream(stream, allow_diff_fx, diff_override)
		_music.volume_db = SILENT_DB
		_fade_to(0.0, FADE_TIME)

func _start_stream(stream: AudioStream, allow_diff_fx: bool = true, diff_override: int = -1) -> void:
	_stopping = false
	_active_allow_diff_fx = allow_diff_fx
	_music.stream = stream
	_refresh_active_music_dynamics(diff_override)
	if is_silent_headless():
		return
	_music.play()
	var d := clampi(diff_override if diff_override >= 0 else difficulty, 0, 2)
	if _music_perc_layer and _music_perc_layer.stream and _active_allow_diff_fx and d == Difficulty.DIFICIL and current_track_id != "menu" and not muted:
		_music_perc_layer.play(0.0)

func _fade_to(db: float, time: float) -> Tween:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	if _music != null:
		_fade_tween.tween_property(_music, "volume_db", db, time)
	return _fade_tween
