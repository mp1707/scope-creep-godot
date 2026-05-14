class_name HiringLifecycleService
extends RefCounted

var state: RunState = null
var content: ContentCatalog = null

func setup(run_state: RunState, content_catalog: ContentCatalog) -> void:
	state = run_state
	content = content_catalog

func try_hire_offer_with_money_stack(
	card: CardInstance,
	moving_card_ids: PackedStringArray,
	target_stack: StackState,
	hire_cost: int,
	salary_due_from_sprint: int,
	consume_money_card: Callable,
	remove_card: Callable,
	spawn_card: Callable,
	spawn_attached_card: Callable,
	move_existing_cards: Callable,
	get_spawn_position: Callable,
	refresh_payment_states: Callable
) -> bool:
	if not _can_interact_with_board():
		return false
	if not is_money_card(card):
		return false
	if not are_all_money_cards(moving_card_ids):
		return false

	var offer: CardInstance = find_offer_in_stack(target_stack)
	if offer == null:
		return false
	var target_employee_definition_id: String = get_offer_target_employee_definition_id(offer)
	if target_employee_definition_id.is_empty():
		return false

	if moving_card_ids.size() < hire_cost:
		return false

	var spawn_position: Vector2 = get_spawn_position.call(target_stack.stack_id, 0) as Vector2
	var leftover_position: Vector2 = get_spawn_position.call(target_stack.stack_id, 1) as Vector2
	var consumed_money_ids: PackedStringArray = PackedStringArray()
	var leftover_money_ids: PackedStringArray = PackedStringArray()
	for index: int in moving_card_ids.size():
		if index < hire_cost:
			consumed_money_ids.append(moving_card_ids[index])
		else:
			leftover_money_ids.append(moving_card_ids[index])

	for consumed_money_id: String in consumed_money_ids:
		consume_money_card.call(consumed_money_id)
	remove_card.call(offer.instance_id)

	var employee: CardInstance = spawn_card.call(target_employee_definition_id, spawn_position) as CardInstance
	if employee != null:
		employee.values["salary_due_from_sprint"] = salary_due_from_sprint
		spawn_attached_card.call(employee.instance_id, "card.blocker.onboarding", "onboarding")

	if not leftover_money_ids.is_empty():
		move_existing_cards.call(leftover_money_ids, leftover_position)

	refresh_payment_states.call()
	return true

func find_offer_in_stack(stack: StackState) -> CardInstance:
	if stack == null or state == null:
		return null
	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card != null and is_offer_card(card):
			return card
	return null

func get_offer_target_employee_definition_id(offer: CardInstance) -> String:
	var offer_definition: CardDefinition = _get_definition(offer)
	if offer_definition == null:
		return ""
	var target_employee_definition_id: String = offer.values.get("target_employee_card_definition_id", "") as String
	if target_employee_definition_id.is_empty():
		target_employee_definition_id = offer_definition.base_values.get("target_employee_card_definition_id", "") as String
	if target_employee_definition_id.is_empty() or not content.has_card_definition(target_employee_definition_id):
		return ""
	return target_employee_definition_id

func are_all_money_cards(card_ids: PackedStringArray) -> bool:
	if card_ids.is_empty():
		return false
	for card_id: String in card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null or not is_money_card(card):
			return false
	return true

func is_money_card(card: CardInstance) -> bool:
	var definition: CardDefinition = _get_definition(card)
	return definition != null and definition.tags.has("money")

func is_offer_card(card: CardInstance) -> bool:
	var definition: CardDefinition = _get_definition(card)
	return definition != null and definition.tags.has("offer")

func _can_interact_with_board() -> bool:
	return state != null and (state.phase == ScopeEnums.RunPhase.SPRINT or state.phase == ScopeEnums.RunPhase.PAYMENT)

func _get_definition(card: CardInstance) -> CardDefinition:
	if card == null or content == null:
		return null
	return content.get_card_definition(card.definition_id)
