extends Control
class_name GameRoomMenuController

# Objects/Scenes
@export_subgroup("Scenes")
@export var biggame_item_scene: PackedScene

# UI Refs
@export_subgroup("UI")
@export var online_information: Control
@export var room_number: Label
@export var host: Label
@export var settings_container: PanelContainer
@export var biggame_selection_container: HBoxContainer
@export var back: Button
@export var player_settings_panel: Panel
@export var player_settings: PlayerSettingsController
@export var player_info_buttons: Array[MenuPlayerInfoButtonController]

# Parent Refs
var game_room_manager: GameRoomManagerBase

# Parameter
var biggame_infos: Array[BiggameInfo]

func setup(_game_room_manager: GameRoomManagerBase, _biggame_infos: Array[BiggameInfo]) -> void: 
	self.game_room_manager = _game_room_manager
	self.biggame_infos = _biggame_infos
	

func _ready() -> void:
	online_information.visible = false
	settings_container.visible = false
	_create_biggame_selection_ui()
	biggame_selection_container.visible = false
	player_settings_panel.visible = false
	player_settings.setup(game_room_manager)
	for i: int in player_info_buttons.size():
		player_info_buttons[i].setup(game_room_manager,i)

func _create_biggame_selection_ui() -> void:
	for biggame_info: BiggameInfo in biggame_infos:
		var item: BiggameItem = biggame_item_scene.instantiate()
		item.setup(self,biggame_info)
		biggame_selection_container.add_child(item)

func update_player_info(player_id: int, player_info: GameRoomManagerBase.PlayerInformation) -> void:
	player_info_buttons[player_id].update_ui(player_info)

func show_online_info(_room_number: String, _host: String) -> void:
	online_information.visible = true
	room_number.text = _room_number
	host.text = _host

func show_biggame_selection() -> void:
	settings_container.visible = false
	biggame_selection_container.visible = true

func show_biggame_settings(_biggame_settings: BiggameSettingsController) -> void:
	settings_container.visible = true
	biggame_selection_container.visible = false
	for child: Node in settings_container.get_children():
		child.queue_free()
	settings_container.add_child(_biggame_settings, true)

func show_player_info_edit(_player_info: GameRoomManagerBase.PlayerInformation, player_id: int) -> void:
	player_settings_panel.visible = true
	player_settings.update(_player_info,player_id)

func update_player_settings(_player_info: GameRoomManagerBase.PlayerInformation, player_id: int) -> void:
	player_settings.update(_player_info,player_id)

func hide_player_info_edit() -> void:
	player_settings_panel.visible = false

func on_biggame_button_pressed(_biggame_id: int) -> void:
	game_room_manager.select_biggame(_biggame_id)

func _on_disconnect_pressed() -> void:
	game_room_manager.dissconnect()

func _on_back_pressed() -> void:
	game_room_manager.back()


func _on_button_pressed() -> void:
	DisplayServer.clipboard_set(room_number.text)
