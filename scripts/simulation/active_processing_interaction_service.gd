class_name ActiveProcessingInteractionService
extends RefCounted

const ActiveProcessingInteractionResultScript: Script = preload("res://scripts/simulation/active_processing_interaction_result.gd")
const OPERATION_ADD_DURATION_PROGRESS_FRACTION: int = 0

func calculate(
	moving_card_ids: PackedStringArray,
	target_stack: StackState,
	state: RunState,
	content: ContentCatalog
) -> ActiveProcessingInteractionResult:
	var result: ActiveProcessingInteractionResult = ActiveProcessingInteractionResultScript.new() as ActiveProcessingInteractionResult
	if moving_card_ids.is_empty() or target_stack == null or not target_stack.processing_state.is_active():
		return result

	var interaction: ProcessingInteractionDefinition = _get_card_interaction(moving_card_ids[0], state, content)
	if interaction == null:
		return result

	for card_id: String in moving_card_ids:
		var card_interaction: ProcessingInteractionDefinition = _get_card_interaction(card_id, state, content)
		if card_interaction == null or not _interactions_match(interaction, card_interaction):
			return ActiveProcessingInteractionResultScript.new() as ActiveProcessingInteractionResult

	if not _target_stack_has_card_type(target_stack, state, content, interaction.required_target_card_type):
		return result

	match interaction.operation:
		OPERATION_ADD_DURATION_PROGRESS_FRACTION:
			_calculate_duration_progress(result, moving_card_ids, target_stack, interaction)
		_:
			return ActiveProcessingInteractionResultScript.new() as ActiveProcessingInteractionResult

	return result

func _calculate_duration_progress(
	result: ActiveProcessingInteractionResult,
	moving_card_ids: PackedStringArray,
	target_stack: StackState,
	interaction: ProcessingInteractionDefinition
) -> void:
	var max_applications: int = interaction.max_applications_per_drop
	var progress_fraction_per_card: float = interaction.progress_fraction_per_card
	var applications: int = mini(moving_card_ids.size(), max_applications)
	if applications <= 0 or progress_fraction_per_card <= 0.0:
		return

	var processing: ProcessingState = target_stack.processing_state
	if processing.duration <= 0.0 or processing.elapsed >= processing.duration:
		return

	var progress_added: float = processing.duration * progress_fraction_per_card * float(applications)
	var new_elapsed: float = processing.elapsed + progress_added
	var allow_instant_complete: bool = interaction.allow_instant_complete
	if new_elapsed >= processing.duration and not allow_instant_complete:
		new_elapsed = maxf(0.0, processing.duration - 0.01)

	result.applied = true
	result.progress_added = progress_added
	result.new_elapsed = minf(processing.duration, new_elapsed)
	result.should_complete = new_elapsed >= processing.duration and allow_instant_complete

	if interaction.consume_cards_on_success:
		for index: int in applications:
			result.consumed_card_ids.append(moving_card_ids[index])

func _get_card_interaction(
	card_id: String,
	state: RunState,
	content: ContentCatalog
) -> ProcessingInteractionDefinition:
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

func _interactions_match(left: ProcessingInteractionDefinition, right: ProcessingInteractionDefinition) -> bool:
	return left.operation == right.operation \
		and is_equal_approx(left.progress_fraction_per_card, right.progress_fraction_per_card) \
		and left.max_applications_per_drop == right.max_applications_per_drop \
		and left.required_target_card_type == right.required_target_card_type \
		and left.consume_cards_on_success == right.consume_cards_on_success \
		and left.allow_instant_complete == right.allow_instant_complete
