class_name PracticeDummy
extends StaticBody2D

## Bia tập bắn / Xe tăng mô phỏng để test pháo Parabola và súng máy

@export var max_health: int = 150
var current_health: int = 150

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_label: Label = $HPLabel

func _ready() -> void:
	current_health = max_health
	update_ui()

func take_damage(amount: int, is_aoe: bool) -> void:
	current_health = maxi(current_health - amount, 0)
	update_ui()
	
	# Hiệu ứng nháy đỏ khi bị bắn trúng
	if sprite:
		sprite.modulate = Color(1.8, 0.4, 0.4)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	
	if current_health <= 0:
		# Tự hồi sinh sau 2 giây để tiếp tục test
		var timer := get_tree().create_timer(2.0)
		timer.timeout.connect(respawn)

func respawn() -> void:
	current_health = max_health
	update_ui()

func update_ui() -> void:
	if hp_label:
		hp_label.text = "%d / %d HP" % [current_health, max_health]
