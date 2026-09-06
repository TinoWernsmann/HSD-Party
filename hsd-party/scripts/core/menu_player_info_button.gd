extends Control
class_name MenuPlayerInfoButtonController

@export_subgroup("Texture")
@export var no_player_icon: Texture2D
@export var cpu_image: Texture2D
@export var online_image: Texture2D

@export_subgroup("UI")
@export var character: TextureRect
@export var controler_type_controller: Panel
@export var controller_type: TextureRect
@export var player_number: Label

var game_room_manager: GameRoomManagerBase
var player_id: int

func setup(_game_room_manager: GameRoomManagerBase, _player_id: int) -> void:
	self.game_room_manager = _game_room_manager
	self.player_id = _player_id
	

func update_ui(_player_info: GameRoomManagerBase.PlayerInformation) -> void:
	player_number.text = str(player_id + 1)
	if _player_info == null:
		character.texture = no_player_icon
		controler_type_controller.visible = false
		player_number.visible = false
		return
	if _player_info is GameRoomManagerBase.ThisClientPlayerInformation:
		var _info: GameRoomManagerBase.ThisClientPlayerInformation = _player_info as GameRoomManagerBase.ThisClientPlayerInformation
		character.texture = CharacterManager.get_character_by(_info.character_id).character_icon
		controler_type_controller.visible = true
		controller_type.texture = ControllerManager.get_controller_definition_by(_info.controller_id).icon	
		player_number.visible = true
		return
	if _player_info is GameRoomManagerBase.OnlineClientPlayerInformation:
		character.texture = CharacterManager.get_character_by(_player_info.character_id).character_icon
		controler_type_controller.visible = true
		controller_type.texture = online_image
		player_number.visible = true
		return
	if _player_info is GameRoomManagerBase.AIPlayerInformation:
		character.texture = CharacterManager.get_character_by(_player_info.character_id).character_icon
		controler_type_controller.visible = true
		controller_type.texture = cpu_image
		player_number.visible = true
		return

func _on_pressed() -> void:
	game_room_manager.open_player_information(player_id)
