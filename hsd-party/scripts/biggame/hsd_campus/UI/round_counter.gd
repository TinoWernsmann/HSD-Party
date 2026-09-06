extends Label
class_name BiggameHSDCampus_RoundCounter

var default_text: String = "Runde: "
@onready var round_label: Label = $"."

func _ready() -> void:
	text = default_text + str(1)

func set_round(round_number: int) -> void:
	text = default_text + str(round_number)
