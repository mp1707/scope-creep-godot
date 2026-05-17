class_name RecipeDefinition
extends Resource

@export var id: String = ""
@export var display_text: String = ""
@export var inputs: Array[RecipeInputMatcher] = []
@export var constraints: Array[RecipeConstraintDefinition] = []
@export var duration: DurationDefinition = DurationDefinition.new()
@export var priority: int = 0
@export var specificity_score: int = 0
@export var effects_on_start: Array[EffectDefinition] = []
@export var effects_on_complete: Array[EffectDefinition] = []
@export var effects_on_cancel: Array[EffectDefinition] = []
@export var allowed_extra_inputs: Array[RecipeInputMatcher] = []
@export var ignore_unmatched_extra_inputs: bool = false
@export var duration_modifier_tags: PackedStringArray = PackedStringArray()
