extends AudioStreamPlayer

var music: AudioStream = preload("res://assets/music/hsdparty_board.ogg")
const FADE_IN_DURATION: float = 0.75
const FADE_OUT_DURATION: float = 1.25

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	stream = music
	play()
	
func fade_in() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "volume_db", -11.0, FADE_IN_DURATION)
	tween.set_ease(Tween.EASE_OUT)

func fade_out() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "volume_db", -80.0, FADE_OUT_DURATION)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: stop())
