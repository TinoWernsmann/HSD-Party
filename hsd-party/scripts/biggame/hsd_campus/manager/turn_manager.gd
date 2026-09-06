extends Node
class_name BiggameHSDCampus_TurnManager

## Index of which player is selected. Starts at 0 (BiggameHSDCampus_Player 1 is index 0)
var select_player: int = 0

## Events on what happens on player turn end
## Selects next player and switches camera to them
## Enables next players turn
## Changes UI visualisation to show which players turn it is
func on_player_on_turn_ended(game_manager: BiggameHSDCampus_GameManager) -> void:
	game_manager.in_transition = true
	for p: BiggameHSDCampus_Player in game_manager.players:
		if p.is_turn:
			p.walk_dir = game_manager.camera.offset
			p.is_turn = false
			
	game_manager.ui_manager.hide_turn_color(select_player)

	if select_player < game_manager.players.size() - 1:
		select_player += 1
		game_manager.ui_manager.fade_out(select_player + 1)
		await get_tree().create_timer(1.0).timeout
		game_manager.ui_manager.show_player_controls(game_manager.hsd_campus.player_information[select_player])
	else:
		select_player = 0
		game_manager.ui_manager.fade_out(select_player + 1)
		await get_tree().create_timer(1.0).timeout
		game_manager.ui_manager.show_player_controls(game_manager.hsd_campus.player_information[select_player])
		game_manager.hsd_campus.increase_round_count()
		if game_manager.hsd_campus.check_game_over():
			game_manager.finish_game()
		else:
			game_manager.play_minigame()

	await game_manager.ui_manager.halfway_fade

	game_manager.ui_manager.update_rounds(game_manager.hsd_campus.get_round_count())

	game_manager.ui_manager.show_turn_color(select_player)
	game_manager.camera.switch_to_other_player(game_manager.players[select_player])
	game_manager.players[select_player].selected_dice.visible = true
	
	await game_manager.ui_manager.fade_done
	
	game_manager.players[select_player].enable_turn()
	game_manager.in_transition = false
