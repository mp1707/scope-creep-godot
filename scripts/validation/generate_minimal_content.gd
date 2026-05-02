extends SceneTree

func _init() -> void:
	var exit_code: int = 0
	exit_code = max(exit_code, _save_cards())
	exit_code = max(exit_code, _save_recipes())
	exit_code = max(exit_code, _save_booster())
	exit_code = max(exit_code, _save_balance())
	quit(exit_code)

func _save_cards() -> int:
	var exit_code: int = 0
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.product.software",
		"Software",
		ScopeEnums.CardType.PRODUCT,
		PackedStringArray(["software", "product"]),
		"Produktbasis",
		Color(0.18, 0.24, 0.31),
		Color(0.40, 0.74, 0.90),
		"SW"
	), "res://data/cards/software.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.employee.developer",
		"Entwickler",
		ScopeEnums.CardType.EMPLOYEE,
		PackedStringArray(["employee", "developer"]),
		"Baut Features",
		Color(0.22, 0.26, 0.20),
		Color(0.60, 0.82, 0.42),
		"DEV"
	), "res://data/cards/developer.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.input.idea",
		"Idee",
		ScopeEnums.CardType.INPUT,
		PackedStringArray(["idea", "input"]),
		"Kann umgesetzt werden",
		Color(0.28, 0.25, 0.18),
		Color(0.90, 0.72, 0.36),
		"IDEA"
	), "res://data/cards/idea.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.output.feature",
		"Funktion",
		ScopeEnums.CardType.OUTPUT,
		PackedStringArray(["feature", "output"]),
		"Erzeugt Wert in Software",
		Color(0.19, 0.23, 0.30),
		Color(0.53, 0.66, 0.98),
		"FEAT"
	), "res://data/cards/feature.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.resource.money",
		"Geld",
		ScopeEnums.CardType.RESOURCE,
		PackedStringArray(["money", "resource"]),
		"Immer genau 1 Geld",
		Color(0.18, 0.29, 0.23),
		Color(0.50, 0.86, 0.58),
		"1"
	), "res://data/cards/money.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.problem.bug",
		"Bug",
		ScopeEnums.CardType.PROBLEM,
		PackedStringArray(["problem", "bug"]),
		"Eskalation am Sprintstart",
		Color(0.32, 0.18, 0.20),
		Color(0.92, 0.38, 0.42),
		"BUG"
	), "res://data/cards/bug.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.consumable.coffee",
		"Kaffee",
		ScopeEnums.CardType.CONSUMABLE,
		PackedStringArray(["coffee", "consumable"]),
		"Beschleunigt ein Arbeits-Recipe",
		Color(0.25, 0.21, 0.18),
		Color(0.79, 0.58, 0.36),
		"CAF"
	), "res://data/cards/coffee.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.resource.booster_pack",
		"Boosterpack",
		ScopeEnums.CardType.RESOURCE,
		PackedStringArray(["booster", "pack"]),
		"Oeffnet neue Karten",
		Color(0.25, 0.20, 0.31),
		Color(0.75, 0.52, 0.95),
		"PACK"
	), "res://data/cards/booster_pack.tres"))
	return exit_code

func _save_recipes() -> int:
	var exit_code: int = 0

	var idea_to_feature: RecipeDefinition = RecipeDefinition.new()
	idea_to_feature.id = "recipe.feature_from_idea.developer"
	idea_to_feature.display_text = "Funktion bauen"
	idea_to_feature.inputs = [
		_create_input("card.input.idea"),
		_create_input("card.employee.developer"),
	]
	idea_to_feature.duration = _create_duration(8.0)
	idea_to_feature.priority = 10
	idea_to_feature.specificity_score = 2
	idea_to_feature.effects_on_complete = [
		_create_effect("effect.consume_input.idea", "consume_input", {"card_definition_id": "card.input.idea"}),
		_create_effect("effect.spawn_card.feature", "spawn_card", {"card_definition_id": "card.output.feature", "count": 1}),
	]
	exit_code = max(exit_code, _save_resource(idea_to_feature, "res://data/recipes/feature_from_idea_developer.tres"))

	var idea_to_feature_with_coffee: RecipeDefinition = RecipeDefinition.new()
	idea_to_feature_with_coffee.id = "recipe.feature_from_idea.developer_coffee"
	idea_to_feature_with_coffee.display_text = "Funktion bauen mit Kaffee"
	idea_to_feature_with_coffee.inputs = [
		_create_input("card.input.idea"),
		_create_input("card.employee.developer"),
		_create_input("card.consumable.coffee"),
	]
	idea_to_feature_with_coffee.duration = _create_duration(4.0)
	idea_to_feature_with_coffee.priority = 20
	idea_to_feature_with_coffee.specificity_score = 3
	idea_to_feature_with_coffee.effects_on_complete = [
		_create_effect("effect.consume_input.idea", "consume_input", {"card_definition_id": "card.input.idea"}),
		_create_effect("effect.consume_input.coffee", "consume_input", {"card_definition_id": "card.consumable.coffee"}),
		_create_effect("effect.spawn_card.feature", "spawn_card", {"card_definition_id": "card.output.feature", "count": 1}),
	]
	exit_code = max(exit_code, _save_resource(idea_to_feature_with_coffee, "res://data/recipes/feature_from_idea_developer_coffee.tres"))

	var feature_to_money: RecipeDefinition = RecipeDefinition.new()
	feature_to_money.id = "recipe.money_from_feature.software"
	feature_to_money.display_text = "Feature releasen"
	feature_to_money.inputs = [
		_create_input("card.output.feature"),
		_create_input("card.product.software"),
	]
	feature_to_money.duration = _create_duration(6.0)
	feature_to_money.priority = 10
	feature_to_money.specificity_score = 2
	feature_to_money.effects_on_complete = [
		_create_effect("effect.consume_input.feature", "consume_input", {"card_definition_id": "card.output.feature"}),
		_create_effect("effect.spawn_card.money", "spawn_card", {"card_definition_id": "card.resource.money", "count": 1}),
		_create_effect("effect.roll_bug_chance", "roll_chance", {"card_definition_id": "card.problem.bug", "chance_key": "bug_chance"}),
	]
	exit_code = max(exit_code, _save_resource(feature_to_money, "res://data/recipes/money_from_feature_software.tres"))

	return exit_code

func _save_booster() -> int:
	var booster: BoosterDefinition = BoosterDefinition.new()
	booster.id = "booster.founder.test_pack"
	booster.display_name = "Gruender-Testpack"
	booster.cost_money_cards = 1
	booster.draw_count = 3
	booster.pool_entries = [
		_create_pool_entry("card.input.idea", 5),
		_create_pool_entry("card.consumable.coffee", 3),
		_create_pool_entry("card.resource.money", 2),
		_create_pool_entry("card.problem.bug", 1),
	]
	return _save_resource(booster, "res://data/boosters/founder_test_pack.tres")

func _save_balance() -> int:
	var balance: BalanceDefinition = BalanceDefinition.new()
	balance.id = "balance.poc.default"
	balance.sprint_duration_seconds = 60.0
	balance.release_duration_seconds = 6.0
	balance.bug_chance = 0.25
	balance.board_snap_distance = 96.0
	balance.stack_offset = Vector2(0.0, 28.0)
	balance.spawn_placement_radius = 160.0
	return _save_resource(balance, "res://data/balance/poc_default.tres")

func _create_card(
	id: String,
	display_name: String,
	type: ScopeEnums.CardType,
	tags: PackedStringArray,
	short_text: String,
	background_color: Color,
	accent_color: Color,
	marker_text: String
) -> CardDefinition:
	var visual: CardVisualDefinition = CardVisualDefinition.new()
	visual.background_color = background_color
	visual.accent_color = accent_color
	visual.marker_text = marker_text

	var card: CardDefinition = CardDefinition.new()
	card.id = id
	card.display_name = display_name
	card.type = type
	card.tags = tags
	card.short_text = short_text
	card.tooltip_text = short_text
	card.visual = visual
	return card

func _create_input(card_definition_id: String) -> RecipeInputMatcher:
	var input: RecipeInputMatcher = RecipeInputMatcher.new()
	input.card_definition_id = card_definition_id
	input.count = 1
	return input

func _create_duration(base_seconds: float) -> DurationDefinition:
	var duration: DurationDefinition = DurationDefinition.new()
	duration.base_seconds = base_seconds
	return duration

func _create_effect(id: String, effect_type: String, parameters: Dictionary) -> EffectDefinition:
	var effect: EffectDefinition = EffectDefinition.new()
	effect.id = id
	effect.effect_type = effect_type
	effect.parameters = parameters
	return effect

func _create_pool_entry(card_definition_id: String, weight: int) -> BoosterPoolEntry:
	var entry: BoosterPoolEntry = BoosterPoolEntry.new()
	entry.card_definition_id = card_definition_id
	entry.weight = weight
	return entry

func _save_resource(resource: Resource, path: String) -> int:
	var error: Error = ResourceSaver.save(resource, path)
	if error != OK:
		printerr("Could not save %s: %s" % [path, error])
		return 1
	print("Saved %s" % path)
	return 0
