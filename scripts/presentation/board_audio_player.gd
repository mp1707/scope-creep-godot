class_name BoardAudioPlayer
extends Node

const DRAG_START_PATH: String = "res://assets/audio/Draw - Board Game.wav"
const CARD_FLIP_PATH: String = "res://assets/audio/Flip Card - Board Game.wav"
const CARD_DESTROY_PATH: String = "res://assets/audio/Exile - Fantasy - Eastern.wav"
const PLAYER_COUNT: int = 6

var _players: Array[AudioStreamPlayer] = []
var _next_player_index: int = 0
var _drag_start_stream: AudioStreamWAV = null
var _card_flip_stream: AudioStreamWAV = null
var _card_destroy_stream: AudioStreamWAV = null

func _ready() -> void:
	_drag_start_stream = _load_wav(DRAG_START_PATH)
	_card_flip_stream = _load_wav(CARD_FLIP_PATH)
	_card_destroy_stream = _load_wav(CARD_DESTROY_PATH)
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
	_drag_start_stream = null
	_card_flip_stream = null
	_card_destroy_stream = null

func play_drag_started() -> void:
	_play(_drag_start_stream)

func play_card_dropped() -> void:
	_play(_card_flip_stream)

func play_card_spawned() -> void:
	_play(_card_flip_stream)

func play_card_destroyed() -> void:
	_play(_card_destroy_stream)

func _play(stream: AudioStream) -> void:
	if stream == null or _players.is_empty():
		return
	var player: AudioStreamPlayer = _players[_next_player_index]
	_next_player_index = (_next_player_index + 1) % _players.size()
	player.stop()
	player.stream = stream
	player.play()

func _load_wav(path: String) -> AudioStreamWAV:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if bytes.size() < 44:
		push_warning("Audio file could not be read as WAV: %s" % path)
		return null
	if not _matches_ascii(bytes, 0, "RIFF") or not _matches_ascii(bytes, 8, "WAVE"):
		push_warning("Audio file is not a RIFF/WAVE file: %s" % path)
		return null

	var offset: int = 12
	var audio_format: int = 0
	var channel_count: int = 1
	var mix_rate: int = 44100
	var bits_per_sample: int = 16
	var data: PackedByteArray = PackedByteArray()

	while offset + 8 <= bytes.size():
		var chunk_size: int = _read_u32_le(bytes, offset + 4)
		var chunk_data_offset: int = offset + 8
		if chunk_data_offset + chunk_size > bytes.size():
			break

		if _matches_ascii(bytes, offset, "fmt ") and chunk_size >= 16:
			audio_format = _read_u16_le(bytes, chunk_data_offset)
			channel_count = _read_u16_le(bytes, chunk_data_offset + 2)
			mix_rate = _read_u32_le(bytes, chunk_data_offset + 4)
			bits_per_sample = _read_u16_le(bytes, chunk_data_offset + 14)
		elif _matches_ascii(bytes, offset, "data"):
			data = bytes.slice(chunk_data_offset, chunk_data_offset + chunk_size)

		offset = chunk_data_offset + chunk_size + (chunk_size % 2)

	if audio_format != 1 or data.is_empty():
		push_warning("Only PCM WAV audio is supported by BoardAudioPlayer: %s" % path)
		return null

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.data = data
	stream.mix_rate = mix_rate
	stream.stereo = channel_count == 2
	if bits_per_sample == 8:
		stream.format = AudioStreamWAV.FORMAT_8_BITS
	else:
		stream.format = AudioStreamWAV.FORMAT_16_BITS
	return stream

func _matches_ascii(bytes: PackedByteArray, offset: int, text: String) -> bool:
	if offset + text.length() > bytes.size():
		return false
	for index: int in text.length():
		if bytes[offset + index] != text.unicode_at(index):
			return false
	return true

func _read_u16_le(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)

func _read_u32_le(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) \
		| (int(bytes[offset + 1]) << 8) \
		| (int(bytes[offset + 2]) << 16) \
		| (int(bytes[offset + 3]) << 24)
