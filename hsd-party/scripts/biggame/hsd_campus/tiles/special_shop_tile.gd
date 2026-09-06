extends Shop_Tile
class_name Special_Shop_Tile

@export var available_item_pool: Array[BiggameHSDCampus_Item]

const MAX_SHOP_SIZE: int = 4
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	is_zoom = true
	# null-safe: prefer Star/Model, fallback to Star node
	if has_node("Star"):
		var s: Node = get_node("Star")
		if s and s.has_node("Model"):
			star_texture = s.get_node("Model")
		else:
			star_texture = s
	shop_visual_manager.set_seller_model(seller_model)
	refill_shop_randomly()
	shop_ui.fill_shop_ui(shop_items)

func _process(_delta: float) -> void:
	if not awaiting_input:
		return
		
	if game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_1):
		if chosen_item != -1:
			on_shop_action.emit(shop_items[chosen_item])
			chosen_item = -1
	elif game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_1):
		if chosen_item != 0:
			set_chosen_item(0)
	elif game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_2):
		if chosen_item != 1:
			set_chosen_item(1)
	elif game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_3):
		if chosen_item != 2:
			set_chosen_item(2)
	elif game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_4):
		if chosen_item != 3:
			set_chosen_item(3)
	elif game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_1):
		on_shop_action.emit(null)
		chosen_item = -1

func do_tile_action(player: BiggameHSDCampus_Player) -> void:
	if is_star:
		do_star_action(player)
		return

	if player.get_inventory_manager().get_inventory().size() >= player.get_inventory_manager().inventory_max_size:
		player.disable_turn()
		return

	refill_shop_randomly()
	shop_ui.update_shop_ui(shop_items)
	shop_visual_manager.shop_cam.current = true
	audio_manager.play_tile_sound(land_sound)
	shop_visual_manager.enter_shop_animation()
	await shop_visual_manager.seller_animator.animation_finished
	shop_ui.change_visibilty()
	var bought: BiggameHSDCampus_Item = await shop_in_shop(player)
	
	if bought != null:
		player.add_coins(-bought.shop_price)
		player.get_inventory_manager().add_item(bought)
		on_purchase_complete.emit(player)
	shop_ui.change_visibilty()
	shop_visual_manager.leave_shop_animation()
	await shop_visual_manager.seller_animator.animation_finished
	on_camera_zoom_out.emit()
	shop_visual_manager.shop_cam.current = false
	player.disable_turn()

func refill_shop_randomly() -> void:
	shop_items.clear()
	shop_items.resize(MAX_SHOP_SIZE)
	var temp_item: Array[BiggameHSDCampus_Item] = available_item_pool.duplicate()
	for i: int in range(MAX_SHOP_SIZE):
		if temp_item.is_empty():
			break
		
		var random_index: int = rng.randi_range(0, temp_item.size() - 1)
		var new_item: BiggameHSDCampus_Item = temp_item[random_index]
		shop_items[i] = new_item
		temp_item.remove_at(random_index)
