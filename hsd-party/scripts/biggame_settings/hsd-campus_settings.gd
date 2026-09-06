extends BiggameSettingsController

const SELECTED_COLOR: Color = Color(1, 0, 0, 1)

var settings: BiggameHSDCampus.BiggameHSDCampusSettings = BiggameHSDCampus.BiggameHSDCampusSettings.new()

@export var panel_4: PanelContainer
@export var panel_8: PanelContainer
@export var panel_16: PanelContainer
@export var panel_32: PanelContainer
@export var debug_minigame_panel: PanelContainer
@export var debug_cheats_panel: PanelContainer

func _ready() -> void:
	highlight_color()

func _on__pressed_4_rounds() -> void:
	settings.max_rounds = 4
	highlight_color()
	
func _on__pressed_8_rounds() -> void:
	settings.max_rounds = 8
	highlight_color()

func _on__pressed_16_round() -> void:
	settings.max_rounds = 16
	highlight_color()

func _on__pressed_32_round() -> void:
	settings.max_rounds = 32
	highlight_color()

func highlight_color() -> void:
	if settings.debug_minigames:
		debug_minigame_panel.modulate = SELECTED_COLOR
	else:
		debug_minigame_panel.modulate = Color(1,1,1,1)
	if settings.debug_cheats:
		debug_cheats_panel.modulate = SELECTED_COLOR
	else:
		debug_cheats_panel.modulate = Color(1,1,1,1)

	panel_4.modulate = Color(1,1,1,1)
	panel_8.modulate = Color(1,1,1,1)
	panel_16.modulate = Color(1,1,1,1)
	panel_32.modulate = Color(1,1,1,1)

	match settings.max_rounds:
		4: panel_4.modulate = SELECTED_COLOR
		8: panel_8.modulate = SELECTED_COLOR
		16: panel_16.modulate = SELECTED_COLOR
		32: panel_32.modulate = SELECTED_COLOR

func _on_start_pressed() -> void:
	game_room_manager.finish_biggame_settings(biggame_id, settings)

func _on_debug_minigames_pressed() -> void:
	settings.debug_minigames = !settings.debug_minigames
	highlight_color()

func _on_debug_cheats_pressed() -> void:
	settings.debug_cheats = !settings.debug_cheats
	highlight_color()
