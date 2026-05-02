class_name RecipeInputMatcher
extends Resource

@export var card_definition_id: String = ""
@export var required_tags: PackedStringArray = PackedStringArray()
@export_range(1, 100, 1, "or_greater") var count: int = 1
