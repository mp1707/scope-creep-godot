class_name ContentCatalog
extends RefCounted

const CARD_DIR: String = "res://data/cards"
const RECIPE_DIR: String = "res://data/recipes"
const BOOSTER_DIR: String = "res://data/boosters"
const SHOP_DIR: String = "res://data/shops"
const BALANCE_PATH: String = "res://data/balance/poc_default.tres"

var cards: Dictionary = {}
var recipes: Dictionary = {}
var boosters: Dictionary = {}
var shops: Dictionary = {}
var balance: BalanceDefinition = null

func load_default_content() -> bool:
	cards.clear()
	recipes.clear()
	boosters.clear()
	shops.clear()
	_load_cards(CARD_DIR)
	_load_recipes(RECIPE_DIR)
	_load_boosters(BOOSTER_DIR)
	_load_shops(SHOP_DIR)
	balance = ResourceLoader.load(BALANCE_PATH) as BalanceDefinition
	apply_balance_overrides()
	return not cards.is_empty() and not recipes.is_empty() and not boosters.is_empty() and balance != null

func get_card_definition(card_definition_id: String) -> CardDefinition:
	return cards.get(card_definition_id, null) as CardDefinition

func has_card_definition(card_definition_id: String) -> bool:
	return cards.has(card_definition_id)

func get_recipe_definition(recipe_id: String) -> RecipeDefinition:
	return recipes.get(recipe_id, null) as RecipeDefinition

func get_recipe_definitions() -> Array[RecipeDefinition]:
	var recipe_definitions: Array[RecipeDefinition] = []
	for recipe: RecipeDefinition in recipes.values():
		recipe_definitions.append(recipe)
	return recipe_definitions

func get_booster_definition(booster_id: String) -> BoosterDefinition:
	return boosters.get(booster_id, null) as BoosterDefinition

func has_booster_definition(booster_id: String) -> bool:
	return boosters.has(booster_id)

func get_shop_definition(shop_id: String) -> ShopDefinition:
	return shops.get(shop_id, null) as ShopDefinition

func apply_balance_overrides() -> void:
	if balance == null:
		return
	_set_recipe_duration("recipe.clear_customer_request.developer", balance.poc3_developer_customer_request_duration_seconds)
	_set_recipe_duration("recipe.demo_customer.developer", balance.poc5_customer_demo_duration_seconds)
	_set_recipe_duration("recipe.feedback_from_customer.product_owner", balance.poc5_customer_feedback_duration_seconds)
	_set_recipe_duration("recipe.interview_candidate.regular_employee", balance.poc4_normal_interview_duration_seconds)
	_set_recipe_duration("recipe.interview_candidate.recruiter", balance.poc4_recruiter_interview_duration_seconds)
	_set_recipe_duration("recipe.onboarding.employee", balance.poc4_onboarding_duration_seconds)
	_set_work_student_balance_values()
	_set_spawn_money_count_key("recipe.money_from_freelance_order.feature", "poc3_freelance_feature_money_cards")
	_set_spawn_money_count_key("recipe.money_from_freelance_order.checked_feature", "poc3_freelance_checked_feature_money_cards")

func _set_recipe_duration(recipe_id: String, duration_seconds: float) -> void:
	var recipe: RecipeDefinition = get_recipe_definition(recipe_id)
	if recipe == null or recipe.duration == null:
		return
	recipe.duration.base_seconds = maxf(0.1, duration_seconds)

func _set_spawn_money_count_key(recipe_id: String, count_key: String) -> void:
	var recipe: RecipeDefinition = get_recipe_definition(recipe_id)
	if recipe == null:
		return
	for effect: EffectDefinition in recipe.effects_on_complete:
		if effect != null and effect.effect_type == "spawn_money":
			effect.parameters.erase("count")
			effect.parameters["count_key"] = count_key

func _set_work_student_balance_values() -> void:
	var work_student: CardDefinition = get_card_definition("card.temp_worker.work_student")
	if work_student == null:
		return
	work_student.base_values["duration_multiplier"] = maxf(1.0, balance.poc4_work_student_duration_multiplier)
	work_student.base_values["completed_task_lifetime"] = maxi(1, balance.poc4_work_student_completed_task_lifetime)

func _load_cards(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		push_error("Card directory does not exist: %s" % directory_path)
		return

	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		if not file_name.begins_with("."):
			var path: String = "%s/%s" % [directory_path, file_name]
			if directory.current_is_dir():
				_load_cards(path)
			elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var card: CardDefinition = ResourceLoader.load(path) as CardDefinition
				if card != null:
					cards[card.id] = card
		file_name = directory.get_next()
	directory.list_dir_end()

func _load_recipes(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		push_error("Recipe directory does not exist: %s" % directory_path)
		return

	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		if not file_name.begins_with("."):
			var path: String = "%s/%s" % [directory_path, file_name]
			if directory.current_is_dir():
				_load_recipes(path)
			elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var recipe: RecipeDefinition = ResourceLoader.load(path) as RecipeDefinition
				if recipe != null:
					recipes[recipe.id] = recipe
		file_name = directory.get_next()
	directory.list_dir_end()

func _load_boosters(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		push_error("Booster directory does not exist: %s" % directory_path)
		return

	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		if not file_name.begins_with("."):
			var path: String = "%s/%s" % [directory_path, file_name]
			if directory.current_is_dir():
				_load_boosters(path)
			elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var booster: BoosterDefinition = ResourceLoader.load(path) as BoosterDefinition
				if booster != null:
					boosters[booster.id] = booster
		file_name = directory.get_next()
	directory.list_dir_end()

func _load_shops(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		return

	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		if not file_name.begins_with("."):
			var path: String = "%s/%s" % [directory_path, file_name]
			if directory.current_is_dir():
				_load_shops(path)
			elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var shop: ShopDefinition = ResourceLoader.load(path) as ShopDefinition
				if shop != null:
					shops[shop.id] = shop
		file_name = directory.get_next()
	directory.list_dir_end()
