extends BiggameHSDCampus_Tile
class_name Teleport_Tile

@export var teleport_destination: Teleport_Tile
@export var animation_destination: Node3D
const TRANSITION_SPEED: float = 1.0

var teleport_down_sound: AudioStream = preload("res://assets/sound/teleport_down.wav")
var teleport_up_sound: AudioStream = preload("res://assets/sound/teleport_up.wav")

func _ready() -> void:
	is_teleport = true

func do_tile_action(player: BiggameHSDCampus_Player) -> void:
	var original_pos_y: float = player.position.y
	
	game_manager.camera.switch_angle(self.new_cam_x, self.new_cam_z)
	await get_tree().create_timer(0.5).timeout
	await move_down(player)
	await game_manager.item_transition()
	execute_teleport(player)
	await game_manager.item_transition_done()
	await end_telpeort(player, original_pos_y)
	
	player.current_tile = teleport_destination
	if player.get_rest_move() > 0:
		player.current_state = player.States.MOVING
		player.move_to_tiles(player.get_rest_move(), true)
	else:
		player.disable_turn()

func move_down(player: BiggameHSDCampus_Player) -> void:
	audio_manager.play_tile_sound(teleport_down_sound)
	var move_down_pos: Vector3 = animation_destination.position
	var down_tween: Tween = create_tween()
	down_tween.tween_property(player, "global_position", move_down_pos, TRANSITION_SPEED)
	await down_tween.finished

func execute_teleport(player: BiggameHSDCampus_Player) -> void:
	var target_pos: Vector3 = teleport_destination.animation_destination.position
	player.position = target_pos
	game_manager.camera.switch_angle(teleport_destination.new_cam_x, teleport_destination.new_cam_z)

func end_telpeort(player: BiggameHSDCampus_Player, original_pos_y: float) -> void:
	audio_manager.play_tile_sound(teleport_up_sound)
	var up_pos: Vector3 = Vector3(teleport_destination.get_world_pos().x, original_pos_y, teleport_destination.get_world_pos().z)
	up_pos  = up_pos + player.offset
	var up_tween: Tween = create_tween()
	up_tween.tween_property(player, "global_position", up_pos, TRANSITION_SPEED)
	await up_tween.finished
