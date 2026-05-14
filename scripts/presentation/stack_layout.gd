class_name StackLayout
extends RefCounted

var card_size: Vector2 = Vector2(144.0, 196.0)
var stack_offset: Vector2 = Vector2(0.0, 26.0)

func get_card_position(stack: StackState, card_id: String) -> Vector2:
	var index: int = stack.card_ids.find(card_id)
	if index < 0:
		return stack.base_position
	return stack.base_position + stack_offset * float(index)

func get_stack_rect(stack: StackState) -> Rect2:
	if stack.card_ids.is_empty():
		return Rect2(stack.base_position, card_size)

	var bottom_position: Vector2 = stack.base_position + stack_offset * float(stack.card_ids.size() - 1)
	var min_position: Vector2 = Vector2(
		minf(stack.base_position.x, bottom_position.x),
		minf(stack.base_position.y, bottom_position.y)
	)
	var max_position: Vector2 = Vector2(
		maxf(stack.base_position.x + card_size.x, bottom_position.x + card_size.x),
		maxf(stack.base_position.y + card_size.y, bottom_position.y + card_size.y)
	)
	return Rect2(min_position, max_position - min_position)
