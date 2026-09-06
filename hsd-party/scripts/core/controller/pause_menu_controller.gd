extends Control
class_name PauseMenuConttroller

var game_room_manager: GameRoomManagerBase

func setup(_game_room_manager: GameRoomManagerBase) -> void: 
	self.game_room_manager = _game_room_manager

func _on_back_to_game_pressed() -> void:
	game_room_manager.pause_resume_pressed(-1)

func _on_leave_game_pressed() -> void:
	game_room_manager.leave_game_pressed()
