class_name AudioManagerNode
extends Node

## Hệ thống Âm thanh Toàn cục (Global Audio Manager)
## Quản lý phát hiệu ứng âm thanh SFX: Pháo nổ, súng máy, nổ tung, nhặt máu

var sfx_cannon: AudioStream
var sfx_mg: AudioStream
var sfx_explosion: AudioStream
var sfx_heal: AudioStream
var sfx_smoke: AudioStream
var sfx_radar: AudioStream

func _ready() -> void:
	if ResourceLoader.exists("res://assets/audio/cannon_fire.wav"):
		sfx_cannon = load("res://assets/audio/cannon_fire.wav")
	if ResourceLoader.exists("res://assets/audio/mg_fire.wav"):
		sfx_mg = load("res://assets/audio/mg_fire.wav")
	if ResourceLoader.exists("res://assets/audio/explosion.wav"):
		sfx_explosion = load("res://assets/audio/explosion.wav")
	if ResourceLoader.exists("res://assets/audio/heal.wav"):
		sfx_heal = load("res://assets/audio/heal.wav")
	if ResourceLoader.exists("res://assets/audio/smoke_deploy.wav"):
		sfx_smoke = load("res://assets/audio/smoke_deploy.wav")
	if ResourceLoader.exists("res://assets/audio/radar_ping.wav"):
		sfx_radar = load("res://assets/audio/radar_ping.wav")

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_cannon() -> void:
	play_sfx(sfx_cannon, 3.0, randf_range(0.92, 1.06))

func play_machinegun() -> void:
	play_sfx(sfx_mg, -2.0, randf_range(0.95, 1.1))

func play_explosion() -> void:
	play_sfx(sfx_explosion, 4.0, randf_range(0.9, 1.05))

func play_heal() -> void:
	play_sfx(sfx_heal, 2.0, 1.0)

func play_smoke() -> void:
	play_sfx(sfx_smoke, 3.5, randf_range(0.95, 1.05))

func play_radar_ping() -> void:
	play_sfx(sfx_radar, 4.0, 1.0)

func play_empty_click() -> void:
	play_sfx(sfx_mg, -6.0, 2.2)


