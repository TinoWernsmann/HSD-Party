extends MinigameBase
class_name MinigamePong

@export_subgroup("Scenes")
@export var playground_2_player: PackedScene 
@export var playground_3_player: PackedScene 
@export var playground_4_player: PackedScene
@export var ball_scene: PackedScene
@export var score_info_scene: PackedScene

@export_subgroup("UI Refs")
@export var center_banner: Container
@export var countdown_label: Label
@export var timer_label: Label
@export var right_score_container: HBoxContainer
@export var left_score_container: HBoxContainer

@export_subgroup("Settings")
@export var duration_in_seconds: int


# Pong Game Objects
var playground: MinigamePong_Playgound
var balls: Array[MinigamePong_Ball] = []
var score_info_panel: Array[MinigamePong_ScoreInfoController]
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


# States
var paused: bool = false
var instruction_preview: bool = false
var timer_active: bool
var countdown_active: bool
var game_acitve: bool = false

# Game States
var ball_counter: int = 0 # Anzahl insgesamt erzeugter Bälle
var scores: Array[int]

# Timer
var timer_start_time_stamp: int
var countdown_start_time_stamp: int
var paused_at_timestamp: int

func setup(_game_room_manager: GameRoomManagerBase, _biggame_base: BigGameBase) -> void:
    super.setup(_game_room_manager,_biggame_base)

func _on_set_game_data(_game_data: GameData) -> void:
    for x: GameRoomManagerBase.PlayerInformation in game_data.all_player_infos():
        var new_score_info_panel: MinigamePong_ScoreInfoController = score_info_scene.instantiate()
        score_info_panel.append(new_score_info_panel)
        new_score_info_panel.setup(CharacterManager.get_character_by(x.character_id))
        scores.append(0)

func _ready() -> void:
    rng.seed = 1
    match game_data.all_player_infos().size():
        2: 
            playground = playground_2_player.instantiate() as MinigamePong_Playgound
            left_score_container.add_child(score_info_panel[0])
            right_score_container.add_child(score_info_panel[1])
        3: 
            playground = playground_3_player.instantiate() as MinigamePong_Playgound
            left_score_container.add_child(score_info_panel[0])
            left_score_container.add_child(score_info_panel[1])
            right_score_container.add_child(score_info_panel[2])
        4:
            playground = playground_4_player.instantiate() as MinigamePong_Playgound
            left_score_container.add_child(score_info_panel[0])
            left_score_container.add_child(score_info_panel[1])
            right_score_container.add_child(score_info_panel[2])
            right_score_container.add_child(score_info_panel[3])
    playground.setup(game_data.all_player_infos(), game_room_manager, self)
    add_child(playground)

func _process(_delta: float) -> void:
    if not paused:
        if countdown_active:
            _process_countdown()
        if timer_active:
            _process_timer()
        if game_acitve:
            _process_game()

func start_minigame() -> void:
    _reset()
    _start_countdown()

func start_instruction_preview_minigame() -> void:
    instruction_preview = true
    _reset()
    _start_countdown()

func _reset() -> void:
    timer_label.text = str(duration_in_seconds)
    game_acitve = false
    timer_active = false
    for i: int in game_data.all_player_infos().size():
        scores[i] = 0
        score_info_panel[i].set_score(0)

func _process_countdown() -> void:
    var countdown_time: int = ceili((3000-(Time.get_ticks_msec()-countdown_start_time_stamp))/1000.0)
    if countdown_time > 0:
        countdown_label.text = str(countdown_time)
    if countdown_time <= 0:
        countdown_label.text = "Start"
        countdown_label.modulate = Color.GREEN
        if not timer_active:
            timer_active = true
            game_acitve = true
            playground.resume()
            timer_start_time_stamp = Time.get_ticks_msec()
    if countdown_time <= -1:
        center_banner.visible = false
        countdown_active = false

func _process_timer() -> void:
    var time: int = ceili((duration_in_seconds*1000-(Time.get_ticks_msec()-timer_start_time_stamp))/1000.0)
    timer_label.text = str(time)
    if time <= 0 && game_acitve:
        game_acitve = false
        center_banner.visible = true
        countdown_label.modulate = Color.RED
        countdown_label.text = "Ende"
        for ball: MinigamePong_Ball in balls:
            ball.queue_free()
        balls.clear()
    if time <= -1:
        if instruction_preview:
            start_instruction_preview_minigame()
        else:
            biggame_base.finish_minigame(_create_game_result())


func _process_game() -> void:
    if balls.size() < floor((Time.get_ticks_msec() - timer_start_time_stamp) / (1000.0 * duration_in_seconds / (game_data as FFAGameData).all_player_infos().size())) + 1:
        _create_new_ball()

func _create_new_ball() -> void:
    var new_ball: MinigamePong_Ball = ball_scene.instantiate() as MinigamePong_Ball
    new_ball.global_position = playground.gamefield_center.global_position
    var angle: float = rng.randf() * 1.2 - 0.6
    var direction: Vector2 = playground.goals[ball_counter%playground.goals.size()].position.normalized()

    new_ball.start_direction = direction.rotated(angle)
    ball_counter = ball_counter + 1
    add_child(new_ball)
    balls.append(new_ball)

func _start_countdown() -> void:
    countdown_label.modulate = Color.WHITE
    countdown_label.visible = true
    center_banner.visible = true
    countdown_active = true
    countdown_start_time_stamp = Time.get_ticks_msec()

func score(_pong_player_nr: int, _ball: MinigamePong_Ball) -> void:
    scores[_pong_player_nr] = scores[_pong_player_nr] - 1
    score_info_panel[_pong_player_nr].set_score(scores[_pong_player_nr])
    _ball.queue_free()
    balls.erase(_ball)

func _create_game_result() -> MinigameBase.MinigameResult:
    var sorted_player_list: Array[int] = scores.duplicate()
    sorted_player_list.sort_custom(
    func(a: int, b: int) -> bool:
        return a > b
    )
    var result: MinigameBase.FFAResult = game_data.create_result()
    var current_points: int = sorted_player_list[0]
    var place: int = 1
    for i: int in sorted_player_list.size():
        var points: int = sorted_player_list[i]
        if points < current_points:
            place += 1
            current_points = points
        for j: int in scores.size():
            if scores[j] == points:
                 result.add_to_place(game_data.all_player_infos()[j], place)
    return result

func pause() -> void:
    paused = true
    paused_at_timestamp = Time.get_ticks_msec()
    if game_acitve:
        for ball: MinigamePong_Ball in balls:
            ball.process_mode = Node.PROCESS_MODE_DISABLED
        playground.pause()

func resume() -> void:
    paused = false
    var time_paused: int = Time.get_ticks_msec() - paused_at_timestamp
    if timer_active:
        timer_start_time_stamp = timer_start_time_stamp + time_paused
    if countdown_active:
        countdown_start_time_stamp = countdown_start_time_stamp + time_paused
    if game_acitve:
        for ball: MinigamePong_Ball in balls:
            ball.process_mode = Node.PROCESS_MODE_INHERIT
        playground.resume()