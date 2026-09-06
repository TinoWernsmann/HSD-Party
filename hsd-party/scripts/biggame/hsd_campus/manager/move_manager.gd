extends Node3D
class_name BiggameHSDCampus_MoveManager

var moving_tiles: Array = []
var next_tile: BiggameHSDCampus_Tile
var rest_move: int
var chosen_path: BiggameHSDCampus_Tile
@onready var my_player: BiggameHSDCampus_Player = $".."

## Builds the Tile Movement Array used in the move_to_next_tile() function
## Stops building if number of rolled number is reached or a split tile is reached
func move_to_tiles(numb: int, is_again: bool) -> void:
	moving_tiles.clear()
	
	move(numb, is_again)

	if not moving_tiles.is_empty():
		my_player.move_to_next_tile()

func move_rest_dice() -> void:
	if rest_move <= 0:
		my_player.disable_turn()
		return
	
	my_player.current_state = my_player.States.MOVING
	moving_tiles.clear()
	
	move(rest_move, true)

	if not moving_tiles.is_empty():
		my_player.move_to_next_tile()

func move(number: int, is_again: bool) -> void:
	for x: int in number:
		my_player.current_tile = get_next_tile_to_move()
		if my_player.current_tile == null:
			break
		moving_tiles.append(my_player.current_tile)
		if my_player.current_tile.is_stopping():
			if is_again:
				rest_move = rest_move - x - 1
			else:
				rest_move = my_player.rolled_numb - x - 1
			break

func get_next_tile_to_move() -> BiggameHSDCampus_Tile:
	if next_tile:
		var t: BiggameHSDCampus_Tile = next_tile
		next_tile = null
		return t
	return my_player.current_tile.get_next_tile()

## Moves the player backwards by a specified number of tiles.
## Parameters:
##   spaces: Number of tiles to move backwards
func move_player_back(spaces: int) -> void: 
	my_player.current_state = my_player.States.MOVING
	moving_tiles.clear()
	rest_move = 0

	for x: int in spaces:
		my_player.current_tile = my_player.current_tile.get_last_tile()
		moving_tiles.append(my_player.current_tile)

	my_player.move_to_next_tile()

func get_rest_move() -> int:
	return rest_move

func set_chosen_next_tile(tile: BiggameHSDCampus_Tile) -> void:
	next_tile = tile

func path_chosen(tile: BiggameHSDCampus_Tile) -> void:
	chosen_path = tile
	my_player.current_state = my_player.States.IDLE
