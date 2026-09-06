extends Button
class_name BiggameItem

@export_subgroup("Textures")
@export var ai_not_allowed: Texture2D
@export var ai_allowed: Texture2D

@export_subgroup("UI")
@export var player_count_label: Label
@export var ai_rect: TextureRect

var room_game_selection_menu_controller: GameRoomMenuController
var biggame_info: BiggameInfo

func setup(_room_game_selection_menu_controller: GameRoomMenuController, _biggame_info: BiggameInfo) -> void:
		self.biggame_info = _biggame_info
		self.room_game_selection_menu_controller = _room_game_selection_menu_controller

func _ready() -> void:
	text = biggame_info.name
	player_count_label.text = str(biggame_info.min_player) + " - " + str(biggame_info.max_player)
	if biggame_info.ai_player:
		ai_rect.texture = ai_allowed
	else:
		ai_rect.texture = ai_not_allowed

func _on_pressed() -> void:
	room_game_selection_menu_controller.on_biggame_button_pressed(biggame_info.id)
