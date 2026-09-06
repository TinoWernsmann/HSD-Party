extends Node3D
class_name BiggameHSDCampus_TileInit

func init_tiles(board_logic: BiggameHSDCampus_BoardLogic, game_manager: BiggameHSDCampus_GameManager) -> void:
	# Connect board tile signals
	for tile: BiggameHSDCampus_Tile in board_logic.get_tile_array():
		connect_tile_signals(tile, game_manager)
	for path: Array in game_manager.path_manager.get_paths():
		for tile: BiggameHSDCampus_Tile in path:
			connect_tile_signals(tile, game_manager)

func connect_tile_signals(tile: BiggameHSDCampus_Tile, game_manager: BiggameHSDCampus_GameManager) -> void:
	if not tile.on_coins_added.is_connected(game_manager._on_tile_on_coins_added):
		tile.on_coins_added.connect(game_manager._on_tile_on_coins_added)
	if not tile.on_star_added.is_connected(game_manager._on_tile_on_star_added):
		tile.on_star_added.connect(game_manager._on_tile_on_star_added)
	if not tile.on_camera_angle_switch.is_connected(game_manager.camera._on_camera_angle_switch):
		tile.on_camera_angle_switch.connect(game_manager.camera._on_camera_angle_switch)
	if tile.has_signal("on_camera_zoom") and tile.is_zoom:
		if not tile.on_camera_zoom.is_connected(game_manager.camera._on_camera_zoom):
			tile.on_camera_zoom.connect(game_manager.camera._on_camera_zoom)
	if tile.has_signal("on_camera_zoom_out") and tile.is_zoom:
		if not tile.on_camera_zoom_out.is_connected(game_manager.camera._on_camera_zoom_out):
			tile.on_camera_zoom_out.connect(game_manager.camera._on_camera_zoom_out)
	if tile.has_signal("on_purchase_complete"):
		if not tile.on_purchase_complete.is_connected(game_manager.ui_manager._on_purchase):
			tile.on_purchase_complete.connect(game_manager.ui_manager._on_purchase)
