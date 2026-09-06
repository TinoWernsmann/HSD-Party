extends Node
class_name DebugMinigame_PlayerInputPanelController

@export var player_nr_label: Label
@export var character_icon_container: HBoxContainer
@export var points_label: Label
@export var panel_container: PanelContainer

var player: DebugMinigame.Player
var debug_minigame: DebugMinigame

func setup(_player: DebugMinigame.Player, _debug_minigame: DebugMinigame) -> void:
	self.player = _player
	self.debug_minigame = _debug_minigame


func _ready() -> void:
	var stylebox: StyleBoxFlat = panel_container.get_theme_stylebox("panel").duplicate()
	if player.player is MinigameBase.TeamGameData.Team:
		var team: MinigameBase.TeamGameData.Team = player.player
		player_nr_label.text = "Team %d" % (player.id + 1)
		player_nr_label.add_theme_color_override("font_color", Color.BLACK)
		points_label.add_theme_color_override("font_color", Color.BLACK)
		stylebox.bg_color = Color.GRAY
		for member: GameRoomManagerBase.PlayerInformation in team.players:
			var new_icon: TextureRect = TextureRect.new()
			new_icon.texture = member.character_info().character_icon
			new_icon.expand_mode = TextureRect.ExpandMode.EXPAND_IGNORE_SIZE
			new_icon.size_flags_horizontal = Control.SizeFlags.SIZE_EXPAND_FILL
			new_icon.stretch_mode = TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
			character_icon_container.add_child(new_icon)
	elif player.player is GameRoomManagerBase.PlayerInformation:
		var player_info: GameRoomManagerBase.PlayerInformation = player.player
		player_nr_label.add_theme_color_override("font_color", player_info.character_info().contrast_color)
		points_label.add_theme_color_override("font_color", player_info.character_info().contrast_color)
		player_nr_label.text = "Spieler %d" % (player_info.player_nr + 1)
		stylebox.bg_color = player_info.character_info().character_color
		var new_icon: TextureRect = TextureRect.new()
		new_icon.texture = player_info.character_info().character_icon
		new_icon.expand_mode = TextureRect.ExpandMode.EXPAND_IGNORE_SIZE
		new_icon.size_flags_horizontal = Control.SizeFlags.SIZE_EXPAND_FILL
		new_icon.stretch_mode = TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
		character_icon_container.add_child(new_icon)
	
	panel_container.add_theme_stylebox_override("panel", stylebox)
	set_points(0)

func set_points(_points: int) -> void:
	points_label.text = "Punkte: %d" % _points

func _on_add_pressed() -> void:
	debug_minigame.change_player_points(player, 1)

func _on_sub_pressed() -> void:
	debug_minigame.change_player_points(player, -1)
