extends MinigamePong_AIPlayerBrain
class_name MinigamePong_EasyAIPlayerBrain

func _input_time() -> float:
	return 300

func _aim_time() -> float:
	return 900

var last_selected_ball: MinigamePong_Ball

func _aim_pos() -> float:
	if pong.balls.size() == 0:
		return 0
	if last_selected_ball == null || rng.randf() > 0.85:
		var weights: Array[float] = []
		for ball: MinigamePong_Ball in pong.balls:
			weights.append(player_parent.to_local(ball.global_position).y + 1500)
		last_selected_ball = pong.balls[rand_weighted_index(weights)]
	return player_parent.to_local(last_selected_ball.global_position).y + rng.randf() * 30

func rand_weighted_index(weights: Array[float]) -> int:
	var sum: float = weights.reduce(func(a: float, b: float) -> float: return a + b)
	var r: float = rng.randf() * sum
	var acc: float = 0.0

	for i: int in weights.size():
		acc += weights[i]
		if r <= acc:
			return i
	return weights.size() - 1