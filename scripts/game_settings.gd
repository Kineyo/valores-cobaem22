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
		"shot_scale": 1.4,
		"shot_speed": 540.0,
		"invulnerable_time": 1.3,
	},
	Difficulty.NORMAL: {
		"max_health": 3,
		"enemy_speed_mult": 1.25,
		"shot_cooldown": 0.32,
		"shot_scale": 1.15,
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

var MUSIC_MENU: AudioStream
var MUSIC_GAME: AudioStream
var MUSIC_HIMNO: AudioStream

const SILENT_DB := -40.0
const FADE_TIME := 0.6

var difficulty: int = Difficulty.NORMAL
var initial_difficulty: int = Difficulty.NORMAL
var game_mode: int = GameMode.ARCADE
var selected_character: int = CharacterSkin.MASCULINO
var music_volume_db: float = -8.0
var sfx_volume_db: float = 0.0
var muted: bool = false
var unlocked_stage_max: int = 0
var selected_start_stage: int = 0
var best_records: Dictionary = {}
var _sfx_hooked: bool = false

var _music: AudioStreamPlayer
var _fade_tween: Tween
var _ducked: bool = false
var _stopping: bool = false

const SETTINGS_PATH := "user://settings.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	MUSIC_MENU = load("res://assets/audio/music_menu.wav")
	MUSIC_GAME = load("res://assets/audio/music_game.wav")

	_music = AudioStreamPlayer.new()
	_music.volume_db = music_volume_db
	add_child(_music)
	# Respaldo de loop si el stream WAV no tiene el flag loop activado
	_music.finished.connect(_on_music_finished)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			save_settings()
			# Pausar stream musical en segundo plano para ahorrar batería y respetar el SO
			if _music and _music.playing:
				_music.stream_paused = true
		NOTIFICATION_APPLICATION_RESUMED:
			# Reanudar música suavemente al regresar a primer plano
			if _music and _music.stream_paused:
				_music.stream_paused = false

func _exit_tree() -> void:
	save_settings()
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if _music:
		if _music.finished.is_connected(_on_music_finished):
			_music.finished.disconnect(_on_music_finished)
		_music.stop()
		_music.stream = null
		_music.free()
		_music = null
	MUSIC_MENU = null
	MUSIC_GAME = null
	MUSIC_HIMNO = null

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "difficulty", difficulty)
	cfg.set_value("game", "game_mode", game_mode)
	cfg.set_value("game", "selected_character", selected_character)
	cfg.set_value("game", "unlocked_stage_max", unlocked_stage_max)
	cfg.set_value("game", "selected_start_stage", selected_start_stage)
	cfg.set_value("audio", "music_volume_db", music_volume_db)
	cfg.set_value("audio", "sfx_volume_db", sfx_volume_db)
	cfg.set_value("audio", "muted", muted)
	cfg.set_value("records", "best_records", best_records)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		difficulty = clampi(int(cfg.get_value("game", "difficulty", Difficulty.NORMAL)), 0, DIFFICULTY_NAMES.size() - 1)
		initial_difficulty = difficulty
		game_mode = clampi(int(cfg.get_value("game", "game_mode", GameMode.ARCADE)), 0, GAME_MODE_NAMES.size() - 1)
		selected_character = clampi(int(cfg.get_value("game", "selected_character", CharacterSkin.PANTALON)), 0, CHARACTER_NAMES.size() - 1)
		unlocked_stage_max = clampi(int(cfg.get_value("game", "unlocked_stage_max", 0)), 0, 5)
		selected_start_stage = clampi(int(cfg.get_value("game", "selected_start_stage", 0)), 0, unlocked_stage_max)
		music_volume_db = clampf(float(cfg.get_value("audio", "music_volume_db", -8.0)), -60.0, 6.0)
		sfx_volume_db = clampf(float(cfg.get_value("audio", "sfx_volume_db", 0.0)), -60.0, 6.0)
		muted = bool(cfg.get_value("audio", "muted", false))
		var loaded_rec = cfg.get_value("records", "best_records", {})
		if loaded_rec is Dictionary:
			best_records = loaded_rec
	apply_audio_settings()

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

## Retorna la ruta de la carpeta del personaje seleccionado
func character_folder() -> String:
	return CHARACTER_FOLDERS[clampi(selected_character, 0, CHARACTER_FOLDERS.size() - 1)]

func play_menu_music() -> void:
	_play(MUSIC_MENU)

func play_game_music() -> void:
	_play(MUSIC_GAME)

func play_himno_music() -> void:
	if MUSIC_HIMNO == null:
		MUSIC_HIMNO = _load_himno_stream()
	if MUSIC_HIMNO != null:
		_play(MUSIC_HIMNO)

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
	if _music:
		_music.volume_db = SILENT_DB if muted else music_volume_db
	if is_inside_tree() and get_tree():
		if not _sfx_hooked:
			_sfx_hooked = true
			if not get_tree().node_added.is_connected(_on_tree_node_added):
				get_tree().node_added.connect(_on_tree_node_added)
		if get_tree().root:
			_apply_sfx_volume_recursive(get_tree().root)

func _on_tree_node_added(node: Node) -> void:
	_apply_sfx_volume_recursive(node)

func _apply_sfx_volume_recursive(node: Node) -> void:
	if node is AudioStreamPlayer:
		var asp := node as AudioStreamPlayer
		if asp != _music and asp.name != "HimnoAudio":
			if not asp.has_meta("_base_vol_db"):
				asp.set_meta("_base_vol_db", asp.volume_db)
			var base_vol := float(asp.get_meta("_base_vol_db", asp.volume_db))
			asp.volume_db = clampf(base_vol + sfx_volume_db, -80.0, 12.0)
	for child in node.get_children():
		_apply_sfx_volume_recursive(child)

func set_music_volume_db(db: float) -> void:
	music_volume_db = clampf(db, -60.0, 6.0)
	if _music and not muted:
		_music.volume_db = music_volume_db
	save_settings()

func set_sfx_volume_db(db: float) -> void:
	sfx_volume_db = clampf(db, -60.0, 6.0)
	apply_audio_settings()
	save_settings()

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
	_fade_to(music_volume_db - (10.0 if enabled else 0.0), 0.25)

## Reproduce un stream de audio con fundido cruzado si ya había música sonando
func _play(stream: AudioStream) -> void:
	_ducked = false
	_stopping = false
	if _music == null:
		return
	if _music.stream == stream and _music.playing:
		_fade_to(music_volume_db, 0.3)
		return
	if _music.playing:
		var tw := _fade_to(SILENT_DB, FADE_TIME * 0.5)
		tw.tween_callback(_start_stream.bind(stream))
		tw.tween_property(_music, "volume_db", music_volume_db, FADE_TIME)
	else:
		_start_stream(stream)
		_music.volume_db = SILENT_DB
		_fade_to(music_volume_db, FADE_TIME)

func _start_stream(stream: AudioStream) -> void:
	_stopping = false
	_music.stream = stream
	_music.play()

func _fade_to(db: float, time: float) -> Tween:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	if _music != null:
		_fade_tween.tween_property(_music, "volume_db", db, time)
	return _fade_tween
