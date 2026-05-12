class_name EffectPipeline
extends RefCounted

func execute(effects: Array[EffectDefinition], context: EffectContext) -> void:
	for effect: EffectDefinition in effects:
		match effect.effect_type:
			"consume_input":
				_consume_input(effect, context)
			"remove_card":
				_remove_card(effect, context)
			"spawn_card":
				_spawn_card(effect, context)
			"spawn_money":
				_spawn_money(effect, context)
			"roll_chance":
				_roll_chance(effect, context)
			"set_card_value":
				_set_card_value(effect, context)
			"modify_card_value":
				_modify_card_value(effect, context)
			"launch_software":
				_launch_software(effect, context)
			"open_booster":
				_open_booster(effect, context)
			_:
				push_warning("Unknown effect_type '%s' on effect '%s'." % [effect.effect_type, effect.id])

func _consume_input(effect: EffectDefinition, context: EffectContext) -> void:
	var card_definition_id: String = effect.parameters.get("card_definition_id", "") as String
	var card: CardInstance = _find_card_in_stack(card_definition_id, context)
	if card != null:
		context.remove_card.call(card.instance_id)

func _remove_card(effect: EffectDefinition, context: EffectContext) -> void:
	var card_id: String = effect.parameters.get("card_id", "") as String
	if not card_id.is_empty():
		context.remove_card.call(card_id)
		return

	var card_definition_id: String = effect.parameters.get("card_definition_id", "") as String
	var card: CardInstance = _find_card_in_stack(card_definition_id, context)
	if card != null:
		context.remove_card.call(card.instance_id)

func _spawn_card(effect: EffectDefinition, context: EffectContext) -> void:
	if _should_skip_effect(effect, context):
		return
	var card_definition_id: String = effect.parameters.get("card_definition_id", "") as String
	var count: int = effect.parameters.get("count", 1) as int
	for index: int in count:
		var spawned_card: CardInstance = context.spawn_card.call(card_definition_id, _get_spawn_position(context, index)) as CardInstance
		_apply_spawn_parameters(spawned_card, effect, context)

func _spawn_money(effect: EffectDefinition, context: EffectContext) -> void:
	if _should_skip_effect(effect, context):
		return
	var count: int = _get_spawn_count(effect, context)
	for index: int in count:
		context.spawn_card.call("card.resource.money", _get_spawn_position(context, index))

func _roll_chance(effect: EffectDefinition, context: EffectContext) -> void:
	var chance: float = _get_chance(effect, context)
	if context.rng.randf() > chance:
		context.state.rng_state = context.rng.state
		return

	var card_definition_id: String = effect.parameters.get("card_definition_id", "") as String
	if not card_definition_id.is_empty():
		var spawn_index: int = effect.parameters.get("spawn_index", 0) as int
		var spawned_card: CardInstance = context.spawn_card.call(card_definition_id, _get_spawn_position(context, spawn_index)) as CardInstance
		_apply_spawn_parameters(spawned_card, effect, context)
	context.state.rng_state = context.rng.state

func _set_card_value(effect: EffectDefinition, context: EffectContext) -> void:
	var card_definition_id: String = effect.parameters.get("card_definition_id", "") as String
	var card: CardInstance = _find_card_in_stack(card_definition_id, context)
	if card == null:
		return

	var key: String = effect.parameters.get("key", "") as String
	if key.is_empty():
		return
	card.values[key] = effect.parameters.get("value", null)

func _modify_card_value(effect: EffectDefinition, context: EffectContext) -> void:
	var card_definition_id: String = effect.parameters.get("card_definition_id", "") as String
	var card: CardInstance = _find_card_in_stack(card_definition_id, context)
	if card == null:
		return

	var key: String = effect.parameters.get("key", "") as String
	if key.is_empty():
		return
	var delta: int = int(effect.parameters.get("delta", 0))
	card.values[key] = int(card.values.get(key, 0)) + delta

func _launch_software(effect: EffectDefinition, context: EffectContext) -> void:
	var software: CardInstance = _find_card_in_stack(ProductLifecycleService.SOFTWARE_DEFINITION_ID, context)
	if software == null:
		return

	var lifecycle: ProductLifecycleService = ProductLifecycleService.new()
	if not lifecycle.is_launch_ready(context.state):
		return

	var feature_count: int = lifecycle.get_feature_count(software)
	software.values[ProductLifecycleService.PRODUCT_STAGE_VALUE] = ProductLifecycleService.PRODUCT_STAGE_LIVE
	software.values[ProductLifecycleService.LAUNCH_FEATURE_COUNT_VALUE] = feature_count

	var customer_card_definition_id: String = effect.parameters.get("customer_card_definition_id", "card.value_source.customer") as String
	var customer_count: int = floori(float(feature_count) / float(_get_launch_features_per_start_customer(context)))
	for index: int in customer_count:
		context.spawn_card.call(customer_card_definition_id, _get_spawn_position(context, index))

	var goal_card_definition_id: String = effect.parameters.get("goal_card_definition_id", "card.goal.business_goal") as String
	if not goal_card_definition_id.is_empty():
		context.state.completed_business_goal_count = 0
		var goal: CardInstance = context.spawn_card.call(goal_card_definition_id, _get_spawn_position(context, customer_count)) as CardInstance
		if goal != null:
			goal.values["goal_index"] = 1
			goal.values["required_money"] = _get_business_goal_required_money(context, 1)
			goal.values["paid_money"] = 0
			goal.state.markers = PackedStringArray(["G1"])

	var shop_slot_card_definition_id: String = effect.parameters.get("shop_slot_card_definition_id", "") as String
	if not shop_slot_card_definition_id.is_empty():
		context.spawn_card.call(shop_slot_card_definition_id, _get_spawn_position(context, customer_count + 1))

func _open_booster(effect: EffectDefinition, context: EffectContext) -> void:
	var booster_id: String = effect.parameters.get("booster_definition_id", "") as String
	var booster: BoosterDefinition = context.content.get_booster_definition(booster_id)
	if booster == null:
		push_error("Missing booster definition: %s" % booster_id)
		return

	for draw_index: int in booster.draw_count:
		var card_definition_id: String = _draw_card_from_booster(booster, context.rng)
		if card_definition_id.is_empty():
			continue
		context.spawn_card.call(card_definition_id, _get_spawn_position(context, draw_index))

	context.state.rng_state = context.rng.state

	if not booster.open_effects.is_empty():
		execute(booster.open_effects, context)

func _draw_card_from_booster(booster: BoosterDefinition, rng: RandomNumberGenerator) -> String:
	var total_weight: int = 0
	for entry: BoosterPoolEntry in booster.pool_entries:
		if entry != null:
			total_weight += maxi(entry.weight, 0)
	if total_weight <= 0:
		return ""

	var roll: int = rng.randi_range(1, total_weight)
	var running_weight: int = 0
	for entry: BoosterPoolEntry in booster.pool_entries:
		if entry == null:
			continue
		running_weight += maxi(entry.weight, 0)
		if roll <= running_weight:
			return entry.card_definition_id

	return ""

func _get_spawn_position(context: EffectContext, spawn_index: int) -> Vector2:
	if context.get_spawn_position.is_valid():
		return context.get_spawn_position.call(context.stack.stack_id, spawn_index) as Vector2
	return context.stack.base_position + Vector2(180.0 + float(spawn_index) * 180.0, 0.0)

func _get_chance(effect: EffectDefinition, context: EffectContext) -> float:
	if effect.parameters.has("chance"):
		return clampf(effect.parameters["chance"] as float, 0.0, 1.0)

	var chance_key: String = effect.parameters.get("chance_key", "") as String
	if context.content.balance != null:
		match chance_key:
			"bug_chance":
				return clampf(context.content.balance.bug_chance, 0.0, 1.0)
			"tech_debt_chance":
				return clampf(context.content.balance.tech_debt_chance, 0.0, 1.0)

	return 0.0

func _get_spawn_count(effect: EffectDefinition, context: EffectContext) -> int:
	var source_card_definition_id: String = effect.parameters.get("count_from_card_definition_id", "") as String
	var value_key: String = effect.parameters.get("count_value_key", "") as String
	if not source_card_definition_id.is_empty() and not value_key.is_empty():
		var source_card: CardInstance = _find_card_in_stack(source_card_definition_id, context)
		if source_card != null:
			return maxi(0, int(source_card.values.get(value_key, 0)))

	var count_key: String = effect.parameters.get("count_key", "") as String
	if context.content.balance != null:
		match count_key:
			"order_bonus_money_cards":
				return maxi(0, context.content.balance.order_bonus_money_cards)
			"poc3_freelance_feature_money_cards":
				return maxi(0, context.content.balance.poc3_freelance_feature_money_cards)
			"poc3_freelance_checked_feature_money_cards":
				return maxi(0, context.content.balance.poc3_freelance_checked_feature_money_cards)

	return maxi(0, effect.parameters.get("count", 1) as int)

func _get_launch_features_per_start_customer(context: EffectContext) -> int:
	if context.content.balance == null:
		return 5
	return maxi(1, context.content.balance.poc3_launch_features_per_start_customer)

func _get_business_goal_required_money(context: EffectContext, goal_index: int) -> int:
	if context.content.balance == null or context.content.balance.poc3_business_goal_required_money.is_empty():
		return [3, 5, 7][clampi(goal_index - 1, 0, 2)]
	var required_money_values: Array[int] = context.content.balance.poc3_business_goal_required_money
	var index: int = clampi(goal_index - 1, 0, required_money_values.size() - 1)
	return maxi(1, required_money_values[index])

func _apply_spawn_parameters(spawned_card: CardInstance, effect: EffectDefinition, context: EffectContext) -> void:
	if spawned_card == null:
		return

	var source_card_definition_id: String = effect.parameters.get("copy_values_from_card_definition_id", "") as String
	if not source_card_definition_id.is_empty():
		var source_card: CardInstance = _find_card_in_stack(source_card_definition_id, context)
		if source_card != null:
			for key: Variant in source_card.values.keys():
				spawned_card.values[key] = source_card.values[key]

	var source_card_tag: String = effect.parameters.get("copy_values_from_card_tag", "") as String
	if not source_card_tag.is_empty():
		var source_card_by_tag: CardInstance = _find_card_in_stack_by_tag(source_card_tag, context)
		if source_card_by_tag != null:
			for key: Variant in source_card_by_tag.values.keys():
				spawned_card.values[key] = source_card_by_tag.values[key]

	if effect.parameters.has("values"):
		var values: Dictionary = effect.parameters["values"] as Dictionary
		for key: Variant in values.keys():
			spawned_card.values[key] = values[key]

	var marker_value_key: String = effect.parameters.get("marker_value_key", "") as String
	if not marker_value_key.is_empty() and spawned_card.values.has(marker_value_key):
		spawned_card.state.markers = PackedStringArray([str(spawned_card.values[marker_value_key])])

func _find_card_in_stack(card_definition_id: String, context: EffectContext) -> CardInstance:
	if card_definition_id.is_empty():
		return null

	for card_id: String in context.active_input_card_ids:
		var active_card: CardInstance = context.state.get_card(card_id)
		if active_card != null and active_card.definition_id == card_definition_id:
			return active_card

	for card_id: String in context.stack.card_ids:
		var card: CardInstance = context.state.get_card(card_id)
		if card != null and card.definition_id == card_definition_id:
			return card

	return null

func _find_card_in_stack_by_tag(tag: String, context: EffectContext) -> CardInstance:
	if tag.is_empty():
		return null

	for card_id: String in context.active_input_card_ids:
		var active_card: CardInstance = context.state.get_card(card_id)
		if active_card == null:
			continue
		var active_definition: CardDefinition = context.content.get_card_definition(active_card.definition_id)
		if active_definition != null and active_definition.tags.has(tag):
			return active_card

	for card_id: String in context.stack.card_ids:
		var card: CardInstance = context.state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = context.content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has(tag):
			return card

	return null

func _should_skip_effect(effect: EffectDefinition, context: EffectContext) -> bool:
	var blocked_tag: String = effect.parameters.get("skip_if_any_card_tag", "") as String
	if blocked_tag.is_empty():
		return false

	for card: CardInstance in context.state.cards.values():
		var definition: CardDefinition = context.content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has(blocked_tag):
			return true

	return false
