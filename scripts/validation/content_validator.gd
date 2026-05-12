class_name ContentValidator
extends RefCounted

const CARD_DIR: String = "res://data/cards"
const RECIPE_DIR: String = "res://data/recipes"
const BOOSTER_DIR: String = "res://data/boosters"
const SHOP_DIR: String = "res://data/shops"
const BALANCE_DIR: String = "res://data/balance"
const POC2_REQUIRED_CARD_TAGS: Dictionary = {
	"card.employee.product_owner": ["employee", "product_owner"],
	"card.employee.tester": ["employee", "tester"],
	"card.employee.external_dev": ["employee", "developer", "external"],
	"card.input.customer_request": ["input", "customer_request"],
	"card.task.user_story": ["task", "user_story"],
	"card.task.promising_user_story": ["task", "user_story", "promising"],
	"card.output.checked_feature": ["output", "feature", "checked"],
	"card.problem.tech_debt": ["problem", "tech_debt"],
	"card.problem.burnout": ["problem", "burnout"],
	"card.problem.prod_crash": ["problem", "prod_crash"],
	"card.problem.unhappy_customer": ["problem", "unhappy_customer"],
	"card.problem.investor_panic": ["problem", "investor_panic"],
	"card.consumable.bugfix_patch": ["consumable", "bugfix_patch"],
	"card.consumable.pizza_party": ["consumable", "pizza_party"],
	"card.consumable.stress_course": ["consumable", "stress_course"],
	"card.value_source.customer": ["value_source", "customer"],
	"card.goal.business_goal": ["goal", "business_goal"],
	"card.value_source.coffee_machine": ["value_source", "coffee_machine"],
	"card.value_source.order": ["value_source", "order"],
	"card.value_source.freelance_order": ["value_source", "order", "freelance_order"],
}
const POC2_REQUIRED_RECIPE_INPUTS: Dictionary = {
	"recipe.feature_from_idea.developer": ["card.input.idea", "card.employee.developer"],
	"recipe.user_story_from_idea.product_owner": ["card.input.idea", "card.employee.product_owner"],
	"recipe.promising_user_story_from_customer_request.product_owner": ["card.input.customer_request", "card.employee.product_owner"],
	"recipe.promising_user_story_from_customer_request.developer": ["card.input.customer_request", "card.employee.developer"],
	"recipe.feature_from_user_story.developer": ["card.task.user_story", "card.employee.developer"],
	"recipe.feature_from_promising_user_story.developer": ["card.task.promising_user_story", "card.employee.developer"],
	"recipe.checked_feature_from_feature.tester": ["card.output.feature", "card.employee.tester"],
	"recipe.money_from_feature.software": ["card.output.feature", "card.product.software"],
	"recipe.money_from_checked_feature.software": ["card.output.checked_feature", "card.product.software"],
	"recipe.debug_bug.developer": ["card.problem.bug", "card.employee.developer"],
	"recipe.debug_bug.tester": ["card.problem.bug", "card.employee.tester"],
	"recipe.debug_bug.external_dev": ["card.problem.bug", "card.employee.external_dev"],
	"recipe.debug_bug.bugfix_patch": ["card.problem.bug", "card.consumable.bugfix_patch"],
	"recipe.cleanup_tech_debt.developer": ["card.problem.tech_debt", "card.employee.developer"],
	"recipe.hotfix_prod_crash.developer": ["card.problem.prod_crash", "card.employee.developer"],
	"recipe.manage_unhappy_customer.product_owner": ["card.value_source.customer", "card.problem.unhappy_customer", "card.employee.product_owner"],
	"recipe.burnout_recovery.employee": ["card.problem.burnout", "tag:employee"],
	"recipe.burnout_recovery.pizza": ["card.problem.burnout", "card.consumable.pizza_party"],
	"recipe.burnout_recovery.stress_course": ["card.problem.burnout", "card.consumable.stress_course"],
	"recipe.money_from_order.feature": ["card.value_source.order", "tag:feature"],
	"recipe.money_from_freelance_order.feature": ["card.value_source.freelance_order", "card.output.feature"],
	"recipe.money_from_freelance_order.checked_feature": ["card.value_source.freelance_order", "card.output.checked_feature"],
}
const POC3_REQUIRED_CARD_IDS: Array[String] = [
	"card.product.software",
	"card.employee.developer",
	"card.input.idea",
	"card.consumable.coffee",
	"card.resource.money",
	"card.value_source.freelance_order",
	"card.value_source.customer",
	"card.input.customer_request",
	"card.problem.unhappy_customer",
	"card.goal.business_goal",
	"card.problem.investor_panic",
	"card.shop.booster_slot",
	"card.shop.booster_slot.office_invest",
	"card.shop.booster_slot.customer_chaos",
	"card.shop.bugfix_patch_slot",
]
const POC3_REQUIRED_BOOSTER_IDS: Array[String] = [
	"booster.founder.test_pack",
	"booster.office_invest",
	"booster.customer_chaos",
]
const POC3_ACTIVE_BOOSTER_SLOT_TARGETS: Dictionary = {
	"card.shop.booster_slot": "booster.founder.test_pack",
	"card.shop.booster_slot.office_invest": "booster.office_invest",
	"card.shop.booster_slot.customer_chaos": "booster.customer_chaos",
}
const POC3_REQUIRED_RECIPE_IDS: Array[String] = [
	"recipe.booster_pack_from_money.slot",
	"recipe.bugfix_patch_from_money.slot",
	"recipe.launch_software.developer",
]
const EFFECT_CARD_REFERENCE_KEYS: Array[String] = [
	"card_definition_id",
	"customer_card_definition_id",
	"goal_card_definition_id",
	"shop_slot_card_definition_id",
	"copy_values_from_card_definition_id",
]

var _errors: PackedStringArray = PackedStringArray()
var _seen_ids: Dictionary = {}
var _card_ids: Dictionary = {}
var _booster_ids: Dictionary = {}

func validate_content() -> PackedStringArray:
	_errors.clear()
	_seen_ids.clear()
	_card_ids.clear()
	_booster_ids.clear()

	var cards: Array = _load_resources(CARD_DIR, CardDefinition)
	var recipes: Array = _load_resources(RECIPE_DIR, RecipeDefinition)
	var boosters: Array = _load_resources(BOOSTER_DIR, BoosterDefinition)
	var shops: Array = _load_resources(SHOP_DIR, ShopDefinition)
	var balances: Array = _load_resources(BALANCE_DIR, BalanceDefinition)

	for card_resource: Resource in cards:
		_validate_card(card_resource as CardDefinition)
	_validate_poc2_cross_card_rules(cards)
	_validate_poc3_required_cards()
	for booster_resource: Resource in boosters:
		var booster: BoosterDefinition = booster_resource as BoosterDefinition
		_booster_ids[booster.id] = booster.resource_path
	_validate_poc3_required_boosters()

	for recipe_resource: Resource in recipes:
		_validate_recipe(recipe_resource as RecipeDefinition)
	_validate_ambiguous_recipes(recipes)
	_validate_poc2_recipe_patterns(recipes)
	_validate_poc3_recipe_patterns(recipes)

	for booster_resource: Resource in boosters:
		_validate_booster(booster_resource as BoosterDefinition)

	for shop_resource: Resource in shops:
		_validate_shop(shop_resource as ShopDefinition)

	for balance_resource: Resource in balances:
		_validate_balance(balance_resource as BalanceDefinition)

	return _errors.duplicate()

func _load_resources(directory_path: String, expected_type: Variant) -> Array:
	var resources: Array = []
	var paths: PackedStringArray = _find_resource_paths(directory_path)
	paths.sort()

	for path: String in paths:
		var resource: Resource = ResourceLoader.load(path)
		if resource == null:
			_errors.append("%s: Resource could not be loaded." % path)
			continue
		if not is_instance_of(resource, expected_type):
			_errors.append("%s: Expected %s, got %s." % [path, expected_type, resource.get_class()])
			continue

		resources.append(resource)
		_register_id(resource.get("id") as String, path)

	return resources

func _find_resource_paths(directory_path: String) -> PackedStringArray:
	var paths: PackedStringArray = PackedStringArray()
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		_errors.append("%s: Directory does not exist." % directory_path)
		return paths

	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		if not file_name.begins_with("."):
			var path: String = "%s/%s" % [directory_path, file_name]
			if directory.current_is_dir():
				paths.append_array(_find_resource_paths(path))
			elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
				paths.append(path)
		file_name = directory.get_next()
	directory.list_dir_end()

	return paths

func _register_id(id: String, path: String) -> void:
	if not IdValidator.is_valid_domain_id(id):
		_errors.append("%s: %s" % [path, IdValidator.get_domain_id_error(id)])
		return

	if _seen_ids.has(id):
		_errors.append("%s: Duplicate ID '%s' already used by %s." % [path, id, _seen_ids[id]])
		return

	_seen_ids[id] = path

func _validate_card(card: CardDefinition) -> void:
	var path: String = card.resource_path
	if card.display_name.strip_edges().is_empty():
		_errors.append("%s: Card '%s' needs a display_name." % [path, card.id])
	if card.short_text.strip_edges().is_empty():
		_errors.append("%s: Card '%s' needs short_text for placeholder cards." % [path, card.id])
	if card.visual == null:
		_errors.append("%s: Card '%s' needs a visual definition." % [path, card.id])
	else:
		_validate_poc2_visual_minimum(card)
	var audio: CardAudioDefinition = card.audio
	if audio != null and not _card_audio_has_any_override(audio):
		_errors.append("%s: Card '%s' has an empty audio override resource." % [path, card.id])
	_validate_processing_interaction(card)
	_validate_poc2_required_tags(card)

	_card_ids[card.id] = path

func _card_audio_has_any_override(audio: CardAudioDefinition) -> bool:
	return audio.has_any_override()

func _validate_processing_interaction(card: CardDefinition) -> void:
	var interaction: ProcessingInteractionDefinition = card.processing_interaction
	if card.id == "card.consumable.coffee" and interaction == null:
		_errors.append("%s: Coffee must define a processing_interaction." % card.resource_path)
		return
	if interaction == null:
		return

	match interaction.operation:
		ProcessingInteractionDefinition.Operation.ADD_DURATION_PROGRESS_FRACTION:
			var progress_fraction_per_card: float = interaction.progress_fraction_per_card
			if progress_fraction_per_card <= 0.0 or progress_fraction_per_card > 1.0:
				_errors.append("%s: Processing interaction on '%s' needs progress_fraction_per_card in (0, 1]." % [card.resource_path, card.id])
		_:
			_errors.append("%s: Processing interaction on '%s' uses an unknown operation." % [card.resource_path, card.id])

	if interaction.max_applications_per_drop <= 0:
		_errors.append("%s: Processing interaction on '%s' needs max_applications_per_drop above 0." % [card.resource_path, card.id])

func _validate_poc2_required_tags(card: CardDefinition) -> void:
	if not POC2_REQUIRED_CARD_TAGS.has(card.id):
		return

	var required_tags: Array = POC2_REQUIRED_CARD_TAGS[card.id] as Array
	for tag: String in required_tags:
		if not card.tags.has(tag):
			_errors.append("%s: PoC2 card '%s' needs tag '%s'." % [card.resource_path, card.id, tag])

func _validate_poc2_visual_minimum(card: CardDefinition) -> void:
	if not POC2_REQUIRED_CARD_TAGS.has(card.id):
		return
	if card.visual.marker_text.strip_edges().is_empty():
		_errors.append("%s: PoC2 card '%s' needs visual.marker_text." % [card.resource_path, card.id])

func _validate_poc2_cross_card_rules(cards: Array) -> void:
	for card_resource: Resource in cards:
		var card: CardDefinition = card_resource as CardDefinition
		if card == null or not card.tags.has("sprint_tick_spawner"):
			continue
		var spawned_card_id: String = card.base_values.get("sprint_tick_spawn_card_id", "") as String
		if spawned_card_id.is_empty():
			_errors.append("%s: Sprint tick spawner '%s' needs base_values.sprint_tick_spawn_card_id." % [card.resource_path, card.id])
		elif not _card_ids.has(spawned_card_id):
			_errors.append("%s: Sprint tick spawner '%s' references missing card '%s'." % [card.resource_path, card.id, spawned_card_id])

func _validate_poc3_required_cards() -> void:
	for card_id: String in POC3_REQUIRED_CARD_IDS:
		if not _card_ids.has(card_id):
			_errors.append("PoC3 requires card '%s'." % card_id)

	for slot_card_id: String in POC3_ACTIVE_BOOSTER_SLOT_TARGETS.keys():
		if not _card_ids.has(slot_card_id):
			continue
		var card: CardDefinition = ResourceLoader.load(_card_ids[slot_card_id]) as CardDefinition
		if card == null:
			continue
		var booster_id: String = card.base_values.get("booster_definition_id", "") as String
		var expected_booster_id: String = POC3_ACTIVE_BOOSTER_SLOT_TARGETS[slot_card_id] as String
		if booster_id != expected_booster_id:
			_errors.append("%s: PoC3 shop slot '%s' must target booster '%s'." % [card.resource_path, slot_card_id, expected_booster_id])

func _validate_poc3_required_boosters() -> void:
	for booster_id: String in POC3_REQUIRED_BOOSTER_IDS:
		if not _booster_ids.has(booster_id):
			_errors.append("PoC3 requires booster '%s'." % booster_id)

func _validate_recipe(recipe: RecipeDefinition) -> void:
	var path: String = recipe.resource_path
	if recipe.display_text.strip_edges().is_empty():
		_errors.append("%s: Recipe '%s' needs display_text." % [path, recipe.id])
	if recipe.inputs.is_empty():
		_errors.append("%s: Recipe '%s' needs at least one input." % [path, recipe.id])
	if recipe.duration == null or recipe.duration.base_seconds <= 0.0:
		_errors.append("%s: Recipe '%s' needs a positive duration." % [path, recipe.id])

	for input: RecipeInputMatcher in recipe.inputs:
		_validate_recipe_input(path, recipe.id, input)

	for input: RecipeInputMatcher in recipe.allowed_extra_inputs:
		_validate_recipe_input(path, recipe.id, input)

	if _recipe_has_card_input(recipe, "card.consumable.coffee"):
		_errors.append("%s: Recipe '%s' must not use coffee as an input; coffee is an active processing interaction." % [path, recipe.id])

	_validate_effects(path, recipe.id, recipe.effects_on_start)
	_validate_effects(path, recipe.id, recipe.effects_on_complete)
	_validate_effects(path, recipe.id, recipe.effects_on_cancel)

func _validate_ambiguous_recipes(recipes: Array) -> void:
	var seen_signatures: Dictionary = {}
	for recipe_resource: Resource in recipes:
		var recipe: RecipeDefinition = recipe_resource as RecipeDefinition
		var signature: String = _get_recipe_ambiguity_signature(recipe)
		if not seen_signatures.has(signature):
			seen_signatures[signature] = recipe
			continue

		var other_recipe: RecipeDefinition = seen_signatures[signature] as RecipeDefinition
		_errors.append(
			"%s: Recipe '%s' is ambiguous with '%s'. Matching inputs, specificity, and priority must not tie."
			% [recipe.resource_path, recipe.id, other_recipe.id]
		)

func _validate_poc2_recipe_patterns(recipes: Array) -> void:
	var recipes_by_id: Dictionary = {}
	for recipe_resource: Resource in recipes:
		var recipe: RecipeDefinition = recipe_resource as RecipeDefinition
		if recipe != null:
			recipes_by_id[recipe.id] = recipe

	for recipe_id: String in POC2_REQUIRED_RECIPE_INPUTS.keys():
		if not recipes_by_id.has(recipe_id):
			_errors.append("PoC2 requires recipe '%s'." % recipe_id)
			continue
		var recipe: RecipeDefinition = recipes_by_id[recipe_id] as RecipeDefinition
		var required_card_ids: Array = POC2_REQUIRED_RECIPE_INPUTS[recipe_id] as Array
		for required_input: String in required_card_ids:
			if not _recipe_has_required_input(recipe, required_input):
				_errors.append("%s: PoC2 recipe '%s' needs input '%s'." % [recipe.resource_path, recipe.id, required_input])

	if recipes_by_id.has("recipe.burnout_recovery.employee") and recipes_by_id.has("recipe.burnout_recovery.pizza"):
		var normal: RecipeDefinition = recipes_by_id["recipe.burnout_recovery.employee"] as RecipeDefinition
		var pizza: RecipeDefinition = recipes_by_id["recipe.burnout_recovery.pizza"] as RecipeDefinition
		if pizza.specificity_score <= normal.specificity_score:
			_errors.append("%s: Pizza burnout recovery must be more specific than normal recovery." % pizza.resource_path)
	if recipes_by_id.has("recipe.burnout_recovery.pizza") and recipes_by_id.has("recipe.burnout_recovery.stress_course"):
		var pizza_recipe: RecipeDefinition = recipes_by_id["recipe.burnout_recovery.pizza"] as RecipeDefinition
		var stress_recipe: RecipeDefinition = recipes_by_id["recipe.burnout_recovery.stress_course"] as RecipeDefinition
		if stress_recipe.specificity_score < pizza_recipe.specificity_score:
			_errors.append("%s: Stress course recovery must be at least as specific as pizza recovery." % stress_recipe.resource_path)

func _validate_poc3_recipe_patterns(recipes: Array) -> void:
	var recipes_by_id: Dictionary = {}
	for recipe_resource: Resource in recipes:
		var recipe: RecipeDefinition = recipe_resource as RecipeDefinition
		if recipe != null:
			recipes_by_id[recipe.id] = recipe

	for recipe_id: String in POC3_REQUIRED_RECIPE_IDS:
		if not recipes_by_id.has(recipe_id):
			_errors.append("PoC3 requires recipe '%s'." % recipe_id)

	var launch_recipe: RecipeDefinition = recipes_by_id.get("recipe.launch_software.developer", null) as RecipeDefinition
	if launch_recipe == null:
		return
	var launches_customer_chaos: bool = false
	for effect: EffectDefinition in launch_recipe.effects_on_complete:
		if effect != null and effect.effect_type == "launch_software":
			launches_customer_chaos = effect.parameters.get("shop_slot_card_definition_id", "") == "card.shop.booster_slot.customer_chaos"
	if not launches_customer_chaos:
		_errors.append("%s: PoC3 launch recipe must activate the Kundenchaos shop slot after launch." % launch_recipe.resource_path)

func _recipe_has_required_input(recipe: RecipeDefinition, required_input: String) -> bool:
	if required_input.begins_with("tag:"):
		return _recipe_has_tag_input(recipe, required_input.trim_prefix("tag:"))
	return _recipe_has_card_input(recipe, required_input)

func _recipe_has_card_input(recipe: RecipeDefinition, card_definition_id: String) -> bool:
	for input: RecipeInputMatcher in recipe.inputs:
		if input != null and input.card_definition_id == card_definition_id:
			return true
	return false

func _recipe_has_tag_input(recipe: RecipeDefinition, tag: String) -> bool:
	for input: RecipeInputMatcher in recipe.inputs:
		if input != null and input.required_tags.has(tag):
			return true
	return false

func _get_recipe_ambiguity_signature(recipe: RecipeDefinition) -> String:
	var input_signatures: PackedStringArray = PackedStringArray()
	for input: RecipeInputMatcher in recipe.inputs:
		input_signatures.append(_get_input_signature(input))
	input_signatures.sort()

	var extra_signatures: PackedStringArray = PackedStringArray()
	for input: RecipeInputMatcher in recipe.allowed_extra_inputs:
		extra_signatures.append(_get_input_signature(input))
	extra_signatures.sort()

	return "%s|%s|inputs:%s|extra:%s" % [
		recipe.specificity_score,
		recipe.priority,
		",".join(input_signatures),
		",".join(extra_signatures),
	]

func _get_input_signature(input: RecipeInputMatcher) -> String:
	var tags: PackedStringArray = input.required_tags.duplicate()
	tags.sort()
	return "%s:%s:%s" % [input.card_definition_id, input.count, "+".join(tags)]

func _validate_recipe_input(path: String, recipe_id: String, input: RecipeInputMatcher) -> void:
	if input == null:
		_errors.append("%s: Recipe '%s' has an empty input matcher." % [path, recipe_id])
		return
	if input.count <= 0:
		_errors.append("%s: Recipe '%s' has an input count below 1." % [path, recipe_id])
	if input.card_definition_id.is_empty() and input.required_tags.is_empty():
		_errors.append("%s: Recipe '%s' input needs a card_definition_id or required_tags." % [path, recipe_id])
	if not input.card_definition_id.is_empty() and not _card_ids.has(input.card_definition_id):
		_errors.append("%s: Recipe '%s' references missing card '%s'." % [path, recipe_id, input.card_definition_id])

func _validate_effects(path: String, owner_id: String, effects: Array[EffectDefinition]) -> void:
	for effect: EffectDefinition in effects:
		if effect == null:
			_errors.append("%s: '%s' has an empty effect." % [path, owner_id])
			continue
		if effect.effect_type.strip_edges().is_empty():
			_errors.append("%s: Effect on '%s' needs effect_type." % [path, owner_id])
		for card_reference_key: String in EFFECT_CARD_REFERENCE_KEYS:
			if not effect.parameters.has(card_reference_key):
				continue
			var card_definition_id: String = effect.parameters[card_reference_key] as String
			if not card_definition_id.is_empty() and not _card_ids.has(card_definition_id):
				_errors.append("%s: Effect on '%s' references missing card '%s' via '%s'." % [path, owner_id, card_definition_id, card_reference_key])
		if effect.parameters.has("booster_definition_id"):
			var booster_definition_id: String = effect.parameters["booster_definition_id"] as String
			if not _booster_ids.has(booster_definition_id):
				_errors.append("%s: Effect on '%s' references missing booster '%s'." % [path, owner_id, booster_definition_id])

func _validate_booster(booster: BoosterDefinition) -> void:
	var path: String = booster.resource_path
	if booster.display_name.strip_edges().is_empty():
		_errors.append("%s: Booster '%s' needs display_name." % [path, booster.id])
	if booster.draw_count <= 0:
		_errors.append("%s: Booster '%s' needs draw_count above 0." % [path, booster.id])
	if booster.pool_entries.is_empty():
		_errors.append("%s: Booster '%s' needs at least one pool entry." % [path, booster.id])

	for entry: BoosterPoolEntry in booster.pool_entries:
		if entry == null:
			_errors.append("%s: Booster '%s' has an empty pool entry." % [path, booster.id])
			continue
		if entry.weight <= 0:
			_errors.append("%s: Booster '%s' has pool weight below 1." % [path, booster.id])
		if not _card_ids.has(entry.card_definition_id):
			_errors.append("%s: Booster '%s' references missing card '%s'." % [path, booster.id, entry.card_definition_id])

	_validate_effects(path, booster.id, booster.open_effects)

func _validate_shop(shop: ShopDefinition) -> void:
	var path: String = shop.resource_path
	if shop.entries.is_empty():
		_errors.append("%s: Shop '%s' needs at least one entry." % [path, shop.id])

	for entry: ShopEntryDefinition in shop.entries:
		if entry == null:
			_errors.append("%s: Shop '%s' has an empty entry." % [path, shop.id])
			continue
		if entry.display_name.strip_edges().is_empty():
			_errors.append("%s: Shop entry '%s' needs display_name." % [path, entry.id])
		if entry.cost_money_cards < 0:
			_errors.append("%s: Shop entry '%s' has negative cost." % [path, entry.id])
		if not entry.card_definition_id.is_empty() and not _card_ids.has(entry.card_definition_id):
			_errors.append("%s: Shop entry '%s' references missing card '%s'." % [path, entry.id, entry.card_definition_id])
		if not entry.booster_definition_id.is_empty() and not _booster_ids.has(entry.booster_definition_id):
			_errors.append("%s: Shop entry '%s' references missing booster '%s'." % [path, entry.id, entry.booster_definition_id])
		if entry.card_definition_id.is_empty() and entry.booster_definition_id.is_empty() and entry.effects_on_buy.is_empty():
			_errors.append("%s: Shop entry '%s' needs a card, booster, or buy effect." % [path, entry.id])
		_validate_effects(path, entry.id, entry.effects_on_buy)

func _validate_balance(balance: BalanceDefinition) -> void:
	var path: String = balance.resource_path
	if balance.sprint_duration_seconds <= 0.0:
		_errors.append("%s: Balance '%s' needs positive sprint_duration_seconds." % [path, balance.id])
	if balance.board_snap_distance <= 0.0:
		_errors.append("%s: Balance '%s' needs positive board_snap_distance." % [path, balance.id])
	if balance.auto_stack_spawn_radius < 0.0:
		_errors.append("%s: Balance '%s' needs non-negative auto_stack_spawn_radius." % [path, balance.id])
	if balance.tech_debt_chance < 0.0 or balance.tech_debt_chance > 1.0:
		_errors.append("%s: Balance '%s' needs tech_debt_chance between 0 and 1." % [path, balance.id])
	if balance.order_bonus_money_cards < 0:
		_errors.append("%s: Balance '%s' needs non-negative order_bonus_money_cards." % [path, balance.id])
