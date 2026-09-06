## Handles linking all tiles together from given BiggameHSDCampus_Tile Array
extends Node3D
class_name BiggameHSDCampus_BoardLogic

@export var tile_group_name: String = "Tile"

var tiles: Array[BiggameHSDCampus_Tile] = []

func _enter_tree() -> void:
	collect_tiles()
	link_tiles()

func collect_tiles() -> void:
	tiles.clear()
	for node: BiggameHSDCampus_Tile in get_tree().get_nodes_in_group(tile_group_name):
		if node is BiggameHSDCampus_Tile:
			tiles.append(node)

func get_tile_array() -> Array[BiggameHSDCampus_Tile]:
	return tiles

func link_tiles() -> void:
	if tiles.is_empty():
		return
	
	for i: int in range(tiles.size()):
		var current: BiggameHSDCampus_Tile = tiles[i]
		var prev: BiggameHSDCampus_Tile = tiles[(i - 1 + tiles.size()) % tiles.size()]
		var next: BiggameHSDCampus_Tile = tiles[(i + 1) % tiles.size()]
		
		current.last_tile = prev
		
		if not current.is_last_path_tile:
			current.next_tile = next
