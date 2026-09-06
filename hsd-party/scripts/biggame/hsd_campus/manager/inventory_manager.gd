extends Node3D
class_name BiggameHSDCampus_InventoryManager

var inventory: Array[BiggameHSDCampus_Item] = []
var inventory_max_size: int = 4
var chosen_item_index: int = -1

@onready var my_player: BiggameHSDCampus_Player = $".."

signal on_item_use(player: BiggameHSDCampus_Player, item: BiggameHSDCampus_Item)
signal on_item_cycle(index: int, player_numb: int)
signal on_item_cancel(player_numb: int)

func _process(_delta: float) -> void:
	if not my_player.is_turn or my_player.current_state == my_player.States.IN_MINIGAME:
		return
	
	if my_player.current_state == my_player.States.CHOOSING_ITEM:
		if my_player.game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_2):
			
			if inventory.size() == 0:
				return
			
			my_player.current_state =  my_player.States.CHOOSING_ITEM
			chosen_item_index = (chosen_item_index + 1) % inventory.size()
			on_item_cycle.emit(chosen_item_index, my_player)
			return
			
		# Confirm Item Usage
		if my_player.game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_1):
			my_player.current_state = my_player.States.USING_ITEM
			on_item_use.emit(my_player, inventory[chosen_item_index])
			chosen_item_index = -1
			get_tree().root.set_input_as_handled()
			return
			
		# Cancel Item Selection
		if my_player.game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_3):
			my_player.current_state = my_player.States.IDLE
			chosen_item_index = -1
			on_item_cancel.emit(my_player.player_numb)
			get_tree().root.set_input_as_handled()
			return
	
	# Start Item Usage
	if my_player.game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_2) and my_player.current_state == my_player.States.IDLE:
		if inventory.size() == 0:
			return
		my_player.current_state = my_player.States.CHOOSING_ITEM
		chosen_item_index = 0
		on_item_cycle.emit(chosen_item_index, my_player)

func add_item(item: BiggameHSDCampus_Item) -> void:
	inventory.append(item)

func remove_item(item: BiggameHSDCampus_Item) -> void:
	inventory.erase(item)

func get_inventory() -> Array:
	return inventory
