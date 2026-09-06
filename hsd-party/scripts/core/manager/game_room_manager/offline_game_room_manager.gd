extends GameRoomManagerBase
class_name OfflineGameRoomManager

# --------------------
#    Hilfsmethoden
# --------------------

func _biggame_infos() -> Array[BiggameInfo]:
	return BiggameManager.filterd_biggames()

func minigame_infos() -> Array[MinigameInfo]:
	return MinigameManager.filterd_minigames()

# --------------------
#    öffentliche Methoden
# --------------------

func select_biggame(_biggame_id: int) -> void:
	state = GameSelectionSettingsState.new(_biggame_id)
	biggame_settings = BiggameManager.get_biggame_by(_biggame_id).settings.instantiate()
	biggame_settings.setup(self,_biggame_id)
	game_room_menu_controller.show_biggame_settings(biggame_settings)
	game_room_menu_controller.back.visible = true

func back() -> void:
	if state is GameSelectionSettingsState:
		game_room_menu_controller.show_biggame_selection()
		state = GameSelectionState.new()
	else:
		main_manager.quit_gameroom()

func finish_biggame_settings(_biggame_id: int, _biggame_settings: BiggameManager.BiggameSettings) -> void:
	var filter: BiggameManager.PlayerInfoFilter = BiggameManager.PlayerInfoFilter.new(player_information)
	var biggame_info: BiggameInfo = BiggameManager.get_biggame_by(_biggame_id)
	if filter.is_allowed(biggame_info):

		state = GameState.new(_biggame_id)
		biggame = BiggameManager.get_biggame_by(_biggame_id).level.instantiate()
		var final_player_infos: Array[GameRoomManagerBase.PlayerInformation] = []
		for p_info: GameRoomManagerBase.PlayerInformation in player_information:
			if p_info != null:
				final_player_infos.append(p_info)
		biggame.setup(_biggame_id, self, final_player_infos)
		add_child(biggame)

		biggame.set_settings(_biggame_settings)
		game_room_menu_controller.visible = false
		biggame.start()
	else:
		InfoPanel.add_message(filter.error_message(biggame_info))

func open_player_information(player_nr: int) -> void:
		game_room_menu_controller.show_player_info_edit(player_information[player_nr], player_nr)


func player_settings_change_character(_player_nr: int, _change: int) -> void: 
	player_information[_player_nr].character_id = posmod((player_information[_player_nr].character_id + _change), CharacterManager.get_amount_of_available_character())
	game_room_menu_controller.show_player_info_edit(player_information[_player_nr],_player_nr)
	game_room_menu_controller.update_player_info(_player_nr, player_information[_player_nr])
	
func player_settings_change_control(_player_nr: int, _change: int) -> void:
	if player_information[_player_nr] is ThisClientPlayerInformation:
		var _player_information: ThisClientPlayerInformation = player_information[_player_nr] 
		_player_information.controller_id = posmod((_player_information.controller_id + _change), ControllerManager.get_amount_of_available_controller())
	game_room_menu_controller.show_player_info_edit(player_information[_player_nr],_player_nr)
	game_room_menu_controller.update_player_info(_player_nr, player_information[_player_nr])
	
func player_settings_change_client(_player_nr: int, _change: int) -> void:
	var current_value: int
	if player_information[_player_nr] == null:
		current_value = 0
	if player_information[_player_nr] is ThisClientPlayerInformation:
		current_value = 1
	if player_information[_player_nr] is AIPlayerInformation:
		current_value = 2
	current_value = posmod(current_value + _change,3)
	if current_value == 0:
		player_information[_player_nr] = null
	if current_value == 1:
		player_information[_player_nr] = ThisClientPlayerInformation.create_from_last(player_information[_player_nr],_player_nr)
	if current_value == 2:
		player_information[_player_nr] = AIPlayerInformation.create_from_last(player_information[_player_nr],_player_nr)
	game_room_menu_controller.show_player_info_edit(player_information[_player_nr],_player_nr)
	game_room_menu_controller.update_player_info(_player_nr, player_information[_player_nr])

func player_settings_change_difficulty(_player_nr: int, _change: int) -> void:
	if player_information[_player_nr] is AIPlayerInformation:
		var _player_information: AIPlayerInformation = player_information[_player_nr] 
		_player_information.difficulty = posmod(_player_information.difficulty + _change, 3 ) as AIPlayerInformation.AIDifficulty
	game_room_menu_controller.show_player_info_edit(player_information[_player_nr],_player_nr)
	game_room_menu_controller.update_player_info(_player_nr, player_information[_player_nr])
	
func  player_settings_done() -> void:
	game_room_menu_controller.hide_player_info_edit()

func biggame_done() -> void:
	# Biggame beenden
	state = GameSelectionState.new()
	biggame.queue_free()

	# Menü laden
	game_room_menu_controller.visible = true
	game_room_menu_controller.show_biggame_selection()

func pause_pressed(_player_nr: int) -> void:
	(state as GameState).paused = true
	biggame.pause()
	pause_menu_controller.visible = true

func pause_resume_pressed(_player_nr: int) -> void:
	(state as GameState).paused = false
	biggame.resume()
	pause_menu_controller.visible = false

func leave_game_pressed() -> void:
	# Biggame beenden
	state = GameSelectionState.new()
	pause_menu_controller.visible = false
	if !biggame.is_queued_for_deletion():
		biggame.queue_free()
	# Menü laden
	game_room_menu_controller.visible = true
	game_room_menu_controller.show_biggame_selection()
