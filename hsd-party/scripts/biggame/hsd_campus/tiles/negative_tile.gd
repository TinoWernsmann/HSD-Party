## Handles logic of the negative tile
##
## Extends the base Tile class
extends BiggameHSDCampus_Tile

@export var is_coin_remove: bool

@onready var pic: Sprite3D = $Sprite3D

@onready var tile_land_sound: AudioStream = preload("res://assets/sound/negative_tile.wav")
@onready var send_back_pic: CompressedTexture2D = preload("res://assets/sprites/biggame/hsd_campus/tiles/send_back.png")
@onready var minus_coins_pic: CompressedTexture2D = preload("res://assets/sprites/biggame/hsd_campus/tiles/minus_coins.png")

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var send_back: int
var minus_coins: int

## Signal when the tile is entered
## Parameters:
##		spaces: spaces to move back
##		player: which player to move back
signal on_entered(spaces: int, player: BiggameHSDCampus_UIManager)

func _ready() -> void:
	is_split = false
	# null-safe: prefer Star/Model, fallback to Star node
	if has_node("Star"):
		var s := get_node("Star")
		if s and s.has_node("Model"):
			star_texture = s.get_node("Model")
		else:
			star_texture = s
	
	if not is_coin_remove:
		pic.texture = send_back_pic
		pic.rotate_y(-0.65)
		send_back = rng.randi_range(3, 6)
	else:
		pic.texture = minus_coins_pic
		minus_coins = rng.randi_range(5, 15)

func _process(delta: float) -> void:
	super._process(delta)

func do_tile_action(player: BiggameHSDCampus_Player) -> void:
	if is_star:
		do_star_action(player)
	elif is_coin_remove:
		audio_manager.play_tile_sound(tile_land_sound)
		on_coins_added.emit(-minus_coins, player)
		await audio_manager.finished
		player.disable_turn()
	else:
		audio_manager.play_tile_sound(tile_land_sound)
		await audio_manager.finished
		on_entered.emit(send_back, player)
