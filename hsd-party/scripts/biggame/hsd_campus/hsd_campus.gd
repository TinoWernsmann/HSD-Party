extends BigGameBase
class_name BiggameHSDCampus

enum State {
	PLAYGOUND,
	MINIGAME_INSTRUCTION,
	MINIGAME,
	ENDSCREEN
}

# Einstellungen speziell für HSD_Campus
class BiggameHSDCampusSettings:
	extends BiggameManager.BiggameSettings
	var max_rounds: int = 4
	var debug_minigames: bool = false
	var debug_cheats: bool = false

@export_subgroup("Scenes")
@export var minigame_instruction_scene: PackedScene
@export var ending_screen_scene: PackedScene

@export_subgroup("Game Nodes")
@export var game_manager: BiggameHSDCampus_GameManager
@export var playground: Node3D

var state: State = State.PLAYGOUND
var hsd_campus_settings: BiggameHSDCampusSettings

var not_played_possible_minigames: Array[MinigameInfo] = []
var current_minigame_info: MinigameInfo = null

var current_minigame: MinigameBase = null
var current_minigame_instruction: MinigameInstruction = null
var endscreen: BiggameHSDCampus_EndingScreen = null

var last_question: Dictionary
var current_round: int = 1

func set_settings(_biggame_settings: BiggameManager.BiggameSettings) -> void:
	if(_biggame_settings is BiggameHSDCampusSettings):
		hsd_campus_settings = _biggame_settings

func start() -> void:
	playground.visible = true
	game_manager.set_disabled(false)
	game_manager.start()

func get_last_question() -> Dictionary:
	return last_question

func set_last_question(question: Dictionary) -> void:
	last_question = question

func get_round_count() -> int:
	return current_round

func increase_round_count() -> void:
	current_round += 1

func check_game_over() -> bool:
	return current_round >= hsd_campus_settings.max_rounds

func play_minigame() -> void:
	if not_played_possible_minigames.size() == 0:
		_fill_minigame_pool()
	var random_index: int = randi() % not_played_possible_minigames.size()
	current_minigame_info = not_played_possible_minigames[random_index]
	not_played_possible_minigames.remove_at(random_index)
	current_minigame_instruction = minigame_instruction_scene.instantiate() as MinigameInstruction
	current_minigame_instruction.setup(current_minigame_info, game_room_manager, self)
	current_minigame_instruction.set_game_data(MinigameBase.FFAGameData.new(player_information))
	playground.visible = false
	game_manager.set_disabled(true)
	add_child(current_minigame_instruction)
	state = State.MINIGAME_INSTRUCTION

func finish_game(_player: Array[int]) -> void:
	state = State.ENDSCREEN
	playground.queue_free()
	endscreen = ending_screen_scene.instantiate()
	var player_info_ordered: Array[GameRoomManagerBase.PlayerInformation] = []
	for i: int in _player:
		player_info_ordered.append(player_information[i])
	endscreen.setup(player_info_ordered,self)
	add_child(endscreen)

func minigame_instruction_ready(_game_data: MinigameBase.GameData) -> void:
	current_minigame_instruction.queue_free()
	current_minigame = current_minigame_info.level.instantiate() as MinigameBase
	current_minigame.setup(game_room_manager, self)
	current_minigame.set_game_data(_game_data)
	add_child(current_minigame)
	current_minigame.start_minigame()
	state = State.MINIGAME

func finish_minigame(result: MinigameBase.MinigameResult) -> void:
	current_minigame.queue_free()
	playground.visible = true
	game_manager.set_disabled(false)
	game_manager.enable_player_input()
	game_manager.enable_player_input()
	game_manager.minigame_done(result)
	state = State.PLAYGOUND

func finish_endscreen() -> void:
	game_room_manager.biggame_done()

func _fill_minigame_pool() -> void:
	not_played_possible_minigames = game_room_manager.minigame_infos() 
	not_played_possible_minigames = MinigameManager.filter_minigames(game_room_manager.minigame_infos(),
		MinigameManager.PlayerInfoFilter.new(player_information),
		)
	not_played_possible_minigames = MinigameManager.filter_minigames(game_room_manager.minigame_infos(),
		MinigameManager.DebugFilter.new(hsd_campus_settings.debug_minigames),
		)	

func pause() -> void:
	if state == State.MINIGAME:
		current_minigame.pause()
	elif state == State.MINIGAME_INSTRUCTION:
		current_minigame_instruction.pause()
	elif state == State.ENDSCREEN:
		pass
	elif state == State.PLAYGOUND:
		playground.process_mode = Node.PROCESS_MODE_DISABLED

func resume() -> void:
	if state == State.MINIGAME:
		current_minigame.resume()
	elif state == State.MINIGAME_INSTRUCTION:
		current_minigame_instruction.resume()
	elif state == State.ENDSCREEN:
		pass
	elif state == State.PLAYGOUND:
		playground.process_mode = Node.PROCESS_MODE_INHERIT
