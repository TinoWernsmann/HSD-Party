## Handles player movement, turn management, coin collection
extends Node3D
class_name BiggameHSDCampus_Player

## The tile where this player begins the game
@export var start_tile: BiggameHSDCampus_Tile

var rolled_numb: int

## Speed multiplier for movement animation
var move_speed: float = 1.25

## Reference to the dice this player uses
@export var selected_dice: BiggameHSDCampus_Dice

## This players index number
@export var player_numb: int

@export var offset: Vector3

@export var inventory_manager: BiggameHSDCampus_InventoryManager

@export var move_manager: BiggameHSDCampus_MoveManager

var current_state: States
var current_tile: BiggameHSDCampus_Tile
var is_turn: bool
var coins: int = 10
var stars: int = 0
var walk_dir: Vector3 = Vector3(0.0, 0.0, 3.5)
@onready var player_mesh: MeshInstance3D = $PlayerMesh
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var player_material: Material

var game_manager: BiggameHSDCampus_GameManager

signal on_turn_ended

## Current gameplay state of the player
enum States {
	IDLE,
	MOVING,
	CHOOSING_ITEM,
	FREE_CAM,
	USING_ITEM,
	ON_SPLIT_TILE,
	IN_MINIGAME
}

func setup(_game_manager: BiggameHSDCampus_GameManager, _player_numb: int, _selected_dice: BiggameHSDCampus_Dice, _start_tile: BiggameHSDCampus_Tile, _offset: Vector3, _player_material: Material) -> void:
	self.game_manager = _game_manager
	on_turn_ended.connect(_game_manager._on_player_on_turn_ended)
	self.player_numb = _player_numb
	self.selected_dice = _selected_dice
	self.start_tile = _start_tile
	self.offset = _offset
	self.player_material = _player_material

func _ready() -> void:
	current_state = States.IDLE
	current_tile = start_tile
	global_position = current_tile.get_world_pos() + offset
	player_mesh.material_override = player_material
	
func _process(_delta: float) -> void:
	if not is_turn:
		return

	if current_state != States.IDLE:
		return

	if game_manager.hsd_campus.hsd_campus_settings.debug_cheats:
		if Input.is_action_just_pressed("cheat 0"):
			handle_dice_roll(10)
		if Input.is_action_just_pressed("cheat 1"):
			handle_dice_roll(1)
		if Input.is_action_just_pressed("cheat 2"):
			handle_dice_roll(2)
		if Input.is_action_just_pressed("cheat 3"):
			handle_dice_roll(3)
		if Input.is_action_just_pressed("cheat 4"):
			handle_dice_roll(4)
		if Input.is_action_just_pressed("cheat 5"):
			handle_dice_roll(5)
		if Input.is_action_just_pressed("cheat 6"):
			handle_dice_roll(6)
		if Input.is_action_just_pressed("cheat 7"):
			handle_dice_roll(7)
		if Input.is_action_just_pressed("cheat 8"):
			handle_dice_roll(8)
		if Input.is_action_just_pressed("cheat 9"):
			handle_dice_roll(9)

	# Roll Dice
	if game_manager.input_is_pressed(ControllerDefinition.Buttons.BUTTON_1):
		handle_dice_roll()

## Builds the Tile Movement Array used in the move_to_next_tile() function
## Stops building if number of rolled number is reached or a split tile is reached
func move_to_tiles(numb: int, is_again: bool) -> void:
	move_manager.move_to_tiles(numb, is_again)

func move_rest_dice() -> void:
	move_manager.move_rest_dice()

func move(number: int, is_again: bool) -> void:
	move_manager.move(number, is_again)

func get_next_tile_to_move() -> BiggameHSDCampus_Tile:
	return move_manager.get_next_tile_to_move()

## Moves the player along the tiles of the Tile Movement Array
## Stops once the array is empty
func move_to_next_tile() -> void:
	if move_manager.moving_tiles.is_empty():  
		current_tile.do_tile_action(self)
		move_manager.next_tile = null
		animation_player.stop()
		return
	move_manager.next_tile = move_manager.moving_tiles.pop_front()
	var direction: Vector3 = (move_manager.next_tile.get_world_pos() - global_position).normalized()
	var target_rotation: float = atan2(direction.x, direction.z)
	move_manager.next_tile.try_switch_cam(self)
	player_mesh.rotation.y = target_rotation
	animation_player.play("walk")
	var target_pos: Vector3 = move_manager.next_tile.get_world_pos() + offset
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", target_pos,  1.0 / move_speed)
	var tile_to_sound: BiggameHSDCampus_Tile = move_manager.next_tile
	tween.finished.connect(func() -> void:
		tile_to_sound.play_pass_sound()
		rolled_numb -= 1
		selected_dice.update_rolled_number(rolled_numb)
		move_to_next_tile()
	)

## Moves the player backwards by a specified number of tiles.
## Parameters:
##   spaces: Number of tiles to move backwards
func move_player_back(spaces: int) -> void: 
	move_manager.move_player_back(spaces)

func enable_turn() -> void:
	is_turn = true

func disable_turn() -> void:
	current_state = States.IDLE
	selected_dice.hide_rolled_numb()
	on_turn_ended.emit()

## Adds coins to the player's total.
## Parameters:
##   new_coins: Amount of coins to add
func add_coins(new_coins: int) -> void:
	coins += new_coins
	if coins < 0:
		coins = 0

func add_stars(new_stars: int) -> void:
	stars += new_stars

func get_coins() -> int:
	return coins

func get_stars() -> int:
	return stars

func get_chosen_path() -> BiggameHSDCampus_Tile:
	return move_manager.chosen_path

func _on_split_tile_path_chosen(tile: BiggameHSDCampus_Tile) -> void:
	move_manager.path_chosen(tile)

func set_chosen_next_tile(tile: BiggameHSDCampus_Tile) -> void:
	move_manager.set_chosen_next_tile(tile)

func get_rest_move() -> int:
	return move_manager.get_rest_move()

func get_visual_scene() -> MeshInstance3D:
	return player_mesh.duplicate()
	
func get_inventory_manager() -> BiggameHSDCampus_InventoryManager:
	return inventory_manager

func set_new_tile(tile: BiggameHSDCampus_Tile) -> void:
	current_tile = tile

func set_dice(dice: BiggameHSDCampus_Item) -> void:
	self.selected_dice.change_dice(dice)

func rotate_player() -> void:
	var target_rot: float = atan2(walk_dir.x, walk_dir.z)
	self.rotation.y = target_rot

func handle_dice_roll(_number: int = -1) -> void:
	current_state = States.MOVING
	rolled_numb = selected_dice.roll_dice(_number)
	var original_position: Vector3 = global_position
	var dice_position: Vector3 = selected_dice.global_position
	
	selected_dice.fix_position()
	
	await jump_to_position(dice_position + Vector3(0, 0.1, 0))
	await selected_dice.animation()
	await jump_to_position(original_position)
	
	selected_dice.unfix_position()
	
	await get_tree().process_frame
	selected_dice.visible = false
	move_to_tiles(rolled_numb, false)

func jump_to_position(target_pos: Vector3, duration: float = 0.6) -> void:
	var start_pos: Vector3 = global_position
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	var mid_point: Vector3 = (start_pos + target_pos) / 2.0
	mid_point.y = max(start_pos.y, target_pos.y) + 0.8
	tween.tween_property(self, "global_position", mid_point, duration * 0.5)
	await tween.finished
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", target_pos, duration * 0.5)
	await tween.finished
