class_name CardDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var type: ScopeEnums.CardType = ScopeEnums.CardType.INPUT
@export var tags: PackedStringArray = PackedStringArray()
@export_multiline var short_text: String = ""
@export_multiline var tooltip_text: String = ""
@export var visual: CardVisualDefinition = CardVisualDefinition.new()
@export var base_values: Dictionary = {}
@export var default_state: Dictionary = {}
