## Handles the choosing of a new question
extends Node
class_name BiggameHSDCampus_QuestionManager

## Dictionary of questions
var question_dic: Dictionary
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _enter_tree() -> void:
	fill_question_dictionary()

## Fills the Dictionary with questions
func fill_question_dictionary() -> void:
	question_dic = {
		0: {
			"Question": "Welche Programmiersprache wird am häufigsten für Spieleentwicklung verwendet?",
			"Answers": ["Python", "C++", "JavaScript", "Ruby"],
			"Correct": 1
		},
		1: {
			"Question": "Was ist ein Sprite in der Spieleentwicklung?",
			"Answers": ["Eine Softdrink-Marke", "Ein 2D-Grafikobjekt, das auf dem Bildschirm erscheint", "Ein Musikgenre", "Ein Server für Multiplayer-Spiele"],
			"Correct": 1
		},
		2: {
			"Question": "Welche Game Engine ist Open Source und kostenlos?",
			"Answers": ["Unity ", "Unreal Engine", "Godot", "Game Maker"],
			"Correct": 2
		},
		3: {
			"Question": "Was ist der sicherste Zugangsmodifikator?",
			"Answers": ["Public", "Protected", "Private", "Package"],
			"Correct": 2
		},
		4: {
			"Question": "Mit welcher Sprache gestaltet man das Aussehen einer Website?",
			"Answers": ["HTML", "Python", "CSS", "C#"],
			"Correct": 2
		},
		5: {
			"Question": "Welcher dieser Sprachen ist am nächsten an der Maschinensprache?",
			"Answers": ["C++", "Assembly", "C", "C#"],
			"Correct": 1
		},
		6: {
			"Question": "Welcher dieser Sprachen ist von der Maschinensprache am weitesten weg?",
			"Answers": ["C++", "Assembly", "C", "C#"],
			"Correct": 3
		},
		7: {
			"Question": "Wofür steht die Abkürzung CPU?",
			"Answers": ["Cooling Process Unit", "Canadian Post Unit", "Central Processing Unit", "Cubic Processing Unit"],
			"Correct": 2
		},
		8: {
			"Question": "Was ist ein Byte?",
			"Answers": ["Eine Gruppe von 8 Bits", "Englisch für das Wort Biss", "Eine Computer Komponente", "Eine Node in GODOT"],
			"Correct": 0
		},
		9: {
			"Question": "Welches Zahlensystem benutzen Menschen normalerweise?",
			"Answers": ["Hexadezimal", "Dual", "Octal", "Dezimal"],
			"Correct": 3
		}
	}

## Chooses a new random question to return
## The last question asked is not included in the question pool
## Returns the first question of the question dictionary for fallback
func get_random_question(manager: BiggameHSDCampus) -> Dictionary:
	var valid_questions: Array[Dictionary] = []
	
	for question: Dictionary in question_dic.values():
		if not question == manager.get_last_question():
			valid_questions.append(question)

	if valid_questions.size() > 0:
		var chosen_question: Dictionary = valid_questions[rng.randi() % valid_questions.size()]
		manager.set_last_question(chosen_question)
		return chosen_question
	
	return question_dic[0]
