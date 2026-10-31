class_name DestructibleCrate
extends StaticBody2D

## Thùng gỗ phá hủy được: Khi bị pháo hoặc súng máy bắn nát sẽ rơi ra Hộp cứu thương

@export var max_health: int = 25
var current_health: int = 25

@export var drop_chance: float = 0.55
@export var health_pickup_scene: PackedScene = preload("res://scenes/environment/HealthPickup.tscn")

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int, _is_aoe: bool = false) -> void:
	current_health = maxi(current_health - amount, 0)
	
	# Nháy trắng khi dính đạn
	if sprite:
		sprite.modulate = Color(2.5, 2.5, 2.5)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	
	if current_health <= 0:
		destroy_crate()

func destroy_crate() -> void:
	# Rơi ra hộp cứu thương theo tỉ lệ
	if randf() <= drop_chance and health_pickup_scene:
		var pickup := health_pickup_scene.instantiate() as Node2D
		pickup.global_position = global_position
		get_parent().call_deferred("add_child", pickup)
	
	queue_free()
