extends Node
class_name MinigameInstructionInputDescriptionController

@export var label: Label
@export var icon: ControlIcon

var control_info: ControlInfo
var player_info: Array[GameRoomManagerBase.PlayerInformation]

func setup(_control_info: ControlInfo, _player_info: Array[GameRoomManagerBase.PlayerInformation]) -> void:
	self.control_info = _control_info
	self.player_info = _player_info

func _ready() -> void:
	icon.set_controller_ids_from_player_information(player_info)
	if control_info is ControlInfoAxis:
		icon.show_axis((control_info as ControlInfoAxis ).input)
	elif control_info is ControlInfoButton:
		icon.show_button((control_info as ControlInfoButton ).input)
	label.text = control_info.control_description
