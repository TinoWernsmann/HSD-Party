extends Node
class_name HSDPartyManager

@export_subgroup("Scenes")
@export var main_menu_scene: PackedScene
@export var online_main_manager_scene: PackedScene
@export var offline_main_manager_scene: PackedScene

var main_menu: HSDPartyMenuController
var current_main_manager: MainManager

var is_server: bool
var save_instance_prefix: String = "default"

func _ready() -> void:
	# Preloaden
	BiggameManager._get_instance()
	MinigameManager._get_instance()
	CharacterManager._get_instance()

	is_server = OS.has_feature("dedicated_server")

	#Setzen von unterschiedlichen Speicherorten für verschiedene Instanzen
	if is_server:
		save_instance_prefix = "HSDParty_Server"
	if OS.has_feature("client1"):
		save_instance_prefix = "HSDParty_Client1"
	if OS.has_feature("client2"):
		save_instance_prefix = "HSDParty_Client2"
		
	if is_server:
		_start_server()
	else:
		_start_client()

func _start_client() -> void:
	main_menu = main_menu_scene.instantiate()
	add_child(main_menu)
	main_menu.hsd_party = self
	
func _start_server() -> void:
	var online_main_manager: OnlineMainManager = online_main_manager_scene.instantiate()
	online_main_manager.hsd_party = self
	online_main_manager.is_server = true
	current_main_manager = online_main_manager
	add_child(current_main_manager)

func start_offline() -> void:
	current_main_manager = offline_main_manager_scene.instantiate()
	current_main_manager.hsd_party = self
	add_child(current_main_manager)
	main_menu.visible = false
	
func start_online() -> void:
	var online_main_manager: OnlineMainManager = online_main_manager_scene.instantiate()
	online_main_manager.hsd_party = self
	current_main_manager = online_main_manager
	add_child(current_main_manager)
	main_menu.visible = false
	
func back_to_menu() -> void:
	current_main_manager.queue_free()
	main_menu.visible = true
