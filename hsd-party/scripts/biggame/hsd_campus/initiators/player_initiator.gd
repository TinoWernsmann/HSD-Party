extends Node
class_name BiggameHSDCampus_PlayerInit

@export var player_scene: PackedScene
@export var player_parent: Node3D
@export var selected_dice: BiggameHSDCampus_Dice
@export var start_tile: BiggameHSDCampus_Tile
@export var offset: Array[Vector3]
@export var player_material: StandardMaterial3D

func gather_players(game_manager: BiggameHSDCampus_GameManager, _player_informations: Array[GameRoomManagerBase.PlayerInformation]) -> void:
	game_manager.players.clear()
	var player_count: int = 0;
	for player_info: GameRoomManagerBase.PlayerInformation in _player_informations:
		var player: BiggameHSDCampus_Player = player_scene.instantiate() as BiggameHSDCampus_Player
		var new_material: StandardMaterial3D = player_material.duplicate() as StandardMaterial3D
		new_material.albedo_texture = CharacterManager.get_character_by(player_info.character_id).character_texture
		player.setup(game_manager, player_count, selected_dice, start_tile, offset[player_count], new_material)
		player_count += 1
		player_parent.add_child(player)
		game_manager.players.append(player)
	
	for player: BiggameHSDCampus_Player in game_manager.players:
		if not player.inventory_manager.on_item_use.is_connected(game_manager._on_player_item_use):
			player.inventory_manager.on_item_use.connect(game_manager._on_player_item_use)
		if not player.inventory_manager.on_item_cycle.is_connected(game_manager.ui_manager._on_player_cycle):
			player.inventory_manager.on_item_cycle.connect(game_manager.ui_manager._on_player_cycle)
		if not player.inventory_manager.on_item_cancel.is_connected(game_manager.ui_manager._on_player_cancel):
			player.inventory_manager.on_item_cancel.connect(game_manager.ui_manager._on_player_cancel)
