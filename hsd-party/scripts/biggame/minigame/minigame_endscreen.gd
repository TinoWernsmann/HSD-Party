extends Node3D
class_name BiggameMinigame_Endscreen

@export var player_scene: PackedScene

@export var ffa_root_mode: Node3D
@export var cylinder_container: CSGCombiner3D

@export var team_root_mode: Node3D
@export var winner_team_cylinder: CSGCylinder3D
@export var looser_team_cylinder: CSGCylinder3D
@export var looser_label: Label3D

var duration: float = 5.0
var paused: bool = false

var result: MinigameBase.MinigameResult
var biggame_minigame: BiggameMinigame
var game_room_manager: GameRoomManagerBase


func setup(_biggame_minigame: BiggameMinigame, _game_room_manager: GameRoomManagerBase) -> void:
	self.biggame_minigame = _biggame_minigame
	self.game_room_manager = _game_room_manager

func set_restul(_result: MinigameBase.MinigameResult) -> void:
	self.result = _result


func _ready() -> void:
	if game_room_manager.is_online():
		if !multiplayer.is_server():
			_request_sync_server_rpc.rpc_id(1)
	else:
		if result is MinigameBase.FFAResult:
			_setup_scene_ffa(result as MinigameBase.FFAResult)
		elif result is MinigameBase.TeamResults:
			_setup_scene_team(result as MinigameBase.TeamResults)

# --------------------
#    ServerMethoden
# --------------------
@rpc("any_peer", "call_remote", "reliable")
func _request_sync_server_rpc() -> void:
	if result is MinigameBase.FFAResult:
		var ffa_result: MinigameBase.FFAResult = result
		var places: Array[int] = []
		for x: GameRoomManagerBase.PlayerInformation in ffa_result.game_data.all_player_infos():
			places.append(ffa_result.get_places_for_player(x))
		_set_ffa_game_result_client_rpc.rpc_id(multiplayer.get_remote_sender_id(), ffa_result.game_data.all_player_nrs(), places)
	elif result is MinigameBase.TeamResults:
		var team_result: MinigameBase.TeamResults = result
		var places: Array[int] = []
		for x: MinigameBase.TeamGameData.Team in team_result.game_data.teams:
			places.append(team_result.get_places_for_team(x))
		_set_team_result_client_rpc.rpc_id(multiplayer.get_remote_sender_id(), team_result.game_data.teams[0].all_player_nrs(), team_result.game_data.teams[1].all_player_nrs(), places)

func _on_sync() -> void:
	pass

func start_minigame() -> void:
	pass


# --------------------
#    ClientMethoden
# --------------------
@rpc("authority", "call_remote", "reliable")
func _set_ffa_game_result_client_rpc(player_nrs: Array[int], places: Array[int]) -> void:
	var player_infos: Array[GameRoomManagerBase.PlayerInformation] = []
	for nr: int in player_nrs:
		player_infos.append(game_room_manager.player_information[nr])
	var game_data: MinigameBase.FFAGameData = MinigameBase.FFAGameData.new(player_infos)
	result = game_data.create_result()
	for i: int in places.size():
		result.add_to_place(player_infos[i],places[i])
	_setup_scene_ffa(result as MinigameBase.FFAResult)


@rpc("authority", "call_remote", "reliable")
func _set_team_result_client_rpc(team_1: Array[int], team_2: Array[int], places: Array[int]) -> void:
	var teams: Array[MinigameBase.TeamGameData.Team] = []
	for team_nrs: Array[int] in [team_1, team_2]:
		var team_players: Array[GameRoomManagerBase.PlayerInformation] = []
		for nr: int in team_nrs:
			team_players.append(game_room_manager.player_information[nr])
		teams.append(MinigameBase.TeamGameData.Team.new(team_players))
	var game_data: MinigameBase.TeamGameData = MinigameBase.TeamGameData.new(teams)
	result = game_data.create_result()
	for i: int in places.size():
		result.add_to_place(game_data.teams[i],places[i])
	_setup_scene_team(result as MinigameBase.TeamResults)

func _setup_scene_ffa(ffa_result: MinigameBase.FFAResult) -> void:
	ffa_root_mode.visible = true
	team_root_mode.visible = false
	_place_player_ffa(ffa_result)

func _place_player_ffa(ffa_result: MinigameBase.FFAResult) -> void:
	var player_infos: Array[GameRoomManagerBase.PlayerInformation] = ffa_result.game_data.all_player_infos()
	var distance_between_two: float = (4.0 - player_infos.size() / 2.0)
	for i: int in player_infos.size():
		#Data
		var player_info: GameRoomManagerBase.PlayerInformation = player_infos[i]
		var score: int = ffa_result.get_places_for_player(player_info)
		var x: float = float(score) / ffa_result.places.size()

		# Cylinder
		var cylinder: CSGCylinder3D = CSGCylinder3D.new()
		cylinder.radius = 0.6
		cylinder.height = 5
		cylinder_container.add_child(cylinder)
		cylinder.global_position = Vector3(i * distance_between_two - (player_infos.size() - 1) * distance_between_two/2, -2 -x * 0.5, -0.5 -player_infos.size() * 0.2)
		
		var player: BiggameHSDCampus_EndingScreenPlayer = player_scene.instantiate()
		player.setup(player_info.character_info().character_texture)
		ffa_root_mode.add_child(player)
		player.global_position = cylinder.global_position + Vector3(0,2.5,0)
		var light: SpotLight3D = SpotLight3D.new()	
		light.light_energy = 25 - (x * 23.0)	
		light.spot_angle_attenuation = player_infos.size() - score
		light.spot_range = 20
		light.spot_angle = 25 - x * 12
		light.light_color = _normalize_color_brightness(player_info.character_info().character_color, 0.8)
		ffa_root_mode.add_child(light)
		light.global_position = player.global_position + Vector3(0,4,4)
		light.look_at(player.global_position + Vector3(0,0.5,0), Vector3.UP)
		
		var label: Label3D = Label3D.new()
		label.text = str(score) + "."
		label.modulate = player_info.character_info().character_color
		label.outline_modulate = player_info.character_info().contrast_color
		label.shaded = true
		label.outline_size = 5
		label.font_size = 150
		ffa_root_mode.add_child(label)
		label.global_position = player.global_position + Vector3(0, 1.5, -0.2)

func _setup_scene_team(team_result: MinigameBase.TeamResults) -> void:
	ffa_root_mode.visible = false
	team_root_mode.visible = true
	var winner_player: Array[GameRoomManagerBase.PlayerInformation] = []
	for team: MinigameBase.TeamGameData.Team in team_result.places[0].teams:
		winner_player.append_array(team.players)
	winner_team_cylinder.radius = 0.2 + 0.4 * winner_player.size()
	_place_player_team(winner_team_cylinder, winner_player, 100)
	if team_result.places.size() > 1:
		var looser_player: Array[GameRoomManagerBase.PlayerInformation] = []
		for place: MinigameBase.TeamResults.TeamPlace in team_result.places:
			if place == team_result.places[1]:
				looser_player.append_array(place.teams[0].players)
		looser_team_cylinder.radius = 0.2 + 0.4 * looser_player.size()
		_place_player_team(looser_team_cylinder, looser_player, 50)
	else:
		looser_team_cylinder.visible = false
		looser_label.visible = false

func _place_player_team(cylinder: CSGCylinder3D, player_infos: Array[GameRoomManagerBase.PlayerInformation], light_intensity: float) -> void:
	for i: int in player_infos.size():
		var player_info: GameRoomManagerBase.PlayerInformation = player_infos[i]
		var player: BiggameHSDCampus_EndingScreenPlayer = player_scene.instantiate()
		player.setup(player_info.character_info().character_texture)
		team_root_mode.add_child(player)
		player.global_position = cylinder.global_position + Vector3(i * 1 - (player_infos.size() - 1) * 0.5,cylinder.height * 0.5,0)

		var light: SpotLight3D = SpotLight3D.new()
		light.light_energy = light_intensity / player_infos.size()
		light.spot_attenuation = 1.5
		light.spot_angle_attenuation = 30
		light.spot_range = 10
		light.spot_angle = 13
		light.light_color = _normalize_color_brightness(player_info.character_info().character_color, 0.8)
		team_root_mode.add_child(light)
		light.global_position = player.global_position + Vector3(0,3,3)
		light.look_at(player.global_position + Vector3(0,0.2,0), Vector3.UP)

func _normalize_color_brightness(color: Color, target_luminance: float = 0.5) -> Color:
	var lum: float = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
	if lum == 0:
		return color
	var factor: float = target_luminance / lum
	return Color(
		clampf(color.r * factor, 0.0, 1.0),
		clampf(color.g * factor, 0.0, 1.0),
		clampf(color.b * factor, 0.0, 1.0)
	)

# Called every frame. 'delta' is the elapsed time since the previöous frame.
func _process(_delta: float) -> void:
	duration -= _delta
	if duration <= 0.0 and not paused:
		biggame_minigame.minigame_endscreen_finished()

func pause() -> void:
	paused = true

func resume() -> void:
	paused = false