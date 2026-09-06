extends Node
class_name MinigamePong_ScoreInfoController

@export var score_label: Label
@export var avate_rect: TextureRect
@export var panel_container: PanelContainer

var character_info: CharacterInfo

func setup(_character_info: CharacterInfo) -> void:
	self.character_info = _character_info

func _ready() -> void:
	var stylebox: StyleBoxFlat = panel_container.get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = character_info.character_color
	panel_container.add_theme_stylebox_override("panel", stylebox)
	score_label.modulate = character_info.contrast_color
	avate_rect.texture = character_info.character_icon

func set_score(score: int) -> void:
	score_label.text = str(score)

