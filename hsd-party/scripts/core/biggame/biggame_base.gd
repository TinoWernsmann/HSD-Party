extends Node
class_name BigGameBase

var biggame_id: int
var game_room_manager: GameRoomManagerBase
var biggame_settings: BiggameManager.BiggameSettings
var player_information: Array[GameRoomManagerBase.PlayerInformation]

func setup(_biggame_id: int, _game_room_manager: GameRoomManagerBase, _player_information: Array[GameRoomManagerBase.PlayerInformation]) -> void:
	self.biggame_id = _biggame_id
	self.game_room_manager = _game_room_manager
	for p_info: GameRoomManagerBase.PlayerInformation in _player_information:
		if p_info == null:
			push_error("Player information is null in biggame_base! Please only pass player, that play the biggame.")
	self.player_information = _player_information

func set_settings(_biggame_settings: BiggameManager.BiggameSettings) -> void:
	self.biggame_settings = _biggame_settings

func start() -> void:
	pass

func pause() -> void:
	pass

func resume() -> void:
	pass

func minigame_instruction_ready(_game_data: MinigameBase.GameData) -> void:
	pass

func finish_minigame(_result: MinigameBase.MinigameResult) -> void:
	pass
