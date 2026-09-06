extends BiggameHSDCampus_Tile
class_name Shop_Tile

@export var shop_items: Array[BiggameHSDCampus_Item]
@export var shop_ui: BiggameHSDCampus_ShopUI
@export var seller_model: PackedScene
@export var shop_visual_manager: BiggameHSDCampus_ShopVisuals

var awaiting_input: bool = false
var land_sound: AudioStream = preload("res://assets/sound/Shop.wav")
var buy_sound: AudioStream = preload("res://assets/sound/bought.wav")
var chosen_item: int = -1

signal on_shop_action(bought_item: BiggameHSDCampus_Item)
signal on_purchase_complete(item: BiggameHSDCampus_Item, player: BiggameHSDCampus_UIManager)
signal on_camera_zoom_out()

func _ready() -> void:
	is_zoom = true
	# null-safe: prefer Star/Model, fallback to Star node
	if has_node("Star"):
		var s := get_node("Star")
		if s and s.has_node("Model"):
			star_texture = s.get_node("Model")
		else:
			star_texture = s
	shop_ui.fill_shop_ui(shop_items)
	shop_visual_manager.set_seller_model(seller_model)

func _process(_delta: float) -> void:
	super._process(_delta)
	
	if not awaiting_input:
		return
		
	if game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_2):
		if chosen_item == shop_items.size() - 1:
			set_chosen_item(0)
		else:
			set_chosen_item(chosen_item + 1)
	elif game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_1):
		if chosen_item != -1:
			on_shop_action.emit(shop_items[chosen_item])
			chosen_item = -1
	elif game_manager.input_is_just_pressed(ControllerDefinition.Buttons.BUTTON_3):
		on_shop_action.emit(null)
		chosen_item = -1


func set_chosen_item(item_numb: int) -> void:
	if shop_items.size() > item_numb and shop_items[item_numb] != null:
		chosen_item = item_numb
		shop_ui.show_new_item_UI(chosen_item, shop_items)
		shop_ui.change_chosen_item_color(shop_items, chosen_item)

func do_tile_action(player: BiggameHSDCampus_Player) -> void:
	if is_star:
		do_star_action(player)
		return

	if player.get_inventory_manager().get_inventory().size() >= player.get_inventory_manager().inventory_max_size:
		player.disable_turn()
		return

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
	
func shop_in_shop(player: BiggameHSDCampus_Player) -> BiggameHSDCampus_Item:
	set_chosen_item(0)
	awaiting_input = true
	var new_item: BiggameHSDCampus_Item = await on_shop_action
	awaiting_input = false

	if new_item == null:
		return null

	if new_item.shop_price > player.get_coins():
		return await shop_in_shop(player)

	audio_manager.play_tile_sound(buy_sound)
	return new_item
