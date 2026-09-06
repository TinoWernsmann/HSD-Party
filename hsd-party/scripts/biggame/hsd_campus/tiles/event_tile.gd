extends BiggameHSDCampus_Tile 

var event_type: Event_Types
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var negative_audio: AudioStream = preload("res://assets/sound/negative_tile.wav")
var positive_audio: AudioStream = preload("res://assets/sound/coin_sound.wav")

enum Event_Types {
	COINSPLUS,
	COINSMINUS,
	FIELDPLUS,
	FIELDMINUS
}

func _ready() -> void:
	is_split = false
	is_zoom = true
	# null-safe: prefer Star/Model, fallback to Star node
	if has_node("Star"):
		var s: Node = get_node("Star")
		if s and s.has_node("Model"):
			star_texture = s.get_node("Model")
		else:
			star_texture = s
	choose_event()

func _process(delta: float) -> void:
	super._process(delta)


func choose_event() -> void:
	var chosen: int = rng.randi_range(0, Event_Types.size() - 1)
	event_type = chosen as Event_Types

func do_tile_action(player: BiggameHSDCampus_Player) -> void:
	if is_star:
		do_star_action(player)
	else:
		match event_type:
			Event_Types.COINSPLUS:
				on_coins_added.emit(rng.randi_range(5, 20), player)
				audio_manager.play_tile_sound(positive_audio)
				await audio_manager.finished
				player.disable_turn() 
				choose_event()
			Event_Types.COINSMINUS:
				on_coins_added.emit(-rng.randi_range(5, 20), player)
				audio_manager.play_tile_sound(negative_audio)
				await audio_manager.finished
				player.disable_turn() 
				choose_event()
			Event_Types.FIELDPLUS:
				audio_manager.play_tile_sound(positive_audio)
				await audio_manager.finished
				player.move_to_tiles(rng.randi_range(1, 5), true)
				choose_event()
			Event_Types.FIELDMINUS:
				audio_manager.play_tile_sound(positive_audio)
				await audio_manager.finished
				player.move_player_back(rng.randi_range(1, 5))
				choose_event()
