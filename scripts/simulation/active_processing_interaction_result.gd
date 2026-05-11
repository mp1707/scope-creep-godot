class_name ActiveProcessingInteractionResult
extends RefCounted

var applied: bool = false
var consumed_card_ids: PackedStringArray = PackedStringArray()
var progress_added: float = 0.0
var new_elapsed: float = 0.0
var should_complete: bool = false
