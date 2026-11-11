extends Node

## Autoload: GameSettings
## Gestiona la dificultad global (vidas, velocidades, cooldowns) y la música de fondo persistente.

enum Difficulty { FACIL, NORMAL, DIFICIL }

const DIFFICULTY_NAMES := ["Fácil", "Normal", "Difícil"]

## Parámetros de balance según el nivel de dificultad
const PRESETS := {
	Difficulty.FACIL: {
		"max_health": 5,
		"enemy_speed_mult": 0.75,
		"shot_cooldown": 0.22,
		"shot_scale": 1.6,
		"shot_speed": 560.0,
		"invulnerable_time": 1.5,
	},
	Difficulty.NORMAL: {
		"max_health": 3,
		"enemy_speed_mult": 1.0,
		"shot_cooldown": 0.35,
		"shot_scale": 1.3,
		"shot_speed": 520.0,
		"invulnerable_time": 1.0,
	},
	Difficulty.DIFICIL: {
		"max_health": 2,
		"enemy_speed_mult": 1.4,
		"shot_cooldown": 0.55,
		"shot_scale": 1.0,
		"shot_speed": 480.0,
		"invulnerable_time": 0.7,
	},
}

var MUSIC_MENU: AudioStream
var MUSIC_GAME: AudioStream

const SILENT_DB := -40.0
const FADE_TIME := 0.6

var difficulty: int = Difficulty.NORMAL
var music_volume_db: float = -8.0

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

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "difficulty", difficulty)
	cfg.set_value("audio", "music_volume_db", music_volume_db)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		difficulty = cfg.get_value("game", "difficulty", Difficulty.NORMAL)
		music_volume_db = cfg.get_value("audio", "music_volume_db", -8.0)
		if _music:
			_music.volume_db = music_volume_db

func _on_music_finished() -> void:
	if _music and _music.stream and not _stopping:
		_music.play()

## Retorna un parámetro de configuración para la dificultad activa
func get_param(key: String) -> Variant:
	return PRESETS[difficulty][key]

## Retorna el nombre legible de la dificultad activa
func difficulty_name() -> String:
	return DIFFICULTY_NAMES[difficulty]

func play_menu_music() -> void:
	_play(MUSIC_MENU)

func play_game_music() -> void:
	_play(MUSIC_GAME)

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
	if enabled == _ducked or not _music.playing:
		return
	_ducked = enabled
	_fade_to(music_volume_db - (10.0 if enabled else 0.0), 0.25)

## Reproduce un stream de audio con fundido cruzado si ya había música sonando
func _play(stream: AudioStream) -> void:
	_ducked = false
	_stopping = false
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
	_fade_tween.tween_property(_music, "volume_db", db, time)
	return _fade_tween
