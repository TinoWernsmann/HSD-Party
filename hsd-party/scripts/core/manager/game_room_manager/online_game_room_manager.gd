extends GameRoomManagerBase
class_name OnlineGameRoomManager

# Client

# Server
var client_peer_ids: Array[int] = []

# Client und Server
var game_room_id: String
var host_id: int

# Parent Refs
var online_main_manager: OnlineMainManager

func setup(_main_manager: MainManager) -> void:
	if _main_manager is OnlineMainManager:
		self.online_main_manager = _main_manager
	if online_main_manager.is_server:
		state = GameSelectionState.new()
	super.setup(_main_manager)

func _ready() -> void:
	super._ready()
	game_room_menu_controller.back.visible = false
	if !multiplayer.is_server():
		_sync.rpc_id(1)

# --------------------
#    ServerMethoden
# --------------------
func client_joins_room(new_client_peer_id: int) -> void:
	if not online_main_manager.is_server:
		return
	client_peer_ids.append(new_client_peer_id)
	#Erster Spieler im Raum wird Host
	if client_peer_ids.size() == 1:
		host_id = new_client_peer_id
	
func client_leaves_room(leaving_client_peer_id: int) -> void:
	if not online_main_manager.is_server:
		return
	
	client_peer_ids.erase(leaving_client_peer_id)

	# Host neu bestimmen, falls Host gegangen ist
	if leaving_client_peer_id == host_id:
		if client_peer_ids.size() == 0:
			_cleanup_room()
		else:
			host_id = client_peer_ids[0]
			call_all_peers_in_gameroom(
				func(peer_id: int) -> void: 
					_sync_online_information(peer_id)

			)
	
	for x: PlayerInformation in player_information:
		if x is OnlineClientPlayerInformation:
			var online_info: OnlineClientPlayerInformation = x
			if online_info.peer_id == leaving_client_peer_id:
				player_information[online_info.player_nr] = null
				_set_null_player_data(online_info.player_nr)
				call_all_peers_in_gameroom(
					func(peer_id: int) -> void: 
						_set_null_player_data.rpc_id(peer_id, online_info.player_nr) 
				)

func _cleanup_room() -> void:
	online_main_manager.remove_room(game_room_id)

@rpc("any_peer", "call_remote", "reliable")
func _sync() -> void:
	_sync_online_information(multiplayer.get_remote_sender_id())
	_sync_player_information(multiplayer.get_remote_sender_id())
	_sync_state(multiplayer.get_remote_sender_id())

func _sync_state(client_peer_id: int) -> void:
	if state is GameSelectionState:
		_set_state_selection_rpc.rpc_id(client_peer_id)
		return
	if state is GameState:
		var game_state: GameState = state
		_set_state_game_rpc.rpc_id(client_peer_id, game_state.biggame_id, game_state.paused)
		return
	if state is GameSelectionSettingsState:
		var selection_state: GameSelectionSettingsState = state
		_set_state_minigame_settings_rpc.rpc_id(client_peer_id, selection_state.biggame_id)
		return

func _sync_player_information(client_peer_id: int) -> void:
	for x: PlayerInformation in player_information:
		if x is OnlineClientPlayerInformation:
			var online_info: OnlineClientPlayerInformation = x
			_set_client_player_data.rpc_id(client_peer_id ,online_info.player_nr, online_info.peer_id, online_info.character_id)
		elif x is AIPlayerInformation: 
			var ai_info: AIPlayerInformation = x
			_set_ai_player_data.rpc_id(client_peer_id , ai_info.player_nr, ai_info.difficulty, ai_info.character_id)

func _sync_online_information(client_peer_id: int) -> void:
	_sync_room_online_state_to_client_rpc.rpc_id(client_peer_id, game_room_id, host_id)

@rpc("any_peer", "call_remote", "reliable")
func _select_biggame_server_rpc(_biggame_id: int) -> void:
	if is_host():
		state = GameSelectionSettingsState.new(_biggame_id)
		biggame_settings = BiggameManager.get_biggame_by(_biggame_id).settings.instantiate()
		biggame_settings.setup(self, _biggame_id)
		game_room_menu_controller.show_biggame_settings(biggame_settings)
		call_all_peers_in_gameroom(
			func(_peer_id: int) -> void: 
				_set_state_minigame_settings_rpc.rpc_id(_peer_id, _biggame_id)
		)

@rpc("any_peer", "call_remote", "reliable")
func _back_server_rpc() -> void:
	if is_host():
		if state is GameSelectionSettingsState:
			state = GameSelectionState.new()
			call_all_peers_in_gameroom(
				func(peer_id: int) -> void: 
					_set_state_selection_rpc.rpc_id(peer_id)
			)

@rpc("any_peer", "call_remote", "reliable")
func _player_settings_change_character_server_rpc(player_nr: int, change: int) -> void:
	if player_information[player_nr] is OnlineClientPlayerInformation:
		var online_info: OnlineClientPlayerInformation = player_information[player_nr]
		if online_info.peer_id == multiplayer.get_remote_sender_id():
			online_info.character_id = posmod((online_info.character_id + change), CharacterManager.get_amount_of_available_character())
			call_all_peers_in_gameroom(
				func(peer_id: int) -> void: 
					_set_client_player_data.rpc_id(peer_id, player_nr, online_info.peer_id, online_info.character_id)
			)	
	elif player_information[player_nr] is AIPlayerInformation:
		var ai_info: AIPlayerInformation = player_information[player_nr]
		if is_host():
			ai_info.character_id = posmod((ai_info.character_id + change), CharacterManager.get_amount_of_available_character())
			call_all_peers_in_gameroom(
				func(peer_id: int) -> void: 
					_set_ai_player_data.rpc_id(peer_id, player_nr, ai_info.difficulty, ai_info.character_id)
			)

@rpc("any_peer", "call_remote", "reliable")
func _player_settings_change_client_server_rpc(player_nr: int, change: int) -> void:
	if is_host():
			var current_value: int
			if player_information[player_nr] == null:
				current_value = 0
			elif player_information[player_nr] is AIPlayerInformation:
				current_value = 1
			elif player_information[player_nr] is OnlineClientPlayerInformation:
				var online_client: OnlineClientPlayerInformation = player_information[player_nr] as OnlineClientPlayerInformation
				current_value = 2 + client_peer_ids.find(online_client.peer_id)
			current_value = posmod(current_value + change,2 + client_peer_ids.size())
			if current_value == 0:
				player_information[player_nr] = null
				call_all_peers_in_gameroom(
					func(peer_id: int) -> void: 
						_set_null_player_data.rpc_id(peer_id, player_nr)
				)
			elif current_value == 1:
				player_information[player_nr] = AIPlayerInformation.create_from_last(player_information[player_nr],player_nr)
				call_all_peers_in_gameroom(
					func(peer_id: int) -> void: 
						_set_ai_player_data.rpc_id(peer_id, player_nr,0,player_information[player_nr].character_id)
				)
			elif current_value >= 2:
				var online_client: OnlineClientPlayerInformation = OnlineClientPlayerInformation.create_from_last(player_information[player_nr],player_nr)
				online_client.peer_id = client_peer_ids[current_value-2]
				player_information[player_nr] = online_client
				call_all_peers_in_gameroom(
					func(peer_id: int) -> void: 
						_set_client_player_data.rpc_id(peer_id, player_nr,online_client.peer_id,online_client.character_id)
				)

@rpc("any_peer", "call_remote", "reliable")
func _player_settings_change_difficulty_server_rpc(player_nr: int, change: int) -> void:
	if is_host():
		if player_information[player_nr] is AIPlayerInformation:
			var ai_info: AIPlayerInformation = player_information[player_nr] 
			ai_info.difficulty = posmod(ai_info.difficulty + change, 3 ) as AIPlayerInformation.AIDifficulty
			call_all_peers_in_gameroom(
					func(peer_id: int) -> void: 
						_set_ai_player_data.rpc_id(peer_id, player_nr,ai_info.difficulty,ai_info.character_id)
			)

@rpc("any_peer", "call_remote", "reliable")
func _pause_server_rpc(_player_nr: int) -> void:
	if state is GameState:
		var game_state: GameState = state
		game_state.paused = true
		biggame.pause()
		call_all_peers_in_gameroom(
			func (peer_id: int) -> void:
				_set_state_game_rpc.rpc_id(peer_id, game_state.biggame_id, true)
		)

@rpc("any_peer", "call_remote", "reliable")
func _resume_server_rpc(_player_nr: int) -> void:
	if state is GameState:
		var game_state: GameState = state
		game_state.paused = false
		biggame.resume()
		call_all_peers_in_gameroom(
			func (peer_id: int) -> void:
				_set_state_game_rpc.rpc_id(peer_id, game_state.biggame_id, false)
		)

func finish_biggame_settings(biggame_id: int, _biggame_settings: BiggameManager.BiggameSettings) -> void:
	var filter: BiggameManager.PlayerInfoFilter = BiggameManager.PlayerInfoFilter.new(player_information)
	var biggame_info: BiggameInfo = BiggameManager.get_biggame_by(biggame_id)
	if filter.is_allowed(biggame_info):
		state = GameState.new(biggame_id)
		biggame = BiggameManager.get_biggame_by(biggame_id).level.instantiate()
		var final_player_infos: Array[GameRoomManagerBase.PlayerInformation] = []
		for p_info: GameRoomManagerBase.PlayerInformation in player_information:
			if p_info != null:
				final_player_infos.append(p_info)
		biggame.setup(biggame_id, self, final_player_infos)
		add_child(biggame,true)
		biggame.set_settings(_biggame_settings)
		call_all_peers_in_gameroom(
			func (peer_id: int) -> void:
				_set_state_game_rpc.rpc_id(peer_id, biggame_id, false)
		)
		biggame.start()
	else:
		var message: String = filter.error_message(biggame_info)
		call_all_peers_in_gameroom(
			func (peer_id: int) -> void:
				InfoPanel.add_message_rpc(peer_id, message)
		)

@rpc("any_peer", "call_remote", "reliable")
func biggame_done() -> void:
	# Biggame beenden
	state = GameSelectionState.new()
	biggame.queue_free()

	call_all_peers_in_gameroom(
		func(peer_id: int) -> void:
			_set_state_selection_rpc.rpc_id(peer_id)
	)

# --------------------
#    ClientMethode
# --------------------

# OnlineInfo

@rpc("authority", "call_remote", "reliable")
func _sync_room_online_state_to_client_rpc(_game_room_id: String, _host_id: int) -> void:
	online_main_manager.mprint("online sync")
	self.game_room_id = _game_room_id
	self.host_id = _host_id
	var host_label: String = str(host_id) + (" (You)" if is_host() else "")
	game_room_menu_controller.show_online_info(game_room_id, host_label)

# State

@rpc("authority", "call_remote", "reliable")
func _set_state_selection_rpc() -> void:
	# State Update
	state = GameSelectionState.new()

	# GameRoom UI Update
	game_room_menu_controller.show_biggame_selection()
	game_room_menu_controller.visible = true
	game_room_menu_controller.back.visible = false
	biggame_settings = null
	pause_menu_controller.visible = false


	# Biggame Update
	if biggame != null :
		biggame.queue_free()
		biggame = null

@rpc("authority", "call_remote", "reliable")
func _set_state_game_rpc(biggame_id: int, paused: bool) -> void:
	# State Update
	var game_state: GameState = GameState.new(biggame_id)
	game_state.paused = paused
	state = game_state
	
	# GameRoom UI Update
	game_room_menu_controller.visible = false
	biggame_settings = null
	pause_menu_controller.visible = paused

	# Biggame Update
	if biggame == null || biggame.biggame_id != biggame_id:
		if biggame != null :
			biggame.queue_free()
		biggame = BiggameManager.get_biggame_by(biggame_id).level.instantiate()
		var final_player_infos: Array[GameRoomManagerBase.PlayerInformation] = []
		for p_info: GameRoomManagerBase.PlayerInformation in player_information:
			if p_info != null:
				final_player_infos.append(p_info)
		biggame.setup(biggame_id,self, final_player_infos)
		add_child(biggame, true)
	if paused:
		biggame.pause()
	else:
		biggame.resume()

@rpc("authority", "call_remote", "reliable")
func _set_state_minigame_settings_rpc(biggame_id: int) -> void:
	# State Update
	state = GameSelectionSettingsState.new(biggame_id)

	# GameRoom UI Update
	game_room_menu_controller.visible = true
	game_room_menu_controller.back.visible = true
	if biggame_settings == null || biggame_settings.biggame_id != biggame_id:
		biggame_settings = BiggameManager.get_biggame_by(biggame_id).settings.instantiate()
		biggame_settings.setup(self, biggame_id)
	game_room_menu_controller.show_biggame_settings(biggame_settings)
	pause_menu_controller.visible = false

	# Biggame Update
	if biggame != null :
		biggame.queue_free()
		biggame = null


# PlayerInfo

@rpc("authority", "call_remote", "reliable")
func _set_client_player_data(player_nr: int, client_peer_id: int, character_id: int) -> void:
	if client_peer_id == multiplayer.get_unique_id():
		var this_client: ThisClientPlayerInformation = ThisClientPlayerInformation.new()
		this_client.character_id = character_id
		this_client.player_nr = player_nr
		this_client.controller_id = 0
		player_information[player_nr] = this_client
	else:
		var online_client: OnlineClientPlayerInformation = OnlineClientPlayerInformation.new()
		online_client.character_id = character_id
		online_client.peer_id = client_peer_id
		online_client.player_nr = player_nr
		player_information[player_nr] = online_client
	game_room_menu_controller.update_player_settings(player_information[player_nr],player_nr)
	game_room_menu_controller.update_player_info(player_nr, player_information[player_nr])

@rpc("authority", "call_remote", "reliable")
func _set_ai_player_data(player_nr: int, difficulty: int, character_id: int) -> void:
	var ai_client: AIPlayerInformation = AIPlayerInformation.new()
	ai_client.character_id = character_id
	ai_client.player_nr = player_nr
	ai_client.difficulty = difficulty as AIPlayerInformation.AIDifficulty
	player_information[player_nr] = ai_client
	game_room_menu_controller.update_player_settings(player_information[player_nr],player_nr)
	game_room_menu_controller.update_player_info(player_nr, player_information[player_nr])

@rpc("authority", "call_remote", "reliable")
func _set_null_player_data(player_nr: int) -> void:
	player_information[player_nr] = null
	game_room_menu_controller.update_player_settings(player_information[player_nr],player_nr)
	game_room_menu_controller.update_player_info(player_nr, player_information[player_nr])

# Nutzereingaben

func dissconnect() -> void:
	quit_gameroom()

func back() -> void:
	if is_host():
		_back_server_rpc.rpc_id(1)
	else:
		InfoPanel.add_message("Diese Funktion kann nur vom Host durchgeführt werden.")

func quit_gameroom() -> void:
	online_main_manager.leave_room()

func select_biggame(_biggame_id: int) -> void:
	if is_host():
		_select_biggame_server_rpc.rpc_id(1,_biggame_id)
	else:
		InfoPanel.add_message("Diese Funktion kann nur vom Host durchgeführt werden.")

func pause_pressed(player_nr: int) -> void:
	_pause_server_rpc.rpc_id(1, player_nr)

func pause_resume_pressed(player_nr: int) -> void:
	_resume_server_rpc.rpc_id(1, player_nr)

func leave_game_pressed() -> void:
	biggame_done.rpc_id(1)

func open_player_information(player_nr: int) -> void:
	game_room_menu_controller.show_player_info_edit(player_information[player_nr], player_nr)

func player_settings_change_character(player_nr: int, change: int) -> void:
	if player_information[player_nr] is ThisClientPlayerInformation:
		_player_settings_change_character_server_rpc.rpc_id(1, player_nr, change)
	elif player_information[player_nr] is OnlineClientPlayerInformation:
		var online_info: OnlineClientPlayerInformation = player_information[player_nr]
		InfoPanel.add_message("Diese Funktion kann nur vom Client %d durchgeführt werden." % online_info.peer_id)
	elif player_information[player_nr] is AIPlayerInformation:
		if is_host():
			_player_settings_change_character_server_rpc.rpc_id(1, player_nr, change)
		else:
			InfoPanel.add_message("Diese Funktion kann nur vom Host durchgeführt werden.")
	
func player_settings_change_control(player_nr: int, _change: int) -> void:
	if player_information[player_nr] is ThisClientPlayerInformation:
		var this_info: ThisClientPlayerInformation = player_information[player_nr] 
		this_info.controller_id = posmod((this_info.controller_id + _change), ControllerManager.get_amount_of_available_controller())
		game_room_menu_controller.show_player_info_edit(this_info,player_nr)
		game_room_menu_controller.update_player_info(player_nr, this_info)
	
func player_settings_change_client(player_nr: int, change: int) -> void:
	if is_host():
		_player_settings_change_client_server_rpc.rpc_id(1,player_nr, change)
	else:
		InfoPanel.add_message("Diese Funktion kann nur vom Host durchgeführt werden.")

func player_settings_change_difficulty(player_nr: int, change: int) -> void:
	if is_host():
		_player_settings_change_difficulty_server_rpc.rpc_id(1,player_nr, change)
	else:
		InfoPanel.add_message("Diese Funktion kann nur vom Host durchgeführt werden.")
	
func player_settings_done() -> void:
	game_room_menu_controller.hide_player_info_edit()

# --------------------
#    Hilfsmethoden
# --------------------

func is_host() -> bool:
	if multiplayer.is_server():
		return multiplayer.get_remote_sender_id() == host_id
	return multiplayer.get_unique_id() == host_id

# Sendet an alle Peers, außer dem, welcher die aktuelle Methode auf dem Server aufgerufen hat.
func call_all_other_peers_in_gameroom(callable: Callable) -> void:
	for peer_id: int in client_peer_ids:
		if peer_id != multiplayer.get_remote_sender_id():
			callable.call(peer_id)

# Sendet an alle Peers
func call_all_peers_in_gameroom(callable: Callable) -> void:
	for peer_id: int in client_peer_ids:
		callable.call(peer_id)

func _biggame_infos() -> Array[BiggameInfo]:
	return BiggameManager.filterd_biggames(BiggameManager.OnlineSupportFilter.new())

func minigame_infos() -> Array[MinigameInfo]:
	return MinigameManager.filterd_minigames(MinigameManager.OnlineSupportFilter.new())

func is_online() -> bool:
	return true
