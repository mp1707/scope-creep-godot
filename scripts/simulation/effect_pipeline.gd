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
		context.spawn_card.call(card_definition_id, _get_spawn_position(context, index))

func _spawn_money(effect: EffectDefinition, context: EffectContext) -> void:
	if _should_skip_effect(effect, context):
		return
	var count: int = effect.parameters.get("count", 1) as int
	for index: int in count:
		context.spawn_card.call("card.resource.money", _get_spawn_position(context, index))

func _roll_chance(effect: EffectDefinition, context: EffectContext) -> void:
	var chance: float = _get_chance(effect, context)
	if context.rng.randf() > chance:
		context.state.rng_state = context.rng.state
		return

	var card_definition_id: String = effect.parameters.get("card_definition_id", "") as String
	if not card_definition_id.is_empty():
		context.spawn_card.call(card_definition_id, _get_spawn_position(context, 0))
	context.state.rng_state = context.rng.state

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
	if context.content.balance != null and chance_key == "bug_chance":
		return clampf(context.content.balance.bug_chance, 0.0, 1.0)

	return 0.0

func _find_card_in_stack(card_definition_id: String, context: EffectContext) -> CardInstance:
	if card_definition_id.is_empty():
		return null

	for card_id: String in context.stack.card_ids:
		var card: CardInstance = context.state.get_card(card_id)
		if card != null and card.definition_id == card_definition_id:
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
