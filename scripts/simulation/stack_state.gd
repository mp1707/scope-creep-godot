class_name StackState
extends Resource

@export var stack_id: String = ""
@export var card_ids: PackedStringArray = PackedStringArray()
@export var base_position: Vector2 = Vector2.ZERO
@export var processing_state: ProcessingState = ProcessingState.new()

func has_card(card_id: String) -> bool:
	return card_ids.has(card_id)
