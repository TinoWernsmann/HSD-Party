extends MinigamePong_AIPlayerBrain
class_name MinigamePong_HardAIPlayerBrain

func _aim_pos() -> float:
	if pong.balls.size() == 0:
		return 0
	var selected_y: float = 0
	var shortest_time: float = 1000
	var sum: float = 0
	var division: float = 0
	for ball: MinigamePong_Ball in pong.balls:
		var local_pos: Vector2 = player_parent.to_local(ball.global_position)
		var sum_impact: float = 1/abs(local_pos.x)
		sum = sum + local_pos.y * sum_impact
		division = division + sum_impact
		var local_velocity: Vector2 = ball.velocity.rotated(-player.global_rotation)
		var t: float = -local_pos.x / local_velocity.x
		if t > 0 && t < shortest_time:
			var local_y: float = local_pos.y + local_velocity.y * t
			if local_y < player.paddle_range + 100 && local_y > -player.paddle_range -100:
				selected_y = local_y
				shortest_time = t

	if shortest_time == 1000:
		return sum / division
	return selected_y


func _input_time() -> float:
	return 150

func _aim_time() -> float:
	return 600
