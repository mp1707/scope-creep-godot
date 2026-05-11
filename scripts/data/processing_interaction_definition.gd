class_name ProcessingInteractionDefinition
extends Resource

enum Operation {
	REDUCE_REMAINING_FRACTION,
}

@export var operation: Operation = Operation.REDUCE_REMAINING_FRACTION
@export_range(0.0, 1.0, 0.01) var remaining_fraction_per_card: float = 0.25
@export_range(1, 100, 1, "or_greater") var max_applications_per_drop: int = 4
@export var required_target_card_type: ScopeEnums.CardType = ScopeEnums.CardType.EMPLOYEE
@export var consume_cards_on_success: bool = true
@export var allow_instant_complete: bool = true
