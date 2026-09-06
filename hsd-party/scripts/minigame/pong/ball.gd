extends CharacterBody2D
class_name MinigamePong_Ball

const MAX_SPEED: float = 20.0
const START_SPEED: float = 5.0
const ACCELERATION: float = 2.0
var current_speed: float

var start_direction: Vector2

func _ready() -> void:
	current_speed = START_SPEED
	velocity = start_direction.normalized() * current_speed

func _physics_process(_delta: float) -> void:
	var col: KinematicCollision2D = move_and_collide(velocity)
	if col:
		var collider: Object = col.get_collider()
		if collider is MinigamePong_Player:
			current_speed = min(current_speed + ACCELERATION, MAX_SPEED)
		elif collider is MinigamePong_GoalCollider:
			(collider as MinigamePong_GoalCollider).collide(self, col)
		var normal: Vector2 = col.get_normal()		
		if collider is MinigamePong_Ball:
			var other_ball: MinigamePong_Ball = collider as MinigamePong_Ball
			other_ball.velocity = other_ball.velocity.normalized().bounce(-normal) * other_ball.current_speed
		velocity = velocity.normalized().bounce(normal) * current_speed