extends Control
class_name InfoPanel

class Message:
	var text: String
	var to_time: int 
	
	func _init(_text: String, _to_time: int) -> void:
		self.text = _text
		self.to_time = _to_time

static var instance: InfoPanel

@export var SHOW_DURATION: int = 2000
@export var label: Label

var messages: Array[Message] = []

func _ready() -> void:
	_render_messages()
	instance = self

func _process(_delta: float) -> void:
	if _remove_unused():
		_render_messages()

static func add_message(_message: String)-> void:
	instance._add_messeage(_message)

@rpc("authority", "call_remote", "reliable")
func _add_messeage(_message: String)-> void:
	messages.append(Message.new(_message, Time.get_ticks_msec() + SHOW_DURATION))
	_render_messages()

func _remove_unused() -> bool:
	if messages.size() > 0:
		if messages[0].to_time < Time.get_ticks_msec():
			messages.remove_at(0)
			_remove_unused()
			return true
	return false

func _render_messages() -> void:
	if messages.size() == 0:
		visible = false
	else:
		visible = true
		var text: String = ""
		var first: bool = true
		for message: Message in messages:
			if !first:
				text += "\n"
			first = false
			text += message.text
		label.text = text

static func add_message_rpc(peer_id: int, _message: String) -> void:
	InfoPanel.instance._add_messeage.rpc_id(peer_id, _message)