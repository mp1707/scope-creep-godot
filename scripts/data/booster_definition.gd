class_name BoosterDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_range(0, 1000, 1, "or_greater") var cost_money_cards: int = 1
@export_range(1, 100, 1, "or_greater") var draw_count: int = 3
@export var fixed_card_definition_ids: PackedStringArray = PackedStringArray()
@export var pool_entries: Array[BoosterPoolEntry] = []
@export var open_effects: Array[EffectDefinition] = []
