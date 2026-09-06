extends Node
class_name BiggameHSDCampus_ItemFactory

const COIN_STEALER: BiggameHSDCampus_Item = preload("res://scenes/object/biggame/hsd_campus/items/steal_coins.tres")
const ITEM_STEALER: BiggameHSDCampus_Item = preload("res://scenes/object/biggame/hsd_campus/items/steal_item.tres")
const TELEPORTER: BiggameHSDCampus_Item = preload("res://scenes/object/biggame/hsd_campus/items/teleport_item.tres")
const STAR_TELEPORTER: BiggameHSDCampus_Item = preload("res://scenes/object/biggame/hsd_campus/items/star_teleporter.tres")
const DUELL_ITEM: BiggameHSDCampus_Item = preload("res://scenes/object/biggame/hsd_campus/items/duell_item.tres")
const BIG_DICE: BiggameHSDCampus_Item = preload("res://scenes/object/biggame/hsd_campus/items/big_dice.tres")
const SMALL_DICE: BiggameHSDCampus_Item = preload("res://scenes/object/biggame/hsd_campus/items/small_dice.tres")

func give_player_item(player: BiggameHSDCampus_Player, item_type: BiggameHSDCampus_Item.Type) -> void:
	var item: BiggameHSDCampus_Item
	match item_type:
		BiggameHSDCampus_Item.Type.STEAL_COINS:
			item = COIN_STEALER.duplicate()
		BiggameHSDCampus_Item.Type.STEAL_ITEM:
			item = ITEM_STEALER.duplicate()
		BiggameHSDCampus_Item.Type.TELEPORT_TO_OTHER:
			item = TELEPORTER.duplicate()
		BiggameHSDCampus_Item.Type.TELEPORT_TO_STAR:
			item = STAR_TELEPORTER.duplicate()
		BiggameHSDCampus_Item.Type.DUELL_ITEM:
			item = DUELL_ITEM.duplicate()
		BiggameHSDCampus_Item.Type.BIG_DICE:
			item = BIG_DICE.duplicate()
		BiggameHSDCampus_Item.Type.SMALL_DICE:
			item = SMALL_DICE.duplicate()

	if item:
		player.get_inventory_manager().add_item(item)
