class_name MachineGunBullet
extends Area2D

## Đạn súng máy dạng 2 THANH CHỮ NHẬT MÀU VÀNG song song
## Tầm bay tối đa đạt cự ly TẦM TRUNG (~480 px), kể cả khi ngắm ở Tầm Gần đạn vẫn bay vươn tới hết Tầm Trung

@export var speed: float = 1050.0
@export var damage: int = 6
@export var lifetime: float = 0.46 # 1050 * 0.46 = 483 px (Tầm Trung tối đa)

var direction: Vector2 = Vector2.RIGHT

func initialize(start_pos: Vector2, shoot_direction: Vector2) -> void:
	global_position = start_pos
	direction = shoot_direction.normalized()
	rotation = direction.angle()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, false)
	queue_free()
