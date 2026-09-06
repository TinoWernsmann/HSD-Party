extends Resource
class_name ControllerDefinition

enum Buttons {
	BUTTON_1,
	BUTTON_2,
	BUTTON_3,
	BUTTON_4,
	PAUSE,
	GAMELESS_INTERACT
}

enum Axis {
	HORIZONTAL,
	VERTICAL
}

var id: int

@export var icon: Texture2D

@export var button_inputs: Dictionary[Buttons, ButtonInput] = {
	Buttons.BUTTON_1: ButtonInput.new(), 
	Buttons.BUTTON_2:  ButtonInput.new(), 
	Buttons.BUTTON_3:  ButtonInput.new(), 
	Buttons.BUTTON_4:  ButtonInput.new(), 
	Buttons.PAUSE:  ButtonInput.new(), 
	Buttons.GAMELESS_INTERACT:  ButtonInput.new()
	}
@export var axis_inputs: Dictionary[Axis, AxisInputs] = {
	Axis.HORIZONTAL: AxisInputs.new(), 
	Axis.VERTICAL: AxisInputs.new()
	}

func get_axis_input(axis: Axis) -> AxisInputs:
	return axis_inputs[axis]

func get_button_input(button: Buttons) -> ButtonInput:
	return button_inputs[button]
