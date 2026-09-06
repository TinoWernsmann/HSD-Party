extends Node
class_name BiggameHSDCampus_QuestionUI

@onready var question_ui: Label = $"../CanvasLayer/MarginContainer/Question"
@onready var answers_ui: Label = $"../CanvasLayer/MarginContainer2/Answers"
@onready var quiz_ui: Node2D = $"../CanvasLayer/Node2D"

func fill_ui_elements(question: Dictionary) -> void:
		question_ui.text = question["Question"]
		
		var answers: String = ""
		var counter: int = 1
		for text: String in question["Answers"]:
			answers += str(counter) + ": " + text + " "
			counter += 1
		answers_ui.text = answers

func change_quiz_visibility() -> void:
	question_ui.modulate = Color(0, 0, 0)
	answers_ui.modulate = Color(0, 0, 0)
	question_ui.visible = !question_ui.visible
	answers_ui.visible = !answers_ui.visible
	quiz_ui.visible = !quiz_ui.visible
	
func change_color_by_answer(correct: bool) -> void:
	if correct:
		question_ui.modulate = Color(0, 1, 0)
		answers_ui.modulate = Color(0, 1, 0)
	else:
		question_ui.modulate = Color(1, 0, 0)
		answers_ui.modulate = Color(1, 0, 0)
