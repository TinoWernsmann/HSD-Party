### Handles the black screen animation after turn end
extends CanvasLayer
class_name BiggameHSDCampus_BlackScreen

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player_label: Label = $CenterContainer/Label

var default_text: String
var player_text: String

signal fade_halfway
signal fade_done

### Starts fade to black animation
func fade_to_black() -> void:
	animation_player.play("FadeToBlack")

func set_player_text(player_numb: int) -> void:
	player_text = default_text + str(player_numb)
	player_label.text = player_text

### Is called at halfway of the fade animation
func get_fade_halfway_signal() -> void:
	fade_halfway.emit()

### Is called at the end of the fade animation
func get_fade_done() -> void:
	fade_done.emit()

func set_empty_text() -> void:
	default_text = ""
	player_label.text = ""

func restore_text() -> void:
	default_text = "Spieler: "
