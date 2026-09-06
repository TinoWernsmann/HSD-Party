extends Resource
class_name ControllerManager

@export var controller_definitions: Array[ControllerDefinition]:
	set(value):
		controller_definitions = value
		_update_controller_definition_ids()

static var instance: ControllerManager
const CONTROLLER_MANAGER_RESSOURCE: String = "res://ressources/controller_manager.tres"

func _update_controller_definition_ids() -> void:
	for i: int in controller_definitions.size():
		if controller_definitions[i]:
			controller_definitions[i].id = i

static func get_amount_of_available_controller() -> int:
	return _get_instance().controller_definitions.size()

static func get_controller_definition_by(_id: int) -> ControllerDefinition:
	return _get_instance().controller_definitions[_id]

static func _get_instance() -> ControllerManager:
	if instance == null:
		instance = load(CONTROLLER_MANAGER_RESSOURCE)
	return instance
