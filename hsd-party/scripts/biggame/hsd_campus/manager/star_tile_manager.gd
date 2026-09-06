### Handles logic of choosing the next star tile
extends Node3D
class_name BiggameHSDCampus_StarManager

var last_star_tile: BiggameHSDCampus_Tile
var current_star_tile: BiggameHSDCampus_Tile

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

### Collects all tiles which are elegible of becoming a star tile
### Afterwards selects a tile randomly from that list to be a star tile
### Parameters:
###		board_logc: Logic of the board which holds all the tiles
func choose_new_star_tile(board_logic: BiggameHSDCampus_BoardLogic) -> void:
	var valid_tiles: Array[BiggameHSDCampus_Tile] = []
	
	for tile: BiggameHSDCampus_Tile in board_logic.get_tile_array():
		if is_tile_star_allowed(tile):
			valid_tiles.append(tile)
	
	if valid_tiles.size() > 0: 
		var chosen_tile:BiggameHSDCampus_Tile = valid_tiles[rng.randi() % valid_tiles.size()]
		# remember previous star, set new star, update visibility and is_star flags
		var prev_star: BiggameHSDCampus_Tile = current_star_tile
		set_star(chosen_tile)
		last_star_tile = prev_star
		if prev_star:
			prev_star.is_star = false
			if prev_star.star_texture:
				prev_star.star_texture.visible = false

		# ensure visual exists for new star; create if missing
		var book_scene_path: String = "res://assets/models/biggame/hsd_campus/book/BookR.glb"
		if current_star_tile:
			if not current_star_tile.star_texture:
				var s: Node = null
				if current_star_tile.has_node("Star"):
					s = current_star_tile.get_node("Star")
				else:
					s = Node3D.new()
					s.name = "Star"
					current_star_tile.add_child(s)
				var packed := load(book_scene_path)
				if packed:
					var model: Node3D = packed.instantiate()
					model.name = "Model"
					s.add_child(model)
					model.scale = Vector3(0.333, 0.333, 0.333)
					model.position = Vector3(0, 0.2, 0)
					model.visible = false
					current_star_tile.star_texture = model
			if current_star_tile.star_texture:
				current_star_tile.star_texture.visible = true

func set_star(tile: BiggameHSDCampus_Tile) -> void:
	tile.is_star = true
	current_star_tile = tile

func is_tile_star_allowed(tile: BiggameHSDCampus_Tile) -> bool:
	return not tile.is_split and not tile == last_star_tile and not tile.is_teleport

func show_next_star_pos(game_manager: BiggameHSDCampus_GameManager) -> void:
	game_manager.in_transition = true
	game_manager.ui_manager.player_whole_UI.visible = false
	game_manager.ui_manager.transition()
	await game_manager.ui_manager.halfway_fade
	game_manager.camera.switch_to_star(current_star_tile)
	await get_tree().create_timer(4.0).timeout
	game_manager.ui_manager.transition()
	await game_manager.ui_manager.halfway_fade
	game_manager.camera.shows_star = false
	await game_manager.ui_manager.fade_done
	game_manager.ui_manager.player_whole_UI.visible = true
	game_manager.in_transition = false
