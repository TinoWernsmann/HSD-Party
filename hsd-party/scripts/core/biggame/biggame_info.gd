extends Resource
class_name BiggameInfo

var id: int

@export var name: String
@export var settings: PackedScene
@export var level: PackedScene

@export_subgroup("Supported functions")
@export var online_multiplayer: bool = false
@export var ai_player: bool = false

@export var min_player: int = 1
@export var max_player: int = 4
