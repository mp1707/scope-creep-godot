class_name RecipeEngine
extends RefCounted

func find_best_match(stack: StackState, state: RunState, content: ContentCatalog) -> RecipeMatchResult:
	var result: RecipeMatchResult = RecipeMatchResult.new()
	var matches: Array[RecipeDefinition] = []

	for recipe: RecipeDefinition in content.get_recipe_definitions():
		if _recipe_matches_stack(recipe, stack, state, content):
			matches.append(recipe)

	if matches.is_empty():
		return result

	matches.sort_custom(_compare_recipe_rank)
	var best: RecipeDefinition = matches[0]
	result.recipe = best

	for index: int in range(1, matches.size()):
		var candidate: RecipeDefinition = matches[index]
		if candidate.specificity_score == best.specificity_score and candidate.priority == best.priority:
			result.ambiguous_recipe_ids.append(candidate.id)

	if result.is_ambiguous():
		result.ambiguous_recipe_ids.insert(0, best.id)

	return result

func _recipe_matches_stack(recipe: RecipeDefinition, stack: StackState, state: RunState, content: ContentCatalog) -> bool:
	if stack.card_ids.is_empty():
		return false

	var used_card_ids: Dictionary = {}
	for input: RecipeInputMatcher in recipe.inputs:
		for index: int in input.count:
			var card_id: String = _find_matching_unused_card(input, stack, state, content, used_card_ids)
			if card_id.is_empty():
				return false
			used_card_ids[card_id] = true

	for card_id: String in stack.card_ids:
		if used_card_ids.has(card_id):
			continue
		if not _matches_any_extra_input(card_id, recipe.allowed_extra_inputs, state, content):
			return false

	return true

func _matches_any_extra_input(
	card_id: String,
	allowed_extra_inputs: Array[RecipeInputMatcher],
	state: RunState,
	content: ContentCatalog
) -> bool:
	for input: RecipeInputMatcher in allowed_extra_inputs:
		if _card_matches_input(card_id, input, state, content):
			return true
	return false

func _find_matching_unused_card(
	input: RecipeInputMatcher,
	stack: StackState,
	state: RunState,
	content: ContentCatalog,
	used_card_ids: Dictionary
) -> String:
	for card_id: String in stack.card_ids:
		if used_card_ids.has(card_id):
			continue
		if _card_matches_input(card_id, input, state, content):
			return card_id
	return ""

func _card_matches_input(card_id: String, input: RecipeInputMatcher, state: RunState, content: ContentCatalog) -> bool:
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return false

	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	if definition == null:
		return false

	if not input.card_definition_id.is_empty() and card.definition_id != input.card_definition_id:
		return false

	for required_tag: String in input.required_tags:
		if not definition.tags.has(required_tag):
			return false

	return true

func _compare_recipe_rank(left: RecipeDefinition, right: RecipeDefinition) -> bool:
	if left.specificity_score != right.specificity_score:
		return left.specificity_score > right.specificity_score
	if left.priority != right.priority:
		return left.priority > right.priority
	return left.id < right.id
