## Handles the default dice of the game
##
## Base class of all other special dice
extends Node3D
class_name BiggameHSDCampus_Dice
 
@onready var dice = $standardWuerfel/wuerfel
@onready var dice_ui = $"../UIs/wuerfel_ui/Label"
var max_dice_numb: int = 10
var min_dice_numb: int = 1
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var target_rotation: Vector3
var current_type: Dice_Type = Dice_Type.NORMAL
var is_fixed: bool = false
var last_selected_player: int = -1
var _original_materials: Dictionary = {}

enum Dice_Type {
	NORMAL,
	BIG,
	SMALL
}

func fix_position() -> void:
	is_fixed = true

func unfix_position() -> void:
	is_fixed = false

func _process(_delta) -> void:
	var gm = get_node("../game_manager")
	# Nur wenn der Spieler wechselt, bewegt sich der Würfel zum neuen Spieler
	if last_selected_player != gm.get_current_player():
		last_selected_player = gm.get_current_player()
		position = gm.players[gm.get_current_player()].position + Vector3(0, 3, 0)
	# Wenn is_fixed true ist, bleibt der Würfel stehen

func roll_dice(_number: int = -1) -> int:
	var result: int = 0
	if _number == -1:
		result = rng.randi_range(min_dice_numb, max_dice_numb)
	else:
		result = _number
	
	if result > 6:
		set_die_texture_by_number(result)
	else:
		restore_original_materials()

	target_rotation = get_rotation_for_result(result)
	# Bei Zahlen >6 die Anzeige relativ zur Kamerarotation ausrichten
	if result > 6:
		var cam_y: float = _get_camera_y_rotation()
		target_rotation.y = cam_y  + PI/2
	animation()
	dice_ui.text = "Würfel-Ergebnis: " + str(result)
	return result
	
func update_rolled_number(numb: int) -> void:
	if numb >= 0:
		dice_ui.text = "Würfel-Ergebnis: " + str(numb)
		
func hide_rolled_numb() -> void:
	dice_ui.text = ""

func animation() -> void:
	var tween1: Tween = create_tween()
	tween1.tween_property(dice, "rotation", Vector3(randf_range(PI*4, PI*6), randf_range(PI*4, PI*6), randf_range(PI*4, PI*6)), 0.5)
	await tween1.finished
	
	var tween2: Tween = create_tween()
	tween2.set_ease(Tween.EASE_OUT)
	#tween2.set_trans(Tween.TRANS_CUBIC)
	tween2.tween_property(dice, "rotation", target_rotation, 0.3)

func get_rotation_for_result(number: int) -> Vector3:
	match number:
		1: return Vector3(0, 0, 0)           
		2: return Vector3(PI/2, 0, 0)        
		3: return Vector3(0, 0, -PI/2)       
		4: return Vector3(0, 0, PI/2)        
		5: return Vector3(-PI/2, 0, 0)     
		6: return Vector3(PI, 0, 0)         
		_: return Vector3(0, 0, 0)

func change_to_normal_dice() -> void:
	current_type = Dice_Type.NORMAL
	min_dice_numb = 1
	max_dice_numb = 10

func change_dice(new_dice: BiggameHSDCampus_Item) -> void:
	match new_dice.type:
		BiggameHSDCampus_Item.Type.BIG_DICE:
			current_type = Dice_Type.BIG
			min_dice_numb = 8
			max_dice_numb = 10
		BiggameHSDCampus_Item.Type.SMALL_DICE:
			current_type = Dice_Type.SMALL
			min_dice_numb = 1
			max_dice_numb = 4

func _ready() -> void:
	_capture_original_materials()

func _capture_original_materials() -> void:
	_original_materials.clear()
	_collect_mesh_materials(dice)

func _collect_mesh_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node.mesh as Mesh
		if mesh:
			var surface_count := mesh.get_surface_count()
			for i in range(surface_count):
				var mat = node.get_surface_override_material(i)
				if mat == null:
					mat = mesh.surface_get_material(i)
				var rel_path := str(self.get_path_to(node)) + ":" + str(i)
				_original_materials[rel_path] = mat

	for child in node.get_children():
		_collect_mesh_materials(child)

func set_die_texture_by_number(number: int) -> void:
	var path := "res://assets/textures/dice/textur%d.png" % number
	var tex := load(path)
	if not tex:
		return

	for key in _original_materials.keys():
		var parts: PackedStringArray = key.split(":")
		var node_path := parts[0]
		var idx := int(parts[1])
		if not has_node(node_path):
			continue
		var node := get_node(node_path)
		if node is MeshInstance3D:
			var orig_mat: Material = _original_materials[key] as Material
			var new_mat: Material = null
			if orig_mat:
				new_mat = orig_mat.duplicate()
			else:
				new_mat = StandardMaterial3D.new()
			if new_mat is StandardMaterial3D:
				new_mat.albedo_texture = tex
			node.set_surface_override_material(idx, new_mat)

func restore_original_materials() -> void:
	for key in _original_materials.keys():
		var parts: PackedStringArray = key.split(":")
		var node_path := parts[0]
		var idx := int(parts[1])
		if not has_node(node_path):
			continue
		var node := get_node(node_path)
		if node is MeshInstance3D:
			node.set_surface_override_material(idx, _original_materials[key])

func _get_camera_y_rotation() -> float:
	var cam := get_viewport().get_camera_3d()
	if cam:
		return cam.rotation.y
	else:
		return 0.0
# Fallback
'	
	var packed := load("res://scenes/object/manager/game_cam.tscn")
	if packed and packed is PackedScene:
		var inst: Node = packed.instantiate()
		var found := _find_camera_in_node(inst)
		if found:
			return found.rotation.y
	return 0.0
	'


func _find_camera_in_node(node: Node) -> Camera3D:
	if node is Camera3D:
		return node
	for child in node.get_children():
		var res := _find_camera_in_node(child)
		if res:
			return res
	return null
