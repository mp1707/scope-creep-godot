class_name DropInteractionPreviewService
extends RefCounted

var state: RunState = null
var can_drop_card_to_stack: Callable = Callable()

func setup(run_state: RunState, can_drop_resolver: Callable) -> void:
	state = run_state
	can_drop_card_to_stack = can_drop_resolver

func get_preview_stack_ids(card_id: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if state == null or not can_drop_card_to_stack.is_valid():
		return result

	var moving_card_ids: PackedStringArray = _get_moving_card_ids(card_id)
	if moving_card_ids.is_empty():
		return result

	for stack: StackState in state.stacks.values():
		if _stack_contains_any(stack, moving_card_ids):
			continue
		var can_drop: bool = can_drop_card_to_stack.call(card_id, stack.stack_id) as bool
		if can_drop:
			result.append(stack.stack_id)
	return result

func _get_moving_card_ids(card_id: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var card: CardInstance = state.get_card(card_id)
	if card == null or not card.parent_card_id.is_empty():
		return result
	var stack: StackState = state.get_stack(card.stack_id)
	if stack == null:
		return result
	var start_index: int = stack.card_ids.find(card_id)
	if start_index < 0:
		return result
	for index: int in range(start_index, stack.card_ids.size()):
		result.append(stack.card_ids[index])
	return result

func _stack_contains_any(stack: StackState, card_ids: PackedStringArray) -> bool:
	if stack == null:
		return false
	for card_id: String in card_ids:
		if stack.card_ids.has(card_id):
			return true
	return false
