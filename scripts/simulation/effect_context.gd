class_name EffectContext
extends RefCounted

var state: RunState = null
var stack: StackState = null
var recipe: RecipeDefinition = null
var content: ContentCatalog = null
var rng: RandomNumberGenerator = null
var spawn_card: Callable = Callable()
var remove_card: Callable = Callable()
