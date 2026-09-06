extends Control
class_name HSDPartyMenuController

var hsd_party: HSDPartyManager
@export var blur_color_rect: ColorRect
@export var start_screnn_content_apear_time: float
@export var start_screnn_content: Container
@export var hsd_label_apear_time: float
@export var hsd_label: TextureRect
@export var party_label_apear_time: float
@export var party_label: TextureRect

var time: float
@onready var main_menu_music: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	start_screnn_content.visible = false
	(blur_color_rect.material as ShaderMaterial).set_shader_parameter("amount", 0)
	hsd_label.visible = false
	party_label.visible = false

func _process(delta: float) -> void:
	time += delta
	if time > start_screnn_content_apear_time:
		start_screnn_content.visible = true
	else: 
		if time + 1 > start_screnn_content_apear_time:
			(blur_color_rect.material as ShaderMaterial).set_shader_parameter("amount", time -start_screnn_content_apear_time+1)
		if time > hsd_label_apear_time:
			hsd_label.visible = true
		if time > party_label_apear_time:
			party_label.visible = true

func _on_offline_button_pressed() -> void:
	hsd_party.start_offline()
	main_menu_music.stop()
	
func _on_online_button_pressed() -> void:
	hsd_party.start_online()
	main_menu_music.stop()
