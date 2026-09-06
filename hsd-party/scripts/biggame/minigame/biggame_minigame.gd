extends BigGameBase
class_name BiggameMinigame

@export var minigame_instruction_scene: PackedScene
@export var end_screen_scene: PackedScene

class BiggameMinigameSettings:
	extends BiggameManager.BiggameSettings
	var minigame_id: int

	var game_data: MinigameBase.GameData

	func _init(_minigame_id: int, _game_data:  MinigameBase.GameData) -> void:
		self.minigame_id = _minigame_id
		self.game_data = _game_data

#State
enum State{
	MINIGAME = 0,
	INSTRUCTION = 1,
	WINNING_SCREEN = 2
}
var state: State = State.INSTRUCTION
var paused: bool = false

var biggame_minigame_settings: BiggameMinigameSettings

var minigame_instruction: MinigameInstruction
var minigame: MinigameBase
var endscreen: BiggameMinigame_Endscreen

func _ready() -> void:
	if game_room_manager.is_online() && !multiplayer.is_server():
		request_sync_server_rpc.rpc_id(1)

# --------------------
#    ServerMethoden
# --------------------

@rpc("any_peer", "call_remote", "reliable")
func request_sync_server_rpc() -> void:
	_set_state_client_rpc.rpc_id(multiplayer.get_remote_sender_id(), state, biggame_minigame_settings.minigame_id)

func set_settings(_biggame_settings: BiggameManager.BiggameSettings) -> void:
	if(_biggame_settings is BiggameMinigameSettings):
		biggame_minigame_settings = _biggame_settings

func start() -> void:
	if !game_room_manager.is_online() || multiplayer.is_server():
		minigame_instruction = minigame_instruction_scene.instantiate()
		minigame_instruction.setup(MinigameManager.get_minigame_by(biggame_minigame_settings.minigame_id), game_room_manager, self)
		minigame_instruction.set_game_data(biggame_minigame_settings.game_data)
		add_child(minigame_instruction, true)

func minigame_instruction_ready(_game_data: MinigameBase.GameData) -> void:
	if !game_room_manager.is_online() || multiplayer.is_server():
		state = State.MINIGAME
		minigame_instruction.queue_free()
		minigame = MinigameManager.get_minigame_by(biggame_minigame_settings.minigame_id).level.instantiate()
		minigame.setup(game_room_manager, self)
		minigame.set_game_data(_game_data)
		add_child(minigame, true)
		if game_room_manager.is_online():
			game_room_manager.call_all_peers_in_gameroom(
				func (peer_id: int) -> void:
					_set_state_client_rpc.rpc_id(peer_id, state, biggame_minigame_settings.minigame_id)	
			)
		else:
			_set_state_client_rpc(state, biggame_minigame_settings.minigame_id)	
		minigame.start_minigame()

func finish_minigame(_result: MinigameBase.MinigameResult) -> void:
	if !game_room_manager.is_online() || multiplayer.is_server():
		state = State.WINNING_SCREEN
		minigame.queue_free()
		endscreen = end_screen_scene.instantiate()
		endscreen.setup(self,game_room_manager)
		endscreen.set_restul(_result)
		add_child(endscreen, true)
		if game_room_manager.is_online():
			game_room_manager.call_all_peers_in_gameroom(
				func (peer_id: int) -> void:
					_set_state_client_rpc.rpc_id(peer_id, state, biggame_minigame_settings.minigame_id)	
			)
		else:
			_set_state_client_rpc(state, biggame_minigame_settings.minigame_id)	
		

func minigame_endscreen_finished() -> void:
	if !game_room_manager.is_online() || multiplayer.is_server():
		game_room_manager.biggame_done()

# --------------------
#    ClientMethoden
# --------------------

@rpc("authority", "call_remote", "reliable")
func _set_state_client_rpc(_state: State, minigame_id: int) -> void:
	self.state = _state
	if state == State.INSTRUCTION:
		if minigame_instruction == null:
			minigame_instruction = minigame_instruction_scene.instantiate()
			minigame_instruction.setup(MinigameManager.get_minigame_by(minigame_id), game_room_manager, self)
			add_child(minigame_instruction, true)
		if minigame != null:
			minigame.queue_free()
			minigame = null
		if endscreen != null:
			endscreen.queue_free()
	elif state == State.MINIGAME:
		if minigame == null:
			minigame = MinigameManager.get_minigame_by(minigame_id).level.instantiate()
			minigame.setup(game_room_manager, self)
			add_child(minigame, true)
		if minigame_instruction != null:
			minigame_instruction.queue_free()
			minigame_instruction = null
		if endscreen != null:
			endscreen.queue_free()
	elif state == State.WINNING_SCREEN:
		if endscreen == null:
			endscreen = end_screen_scene.instantiate()
			endscreen.setup(self,game_room_manager)
			add_child(endscreen, true)
		if minigame_instruction != null:
			minigame_instruction.queue_free()
			minigame_instruction = null
		if minigame != null:
			minigame.queue_free()
			minigame = null

func pause() -> void:
	paused = true
	if state == State.INSTRUCTION:
		minigame_instruction.pause()
	elif state == State.MINIGAME:
		minigame.pause()
	elif state == State.WINNING_SCREEN:
		endscreen.pause()

func resume() -> void:
	paused = false
	if state == State.INSTRUCTION && minigame_instruction != null:
		minigame_instruction.resume()
	elif state == State.MINIGAME && minigame != null:
		minigame.resume()
	elif state == State.WINNING_SCREEN && endscreen != null:
		endscreen.resume()
