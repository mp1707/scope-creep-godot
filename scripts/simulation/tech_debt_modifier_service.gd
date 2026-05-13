class_name TechDebtModifierService
extends RefCounted

const FEATURE_WORK_TAG: String = "feature_work"
const BUGFIX_WORK_TAG: String = "bugfix_work"
const TECH_DEBT_TAG: String = "tech_debt"
const TEMP_WORKER_DURATION_TAG: String = "temp_worker_duration"
const TEMP_WORKER_TAG: String = "temp_worker"

func get_duration_seconds(
	recipe: RecipeDefinition,
	state: RunState,
	content: ContentCatalog,
	stack: StackState = null,
	active_input_card_ids: PackedStringArray = PackedStringArray()
) -> float:
	if recipe == null or recipe.duration == null:
		return 0.0

	var duration_seconds: float = recipe.duration.base_seconds
	if _is_tech_debt_affected_recipe(recipe):
		duration_seconds += float(_count_tech_debt_cards(state, content)) * _get_seconds_per_tech_debt(content)

	if recipe.duration_modifier_tags.has(TEMP_WORKER_DURATION_TAG):
		duration_seconds *= _get_temp_worker_duration_multiplier(state, content, stack, active_input_card_ids)

	return duration_seconds

func _is_tech_debt_affected_recipe(recipe: RecipeDefinition) -> bool:
	return recipe.duration_modifier_tags.has(FEATURE_WORK_TAG) or recipe.duration_modifier_tags.has(BUGFIX_WORK_TAG)

func _count_tech_debt_cards(state: RunState, content: ContentCatalog) -> int:
	var count: int = 0
	for card: CardInstance in state.cards.values():
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has(TECH_DEBT_TAG):
			count += 1
	return count

func _get_seconds_per_tech_debt(content: ContentCatalog) -> float:
	if content.balance == null:
		return 5.0
	return content.balance.tech_debt_duration_seconds_per_card

func _get_temp_worker_duration_multiplier(
	state: RunState,
	content: ContentCatalog,
	stack: StackState,
	active_input_card_ids: PackedStringArray
) -> float:
	var worker_ids: PackedStringArray = active_input_card_ids
	if worker_ids.is_empty() and stack != null:
		worker_ids = stack.card_ids

	for card_id: String in worker_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has(TEMP_WORKER_TAG):
			var fallback_multiplier: float = 2.0
			if content.balance != null:
				fallback_multiplier = content.balance.poc4_work_student_duration_multiplier
			return maxf(1.0, float(card.values.get("duration_multiplier", fallback_multiplier)))

	if content.balance == null:
		return 2.0
	return maxf(1.0, content.balance.poc4_work_student_duration_multiplier)
