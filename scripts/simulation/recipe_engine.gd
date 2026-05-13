class_name RecipeEngine
extends RefCounted

func find_best_match(stack: StackState, state: RunState, content: ContentCatalog) -> RecipeMatchResult:
	var result: RecipeMatchResult = RecipeMatchResult.new()
	var matches: Array[Dictionary] = []

	for recipe: RecipeDefinition in content.get_recipe_definitions():
		var match_data: Dictionary = _get_recipe_match_data(recipe, stack, state, content)
		if not match_data.is_empty():
			matches.append(match_data)

	if matches.is_empty():
		return result

	matches.sort_custom(_compare_match_rank)
	var best_data: Dictionary = matches[0]
	var best: RecipeDefinition = best_data["recipe"] as RecipeDefinition
	result.recipe = best
	result.active_input_card_ids = best_data["active_input_card_ids"] as PackedStringArray
	result.active_queue_index = best_data["active_queue_index"] as int

	for index: int in range(1, matches.size()):
		var candidate_data: Dictionary = matches[index]
		var candidate: RecipeDefinition = candidate_data["recipe"] as RecipeDefinition
		if candidate.specificity_score == best.specificity_score and candidate.priority == best.priority:
			result.ambiguous_recipe_ids.append(candidate.id)

	if result.is_ambiguous():
		result.ambiguous_recipe_ids.insert(0, best.id)

	return result

func _get_recipe_match_data(recipe: RecipeDefinition, stack: StackState, state: RunState, content: ContentCatalog) -> Dictionary:
	if stack.card_ids.is_empty():
		return {}

	var used_card_ids: Dictionary = {}
	for input: RecipeInputMatcher in recipe.inputs:
		for index: int in input.count:
			var card_id: String = _find_matching_unused_card(input, stack, state, content, used_card_ids)
			if card_id.is_empty():
				return {}
			used_card_ids[card_id] = true

	if not _constraints_match(recipe, stack, state, content, used_card_ids):
		return {}
	if _has_blocked_employee_input(recipe, state, content, used_card_ids):
		return {}

	var anchor_card_id: String = _find_queue_anchor_card_id(used_card_ids, state, content)

	for card_id: String in stack.card_ids:
		if used_card_ids.has(card_id):
			continue
		if not _matches_any_extra_input(card_id, recipe.allowed_extra_inputs, state, content):
			if anchor_card_id.is_empty() or not _is_queue_extra_card(card_id, anchor_card_id, state, content):
				return {}

	var active_input_card_ids: PackedStringArray = PackedStringArray()
	for card_id: String in stack.card_ids:
		if used_card_ids.has(card_id):
			active_input_card_ids.append(card_id)

	return {
		"recipe": recipe,
		"active_input_card_ids": active_input_card_ids,
		"active_queue_index": _get_active_queue_index(stack, active_input_card_ids, state, content),
	}

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
	for reverse_index: int in stack.card_ids.size():
		var card_id: String = stack.card_ids[stack.card_ids.size() - 1 - reverse_index]
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

func _constraints_match(
	recipe: RecipeDefinition,
	stack: StackState,
	state: RunState,
	content: ContentCatalog,
	used_card_ids: Dictionary
) -> bool:
	for constraint: RecipeConstraintDefinition in recipe.constraints:
		if constraint == null:
			continue
		match constraint.constraint_type:
			"attached_card":
				if not _attached_card_constraint_matches(constraint, stack, state, content, used_card_ids):
					return false
			"software_launch_ready":
				if not _software_launch_ready_constraint_matches(state):
					return false
			"no_card_with_tag":
				if not _no_card_with_tag_constraint_matches(constraint, state, content):
					return false
			_:
				push_warning("Unknown recipe constraint '%s' on recipe '%s'." % [constraint.constraint_type, recipe.id])
	return true

func _software_launch_ready_constraint_matches(state: RunState) -> bool:
	var lifecycle: ProductLifecycleService = ProductLifecycleService.new()
	return lifecycle.is_launch_ready(state)

func _no_card_with_tag_constraint_matches(
	constraint: RecipeConstraintDefinition,
	state: RunState,
	content: ContentCatalog
) -> bool:
	var blocked_tag: String = constraint.parameters.get("tag", "") as String
	if blocked_tag.is_empty():
		return true
	for card: CardInstance in state.cards.values():
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has(blocked_tag):
			return false
	return true

func _attached_card_constraint_matches(
	constraint: RecipeConstraintDefinition,
	stack: StackState,
	state: RunState,
	content: ContentCatalog,
	used_card_ids: Dictionary
) -> bool:
	var parent_card_id: String = _find_used_card_for_constraint(
		constraint.parameters.get("parent_card_definition_id", "") as String,
		constraint.parameters.get("parent_required_tag", "") as String,
		state,
		content,
		used_card_ids
	)
	if parent_card_id.is_empty():
		return false

	var attachment_card_id: String = _find_used_card_for_constraint(
		constraint.parameters.get("attachment_card_definition_id", "") as String,
		constraint.parameters.get("attachment_required_tag", "") as String,
		state,
		content,
		used_card_ids
	)
	if attachment_card_id.is_empty() or not stack.card_ids.has(attachment_card_id):
		return false

	var attachment: CardInstance = state.get_card(attachment_card_id)
	if attachment == null or attachment.parent_card_id != parent_card_id:
		return false

	var required_slot: String = constraint.parameters.get("attachment_slot", "") as String
	return required_slot.is_empty() or attachment.attachment_slot == required_slot

func _find_used_card_for_constraint(
	card_definition_id: String,
	required_tag: String,
	state: RunState,
	content: ContentCatalog,
	used_card_ids: Dictionary
) -> String:
	for card_id: String in used_card_ids.keys():
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		if not card_definition_id.is_empty() and card.definition_id != card_definition_id:
			continue
		if not required_tag.is_empty():
			var definition: CardDefinition = content.get_card_definition(card.definition_id)
			if definition == null or not definition.tags.has(required_tag):
				continue
		return card_id
	return ""

func _has_blocked_employee_input(
	recipe: RecipeDefinition,
	state: RunState,
	content: ContentCatalog,
	used_card_ids: Dictionary
) -> bool:
	if _recipe_uses_burnout(recipe, state, content, used_card_ids):
		return false
	if _recipe_uses_employee_blocker(recipe, state, content, used_card_ids):
		return false

	for card_id: String in used_card_ids.keys():
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has("employee") and _has_blocking_employee_attachment(card.instance_id, state, content):
			return true
	return false

func _recipe_uses_burnout(
	_recipe: RecipeDefinition,
	state: RunState,
	content: ContentCatalog,
	used_card_ids: Dictionary
) -> bool:
	for card_id: String in used_card_ids.keys():
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has("burnout"):
			return true
	return false

func _has_burnout_attachment(parent_card_id: String, state: RunState, content: ContentCatalog) -> bool:
	for card: CardInstance in state.cards.values():
		if card.parent_card_id != parent_card_id:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has("burnout"):
			return true
	return false

func _recipe_uses_employee_blocker(
	_recipe: RecipeDefinition,
	state: RunState,
	content: ContentCatalog,
	used_card_ids: Dictionary
) -> bool:
	for card_id: String in used_card_ids.keys():
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has("employee_blocker"):
			return true
	return false

func _has_blocking_employee_attachment(parent_card_id: String, state: RunState, content: ContentCatalog) -> bool:
	for card: CardInstance in state.cards.values():
		if card.parent_card_id != parent_card_id:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition == null:
			continue
		if definition.tags.has("burnout") or definition.tags.has("employee_blocker"):
			return true
	return false

func _find_queue_anchor_card_id(used_card_ids: Dictionary, state: RunState, content: ContentCatalog) -> String:
	var anchor_card_id: String = ""
	for card_id: String in used_card_ids.keys():
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition == null:
			continue
		if definition.type == ScopeEnums.CardType.EMPLOYEE or definition.type == ScopeEnums.CardType.PRODUCT:
			if not anchor_card_id.is_empty():
				return ""
			anchor_card_id = card.instance_id
	return anchor_card_id

func _is_queue_extra_card(card_id: String, anchor_card_id: String, state: RunState, content: ContentCatalog) -> bool:
	var extra_card: CardInstance = state.get_card(card_id)
	var anchor_card: CardInstance = state.get_card(anchor_card_id)
	if extra_card == null or anchor_card == null:
		return false
	if not extra_card.parent_card_id.is_empty():
		return false
	var extra_definition: CardDefinition = content.get_card_definition(extra_card.definition_id)
	if extra_definition == null:
		return false
	if not _is_queueable_card_type(extra_definition.type):
		return false

	for recipe: RecipeDefinition in content.get_recipe_definitions():
		if _recipe_has_anchor_and_card(recipe, anchor_card_id, card_id, state, content):
			return true
	return false

func _recipe_has_anchor_and_card(
	recipe: RecipeDefinition,
	anchor_card_id: String,
	queue_card_id: String,
	state: RunState,
	content: ContentCatalog
) -> bool:
	var has_anchor: bool = false
	var has_queue_card: bool = false
	for input: RecipeInputMatcher in recipe.inputs:
		if _card_matches_input(anchor_card_id, input, state, content):
			has_anchor = true
		if _card_matches_input(queue_card_id, input, state, content):
			has_queue_card = true
	return has_anchor and has_queue_card

func _is_queueable_card_type(card_type: ScopeEnums.CardType) -> bool:
	if card_type == ScopeEnums.CardType.INPUT:
		return true
	if card_type == ScopeEnums.CardType.TASK:
		return true
	if card_type == ScopeEnums.CardType.OUTPUT:
		return true
	return card_type == ScopeEnums.CardType.PROBLEM

func _get_active_queue_index(
	stack: StackState,
	active_input_card_ids: PackedStringArray,
	state: RunState,
	content: ContentCatalog
) -> int:
	var best_index: int = -1
	for card_id: String in active_input_card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition == null:
			continue
		if definition.type == ScopeEnums.CardType.EMPLOYEE or definition.type == ScopeEnums.CardType.PRODUCT:
			continue
		best_index = maxi(best_index, stack.card_ids.find(card_id))
	return best_index

func _compare_match_rank(left: Dictionary, right: Dictionary) -> bool:
	var left_queue_index: int = left["active_queue_index"] as int
	var right_queue_index: int = right["active_queue_index"] as int
	if left_queue_index != right_queue_index:
		return left_queue_index > right_queue_index
	return _compare_recipe_rank(left["recipe"] as RecipeDefinition, right["recipe"] as RecipeDefinition)

func _compare_recipe_rank(left: RecipeDefinition, right: RecipeDefinition) -> bool:
	if left.specificity_score != right.specificity_score:
		return left.specificity_score > right.specificity_score
	if left.priority != right.priority:
		return left.priority > right.priority
	return left.id < right.id
