extends Control
class_name BiggameSettingsController

var game_room_manager: GameRoomManagerBase
var biggame_id: int

func setup(_game_room_manager: GameRoomManagerBase, _biggame_id: int) -> void:
	self.game_room_manager = _game_room_manager
	self.biggame_id = _biggame_id