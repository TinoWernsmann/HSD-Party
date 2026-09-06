extends Resource
class_name MinigameManager

class MinigameFilter:
	func is_allowed(_minigame_info: MinigameInfo) -> bool:
		return true

	func error_message(_minigame_info: MinigameInfo) -> String:
		return "Unimplemented error message"

class OnlineSupportFilter:
	extends MinigameFilter
	func is_allowed(_minigame_info: MinigameInfo) -> bool:
		return _minigame_info.online_multiplayer

	func error_message(_minigame_info: MinigameInfo) -> String:
		if not is_allowed(_minigame_info):
			return "Fehlender Online Support."
		return ""

class PlayerInfoFilter:
	extends MinigameFilter

	var player_infos: Array[GameRoomManagerBase.PlayerInformation]

	func _init(_player_infos: Array[GameRoomManagerBase.PlayerInformation]) -> void:
		self.player_infos = _player_infos

	func is_allowed(_minigame_info: MinigameInfo) -> bool:
		var need_ai_support: bool = false
		var need_online_support: bool = false
		var player_count: int = 0

		for player_info: GameRoomManagerBase.PlayerInformation in player_infos:
			if player_info != null:
				player_count = player_count + 1
				if player_info is GameRoomManagerBase.AIPlayerInformation:
					need_ai_support = true
				if player_info is GameRoomManagerBase.OnlineClientPlayerInformation:
					need_online_support = true
		
		return _minigame_info.min_player <= player_count && _minigame_info.max_player >= player_count && (!need_ai_support || _minigame_info.ai_player) && (!need_online_support || _minigame_info.online_multiplayer)
	
	func error_message(_minigame_info: MinigameInfo) -> String:
		var need_ai_support: bool = false
		var need_online_support: bool = false
		var player_count: int = 0

		for player_info: GameRoomManagerBase.PlayerInformation in player_infos:
			if player_info != null:
				player_count = player_count + 1
				if player_info is GameRoomManagerBase.AIPlayerInformation:
					need_ai_support = true
				if player_info is GameRoomManagerBase.OnlineClientPlayerInformation:
					need_online_support = true
		
		var result: String = ""
		if player_count < _minigame_info.min_player:
			result += "Zu wenig Spieler.\n"
		if player_count > _minigame_info.max_player:
			result += "Zu viele Spieler.\n"
		if need_ai_support and not _minigame_info.ai_player:
			result += "Keine KI-Unterstützung.\n"
		if need_online_support and not _minigame_info.online_multiplayer:
			result += "Kein Online-Support.\n"
		return result.strip_edges()
	
class DebugFilter:
	extends MinigameFilter
	var is_debug: bool = true

	func _init(_is_debug: bool) -> void:
		self.is_debug = _is_debug

	func is_allowed(_minigame_info: MinigameInfo) -> bool:
		return _minigame_info.debug_minigame == is_debug

class TypeFilter:
	extends MinigameFilter

	var type: MinigameInfo.MinigameTypes

	func _init(_type: MinigameInfo.MinigameTypes) -> void:
		self.type = _type

	func is_allowed(_minigame_info: MinigameInfo) -> bool:
		return _minigame_info.game_types.has(type)	

	func error_message(_minigame_info: MinigameInfo) -> String:
		if _minigame_info.game_types.has(type):
			return "Der Typ " + MinigameInfo.minigame_type_to_text(type) + " wird nicht unterstützt."
		return ""
	

@export var minigames: Array[MinigameInfo]:
	set(value):
		minigames = value
		_update_minigame_ids()
		
static var instance: MinigameManager
const MINIGAME_MANAGER_RESSOURCE: String = "res://ressources/minigame_manager.tres"

func _update_minigame_ids() -> void:
	for i: int in minigames.size():
		if minigames[i]:
			minigames[i].id = i

static func get_minigame_by(_id: int) -> MinigameInfo:
	return _get_instance().minigames[_id]

static func filter_minigames(_minigames: Array[MinigameInfo], _filter: MinigameFilter) -> Array[MinigameInfo]:
	var result: Array[MinigameInfo] = []
	for minigame_info: MinigameInfo in _minigames:
		if _filter.is_allowed(minigame_info):
			result.append(minigame_info)
	return result

static func filterd_minigames(..._filters: Array) -> Array[MinigameInfo]:
	var current_minigames: Array[MinigameInfo] = _get_instance().minigames
	if _filters != null:
		for filter: MinigameFilter in _filters:
			current_minigames = filter_minigames(current_minigames, filter)
	return current_minigames

static func _get_instance() -> MinigameManager:
	if instance == null:
		instance = load(MINIGAME_MANAGER_RESSOURCE)
	return instance