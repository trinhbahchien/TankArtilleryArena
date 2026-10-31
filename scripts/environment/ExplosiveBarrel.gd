class_name ExplosiveBarrel
extends StaticBody2D

## Thùng phuy xăng đỏ: Khi bị bắn trúng sẽ phát nổ diện rộng AoE gây sát thương khủng

@export var max_health: int = 15
var current_health: int = 15
var has_exploded: bool = false

@export var explosion_radius: float = 140.0
@export var explosion_damage: int = 65
@export var explosion_vfx_scene: PackedScene = preload("res://scenes/vfx/ExplosionVFX.tscn")

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int, _is_aoe: bool = false) -> void:
	if has_exploded:
		return
	current_health = maxi(current_health - amount, 0)
	
	if sprite:
		sprite.modulate = Color(3.0, 1.5, 1.5)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		
	if current_health <= 0:
		explode()

func explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	
	if explosion_vfx_scene:
		var vfx := explosion_vfx_scene.instantiate() as Node2D
		vfx.global_position = global_position
		get_parent().add_child(vfx)
		
	GlobalEvents.camera_shake_requested.emit(14.0, 0.5)
	AudioManager.play_explosion()
	
	# Quét sát thương nổ
	var space_state := get_world_2d().direct_space_state
	var shape_query := PhysicsShapeQueryParameters2D.new()
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = explosion_radius
	shape_query.shape = circle_shape
	shape_query.transform = Transform2D(0.0, global_position)
	shape_query.collision_mask = 1 | 2 | 4 # Tường/Thùng (1), Player (2), Enemy (4)
	
	var hits := space_state.intersect_shape(shape_query)
	for hit in hits:
		var col = hit.get("collider")
		if col and col != self and col.has_method("take_damage"):
			var dist := global_position.distance_to(col.global_position)
			var ratio := 1.0 - clampf(dist / explosion_radius, 0.0, 0.6)
			col.take_damage(int(explosion_damage * ratio), true)
			
	queue_free()
