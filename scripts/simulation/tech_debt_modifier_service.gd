class_name TechDebtModifierService
extends RefCounted

const FEATURE_WORK_TAG: String = "feature_work"
const BUGFIX_WORK_TAG: String = "bugfix_work"
const TECH_DEBT_TAG: String = "tech_debt"

func get_duration_seconds(recipe: RecipeDefinition, state: RunState, content: ContentCatalog) -> float:
	if recipe == null or recipe.duration == null:
		return 0.0

	var duration_seconds: float = recipe.duration.base_seconds
	if not _is_affected_recipe(recipe):
		return duration_seconds

	return duration_seconds + float(_count_tech_debt_cards(state, content)) * _get_seconds_per_tech_debt(content)

func _is_affected_recipe(recipe: RecipeDefinition) -> bool:
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
