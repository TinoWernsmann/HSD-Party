## Handles the Game Camera of the baord scene
extends Camera3D
class_name BiggameHSDCampus_CameraLogic

@export var game_manager: BiggameHSDCampus_GameManager

## Movement target of camera 
@export var follow_target: BiggameHSDCampus_Player 

## Rotation target of camera
@export var look_target: BiggameHSDCampus_Player

## Camera offset
@export var offset: Vector3 = Vector3(0, 5.0, 3.5)
var default_offset: Vector3 = offset
@export var zoom_offset: Vector3 = Vector3(0.5, 0.5, 0.5)
@export var move_speed: float = 15.0
@export var zoom_speed: float = 6.5

var shows_star: bool = false
var current_angle: Vector3
var is_free_cam: bool = false
var saved_player_state: int = -1
var angle_just_switched: bool = false

const MAX_ZOOM: float = 3.0
const MAX_OUT: float = 15.0
const MAX_Z_POSITIVE: float = 47.0
const MAX_Z_NEGATIVE: float = -38.0
const MAX_X_POSTIVE: float = 43.0
const MAX_X_NEGATIVE: float = -55.0

var started: bool = false

func start() -> void:
	started = true
	global_position = follow_target.global_position + offset
	current_angle = offset
	current = true

func _process(delta: float) -> void:
	if started:
		if not shows_star and not is_free_cam:
			global_position = global_position.lerp(follow_target.global_position + offset, 2.5 * delta)
			look_at(look_target.global_position)
		elif not shows_star and is_free_cam:
			var delta_pos_y: float = game_manager.input_get_axis(ControllerDefinition.Axis.VERTICAL)
			var delta_pos_x: float = game_manager.input_get_axis(ControllerDefinition.Axis.HORIZONTAL)

			if delta_pos_y < 0 and global_position.z > MAX_Z_NEGATIVE:
				global_position.z += delta_pos_y * move_speed * delta
			if delta_pos_y > 0 and global_position.z < MAX_Z_POSITIVE:
				global_position.z += delta_pos_y * move_speed * delta
			if delta_pos_x < 0 and global_position.x > MAX_X_NEGATIVE:
				global_position.x += delta_pos_x * move_speed * delta
			if delta_pos_x > 0 and global_position.x < MAX_X_POSTIVE:
				global_position.x += delta_pos_x * move_speed * delta
			if game_manager.input_is_pressed(ControllerDefinition.Buttons.BUTTON_1) and global_position.y < MAX_OUT:
				global_position.z += zoom_speed * delta
				global_position.y += zoom_speed * delta
			if game_manager.input_is_pressed(ControllerDefinition.Buttons.BUTTON_2) and global_position.y > MAX_ZOOM:
				global_position.z -= zoom_speed * delta
				global_position.y -= zoom_speed * delta

func switch_to_other_player(player: BiggameHSDCampus_Player) -> void:
	follow_target = player
	look_target = player
	switch_angle(player.walk_dir.x, player.walk_dir.z)

func switch_angle(x: float, z: float) -> void:
	offset.x = x
	offset.z = z
	current_angle = offset

func _on_camera_angle_switch(new_x: float, new_z: float) -> void:
	switch_angle(new_x, new_z)
	angle_just_switched = true

func _on_camera_zoom() -> void:
	offset = current_angle * zoom_offset

func _on_camera_zoom_out() -> void:
	offset = current_angle
	current = true

func change_free_cam(player: BiggameHSDCampus_Player) -> void:
	if is_free_cam:
		is_free_cam = false
		global_position = player.global_position + offset
		if saved_player_state >= 0:
			player.current_state = saved_player_state
			saved_player_state = -1
		else:
			player.current_state = player.States.IDLE
	else:
		saved_player_state = player.current_state
		global_position = player.global_position + default_offset
		look_at(player.global_position)
		player.current_state = player.States.FREE_CAM
		is_free_cam = true

func switch_to_star(star_tile: BiggameHSDCampus_Tile) -> void:
	shows_star = true
	global_position = star_tile.global_position + Vector3(star_tile.new_cam_x, global_position.y, star_tile.new_cam_z)
	look_at(star_tile.global_position)
