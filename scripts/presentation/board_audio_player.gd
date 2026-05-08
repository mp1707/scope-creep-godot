class_name BoardAudioPlayer
extends Node

const PLAYER_COUNT: int = 6

@export var default_create_stream: AudioStream = preload("res://assets/audio/Flip Card - Board Game.wav")
@export var default_drag_stream: AudioStream = preload("res://assets/audio/Draw - Board Game.wav")
@export var default_drop_stream: AudioStream = preload("res://assets/audio/Flip Card - Board Game.wav")
@export var default_stack_stream: AudioStream = preload("res://assets/audio/Flip Card - Board Game.wav")
@export var default_destroy_stream: AudioStream = preload("res://assets/audio/Exile - Fantasy - Eastern.wav")

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

func play_drag_started(card_definition: CardDefinition = null) -> void:
	_play(_get_drag_stream(card_definition))

func play_card_dropped(card_definition: CardDefinition = null) -> void:
	_play(_get_drop_stream(card_definition))

func play_card_stacked(card_definition: CardDefinition = null) -> void:
	_play(_get_stack_stream(card_definition))

func play_card_created(card_definition: CardDefinition = null) -> void:
	_play(_get_create_stream(card_definition))

func play_card_destroyed(card_definition: CardDefinition = null) -> void:
	_play(_get_destroy_stream(card_definition))

func _get_create_stream(card_definition: CardDefinition) -> AudioStream:
	var audio: CardAudioDefinition = _get_card_audio(card_definition)
	if audio != null and audio.create_stream != null:
		return audio.create_stream
	return default_create_stream

func _get_drag_stream(card_definition: CardDefinition) -> AudioStream:
	var audio: CardAudioDefinition = _get_card_audio(card_definition)
	if audio != null and audio.drag_stream != null:
		return audio.drag_stream
	return default_drag_stream

func _get_drop_stream(card_definition: CardDefinition) -> AudioStream:
	var audio: CardAudioDefinition = _get_card_audio(card_definition)
	if audio != null and audio.drop_stream != null:
		return audio.drop_stream
	return default_drop_stream

func _get_stack_stream(card_definition: CardDefinition) -> AudioStream:
	var audio: CardAudioDefinition = _get_card_audio(card_definition)
	if audio != null and audio.stack_stream != null:
		return audio.stack_stream
	return default_stack_stream

func _get_destroy_stream(card_definition: CardDefinition) -> AudioStream:
	var audio: CardAudioDefinition = _get_card_audio(card_definition)
	if audio != null and audio.destroy_stream != null:
		return audio.destroy_stream
	return default_destroy_stream

func _get_card_audio(card_definition: CardDefinition) -> CardAudioDefinition:
	if card_definition == null:
		return null
	return card_definition.audio

func _play(stream: AudioStream) -> void:
	if stream == null or _players.is_empty():
		return
	var player: AudioStreamPlayer = _players[_next_player_index]
	_next_player_index = (_next_player_index + 1) % _players.size()
	player.stop()
	player.stream = stream
	player.play()
