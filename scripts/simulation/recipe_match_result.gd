class_name RecipeMatchResult
extends RefCounted

var recipe: RecipeDefinition = null
var ambiguous_recipe_ids: PackedStringArray = PackedStringArray()

func has_match() -> bool:
	return recipe != null

func is_ambiguous() -> bool:
	return not ambiguous_recipe_ids.is_empty()
