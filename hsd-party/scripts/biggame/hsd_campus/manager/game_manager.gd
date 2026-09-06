## Handles game logic and assigning each manager its values
##
## Fills the BiggameHSDCampus_Player Array
## Initializes UI manager and the UI itself
## Starts the first players turn
extends Node3D
class_name BiggameHSDCampus_GameManager

## Array of all players on board
var players: Array[BiggameHSDCampus_Player]

var awaiting_input: bool = false
var in_transition: bool

## Camera Object of the game
@export var camera: BiggameHSDCampus_CameraLogic

## BiggameHSDCampus_UIManager object of the game
@export var ui_manager: BiggameHSDCampus_UIManager

@export var board_logic: BiggameHSDCampus_BoardLogic
@export var star_manager: BiggameHSDCampus_StarManager
@export var hsd_campus: BiggameHSDCampus
@export var item_factory: BiggameHSDCampus_ItemFactory
@export var path_manager: BiggameHSDCampus_PathManager
@export var tile_init: BiggameHSDCampus_TileInit
@export var player_init: BiggameHSDCampus_PlayerInit
@export var turn_manager: BiggameHSDCampus_TurnManager

var disabled: bool
@export var canvas_layer_to_hide: Array[CanvasLayer]

signal player_chosen(player: BiggameHSDCampus_Player)

func start() -> void:
	## Create BiggameHSDCampus_Player
	player_init.gather_players(self, hsd_campus.player_information)
	ui_manager.generate_ui(self, hsd_campus.player_information)

	camera.switch_to_other_player(players[0])
	camera.start()
	tile_init.init_tiles(board_logic, self)
			
	star_manager.choose_new_star_tile(board_logic)
	
	await star_manager.show_next_star_pos(self)

	ui_manager.update_item_list(players[turn_manager.select_player])

	players[turn_manager.select_player].enable_turn()
	ui_manager.show_turn_color(turn_manager.select_player)
	ui_manager.show_player_controls(hsd_campus.player_information[turn_manager.select_player])

func _process(_delta: float) -> void:  
	if players[turn_manager.select_player].current_state == players[turn_manager.select_player].States.IN_MINIGAME:
		return 
	
	if input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_3) and is_allowed_free_cam():
		camera.change_free_cam(players[turn_manager.select_player])
	
	if players[turn_manager.select_player].current_state == players[turn_manager.select_player].States.IDLE:
		if hsd_campus.hsd_campus_settings.debug_cheats:
			var player: BiggameHSDCampus_Player = players[turn_manager.select_player]
			if Input.is_action_just_pressed("cheat +"):
				player.add_coins(1)
				ui_manager.update_coins(player.player_numb, player.get_coins())
			if Input.is_action_just_pressed("cheat -"):
				player.add_coins(-1)
				ui_manager.update_coins(player.player_numb, player.get_coins())
		return

	if players[turn_manager.select_player].current_state == players[turn_manager.select_player].States.USING_ITEM:
		var select: int = -1

		if input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_1) and turn_manager.select_player != 0:
			select = 0
		elif input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_2) and turn_manager.select_player != 1:
			select = 1
		elif input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_3) and turn_manager.select_player != 2:
			select = 2
		elif input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_4) and turn_manager.select_player != 3:
			select = 3
		
		if select >= 0 and select < players.size():
			player_chosen.emit(players[select])
			awaiting_input = false
			get_viewport().set_input_as_handled()

func is_allowed_free_cam() -> bool:
	var player_state: BiggameHSDCampus_Player.States = players[turn_manager.select_player].current_state
	return not in_transition and (player_state == players[turn_manager.select_player].States.IDLE or player_state == players[turn_manager.select_player].States.FREE_CAM or player_state == players[turn_manager.select_player].States.ON_SPLIT_TILE)

func input_is_pressed(button: ControllerDefinition.Buttons) -> bool:
	return  hsd_campus.game_room_manager.input_is_pressed(hsd_campus.player_information[turn_manager.select_player].player_nr, button)

func input_is_just_pressed(button: ControllerDefinition.Buttons) -> bool:
	return  hsd_campus.game_room_manager.input_is_just_pressed(hsd_campus.player_information[turn_manager.select_player].player_nr, button)

func input_get_axis(axis: ControllerDefinition.Axis) -> float:
	return  hsd_campus.game_room_manager.input_get_axis(hsd_campus.player_information[turn_manager.select_player].player_nr, axis)

func _on_player_on_turn_ended() -> void:
	turn_manager.on_player_on_turn_ended(self)

## Events on what happens if player lands on negative tile
## Moves player back a given number of spaces
## Parameters:
##		spaces: number of spaces to move back
##		player: player to move back
func _on_negative_tile_on_entered(spaces: int, player: BiggameHSDCampus_Player) -> void:
	player.move_player_back(spaces)

## Events on what happens when player gets coins from a tile
## Adds coins to player and updates UI
## Parameters:
##		coins: number of coins to add
##		player: which player to add coins to
func _on_tile_on_coins_added(coins: int, player: BiggameHSDCampus_Player) -> void:
	if coins == 0:
		return

	player.add_coins(coins)
	ui_manager.update_coins(player.player_numb, player.get_coins())

func _on_tile_on_star_added(stars: int, coins: int, player: BiggameHSDCampus_Player) -> void:
	player.add_stars(stars)
	player.add_coins(-coins)
	ui_manager.update_stars(player.player_numb, player.get_stars())
	ui_manager.update_coins(player.player_numb, player.get_coins())
	# hide bought star visual on current tile
	var cur_tile: BiggameHSDCampus_Tile = players[turn_manager.select_player].current_tile
	if cur_tile:
		cur_tile.is_star = false
		if cur_tile.star_texture:
			cur_tile.star_texture.visible = false

	# Choose and show the next star tile
	star_manager.choose_new_star_tile(board_logic)
	await star_manager.show_next_star_pos(self)

func update_selected_item(index: int) -> void:
	ui_manager.selected_item(index, turn_manager.select_player)

func _on_player_item_use(player: BiggameHSDCampus_Player, item: BiggameHSDCampus_Item) -> void:
	var success: bool = await item.use(self, player)
	ui_manager.hide_selected_item_description()
	
	if success:
		player.get_inventory_manager().remove_item(item)
		player.get_inventory_manager().chosen_item_index = -1
		ui_manager.update_item_list(player)
	else:
		player.get_inventory_manager().chosen_item_index = -1
		ui_manager.cancel_item_selection(turn_manager.select_player)

func steal_coins(amount: int, receive: BiggameHSDCampus_Player, subtract: BiggameHSDCampus_Player) -> void:
	receive.current_state = receive.States.USING_ITEM
	subtract.add_coins(-amount)
	receive.add_coins(amount)
	ui_manager.update_coins(subtract.player_numb, subtract.get_coins())
	ui_manager.update_coins(receive.player_numb, receive.get_coins())
	receive.current_state = receive.States.IDLE
	
func steal_item(item: BiggameHSDCampus_Item, receive: BiggameHSDCampus_Player, remove: BiggameHSDCampus_Player) -> void:
	receive.current_state = receive.States.USING_ITEM
	receive.get_inventory_manager().add_item(item)
	remove.get_inventory_manager().remove_item(item)
	ui_manager.update_item_list(receive)
	ui_manager.update_item_list(remove)
	receive.current_state = receive.States.IDLE

func change_cam(dir: Vector3) -> void:
	camera.switch_angle(dir.x, dir.z)

func await_player_chosen() -> BiggameHSDCampus_Player:
	return await player_chosen

func get_current_star_tile() -> BiggameHSDCampus_Tile:
	return star_manager.current_star_tile

func item_transition() -> void:
	in_transition = true
	ui_manager.transition()
	await ui_manager.halfway_fade

func item_transition_done() -> void:
	await ui_manager.fade_done
	ui_manager.restore_fade()
	in_transition = false

func play_minigame() -> void:
	# Hier wird ein Minispiel gestartet und abgewartet bis es beendet ist
	await ui_manager.halfway_fade
	for player: BiggameHSDCampus_Player in players:
		player.current_state = player.States.IN_MINIGAME
	hsd_campus.play_minigame()

func enable_player_input() -> void:
	for player: BiggameHSDCampus_Player in players:
		player.current_state = player.States.IDLE

func minigame_done(result: MinigameBase.MinigameResult) -> void:
	if result is MinigameBase.FFAResult:
		var ffa_result: MinigameBase.FFAResult = result
		var place_counter: int = 1
		for x: MinigameBase.FFAResult.FFAPlace in ffa_result.places:
			for player_info: GameRoomManagerBase.PlayerInformation in x.players:
				var player_id: int = hsd_campus.player_information.find(player_info)
				print(player_id)
				var amount_of_coins: int = 0
				match (place_counter):
					1: amount_of_coins = 10
					2: amount_of_coins = 5
					3: amount_of_coins = 3
					4: amount_of_coins = 1

				_on_tile_on_coins_added(amount_of_coins, players[player_id])
			place_counter += x.players.size()

func play_duell() -> BiggameHSDCampus_Player:
	var winner: BiggameHSDCampus_Player = players[0]
	return winner

func get_current_player() -> int:
	return turn_manager.select_player

func finish_game() -> void:
	var player_order: Array[int] = []
	for i: int in players.size():
		player_order.append(i)	
	
	player_order.sort_custom(func (a: int,b: int)-> bool:
		var a_player: BiggameHSDCampus_Player = players[a]
		var b_player: BiggameHSDCampus_Player = players[b]
		if a_player.stars == b_player.stars:
			return a_player.coins > b_player.coins
		else:
			return a_player.stars > b_player.stars
	)
	hsd_campus.finish_game(player_order)

#Deaktiviert alle Elemente im Playgound. Wird z.B. genutzt während eines Minispiels.
func set_disabled(value: bool) -> void:
	disabled = value
	for x: CanvasLayer in canvas_layer_to_hide:
		x.visible = !value

# Mache alle Spieler unsichtbar. Wird z.B. bei der Quiz Tile genutzt
func hide_all_players() -> void:
	for player: BiggameHSDCampus_Player in players:
		player.visible = false

func show_all_players() -> void:
	for player: BiggameHSDCampus_Player in players:
		player.visible = true
