class_name ActiveProcessingInteractionService
extends RefCounted

const ActiveProcessingInteractionResultScript: Script = preload("res://scripts/simulation/active_processing_interaction_result.gd")
const OPERATION_ADD_DURATION_PROGRESS_FRACTION: int = 0

func calculate(
	moving_card_ids: PackedStringArray,
	target_stack: StackState,
	state: RunState,
	content: ContentCatalog
) -> RefCounted:
	var result: RefCounted = ActiveProcessingInteractionResultScript.new()
	if moving_card_ids.is_empty() or target_stack == null or not target_stack.processing_state.is_active():
		return result

	var interaction: Resource = _get_card_interaction(moving_card_ids[0], state, content)
	if interaction == null:
		return result

	for card_id: String in moving_card_ids:
		var card_interaction: Resource = _get_card_interaction(card_id, state, content)
		if card_interaction == null or not _interactions_match(interaction, card_interaction):
			return ActiveProcessingInteractionResultScript.new()

	if not _target_stack_has_card_type(target_stack, state, content, interaction.get("required_target_card_type") as ScopeEnums.CardType):
		return result

	match interaction.get("operation") as int:
		OPERATION_ADD_DURATION_PROGRESS_FRACTION:
			_calculate_duration_progress(result, moving_card_ids, target_stack, interaction)
		_:
			return ActiveProcessingInteractionResultScript.new()

	return result

func _calculate_duration_progress(
	result: RefCounted,
	moving_card_ids: PackedStringArray,
	target_stack: StackState,
	interaction: Resource
) -> void:
	var max_applications: int = interaction.get("max_applications_per_drop") as int
	var progress_fraction_per_card: float = interaction.get("progress_fraction_per_card") as float
	var applications: int = mini(moving_card_ids.size(), max_applications)
	if applications <= 0 or progress_fraction_per_card <= 0.0:
		return

	var processing: ProcessingState = target_stack.processing_state
	if processing.duration <= 0.0 or processing.elapsed >= processing.duration:
		return

	var progress_added: float = processing.duration * progress_fraction_per_card * float(applications)
	var new_elapsed: float = processing.elapsed + progress_added
	var allow_instant_complete: bool = interaction.get("allow_instant_complete") as bool
	if new_elapsed >= processing.duration and not allow_instant_complete:
		new_elapsed = maxf(0.0, processing.duration - 0.01)

	result.applied = true
	result.progress_added = progress_added
	result.new_elapsed = minf(processing.duration, new_elapsed)
	result.should_complete = new_elapsed >= processing.duration and allow_instant_complete

	if interaction.get("consume_cards_on_success") as bool:
		for index: int in applications:
			result.consumed_card_ids.append(moving_card_ids[index])

func _get_card_interaction(
	card_id: String,
	state: RunState,
	content: ContentCatalog
) -> Resource:
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return null

	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	if definition == null:
		return null

	return definition.processing_interaction

func _target_stack_has_card_type(
	target_stack: StackState,
	state: RunState,
	content: ContentCatalog,
	required_type: ScopeEnums.CardType
) -> bool:
	for card_id: String in target_stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.type == required_type:
			return true
	return false

func _interactions_match(left: Resource, right: Resource) -> bool:
	return left.get("operation") as int == right.get("operation") as int \
		and is_equal_approx(left.get("progress_fraction_per_card") as float, right.get("progress_fraction_per_card") as float) \
		and left.get("max_applications_per_drop") as int == right.get("max_applications_per_drop") as int \
		and left.get("required_target_card_type") as ScopeEnums.CardType == right.get("required_target_card_type") as ScopeEnums.CardType \
		and left.get("consume_cards_on_success") as bool == right.get("consume_cards_on_success") as bool \
		and left.get("allow_instant_complete") as bool == right.get("allow_instant_complete") as bool
