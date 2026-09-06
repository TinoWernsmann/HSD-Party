extends RefCounted
class_name ClientStatus

enum ConnectionStatus {
	DISCONNECTED,
	CONNECTED,
}
enum ClientState {
	IN_LOBBY,
	IN_ROOM,
}
var connection_status: ConnectionStatus = ConnectionStatus.DISCONNECTED

# Ein Client bleibt auch nach dem Disconnecten noch In_ROOM, bis der Raum geschlossen wird, da er nach einem Reconnecten das Spiel fortsetzen können soll.
var client_state: ClientState = ClientState.IN_LOBBY
var room_id: String = ""
var client_id: String = ""
