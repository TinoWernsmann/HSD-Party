extends Control
class_name PlayerSettingsController

@export_subgroup("UI")
@export var player_label: Label
@export var difficulty_container: Container
@export var controller_container: Container
@export var character_container: Container
@export var client_label: Label
@export var difficulty_label: Label
@export var controller_texure: TextureRect
@export var character_texture: TextureRect

var game_room_manager: GameRoomManagerBase

var player_id: int

func setup(_game_room_manager: GameRoomManagerBase) -> void:
	self.game_room_manager = _game_room_manager

func update(player_info: GameRoomManagerBase.PlayerInformation, _player_id: int) -> void:
	self.player_id = _player_id
	player_label.text = "Spieler " + str(_player_id)
	if player_info == null:
		client_label.text = "Keiner"
		difficulty_container.visible = false
		controller_container.visible = false
		character_container.visible = false
		return
	if player_info is GameRoomManagerBase.ThisClientPlayerInformation:
		var this_info: GameRoomManagerBase.ThisClientPlayerInformation = player_info as GameRoomManagerBase.ThisClientPlayerInformation
		client_label.text = "Dieses Gerät"
		difficulty_container.visible = false
		controller_container.visible = true
		character_container.visible = true
		controller_texure.texture = ControllerManager.get_controller_definition_by(this_info.controller_id).icon
		character_texture.texture = CharacterManager.get_character_by(this_info.character_id).character_icon
		return
	if player_info is GameRoomManagerBase.OnlineClientPlayerInformation:
		var online_info: GameRoomManagerBase.OnlineClientPlayerInformation = player_info as GameRoomManagerBase.OnlineClientPlayerInformation
		client_label.text = str(online_info.peer_id)
		difficulty_container.visible = false
		controller_container.visible = false
		character_container.visible = true
		character_texture.texture = CharacterManager.get_character_by(online_info.character_id).character_icon
		return
	if player_info is GameRoomManagerBase.AIPlayerInformation:
		var ai_info: GameRoomManagerBase.AIPlayerInformation = player_info as GameRoomManagerBase.AIPlayerInformation
		client_label.text = "KI"
		difficulty_label.text = ai_info.difficulty_text()
		difficulty_container.visible = true
		controller_container.visible = false
		character_container.visible = true
		character_texture.texture = CharacterManager.get_character_by(ai_info.character_id).character_icon
		return

func _on_next_character_pressed() -> void:
	game_room_manager.player_settings_change_character(player_id, 1)
	
func _on_last_character_pressed() -> void:
	game_room_manager.player_settings_change_character(player_id, -1)

func _on_next_control_pressed() -> void:
	game_room_manager.player_settings_change_control(player_id, 1)

func _on_last_control_pressed() -> void:
	game_room_manager.player_settings_change_control(player_id, -1)
	
func _on_next_client_pressed() -> void:
	game_room_manager.player_settings_change_client(player_id, 1)

func _on_last_client_pressed() -> void:
	game_room_manager.player_settings_change_client(player_id, -1)

func _on_last_difficulty_pressed() -> void:
	game_room_manager.player_settings_change_difficulty(player_id, -1)

func _on_next_difficulty_pressed() -> void:
	game_room_manager.player_settings_change_difficulty(player_id, 1)

func _on_done_pressed() -> void:
	game_room_manager.player_settings_done()
