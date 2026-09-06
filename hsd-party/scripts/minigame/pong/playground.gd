extends Node2D
class_name MinigamePong_Playgound

@export var player: Array[MinigamePong_Player]
@export var goals: Array[MinigamePong_Goal]
@export var gamefield_center: Node2D

var player_infos: Array[GameRoomManagerBase.PlayerInformation]
var game_room_manager: GameRoomManagerBase

func setup(_player_infos: Array[GameRoomManagerBase.PlayerInformation], _game_room_manager: GameRoomManagerBase, _minigame_pong: MinigamePong) -> void:
	self.player_infos = _player_infos
	self.game_room_manager = _game_room_manager
	for i: int in player.size():
		player[i].setup(player_infos[i], _minigame_pong, game_room_manager)
		goals[i].setup(i,CharacterManager.get_character_by(player_infos[i].character_id).character_color,_minigame_pong)
	pause()

func resume() -> void:
	for x: MinigamePong_Player in player:
		x.process_mode = Node.PROCESS_MODE_INHERIT

func pause() -> void:
	for x: MinigamePong_Player in player:
		x.process_mode = Node.PROCESS_MODE_DISABLED
