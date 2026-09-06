extends StaticBody2D
class_name MinigamePong_GoalCollider

@export var goal: MinigamePong_Goal

func collide(_ball: MinigamePong_Ball, _col: KinematicCollision2D) -> void:
	goal.score(_ball, _col)
