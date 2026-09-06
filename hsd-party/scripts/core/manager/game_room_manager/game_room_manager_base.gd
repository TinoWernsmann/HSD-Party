extends Node
class_name GameRoomManagerBase

# 
# GameRooms sind die Grundlage aller Spiele. In einem Gameroom findet die Spielerverwaltung statt.
# GameRooms erstellen
#

# Objects/Scenes
const GAME_ROOM_MENU_SCENE: PackedScene = preload("res://scenes/object/core/ui_elements/game_room_menu.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/object/core/ui_elements/pause_menu.tscn")

# Parent Refs
var main_manager: MainManager

# Managed Childs
var game_room_menu_controller: GameRoomMenuController
var pause_menu_controller: PauseMenuConttroller
var biggame_settings: BiggameSettingsController
var biggame: BigGameBase

# State
class PlayerInformation:
	var player_nr: int
	var character_id: int

	func character_info() -> CharacterInfo:
		return CharacterManager.get_character_by(character_id)

	static func create_from_last(_last_player_information: PlayerInformation, _player_nr: int) -> PlayerInformation:
		return null
	
class OnlineClientPlayerInformation:
	extends PlayerInformation
	var peer_id: int
	
	static func create_from_last(_last_player_information: PlayerInformation, _player_nr: int) -> OnlineClientPlayerInformation:
		var new_player_information: OnlineClientPlayerInformation = OnlineClientPlayerInformation.new()
		new_player_information.player_nr = _player_nr
		if _last_player_information != null:
			new_player_information.character_id = _last_player_information.character_id
		return new_player_information
		
class ThisClientPlayerInformation:
	extends PlayerInformation
	
	var controller_id: int
	
	static func create_from_last(_last_player_information: PlayerInformation, _player_nr: int) -> ThisClientPlayerInformation:
		var new_player_information: ThisClientPlayerInformation = ThisClientPlayerInformation.new()
		new_player_information.player_nr = _player_nr
		if _last_player_information != null:
			new_player_information.character_id = _last_player_information.character_id
		return new_player_information

class AIPlayerInformation:
	extends PlayerInformation
	
	enum AIDifficulty{
		EASY = 0,
		MEDIUM = 1, 
		HARD = 2
	}
	
	var difficulty: AIDifficulty = AIDifficulty.EASY
	
	func difficulty_text() -> String:
		match difficulty:
			AIDifficulty.EASY:
				return "Schwach"
			AIDifficulty.MEDIUM:
				return "Mittel"
			AIDifficulty.HARD:
				return "Stark"
		return "Error"
	
	static func create_from_last(_last_player_information: PlayerInformation, _player_nr: int) -> AIPlayerInformation:
		var new_player_information: AIPlayerInformation = AIPlayerInformation.new()
		new_player_information.player_nr = _player_nr
		if _last_player_information != null:
			new_player_information.character_id = _last_player_information.character_id
		return new_player_information
	
class State:
	pass

class GameSelectionState:
	extends State
	
class GameSelectionSettingsState:
	extends State
	var biggame_id: int
	
	func _init(_biggame_id: int) -> void:
		self.biggame_id = _biggame_id

class GameState:
	extends State
	var paused: bool = false
	var biggame_id: int
	func _init(_biggame_id: int) -> void:
		self.biggame_id = _biggame_id

# State des GameRooms
var state: State
var player_information: Array[PlayerInformation] = [null, null, null, null]

func setup(_main_manager: MainManager) -> void:
	self.main_manager = _main_manager

func _ready() -> void:
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.name = "GameRoomCanvas"
	canvas_layer.layer = 1000
	add_child(canvas_layer)
	game_room_menu_controller = GAME_ROOM_MENU_SCENE.instantiate()
	game_room_menu_controller.setup(self, _biggame_infos())
	canvas_layer.add_child(game_room_menu_controller, true)
	game_room_menu_controller.show_biggame_selection()	
	for i: int in player_information.size():
		game_room_menu_controller.update_player_info(i,player_information[i])

	pause_menu_controller = PAUSE_MENU_SCENE.instantiate()
	pause_menu_controller.setup(self)
	canvas_layer.add_child(pause_menu_controller, true)
	pause_menu_controller.visible = false

func _process(_delta: float) -> void:
	var no_human_player: bool = true
	if state is GameState:
		for x: PlayerInformation in player_information:
			if x is ThisClientPlayerInformation:
				no_human_player = false
				if input_is_just_pressed(x.player_nr, ControllerDefinition.Buttons.PAUSE):
					if (state as GameState).paused:
						pause_resume_pressed(x.player_nr)
					else:
						pause_pressed(x.player_nr)
			if x is OnlineClientPlayerInformation:
				no_human_player = false
		if no_human_player:
			if Input.is_action_just_pressed("escape"):
				if (state as GameState).paused:
					pause_resume_pressed(-1)
				else:
					pause_pressed(-1)

# --------------------
#    Hilfsmethoden
# --------------------

func get_actual_player_info() -> Array[GameRoomManagerBase.PlayerInformation]:
	var final_player_infos: Array[GameRoomManagerBase.PlayerInformation] = []
	for p_info: GameRoomManagerBase.PlayerInformation in player_information:
		if p_info != null:
			final_player_infos.append(p_info)
	return final_player_infos

func _biggame_infos() -> Array[BiggameInfo]:
	printerr("Unimplemented sync methode")
	return []

func minigame_infos() -> Array[MinigameInfo]:
	printerr("Unimplemented sync methode")
	return []

# Testet ob der Client, welche die Anfrage stellt der Host ist. 
# Offline immer true. 
# Online Server, wenn der RequestClient der Host ist.
# Online Client, wenn der Client der Host ist.
func is_host() -> bool:
	return true

func is_online() -> bool:
	return false

# Ruft _callable mit allen peer_ids in diesem raum auf.
func call_all_other_peers_in_gameroom(_callable: Callable) -> void:
	printerr("call_all_other_peers_in_gameroom is a online only methode")
	pass

# Ruft _callable mit allen peer_ids in diesem raum auf.
func call_all_peers_in_gameroom(_callable: Callable) -> void:
	printerr("call_all_peers_in_gameroom is a online only methode")
	pass
# --------------------
#    öffentliche Methoden
# --------------------
func dissconnect() -> void:
	pass

func pause_pressed(_player_nr: int) -> void:
	pass

func pause_resume_pressed(_player_nr: int) -> void:
	pass

func leave_game_pressed() -> void:
	pass

func back() -> void:
	pass

func select_biggame(_biggame_id: int) -> void:
	pass
	
func finish_biggame_settings(_biggame_id: int, _biggame_settings: BiggameManager.BiggameSettings) -> void:
	pass

func open_player_information(_player_nr:int) -> void:
	pass

func player_settings_change_character(_player_nr: int, _change: int) -> void:
	pass

func player_settings_change_control(_player_nr: int, _change: int) -> void:
	pass
	
func player_settings_change_client(_player_nr: int, _change: int) -> void:
	pass

func player_settings_change_difficulty(_player_nr: int, _change: int) -> void:
	pass
	
func player_settings_done() -> void:
	pass

func biggame_done() -> void:
	pass

func input_is_pressed(player_nr: int, button: ControllerDefinition.Buttons) -> bool:
	if player_information[player_nr] is ThisClientPlayerInformation:
		var controller_id: int = (player_information[player_nr] as ThisClientPlayerInformation).controller_id
		var controller_definition: ControllerDefinition = ControllerManager.get_controller_definition_by(controller_id)
		return Input.is_action_pressed(controller_definition.get_button_input(button).action)
	else:
		printerr("Input requested for non-local player ", player_nr)
	return false

func input_is_just_pressed(player_nr: int, button: ControllerDefinition.Buttons) -> bool:
	if player_information[player_nr] is ThisClientPlayerInformation:
		var controller_id: int = (player_information[player_nr] as ThisClientPlayerInformation).controller_id
		var controller_definition: ControllerDefinition = ControllerManager.get_controller_definition_by(controller_id)
		return Input.is_action_just_pressed(controller_definition.get_button_input(button).action)
	else:
		printerr("Input requested for non-local player ", player_nr)
	return false
	
func input_get_axis(player_nr: int, axis: ControllerDefinition.Axis) -> float:
	if player_information[player_nr] is ThisClientPlayerInformation:
		var controller_id: int = (player_information[player_nr] as ThisClientPlayerInformation).controller_id
		var controller_definition: ControllerDefinition = ControllerManager.get_controller_definition_by(controller_id)
		var axis_inputs: AxisInputs = controller_definition.get_axis_input(axis)
		return Input.get_axis(axis_inputs.neg, axis_inputs.pos)
	else:
		printerr("Input requested for non-local player ", player_nr)
	return 0.0
