class_name ShopInteractionService
extends RefCounted

const BOOSTER_DEFINITION_ID_VALUE: String = "booster_definition_id"
const BOOSTER_PACK_DEFINITION_ID: String = "card.resource.booster_pack"
const BUGFIX_PATCH_DEFINITION_ID: String = "card.consumable.bugfix_patch"
const RECYCLING_BIN_DEFINITION_ID: String = "card.shop.recycling_bin"
const FREELANCE_SLOT_DEFINITION_ID: String = "card.shop.freelance_order"
const MONEY_DEFINITION_ID: String = "card.resource.money"
const FEATURE_DEFINITION_ID: String = "card.output.feature"
const CHECKED_FEATURE_DEFINITION_ID: String = "card.output.checked_feature"
const BUG_DEFINITION_ID: String = "card.problem.bug"
const RECYCLABLE_TAG: String = "recyclable"
const RECYCLING_CARD_COUNT: int = 3

var state: RunState = null
var content: ContentCatalog = null

func setup(run_state: RunState, content_catalog: ContentCatalog) -> void:
	state = run_state
	content = content_catalog

func try_buy_shop_with_money_stack(
	card: CardInstance,
	moving_card_ids: PackedStringArray,
	target_stack: StackState,
	consume_money_card: Callable,
	spawn_card: Callable,
	move_existing_cards: Callable,
	get_spawn_position: Callable,
	emit_stack_changed: Callable
) -> bool:
	if not _can_interact_with_board():
		return false
	if not is_money_card(card):
		return false
	if not are_all_cards_tagged(moving_card_ids, "money"):
		return false

	var target_shop_card: CardInstance = find_shop_card_in_stack(target_stack)
	if target_shop_card == null:
		return false
	var purchase: Dictionary = get_shop_purchase(target_shop_card)
	if purchase.is_empty():
		return false

	var cost_money_cards: int = purchase["cost_money_cards"] as int
	if moving_card_ids.size() < cost_money_cards:
		return false

	var consumed_money_ids: PackedStringArray = PackedStringArray()
	var leftover_money_ids: PackedStringArray = PackedStringArray()
	for index: int in moving_card_ids.size():
		if index < cost_money_cards:
			consumed_money_ids.append(moving_card_ids[index])
		else:
			leftover_money_ids.append(moving_card_ids[index])

	for consumed_money_id: String in consumed_money_ids:
		consume_money_card.call(consumed_money_id)

	var spawned_card_definition_id: String = purchase["spawned_card_definition_id"] as String
	var spawned_card: CardInstance = spawn_card.call(spawned_card_definition_id, get_spawn_position.call(target_stack.stack_id, 0)) as CardInstance
	if spawned_card != null:
		var copied_values: Dictionary = purchase.get("values", {}) as Dictionary
		for key: Variant in copied_values.keys():
			spawned_card.values[key] = copied_values[key]

	if not leftover_money_ids.is_empty():
		move_existing_cards.call(leftover_money_ids, get_spawn_position.call(target_stack.stack_id, 1))

	emit_stack_changed.call(target_stack.stack_id)
	return true

func try_recycle_card_stack(
	moving_card_ids: PackedStringArray,
	target_stack: StackState,
	remove_card: Callable,
	spawn_card: Callable,
	move_existing_cards: Callable,
	get_spawn_position: Callable,
	emit_stack_changed: Callable
) -> bool:
	if not _can_interact_with_board():
		return false

	var target_shop_card: CardInstance = find_shop_card_in_stack(target_stack)
	if target_shop_card == null or not is_recycling_bin_card(target_shop_card):
		return false
	if moving_card_ids.size() < RECYCLING_CARD_COUNT:
		return false
	if not are_all_recyclable_cards(moving_card_ids):
		return false

	var consumed_card_ids: PackedStringArray = PackedStringArray()
	var leftover_card_ids: PackedStringArray = PackedStringArray()
	var first_consumed_index: int = moving_card_ids.size() - RECYCLING_CARD_COUNT
	for index: int in moving_card_ids.size():
		if index >= first_consumed_index:
			consumed_card_ids.append(moving_card_ids[index])
		else:
			leftover_card_ids.append(moving_card_ids[index])

	for consumed_card_id: String in consumed_card_ids:
		remove_card.call(consumed_card_id)

	spawn_card.call(MONEY_DEFINITION_ID, get_spawn_position.call(target_stack.stack_id, 0))

	if not leftover_card_ids.is_empty():
		move_existing_cards.call(leftover_card_ids, get_spawn_position.call(target_stack.stack_id, 1))

	emit_stack_changed.call(target_stack.stack_id)
	return true

func try_dump_freelance_feature_stack(
	moving_card_ids: PackedStringArray,
	target_stack: StackState,
	rng: RandomNumberGenerator,
	money_card_count: int,
	bug_chance: float,
	remove_card: Callable,
	spawn_card: Callable,
	get_spawn_position: Callable,
	emit_stack_changed: Callable
) -> bool:
	if not _can_interact_with_board():
		return false

	var target_shop_card: CardInstance = find_shop_card_in_stack(target_stack)
	if target_shop_card == null or target_shop_card.definition_id != FREELANCE_SLOT_DEFINITION_ID:
		return false
	if not are_all_freelance_feature_cards(moving_card_ids):
		return false

	var spawn_index: int = 0
	rng.state = state.rng_state
	for moving_card_id: String in moving_card_ids:
		var moving_card: CardInstance = state.get_card(moving_card_id)
		if moving_card == null:
			continue
		var is_unchecked_feature: bool = moving_card.definition_id == FEATURE_DEFINITION_ID
		remove_card.call(moving_card_id)
		for money_index: int in money_card_count:
			spawn_card.call(MONEY_DEFINITION_ID, get_spawn_position.call(target_stack.stack_id, spawn_index))
			spawn_index += 1
		if is_unchecked_feature and rng.randf() <= bug_chance:
			spawn_card.call(BUG_DEFINITION_ID, get_spawn_position.call(target_stack.stack_id, spawn_index))
			spawn_index += 1
	state.rng_state = rng.state

	emit_stack_changed.call(target_stack.stack_id)
	return true

func can_drop_card_on_shop(card_id: String, moving_card_count: int, shop_card: CardInstance) -> bool:
	if state == null or content == null:
		return false
	if moving_card_count < 1:
		return false
	if not _can_interact_with_board():
		return false

	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return false

	var moving_card_ids: PackedStringArray = get_moving_card_ids(card_id)
	if moving_card_ids.size() != moving_card_count:
		return false
	if is_recycling_bin_card(shop_card):
		return moving_card_ids.size() >= RECYCLING_CARD_COUNT and are_all_recyclable_cards(moving_card_ids)
	if is_freelance_slot_card(shop_card):
		return are_all_freelance_feature_cards(moving_card_ids)

	return are_all_cards_tagged(moving_card_ids, "money") and moving_card_ids.size() >= get_shop_purchase_cost(shop_card)

func get_moving_card_ids(card_id: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if state == null:
		return result
	var card: CardInstance = state.get_card(card_id)
	if card == null:
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

func find_shop_card_in_stack(stack: StackState) -> CardInstance:
	if stack == null or state == null or content == null:
		return null
	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has("shop"):
			return card
	return null

func is_recycling_bin_card(card: CardInstance) -> bool:
	return card != null and card.definition_id == RECYCLING_BIN_DEFINITION_ID

func is_freelance_slot_card(card: CardInstance) -> bool:
	return card != null and card.definition_id == FREELANCE_SLOT_DEFINITION_ID

func is_money_card(card: CardInstance) -> bool:
	var definition: CardDefinition = _get_definition(card)
	return definition != null and definition.tags.has("money")

func are_all_cards_tagged(card_ids: PackedStringArray, tag: String) -> bool:
	if card_ids.is_empty():
		return false
	for card_id: String in card_ids:
		var card: CardInstance = state.get_card(card_id)
		var definition: CardDefinition = _get_definition(card)
		if definition == null or not definition.tags.has(tag):
			return false
	return true

func are_all_recyclable_cards(card_ids: PackedStringArray) -> bool:
	if card_ids.is_empty():
		return false
	for card_id: String in card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null or not card.parent_card_id.is_empty():
			return false
		var definition: CardDefinition = _get_definition(card)
		if definition == null or not definition.tags.has(RECYCLABLE_TAG):
			return false
	return true

func are_all_freelance_feature_cards(card_ids: PackedStringArray) -> bool:
	if card_ids.is_empty():
		return false
	for card_id: String in card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null or not card.parent_card_id.is_empty():
			return false
		if card.definition_id != FEATURE_DEFINITION_ID and card.definition_id != CHECKED_FEATURE_DEFINITION_ID:
			return false
	return true

func get_shop_purchase(shop_card: CardInstance) -> Dictionary:
	var definition: CardDefinition = _get_definition(shop_card)
	if definition == null:
		return {}

	var booster_id: String = shop_card.values.get(BOOSTER_DEFINITION_ID_VALUE, "") as String
	if booster_id.is_empty():
		booster_id = definition.base_values.get(BOOSTER_DEFINITION_ID_VALUE, "") as String
	if not booster_id.is_empty():
		var booster: BoosterDefinition = content.get_booster_definition(booster_id)
		if booster == null:
			return {}
		return {
			"cost_money_cards": maxi(1, booster.cost_money_cards),
			"spawned_card_definition_id": BOOSTER_PACK_DEFINITION_ID,
			"values": {BOOSTER_DEFINITION_ID_VALUE: booster_id},
		}

	if definition.tags.has("bugfix_patch_slot"):
		return {
			"cost_money_cards": 1,
			"spawned_card_definition_id": BUGFIX_PATCH_DEFINITION_ID,
			"values": {},
		}

	return {}

func get_shop_purchase_cost(shop_card: CardInstance) -> int:
	var purchase: Dictionary = get_shop_purchase(shop_card)
	if purchase.is_empty():
		return 100000
	return purchase["cost_money_cards"] as int

func _can_interact_with_board() -> bool:
	return state != null and (state.phase == ScopeEnums.RunPhase.SPRINT or state.phase == ScopeEnums.RunPhase.PAYMENT)

func _get_definition(card: CardInstance) -> CardDefinition:
	if card == null or content == null:
		return null
	return content.get_card_definition(card.definition_id)
