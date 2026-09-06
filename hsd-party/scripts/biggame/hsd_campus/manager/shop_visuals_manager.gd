extends Node3D
class_name BiggameHSDCampus_ShopVisuals

@onready var shop_cam: Camera3D = $"../Camera3D"
@onready var seller_animator: AnimationPlayer = $"../seller/AnimationPlayer"
@onready var seller: Node3D = $"../seller"

@export var scale_setting: float = 0.25

func _ready() -> void:
	seller.position.y = -1.539

func enter_shop_animation() -> void:
	seller_animator.play("new_animation")

func leave_shop_animation() -> void:
	seller_animator.play("RESET")

func set_seller_model(model: PackedScene) -> void:
	if model:
		var seller_instance := model.instantiate()
		seller_instance.scale = Vector3(scale_setting, scale_setting, scale_setting)
		seller.add_child(seller_instance)
