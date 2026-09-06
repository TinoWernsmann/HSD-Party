extends Resource
class_name BiggameManager

class BiggameSettings:
	pass
	
class BiggameFilter:
	func is_allowed(_biggame_info: BiggameInfo) -> bool:
		return true

	func error_message(_biggame_info: BiggameInfo) -> String:
		return "Unimplemented error message"

class OnlineSupportFilter:
	extends BiggameFilter

	func is_allowed(_biggame_info: BiggameInfo) -> bool:
		return _biggame_info.online_multiplayer

	func error_message(_biggame_info: BiggameInfo) -> String:
		if not is_allowed(_biggame_info):
			return "Fehlender Online Support."
		return ""

class PlayerInfoFilter:
	extends BiggameFilter

	var player_infos: Array[GameRoomManagerBase.PlayerInformation]

	func _init(_player_infos: Array[GameRoomManagerBase.PlayerInformation]) -> void:
		self.player_infos = _player_infos

	func is_allowed(_biggame_info: BiggameInfo) -> bool:
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
		
		return _biggame_info.min_player <= player_count && _biggame_info.max_player >= player_count && (!need_ai_support || _biggame_info.ai_player) && (!need_online_support || _biggame_info.online_multiplayer)
	
	func error_message(_biggame_info: BiggameInfo) -> String:
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
		if player_count < _biggame_info.min_player:
			result += "Zu wenig Spieler.\n"
		if player_count > _biggame_info.max_player:
			result += "Zu viele Spieler.\n"
		if need_ai_support and not _biggame_info.ai_player:
			result += "Keine KI-Unterstützung.\n"
		if need_online_support and not _biggame_info.online_multiplayer:
			result += "Kein Online-Support.\n"
		return result.strip_edges()

static var instance: BiggameManager
const BIGGAME_MANAGER_RESSOURCE: String = "res://ressources/biggame_manager.tres"

@export var biggames: Array[BiggameInfo]:
	set(value):
		biggames = value
		_update_biggame_ids()

func _update_biggame_ids() -> void:
	for i: int in biggames.size():
		if biggames[i]:
			biggames[i].id = i

static func get_biggame_by(_id: int) -> BiggameInfo:
	return _get_instance().biggames[_id]

static func filter_biggames(_biggames: Array[BiggameInfo], _filter: BiggameFilter) -> Array[BiggameInfo]:
	var result: Array[BiggameInfo] = []
	for biggame_info: BiggameInfo in _biggames:
		if _filter.is_allowed(biggame_info):
			result.append(biggame_info)
	return result

static func filterd_biggames(..._filters: Array) -> Array[BiggameInfo]:
	var current_biggames: Array[BiggameInfo] = _get_instance().biggames
	if _filters != null:
		for filter: BiggameFilter in _filters:
			current_biggames = filter_biggames(current_biggames, filter)
	return current_biggames

static func _get_instance() -> BiggameManager:
	if instance == null:
		instance = load(BIGGAME_MANAGER_RESSOURCE)
	return instance
