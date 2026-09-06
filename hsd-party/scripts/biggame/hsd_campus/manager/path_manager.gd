## Handles the logic of splitting pathways
##
## Links all the choosable pathways together with the given Tiles
extends Node3D
class_name BiggameHSDCampus_PathManager

## Array of all split pathways on the board
var pathways: Dictionary = {}

func get_paths() -> Array:
	return pathways.values()

func register_path(path_name: String, tiles: Array[BiggameHSDCampus_Tile]) -> void:
	pathways[path_name] = tiles
	link_path(tiles)
	
func link_path(tiles: Array[BiggameHSDCampus_Tile]) -> void:
	for i: int in range(tiles.size()):
		var current: BiggameHSDCampus_Tile = tiles[i]
		current.last_tile = tiles[(i - 1 + tiles.size()) % tiles.size()]
		current.next_tile = tiles[(i + 1) % tiles.size()]
