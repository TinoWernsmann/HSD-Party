extends AudioStreamPlayer
class_name BiggameHSDCampus_AudioManager

func play_tile_sound(sound: AudioStream) -> void:
	stream = sound
	play()

func play_music(music: AudioStream) -> void:
	stream = music
	play()

func stop_music() -> void:
	stop()
