class_name ContentCatalog
extends RefCounted

const CARD_DIR: String = "res://data/cards"
const BALANCE_PATH: String = "res://data/balance/poc_default.tres"

var cards: Dictionary = {}
var balance: BalanceDefinition = null

func load_default_content() -> bool:
	cards.clear()
	_load_cards(CARD_DIR)
	balance = ResourceLoader.load(BALANCE_PATH) as BalanceDefinition
	return not cards.is_empty() and balance != null

func get_card_definition(card_definition_id: String) -> CardDefinition:
	return cards.get(card_definition_id, null) as CardDefinition

func has_card_definition(card_definition_id: String) -> bool:
	return cards.has(card_definition_id)

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
