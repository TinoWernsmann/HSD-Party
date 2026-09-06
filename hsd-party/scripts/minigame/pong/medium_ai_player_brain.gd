extends MinigamePong_AIPlayerBrain
class_name MinigamePong_MediumAIPlayerBrain

var last_selected_ball: MinigamePong_Ball

func _aim_pos() -> float:
	if pong.balls.size() == 0:
		return 0
	if last_selected_ball == null || rng.randf() > 0.6:
		var selected_ball: MinigamePong_Ball = null
		var pos_selected_ball: Vector2
		for ball: MinigamePong_Ball in pong.balls:
			var local_pos: Vector2 = player_parent.to_local(ball.global_position)
			var local_velocity: Vector2 = ball.velocity.rotated(-player.global_rotation)
			if selected_ball == null || local_pos.x > pos_selected_ball.x && local_velocity.x > 0:
				pos_selected_ball = local_pos
				selected_ball = ball
		last_selected_ball = selected_ball
	return player_parent.to_local(last_selected_ball.global_position).y


func _input_time() -> float:
	return 250

func _aim_time() -> float:
	return 800
