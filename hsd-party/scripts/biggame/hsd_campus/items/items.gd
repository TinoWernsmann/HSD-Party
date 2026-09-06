extends Resource
class_name BiggameHSDCampus_Item

@export var type: Type
@export var amount: int # Number of coins, Tiles to move back or Index of chosen player affected
@export var shop_price: int
@export var item_name: String
@export var icon: Texture2D
@export var description: String

enum Type {
	BIG_DICE,
	SMALL_DICE,
	DUELL_ITEM,
	STEAL_COINS,
	STEAL_ITEM,
	TELEPORT_TO_OTHER,
	TELEPORT_TO_STAR,
}

func use(game_manager: BiggameHSDCampus_GameManager, user: BiggameHSDCampus_Player) -> bool:
	user.current_state = user.States.USING_ITEM
	var success: bool = false
	match self.type:
		Type.STEAL_COINS:
			success = await use_steal_coins(game_manager, user)
		Type.STEAL_ITEM:
			success = await use_steal_item(game_manager, user)
		Type.TELEPORT_TO_OTHER:
			success = await use_teleporter(game_manager, user)
		Type.TELEPORT_TO_STAR:
			success = await use_star_teleport(game_manager, user)
		Type.DUELL_ITEM:
			success = await use_duell_item(game_manager, user)
		Type.BIG_DICE:
			success = use_dice(user, self)
		Type.SMALL_DICE:
			success = use_dice(user, self)
		_:
			success = false
	
	return success

func use_steal_coins(game_manager: BiggameHSDCampus_GameManager, user: BiggameHSDCampus_Player) -> bool:
	game_manager.awaiting_input = true
	game_manager.ui_manager.change_player_select_prompt_visibility(true)
	var target: BiggameHSDCampus_Player = await game_manager.await_player_chosen()
	game_manager.ui_manager.change_player_select_prompt_visibility(false)
	
	if target.get_coins() <= 0:
		return false
	
	game_manager.steal_coins(amount, user, target)
	return true

func use_dice(player: BiggameHSDCampus_Player, new_dice: BiggameHSDCampus_Item) -> bool:
	player.set_dice(new_dice)
	player.current_state = player.States.IDLE
	return true

func use_duell_item(game_manager: BiggameHSDCampus_GameManager, user: BiggameHSDCampus_Player) -> bool:
	game_manager.awaiting_input = true
	game_manager.ui_manager.change_player_select_prompt_visibility(true)
	var target: BiggameHSDCampus_Player = await game_manager.await_player_chosen()
	game_manager.ui_manager.change_player_select_prompt_visibility(false)

	if target.get_coins() <= 0:
		return false
	var winner: BiggameHSDCampus_Player = game_manager.play_duell()
	if winner == target:
		return true
	
	game_manager.steal_coins(target.get_coins(), user, target)
	return true

func use_steal_item(game_manager: BiggameHSDCampus_GameManager, user: BiggameHSDCampus_Player) -> bool:
	game_manager.awaiting_input = true
	game_manager.ui_manager.change_player_select_prompt_visibility(true)
	var target: BiggameHSDCampus_Player = await game_manager.await_player_chosen()
	game_manager.ui_manager.change_player_select_prompt_visibility(false)
	
	var target_inventory: Array = target.get_inventory_manager().get_inventory()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	
	if target_inventory.size() <= 0:
		return false
	
	var chosen_item: BiggameHSDCampus_Item = target_inventory[rng.randi() % target_inventory.size()]
	game_manager.steal_item(chosen_item, user, target)
	return true

func use_teleporter(game_manager: BiggameHSDCampus_GameManager, user: BiggameHSDCampus_Player) -> bool:
	game_manager.awaiting_input = true
	game_manager.ui_manager.change_player_select_prompt_visibility(true)
	var target: BiggameHSDCampus_Player = await game_manager.await_player_chosen()
	game_manager.ui_manager.change_player_select_prompt_visibility(false)
	
	if target.current_tile == user.current_tile:
		print("Cannot be on the same tile!")
		return false
	
	await game_manager.item_transition()
	user.set_new_tile(target.current_tile)
	user.global_position = user.current_tile.global_position + user.offset
	user.walk_dir.x = target.walk_dir.x
	user.walk_dir.z = target.walk_dir.z
	user.current_tile.on_camera_angle_switch.emit(user.current_tile.new_cam_x, user.current_tile.new_cam_z)
	await game_manager.item_transition_done()
	user.current_tile.do_tile_action(user)
	return true

func use_star_teleport(game_manager: BiggameHSDCampus_GameManager, user: BiggameHSDCampus_Player) -> bool:
	await game_manager.item_transition()
	var target: BiggameHSDCampus_Tile = game_manager.get_current_star_tile()
	user.set_new_tile(target)
	user.global_position = target.global_position + user.offset
	target.on_camera_angle_switch.emit(target.new_cam_x, target.new_cam_z)
	await game_manager.item_transition_done()
	target.do_tile_action(user)
	return true
