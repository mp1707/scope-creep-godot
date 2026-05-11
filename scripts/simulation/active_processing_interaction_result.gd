class_name ActiveProcessingInteractionResult
extends RefCounted

var applied: bool = false
var consumed_card_ids: PackedStringArray = PackedStringArray()
var remaining_before: float = 0.0
var remaining_after: float = 0.0
var new_elapsed: float = 0.0
var should_complete: bool = false
