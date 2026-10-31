class_name HealthComponent
extends Node

## Component Quản lý Máu & Sát thương dùng chung cho mọi thực thể (Player, Enemy, Tường phá hủy)

signal health_changed(current_hp: int, max_hp: int)
signal died()

@export var max_health: int = 100
var current_health: int = 100

@export var parent_sprite: CanvasItem

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int, is_aoe: bool = false) -> void:
	if current_health <= 0:
		return
		
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	GlobalEvents.tank_damaged.emit(get_parent(), current_health, max_health)
	
	# Hiệu ứng nháy đỏ khi bị thương
	if parent_sprite:
		parent_sprite.modulate = Color(2.0, 0.4, 0.4)
		var tween := create_tween()
		tween.tween_property(parent_sprite, "modulate", Color.WHITE, 0.2)
	
	if current_health <= 0:
		died.emit()
		GlobalEvents.tank_destroyed.emit(get_parent(), null)

func heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
	
	# Hiệu ứng nháy xanh lá khi được hồi máu/sửa chữa
	if parent_sprite:
		parent_sprite.modulate = Color(0.4, 2.5, 0.7)
		var tween := create_tween()
		tween.tween_property(parent_sprite, "modulate", Color.WHITE, 0.35)
