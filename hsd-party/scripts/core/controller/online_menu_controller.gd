extends Control
class_name OnlineMenuController

@export var room_id_input: LineEdit
@export var host_button: Button
@export var join_button: Button
@export var info_label: Label

var multiplayer_manager: OnlineMainManager

func connecting() -> void:
	_disable()
	info_label.text = "Verbindungsaufbau..."

func connected() -> void:
	_enable()
	info_label.text = "Verbunden"

func connection_failed() -> void:
	_disable()
	info_label.text = "Verbindung fehlgeschlagen"

func _enable() -> void:
	host_button.disabled = false
	join_button.disabled = false
	room_id_input.editable = true

func _disable() -> void:
	host_button.disabled = true
	join_button.disabled = true
	room_id_input.editable = false


func _on_start_game_as_host_pressed() -> void:
	multiplayer_manager.create_room()

func _on_join_game_pressed() -> void:
	multiplayer_manager.join_room(room_id_input.text)

func _on_back_pressed() -> void:
	multiplayer_manager.back_to_main_menu()
