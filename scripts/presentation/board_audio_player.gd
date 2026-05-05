class_name BoardAudioPlayer
extends Node

const PLAYER_COUNT: int = 6

@export var drag_start_stream: AudioStream = preload("res://assets/audio/Draw - Board Game.wav")
@export var card_flip_stream: AudioStream = preload("res://assets/audio/Flip Card - Board Game.wav")
@export var card_destroy_stream: AudioStream = preload("res://assets/audio/Exile - Fantasy - Eastern.wav")

var _players: Array[AudioStreamPlayer] = []
var _next_player_index: int = 0

func _ready() -> void:
	for index: int in PLAYER_COUNT:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "AudioStreamPlayer_%d" % index
		add_child(player)
		_players.append(player)

func _exit_tree() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()
		player.stream = null
	_players.clear()

func play_drag_started() -> void:
	_play(drag_start_stream)

func play_card_dropped() -> void:
	_play(card_flip_stream)

func play_card_spawned() -> void:
	_play(card_flip_stream)

func play_card_destroyed() -> void:
	_play(card_destroy_stream)

func _play(stream: AudioStream) -> void:
	if stream == null or _players.is_empty():
		return
	var player: AudioStreamPlayer = _players[_next_player_index]
	_next_player_index = (_next_player_index + 1) % _players.size()
	player.stop()
	player.stream = stream
	player.play()
