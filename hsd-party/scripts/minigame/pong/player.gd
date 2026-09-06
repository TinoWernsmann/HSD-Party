extends CharacterBody2D
class_name MinigamePong_Player

var max_speed: float = 4
var acceleration: float = 10
var deceleration: float = 10
@export var paddle_range: float = 320.0
@export var sprite: Sprite2D


var speed: float = 0.0
var player_info: GameRoomManagerBase.PlayerInformation
var game_room_manager: GameRoomManagerBase

var ai_brain: MinigamePong_AIPlayerBrain

func setup(_player_info: GameRoomManagerBase.PlayerInformation, _pong: MinigamePong, _game_room_manager: GameRoomManagerBase) -> void:
	self.player_info = _player_info
	self.game_room_manager = _game_room_manager
	if player_info is GameRoomManagerBase.AIPlayerInformation:
		match (player_info as GameRoomManagerBase.AIPlayerInformation).difficulty:
			GameRoomManagerBase.AIPlayerInformation.AIDifficulty.EASY:
				ai_brain = MinigamePong_EasyAIPlayerBrain.new(_pong, self)
			GameRoomManagerBase.AIPlayerInformation.AIDifficulty.MEDIUM:
				ai_brain = MinigamePong_MediumAIPlayerBrain.new(_pong, self)
			GameRoomManagerBase.AIPlayerInformation.AIDifficulty.HARD:
				ai_brain = MinigamePong_HardAIPlayerBrain.new(_pong, self)

func _ready() -> void:
	sprite.modulate = CharacterManager.get_character_by(player_info.character_id).character_color

func _get_input() -> float:
	if player_info is GameRoomManagerBase.ThisClientPlayerInformation:
		return _get_player_input()
	elif player_info is GameRoomManagerBase.AIPlayerInformation:
		return ai_brain.get_input()
	return 0

func _get_player_input() -> float:
	return -game_room_manager.input_get_axis(player_info.player_nr, ControllerDefinition.Axis.HORIZONTAL)

func _physics_process(_delta: float) -> void:
	var input: float = _get_input()
	if input != 0.0:
		if sign(speed) != sign(input):
			speed = 0.0
		var target_speed: float = input * max_speed * paddle_range
		speed = move_toward(speed, target_speed, acceleration * _delta * paddle_range)
	else:
		speed = move_toward(speed, 0.0, deceleration * _delta * paddle_range)

	velocity = global_transform.y * speed
	move_and_slide()
	position.y = clampf(position.y, -paddle_range, paddle_range)
	position.x = 0
