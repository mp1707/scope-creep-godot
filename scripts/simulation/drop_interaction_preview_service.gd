class_name DropInteractionPreviewService
extends RefCounted

const BUSINESS_GOAL_DEFINITION_ID: String = "card.goal.business_goal"
const SALARY_DUE_FROM_SPRINT_VALUE: String = "salary_due_from_sprint"

const ActiveProcessingInteractionServiceScript: Script = preload("res://scripts/simulation/active_processing_interaction_service.gd")
const HiringLifecycleServiceScript: Script = preload("res://scripts/simulation/hiring_lifecycle_service.gd")
const ShopInteractionServiceScript: Script = preload("res://scripts/simulation/shop_interaction_service.gd")

var state: RunState = null
var content: ContentCatalog = null
var _recipe_engine: RecipeEngine = RecipeEngine.new()
var _processing_interactions: ActiveProcessingInteractionService = ActiveProcessingInteractionServiceScript.new() as ActiveProcessingInteractionService
var _shop_interactions: ShopInteractionService = ShopInteractionServiceScript.new() as ShopInteractionService
var _hiring_lifecycle: HiringLifecycleService = HiringLifecycleServiceScript.new() as HiringLifecycleService

func setup(run_state: RunState, content_catalog: ContentCatalog) -> void:
	state = run_state
	content = content_catalog
	_shop_interactions.setup(state, content)
	_hiring_lifecycle.setup(state, content)

func get_preview_stack_ids(card_id: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if state == null or content == null or not _can_interact_with_board():
		return result

	var moving_card_ids: PackedStringArray = _get_moving_card_ids(card_id)
	if moving_card_ids.is_empty():
		return result

	for stack: StackState in state.stacks.values():
		if _stack_contains_any(stack, moving_card_ids):
			continue
		if _can_drop_on_stack(moving_card_ids, stack):
			result.append(stack.stack_id)
	return result

func _can_drop_on_stack(moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	if target_stack == null or target_stack.card_ids.is_empty():
		return false

	if _can_drop_on_shop(moving_card_ids, target_stack):
		return true
	if _can_hire_offer_with_money_stack(moving_card_ids, target_stack):
		return true
	if _can_pay_employee_with_money(moving_card_ids, target_stack):
		return true
	if _can_pay_business_goal_with_money(moving_card_ids, target_stack):
		return true
	if _can_apply_processing_interaction(moving_card_ids, target_stack):
		return true
	return _can_form_recipe_stack(moving_card_ids, target_stack)

func _can_drop_on_shop(moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	var shop_card: CardInstance = _shop_interactions.find_shop_card_in_stack(target_stack)
	if shop_card == null:
		return false
	return _shop_interactions.can_drop_card_on_shop(moving_card_ids[0], moving_card_ids.size(), shop_card)

func _can_hire_offer_with_money_stack(moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	if not _can_interact_with_board() or not _are_all_money_cards(moving_card_ids):
		return false
	var offer: CardInstance = _hiring_lifecycle.find_offer_in_stack(target_stack)
	if offer == null:
		return false
	if _hiring_lifecycle.get_offer_target_employee_definition_id(offer).is_empty():
		return false
	return moving_card_ids.size() >= _get_offer_hire_cost_money_cards()

func _can_pay_employee_with_money(moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	if state.phase != ScopeEnums.RunPhase.PAYMENT:
		return false
	if moving_card_ids.size() != 1 or not _is_money_card_id(moving_card_ids[0]):
		return false
	return not _find_unpaid_employee_in_stack(target_stack).is_empty()

func _can_pay_business_goal_with_money(moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	if not _are_all_money_cards(moving_card_ids):
		return false
	var goal: CardInstance = _find_business_goal_in_stack(target_stack)
	if goal == null:
		return false
	return _get_business_goal_paid_money(goal) < _get_business_goal_required_money(goal)

func _can_apply_processing_interaction(moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	return _processing_interactions.calculate(moving_card_ids, target_stack, state, content).applied

func _can_form_recipe_stack(moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	var temporary_stack: StackState = StackState.new()
	temporary_stack.stack_id = target_stack.stack_id
	temporary_stack.base_position = target_stack.base_position
	temporary_stack.card_ids = target_stack.card_ids.duplicate()
	for card_id: String in moving_card_ids:
		temporary_stack.card_ids.append(card_id)

	var match_result: RecipeMatchResult = _recipe_engine.find_best_match(temporary_stack, state, content)
	return match_result.has_match()

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

func _find_unpaid_employee_in_stack(stack: StackState) -> String:
	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card != null and _requires_salary(card) and not state.paid_employee_ids.has(card.instance_id):
			return card.instance_id
	return ""

func _find_business_goal_in_stack(stack: StackState) -> CardInstance:
	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card != null and card.definition_id == BUSINESS_GOAL_DEFINITION_ID:
			return card
	return null

func _are_all_money_cards(card_ids: PackedStringArray) -> bool:
	if card_ids.is_empty():
		return false
	for card_id: String in card_ids:
		if not _is_money_card_id(card_id):
			return false
	return true

func _is_money_card_id(card_id: String) -> bool:
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return false
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	return definition != null and definition.tags.has("money")

func _requires_salary(card: CardInstance) -> bool:
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	if definition == null or definition.type != ScopeEnums.CardType.EMPLOYEE or not definition.tags.has("salary_required"):
		return false
	return int(card.values.get(SALARY_DUE_FROM_SPRINT_VALUE, state.sprint_index)) <= state.sprint_index

func _get_offer_hire_cost_money_cards() -> int:
	if content.balance == null:
		return 1
	return maxi(1, content.balance.poc4_offer_hire_cost_money_cards)

func _get_business_goal_paid_money(goal: CardInstance) -> int:
	return maxi(0, int(goal.values.get("paid_money", 0)))

func _get_business_goal_required_money(goal: CardInstance) -> int:
	return maxi(1, int(goal.values.get("required_money", _get_required_money_for_business_goal_index(_get_business_goal_index(goal)))))

func _get_business_goal_index(goal: CardInstance) -> int:
	return maxi(1, int(goal.values.get("goal_index", 1)))

func _get_required_money_for_business_goal_index(goal_index: int) -> int:
	var values: Array[int] = _get_business_goal_required_money_values()
	if goal_index <= values.size():
		return values[maxi(0, goal_index - 1)]
	return maxi(1, goal_index)

func _get_business_goal_required_money_values() -> Array[int]:
	if content.balance == null or content.balance.poc3_business_goal_required_money.is_empty():
		return [1, 2, 3, 4, 5]
	return content.balance.poc3_business_goal_required_money

func _can_interact_with_board() -> bool:
	return state.phase == ScopeEnums.RunPhase.SPRINT or state.phase == ScopeEnums.RunPhase.PAYMENT
