extends MainManager

@export var offline_game_room_manager_scene: PackedScene

var game_room: OfflineGameRoomManager

func _ready() -> void:
	game_room = offline_game_room_manager_scene.instantiate()
	game_room.setup(self)
	add_child(game_room)

func quit_gameroom() -> void:
	hsd_party.back_to_menu()
