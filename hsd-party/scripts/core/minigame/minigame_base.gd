extends Node
class_name MinigameBase

class MinigameResult:
	func add_to_place(_players: Variant, _place: int) -> void:
		pass

class FFAResult:
	extends MinigameResult	
	class FFAPlace:
		var players: Array[GameRoomManagerBase.PlayerInformation] = []

		func add_player(_player: GameRoomManagerBase.PlayerInformation) -> void:
			players.append(_player)

	var game_data: FFAGameData
	var places: Array[FFAPlace] = []

	func _init(_game_data: FFAGameData) -> void:
		self.game_data = _game_data

	func add_to_place(_players: Variant, _place: int) -> void:
		if _players is GameRoomManagerBase.PlayerInformation:
			var player_info: GameRoomManagerBase.PlayerInformation = _players
			if places.size() < _place:
				places.resize(_place)
				for i: int in places.size():
					if places[i] == null:
						places[i] = FFAPlace.new()
			places[_place - 1].add_player(player_info)
		else:
			push_error("Expected PlayerInformation, got %s" % typeof(_players))
			return

	func get_places_for_player(_player: GameRoomManagerBase.PlayerInformation) -> int:
		for i: int in places.size():
			var place: FFAPlace = places[i]
			if _player in place.players:
				return i + 1
		return -1

class TeamResults:
	extends MinigameResult
	
	class TeamPlace:
		var teams: Array[TeamGameData.Team] = []
		func add_team(_team: TeamGameData.Team) -> void:
			teams.append(_team)

	var game_data: TeamGameData
	var places: Array[TeamPlace] = []

	func _init( _game_data: TeamGameData) -> void:
		self.game_data = _game_data

	func add_to_place(_teams: Variant, _place: int) -> void:
		if _teams is TeamGameData.Team:
			var team: TeamGameData.Team = _teams
			if places.size() < _place:
				places.resize(_place)
				for i: int in places.size():
					if places[i] == null:
						places[i] = TeamPlace.new()
			places[_place - 1].add_team(team)
		else:
			push_error("Expected Team, got %s" % typeof(_teams))
			return

	func get_places_for_team(_team: TeamGameData.Team) -> int:
		for i: int in places.size():
			var place: TeamPlace = places[i]
			if _team in place.teams:
				return i + 1
		return -1

class GameData:

	# Jeder einzelne Spieler in diesem Minispiel
	func all_player_infos() -> Array[GameRoomManagerBase.PlayerInformation]:
		return []
	func all_game_entities() -> Array[Variant]:
		return []
	func create_result() -> MinigameResult:
		return MinigameResult.new()
	func all_player_nrs() -> Array[int]:
		var result: Array[int] = []
		for p_info: GameRoomManagerBase.PlayerInformation in all_player_infos():
			result.append(p_info.player_nr)
		return result
	
class FFAGameData:
	extends GameData
	var player_infos: Array[GameRoomManagerBase.PlayerInformation]
	
	func _init(_player_infos: Array[GameRoomManagerBase.PlayerInformation]) -> void:
		self.player_infos = _player_infos

	func all_player_infos() -> Array[GameRoomManagerBase.PlayerInformation]:
		return player_infos

	func all_game_entities() -> Array[Variant]:
		return player_infos
	func create_result() -> MinigameResult:
		return FFAResult.new(self)

class TeamGameData:
	extends GameData

	class Team:
		var players: Array[GameRoomManagerBase.PlayerInformation]
		func _init(_players: Array[GameRoomManagerBase.PlayerInformation]) -> void:
			self.players = _players
		func all_player_nrs() -> Array[int]:
			var result: Array[int] = []
			for p_info: GameRoomManagerBase.PlayerInformation in players:
				result.append(p_info.player_nr)
			return result

	var teams: Array[Team] = []

	func _init(_teams: Array[Team]) -> void:
		self.teams = _teams

	func all_player_infos() -> Array[GameRoomManagerBase.PlayerInformation]:
		var result: Array[GameRoomManagerBase.PlayerInformation] = []
		for team: Team in teams:
			result.append_array(team.players)
		return result

	func all_game_entities() -> Array[Variant]:
		return teams
	func create_result() -> MinigameResult:
		return TeamResults.new(self)


var is_team_game: bool = false
var game_data: GameData
var game_room_manager: GameRoomManagerBase
var biggame_base: BigGameBase

@export_subgroup("Cameras")
@export var cameras2d: Array[Camera2D]
@export var cameras3d: Array[Camera3D]
@export var canvas_layers: Array[CanvasLayer]
var canvas_layer_control: Array[Control]

@export_subgroup("Viewportsettings")
@export var viewport_base_size: Vector2 = Vector2(1920, 1080)

func setup(_game_room_manager: GameRoomManagerBase, _biggame_base: BigGameBase) -> void:
	self.game_room_manager = _game_room_manager
	self.biggame_base = _biggame_base

# --------------------
#    ServerMethoden
# --------------------
@rpc("any_peer", "call_remote", "reliable")
func _request_sync_server_rpc() -> void:
	if game_data is FFAGameData:
		_set_ffa_game_data_client_rpc.rpc_id(multiplayer.get_remote_sender_id(), game_data.all_player_nrs())
	elif game_data is TeamGameData:
		var team_data: TeamGameData = game_data
		_set_team_game_data_client_rpc.rpc_id(multiplayer.get_remote_sender_id(), team_data.teams[0].all_player_nrs(), team_data.teams[1].all_player_nrs())
	_on_sync()
	_after_sync_client_rpc.rpc_id(multiplayer.get_remote_sender_id())

func _on_sync() -> void:
	pass

func start_minigame() -> void:
	pass

func set_game_data(_game_data: MinigameBase.GameData) -> void: 
	self.game_data = _game_data
	self.is_team_game = _game_data is TeamGameData
	if !game_room_manager.is_online():
		_on_set_game_data(_game_data)

# --------------------
#    ClientMethoden
# --------------------
@rpc("authority", "call_remote", "reliable")
func _set_ffa_game_data_client_rpc(player_nrs: Array[int]) -> void:
	var player_infos: Array[GameRoomManagerBase.PlayerInformation] = []
	for nr: int in player_nrs:
		player_infos.append(game_room_manager.player_information[nr])
	self.game_data = FFAGameData.new(player_infos)
	_on_set_game_data(self.game_data)
	self.is_team_game = false

@rpc("authority", "call_remote", "reliable")
func _set_team_game_data_client_rpc(team_1: Array[int], team_2: Array[int]) -> void:
	var teams: Array[TeamGameData.Team] = []
	for team_nrs: Array[int] in [team_1, team_2]:
		var team_players: Array[GameRoomManagerBase.PlayerInformation] = []
		for nr: int in team_nrs:
			team_players.append(game_room_manager.player_information[nr])
		teams.append(TeamGameData.Team.new(team_players))
	self.game_data = TeamGameData.new(teams)
	_on_set_game_data(self.game_data)
	self.is_team_game = true

@rpc("authority", "call_remote", "reliable")
func _after_sync_client_rpc() -> void:
	_after_sync_client()

func _after_sync_client() -> void:
	pass


func _on_set_game_data(_game_data: GameData) -> void:
	pass
	
func replace_canvas_layer() -> void:
	for canvas_layer: CanvasLayer in canvas_layers:
		var parent: Node = canvas_layer.get_parent()
		var index: int = canvas_layer.get_index()

		# Neues Control erzeugen
		var control: Control = Control.new()
		control.name = canvas_layer.name

		# Optional: Standard-HUD-Setup
		control.set_anchors_preset(Control.PRESET_FULL_RECT)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL

		# Control an gleicher Stelle einfügen
		parent.add_child(control)
		parent.move_child(control, index)

		# Kinder verschieben
		var children: Array[Node] = canvas_layer.get_children()
		for child: Node in children:
			canvas_layer.remove_child(child)
			control.add_child(child)

		# CanvasLayer entfernen
		canvas_layer.queue_free()
		canvas_layer_control.append(control)

func start_instruction_preview_minigame() -> void:
	pass

func on_viewport_resized(_new_size: Vector2) -> void:
	_update_3d_cameras(_new_size)
	if cameras2d.is_empty():
		return
	var scale: float = min(_new_size.x / viewport_base_size.x ,_new_size.y / viewport_base_size.y)

	for cam: Camera2D in cameras2d:
		cam.zoom.x = scale
		cam.zoom.y = scale

	for control: Control in canvas_layer_control:
		control.size = _new_size / scale
		control.position = _new_size / scale / -2

func _update_3d_cameras(new_size: Vector2) -> void:
	if cameras3d.is_empty():
		return

	var base_aspect: float = viewport_base_size.x / viewport_base_size.y
	var base_fov: float = 70.0
	var aspect: float = new_size.x / new_size.y
	var fov: float = base_fov

	if aspect > base_aspect:
		fov = rad_to_deg(
			2.0 * atan(
				tan(deg_to_rad(base_fov * 0.5)) * aspect / base_aspect
			)
		)

	for cam: Camera3D in cameras3d:
		cam.fov = fov

func pause() -> void:
	pass

func resume() -> void:
	pass
