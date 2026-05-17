class_name EffectContext
extends RefCounted

var state: RunState = null
var stack: StackState = null
var recipe: RecipeDefinition = null
var active_input_card_ids: PackedStringArray = PackedStringArray()
var content: ContentCatalog = null
var rng: RandomNumberGenerator = null
var spawn_card: Callable = Callable()
var remove_card: Callable = Callable()
var get_spawn_position: Callable = Callable()
var reveal_shop_slot: Callable = Callable()
