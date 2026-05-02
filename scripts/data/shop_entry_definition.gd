class_name ShopEntryDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_range(0, 1000, 1, "or_greater") var cost_money_cards: int = 1
@export var card_definition_id: String = ""
@export var booster_definition_id: String = ""
@export var effects_on_buy: Array[EffectDefinition] = []
