extends Node3D
class_name BiggameHSDCampus_UIManager

@export_subgroup("Scenes")
@export var player_ui_scene: PackedScene

@export_subgroup("UI Components")
@export var black_screen: BiggameHSDCampus_BlackScreen
@export var round_counter: BiggameHSDCampus_RoundCounter
@export var ui_root: Node
@export var player_whole_UI: CanvasLayer
@export var player_roll_control: ControlIcon
@export var player_item_control: ControlIcon
@export var player_cam_control: ControlIcon
@export var player_four_control: ControlIcon
@export var select_item_description: Label
@export var player_pick_prompt: Label

# Optional: Wenn du deine Player sauber unter einem Node gesammelt hast, hier reinziehen:
@export var players_root: Node

@onready var icon_root: VBoxContainer = $"../../UIs/controls/VBoxContainer2"

signal halfway_fade
signal fade_done

var player_uis: Array[BiggameHSDCampus_PlayerUI] = []
var player_control_uis: Array[ControlIcon] = []

func generate_ui(_game_manager: BiggameHSDCampus_GameManager, _player_informations: Array[GameRoomManagerBase.PlayerInformation]) -> void:

	for player_info: GameRoomManagerBase.PlayerInformation in _player_informations:
		if player_info != null:
			var player_ui: BiggameHSDCampus_PlayerUI = player_ui_scene.instantiate() as BiggameHSDCampus_PlayerUI
			player_ui.setup(player_info.character_id)
			players_root.add_child(player_ui)
			player_uis.append(player_ui)

	for index: int in _game_manager.players.size():
		update_coins(index, _game_manager.players[index].get_coins())
		update_star_text(index, _game_manager.players[index].get_stars())
	show_turn_color(_game_manager.get_current_player())

func _ready() -> void:
	_init_player_uis()
	_connect_black_screen_signals()
	_connect_player_inventory_signals()


# -------------------------
# Setup / Caching
# -------------------------

func _init_player_uis() -> void:
	player_uis.clear()

	if ui_root == null:
		push_warning("BiggameHSDCampus_UIManager: ui_root ist nicht gesetzt!")
		return

	for child: Node in ui_root.get_children():
		if child is BiggameHSDCampus_PlayerUI:
			player_uis.append(child as BiggameHSDCampus_PlayerUI)
			
	for icon: ControlIcon in icon_root.get_children():
		player_control_uis.append(icon)

func _connect_black_screen_signals() -> void:
	if black_screen == null:
		push_warning("BiggameHSDCampus_UIManager: black_screen ist nicht gesetzt!")
		return

	if not black_screen.fade_halfway.is_connected(_on_halfway_fade):
		black_screen.fade_halfway.connect(_on_halfway_fade)
	if not black_screen.fade_done.is_connected(_on_fade_done):
		black_screen.fade_done.connect(_on_fade_done)


func _connect_player_inventory_signals() -> void:
	for p: BiggameHSDCampus_Player in _find_players():
		var inv: BiggameHSDCampus_InventoryManager = p.get_inventory_manager()
		if inv == null:
			continue

		if not inv.on_item_cycle.is_connected(_on_player_cycle):
			inv.on_item_cycle.connect(_on_player_cycle)

		if not inv.on_item_cancel.is_connected(_on_player_cancel):
			inv.on_item_cancel.connect(_on_player_cancel)


func _find_players() -> Array[BiggameHSDCampus_Player]:
	var result: Array[BiggameHSDCampus_Player] = []

	# 1) bevorzugt: Gruppe "players"
	for n: Node in get_tree().get_nodes_in_group("players"):
		if n is BiggameHSDCampus_Player:
			result.append(n as BiggameHSDCampus_Player)

	if not result.is_empty():
		return result

	# 2) optionaler Root-Node
	if players_root != null:
		_collect_players_recursive(players_root, result)
		if not result.is_empty():
			return result

	# 3) Fallback: ganze Szene durchsuchen
	var scene_root: Node = get_tree().current_scene
	if scene_root != null:
		_collect_players_recursive(scene_root, result)

	return result


func _collect_players_recursive(node: Node, out: Array[BiggameHSDCampus_Player]) -> void:
	if node is BiggameHSDCampus_Player:
		out.append(node as BiggameHSDCampus_Player)

	for c: Node in node.get_children():
		_collect_players_recursive(c, out)


func _has_player_index(i: int) -> bool:
	return i >= 0 and i < player_uis.size()


# -------------------------
# Turn Highlight (passt zu BiggameHSDCampus_PlayerUI: set_player_active)
# -------------------------

func show_turn_color(player_numb: int) -> void:
	if _has_player_index(player_numb):
		player_uis[player_numb].set_player_active(true)

func hide_turn_color(player_numb: int) -> void:
	if _has_player_index(player_numb):
		player_uis[player_numb].set_player_active(false)

func show_player_controls(player_info: GameRoomManagerBase.PlayerInformation) -> void:
	if player_info != null:
		var player_array: Array[GameRoomManagerBase.PlayerInformation]
		player_array.append(player_info)
		for icon: ControlIcon in player_control_uis:
			icon.set_controller_ids_from_player_information(player_array)
		player_roll_control.show_button(ControllerDefinition.Buttons.BUTTON_1)
		player_item_control.show_button(ControllerDefinition.Buttons.BUTTON_2)
		player_cam_control.show_button(ControllerDefinition.Buttons.BUTTON_3)
		player_four_control.show_button(ControllerDefinition.Buttons.BUTTON_4)

# -------------------------
# Inventory UI (Zugriff wie in deinem 1. Code: über BiggameHSDCampus_InventoryManager)
# -------------------------

func update_item_list(player: BiggameHSDCampus_Player) -> void:
	if player == null:
		return

	var idx: int = player.player_numb
	if not _has_player_index(idx):
		push_warning("BiggameHSDCampus_UIManager: update_item_list ungültiger player_numb: %d" % idx)
		return

	var inv_manager: BiggameHSDCampus_InventoryManager = player.get_inventory_manager()
	if inv_manager == null:
		push_warning("BiggameHSDCampus_UIManager: update_item_list inventory_manager ist null (player %d)" % idx)
		player_uis[idx].clear_item_list()
		return

	player_uis[idx].add_items(inv_manager.get_inventory())


func cancel_item_selection(player_numb: int) -> void:
	if _has_player_index(player_numb):
		player_uis[player_numb].deselect_all_items()

func selected_item(index: int, player_numb: int) -> void:
	if _has_player_index(player_numb):
		player_uis[player_numb].highlight_item(index)
		
func show_selected_item_description(index: int, player: BiggameHSDCampus_Player) -> void:
	print(player.inventory_manager.get_inventory()[index].description)
	select_item_description.text = player.inventory_manager.get_inventory()[index].description

func hide_selected_item_description() -> void:
	select_item_description.text = ""
	
func change_player_select_prompt_visibility(isVisible: bool) -> void:
	player_pick_prompt.visible = isVisible

# -------------------------
# Stats UI
# -------------------------

func update_coins(index: int, coins: int) -> void:
	if _has_player_index(index):
		player_uis[index].set_player_coins(coins)

func update_stars(index: int, stars: int) -> void:
	if _has_player_index(index):
		player_uis[index].set_player_stars(stars)

func update_star_text(index: int, player_stars: int) -> void:
	update_stars(index, player_stars)


# -------------------------
# Round & Fade
# -------------------------

func update_rounds(round_numb: int) -> void:
	if round_counter != null:
		round_counter.set_round(round_numb)

func fade_out(player_numb: int) -> void:
	if black_screen == null:
		return
	black_screen.set_player_text(player_numb)
	black_screen.fade_to_black()

func transition() -> void:
	if black_screen == null:
		return
	black_screen.set_empty_text()
	black_screen.fade_to_black()

func set_end_screen() -> void:
	if black_screen == null:
		return
	black_screen.set_empty_text()

func restore_fade() -> void:
	if black_screen == null:
		return
	black_screen.restore_text()

func _on_halfway_fade() -> void:
	halfway_fade.emit()

func _on_fade_done() -> void:
	fade_done.emit()


# -------------------------
# Inventory Signals (aus BiggameHSDCampus_InventoryManager)
# -------------------------

func _on_player_cycle(index: int, player: BiggameHSDCampus_Player) -> void:
	selected_item(index, player.player_numb)
	show_selected_item_description(index, player)

func _on_player_cancel(player_numb: int) -> void:
	cancel_item_selection(player_numb)
	hide_selected_item_description()


# -------------------------
# Purchase Callback (damit dein connect nicht mehr crasht)
# -------------------------

func _on_purchase(player: BiggameHSDCampus_Player) -> void:
	# Nach Kauf: Inventar + Coins UI updaten
	update_item_list(player)
	if player != null:
		update_coins(player.player_numb, player.get_coins())
