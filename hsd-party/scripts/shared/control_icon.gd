extends TextureRect
class_name ControlIcon

#
# 1. Setze mit set_controller_ids oder set_controller_ids_from_player_information die ids von den Controllern, dessen Steuerung angezeigt werden soll
# 2. Setze mit show_button oder show_axis den Input, welcher angezeigt werden soll
#

@export var texture_rect: TextureRect

enum State{
	BUTTON,
	AXIS
}

var state: State

var controller_ids: Array[int]

var image_counter: int = 0
var last_timestamp: int

var button: ControllerDefinition.Buttons
var axis: ControllerDefinition.Axis

func _ready() -> void:
	last_timestamp = Time.get_ticks_msec()

func show_button(_button: ControllerDefinition.Buttons) -> void:
	button = _button
	state = State.BUTTON
	_render_image()

func show_axis(_axis: ControllerDefinition.Axis) -> void:
	axis = _axis
	state = State.AXIS
	_render_image()

# Setzt die Controller ids, für alle Spieler, welche auf diesem Gerät am Spielen sind.
# returned true, wenn mindesten ein Spieler auf diesem Gerät spielt und daher einen Input benötigt. 
func set_controller_ids_from_player_information(_player_information: Array[GameRoomManagerBase.PlayerInformation]) -> bool:
	controller_ids = []
	for x: GameRoomManagerBase.PlayerInformation in _player_information:
		if x is GameRoomManagerBase.ThisClientPlayerInformation:
			if not controller_ids.has((x as GameRoomManagerBase.ThisClientPlayerInformation).controller_id):
				controller_ids.append((x as GameRoomManagerBase.ThisClientPlayerInformation).controller_id)
	_render_image()
	return controller_ids.size() > 0

func set_controller_ids(_controller_ids: Array[int]) -> void:
	controller_ids = []
	for x: int in _controller_ids:
		if not controller_ids.has(x):
			controller_ids.append(x)
	_render_image()

func _process(_delta: float) -> void:
	if last_timestamp + 2000 < Time.get_ticks_msec():
		last_timestamp = Time.get_ticks_msec()
		image_counter = image_counter + 1
		_render_image()
	
func _render_image() -> void:
	if controller_ids.size() > 0:
		if state == State.BUTTON:
			texture_rect.texture = ControllerManager.get_controller_definition_by(controller_ids[image_counter%controller_ids.size()]).get_button_input(button).icon
		else:
			texture_rect.texture = ControllerManager.get_controller_definition_by(controller_ids[image_counter%controller_ids.size()]).get_axis_input(axis).icon
