extends BiggameSettingsController
class_name BiggameSettingsMinigame

class TeamVariation:
	var team_1: Array # Eigentlich Array[int], aber Godot ist halt scheiße, was den Umgang mit Arrays und Types angeht.
	var team_2: Array

	func label() -> String:
		var t1_names: Array = team_1.map(func(number: int) -> String: return str(number + 1))
		var t2_names: Array = team_2.map(func(number: int) -> String: return str(number + 1))
		
		return "%s vs %s" % [", ".join(t1_names), ", ".join(t2_names)]

const MINIGAME_SELECTION_ITEM: PackedScene = preload("res://scenes/object/core/ui_elements/minigame_selection_item.tscn")

#State
var selected_minigame_id: int = 0
var selected_minigame_type: int = 0
var selected_team_variations: int = 0

@export var minigame_items_container: HBoxContainer
@export var description: Label
@export var start: Button
@export var type_dropdown: OptionButton
@export var variation_dropdown: OptionButton
@export var variation_label: Label

var all_minigame_types: Array[MinigameInfo.MinigameTypes] = []
var team_variations: Array[TeamVariation]

func _ready() -> void:
	_add_types()
	_show_minigame_list()
	description.text = 	MinigameManager.get_minigame_by(selected_minigame_id).game_description
	if game_room_manager.is_online() && !multiplayer.is_server():
		_request_sync_server_rpc.rpc_id(1)

# --------------------
#    ServerMethoden
# --------------------
@rpc("any_peer", "call_remote", "reliable")
func _request_sync_server_rpc() -> void:
	_set_settings_client_rpc.rpc_id(multiplayer.get_remote_sender_id(), selected_minigame_id, selected_minigame_type, selected_team_variations)

@rpc("any_peer", "call_remote", "reliable")
func _select_minigame_server_rpc(_selected_minigame_id: int) -> void:
	if game_room_manager.is_host():
		self.selected_minigame_id = _selected_minigame_id
		game_room_manager.call_all_peers_in_gameroom(
			func(peer_id: int) -> void:
				_set_settings_client_rpc.rpc_id(peer_id, _selected_minigame_id, selected_minigame_type, selected_team_variations)
		)

@rpc("any_peer", "call_remote", "reliable")
func _start_server_rpc() -> void:
	if game_room_manager.is_host():
		var filter: MinigameManager.PlayerInfoFilter = MinigameManager.PlayerInfoFilter.new(game_room_manager.player_information)
		var minigame_info: MinigameInfo = MinigameManager.get_minigame_by(selected_minigame_id)
		var game_data: MinigameBase.GameData
		# Prüfen, ob es mit AI und Spieleranzahl passt
		if filter.is_allowed(minigame_info):
			var has_error: bool = false
			if all_minigame_types[selected_minigame_type] == MinigameInfo.MinigameTypes.FFA:
				game_data = MinigameBase.FFAGameData.new(game_room_manager.get_actual_player_info())
			else:
				var player_team_1: Array[GameRoomManagerBase.PlayerInformation]
				var player_team_2: Array[GameRoomManagerBase.PlayerInformation]
				_show_variation()
				for i: int in team_variations[selected_team_variations].team_1:
					if game_room_manager.player_information[i] == null:
						has_error = true
						var message: String = "Spieler " + str(i+1) + " ist nicht zugewiesen."
						if game_room_manager.is_online():
							InfoPanel.add_message_rpc(multiplayer.get_remote_sender_id(), message)
						else:
							InfoPanel.add_message(message)
					player_team_1.append(game_room_manager.player_information[i])
				for i: int in team_variations[selected_team_variations].team_2:
					if game_room_manager.player_information[i] == null:
						has_error = true
						var message: String = "Spieler " + str(i+1) + " ist nicht zugewiesen."
						if game_room_manager.is_online():
							InfoPanel.add_message_rpc(multiplayer.get_remote_sender_id(), message)
						else:
							InfoPanel.add_message("Spieler " + str(i+1) + " ist nicht zugewiesen.")
					player_team_2.append(game_room_manager.player_information[i])
				game_data = MinigameBase.TeamGameData.new([MinigameBase.TeamGameData.Team.new(player_team_1), MinigameBase.TeamGameData.Team.new(player_team_2)])
			if not has_error:
				game_room_manager.finish_biggame_settings(biggame_id, BiggameMinigame.BiggameMinigameSettings.new(selected_minigame_id, game_data))
		else:
			if game_room_manager.is_online():
				InfoPanel.add_message_rpc(multiplayer.get_remote_sender_id(), filter.error_message(minigame_info))
			else:
				InfoPanel.add_message(filter.error_message(minigame_info))

@rpc("any_peer", "call_remote", "reliable")
func _select_type_server_rpc(_selected_minigame_type: int) -> void:
	if game_room_manager.is_host():
		self.selected_minigame_type = _selected_minigame_type
		game_room_manager.call_all_peers_in_gameroom(
			func(peer_id: int) -> void:
				_set_settings_client_rpc.rpc_id(peer_id, selected_minigame_id, _selected_minigame_type, selected_team_variations)
		)

@rpc("any_peer", "call_remote", "reliable")
func _select_variations_server_rpc(_selected_team_variations: int) -> void:
	if game_room_manager.is_host():
		self.selected_team_variations = _selected_team_variations
		game_room_manager.call_all_peers_in_gameroom(
			func(peer_id: int) -> void:
				_set_settings_client_rpc.rpc_id(peer_id, selected_minigame_id, selected_minigame_type, _selected_team_variations)
		)

# --------------------
#    ClientMethoden
# --------------------
@rpc("authority", "call_remote", "reliable")
func _set_settings_client_rpc(_selected_minigame_id: int, _selected_minigame_type: int, _selected_team_variations: int) -> void:
	self.selected_minigame_id = _selected_minigame_id
	self.selected_minigame_type = _selected_minigame_type
	self.selected_team_variations = _selected_team_variations

	description.text = 	MinigameManager.get_minigame_by(_selected_minigame_id).game_description
	_show_variation()
	_show_minigame_list()

	type_dropdown.select(selected_minigame_type)
	if variation_dropdown.item_count > 1:
		variation_dropdown.select(selected_team_variations)

# --------------------
#    Hilfsfunktionen
# --------------------
func _show_minigame_list() -> void:
	#Container leeren
	for child: Node in minigame_items_container.get_children():
		child.queue_free()
	var minigame_infos: Array[MinigameInfo] = MinigameManager.filter_minigames(game_room_manager.minigame_infos(),MinigameManager.TypeFilter.new(all_minigame_types[selected_minigame_type]))
	#Neue Einträge erzeugen
	var amount_of_columns: int = ceil(minigame_infos.size()/2.0)
	for i: int in range(amount_of_columns):
		var column_container: VBoxContainer = VBoxContainer.new()
		var item1: MinigameSelectionItem = MINIGAME_SELECTION_ITEM.instantiate()
		item1.setup(minigame_infos[i*2], self)
		column_container.add_child(item1)
		if i*2+1 < minigame_infos.size():
			var item2: MinigameSelectionItem = MINIGAME_SELECTION_ITEM.instantiate()
			item2.setup(minigame_infos[i*2+1], self)
			column_container.add_child(item2)
		else:
			var item2: Container = Container.new()
			item2.size_flags_vertical = SIZE_EXPAND_FILL
			column_container.add_child(item2)
		minigame_items_container.add_child(column_container)

func _add_types() -> void:
	for t: MinigameInfo.MinigameTypes in MinigameInfo.MinigameTypes.values():
		all_minigame_types.append(t)
	for i: int in all_minigame_types.size():
		type_dropdown.add_item(MinigameInfo.minigame_type_to_text(all_minigame_types[i]),i)
	type_dropdown.select(selected_minigame_type)
	_show_variation()

func _show_variation() -> void:
	variation_dropdown.visible = true
	variation_label.visible = true
	team_variations = []
	match all_minigame_types[selected_minigame_type]:
		MinigameInfo.MinigameTypes.FFA:
			variation_dropdown.visible = false
			variation_label.visible = false
		MinigameInfo.MinigameTypes.ONE_VS_ONE:
			_generate_variations(1, 1)
		MinigameInfo.MinigameTypes.TWO_VS_TWO:
			_generate_variations(2, 2)
		MinigameInfo.MinigameTypes.ONE_VS_TWO:
			_generate_variations(1, 2)
		MinigameInfo.MinigameTypes.ONE_VS_THREE:
			_generate_variations(1, 3)

func _generate_variations(team_1_size: int, team_2_size: int) -> void:
	var players: Array[int] = [0, 1, 2, 3]
	var all_variations: Array = []
	
	var team_1_combinations: Array = _get_combinations(players, team_1_size)
	
	for t1: Array in team_1_combinations:
		var remaining_players: Array[int]  = []
		for p: int in players:
			if not p in t1:
				remaining_players.append(p)
		
		var team_2_combinations: Array = _get_combinations(remaining_players, team_2_size)
		
		for t2: Array in team_2_combinations:
			var match_up: Array = [t1, t2]
			match_up.sort_custom(func(a: Array, b: Array) -> bool:
				if a.size() != b.size():
					return a.size() < b.size()
				return a < b
			)
			if not match_up in all_variations:
				all_variations.append(match_up)
	
	for x: Array in all_variations:
		var v: TeamVariation = TeamVariation.new()
		v.team_1 = x[0]
		v.team_2 = x[1]
		team_variations.append(v)

	variation_dropdown.clear()
	for i: int in team_variations.size():
		variation_dropdown.add_item(team_variations[i].label(),i)

# Godot ist scheiße und erlaubt keine 2D Array, warum auch immer jemand dachte, dass das eine gute Idee ist. Was zur Hölle ist bei denen schiefgelaufen. Ich meine, 2D Arrays hat man doch schon fast baut man doch schon versehentlich ein. Da muss ja schon jemand sich aktiv gedacht haben, ey wir wolle eine schlechte Sprache sein.
func _get_combinations(pool: Array[int], k: int) -> Array:
	var result: Array = []
	if k == 0:
		return [[]]
	if pool.size() < k:
		return []
		
	for i: int in range(pool.size()):
		var element: int = pool[i]
		var rest: Array[int] = pool.slice(i + 1)
		for sub_combination: Array in _get_combinations(rest, k - 1):
			result.append([element] + sub_combination)
	return result

# --------------------
#    UI-Callbacks
# --------------------
func select_minigame(_minigame_id: int) -> void:
	selected_minigame_id = _minigame_id
	if game_room_manager.is_online():
		if game_room_manager.is_host():
			_select_minigame_server_rpc.rpc_id(1,_minigame_id)
		else:
			InfoPanel.add_message("Nur der Host kann das Minigame auswählen.")
	else:
		_set_settings_client_rpc(_minigame_id, selected_minigame_type, selected_team_variations)

func _on_start_pressed() -> void:
	if game_room_manager.is_online():
		if game_room_manager.is_host():
			_start_server_rpc.rpc_id(1)
		else:
			InfoPanel.add_message("Nur der Host kann das Minigame starten.")
	else:
		_start_server_rpc()

func _on_type_select_item_selected(index: int) -> void:
	if game_room_manager.is_online():
		if game_room_manager.is_host():
			_select_type_server_rpc.rpc_id(1, index)
		else:
			type_dropdown.select(selected_minigame_type)
			InfoPanel.add_message("Nur der Host kann das Minigame Typ auswählen.")
	else:
		_set_settings_client_rpc(selected_minigame_id, index, selected_team_variations)

func _on_variation_select_item_selected(index: int) -> void:
	if game_room_manager.is_online():
		if game_room_manager.is_host():
			_select_variations_server_rpc.rpc_id(1, index)
		else:
			variation_dropdown.select(selected_team_variations)
			InfoPanel.add_message("Nur der Host kann das Minigame Variation auswählen.")
	else:
		_set_settings_client_rpc(selected_minigame_id, selected_minigame_type, index)