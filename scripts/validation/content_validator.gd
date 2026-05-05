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
	"card.consumable.bugfix_patch": ["consumable", "bugfix_patch"],
	"card.consumable.pizza_party": ["consumable", "pizza_party"],
	"card.consumable.stress_course": ["consumable", "stress_course"],
	"card.value_source.customer": ["value_source", "customer"],
	"card.value_source.coffee_machine": ["value_source", "coffee_machine"],
	"card.value_source.order": ["value_source", "order"],
}

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
	for booster_resource: Resource in boosters:
		var booster: BoosterDefinition = booster_resource as BoosterDefinition
		_booster_ids[booster.id] = booster.resource_path

	for recipe_resource: Resource in recipes:
		_validate_recipe(recipe_resource as RecipeDefinition)
	_validate_ambiguous_recipes(recipes)

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
	_validate_poc2_required_tags(card)

	_card_ids[card.id] = path

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
		if effect.parameters.has("card_definition_id"):
			var card_definition_id: String = effect.parameters["card_definition_id"] as String
			if not _card_ids.has(card_definition_id):
				_errors.append("%s: Effect on '%s' references missing card '%s'." % [path, owner_id, card_definition_id])
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
	if balance.tech_debt_chance < 0.0 or balance.tech_debt_chance > 1.0:
		_errors.append("%s: Balance '%s' needs tech_debt_chance between 0 and 1." % [path, balance.id])
	if balance.order_bonus_money_cards < 0:
		_errors.append("%s: Balance '%s' needs non-negative order_bonus_money_cards." % [path, balance.id])
