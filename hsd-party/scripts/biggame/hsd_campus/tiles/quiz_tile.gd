## Handles the Quiz Tile used in game
extends BiggameHSDCampus_Tile
class_name Quiz_Tile

@export var question_manager: BiggameHSDCampus_QuestionManager
@export var hsd_campus: BiggameHSDCampus
@export var question_UI: BiggameHSDCampus_QuestionUI

@onready var quiz_animator: AnimationPlayer = $Camera3D/AnimationPlayer
@onready var quiz_cam: Camera3D = $Camera3D

var awaiting_input: bool = false
var chosen_answer: int
var land_sound: AudioStream = preload("res://assets/sound/quiz.wav")
var wrong_sound: AudioStream = preload("res://assets/sound/negative_tile.wav")
var right_sound: AudioStream = preload("res://assets/sound/coin_sound.wav")

signal question_answered()
signal on_camera_zoom_out()

func _ready() -> void:
	is_zoom = true
	# null-safe: prefer Star/Model, fallback to Star node
	if has_node("Star"):
		var s := get_node("Star")
		if s and s.has_node("Model"):
			star_texture = s.get_node("Model")
		else:
			star_texture = s
			

func _process(_delta: float) -> void:
	super._process(_delta)
	
	if not awaiting_input:
		return

	if game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_1):
		chosen_answer = 0
		question_answered.emit()
	elif game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_2):
		chosen_answer = 1
		question_answered.emit()
	elif game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_3):
		chosen_answer = 2
		question_answered.emit()
	elif game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_4):
		chosen_answer = 3
		question_answered.emit()

func do_tile_action(player: BiggameHSDCampus_Player) -> void:
	if is_star:
		do_star_action(player)
	else:
		var origin: Vector3 = player.position
		player.position = Vector3(self.get_world_pos().x, player.position.y, self.get_world_pos().z)
		player.rotation_degrees.y += 60
		var question: Dictionary = question_manager.get_random_question(hsd_campus)
		game_manager.hide_all_players()
		player.visible = true
		quiz_cam.current = true
		quiz_animator.play("intro")
		question_UI.fill_ui_elements(question) 
		audio_manager.play_tile_sound(land_sound)
		await quiz_animator.animation_finished
		question_UI.change_quiz_visibility()
		awaiting_input = true
		await question_answered

		if chosen_answer == question["Correct"]:
			audio_manager.play_tile_sound(right_sound)
			player.animation_player.play("happy")
			on_coins_added.emit(10, player)
			question_UI.change_color_by_answer(true)
		else:
			audio_manager.play_tile_sound(wrong_sound)
			player.animation_player.play("sad")
			on_coins_added.emit(-5, player)
			question_UI.change_color_by_answer(false)

		quiz_animator.play("RESET")
		await quiz_animator.animation_finished
		player.position = origin
		on_camera_zoom_out.emit()
		quiz_cam.current = false
		game_manager.show_all_players()
		question_UI.change_quiz_visibility()
		player.rotation_degrees.y -= 60
		player.disable_turn()
