extends Node
class_name MinigameSelectionItem

@onready var title: Label = $VBoxContainer/Title
@onready var thumbnail: TextureRect = $VBoxContainer/Control/Thumbnail

var minigame_info: MinigameInfo
var minigame_settings: BiggameSettingsMinigame


func setup(_minigame_info: MinigameInfo, _minigame_settings: BiggameSettingsMinigame) -> void:
	self.minigame_info = _minigame_info
	self.minigame_settings = _minigame_settings

func _ready() -> void:
	title.text = minigame_info.name
	thumbnail.texture = minigame_info.icon


func _on_pressed() -> void:
	minigame_settings.select_minigame(minigame_info.id)
