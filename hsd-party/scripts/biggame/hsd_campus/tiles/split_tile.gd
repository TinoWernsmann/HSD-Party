## Handles logic of the split tile
##
## Extends the base Tile class
extends BiggameHSDCampus_Tile
class_name SplitTile

@export var path_options: Array[BiggameHSDCampus_Tile] = []

var current_player: BiggameHSDCampus_Player  = null
var awaiting_input: bool = false
var chosen_index: int = 0
var selection_indicator: Node3D = null
@onready var arrow_texture: Texture2D = load("res://assets/models/biggame/hsd_campus/directionArrow/dot.png")

## Signal on when the player has chosen a path
## Parameter:
##		tile: chosen tile
signal path_chosen(tile: BiggameHSDCampus_Tile)
signal on_camera_zoom()
signal on_camera_zoom_out()

func _ready() -> void:
	is_split = true
	is_zoom = true
	_set_last_tiles_of_next()

func _input(event: InputEvent) -> void:
	if not awaiting_input:
		return
	if current_player == null:
		return
	if current_player.current_state == current_player.States.FREE_CAM:
		return
	var axis_val: float = 0.0
	if game_manager:
		axis_val = game_manager.input_get_axis(ControllerDefinition.Axis.HORIZONTAL)
	if axis_val < 0:
		_set_chosen_index(1)
	elif axis_val > 0:
		_set_chosen_index(0)
	if game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_1):
		path_chosen.emit(path_options[chosen_index])
		_clear_selection_indicator()
		awaiting_input = false
		get_viewport().set_input_as_handled()

func do_tile_action(player: BiggameHSDCampus_Player ) -> void:
	on_camera_zoom.emit()
	player.current_state = player.States.ON_SPLIT_TILE
	awaiting_input = true
	current_player = player
	_show_selection_indicator()
	var chosen: BiggameHSDCampus_Tile = await _await_player_choice()
	_clear_selection_indicator()
	awaiting_input = false
	current_player = null
	player.set_chosen_next_tile(chosen)
	on_camera_zoom_out.emit()
	if player.get_rest_move() > 0:
		player.current_state = player.States.MOVING
		player.move_to_tiles(player.get_rest_move(), true)
	else:
		player.disable_turn()

func _await_player_choice() -> BiggameHSDCampus_Tile:
	return await path_chosen

func _set_last_tiles_of_next() -> void:
	for tile: BiggameHSDCampus_Tile in path_options:
		tile.last_tile = self

func _set_chosen_index(index: int) -> void:
	if index < 0 or index >= path_options.size():
		return
	chosen_index = index
	if selection_indicator:
		var target := path_options[chosen_index].get_world_pos()
		var my_pos := get_world_pos()
		var mid := (my_pos + target) * 0.5
		selection_indicator.global_position = mid + Vector3(0, 0.1, 0)
		selection_indicator.rotation = Vector3(-PI/2, 0, 0)
		var s := selection_indicator.get_node_or_null("SelectionSprite")
		if s:
			s.rotation = Vector3(0, 0, 0)
		
	else:
		_show_selection_indicator()

func _show_selection_indicator() -> void:
	_clear_selection_indicator()
	if path_options.size() == 0:
		return
	var tile := path_options[chosen_index]
	var indicator := Area3D.new()
	var sprite := Sprite3D.new()
	sprite.name = "SelectionSprite"
	sprite.texture = arrow_texture
	sprite.pixel_size = 0.005
	indicator.add_child(sprite)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, 0.4, 0.2) 
	shape.shape = box
	indicator.add_child(shape)

	var pos : Vector3 = tile.get_world_pos()
	add_child(indicator)
	var target := tile.get_world_pos()
	var mid := (get_world_pos() + target) * 0.5
	indicator.global_position = mid + Vector3(0, 0.1, 0)

	indicator.rotation = Vector3(-PI/2, 0, 0)
	var s := indicator.get_node_or_null("SelectionSprite")
	if s:
		s.rotation = Vector3(0, 0, 0)

	selection_indicator = indicator
	

func _clear_selection_indicator() -> void:
	if selection_indicator and selection_indicator.is_inside_tree():
		selection_indicator.queue_free()
	selection_indicator = null


func _choose_path(tile: BiggameHSDCampus_Tile) -> void:
	if not awaiting_input:
		return
	path_chosen.emit(tile)
	awaiting_input = false
