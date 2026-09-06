extends Node
class_name MinigameInstructionPlayerInfoController

@export var player_icon_rect: TextureRect
@export var ready_label: Label
@export var not_ready_label: Label

var character_id: int

func setup(_character_id: int) -> void:
	self.character_id = _character_id

func _ready() -> void:
	set_ready(false)
	player_icon_rect.texture = CharacterManager.get_character_by(character_id).character_icon

func set_ready(_ready_state: bool) -> void:
	ready_label.visible = _ready_state
	not_ready_label.visible = not _ready_state