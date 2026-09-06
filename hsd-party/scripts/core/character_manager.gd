extends Resource
class_name CharacterManager

@export var available_character: Array[CharacterInfo]:
	set(value):
		available_character = value
		_update_character_ids()
		
static var instance: CharacterManager
const CHARACTER_MANAGER_RESSOURCE: String = "res://ressources/character_manager.tres"	

func _update_character_ids() -> void:
	for i: int in available_character.size():
		if available_character[i]:
			available_character[i].id = i

static func get_amount_of_available_character() -> int:
	return _get_instance().available_character.size()

static func get_character_by(_id: int) -> CharacterInfo:
	return _get_instance().available_character[_id]

static func _get_instance() -> CharacterManager:
	if instance == null:
		instance = load(CHARACTER_MANAGER_RESSOURCE)
	return instance
