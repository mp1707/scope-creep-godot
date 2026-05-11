extends SceneTree

const ProcessingInteractionDefinitionScript: Script = preload("res://scripts/data/processing_interaction_definition.gd")

func _init() -> void:
	var exit_code: int = 0
	exit_code = max(exit_code, _save_cards())
	exit_code = max(exit_code, _save_recipes())
	exit_code = max(exit_code, _save_booster())
	exit_code = max(exit_code, _save_shop())
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
		Color(0.62, 0.82, 0.92),
		Color(0.16, 0.42, 0.58),
		"res://assets/icons/handdrawn/cardIcons/calendar.png"
	), "res://data/cards/software.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.employee.developer",
		"Entwickler",
		ScopeEnums.CardType.EMPLOYEE,
		PackedStringArray(["employee", "developer"]),
		"Baut Features",
		Color(0.64, 0.82, 0.58),
		Color(0.25, 0.48, 0.25),
		"res://assets/icons/handdrawn/characters/steve.png"
	), "res://data/cards/developer.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.input.idea",
		"Idee",
		ScopeEnums.CardType.INPUT,
		PackedStringArray(["idea", "input"]),
		"Kann umgesetzt werden",
		Color(0.98, 0.82, 0.42),
		Color(0.62, 0.42, 0.08),
		"res://assets/icons/handdrawn/cardIcons/star.png"
	), "res://data/cards/idea.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.output.feature",
		"Funktion",
		ScopeEnums.CardType.OUTPUT,
		PackedStringArray(["feature", "output"]),
		"Erzeugt Wert in Software",
		Color(0.70, 0.78, 0.96),
		Color(0.22, 0.36, 0.68),
		"res://assets/icons/handdrawn/cardIcons/mail.png"
	), "res://data/cards/feature.tres"))
	var money_card: CardDefinition = _create_card(
		"card.resource.money",
		"Geld",
		ScopeEnums.CardType.RESOURCE,
		PackedStringArray(["money", "resource"]),
		"Immer genau 1 Geld",
		Color(0.62, 0.88, 0.66),
		Color(0.17, 0.48, 0.24),
		"res://assets/icons/handdrawn/cardIcons/money.png"
	)
	money_card.auto_stack_on_spawn = true
	exit_code = max(exit_code, _save_resource(money_card, "res://data/cards/money.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.problem.bug",
		"Bug",
		ScopeEnums.CardType.PROBLEM,
		PackedStringArray(["problem", "bug"]),
		"Eskalation am Sprintstart",
		Color(0.94, 0.52, 0.55),
		Color(0.55, 0.12, 0.17),
		"res://assets/icons/handdrawn/cardIcons/bug.png"
	), "res://data/cards/bug.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.problem.prod_crash",
		"Prod-Crash",
		ScopeEnums.CardType.PROBLEM,
		PackedStringArray(["problem", "prod_crash"]),
		"Blockiert Einnahmen",
		Color(0.48, 0.09, 0.12),
		Color(0.98, 0.58, 0.24),
		"res://assets/icons/handdrawn/cardIcons/fire.png"
	), "res://data/cards/prod_crash.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.problem.tech_debt",
		"Technische Schulden",
		ScopeEnums.CardType.PROBLEM,
		PackedStringArray(["problem", "tech_debt"]),
		"+5s auf Feature/Bugfix",
		Color(0.74, 0.72, 0.68),
		Color(0.26, 0.27, 0.29),
		"res://assets/icons/handdrawn/cardIcons/exclamationmark.png"
	), "res://data/cards/tech_debt.tres"))
	var coffee_card: CardDefinition = _create_card(
		"card.consumable.coffee",
		"Kaffee",
		ScopeEnums.CardType.CONSUMABLE,
		PackedStringArray(["coffee", "consumable"]),
		"+25% Fortschritt auf laufende Mitarbeiterarbeit",
		Color(0.92, 0.68, 0.52),
		Color(0.50, 0.25, 0.12),
		"res://assets/icons/handdrawn/cardIcons/coffee.png"
	)
	coffee_card.tooltip_text = "Auf eine laufende Mitarbeiterarbeit droppen: verbraucht Kaffee und fuegt 25% der Grunddauer als Fortschritt hinzu."
	coffee_card.auto_stack_on_spawn = true
	coffee_card.processing_interaction = _create_processing_interaction()
	exit_code = max(exit_code, _save_resource(coffee_card, "res://data/cards/coffee.tres"))
	var booster_pack_card: CardDefinition = _create_card(
		"card.resource.booster_pack",
		"Boosterpack",
		ScopeEnums.CardType.RESOURCE,
		PackedStringArray(["booster", "pack"]),
		"Oeffnet neue Karten",
		Color(0.78, 0.67, 0.90),
		Color(0.36, 0.28, 0.48),
		"res://assets/icons/handdrawn/cardIcons/star.png"
	)
	booster_pack_card.base_values = {"booster_definition_id": "booster.founder.test_pack"}
	exit_code = max(exit_code, _save_resource(booster_pack_card, "res://data/cards/booster_pack.tres"))
	exit_code = max(exit_code, _save_resource(_create_card(
		"card.shop.booster_slot",
		"Booster-Slot",
		ScopeEnums.CardType.PROCESS,
		PackedStringArray(["shop", "booster_slot"]),
		"Kauft ein Pack",
		Color(0.64, 0.76, 0.88),
		Color(0.18, 0.33, 0.48),
		"res://assets/icons/handdrawn/cardIcons/money.png"
	), "res://data/cards/booster_slot.tres"))
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
	idea_to_feature.duration_modifier_tags = PackedStringArray(["feature_work"])
	exit_code = max(exit_code, _save_resource(idea_to_feature, "res://data/recipes/feature_from_idea_developer.tres"))

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
		_create_effect("effect.spawn_card.money", "spawn_card", {
			"card_definition_id": "card.resource.money",
			"count": 1,
			"skip_if_any_card_tag": "prod_crash",
		}),
		_create_effect("effect.roll_bug_chance", "roll_chance", {"card_definition_id": "card.problem.bug", "chance_key": "bug_chance"}),
	]
	exit_code = max(exit_code, _save_resource(feature_to_money, "res://data/recipes/money_from_feature_software.tres"))

	var booster_buy: RecipeDefinition = RecipeDefinition.new()
	booster_buy.id = "recipe.booster_pack_from_money.slot"
	booster_buy.display_text = "Booster kaufen"
	booster_buy.inputs = [
		_create_input("card.resource.money"),
		_create_input("card.shop.booster_slot"),
	]
	booster_buy.duration = _create_duration(1.0)
	booster_buy.priority = 10
	booster_buy.specificity_score = 2
	booster_buy.effects_on_complete = [
		_create_effect("effect.consume_input.money.booster_buy", "consume_input", {"card_definition_id": "card.resource.money"}),
		_create_effect("effect.spawn_card.booster_pack", "spawn_card", {"card_definition_id": "card.resource.booster_pack", "count": 1}),
	]
	exit_code = max(exit_code, _save_resource(booster_buy, "res://data/recipes/booster_pack_from_money_slot.tres"))

	var debug_bug: RecipeDefinition = RecipeDefinition.new()
	debug_bug.id = "recipe.debug_bug.developer"
	debug_bug.display_text = "Debugging..."
	debug_bug.inputs = [
		_create_input("card.problem.bug"),
		_create_input("card.employee.developer"),
	]
	debug_bug.duration = _create_duration(12.0)
	debug_bug.priority = 10
	debug_bug.specificity_score = 2
	debug_bug.effects_on_complete = [
		_create_effect("effect.remove_card.bug", "remove_card", {"card_definition_id": "card.problem.bug"}),
	]
	debug_bug.duration_modifier_tags = PackedStringArray(["bugfix_work"])
	exit_code = max(exit_code, _save_resource(debug_bug, "res://data/recipes/debug_bug_developer.tres"))

	var hotfix_prod_crash: RecipeDefinition = RecipeDefinition.new()
	hotfix_prod_crash.id = "recipe.hotfix_prod_crash.developer"
	hotfix_prod_crash.display_text = "Hotfixing..."
	hotfix_prod_crash.inputs = [
		_create_input("card.problem.prod_crash"),
		_create_input("card.employee.developer"),
	]
	hotfix_prod_crash.duration = _create_duration(45.0)
	hotfix_prod_crash.priority = 10
	hotfix_prod_crash.specificity_score = 2
	hotfix_prod_crash.effects_on_complete = [
		_create_effect("effect.remove_card.prod_crash", "remove_card", {"card_definition_id": "card.problem.prod_crash"}),
	]
	exit_code = max(exit_code, _save_resource(hotfix_prod_crash, "res://data/recipes/hotfix_prod_crash_developer.tres"))

	var cleanup_tech_debt: RecipeDefinition = RecipeDefinition.new()
	cleanup_tech_debt.id = "recipe.cleanup_tech_debt.developer"
	cleanup_tech_debt.display_text = "Aufräumen..."
	cleanup_tech_debt.inputs = [
		_create_input("card.problem.tech_debt"),
		_create_input("card.employee.developer"),
	]
	cleanup_tech_debt.duration = _create_duration(10.0)
	cleanup_tech_debt.priority = 10
	cleanup_tech_debt.specificity_score = 2
	cleanup_tech_debt.effects_on_complete = [
		_create_effect("effect.remove_card.tech_debt", "remove_card", {"card_definition_id": "card.problem.tech_debt"}),
	]
	exit_code = max(exit_code, _save_resource(cleanup_tech_debt, "res://data/recipes/cleanup_tech_debt_developer.tres"))

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
	]
	return _save_resource(booster, "res://data/boosters/founder_test_pack.tres")

func _save_shop() -> int:
	var entry: ShopEntryDefinition = ShopEntryDefinition.new()
	entry.id = "shop_entry.booster.founder_test_pack"
	entry.display_name = "Gruender-Testpack"
	entry.cost_money_cards = 1
	entry.card_definition_id = "card.resource.booster_pack"
	entry.booster_definition_id = "booster.founder.test_pack"

	var shop: ShopDefinition = ShopDefinition.new()
	shop.id = "shop.poc.boosters"
	shop.entries = [entry]
	return _save_resource(shop, "res://data/shops/poc_booster_shop.tres")

func _save_balance() -> int:
	var balance: BalanceDefinition = BalanceDefinition.new()
	balance.id = "balance.poc.default"
	balance.sprint_duration_seconds = 60.0
	balance.release_duration_seconds = 6.0
	balance.bug_chance = 0.5
	balance.tech_debt_duration_seconds_per_card = 5.0
	balance.board_snap_distance = 96.0
	balance.stack_offset = Vector2(0.0, 40.0)
	balance.spawn_placement_radius = 160.0
	balance.auto_stack_spawn_radius = 180.0
	return _save_resource(balance, "res://data/balance/poc_default.tres")

func _create_card(
	id: String,
	display_name: String,
	type: ScopeEnums.CardType,
	tags: PackedStringArray,
	short_text: String,
	background_color: Color,
	accent_color: Color,
	icon_path: String = ""
) -> CardDefinition:
	var visual: CardVisualDefinition = CardVisualDefinition.new()
	visual.background_color = background_color
	visual.accent_color = accent_color
	visual.text_color = Color(0.06, 0.055, 0.05)
	if not icon_path.is_empty():
		visual.icon_texture = ResourceLoader.load(icon_path) as Texture2D
	visual.icon_color = visual.text_color
	visual.icon_size = Vector2(78.0, 78.0)
	visual.icon_offset = Vector2.ZERO
	visual.icon_recolor_alpha_mask = true
	visual.marker_text = ""

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

func _create_processing_interaction() -> ProcessingInteractionDefinition:
	var interaction: ProcessingInteractionDefinition = ProcessingInteractionDefinitionScript.new() as ProcessingInteractionDefinition
	interaction.operation = ProcessingInteractionDefinition.Operation.ADD_DURATION_PROGRESS_FRACTION
	interaction.progress_fraction_per_card = 0.25
	interaction.max_applications_per_drop = 4
	interaction.required_target_card_type = ScopeEnums.CardType.EMPLOYEE
	interaction.consume_cards_on_success = true
	interaction.allow_instant_complete = true
	return interaction

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
