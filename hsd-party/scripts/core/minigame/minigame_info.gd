extends Resource
class_name MinigameInfo

enum MinigameTypes {
	FFA,
	ONE_VS_ONE,
	TWO_VS_TWO,
	ONE_VS_TWO,
	ONE_VS_THREE,
}

static func minigame_type_to_text(type: MinigameTypes) -> String:
	match type:
		MinigameTypes.FFA: return "FFA"
		MinigameTypes.ONE_VS_ONE: return "1 VS 1"
		MinigameTypes.TWO_VS_TWO: return "2 VS 2"
		MinigameTypes.ONE_VS_TWO: return "1 VS 2"
		MinigameTypes.ONE_VS_THREE: return "1 VS 3"
	return ""

var id: int

@export_subgroup("PreviewDescription")
@export var name: String = "Dummy Title"
@export_multiline var preview_description: String = "Short Description for the Minigame"
@export var icon: Texture2D = preload("res://icon.svg")

@export_subgroup("ConrolInfo")
@export var control_info: Array[ControlInfo]
@export_multiline var game_description: String = "Win the game by collecting the most points."

@export_subgroup("Scenes")
@export var level: PackedScene = preload("res://scenes/level/minigames/minigame_debug.tscn")

@export_subgroup("Supported functions")
@export var instruction_playing: bool = false
@export var ai_player: bool = false
@export var online_multiplayer: bool = false
@export var min_player: int = 1
@export var max_player: int = 4
@export var game_types: Array[MinigameTypes] = [MinigameTypes.FFA]

@export var debug_minigame: bool = false
