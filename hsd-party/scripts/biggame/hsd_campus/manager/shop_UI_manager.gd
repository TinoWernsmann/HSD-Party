extends Node
class_name BiggameHSDCampus_ShopUI

@onready var shop_ui: VBoxContainer = $"../CanvasLayer/MarginContainer/VBoxContainer"
@onready var item_desc: Label = $"../CanvasLayer/MarginContainer2/Label"
@onready var item_back: ColorRect = $"../CanvasLayer/ItemBack"
@onready var desc_back: ColorRect = $"../CanvasLayer/DescBack"

func fill_shop_ui(shop: Array[BiggameHSDCampus_Item]) -> void:
	var counter: int = 1
	for item: BiggameHSDCampus_Item in shop:
		var label: Label = Label.new()
		label.text = str(counter) + ": " + item.item_name + ": " + str(item.shop_price)
		label.modulate = Color(0, 0, 0)
		shop_ui.add_child(label)
		counter += 1
	shop_ui.visible = false

func change_chosen_item_color(shop: Array[BiggameHSDCampus_Item], current_item: int) -> void:
	for item: Label in shop_ui.get_children():
		item.modulate = Color(0, 0, 0)
		if shop[current_item].item_name in item.text and current_item >= 0:
			item.modulate = Color(0, 1, 0)

func change_visibilty() -> void:
	shop_ui.visible = !shop_ui.visible
	item_back.visible = !item_back.visible
	desc_back.visible = !desc_back.visible
	for item: Label in shop_ui.get_children():
		item.modulate = Color(0, 0, 0)
	item_desc.text = ""

func update_shop_ui(shop: Array[BiggameHSDCampus_Item]) -> void:
	var labels: Array = shop_ui.get_children()
	for i: int in range(min(labels.size(), shop.size())):
		labels[i].text = str(i + 1) + ": " + shop[i].item_name + ": " + str(shop[i].shop_price)

func show_new_item_UI(item: int, shop: Array[BiggameHSDCampus_Item]) -> void:
	item_desc.text = shop[item].description
