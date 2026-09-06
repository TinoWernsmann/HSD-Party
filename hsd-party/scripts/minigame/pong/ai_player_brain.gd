extends RefCounted
class_name MinigamePong_AIPlayerBrain

var pong: MinigamePong
var player: MinigamePong_Player
var player_parent: Node2D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(_pong: MinigamePong, _player: MinigamePong_Player) -> void:
	self.pong = _pong
	self.player = _player
	player_parent = player.get_parent() as Node2D


var aimed_pos: float = 0
var timestamp_last_input_change: int
var timestamp_last_aim_change: int

var input: float = 0


func get_input() -> float:
	if timestamp_last_aim_change + _input_time() < Time.get_ticks_msec():
		aimed_pos = _aim_pos()
		timestamp_last_aim_change = Time.get_ticks_msec()
	if timestamp_last_input_change + _input_time() < Time.get_ticks_msec():
		input = clampf((player.position.y - aimed_pos) / _input_time() * 1.5, -1, 1)
		if abs(input) < 0.3:
			input = 0
		timestamp_last_input_change = Time.get_ticks_msec()
	return -input
 
func _aim_time() -> float:
	return 0

func _input_time() -> float:
	return 0

func _aim_pos() -> float:
	return 0