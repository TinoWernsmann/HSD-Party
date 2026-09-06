extends MainManager
class_name OnlineMainManager

@export_subgroup("Scenes")
@export var online_menu_scene: PackedScene
@export var online_game_room_manager_scene: PackedScene

# Der OnlineMainManager verwaltet die Verbindungen und die Räume in welchen die Spieler spielen.

const SERVER_PORT: int = 2454
const SERVER_IP: String = "127.0.0.1"

#Server und Client
var is_server: bool
var identifier: String

#Serverside
var game_rooms: Dictionary[String, OnlineGameRoomManager] = {}

# Die ClientGuid ist eine Nutzer spezifische Guid, welche unverändert einem Gerät zugeordnet werden kann. Der 
# Der ClientStatus speichert ClientDaten zur Laufzeit. Damit der Spieler nach einem Reconnect weiterspielen kann bleibt der ClientStatus erhalten, bis dieser in keinem Raum mehr ist.
var client_guid_to_client_data: Dictionary[String, ClientStatus] = {}
var peer_id_to_client_guid: Dictionary[int, String] = {}
var unknown_connected_peers: Array[int] = []

#Clientside
var game_room_manager: OnlineGameRoomManager
var menu_controller: OnlineMenuController

func _ready() -> void:
	if(is_server):
		become_server()
	else:
		menu_controller = online_menu_scene.instantiate()
		menu_controller.multiplayer_manager = self
		add_child(menu_controller)	
		join_server()
# --------------------
#    Netzwerk Setup
# --------------------
func become_server() -> void:
	identifier = "Server"
	mprint("Starting dedicated server...")
	
	#Server verbindung öffnen.
	var server_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: Error = server_peer.create_server(SERVER_PORT)
	if err != OK:
		InfoPanel.add_message("Failed to start server: %s" % err)
		push_error("Failed to start server: %s" % err)
		return
	multiplayer.multiplayer_peer = server_peer
	
	#Server callback registrieren
	multiplayer.peer_connected.connect(_client_joins_server)
	multiplayer.peer_disconnected.connect(_client_disconnects_from_server)
	
	mprint("Server listening on port %d" % SERVER_PORT)
	
func join_server() -> void:
	identifier = "Client(joining)"
	mprint("Connecting to Server")
	menu_controller.connecting()
	#Server Verbindung öffnen.
	var client_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var response: int = client_peer.create_client(SERVER_IP, SERVER_PORT)
	if response == OK:
		multiplayer.multiplayer_peer = client_peer
		identifier = "Client(" + str(multiplayer.get_unique_id()) + ")"
		menu_controller.connected()
		client_peer.peer_disconnected.connect(_client_disconnected)
	else:
		menu_controller.connection_failed() 
# --------------------
#    ClientMethoden
# --------------------

func leave_room() -> void:
	game_room_manager.queue_free()
	menu_controller.visible = true
	_leave_game_room_server_rpc.rpc_id(1, multiplayer.get_unique_id())

# Fragt beim Server einen neuen GameRoom an. Dieser Client wird zum Host
func create_room() -> void:
	mprint("Create new Room")
	_create_gameroom_server_rpc.rpc_id(1, multiplayer.get_unique_id())

func join_room(room_id: String) -> void:
	mprint("Requesting to join room: %s" % room_id)
	_join_room_rpc.rpc_id(1, room_id)

func back_to_main_menu() -> void:
	disconnect_from_server()
	hsd_party.back_to_menu()

func _client_disconnected() -> void:
	menu_controller.connection_failed()

func disconnect_from_server() -> void:
	mprint("Disconnecting...")

	if multiplayer.multiplayer_peer == null:
		mprint("No active network connection.")
		return

	# Falls wir ein Client sind → vom Server trennen
	if multiplayer.get_unique_id() != 1: # 1 ist immer der Server
		mprint("Disconnecting client...")
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		identifier = "Client(disconnected)"
		return

	mprint("Disconnect: Unknown state?")


@rpc("authority", "call_remote", "reliable")
func _join_callback() -> void:
	menu_controller.connected()
	var data: Dictionary = load_data()
	var client_id: Variant = data.get("client_id")
	if client_id == null:
		client_id = _create_client_id()
		data["client_id"] = client_id
		save_data(data)
	_identify_client_server_rpc.rpc_id(1, client_id)

@rpc("authority", "call_remote", "reliable")
func _create_gameroom_response(room_id: String) -> void:
	mprint("Received new room id from server: %s" % room_id)
	game_room_manager = online_game_room_manager_scene.instantiate()
	game_room_manager.setup(self)
	game_room_manager.name = "GameRoom_" + room_id
	game_room_manager.game_room_id = room_id
	hsd_party.add_child(game_room_manager)
	menu_controller.visible = false

@rpc("authority", "call_remote", "reliable")
func _join_room_response(room_id: String) -> void:
	mprint("Joined room: %s" % room_id)
	
	game_room_manager = online_game_room_manager_scene.instantiate()
	game_room_manager.setup(self)
	game_room_manager.name = "GameRoom_" + room_id
	game_room_manager.game_room_id = room_id
	hsd_party.add_child(game_room_manager)
	menu_controller.visible = false

@rpc("authority", "call_remote", "reliable")
func _join_room_failed_response(room_id: String) -> void:
	InfoPanel.add_message("Failed to join room: %s" % room_id)
	mprint("Failed to join room: %s" % room_id)

# --------------------
#    ServerMethoden
# --------------------

func _client_joins_server(peer_id: int) -> void:
	mprint("Player with peer_id %s connects to the server!" % peer_id)
	if is_server: 
		unknown_connected_peers.append(peer_id)
		_join_callback.rpc_id(peer_id)

func _client_disconnects_from_server(peer_id: int) -> void:
	if is_server:
		if unknown_connected_peers.find(peer_id) != -1:
			unknown_connected_peers.erase(peer_id)
		else:
			var client_status: ClientStatus = _get_client_status(peer_id)
			if client_status.room_id != null:
				if game_rooms.has(client_status.room_id):
					game_rooms[client_status.room_id].client_leaves_room(peer_id)
			client_status.connection_status = ClientStatus.ConnectionStatus.DISCONNECTED
			peer_id_to_client_guid.erase(peer_id)


@rpc("any_peer", "call_remote", "reliable")
func _identify_client_server_rpc(client_id: String) -> void:
	var requester_peer_id: int = multiplayer.get_remote_sender_id() 
	if unknown_connected_peers.find(requester_peer_id) == -1:
		mprint("No connected unidentified peer with peer_id: %s" % requester_peer_id)
		pass
	mprint("Peer %s identified as client %s" % [requester_peer_id, client_id])
	unknown_connected_peers.erase(requester_peer_id)
	peer_id_to_client_guid[requester_peer_id] = client_id
	if client_guid_to_client_data.get(client_id) == null:
		client_guid_to_client_data[client_id] = ClientStatus.new()
		client_guid_to_client_data[client_id].client_id = client_id
	
	client_guid_to_client_data[client_id].connection_status = ClientStatus.ConnectionStatus.CONNECTED

@rpc("any_peer", "call_remote", "reliable")
func _leave_game_room_server_rpc(peer_id: int) -> void:
	if not peer_id_to_client_guid.has(peer_id):
		mprint("Unknown peer_id %s tried to leave a room!" % peer_id)
		return
	
	var client_guid: String = peer_id_to_client_guid[peer_id]
	var client_status: ClientStatus = client_guid_to_client_data[client_guid]
	
	# Prüfen, ob der Client aktuell in einem Raum ist
	var room_id: String = client_status.room_id
	if room_id == null or not game_rooms.has(room_id):
		mprint("Client %s is not in any room!" % peer_id)
		return
	
	# Raum holen und Client entfernen
	var room: OnlineGameRoomManager = game_rooms[room_id]
	room.client_leaves_room(peer_id)
	mprint("Client %s left room %s" % [peer_id, room_id])
	
	# ClientStatus aktualisieren
	client_status.room_id = ""

# Erstellen eines neuen GameRooms
@rpc("any_peer", "call_remote", "reliable")
func _create_gameroom_server_rpc(requester_peer_id: int) -> void:
	mprint("Server received request for new room from %s" % requester_peer_id)
	if unknown_connected_peers.find(requester_peer_id) == -1:
		mprint("Request from not identified client. PeerID: %s" % requester_peer_id)
		pass
	
	var new_game_room_id: String = _create_room_id()
	var newRoom: OnlineGameRoomManager = online_game_room_manager_scene.instantiate()
	newRoom.setup(self)
	newRoom.name = "GameRoom_" + new_game_room_id
	newRoom.game_room_id = new_game_room_id
	hsd_party.add_child(newRoom)
	game_rooms[new_game_room_id] = newRoom
	mprint("Created room %s for client %s" % [new_game_room_id, requester_peer_id])
	_create_gameroom_response.rpc_id(requester_peer_id, new_game_room_id)
	
	#Client Raum hinzufügem
	_get_client_status(requester_peer_id).room_id = new_game_room_id
	newRoom.client_joins_room(requester_peer_id)

func _get_client_status(peer_id: int) -> ClientStatus:
	return client_guid_to_client_data[peer_id_to_client_guid[peer_id]]

@rpc("any_peer", "call_remote", "reliable")
func _join_room_rpc(room_id: String) -> void:
	var requester_peer_id: int = multiplayer.get_remote_sender_id() 
	mprint("Server received join request from %s for room %s" % [requester_peer_id, room_id])
	
	if not game_rooms.has(room_id):
		mprint("Room %s does not exist!" % room_id)
		_join_room_failed_response.rpc_id(requester_peer_id, room_id)
		return
	
	_join_room_response.rpc_id(requester_peer_id, room_id)
	var room: OnlineGameRoomManager = game_rooms[room_id]
	_get_client_status(requester_peer_id).room_id = room_id
	room.client_joins_room(requester_peer_id)
	mprint("Client %s joined room %s" % [requester_peer_id, room_id])

func remove_room(room_id: String) -> void:
	if game_rooms.has(room_id):
		game_rooms[room_id].queue_free()
		game_rooms.erase(room_id)
# --------------------
#    Hilfsmethoden
# --------------------

const ID_CHARS:String = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNOPQRSTUVWXYZ0123456789" 
const AMOUNT_OF_PARTS: int = 2
const LENGTH_OF_PART: int = 3

# Erstellen einer zufälligen Id XXX XXX
func _create_room_id() -> String:
	var roomId: String = ""
	for part_index: int in range(AMOUNT_OF_PARTS):
		for index_of_part_char: int in range(LENGTH_OF_PART):
			roomId += ID_CHARS[randi_range(0,ID_CHARS.length()-1)]
		if(part_index != AMOUNT_OF_PARTS-1):
			roomId += " "
	return roomId

# Erstellen einer zufälligen Id XXX XXX
func _create_client_id() -> String:
	var client_id: String = ""
	for index_of_part_char: int in range(10):
		client_id += ID_CHARS[randi_range(0,ID_CHARS.length()-1)]
	return client_id

# Print inklusive Clinet/Server identifier
func mprint(...args: Array) -> void:
	print(identifier, ": ", args)
	
func save_data(data: Dictionary, file_name: String = "save.json") -> void:
	var path: String = "user://%s_%s" % [hsd_party.save_instance_prefix,file_name]
	var json: String = JSON.stringify(data)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json)
	file.close()
	
func load_data(file_name: String = "save.json") -> Dictionary:
	var path: String = "user://%s_%s" % [hsd_party.save_instance_prefix,file_name]
	if not FileAccess.file_exists(path):
		return {} # Noch nichts gespeichert
	
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var data: String = file.get_as_text()
	file.close()
	
	var result: Dictionary = JSON.parse_string(data)
	return result if result != null else {}	
