extends MinigameBase
class_name DebugMinigame

enum GameState{
    PLAYING,
    SHOW_WINNER_MESSAGE,
    RESETTING
}

class Player:
    var id: int
    var player: Variant # PlayerInformation or Team
    var points: int = 0
    var panel_controller: DebugMinigame_PlayerInputPanelController
    func _init(_player: Variant, _panel_controller: DebugMinigame_PlayerInputPanelController, _id: int) -> void:
        self.player = _player
        self.panel_controller = _panel_controller
        self.id = _id

@export var player_input_panel_scene: PackedScene
@export var player_input_panel_container: HBoxContainer

@export var winning_message_container: Container
@export var winning_player_container: HBoxContainer

@export var reset_panel: PanelContainer

var game_state: GameState = GameState.PLAYING
var player_list: Array[Player] = []
var instruction: bool = false

var message: Array[String] = []
var player_nr: Array[int] = []

var timestamp_reset_start: float = 0.0
var timestamp_winning_message_start: float = 0.0

func _ready() -> void:
    if game_room_manager.is_online() && !multiplayer.is_server():
        _request_sync_server_rpc.rpc_id(1)
    _set_state_playing()

# --------------------
#    ServerMethoden
# --------------------

func _on_sync() -> void:
    var points: Array[int] = []
    for x: Player in player_list:
        points.append(x.points)
    _set_player.rpc_id(multiplayer.get_remote_sender_id(), points)
    if game_state == GameState.PLAYING:
        _set_state_playing.rpc_id(multiplayer.get_remote_sender_id())
    if game_state == GameState.SHOW_WINNER_MESSAGE:
        _set_state_winning_screen.rpc_id(multiplayer.get_remote_sender_id(), message, player_nr)
    
func start_minigame() -> void:
    _start()

func start_instruction_preview_minigame() -> void:
    instruction = true
    _start()

func _start() -> void:
    var points: Array[int] = []
    for x: Player in player_list:
        points.append(0)
    _set_player(points)

func _process(_delta: float) -> void:
    if game_room_manager.is_online() && !multiplayer.is_server():
        return
    if game_state == GameState.RESETTING:
        if Time.get_ticks_msec() - timestamp_reset_start > 500:
            if game_room_manager.is_online():
                game_room_manager.call_all_peers_in_gameroom(
                    func (peer_id: int) -> void:
                        _set_state_playing.rpc_id(peer_id)
                )
            else:
                _set_state_playing()
            game_state = GameState.PLAYING
            var points: Array[int] = []
            for x: Player in player_list:
                x.points = 0
                points.append(0)
            if game_room_manager.is_online():
                game_room_manager.call_all_peers_in_gameroom(
                    func (peer_id: int) -> void:
                        _set_player.rpc_id(peer_id, points)
                )
            else:
                _set_player(points)
    elif game_state == GameState.SHOW_WINNER_MESSAGE:
        if Time.get_ticks_msec() - timestamp_winning_message_start > 2000:
            game_state = GameState.RESETTING
            timestamp_reset_start = Time.get_ticks_msec() 
            if game_room_manager.is_online():
                game_room_manager.call_all_peers_in_gameroom(
                    func (peer_id: int) -> void:
                        _set_state_resetting.rpc_id(peer_id)
                )
            else:
                _set_state_resetting()

@rpc("any_peer", "call_remote", "reliable")
func _change_point_server_rpc(player_id: int, change: int) -> void: 
    if game_room_manager.is_host():
        player_list[player_id].points += change
        var points: Array[int] = []
        for x: Player in player_list:
            points.append(x.points)
        if game_room_manager.is_online():
            game_room_manager.call_all_peers_in_gameroom(
                func (peer_id: int) -> void:
                    _set_player.rpc_id(peer_id, points)
            )
        else:
            _set_player(points)


@rpc("any_peer", "call_remote", "reliable")
func _finish_server_rpc() -> void: 
    var game_result: MinigameBase.MinigameResult = _create_game_result()
    if instruction:
        _winning_screen(game_result)
    else:
        biggame_base.finish_minigame(game_result)

func _create_game_result() -> MinigameBase.MinigameResult:
    var sorted_player_list: Array[Player] = player_list.duplicate()
    sorted_player_list.sort_custom(
    func(a: Player, b: Player) -> bool:
        return a.points > b.points
    )
    var result: MinigameBase.MinigameResult = game_data.create_result()
    var current_points: int = sorted_player_list[0].points
    var place: int = 1
    for i: int in sorted_player_list.size():
        var player: Player = sorted_player_list[i]
        if player.points < current_points:
            place += 1
            current_points = player.points
        result.add_to_place(player.player, place)
    return result

func _winning_screen(game_result: MinigameResult ) -> void:
    timestamp_winning_message_start = Time.get_ticks_msec()
    game_state = GameState.SHOW_WINNER_MESSAGE
    for child: Node in winning_player_container.get_children():
        child.queue_free()
    message.clear()
    player_nr.clear()
    if game_result is TeamResults:
        var team_result: TeamResults = game_result as TeamResults
        if team_result.places.size() == 1:
            message.append("Unentschieden!")
            player_nr.append(-1)
        else:
            message.append("Gewinner sind:")
            player_nr.append(-1)
            for x: GameRoomManagerBase.PlayerInformation in team_result.places[0].teams[0].players:
                message.append("Spieler " + str(x.player_nr))
                player_nr.append(x.player_nr)
    elif game_result is FFAResult:
        var ffa_result: FFAResult = game_result as FFAResult
        if ffa_result.places.size() == 1:
            message.append("Unentschieden!")
            player_nr.append(-1)
        else:
            message.append("Gewonnen hat:")
            player_nr.append(-1)
            for x: GameRoomManagerBase.PlayerInformation in ffa_result.places[0].players:
                message.append("Spieler " + str(x.player_nr))
                player_nr.append(x.player_nr)
    if game_room_manager.is_online():
        game_room_manager.call_all_peers_in_gameroom(
            func (peer_id: int) -> void:
                _set_state_winning_screen.rpc_id(peer_id, message, player_nr)
        )
    else:
        _set_state_winning_screen(message, player_nr)


# --------------------
#    ClientMethoden
# --------------------

@rpc("authority", "call_remote", "reliable")
func _set_player(points: Array[int]) -> void:
    if player_list.size() > 0:
        for i: int in  game_data.all_game_entities().size():
            player_list[i].points = points[i]
            player_list[i].panel_controller.set_points(points[i])
    else:
        for i: int in  game_data.all_game_entities().size():
            var panel_instance: DebugMinigame_PlayerInputPanelController = player_input_panel_scene.instantiate()
            var new_player: Player = Player.new(game_data.all_game_entities()[i], panel_instance, i)
            panel_instance.setup(new_player, self)
            player_list.append(new_player)
            player_input_panel_container.add_child(panel_instance)

@rpc("authority", "call_remote", "reliable")
func _set_state_playing() -> void:
    game_state = GameState.PLAYING
    reset_panel.visible = false
    winning_message_container.visible = false

@rpc("authority", "call_remote", "reliable")
func _set_state_winning_screen(_message: Array[String], player_nr_collor: Array[int]) -> void:
    game_state = GameState.SHOW_WINNER_MESSAGE
    reset_panel.visible = false
    winning_message_container.visible = true
    for x: Node in winning_player_container.get_children():
        x.queue_free()
    for i: int in _message.size():
        var player_label: Label = Label.new()
        player_label.text = _message[i]
        if player_nr_collor[i] > -1:
            player_label.modulate = game_room_manager.player_information[player_nr_collor[i]].character_info().character_color
        winning_player_container.add_child(player_label)

@rpc("authority", "call_remote", "reliable")
func _set_state_resetting() -> void:
    game_state = GameState.RESETTING
    reset_panel.visible = true

func _after_sync_client() -> void:
    pass

func change_player_points(player: Player, points_change: int) -> void:
    if game_room_manager.is_host():
        if game_room_manager.is_online():
            _change_point_server_rpc.rpc_id(1, player.id, points_change)
        else:
            _change_point_server_rpc(player.id, points_change)

func _on_finish_pressed() -> void:
    if game_room_manager.is_host():
        if game_room_manager.is_online():
            _finish_server_rpc.rpc_id(1)
        else:
            _finish_server_rpc()