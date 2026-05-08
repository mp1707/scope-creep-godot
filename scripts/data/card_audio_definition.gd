class_name CardAudioDefinition
extends Resource

@export var create_stream: AudioStream
@export var drag_stream: AudioStream
@export var drop_stream: AudioStream
@export var stack_stream: AudioStream
@export var destroy_stream: AudioStream

func has_any_override() -> bool:
	return create_stream != null \
		or drag_stream != null \
		or drop_stream != null \
		or stack_stream != null \
		or destroy_stream != null
