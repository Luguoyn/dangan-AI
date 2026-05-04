extends Node
# ============================================================
# AudioManager — 音频播放管理 (Autoload)
# ============================================================

@onready var _bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var _sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var _voice_player: AudioStreamPlayer = $VoicePlayer
@onready var _sfx_pool: Array[AudioStreamPlayer] = []

var _bgm_library: Dictionary = {}
var _sfx_library: Dictionary = {}
var _voice_library: Dictionary = {}
var _master_volume: float = 1.0
var _bgm_volume: float = 0.8
var _sfx_volume: float = 1.0
var _voice_volume: float = 1.0

func _ready() -> void:
	_create_audio_players()
	EventBus.bgm_requested.connect(_on_bgm_requested)
	EventBus.sfx_requested.connect(_on_sfx_requested)

func _create_audio_players() -> void:
	if not has_node("BGMPlayer"):
		var bgm = AudioStreamPlayer.new()
		bgm.name = "BGMPlayer"
		bgm.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
		add_child(bgm)
		_bgm_player = bgm

	if not has_node("SFXPlayer"):
		var sfx = AudioStreamPlayer.new()
		sfx.name = "SFXPlayer"
		sfx.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(sfx)
		_sfx_player = sfx

	if not has_node("VoicePlayer"):
		var voice = AudioStreamPlayer.new()
		voice.name = "VoicePlayer"
		voice.bus = "Voice" if AudioServer.get_bus_index("Voice") >= 0 else "Master"
		add_child(voice)
		_voice_player = voice

func register_bgm(bgm_id: String, stream: AudioStream) -> void:
	_bgm_library[bgm_id] = stream

func register_sfx(sfx_id: String, stream: AudioStream) -> void:
	_sfx_library[sfx_id] = stream

func register_voice(voice_id: String, stream: AudioStream) -> void:
	_voice_library[voice_id] = stream

func play_bgm(bgm_id: String, volume: float = 0.8) -> void:
	if not _bgm_library.has(bgm_id):
		return
	_bgm_player.stream = _bgm_library[bgm_id]
	_bgm_player.volume_db = linear_to_db(volume * _bgm_volume * _master_volume)
	_bgm_player.play()

func stop_bgm(fade_duration: float = 0.0) -> void:
	if fade_duration > 0.0:
		var tween = create_tween()
		tween.tween_property(_bgm_player, "volume_db", linear_to_db(0.001), fade_duration)
		tween.tween_callback(_bgm_player.stop)
	else:
		_bgm_player.stop()

func play_sfx(sfx_id: String, volume: float = 1.0) -> void:
	if not _sfx_library.has(sfx_id):
		return
	var player = _get_available_sfx_player()
	player.stream = _sfx_library[sfx_id]
	player.volume_db = linear_to_db(volume * _sfx_volume * _master_volume)
	player.play()

func play_voice(voice_id: String) -> void:
	if not _voice_library.has(voice_id):
		return
	_voice_player.stream = _voice_library[voice_id]
	_voice_player.volume_db = linear_to_db(_voice_volume * _master_volume)
	_voice_player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	var new_player = AudioStreamPlayer.new()
	new_player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(new_player)
	_sfx_pool.append(new_player)
	return new_player

func set_master_volume(volume: float) -> void:
	_master_volume = clamp(volume, 0.0, 1.0)

func set_bgm_volume(volume: float) -> void:
	_bgm_volume = clamp(volume, 0.0, 1.0)

func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clamp(volume, 0.0, 1.0)

func set_voice_volume(volume: float) -> void:
	_voice_volume = clamp(volume, 0.0, 1.0)

func _on_bgm_requested(action: String, bgm_id: String, volume: float, fade_duration: float) -> void:
	match action:
		"play":
			play_bgm(bgm_id, volume)
		"stop":
			stop_bgm()
		"fade_out":
			stop_bgm(fade_duration)

func _on_sfx_requested(sfx_id: String, volume: float) -> void:
	play_sfx(sfx_id, volume)
