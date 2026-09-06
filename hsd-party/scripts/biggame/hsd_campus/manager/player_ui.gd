extends Control
class_name BiggameHSDCampus_PlayerUI

@export_group("Stats & Text")
@export var coins_label: Label
@export var stars_label: Label
@export var background: PanelContainer

@export_group("Avatar")
@export var avatar_icon: TextureRect
@export var avatar_texture: Texture2D

@export_group("Inventory")
@export var item_container: Container

var character_id: int

const MAX_ITEMS: int = 4
var item_slots: Array[TextureRect] = []

func setup(_character_id: int) -> void:
	character_id = _character_id

func _ready() -> void:
	
	var stylebox: StyleBoxFlat = background.get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = CharacterManager.get_character_by(character_id).character_color
	background.add_theme_stylebox_override("panel", stylebox)
	coins_label.modulate = CharacterManager.get_character_by(character_id).contrast_color
	stars_label.modulate = CharacterManager.get_character_by(character_id).contrast_color
	avatar_icon.texture = CharacterManager.get_character_by(character_id).character_icon

	_cache_item_slots()
	set_player_active(false)


func _cache_item_slots() -> void:
	item_slots.clear()

	if item_container == null:
		push_warning("HSDCampus_PlayerUI: item_container ist nicht gesetzt!")
		return

	for child in item_container.get_children():
		if child is TextureRect:
			item_slots.append(child as TextureRect)

	# Falls mehr Slots im Container sind als erlaubt
	if item_slots.size() > MAX_ITEMS:
		item_slots = item_slots.slice(0, MAX_ITEMS)


# --- Stats ---

func set_player_coins(player_coins: int) -> void:
	if coins_label != null:
		coins_label.text = str(player_coins)

func set_player_stars(player_stars: int) -> void:
	if stars_label != null:
		stars_label.text = str(player_stars)


# --- Dummy-Highlight / Debug ---

func set_player_active(is_active: bool) -> void:
	if is_active:
		avatar_icon.modulate = Color(1, 0, 0)
	else:
		avatar_icon.modulate = Color(1, 1, 1)

# --- Inventar ---

# Wenn du strikt tippen willst: func add_items(inventory: Array[Item]) -> void:
func add_items(inventory: Array) -> void:
	if item_container == null:
		push_warning("HSDCampus_PlayerUI: item_container ist nicht gesetzt (add_items)!")
		return

	if item_slots.is_empty():
		_cache_item_slots()

	clear_item_list()

	var inv_size: int = inventory.size()
	var slot_size: int = item_slots.size()
	var max_count: int = min(inv_size, slot_size, MAX_ITEMS)

	# Slots befüllen
	for i in range(max_count):
		var slot: TextureRect = item_slots[i]
		var item: Variant = inventory[i]
# Variant, damit "item is Item" sicher ist

		if item is BiggameHSDCampus_Item:
			slot.texture = item.icon
			slot.tooltip_text = item.item_name
		else:
			slot.texture = null
			slot.tooltip_text = ""

	# Restliche Slots leeren
	for i in range(max_count, slot_size):
		var slot: TextureRect = item_slots[i]
		slot.texture = null
		slot.tooltip_text = ""
		slot.modulate = Color(1, 1, 1, 1)
		slot.scale = Vector2(1, 1)


func clear_item_list() -> void:
	if item_slots.is_empty():
		_cache_item_slots()

	for slot: TextureRect in item_slots:
		slot.texture = null
		slot.tooltip_text = ""
		slot.modulate = Color(1, 1, 1, 1)
		slot.scale = Vector2(1, 1)


func highlight_item(index: int) -> void:
	if item_slots.is_empty():
		_cache_item_slots()

	for i in range(item_slots.size()):
		var slot: TextureRect = item_slots[i]
		if i == index:
			slot.modulate = Color(1, 0.5, 0.5, 1)
			slot.scale = Vector2(1.1, 1.1)
		else:
			slot.modulate = Color(1, 1, 1, 1)
			slot.scale = Vector2(1, 1)


func deselect_all_items() -> void:
	if item_slots.is_empty():
		_cache_item_slots()

	for slot: TextureRect in item_slots:
		slot.modulate = Color(1, 1, 1, 1)
		slot.scale = Vector2(1, 1)
