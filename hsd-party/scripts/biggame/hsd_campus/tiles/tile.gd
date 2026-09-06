## Handles the logic of the default tile
##
## Used as the base class for every special tile
extends Node3D
class_name BiggameHSDCampus_Tile

@export var game_manager: BiggameHSDCampus_GameManager

## Tile behind thhis tile
var last_tile: BiggameHSDCampus_Tile

## Tile after this tile
@export var next_tile: BiggameHSDCampus_Tile

@export var is_last_path_tile: bool

@export var is_not_cam_switch: bool

var add_coin_audio: AudioStream = preload("res://assets/sound/coin_sound.wav")
var pass_tile_sound: AudioStream = preload("res://assets/sound/pass_tile.wav")
var earn_star_sound: AudioStream = preload("res://assets/sound/star_collect.wav")

## World position of thhis tile
var world_pos: Vector3

## Boolean if this tile is a split tile
var is_split: bool

## Boolean is this tile is a teleport tile
var is_teleport: bool

# Price is 5 for testing, later it will be 50
var star_price: int = 40

@onready var audio_manager: BiggameHSDCampus_AudioManager = get_tree().get_first_node_in_group("TileAudio")
var star_texture: Node3D

var is_zoom: bool = false

@export var star_rotate_speed: float = 0.6 # radians per second

var is_star: bool
@export var new_cam_x: float
@export var new_cam_z: float

signal on_coins_added(coins: int, player: BiggameHSDCampus_UIManager)
signal on_star_added(stars: int, coins: int,player: BiggameHSDCampus_UIManager)
signal on_camera_angle_switch(new_x: int, new_z: int)

func _ready() -> void:
	is_split = false
	# Try to find the Star node and the instanced Model child. Be null-safe.
	var book_scene_path: String = "res://assets/models/biggame/hsd_campus/book/BookR.glb"
	if has_node("Star"):
		var star_node: Node = get_node("Star")
		if star_node and star_node.has_node("Model"):
			star_texture = star_node.get_node("Model")
		else:
			# create Model child from BookR if missing
			star_texture = star_node
			var packed: Resource = load(book_scene_path)
			if packed:
				var model: Node3D = packed.instantiate()
				model.name = "Model"
				star_node.add_child(model)
				model.visible = false
				model.scale = Vector3(0.333, 0.333, 0.333)
				model.position = Vector3(0, 0.2, 0)
				star_texture = model
	else:
		# No Star node present in this tile scene; create Star node + Model child so visuals exist
		var star_node: Node3D = Node3D.new()
		star_node.name = "Star"
		add_child(star_node)
		var packed: Resource = load(book_scene_path)
		if packed:
			var model: Node3D = packed.instantiate()
			model.name = "Model"
			star_node.add_child(model)
			model.visible = false
			model.scale = Vector3(0.333, 0.333, 0.333)
			model.position = Vector3(0, 0.2, 0)
			star_texture = model
		else:
			star_texture = null
	
func _enter_tree() -> void:
	world_pos = global_position

func _process(delta: float) -> void:
	# rotate the star model slowly when it's visible
	if star_texture:
		star_texture.rotate_y(star_rotate_speed * delta)

func get_next_tile() -> BiggameHSDCampus_Tile:
	return next_tile
	
func get_last_tile() -> BiggameHSDCampus_Tile:
	return last_tile
	
func get_world_pos() -> Vector3:
	return world_pos
	
## Function on what this tile does if its landed upon
## Overwritten by all other special tiles
## Parameter:
##		player: player that landed on the tile
func do_tile_action(player: BiggameHSDCampus_Player) -> void:
	if is_star:
		do_star_action(player)
	else:
		audio_manager.play_tile_sound(add_coin_audio)
		on_coins_added.emit(5, player)
		await get_tree().create_timer(1.25).timeout
		player.disable_turn()

func is_stopping() -> bool:
	return is_split or is_star or is_teleport

func do_star_action(player: BiggameHSDCampus_Player) -> void:
	if is_buyable(player.get_coins()):
		await get_tree().create_timer(0.5).timeout
		audio_manager.play_tile_sound(earn_star_sound)
		await audio_manager.finished
		on_star_added.emit(1, star_price, player)
		is_star = false
		player.disable_turn()
	else:
		player.disable_turn()

func play_pass_sound() -> void:
	audio_manager.play_tile_sound(pass_tile_sound)

func is_buyable(cp: int) -> bool:
	return cp >= star_price

func try_switch_cam(player: BiggameHSDCampus_Player) -> void:
	if not is_not_cam_switch:
		player.walk_dir.x = new_cam_x
		player.walk_dir.z = new_cam_z
		player.rotate_player()
		on_camera_angle_switch.emit(new_cam_x, new_cam_z)
