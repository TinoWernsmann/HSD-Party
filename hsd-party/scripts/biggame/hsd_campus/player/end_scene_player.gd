extends Node3D
class_name BiggameHSDCampus_EndingScreenPlayer

@export var player_material_base: StandardMaterial3D
@export var player_mesh: MeshInstance3D

var texture: Texture2D

func setup(_texture: Texture2D) -> void:
	self.texture = _texture

func _ready() -> void:
	var player_mat: StandardMaterial3D = player_material_base.duplicate()
	player_mat.albedo_texture = texture
	player_mesh.material_override = player_mat
