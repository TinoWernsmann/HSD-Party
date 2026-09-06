extends Node3D
class_name BiggameHSDCampus_EndingScreen

@export var endgame_player_scene: PackedScene
@export var spawn_point: Array[Node3D]

var player_data: Array[GameRoomManagerBase.PlayerInformation]

var timestamp_on_ready: int
var hsd_campus: BiggameHSDCampus

func setup(_player_data: Array[GameRoomManagerBase.PlayerInformation], _hsd_campus: BiggameHSDCampus) -> void:
	self.player_data = _player_data
	self.hsd_campus = _hsd_campus

func _ready() -> void:
	timestamp_on_ready = Time.get_ticks_msec()
	for i: int in player_data.size():
		var player_instance: BiggameHSDCampus_EndingScreenPlayer = endgame_player_scene.instantiate() as BiggameHSDCampus_EndingScreenPlayer
		player_instance.transform.origin = spawn_point[i].transform.origin
		player_instance.transform.basis = spawn_point[i].transform.basis
		player_instance.setup(CharacterManager.get_character_by(player_data[i].character_id).character_texture)
		add_child(player_instance)

func _process(_delta: float) -> void:
	if timestamp_on_ready + 3000 < Time.get_ticks_msec():
		hsd_campus.finish_endscreen()
