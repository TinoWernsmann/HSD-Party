extends Node
class_name MinigameInstruction

@export_subgroup("Scenes")
@export var player_icon_scene: PackedScene
@export var control_item: PackedScene

@export_subgroup("UI Refs")
@export  var titel: Label
@export var description: Label
@export var sub_viewport_container: SubViewportContainer
@export var dummy_game_viewport: SubViewport
@export var thumbnail: TextureRect
@export var player_ready_container_team_1: HBoxContainer
@export var player_ready_container_team_2: HBoxContainer
@export var control_container: VBoxContainer
@export var ready_icon: ControlIcon

var minigame_info: MinigameInfo

var game_data: MinigameBase.GameData
var player_is_ready: Array[bool]

var player_info_controller: Array[MinigameInstructionPlayerInfoController]
var dummy_minigame: MinigameBase
var biggame_base: BigGameBase

var game_room_manager: GameRoomManagerBase

func setup(_minigame_info: MinigameInfo, _game_room_manager: GameRoomManagerBase, _biggame_base: BigGameBase) -> void: 
	self.minigame_info = _minigame_info
	self.game_room_manager = _game_room_manager
	self.biggame_base = _biggame_base

func set_game_data(_game_data: MinigameBase.GameData) -> void: 
	self.game_data = _game_data
	self.player_is_ready = []
	for x: GameRoomManagerBase.PlayerInformation in game_data.all_player_infos():
		if x is GameRoomManagerBase.AIPlayerInformation:
			player_is_ready.append(true)
		else:
			player_is_ready.append(false)

func _ready() -> void:
	dummy_game_viewport.size_changed.connect(_on_subviewport_size_changed)
	if game_room_manager.is_online() && !multiplayer.is_server():
		_request_sync_server_rpc.rpc_id(1)
	else:
		_after_sync_rpc()
	
func _process(_delta: float) -> void:
	if game_data == null:
		return
	for i: int in game_data.all_player_infos().size():
		if game_data.all_player_infos()[i] is GameRoomManagerBase.ThisClientPlayerInformation:	
			if game_room_manager.input_is_pressed(game_data.all_player_infos()[i].player_nr , ControllerDefinition.Buttons.GAMELESS_INTERACT):
				if not player_is_ready[i]:
					if game_room_manager.is_online():
						_set_player_ready_server_rpc.rpc_id(1, game_data.all_player_infos()[i].player_nr)
					else:
						_set_player_ready_server_rpc(game_data.all_player_infos()[i].player_nr)
	
# --------------------
#    ServerMethoden
# --------------------
@rpc("any_peer", "call_remote", "reliable")
func _request_sync_server_rpc() -> void:
	# Sync game data
	if game_data is MinigameBase.FFAGameData:
		_set_ffa_game_data_client_rpc.rpc_id(multiplayer.get_remote_sender_id(), game_data.all_player_nrs())
	elif game_data is MinigameBase.TeamGameData:
		var team_data: MinigameBase.TeamGameData = game_data
		_set_team_game_data_client_rpc.rpc_id(multiplayer.get_remote_sender_id(), team_data.teams[0].all_player_nrs(), team_data.teams[1].all_player_nrs())
	_set_settings_client_rpc.rpc_id(multiplayer.get_remote_sender_id(), player_is_ready)
	_after_sync_rpc.rpc_id(multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func _set_player_ready_server_rpc(player_nr: int) -> void:
	print("Player ", player_nr, " is ready")
	player_is_ready[player_nr] = true
	if check_all_ready():
		biggame_base.minigame_instruction_ready(game_data)
	
	if game_room_manager.is_online():
		game_room_manager.call_all_peers_in_gameroom(
			func (peer_id: int) -> void:
				_set_settings_client_rpc.rpc_id(peer_id, player_is_ready)	
		)
	else:
		_set_settings_client_rpc(player_is_ready)

# --------------------
#    ClientMethoden
# --------------------
@rpc("authority", "call_remote", "reliable")
func _set_settings_client_rpc(ready_player: Array[bool]) -> void:
	print("Set Player Ready State: ", ready_player)
	player_is_ready = ready_player
	for i: int in player_is_ready.size():
		if player_is_ready[i] && player_info_controller.size() > i:
			player_info_controller[i].set_ready(true)

@rpc("authority", "call_remote", "reliable")
func _set_ffa_game_data_client_rpc(player_nrs: Array[int]) -> void:
	var player_infos: Array[GameRoomManagerBase.PlayerInformation] = []
	for nr: int in player_nrs:
		player_infos.append(game_room_manager.player_information[nr])
	self.game_data = MinigameBase.FFAGameData.new(player_infos)

@rpc("authority", "call_remote", "reliable")
func _set_team_game_data_client_rpc(team_1: Array[int], team_2: Array[int]) -> void:
	var teams: Array[MinigameBase.TeamGameData.Team] = []
	for team_nrs: Array[int] in [team_1, team_2]:
		var team_players: Array[GameRoomManagerBase.PlayerInformation] = []
		for nr: int in team_nrs:
			team_players.append(game_room_manager.player_information[nr])
		teams.append(MinigameBase.TeamGameData.Team.new(team_players))
	self.game_data = MinigameBase.TeamGameData.new(teams)

@rpc("authority", "call_remote", "reliable")
func _after_sync_rpc() -> void:
	#Icons setzuen
	ready_icon.set_controller_ids_from_player_information(game_data.all_player_infos())
	ready_icon.show_button(ControllerDefinition.Buttons.GAMELESS_INTERACT)

	if minigame_info.instruction_playing:
		thumbnail.visible = false
		sub_viewport_container.visible = true
		dummy_minigame = minigame_info.level.instantiate()
		dummy_minigame.setup(game_room_manager, biggame_base)
		dummy_minigame.replace_canvas_layer()

		if game_room_manager.multiplayer.is_server() || !game_room_manager.is_online():
			dummy_minigame.set_game_data(game_data)
		dummy_game_viewport.add_child(dummy_minigame)
		if game_room_manager.multiplayer.is_server() || !game_room_manager.is_online():
			dummy_minigame.start_instruction_preview_minigame()
	else:
		thumbnail.visible = true
		thumbnail.texture = minigame_info.icon
		sub_viewport_container.visible = false
		titel.text = minigame_info.name
	description.text = minigame_info.game_description

	_create_player_ready_info_from_game_data()

	for x: ControlInfo in minigame_info.control_info:
		var control_item_instance: MinigameInstructionInputDescriptionController = control_item.instantiate()
		control_item_instance.setup(x, game_data.all_player_infos())
		control_container.add_child(control_item_instance)
			
	if check_all_ready():
		biggame_base.minigame_instruction_ready(game_data)
	
func check_all_ready() -> bool:
	return not player_is_ready.has(false)

func _create_player_ready_info_from_game_data() -> void:
	if game_data is MinigameBase.TeamGameData:
		_create_player_ready_info((game_data as MinigameBase.TeamGameData).teams[0].players, player_ready_container_team_1)
		_create_player_ready_info((game_data as MinigameBase.TeamGameData).teams[1].players, player_ready_container_team_2)
	else:
		_create_player_ready_info(game_data.all_player_infos(), player_ready_container_team_2)

func _create_player_ready_info(player_info:  Array[GameRoomManagerBase.PlayerInformation], container: HBoxContainer) -> void:
	var i: int = 0
	for p_info: GameRoomManagerBase.PlayerInformation in player_info:
		var player_icon_instance: MinigameInstructionPlayerInfoController = player_icon_scene.instantiate()
		player_icon_instance.setup(p_info.character_id)
		container.add_child(player_icon_instance)
		player_info_controller.append(player_icon_instance)
		if player_is_ready[i]:
			player_info_controller[i].set_ready(true)
		i += 1


func _on_subviewport_size_changed() -> void:
	if dummy_minigame != null:
		dummy_minigame.on_viewport_resized(sub_viewport_container.size)

func pause() -> void:
	if dummy_minigame != null:
		dummy_minigame.pause()

func resume() -> void:
	if dummy_minigame != null:
		dummy_minigame.resume()
