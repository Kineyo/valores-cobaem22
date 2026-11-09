extends Node

## Autoload "GameSettings"
## Guarda la dificultad elegida en el menú y maneja la música de fondo
## (persiste entre escenas, así la música no se corta al reiniciar).

enum Difficulty { FACIL, NORMAL, DIFICIL }

const DIFFICULTY_NAMES := ["Fácil", "Normal", "Difícil"]

## Parámetros por dificultad.
## - max_health: corazones del jugador
## - enemy_speed_mult: multiplicador de velocidad de los antivalores
## - shot_cooldown: segundos entre disparos
## - shot_scale: tamaño del disparo (más grande = más fácil acertar)
## - shot_speed: velocidad del disparo
## - invulnerable_time: segundos de invulnerabilidad tras recibir daño
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

## Precargadas una sola vez (evita leer el disco en cada cambio de escena)
const MUSIC_MENU: AudioStream = preload("res://assets/audio/music_menu.wav")
const MUSIC_GAME: AudioStream = preload("res://assets/audio/music_game.wav")

## Volumen "apagado" usado en los fundidos
const SILENT_DB := -40.0
const FADE_TIME := 0.6

var difficulty: int = Difficulty.NORMAL
var music_volume_db: float = -8.0

var _music: AudioStreamPlayer
var _fade_tween: Tween
var _ducked: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.volume_db = music_volume_db
	add_child(_music)
	# Respaldo de loop: los WAV de música ya vienen con loop en su .import,
	# pero si se reimportan sin él, la canción vuelve a empezar igual.
	_music.finished.connect(_music.play)

func _exit_tree() -> void:
	if _music:
		if _music.finished.is_connected(_music.play):
			_music.finished.disconnect(_music.play)
		_music.stop()
		_music.stream = null

func get_param(key: String) -> Variant:
	return PRESETS[difficulty][key]

func difficulty_name() -> String:
	return DIFFICULTY_NAMES[difficulty]

func play_menu_music() -> void:
	_play(MUSIC_MENU)

func play_game_music() -> void:
	_play(MUSIC_GAME)

## Baja la música con un fundido (en vez de cortarla en seco).
func stop_music(fade: float = FADE_TIME) -> void:
	if not _music.playing:
		return
	_ducked = false
	_fade_to(SILENT_DB, fade).tween_callback(_music.stop)

## Baja un poco el volumen (p. ej. en la pausa) sin detener la música.
func duck_music(enabled: bool) -> void:
	if enabled == _ducked or not _music.playing:
		return
	_ducked = enabled
	_fade_to(music_volume_db - (10.0 if enabled else 0.0), 0.25)

func _play(stream: AudioStream) -> void:
	_ducked = false
	if _music.stream == stream and _music.playing:
		_fade_to(music_volume_db, 0.3)
		return
	if _music.playing:
		# Fundido cruzado: baja la canción actual, cambia y sube la nueva
		var tw := _fade_to(SILENT_DB, FADE_TIME * 0.5)
		tw.tween_callback(_start_stream.bind(stream))
		tw.tween_property(_music, "volume_db", music_volume_db, FADE_TIME)
	else:
		_start_stream(stream)
		_music.volume_db = SILENT_DB
		_fade_to(music_volume_db, FADE_TIME)

func _start_stream(stream: AudioStream) -> void:
	_music.stream = stream
	_music.play()

func _fade_to(db: float, time: float) -> Tween:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_music, "volume_db", db, time)
	return _fade_tween
